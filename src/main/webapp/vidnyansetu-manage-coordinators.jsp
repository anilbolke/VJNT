<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.vjnt.model.User,com.vjnt.util.DatabaseConnection,java.sql.*,java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    // One row per school (schools master only — udise_no is all we need for the
    // username), left-joined with vidnyansetu_users (role COORDINATOR) so a
    // school that already has a VidnyanSetu login shows its status instead of
    // a Create button. school_contacts is intentionally not touched.
    List<Map<String,Object>> rows = new ArrayList<>();
    String sql =
        "SELECT s.udise_no, s.school_name, s.district_name, " +
        "       v.vs_user_id, v.username AS vs_username, v.is_active AS vs_active " +
        "FROM schools s " +
        "LEFT JOIN vidnyansetu_users v ON v.udise_no = s.udise_no AND v.role = 'COORDINATOR' " +
        "ORDER BY s.school_name";
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql);
         ResultSet rs = ps.executeQuery()) {
        while (rs.next()) {
            Map<String,Object> r = new LinkedHashMap<>();
            r.put("udise", rs.getString("udise_no"));
            r.put("name", rs.getString("school_name"));
            r.put("district", rs.getString("district_name"));
            Object vsId = rs.getObject("vs_user_id");
            r.put("vsUserId", vsId);
            r.put("vsUsername", rs.getString("vs_username"));
            r.put("vsActive", rs.getBoolean("vs_active"));
            rows.add(r);
        }
    }
