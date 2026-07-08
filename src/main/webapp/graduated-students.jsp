<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.vjnt.model.User,com.vjnt.util.DatabaseConnection,java.sql.*,java.util.*,java.text.SimpleDateFormat" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    User.UserType uType = user.getUserType();
    boolean isAdmin    = uType.equals(User.UserType.DATA_ADMIN);
    boolean isSchool   = uType.equals(User.UserType.SCHOOL_COORDINATOR) || uType.equals(User.UserType.HEAD_MASTER);
    boolean isDistrict = uType.equals(User.UserType.DISTRICT_COORDINATOR) || uType.equals(User.UserType.DISTRICT_2ND_COORDINATOR);
    boolean isDivision = uType.equals(User.UserType.DIVISION) || uType.equals(User.UserType.SUPER_DIVISION_OFFICER);

    if (!isAdmin && !isSchool && !isDistrict && !isDivision) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    // Filter params
    String filterYear  = request.getParameter("year")     != null ? request.getParameter("year").trim()     : "";
    String filterDiv   = request.getParameter("division")  != null ? request.getParameter("division").trim()  : "";
    String filterDist  = request.getParameter("district")  != null ? request.getParameter("district").trim()  : "";
    String filterUdise = request.getParameter("udise")     != null ? request.getParameter("udise").trim()     : "";
    String filterName  = request.getParameter("name")      != null ? request.getParameter("name").trim()      : "";
    int page_g = 1;
    try { page_g = Math.max(1, Integer.parseInt(request.getParameter("page"))); } catch (Exception ex) {}
    int pageSize = 50;
    int offset   = (page_g - 1) * pageSize;

    // Build WHERE clause — scope by role
    StringBuilder where = new StringBuilder(" WHERE 1=1");
    List<String> params = new ArrayList<>();
    if (isSchool) {
        // Lock to own UDISE; ignore any udise param from URL
        where.append(" AND udise_no=?");
        params.add(user.getUdiseNo());
    } else if (isDistrict) {
        where.append(" AND district=?");
        params.add(user.getDistrictName());
    } else if (isDivision && !isAdmin) {
        where.append(" AND division=?");
        params.add(user.getDivisionName());
    }
    if (!filterYear.isEmpty())  { where.append(" AND academic_year=?");       params.add(filterYear); }
    if (!isSchool && !filterDiv.isEmpty())   { where.append(" AND division=?");  params.add(filterDiv); }
    if (!isSchool && !isDistrict && !filterDist.isEmpty()) { where.append(" AND district=?"); params.add(filterDist); }
    if (!isSchool && !filterUdise.isEmpty()) { where.append(" AND udise_no=?");  params.add(filterUdise); }
    if (!filterName.isEmpty())  { where.append(" AND student_name LIKE ?");    params.add("%" + filterName + "%"); }

    // Distinct years for dropdown
    List<String> years = new ArrayList<>();
    int totalCount = 0;
    List<Map<String,Object>> rows = new ArrayList<>();
    int totalGradAll = 0;

    try (Connection conn = DatabaseConnection.getConnection()) {

        // Distinct academic years
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT DISTINCT academic_year FROM graduated_students ORDER BY academic_year DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) years.add(rs.getString("academic_year"));
        }

        // Total graduated (all time)
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM graduated_students");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) totalGradAll = rs.getInt(1);
        }

        // Count with filters
        String countSql = "SELECT COUNT(*) FROM graduated_students" + where;
        try (PreparedStatement ps = conn.prepareStatement(countSql)) {
            for (int i = 0; i < params.size(); i++) ps.setString(i+1, params.get(i));
            ResultSet rs = ps.executeQuery();
            if (rs.next()) totalCount = rs.getInt(1);
        }

        // Fetch page
        String dataSql = "SELECT graduation_id, student_name, student_pen, gender, udise_no, " +
                         "division, district, section, academic_year, " +
                         "final_marathi_level, final_math_level, final_english_level, fln_completed, " +
                         "graduated_at FROM graduated_students" +
                         where + " ORDER BY academic_year DESC, division, district, student_name " +
                         "LIMIT ? OFFSET ?";
        try (PreparedStatement ps = conn.prepareStatement(dataSql)) {
            int idx = 1;
            for (String p : params) ps.setString(idx++, p);
            ps.setInt(idx++, pageSize);
            ps.setInt(idx,   offset);
            ResultSet rs = ps.executeQuery();
            SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy");
            while (rs.next()) {
                Map<String,Object> r = new LinkedHashMap<>();
                r.put("id",      rs.getLong("graduation_id"));
                r.put("name",    rs.getString("student_name"));
                r.put("pen",     rs.getString("student_pen"));
                r.put("gender",  rs.getString("gender"));
                r.put("udise",   rs.getString("udise_no"));
                r.put("div",     rs.getString("division"));
                r.put("dist",    rs.getString("district"));
                r.put("section", rs.getString("section"));
                r.put("year",    rs.getString("academic_year"));
                r.put("mar",     rs.getObject("final_marathi_level"));
                r.put("math",    rs.getObject("final_math_level"));
                r.put("eng",     rs.getObject("final_english_level"));
                r.put("fln",     rs.getInt("fln_completed") == 1);
                r.put("date",    rs.getTimestamp("graduated_at") != null
                                  ? sdf.format(rs.getTimestamp("graduated_at")) : "—");
                rows.add(r);
            }
        }

    } catch (Exception e) {
        // tables may not exist yet — silently fall through to empty state
    }

    int totalPages = (int) Math.ceil((double) totalCount / pageSize);

    // Build query string for pagination links
    StringBuilder qsBuilder = new StringBuilder();
    if (!filterYear.isEmpty())  qsBuilder.append("&year=").append(java.net.URLEncoder.encode(filterYear,"UTF-8"));
    if (!filterDiv.isEmpty())   qsBuilder.append("&division=").append(java.net.URLEncoder.encode(filterDiv,"UTF-8"));
    if (!filterDist.isEmpty())  qsBuilder.append("&district=").append(java.net.URLEncoder.encode(filterDist,"UTF-8"));
    if (!filterUdise.isEmpty()) qsBuilder.append("&udise=").append(java.net.URLEncoder.encode(filterUdise,"UTF-8"));
    if (!filterName.isEmpty())  qsBuilder.append("&name=").append(java.net.URLEncoder.encode(filterName,"UTF-8"));
    String qs = qsBuilder.toString();
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Graduated Students — GATEE Portal</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box;}
    body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f2f5;padding:24px;}
    .container{max-width:1200px;margin:0 auto;}
    .header{background:#fff;border-radius:12px;padding:22px 28px;margin-bottom:22px;
            box-shadow:0 2px 8px rgba(0,0,0,.07);display:flex;align-items:center;justify-content:space-between;}
    .header h1{font-size:22px;font-weight:700;color:#2d3748;display:flex;align-items:center;gap:10px;}
    .back-btn{background:#667eea;color:#fff;border:none;border-radius:8px;padding:9px 18px;
              font-size:14px;font-weight:600;cursor:pointer;text-decoration:none;display:inline-block;}
    .back-btn:hover{background:#5a67d8;}

    .summary-row{display:flex;gap:14px;margin-bottom:20px;flex-wrap:wrap;}
    .chip{background:#fff;border:1px solid #e2e8f0;border-radius:10px;padding:14px 20px;
          flex:1;min-width:130px;box-shadow:0 1px 4px rgba(0,0,0,.05);}
    .chip .num{font-size:26px;font-weight:700;color:#d69e2e;}
    .chip .lbl{font-size:12px;color:#718096;margin-top:3px;}

    .filter-card{background:#fff;border-radius:12px;padding:20px 24px;margin-bottom:18px;
                 box-shadow:0 2px 8px rgba(0,0,0,.07);}
    .filter-card h3{font-size:14px;font-weight:700;color:#4a5568;margin-bottom:12px;}
    .filter-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:10px;}
    .filter-grid input,.filter-grid select{border:1px solid #e2e8f0;border-radius:7px;
      padding:8px 12px;font-size:13px;outline:none;width:100%;font-family:inherit;}
    .filter-grid input:focus,.filter-grid select:focus{border-color:#667eea;}
    .filter-btns{display:flex;gap:10px;margin-top:12px;}
    .btn-filter{background:#667eea;color:#fff;border:none;border-radius:7px;padding:8px 20px;
                font-size:13px;font-weight:600;cursor:pointer;}
    .btn-clear{background:#e2e8f0;color:#4a5568;border:none;border-radius:7px;padding:8px 16px;
               font-size:13px;font-weight:600;cursor:pointer;text-decoration:none;display:inline-block;}

    .card{background:#fff;border-radius:12px;padding:22px;margin-bottom:20px;
          box-shadow:0 2px 8px rgba(0,0,0,.07);overflow-x:auto;}
    table{width:100%;border-collapse:collapse;font-size:13px;min-width:900px;}
    th{background:#d69e2e;color:#fff;padding:10px 12px;text-align:left;font-weight:600;white-space:nowrap;}
    td{padding:9px 12px;border-bottom:1px solid #e2e8f0;vertical-align:middle;}
    tr:last-child td{border-bottom:none;}
    tr:hover td{background:#fffbeb;}
    .fln-yes{display:inline-block;background:#c6f6d5;color:#276749;border-radius:5px;
              padding:2px 7px;font-size:11px;font-weight:700;}
    .fln-no {display:inline-block;background:#e2e8f0;color:#718096;border-radius:5px;
              padding:2px 7px;font-size:11px;}
    .gender-m{color:#3182ce;font-weight:600;}
    .gender-f{color:#d53f8c;font-weight:600;}
    .null-val{color:#cbd5e0;font-style:italic;}

    .pager{display:flex;gap:6px;justify-content:center;flex-wrap:wrap;margin-top:18px;}
    .pager a,.pager span{display:inline-block;padding:6px 14px;border-radius:6px;font-size:13px;
                          font-weight:600;text-decoration:none;border:1px solid #e2e8f0;}
    .pager a{background:#fff;color:#667eea;}
    .pager a:hover{background:#ebf4ff;}
    .pager span.current{background:#667eea;color:#fff;border-color:#667eea;}
    .pager span.dots{color:#a0aec0;border:none;}
    .result-info{font-size:13px;color:#718096;margin-bottom:12px;}
    .empty{text-align:center;padding:50px;color:#718096;font-size:15px;}
  </style>
</head>
<body>
<div class="container">

  <div class="header">
    <h1>🏆 Graduated Students</h1>
    <a href="<%= request.getContextPath() %>/data-admin-dashboard.jsp" class="back-btn">← Dashboard</a>
  </div>

  <!-- Summary chips -->
  <div class="summary-row">
    <div class="chip">
      <div class="num"><%= totalGradAll %></div>
      <div class="lbl">Total Graduates (All Years)</div>
    </div>
    <div class="chip">
      <div class="num" style="color:#667eea;"><%= years.size() %></div>
      <div class="lbl">Academic Years Recorded</div>
    </div>
    <div class="chip">
      <div class="num" style="color:#38a169;"><%= totalCount %></div>
      <div class="lbl">Matching Current Filters</div>
    </div>
  </div>

  <!-- Filters -->
  <div class="filter-card">
    <h3>🔍 Filter Graduated Students</h3>
    <form method="get" action="<%= request.getContextPath() %>/graduated-students.jsp">
      <div class="filter-grid">
        <select name="year">
          <option value="">All Academic Years</option>
          <% for (String y : years) { %>
            <option value="<%= y %>" <%= filterYear.equals(y) ? "selected" : "" %>><%= y %></option>
          <% } %>
        </select>
        <input type="text" name="division" placeholder="Division" value="<%= filterDiv %>"/>
        <input type="text" name="district" placeholder="District"  value="<%= filterDist %>"/>
        <input type="text" name="udise"    placeholder="UDISE No"  value="<%= filterUdise %>"/>
        <input type="text" name="name"     placeholder="Student Name" value="<%= filterName %>"/>
      </div>
      <div class="filter-btns">
        <button type="submit" class="btn-filter">Apply Filters</button>
        <a href="<%= request.getContextPath() %>/graduated-students.jsp" class="btn-clear">Clear All</a>
      </div>
    </form>
  </div>

  <!-- Data table -->
  <div class="card">
    <% if (rows.isEmpty()) { %>
      <div class="empty">
        <div style="font-size:48px;margin-bottom:14px;">🎓</div>
        <% if (totalGradAll == 0) { %>
          No graduated students found. Run "Promote Classes" at year-end to graduate Class 9 students.
        <% } else { %>
          No students match the current filters.
        <% } %>
      </div>
    <% } else { %>
      <p class="result-info">
        Showing <%= offset+1 %>–<%= Math.min(offset+pageSize, totalCount) %> of <%= totalCount %> students
        (page <%= page %> of <%= totalPages %>)
      </p>
      <table>
        <thead>
          <tr>
            <th>#</th><th>Student Name</th><th>PEN</th><th>G</th>
            <th>Division</th><th>District</th><th>UDISE</th><th>Sec</th>
            <th>Year</th>
            <th>Final Mar</th><th>Final Math</th><th>Final Eng</th>
            <th>FLN</th><th>Graduated On</th>
          </tr>
        </thead>
        <tbody>
          <% int rowNum = offset + 1;
             for (Map<String,Object> r : rows) { %>
          <tr>
            <td style="color:#a0aec0;"><%= rowNum++ %></td>
            <td><strong><%= r.get("name") %></strong></td>
            <td style="font-family:monospace;font-size:12px;"><%= r.get("pen") %></td>
            <td class="<%= "M".equalsIgnoreCase((String)r.get("gender")) ? "gender-m" : "gender-f" %>">
              <%= r.get("gender") %>
            </td>
            <td><%= r.get("div")  %></td>
            <td><%= r.get("dist") %></td>
            <td style="font-family:monospace;font-size:11px;"><%= r.get("udise") %></td>
            <td><%= r.get("section") %></td>
            <td><span style="background:#fbd38d;color:#7c2d12;border-radius:5px;padding:2px 7px;font-size:11px;font-weight:700;"><%= r.get("year") %></span></td>
            <td><%= r.get("mar")  != null ? r.get("mar")  : "<span class='null-val'>—</span>" %></td>
            <td><%= r.get("math") != null ? r.get("math") : "<span class='null-val'>—</span>" %></td>
            <td><%= r.get("eng")  != null ? r.get("eng")  : "<span class='null-val'>—</span>" %></td>
            <td>
              <% if (Boolean.TRUE.equals(r.get("fln"))) { %>
                <span class="fln-yes">✓ FLN</span>
              <% } else { %>
                <span class="fln-no">Partial</span>
              <% } %>
            </td>
            <td style="font-size:12px;color:#718096;"><%= r.get("date") %></td>
          </tr>
          <% } %>
        </tbody>
      </table>

      <!-- Pagination -->
      <% if (totalPages > 1) { %>
      <div class="pager">
        <% if (page_g > 1) { %>
          <a href="?page_g=<%= page_g-1 %><%= qs %>">« Prev</a>
        <% } %>
        <% for (int p2 = 1; p2 <= totalPages; p2++) {
             if (p2 == page_g) { %>
               <span class="current"><%= p2 %></span>
           <% } else if (p2 == 1 || p2 == totalPages || Math.abs(p2-page_g) <= 2) { %>
               <a href="?page_g=<%= p2 %><%= qs %>"><%= p2 %></a>
           <% } else if (Math.abs(p2-page_g) == 3) { %>
               <span class="dots">…</span>
           <% } } %>
        <% if (page_g < totalPages) { %>
          <a href="?page_g=<%= page_g+1 %><%= qs %>">Next »</a>
        <% } %>
      </div>
      <% } %>
    <% } %>
  </div>

</div>
</body>
</html>
