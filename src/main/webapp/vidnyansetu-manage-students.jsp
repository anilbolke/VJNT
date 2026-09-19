<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.VidnyanSetuUser,com.vjnt.model.School,com.vjnt.dao.SchoolDAO,com.vjnt.dao.VidnyanSetuPhaseApprovalDAO,com.vjnt.util.DatabaseConnection,java.sql.*,java.util.*" %>
<%
    VidnyanSetuUser vsUser = (VidnyanSetuUser) session.getAttribute("vsUser");
    if (vsUser == null) { response.sendRedirect(request.getContextPath() + "/vidnyansetu-login"); return; }
    // Coordinator-only page: VS Teachers use vidnyansetu-activity.jsp instead.
    if (vsUser.getRole() != VidnyanSetuUser.Role.COORDINATOR) {
        response.sendRedirect(request.getContextPath() + "/vidnyansetu-teacher-dashboard.jsp"); return;
    }
    boolean isCoordinator = true;
    String udiseNo = vsUser.getUdiseNo();

    School school = new SchoolDAO().getSchoolByUdise(udiseNo);
    String schoolName = school != null ? school.getSchoolName() : "-";

    // ── Phase gating: same rule as manage-students.jsp (FLN) ──
    // Phase N is reachable once Phase N-1 is APPROVED by Head Master (Phase 1
    // always is). A reachable phase is read-only once submitted (a row
    // exists) and not REJECTED.
    VidnyanSetuPhaseApprovalDAO approvalDAO = new VidnyanSetuPhaseApprovalDAO();
    Map<String,Object>[] pa = new Map[5]; // 1-indexed
    boolean[] complete = new boolean[5];
    boolean[] approved = new boolean[5];
    boolean[] rejected = new boolean[5];
    for (int p = 1; p <= 4; p++) {
        pa[p] = approvalDAO.getPhaseApproval(udiseNo, p);
        complete[p] = pa[p] != null;
        approved[p] = pa[p] != null && "APPROVED".equals(pa[p].get("approvalStatus"));
        rejected[p] = pa[p] != null && "REJECTED".equals(pa[p].get("approvalStatus"));
    }
    boolean[] reachable = new boolean[5];
    reachable[1] = true;
    reachable[2] = approved[1];
    reachable[3] = approved[2];
    reachable[4] = approved[3];

    int selectedPhase = 1;
    try { selectedPhase = Integer.parseInt(request.getParameter("phase")); } catch (Exception ignore) {}
    if (selectedPhase < 1 || selectedPhase > 4) selectedPhase = 1;
    while (selectedPhase > 1 && !reachable[selectedPhase]) selectedPhase--;

    boolean currentComplete = complete[selectedPhase];
    boolean currentApproved = approved[selectedPhase];
    boolean currentRejected = rejected[selectedPhase];
    boolean isReadOnly = currentComplete && !currentRejected; // editing gate — applies to both roles now
    String phaseValueCol = "phase" + selectedPhase + "_vidnyan";
    String phaseDateCol = "phase" + selectedPhase + "_date";

    // ── Roster for the selected phase ──
    // Teacher: only their own assigned class-sections (that's what they're
    // authorized to edit). Coordinator: EVERY active student at the school,
    // school-wide, with a flag for whether a VidnyanSetu teacher covers them.
    List<Map<String,Object>> students = new ArrayList<>();
    String rosterSql = isCoordinator ?
        "SELECT s.student_id, s.student_pen, s.student_name, s.class, s.section, " +
        "       l." + phaseValueCol + " AS lvl, l." + phaseDateCol + " AS lvlDate, MAX(a.vs_user_id IS NOT NULL) AS has_teacher " +
        "FROM students s " +
        "LEFT JOIN vidnyansetu_teacher_assignments a ON a.udise_code = s.udise_no " +
        "  AND a.class = s.class AND a.section = s.section AND a.is_active = 1 " +
        "LEFT JOIN vidnyansetu_student_levels l ON l.student_id = s.student_id " +
        "WHERE s.is_active = 1 AND s.udise_no = ? " +
        "GROUP BY s.student_id ORDER BY s.class, s.section, s.student_name" :
        "SELECT s.student_id, s.student_pen, s.student_name, s.class, s.section, " +
        "       l." + phaseValueCol + " AS lvl, l." + phaseDateCol + " AS lvlDate, 1 AS has_teacher " +
        "FROM students s " +
        "JOIN vidnyansetu_teacher_assignments a ON a.udise_code = s.udise_no " +
        "  AND a.class = s.class AND a.section = s.section AND a.is_active = 1 AND a.vs_user_id = ? " +
        "LEFT JOIN vidnyansetu_student_levels l ON l.student_id = s.student_id " +
        "WHERE s.is_active = 1 AND s.udise_no = ? " +
        "ORDER BY s.class, s.section, s.student_name";
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(rosterSql)) {
        if (isCoordinator) {
            ps.setString(1, udiseNo);
        } else {
            ps.setInt(1, vsUser.getVsUserId());
            ps.setString(2, udiseNo);
        }
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new LinkedHashMap<>();
                m.put("id", rs.getInt("student_id"));
                m.put("pen", rs.getString("student_pen"));
                m.put("name", rs.getString("student_name"));
                m.put("class", rs.getString("class"));
                m.put("section", rs.getString("section"));
                // Explicitly-saved (even level 0 = "स्तर निश्चित केला नाही") vs never touched —
                // phase{N}_date is set on every save regardless of value, so it's the right
                // signal for "has this row been saved at all", separate from "level > 0"
                // which drives the Level Recorded *count* (see completedStudents below).
                m.put("dateSet", rs.getTimestamp("lvlDate") != null);
                Object lvl = rs.getObject("lvl");
                m.put("level", lvl == null ? 0 : ((Number) lvl).intValue());
                m.put("hasTeacher", rs.getBoolean("has_teacher"));
                students.add(m);
            }
        }
    }

    int totalStudents = students.size();
    int completedStudents = 0;
    for (Map<String,Object> s : students) {
        // "completed" for submit purposes means a level has actually been recorded (non-null in DB) —
        // level 0 default when nothing was ever saved doesn't count. Re-check via presence in list is
        // enough here since NULL was already coalesced to 0 above for display; completedStudents is
        // informational for the coordinator's submit bar, so approximate via >0 is acceptable.
        if ((Integer) s.get("level") > 0) completedStudents++;
    }
    int pendingStudents = totalStudents - completedStudents;

    LinkedHashSet<String> distinctClasses = new LinkedHashSet<>();
    for (Map<String,Object> s : students) distinctClasses.add((String) s.get("class"));
    String classesLabel = distinctClasses.isEmpty() ? "-" : String.join(", ", distinctClasses);

    String[] levelLabels = { "स्तर निश्चित केला नाही", "प्रारंभिक", "विकसनशिल", "विकसीत", "प्रगत" };
