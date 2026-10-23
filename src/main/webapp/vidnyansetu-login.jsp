<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="mr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>विज्ञानसेतू पोर्टल - Login</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #0f9b6c 0%, #0c7b54 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .login-card {
            background: #fff;
            width: 100%;
            max-width: 420px;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.25);
            overflow: hidden;
        }
        .brand {
            background: linear-gradient(135deg, #0f9b6c 0%, #0c7b54 100%);
            color: #fff;
            padding: 32px 30px 26px;
            text-align: center;
        }
        .brand .emoji { font-size: 40px; margin-bottom: 8px; }
        .brand h1 { font-size: 24px; font-weight: 800; letter-spacing: 0.5px; }
        .brand p { font-size: 13px; opacity: 0.9; margin-top: 6px; }
        .form-area { padding: 30px; }
        .alert {
            padding: 12px 16px; border-radius: 8px; font-size: 13.5px;
            margin-bottom: 18px; font-weight: 500;
        }
        .alert-error { background: #fee2e2; color: #991b1b; border-left: 4px solid #dc2626; }
        .alert-success { background: #d1fae5; color: #065f46; border-left: 4px solid #10b981; }
        .form-group { margin-bottom: 18px; }
        .form-group label {
            display: block; margin-bottom: 6px; color: #374151; font-size: 13.5px; font-weight: 600;
        }
        .form-group input {
            width: 100%; padding: 12px 14px; border: 2px solid #e5e7eb; border-radius: 8px;
            font-size: 15px; background: #f9fafb; color: #1f2937;
        }
        .form-group input:focus {
            outline: none; border-color: #0f9b6c; background: #fff;
            box-shadow: 0 0 0 3px rgba(15,155,108,0.12);
        }
        .btn-login {
            width: 100%; padding: 14px; background: linear-gradient(135deg, #0f9b6c 0%, #0c7b54 100%);
            color: #fff; border: none; border-radius: 8px; font-size: 15px; font-weight: 700;
            cursor: pointer; margin-top: 4px;
        }
        .btn-login:hover { filter: brightness(1.05); }
        .back-link {
            display: block; text-align: center; margin-top: 18px; font-size: 13px;
            color: #0c7b54; text-decoration: none; font-weight: 600;
        }
        .back-link:hover { text-decoration: underline; }
        .default-credentials {
            background: #ecfdf5; border: 1px solid #86efac; border-radius: 8px;
            padding: 14px; margin-top: 20px; font-size: 12.5px; color: #065f46;
        }
    </style>
</head>
<body>
    <div class="login-card">
        <div class="brand">
            <div class="emoji">🔬</div>
            <h1>विज्ञानसेतू</h1>
            <p>School Coordinator / Teacher Login</p>
        </div>
        <div class="form-area">
            <%
                String errorMessage = (String) request.getAttribute("errorMessage");
                String logoutMessage = request.getParameter("message");
                if (errorMessage != null && !errorMessage.isEmpty()) {
            %>
                <div class="alert alert-error"><%= errorMessage %></div>
            <% } %>
            <% if (logoutMessage != null && !logoutMessage.isEmpty()) { %>
                <div class="alert alert-success"><%= logoutMessage %></div>
            <% } %>

            <form method="post" action="<%= request.getContextPath() %>/vidnyansetu-login">
                <div class="form-group">
                    <label for="username">Username</label>
                    <input type="text" id="username" name="username" placeholder="Enter your username" required autofocus>
                </div>
                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" placeholder="Enter your password" required>
                </div>
                <button type="submit" class="btn-login">Sign In</button>
            </form>

            <div class="default-credentials">
                First login? Default password is <strong>Pass@123</strong> — you'll be asked to set a new one.
            </div>

            <a class="back-link" href="<%= request.getContextPath() %>/login">← Back to GATEE Portal login</a>
        </div>
    </div>
</body>
</html>
