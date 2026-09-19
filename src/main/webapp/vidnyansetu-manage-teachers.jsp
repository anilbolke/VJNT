<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.VidnyanSetuUser,com.vjnt.util.DatabaseConnection,java.sql.*,java.util.*" %>
<%
    VidnyanSetuUser coordinator = (VidnyanSetuUser) session.getAttribute("vsUser");
    if (coordinator == null) { response.sendRedirect(request.getContextPath() + "/vidnyansetu-login"); return; }
    if (coordinator.getRole() != VidnyanSetuUser.Role.COORDINATOR) {
        response.sendRedirect(request.getContextPath() + "/vidnyansetu-teacher-dashboard.jsp"); return;
    }

    List<Map<String,Object>> teachers = new ArrayList<>();
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(
             "SELECT u.vs_user_id, u.username, u.full_name, u.is_active, u.must_change_password, " +
             "       GROUP_CONCAT(CONCAT(a.class,'-',a.section) ORDER BY a.class,a.section SEPARATOR ', ') AS assignments " +
             "FROM vidnyansetu_users u " +
             "LEFT JOIN vidnyansetu_teacher_assignments a ON a.vs_user_id = u.vs_user_id AND a.is_active = 1 " +
             "WHERE u.role = 'TEACHER' AND u.udise_no = ? " +
             "GROUP BY u.vs_user_id ORDER BY u.full_name")) {
        ps.setString(1, coordinator.getUdiseNo());
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> t = new LinkedHashMap<>();
                t.put("id", rs.getInt("vs_user_id"));
                t.put("username", rs.getString("username"));
                t.put("name", rs.getString("full_name"));
                t.put("active", rs.getBoolean("is_active"));
                t.put("mustChange", rs.getBoolean("must_change_password"));
                t.put("assignments", rs.getString("assignments"));
                teachers.add(t);
            }
        }
    }

    // Real class-sections that exist at this school (students table) — the
    // teacher-assignment picker offers only these, not a generic I-X/A-D list.
    List<String[]> classSections = new ArrayList<>();
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(
             "SELECT DISTINCT class, section FROM students WHERE is_active = 1 AND udise_no = ? " +
             "ORDER BY FIELD(class,'I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII'), section")) {
        ps.setString(1, coordinator.getUdiseNo());
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) classSections.add(new String[]{ rs.getString("class"), rs.getString("section") });
        }
    }
