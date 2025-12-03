<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - VJNT Class Management System</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: #f0f2f5;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 15px;
        }
        
        .login-container {
            background: #e8eaf0;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
            width: 100%;
            max-width: 380px;
        }
        
        .login-header {
            text-align: center;
            margin-bottom: 25px;
            background: #f0f2f5;
            padding: 20px;
            border-radius: 8px;
        }
        
        .login-header h1 {
            color: #000;
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 5px;
        }
        
        .login-header p {
            color: #000;
            font-size: 13px;
            font-weight: 600;
        }
        
        .form-group {
            margin-bottom: 18px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 6px;
            color: #000;
            font-size: 14px;
            font-weight: 700;
        }
        
        .form-group input {
            width: 100%;
            padding: 11px 14px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            transition: all 0.2s;
            background: #fff;
            color: #000;
        }
        
        .form-group input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .btn-login {
            width: 100%;
            padding: 12px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 15px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s;
            margin-top: 5px;
        }
        
        .btn-login:hover {
            background: #5568d3;
        }
        
        .btn-login:active {
            transform: scale(0.98);
        }
        
        .alert {
            padding: 12px 14px;
            border-radius: 6px;
            font-size: 14px;
            margin-bottom: 15px;
            font-weight: 600;
        }
        
        .alert-error {
            background: #ffcdd2;
            color: #c62828;
            border-left: 4px solid #c62828;
        }
        
        .alert-success {
            background: #c8e6c9;
            color: #2e7d32;
            border-left: 4px solid #2e7d32;
        }
        
        .login-footer {
            text-align: center;
            margin-top: 20px;
            color: #000;
            font-weight: 600;
            font-size: 13px;
        }
        
        .login-footer a {
            color: #667eea;
            text-decoration: none;
            font-weight: 700;
        }
        
        .login-footer a:hover {
            text-decoration: underline;
        }
        
        .remember-me {
            display: flex;
            align-items: center;
            margin-bottom: 15px;
        }
        
        .remember-me input[type="checkbox"] {
            margin-right: 8px;
            cursor: pointer;
        }
        
        .remember-me label {
            margin: 0;
            color: #000;
            font-weight: 600;
            cursor: pointer;
            font-size: 13px;
        }
            border-radius: 6px;
            margin-bottom: 18px;
            font-size: 13px;
            line-height: 1.5;
        }
        
        .alert-error {
            background-color: #fed7d7;
            color: #c53030;
            border-left: 3px solid #fc8181;
        }
        
        .alert-success {
            background-color: #c6f6d5;
            color: #276749;
            border-left: 3px solid #48bb78;
        }
        
        .default-password-info {
            background: #f7fafc;
            padding: 12px;
            border-radius: 6px;
            margin-top: 18px;
            font-size: 12px;
            color: #718096;
            border: 1px solid #e2e8f0;
        }
        
        .default-password-info strong {
            color: #2d3748;
        }
        
        /* Mobile Responsive */
        @media (max-width: 480px) {
            .login-container {
                padding: 25px 20px;
            }
            
            .login-header h1 {
                font-size: 22px;
            }
            
            .login-header p {
                font-size: 12px;
            }
            
            .form-group input {
                padding: 10px 12px;
                font-size: 16px; /* Prevents zoom on iOS */
            }
            
            .btn-login {
                padding: 11px;
                font-size: 14px;
            }
            
            .default-password-info {
                font-size: 11px;
                padding: 10px;
            }
        }
        
        @media (max-width: 360px) {
            body {
                padding: 10px;
            }
            
            .login-container {
                padding: 20px 15px;
            }
            
            .login-header h1 {
                font-size: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-header">
            <h1>🎓 VJNT</h1>
            <p>Class Management System</p>
        </div>
        
        <% 
            String errorMessage = (String) request.getAttribute("errorMessage");
            String successMessage = (String) request.getAttribute("successMessage");
            String logoutMessage = request.getParameter("message");
            
            if (errorMessage != null && !errorMessage.isEmpty()) {
        %>
            <div class="alert alert-error">
                <%= errorMessage %>
            </div>
        <% } %>
        
        <% if (successMessage != null && !successMessage.isEmpty()) { %>
            <div class="alert alert-success">
                <%= successMessage %>
            </div>
        <% } %>
        
        <% if (logoutMessage != null && !logoutMessage.isEmpty()) { %>
            <div class="alert alert-success">
                <%= logoutMessage %>
            </div>
        <% } %>
        
        <form method="post" action="<%= request.getContextPath() %>/login">
            <div class="form-group">
                <label for="username">Username</label>
                <input type="text"  id="username" name="username" 
                       placeholder="Enter your username" required autofocus>
            </div>
            
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password"  id="password" name="password" 
                       placeholder="Enter your password" required>
            </div>
            
            <button type="submit" class="btn-login">Login</button>
        </form>
        
        <div class="default-password-info">
            <strong>Default Password:</strong> Pass@123<br>
            Change password required on first login.
        </div>
    </div>
</body>
</html>
