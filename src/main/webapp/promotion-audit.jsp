<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.vjnt.model.User,com.vjnt.util.DatabaseConnection,java.sql.*,java.util.*,java.text.SimpleDateFormat" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    // Fetch all promotion log entries
    List<Map<String,Object>> promotions = new ArrayList<>();
    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, hh:mm a");
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(
             "SELECT * FROM class_promotion_log ORDER BY promotion_date DESC");
         ResultSet rs = ps.executeQuery()) {
        while (rs.next()) {
            Map<String,Object> m = new LinkedHashMap<>();
            m.put("id",         rs.getLong("promotion_id"));
            m.put("year",       rs.getString("academic_year"));
            m.put("by",         rs.getString("promoted_by"));
            m.put("date",       rs.getTimestamp("promotion_date") != null
                                 ? sdf.format(rs.getTimestamp("promotion_date")) : "—");
            m.put("promoted",   rs.getInt("students_promoted"));
            m.put("graduated",  rs.getInt("students_graduated"));
            m.put("remarks",    rs.getString("remarks") != null ? rs.getString("remarks") : "");
            promotions.add(m);
        }
    } catch (Exception e) {
        // table may not exist yet
    }

    // Detail view: single promotion
    long detailId = 0;
    String detailParam = request.getParameter("detailId");
    if (detailParam != null) {
        try { detailId = Long.parseLong(detailParam); } catch (Exception ex) {}
    }

    // Filter params for detail
    String filterDiv  = request.getParameter("division") != null ? request.getParameter("division").trim() : "";
    String filterDist = request.getParameter("district") != null ? request.getParameter("district").trim() : "";
    String filterUdise= request.getParameter("udise")    != null ? request.getParameter("udise").trim()    : "";

    List<Map<String,Object>> detailRows = new ArrayList<>();
    String detailYear = "";
    if (detailId > 0) {
        // Fetch year for title
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT academic_year FROM class_promotion_log WHERE promotion_id=?")) {
            ps.setLong(1, detailId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) detailYear = rs.getString("academic_year");
        } catch (Exception ex) {}

        // Build query with optional filters
        StringBuilder sql = new StringBuilder(
            "SELECT student_name, student_pen, udise_no, division, district, " +
            "class_before, class_after, " +
            "phase1_marathi, phase1_math, phase1_english, " +
            "phase2_marathi, phase2_math, phase2_english, " +
            "phase3_marathi, phase3_math, phase3_english, " +
            "phase4_marathi, phase4_math, phase4_english " +
            "FROM student_phase_history WHERE promotion_id=?");
        if (!filterDiv.isEmpty())  sql.append(" AND division=?");
        if (!filterDist.isEmpty()) sql.append(" AND district=?");
        if (!filterUdise.isEmpty()) sql.append(" AND udise_no=?");
        sql.append(" ORDER BY division, district, udise_no, student_name LIMIT 500");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            ps.setLong(idx++, detailId);
            if (!filterDiv.isEmpty())  ps.setString(idx++, filterDiv);
            if (!filterDist.isEmpty()) ps.setString(idx++, filterDist);
            if (!filterUdise.isEmpty()) ps.setString(idx++, filterUdise);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String,Object> r = new LinkedHashMap<>();
                r.put("name",       rs.getString("student_name"));
                r.put("pen",        rs.getString("student_pen"));
                r.put("udise",      rs.getString("udise_no"));
                r.put("division",   rs.getString("division"));
                r.put("district",   rs.getString("district"));
                r.put("before",     rs.getString("class_before"));
                r.put("after",      rs.getString("class_after"));
                r.put("p1m",        rs.getObject("phase1_marathi"));
                r.put("p1mt",       rs.getObject("phase1_math"));
                r.put("p1e",        rs.getObject("phase1_english"));
                r.put("p4m",        rs.getObject("phase4_marathi"));
                r.put("p4mt",       rs.getObject("phase4_math"));
                r.put("p4e",        rs.getObject("phase4_english"));
                detailRows.add(r);
            }
        } catch (Exception ex) {}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Promotion Audit — GATEE Portal</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box;}
    body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f2f5;padding:24px;}
    .container{max-width:1100px;margin:0 auto;}
    .header{background:#fff;border-radius:12px;padding:22px 28px;margin-bottom:22px;
            box-shadow:0 2px 8px rgba(0,0,0,.07);display:flex;align-items:center;justify-content:space-between;}
    .header h1{font-size:22px;font-weight:700;color:#2d3748;display:flex;align-items:center;gap:10px;}
    .back-btn{background:#667eea;color:#fff;border:none;border-radius:8px;padding:9px 18px;
              font-size:14px;font-weight:600;cursor:pointer;text-decoration:none;display:inline-block;}
    .back-btn:hover{background:#5a67d8;}
    .card{background:#fff;border-radius:12px;padding:24px;margin-bottom:20px;box-shadow:0 2px 8px rgba(0,0,0,.07);}
    .card h2{font-size:17px;font-weight:700;margin-bottom:16px;color:#2d3748;}
    table{width:100%;border-collapse:collapse;font-size:13.5px;}
    th{background:#667eea;color:#fff;padding:10px 14px;text-align:left;font-weight:600;}
    td{padding:10px 14px;border-bottom:1px solid #e2e8f0;vertical-align:middle;}
    tr:last-child td{border-bottom:none;}
    tr:hover td{background:#f7f8fc;}
    .btn-sm{display:inline-block;padding:5px 12px;border-radius:6px;font-size:12px;font-weight:600;
             text-decoration:none;cursor:pointer;border:none;}
    .btn-detail{background:#ebf8ff;color:#2c5282;}
    .btn-detail:hover{background:#bee3f8;}
    .badge-promoted{background:#c6f6d5;color:#276749;border-radius:5px;padding:2px 8px;font-size:12px;font-weight:600;}
    .badge-grad{background:#fbd38d;color:#7c2d12;border-radius:5px;padding:2px 8px;font-size:12px;font-weight:600;}
    .badge-after{font-weight:700;}
    .grad-after{color:#d69e2e;}
    .empty{text-align:center;padding:40px;color:#718096;font-size:15px;}
    .filter-form{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:18px;}
    .filter-form input{flex:1;min-width:160px;border:1px solid #e2e8f0;border-radius:7px;
                       padding:8px 12px;font-size:13px;outline:none;}
    .filter-form input:focus{border-color:#667eea;}
    .filter-form button{background:#667eea;color:#fff;border:none;border-radius:7px;padding:8px 18px;
                        font-size:13px;font-weight:600;cursor:pointer;}
    .filter-form .clear-btn{background:#e2e8f0;color:#4a5568;}
    .detail-title{display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;}
    .count-note{font-size:12px;color:#718096;margin-top:6px;}
    td .null-val{color:#cbd5e0;font-style:italic;}
  </style>
</head>
<body>
<div class="container">

  <div class="header">
    <h1>📋 Promotion Audit Log</h1>
    <a href="<%= request.getContextPath() %>/data-admin-dashboard.jsp" class="back-btn">← Dashboard</a>
  </div>

  <%-- ── DETAIL VIEW ── --%>
  <% if (detailId > 0) { %>
  <div class="card">
    <div class="detail-title">
      <h2>📄 Promotion #<%= detailId %> — Academic Year: <%= detailYear %></h2>
      <a href="<%= request.getContextPath() %>/promotion-audit.jsp" class="btn-sm btn-detail">← All Promotions</a>
    </div>

    <form method="get" action="<%= request.getContextPath() %>/promotion-audit.jsp" class="filter-form">
      <input type="hidden" name="detailId" value="<%= detailId %>"/>
      <input type="text"   name="division" placeholder="Filter: Division"  value="<%= filterDiv %>"/>
      <input type="text"   name="district" placeholder="Filter: District"  value="<%= filterDist %>"/>
      <input type="text"   name="udise"    placeholder="Filter: UDISE No"  value="<%= filterUdise %>"/>
      <button type="submit">Filter</button>
      <a href="<%= request.getContextPath() %>/promotion-audit.jsp?detailId=<%= detailId %>" class="btn-sm clear-btn" style="padding:8px 14px;border-radius:7px;">Clear</a>
    </form>

    <% if (detailRows.isEmpty()) { %>
      <div class="empty">No records found for the selected filters.</div>
    <% } else { %>
      <p class="count-note">Showing <%= detailRows.size() %> records (max 500). Use filters to narrow down.</p>
      <div style="overflow-x:auto;margin-top:12px;">
      <table>
        <thead>
          <tr>
            <th>Student Name</th><th>PEN</th><th>Division</th><th>District</th>
            <th>UDISE</th><th>Class Before</th><th>Class After</th>
            <th>P1 Mar</th><th>P1 Math</th><th>P1 Eng</th>
            <th>P4 Mar</th><th>P4 Math</th><th>P4 Eng</th>
          </tr>
        </thead>
        <tbody>
          <% for (Map<String,Object> r : detailRows) {
               boolean isGrad = "GRADUATED".equals(r.get("after")); %>
          <tr>
            <td><%= r.get("name") %></td>
            <td><%= r.get("pen") %></td>
            <td><%= r.get("division") %></td>
            <td><%= r.get("district") %></td>
            <td style="font-family:monospace;font-size:12px;"><%= r.get("udise") %></td>
            <td>Class <%= r.get("before") %></td>
            <td class="badge-after <%= isGrad ? "grad-after" : "" %>">
              <%= isGrad ? "🎓 Graduated" : "Class " + r.get("after") %>
            </td>
            <td><%= r.get("p1m")  != null ? r.get("p1m")  : "<span class='null-val'>—</span>" %></td>
            <td><%= r.get("p1mt") != null ? r.get("p1mt") : "<span class='null-val'>—</span>" %></td>
            <td><%= r.get("p1e")  != null ? r.get("p1e")  : "<span class='null-val'>—</span>" %></td>
            <td><%= r.get("p4m")  != null ? r.get("p4m")  : "<span class='null-val'>—</span>" %></td>
            <td><%= r.get("p4mt") != null ? r.get("p4mt") : "<span class='null-val'>—</span>" %></td>
            <td><%= r.get("p4e")  != null ? r.get("p4e")  : "<span class='null-val'>—</span>" %></td>
          </tr>
          <% } %>
        </tbody>
      </table>
      </div>
    <% } %>
  </div>

  <%-- ── MAIN LIST VIEW ── --%>
  <% } else { %>
  <div class="card">
    <h2>All Promotion Events</h2>
    <% if (promotions.isEmpty()) { %>
      <div class="empty">No promotions have been run yet.</div>
    <% } else { %>
    <table>
      <thead>
        <tr>
          <th>#ID</th><th>Academic Year</th><th>Promotion Date</th>
          <th>Run By</th><th>Promoted</th><th>Graduated</th><th>Remarks</th><th>Details</th>
        </tr>
      </thead>
      <tbody>
        <% for (Map<String,Object> p : promotions) { %>
        <tr>
          <td><strong><%= p.get("id") %></strong></td>
          <td><%= p.get("year") %></td>
          <td><%= p.get("date") %></td>
          <td><%= p.get("by") %></td>
          <td><span class="badge-promoted"><%= p.get("promoted") %> students</span></td>
          <td><span class="badge-grad"><%= p.get("graduated") %> graduated</span></td>
          <td style="max-width:180px;font-size:12px;color:#718096;"><%= p.get("remarks") %></td>
          <td>
            <a href="<%= request.getContextPath() %>/promotion-audit.jsp?detailId=<%= p.get("id") %>"
               class="btn-sm btn-detail">View →</a>
          </td>
        </tr>
        <% } %>
      </tbody>
    </table>
    <% } %>
  </div>
  <% } %>

</div>
</body>
</html>
