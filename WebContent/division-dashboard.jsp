<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.UserDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
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
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div class="header-left">
                <h1>
                    <span style="font-size: 32px;">🏢</span>
                    <span>VJNT Class Management</span>
                </h1>
                <p class="header-subtitle">📍 Division Dashboard - <%= divisionName %></p>
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
                    <a href="<%= request.getContextPath() %>/division-dashboard-enhanced.jsp" class="btn btn-analytics" title="View detailed analytics and reports">
                        <span>📊</span>
                        <span>Analytics</span>
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
            <span>Division:</span> <strong><%= divisionName %></strong>
        </div>
        
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
                            <span class="badge badge-primary">
                                <%= totalCount %> students
                            </span>
                        </td>
                        <td><span class="badge badge-warning"><%= schoolCount %> schools</span></td>
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
</body>
</html>
