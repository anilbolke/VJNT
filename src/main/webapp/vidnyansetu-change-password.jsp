<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.VidnyanSetuUser" %>
<%
    VidnyanSetuUser vsUser = (VidnyanSetuUser) session.getAttribute("vsUser");
    if (vsUser == null) {
        response.sendRedirect(request.getContextPath() + "/vidnyansetu-login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Change Password - विज्ञानसेतू</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f9b6c 0%, #0c7b54 100%);
            min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 15px;
        }
        .container { background: #fff; padding: 30px; border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,0.15); width: 100%; max-width: 440px; }
        .header { text-align: center; margin-bottom: 20px; background: #ecfdf5; padding: 18px; border-radius: 8px; }
        .header h1 { color: #065f46; font-size: 22px; font-weight: 700; margin-bottom: 4px; }
        .header p { color: #0c7b54; font-size: 13px; }
        .user-info { background: #f7fafc; padding: 12px; border-radius: 6px; margin-bottom: 18px; border: 1px solid #e2e8f0; font-size: 13px; color: #4a5568; }
        .user-info strong { color: #2d3748; }
        .form-group { margin-bottom: 16px; }
        .form-group label { display: block; margin-bottom: 6px; color: #4a5568; font-size: 14px; font-weight: 500; }
        .form-group input { width: 100%; padding: 11px 14px; border: 1px solid #e2e8f0; border-radius: 6px; font-size: 14px; }
        .form-group input:focus { outline: none; border-color: #0f9b6c; box-shadow: 0 0 0 3px rgba(15,155,108,0.1); }
        .btn-submit { width: 100%; padding: 12px; background: #0f9b6c; color: #fff; border: none; border-radius: 6px; font-size: 15px; font-weight: 600; cursor: pointer; margin-top: 5px; }
        .btn-submit:hover { background: #0c7b54; }
        .alert { padding: 10px 14px; border-radius: 6px; margin-bottom: 16px; font-size: 13px; line-height: 1.5; }
        .alert-error { background-color: #fed7d7; color: #c53030; border-left: 3px solid #fc8181; }
        .alert-warning { background-color: #fef5e7; color: #d68910; border-left: 3px solid #f39c12; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Change Password</h1>
            <p>विज्ञानसेतू Portal</p>
        </div>

        <div class="user-info">
            <p><strong>Username:</strong> <%= vsUser.getUsername() %></p>
            <p><strong>Role:</strong> <%= vsUser.getRole() == VidnyanSetuUser.Role.COORDINATOR ? "School Coordinator" : "Teacher" %></p>
            <p><strong>UDISE No:</strong> <%= vsUser.getUdiseNo() %></p>
        </div>

        <% if (vsUser.isFirstLogin() || vsUser.isMustChangePassword()) { %>
            <div class="alert alert-warning">
                <strong>Password Change Required</strong><br>
                You must change your password to continue.
            </div>
        <% } %>

        <%
            String errorMessage = (String) request.getAttribute("errorMessage");
            if (errorMessage != null && !errorMessage.isEmpty()) {
        %>
            <div class="alert alert-error"><%= errorMessage %></div>
        <% } %>

        <form method="post" action="<%= request.getContextPath() %>/vidnyansetu-change-password">
            <div class="form-group">
                <label for="currentPassword">Current Password</label>
                <input type="password" id="currentPassword" name="currentPassword" placeholder="Enter your current password" required autofocus>
            </div>
            <div class="form-group">
                <label for="newPassword">New Password</label>
                <input type="password" id="newPassword" name="newPassword" placeholder="Enter new password" required>
            </div>
            <div class="form-group">
                <label for="confirmPassword">Confirm New Password</label>
                <input type="password" id="confirmPassword" name="confirmPassword" placeholder="Confirm new password" required>
            </div>
            <button type="submit" class="btn-submit">Change Password</button>
        </form>
    </div>
</body>
</html>
