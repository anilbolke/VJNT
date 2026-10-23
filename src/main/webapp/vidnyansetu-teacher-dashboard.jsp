<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.VidnyanSetuUser,com.vjnt.model.School,com.vjnt.dao.SchoolDAO,com.vjnt.util.DatabaseConnection,java.sql.*,java.util.*" %>
<%
    VidnyanSetuUser teacher = (VidnyanSetuUser) session.getAttribute("vsUser");
    if (teacher == null) { response.sendRedirect(request.getContextPath() + "/vidnyansetu-login"); return; }
    if (teacher.getRole() != VidnyanSetuUser.Role.TEACHER) {
        response.sendRedirect(request.getContextPath() + "/vidnyansetu-coordinator-dashboard.jsp"); return;
    }

    School school = new SchoolDAO().getSchoolByUdise(teacher.getUdiseNo());
    String schoolName = school != null ? school.getSchoolName() : "-";

    // assignments -> list of class/section this teacher covers, + student count per one
    List<String[]> assignments = new ArrayList<>();
    int totalStudents = 0;
    LinkedHashSet<String> distinctClasses = new LinkedHashSet<>();
    try (Connection conn = DatabaseConnection.getConnection()) {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT class, section FROM vidnyansetu_teacher_assignments " +
                "WHERE vs_user_id = ? AND is_active = 1 ORDER BY class, section")) {
            ps.setInt(1, teacher.getVsUserId());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) assignments.add(new String[]{ rs.getString("class"), rs.getString("section") });
            }
        }
        for (String[] cs : assignments) {
            distinctClasses.add(cs[0]);
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*) FROM students WHERE is_active = 1 AND udise_no = ? AND class = ? AND section = ?")) {
                ps.setString(1, teacher.getUdiseNo());
                ps.setString(2, cs[0]);
                ps.setString(3, cs[1]);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) totalStudents += rs.getInt(1);
                }
            }
        }
    }
    String classesLabel = distinctClasses.isEmpty() ? "-" : String.join(", ", distinctClasses);
%>
<!DOCTYPE html>
<html lang="mr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>विज्ञानसेतू - Teacher</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f0f4f8; color: #1e293b; min-height: 100vh; }
        .topbar {
            background: linear-gradient(135deg, #0f9b6c 0%, #0c7b54 100%); color: #fff;
            padding: 16px 24px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 10px;
        }
        .topbar .brand { font-size: 19px; font-weight: 800; display: flex; align-items: center; gap: 8px; }
        .topbar .who { font-size: 13px; opacity: 0.9; }
        .topbar-actions { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
        .topbar-btn {
            background: rgba(255,255,255,0.15); color: #fff; text-decoration: none; padding: 8px 14px;
            border-radius: 8px; font-size: 13px; font-weight: 600; border: 1px solid rgba(255,255,255,0.3);
        }
        .topbar-btn:hover { background: rgba(255,255,255,0.28); }
        .wrap { max-width: 900px; margin: 40px auto; padding: 0 20px; }
        .wrap h2 { font-size: 20px; margin-bottom: 18px; color: #0c7b54; }

        /* School info header + stat cards — same pattern as school-dashboard-enhanced.jsp */
        .school-header { background: #f0f2f5; color: #000; padding: 20px 30px; border-radius: 8px; margin-bottom: 20px; text-align: center; }
        .school-header .school-icon { font-size: 24px; }
        .school-header h1 { font-size: 22px; font-weight: 700; margin: 4px 0; }
        .school-header .header-subtitle { font-size: 14px; opacity: 0.85; }
        .breadcrumb { background: #fff; padding: 15px 25px; border-radius: 12px; margin-bottom: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-left: 5px solid #0f9b6c; font-size: 13.5px; }
        .dashboard-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 12px; margin-bottom: 24px; }
        .stat-card { background: #fff; padding: 15px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); border-left: 3px solid #0f9b6c; text-align: center; }
        .stat-icon { font-size: 28px; margin-bottom: 6px; display: block; }
        .stat-value { font-size: 26px; font-weight: 700; color: #2d3748; margin-bottom: 4px; }
        .stat-label { font-size: 11px; color: #718096; font-weight: 500; }
        .activity-card {
            background: #fff; border-radius: 14px; padding: 30px; box-shadow: 0 4px 18px rgba(0,0,0,0.08);
            display: flex; align-items: center; gap: 22px; text-decoration: none; color: inherit;
            border: 1px solid #e2e8f0; transition: all 0.2s; max-width: 480px; margin-bottom: 16px;
        }
        .activity-card:hover { box-shadow: 0 8px 28px rgba(0,0,0,0.14); transform: translateY(-2px); border-color: #0f9b6c; }
        .activity-card .icon { font-size: 44px; }
        .activity-card .title { font-size: 18px; font-weight: 700; color: #1e293b; margin-bottom: 4px; }
        .activity-card .desc { font-size: 13px; color: #64748b; }
    </style>
</head>
<body>
    <div class="topbar">
        <div class="brand">🔬 विज्ञानसेतू</div>
        <div class="topbar-actions">
            <span class="who"><%= teacher.getFullName() != null ? teacher.getFullName() : teacher.getUsername() %> · UDISE <%= teacher.getUdiseNo() %></span>
            <a class="topbar-btn" href="<%= request.getContextPath() %>/vidnyansetu-change-password.jsp">🔐 Change Password</a>
            <a class="topbar-btn" href="<%= request.getContextPath() %>/logout">🚪 Logout</a>
        </div>
    </div>

    <div class="wrap">
        <div class="school-header">
            <div class="school-icon">🏫</div>
            <h1><%= schoolName %></h1>
            <div class="header-subtitle">UDISE: <%= teacher.getUdiseNo() %> | VidnyanSetu Teacher</div>
        </div>

        <div class="breadcrumb">
            <span>🏫 School:</span> <strong><%= schoolName %></strong> (<%= teacher.getUdiseNo() %>)
            <span style="margin: 0 10px;">→</span>
            <span>📚 Class:</span> <strong><%= classesLabel %></strong>
        </div>

        <div class="dashboard-grid">
            <div class="stat-card">
                <div class="stat-icon">👥</div>
                <div class="stat-value"><%= totalStudents %></div>
                <div class="stat-label">Total Students</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">📚</div>
                <div class="stat-value"><%= distinctClasses.size() %></div>
                <div class="stat-label">Classes</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">📋</div>
                <div class="stat-value"><%= assignments.size() %></div>
                <div class="stat-label">Sections</div>
            </div>
        </div>

        <h2>Activities</h2>
        <a class="activity-card" href="<%= request.getContextPath() %>/vidnyansetu-activity.jsp">
            <div class="icon">🔬</div>
            <div>
                <div class="title">VidnyanSetu Activity</div>
                <div class="desc">Log a science activity for your assigned class against the curriculum (Week → Day) with a video, for Head Master approval.</div>
            </div>
        </a>
        <a class="activity-card" href="<%= request.getContextPath() %>/vidnyansetu2-activity.jsp">
            <div class="icon">🧪</div>
            <div>
                <div class="title">VidnyanSetu 2 Activity</div>
                <div class="desc">Classes VI–IX: log a STEM activity with date, notes and a video, for Head Master approval.</div>
            </div>
        </a>
    </div>
</body>
</html>
