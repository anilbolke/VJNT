<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.vjnt.model.User,com.vjnt.util.DatabaseConnection,java.sql.*,java.util.*,java.text.SimpleDateFormat" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    String userType  = user.getUserType().toString();
    String userUdise = user.getUdiseNo()      != null ? user.getUdiseNo().trim()      : "";
    String userDist  = user.getDistrictName() != null ? user.getDistrictName().trim()  : "";
    String userDiv   = user.getDivisionName() != null ? user.getDivisionName().trim()  : "";
    boolean isAdmin  = userType.equals("DATA_ADMIN");
    boolean canWrite = isAdmin || userType.equals("SCHOOL_COORDINATOR") || userType.equals("HEAD_MASTER");

    // ── Filter params ──
    String filterUdise = request.getParameter("udise")   != null ? request.getParameter("udise").trim()   : "";
    String filterClass = request.getParameter("class")   != null ? request.getParameter("class").trim()   : "";
    String filterType  = request.getParameter("type")    != null ? request.getParameter("type").trim()    : "";
    String filterPen   = request.getParameter("pen")     != null ? request.getParameter("pen").trim()     : "";

    // For school-level roles, lock UDISE to their own
    if (userType.equals("SCHOOL_COORDINATOR") || userType.equals("HEAD_MASTER")) {
        filterUdise = userUdise;
    }

    String successMsg = request.getParameter("success");
    String errorMsg   = request.getParameter("error");

    // ── Load school name ──
    String schoolName = "";
    if (!filterUdise.isEmpty()) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT school_name FROM schools WHERE udise_no = ? LIMIT 1")) {
            ps.setString(1, filterUdise);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) schoolName = rs.getString("school_name");
        } catch (Exception ex) { schoolName = filterUdise; }
    }

    // ── Load students for the dropdown (for the selected/own school) ──
    List<Map<String,Object>> students = new ArrayList<>();
    String stuUdise = filterUdise.isEmpty() ? userUdise : filterUdise;
    if (!stuUdise.isEmpty()) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT student_id, student_pen, student_name, class " +
                 "FROM students WHERE is_active=1 AND udise_no=? ORDER BY class, student_name")) {
            ps.setString(1, stuUdise);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String,Object> s = new LinkedHashMap<>();
                s.put("id",    rs.getInt("student_id"));
                s.put("pen",   rs.getString("student_pen"));
                s.put("name",  rs.getString("student_name"));
                s.put("class", rs.getString("class"));
                students.add(s);
            }
        } catch (Exception ex) {}
    }

    // ── Load activities ──
    List<Map<String,Object>> activities = new ArrayList<>();
    int totalCount = 0;
    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy");

    try (Connection conn = DatabaseConnection.getConnection()) {
        StringBuilder sql = new StringBuilder(
            "SELECT activity_id, student_pen, student_name, udise_no, student_class, " +
            "activity_type, activity_name, activity_date, description, achievement, " +
            "competition_level, photo_filename, created_by, created_date " +
            "FROM student_activities WHERE 1=1 ");
        List<String> params = new ArrayList<>();

        if (!filterUdise.isEmpty()) { sql.append("AND udise_no=? "); params.add(filterUdise); }
        else if (userType.equals("DISTRICT_OFFICER")) { sql.append("AND udise_no IN (SELECT udise_no FROM students WHERE district=? LIMIT 500) "); params.add(userDist); }
        else if (userType.equals("DIVISION_OFFICER") || userType.equals("SUPER_DIVISION_OFFICER")) { sql.append("AND udise_no IN (SELECT udise_no FROM students WHERE division=? LIMIT 1000) "); params.add(userDiv); }

        if (!filterClass.isEmpty()) { sql.append("AND student_class=? "); params.add(filterClass); }
        if (!filterType.isEmpty())  { sql.append("AND activity_type=? "); params.add(filterType); }
        if (!filterPen.isEmpty())   { sql.append("AND (student_pen=? OR student_name LIKE ?) "); params.add(filterPen); params.add("%" + filterPen + "%"); }

        sql.append("ORDER BY created_date DESC LIMIT 200");

        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setString(i+1, params.get(i));
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String,Object> a = new LinkedHashMap<>();
                a.put("id",      rs.getInt("activity_id"));
                a.put("pen",     rs.getString("student_pen"));
                a.put("name",    rs.getString("student_name"));
                a.put("udise",   rs.getString("udise_no"));
                a.put("class",   rs.getString("student_class"));
                a.put("type",    rs.getString("activity_type"));
                a.put("aname",   rs.getString("activity_name"));
                a.put("date",    rs.getDate("activity_date") != null ? sdf.format(rs.getDate("activity_date")) : "—");
                a.put("desc",    rs.getString("description"));
                a.put("achieve", rs.getString("achievement"));
                a.put("level",   rs.getString("competition_level"));
                a.put("hasPhoto",rs.getString("photo_filename") != null);
                a.put("by",      rs.getString("created_by"));
                a.put("on",      rs.getTimestamp("created_date") != null ? sdf.format(rs.getTimestamp("created_date")) : "—");
                activities.add(a);
                totalCount++;
            }
        }
    } catch (Exception ex) { errorMsg = "टेबल आढळले नाही. SQL चालवा: " + ex.getMessage(); }

    String[] actTypes  = {"क्रीडा (Sports)","सांस्कृतिक (Cultural)","शैक्षणिक (Academic)","विज्ञान (Science)","कला (Art)","वाचन (Reading)","इतर (Other)"};
    String[] achvTypes = {"प्रथम (1st Place)","द्वितीय (2nd Place)","तृतीय (3rd Place)","सहभाग (Participation)","विशेष सन्मान (Special Mention)"};
    String[] lvlTypes  = {"शाळा स्तर (School)","तालुका स्तर (Taluka)","जिल्हा स्तर (District)","विभाग स्तर (Division)","राज्य स्तर (State)","राष्ट्रीय (National)"};
    String[] classes   = {"I","II","III","IV","V","VI","VII","VIII","IX"};