%>
<!DOCTYPE html>
<html lang="mr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Manage VidnyanSetu Teachers</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f4f8;color:#1e293b;}
.topbar{background:linear-gradient(135deg,#0f9b6c 0%,#0c7b54 100%);color:#fff;padding:16px 24px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;}
.topbar .brand{font-size:19px;font-weight:800;}
.topbar-btn{background:rgba(255,255,255,0.15);color:#fff;text-decoration:none;padding:8px 14px;border-radius:8px;font-size:13px;font-weight:600;border:1px solid rgba(255,255,255,0.3);}
.topbar-btn:hover{background:rgba(255,255,255,0.28);}
.wrap{max-width:1000px;margin:30px auto;padding:0 20px;}
.card{background:#fff;border-radius:12px;padding:22px;box-shadow:0 4px 18px rgba(0,0,0,0.08);margin-bottom:22px;border:1px solid #e2e8f0;}
.card h3{margin-bottom:16px;color:#0c7b54;}
.form-row{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:12px;}
.form-row .fg{flex:1;min-width:150px;}
.form-row label{display:block;font-size:12.5px;font-weight:600;color:#475569;margin-bottom:5px;}
.form-row input,.form-row select{width:100%;padding:9px 10px;border:1px solid #cbd5e1;border-radius:7px;font-size:14px;}
.btn{background:#0f9b6c;color:#fff;border:none;padding:10px 18px;border-radius:7px;font-size:14px;font-weight:700;cursor:pointer;}
.btn:hover{background:#0c7b54;}
.btn-sm{padding:6px 12px;font-size:12.5px;border-radius:6px;}
.btn-danger{background:#dc2626;}
.btn-danger:hover{background:#b91c1c;}
table{width:100%;border-collapse:collapse;}
th,td{padding:10px 12px;text-align:left;border-bottom:1px solid #e2e8f0;font-size:13.5px;}
th{background:#f8fafc;color:#475569;font-weight:700;}
.badge{padding:3px 9px;border-radius:20px;font-size:11.5px;font-weight:700;}
.badge-active{background:#d1fae5;color:#065f46;}
.badge-inactive{background:#fee2e2;color:#991b1b;}
#msgBox{margin-bottom:14px;}
.alert{padding:10px 14px;border-radius:7px;font-size:13px;font-weight:500;}
.alert-error{background:#fee2e2;color:#991b1b;}
.alert-success{background:#d1fae5;color:#065f46;}
</style>
</head>
<body>
<div class="topbar">
    <div class="brand">🔬 विज्ञानसेतू</div>
    <a class="topbar-btn" href="<%= request.getContextPath() %>/vidnyansetu-coordinator-dashboard.jsp">← Dashboard</a>
</div>
<div class="wrap">
    <div class="card">
        <h3>➕ Add VidnyanSetu Teacher</h3>
        <div id="msgBox"></div>
        <div class="form-row">
            <div class="fg"><label>Teacher Name</label><input type="text" id="teacherName" placeholder="Full name"></div>
            <div class="fg"><label>Mobile Number</label><input type="text" id="mobile" placeholder="10-digit mobile" maxlength="10"></div>
            <div class="fg"><label>Class - Section</label>
                <% if (classSections.isEmpty()) { %>
                    <select id="classSection" disabled><option>No classes found for this school yet</option></select>
                <% } else { %>
                    <select id="classSection">
                        <% for (String[] cs : classSections) { %>
                            <option value="<%= cs[0] %>|<%= cs[1] %>"><%= cs[0] %> - <%= cs[1] %></option>
                        <% } %>
                    </select>
                <% } %>
            </div>
        </div>
        <button class="btn" onclick="addTeacher()" <%= classSections.isEmpty() ? "disabled" : "" %>>Add Teacher</button>
        <p style="margin-top:10px;font-size:12.5px;color:#64748b;">Login username will be <strong>vs_&lt;mobile number&gt;</strong>, default password <strong>Pass@123</strong>.</p>
    </div>

    <div class="card">
        <h3>👩‍🏫 VidnyanSetu Teachers (<%= teachers.size() %>)</h3>
        <% if (teachers.isEmpty()) { %>
            <p style="color:#64748b;">No VidnyanSetu teachers added yet.</p>
        <% } else { %>
        <table>
            <thead><tr><th>Name</th><th>Username</th><th>Class-Section</th><th>Status</th><th>Action</th></tr></thead>
            <tbody>
            <% for (Map<String,Object> t : teachers) { %>
                <tr id="row-<%= t.get("id") %>">
                    <td><%= t.get("name") %></td>
                    <td><%= t.get("username") %></td>
                    <td><%= t.get("assignments") != null ? t.get("assignments") : "-" %></td>
                    <td>
                        <span class="badge <%= (Boolean)t.get("active") ? "badge-active" : "badge-inactive" %>">
                            <%= (Boolean)t.get("active") ? "Active" : "Disabled" %>
                        </span>
                    </td>
                    <td>
                        <button class="btn btn-sm <%= (Boolean)t.get("active") ? "btn-danger" : "" %>"
                                onclick="toggleTeacher(<%= t.get("id") %>, <%= !(Boolean)t.get("active") %>)">
                            <%= (Boolean)t.get("active") ? "Disable" : "Enable" %>
                        </button>
                    </td>
                </tr>
            <% } %>
            </tbody>
        </table>
        <% } %>
    </div>
</div>

<script>
var ctx = '<%= request.getContextPath() %>';

function showMsg(ok, text) {
    document.getElementById('msgBox').innerHTML =
        '<div class="alert ' + (ok ? 'alert-success' : 'alert-error') + '">' + text + '</div>';
}

function addTeacher() {
    var name = document.getElementById('teacherName').value.trim();
    var mobile = document.getElementById('mobile').value.trim();
    var csVal = document.getElementById('classSection').value;
    var csParts = csVal.split('|');
    var cls = csParts[0];
    var section = csParts[1];

    if (!name || !mobile) { showMsg(false, 'Please enter teacher name and mobile number'); return; }
    if (!/^\d{10}$/.test(mobile)) { showMsg(false, 'Mobile number must be 10 digits'); return; }
    if (!cls || !section) { showMsg(false, 'Please select a class-section'); return; }

    var params = new URLSearchParams();
    params.append('teacherName', name);
    params.append('mobile', mobile);
    params.append('class', cls);
    params.append('section', section);

    fetch(ctx + '/vidnyansetu-add-teacher', {
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

function toggleTeacher(id, makeActive) {
    var params = new URLSearchParams();
    params.append('vsUserId', id);
    params.append('active', makeActive);

    fetch(ctx + '/vidnyansetu-toggle-teacher', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
    })
    .then(function(r) { return r.json(); })
    .then(function(res) {
        if (res.success) { location.reload(); } else { showMsg(false, res.message || 'Failed to update status'); }
    })
    .catch(function() { showMsg(false, 'Something went wrong. Please try again.'); });
}
</script>
</body>
</html>
