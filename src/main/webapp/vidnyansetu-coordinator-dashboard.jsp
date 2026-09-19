<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.VidnyanSetuUser,com.vjnt.model.School,com.vjnt.dao.SchoolDAO,com.vjnt.dao.VidnyanSetuPhaseApprovalDAO,com.vjnt.util.DatabaseConnection,java.sql.*,java.util.*" %>
<%
    VidnyanSetuUser vsUser = (VidnyanSetuUser) session.getAttribute("vsUser");
    if (vsUser == null) { response.sendRedirect(request.getContextPath() + "/vidnyansetu-login"); return; }
    if (vsUser.getRole() != VidnyanSetuUser.Role.COORDINATOR) {
        response.sendRedirect(request.getContextPath() + "/vidnyansetu-teacher-dashboard.jsp"); return;
    }

    School school = new SchoolDAO().getSchoolByUdise(vsUser.getUdiseNo());
    String schoolName = school != null ? school.getSchoolName() : "-";

    // School-wide stats: total active students, distinct classes/sections, VidnyanSetu teacher logins.
    int totalStudents = 0;
    LinkedHashSet<String> distinctClasses = new LinkedHashSet<>();
    LinkedHashSet<String> distinctSections = new LinkedHashSet<>();
    int teacherCount = 0;
    try (Connection conn = DatabaseConnection.getConnection()) {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT class, section FROM students WHERE is_active = 1 AND udise_no = ?")) {
            ps.setString(1, vsUser.getUdiseNo());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    totalStudents++;
                    distinctClasses.add(rs.getString("class"));
                    distinctSections.add(rs.getString("class") + "-" + rs.getString("section"));
                }
            }
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM vidnyansetu_users WHERE role = 'TEACHER' AND udise_no = ?")) {
            ps.setString(1, vsUser.getUdiseNo());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) teacherCount = rs.getInt(1);
            }
        }
    }

    // ── Phase Completion Reports — same 4-phase workflow as the main portal's
    //    School Coordinator dashboard, against vidnyansetu_phase_approvals.
    //    Completion % is over EVERY active student at the school (same
    //    denominator as totalStudents above / "Level Recorded" on
    //    vidnyansetu-manage-students.jsp) — NOT just VS-teacher-covered ones,
    //    since the Coordinator can set a level for any student school-wide. ──
    VidnyanSetuPhaseApprovalDAO approvalDAO = new VidnyanSetuPhaseApprovalDAO();
    Map<String,Object>[] pa = new Map[5];
    boolean[] phaseComplete = new boolean[5];
    boolean[] phaseApproved = new boolean[5];
    boolean[] phaseRejected = new boolean[5];
    boolean[] phasePending = new boolean[5];
    int[] phaseCompletion = new int[5];
    try (Connection conn = DatabaseConnection.getConnection()) {
        for (int p = 1; p <= 4; p++) {
            pa[p] = approvalDAO.getPhaseApproval(vsUser.getUdiseNo(), p);
            phaseComplete[p] = pa[p] != null;
            phaseApproved[p] = pa[p] != null && "APPROVED".equals(pa[p].get("approvalStatus"));
            phaseRejected[p] = pa[p] != null && "REJECTED".equals(pa[p].get("approvalStatus"));
            phasePending[p] = pa[p] != null && "PENDING".equals(pa[p].get("approvalStatus"));

            if (totalStudents > 0) {
                int done = 0;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(DISTINCT s.student_id) FROM students s " +
                        "JOIN vidnyansetu_student_levels l ON l.student_id = s.student_id " +
                        // > 0, not just "IS NOT NULL" — a saved level 0 (स्तर निश्चित केला नाही)
                        // still writes phase{N}_date, but that's not an actual level being set.
                        "WHERE s.is_active = 1 AND s.udise_no = ? AND l.phase" + p + "_vidnyan > 0")) {
                    ps.setString(1, vsUser.getUdiseNo());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) done = rs.getInt(1);
                    }
                }
                phaseCompletion[p] = (int) Math.round(done * 100.0 / totalStudents);
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="mr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>विज्ञानसेतू - School Coordinator</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f0f4f8; color: #1e293b; min-height: 100vh; }
        .topbar {
            background: linear-gradient(135deg, #0f9b6c 0%, #0c7b54 100%); color: #fff;
            padding: 16px 24px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 10px;
        }
        .topbar .brand { font-size: 19px; font-weight: 800; display: flex; align-items: center; gap: 8px; }
        .topbar .who { font-size: 13px; opacity: 0.9; }
        .topbar-actions { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
        .topbar-btn {
            background: rgba(255,255,255,0.15); color: #fff; text-decoration: none; padding: 8px 14px;
            border-radius: 8px; font-size: 13px; font-weight: 600; border: 1px solid rgba(255,255,255,0.3);
        }
        .topbar-btn:hover { background: rgba(255,255,255,0.28); }
        .wrap { max-width: 900px; margin: 40px auto; padding: 0 20px; }
        .wrap h2 { font-size: 20px; margin-bottom: 18px; color: #0c7b54; }

        /* School info header + stat cards — same pattern as school-dashboard-enhanced.jsp */
        .school-header { background: #f0f2f5; color: #000; padding: 20px 30px; border-radius: 8px; margin-bottom: 20px; text-align: center; }
        .school-header .school-icon { font-size: 24px; }
        .school-header h1 { font-size: 22px; font-weight: 700; margin: 4px 0; }
        .school-header .header-subtitle { font-size: 14px; opacity: 0.85; }
        .breadcrumb { background: #fff; padding: 15px 25px; border-radius: 12px; margin-bottom: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-left: 5px solid #0f9b6c; font-size: 13.5px; }
        .dashboard-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 12px; margin-bottom: 24px; }
        .stat-card { background: #fff; padding: 15px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); border-left: 3px solid #0f9b6c; text-align: center; }
        .stat-icon { font-size: 28px; margin-bottom: 6px; display: block; }
        .stat-value { font-size: 26px; font-weight: 700; color: #2d3748; margin-bottom: 4px; }
        .stat-label { font-size: 11px; color: #718096; font-weight: 500; }
        .activity-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 18px; }
        .activity-card {
            background: #fff; border-radius: 14px; padding: 30px; box-shadow: 0 4px 18px rgba(0,0,0,0.08);
            display: flex; align-items: center; gap: 22px; text-decoration: none; color: inherit;
            border: 1px solid #e2e8f0; transition: all 0.2s;
        }
        .activity-card:hover { box-shadow: 0 8px 28px rgba(0,0,0,0.14); transform: translateY(-2px); border-color: #0f9b6c; }
        .activity-card .icon { font-size: 44px; }
        .activity-card .title { font-size: 18px; font-weight: 700; color: #1e293b; margin-bottom: 4px; }
        .activity-card .desc { font-size: 13px; color: #64748b; }

        /* Phase Completion Reports — same pattern as school-dashboard-enhanced.jsp */
        .section-title { font-size: 20px; margin-bottom: 4px; color: #0c7b54; }
        .section-hint { margin-bottom: 20px; color: #666; font-size: 13.5px; }
        .phase-reports { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; margin: 20px 0 30px; }
        .phase-card { background: #fff; border-radius: 15px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); border: 3px solid transparent; }
        .phase-card.clickable { cursor: pointer; transition: transform 0.2s, box-shadow 0.2s; }
        .phase-card.clickable:hover { transform: translateY(-4px); box-shadow: 0 8px 24px rgba(0,0,0,0.15); }
        .phase-card.complete { border-color: #4caf50; background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%); }
        .phase-card.in-progress { border-color: #ff9800; background: linear-gradient(135deg, #fff3e0 0%, #ffe0b2 100%); }
        .phase-card.not-started { border-color: #9e9e9e; background: linear-gradient(135deg, #f5f5f5 0%, #eeeeee 100%); }
        .phase-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding-bottom: 15px; border-bottom: 2px solid rgba(0,0,0,0.1); }
        .phase-title { font-size: 20px; font-weight: 700; color: #333; }
        .phase-icon { font-size: 32px; }
        .phase-progress { margin: 20px 0; }
        .progress-label { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 14px; color: #666; }
        .progress-bar-container { width: 100%; height: 25px; background: #e0e0e0; border-radius: 15px; overflow: hidden; box-shadow: inset 0 2px 4px rgba(0,0,0,0.1); }
        .progress-bar { height: 100%; background: linear-gradient(90deg, #0f9b6c 0%, #0c7b54 100%); border-radius: 15px; transition: width 0.5s ease; display: flex; align-items: center; justify-content: flex-end; padding-right: 8px; color: #fff; font-size: 12px; font-weight: 700; }
        .progress-bar.complete { background: linear-gradient(90deg, #4caf50 0%, #8bc34a 100%); }
        .progress-bar.in-progress { background: linear-gradient(90deg, #ff9800 0%, #ffc107 100%); }
        .phase-status { display: inline-block; padding: 8px 16px; border-radius: 20px; font-size: 13px; font-weight: 600; margin-top: 15px; }
        .phase-status.complete { background: #4caf50; color: #fff; }
        .phase-status.in-progress { background: #ff9800; color: #fff; }
        .phase-status.not-started { background: #9e9e9e; color: #fff; }
        .phase-status.pending-approval { background: #ff9800; color: #fff; }
        .phase-status.rejected { background: #f44336; color: #fff; }
        .btn-submit-phase { width: 100%; padding: 12px; margin-top: 15px; background: linear-gradient(135deg, #0f9b6c 0%, #0c7b54 100%); color: #fff; border: none; border-radius: 10px; font-size: 14px; font-weight: 700; cursor: pointer; transition: all 0.2s; }
        .btn-submit-phase:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(15,155,108,0.4); }
        .btn-submit-phase:disabled { opacity: 0.6; cursor: not-allowed; transform: none; box-shadow: none; }
        .progress-summary { margin-top: 10px; padding: 20px; background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%); border-radius: 10px; border-left: 5px solid #2196f3; }
        .progress-summary h3 { margin-bottom: 15px; color: #1976d2; }
        .progress-summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
        .progress-summary-item { text-align: center; }
        .progress-summary-value { font-size: 32px; font-weight: 700; }
        .progress-summary-label { color: #666; font-size: 14px; margin-top: 5px; }

        /* Phase student-list modal */
        .pmodal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.55); z-index: 1000; align-items: center; justify-content: center; padding: 20px; }
        .pmodal-overlay.show { display: flex; }
        .pmodal-box { background: #fff; border-radius: 14px; width: 100%; max-width: 720px; max-height: 85vh; display: flex; flex-direction: column; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
        .pmodal-header { background: linear-gradient(135deg, #0f9b6c 0%, #0c7b54 100%); color: #fff; padding: 18px 24px; border-radius: 14px 14px 0 0; display: flex; justify-content: space-between; align-items: center; }
        .pmodal-header h3 { font-size: 17px; font-weight: 700; }
        .pmodal-close { background: none; border: none; color: #fff; font-size: 26px; line-height: 1; cursor: pointer; }
        .pmodal-body { padding: 18px 24px; overflow-y: auto; }
        .pmodal-search { width: 100%; padding: 9px 12px; border: 1px solid #cbd5e1; border-radius: 7px; font-size: 13px; margin-bottom: 14px; }
        .pmodal-count { font-size: 12.5px; color: #64748b; margin-bottom: 10px; }
        .pmodal-body table { width: 100%; border-collapse: collapse; }
        .pmodal-body th, .pmodal-body td { padding: 8px 10px; text-align: left; border-bottom: 1px solid #e2e8f0; font-size: 13px; }
        .pmodal-body th { background: #f8fafc; color: #475569; position: sticky; top: 0; }
        .pmodal-empty { text-align: center; padding: 40px 20px; color: #94a3b8; }
        .level-chip { padding: 3px 9px; border-radius: 20px; font-size: 11px; font-weight: 700; background: #ecfdf5; color: #0c7b54; }
        .pager { display: flex; gap: 6px; justify-content: center; align-items: center; flex-wrap: wrap; margin-top: 14px; }
        .pager button { padding: 6px 11px; border: 1px solid #cbd5e1; border-radius: 6px; background: #fff; font-size: 12.5px; cursor: pointer; }
        .pager button:hover:not(:disabled) { background: #ecfdf5; border-color: #0f9b6c; }
        .pager button.active { background: #0f9b6c; color: #fff; border-color: #0f9b6c; }
        .pager button:disabled { opacity: 0.4; cursor: not-allowed; }
        .pager .pager-info { font-size: 12px; color: #64748b; margin: 0 6px; }
    </style>
</head>
<body>
    <div class="topbar">
        <div class="brand">🔬 विज्ञानसेतू</div>
        <div class="topbar-actions">
            <span class="who"><%= vsUser.getFullName() != null ? vsUser.getFullName() : vsUser.getUsername() %> · UDISE <%= vsUser.getUdiseNo() %></span>
            <a class="topbar-btn" href="<%= request.getContextPath() %>/vidnyansetu-manage-teachers.jsp">👩‍🏫 Manage Teachers</a>
            <a class="topbar-btn" href="<%= request.getContextPath() %>/vidnyansetu-change-password.jsp">🔐 Change Password</a>
            <a class="topbar-btn" href="<%= request.getContextPath() %>/logout">🚪 Logout</a>
        </div>
    </div>

    <div class="wrap">
        <div class="school-header">
            <div class="school-icon">🏫</div>
            <h1><%= schoolName %></h1>
            <div class="header-subtitle">UDISE: <%= vsUser.getUdiseNo() %> | VidnyanSetu School Coordinator</div>
        </div>

        <div class="breadcrumb">
            <span>🏫 School:</span> <strong><%= schoolName %></strong> (<%= vsUser.getUdiseNo() %>)
        </div>

        <div class="dashboard-grid">
            <div class="stat-card">
                <div class="stat-icon">👥</div>
                <div class="stat-value"><%= totalStudents %></div>
                <div class="stat-label">Total Students</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">📚</div>
                <div class="stat-value"><%= distinctClasses.size() %></div>
                <div class="stat-label">Classes</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">📋</div>
                <div class="stat-value"><%= distinctSections.size() %></div>
                <div class="stat-label">Sections</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">👩‍🏫</div>
                <div class="stat-value"><%= teacherCount %></div>
                <div class="stat-label">VidnyanSetu Teachers</div>
            </div>
        </div>

        <h2>Activities</h2>
        <div class="activity-grid">
            <%-- <a class="activity-card" href="<%= request.getContextPath() %>/vidnyansetu-activity.jsp">
                <div class="icon">🔬</div>
                <div>
                    <div class="title">VidnyanSetu Activity</div>
                    <div class="desc">Log student science activities against the curriculum (Class → Week → Day) with a video, for Head Master approval.</div>
                </div>
            </a> --%>
            <a class="activity-card" href="<%= request.getContextPath() %>/vidnyansetu-manage-students.jsp">
                <div class="icon">👨‍🎓</div>
                <div>
                    <div class="title">Manage Students</div>
                    <div class="desc">View विज्ञान phase progress across all your school's VidnyanSetu teachers and submit a phase for Head Master approval.</div>
                </div>
            </a>
        </div>

        <div id="msgBox" style="margin-top:24px;"></div>

        <h2 class="section-title" style="margin-top:30px;">📈 चरण अहवाल (Phase Completion Reports)</h2>
        <p class="section-hint">Track the progress of each विज्ञान phase for your school</p>

        <div class="phase-reports">
            <% for (int p = 1; p <= 4; p++) {
                String cardClass = phaseApproved[p] ? "complete" : (phaseComplete[p] ? "complete" : (phaseCompletion[p] > 0 ? "in-progress" : "not-started"));
                String barClass  = phaseApproved[p] ? "complete" : (phaseComplete[p] ? "complete" : (phaseCompletion[p] > 0 ? "in-progress" : ""));
                String icon = phaseApproved[p] ? "✅" : (phaseComplete[p] ? "✓" : (phaseCompletion[p] > 0 ? "⏳" : "🔒"));
            %>
            <div class="phase-card clickable <%= cardClass %>" onclick="showPhaseStudents(<%= p %>, event)">
                <div class="phase-header">
                    <div class="phase-title">चरण <%= p %> (Phase <%= p %>)</div>
                    <div class="phase-icon"><%= icon %></div>
                </div>
                <div class="phase-progress">
                    <div class="progress-label"><span>Progress</span><span><strong><%= phaseCompletion[p] %>%</strong></span></div>
                    <div class="progress-bar-container">
                        <div class="progress-bar <%= barClass %>" style="width: <%= phaseCompletion[p] %>%;">
                            <%= phaseCompletion[p] > 10 ? phaseCompletion[p] + "%" : "" %>
                        </div>
                    </div>
                </div>

                <% if (phasePending[p]) { %>
                    <div class="phase-status pending-approval">⏳ Pending Approval</div>
                <% } else if (phaseApproved[p]) { %>
                    <div class="phase-status complete">✅ Approved by Head Master</div>
                <% } else if (phaseRejected[p]) { %>
                    <div class="phase-status rejected">✗ Rejected — Resubmit Required</div>
                <% } else if (phaseCompletion[p] > 0) { %>
                    <div class="phase-status in-progress">⏳ In Progress (<%= phaseCompletion[p] %>%)</div>
                <% } else { %>
                    <div class="phase-status not-started">🔒 Not Started</div>
                <% } %>

                <% boolean canSubmit = (p == 1 || phaseApproved[p - 1]) && (!phaseComplete[p] || phaseRejected[p]); %>
                <button class="btn-submit-phase" <%= canSubmit ? "" : "disabled" %> onclick="event.stopPropagation(); submitPhaseForApproval(<%= p %>);">
                    📤 Submit for Approval
                </button>
            </div>
            <% } %>
        </div>

        <div class="progress-summary">
            <h3>📊 Overall Progress Summary</h3>
            <div class="progress-summary-grid">
                <div class="progress-summary-item">
                    <div class="progress-summary-value" style="color:#4caf50;">
                        <%= (phaseComplete[1]?1:0) + (phaseComplete[2]?1:0) + (phaseComplete[3]?1:0) + (phaseComplete[4]?1:0) %>
                    </div>
                    <div class="progress-summary-label">Phases Completed</div>
                </div>
                <div class="progress-summary-item">
                    <div class="progress-summary-value" style="color:#ff9800;">
                        <%= (phaseCompletion[1] + phaseCompletion[2] + phaseCompletion[3] + phaseCompletion[4]) / 4 %>%
                    </div>
                    <div class="progress-summary-label">Average Progress</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Phase student-list modal -->
    <div id="pmodalOverlay" class="pmodal-overlay" onclick="if (event.target === this) closePhaseModal()">
        <div class="pmodal-box">
            <div class="pmodal-header">
                <h3 id="pmodalTitle">Phase students</h3>
                <button type="button" class="pmodal-close" onclick="closePhaseModal()" aria-label="Close">&times;</button>
            </div>
            <div class="pmodal-body">
                <input type="text" id="pmodalSearch" class="pmodal-search" placeholder="Search by name, PEN or class..." oninput="filterPhaseModal()" style="display:none;">
                <div id="pmodalCount" class="pmodal-count"></div>
                <div id="pmodalContent"><div class="pmodal-empty">⏳ Loading...</div></div>
                <div class="pager" id="pmodalPager"></div>
            </div>
        </div>
    </div>

<script>
var ctx = '<%= request.getContextPath() %>';
var pmodalStudents = [];
var pmodalPage = 1;
var PMODAL_PAGE_SIZE = 10;
var levelLabels = ["स्तर निश्चित केला नाही", "प्रारंभिक", "विकसनशिल", "विकसीत", "प्रगत"];

function showPhaseStudents(phaseNumber, event) {
    if (event && event.target && event.target.tagName === 'BUTTON') return;

    document.getElementById('pmodalTitle').textContent = 'चरण ' + phaseNumber + ' — स्तर नोंदवलेले विद्यार्थी (Phase ' + phaseNumber + ' Students)';
    document.getElementById('pmodalOverlay').classList.add('show');
    document.getElementById('pmodalSearch').style.display = 'none';
    document.getElementById('pmodalSearch').value = '';
    document.getElementById('pmodalCount').textContent = '';
    document.getElementById('pmodalContent').innerHTML = '<div class="pmodal-empty">⏳ Loading...</div>';
    document.getElementById('pmodalPager').innerHTML = '';
    pmodalPage = 1;

    fetch(ctx + '/vidnyansetu-phase-students?phase=' + phaseNumber)
        .then(function(r) { return r.json(); })
        .then(function(data) {
            pmodalStudents = data;
            if (!data.length) {
                document.getElementById('pmodalContent').innerHTML =
                    '<div class="pmodal-empty">No students have a Phase ' + phaseNumber + ' level recorded yet.</div>';
                return;
            }
            document.getElementById('pmodalSearch').style.display = 'block';
            renderPhaseModal(data);
        })
        .catch(function() {
            document.getElementById('pmodalContent').innerHTML = '<div class="pmodal-empty">Failed to load. Please try again.</div>';
        });
}

function renderPhaseModal(list) {
    document.getElementById('pmodalCount').textContent = list.length + ' student' + (list.length === 1 ? '' : 's');

    var totalPages = Math.max(1, Math.ceil(list.length / PMODAL_PAGE_SIZE));
    if (pmodalPage > totalPages) pmodalPage = totalPages;
    var start = (pmodalPage - 1) * PMODAL_PAGE_SIZE;
    var pageList = list.slice(start, start + PMODAL_PAGE_SIZE);

    var rows = pageList.map(function(s, idx) {
        return '<tr><td>' + (start + idx + 1) + '</td><td>' + esc(s.pen) + '</td><td>' + esc(s.name) + '</td><td>' + esc(s.class) + '-' + esc(s.section) + '</td>' +
               '<td><span class="level-chip">' + esc(levelLabels[s.level] || s.level) + '</span></td></tr>';
    }).join('');
    document.getElementById('pmodalContent').innerHTML = !pageList.length
        ? '<div class="pmodal-empty">No matching students.</div>'
        : '<table><thead><tr><th>#</th><th>PEN</th><th>Name</th><th>Class-Section</th><th>विज्ञान स्तर</th></tr></thead><tbody>' + rows + '</tbody></table>';

    renderPmodalPager(list.length, totalPages);
}

function renderPmodalPager(totalMatched, totalPages) {
    var pager = document.getElementById('pmodalPager');
    if (totalMatched === 0) { pager.innerHTML = ''; return; }

    var html = '';
    html += '<button ' + (pmodalPage === 1 ? 'disabled' : '') + ' onclick="goToPmodalPage(' + (pmodalPage - 1) + ')">‹ Prev</button>';

    var start = Math.max(1, pmodalPage - 2);
    var end = Math.min(totalPages, start + 4);
    start = Math.max(1, end - 4);
    for (var p = start; p <= end; p++) {
        html += '<button class="' + (p === pmodalPage ? 'active' : '') + '" onclick="goToPmodalPage(' + p + ')">' + p + '</button>';
    }

    html += '<button ' + (pmodalPage === totalPages ? 'disabled' : '') + ' onclick="goToPmodalPage(' + (pmodalPage + 1) + ')">Next ›</button>';
    html += '<span class="pager-info">Page ' + pmodalPage + ' of ' + totalPages + '</span>';
    pager.innerHTML = html;
}

function goToPmodalPage(p) {
    pmodalPage = p;
    renderPhaseModal(currentPmodalFiltered());
}

function currentPmodalFiltered() {
    var q = document.getElementById('pmodalSearch').value.trim().toLowerCase();
    return !q ? pmodalStudents : pmodalStudents.filter(function(s) {
        return (s.name && s.name.toLowerCase().indexOf(q) !== -1) ||
               (s.pen && s.pen.toLowerCase().indexOf(q) !== -1) ||
               (s.class && s.class.toLowerCase().indexOf(q) !== -1);
    });
}

function filterPhaseModal() {
    pmodalPage = 1;
    renderPhaseModal(currentPmodalFiltered());
}

function closePhaseModal() {
    document.getElementById('pmodalOverlay').classList.remove('show');
}

function esc(s) {
    var d = document.createElement('div');
    d.textContent = s == null ? '' : String(s);
    return d.innerHTML;
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closePhaseModal();
});

function showMsg(ok, text) {
    document.getElementById('msgBox').innerHTML =
        '<div style="padding:10px 14px;border-radius:7px;font-size:13px;font-weight:500;background:' +
        (ok ? '#d1fae5;color:#065f46' : '#fee2e2;color:#991b1b') + ';">' + text + '</div>';
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

function submitPhaseForApproval(phaseNumber) {
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