%>
<!DOCTYPE html>
<html lang="mr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>VidnyanSetu Coordinators - Data Admin</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f4f8;color:#1e293b;}
.topbar{background:linear-gradient(135deg,#0f9b6c 0%,#0c7b54 100%);color:#fff;padding:16px 24px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;}
.topbar .brand{font-size:19px;font-weight:800;}
.topbar-btn{background:rgba(255,255,255,0.15);color:#fff;text-decoration:none;padding:8px 14px;border-radius:8px;font-size:13px;font-weight:600;border:1px solid rgba(255,255,255,0.3);}
.topbar-btn:hover{background:rgba(255,255,255,0.28);}
.wrap{max-width:1300px;margin:24px auto;padding:0 20px;}
.card{background:#fff;border-radius:12px;padding:22px;box-shadow:0 4px 18px rgba(0,0,0,0.08);border:1px solid #e2e8f0;}
.card h3{margin-bottom:6px;color:#0c7b54;}
.card .hint{font-size:12.5px;color:#64748b;margin-bottom:14px;}
.toolbar{display:flex;gap:12px;align-items:center;margin-bottom:14px;flex-wrap:wrap;}
.toolbar input{flex:1;min-width:220px;padding:10px 14px;border:1px solid #cbd5e1;border-radius:8px;font-size:14px;}
.toolbar .count{font-size:12.5px;color:#64748b;white-space:nowrap;}
#msgBox{margin-bottom:14px;}
.alert{padding:10px 14px;border-radius:7px;font-size:13px;font-weight:500;}
.alert-error{background:#fee2e2;color:#991b1b;}
.alert-success{background:#d1fae5;color:#065f46;}
.table-scroll{max-height:70vh;overflow-y:auto;border:1px solid #e2e8f0;border-radius:8px;}
table{width:100%;border-collapse:collapse;}
th,td{padding:9px 10px;text-align:left;border-bottom:1px solid #e2e8f0;font-size:13px;vertical-align:middle;}
th{background:#f8fafc;color:#475569;font-weight:700;position:sticky;top:0;z-index:5;}
tr.no-match{display:none;}
.school-name{font-weight:600;color:#1e293b;}
.udise{color:#94a3b8;font-size:11.5px;}
input.row-input{width:100%;padding:6px 8px;border:1px solid #cbd5e1;border-radius:6px;font-size:12.5px;}
.btn{background:#0f9b6c;color:#fff;border:none;padding:7px 14px;border-radius:6px;font-size:12.5px;font-weight:700;cursor:pointer;white-space:nowrap;}
.btn:hover{background:#0c7b54;}
.btn:disabled{background:#94a3b8;cursor:not-allowed;}
.btn-danger{background:#dc2626;}
.btn-danger:hover{background:#b91c1c;}
.badge{padding:3px 9px;border-radius:20px;font-size:11px;font-weight:700;white-space:nowrap;}
.badge-active{background:#d1fae5;color:#065f46;}
.badge-inactive{background:#fee2e2;color:#991b1b;}
.action-cell{display:flex;flex-direction:column;gap:5px;align-items:flex-start;}
</style>
</head>
<body>
<div class="topbar">
    <div class="brand">🔬 विज्ञानसेतू Coordinators</div>
    <a class="topbar-btn" href="<%= request.getContextPath() %>/data-admin-dashboard.jsp">← Data Admin Dashboard</a>
</div>
<div class="wrap">
    <div class="card">
        <h3>🏫 Schools (<%= rows.size() %>)</h3>
        <p class="hint">School and UDISE are from the school master — enter the coordinator's name and mobile, then click Create Login. Username is auto-generated as <strong>vs_&lt;UDISE&gt;</strong>, default password <strong>Pass@123</strong>.</p>
        <div id="msgBox"></div>
        <div class="toolbar">
            <input type="text" id="searchBox" placeholder="Search by school name, UDISE or district..." oninput="filterRows()">
            <span class="count" id="visibleCount"></span>
        </div>
        <div class="table-scroll">
        <table id="schoolTable">
            <thead><tr><th style="min-width:260px;">School</th><th>District</th><th style="min-width:150px;">Coordinator Name</th><th style="min-width:120px;">Mobile</th><th style="min-width:150px;">VidnyanSetu Login</th></tr></thead>
            <tbody>
            <% for (Map<String,Object> r : rows) {
                boolean hasLogin = r.get("vsUserId") != null;
                String searchBlob = ((String)r.get("name") + " " + r.get("udise") + " " + (r.get("district") != null ? r.get("district") : "")).toLowerCase();
            %>
                <tr data-search="<%= searchBlob.replace("\"","'") %>">
                    <td>
                        <div class="school-name"><%= r.get("name") %></div>
                        <div class="udise">UDISE <%= r.get("udise") %></div>
                    </td>
                    <td><%= r.get("district") != null ? r.get("district") : "-" %></td>
                    <% if (hasLogin) { %>
                        <td colspan="2" style="color:#64748b;">Username: <strong><%= r.get("vsUsername") %></strong></td>
                        <td class="action-cell">
                            <span class="badge <%= (Boolean)r.get("vsActive") ? "badge-active" : "badge-inactive" %>">
                                <%= (Boolean)r.get("vsActive") ? "Active" : "Disabled" %>
                            </span>
                            <button class="btn btn-sm <%= (Boolean)r.get("vsActive") ? "btn-danger" : "" %>"
                                    onclick="toggleCoordinator(this, <%= r.get("vsUserId") %>, <%= !(Boolean)r.get("vsActive") %>)">
                                <%= (Boolean)r.get("vsActive") ? "Disable" : "Enable" %>
                            </button>
                        </td>
                    <% } else { %>
                        <td><input type="text" class="row-input coord-name" placeholder="Coordinator name"></td>
                        <td><input type="text" class="row-input coord-mobile" placeholder="10-digit mobile" maxlength="10"></td>
                        <td class="action-cell">
                            <button class="btn" onclick="createLogin(this, '<%= r.get("udise") %>')">➕ Create Login</button>
                        </td>
                    <% } %>
                </tr>
            <% } %>
            </tbody>
        </table>
        </div>
    </div>
</div>

<script>
var ctx = '<%= request.getContextPath() %>';

function showMsg(ok, text) {
    document.getElementById('msgBox').innerHTML =
        '<div class="alert ' + (ok ? 'alert-success' : 'alert-error') + '">' + text + '</div>';
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

function filterRows() {
    var q = document.getElementById('searchBox').value.trim().toLowerCase();
    var rowsEls = document.querySelectorAll('#schoolTable tbody tr');
    var visible = 0;
    rowsEls.forEach(function(tr) {
        var match = !q || tr.getAttribute('data-search').indexOf(q) !== -1;
        tr.classList.toggle('no-match', !match);
        if (match) visible++;
    });
    document.getElementById('visibleCount').textContent = visible + ' / ' + rowsEls.length + ' schools';
}
filterRows();

function createLogin(btn, udise) {
    var row = btn.closest('tr');
    var name = row.querySelector('.coord-name').value.trim();
    var mobile = row.querySelector('.coord-mobile').value.trim();

    if (!name) { showMsg(false, 'Please enter a coordinator name for this school'); return; }
    if (!/^\d{10}$/.test(mobile)) { showMsg(false, 'Mobile number must be 10 digits'); return; }

    btn.disabled = true;
    btn.textContent = 'Creating...';

    var params = new URLSearchParams();
    params.append('action', 'add');
    params.append('coordinatorName', name);
    params.append('mobile', mobile);
    params.append('udiseNo', udise);

    fetch(ctx + '/vidnyansetu-manage-coordinators', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
    })
    .then(function(r) { return r.json(); })
    .then(function(res) {
        showMsg(res.success, res.message);
        if (res.success) {
            var actionCell = row.querySelector('.action-cell');
            row.querySelector('.coord-name').closest('td').outerHTML =
                '<td colspan="2" style="color:#64748b;">Username: <strong>' + res.username + '</strong></td>';
            actionCell.innerHTML =
                '<span class="badge badge-active">Active</span>' +
                '<button class="btn btn-sm btn-danger" onclick="toggleCoordinator(this, ' + res.vsUserId + ', false)">Disable</button>';
        } else {
            btn.disabled = false;
            btn.textContent = '➕ Create Login';
        }
    })
    .catch(function() {
        showMsg(false, 'Something went wrong. Please try again.');
        btn.disabled = false;
        btn.textContent = '➕ Create Login';
    });
}

function toggleCoordinator(btn, id, makeActive) {
    var params = new URLSearchParams();
    params.append('action', 'toggle');
    params.append('vsUserId', id);
    params.append('active', makeActive);

    fetch(ctx + '/vidnyansetu-manage-coordinators', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
    })
    .then(function(r) { return r.json(); })
    .then(function(res) {
        if (res.success) {
            var actionCell = btn.closest('.action-cell');
            actionCell.querySelector('.badge').className = 'badge ' + (makeActive ? 'badge-active' : 'badge-inactive');
            actionCell.querySelector('.badge').textContent = makeActive ? 'Active' : 'Disabled';
            btn.className = 'btn btn-sm' + (makeActive ? ' btn-danger' : '');
            btn.textContent = makeActive ? 'Disable' : 'Enable';
            btn.setAttribute('onclick', "toggleCoordinator(this, " + id + ", " + (!makeActive) + ")");
        } else {
            showMsg(false, res.message || 'Failed to update status');
        }
    })
    .catch(function() { showMsg(false, 'Something went wrong. Please try again.'); });
}
</script>
</body>
</html>
