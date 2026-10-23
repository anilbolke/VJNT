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
    int countRegular = 0, countPermanent = 0;
    String errorMessage = null;

    try (Connection conn = DatabaseConnection.getConnection()) {
        String sql = "SELECT t.teacher_id, t.teacher_name, t.mobile_number, t.subjects_taught, " +
                     "COALESCE(t.teacher_category, 'REGULAR') AS teacher_category, " +
                     "s.udise_no, s.school_name " +
                     "FROM schools s " +
                     "JOIN teachers t ON s.udise_no COLLATE utf8mb4_unicode_ci = t.udise_code AND t.is_active = 1 " +
                     "WHERE s.district_name = ? " +
                     "ORDER BY s.school_name, t.teacher_name";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, districtName);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> t = new HashMap<>();
                    t.put("id", rs.getInt("teacher_id"));
                    t.put("name", rs.getString("teacher_name"));
                    t.put("mobile", rs.getString("mobile_number"));
                    t.put("subjects", rs.getString("subjects_taught"));
                    String cat = rs.getString("teacher_category");
                    if (!"PERMANENT".equals(cat)) cat = "REGULAR";
                    t.put("category", cat);
                    t.put("udise", rs.getString("udise_no"));
                    t.put("school", rs.getString("school_name"));
                    teachers.add(t);
                    if ("PERMANENT".equals(cat)) countPermanent++; else countRegular++;
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
    <title>शिक्षक वर्गवारी (Teacher Category) - <%= esc(districtName) %></title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f0f2f5; color: #1e293b; padding: 24px; }
        .container { max-width: 1200px; margin: 0 auto; background: #fff; border-radius: 14px; box-shadow: 0 10px 30px rgba(0,0,0,.1); overflow: hidden; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #fff; padding: 28px 30px; }
        .header h1 { font-size: 22px; font-weight: 800; margin-bottom: 6px; }
        .header p { font-size: 14px; opacity: .9; }
        .back-link { display: inline-block; color: #fff; text-decoration: none; font-size: 13px; margin-bottom: 14px; opacity: .9; }
        .back-link:hover { opacity: 1; text-decoration: underline; }
        .content { padding: 24px 30px 40px; }

        .stats { display: flex; gap: 14px; flex-wrap: wrap; margin-bottom: 20px; }
        .stat { flex: 1; min-width: 150px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 14px 18px; }
        .stat .n { font-size: 26px; font-weight: 800; }
        .stat .l { font-size: 12px; color: #64748b; text-transform: uppercase; letter-spacing: .5px; margin-top: 2px; }
        .stat.reg .n { color: #2563eb; }
        .stat.perm .n { color: #059669; }

        .toolbar { display: flex; gap: 12px; flex-wrap: wrap; margin-bottom: 16px; align-items: center; }
        .toolbar input, .toolbar select { padding: 9px 12px; border: 2px solid #e2e8f0; border-radius: 8px; font-size: 13px; font-family: inherit; outline: none; }
        .toolbar input:focus, .toolbar select:focus { border-color: #667eea; }
        .toolbar input[type=text] { flex: 1; min-width: 220px; }

        table { width: 100%; border-collapse: collapse; font-size: 13px; }
        thead th { background: #667eea; color: #fff; text-align: left; padding: 10px 12px; white-space: nowrap; position: sticky; top: 0; }
        tbody td { padding: 9px 12px; border-bottom: 1px solid #eef2f7; vertical-align: middle; }
        tbody tr:hover { background: #f5f7ff; }
        .subject-tag { display: inline-block; background: #eef2ff; color: #3730a3; border-radius: 8px; padding: 2px 8px; font-size: 11px; margin: 1px 2px; }
        .cat-select { padding: 6px 10px; border: 2px solid #e2e8f0; border-radius: 8px; font-size: 13px; font-family: inherit; background: #fff; cursor: pointer; max-width: 280px; }
        .cat-select.PERMANENT { border-color: #6ee7b7; background: #ecfdf5; color: #065f46; font-weight: 700; }
        .cat-select.REGULAR   { border-color: #bfdbfe; background: #eff6ff; color: #1e40af; font-weight: 700; }
        .save-flag { font-size: 12px; margin-left: 8px; white-space: nowrap; }
        .save-flag.ok  { color: #059669; }
        .save-flag.err { color: #dc2626; }

        .empty { text-align: center; padding: 50px 20px; color: #94a3b8; }
        .err-box { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; border-radius: 8px; padding: 12px 16px; font-size: 13px; margin-bottom: 16px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <a href="<%= request.getContextPath() %>/district-dashboard.jsp" class="back-link">← Back to Dashboard</a>
            <h1>🏷️ शिक्षक वर्गवारी (Teacher Category)</h1>
            <p><%= esc(districtName) %> District — प्रत्येक शिक्षकाची वर्गवारी निवडा: <strong>संस्थेने स्वउत्पन्नातून नेमलेले शिक्षक</strong> किंवा <strong>कायम मान्यता प्राप्त शिक्षक</strong></p>
        </div>

        <div class="content">
            <% if (errorMessage != null) { %>
                <div class="err-box">⚠️ Could not load teachers: <%= esc(errorMessage) %></div>
            <% } %>

            <div class="stats">
                <div class="stat"><div class="n" id="statTotal"><%= teachers.size() %></div><div class="l">Total Teachers</div></div>
                <div class="stat reg"><div class="n" id="statReg"><%= countRegular %></div><div class="l">संस्थेने स्वउत्पन्नातून नेमलेले शिक्षक</div></div>
                <div class="stat perm"><div class="n" id="statPerm"><%= countPermanent %></div><div class="l">कायम मान्यता प्राप्त शिक्षक</div></div>
            </div>

            <% if (teachers.isEmpty() && errorMessage == null) { %>
                <div class="empty">No active teachers found in this district.</div>
            <% } else if (!teachers.isEmpty()) { %>
                <div class="toolbar">
                    <input type="text" id="searchBox" placeholder="🔍 Search by teacher, school or mobile...">
                    <select id="catFilter">
                        <option value="">सर्व वर्गवारी (All)</option>
                        <option value="REGULAR">संस्थेने स्वउत्पन्नातून नेमलेले शिक्षक</option>
                        <option value="PERMANENT">कायम मान्यता प्राप्त शिक्षक</option>
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
                            <th>Category</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% int sr = 0; for (Map<String, Object> t : teachers) { sr++;
                            String cat = (String) t.get("category");
                            String[] subs = ((String) t.get("subjects") == null ? "" : (String) t.get("subjects")).split(",");
                        %>
                        <tr data-search="<%= esc(((String) t.get("name")) + " " + ((String) t.get("school")) + " " + ((String) t.get("mobile")) + " " + ((String) t.get("udise"))).toLowerCase() %>"
                            data-cat="<%= cat %>">
                            <td><%= sr %></td>
                            <td><strong><%= esc((String) t.get("school")) %></strong><br><span style="color:#94a3b8;font-size:11px;"><%= esc((String) t.get("udise")) %></span></td>
                            <td><strong><%= esc((String) t.get("name")) %></strong></td>
                            <td><%= esc((String) t.get("mobile")) %></td>
                            <td>
                                <% for (String s : subs) { if (s.trim().isEmpty()) continue; %>
                                    <span class="subject-tag"><%= esc(s.trim()) %></span>
                                <% } %>
                            </td>
                            <td style="white-space:nowrap;">
                                <select class="cat-select <%= cat %>" data-teacher-id="<%= t.get("id") %>"
                                        onchange="saveCategory(this)">
                                    <option value="REGULAR"   <%= "REGULAR".equals(cat)   ? "selected" : "" %>>संस्थेने स्वउत्पन्नातून नेमलेले शिक्षक</option>
                                    <option value="PERMANENT" <%= "PERMANENT".equals(cat) ? "selected" : "" %>>कायम मान्यता प्राप्त शिक्षक</option>
                                </select>
                                <span class="save-flag" id="flag<%= t.get("id") %>"></span>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
                </div>
            <% } %>
        </div>
    </div>

    <script>
        var CTX = '<%= request.getContextPath() %>';

        function applyFilters() {
            var q = (document.getElementById('searchBox').value || '').toLowerCase().trim();
            var cf = document.getElementById('catFilter').value;
            var rows = document.querySelectorAll('#teacherTable tbody tr');
            var shown = 0;
            rows.forEach(function (r) {
                var okQ = !q || r.getAttribute('data-search').indexOf(q) > -1;
                var okC = !cf || r.getAttribute('data-cat') === cf;
                r.style.display = (okQ && okC) ? '' : 'none';
                if (okQ && okC) shown++;
            });
        }

        function recountStats() {
            var rows = document.querySelectorAll('#teacherTable tbody tr');
            var reg = 0, perm = 0;
            rows.forEach(function (r) {
                if (r.getAttribute('data-cat') === 'PERMANENT') perm++; else reg++;
            });
            document.getElementById('statReg').textContent = reg;
            document.getElementById('statPerm').textContent = perm;
        }

        function saveCategory(sel) {
            var teacherId = sel.getAttribute('data-teacher-id');
            var category = sel.value;
            var flag = document.getElementById('flag' + teacherId);
            var row = sel.closest('tr');

            sel.disabled = true;
            flag.className = 'save-flag';
            flag.textContent = '⏳';

            var body = new URLSearchParams();
            body.append('teacherId', teacherId);
            body.append('category', category);

            fetch(CTX + '/update-teacher-category', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: body.toString()
            })
            .then(function (r) { return r.json(); })
            .then(function (res) {
                sel.disabled = false;
                if (res.success) {
                    sel.className = 'cat-select ' + category;
                    row.setAttribute('data-cat', category);
                    flag.className = 'save-flag ok';
                    flag.textContent = '✓ saved';
                    recountStats();
                    setTimeout(function () { flag.textContent = ''; }, 2500);
                } else {
                    flag.className = 'save-flag err';
                    flag.textContent = '✕ ' + (res.message || 'failed');
                }
            })
            .catch(function () {
                sel.disabled = false;
                flag.className = 'save-flag err';
                flag.textContent = '✕ error';
            });
        }

        var sb = document.getElementById('searchBox');
        var cfl = document.getElementById('catFilter');
        if (sb) sb.addEventListener('input', applyFilters);
        if (cfl) cfl.addEventListener('change', applyFilters);
    </script>
</body>
</html>
