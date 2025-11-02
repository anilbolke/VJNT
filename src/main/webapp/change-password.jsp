<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    // Check if user is logged in
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    Boolean isFirstLogin = (Boolean) request.getAttribute("isFirstLogin");
    Boolean mustChangePassword = (Boolean) request.getAttribute("mustChangePassword");
    if (isFirstLogin == null) isFirstLogin = user.isFirstLogin();
    if (mustChangePassword == null) mustChangePassword = user.isMustChangePassword();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Change Password - VJNT Class Management System</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .change-password-container {
            background: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            width: 100%;
            max-width: 500px;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .header h1 {
            color: #333;
            font-size: 26px;
            margin-bottom: 10px;
        }
        
        .header p {
            color: #666;
            font-size: 14px;
        }
        
        .user-info {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        
        .user-info p {
            margin: 5px 0;
            color: #555;
            font-size: 14px;
        }
        
        .user-info strong {
            color: #333;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: 500;
        }
        
        .form-group input {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        
        .form-group input:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .btn-submit {
            width: 100%;
            padding: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s;
        }
        
        .btn-submit:hover {
            transform: translateY(-2px);
        }
        
        .alert {
            padding: 12px 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        
        .alert-error {
            background-color: #fee;
            color: #c33;
            border: 1px solid #fcc;
        }
        
        .alert-warning {
            background-color: #fff3cd;
            color: #856404;
            border: 1px solid #ffeaa7;
        }
        
        .password-requirements {
            background: #f0f7ff;
            padding: 15px;
            border-radius: 8px;
            margin-top: 15px;
            font-size: 13px;
            color: #555;
        }
        
        .password-requirements h4 {
            color: #333;
            margin-bottom: 10px;
            font-size: 14px;
        }
        
        .password-requirements ul {
            margin-left: 20px;
        }
        
        .password-requirements li {
            margin: 5px 0;
        }
    </style>
</head>
<body>
    <div class="change-password-container">
        <div class="header">
            <h1>🔐 Change Password</h1>
            <p>Update your account password</p>
        </div>
        
        <div class="user-info">
            <p><strong>Username:</strong> <%= user.getUsername() %></p>
            <p><strong>User Type:</strong> <%= user.getUserType() %></p>
            <% if (user.getDivisionName() != null) { %>
                <p><strong>Division:</strong> <%= user.getDivisionName() %></p>
            <% } %>
            <% if (user.getDistrictName() != null) { %>
                <p><strong>District:</strong> <%= user.getDistrictName() %></p>
            <% } %>
            <% if (user.getUdiseNo() != null) { %>
                <p><strong>UDISE No:</strong> <%= user.getUdiseNo() %></p>
            <% } %>
        </div>
        
        <% if (isFirstLogin || mustChangePassword) { %>
            <div class="alert alert-warning">
                ⚠️ <strong>Password Change Required!</strong><br>
                You must change your password before proceeding.
            </div>
        <% } %>
        
        <% 
            String errorMessage = (String) request.getAttribute("errorMessage");
            if (errorMessage != null && !errorMessage.isEmpty()) {
        %>
            <div class="alert alert-error">
                ⚠️ <%= errorMessage %>
            </div>
        <% } %>
        
        <form method="post" action="<%= request.getContextPath() %>/change-password">
            <div class="form-group">
                <label for="currentPassword">Current Password</label>
                <input type="password" id="currentPassword" name="currentPassword" 
                       placeholder="Enter your current password" required autofocus>
            </div>
            
            <div class="form-group">
                <label for="newPassword">New Password</label>
                <input type="password" id="newPassword" name="newPassword" 
                       placeholder="Enter new password" required>
            </div>
            
            <div class="form-group">
                <label for="confirmPassword">Confirm New Password</label>
                <input type="password" id="confirmPassword" name="confirmPassword" 
                       placeholder="Confirm new password" required>
            </div>
            
            <button type="submit" class="btn-submit">Change Password</button>
        </form>
        
        <div class="password-requirements">
            <h4>📋 Password Requirements:</h4>
            <ul>
                <li>Minimum 8 characters long</li>
                <li>At least 1 uppercase letter (A-Z)</li>
                <li>At least 1 lowercase letter (a-z)</li>
                <li>At least 1 digit (0-9)</li>
                <li>At least 1 special character (@, #, $, %, etc.)</li>
                <li>Must be different from current password</li>
            </ul>
        </div>
    </div>
</body>
</html>