%>
<!DOCTYPE html>
<html lang="mr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>विद्यार्थी व्यवस्थापन - विज्ञानसेतू</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f4f8;color:#1e293b;}
.topbar{background:linear-gradient(135deg,#0f9b6c 0%,#0c7b54 100%);color:#fff;padding:16px 24px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;}
.topbar .brand{font-size:19px;font-weight:800;}
.topbar .who{font-size:13px;opacity:0.9;}
.topbar-actions{display:flex;gap:10px;align-items:center;flex-wrap:wrap;}
.topbar-btn{background:rgba(255,255,255,0.15);color:#fff;text-decoration:none;padding:8px 14px;border-radius:8px;font-size:13px;font-weight:600;border:1px solid rgba(255,255,255,0.3);}
.topbar-btn:hover{background:rgba(255,255,255,0.28);}
.wrap{max-width:1100px;margin:30px auto;padding:0 20px;}
.page-title{font-size:20px;font-weight:700;color:#0c7b54;margin-bottom:10px;}
.back-btn{display:inline-block;margin-bottom:18px;background:#fff;color:#0c7b54;border:1px solid #0f9b6c;}
.back-btn:hover{background:#ecfdf5;}

.school-header{background:#f0f2f5;color:#000;padding:20px 30px;border-radius:8px;margin-bottom:20px;text-align:center;}
.school-header .school-icon{font-size:24px;}
.school-header h1{font-size:22px;font-weight:700;margin:4px 0;}
.school-header .header-subtitle{font-size:14px;opacity:0.85;}
.breadcrumb{background:#fff;padding:15px 25px;border-radius:12px;margin-bottom:20px;box-shadow:0 4px 15px rgba(0,0,0,0.08);border-left:5px solid #0f9b6c;font-size:13.5px;}
.dashboard-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;margin-bottom:24px;}
.stat-card{background:#fff;padding:15px;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,0.06);border-left:3px solid #0f9b6c;text-align:center;}
.stat-icon{font-size:28px;margin-bottom:6px;display:block;}
.stat-value{font-size:26px;font-weight:700;color:#2d3748;margin-bottom:4px;}
.stat-label{font-size:11px;color:#718096;font-weight:500;}

.phase-bar{background:#fff;border-radius:12px;padding:18px 22px;box-shadow:0 4px 18px rgba(0,0,0,0.08);margin-bottom:22px;border:1px solid #e2e8f0;display:flex;align-items:center;gap:16px;flex-wrap:wrap;}
.phase-bar select{padding:9px 14px;border:2px solid #0f9b6c;border-radius:7px;font-size:14px;font-weight:600;}
.phase-status{font-size:13px;font-weight:700;padding:5px 12px;border-radius:20px;}
.ps-open{background:#fef3c7;color:#92400e;}
.ps-pending{background:#fef3c7;color:#92400e;}
.ps-approved{background:#dcfce7;color:#14532d;}
.ps-rejected{background:#fee2e2;color:#991b1b;}
.btn-submit-phase{background:#0f9b6c;color:#fff;border:none;padding:10px 20px;border-radius:8px;font-size:13.5px;font-weight:700;cursor:pointer;}
.btn-submit-phase:hover{background:#0c7b54;}
.btn-submit-phase:disabled{background:#94a3b8;cursor:not-allowed;}

.section-card{background:#fff;border-radius:12px;padding:22px;box-shadow:0 4px 18px rgba(0,0,0,0.08);margin-bottom:22px;border:1px solid #e2e8f0;}
.section-card h3{margin-bottom:14px;color:#0c7b54;}
.filter-bar{display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin-bottom:16px;}
.filter-bar input,.filter-bar select{padding:9px 12px;border:1px solid #cbd5e1;border-radius:7px;font-size:13px;}
.filter-bar input{flex:1;min-width:200px;}
.filter-bar .count{font-size:12.5px;color:#64748b;white-space:nowrap;}
tr.row-hidden{display:none;}
.pager{display:flex;gap:6px;justify-content:center;align-items:center;flex-wrap:wrap;margin-top:16px;}
.pager button{padding:7px 12px;border:1px solid #cbd5e1;border-radius:6px;background:#fff;font-size:13px;cursor:pointer;}
.pager button:hover:not(:disabled){background:#ecfdf5;border-color:#0f9b6c;}
.pager button.active{background:#0f9b6c;color:#fff;border-color:#0f9b6c;}
.pager button:disabled{opacity:0.4;cursor:not-allowed;}
.pager .pager-info{font-size:12.5px;color:#64748b;margin:0 6px;}
.badge{padding:3px 9px;border-radius:20px;font-size:11px;font-weight:700;}
.badge-yes{background:#dcfce7;color:#14532d;}
.badge-no{background:#fee2e2;color:#991b1b;}
table{width:100%;border-collapse:collapse;}
th,td{padding:10px 12px;text-align:left;border-bottom:1px solid #e2e8f0;font-size:13.5px;}
th{background:#f8fafc;color:#475569;font-weight:700;}
select.level-select{padding:7px 10px;border:1px solid #cbd5e1;border-radius:7px;font-size:13px;min-width:180px;}
select.level-select:disabled{background:#f1f5f9;color:#64748b;}
.btn-save-level{padding:7px 14px;border:1px solid #cbd5e1;border-radius:7px;font-size:12.5px;font-weight:700;cursor:pointer;background:#fff;color:#334155;white-space:nowrap;transition:all 0.2s;}
.btn-save-level:hover:not(:disabled){border-color:#0f9b6c;background:#ecfdf5;}
.btn-save-level.is-saved{background:#0f9b6c;border-color:#0f9b6c;color:#fff;}
.btn-save-level.is-saved:hover:not(:disabled){background:#0c7b54;}
.btn-save-level:disabled{opacity:0.5;cursor:not-allowed;}
.empty{color:#64748b;padding:10px 0;}
.readonly-note{background:#fef3c7;color:#92400e;padding:10px 16px;border-radius:8px;font-size:13px;margin-bottom:16px;}
.rejected-note{background:#fee2e2;color:#991b1b;padding:10px 16px;border-radius:8px;font-size:13px;margin-bottom:16px;}
</style>
</head>
<body>
<div class="topbar">
    <div class="brand">🔬 विज्ञानसेतू</div>
    <div class="topbar-actions">
        <span class="who"><%= vsUser.getFullName() != null ? vsUser.getFullName() : vsUser.getUsername() %> · UDISE <%= udiseNo %></span>
    </div>
</div>

<div class="wrap">
    <div class="school-header">
        <div class="school-icon">🏫</div>
        <h1><%= schoolName %></h1>
        <div class="header-subtitle">UDISE: <%= udiseNo %> | <%= isCoordinator ? "VidnyanSetu School Coordinator" : "VidnyanSetu Teacher" %></div>
    </div>

    <div class="breadcrumb">
        <span>🏫 School:</span> <strong><%= schoolName %></strong> (<%= udiseNo %>)
        <span style="margin: 0 10px;">→</span>
        <span>📚 Class:</span> <strong><%= classesLabel %></strong>
    </div>

    <div class="dashboard-grid">
        <div class="stat-card"><div class="stat-icon">👥</div><div class="stat-value"><%= totalStudents %></div><div class="stat-label">Total Students</div></div>
        <div class="stat-card"><div class="stat-icon">📚</div><div class="stat-value"><%= distinctClasses.size() %></div><div class="stat-label">Classes</div></div>
        <div class="stat-card"><div class="stat-icon">✅</div><div class="stat-value" id="levelRecordedCount"><%= completedStudents %></div><div class="stat-label">Level Recorded</div></div>
    </div>

    <div class="page-title">👨‍🎓 विद्यार्थी व्यवस्थापन (Manage Students) — Phase <%= selectedPhase %></div>
    <a class="topbar-btn back-btn" href="<%= request.getContextPath() %>/<%= isCoordinator ? "vidnyansetu-coordinator-dashboard.jsp" : "vidnyansetu-teacher-dashboard.jsp" %>">← Dashboard</a>

    <div class="phase-bar">
        <form method="get" style="display:inline;">
            <select name="phase" onchange="this.form.submit()">
                <option value="1" <%= selectedPhase==1?"selected":"" %>>Phase 1 <%= rejected[1] ? "❌ Rejected" : (complete[1] ? (approved[1] ? "✓ Approved" : "🕒 Pending Approval") : "") %></option>
                <option value="2" <%= selectedPhase==2?"selected":"" %> <%= !reachable[2]?"disabled":"" %>>Phase 2 <%= !reachable[2] ? "🔒 Locked" : (rejected[2] ? "❌ Rejected" : (complete[2] ? (approved[2] ? "✓ Approved" : "🕒 Pending Approval") : "")) %></option>
                <option value="3" <%= selectedPhase==3?"selected":"" %> <%= !reachable[3]?"disabled":"" %>>Phase 3 <%= !reachable[3] ? "🔒 Locked" : (rejected[3] ? "❌ Rejected" : (complete[3] ? (approved[3] ? "✓ Approved" : "🕒 Pending Approval") : "")) %></option>
                <option value="4" <%= selectedPhase==4?"selected":"" %> <%= !reachable[4]?"disabled":"" %>>Phase 4 <%= !reachable[4] ? "🔒 Locked" : (rejected[4] ? "❌ Rejected" : (complete[4] ? (approved[4] ? "✓ Approved" : "🕒 Pending Approval") : "")) %></option>
            </select>
        </form>

        <% if (currentApproved) { %>
            <span class="phase-status ps-approved">✅ Approved by Head Master</span>
        <% } else if (currentRejected) { %>
            <span class="phase-status ps-rejected">❌ Rejected — edit and resubmit</span>
        <% } else if (currentComplete) { %>
            <span class="phase-status ps-pending">🕒 Pending Head Master Approval</span>
        <% } else { %>
            <span class="phase-status ps-open">✏️ Open for entry</span>
        <% } %>

        <%-- <% if (isCoordinator) { %>
            <button type="button" class="btn-submit-phase"
                    <%= (currentComplete && !currentRejected) ? "disabled" : "" %>
                    onclick="submitPhase(<%= selectedPhase %>)">
                📤 Submit Phase <%= selectedPhase %> for Approval
            </button>
        <% } %> --%>
    </div>
    <div id="msgBox"></div>

    <% if (isReadOnly) { %>
        <div class="readonly-note">This phase has been submitted for Head Master approval and is read-only until a decision is made.</div>
    <% } %>
    <% if (currentRejected) { %>
        <div class="rejected-note">This phase was rejected<% if (pa[selectedPhase].get("approvalRemarks") != null) { %>: <%= pa[selectedPhase].get("approvalRemarks") %><% } %> — please review and resubmit<%= isCoordinator ? "." : " via your Coordinator." %></div>
    <% } %>

    <% if (students.isEmpty()) { %>
        <div class="section-card">
            <p class="empty"><%= isCoordinator ? "No active students found for this school." : "You have not been assigned any class/section yet. Please contact your VidnyanSetu School Coordinator." %></p>
        </div>
    <% } else { %>
        <div class="section-card">
            <div class="filter-bar">
                <input type="text" id="searchBox" placeholder="Search by name or PEN..." oninput="filterRows()">
                <select id="classFilter" onchange="filterRows()">
                    <option value="">All Classes</option>
                    <% for (String c : distinctClasses) { %>
                        <option value="<%= c %>"><%= c %></option>
                    <% } %>
                </select>
                <% if (isCoordinator) { %>
                <select id="coverageFilter" onchange="filterRows()">
                    <option value="">All Students</option>
                    <option value="yes">With VidnyanSetu Teacher</option>
                    <option value="no">Without VidnyanSetu Teacher</option>
                </select>
                <% } %>
                <span class="count" id="visibleCount"></span>
            </div>
            <table id="studentTable">
                <thead><tr><th>#</th><th>PEN</th><th>Name</th><th>Class-Section</th><th>विज्ञान स्तर</th><th>स्थिती</th></tr></thead>
                <tbody>
                <% for (int i = 0; i < students.size(); i++) {
                    Map<String,Object> st = students.get(i);
                    boolean hasTeacher = (Boolean) st.get("hasTeacher");
                    boolean levelSet = (Boolean) st.get("dateSet"); // explicitly saved, any value incl. 0
                    String searchBlob = (String.valueOf(st.get("name")) + " " + st.get("pen")).toLowerCase().replace("\"","'");
                %>
                    <tr data-class="<%= st.get("class") %>" data-coverage="<%= hasTeacher ? "yes" : "no" %>" data-search="<%= searchBlob %>">
                        <td class="sno-cell"><%= i + 1 %></td>
                        <td><%= st.get("pen") %></td>
                        <td><%= st.get("name") %></td>
                        <td><%= st.get("class") %>-<%= st.get("section") %></td>
                        <td>
                            <select class="level-select" data-student-id="<%= st.get("id") %>" onchange="markUnsaved(this)"
                                    <%= isReadOnly ? "disabled" : "" %>>
                                <% for (int lv = 0; lv < levelLabels.length; lv++) { %>
                                    <option value="<%= lv %>" <%= ((Integer)st.get("level")) == lv ? "selected" : "" %>><%= levelLabels[lv] %></option>
                                <% } %>
                            </select>
                        </td>
                        <td>
                            <button type="button" class="btn-save-level <%= levelSet ? "is-saved" : "" %>"
                                    data-counted="<%= levelSet %>"
                                    onclick="saveLevel(this)" <%= isReadOnly ? "disabled" : "" %>>
                                <%= levelSet ? "✓ जतन झाले" : "💾 जतन करा" %>
                            </button>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
            <div class="pager" id="pager"></div>
        </div>
    <% } %>
</div>

<script>
var ctx = '<%= request.getContextPath() %>';
var selectedPhase = <%= selectedPhase %>;

var STUDENT_PAGE_SIZE = 10;
var studentPage = 1;

function filterRows(resetPage) {
    if (resetPage !== false) studentPage = 1;

    var q = (document.getElementById('searchBox') || {}).value;
    q = q ? q.trim().toLowerCase() : '';
    var cls = (document.getElementById('classFilter') || {}).value || '';
    var coverageEl = document.getElementById('coverageFilter');
    var coverage = coverageEl ? coverageEl.value : '';

    var allRows = Array.prototype.slice.call(document.querySelectorAll('#studentTable tbody tr'));
    var matched = allRows.filter(function(tr) {
        var matchesSearch = !q || tr.getAttribute('data-search').indexOf(q) !== -1;
        var matchesClass = !cls || tr.getAttribute('data-class') === cls;
        var matchesCoverage = !coverage || tr.getAttribute('data-coverage') === coverage;
        return matchesSearch && matchesClass && matchesCoverage;
    });

    var totalPages = Math.max(1, Math.ceil(matched.length / STUDENT_PAGE_SIZE));
    if (studentPage > totalPages) studentPage = totalPages;
    var startIdx = (studentPage - 1) * STUDENT_PAGE_SIZE;
    var pageRows = matched.slice(startIdx, startIdx + STUDENT_PAGE_SIZE);

    allRows.forEach(function(tr) { tr.classList.add('row-hidden'); });
    pageRows.forEach(function(tr, idx) {
        tr.classList.remove('row-hidden');
        var snoCell = tr.querySelector('.sno-cell');
        if (snoCell) snoCell.textContent = startIdx + idx + 1;
    });

    var countEl = document.getElementById('visibleCount');
    if (countEl) countEl.textContent = matched.length + ' / ' + allRows.length + ' students';

    renderPager(matched.length, totalPages);
}

function renderPager(totalMatched, totalPages) {
    var pager = document.getElementById('pager');
    if (!pager) return;
    if (totalMatched === 0) { pager.innerHTML = ''; return; }

    var html = '';
    html += '<button ' + (studentPage === 1 ? 'disabled' : '') + ' onclick="goToStudentPage(' + (studentPage - 1) + ')">‹ Prev</button>';

    var start = Math.max(1, studentPage - 2);
    var end = Math.min(totalPages, start + 4);
    start = Math.max(1, end - 4);
    for (var p = start; p <= end; p++) {
        html += '<button class="' + (p === studentPage ? 'active' : '') + '" onclick="goToStudentPage(' + p + ')">' + p + '</button>';
    }

    html += '<button ' + (studentPage === totalPages ? 'disabled' : '') + ' onclick="goToStudentPage(' + (studentPage + 1) + ')">Next ›</button>';
    html += '<span class="pager-info">Page ' + studentPage + ' of ' + totalPages + '</span>';
    pager.innerHTML = html;
}

function goToStudentPage(p) {
    studentPage = p;
    filterRows(false);
    document.getElementById('studentTable').scrollIntoView({ behavior: 'smooth', block: 'start' });
}

filterRows();

function showMsg(ok, text) {
    document.getElementById('msgBox').innerHTML =
        '<div style="padding:10px 14px;border-radius:7px;font-size:13px;font-weight:500;margin-bottom:16px;background:' +
        (ok ? '#d1fae5;color:#065f46' : '#fee2e2;color:#991b1b') + ';">' + text + '</div>';
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

function updateLevelRecordedCount(btn, nowCounted) {
    var wasCounted = btn.getAttribute('data-counted') === 'true';
    if (wasCounted === nowCounted) return;
    btn.setAttribute('data-counted', nowCounted);
    var countEl = document.getElementById('levelRecordedCount');
    if (!countEl) return;
    var current = parseInt(countEl.textContent, 10) || 0;
    countEl.textContent = current + (nowCounted ? 1 : -1);
}

function markUnsaved(sel) {
    var btn = sel.closest('tr').querySelector('.btn-save-level');
    if (!btn) return;
    btn.classList.remove('is-saved');
    btn.textContent = '💾 जतन करा';
}

function saveLevel(btn) {
    var row = btn.closest('tr');
    var sel = row.querySelector('.level-select');
    var studentId = sel.getAttribute('data-student-id');
    var level = sel.value;

    var params = new URLSearchParams();
    params.append('studentId', studentId);
    params.append('level', level);
    params.append('phase', selectedPhase);

    btn.disabled = true;
    var originalText = btn.textContent;
    btn.textContent = 'जतन होत आहे...';

    fetch(ctx + '/vidnyansetu-set-level', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
    })
    .then(function(r) { return r.json(); })
    .then(function(res) {
        btn.disabled = false;
        if (res.success) {
            btn.classList.add('is-saved');
            btn.textContent = '✓ जतन झाले';
            updateLevelRecordedCount(btn, parseInt(level, 10) > 0);
        } else {
            btn.classList.remove('is-saved');
            btn.textContent = originalText;
            alert(res.message || 'स्तर जतन करताना त्रुटी आली.');
        }
    })
    .catch(function() {
        btn.disabled = false;
        btn.textContent = originalText;
        alert('काहीतरी चूक झाली. पुन्हा प्रयत्न करा.');
    });
}

function submitPhase(phaseNumber) {
    if (!confirm('Submit Phase ' + phaseNumber + ' for Head Master approval? Students will not be editable until a decision is made.')) return;

    var params = new URLSearchParams();
    params.append('phaseNumber', phaseNumber);

    fetch(ctx + '/vidnyansetu-submit-phase', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
    })
    .then(function(r) { return r.json(); })
    .then(function(res) {
        showMsg(res.success, res.message);
        if (res.success) setTimeout(function() { location.reload(); }, 1200);
    })
    .catch(function() { showMsg(false, 'Something went wrong. Please try again.'); });
}
</script>
</body>
</html>
