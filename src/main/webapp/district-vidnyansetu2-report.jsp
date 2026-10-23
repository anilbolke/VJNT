<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.util.DatabaseConnection" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%!
    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
    private static String placeholders(int n) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < n; i++) { if (i > 0) sb.append(','); sb.append('?'); }
        return sb.toString();
    }
%>
<%
    // VidnyanSetu 2 (STEM, classes VI..IX) activities of one district, WITHOUT
    // video — video_url / thumbnail are deliberately never selected, same rule
    // as district-vidnyansetu-report.jsp. Division counterpart (with video):
    // division-vidnyansetu2-acts.jsp.
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR)
                      && !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    com.vjnt.dao.VidnyanSetu2ActivityDAO.ensureSchema();

    String districtName = user.getDistrictName();
    boolean prevYear = "1".equals(request.getParameter("prevYear"));

    List<Map<String,Object>> acts = new ArrayList<>();
    int total = 0, pending = 0, approved = 0, rejected = 0;
    // School-wise counts: udise -> {school name, logged, pending, approved, rejected}
    Map<String,Object[]> bySchool = new LinkedHashMap<>();

    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(
             "SELECT a.activity_id, a.udise_no, s.school_name, a.student_class, a.student_section, " +
             "       a.activity_no, a.activity_name, a.activity_date, a.description, a.created_by, a.created_date, " +
             "       a.approval_status, a.approved_by_name, a.approval_date, a.rejection_reason " +
             "FROM vidnyansetu2_activities a " +
             "JOIN schools s ON s.udise_no = a.udise_no " +
             "WHERE s.district_name = ? AND a.archived_promotion_id " + (prevYear ? "IS NOT NULL " : "IS NULL ") +
             "ORDER BY s.school_name, a.created_date DESC")) {
        ps.setString(1, districtName);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> v = new LinkedHashMap<>();
                String udise = rs.getString("udise_no");
                v.put("udise", udise);
                v.put("school", rs.getString("school_name"));
                v.put("district", districtName);
                v.put("cls", rs.getString("student_class"));
                v.put("section", rs.getString("student_section"));
                v.put("activityNo", rs.getInt("activity_no"));
                v.put("activityName", rs.getString("activity_name"));
                v.put("date", rs.getDate("activity_date"));
                v.put("desc", rs.getString("description"));
                v.put("createdBy", rs.getString("created_by"));
                v.put("createdDate", rs.getTimestamp("created_date"));
                String status = rs.getString("approval_status");
                v.put("status", status);
                v.put("approvedBy", rs.getString("approved_by_name"));
                v.put("approvalDate", rs.getTimestamp("approval_date"));
                v.put("rejectionReason", rs.getString("rejection_reason"));
                acts.add(v);
                Object[] sc = bySchool.computeIfAbsent(udise, k -> new Object[]{ v.get("school"), 0, 0, 0, 0 });
                sc[1] = (Integer) sc[1] + 1;
                total++;
                if ("PENDING".equals(status)) { pending++; sc[2] = (Integer) sc[2] + 1; }
                else if ("APPROVED".equals(status)) { approved++; sc[3] = (Integer) sc[3] + 1; }
                else if ("REJECTED".equals(status)) { rejected++; sc[4] = (Integer) sc[4] + 1; }
            }
        }
    }

    // Filter option lists, built from the loaded rows
    TreeMap<String,String> fSchools = new TreeMap<>();          // udise -> school name
    Map<String,String> fSchoolDistrict = new HashMap<>();      // udise -> district
    List<String> classOrder = com.vjnt.dao.VidnyanSetu2ActivityDAO.CLASSES;
    TreeSet<String> fClasses = new TreeSet<>(Comparator.comparingInt((String c) -> classOrder.indexOf(c) < 0 ? 99 : classOrder.indexOf(c)).thenComparing(c -> c));
    TreeMap<Integer,String> fActivities = new TreeMap<>();     // activity_no -> name
    for (Map<String,Object> v : acts) {
        String d = (String) v.get("district");
        String u = (String) v.get("udise");
        fSchools.put(u, v.get("school") != null ? (String) v.get("school") : u);
        fSchoolDistrict.put(u, d == null ? "" : d);
        if (v.get("cls") != null) fClasses.add((String) v.get("cls"));
        fActivities.putIfAbsent((Integer) v.get("activityNo"), (String) v.get("activityName"));
    }