%>
<!DOCTYPE html>
<html lang="mr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>विद्यार्थी उपक्रम — GATEE पोर्टल</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f4f8;color:#1e293b;min-height:100vh;}

/* Top bar */
.topbar{background:linear-gradient(90deg,#667eea,#764ba2);color:#fff;display:flex;
        align-items:center;justify-content:space-between;padding:0 24px;height:56px;
        position:sticky;top:0;z-index:100;box-shadow:0 2px 8px rgba(0,0,0,.2);}
.topbar-left{display:flex;align-items:center;gap:12px;}
.topbar-title{font-size:17px;font-weight:800;}
.topbar-right{display:flex;gap:10px;align-items:center;}
.topbar-btn{background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.3);color:#fff;
            padding:6px 16px;border-radius:20px;font-size:13px;cursor:pointer;text-decoration:none;transition:.2s;}
.topbar-btn:hover{background:rgba(255,255,255,.25);}
.topbar-btn.primary{background:#fff;color:#667eea;font-weight:700;}
.topbar-btn.primary:hover{background:#f0f4f8;}

/* Page */
.page{max-width:1200px;margin:0 auto;padding:24px 20px 60px;}

/* Alert */
.alert{border-radius:10px;padding:12px 18px;font-size:14px;margin-bottom:16px;display:flex;align-items:center;gap:10px;}
.alert-ok  {background:#dcfce7;color:#14532d;border:1px solid #86efac;}
.alert-err {background:#fee2e2;color:#991b1b;border:1px solid #fca5a5;}

/* Stat bar */
.stat-bar{display:flex;gap:14px;margin-bottom:20px;flex-wrap:wrap;}
.stat-pill{background:#fff;border-radius:10px;padding:14px 20px;flex:1;min-width:130px;
           text-align:center;box-shadow:0 1px 4px rgba(0,0,0,.07);}
.stat-pill .sp-num{font-size:26px;font-weight:800;margin-bottom:2px;}
.stat-pill .sp-lbl{font-size:12px;color:#64748b;}

/* Layout */
.layout{display:grid;grid-template-columns:1fr 380px;gap:20px;align-items:start;}

/* Filter card */
.filter-card{background:#fff;border-radius:12px;padding:18px;box-shadow:0 1px 4px rgba(0,0,0,.07);margin-bottom:20px;}
.filter-card h3{font-size:15px;font-weight:700;margin-bottom:14px;display:flex;align-items:center;gap:6px;}
.filter-row{display:flex;gap:10px;flex-wrap:wrap;align-items:flex-end;}
.filter-row select, .filter-row input{padding:9px 12px;border:2px solid #e2e8f0;border-radius:8px;
                                       font-size:13px;outline:none;min-width:140px;transition:.2s;}
.filter-row select:focus,.filter-row input:focus{border-color:#667eea;}
.btn-filter{background:linear-gradient(135deg,#667eea,#764ba2);color:#fff;border:none;
            padding:9px 20px;border-radius:8px;font-size:13px;font-weight:700;cursor:pointer;}
.btn-clear{background:#f1f5f9;color:#475569;border:none;padding:9px 16px;border-radius:8px;
           font-size:13px;font-weight:600;cursor:pointer;text-decoration:none;}

/* Activity cards list */
.list-area h3{font-size:16px;font-weight:800;margin-bottom:14px;display:flex;align-items:center;gap:8px;}
.activity-card{background:#fff;border-radius:12px;box-shadow:0 1px 4px rgba(0,0,0,.07);
               margin-bottom:14px;overflow:hidden;border-left:4px solid #667eea;transition:.2s;}
.activity-card:hover{box-shadow:0 4px 16px rgba(102,126,234,.15);}
.ac-head{padding:14px 18px;display:flex;align-items:flex-start;gap:12px;}
.ac-icon{font-size:28px;flex-shrink:0;}
.ac-info{flex:1;min-width:0;}
.ac-name{font-size:15px;font-weight:700;color:#1e293b;margin-bottom:3px;}
.ac-sub{font-size:12px;color:#64748b;margin-bottom:6px;}
.ac-chips{display:flex;gap:6px;flex-wrap:wrap;}
.chip{display:inline-block;border-radius:10px;padding:2px 10px;font-size:11px;font-weight:700;}
.chip-type{background:#ede9fe;color:#6d28d9;}
.chip-achv{background:#fef3c7;color:#92400e;}
.chip-level{background:#dcfce7;color:#14532d;}
.chip-class{background:#dbeafe;color:#1e40af;}
.chip-date{background:#f1f5f9;color:#475569;}
.ac-photo{width:60px;height:60px;object-fit:cover;border-radius:8px;cursor:pointer;flex-shrink:0;}
.ac-body{padding:0 18px 14px 18px;}
.ac-desc{font-size:13px;color:#475569;line-height:1.7;margin-bottom:8px;}
.ac-footer{display:flex;justify-content:space-between;align-items:center;
           padding:10px 18px;background:#f8fafc;border-top:1px solid #f1f5f9;}
.ac-footer .by{font-size:11px;color:#94a3b8;}
.btn-del{background:#fee2e2;color:#dc2626;border:none;padding:4px 12px;border-radius:6px;
         font-size:12px;font-weight:700;cursor:pointer;transition:.2s;}
.btn-del:hover{background:#dc2626;color:#fff;}

/* Type colours */
.ac-card-sports  {border-left-color:#3b82f6;}
.ac-card-cultural{border-left-color:#a855f7;}
.ac-card-academic{border-left-color:#22c55e;}
.ac-card-science {border-left-color:#f97316;}
.ac-card-art     {border-left-color:#ec4899;}
.ac-card-reading {border-left-color:#14b8a6;}
.ac-card-other   {border-left-color:#94a3b8;}

/* Add form */
.form-card{background:#fff;border-radius:14px;box-shadow:0 2px 12px rgba(0,0,0,.08);
           padding:22px;position:sticky;top:72px;}
.form-card h3{font-size:16px;font-weight:800;margin-bottom:18px;display:flex;align-items:center;gap:8px;
              padding-bottom:12px;border-bottom:2px solid #f1f5f9;}
.form-group{margin-bottom:14px;}
.form-group label{display:block;font-size:12px;font-weight:700;color:#475569;
                  text-transform:uppercase;letter-spacing:.5px;margin-bottom:5px;}
.form-group input,.form-group select,.form-group textarea{
    width:100%;padding:10px 12px;border:2px solid #e2e8f0;border-radius:8px;
    font-size:13px;font-family:inherit;outline:none;transition:.2s;background:#fff;}
.form-group input:focus,.form-group select:focus,.form-group textarea:focus{border-color:#667eea;}
.form-group textarea{resize:vertical;min-height:70px;}
.form-row-2{display:grid;grid-template-columns:1fr 1fr;gap:10px;}
.photo-zone{border:2px dashed #e2e8f0;border-radius:8px;padding:16px;text-align:center;cursor:pointer;
            transition:.2s;position:relative;}
.photo-zone:hover{border-color:#667eea;background:#f8f7ff;}
.photo-zone input{position:absolute;inset:0;opacity:0;cursor:pointer;}
.photo-zone .pz-icon{font-size:28px;margin-bottom:6px;}
.photo-zone p{font-size:12px;color:#64748b;}
#photoPreview{max-width:100%;border-radius:8px;margin-top:10px;display:none;}
.btn-submit{width:100%;background:linear-gradient(135deg,#667eea,#764ba2);color:#fff;border:none;
            padding:13px;border-radius:10px;font-size:15px;font-weight:700;cursor:pointer;transition:.2s;margin-top:6px;}
.btn-submit:hover{opacity:.9;}
.stu-select-wrap{position:relative;}
#stuSearch{padding-right:36px;}
.stu-dropdown{display:none;position:absolute;top:100%;left:0;right:0;background:#fff;
              border:2px solid #667eea;border-top:none;border-radius:0 0 8px 8px;
              max-height:200px;overflow-y:auto;z-index:50;box-shadow:0 8px 20px rgba(0,0,0,.1);}
.stu-opt{padding:9px 12px;font-size:13px;cursor:pointer;display:flex;justify-content:space-between;}
.stu-opt:hover{background:#f1f5f9;}
.stu-opt .so-name{font-weight:600;}
.stu-opt .so-meta{font-size:11px;color:#94a3b8;}

/* Empty state */
.empty{text-align:center;padding:60px 20px;background:#fff;border-radius:12px;
       box-shadow:0 1px 4px rgba(0,0,0,.07);}
.empty .ei{font-size:56px;margin-bottom:12px;}

/* Photo modal */
.modal-bg{display:none;position:fixed;inset:0;background:rgba(0,0,0,.7);z-index:200;
          align-items:center;justify-content:center;}
.modal-bg.open{display:flex;}
.modal-img{max-width:90vw;max-height:85vh;border-radius:12px;box-shadow:0 8px 40px rgba(0,0,0,.5);}
.modal-close{position:fixed;top:20px;right:24px;font-size:32px;color:#fff;cursor:pointer;
             font-weight:700;background:rgba(0,0,0,.4);border-radius:50%;width:44px;height:44px;
             display:flex;align-items:center;justify-content:center;}

/* SQL setup info */
.sql-box{background:#1e293b;color:#e2e8f0;border-radius:10px;padding:16px;font-size:12px;
         font-family:monospace;line-height:1.8;overflow-x:auto;margin-bottom:16px;}

@media(max-width:900px){.layout{grid-template-columns:1fr;} .form-card{position:static;}}
@media(max-width:600px){.form-row-2{grid-template-columns:1fr;} .filter-row select,.filter-row input{min-width:120px;}}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-left">
    <div class="topbar-title">🏅 विद्यार्थी उपक्रम व कामगिरी</div>
  </div>
  <div class="topbar-right">
    <% if (canWrite) { %><a href="#addForm" class="topbar-btn primary">+ नवीन उपक्रम</a><% } %>
    <a href="javascript:history.back()" class="topbar-btn">← मागे</a>
  </div>
</div>

<jsp:include page="academic-year-bar.jsp" />

<div class="page">

  <!-- Alerts -->
  <% if ("1".equals(successMsg)) { %><div class="alert alert-ok">✅ उपक्रम यशस्वीरित्या जतन झाला!</div><% } %>
  <% if ("deleted".equals(successMsg)) { %><div class="alert alert-ok">🗑️ उपक्रम हटवण्यात आला.</div><% } %>
  <% if (errorMsg != null && errorMsg.startsWith("टेबल")) { %>
  <div class="alert alert-err">
    ⚠️ <strong>पहिल्यांदा हे SQL चालवा (MySQL मध्ये):</strong>
    <div class="sql-box" style="margin-top:10px;">CREATE TABLE IF NOT EXISTS student_activities (<br/>
&nbsp;&nbsp;activity_id INT AUTO_INCREMENT PRIMARY KEY,<br/>
&nbsp;&nbsp;student_pen VARCHAR(50) NOT NULL,<br/>
&nbsp;&nbsp;student_name VARCHAR(200) NOT NULL,<br/>
&nbsp;&nbsp;udise_no VARCHAR(20) NOT NULL,<br/>
&nbsp;&nbsp;student_class VARCHAR(10),<br/>
&nbsp;&nbsp;activity_type VARCHAR(50) NOT NULL,<br/>
&nbsp;&nbsp;activity_name VARCHAR(200) NOT NULL,<br/>
&nbsp;&nbsp;activity_date DATE,<br/>
&nbsp;&nbsp;description TEXT,<br/>
&nbsp;&nbsp;achievement VARCHAR(100),<br/>
&nbsp;&nbsp;competition_level VARCHAR(50),<br/>
&nbsp;&nbsp;photo_content LONGBLOB,<br/>
&nbsp;&nbsp;photo_filename VARCHAR(200),<br/>
&nbsp;&nbsp;photo_content_type VARCHAR(100),<br/>
&nbsp;&nbsp;created_by VARCHAR(100),<br/>
&nbsp;&nbsp;created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP<br/>
);</div>
  </div>
  <% } else if (errorMsg != null && !errorMsg.isEmpty()) { %>
  <div class="alert alert-err">⚠️ <%= errorMsg %></div>
  <% } %>

  <!-- Stats -->
  <%
    long sports=0,cultural=0,academic=0,science=0,art=0,other=0;
    for(Map<String,Object> a:activities){
      String t=String.valueOf(a.get("type"));
      if(t.startsWith("क्रीडा"))sports++;
      else if(t.startsWith("सांस्कृतिक"))cultural++;
      else if(t.startsWith("शैक्षणिक"))academic++;
      else if(t.startsWith("विज्ञान"))science++;
      else if(t.startsWith("कला"))art++;
      else other++;
    }
  %>
  <div class="stat-bar">
    <div class="stat-pill"><div class="sp-num" style="color:#667eea;"><%= totalCount %></div><div class="sp-lbl">एकूण उपक्रम</div></div>
    <div class="stat-pill"><div class="sp-num" style="color:#3b82f6;"><%= sports %></div><div class="sp-lbl">🏅 क्रीडा</div></div>
    <div class="stat-pill"><div class="sp-num" style="color:#a855f7;"><%= cultural %></div><div class="sp-lbl">🎭 सांस्कृतिक</div></div>
    <div class="stat-pill"><div class="sp-num" style="color:#22c55e;"><%= academic %></div><div class="sp-lbl">📚 शैक्षणिक</div></div>
    <div class="stat-pill"><div class="sp-num" style="color:#f97316;"><%= science %></div><div class="sp-lbl">🔬 विज्ञान</div></div>
    <div class="stat-pill"><div class="sp-num" style="color:#ec4899;"><%= art %></div><div class="sp-lbl">🎨 कला</div></div>
  </div>

  <!-- Filter -->
  <div class="filter-card">
    <h3>🔍 फिल्टर</h3>
    <form method="GET" action="">
      <% if (!filterUdise.isEmpty()) { %><input type="hidden" name="udise" value="<%= filterUdise %>"/><% } %>
      <div class="filter-row">
        <% if (isAdmin) { %><input type="text" name="udise" value="<%= filterUdise %>" placeholder="UDISE क्रमांक" style="min-width:170px;"/><% } %>
        <select name="class">
          <option value="">-- सर्व इयत्ता --</option>
          <% for(String c:classes){ %><option value="<%= c %>"<%= c.equals(filterClass)?" selected":"" %>><%= c %></option><% } %>
        </select>
        <select name="type">
          <option value="">-- सर्व प्रकार --</option>
          <% for(String t:actTypes){ %><option value="<%= t %>"<%= t.equals(filterType)?" selected":"" %>><%= t %></option><% } %>
        </select>
        <input type="text" name="pen" value="<%= filterPen %>" placeholder="PEN / विद्यार्थी नाव" style="min-width:170px;"/>
        <button type="submit" class="btn-filter">🔍 शोधा</button>
        <a href="student-activity.jsp<%= filterUdise.isEmpty()?"":" ?udise="+filterUdise %>" class="btn-clear">✕ साफ</a>
      </div>
    </form>
  </div>

  <div class="layout">

    <!-- ══ Activity List ══ -->
    <div class="list-area">
      <h3>
        🏅 उपक्रम यादी
        <% if (!schoolName.isEmpty()) { %><span style="font-size:13px;font-weight:400;color:#64748b;"> — <%= schoolName %></span><% } %>
      </h3>

      <% if (activities.isEmpty()) { %>
      <div class="empty">
        <div class="ei">🏅</div>
        <h3 style="font-size:17px;margin-bottom:8px;">अजून कोणताही उपक्रम नोंदला नाही</h3>
        <p style="color:#64748b;font-size:13px;">उजव्या बाजूच्या फॉर्मने पहिला विद्यार्थी उपक्रम नोंदवा.</p>
      </div>
      <% } %>

      <% for (Map<String,Object> a : activities) {
           String atype = String.valueOf(a.get("type"));
           String cardCls = "ac-card-other";
           String typeIcon = "⭐";
           if(atype.startsWith("क्रीडा"))    { cardCls="ac-card-sports";   typeIcon="🏅"; }
           else if(atype.startsWith("सांस्कृतिक")) { cardCls="ac-card-cultural"; typeIcon="🎭"; }
           else if(atype.startsWith("शैक्षणिक"))  { cardCls="ac-card-academic"; typeIcon="📚"; }
           else if(atype.startsWith("विज्ञान"))   { cardCls="ac-card-science";  typeIcon="🔬"; }
           else if(atype.startsWith("कला"))      { cardCls="ac-card-art";      typeIcon="🎨"; }
           else if(atype.startsWith("वाचन"))     { cardCls="ac-card-reading";  typeIcon="📖"; }
      %>
      <div class="activity-card <%= cardCls %>">
        <div class="ac-head">
          <div class="ac-icon"><%= typeIcon %></div>
          <div class="ac-info">
            <div class="ac-name"><%= a.get("aname") %></div>
            <div class="ac-sub">
              👤 <%= a.get("name") %> &nbsp;|&nbsp; PEN: <%= a.get("pen") %>
            </div>
            <div class="ac-chips">
              <span class="chip chip-type"><%= a.get("type") %></span>
              <span class="chip chip-class">इयत्ता <%= a.get("class") %></span>
              <span class="chip chip-date">📅 <%= a.get("date") %></span>
              <% if (a.get("achieve") != null && !String.valueOf(a.get("achieve")).isEmpty()) { %>
              <span class="chip chip-achv">🏆 <%= a.get("achieve") %></span>
              <% } %>
              <% if (a.get("level") != null && !String.valueOf(a.get("level")).isEmpty()) { %>
              <span class="chip chip-level"><%= a.get("level") %></span>
              <% } %>
            </div>
          </div>
          <% if (Boolean.TRUE.equals(a.get("hasPhoto"))) { %>
          <img src="<%= request.getContextPath() %>/student-activity?photo=<%= a.get("id") %>"
               class="ac-photo" alt="फोटो" onclick="openPhoto(this.src)" loading="lazy"/>
          <% } %>
        </div>
        <% if (a.get("desc") != null && !String.valueOf(a.get("desc")).isEmpty()) { %>
        <div class="ac-body"><div class="ac-desc"><%= a.get("desc") %></div></div>
        <% } %>
        <div class="ac-footer">
          <span class="by">नोंदवले: <%= a.get("by") %> &nbsp;|&nbsp; <%= a.get("on") %></span>
          <% if (canWrite) { %>
          <form method="POST" action="student-activity" style="display:inline;"
                onsubmit="return confirm('हा उपक्रम हटवायचा आहे का?');">
            <input type="hidden" name="action"      value="delete"/>
            <input type="hidden" name="activity_id" value="<%= a.get("id") %>"/>
            <input type="hidden" name="udise_no"    value="<%= a.get("udise") %>"/>
            <button type="submit" class="btn-del">🗑️ हटवा</button>
          </form>
          <% } %>
        </div>
      </div>
      <% } %>
    </div>

    <!-- ══ Add Form ══ -->
    <% if (canWrite) { %>
    <div id="addForm" class="form-card">
      <h3>➕ नवीन उपक्रम नोंदवा</h3>
      <form method="POST" action="<%= request.getContextPath() %>/student-activity"
            enctype="multipart/form-data" id="activityForm">

        <!-- Student search -->
        <div class="form-group">
          <label>विद्यार्थी निवडा *</label>
          <div class="stu-select-wrap">
            <input type="text" id="stuSearch" placeholder="नाव किंवा PEN टाइप करा..." autocomplete="off"
                   oninput="filterStudents(this.value)" onfocus="showDropdown()" required/>
            <div class="stu-dropdown" id="stuDropdown">
              <% for(Map<String,Object> s : students) { %>
              <div class="stu-opt"
                   onclick="selectStudent('<%= s.get("pen") %>','<%= ((String)s.get("name")).replace("'","\\'") %>','<%= s.get("class") %>','<%= stuUdise %>')">
                <span class="so-name"><%= s.get("name") %></span>
                <span class="so-meta">इयत्ता <%= s.get("class") %> | PEN: <%= s.get("pen") %></span>
              </div>
              <% } %>
              <% if(students.isEmpty()) { %>
              <div style="padding:12px;font-size:13px;color:#94a3b8;">
                <% if(stuUdise.isEmpty()) { %>UDISE निवडा / Admin: UDISE filter वापरा<% } else { %>या शाळेत विद्यार्थी नाहीत<% } %>
              </div>
              <% } %>
            </div>
          </div>
          <input type="hidden" name="student_pen"   id="hidPen"   required/>
          <input type="hidden" name="student_name"  id="hidName"/>
          <input type="hidden" name="student_class" id="hidClass"/>
          <input type="hidden" name="udise_no"      id="hidUdise" value="<%= stuUdise %>"/>
          <div id="selectedStu" style="margin-top:6px;font-size:12px;color:#667eea;font-weight:600;min-height:18px;"></div>
        </div>

        <!-- Activity type + name -->
        <div class="form-group">
          <label>उपक्रम प्रकार *</label>
          <select name="activity_type" required>
            <option value="">-- निवडा --</option>
            <% for(String t:actTypes){ %><option value="<%= t %>"><%= t %></option><% } %>
          </select>
        </div>

        <div class="form-group">
          <label>उपक्रमाचे नाव / स्पर्धेचे नाव *</label>
          <input type="text" name="activity_name" placeholder="उदा. आंतरशालेय कबड्डी स्पर्धा" required maxlength="200"/>
        </div>

        <div class="form-row-2">
          <div class="form-group">
            <label>तारीख *</label>
            <input type="date" name="activity_date" required/>
          </div>
          <div class="form-group">
            <label>स्पर्धा स्तर</label>
            <select name="competition_level">
              <option value="">-- निवडा --</option>
              <% for(String l:lvlTypes){ %><option value="<%= l %>"><%= l %></option><% } %>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label>कामगिरी / निकाल</label>
          <select name="achievement">
            <option value="">-- निवडा --</option>
            <% for(String ac:achvTypes){ %><option value="<%= ac %>"><%= ac %></option><% } %>
          </select>
        </div>

        <div class="form-group">
          <label>विवरण / तपशील</label>
          <textarea name="description" placeholder="उपक्रमाबद्दल थोडक्यात माहिती लिहा..." maxlength="1000"></textarea>
        </div>

        <div class="form-group">
          <label>फोटो (पर्यायी, कमाल 5MB)</label>
          <div class="photo-zone" onclick="document.getElementById('photoInput').click()">
            <input type="file" name="photo" id="photoInput" accept="image/*"
                   onchange="previewPhoto(this)" style="display:none"/>
            <div class="pz-icon">📷</div>
            <p>फोटो निवडा (JPG / PNG)</p>
          </div>
          <img id="photoPreview" alt="preview"/>
        </div>

        <button type="submit" class="btn-submit" onclick="return validateForm()">✅ उपक्रम जतन करा</button>
      </form>
    </div>
    <% } %>
  </div>
</div>

<!-- Photo modal -->
<div class="modal-bg" id="photoModal" onclick="closePhoto()">
  <div class="modal-close" onclick="closePhoto()">✕</div>
  <img id="modalImg" class="modal-img" src="" alt=""/>
</div>

<script>
// ── Student dropdown ──
const allStudents = [
  <% for(Map<String,Object> s : students) { %>
  {pen:"<%= s.get("pen") %>", name:"<%= ((String)s.get("name")).replace("'","\\'") %>", cls:"<%= s.get("class") %>", udise:"<%= stuUdise %>"},
  <% } %>
];

function filterStudents(q) {
  const dd = document.getElementById('stuDropdown');
  q = q.toLowerCase();
  const matched = allStudents.filter(s => s.name.toLowerCase().includes(q) || s.pen.toLowerCase().includes(q));
  dd.innerHTML = matched.length
    ? matched.map(s =>
        `<div class="stu-opt" onclick="selectStudent('${s.pen}','${s.name.replace(/'/g,"\\'")}','${s.cls}','${s.udise}')">
           <span class="so-name">${s.name}</span>
           <span class="so-meta">इयत्ता ${s.cls} | PEN: ${s.pen}</span>
         </div>`).join('')
    : '<div style="padding:12px;font-size:13px;color:#94a3b8;">विद्यार्थी आढळला नाही</div>';
  dd.style.display = 'block';
}

function showDropdown() {
  document.getElementById('stuDropdown').style.display = 'block';
}

function selectStudent(pen, name, cls, udise) {
  document.getElementById('stuSearch').value  = name + ' (इयत्ता ' + cls + ')';
  document.getElementById('hidPen').value     = pen;
  document.getElementById('hidName').value    = name;
  document.getElementById('hidClass').value   = cls;
  document.getElementById('hidUdise').value   = udise;
  document.getElementById('stuDropdown').style.display = 'none';
  document.getElementById('selectedStu').textContent  = '✅ निवडले: ' + name + ' | PEN: ' + pen;
}

document.addEventListener('click', function(e) {
  if (!e.target.closest('.stu-select-wrap')) {
    document.getElementById('stuDropdown').style.display = 'none';
  }
});

// ── Photo preview ──
function previewPhoto(input) {
  const prev = document.getElementById('photoPreview');
  if (input.files && input.files[0]) {
    const reader = new FileReader();
    reader.onload = e => { prev.src = e.target.result; prev.style.display = 'block'; };
    reader.readAsDataURL(input.files[0]);
  }
}

// ── Form validation ──
function validateForm() {
  const pen = document.getElementById('hidPen').value;
  if (!pen) { alert('कृपया विद्यार्थी निवडा.'); return false; }
  return true;
}

// ── Photo modal ──
function openPhoto(src) {
  document.getElementById('modalImg').src = src;
  document.getElementById('photoModal').classList.add('open');
}
function closePhoto() {
  document.getElementById('photoModal').classList.remove('open');
}

// ── Photo input trigger from zone ──
document.querySelector('.photo-zone') && document.querySelector('.photo-zone').addEventListener('click', function(e) {
  if (e.target !== document.getElementById('photoInput')) {
    document.getElementById('photoInput').click();
  }
});
</script>
</body>
</html>
