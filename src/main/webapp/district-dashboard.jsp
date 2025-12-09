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
            flex-direction: column;
            gap: 15px;
        }
        
        .header h1 {
            font-size: 24px;
            color: #000;
            margin-bottom: 5px;
        }
        
        .header-info {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 10px;
            background: rgba(102, 126, 234, 0.1);
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        
        .user-info {
            font-size: 13px;
            color: #333;
            padding: 5px;
        }
        
        .user-info strong {
            color: #667eea;
            font-weight: 600;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            text-decoration: none;
            font-size: 13px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            transition: all 0.3s;
            color: white;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0,0,0,0.3);
        }
        
        .btn-logout {
            background: #f44336;
            color: white;
        }
        
        .btn-logout:hover {
            background: #d32f2f;
        }
        
        .btn-change-password {
            background: #667eea;
            color: white;
        }
        
        .btn-change-password:hover {
            background: #5568d3;
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
            <div style="display: flex; gap: 10px; flex-wrap: wrap; align-items: center; margin-top: 15px; justify-content: center;">
                <a href="<%= request.getContextPath() %>/palak-melava.jsp" class="btn btn-change-password" style="background: #9C27B0;">👪 Palak Melava</a>
                <a href="<%= request.getContextPath() %>/phase-status.jsp" class="btn btn-change-password" style="background: #4CAF50;">📋 Phase Status</a>
                <a href="<%= request.getContextPath() %>/school-contacts.jsp" class="btn btn-change-password" style="background: #FF5722;">📞 School Contacts</a>
                <a href="<%= request.getContextPath() %>/district-activity-analysis.jsp" class="btn btn-change-password" style="background: #FF9800;">📈 Analytics</a>
                <a href="<%= request.getContextPath() %>/district-dashboard-enhanced.jsp" class="btn btn-change-password" style="background: #2196F3;">📊 Analytics Dashboard</a>
                <a href="<%= request.getContextPath() %>/change-password" class="btn btn-change-password" style="background: #607D8B;">🔐 Change Password</a>
                <a href="<%= request.getContextPath() %>/logout" class="btn btn-logout" style="background: #f44336;">🚪 Logout</a>
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
        function showDistrictStudents() {
            const modal = document.getElementById('studentDetailsModal');
            const modalSchoolInfo = document.getElementById('modalSchoolInfo');
            const content = document.getElementById('studentDetailsContent');
            
            // Show modal
            modal.style.display = 'block';
            
            // Update header
            modalSchoolInfo.innerHTML = '<h3 style="margin: 0 0 5px 0; color: #333;">📊 All Students in <%= districtName %> District</h3>' +
                '<p style="margin: 0; color: #666;">Complete student list</p>';
            
            // Show loading
            content.innerHTML = '<div style="text-align: center; padding: 50px;">' +
                '<div style="border: 4px solid #f3f3f3; border-top: 4px solid #667eea; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto;"></div>' +
                '<p style="margin-top: 15px; color: #666;">Loading all students...</p>' +
                '</div>';
            
            // Fetch all students from district
            fetch('GetDistrictStudentsServlet?district=<%= java.net.URLEncoder.encode(districtName, "UTF-8") %>')
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.students && data.students.length > 0) {
                        displayStudents(data.students);
                    } else {
                        content.innerHTML = '<div class="no-data">No students found in this district.</div>';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    content.innerHTML = '<div class="no-data" style="color: #dc3545;">Error loading student details. Please try again.</div>';
                });
        }
        
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
            // Store students data globally for modal access
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
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Marathi Level</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Math Level</th>';
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
                
                // Marathi Level - Single Badge
                html += '<td style="padding: 10px; border: 1px solid #ddd;">';
                const marathiLevelText = getMarathiLevelText(student.marathiLevel);
                const marathiStyle = (student.marathiLevel && student.marathiLevel !== '0') 
                    ? 'background: #2196F3; color: white;' 
                    : 'background: #e0e0e0; color: #666;';
                html += '<span style="display: inline-block; padding: 5px 10px; border-radius: 5px; font-size: 11px; font-weight: 600; ' + marathiStyle + '">' 
                    + escapeHtml(marathiLevelText) + '</span>';
                html += '</td>';
                
                // Math Level - Single Badge
                html += '<td style="padding: 10px; border: 1px solid #ddd;">';
                const mathLevelText = getMathLevelText(student.mathLevel);
                const mathStyle = (student.mathLevel && student.mathLevel !== '0') 
                    ? 'background: #9C27B0; color: white;' 
                    : 'background: #e0e0e0; color: #666;';
                html += '<span style="display: inline-block; padding: 5px 10px; border-radius: 5px; font-size: 11px; font-weight: 600; ' + mathStyle + '">' 
                    + escapeHtml(mathLevelText) + '</span>';
                html += '</td>';
                
                // English Level - Single Badge
                html += '<td style="padding: 10px; border: 1px solid #ddd;">';
                const englishLevelText = getEnglishLevelText(student.englishLevel);
                const englishStyle = (student.englishLevel && student.englishLevel !== '0') 
                    ? 'background: #4CAF50; color: white;' 
                    : 'background: #e0e0e0; color: #666;';
                html += '<span style="display: inline-block; padding: 5px 10px; border-radius: 5px; font-size: 11px; font-weight: 600; ' + englishStyle + '">' 
                    + escapeHtml(englishLevelText) + '</span>';
                html += '</td>';
                
                // Activities - Clickable
                html += '<td style="padding: 10px; border: 1px solid #ddd;">';
                if (student.activities && student.activities.length > 0) {
                    html += '<button onclick="viewAllActivities(' + student.studentId + ', \'' + escapeHtml(student.studentName) + '\')" style="background: #ff9800; color: white; border: none; padding: 8px 15px; border-radius: 5px; cursor: pointer; font-size: 12px; font-weight: 600; box-shadow: 0 2px 5px rgba(0,0,0,0.2);">';
                    html += '<span style="margin-right: 5px;">📚</span>' + student.activities.length + ' Activities';
                    html += '</button>';
                } else {
                    html += '<span style="color: #999;">No Activities</span>';
                }
                html += '</td>';
                
                // Videos - Clickable
                html += '<td style="padding: 10px; border: 1px solid #ddd;">';
                if (student.videos && student.videos.length > 0) {
                    html += '<button onclick="viewAllVideos(' + student.studentId + ', \'' + escapeHtml(student.studentName) + '\')" style="background: #2196F3; color: white; border: none; padding: 8px 15px; border-radius: 5px; cursor: pointer; font-size: 12px; font-weight: 600; box-shadow: 0 2px 5px rgba(0,0,0,0.2);">';
                    html += '<span style="margin-right: 5px;">🎥</span>' + student.videos.length + ' Videos';
                    html += '</button>';
                } else {
                    html += '<span style="color: #999;">No Videos</span>';
                }
                html += '</td>';
                
                // Phases - Clickable
                html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">';
                html += '<button onclick="viewPhaseDetails(' + student.studentId + ', \'' + escapeHtml(student.studentName) + '\')" style="background: #4CAF50; color: white; border: none; padding: 8px 15px; border-radius: 5px; cursor: pointer; font-size: 12px; font-weight: 600; box-shadow: 0 2px 5px rgba(0,0,0,0.2);">';
                html += '<span style="margin-right: 5px;">📋</span>View Phases';
                html += '</button>';
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
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('studentDetailsModal');
            if (event.target == modal) {
                closeStudentModal();
            }
            const activitiesModal = document.getElementById('activitiesModal');
            if (event.target == activitiesModal) {
                closeActivitiesModal();
            }
            const videosModal = document.getElementById('videosModal');
            if (event.target == videosModal) {
                closeVideosModal();
            }
            const phasesModal = document.getElementById('phasesModal');
            if (event.target == phasesModal) {
                closePhasesModal();
            }
        }
        
        // View All Activities
        function viewAllActivities(studentId, studentName) {
            const student = currentStudentsData.find(s => s.studentId == studentId);
            if (!student || !student.activities || student.activities.length === 0) {
                alert('No activities found for this student.');
                return;
            }
            
            document.getElementById('activitiesStudentName').textContent = studentName;
            const tableBody = document.getElementById('activitiesTableBody');
            tableBody.innerHTML = '';
            
            student.activities.forEach((activity, index) => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td style="padding: 10px; border: 1px solid #ddd; text-align: center;">${index + 1}</td>
                    <td style="padding: 10px; border: 1px solid #ddd;">${escapeHtml(activity.activityName || activity.activity_name || activity)}</td>
                    <td style="padding: 10px; border: 1px solid #ddd; text-align: center;">${escapeHtml(activity.activityDate || activity.activity_date || 'N/A')}</td>
                    <td style="padding: 10px; border: 1px solid #ddd;">${escapeHtml(activity.subject || 'N/A')}</td>
                    <td style="padding: 10px; border: 1px solid #ddd; text-align: center;">${escapeHtml(activity.status || 'Completed')}</td>
                `;
                tableBody.appendChild(row);
            });
            
            document.getElementById('activitiesModal').style.display = 'block';
        }
        
        function closeActivitiesModal() {
            document.getElementById('activitiesModal').style.display = 'none';
        }
        
        // View All Videos
        function viewAllVideos(studentId, studentName) {
            const student = currentStudentsData.find(s => s.studentId == studentId);
            if (!student || !student.videos || student.videos.length === 0) {
                alert('No videos found for this student.');
                return;
            }
            
            document.getElementById('videosStudentName').textContent = studentName;
            const tableBody = document.getElementById('videosTableBody');
            tableBody.innerHTML = '';
            
            student.videos.forEach((video, index) => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td style="padding: 10px; border: 1px solid #ddd; text-align: center;">${index + 1}</td>
                    <td style="padding: 10px; border: 1px solid #ddd;">${escapeHtml(video.title || video.videoTitle || 'Video ' + (index + 1))}</td>
                    <td style="padding: 10px; border: 1px solid #ddd; text-align: center;">${escapeHtml(video.uploadDate || video.date || 'N/A')}</td>
                    <td style="padding: 10px; border: 1px solid #ddd; text-align: center;">
                        ${video.url || video.videoUrl ? `<a href="${escapeHtml(video.url || video.videoUrl)}" target="_blank" style="background: #2196F3; color: white; padding: 5px 10px; border-radius: 3px; text-decoration: none; font-size: 11px;">▶ Watch</a>` : 'N/A'}
                    </td>
                `;
                tableBody.appendChild(row);
            });
            
            document.getElementById('videosModal').style.display = 'block';
        }
        
        function closeVideosModal() {
            document.getElementById('videosModal').style.display = 'none';
        }
        
        // View Phase Details
        function viewPhaseDetails(studentId, studentName) {
            const student = currentStudentsData.find(s => s.studentId == studentId);
            if (!student) {
                alert('Student data not found.');
                return;
            }
            
            document.getElementById('phasesStudentName').textContent = studentName;
            const tableBody = document.getElementById('phasesTableBody');
            tableBody.innerHTML = '';
            
            const phases = [
                { num: 1, date: student.phase1Date, status: student.phase1Status, level: student.phase1Level },
                { num: 2, date: student.phase2Date, status: student.phase2Status, level: student.phase2Level },
                { num: 3, date: student.phase3Date, status: student.phase3Status, level: student.phase3Level },
                { num: 4, date: student.phase4Date, status: student.phase4Status, level: student.phase4Level }
            ];
            
            phases.forEach(phase => {
                const isCompleted = phase.date ? true : false;
                const statusBadge = isCompleted 
                    ? '<span style="background: #4CAF50; color: white; padding: 5px 10px; border-radius: 5px; font-size: 11px; font-weight: 600;">✓ Completed</span>'
                    : '<span style="background: #f44336; color: white; padding: 5px 10px; border-radius: 5px; font-size: 11px; font-weight: 600;">✗ Pending</span>';
                
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td style="padding: 10px; border: 1px solid #ddd; text-align: center; font-weight: 600;">Phase ${phase.num}</td>
                    <td style="padding: 10px; border: 1px solid #ddd; text-align: center;">${statusBadge}</td>
                    <td style="padding: 10px; border: 1px solid #ddd; text-align: center;">${escapeHtml(phase.date || 'Not Completed')}</td>
                    <td style="padding: 10px; border: 1px solid #ddd; text-align: center;">${escapeHtml(phase.level || 'N/A')}</td>
                    <td style="padding: 10px; border: 1px solid #ddd;">${escapeHtml(phase.status || 'No remarks')}</td>
                `;
                tableBody.appendChild(row);
            });
            
            document.getElementById('phasesModal').style.display = 'block';
        }
        
        function closePhasesModal() {
            document.getElementById('phasesModal').style.display = 'none';
        }
        
        // Store current students data globally for modal access
        let currentStudentsData = [];
    </script>
    
    <!-- Activities Modal -->
    <div id="activitiesModal" style="display: none; position: fixed; z-index: 10000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.5);">
        <div style="background-color: #fefefe; margin: 5% auto; padding: 0; border: 1px solid #888; border-radius: 10px; width: 80%; max-width: 900px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
            <div style="background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <h2 style="margin: 0; font-size: 24px;">📚 All Activities - <span id="activitiesStudentName"></span></h2>
                <button onclick="closeActivitiesModal()" style="background: transparent; border: none; color: white; font-size: 30px; cursor: pointer; padding: 0; line-height: 1;">&times;</button>
            </div>
            <div style="padding: 20px; max-height: 500px; overflow-y: auto;">
                <table style="width: 100%; border-collapse: collapse; background: white;">
                    <thead>
                        <tr style="background: #fff3e0;">
                            <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Sr No</th>
                            <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Activity Name</th>
                            <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Date</th>
                            <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Subject</th>
                            <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Status</th>
                        </tr>
                    </thead>
                    <tbody id="activitiesTableBody"></tbody>
                </table>
            </div>
        </div>
    </div>
    
    <!-- Videos Modal -->
    <div id="videosModal" style="display: none; position: fixed; z-index: 10000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.5);">
        <div style="background-color: #fefefe; margin: 5% auto; padding: 0; border: 1px solid #888; border-radius: 10px; width: 80%; max-width: 900px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
            <div style="background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <h2 style="margin: 0; font-size: 24px;">🎥 All Videos - <span id="videosStudentName"></span></h2>
                <button onclick="closeVideosModal()" style="background: transparent; border: none; color: white; font-size: 30px; cursor: pointer; padding: 0; line-height: 1;">&times;</button>
            </div>
            <div style="padding: 20px; max-height: 500px; overflow-y: auto;">
                <table style="width: 100%; border-collapse: collapse; background: white;">
                    <thead>
                        <tr style="background: #e3f2fd;">
                            <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Sr No</th>
                            <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Video Title</th>
                            <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Upload Date</th>
                            <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Action</th>
                        </tr>
                    </thead>
                    <tbody id="videosTableBody"></tbody>
                </table>
            </div>
        </div>
    </div>
    
    <!-- Phases Modal -->
    <div id="phasesModal" style="display: none; position: fixed; z-index: 10000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.5);">
        <div style="background-color: #fefefe; margin: 5% auto; padding: 0; border: 1px solid #888; border-radius: 10px; width: 80%; max-width: 900px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
            <div style="background: linear-gradient(135deg, #4CAF50 0%, #388E3C 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <h2 style="margin: 0; font-size: 24px;">📋 Phase Details - <span id="phasesStudentName"></span></h2>
                <button onclick="closePhasesModal()" style="background: transparent; border: none; color: white; font-size: 30px; cursor: pointer; padding: 0; line-height: 1;">&times;</button>
            </div>
            <div style="padding: 20px;">
                <table style="width: 100%; border-collapse: collapse; background: white;">
                    <thead>
                        <tr style="background: #e8f5e9;">
                            <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Phase</th>
                            <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Status</th>
                            <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Completion Date</th>
                            <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Level</th>
                            <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Remarks</th>
                        </tr>
                    </thead>
                    <tbody id="phasesTableBody"></tbody>
                </table>
            </div>
        </div>
    </div>
</body>
</html>
