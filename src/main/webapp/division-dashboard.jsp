<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.UserDAO" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.DIVISION)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    UserDAO userDAO = new UserDAO();
    
    // Get statistics for this division
    String divisionName = user.getDivisionName();
    List<com.vjnt.model.Student> students = studentDAO.getStudentsByDivision(divisionName);
    List<User> divisionUsers = userDAO.getUsersByDivision(divisionName);
    
    // Calculate statistics
    Map<String, Integer> districtCount = new HashMap<>();
    Map<String, Integer> udiseCount = new HashMap<>();
    int maleCount = 0, femaleCount = 0;
    
    for (com.vjnt.model.Student student : students) {
        String district = student.getDistrict();
        String udise = student.getUdiseNo();
        
        if (district != null) {
            districtCount.put(district, districtCount.getOrDefault(district, 0) + 1);
        }
        if (udise != null) {
            udiseCount.put(udise, udiseCount.getOrDefault(udise, 0) + 1);
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
    <title>Division Dashboard - <%= divisionName %></title>
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
            color: #667eea;
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
            border-bottom: 2px solid #667eea;
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
        
        .badge-info {
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
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            transition: width 0.3s;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div>
                <h1>🎓 VJNT Class Management System</h1>
                <p>Division Dashboard - <%= divisionName %></p>
            </div>
            <div class="header-info">
                <div class="user-info">
                    Welcome, <strong><%= user.getFullName() %></strong>
                </div>
                <div class="user-info">
                    Role: <strong>Division Administrator</strong>
                </div>
                <a href="<%= request.getContextPath() %>/change-password" class="btn btn-change-password">Change Password</a>
                <a href="<%= request.getContextPath() %>/logout" class="btn btn-logout">Logout</a>
            </div>
        </div>
    </div>
    
    <div class="container">
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
                <div class="stat-value"><%= udiseCount.size() %></div>
                <div class="stat-label">Schools (UDISE)</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">👤</div>
                <div class="stat-value"><%= divisionUsers.size() %></div>
                <div class="stat-label">Total Users</div>
            </div>
        </div>
        
        <!-- Gender Distribution -->
        <div class="section">
            <h2 class="section-title">📊 Gender Distribution</h2>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                <div>
                    <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                        <span>Male Students (पुरुष)</span>
                        <strong><%= maleCount %></strong>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: <%= students.size() > 0 ? (maleCount * 100.0 / students.size()) : 0 %>%;"></div>
                    </div>
                </div>
                <div>
                    <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                        <span>Female Students (स्त्री)</span>
                        <strong><%= femaleCount %></strong>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: <%= students.size() > 0 ? (femaleCount * 100.0 / students.size()) : 0 %>%; background: linear-gradient(90deg, #f093fb 0%, #f5576c 100%);"></div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- District-wise Statistics -->
        <div class="section">
            <h2 class="section-title">🏛️ District-wise Student Count</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>District Name</th>
                        <th>Student Count</th>
                        <th>Percentage</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                    List<Map.Entry<String, Integer>> sortedDistricts = new ArrayList<>(districtCount.entrySet());
                    sortedDistricts.sort((a, b) -> b.getValue().compareTo(a.getValue()));
                    
                    for (Map.Entry<String, Integer> entry : sortedDistricts) { 
                        double percentage = students.size() > 0 ? (entry.getValue() * 100.0 / students.size()) : 0;
                    %>
                    <tr>
                        <td><strong><%= entry.getKey() %></strong></td>
                        <td><span class="badge badge-primary"><%= entry.getValue() %> students</span></td>
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
        </div>
        
        <!-- Top Schools by Student Count -->
        <div class="section">
            <h2 class="section-title">🏫 Top 10 Schools by Student Count</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>Rank</th>
                        <th>UDISE No</th>
                        <th>Student Count</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                    List<Map.Entry<String, Integer>> sortedUdise = new ArrayList<>(udiseCount.entrySet());
                    sortedUdise.sort((a, b) -> b.getValue().compareTo(a.getValue()));
                    
                    int rank = 1;
                    for (Map.Entry<String, Integer> entry : sortedUdise) {
                        if (rank > 10) break;
                    %>
                    <tr>
                        <td><strong>#<%= rank++ %></strong></td>
                        <td><%= entry.getKey() %></td>
                        <td><span class="badge badge-success"><%= entry.getValue() %> students</span></td>
                        <td><span class="badge badge-info">Active</span></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        
        <!-- User Management Summary -->
        <div class="section">
            <h2 class="section-title">👥 User Management Summary</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>User Type</th>
                        <th>Count</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                    Map<String, Integer> userTypeCount = new HashMap<>();
                    for (User u : divisionUsers) {
                        String type = u.getUserType().name();
                        userTypeCount.put(type, userTypeCount.getOrDefault(type, 0) + 1);
                    }
                    
                    String[] userTypes = {"DIVISION", "DISTRICT_COORDINATOR", "DISTRICT_2ND_COORDINATOR", "SCHOOL_COORDINATOR", "HEAD_MASTER"};
                    String[] userLabels = {"Division Admin", "District Coordinator", "District 2nd Coordinator", "School Coordinator", "Head Master"};
                    
                    for (int i = 0; i < userTypes.length; i++) {
                        int count = userTypeCount.getOrDefault(userTypes[i], 0);
                        if (count > 0) {
                    %>
                    <tr>
                        <td><strong><%= userLabels[i] %></strong></td>
                        <td><span class="badge badge-primary"><%= count %> users</span></td>
                        <td><span class="badge badge-success">Active</span></td>
                    </tr>
                    <% 
                        }
                    } 
                    %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
