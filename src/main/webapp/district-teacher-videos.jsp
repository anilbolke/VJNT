<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.vjnt.util.DatabaseConnection" %>
<%@ page import="java.util.*" %>
<%!
    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }

    /** True if the given subject text mentions any of the 3 FLN subjects (Marathi/English/Math), either spelling. */
    private static boolean hasFlnSubject(String subjectsText) {
        if (subjectsText == null) return false;
        String s = subjectsText.toLowerCase();
        return s.contains("मराठी") || s.contains("marathi")
            || s.contains("इंग्रजी") || s.contains("इंग्लिश") || s.contains("english")
            || s.contains("गणित") || s.contains("math");
    }
%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR)
                      && !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String districtName = user.getDistrictName();

    List<Map<String, Object>> teachers = new ArrayList<>();
    int teachersWithData = 0;
    int pendingApprovalCount = 0;
    String errorMessage = null;

    try (Connection conn = DatabaseConnection.getConnection()) {

        // District-wide count of phase videos still awaiting Head Master approval.
        String pendSql =
            "SELECT COUNT(*) FROM student_videos v " +
            "JOIN schools s ON v.udise_no COLLATE utf8mb4_unicode_ci = s.udise_no COLLATE utf8mb4_unicode_ci " +
            "WHERE s.district_name = ? AND v.phase_number IS NOT NULL AND v.is_active = 1 " +
            "  AND v.approval_status = 'PENDING'";
        try (PreparedStatement ps = conn.prepareStatement(pendSql)) {
            ps.setString(1, districtName);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) pendingApprovalCount = rs.getInt(1);
            }
        }
        String sql =
            "SELECT ta.teacher_id, ta.teacher_name, " +
            "       MIN(s.school_name) AS school_name, " +
            "       GROUP_CONCAT(DISTINCT ta.udise_code) AS udise_codes, " +
            "       MAX(t.mobile_number) AS mobile_number, " +
            "       MAX(t.subjects_taught) AS subjects_taught, " +
            "       GROUP_CONCAT(DISTINCT ta.subjects_assigned SEPARATOR ',') AS subjects_assigned_all, " +
            "       COALESCE(mm.mapped_count, 0) AS mapped_count, " +
            "       COALESCE(pp.pending_count, 0) AS pending_count " +
            "FROM teacher_assignments ta " +
            "LEFT JOIN schools s ON ta.udise_code COLLATE utf8mb4_unicode_ci = s.udise_no COLLATE utf8mb4_unicode_ci " +
            "LEFT JOIN teachers t ON t.teacher_id = ta.teacher_id " +
            "LEFT JOIN ( SELECT teacher_id, COUNT(DISTINCT student_id) AS mapped_count " +
            "            FROM teacher_student_mapping WHERE is_active = 1 GROUP BY teacher_id ) mm " +
            "       ON mm.teacher_id = ta.teacher_id " +
            "LEFT JOIN ( SELECT m.teacher_id, COUNT(*) AS pending_count " +
            "            FROM teacher_student_mapping m " +
            "            JOIN student_videos v ON v.student_id = m.student_id " +
            "                 AND v.phase_number IS NOT NULL AND v.is_active = 1 " +
            "                 AND v.approval_status = 'PENDING' " +
            "            WHERE m.is_active = 1 GROUP BY m.teacher_id ) pp " +
            "       ON pp.teacher_id = ta.teacher_id " +
            "WHERE ta.is_active = 1 AND ta.district = ? " +
            "GROUP BY ta.teacher_id, ta.teacher_name, mm.mapped_count, pp.pending_count " +
            "ORDER BY school_name, ta.teacher_name";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, districtName);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    // Only teachers who teach at least one FLN subject (मराठी / इंग्रजी / गणित).
                    String subjAssigned = rs.getString("subjects_assigned_all");
                    String subjTaught = rs.getString("subjects_taught");
                    if (!hasFlnSubject(subjAssigned) && !hasFlnSubject(subjTaught)) continue;

                    Map<String, Object> t = new HashMap<>();
                    t.put("id", rs.getInt("teacher_id"));
                    t.put("name", rs.getString("teacher_name"));
                    t.put("school", rs.getString("school_name"));
                    t.put("udise", rs.getString("udise_codes"));
                    t.put("mobile", rs.getString("mobile_number"));
                    t.put("subjects", rs.getString("subjects_taught"));
                    int mapped = rs.getInt("mapped_count");
                    t.put("mapped", mapped);
                    t.put("pending", rs.getInt("pending_count"));
                    if (mapped > 0) teachersWithData++;
                    teachers.add(t);
                }
            }
        }
    } catch (Exception e) {
        errorMessage = e.getMessage();
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="mr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>शिक्षक विद्यार्थी व्हिडिओ (Teacher Student Videos) - <%= esc(districtName) %></title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f0f2f5; color: #1e293b; padding: 24px; }
        .container { max-width: 1280px; margin: 0 auto; background: #fff; border-radius: 14px; box-shadow: 0 10px 30px rgba(0,0,0,.1); overflow: hidden; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #fff; padding: 28px 30px; }
        .header h1 { font-size: 22px; font-weight: 800; margin-bottom: 6px; }
        .header p { font-size: 14px; opacity: .9; }
        .header-pending { display: inline-block; margin-top: 12px; background: rgba(255,255,255,.18); border: 1px solid rgba(255,255,255,.35); border-radius: 999px; padding: 6px 14px; font-size: 13px; }
        .header-pending strong { font-size: 15px; background: #fde68a; color: #7c2d12; border-radius: 999px; padding: 1px 9px; margin-left: 4px; }
        .back-link { display: inline-block; color: #fff; text-decoration: none; font-size: 13px; margin-bottom: 14px; opacity: .9; }
        .back-link:hover { opacity: 1; text-decoration: underline; }
        .content { padding: 24px 30px 40px; }

        .stats { display: flex; gap: 14px; flex-wrap: wrap; margin-bottom: 20px; }
        .stat { flex: 1; min-width: 150px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 14px 18px; }
        .stat .n { font-size: 26px; font-weight: 800; }
        .stat .l { font-size: 12px; color: #64748b; text-transform: uppercase; letter-spacing: .5px; margin-top: 2px; }
        .stat.data .n { color: #059669; }
        .stat.pend .n { color: #b45309; }

        .toolbar { display: flex; gap: 12px; flex-wrap: wrap; margin-bottom: 16px; align-items: center; }
        .toolbar input, .toolbar select { padding: 9px 12px; border: 2px solid #e2e8f0; border-radius: 8px; font-size: 13px; font-family: inherit; outline: none; background: #fff; }
        .toolbar input:focus, .toolbar select:focus { border-color: #667eea; }
        .toolbar input[type=text] { flex: 1; min-width: 220px; }
        .pill.pend { background: #fef3c7; color: #92400e; margin-left: 4px; }

        table { width: 100%; border-collapse: collapse; font-size: 13px; }
        thead th { background: #667eea; color: #fff; text-align: left; padding: 10px 12px; white-space: nowrap; position: sticky; top: 0; }
        tbody td { padding: 9px 12px; border-bottom: 1px solid #eef2f7; vertical-align: middle; }
        tbody tr:hover { background: #f5f7ff; }
        .subject-tag { display: inline-block; background: #eef2ff; color: #3730a3; border-radius: 8px; padding: 2px 8px; font-size: 11px; margin: 1px 2px; }
        .pill { display: inline-block; border-radius: 999px; padding: 2px 10px; font-size: 11px; font-weight: 700; }
        .pill.has { background: #dcfce7; color: #166534; }
        .pill.none { background: #f1f5f9; color: #64748b; }
        .view-btn { background: #667eea; color: #fff; border: none; padding: 7px 16px; border-radius: 8px; font-size: 12px; font-weight: 700; cursor: pointer; white-space: nowrap; }
        .view-btn:hover { background: #5568d3; }

        /* Pagination */
        .pager { display: flex; gap: 6px; align-items: center; flex-wrap: wrap; margin-top: 14px; font-size: 13px; }
        .pager button { border: 1px solid #cbd5e1; background: #fff; border-radius: 7px; padding: 6px 11px; font-size: 12px; font-weight: 700; cursor: pointer; color: #334155; }
        .pager button:hover:not(:disabled) { background: #eef2ff; border-color: #667eea; }
        .pager button:disabled { opacity: .45; cursor: default; }
        .pager button.active { background: #667eea; border-color: #667eea; color: #fff; }
        .pager .info { color: #64748b; margin-left: auto; }

        .empty { text-align: center; padding: 50px 20px; color: #94a3b8; }
        .err-box { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; border-radius: 8px; padding: 12px 16px; font-size: 13px; margin-bottom: 16px; }

        /* Teacher students popup */
        .panel-head { display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 10px; margin-bottom: 16px; padding-bottom: 12px; border-bottom: 2px solid #e2e8f0; }
        .panel-head h2 { font-size: 18px; }
        .panel-head .sub { font-size: 13px; color: #64748b; margin-top: 2px; }
        .close-panel { background: #e2e8f0; border: none; border-radius: 8px; padding: 7px 14px; font-size: 12px; font-weight: 700; cursor: pointer; }
        #videosBody { overflow-y: auto; flex: 1; }

        .subject-block { margin-bottom: 26px; }
        .subject-block h3 { font-size: 15px; color: #4338ca; border-bottom: 2px solid #c7d2fe; padding-bottom: 6px; margin-bottom: 14px; }
        .student-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 12px; }
        .student-card { border: 1px solid #e2e8f0; border-radius: 10px; padding: 12px 14px; background: #fbfcfe; cursor: pointer; transition: box-shadow .15s, border-color .15s; }
        .student-card:hover { border-color: #667eea; box-shadow: 0 4px 12px rgba(102,126,234,.18); }
        .student-card .sname { font-size: 14px; font-weight: 800; }
        .student-card .smeta { font-size: 12px; color: #64748b; margin: 2px 0 9px; }
        .phase-dots { display: flex; gap: 5px; flex-wrap: wrap; }
        .pdot { font-size: 10px; font-weight: 800; border-radius: 5px; padding: 2px 6px; border: 1px solid transparent; }
        .pdot.APPROVED { background: #dcfce7; color: #166534; }
        .pdot.PENDING  { background: #fef9c3; color: #854d0e; }
        .pdot.REJECTED { background: #fee2e2; color: #991b1b; }
        .pdot.NONE     { background: #f1f5f9; color: #94a3b8; }
        .card-hint { font-size: 11px; color: #94a3b8; margin-top: 8px; }

        /* Modal */
        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(15,23,42,.75); z-index: 1000; align-items: flex-start; justify-content: center; padding: 40px 20px; overflow-y: auto; }
        .modal-overlay.open { display: flex; }
        #studentModal { z-index: 1100; }
        .modal-box { background: #fff; border-radius: 12px; max-width: 560px; width: 100%; padding: 22px 24px; }
        .modal-box.wide { max-width: 1040px; max-height: 85vh; display: flex; flex-direction: column; }
        .modal-box .m-title { font-size: 18px; font-weight: 800; }
        .modal-box .m-meta { font-size: 13px; color: #64748b; margin-top: 3px; }
        .modal-close { float: right; background: #e2e8f0; border: none; border-radius: 8px; width: 30px; height: 30px; font-size: 16px; cursor: pointer; }
        .phase-list { margin-top: 18px; }
        .phase-item { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; padding: 11px 0; border-bottom: 1px solid #eef2f7; }
        .phase-item:last-child { border-bottom: none; }
        .phase-item .pname { font-weight: 700; font-size: 13px; }
        .phase-item .pdate { font-size: 11px; color: #94a3b8; margin-top: 2px; }
        .phase-item .preason { font-size: 11px; color: #b91c1c; margin-top: 3px; }
        .status-badge { display: inline-block; border-radius: 7px; padding: 3px 10px; font-size: 11px; font-weight: 800; white-space: nowrap; }
        .status-badge.APPROVED { background: #dcfce7; color: #166534; }
        .status-badge.PENDING  { background: #fef9c3; color: #854d0e; }
        .status-badge.REJECTED { background: #fee2e2; color: #991b1b; }
        .status-badge.NONE     { background: #f1f5f9; color: #64748b; }
        .loading { text-align: center; padding: 30px; color: #64748b; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <a href="<%= request.getContextPath() %>/district-dashboard.jsp" class="back-link">← Back to Dashboard</a>
            <h1>📹 शिक्षक विद्यार्थी व्हिडिओ (Teacher Student Videos)</h1>
            <p><%= esc(districtName) %> District — शिक्षक निवडा; त्या शिक्षकाच्या विद्यार्थ्यांवर क्लिक करून विषयनिहाय टप्पा-व्हिडिओची स्थिती पहा.</p>
            <div class="header-pending">
                ⏳ मुख्याध्यापक मंजुरीसाठी प्रलंबित व्हिडिओ (Pending HM approval):
                <strong><%= pendingApprovalCount %></strong>
            </div>
        </div>

        <div class="content">
            <% if (errorMessage != null) { %>
                <div class="err-box">⚠️ Could not load teachers: <%= esc(errorMessage) %></div>
            <% } %>

            <div class="stats">
                <div class="stat"><div class="n"><%= teachers.size() %></div><div class="l">Total Teachers</div></div>
                <div class="stat data"><div class="n"><%= teachersWithData %></div><div class="l">Teachers With Student Data</div></div>
                <div class="stat pend"><div class="n"><%= pendingApprovalCount %></div><div class="l">Videos Pending HM Approval</div></div>
            </div>

            <% if (teachers.isEmpty() && errorMessage == null) { %>
                <div class="empty">No active teachers found in this district.</div>
            <% } else if (!teachers.isEmpty()) { %>
                <div class="toolbar">
                    <input type="text" id="searchBox" placeholder="🔍 Search by teacher, school, mobile or UDISE...">
                    <select id="pendingFilter">
                        <option value="">Pending approval: All</option>
                        <option value="has">Has pending videos</option>
                        <option value="none">No pending videos</option>
                    </select>
                </div>

                <div style="overflow-x:auto;">
                <table id="teacherTable">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>School</th>
                            <th>Teacher</th>
                            <th>Mobile</th>
                            <th>Subjects</th>
                            <th>Students</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        <% int sr = 0; for (Map<String, Object> t : teachers) { sr++;
                            String subjectsStr = (String) t.get("subjects");
                            String[] subs = (subjectsStr == null ? "" : subjectsStr).split(",");
                            int mapped = (Integer) t.get("mapped");
                            int pending = (Integer) t.get("pending");
                        %>
                        <tr data-pending="<%= pending %>" data-search="<%= esc((String.valueOf(t.get("name")) + " " + String.valueOf(t.get("school")) + " " + String.valueOf(t.get("mobile")) + " " + String.valueOf(t.get("udise"))).toLowerCase()) %>">
                            <td class="sr"><%= sr %></td>
                            <td><strong><%= esc((String) t.get("school")) %></strong><br><span style="color:#94a3b8;font-size:11px;"><%= esc((String) t.get("udise")) %></span></td>
                            <td><strong><%= esc((String) t.get("name")) %></strong></td>
                            <td><%= esc((String) t.get("mobile")) %></td>
                            <td>
                                <% for (String s : subs) { if (s.trim().isEmpty() || !hasFlnSubject(s)) continue; %>
                                    <span class="subject-tag"><%= esc(s.trim()) %></span>
                                <% } %>
                            </td>
                            <td>
                                <% if (mapped > 0) { %>
                                    <span class="pill has"><%= mapped %> students</span>
                                <% } else { %>
                                    <span class="pill none">no data yet</span>
                                <% } %>
                                <% if (pending > 0) { %>
                                    <span class="pill pend">⏳ <%= pending %> pending</span>
                                <% } %>
                            </td>
                            <td>
                                <button class="view-btn" data-tid="<%= t.get("id") %>" data-tname="<%= esc((String) t.get("name")) %>">View</button>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
                </div>

                <div class="pager" id="pager"></div>
            <% } %>
        </div>
    </div>

    <!-- Teacher's students popup -->
    <div class="modal-overlay" id="teacherModal">
        <div class="modal-box wide">
            <div class="panel-head">
                <div>
                    <h2 id="panelTitle">Students</h2>
                    <div class="sub" id="panelSub"></div>
                </div>
                <button class="close-panel" onclick="closeVideosPanel()">✕ Close</button>
            </div>
            <div id="videosBody"></div>
        </div>
    </div>

    <!-- Student detail popup (statuses only, no video) -->
    <div class="modal-overlay" id="studentModal">
        <div class="modal-box">
            <button class="modal-close" onclick="closeStudentModal()">&times;</button>
            <div class="m-title" id="smName">Student</div>
            <div class="m-meta" id="smMeta"></div>
            <div class="phase-list" id="smPhases"></div>
        </div>
    </div>

    <script>
        var CTX = '<%= request.getContextPath() %>';
        var PAGE_SIZE = 25;
        var currentPage = 1;
        var currentData = null;          // last loaded teacher payload
        var studentIndex = {};           // studentId -> { subject, student }

        function escHtml(s) {
            return String(s == null ? '' : s)
                .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
        }

        /* ================= Teacher list: search + pagination ================= */
        var allRows = Array.prototype.slice.call(document.querySelectorAll('#teacherTable tbody tr'));

        function filteredRows() {
            var q = (document.getElementById('searchBox').value || '').toLowerCase().trim();
            var pf = document.getElementById('pendingFilter').value;
            return allRows.filter(function (r) {
                if (q && r.getAttribute('data-search').indexOf(q) === -1) return false;
                var pend = parseInt(r.getAttribute('data-pending'), 10) || 0;
                if (pf === 'has' && pend <= 0) return false;
                if (pf === 'none' && pend > 0) return false;
                return true;
            });
        }

        function renderPage() {
            var rows = filteredRows();
            var totalPages = Math.max(1, Math.ceil(rows.length / PAGE_SIZE));
            if (currentPage > totalPages) currentPage = totalPages;
            var start = (currentPage - 1) * PAGE_SIZE;
            var end = start + PAGE_SIZE;

            allRows.forEach(function (r) { r.style.display = 'none'; });
            rows.slice(start, end).forEach(function (r, i) {
                r.style.display = '';
                var srCell = r.querySelector('.sr');
                if (srCell) srCell.textContent = start + i + 1;
            });

            renderPager(rows.length, totalPages);
        }

        function renderPager(totalRows, totalPages) {
            var pager = document.getElementById('pager');
            if (!pager) return;
            if (totalRows === 0) { pager.innerHTML = '<span class="info">No matching teachers.</span>'; return; }

            var html = '';
            html += '<button ' + (currentPage === 1 ? 'disabled' : '') + ' data-go="1">« First</button>';
            html += '<button ' + (currentPage === 1 ? 'disabled' : '') + ' data-go="' + (currentPage - 1) + '">‹ Prev</button>';

            var from = Math.max(1, currentPage - 2);
            var to = Math.min(totalPages, from + 4);
            from = Math.max(1, to - 4);
            for (var p = from; p <= to; p++) {
                html += '<button class="' + (p === currentPage ? 'active' : '') + '" data-go="' + p + '">' + p + '</button>';
            }

            html += '<button ' + (currentPage === totalPages ? 'disabled' : '') + ' data-go="' + (currentPage + 1) + '">Next ›</button>';
            html += '<button ' + (currentPage === totalPages ? 'disabled' : '') + ' data-go="' + totalPages + '">Last »</button>';

            var s = (currentPage - 1) * PAGE_SIZE + 1;
            var e = Math.min(totalRows, currentPage * PAGE_SIZE);
            html += '<span class="info">' + s + '–' + e + ' of ' + totalRows + ' teachers</span>';
            pager.innerHTML = html;

            pager.querySelectorAll('button[data-go]').forEach(function (b) {
                b.addEventListener('click', function () {
                    var go = parseInt(this.getAttribute('data-go'), 10);
                    if (!isNaN(go) && go >= 1 && go <= totalPages) { currentPage = go; renderPage(); }
                });
            });
        }

        var sb = document.getElementById('searchBox');
        if (sb) sb.addEventListener('input', function () { currentPage = 1; renderPage(); });

        var pf = document.getElementById('pendingFilter');
        if (pf) pf.addEventListener('change', function () { currentPage = 1; renderPage(); });

        document.querySelectorAll('.view-btn').forEach(function (btn) {
            btn.addEventListener('click', function () {
                loadTeacherVideos(this.getAttribute('data-tid'), this.getAttribute('data-tname'));
            });
        });

        renderPage();

        /* ================= Load a teacher's students ================= */
        function loadTeacherVideos(teacherId, teacherName) {
            var body = document.getElementById('videosBody');
            document.getElementById('panelTitle').textContent = '👨‍🏫 ' + teacherName;
            document.getElementById('panelSub').textContent = '';
            body.innerHTML = '<div class="loading">⏳ Loading students...</div>';
            document.getElementById('teacherModal').classList.add('open');
            body.scrollTop = 0;

            fetch(CTX + '/district-teacher-videos?teacherId=' + encodeURIComponent(teacherId))
                .then(function (r) { return r.json(); })
                .then(function (res) {
                    if (!res.success) {
                        body.innerHTML = '<div class="err-box">' + escHtml(res.message || 'Failed to load.') + '</div>';
                        return;
                    }
                    currentData = res;
                    render(res);
                })
                .catch(function () {
                    body.innerHTML = '<div class="err-box">Network error while loading students.</div>';
                });
        }

        function phaseMap(stu) {
            var m = {};
            (stu.videos || []).forEach(function (v) { m[v.phase] = v; });
            return m;
        }

        function render(res) {
            var body = document.getElementById('videosBody');
            document.getElementById('panelSub').textContent =
                (res.schoolName ? res.schoolName + ' · ' : '') +
                res.totalStudents + ' students · ' + res.totalVideos + ' phase videos';

            studentIndex = {};
            var subjects = res.subjects || [];
            if (!subjects.length) {
                body.innerHTML = '<div class="empty">या शिक्षकाच्या विद्यार्थ्यांची यादी अद्याप तयार झालेली नाही.<br>' +
                    'शिक्षकाने एकदा त्यांच्या लॉगिनमध्ये प्रवेश केल्यानंतर विद्यार्थी येथे दिसतील.<br>' +
                    '<span style="font-size:12px;">(Student list is created the first time the teacher logs in.)</span></div>';
                return;
            }

            var html = '';
            subjects.forEach(function (subj) {
                html += '<div class="subject-block">';
                html += '<h3>📚 ' + escHtml(subj.subject) + ' <span style="font-weight:500;color:#64748b;">(' + subj.studentCount + ' students)</span></h3>';
                html += '<div class="student-grid">';
                (subj.students || []).forEach(function (stu) {
                    studentIndex[stu.studentId] = { subject: subj.subject, student: stu };
                    var pm = phaseMap(stu);
                    var meta = [];
                    if (stu['class'] || stu.section) meta.push(escHtml((stu['class'] || '') + (stu.section ? ' - ' + stu.section : '')));
                    if (stu.pen) meta.push('PEN: ' + escHtml(stu.pen));

                    html += '<div class="student-card" data-sid="' + stu.studentId + '">';
                    html += '<div class="sname">' + escHtml(stu.name) + '</div>';
                    html += '<div class="smeta">' + meta.join(' &nbsp;|&nbsp; ') + '</div>';
                    html += '<div class="phase-dots">';
                    for (var p = 1; p <= 4; p++) {
                        var st = pm[p] ? (pm[p].status || 'PENDING') : 'NONE';
                        html += '<span class="pdot ' + st + '">P' + p + '</span>';
                    }
                    html += '</div>';
                    html += '<div class="card-hint">Click for status details →</div>';
                    html += '</div>';
                });
                html += '</div></div>';
            });
            body.innerHTML = html;

            body.querySelectorAll('.student-card').forEach(function (card) {
                card.addEventListener('click', function () {
                    openStudentModal(this.getAttribute('data-sid'));
                });
            });
        }

        function closeVideosPanel() {
            document.getElementById('teacherModal').classList.remove('open');
        }

        document.getElementById('teacherModal').addEventListener('click', function (e) {
            if (e.target === this) closeVideosPanel();
        });

        /* ================= Student popup (statuses only) ================= */
        function statusLabel(st) {
            if (st === 'APPROVED') return 'Approved';
            if (st === 'PENDING')  return 'Pending HM review';
            if (st === 'REJECTED') return 'Rejected';
            return 'Not uploaded';
        }

        function openStudentModal(sid) {
            var entry = studentIndex[sid];
            if (!entry) return;
            var stu = entry.student;
            var pm = phaseMap(stu);

            document.getElementById('smName').textContent = stu.name || 'Student';
            var meta = [];
            if (stu['class'] || stu.section) meta.push((stu['class'] || '') + (stu.section ? ' - ' + stu.section : ''));
            if (stu.pen) meta.push('PEN: ' + stu.pen);
            meta.push('विषय: ' + entry.subject);
            document.getElementById('smMeta').textContent = meta.join('  |  ');

            var html = '';
            for (var p = 1; p <= 4; p++) {
                var v = pm[p];
                var st = v ? (v.status || 'PENDING') : 'NONE';
                html += '<div class="phase-item">';
                html += '<div>';
                html += '<div class="pname">Phase ' + p + '</div>';
                if (v && v.uploadDate) html += '<div class="pdate">📅 ' + escHtml(v.uploadDate.substring(0, 16)) + '</div>';
                if (st === 'REJECTED' && v && v.rejectionReason) html += '<div class="preason">कारण: ' + escHtml(v.rejectionReason) + '</div>';
                html += '</div>';
                html += '<span class="status-badge ' + st + '">' + statusLabel(st) + '</span>';
                html += '</div>';
            }
            document.getElementById('smPhases').innerHTML = html;
            document.getElementById('studentModal').classList.add('open');
        }

        function closeStudentModal() {
            document.getElementById('studentModal').classList.remove('open');
        }

        document.getElementById('studentModal').addEventListener('click', function (e) {
            if (e.target === this) closeStudentModal();
        });
        document.addEventListener('keydown', function (e) {
            if (e.key !== 'Escape') return;
            if (document.getElementById('studentModal').classList.contains('open')) {
                closeStudentModal();
            } else if (document.getElementById('teacherModal').classList.contains('open')) {
                closeVideosPanel();
            }
        });
    </script>
</body>
</html>