%>
<!DOCTYPE html>
<html lang="mr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>VidnyanSetu 2 Report - <%= esc(districtName) %></title>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f2f5;color:#1e293b;}
.header{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff;padding:28px 30px;}
.header h1{font-size:22px;font-weight:800;margin-bottom:6px;}
.header p{font-size:14px;opacity:.9;}
.header .back{display:inline-block;margin-top:14px;background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.35);color:#fff;text-decoration:none;padding:7px 14px;border-radius:20px;font-size:13px;}
.header .back:hover{background:rgba(255,255,255,.25);}
.wrap{max-width:1300px;margin:24px auto;padding:0 20px 60px;}
.stat-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin-bottom:22px;}
.stat-card{background:#fff;padding:16px;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,.06);border-left:3px solid #667eea;text-align:center;cursor:pointer;}
.stat-card.active{box-shadow:0 0 0 2px #667eea;}
.stat-card .n{font-size:24px;font-weight:700;color:#2d3748;}
.stat-card .k{font-size:12px;color:#718096;margin-top:4px;}
.card{background:#fff;border-radius:10px;box-shadow:0 2px 8px rgba(0,0,0,.06);padding:20px;}
.toolbar{display:flex;gap:10px;align-items:center;margin-bottom:16px;flex-wrap:wrap;}
.toolbar input,.toolbar select{padding:9px 12px;border:1px solid #cbd5e1;border-radius:7px;font-size:13.5px;}
.toolbar input{flex:1;min-width:220px;}
.toolbar .count{font-size:12.5px;color:#718096;white-space:nowrap;}
.filters{display:grid;grid-template-columns:repeat(auto-fill,minmax(170px,1fr));gap:10px;margin-bottom:16px;padding:14px;background:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;}
.filters label{display:flex;flex-direction:column;gap:4px;font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.3px;}
.filters select,.filters input{padding:8px 10px;border:1px solid #cbd5e1;border-radius:7px;font-size:13px;font-weight:400;color:#1e293b;background:#fff;text-transform:none;letter-spacing:0;}
.filters .reset-btn{align-self:end;background:#fff;color:#667eea;border:1px solid #667eea;padding:8px 12px;border-radius:7px;font-size:13px;font-weight:700;cursor:pointer;}
.chip{padding:2px 8px;border-radius:20px;font-size:10.5px;font-weight:700;}
.chip-pending{background:#fef3c7;color:#92400e;}
.chip-approved{background:#dcfce7;color:#14532d;}
.chip-rejected{background:#fee2e2;color:#991b1b;}
.empty{text-align:center;padding:60px 20px;color:#94a3b8;}
.vtable-wrap{overflow-x:auto;}
.vtable{width:100%;border-collapse:collapse;font-size:12.5px;}
.vtable th{background:#f8fafc;color:#475569;font-size:11px;text-transform:uppercase;letter-spacing:.3px;text-align:left;padding:9px 8px;border-bottom:1px solid #e2e8f0;white-space:nowrap;position:sticky;top:0;}
.vtable td{padding:8px;border-bottom:1px solid #f1f5f9;vertical-align:middle;}
.vtable tr:hover td{background:#fafbff;}
.vtable tr.no-match{display:none;}
.t-school{font-weight:700;color:#1e293b;}
.t-sub{font-size:11px;color:#64748b;}
.t-reason{font-size:11px;color:#991b1b;}
</style>
</head>
<body>
<div class="header">
    <h1>🧪 VidnyanSetu 2 Report — <%= esc(districtName) %><%= prevYear ? " (Previous year)" : "" %></h1>
    <p>STEM activities (classes VI–IX) logged by schools in the district, with approval status</p>
    <a class="back" href="<%= request.getContextPath() %>/district-dashboard.jsp">← District Dashboard</a>
    <a class="back" href="<%= request.getContextPath() %>/district-vidnyansetu2-report.jsp<%= prevYear ? "" : "?prevYear=1" %>"><%= prevYear ? "📅 Current year" : "🕘 Previous year" %></a>
</div>

<div class="wrap">
        <div class="stat-grid">
            <div class="stat-card" data-st="" onclick="setStatus('')"><div class="n" id="statTotal"><%= total %></div><div class="k">Activities Logged</div></div>
            <div class="stat-card" data-st="PENDING" onclick="setStatus('PENDING')"><div class="n" id="statPending"><%= pending %></div><div class="k">Pending HM Approval</div></div>
            <div class="stat-card" data-st="APPROVED" onclick="setStatus('APPROVED')"><div class="n" id="statApproved"><%= approved %></div><div class="k">Approved</div></div>
            <div class="stat-card" data-st="REJECTED" onclick="setStatus('REJECTED')"><div class="n" id="statRejected"><%= rejected %></div><div class="k">Rejected</div></div>
        </div>

        <% if (!bySchool.isEmpty()) { %>
        <div class="card" style="margin-bottom:22px;">
            <h3 style="font-size:15px;margin-bottom:12px;">🏫 School-wise</h3>
            <div class="vtable-wrap">
            <table class="vtable">
                <thead><tr><th>School</th><th>Logged</th><th>Pending</th><th>Approved</th><th>Rejected</th></tr></thead>
                <tbody>
                <% for (Map.Entry<String,Object[]> e : bySchool.entrySet()) { Object[] sc = e.getValue(); %>
                    <tr>
                        <td><div class="t-school"><%= esc((String) sc[0]) %></div><div class="t-sub">UDISE <%= esc(e.getKey()) %></div></td>
                        <td><strong><%= sc[1] %></strong></td><td><%= sc[2] %></td><td><%= sc[3] %></td><td><%= sc[4] %></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
            </div>
        </div>
        <% } %>

        <div class="card">
            <% if (acts.isEmpty()) { %>
                <div class="empty">No VidnyanSetu 2 activities logged yet in this district.</div>
            <% } else { %>
                <div class="toolbar">
                    <input type="text" id="searchBox" placeholder="Search by school, teacher, activity, class..." oninput="filterRows()">
                    <select id="statusFilter" onchange="filterRows()">
                        <option value="">All statuses</option>
                        <option value="PENDING">Pending</option>
                        <option value="APPROVED">Approved</option>
                        <option value="REJECTED">Rejected</option>
                    </select>
                    <span class="count" id="visibleCount"></span>
                </div>
                <div class="filters">
                    <label>शाळा (School)
                        <select id="schoolFilter" onchange="filterRows()">
                            <option value="">All schools</option>
                            <% for (Map.Entry<String,String> s : fSchools.entrySet()) { %>
                                <option value="<%= esc(s.getKey()) %>" data-district="<%= esc(fSchoolDistrict.get(s.getKey())) %>"><%= esc(s.getValue()) %> (<%= esc(s.getKey()) %>)</option>
                            <% } %>
                        </select>
                    </label>
                    <label>इयत्ता (Class)
                        <select id="classFilter" onchange="filterRows()">
                            <option value="">All classes</option>
                            <% for (String c : fClasses) { %><option value="<%= esc(c) %>"><%= esc(c) %></option><% } %>
                        </select>
                    </label>
                    <label>उपक्रम (Activity)
                        <select id="activityFilter" onchange="filterRows()">
                            <option value="">All activities</option>
                            <% for (Map.Entry<Integer,String> a : fActivities.entrySet()) { %><option value="<%= a.getKey() %>"><%= a.getKey() %>. <%= esc(a.getValue()) %></option><% } %>
                        </select>
                    </label>
                    <label>Activity date from
                        <input type="date" id="dateFrom" onchange="filterRows()">
                    </label>
                    <label>Activity date to
                        <input type="date" id="dateTo" onchange="filterRows()">
                    </label>
                    <button type="button" class="reset-btn" onclick="resetFilters()">↺ Reset filters</button>
                </div>

                <div class="vtable-wrap">
                <table class="vtable" id="actTable">
                    <thead><tr>
                        <th>#</th><th>School</th><th>Class</th>
                        <th>STEM Activity</th><th>Activity date</th><th>Notes</th><th>Uploaded by</th><th>Status</th>
                    </tr></thead>
                    <tbody>
                    <% for (Map<String,Object> v : acts) {
                        String status = (String) v.get("status");
                        String statusChip = "PENDING".equals(status) ? "chip-pending" : "APPROVED".equals(status) ? "chip-approved" : "chip-rejected";
                        String statusLabel = "PENDING".equals(status) ? "Pending" : "APPROVED".equals(status) ? "Approved" : "Rejected";
                        String clsSec = v.get("section") != null ? v.get("cls") + "-" + v.get("section") : (String) v.get("cls");
                        String searchBlob = (esc((String)v.get("school")) + " " + esc((String)v.get("createdBy")) + " " +
                                              esc((String)v.get("activityName")) + " " + esc(clsSec))
                                              .toLowerCase();
                    %>
                        <tr data-search="<%= searchBlob %>" data-status="<%= esc(status) %>"
                            data-udise="<%= esc((String)v.get("udise")) %>"
                            data-class="<%= esc((String)v.get("cls")) %>" data-activity="<%= v.get("activityNo") %>"
                            data-date="<%= v.get("date") != null ? v.get("date").toString() : "" %>">
                            <td class="t-sub row-no"></td>
                            <td><div class="t-school"><%= esc((String)v.get("school")) %></div><div class="t-sub">UDISE <%= esc((String)v.get("udise")) %></div></td>
                            <td><%= esc(clsSec) %></td>
                            <td><strong><%= v.get("activityNo") %>.</strong> <%= esc((String)v.get("activityName")) %></td>
                            <td style="white-space:nowrap"><%= v.get("date") != null ? v.get("date") : "—" %></td>
                            <td><%= v.get("desc") != null && !((String)v.get("desc")).isEmpty() ? esc((String)v.get("desc")) : "<span class='t-sub'>—</span>" %></td>
                            <td><%= esc((String)v.get("createdBy")) %><% if (v.get("createdDate") != null) { %><div class="t-sub"><%= v.get("createdDate").toString().substring(0, 16) %></div><% } %></td>
                            <td><span class="chip <%= statusChip %>"><%= statusLabel %></span>
                                <% if ("REJECTED".equals(status) && v.get("rejectionReason") != null) { %><div class="t-reason">⚠️ <%= esc((String)v.get("rejectionReason")) %></div>
                                <% } else if ("APPROVED".equals(status) && v.get("approvedBy") != null) { %><div class="t-sub">✅ <%= esc((String)v.get("approvedBy")) %></div><% } %></td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
                </div>
            <% } %>
        </div>
</div>

<script>
function val(id) { var el = document.getElementById(id); return el ? el.value : ''; }

function filterRows() {
    var q = val('searchBox').trim().toLowerCase();
    var st = val('statusFilter');
    var udise = val('schoolFilter'), cls = val('classFilter'), act = val('activityFilter');
    var from = val('dateFrom'), to = val('dateTo');
    var rows = document.querySelectorAll('#actTable tbody tr');
    var visible = 0, counts = { total: 0, PENDING: 0, APPROVED: 0, REJECTED: 0 };
    rows.forEach(function(r) {
        var d = r.getAttribute('data-date');
        // Everything except status -- these drive the stat cards
        var matchOther =
            (!q || r.getAttribute('data-search').indexOf(q) !== -1) &&
            (!udise || r.getAttribute('data-udise') === udise) &&
            (!cls || r.getAttribute('data-class') === cls) &&
            (!act || r.getAttribute('data-activity') === act) &&
            (!from || (d && d >= from)) &&
            (!to || (d && d <= to));
        if (matchOther) {
            counts.total++;
            var s = r.getAttribute('data-status');
            if (counts[s] !== undefined) counts[s]++;
        }
        var match = matchOther && (!st || r.getAttribute('data-status') === st);
        r.classList.toggle('no-match', !match);
        if (match) r.querySelector('.row-no').textContent = ++visible;
    });
    document.getElementById('visibleCount').textContent = visible + ' / ' + rows.length + ' activities';
    document.getElementById('statTotal').textContent = counts.total;
    document.getElementById('statPending').textContent = counts.PENDING;
    document.getElementById('statApproved').textContent = counts.APPROVED;
    document.getElementById('statRejected').textContent = counts.REJECTED;
    document.querySelectorAll('.stat-card[data-st]').forEach(function(sc) {
        sc.classList.toggle('active', sc.getAttribute('data-st') === st);
    });
}

function setStatus(st) {
    var sf = document.getElementById('statusFilter');
    if (!sf) return;
    sf.value = st;
    filterRows();
}

function resetFilters() {
    ['searchBox','statusFilter','schoolFilter','classFilter','activityFilter','dateFrom','dateTo']
        .forEach(function(id) { var el = document.getElementById(id); if (el) el.value = ''; });
    filterRows();
}

if (document.getElementById('searchBox')) filterRows();

</script>
</body>
</html>
