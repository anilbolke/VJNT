<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.UserDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    UserDAO userDAO = new UserDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    
    // Get statistics for this district
    String districtName = user.getDistrictName();
    List<com.vjnt.model.Student> students = studentDAO.getStudentsByDistrict(districtName);
    List<User> districtUsers = userDAO.getUsersByDistrict(districtName);
    
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
            background: #f0f2f5;
            color: #000;
            padding: 20px 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-radius: 8px;
        }
        
        .header-content {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            font-size: 24px;
            color: #000;
        }
        
        .header-info {
            text-align: right;
        }
        
        .user-info {
            font-size: 14px;
            margin-bottom: 5px;
            color: #000;
        }
        
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
            display: inline-block;
            transition: all 0.3s;
        }
        
        .btn-logout {
            background: rgba(255,255,255,0.2);
            color: white;
            margin-left: 10px;
        }
        
        .btn-logout:hover {
            background: rgba(255,255,255,0.3);
        }
        
        .btn-change-password {
            background: rgba(255,255,255,0.2);
            color: white;
        }
        
        .btn-change-password:hover {
            background: rgba(255,255,255,0.3);
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
            <div>
                <h1>🏛️ VJNT Class Management System</h1>
                <p>District Dashboard - <%= districtName %></p>
            </div>
            <div class="header-info">
                <div class="user-info">
                    Welcome, <strong><%= user.getFullName() %></strong>
                </div>
                <div class="user-info">
                    Role: <strong><%= user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) ? "District Coordinator" : "District 2nd Coordinator" %></strong>
                </div>
                <a href="<%= request.getContextPath() %>/district-dashboard-enhanced.jsp" class="btn btn-change-password">📊 Analytics Dashboard</a>
                <a href="<%= request.getContextPath() %>/change-password" class="btn btn-change-password">Change Password</a>
                <a href="<%= request.getContextPath() %>/logout" class="btn btn-logout">Logout</a>
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
        
        <!-- School-wise Statistics -->
        <div class="section">
            <h2 class="section-title">🏫 School-wise Student Count</h2>
            
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
            
            <div style="margin-bottom: 15px; color: #666; font-size: 14px;">
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
                
                <div id="studentDetailsContent" style="min-height: 200px;">
                    <div style="text-align: center; padding: 50px;">
                        <div style="border: 4px solid #f3f3f3; border-top: 4px solid #667eea; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto;"></div>
                        <p style="margin-top: 15px; color: #666;">Loading student details...</p>
                    </div>
                </div>
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
        
        function displayStudents(students) {
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
                if (student.marathiAksharaLevel && student.marathiAksharaLevel !== 'स्तर निश्चित केला नाही') marathiLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #e3f2fd; color: #1976d2; border-radius: 3px;"><strong>अक्षर:</strong> ' + escapeHtml(student.marathiAksharaLevel) + '</div>');
                if (student.marathiShabdaLevel && student.marathiShabdaLevel !== 'स्तर निश्चित केला नाही') marathiLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #e3f2fd; color: #1976d2; border-radius: 3px;"><strong>शब्द:</strong> ' + escapeHtml(student.marathiShabdaLevel) + '</div>');
                if (student.marathiVakyaLevel && student.marathiVakyaLevel !== 'स्तर निश्चित केला नाही') marathiLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #e3f2fd; color: #1976d2; border-radius: 3px;"><strong>वाक्य:</strong> ' + escapeHtml(student.marathiVakyaLevel) + '</div>');
                if (student.marathiSamajpurvakLevel && student.marathiSamajpurvakLevel !== 'स्तर निश्चित केला नाही') marathiLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #e3f2fd; color: #1976d2; border-radius: 3px;"><strong>समजपूर्वक:</strong> ' + escapeHtml(student.marathiSamajpurvakLevel) + '</div>');
                html += marathiLevels.length > 0 ? marathiLevels.join('') : '<span style="color: #999;">-</span>';
                html += '</td>';
                
                // Math Levels
                html += '<td style="padding: 10px; border: 1px solid #ddd; font-size: 11px;">';
                let mathLevels = [];
                if (student.mathAksharaLevel && student.mathAksharaLevel !== 'स्तर निश्चित केला नाही') mathLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #f3e5f5; color: #7b1fa2; border-radius: 3px;"><strong>अक्षर:</strong> ' + escapeHtml(student.mathAksharaLevel) + '</div>');
                if (student.mathShabdaLevel && student.mathShabdaLevel !== 'स्तर निश्चित केला नाही') mathLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #f3e5f5; color: #7b1fa2; border-radius: 3px;"><strong>शब्द:</strong> ' + escapeHtml(student.mathShabdaLevel) + '</div>');
                if (student.mathVakyaLevel && student.mathVakyaLevel !== 'स्तर निश्चित केला नाही') mathLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #f3e5f5; color: #7b1fa2; border-radius: 3px;"><strong>वाक्य:</strong> ' + escapeHtml(student.mathVakyaLevel) + '</div>');
                if (student.mathSamajpurvakLevel && student.mathSamajpurvakLevel !== 'स्तर निश्चित केला नाही') mathLevels.push('<div style="margin: 3px 0; padding: 4px 6px; background: #f3e5f5; color: #7b1fa2; border-radius: 3px;"><strong>समजपूर्वक:</strong> ' + escapeHtml(student.mathSamajpurvakLevel) + '</div>');
                html += mathLevels.length > 0 ? mathLevels.join('') : '<span style="color: #999;">-</span>';
                html += '</td>';
                
                // English Level
                html += '<td style="padding: 10px; border: 1px solid #ddd; font-size: 11px;">';
                if (student.englishAksharaLevel && student.englishAksharaLevel !== 'स्तर निश्चित केला नाही') {
                    html += '<div style="padding: 4px 6px; background: #e8f5e9; color: #2e7d32; border-radius: 3px;">' + escapeHtml(student.englishAksharaLevel) + '</div>';
                } else {
                    html += '<span style="color: #999;">-</span>';
                }
                html += '</td>';
                
                // Activities
                html += '<td style="padding: 10px; border: 1px solid #ddd;">';
                if (student.activities && student.activities.length > 0) {
                    student.activities.slice(0, 3).forEach(activity => {
                        html += '<span style="display: inline-block; background: #fff3e0; color: #e65100; padding: 3px 6px; border-radius: 3px; margin: 2px; font-size: 10px;">' + escapeHtml(activity.activityName || activity) + '</span>';
                    });
                    if (student.activities.length > 3) {
                        html += '<span style="color: #666; font-size: 10px;">+' + (student.activities.length - 3) + ' more</span>';
                    }
                } else {
                    html += '<span style="color: #999;">None</span>';
                }
                html += '</td>';
                
                // Videos
                html += '<td style="padding: 10px; border: 1px solid #ddd;">';
                if (student.videos && student.videos.length > 0) {
                    html += '<span style="display: inline-block; background: #e1f5fe; color: #0277bd; padding: 3px 8px; border-radius: 3px; font-size: 11px; font-weight: 600;">' + student.videos.length + ' videos</span>';
                    if (student.videos[0] && student.videos[0].url) {
                        html += '<br><a href="' + escapeHtml(student.videos[0].url) + '" target="_blank" style="font-size: 10px; color: #0277bd; text-decoration: none;">View →</a>';
                    }
                } else {
                    html += '<span style="color: #999;">None</span>';
                }
                html += '</td>';
                
                // Phases
                html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">';
                html += '<div style="display: flex; flex-wrap: wrap; gap: 3px; justify-content: center;">';
                html += '<span style="display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 10px; ' + (student.phase1Date ? 'background: #c8e6c9; color: #2e7d32;' : 'background: #ffcdd2; color: #c62828;') + '">P1' + (student.phase1Date ? '✓' : '✗') + '</span>';
                html += '<span style="display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 10px; ' + (student.phase2Date ? 'background: #c8e6c9; color: #2e7d32;' : 'background: #ffcdd2; color: #c62828;') + '">P2' + (student.phase2Date ? '✓' : '✗') + '</span>';
                html += '<span style="display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 10px; ' + (student.phase3Date ? 'background: #c8e6c9; color: #2e7d32;' : 'background: #ffcdd2; color: #c62828;') + '">P3' + (student.phase3Date ? '✓' : '✗') + '</span>';
                html += '<span style="display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 10px; ' + (student.phase4Date ? 'background: #c8e6c9; color: #2e7d32;' : 'background: #ffcdd2; color: #c62828;') + '">P4' + (student.phase4Date ? '✓' : '✗') + '</span>';
                html += '</div>';
                html += '</td>';
                
                html += '</tr>';
            });
            
            html += '</tbody>';
            html += '</table>';
            html += '</div>';
            
            content.innerHTML = html;
        }
        
        function closeStudentModal() {
            document.getElementById('studentDetailsModal').style.display = 'none';
        }
        
        function escapeHtml(text) {
            if (!text) return '';
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('studentDetailsModal');
            if (event.target == modal) {
                closeStudentModal();
            }
        }
    </script>
</body>
</html>
