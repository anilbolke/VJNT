<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - VJNT Class Management</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 40px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .header-content {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            font-size: 24px;
        }
        
        .user-info {
            text-align: right;
        }
        
        .user-info p {
            margin: 5px 0;
            font-size: 14px;
        }
        
        .logout-btn {
            background: rgba(255,255,255,0.2);
            color: white;
            border: 1px solid white;
            padding: 8px 20px;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            margin-top: 10px;
            transition: background 0.3s;
        }
        
        .logout-btn:hover {
            background: rgba(255,255,255,0.3);
        }
        
        .container {
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        .welcome-card {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        
        .welcome-card h2 {
            color: #333;
            margin-bottom: 15px;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        
        .info-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        
        .info-item label {
            display: block;
            color: #666;
            font-size: 12px;
            margin-bottom: 5px;
            text-transform: uppercase;
        }
        
        .info-item value {
            display: block;
            color: #333;
            font-size: 16px;
            font-weight: 600;
        }
        
        .action-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        
        .action-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            transition: transform 0.3s;
        }
        
        .action-card:hover {
            transform: translateY(-5px);
        }
        
        .action-card h3 {
            color: #333;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
        }
        
        .action-card p {
            color: #666;
            font-size: 14px;
            margin-bottom: 15px;
        }
        
        .action-btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            font-size: 14px;
        }
        
        .badge {
            background: #667eea;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            display: inline-block;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <h1>🎓 VJNT Class Management System</h1>
            <div class="user-info">
                <p><strong><%= user.getFullName() != null ? user.getFullName() : user.getUsername() %></strong></p>
                <p><%= user.getUserType().toString().replace("_", " ") %></p>
                <a href="<%= request.getContextPath() %>/logout" class="logout-btn">Logout</a>
            </div>
        </div>
    </div>
    
    <div class="container">
        <div class="welcome-card">
            <h2>Welcome to Your Dashboard!</h2>
            <p>You have successfully logged in to the VJNT Class Management System.</p>
            
            <div class="info-grid">
                <div class="info-item">
                    <label>Username</label>
                    <value><%= user.getUsername() %></value>
                </div>
                
                <div class="info-item">
                    <label>User Type</label>
                    <value><%= user.getUserType().toString().replace("_", " ") %></value>
                </div>
                
                <% if (user.getDivisionName() != null) { %>
                <div class="info-item">
                    <label>Division</label>
                    <value><%= user.getDivisionName() %></value>
                </div>
                <% } %>
                
                <% if (user.getDistrictName() != null) { %>
                <div class="info-item">
                    <label>District</label>
                    <value><%= user.getDistrictName() %></value>
                </div>
                <% } %>
                
                <% if (user.getUdiseNo() != null) { %>
                <div class="info-item">
                    <label>UDISE Number</label>
                    <value><%= user.getUdiseNo() %></value>
                </div>
                <% } %>
                
                <div class="info-item">
                    <label>Last Login</label>
                    <value><%= user.getLastLoginDate() != null ? user.getLastLoginDate() : "First Login" %></value>
                </div>
            </div>
        </div>
        
        <div class="action-cards">
            <div class="action-card">
                <h3>📝 Manage Students</h3>
                <p>View, add, and manage student information and records.</p>
                <span class="badge">Coming Soon</span>
            </div>
            
            <div class="action-card">
                <h3>📊 View Reports</h3>
                <p>Access and generate various reports and analytics.</p>
                <span class="badge">Coming Soon</span>
            </div>
            
            <div class="action-card">
                <h3>⚙️ Settings</h3>
                <p>Manage your account settings and preferences.</p>
                <a href="<%= request.getContextPath() %>/change-password" class="action-btn">Change Password</a>
            </div>
        </div>
    </div>
</body>
</html>
