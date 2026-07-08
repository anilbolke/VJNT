<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.TEACHER)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="mr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Teacher Dashboard - GATEE Portal</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, sans-serif; }
        body { background: #f0f2f5; min-height: 100vh; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px 30px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 15px; }
        .header h1 { font-size: 22px; }
        .header .sub { font-size: 13px; opacity: 0.9; margin-top: 4px; }
        .header-actions { display: flex; gap: 10px; }
        .header-actions a { background: rgba(255,255,255,0.2); color: white; text-decoration: none; padding: 10px 18px; border-radius: 8px; font-size: 14px; font-weight: 600; }
        .header-actions a:hover { background: rgba(255,255,255,0.3); }
        .container { max-width: 1300px; margin: 25px auto; padding: 0 20px; }
        .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 25px; }
        .card { padding: 20px; border-radius: 12px; color: white; text-align: center; }
        .card .num { font-size: 32px; font-weight: 700; }
        .card .lbl { font-size: 14px; margin-top: 5px; }
        .section { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 25px; }
        .section h2 { color: #333; margin-bottom: 15px; font-size: 18px; }
        .filters { display: flex; gap: 15px; margin-bottom: 18px; flex-wrap: wrap; }
        .filters input, .filters select { padding: 10px 15px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; }
        .filters input { flex: 1; min-width: 220px; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #f8f9fa; border-bottom: 2px solid #dee2e6; padding: 12px; text-align: left; font-weight: 600; font-size: 14px; }
        td { padding: 11px 12px; border-bottom: 1px solid #e9ecef; font-size: 14px; }
        tr:hover td { background: #f8f9fa; }
        .badge { display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600; color: white; }
        .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #667eea; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        .assignment-chip { display: inline-block; background: #EDE7F6; color: #4527A0; padding: 6px 14px; border-radius: 16px; font-size: 13px; font-weight: 600; margin: 0 8px 8px 0; }
        .error-box { background: #FFEBEE; border: 1px solid #EF9A9A; color: #B71C1C; padding: 15px; border-radius: 8px; }
        @media (max-width: 700px) { .table-wrap { overflow-x: auto; } }
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>👨‍🏫 <span id="hdrTeacherName"><%= user.getFullName() != null ? user.getFullName() : user.getUsername() %></span></h1>
            <div class="sub">Subject Teacher | UDISE: <%= user.getUdiseNo() != null ? user.getUdiseNo() : "-" %> | <span id="hdrSubjects"></span></div>
        </div>
        <div class="header-actions">
            <a href="<%= request.getContextPath() %>/raise-ticket.jsp">🎫 Support Tickets</a>
            <a href="<%= request.getContextPath() %>/change-password">🔑 Change Password</a>
            <a href="<%= request.getContextPath() %>/logout">🚪 Logout</a>
        </div>
    </div>

    <div class="container">
        <!-- Summary Cards -->
        <div class="cards">
            <div class="card" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
                <div class="num" id="cardStudents">-</div>
                <div class="lbl">माझे विद्यार्थी (My Students)</div>
            </div>
            <div class="card" style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);">
                <div class="num" id="cardClasses">-</div>
                <div class="lbl">नियुक्त वर्ग (Assigned Classes)</div>
            </div>
            <div class="card" style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);">
                <div class="num" id="cardSubjects">-</div>
                <div class="lbl">विषय (Subjects)</div>
            </div>
        </div>

        <!-- Assignments -->
        <div class="section">
            <h2>📚 माझे वर्ग (My Class Assignments)</h2>
            <div id="assignmentChips"><div class="spinner"></div></div>
        </div>

        <!-- My Students -->
        <div class="section">
            <h2>👨‍🎓 माझे विद्यार्थी (My Students)</h2>
            <p style="color:#666; font-size:13px; margin-bottom:15px;">फक्त आपल्याला नियुक्त केलेले विद्यार्थी येथे दिसतात (Only students mapped to you are shown).</p>
            <div class="filters">
                <input type="text" id="searchBox" placeholder="Search student name / PEN..." onkeyup="renderStudents()">
                <select id="classFilter" onchange="renderStudents()">
                    <option value="">All Classes</option>
                </select>
            </div>
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>विद्यार्थ्याचे नाव (Student Name)</th>
                            <th>वर्ग (Class)</th>
                            <th>तुकडी (Section)</th>
                            <th>Gender</th>
                            <th>PEN</th>
                            <th>मराठी</th>
                            <th>गणित</th>
                            <th>English</th>
                        </tr>
                    </thead>
                    <tbody id="studentsBody">
                        <tr><td colspan="9" style="text-align:center; padding:40px;"><div class="spinner"></div></td></tr>
                    </tbody>
                </table>
            </div>
            <div id="countInfo" style="margin-top:12px; color:#666; font-size:14px;"></div>
        </div>
    </div>

    <script>
        const contextPath = '<%= request.getContextPath() %>';
        let allStudents = [];

        function escapeHtml(text) {
            if (text === null || text === undefined) return '';
            return String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;')
                .replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#039;');
        }

        window.addEventListener('load', function() {
            fetch(contextPath + '/teacher-my-students')
                .then(r => r.json())
                .then(data => {
                    if (data.error) {
                        document.getElementById('assignmentChips').innerHTML = '';
                        document.getElementById('studentsBody').innerHTML =
                            '<tr><td colspan="9"><div class="error-box">' + escapeHtml(data.error) + '</div></td></tr>';
                        return;
                    }

                    document.getElementById('hdrSubjects').textContent = data.subjectsTaught || '';

                    // Assignments
                    const assignments = data.assignments || [];
                    let chips = '';
                    assignments.forEach(a => {
                        chips += '<span class="assignment-chip">वर्ग ' + escapeHtml(a['class']) + ' - ' + escapeHtml(a.section)
                              + ' | ' + escapeHtml(a.subjects)
                              + (a.isClassTeacher ? ' ⭐ (Class Teacher)' : '') + '</span>';
                    });
                    document.getElementById('assignmentChips').innerHTML =
                        chips || '<div class="error-box">अद्याप वर्ग नियुक्त केलेले नाहीत. कृपया शाळा समन्वयकांशी संपर्क करा.<br>(No classes assigned yet. Please contact your School Coordinator.)</div>';

                    // Cards
                    allStudents = data.students || [];
                    document.getElementById('cardStudents').textContent = allStudents.length;
                    document.getElementById('cardClasses').textContent = assignments.length;
                    const subjects = (data.subjectsTaught || '').split(',').map(s => s.trim()).filter(s => s);
                    document.getElementById('cardSubjects').textContent = subjects.length || '-';

                    // Class filter options
                    const classes = [...new Set(allStudents.map(s => s['class'] + ' - ' + s.section))].sort();
                    const sel = document.getElementById('classFilter');
                    classes.forEach(c => {
                        const opt = document.createElement('option');
                        opt.value = c;
                        opt.textContent = 'वर्ग ' + c;
                        sel.appendChild(opt);
                    });

                    renderStudents();
                })
                .catch(err => {
                    document.getElementById('studentsBody').innerHTML =
                        '<tr><td colspan="9"><div class="error-box">Failed to load students: ' + escapeHtml(err) + '</div></td></tr>';
                });
        });

        function levelBadge(level) {
            if (!level || level === '-') return '<span style="color:#bbb;">-</span>';
            return '<span class="badge" style="background:#667eea;">' + escapeHtml(level) + '</span>';
        }

        function renderStudents() {
            const search = document.getElementById('searchBox').value.toLowerCase();
            const classFilter = document.getElementById('classFilter').value;
            const tbody = document.getElementById('studentsBody');

            const filtered = allStudents.filter(s => {
                const matchesSearch = !search ||
                    s.studentName.toLowerCase().includes(search) ||
                    (s.studentPen && s.studentPen.toLowerCase().includes(search));
                const matchesClass = !classFilter || (s['class'] + ' - ' + s.section) === classFilter;
                return matchesSearch && matchesClass;
            });

            if (filtered.length === 0) {
                tbody.innerHTML = '<tr><td colspan="9" style="text-align:center; padding:25px; color:#999;">No students found</td></tr>';
                document.getElementById('countInfo').textContent = '';
                return;
            }

            let html = '';
            filtered.forEach((s, i) => {
                html += '<tr>';
                html += '<td>' + (i + 1) + '</td>';
                html += '<td style="font-weight:500;">' + escapeHtml(s.studentName) + '</td>';
                html += '<td>' + escapeHtml(s['class']) + '</td>';
                html += '<td>' + escapeHtml(s.section) + '</td>';
                html += '<td>' + escapeHtml(s.gender) + '</td>';
                html += '<td style="font-family:monospace; color:#666;">' + escapeHtml(s.studentPen) + '</td>';
                html += '<td>' + levelBadge(s.marathiLevel) + '</td>';
                html += '<td>' + levelBadge(s.mathLevel) + '</td>';
                html += '<td>' + levelBadge(s.englishLevel) + '</td>';
                html += '</tr>';
            });
            tbody.innerHTML = html;
            document.getElementById('countInfo').textContent = 'Showing ' + filtered.length + ' of ' + allStudents.length + ' students';
        }
    </script>
</body>
</html>
