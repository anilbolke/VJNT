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
    // VidnyanSetu 2 (STEM, classes VI..IX) activities across a division, WITH
    // video. Same scoping as division-vidnyansetu-videos.jsp: DIVISION sees its
    // own division, SDO picks one with ?division=. The district counterpart
    // (no video) is district-vidnyansetu2-report.jsp.
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DIVISION)
                      && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    com.vjnt.dao.VidnyanSetu2ActivityDAO.ensureSchema();

    boolean isSdo = user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER);
    String dashboardUrl = isSdo ? "/super-officer-dashboard.jsp" : "/division-dashboard.jsp";

    String divisionName = isSdo ? request.getParameter("division") : user.getDivisionName();
    boolean prevYear = "1".equals(request.getParameter("prevYear"));
    if (divisionName != null) divisionName = divisionName.trim();
    boolean hasDivision = divisionName != null && !divisionName.isEmpty();

    List<String> allDivisions = new ArrayList<>();
    if (isSdo) {
        try (Connection c = DatabaseConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(
                 "SELECT DISTINCT division FROM teacher_assignments " +
                 "WHERE is_active = 1 AND division IS NOT NULL AND division <> '' ORDER BY division");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) allDivisions.add(rs.getString(1));
        } catch (Exception e) { /* picker just stays empty */ }
    }

    List<Map<String,Object>> videos = new ArrayList<>();
    int total = 0, pending = 0, approved = 0, rejected = 0;

    if (hasDivision) try (Connection conn = DatabaseConnection.getConnection()) {
        List<String> udiseList = new ArrayList<>();
        Map<String,String> udiseToDistrict = new HashMap<>();
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT DISTINCT udise_code, district FROM teacher_assignments WHERE division = ? AND is_active = 1")) {
            ps.setString(1, divisionName);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String u = rs.getString("udise_code");
                    udiseList.add(u);
                    udiseToDistrict.put(u, rs.getString("district"));
                }
            }
        }

        if (!udiseList.isEmpty()) {
            String sql =
                "SELECT a.activity_id, a.udise_no, s.school_name, a.student_class, a.student_section, " +
                "       a.activity_no, a.activity_name, a.activity_date, a.description, a.created_by, a.created_date, " +
                "       a.video_url, a.video_filename, a.video_size, a.video_thumbnail_url, " +
                "       a.approval_status, a.approved_by_name, a.approval_date, a.rejection_reason " +
                "FROM vidnyansetu2_activities a " +
                "JOIN schools s ON s.udise_no = a.udise_no " +
                "WHERE a.udise_no IN (" + placeholders(udiseList.size()) + ") " +
                "  AND a.archived_promotion_id " + (prevYear ? "IS NOT NULL " : "IS NULL ") +
                "ORDER BY a.created_date DESC";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                int i = 1; for (String u : udiseList) ps.setString(i++, u);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String,Object> v = new LinkedHashMap<>();
                        String udise = rs.getString("udise_no");
                        v.put("udise", udise);
                        v.put("school", rs.getString("school_name"));
                        v.put("district", udiseToDistrict.get(udise));
                        v.put("cls", rs.getString("student_class"));
                        v.put("section", rs.getString("student_section"));
                        v.put("activityNo", rs.getInt("activity_no"));
                        v.put("activityName", rs.getString("activity_name"));
                        v.put("date", rs.getDate("activity_date"));
                        v.put("desc", rs.getString("description"));
                        v.put("createdBy", rs.getString("created_by"));
                        v.put("createdDate", rs.getTimestamp("created_date"));
                        v.put("videoUrl", rs.getString("video_url"));
                        v.put("videoFilename", rs.getString("video_filename"));
                        v.put("videoSize", rs.getLong("video_size"));
                        v.put("thumb", rs.getString("video_thumbnail_url"));
                        String status = rs.getString("approval_status");
                        v.put("status", status);
                        v.put("approvedBy", rs.getString("approved_by_name"));
                        v.put("approvalDate", rs.getTimestamp("approval_date"));
                        v.put("rejectionReason", rs.getString("rejection_reason"));
                        videos.add(v);
                        total++;
                        if ("PENDING".equals(status)) pending++;
                        else if ("APPROVED".equals(status)) approved++;
                        else if ("REJECTED".equals(status)) rejected++;
                    }
                }
            }
        }
    }

    // Filter option lists, built from the loaded rows
    TreeSet<String> fDistricts = new TreeSet<>();
    TreeMap<String,String> fSchools = new TreeMap<>();          // udise -> school name
    Map<String,String> fSchoolDistrict = new HashMap<>();      // udise -> district
    List<String> classOrder = com.vjnt.dao.VidnyanSetu2ActivityDAO.CLASSES;
    TreeSet<String> fClasses = new TreeSet<>(Comparator.comparingInt((String c) -> classOrder.indexOf(c) < 0 ? 99 : classOrder.indexOf(c)).thenComparing(c -> c));
    TreeMap<Integer,String> fActivities = new TreeMap<>();     // activity_no -> name
    for (Map<String,Object> v : videos) {
        String d = (String) v.get("district");
        if (d != null && !d.isEmpty()) fDistricts.add(d);
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
<title>VidnyanSetu 2 Videos<%= hasDivision ? " - " + esc(divisionName) : "" %></title>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f2f5;color:#1e293b;}
.header{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff;padding:28px 30px;}
.header h1{font-size:22px;font-weight:800;margin-bottom:6px;}
.header p{font-size:14px;opacity:.9;}
.header .back{display:inline-block;margin-top:14px;background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.35);color:#fff;text-decoration:none;padding:7px 14px;border-radius:20px;font-size:13px;}
.header .back:hover{background:rgba(255,255,255,.25);}
.wrap{max-width:1300px;margin:24px auto;padding:0 20px 60px;}
.division-form{background:#fff;border-radius:10px;box-shadow:0 2px 8px rgba(0,0,0,.06);padding:20px;display:flex;gap:10px;align-items:center;margin-bottom:22px;}
.division-form select{flex:1;max-width:320px;padding:9px 12px;border:1px solid #cbd5e1;border-radius:7px;font-size:14px;}
.division-form button{background:#667eea;color:#fff;border:none;padding:9px 20px;border-radius:7px;font-size:14px;font-weight:700;cursor:pointer;}
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
.mini-thumb{width:84px;height:50px;border-radius:5px;background:#0f172a;position:relative;cursor:pointer;overflow:hidden;}
.mini-thumb img{width:100%;height:100%;object-fit:cover;display:block;}
.mini-thumb span{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;color:#fff;font-size:18px;text-shadow:0 1px 4px rgba(0,0,0,.6);}
.t-school{font-weight:700;color:#1e293b;}
.t-sub{font-size:11px;color:#64748b;}
.t-reason{font-size:11px;color:#991b1b;}
.video-modal-overlay{display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.85);z-index:1050;align-items:center;justify-content:center;padding:20px;}
.video-modal-box{position:relative;width:100%;max-width:900px;}
.video-modal-close{position:absolute;top:-40px;right:0;background:none;border:none;color:#fff;font-size:32px;line-height:1;cursor:pointer;}
</style>
</head>
<body>
<div class="header">
    <h1>🧪 VidnyanSetu 2 Videos<%= hasDivision ? " — " + esc(divisionName) : "" %><%= prevYear ? " (Previous year)" : "" %></h1>
    <p>STEM activity videos (classes VI–IX) logged across the division, with upload and approval detail</p>
    <a class="back" href="<%= request.getContextPath() + dashboardUrl %>">← <%= isSdo ? "Super Officer" : "Division" %> Dashboard</a>
    <% String yearHref = request.getContextPath() + "/division-vidnyansetu2-videos.jsp?" +
           (isSdo && hasDivision ? "division=" + java.net.URLEncoder.encode(divisionName, "UTF-8") + "&" : "") +
           (prevYear ? "" : "prevYear=1"); %>
    <a class="back" href="<%= esc(yearHref) %>"><%= prevYear ? "📅 Current year" : "🕘 Previous year" %></a>
</div>

<div class="wrap">
    <% if (isSdo) { %>
    <form method="get" action="<%= request.getContextPath() %>/division-vidnyansetu2-videos.jsp" class="division-form">
        <% if (prevYear) { %><input type="hidden" name="prevYear" value="1"><% } %>
        <select name="division">
            <option value="">-- विभाग निवडा (Select Division) --</option>
            <% for (String d : allDivisions) { %>
                <option value="<%= esc(d) %>" <%= (hasDivision && d.equals(divisionName)) ? "selected" : "" %>><%= esc(d) %></option>
            <% } %>
        </select>
        <button type="submit">पहा (View)</button>
    </form>
    <% } %>

    <% if (!hasDivision) { %>
        <div class="card"><div class="empty"><%= isSdo ? "Select a division above to view its videos." : "No division set on this account." %></div></div>
    <% } else { %>

        <div class="stat-grid">
            <div class="stat-card" data-st="" onclick="setStatus('')"><div class="n" id="statTotal"><%= total %></div><div class="k">Total Videos</div></div>
            <div class="stat-card" data-st="PENDING" onclick="setStatus('PENDING')"><div class="n" id="statPending"><%= pending %></div><div class="k">Pending HM Approval</div></div>
            <div class="stat-card" data-st="APPROVED" onclick="setStatus('APPROVED')"><div class="n" id="statApproved"><%= approved %></div><div class="k">Approved</div></div>
            <div class="stat-card" data-st="REJECTED" onclick="setStatus('REJECTED')"><div class="n" id="statRejected"><%= rejected %></div><div class="k">Rejected</div></div>
        </div>

        <div class="card">
            <% if (videos.isEmpty()) { %>
                <div class="empty">No VidnyanSetu 2 activity videos logged yet for this division.</div>
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
                    <label>जिल्हा (District)
                        <select id="districtFilter" onchange="onDistrictChange()">
                            <option value="">All districts</option>
                            <% for (String d : fDistricts) { %><option value="<%= esc(d) %>"><%= esc(d) %></option><% } %>
                        </select>
                    </label>
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
                <table class="vtable" id="videoTable">
                    <thead><tr>
                        <th>#</th><th>Video</th><th>District</th><th>School</th><th>Class</th>
                        <th>STEM Activity</th><th>Activity date</th><th>Notes</th><th>Uploaded by</th><th>Status</th>
                    </tr></thead>
                    <tbody>
                    <% for (Map<String,Object> v : videos) {
                        String status = (String) v.get("status");
                        String statusChip = "PENDING".equals(status) ? "chip-pending" : "APPROVED".equals(status) ? "chip-approved" : "chip-rejected";
                        String statusLabel = "PENDING".equals(status) ? "Pending" : "APPROVED".equals(status) ? "Approved" : "Rejected";
                        String clsSec = v.get("section") != null ? v.get("cls") + "-" + v.get("section") : (String) v.get("cls");
                        String searchBlob = (esc((String)v.get("school")) + " " + esc((String)v.get("createdBy")) + " " +
                                              esc((String)v.get("activityName")) + " " + esc(clsSec) + " " + esc((String)v.get("district")))
                                              .toLowerCase();
                        long sizeKb = ((Long) v.get("videoSize")) / 1024;
                    %>
                        <tr data-search="<%= searchBlob %>" data-status="<%= esc(status) %>"
                            data-district="<%= esc((String)v.get("district")) %>" data-udise="<%= esc((String)v.get("udise")) %>"
                            data-class="<%= esc((String)v.get("cls")) %>" data-activity="<%= v.get("activityNo") %>"
                            data-date="<%= v.get("date") != null ? v.get("date").toString() : "" %>">
                            <td class="t-sub row-no"></td>
                            <td><div class="mini-thumb" data-video-url="<%= esc((String)v.get("videoUrl")) %>" onclick="openVideoModal(this.getAttribute('data-video-url'))"
                                     title="<%= esc((String)v.get("videoFilename")) %><%= sizeKb > 0 ? " · " + sizeKb + " KB" : "" %>">
                                <% if (v.get("thumb") != null) { %><img src="<%= esc((String)v.get("thumb")) %>" alt="" loading="lazy"><% } %><span>▶</span></div></td>
                            <td><%= esc((String)v.get("district")) %></td>
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

    <% } %>
</div>

<div id="videoModalOverlay" class="video-modal-overlay" onclick="if (event.target === this) closeVideoModal()">
    <div class="video-modal-box">
        <button type="button" class="video-modal-close" onclick="closeVideoModal()" aria-label="Close">&times;</button>
        <video id="videoModalPlayer" controls autoplay style="width:100%; max-height:80vh; border-radius:8px; background:#000;"></video>
    </div>
</div>

<script>
function val(id) { var el = document.getElementById(id); return el ? el.value : ''; }

function filterRows() {
    var q = val('searchBox').trim().toLowerCase();
    var st = val('statusFilter');
    var dist = val('districtFilter'), udise = val('schoolFilter'), cls = val('classFilter'), act = val('activityFilter');
    var from = val('dateFrom'), to = val('dateTo');
    var rows = document.querySelectorAll('#videoTable tbody tr');
    var visible = 0, counts = { total: 0, PENDING: 0, APPROVED: 0, REJECTED: 0 };
    rows.forEach(function(r) {
        var d = r.getAttribute('data-date');
        // Everything except status -- these drive the stat cards
        var matchOther =
            (!q || r.getAttribute('data-search').indexOf(q) !== -1) &&
            (!dist || r.getAttribute('data-district') === dist) &&
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
    document.getElementById('visibleCount').textContent = visible + ' / ' + rows.length + ' videos';
    document.getElementById('statTotal').textContent = counts.total;
    document.getElementById('statPending').textContent = counts.PENDING;
    document.getElementById('statApproved').textContent = counts.APPROVED;
    document.getElementById('statRejected').textContent = counts.REJECTED;
    document.querySelectorAll('.stat-card[data-st]').forEach(function(sc) {
        sc.classList.toggle('active', sc.getAttribute('data-st') === st);
    });
}

function onDistrictChange() {
    var key = val('districtFilter'), sel = document.getElementById('schoolFilter');
    Array.prototype.forEach.call(sel.options, function(o) {
        if (!o.value) return;
        var show = !key || o.getAttribute('data-district') === key;
        o.hidden = !show; o.disabled = !show;
    });
    if (sel.selectedOptions[0] && sel.selectedOptions[0].disabled) sel.value = '';
    filterRows();
}

function setStatus(st) {
    var sf = document.getElementById('statusFilter');
    if (!sf) return;
    sf.value = st;
    filterRows();
}

function resetFilters() {
    ['searchBox','statusFilter','districtFilter','schoolFilter','classFilter','activityFilter','dateFrom','dateTo']
        .forEach(function(id) { var el = document.getElementById(id); if (el) el.value = ''; });
    onDistrictChange();
}

if (document.getElementById('searchBox')) filterRows();

function openVideoModal(url) {
    var player = document.getElementById('videoModalPlayer');
    player.src = url;
    document.getElementById('videoModalOverlay').style.display = 'flex';
}
function closeVideoModal() {
    var player = document.getElementById('videoModalPlayer');
    player.pause();
    player.src = '';
    document.getElementById('videoModalOverlay').style.display = 'none';
}
document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeVideoModal(); });
</script>
</body>
</html>
