<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.UserDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%@ page import="java.sql.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.DIVISION)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    UserDAO userDAO = new UserDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    
    // Get statistics for this division
    String divisionName = user.getDivisionName();
    List<com.vjnt.model.Student> students = studentDAO.getStudentsByDivision(divisionName);
    List<User> divisionUsers = userDAO.getUsersByDivision(divisionName);
    
    // Pagination parameters for district list
    int districtCurrentPage = 1;
    int districtPageSize = 10;
    String districtPageParam = request.getParameter("districtPage");
    if (districtPageParam != null) {
        try {
            districtCurrentPage = Integer.parseInt(districtPageParam);
        } catch (NumberFormatException e) {
            districtCurrentPage = 1;
        }
    }
    
    // Calculate statistics
    Map<String, Integer> districtCount = new HashMap<>();
    Map<String, String> districtToSchoolCount = new HashMap<>();
    Map<String, Integer> districtToTeacherCount = new HashMap<>();
    Map<String, Integer> classCount = new HashMap<>();
    int maleCount = 0, femaleCount = 0;
    int totalSchools = 0;
    
    // Track unique UDISE codes per district
    Map<String, Set<String>> districtUdiseMap = new HashMap<>();
    
    for (com.vjnt.model.Student student : students) {
        String district = student.getDistrict();
        String udise = student.getUdiseNo();
        String studentClass = student.getStudentClass();
        
        if (district != null) {
            districtCount.put(district, districtCount.getOrDefault(district, 0) + 1);
            
            if (!districtUdiseMap.containsKey(district)) {
                districtUdiseMap.put(district, new HashSet<>());
            }
            if (udise != null) {
                districtUdiseMap.get(district).add(udise);
            }
        }
        
        if (studentClass != null) {
            classCount.put(studentClass, classCount.getOrDefault(studentClass, 0) + 1);
        }
        
        String gender = student.getGender();
        if ("Male".equalsIgnoreCase(gender) || "पुरुष".equals(gender)) {
            maleCount++;
        } else if ("Female".equalsIgnoreCase(gender) || "स्त्री".equals(gender)) {
            femaleCount++;
        }
    }
    
    // Count schools per district
    for (Map.Entry<String, Set<String>> entry : districtUdiseMap.entrySet()) {
        String district = entry.getKey();
        int schoolCount = entry.getValue().size();
        districtToSchoolCount.put(district, String.valueOf(schoolCount));
        totalSchools += schoolCount;
    }
    
    // Count teachers per district from teachers table
    System.out.println("=== Teacher Count Calculation (from teachers table) ===");
    Connection teacherConn = null;
    PreparedStatement teacherStmt = null;
    ResultSet teacherRs = null;
    try {
        teacherConn = com.vjnt.util.DatabaseConnection.getConnection();
        // Query to get teacher count by district
        // Join teachers table with schools table to get district information
        String teacherCountSql = "SELECT s.district_name, COUNT(DISTINCT t.teacher_id) as teacher_count " +
                                 "FROM teachers t " +
                                 "INNER JOIN schools s ON t.udise_code = s.udise_no " +
                                 "WHERE t.is_active = 1 " +
                                 "GROUP BY s.district_name";
        teacherStmt = teacherConn.prepareStatement(teacherCountSql);
        teacherRs = teacherStmt.executeQuery();
        
        int totalTeacherCount = 0;
        while (teacherRs.next()) {
            String district = teacherRs.getString("district_name");
            int count = teacherRs.getInt("teacher_count");
            if (district != null && !district.trim().isEmpty()) {
                districtToTeacherCount.put(district, count);
                totalTeacherCount += count;
                System.out.println("District: " + district + " - Teachers: " + count);
            }
        }
        System.out.println("Total teachers in division: " + totalTeacherCount);
        System.out.println("Districts with teachers: " + districtToTeacherCount.keySet());
    } catch (Exception e) {
        System.err.println("Error counting teachers: " + e.getMessage());
        e.printStackTrace();
    } finally {
        if (teacherRs != null) try { teacherRs.close(); } catch (Exception e) {}
        if (teacherStmt != null) try { teacherStmt.close(); } catch (Exception e) {}
        if (teacherConn != null) try { teacherConn.close(); } catch (Exception e) {}
    }
    System.out.println("=======================================================");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Division Dashboard - <%= divisionName %></title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: '\''Segoe UI'\'', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f7fa;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 0;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            border-radius: 0;
            margin-bottom: 30px;
        }
        
        .header-content {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 25px 30px;
            flex-wrap: wrap;
            gap: 20px;
        }
        
        .header-left {
            flex: 1;
            min-width: 300px;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 10px;
            text-align: center;
        }
        
        .header-logo {
            display: flex;
            justify-content: center;
            width: 100%;
        }
        
        .header-logo img {
            max-width: 150px;
            width: 150px;
            height: auto;
            display: block;
        }
        
        .header h1 {
            font-size: 28px;
            color: white;
            margin: 0 0 8px 0;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .gatee-tooltip {
            position: relative;
            display: inline-block;
            cursor: help;
            margin-left: 8px;
            color: #ffd700;
            font-size: 18px;
        }
        
        .gatee-tooltip:hover .tooltip-content {
            visibility: visible;
            opacity: 1;
        }
        
        .tooltip-content {
            visibility: hidden;
            opacity: 0;
            position: absolute;
            z-index: 1000;
            background: #2d3748;
            color: white;
            padding: 12px 15px;
            border-radius: 8px;
            font-size: 12px;
            white-space: nowrap;
            bottom: 125%;
            left: 50%;
            transform: translateX(-50%);
            transition: opacity 0.3s;
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }
        
        .tooltip-content::after {
            content: "";
            position: absolute;
            top: 100%;
            left: 50%;
            margin-left: -5px;
            border-width: 5px;
            border-style: solid;
            border-color: #2d3748 transparent transparent transparent;
        }
        
        .tooltip-content div {
            margin: 3px 0;
        }
        
        .header-subtitle {
            font-size: 15px;
            color: rgba(255,255,255,0.9);
            margin: 0;
            font-weight: 400;
        }
        
        .header-right {
            display: flex;
            flex-direction: column;
            align-items: flex-end;
            gap: 12px;
        }
        
        .user-info-box {
            background: rgba(255,255,255,0.15);
            padding: 12px 18px;
            border-radius: 8px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
        }
        
        .user-info {
            font-size: 14px;
            margin: 0 0 4px 0;
            color: white;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .user-info:last-child {
            margin-bottom: 0;
        }
        
        .user-info strong {
            font-weight: 600;
            color: #fff;
        }
        
        .header-actions {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .btn {
            padding: 10px 18px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.3s;
            font-weight: 500;
            box-shadow: 0 2px 5px rgba(0,0,0,0.15);
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0,0,0,0.25);
        }
        
        .btn:active {
            transform: translateY(0);
        }
        
        .btn-analytics {
            background: #4caf50;
            color: white;
        }
        
        .btn-analytics:hover {
            background: #45a049;
        }
        
        .btn-change-password {
            background: #ff9800;
            color: white;
        }
        
        .btn-change-password:hover {
            background: #f57c00;
        }
        
        .btn-logout {
            background: #f44336;
            color: white;
        }
        
        .btn-logout:hover {
            background: #d32f2f;
        }
        
        @media (max-width: 768px) {
            .header-content {
                flex-direction: column;
                align-items: stretch;
                gap: 15px;
            }
            
            .header-left {
                min-width: auto;
            }
            
            .header h1 {
                font-size: 22px;
            }
            
            .header-right {
                align-items: stretch;
            }
            
            .user-info-box {
                text-align: center;
            }
            
            .header-actions {
                justify-content: center;
            }
        }
        
        .container {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 30px;
        }
        
        .breadcrumb {
            background: white;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }
        
        .breadcrumb span {
            color: #666;
        }
        
        .breadcrumb strong {
            color: #333;
        }
        
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            transition: transform 0.3s;
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 4px 20px rgba(0,0,0,0.12);
        }
        
        .stat-icon {
            font-size: 36px;
            margin-bottom: 10px;
        }
        
        .stat-value {
            font-size: 32px;
            font-weight: bold;
            color: #4facfe;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 14px;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .section {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            margin-bottom: 30px;
        }
        
        .section-title {
            font-size: 20px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #4facfe;
        }
        
        .table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .table th {
            background: #f8f9fa;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #dee2e6;
        }
        
        .table td {
            padding: 12px;
            border-bottom: 1px solid #dee2e6;
        }
        
        .table tr:hover {
            background: #f8f9fa;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .badge-primary {
            background: #e3f2fd;
            color: #1976d2;
        }
        
        .badge-success {
            background: #e8f5e9;
            color: #388e3c;
        }
        
        .badge-warning {
            background: #fff3e0;
            color: #f57c00;
        }
        
        .progress-bar {
            width: 100%;
            height: 8px;
            background: #e0e0e0;
            border-radius: 4px;
            overflow: hidden;
            margin-top: 5px;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #4facfe 0%, #00f2fe 100%);
            transition: width 0.3s;
        }
        
        .chart-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        
        .chart-item {
            text-align: center;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 8px;
        }
        
        .chart-value {
            font-size: 28px;
            font-weight: bold;
            color: #4facfe;
        }
        
        .chart-label {
            font-size: 14px;
            color: #666;
            margin-top: 5px;
        }
        
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 8px;
            margin-top: 25px;
            flex-wrap: wrap;
        }
        
        .page-btn {
            padding: 8px 14px;
            background: white;
            color: #4facfe;
            border: 1px solid #e0e0e0;
            border-radius: 5px;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.3s;
            cursor: pointer;
        }
        
        .page-btn:hover {
            background: #4facfe;
            color: white;
            border-color: #4facfe;
        }
        
        .page-btn.active {
            background: #4facfe;
            color: white;
            border-color: #4facfe;
            font-weight: bold;
        }
        
        .page-btn:active {
            transform: scale(0.95);
        }
        
        @media (max-width: 768px) {
            .pagination {
                gap: 5px;
            }
            
            .page-btn {
                padding: 6px 10px;
                font-size: 12px;
            }
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div class="header-left">
                <!-- Logo Section - START -->
                <%-- <div class="header-logo">
                    <img src="<%= request.getContextPath() %>/Document/GATEE LOGO.png?v=2" alt="GATEE Logo">
                </div> --%>
                <!-- Logo Section - END -->
                <!-- Division Icon and Name Section - START -->
                <div class="school-icon">🏛️</div>
                <h1><%= divisionName %> Division</h1>
                <!-- Division Icon and Name Section - END -->
                <p class="header-subtitle">📍 Division Dashboard</p>
            </div>
            <div class="header-right">
                <div class="user-info-box">
                    <div class="user-info">
                        <span>👤</span>
                        <span>Welcome, <strong><%= user.getFullName() != null && !user.getFullName().isEmpty() ? user.getFullName() : user.getUsername() %></strong></span>
                    </div>
                    <div class="user-info">
                        <span>🎭</span>
                        <span><strong>Division Administrator</strong></span>
                    </div>
                </div>
                <div class="header-actions">
                    <a href="<%= request.getContextPath() %>/manage-notifications.jsp" class="btn" style="background: #9c27b0; color: white;" title="Create and manage announcements for schools">
                        <span>📢</span>
                        <span>Manage Announcements</span>
                    </a>
                    <a href="<%= request.getContextPath() %>/division-dashboard-enhanced.jsp" class="btn btn-analytics" title="View detailed analytics and reports">
                        <span>📊</span>
                        <span>Analytics</span>
                    </a>
                    <a href="<%= request.getContextPath() %>/division-activity-analysis.jsp" class="btn btn-logout" style="background: #FF9800;">📈 Activity Analysis</a>
                    
                    <a href="<%= request.getContextPath() %>/change-password" class="btn btn-change-password" title="Change your password">
                        <span>🔐</span>
                        <span>Change Password</span>
                    </a>
                    <a href="<%= request.getContextPath() %>/logout" class="btn btn-logout" title="Logout from the system">
                        <span>🚪</span>
                        <span>Logout</span>
                    </a>
                </div>
            </div>
        </div>
    </div>
    
    <div class="container">
        <!-- Breadcrumb -->
        <div class="breadcrumb">
            <span>Division:</span> <strong><%= divisionName %></strong>
        </div>
        
        <script>
        // Define teacher modal functions early so they're available for onclick events
        function escapeHtml(text) {
            if (!text) return '';
            const map = {
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&#039;'
            };
            return text.toString().replace(/[&<>"']/g, function(m) { return map[m]; });
        }
        
        function showDistrictTeacherDetails(districtName) {
            console.log('showDistrictTeacherDetails called with district:', districtName);
            
            const modal = document.getElementById('teacherDetailsModal');
            const modalDistrictInfo = document.getElementById('modalTeacherDistrictInfo');
            const content = document.getElementById('teacherDetailsContent');
            
            console.log('Modal element:', modal);
            console.log('Modal district info element:', modalDistrictInfo);
            console.log('Content element:', content);
            
            if (!modal) {
                console.error('Teacher modal element not found!');
                alert('Error: Teacher modal not found. Please refresh the page.');
                return;
            }
            
            // Show modal
            modal.style.display = 'block';
            console.log('Modal display set to block');
            
            // Update district info
            modalDistrictInfo.innerHTML = '<h3 style="margin: 0 0 5px 0; color: #333;">🏛️ ' + escapeHtml(districtName) + '</h3>' +
                '<p style="margin: 0; color: #666;">District</p>';
            
            // Show loading
            content.innerHTML = '<div style="text-align: center; padding: 50px;">' +
                '<div style="border: 4px solid #f3f3f3; border-top: 4px solid #28a745; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto;"></div>' +
                '<p style="margin-top: 15px; color: #666;">Loading teacher details...</p>' +
                '</div>';
            
            // Make AJAX request to get teacher details
            const apiUrl = '<%= request.getContextPath() %>/api/teachers?district=' + encodeURIComponent(districtName);
            console.log('Fetching from URL:', apiUrl);
            
            fetch(apiUrl)
                .then(response => {
                    console.log('Response status:', response.status);
                    if (!response.ok) {
                        throw new Error('HTTP error! status: ' + response.status);
                    }
                    return response.json();
                })
                .then(data => {
                    console.log('Received teacher data:', data);
                    console.log('Number of teachers:', data.length);
                    displayTeacherDetails(data, districtName);
                })
                .catch(error => {
                    console.error('Error fetching teacher details:', error);
                    content.innerHTML = '<div style="text-align: center; padding: 50px; color: #dc3545;">' +
                        '<p>❌ Error loading teacher details: ' + error.message + '</p>' +
                        '<p style="font-size: 12px; margin-top: 10px;">Please check the console for more details.</p>' +
                        '</div>';
                });
        }
        
        function displayTeacherDetails(teachers, districtName) {
            const content = document.getElementById('teacherDetailsContent');
            
            if (!teachers || teachers.length === 0) {
                content.innerHTML = '<div style="text-align: center; padding: 50px; color: #666;">' +
                    '<p>📭 No teachers found in this district.</p>' +
                    '</div>';
                return;
            }
            
            let html = '';
            
            // Teacher count summary
            html += '<div style="margin-bottom: 20px;">';
            html += '<div style="background: #e8f5e9; padding: 12px; border-radius: 8px; display: inline-flex; align-items: center; gap: 10px;">';
            html += '<span style="font-size: 18px;">👥</span>';
            html += '<span style="font-weight: bold; color: #2e7d32;">Total Teachers: ' + teachers.length + '</span>';
            html += '</div>';
            html += '</div>';
            
            // Search/Filter Box
            html += '<div style="margin-bottom: 20px;">';
            html += '<div style="position: relative;">';
            html += '<input type="text" id="teacherSearchInput" placeholder="🔍 Search by Teacher Name, School Name, Mobile, or Subjects..." ';
            html += 'onkeyup="filterTeachers()" ';
            html += 'style="width: 100%; padding: 12px 40px 12px 15px; border: 2px solid #28a745; border-radius: 8px; font-size: 14px; outline: none; transition: all 0.3s;">';
            html += '<button onclick="clearTeacherSearch()" id="clearTeacherSearchBtn" ';
            html += 'style="display: none; position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: #dc3545; color: white; border: none; border-radius: 50%; width: 28px; height: 28px; cursor: pointer; font-size: 14px; line-height: 1;">✕</button>';
            html += '</div>';
            html += '<div id="teacherSearchResultsInfo" style="margin-top: 8px; font-size: 13px; color: #666;"></div>';
            html += '</div>';
            
            // Teachers Table
            html += '<div style="overflow-x: auto;">';
            html += '<table id="teachersTable" style="width: 100%; border-collapse: collapse; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">';
            html += '<thead>';
            html += '<tr style="background: linear-gradient(135deg, #28a745 0%, #20c997 100%); color: white;">';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">#</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Teacher Name</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">School Name</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">UDISE No</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Mobile Number</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Subjects Taught</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Description</th>';
            html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Status</th>';
            html += '</tr>';
            html += '</thead>';
            html += '<tbody id="teachersTableBody">';
            html += '<tbody id="teachersTableBody">';
            
            teachers.forEach((teacher, index) => {
                html += '<tr class="teacher-row">';
                html += '<td style="padding: 10px; border: 1px solid #ddd;">' + (index + 1) + '</td>';
                html += '<td style="padding: 10px; border: 1px solid #ddd;" class="teacher-name"><strong>' + escapeHtml(teacher.teacherName || 'N/A') + '</strong></td>';
                
                // School name
                html += '<td style="padding: 10px; border: 1px solid #ddd;" class="school-name">' + escapeHtml(teacher.schoolName || 'N/A') + '</td>';
                
                // UDISE
                html += '<td style="padding: 10px; border: 1px solid #ddd;" class="udise-no"><code style="background: #e9ecef; padding: 2px 6px; border-radius: 3px;">' + escapeHtml(teacher.udiseNo || 'N/A') + '</code></td>';
                
                // Mobile number
                html += '<td style="padding: 10px; border: 1px solid #ddd;" class="mobile-number">';
                if (teacher.mobile) {
                    html += '📱 ' + escapeHtml(teacher.mobile);
                } else {
                    html += 'N/A';
                }
                html += '</td>';
                
                // Subjects taught
                html += '<td style="padding: 10px; border: 1px solid #ddd;" class="subjects">';
                if (teacher.subjects) {
                    const subjects = teacher.subjects.split(',');
                    subjects.forEach(subject => {
                        html += '<span style="display: inline-block; background: #e3f2fd; color: #1565c0; padding: 3px 8px; border-radius: 12px; font-size: 11px; margin: 2px;">' + escapeHtml(subject.trim()) + '</span>';
                    });
                } else {
                    html += 'N/A';
                }
                html += '</td>';
                
                // Description
                html += '<td style="padding: 10px; border: 1px solid #ddd; max-width: 200px; font-size: 12px; color: #666;">' + escapeHtml(teacher.description || '-') + '</td>';
                
                // Status
                html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">';
                if (teacher.isActive) {
                    html += '<span style="background: #28a745; color: white; padding: 4px 8px; border-radius: 12px; font-size: 11px;">✓ Active</span>';
                } else {
                    html += '<span style="background: #dc3545; color: white; padding: 4px 8px; border-radius: 12px; font-size: 11px;">✗ Inactive</span>';
                }
                html += '</td>';
                
                html += '</tr>';
            });
            
            html += '</tbody>';
            html += '</table>';
            html += '</div>';
            
            content.innerHTML = html;
            
            // Initialize search results info
            updateTeacherSearchResultsInfo(teachers.length, teachers.length);
        }
        
        function filterTeachers() {
            const input = document.getElementById('teacherSearchInput');
            const clearBtn = document.getElementById('clearTeacherSearchBtn');
            const filter = input.value.toUpperCase();
            const table = document.getElementById('teachersTable');
            const tr = table.getElementsByClassName('teacher-row');
            
            // Show/hide clear button
            clearBtn.style.display = filter ? 'block' : 'none';
            
            let visibleCount = 0;
            
            for (let i = 0; i < tr.length; i++) {
                const teacherName = tr[i].getElementsByClassName('teacher-name')[0];
                const schoolName = tr[i].getElementsByClassName('school-name')[0];
                const mobileNumber = tr[i].getElementsByClassName('mobile-number')[0];
                const subjects = tr[i].getElementsByClassName('subjects')[0];
                
                if (teacherName || schoolName || mobileNumber || subjects) {
                    const nameValue = teacherName ? (teacherName.textContent || teacherName.innerText) : '';
                    const schoolValue = schoolName ? (schoolName.textContent || schoolName.innerText) : '';
                    const mobileValue = mobileNumber ? (mobileNumber.textContent || mobileNumber.innerText) : '';
                    const subjectsValue = subjects ? (subjects.textContent || subjects.innerText) : '';
                    
                    if (nameValue.toUpperCase().indexOf(filter) > -1 || 
                        schoolValue.toUpperCase().indexOf(filter) > -1 || 
                        mobileValue.toUpperCase().indexOf(filter) > -1 || 
                        subjectsValue.toUpperCase().indexOf(filter) > -1) {
                        tr[i].style.display = '';
                        visibleCount++;
                    } else {
                        tr[i].style.display = 'none';
                    }
                }
            }
            
            // Update search results info
            updateTeacherSearchResultsInfo(visibleCount, tr.length);
        }
        
        function updateTeacherSearchResultsInfo(visibleCount, totalCount) {
            const infoDiv = document.getElementById('teacherSearchResultsInfo');
            if (!infoDiv) return;
            
            if (visibleCount === totalCount) {
                infoDiv.innerHTML = '<span style="color: #666;">Showing all ' + totalCount + ' teachers</span>';
            } else {
                infoDiv.innerHTML = '<span style="color: #28a745; font-weight: 600;">Found ' + visibleCount + ' of ' + totalCount + ' teachers</span>';
            }
        }
        
        function clearTeacherSearch() {
            const searchInput = document.getElementById('teacherSearchInput');
            searchInput.value = '';
            filterTeachers();
        }
        
        function closeTeacherModal() {
            document.getElementById('teacherDetailsModal').style.display = 'none';
        }
        
        // School Modal Functions
        function showDistrictSchoolDetails(districtName) {
            console.log('showDistrictSchoolDetails called with district:', districtName);
            
            const modal = document.getElementById('schoolDetailsModal');
            const modalDistrictInfo = document.getElementById('modalSchoolDistrictInfo');
            const content = document.getElementById('schoolDetailsContent');
            
            if (!modal) {
                console.error('School modal element not found!');
                alert('Error: School modal not found. Please refresh the page.');
                return;
            }
            
            // Show modal
            modal.style.display = 'block';
            
            // Update district info
            modalDistrictInfo.innerHTML = '<h3 style="margin: 0 0 5px 0; color: #333;">🏛️ ' + escapeHtml(districtName) + '</h3>' +
                '<p style="margin: 0; color: #666;">District</p>';
            
            // Show loading
            content.innerHTML = '<div style="text-align: center; padding: 50px;">' +
                '<div style="border: 4px solid #f3f3f3; border-top: 4px solid #ff9800; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto;"></div>' +
                '<p style="margin-top: 15px; color: #666;">Loading school details...</p>' +
                '</div>';
            
            // Make AJAX request to get school details
            const apiUrl = '<%= request.getContextPath() %>/api/schools?district=' + encodeURIComponent(districtName);
            console.log('Fetching schools from URL:', apiUrl);
            
            fetch(apiUrl)
                .then(response => {
                    console.log('Response status:', response.status);
                    if (!response.ok) {
                        throw new Error('HTTP error! status: ' + response.status);
                    }
                    return response.json();
                })
                .then(data => {
                    console.log('Received school data:', data);
                    console.log('Number of schools:', data.length);
                    displaySchoolDetails(data, districtName);
                })
                .catch(error => {
                    console.error('Error fetching school details:', error);
                    content.innerHTML = '<div style="text-align: center; padding: 50px; color: #dc3545;">' +
                        '<p>❌ Error loading school details: ' + error.message + '</p>' +
                        '<p style="font-size: 12px; margin-top: 10px;">Please check the console for more details.</p>' +
                        '</div>';
                });
        }
        
        function displaySchoolDetails(schools, districtName) {
            const content = document.getElementById('schoolDetailsContent');
            
            if (!schools || schools.length === 0) {
                content.innerHTML = '<div style="text-align: center; padding: 50px; color: #666;">' +
                    '<p>📭 No schools found in this district.</p>' +
                    '</div>';
                return;
            }
            
            let html = '';
            
            // School count summary
            html += '<div style="margin-bottom: 20px;">';
            html += '<div style="background: #fff3e0; padding: 12px; border-radius: 8px; display: inline-flex; align-items: center; gap: 10px;">';
            html += '<span style="font-size: 18px;">🏫</span>';
            html += '<span style="font-weight: bold; color: #e65100;">Total Schools: ' + schools.length + '</span>';
            html += '</div>';
            html += '</div>';
            
            // Search/Filter Box
            html += '<div style="margin-bottom: 20px;">';
            html += '<div style="position: relative;">';
            html += '<input type="text" id="schoolSearchInput" placeholder="🔍 Search by School Name, UDISE Number..." ';
            html += 'onkeyup="filterSchools()" ';
            html += 'style="width: 100%; padding: 12px 40px 12px 15px; border: 2px solid #ff9800; border-radius: 8px; font-size: 14px; outline: none; transition: all 0.3s;">';
            html += '<button onclick="clearSchoolSearch()" id="clearSchoolSearchBtn" ';
            html += 'style="display: none; position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: #dc3545; color: white; border: none; border-radius: 50%; width: 28px; height: 28px; cursor: pointer; font-size: 14px; line-height: 1;">✕</button>';
            html += '</div>';
            html += '<div id="schoolSearchResultsInfo" style="margin-top: 8px; font-size: 13px; color: #666;"></div>';
            html += '</div>';
            
            // Schools Table
            html += '<div style="overflow-x: auto;">';
            html += '<table id="schoolsTable" style="width: 100%; border-collapse: collapse; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">';
            html += '<thead>';
            html += '<tr style="background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%); color: white;">';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">#</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">School Name</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">UDISE Number</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">District</th>';
            html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Student Count</th>';
            html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Teacher Count</th>';
            html += '</tr>';
            html += '</thead>';
            html += '<tbody id="schoolsTableBody">';
            
            schools.forEach((school, index) => {
                html += '<tr class="school-row">';
                html += '<td style="padding: 10px; border: 1px solid #ddd;">' + (index + 1) + '</td>';
                html += '<td style="padding: 10px; border: 1px solid #ddd;" class="school-name"><strong>' + escapeHtml(school.schoolName || 'N/A') + '</strong></td>';
                
                // UDISE Number
                html += '<td style="padding: 10px; border: 1px solid #ddd;" class="udise-number"><code style="background: #e9ecef; padding: 2px 6px; border-radius: 3px;">' + escapeHtml(school.udiseNo || 'N/A') + '</code></td>';
                
                // District
                html += '<td style="padding: 10px; border: 1px solid #ddd;">' + escapeHtml(school.districtName || 'N/A') + '</td>';
                
                // Student Count
                html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">';
                if (school.studentCount && school.studentCount > 0) {
                    html += '<span style="background: #667eea; color: white; padding: 4px 8px; border-radius: 12px; font-size: 11px;">' + school.studentCount + ' students</span>';
                } else {
                    html += '<span style="color: #999;">No data</span>';
                }
                html += '</td>';
                
                // Teacher Count
                html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">';
                if (school.teacherCount && school.teacherCount > 0) {
                    html += '<span style="background: #28a745; color: white; padding: 4px 8px; border-radius: 12px; font-size: 11px;">' + school.teacherCount + ' teachers</span>';
                } else {
                    html += '<span style="color: #999;">No data</span>';
                }
                html += '</td>';
                
                html += '</tr>';
            });
            
            html += '</tbody>';
            html += '</table>';
            html += '</div>';
            
            content.innerHTML = html;
            
            // Initialize search results info
            updateSchoolSearchResultsInfo(schools.length, schools.length);
        }
        
        function filterSchools() {
            const input = document.getElementById('schoolSearchInput');
            const clearBtn = document.getElementById('clearSchoolSearchBtn');
            const filter = input.value.toUpperCase();
            const table = document.getElementById('schoolsTable');
            const tr = table.getElementsByClassName('school-row');
            
            // Show/hide clear button
            clearBtn.style.display = filter ? 'block' : 'none';
            
            let visibleCount = 0;
            
            for (let i = 0; i < tr.length; i++) {
                const schoolName = tr[i].getElementsByClassName('school-name')[0];
                const udiseNumber = tr[i].getElementsByClassName('udise-number')[0];
                
                if (schoolName || udiseNumber) {
                    const nameValue = schoolName ? (schoolName.textContent || schoolName.innerText) : '';
                    const udiseValue = udiseNumber ? (udiseNumber.textContent || udiseNumber.innerText) : '';
                    
                    if (nameValue.toUpperCase().indexOf(filter) > -1 || 
                        udiseValue.toUpperCase().indexOf(filter) > -1) {
                        tr[i].style.display = '';
                        visibleCount++;
                    } else {
                        tr[i].style.display = 'none';
                    }
                }
            }
            
            // Update search results info
            updateSchoolSearchResultsInfo(visibleCount, tr.length);
        }
        
        function updateSchoolSearchResultsInfo(visibleCount, totalCount) {
            const infoDiv = document.getElementById('schoolSearchResultsInfo');
            if (!infoDiv) return;
            
            if (visibleCount === totalCount) {
                infoDiv.innerHTML = '<span style="color: #666;">Showing all ' + totalCount + ' schools</span>';
            } else {
                infoDiv.innerHTML = '<span style="color: #ff9800; font-weight: 600;">Found ' + visibleCount + ' of ' + totalCount + ' schools</span>';
            }
        }
        
        function clearSchoolSearch() {
            const searchInput = document.getElementById('schoolSearchInput');
            searchInput.value = '';
            filterSchools();
        }
        
        function closeSchoolModal() {
            document.getElementById('schoolDetailsModal').style.display = 'none';
        }
        </script>
        
        <!-- Statistics Cards -->
        <div class="dashboard-grid">
            <div class="stat-card">
                <div class="stat-icon">👥</div>
                <div class="stat-value"><%= students.size() %></div>
                <div class="stat-label">Total Students</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">🏛️</div>
                <div class="stat-value"><%= districtCount.size() %></div>
                <div class="stat-label">Districts</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">🏫</div>
                <div class="stat-value"><%= totalSchools %></div>
                <div class="stat-label">Schools (UDISE)</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">👨‍🎓</div>
                <div class="stat-value"><%= maleCount %></div>
                <div class="stat-label">Male Students</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">👩‍🎓</div>
                <div class="stat-value"><%= femaleCount %></div>
                <div class="stat-label">Female Students</div>
            </div>
        </div>
        
        <!-- Class-wise Distribution -->
        <div class="section">
            <h2 class="section-title">📚 Class-wise Student Distribution</h2>
            <div class="chart-container">
                <% 
                List<Map.Entry<String, Integer>> sortedClasses = new ArrayList<>(classCount.entrySet());
                sortedClasses.sort((a, b) -> {
                    try {
                        return Integer.compare(Integer.parseInt(a.getKey()), Integer.parseInt(b.getKey()));
                    } catch (NumberFormatException e) {
                        return a.getKey().compareTo(b.getKey());
                    }
                });
                
                for (Map.Entry<String, Integer> entry : sortedClasses) { 
                %>
                <div class="chart-item">
                    <div class="chart-value"><%= entry.getValue() %></div>
                    <div class="chart-label">Class <%= entry.getKey() %></div>
                </div>
                <% } %>
            </div>
        </div>
        
        <!-- District-wise Statistics -->
        <div class="section">
            <h2 class="section-title">🏛️ District-wise Student Count</h2>
            
            <% 
            // Sort and paginate district list
            List<Map.Entry<String, Integer>> sortedDistricts = new ArrayList<>(districtCount.entrySet());
            sortedDistricts.sort((a, b) -> a.getKey().compareTo(b.getKey()));
            
            int totalDistricts = sortedDistricts.size();
            int districtTotalPages = (int) Math.ceil((double) totalDistricts / districtPageSize);
            int districtStartIndex = (districtCurrentPage - 1) * districtPageSize;
            int districtEndIndex = Math.min(districtStartIndex + districtPageSize, totalDistricts);
            
            List<Map.Entry<String, Integer>> paginatedDistricts = sortedDistricts.subList(districtStartIndex, districtEndIndex);
            %>
            
            <div style="margin-bottom: 15px; color: #666; font-size: 14px;">
                Showing <%= districtStartIndex + 1 %> - <%= districtEndIndex %> of <%= totalDistricts %> districts
            </div>
            
            <table class="table">
                <thead>
                    <tr>
                        <th>District Name</th>
                        <th>Student Count</th>
                        <th>School Count</th>
                        <th>Teacher Count</th>
                        <th>Male</th>
                        <th>Female</th>
                        <th>Percentage</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                    for (Map.Entry<String, Integer> entry : paginatedDistricts) {
                        String district = entry.getKey();
                        int totalCount = entry.getValue();
                        int schoolCount = Integer.parseInt(districtToSchoolCount.getOrDefault(district, "0"));
                        int teacherCount = districtToTeacherCount.getOrDefault(district, 0);
                        
                        // Count gender for this district
                        int districtMale = 0, districtFemale = 0;
                        for (com.vjnt.model.Student s : students) {
                            if (district.equals(s.getDistrict())) {
                                String g = s.getGender();
                                if ("Male".equalsIgnoreCase(g) || "पुरुष".equals(g)) {
                                    districtMale++;
                                } else if ("Female".equalsIgnoreCase(g) || "स्त्री".equals(g)) {
                                    districtFemale++;
                                }
                            }
                        }
                        
                        double percentage = students.size() > 0 ? (totalCount * 100.0 / students.size()) : 0;
                    %>
                    <tr>
                        <td><strong style="color: #667eea;"><%= district %></strong></td>
                        <td>
                            <span class="badge badge-primary" style="cursor: pointer;" 
                                  onclick="showDistrictStudentDetails('<%= district %>')">
                                <%= totalCount %> students
                            </span>
                        </td>
                        <td>
                            <span class="badge badge-warning" style="cursor: pointer;" 
                                  onclick="showDistrictSchoolDetails('<%= district %>')">
                                <%= schoolCount %> schools
                            </span>
                        </td>
                        <td>
                            <span class="badge badge-success" style="cursor: pointer;" 
                                  onclick="showDistrictTeacherDetails('<%= district %>')">
                                <%= teacherCount %> teachers
                            </span>
                        </td>
                        <td><%= districtMale %></td>
                        <td><%= districtFemale %></td>
                        <td>
                            <%= String.format("%.1f", percentage) %>%
                            <div class="progress-bar">
                                <div class="progress-fill" style="width: <%= percentage %>%;"></div>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
            
            <!-- Pagination Controls -->
            <% if (districtTotalPages > 1) { %>
            <div class="pagination">
                <% if (districtCurrentPage > 1) { %>
                    <a href="?districtPage=<%= districtCurrentPage - 1 %>" class="page-btn">« Previous</a>
                <% } %>
                
                <% 
                int startPage = Math.max(1, districtCurrentPage - 2);
                int endPage = Math.min(districtTotalPages, districtCurrentPage + 2);
                
                for (int i = startPage; i <= endPage; i++) { 
                %>
                    <a href="?districtPage=<%= i %>" class="page-btn <%= i == districtCurrentPage ? "active" : "" %>"><%= i %></a>
                <% } %>
                
                <% if (districtCurrentPage < districtTotalPages) { %>
                    <a href="?districtPage=<%= districtCurrentPage + 1 %>" class="page-btn">Next »</a>
                <% } %>
            </div>
            <% } %>
        </div>
        
    </div>
    
    <!-- Student Details Modal -->
    <div id="studentDetailsModal" style="display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.6);">
        <div style="background-color: #fefefe; margin: 2% auto; padding: 0; border-radius: 10px; width: 90%; max-width: 1200px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
            <!-- Modal Header -->
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <h2 style="margin: 0; font-size: 24px;">📊 Student Details</h2>
                <span onclick="closeStudentModal()" style="cursor: pointer; font-size: 28px; font-weight: bold;">&times;</span>
            </div>
            
            <!-- Modal Body -->
            <div style="padding: 25px; max-height: 70vh; overflow-y: auto;">
                <div id="modalDistrictInfo" style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #667eea;">
                    <h3 style="margin: 0 0 5px 0; color: #333;">Loading...</h3>
                    <p style="margin: 0; color: #666;">Please wait...</p>
                </div>
                
                <!-- Search Box -->
                <div id="studentSearchContainer" style="display: none; margin-bottom: 20px;">
                    <div style="position: relative;">
                        <input type="text" 
                               id="studentSearchInput" 
                               placeholder="🔍 Search by Name, PEN Number, or Class..." 
                               onkeyup="filterStudents()"
                               style="width: 100%; padding: 12px 40px 12px 15px; border: 2px solid #667eea; border-radius: 8px; font-size: 14px; outline: none; transition: all 0.3s;">
                        <button onclick="clearStudentSearch()" 
                                id="clearSearchBtn"
                                style="display: none; position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: #dc3545; color: white; border: none; border-radius: 50%; width: 28px; height: 28px; cursor: pointer; font-size: 14px; line-height: 1;">✕</button>
                    </div>
                    <div id="searchResultsInfo" style="margin-top: 8px; font-size: 13px; color: #666;"></div>
                </div>
                
                <div id="studentDetailsContent" style="min-height: 200px;">
                    <div style="text-align: center; padding: 50px;">
                        <div style="border: 4px solid #f3f3f3; border-top: 4px solid #667eea; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto;"></div>
                        <p style="margin-top: 15px; color: #666;">Loading student details...</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
     <!-- Activities Modal -->
    <div id="activitiesModal" style="display: none; position: fixed; z-index: 1001; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.6);">
        <div style="background-color: #fefefe; margin: 3% auto; padding: 0; border-radius: 10px; width: 85%; max-width: 900px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
            <!-- Modal Header -->
            <div style="background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <h2 style="margin: 0; font-size: 22px;" id="activitiesModalTitle">📋 All Activities</h2>
                <span onclick="closeActivitiesModal()" style="cursor: pointer; font-size: 28px; font-weight: bold;">&times;</span>
            </div>
            
            <!-- Modal Body -->
            <div style="padding: 20px; max-height: 65vh; overflow-y: auto;">
                <div id="activitiesContent"></div>
            </div>
        </div>
    </div>
    
    <!-- Videos Modal -->
    <div id="videosModal" style="display: none; position: fixed; z-index: 1002; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.6);">
        <div style="background-color: #fefefe; margin: 3% auto; padding: 0; border-radius: 10px; width: 85%; max-width: 1000px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
            <!-- Modal Header -->
            <div style="background: linear-gradient(135deg, #0277bd 0%, #01579b 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <h2 style="margin: 0; font-size: 22px;" id="videosModalTitle">🎬 All Videos</h2>
                <span onclick="closeVideosModal()" style="cursor: pointer; font-size: 28px; font-weight: bold;">&times;</span>
            </div>
            
            <!-- Modal Body -->
            <div style="padding: 20px; max-height: 65vh; overflow-y: auto;">
                <div id="videosContent"></div>
            </div>
        </div>
    </div>
    
    <!-- Phases Modal -->
    <div id="phasesModal" style="display: none; position: fixed; z-index: 1003; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.6);">
        <div style="background-color: #fefefe; margin: 2% auto; padding: 0; border-radius: 10px; width: 90%; max-width: 1100px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
            <!-- Modal Header -->
            <div style="background: linear-gradient(135deg, #7b1fa2 0%, #4a148c 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <h2 style="margin: 0; font-size: 22px;" id="phasesModalTitle">📊 Phase-wise Subject Levels</h2>
                <span onclick="closePhasesModal()" style="cursor: pointer; font-size: 28px; font-weight: bold;">&times;</span>
            </div>
            
            <!-- Modal Body -->
            <div style="padding: 20px; max-height: 70vh; overflow-y: auto;">
                <div id="phasesContent"></div>
            </div>
        </div>
    </div>
    
    <!-- Teacher Details Modal -->
    <div id="teacherDetailsModal" style="display: none; position: fixed; z-index: 1004; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.6);">
        <div style="background-color: #fefefe; margin: 2% auto; padding: 0; border-radius: 10px; width: 90%; max-width: 1200px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
            <!-- Modal Header -->
            <div style="background: linear-gradient(135deg, #28a745 0%, #20c997 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <h2 style="margin: 0; font-size: 24px;">👨‍🏫 Teacher Details</h2>
                <span onclick="closeTeacherModal()" style="cursor: pointer; font-size: 28px; font-weight: bold;">&times;</span>
            </div>
            
            <!-- Modal Body -->
            <div style="padding: 25px; max-height: 70vh; overflow-y: auto;">
                <div id="modalTeacherDistrictInfo" style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #28a745;">
                    <h3 style="margin: 0 0 5px 0; color: #333;">Loading...</h3>
                    <p style="margin: 0; color: #666;">Please wait...</p>
                </div>
                
                <div id="teacherDetailsContent" style="min-height: 200px;">
                    <div style="text-align: center; padding: 50px;">
                        <div style="border: 4px solid #f3f3f3; border-top: 4px solid #28a745; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto;"></div>
                        <p style="margin-top: 15px; color: #666;">Loading teacher details...</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- School Details Modal -->
    <div id="schoolDetailsModal" style="display: none; position: fixed; z-index: 1005; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.6);">
        <div style="background-color: #fefefe; margin: 2% auto; padding: 0; border-radius: 10px; width: 90%; max-width: 1200px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
            <!-- Modal Header -->
            <div style="background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <h2 style="margin: 0; font-size: 24px;">🏫 School Details</h2>
                <span onclick="closeSchoolModal()" style="cursor: pointer; font-size: 28px; font-weight: bold;">&times;</span>
            </div>
            
            <!-- Modal Body -->
            <div style="padding: 25px; max-height: 70vh; overflow-y: auto;">
                <div id="modalSchoolDistrictInfo" style="background: #fff3e0; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #ff9800;">
                    <h3 style="margin: 0 0 5px 0; color: #333;">Loading...</h3>
                    <p style="margin: 0; color: #666;">Please wait...</p>
                </div>
                
                <div id="schoolDetailsContent" style="min-height: 200px;">
                    <div style="text-align: center; padding: 50px;">
                        <div style="border: 4px solid #f3f3f3; border-top: 4px solid #ff9800; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto;"></div>
                        <p style="margin-top: 15px; color: #666;">Loading school details...</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Global variable to store students data
        let currentStudentsData = [];
        
        // Helper function to escape HTML - defined early so it's available everywhere
        function escapeHtml(text) {
            if (!text) return '';
            const map = {
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&#039;'
            };
            return text.toString().replace(/[&<>"']/g, function(m) { return map[m]; });
        }
        
        // Helper function to extract YouTube video ID from various URL formats
        function extractYouTubeVideoId(url) {
            if (!url) return null;
            
            // Handle different YouTube URL formats
            const patterns = [
                /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)/,
                /^([a-zA-Z0-9_-]{11})$/ // Direct video ID
            ];
            
            for (const pattern of patterns) {
                const match = url.match(pattern);
                if (match && match[1]) {
                    return match[1];
                }
            }
            
            return null;
        }
        
        function showDistrictStudentDetails(districtName) {
            const modal = document.getElementById('studentDetailsModal');
            const modalDistrictInfo = document.getElementById('modalDistrictInfo');
            const content = document.getElementById('studentDetailsContent');
            
            // Show modal
            modal.style.display = 'block';
            
            // Update district info
            modalDistrictInfo.innerHTML = '<h3 style="margin: 0 0 5px 0; color: #333;">🏛️ ' + escapeHtml(districtName) + '</h3>' +
                '<p style="margin: 0; color: #666;">District</p>';
            
            // Show loading
            content.innerHTML = '<div style="text-align: center; padding: 50px;">' +
                '<div style="border: 4px solid #f3f3f3; border-top: 4px solid #667eea; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto;"></div>' +
                '<p style="margin-top: 15px; color: #666;">Loading student details...</p>' +
                '</div>';
            
            // Fetch student details
            fetch('GetDistrictStudentsServlet?district=' + encodeURIComponent(districtName))
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.students && data.students.length > 0) {
                        displayStudents(data.students);
                    } else {
                        content.innerHTML = '<div class="no-data">No students found for this district.</div>';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    content.innerHTML = '<div class="no-data" style="color: #dc3545;">Error loading student details. Please try again.</div>';
                });
        }
        
        
        function closeActivitiesModal() {
            document.getElementById('activitiesModal').style.display = 'none';
        }
        
        function closeVideosModal() {
            document.getElementById('videosModal').style.display = 'none';
        }
        
        function closePhasesModal() {
            document.getElementById('phasesModal').style.display = 'none';
        }
        function displayStudents(students) {
            // Store students data globally for access by other functions
            currentStudentsData = students;
            
            const content = document.getElementById('studentDetailsContent');
            let html = '';
            
            // Create table
              html += '<div style="overflow-x: auto;">';
            html += '<table style="width: 100%; border-collapse: collapse; font-size: 13px;">';
            html += '<thead>';
            html += '<tr style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Sr No</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Student Name</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">PEN Number</th>';
            html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Class</th>';
            html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Gender</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Marathi Levels</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Math Levels</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">English Level</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Activities</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Videos</th>';
            html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Phases</th>';
            html += '</tr>';
            html += '</thead>';
            html += '<tbody>';
            
            students.forEach((student, index) => {
            	  html += '<tr style="background: ' + (index % 2 === 0 ? '#f8f9fa' : '#ffffff') + ';">';
                  
                  // Sr No
                  html += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">' + (index + 1) + '</td>';
                  
                  // Student Name
                  html += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: 600; color: #333;">' + escapeHtml(student.name) + '</td>';
                  
                  // PEN Number
                  html += '<td style="padding: 10px; border: 1px solid #ddd; color: #666;">' + escapeHtml(student.penNumber || 'N/A') + '</td>';
                  
                  // Class
                  html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">' + escapeHtml(student.studentClass || 'N/A') + '</td>';
                  
                  // Gender
                  html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">' + escapeHtml(student.gender || 'N/A') + '</td>';
                  
                  // Marathi Levels
                  html += '<td style="padding: 10px; border: 1px solid #ddd; font-size: 11px;">';
                  let marathiLevels = [];
                  if (student.marathiAksharaLevelText && student.marathiAksharaLevelText !== 'स्तर निश्चित केला नाही') marathiLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #e3f2fd; color: #1976d2; border-radius: 3px;"> ' + escapeHtml(student.marathiAksharaLevelText) + '</div>');
                 /*  if (student.marathiShabdaLevelText && student.marathiShabdaLevelText !== 'स्तर निश्चित केला नाही') marathiLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #e3f2fd; color: #1976d2; border-radius: 3px;"><strong>शब्द:</strong> ' + escapeHtml(student.marathiShabdaLevelText) + '</div>');
                  if (student.marathiVakyaLevelText && student.marathiVakyaLevelText !== 'स्तर निश्चित केला नाही') marathiLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #e3f2fd; color: #1976d2; border-radius: 3px;"><strong>वाक्य:</strong> ' + escapeHtml(student.marathiVakyaLevelText) + '</div>');
                  if (student.marathiSamajpurvakLevelText && student.marathiSamajpurvakLevelText !== 'स्तर निश्चित केला नाही') marathiLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #e3f2fd; color: #1976d2; border-radius: 3px;"><strong>समजपूर्वक:</strong> ' + escapeHtml(student.marathiSamajpurvakLevelText) + '</div>');
             */      html += marathiLevels.length > 0 ? marathiLevels.join('') : '<span style="color: #999;">-</span>';
                  html += '</td>';
                  
                  // Math Levels
                  html += '<td style="padding: 10px; border: 1px solid #ddd; font-size: 11px;">';
                  let mathLevels = [];
                  if (student.mathAksharaLevelText && student.mathAksharaLevelText !== 'स्तर निश्चित केला नाही') mathLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #f3e5f5; color: #7b1fa2; border-radius: 3px;"> ' + escapeHtml(student.mathAksharaLevelText) + '</div>');
                 /*  if (student.mathShabdaLevelText && student.mathShabdaLevelText !== 'स्तर निश्चित केला नाही') mathLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #f3e5f5; color: #7b1fa2; border-radius: 3px;"><strong>शब्द:</strong> ' + escapeHtml(student.mathShabdaLevelText) + '</div>');
                  if (student.mathVakyaLevelText && student.mathVakyaLevelText !== 'स्तर निश्चित केला नाही') mathLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #f3e5f5; color: #7b1fa2; border-radius: 3px;"><strong>वाक्य:</strong> ' + escapeHtml(student.mathVakyaLevelText) + '</div>');
                  if (student.mathSamajpurvakLevelText && student.mathSamajpurvakLevelText !== 'स्तर निश्चित केला नाही') mathLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #f3e5f5; color: #7b1fa2; border-radius: 3px;"><strong>समजपूर्वक:</strong> ' + escapeHtml(student.mathSamajpurvakLevelText) + '</div>');
           */        html += mathLevels.length > 0 ? mathLevels.join('') : '<span style="color: #999;">-</span>';
                  html += '</td>';
                  
                  // English Level
                  html += '<td style="padding: 10px; border: 1px solid #ddd; font-size: 11px;">';
                  if (student.englishAksharaLevelText && student.englishAksharaLevelText !== 'स्तर निश्चित केला नाही') {
                      html += '<div style="padding: 4px 6px; background: #e8f5e9; color: #2e7d32; border-radius: 3px;">' + escapeHtml(student.englishAksharaLevelText) + '</div>';
                  } else {
                      html += '<span style="color: #999;">-</span>';
                  }
                  html += '</td>';
                  
                  // Activities - Lazy loading
                  html += '<td style="padding: 10px; border: 1px solid #ddd;">';
                  html += '<button class="load-activities-btn" data-index="' + index + '" data-student-id="' + student.studentId + '" style="background: #2196f3; color: white; border: none; padding: 6px 12px; border-radius: 3px; cursor: pointer; font-size: 11px; width: 100%;">📋 Load Activities</button>';
                  html += '</td>';
                  
                  // Videos - Lazy loading
                  html += '<td style="padding: 10px; border: 1px solid #ddd;">';
                  html += '<button class="load-videos-btn" data-index="' + index + '" data-student-id="' + student.studentId + '" style="background: #0277bd; color: white; border: none; padding: 6px 12px; border-radius: 3px; cursor: pointer; font-size: 11px; width: 100%;">🎬 Load Videos</button>';
                  html += '</td>';
                  
                  // Phases
                  html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">';
                  html += '<div style="display: flex; flex-wrap: wrap; gap: 3px; justify-content: center; margin-bottom: 5px;">';
                  html += '<span style="display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 10px; ' + (student.phase1Date ? 'background: #c8e6c9; color: #2e7d32;' : 'background: #ffcdd2; color: #c62828;') + '">P1' + (student.phase1Date ? '✓' : '✗') + '</span>';
                  html += '<span style="display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 10px; ' + (student.phase2Date ? 'background: #c8e6c9; color: #2e7d32;' : 'background: #ffcdd2; color: #c62828;') + '">P2' + (student.phase2Date ? '✓' : '✗') + '</span>';
                  html += '<span style="display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 10px; ' + (student.phase3Date ? 'background: #c8e6c9; color: #2e7d32;' : 'background: #ffcdd2; color: #c62828;') + '">P3' + (student.phase3Date ? '✓' : '✗') + '</span>';
                  html += '<span style="display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 10px; ' + (student.phase4Date ? 'background: #c8e6c9; color: #2e7d32;' : 'background: #ffcdd2; color: #c62828;') + '">P4' + (student.phase4Date ? '✓' : '✗') + '</span>';
                  html += '</div>';
                  html += '<button onclick="showAllPhases(' + index + ')" style="background: #7b1fa2; color: white; border: none; padding: 4px 8px; border-radius: 3px; cursor: pointer; font-size: 10px; width: 100%;">📊 View All Phases</button>';
                  html += '</td>';
                  
                  html += '</tr>';
            });
            
            html += '</tbody>';
            html += '</table>';
            html += '</div>';
            
            content.innerHTML = html;
            
            // Show search container
            document.getElementById('studentSearchContainer').style.display = 'block';
            
            // Attach event listeners to dynamically created buttons
            attachButtonEventListeners();
        }
        
        // Attach event listeners to load activities and videos buttons
        function attachButtonEventListeners() {
            // Activities buttons
            const activityButtons = document.querySelectorAll('.load-activities-btn');
            activityButtons.forEach(button => {
                button.addEventListener('click', function() {
                    const index = parseInt(this.getAttribute('data-index'));
                    const studentId = parseInt(this.getAttribute('data-student-id'));
                    loadAndShowActivities(index, studentId);
                });
            });
            
            // Videos buttons
            const videoButtons = document.querySelectorAll('.load-videos-btn');
            videoButtons.forEach(button => {
                button.addEventListener('click', function() {
                    const index = parseInt(this.getAttribute('data-index'));
                    const studentId = parseInt(this.getAttribute('data-student-id'));
                    loadAndShowVideos(index, studentId);
                });
            });
        }
        
        function closeStudentModal() {
            document.getElementById('studentDetailsModal').style.display = 'none';
        }
        
        function showAllPhases(studentIndex) {
            // Get student data from global array
            if (!currentStudentsData || studentIndex >= currentStudentsData.length) {
                alert('Error: Student data not found');
                return;
            }
            
            const student = currentStudentsData[studentIndex];
            const studentName = student.name || 'Unknown Student';
            
            const modal = document.getElementById('phasesModal');
            const title = document.getElementById('phasesModalTitle');
            const content = document.getElementById('phasesContent');
            
            // Update title
            title.textContent = '📊 Phase-wise Subject Levels for ' + studentName;
            
            // Build HTML
            let html = '';
            html += '<div style="background: #f3e5f5; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #7b1fa2;">';
            html += '<h3 style="margin: 0 0 8px 0; color: #4a148c;">Student: ' + escapeHtml(studentName) + '</h3>';
            html += '<p style="margin: 0; color: #666; font-size: 14px;">Track language proficiency levels across all 4 phases</p>';
            html += '</div>';
            
            // Phase data array
            const phases = [
                {
                    num: 1,
                    marathi: student.phase1MarathiText,
                    math: student.phase1MathText,
                    english: student.phase1EnglishText,
                    date: student.phase1Date,
                    completed: !!student.phase1Date
                },
                {
                    num: 2,
                    marathi: student.phase2MarathiText,
                    math: student.phase2MathText,
                    english: student.phase2EnglishText,
                    date: student.phase2Date,
                    completed: !!student.phase2Date
                },
                {
                    num: 3,
                    marathi: student.phase3MarathiText,
                    math: student.phase3MathText,
                    english: student.phase3EnglishText,
                    date: student.phase3Date,
                    completed: !!student.phase3Date
                },
                {
                    num: 4,
                    marathi: student.phase4MarathiText,
                    math: student.phase4MathText,
                    english: student.phase4EnglishText,
                    date: student.phase4Date,
                    completed: !!student.phase4Date
                }
            ];
            
            // Display each phase
            phases.forEach(phase => {
                const bgColor = phase.completed ? '#f1f8e9' : '#fafafa';
                const borderColor = phase.completed ? '#7cb342' : '#bdbdbd';
                const statusIcon = phase.completed ? '✓' : '○';
                const statusText = phase.completed ? 'Completed' : 'Not Completed';
                const statusColor = phase.completed ? '#7cb342' : '#999';
                
                html += '<div style="background: ' + bgColor + '; padding: 18px; border-radius: 10px; margin-bottom: 15px; border: 2px solid ' + borderColor + '; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">';
                
                // Phase Header
                html += '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; padding-bottom: 10px; border-bottom: 2px solid ' + borderColor + ';">';
                html += '<h3 style="margin: 0; color: #333; font-size: 18px;">📋 Phase ' + phase.num + '</h3>';
                html += '<div style="text-align: right;">';
                html += '<div style="font-size: 20px; color: ' + statusColor + ';">' + statusIcon + '</div>';
                html += '<div style="font-size: 11px; color: ' + statusColor + '; font-weight: 600;">' + statusText + '</div>';
                if (phase.date) {
                    html += '<div style="font-size: 10px; color: #666; margin-top: 3px;">📅 ' + phase.date + '</div>';
                }
                html += '</div>';
                html += '</div>';
                
                // Subject Levels Grid
                html += '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 12px;">';
                
                // Marathi
                html += '<div style="background: white; padding: 12px; border-radius: 8px; border-left: 4px solid #ff9800;">';
                html += '<div style="font-weight: 600; color: #e65100; margin-bottom: 6px; font-size: 13px;">📚 मराठी (Marathi)</div>';
                if (phase.marathi && phase.marathi !== 'स्तर निश्चित केला नाही') {
                    html += '<div style="font-size: 12px; color: #333; line-height: 1.4;">' + escapeHtml(phase.marathi) + '</div>';
                } else {
                    html += '<div style="font-size: 12px; color: #999; font-style: italic;">स्तर निश्चित केला नाही</div>';
                }
                html += '</div>';
                
                // Math
                html += '<div style="background: white; padding: 12px; border-radius: 8px; border-left: 4px solid #9c27b0;">';
                html += '<div style="font-weight: 600; color: #6a1b9a; margin-bottom: 6px; font-size: 13px;">🔢 गणित (Math)</div>';
                if (phase.math && phase.math !== 'स्तर निश्चित केला नाही') {
                    html += '<div style="font-size: 12px; color: #333; line-height: 1.4;">' + escapeHtml(phase.math) + '</div>';
                } else {
                    html += '<div style="font-size: 12px; color: #999; font-style: italic;">स्तर निश्चित केला नाही</div>';
                }
                html += '</div>';
                
                // English
                html += '<div style="background: white; padding: 12px; border-radius: 8px; border-left: 4px solid #4caf50;">';
                html += '<div style="font-weight: 600; color: #2e7d32; margin-bottom: 6px; font-size: 13px;">🔤 English</div>';
                if (phase.english && phase.english !== 'स्तर निश्चित केला नाही') {
                    html += '<div style="font-size: 12px; color: #333; line-height: 1.4;">' + escapeHtml(phase.english) + '</div>';
                } else {
                    html += '<div style="font-size: 12px; color: #999; font-style: italic;">स्तर निश्चित केला नाही</div>';
                }
                html += '</div>';
                
                html += '</div>'; // End grid
                html += '</div>'; // End phase card
            });
            
            // Summary Statistics
            const completedPhases = phases.filter(p => p.completed).length;
            html += '<div style="background: linear-gradient(135deg, #7b1fa2 0%, #4a148c 100%); color: white; padding: 15px; border-radius: 8px; margin-top: 20px; text-align: center;">';
            html += '<div style="font-size: 16px; font-weight: 600;">Progress Summary</div>';
            html += '<div style="font-size: 28px; font-weight: bold; margin: 8px 0;">' + completedPhases + ' / 4 Phases Completed</div>';
            html += '<div style="font-size: 13px; opacity: 0.9;">(' + Math.round((completedPhases / 4) * 100) + '% Complete)</div>';
            html += '</div>';
            
            content.innerHTML = html;
            modal.style.display = 'block';
        }
        
        // Helper function to get Marathi level text
        function getMarathiLevelText(level) {
            if (!level || level === '0') return 'स्तर निश्चित केला नाही';
            const levels = {
                '1': 'प्रारंभिक स्तर',
                '2': 'अक्षर स्तर',
                '3': 'शब्द स्तर',
                '4': 'वाक्य स्तर',
                '5': 'समजपूर्वक उतारा वाचन स्तर',
                '6': 'FLN 100% पूर्ण'
            };
            return levels[level] || 'स्तर निश्चित केला नाही';
        }
        
        window.onclick = function(event) {
            const studentModal = document.getElementById('studentDetailsModal');
            const activitiesModal = document.getElementById('activitiesModal');
            const videosModal = document.getElementById('videosModal');
            const phasesModal = document.getElementById('phasesModal');
            if (event.target == studentModal) {
                closeStudentModal();
            }
            if (event.target == activitiesModal) {
                closeActivitiesModal();
            }
            if (event.target == videosModal) {
                closeVideosModal();
            }
            if (event.target == phasesModal) {
                closePhasesModal();
            }
        }
        
        // Helper function to get Math level text
        function getMathLevelText(level) {
            if (!level || level === '0') return 'स्तर निश्चित केला नाही';
            const levels = {
                '1': 'संख्या ओळख स्तर',
                '2': 'बेरीज स्तर',
                '3': 'वजाबाकी स्तर',
                '4': 'गुणाकार स्तर',
                '5': 'भागाकार स्तर',
                '6': 'भिन्न स्तर',
                '7': 'दशांश स्तर',
                '8': 'FLN 100% पूर्ण'
            };
            return levels[level] || 'स्तर निश्चित केला नाही';
        }
        
        // Lazy load activities for a student
        function loadAndShowActivities(studentIndex, studentId) {
            if (!currentStudentsData || studentIndex >= currentStudentsData.length) {
                alert('Error: Student data not found');
                return;
            }
            
            const student = currentStudentsData[studentIndex];
            
            // Check if already loaded (activities property exists and is an array)
            if (student.activities !== undefined && Array.isArray(student.activities)) {
                showAllActivitiesByIndex(studentIndex);
                return;
            }
            
            // Show loading indicator
            const modal = document.getElementById('activitiesModal');
            const title = document.getElementById('activitiesModalTitle');
            const content = document.getElementById('activitiesContent');
            
            title.textContent = '📋 Loading Activities...';
            content.innerHTML = '<div style="text-align: center; padding: 50px;">' +
                '<div style="border: 4px solid #f3f3f3; border-top: 4px solid #ff9800; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto;"></div>' +
                '<p style="margin-top: 15px; color: #666;">Loading activities...</p>' +
                '</div>';
            modal.style.display = 'block';
            
            // Fetch activities
            fetch('GetStudentActivitiesServlet?studentId=' + studentId)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        student.activities = data.activities || [];
                        showAllActivitiesByIndex(studentIndex);
                    } else {
                        content.innerHTML = '<div style="text-align: center; padding: 40px; color: #dc3545;">Error loading activities: ' + escapeHtml(data.message || 'Unknown error') + '</div>';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    content.innerHTML = '<div style="text-align: center; padding: 40px; color: #dc3545;">Error loading activities. Please try again.</div>';
                });
        }
        
        // Lazy load videos for a student
        function loadAndShowVideos(studentIndex, studentId) {
            if (!currentStudentsData || studentIndex >= currentStudentsData.length) {
                alert('Error: Student data not found');
                return;
            }
            
            const student = currentStudentsData[studentIndex];
            
            // Check if already loaded (videos property exists and is an array)
            if (student.videos !== undefined && Array.isArray(student.videos)) {
                showAllVideos(studentIndex);
                return;
            }
            
            // Show loading indicator
            const modal = document.getElementById('videosModal');
            const title = document.getElementById('videosModalTitle');
            const content = document.getElementById('videosContent');
            
            title.textContent = '🎬 Loading Videos...';
            content.innerHTML = '<div style="text-align: center; padding: 50px;">' +
                '<div style="border: 4px solid #f3f3f3; border-top: 4px solid #0277bd; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto;"></div>' +
                '<p style="margin-top: 15px; color: #666;">Loading videos...</p>' +
                '</div>';
            modal.style.display = 'block';
            
            // Fetch videos using the correct servlet and parameter
            fetch('getStudentVideos?studentId=' + studentId)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        student.videos = data.videos || [];
                        showAllVideos(studentIndex);
                    } else {
                        content.innerHTML = '<div style="text-align: center; padding: 40px; color: #dc3545;">Error loading videos: ' + escapeHtml(data.message || 'Unknown error') + '</div>';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    content.innerHTML = '<div style="text-align: center; padding: 40px; color: #dc3545;">Error loading videos. Please try again.</div>';
                });
        }
        
        function showAllActivitiesByIndex(studentIndex) {
            // Get student data from global array
            if (!currentStudentsData || studentIndex >= currentStudentsData.length) {
                alert('Error: Student data not found');
                return;
            }
            
            const student = currentStudentsData[studentIndex];
            const activities = student.activities || [];
            const studentName = student.name || 'Unknown Student';
            
            const modal = document.getElementById('activitiesModal');
            const title = document.getElementById('activitiesModalTitle');
            const content = document.getElementById('activitiesContent');
            
            // Update title
            title.textContent = '📋 All Activities for ' + studentName;
            
            // Group activities by language
            const activityGroups = {};
            activities.forEach(activity => {
                const lang = activity.language || 'Other';
                if (!activityGroups[lang]) {
                    activityGroups[lang] = [];
                }
                activityGroups[lang].push(activity);
            });
            
            // Build HTML
            let html = '';
            html += '<div style="background: #e3f2fd; padding: 12px; border-radius: 8px; margin-bottom: 15px; border-left: 4px solid #2196f3;">';
            html += '<strong style="font-size: 16px;">Total Activities: ' + activities.length + '</strong>';
            html += '</div>';
            
            // Display by language
            const languageColors = {
                'Marathi': { bg: '#fff3e0', border: '#ff9800', text: '#e65100' },
                'Math': { bg: '#f3e5f5', border: '#9c27b0', text: '#6a1b9a' },
                'English': { bg: '#e8f5e9', border: '#4caf50', text: '#2e7d32' }
            };
            
            for (const [language, langActivities] of Object.entries(activityGroups)) {
                const colors = languageColors[language] || { bg: '#f5f5f5', border: '#757575', text: '#424242' };
                
                html += '<div style="margin-bottom: 20px;">';
                html += '<h3 style="color: ' + colors.text + '; margin-bottom: 10px; padding-bottom: 8px; border-bottom: 2px solid ' + colors.border + ';">';
                html += '📚 ' + language + ' (' + langActivities.length + ' activities)</h3>';
                
                // Group by week
                const weekGroups = {};
                langActivities.forEach(activity => {
                    const week = activity.weekNumber || 0;
                    if (!weekGroups[week]) {
                        weekGroups[week] = [];
                    }
                    weekGroups[week].push(activity);
                });
                
                // Display each week
                const sortedWeeks = Object.keys(weekGroups).sort((a, b) => parseInt(b) - parseInt(a));
                sortedWeeks.forEach(week => {
                    const weekActivities = weekGroups[week];
                    
                    html += '<div style="margin-bottom: 15px; background: ' + colors.bg + '; padding: 12px; border-radius: 8px; border-left: 4px solid ' + colors.border + ';">';
                    html += '<div style="font-weight: 600; color: ' + colors.text + '; margin-bottom: 8px; font-size: 14px;">📅 Week ' + week + '</div>';
                    
                    // Sort by day
                    weekActivities.sort((a, b) => (b.dayNumber || 0) - (a.dayNumber || 0));
                    
                    weekActivities.forEach(activity => {
                        const completed = activity.completed ? '✓' : '○';
                        const completedStyle = activity.completed ? 'color: #4caf50; font-weight: bold;' : 'color: #999;';
                        
                        html += '<div style="background: white; padding: 10px; margin: 5px 0; border-radius: 5px; border: 1px solid #e0e0e0;">';
                        html += '<div style="display: flex; justify-content: space-between; align-items: start;">';
                        html += '<div style="flex: 1;">';
                        html += '<div style="font-size: 12px; color: #666; margin-bottom: 4px;">';
                        html += '<strong>Day ' + (activity.dayNumber || 'N/A') + '</strong>';
                        if (activity.assignedDate) {
                            html += ' • Assigned: ' + activity.assignedDate;
                        }
                        html += '</div>';
                        html += '<div style="font-size: 13px; color: #333;">' + escapeHtml(activity.activityName) + '</div>';
                        html += '<div style="font-size: 11px; color: #666; margin-top: 3px;">Activity Count: ' + (activity.activityCount || 0) + '</div>';
                        html += '</div>';
                        html += '<div style="text-align: right; margin-left: 10px;">';
                        html += '</div>';
                        html += '</div>';
                        html += '</div>';
                    });
                    
                    html += '</div>';
                });
                
                html += '</div>';
            }
            
            if (activities.length === 0) {
                html = '<div style="text-align: center; padding: 40px; color: #999;">No activities found for this student.</div>';
            }
            
            content.innerHTML = html;
            modal.style.display = 'block';
        }
        
        // Helper function to get English level text
        function getEnglishLevelText(level) {
            if (!level || level === '0') return 'Level Not Set';
            const levels = {
                '1': 'Beginning Level',
                '2': 'Letter Level',
                '3': 'Word Level',
                '4': 'Sentence Level',
                '5': 'Reading Comprehension',
                '6': 'FLN 100% Complete'
            };
            return levels[level] || 'Level Not Set';
        }
        
        function filterStudents() {
            const searchInput = document.getElementById('studentSearchInput');
            const filter = searchInput.value.toUpperCase();
            const table = document.querySelector('#studentDetailsContent table');
            const tbody = table.getElementsByTagName('tbody')[0];
            const tr = tbody.getElementsByTagName('tr');
            
            // Show/hide clear button
            const clearBtn = document.getElementById('clearSearchBtn');
            clearBtn.style.display = filter ? 'block' : 'none';
            
            let visibleCount = 0;
            
            // Loop through all table rows and hide those that don't match the search query
            for (let i = 0; i < tr.length; i++) {
                const tdName = tr[i].getElementsByTagName('td')[1]; // Student Name
                const tdPEN = tr[i].getElementsByTagName('td')[2];  // PEN Number
                const tdClass = tr[i].getElementsByTagName('td')[3]; // Class
                
                if (tdName || tdPEN || tdClass) {
                    const nameValue = tdName.textContent || tdName.innerText;
                    const penValue = tdPEN.textContent || tdPEN.innerText;
                    const classValue = tdClass.textContent || tdClass.innerText;
                    
                    if (nameValue.toUpperCase().indexOf(filter) > -1 || 
                        penValue.toUpperCase().indexOf(filter) > -1 || 
                        classValue.toUpperCase().indexOf(filter) > -1) {
                        tr[i].style.display = '';
                        visibleCount++;
                    } else {
                        tr[i].style.display = 'none';
                    }
                }
            }
            
            // Update search results info
            updateSearchResultsInfo(visibleCount, tr.length);
        }
        
        // Update search results info
        function updateSearchResultsInfo(visibleCount, totalCount) {
            const infoDiv = document.getElementById('searchResultsInfo');
            if (visibleCount === totalCount) {
                infoDiv.innerHTML = '<span style="color: #666;">Showing all ' + totalCount + ' students</span>';
            } else {
                infoDiv.innerHTML = '<span style="color: #2196f3; font-weight: 600;">Found ' + visibleCount + ' of ' + totalCount + ' students</span>';
            }
        }
        
        // Clear search input and reset filter
        function clearStudentSearch() {
            const searchInput = document.getElementById('studentSearchInput');
            searchInput.value = '';
            filterStudents();
        }
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            const studentModal = document.getElementById('studentDetailsModal');
            const teacherModal = document.getElementById('teacherDetailsModal');
            const schoolModal = document.getElementById('schoolDetailsModal');
            
            if (event.target == studentModal) {
                closeStudentModal();
            }
            if (event.target == teacherModal) {
                closeTeacherModal();
            }
            if (event.target == schoolModal) {
                closeSchoolModal();
            }
        }
        
        function showAllVideos(studentIndex) {
            // Get student data from global array
            if (!currentStudentsData || studentIndex >= currentStudentsData.length) {
                alert('Error: Student data not found');
                return;
            }
            
            const student = currentStudentsData[studentIndex];
            const videos = student.videos || [];
            const studentName = student.name || 'Unknown Student';
            
            const modal = document.getElementById('videosModal');
            const title = document.getElementById('videosModalTitle');
            const content = document.getElementById('videosContent');
            
            // Update title
            title.textContent = '🎬 All Videos for ' + studentName;
            
            // Build HTML
            let html = '';
            html += '<div style="background: #e1f5fe; padding: 12px; border-radius: 8px; margin-bottom: 15px; border-left: 4px solid #0277bd;">';
            html += '<strong style="font-size: 16px;">Total Videos: ' + videos.length + '</strong>';
            html += '</div>';
            
            if (videos.length === 0) {
                html = '<div style="text-align: center; padding: 40px; color: #999;">No videos found for this student.</div>';
            } else {
                // Group videos by category
                const categoryGroups = {};
                videos.forEach(video => {
                    const cat = video.category || 'Other';
                    if (!categoryGroups[cat]) {
                        categoryGroups[cat] = [];
                    }
                    categoryGroups[cat].push(video);
                });
                
                // Display by category
                const categoryColors = {
                    'Marathi': { bg: '#fff3e0', border: '#ff9800', text: '#e65100' },
                    'Math': { bg: '#f3e5f5', border: '#9c27b0', text: '#6a1b9a' },
                    'English': { bg: '#e8f5e9', border: '#4caf50', text: '#2e7d32' }
                };
                
                for (const [category, catVideos] of Object.entries(categoryGroups)) {
                    const colors = categoryColors[category] || { bg: '#f5f5f5', border: '#757575', text: '#424242' };
                    
                    html += '<div style="margin-bottom: 20px;">';
                    html += '<h3 style="color: ' + colors.text + '; margin-bottom: 10px; padding-bottom: 8px; border-bottom: 2px solid ' + colors.border + ';">';
                    html += '📚 ' + category + ' (' + catVideos.length + ' videos)</h3>';
                    
                    catVideos.forEach((video, videoIndex) => {
                        const videoId = video.youtubeVideoId || extractYouTubeVideoId(video.youtubeUrl || video.url);
                        const uniqueId = 'video-' + category.replace(/\s+/g, '-') + '-' + videoIndex;
                        
                        html += '<div style="background: white; padding: 15px; margin: 10px 0; border-radius: 8px; border: 2px solid ' + colors.border + '; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">';
                        
                        // Video Title and Details
                        html += '<div style="margin-bottom: 10px;">';
                        html += '<div style="font-size: 15px; font-weight: 600; color: #333; margin-bottom: 5px;">' + escapeHtml(video.title) + '</div>';
                        
                        if (video.subCategory) {
                            html += '<div style="font-size: 12px; color: #666; margin-bottom: 5px;">Sub-category: ' + escapeHtml(video.subCategory) + '</div>';
                        }
                        
                        if (video.uploadDate) {
                            html += '<div style="font-size: 11px; color: #999;">📅 Uploaded: ' + video.uploadDate + '</div>';
                        }
                        html += '</div>';
                        
                        // Embedded YouTube Player
                        if (videoId) {
                            html += '<div id="' + uniqueId + '-container" style="margin-bottom: 10px;">';
                            html += '<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; border-radius: 8px; background: #000;">';
                            html += '<iframe id="' + uniqueId + '" ';
                            html += 'src="https://www.youtube.com/embed/' + escapeHtml(videoId) + '?rel=0&modestbranding=1" ';
                            html += 'style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;" ';
                            html += 'frameborder="0" ';
                            html += 'allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" ';
                            html += 'allowfullscreen>';
                            html += '</iframe>';
                            html += '</div>';
                            html += '</div>';
                        } else {
                            html += '<div style="background: #ffebee; color: #c62828; padding: 10px; border-radius: 5px; font-size: 12px; margin-bottom: 10px;">⚠️ Video ID not available for playback</div>';
                        }
                        
                        // Action Buttons
                        html += '<div style="display: flex; gap: 10px;">';
                        if (video.youtubeUrl || video.url) {
                            html += '<a href="' + escapeHtml(video.youtubeUrl || video.url) + '" target="_blank" style="display: inline-block; background: #0277bd; color: white; padding: 6px 12px; border-radius: 5px; text-decoration: none; font-size: 12px;">🔗 Open in YouTube</a>';
                        }
                        html += '</div>';
                        
                        html += '</div>';
                    });
                    
                    html += '</div>';
                }
            }
            
            content.innerHTML = html;
            modal.style.display = 'block';
        }
    </script>
</body>
</html>
