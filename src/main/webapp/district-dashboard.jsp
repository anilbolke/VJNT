<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.UserDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.dao.SchoolContactDAO" %>
<%@ page import="com.vjnt.dao.VideoDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="com.vjnt.model.SchoolContact" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR) &&
                         !user.getUserType().equals(User.UserType.DIVISION))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    UserDAO userDAO = new UserDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    SchoolContactDAO contactDAO = new SchoolContactDAO();
    VideoDAO videoDAO = new VideoDAO();
    
    // Get statistics for this district
    String districtName = user.getDistrictName();
    List<com.vjnt.model.Student> students = studentDAO.getStudentsByDistrict(districtName);
    List<User> districtUsers = userDAO.getUsersByDistrict(districtName);
    int videoCount = videoDAO.getVideoCountByDistrict(districtName);
    
    // Get school contacts for this district
    List<SchoolContact> schoolContacts = contactDAO.getContactsByDistrict(districtName);
    
    // Create maps for quick lookup of contacts by UDISE
    Map<String, SchoolContact> coordinatorMap = new HashMap<>();
    Map<String, SchoolContact> headMasterMap = new HashMap<>();
    
    for (SchoolContact contact : schoolContacts) {
        if ("School Coordinator".equals(contact.getContactType())) {
            coordinatorMap.put(contact.getUdiseNo(), contact);
        } else if ("Head Master".equals(contact.getContactType())) {
            headMasterMap.put(contact.getUdiseNo(), contact);
        }
    }
    
    // Create maps for User objects to get actual passwords
    Map<String, User> coordinatorUserMap = new HashMap<>();
    Map<String, User> headMasterUserMap = new HashMap<>();
    
    for (User districtUser : districtUsers) {
        if (districtUser.getUdiseNo() != null) {
            if (districtUser.getUserType() == User.UserType.SCHOOL_COORDINATOR) {
                coordinatorUserMap.put(districtUser.getUdiseNo(), districtUser);
            } else if (districtUser.getUserType() == User.UserType.HEAD_MASTER) {
                headMasterUserMap.put(districtUser.getUdiseNo(), districtUser);
            }
        }
    }
    
    // Pagination parameters for school list
    int schoolCurrentPage = 1;
    int schoolPageSize = 10;
    String schoolPageParam = request.getParameter("schoolPage");
    if (schoolPageParam != null) {
        try {
            schoolCurrentPage = Integer.parseInt(schoolPageParam);
        } catch (NumberFormatException e) {
            schoolCurrentPage = 1;
        }
    }
    
    // Calculate statistics
    Map<String, Integer> udiseCount = new HashMap<>();
    Map<String, String> udiseToSchoolName = new HashMap<>();
    Map<String, Integer> classCount = new HashMap<>();
    int maleCount = 0, femaleCount = 0;
    
    for (com.vjnt.model.Student student : students) {
        String udise = student.getUdiseNo();
        String studentClass = student.getStudentClass();
        
        if (udise != null) {
            udiseCount.put(udise, udiseCount.getOrDefault(udise, 0) + 1);
            
            // Fetch school name if not already cached
            if (!udiseToSchoolName.containsKey(udise)) {
                School school = schoolDAO.getSchoolByUdise(udise);
                if (school != null && school.getSchoolName() != null) {
                    udiseToSchoolName.put(udise, school.getSchoolName());
                } else {
                    udiseToSchoolName.put(udise, udise); // Fallback to UDISE
                }
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
    
    // Calculate subject level action taken counts per school
    Map<String, Map<String, Integer>> schoolSubjectLevelCounts = new HashMap<>();
    
    for (com.vjnt.model.Student student : students) {
        String udise = student.getUdiseNo();
        if (udise == null || udise.trim().isEmpty()) continue;
        
        // Initialize map for this school if not exists
        if (!schoolSubjectLevelCounts.containsKey(udise)) {
            Map<String, Integer> subjectCounts = new HashMap<>();
            subjectCounts.put("marathi", 0);
            subjectCounts.put("math", 0);
            subjectCounts.put("english", 0);
            schoolSubjectLevelCounts.put(udise, subjectCounts);
        }
        
        Map<String, Integer> subjectCounts = schoolSubjectLevelCounts.get(udise);
        
        // Count Marathi level action taken (any level set)
        Integer marathiAkshara = student.getMarathiAksharaLevel();
        Integer marathiShabda = student.getMarathiShabdaLevel();
        Integer marathiVakya = student.getMarathiVakyaLevel();
        Integer marathiSamajpurvak = student.getMarathiSamajpurvakLevel();
        
        if ((marathiAkshara != null && marathiAkshara > 0) ||
            (marathiShabda != null && marathiShabda > 0) ||
            (marathiVakya != null && marathiVakya > 0) ||
            (marathiSamajpurvak != null && marathiSamajpurvak > 0)) {
            subjectCounts.put("marathi", subjectCounts.get("marathi") + 1);
        }
        
        // Count Math level action taken (any level set)
        Integer mathAkshara = student.getMathAksharaLevel();
        Integer mathShabda = student.getMathShabdaLevel();
        Integer mathVakya = student.getMathVakyaLevel();
        Integer mathSamajpurvak = student.getMathSamajpurvakLevel();
        
        if ((mathAkshara != null && mathAkshara > 0) ||
            (mathShabda != null && mathShabda > 0) ||
            (mathVakya != null && mathVakya > 0) ||
            (mathSamajpurvak != null && mathSamajpurvak > 0)) {
            subjectCounts.put("math", subjectCounts.get("math") + 1);
        }
        
        // Count English level action taken (any level set)
        Integer englishAkshara = student.getEnglishAksharaLevel();
        if (englishAkshara != null && englishAkshara > 0) {
            subjectCounts.put("english", subjectCounts.get("english") + 1);
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>District Dashboard - <%= districtName %></title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
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
            display: none;
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
        
        /* Pagination Styles */
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
                <!-- District Icon and Name Section - START -->
                <div class="school-icon">🏢</div>
                <h1><%= districtName %> District</h1>
                <!-- District Icon and Name Section - END -->
                <p class="header-subtitle">📍 District Dashboard</p>
            </div>
            <div class="header-right">
                <div class="user-info-box">
                    <div class="user-info">
                        <span>👤</span>
                        <span>Welcome, <strong><%= user.getFullName() != null && !user.getFullName().isEmpty() ? user.getFullName() : user.getUsername() %></strong></span>
                    </div>
                    <div class="user-info">
                        <span>🎭</span>
                        <span><strong><%= user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) ? "District Coordinator" : "District 2nd Coordinator" %></strong></span>
                    </div>
                </div>
                <div class="header-actions">
                    <%-- <a href="<%= request.getContextPath() %>/palak-melava-status.jsp" class="btn btn-analytics" style="background: #ff9800;" title="View Palak Melava (Parent Meeting) Status">
                        <span>👨‍👩‍👧‍👦</span>
                        <span>Palak Melava</span>
                    </a>
                    <a href="<%= request.getContextPath() %>/phase-status.jsp" class="btn btn-analytics" style="background: #667eea;" title="View Phase Completion Status by School">
                        <span>📊</span>
                        <span>Phase Status</span>
                    </a>
                   
                    <a href="<%= request.getContextPath() %>/district-dashboard-enhanced.jsp" class="btn btn-analytics" title="View detailed analytics and reports">
                        <span>📊</span>
                        <span>Analytics</span>
                    </a>
                     <a href="<%= request.getContextPath() %>/district-activity-analysis.jsp" class="btn btn-logout" style="background: #FF9800;">
                     📈 Activity Analysis</a> --%>
                      <a href="<%= request.getContextPath() %>/school-contacts.jsp" class="btn btn-analytics" style="background: #9c27b0;" title="View and manage school contacts directory">
                        <span>👥</span>
                        <span>School Contacts</span>
                    </a>
                    <button onclick="toggleSubjectLevelSection()" class="btn btn-analytics" style="background: #9C27B0; cursor: pointer; border: none;" title="View School-wise Student Count & Subject Level Actions">
                        <span>📊</span>
                        <span>Subject Level Actions</span>
                    </button>
                    
                    <a href="<%= request.getContextPath() %>/district-teacher-report.jsp" class="btn btn-analytics" style="background: #4CAF50;" title="View school-wise teacher report">
                        <span>👨‍🏫</span>
                        <span>Teacher Report</span>
                    </a>
                    
                    <a href="<%= request.getContextPath() %>/district-teacher-assignments.jsp" class="btn btn-analytics" style="background: #9C27B0;" title="View complete teacher assignment details with UDISE, school name, class, section, and subjects">
                        <span>👥</span>
                        <span>Teacher Assignments</span>
                    </a>
                    
                    <a href="<%= request.getContextPath() %>/district-credentials" class="btn btn-analytics" style="background: #FF6B6B;" title="View login credentials and manage school coordinator passwords">
                        <span>🔑</span>
                        <span>Login Credentials</span>
                    </a>
                    
                    <a href="<%= request.getContextPath() %>/district-profile" class="btn btn-analytics" style="background: #2196F3;" title="View profile and reset password">
                        <span>👤</span>
                        <span>My Profile</span>
                    </a>
                    
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
            <span>Division:</span> <strong><%= user.getDivisionName() %></strong> 
            <span style="margin: 0 10px;">→</span> 
            <span>District:</span> <strong><%= districtName %></strong>
        </div>
        
        <!-- Statistics Cards -->
        <div class="dashboard-grid">
            <div class="stat-card">
                <div class="stat-icon">👥</div>
                <div class="stat-value"><%= students.size() %></div>
                <div class="stat-label">Total Students</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">🏫</div>
                <div class="stat-value"><%= udiseCount.size() %></div>
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
            
            <div class="stat-card">
                <div class="stat-icon">🎬</div>
                <div class="stat-value"><%= videoCount %></div>
                <div class="stat-label">Total Videos</div>
            </div>
        </div>
        
        <!-- Class-wise Distribution -->
        <div class="section" >
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
        
        <!-- School-wise Student Count & Subject Level Action Section -->
        <div class="section" id="subjectLevelSection" style="display: none;">
            <h2 class="section-title">🏫 School-wise Student Count & Subject Level Actions</h2>
            
            <!-- Filter Section -->
            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #9C27B0;">
                <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 15px;">
                    <span style="font-size: 18px;">🔍</span>
                    <h3 style="margin: 0; color: #333; font-size: 16px;">Search & Filter Schools</h3>
                </div>
                
                <div style="position: relative; margin-bottom: 10px;">
                    <input type="text" 
                           id="subjectLevelSearchInput" 
                           placeholder="🔍 Search by School Name or UDISE Number..."
                           onkeyup="filterSubjectLevelTable()"
                           style="width: 100%; padding: 12px 40px 12px 15px; border: 2px solid #9C27B0; border-radius: 8px; font-size: 14px; outline: none; transition: all 0.3s;">
                    <button onclick="clearSubjectLevelSearch()" 
                            id="clearSubjectLevelBtn"
                            style="display: none; position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: #dc3545; color: white; border: none; border-radius: 50%; width: 28px; height: 28px; cursor: pointer; font-size: 14px; line-height: 1;">✕</button>
                </div>
                <div id="subjectLevelSearchInfo" style="font-size: 13px; color: #666;"></div>
            </div>
            
            <div style="margin-bottom: 15px; color: #666; font-size: 14px;">
                Showing all <%= udiseCount.size() %> schools with total students and subject-wise level action taken counts
            </div>
            
            <div style="overflow-x: auto;">
                <table class="table" style="width: 100%; border-collapse: collapse; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                    <thead>
                        <tr style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
                            <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Sr. No.</th>
                            <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">School Name</th>
                            <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">UDISE No.</th>
                            <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Total Students</th>
                            <th style="padding: 12px; text-align: center; border: 1px solid #ddd;" colspan="3">Subject Level Action Taken</th>
                        </tr>
                        <tr style="background: #f0f0f0; color: #333; font-weight: 600;">
                            <th colspan="4" style="padding: 8px; border: 1px solid #ddd;"></th>
                            <th style="padding: 8px; text-align: center; border: 1px solid #ddd; background: #fff3e0;">📚 Marathi</th>
                            <th style="padding: 8px; text-align: center; border: 1px solid #ddd; background: #e3f2fd;">🔢 Math</th>
                            <th style="padding: 8px; text-align: center; border: 1px solid #ddd; background: #e8f5e9;">🔤 English</th>
                        </tr>
                    </thead>
                    <tbody id="subjectLevelTableBody">
                        <% 
                        // Sort schools by name
                        List<Map.Entry<String, Integer>> sortedSchools = new ArrayList<>(udiseCount.entrySet());
                        sortedSchools.sort((a, b) -> {
                            String nameA = udiseToSchoolName.getOrDefault(a.getKey(), a.getKey());
                            String nameB = udiseToSchoolName.getOrDefault(b.getKey(), b.getKey());
                            return nameA.compareTo(nameB);
                        });
                        
                        int srNo = 0;
                        for (Map.Entry<String, Integer> entry : sortedSchools) {
                            srNo++;
                            String udise = entry.getKey();
                            int studentCount = entry.getValue();
                            String schoolName = udiseToSchoolName.getOrDefault(udise, "Unknown School");
                            
                            // Get subject level counts for this school
                            Map<String, Integer> subjectCounts = schoolSubjectLevelCounts.getOrDefault(udise, new HashMap<>());
                            int marathiCount = subjectCounts.getOrDefault("marathi", 0);
                            int mathCount = subjectCounts.getOrDefault("math", 0);
                            int englishCount = subjectCounts.getOrDefault("english", 0);
                        %>
                        <tr class="subject-level-row" style="<%= srNo % 2 == 0 ? "background: #f8f9fa;" : "background: white;" %>">
                            <td style="padding: 10px; border: 1px solid #ddd; text-align: center;"><strong><%= srNo %></strong></td>
                            <td style="padding: 10px; border: 1px solid #ddd;" class="school-name-cell">
                                <strong style="color: #667eea;"><%= schoolName %></strong>
                            </td>
                            <td style="padding: 10px; border: 1px solid #ddd;" class="udise-cell">
                                <code style="background: #e9ecef; padding: 2px 6px; border-radius: 3px; font-size: 12px;"><%= udise %></code>
                            </td>
                            <td style="padding: 10px; border: 1px solid #ddd; text-align: center;">
                                <span style="background: #667eea; color: white; padding: 5px 12px; border-radius: 15px; font-weight: 600; font-size: 14px;">
                                    <%= studentCount %>
                                </span>
                            </td>
                            <td style="padding: 10px; border: 1px solid #ddd; text-align: center; background: #fffaf0;">
                                <span style="<%= marathiCount > 0 ? "background: #ff9800; color: white;" : "background: #f5f5f5; color: #999;" %> padding: 5px 12px; border-radius: 15px; font-weight: 600; font-size: 14px;">
                                    <%= marathiCount %>
                                </span>
                            </td>
                            <td style="padding: 10px; border: 1px solid #ddd; text-align: center; background: #f0f8ff;">
                                <span style="<%= mathCount > 0 ? "background: #2196F3; color: white;" : "background: #f5f5f5; color: #999;" %> padding: 5px 12px; border-radius: 15px; font-weight: 600; font-size: 14px;">
                                    <%= mathCount %>
                                </span>
                            </td>
                            <td style="padding: 10px; border: 1px solid #ddd; text-align: center; background: #f0fff0;">
                                <span style="<%= englishCount > 0 ? "background: #4CAF50; color: white;" : "background: #f5f5f5; color: #999;" %> padding: 5px 12px; border-radius: 15px; font-weight: 600; font-size: 14px;">
                                    <%= englishCount %>
                                </span>
                            </td>
                        </tr>
                        <% } %>
                        
                        <!-- Summary Row -->
                        <tr style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; font-weight: 700;">
                            <td colspan="3" style="padding: 12px; border: 1px solid #ddd; text-align: right;">
                                <strong>📊 TOTAL:</strong>
                            </td>
                            <td style="padding: 12px; border: 1px solid #ddd; text-align: center;">
                                <strong style="font-size: 16px;"><%= students.size() %></strong>
                            </td>
                            <td style="padding: 12px; border: 1px solid #ddd; text-align: center;">
                                <strong style="font-size: 16px;">
                                    <%= schoolSubjectLevelCounts.values().stream().mapToInt(m -> m.getOrDefault("marathi", 0)).sum() %>
                                </strong>
                            </td>
                            <td style="padding: 12px; border: 1px solid #ddd; text-align: center;">
                                <strong style="font-size: 16px;">
                                    <%= schoolSubjectLevelCounts.values().stream().mapToInt(m -> m.getOrDefault("math", 0)).sum() %>
                                </strong>
                            </td>
                            <td style="padding: 12px; border: 1px solid #ddd; text-align: center;">
                                <strong style="font-size: 16px;">
                                    <%= schoolSubjectLevelCounts.values().stream().mapToInt(m -> m.getOrDefault("english", 0)).sum() %>
                                </strong>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
        
        <!-- School-wise Statistics (Hidden Section) -->
        <div class="section" style="display: none;">
            <h2 class="section-title">🏫 School-wise Student Count</h2>
            
            <!-- Filter Section -->
           <!--  <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #667eea;">
                <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 15px;">
                    <span style="font-size: 18px;">🔍</span>
                    <h3 style="margin: 0; color: #333; font-size: 16px;">Filter Schools</h3>
                </div>
                
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px;">
                    School Name Search
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            🏫 Search School Name/UDISE
                        </label>
                        <input type="text" 
                               id="schoolSearchFilter" 
                               placeholder="Enter school name or UDISE..."
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               oninput="applySchoolFilters()">
                    </div>
                    
                    Minimum Student Count
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            📊 Min Student Count
                        </label>
                        <input type="number" 
                               id="minStudentFilter" 
                               placeholder="e.g., 10"
                               min="0"
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               oninput="applySchoolFilters()">
                    </div>
                    
                    Maximum Student Count
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            📊 Max Student Count
                        </label>
                        <input type="number" 
                               id="maxStudentFilter" 
                               placeholder="e.g., 100"
                               min="0"
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               oninput="applySchoolFilters()">
                    </div>
                    
                    Sort By
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            🔄 Sort By
                        </label>
                        <select id="sortByFilter" 
                                style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none; cursor: pointer;"
                                onchange="applySchoolFilters()">
                            <option value="name_asc">School Name (A-Z)</option>
                            <option value="name_desc">School Name (Z-A)</option>
                            <option value="student_desc">Student Count (High to Low)</option>
                            <option value="student_asc">Student Count (Low to High)</option>
                            <option value="udise_asc">UDISE (A-Z)</option>
                        </select>
                    </div>
                </div>
                
                Filter Actions
                <div style="margin-top: 15px; display: flex; gap: 10px; flex-wrap: wrap;">
                    <button onclick="applySchoolFilters()" 
                            style="background: #667eea; color: white; padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500;">
                        ✓ Apply Filters
                    </button>
                    <button onclick="clearSchoolFilters()" 
                            style="background: #dc3545; color: white; padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500;">
                        ✕ Clear All
                    </button>
                    <span id="filterResultsInfo" style="align-self: center; color: #666; font-size: 13px; margin-left: 10px;"></span>
                </div>
            </div> -->
            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #667eea;">
                <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 15px;">
                    <span style="font-size: 18px;">🔍</span>
                    <h3 style="margin: 0; color: #333; font-size: 16px;">Filter Schools</h3>
                </div>
                
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px;">
                    <!-- School Name Search -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            🏫 Search School Name/UDISE
                        </label>
                        <input type="text" 
                               id="schoolSearchFilter" 
                               placeholder="Enter school name or UDISE..."
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               oninput="applySchoolFilters()">
                    </div>
                    
                    <!-- Minimum Student Count -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            📊 Min Student Count
                        </label>
                        <input type="number" 
                               id="minStudentFilter" 
                               placeholder="e.g., 10"
                               min="0"
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               oninput="applySchoolFilters()">
                    </div>
                    
                    <!-- Maximum Student Count -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            📊 Max Student Count
                        </label>
                        <input type="number" 
                               id="maxStudentFilter" 
                               placeholder="e.g., 100"
                               min="0"
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               oninput="applySchoolFilters()">
                    </div>
                    
                    <!-- Sort By -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            🔄 Sort By
                        </label>
                        <select id="sortByFilter" 
                                style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none; cursor: pointer;"
                                onchange="applySchoolFilters()">
                            <option value="name_asc">School Name (A-Z)</option>
                            <option value="name_desc">School Name (Z-A)</option>
                            <option value="student_desc">Student Count (High to Low)</option>
                            <option value="student_asc">Student Count (Low to High)</option>
                            <option value="udise_asc">UDISE (A-Z)</option>
                        </select>
                    </div>
                </div>
                
                <!-- Filter Actions -->
                <div style="margin-top: 15px; display: flex; gap: 10px; flex-wrap: wrap;">
                    <button onclick="applySchoolFilters()" 
                            style="background: #667eea; color: white; padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500;">
                        ✓ Apply Filters
                    </button>
                    <button onclick="clearSchoolFilters()" 
                            style="background: #dc3545; color: white; padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500;">
                        ✕ Clear All
                    </button>
                    <span id="filterResultsInfo" style="align-self: center; color: #666; font-size: 13px; margin-left: 10px;"></span>
                </div>
            </div>
            
            <% 
            // Sort and paginate school list
            List<Map.Entry<String, Integer>> sortedUdise = new ArrayList<>(udiseCount.entrySet());
            sortedUdise.sort((a, b) -> a.getKey().compareTo(b.getKey()));
            
            int totalSchools = sortedUdise.size();
            int schoolTotalPages = (int) Math.ceil((double) totalSchools / schoolPageSize);
            int schoolStartIndex = (schoolCurrentPage - 1) * schoolPageSize;
            int schoolEndIndex = Math.min(schoolStartIndex + schoolPageSize, totalSchools);
            
            List<Map.Entry<String, Integer>> paginatedSchools = sortedUdise.subList(schoolStartIndex, schoolEndIndex);
            %>
            
            <div id="schoolCountInfo" style="margin-bottom: 15px; color: #666; font-size: 14px;">
                Showing <%= schoolStartIndex + 1 %> - <%= schoolEndIndex %> of <%= totalSchools %> schools
            </div>
            
            <table class="table">
                <thead>
                    <tr>
                        <th>UDISE No</th>
                        <th>School Name</th>
                        <th>Student Count</th>
                        <th>Male</th>
                        <th>Female</th>
                        <th>School Coordinator</th>
                        <th>Head Master</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                    for (Map.Entry<String, Integer> entry : paginatedSchools) {
                        String udise = entry.getKey();
                        int totalCount = entry.getValue();
                        String schoolName = udiseToSchoolName.get(udise);
                        
                        // Count gender for this UDISE
                        int udiseMale = 0, udiseFemale = 0;
                        for (com.vjnt.model.Student s : students) {
                            if (udise.equals(s.getUdiseNo())) {
                                String g = s.getGender();
                                if ("Male".equalsIgnoreCase(g) || "पुरुष".equals(g)) {
                                    udiseMale++;
                                } else if ("Female".equalsIgnoreCase(g) || "स्त्री".equals(g)) {
                                    udiseFemale++;
                                }
                            }
                        }
                    %>
                    <tr>
                        <td><strong><%= udise %></strong></td>
                        <td><strong style="color: #667eea;"><%= schoolName %></strong></td>
                        <td>
                            <span class="badge badge-primary" style="cursor: pointer;" 
                                  onclick="showStudentDetails('<%= udise %>', '<%= schoolName %>')">
                                <%= totalCount %> students
                            </span>
                        </td>
                        <td><%= udiseMale %></td>
                        <td><%= udiseFemale %></td>
                        <td>
                            <% 
                            SchoolContact coordinator = coordinatorMap.get(udise);
                            User coordinatorUser = coordinatorUserMap.get(udise);
                            String srUsername = coordinatorUser != null ? coordinatorUser.getUsername() : "sr_" + udise.toLowerCase().replaceAll("\\s+", "_");
                            String srPassword = coordinatorUser != null && coordinatorUser.getPassword() != null ? coordinatorUser.getPassword() : "Pass@123";
                            
                            if (coordinator != null) {
                            %>
                                <div style="font-size: 13px;">
                                    <div style="font-weight: 600; color: #333; margin-bottom: 3px;">
                                        <%= coordinator.getFullName() %>
                                    </div>
                                    <div style="color: #666; font-size: 12px;">
                                        📱 <a href="tel:<%= coordinator.getMobile() %>" style="color: #2196f3; text-decoration: none;">
                                            <%= coordinator.getMobile() %>
                                        </a>
                                    </div>
                                    <% if (coordinator.getWhatsappNumber() != null && !coordinator.getWhatsappNumber().isEmpty()) { %>
                                    <div style="color: #25D366; font-size: 12px;">
                                        💬 <a href="https://wa.me/91<%= coordinator.getWhatsappNumber() %>" target="_blank" style="color: #25D366; text-decoration: none;">
                                            <%= coordinator.getWhatsappNumber() %>
                                        </a>
                                    </div>
                                    <% } %>
                                    <div style="margin-top: 8px; padding-top: 8px; border-top: 1px solid #e0e0e0;">
                                        <div style="color: #666; font-size: 11px; margin-bottom: 2px;">
                                            🔐 <strong>Login:</strong> <%= srUsername %>
                                        </div>
                                        <div style="color: #666; font-size: 11px;">
                                            🔑 <strong>Password:</strong> 
                                            <span style="font-weight: bold; color: #28a745;"><%= srPassword %></span>
                                            <button onclick="copyCredential('<%= srUsername %>', '<%= srPassword %>')" 
                                                    style="background: #667eea; color: white; border: none; padding: 2px 8px; border-radius: 4px; font-size: 10px; margin-left: 5px; cursor: pointer;">
                                                📋 Copy
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            <% } else { %>
                                <div style="font-size: 13px;">
                                    <span style="color: #999; font-size: 12px;">Contact not assigned</span>
                                    <div style="margin-top: 8px; padding-top: 8px; border-top: 1px solid #e0e0e0;">
                                        <div style="color: #666; font-size: 11px; margin-bottom: 2px;">
                                            🔐 <strong>Login:</strong> <%= srUsername %>
                                        </div>
                                        <div style="color: #666; font-size: 11px;">
                                            🔑 <strong>Password:</strong> 
                                            <span style="font-weight: bold; color: #28a745;"><%= srPassword %></span>
                                            <button onclick="copyCredential('<%= srUsername %>', '<%= srPassword %>')" 
                                                    style="background: #667eea; color: white; border: none; padding: 2px 8px; border-radius: 4px; font-size: 10px; margin-left: 5px; cursor: pointer;">
                                                📋 Copy
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            <% } %>
                        </td>
                        <td>
                            <% 
                            SchoolContact headMaster = headMasterMap.get(udise);
                            User headMasterUser = headMasterUserMap.get(udise);
                            String hmUsername = headMasterUser != null ? headMasterUser.getUsername() : "hm_" + udise.toLowerCase().replaceAll("\\s+", "_");
                            String hmPassword = headMasterUser != null && headMasterUser.getPassword() != null ? headMasterUser.getPassword() : "Pass@123";
                            
                            if (headMaster != null) {
                            %>
                                <div style="font-size: 13px;">
                                    <div style="font-weight: 600; color: #333; margin-bottom: 3px;">
                                        <%= headMaster.getFullName() %>
                                    </div>
                                    <div style="color: #666; font-size: 12px;">
                                        📱 <a href="tel:<%= headMaster.getMobile() %>" style="color: #2196f3; text-decoration: none;">
                                            <%= headMaster.getMobile() %>
                                        </a>
                                    </div>
                                    <% if (headMaster.getWhatsappNumber() != null && !headMaster.getWhatsappNumber().isEmpty()) { %>
                                    <div style="color: #25D366; font-size: 12px;">
                                        💬 <a href="https://wa.me/91<%= headMaster.getWhatsappNumber() %>" target="_blank" style="color: #25D366; text-decoration: none;">
                                            <%= headMaster.getWhatsappNumber() %>
                                        </a>
                                    </div>
                                    <% } %>
                                    <div style="margin-top: 8px; padding-top: 8px; border-top: 1px solid #e0e0e0;">
                                        <div style="color: #666; font-size: 11px; margin-bottom: 2px;">
                                            🔐 <strong>Login:</strong> <%= hmUsername %>
                                        </div>
                                        <div style="color: #666; font-size: 11px;">
                                            🔑 <strong>Password:</strong> 
                                            <span style="font-weight: bold; color: #28a745;"><%= hmPassword %></span>
                                            <button onclick="copyCredential('<%= hmUsername %>', '<%= hmPassword %>')" 
                                                    style="background: #17a2b8; color: white; border: none; padding: 2px 8px; border-radius: 4px; font-size: 10px; margin-left: 5px; cursor: pointer;">
                                                📋 Copy
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            <% } else { %>
                                <div style="font-size: 13px;">
                                    <span style="color: #999; font-size: 12px;">Contact not assigned</span>
                                    <div style="margin-top: 8px; padding-top: 8px; border-top: 1px solid #e0e0e0;">
                                        <div style="color: #666; font-size: 11px; margin-bottom: 2px;">
                                            🔐 <strong>Login:</strong> <%= hmUsername %>
                                        </div>
                                        <div style="color: #666; font-size: 11px;">
                                            🔑 <strong>Password:</strong> 
                                            <span style="font-weight: bold; color: #28a745;"><%= hmPassword %></span>
                                            <button onclick="copyCredential('<%= hmUsername %>', '<%= hmPassword %>')" 
                                                    style="background: #17a2b8; color: white; border: none; padding: 2px 8px; border-radius: 4px; font-size: 10px; margin-left: 5px; cursor: pointer;">
                                                📋 Copy
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            <% } %>
                        </td>
                        <td><span class="badge badge-success">Active</span></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
            
            <!-- Pagination Controls -->
            <% if (schoolTotalPages > 1) { %>
            <div class="pagination">
                <% if (schoolCurrentPage > 1) { %>
                    <a href="?schoolPage=<%= schoolCurrentPage - 1 %>" class="page-btn">« Previous</a>
                <% } %>
                
                <% 
                int startPage = Math.max(1, schoolCurrentPage - 2);
                int endPage = Math.min(schoolTotalPages, schoolCurrentPage + 2);
                
                for (int i = startPage; i <= endPage; i++) { 
                %>
                    <a href="?schoolPage=<%= i %>" class="page-btn <%= i == schoolCurrentPage ? "active" : "" %>"><%= i %></a>
                <% } %>
                
                <% if (schoolCurrentPage < schoolTotalPages) { %>
                    <a href="?schoolPage=<%= schoolCurrentPage + 1 %>" class="page-btn">Next »</a>
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
                <div id="modalSchoolInfo" style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #667eea;">
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
    
    <style>
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        /* Table Styles */
        #studentDetailsContent table {
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        #studentDetailsContent tbody tr:hover {
            background: #f0f4ff !important;
            transition: background 0.2s ease;
            margin: 2px;
        }
        
        .level-marathi {
            background: #e3f2fd;
            color: #1976d2;
        }
        
        .level-math {
            background: #f3e5f5;
            color: #7b1fa2;
        }
        
        .level-english {
            background: #e8f5e9;
            color: #388e3c;
        }
        
        .activity-list {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-top: 8px;
        }
        
        .activity-badge {
            background: #fff3cd;
            color: #856404;
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 12px;
            border: 1px solid #ffc107;
        }
        
        .video-item {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 8px;
            border-left: 3px solid #667eea;
        }
        
        .video-title {
            font-weight: 600;
            color: #333;
            margin-bottom: 3px;
        }
        
        .video-url {
            color: #667eea;
            font-size: 12px;
            text-decoration: none;
        }
        
        .video-url:hover {
            text-decoration: underline;
        }
        
        .no-data {
            text-align: center;
            padding: 20px;
            color: #999;
            font-style: italic;
        }
    </style>
    
    <script>
        function showStudentDetails(udise, schoolName) {
            const modal = document.getElementById('studentDetailsModal');
            const modalSchoolInfo = document.getElementById('modalSchoolInfo');
            const content = document.getElementById('studentDetailsContent');
            
            // Show modal
            modal.style.display = 'block';
            
            // Update school info
            modalSchoolInfo.innerHTML = '<h3 style="margin: 0 0 5px 0; color: #333;">🏫 ' + escapeHtml(schoolName) + '</h3>' +
                '<p style="margin: 0; color: #666;">UDISE: ' + escapeHtml(udise) + '</p>';
            
            // Show loading
            content.innerHTML = '<div style="text-align: center; padding: 50px;">' +
                '<div style="border: 4px solid #f3f3f3; border-top: 4px solid #667eea; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto;"></div>' +
                '<p style="margin-top: 15px; color: #666;">Loading student details...</p>' +
                '</div>';
            
            // Fetch student details
            fetch('GetSchoolStudentsServlet?udise=' + encodeURIComponent(udise))
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.students && data.students.length > 0) {
                        displayStudents(data.students);
                    } else {
                        content.innerHTML = '<div class="no-data">No students found for this school.</div>';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    content.innerHTML = '<div class="no-data" style="color: #dc3545;">Error loading student details. Please try again.</div>';
                });
        }
        
        // Global variable to store students data
        let currentStudentsData = [];
        
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
                
                // Activities
                html += '<td style="padding: 10px; border: 1px solid #ddd;">';
                if (student.activities && student.activities.length > 0) {
                    html += '<div style="margin-bottom: 5px;">';
                    student.activities.slice(0, 2).forEach(activity => {
                        html += '<div style="background: #fff3e0; color: #e65100; padding: 4px 6px; border-radius: 3px; margin: 2px 0; font-size: 10px; border-left: 3px solid #ff9800;">';
                        html += '<strong>Week ' + activity.weekNumber + ', Day ' + activity.dayNumber + '</strong> - ' + activity.language;
                        html += '<br><span style="font-size: 9px;">' + escapeHtml(activity.activityName) + '</span>';
                        html += '</div>';
                    });
                    html += '</div>';
                    html += '<button onclick="showAllActivitiesByIndex(' + index + ')" style="background: #2196f3; color: white; border: none; padding: 4px 8px; border-radius: 3px; cursor: pointer; font-size: 10px; width: 100%;">📋 View All (' + student.activities.length + ')</button>';
                } else {
                    html += '<span style="color: #999;">None</span>';
                }
                html += '</td>';
                
                // Videos
                html += '<td style="padding: 10px; border: 1px solid #ddd;">';
                if (student.videos && student.videos.length > 0) {
                    html += '<div style="margin-bottom: 5px;">';
                    student.videos.slice(0, 2).forEach(video => {
                        html += '<div style="background: #e1f5fe; color: #0277bd; padding: 4px 6px; border-radius: 3px; margin: 2px 0; font-size: 10px; border-left: 3px solid #0277bd;">';
                        html += '<strong>📹 ' + escapeHtml(video.title || 'Video') + '</strong>';
                        if (video.uploadDate) {
                            html += '<br><span style="font-size: 9px;">Uploaded: ' + video.uploadDate + '</span>';
                        }
                        html += '</div>';
                    });
                    html += '</div>';
                    html += '<button onclick="showAllVideos(' + index + ')" style="background: #0277bd; color: white; border: none; padding: 4px 8px; border-radius: 3px; cursor: pointer; font-size: 10px; width: 100%;">🎬 View All (' + student.videos.length + ')</button>';
                } else {
                    html += '<span style="color: #999;">None</span>';
                }
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
            updateSearchResultsInfo(students.length, students.length);
        }
        
        function closeStudentModal() {
            document.getElementById('studentDetailsModal').style.display = 'none';
            // Clear search when closing modal
            clearStudentSearch();
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
        
        function clearStudentSearch() {
            const searchInput = document.getElementById('studentSearchInput');
            searchInput.value = '';
            filterStudents();
        }
        
        function updateSearchResultsInfo(visibleCount, totalCount) {
            const infoDiv = document.getElementById('searchResultsInfo');
            if (visibleCount === totalCount) {
                infoDiv.innerHTML = '<span style="color: #666;">Showing all <strong>' + totalCount + '</strong> students</span>';
            } else {
                infoDiv.innerHTML = '<span style="color: #667eea;">Showing <strong>' + visibleCount + '</strong> of <strong>' + totalCount + '</strong> students</span>';
            }
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
                    
                    catVideos.forEach(video => {
                        html += '<div style="background: white; padding: 15px; margin: 10px 0; border-radius: 8px; border: 2px solid ' + colors.border + '; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">';
                        html += '<div style="display: flex; gap: 15px; align-items: start;">';
                        
                        // Thumbnail
                        if (video.thumbnailUrl) {
                            html += '<div style="flex-shrink: 0;">';
                            html += '<img src="' + escapeHtml(video.thumbnailUrl) + '" style="width: 120px; height: 90px; object-fit: cover; border-radius: 5px; border: 2px solid #e0e0e0;">';
                            html += '</div>';
                        }
                        
                        // Video details
                        html += '<div style="flex: 1;">';
                        html += '<div style="font-size: 15px; font-weight: 600; color: #333; margin-bottom: 5px;">' + escapeHtml(video.title) + '</div>';
                        
                        if (video.subCategory) {
                            html += '<div style="font-size: 12px; color: #666; margin-bottom: 8px;">Sub-category: ' + escapeHtml(video.subCategory) + '</div>';
                        }
                        
                        if (video.uploadDate) {
                            html += '<div style="font-size: 11px; color: #999; margin-bottom: 8px;">📅 Uploaded: ' + video.uploadDate + '</div>';
                        }
                        
                        if (video.url) {
                            html += '<a href="' + escapeHtml(video.url) + '" target="_blank" style="display: inline-block; background: #0277bd; color: white; padding: 6px 12px; border-radius: 5px; text-decoration: none; font-size: 12px; margin-top: 5px;">▶️ Watch on YouTube</a>';
                        }
                        
                        html += '</div>';
                        html += '</div>';
                        html += '</div>';
                    });
                    
                    html += '</div>';
                }
            }
            
            content.innerHTML = html;
            modal.style.display = 'block';
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
        
        function escapeHtml(text) {
            if (!text) return '';
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        // School Filtering Functions
        function applySchoolFilters() {
            const searchText = document.getElementById('schoolSearchFilter').value.toLowerCase();
            const minCount = parseInt(document.getElementById('minStudentFilter').value) || 0;
            const maxCount = parseInt(document.getElementById('maxStudentFilter').value) || Infinity;
            const sortBy = document.getElementById('sortByFilter').value;
            
            const table = document.querySelector('.section table tbody');
            if (!table) return;
            
            const rows = Array.from(table.querySelectorAll('tr'));
            let visibleCount = 0;
            
            // Filter and sort rows
            rows.forEach(row => {
                const udise = row.cells[0].textContent.toLowerCase();
                const schoolName = row.cells[1].textContent.toLowerCase();
                const studentCount = parseInt(row.cells[2].textContent.match(/\d+/)[0]);
                
                // Apply filters
                const matchesSearch = searchText === '' || 
                                    udise.includes(searchText) || 
                                    schoolName.includes(searchText);
                const matchesMin = studentCount >= minCount;
                const matchesMax = studentCount <= maxCount;
                
                if (matchesSearch && matchesMin && matchesMax) {
                    row.style.display = '';
                    visibleCount++;
                } else {
                    row.style.display = 'none';
                }
            });
            
            // Sort visible rows
            const visibleRows = rows.filter(row => row.style.display !== 'none');
            sortSchoolRows(visibleRows, sortBy);
            
            // Re-append sorted rows
            visibleRows.forEach(row => table.appendChild(row));
            
            // Update filter info
            const filterInfo = document.getElementById('filterResultsInfo');
            const countInfo = document.getElementById('schoolCountInfo');
            
            if (visibleCount === rows.length) {
                filterInfo.textContent = 'Showing all ' + rows.length + ' schools';
                filterInfo.style.color = '#28a745';
            } else {
                filterInfo.textContent = 'Filtered: ' + visibleCount + ' of ' + rows.length + ' schools';
                filterInfo.style.color = '#ff9800';
            }
            
            countInfo.textContent = 'Showing ' + visibleCount + ' schools';
        }
        
        function sortSchoolRows(rows, sortBy) {
            rows.sort((a, b) => {
                switch(sortBy) {
                    case 'name_asc':
                        return a.cells[1].textContent.localeCompare(b.cells[1].textContent);
                    case 'name_desc':
                        return b.cells[1].textContent.localeCompare(a.cells[1].textContent);
                    case 'student_desc':
                        const aCount = parseInt(a.cells[2].textContent.match(/\d+/)[0]);
                        const bCount = parseInt(b.cells[2].textContent.match(/\d+/)[0]);
                        return bCount - aCount;
                    case 'student_asc':
                        const aCount2 = parseInt(a.cells[2].textContent.match(/\d+/)[0]);
                        const bCount2 = parseInt(b.cells[2].textContent.match(/\d+/)[0]);
                        return aCount2 - bCount2;
                    case 'udise_asc':
                        return a.cells[0].textContent.localeCompare(b.cells[0].textContent);
                    default:
                        return 0;
                }
            });
        }
        
        function clearSchoolFilters() {
            document.getElementById('schoolSearchFilter').value = '';
            document.getElementById('minStudentFilter').value = '';
            document.getElementById('maxStudentFilter').value = '';
            document.getElementById('sortByFilter').value = 'name_asc';
            
            const table = document.querySelector('.section table tbody');
            if (table) {
                const rows = Array.from(table.querySelectorAll('tr'));
                rows.forEach(row => row.style.display = '');
                
                // Reset to default sort
                sortSchoolRows(rows, 'udise_asc');
                rows.forEach(row => table.appendChild(row));
            }
            
            document.getElementById('filterResultsInfo').textContent = '';
            
            // Reset count info
            const countInfo = document.getElementById('schoolCountInfo');
            const originalText = countInfo.getAttribute('data-original') || countInfo.textContent;
            countInfo.textContent = originalText;
        }
        
        // Store original count info on page load
        window.addEventListener('DOMContentLoaded', function() {
            const countInfo = document.getElementById('schoolCountInfo');
            if (countInfo) {
                countInfo.setAttribute('data-original', countInfo.textContent);
            }
        });
        
        // Close modal when clicking outside
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
        
        // Password visibility toggle function
        function togglePassword(elementId) {
            const element = document.getElementById(elementId);
            if (element.style.filter === 'blur(4px)' || element.style.filter === '') {
                element.style.filter = 'none';
                element.style.fontWeight = 'bold';
                element.style.color = '#28a745';
            } else {
                element.style.filter = 'blur(4px)';
                element.style.fontWeight = 'normal';
                element.style.color = '';
            }
        }
        
        // Copy credential function
        function copyCredential(username, password) {
            const text = 'Username: ' + username + '\nPassword: ' + password;
            
            // Use modern clipboard API
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).then(function() {
                    alert('✓ Login credentials copied to clipboard!\n\nUsername: ' + username + '\nPassword: ' + password);
                }).catch(function(err) {
                    // Fallback to old method
                    copyCredentialFallback(text);
                });
            } else {
                // Fallback for older browsers
                copyCredentialFallback(text);
            }
        }
        
        // Fallback copy method for older browsers
        function copyCredentialFallback(text) {
            const textarea = document.createElement('textarea');
            textarea.value = text;
            textarea.style.position = 'fixed';
            textarea.style.opacity = '0';
            document.body.appendChild(textarea);
            textarea.select();
            
            try {
                document.execCommand('copy');
                alert('✓ Login credentials copied to clipboard!');
            } catch (err) {
                alert('Unable to copy. Please copy manually:\n\n' + text);
            }
            
            document.body.removeChild(textarea);
        }
        
        // Toggle Subject Level Actions Section
        function toggleSubjectLevelSection() {
            const section = document.getElementById('subjectLevelSection');
            if (section.style.display === 'none') {
                section.style.display = 'block';
                // Scroll to the section smoothly
                section.scrollIntoView({ behavior: 'smooth', block: 'start' });
            } else {
                section.style.display = 'none';
                // Scroll back to top
                window.scrollTo({ top: 0, behavior: 'smooth' });
            }
        }
        
        // Filter Subject Level Actions Table
        function filterSubjectLevelTable() {
            const input = document.getElementById('subjectLevelSearchInput');
            const clearBtn = document.getElementById('clearSubjectLevelBtn');
            const filter = input.value.toUpperCase();
            const table = document.getElementById('subjectLevelTableBody');
            const tr = table.getElementsByClassName('subject-level-row');
            
            // Show/hide clear button
            clearBtn.style.display = filter ? 'block' : 'none';
            
            let visibleCount = 0;
            const totalCount = tr.length;
            
            for (let i = 0; i < tr.length; i++) {
                const schoolNameCell = tr[i].getElementsByClassName('school-name-cell')[0];
                const udiseCell = tr[i].getElementsByClassName('udise-cell')[0];
                
                if (schoolNameCell && udiseCell) {
                    const schoolName = schoolNameCell.textContent || schoolNameCell.innerText;
                    const udise = udiseCell.textContent || udiseCell.innerText;
                    
                    if (schoolName.toUpperCase().indexOf(filter) > -1 || 
                        udise.toUpperCase().indexOf(filter) > -1) {
                        tr[i].style.display = '';
                        visibleCount++;
                    } else {
                        tr[i].style.display = 'none';
                    }
                }
            }
            
            // Update search info
            updateSubjectLevelSearchInfo(visibleCount, totalCount);
        }
        
        function updateSubjectLevelSearchInfo(visibleCount, totalCount) {
            const infoDiv = document.getElementById('subjectLevelSearchInfo');
            if (!infoDiv) return;
            
            if (visibleCount === totalCount) {
                infoDiv.innerHTML = '<span style="color: #666;">Showing all ' + totalCount + ' schools</span>';
            } else {
                infoDiv.innerHTML = '<span style="color: #9C27B0; font-weight: 600;">Found ' + visibleCount + ' of ' + totalCount + ' schools</span>';
            }
        }
        
        function clearSubjectLevelSearch() {
            const searchInput = document.getElementById('subjectLevelSearchInput');
            searchInput.value = '';
            filterSubjectLevelTable();
        }
    </script>
</body>
</html>
