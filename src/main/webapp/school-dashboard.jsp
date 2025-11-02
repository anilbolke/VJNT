<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.UserDAO" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.HEAD_MASTER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    
    // Get statistics for this school (UDISE)
    String udiseNo = user.getUdiseNo();
    List<com.vjnt.model.Student> students = studentDAO.getStudentsByUdise(udiseNo);
    
    // Calculate statistics
    Map<String, Integer> classCount = new HashMap<>();
    Map<String, Integer> sectionCount = new HashMap<>();
    Map<String, Map<String, Integer>> classSectionCount = new HashMap<>();
    int maleCount = 0, femaleCount = 0;
    
    for (com.vjnt.model.Student student : students) {
        String studentClass = student.getStudentClass();
        String section = student.getSection();
        
        if (studentClass != null) {
            classCount.put(studentClass, classCount.getOrDefault(studentClass, 0) + 1);
            
            if (section != null) {
                String key = studentClass + "-" + section;
                classSectionCount.computeIfAbsent(studentClass, k -> new HashMap<>())
                    .put(section, classSectionCount.getOrDefault(studentClass, new HashMap<>()).getOrDefault(section, 0) + 1);
            }
        }
        
        if (section != null) {
            sectionCount.put(section, sectionCount.getOrDefault(section, 0) + 1);
        }
        
        String gender = student.getGender();
        if ("Male".equalsIgnoreCase(gender) || "पुरुष".equals(gender)) {
            maleCount++;
        } else if ("Female".equalsIgnoreCase(gender) || "स्त्री".equals(gender)) {
            femaleCount++;
        }
    }
    
    // Performance statistics
    Map<String, Integer> marathiLevelCount = new HashMap<>();
    Map<String, Integer> mathLevelCount = new HashMap<>();
    Map<String, Integer> englishLevelCount = new HashMap<>();
    
    for (com.vjnt.model.Student student : students) {
        if (student.getMarathiLevel() != null && !student.getMarathiLevel().isEmpty()) {
            marathiLevelCount.put(student.getMarathiLevel(), marathiLevelCount.getOrDefault(student.getMarathiLevel(), 0) + 1);
        }
        if (student.getMathLevel() != null && !student.getMathLevel().isEmpty()) {
            mathLevelCount.put(student.getMathLevel(), mathLevelCount.getOrDefault(student.getMathLevel(), 0) + 1);
        }
        if (student.getEnglishLevel() != null && !student.getEnglishLevel().isEmpty()) {
            englishLevelCount.put(student.getEnglishLevel(), englishLevelCount.getOrDefault(student.getEnglishLevel(), 0) + 1);
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>School Dashboard - UDISE <%= udiseNo %></title>
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
            background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
            color: white;
            padding: 20px 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
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
        }
        
        .header-info {
            text-align: right;
        }
        
        .user-info {
            font-size: 14px;
            margin-bottom: 5px;
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
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
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
            color: #43e97b;
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
            border-bottom: 2px solid #43e97b;
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
        
        .badge-info {
            background: #e1f5fe;
            color: #0288d1;
        }
        
        .chart-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
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
            color: #43e97b;
        }
        
        .chart-label {
            font-size: 14px;
            color: #666;
            margin-top: 5px;
        }
        
        .grid-2 {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        
        .performance-card {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 10px;
        }
        
        .performance-title {
            font-size: 16px;
            font-weight: 600;
            color: #333;
            margin-bottom: 10px;
        }
        
        .performance-item {
            display: flex;
            justify-content: space-between;
            padding: 5px 0;
            border-bottom: 1px solid #dee2e6;
        }
        
        .performance-item:last-child {
            border-bottom: none;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div>
                <h1>🏫 VJNT Class Management System</h1>
                <p>School Dashboard - UDISE <%= udiseNo %></p>
            </div>
            <div class="header-info">
                <div class="user-info">
                    Welcome, <strong><%= user.getFullName() %></strong>
                </div>
                <div class="user-info">
                    Role: <strong><%= user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) ? "School Coordinator" : "Head Master" %></strong>
                </div>
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
            <span>District:</span> <strong><%= user.getDistrictName() %></strong>
            <span style="margin: 0 10px;">→</span>
            <span>School UDISE:</span> <strong><%= udiseNo %></strong>
        </div>
        
        <!-- Statistics Cards -->
        <div class="dashboard-grid">
            <div class="stat-card">
                <div class="stat-icon">👥</div>
                <div class="stat-value"><%= students.size() %></div>
                <div class="stat-label">Total Students</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">📚</div>
                <div class="stat-value"><%= classCount.size() %></div>
                <div class="stat-label">Classes</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">📋</div>
                <div class="stat-value"><%= sectionCount.size() %></div>
                <div class="stat-label">Sections</div>
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
        
        <!-- Class and Section Distribution -->
        <div class="grid-2">
            <div class="section">
                <h2 class="section-title">📚 Class-wise Distribution</h2>
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
            
            <div class="section">
                <h2 class="section-title">📋 Section-wise Distribution</h2>
                <div class="chart-container">
                    <% 
                    List<Map.Entry<String, Integer>> sortedSections = new ArrayList<>(sectionCount.entrySet());
                    sortedSections.sort((a, b) -> a.getKey().compareTo(b.getKey()));
                    
                    for (Map.Entry<String, Integer> entry : sortedSections) { 
                    %>
                    <div class="chart-item">
                        <div class="chart-value"><%= entry.getValue() %></div>
                        <div class="chart-label">Section <%= entry.getKey() %></div>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>
        
        <!-- Performance Levels -->
        <% if (!marathiLevelCount.isEmpty() || !mathLevelCount.isEmpty() || !englishLevelCount.isEmpty()) { %>
        <div class="section">
            <h2 class="section-title">📊 Performance Levels (स्तर)</h2>
            <div class="grid-2">
                <div>
                    <% if (!marathiLevelCount.isEmpty()) { %>
                    <div class="performance-card">
                        <div class="performance-title">🇮🇳 मराठी भाषा स्तर</div>
                        <% for (Map.Entry<String, Integer> entry : marathiLevelCount.entrySet()) { %>
                        <div class="performance-item">
                            <span><%= entry.getKey() %></span>
                            <span class="badge badge-primary"><%= entry.getValue() %> students</span>
                        </div>
                        <% } %>
                    </div>
                    <% } %>
                    
                    <% if (!englishLevelCount.isEmpty()) { %>
                    <div class="performance-card">
                        <div class="performance-title">🇬🇧 इंग्रजी स्तर</div>
                        <% for (Map.Entry<String, Integer> entry : englishLevelCount.entrySet()) { %>
                        <div class="performance-item">
                            <span><%= entry.getKey() %></span>
                            <span class="badge badge-info"><%= entry.getValue() %> students</span>
                        </div>
                        <% } %>
                    </div>
                    <% } %>
                </div>
                
                <div>
                    <% if (!mathLevelCount.isEmpty()) { %>
                    <div class="performance-card">
                        <div class="performance-title">🔢 गणित स्तर</div>
                        <% for (Map.Entry<String, Integer> entry : mathLevelCount.entrySet()) { %>
                        <div class="performance-item">
                            <span><%= entry.getKey() %></span>
                            <span class="badge badge-success"><%= entry.getValue() %> students</span>
                        </div>
                        <% } %>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>
        <% } %>
        
        <!-- Class-Section Matrix -->
        <div class="section">
            <h2 class="section-title">📊 Class-Section Matrix</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>Class</th>
                        <% 
                        Set<String> allSections = new TreeSet<>();
                        for (com.vjnt.model.Student s : students) {
                            if (s.getSection() != null) {
                                allSections.add(s.getSection());
                            }
                        }
                        for (String sec : allSections) { 
                        %>
                        <th>Section <%= sec %></th>
                        <% } %>
                        <th>Total</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                    for (Map.Entry<String, Integer> classEntry : sortedClasses) {
                        String className = classEntry.getKey();
                    %>
                    <tr>
                        <td><strong>Class <%= className %></strong></td>
                        <% 
                        int rowTotal = 0;
                        for (String sec : allSections) {
                            int count = classSectionCount.getOrDefault(className, new HashMap<>()).getOrDefault(sec, 0);
                            rowTotal += count;
                        %>
                        <td><%= count > 0 ? "<span class='badge badge-primary'>" + count + "</span>" : "-" %></td>
                        <% } %>
                        <td><strong><%= rowTotal %></strong></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        
        <!-- All Students List -->
        <div class="section">
            <h2 class="section-title">📋 Complete Student List</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>PEN</th>
                        <th>Name</th>
                        <th>Class</th>
                        <th>Section</th>
                        <th>Gender</th>
                        <th>Category</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                    // Sort students by class and section
                    students.sort((a, b) -> {
                        int classCompare = 0;
                        try {
                            classCompare = Integer.compare(
                                Integer.parseInt(a.getStudentClass()), 
                                Integer.parseInt(b.getStudentClass())
                            );
                        } catch (Exception e) {
                            classCompare = a.getStudentClass().compareTo(b.getStudentClass());
                        }
                        if (classCompare != 0) return classCompare;
                        
                        String secA = a.getSection() != null ? a.getSection() : "";
                        String secB = b.getSection() != null ? b.getSection() : "";
                        return secA.compareTo(secB);
                    });
                    
                    for (com.vjnt.model.Student s : students) {
                    %>
                    <tr>
                        <td><%= s.getStudentPen() != null ? s.getStudentPen() : "N/A" %></td>
                        <td><strong><%= s.getStudentName() %></strong></td>
                        <td><%= s.getStudentClass() %></td>
                        <td><%= s.getSection() %></td>
                        <td><span class="badge badge-<%= "Male".equalsIgnoreCase(s.getGender()) || "पुरुष".equals(s.getGender()) ? "primary" : "warning" %>"><%= s.getGender() %></span></td>
                        <td><%= s.getClassCategory() != null ? s.getClassCategory() : "-" %></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
