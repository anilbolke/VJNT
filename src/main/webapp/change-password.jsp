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
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 15px;
        }
        
        .change-password-container {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
            width: 100%;
            max-width: 450px;
        }
        
        .header {
            text-align: center;
            margin-bottom: 20px;
        }
        
        .header h1 {
            color: #2d3748;
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 5px;
        }
        
        .header p {
            color: #718096;
            font-size: 13px;
        }
        
        .user-info {
            background: #f7fafc;
            padding: 12px;
            border-radius: 6px;
            margin-bottom: 18px;
            border: 1px solid #e2e8f0;
        }
        
        .user-info p {
            margin: 4px 0;
            color: #4a5568;
            font-size: 13px;
        }
        
        .user-info strong {
            color: #2d3748;
        }
        
        .form-group {
            margin-bottom: 16px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 6px;
            color: #4a5568;
            font-size: 14px;
            font-weight: 500;
        }
        
        .form-group input {
            width: 100%;
            padding: 11px 14px;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            font-size: 14px;
            transition: all 0.2s;
        }
        
        .form-group input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .btn-submit {
            width: 100%;
            padding: 12px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            margin-top: 5px;
        }
        
        .btn-submit:hover {
            background: #5568d3;
        }
        
        .btn-submit:active {
            transform: scale(0.98);
        }
        
        .alert {
            padding: 10px 14px;
            border-radius: 6px;
            margin-bottom: 16px;
            font-size: 13px;
            line-height: 1.5;
        }
        
        .alert-error {
            background-color: #fed7d7;
            color: #c53030;
            border-left: 3px solid #fc8181;
        }
        
        .alert-warning {
            background-color: #fef5e7;
            color: #d68910;
            border-left: 3px solid #f39c12;
        }
        
        .password-requirements {
            background: #edf2f7;
            padding: 12px;
            border-radius: 6px;
            margin-top: 15px;
            font-size: 12px;
            color: #4a5568;
            border: 1px solid #e2e8f0;
        }
        
        .password-requirements h4 {
            color: #2d3748;
            margin-bottom: 8px;
            font-size: 13px;
            font-weight: 600;
        }
        
        .password-requirements ul {
            margin-left: 18px;
        }
        
        .password-requirements li {
            margin: 3px 0;
        }
        
        /* Mobile Responsive */
        @media (max-width: 480px) {
            .change-password-container {
                padding: 25px 20px;
            }
            
            .header h1 {
                font-size: 22px;
            }
            
            .header p {
                font-size: 12px;
            }
            
            .user-info {
                padding: 10px;
                font-size: 12px;
            }
            
            .user-info p {
                font-size: 12px;
            }
            
            .form-group input {
                padding: 10px 12px;
                font-size: 16px; /* Prevents zoom on iOS */
            }
            
            .btn-submit {
                padding: 11px;
                font-size: 14px;
            }
            
            .password-requirements {
                font-size: 11px;
                padding: 10px;
            }
            
            .password-requirements h4 {
                font-size: 12px;
            }
        }
        
        @media (max-width: 360px) {
            body {
                padding: 10px;
            }
            
            .change-password-container {
                padding: 20px 15px;
            }
            
            .header h1 {
                font-size: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="change-password-container">
        <div class="header">
            <h1>🔐 Change Password</h1>
            <p>Update your password</p>
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
                <strong>Password Change Required</strong><br>
                You must change your password to continue.
            </div>
        <% } %>
        
        <% 
            String errorMessage = (String) request.getAttribute("errorMessage");
            if (errorMessage != null && !errorMessage.isEmpty()) {
        %>
            <div class="alert alert-error">
                <%= errorMessage %>
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
            <h4>Password Requirements:</h4>
            <ul>
                <li>At least 8 characters</li>
                <li>One uppercase letter (A-Z)</li>
                <li>One lowercase letter (a-z)</li>
                <li>One number (0-9)</li>
                <li>One special character (@#$%)</li>
                <li>Different from current password</li>
            </ul>
        </div>
    </div>
</body>
</html>
