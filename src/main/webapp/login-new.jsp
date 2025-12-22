<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GATEE  - Secure Login</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            position: relative;
            overflow: hidden;
        }
        
        /* Animated background pattern */
        body::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-image: 
                radial-gradient(circle at 20% 50%, rgba(255, 255, 255, 0.1) 0%, transparent 50%),
                radial-gradient(circle at 80% 80%, rgba(255, 255, 255, 0.1) 0%, transparent 50%);
            animation: backgroundShift 15s ease-in-out infinite;
        }
        
        @keyframes backgroundShift {
            0%, 100% { transform: translate(0, 0); }
            50% { transform: translate(20px, 20px); }
        }
        
        .login-wrapper {
            position: relative;
            z-index: 1;
            width: 100%;
            max-width: 1200px;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            overflow: hidden;
        }
        
        /* Left side - Branding */
        .branding-section {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 60px 50px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            color: white;
            position: relative;
            overflow: hidden;
        }
        
        .branding-section::before {
            content: '';
            position: absolute;
            width: 300px;
            height: 300px;
            background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%);
            top: -100px;
            right: -100px;
            animation: float 6s ease-in-out infinite;
        }
        
        @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-20px); }
        }
        
        .logo-section {
            text-align: center;
            margin-bottom: 40px;
            position: relative;
            z-index: 1;
        }
        
        .logo-section img {
            width: 200px;
            height: auto;
            margin-bottom: 30px;
            filter: drop-shadow(0 10px 20px rgba(0, 0, 0, 0.2));
            animation: logoGlow 3s ease-in-out infinite;
        }
        
        @keyframes logoGlow {
            0%, 100% { filter: drop-shadow(0 10px 20px rgba(0, 0, 0, 0.2)); }
            50% { filter: drop-shadow(0 10px 30px rgba(255, 255, 255, 0.4)); }
        }
        
        .system-title {
            font-size: 32px;
            font-weight: 800;
            margin-bottom: 15px;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
            letter-spacing: 1px;
        }
        
        .system-subtitle {
            font-size: 16px;
            font-weight: 400;
            opacity: 0.95;
            margin-bottom: 50px;
        }
        
        .gatee-section {
            background: rgba(255, 255, 255, 0.15);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 30px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            position: relative;
            z-index: 1;
        }
        
        .gatee-title {
            font-size: 20px;
            font-weight: 700;
            text-align: center;
            margin-bottom: 20px;
            text-transform: uppercase;
            letter-spacing: 3px;
        }
        
        .gatee-title::after {
            content: '';
            display: block;
            width: 80px;
            height: 4px;
            background: #ffd700;
            margin: 15px auto 0;
            border-radius: 2px;
        }
        
        .gatee-list {
            list-style: none;
            padding: 0;
        }
        
        .gatee-item {
            padding: 12px 15px;
            margin: 10px 0;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 8px;
            border-left: 4px solid #ffd700;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
        }
        
        .gatee-item:hover {
            background: rgba(255, 255, 255, 0.2);
            transform: translateX(5px);
        }
        
        .gatee-item::before {
            content: '◆';
            color: #ffd700;
            font-size: 14px;
            margin-right: 12px;
        }
        
        .gatee-letter {
            font-size: 22px;
            font-weight: 800;
            color: #ffd700;
            margin-right: 10px;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        
        .gatee-text {
            font-size: 15px;
            font-weight: 500;
        }
        
        /* Right side - Login Form */
        .login-section {
            padding: 60px 50px;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }
        
        .login-header {
            margin-bottom: 40px;
        }
        
        .login-header h2 {
            font-size: 28px;
            font-weight: 700;
            color: #1a202c;
            margin-bottom: 10px;
        }
        
        .login-header p {
            font-size: 15px;
            color: #718096;
            font-weight: 400;
        }
        
        .security-badge {
            display: inline-flex;
            align-items: center;
            background: #f0fdf4;
            color: #166534;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            margin-top: 10px;
            border: 1px solid #86efac;
        }
        
        .security-badge::before {
            content: '🔒';
            margin-right: 6px;
        }
        
        .alert {
            padding: 14px 18px;
            border-radius: 8px;
            font-size: 14px;
            margin-bottom: 20px;
            font-weight: 500;
            display: flex;
            align-items: center;
            animation: slideIn 0.3s ease;
        }
        
        @keyframes slideIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .alert::before {
            font-size: 18px;
            margin-right: 10px;
        }
        
        .alert-error {
            background: #fee2e2;
            color: #991b1b;
            border-left: 4px solid #dc2626;
        }
        
        .alert-error::before {
            content: '⚠️';
        }
        
        .alert-success {
            background: #d1fae5;
            color: #065f46;
            border-left: 4px solid #10b981;
        }
        
        .alert-success::before {
            content: '✓';
        }
        
        .form-group {
            margin-bottom: 25px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #374151;
            font-size: 14px;
            font-weight: 600;
        }
        
        .input-wrapper {
            position: relative;
        }
        
        .input-icon {
            position: absolute;
            left: 15px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 18px;
            color: #9ca3af;
        }
        
        .form-group input {
            width: 100%;
            padding: 14px 15px 14px 45px;
            border: 2px solid #e5e7eb;
            border-radius: 10px;
            font-size: 15px;
            transition: all 0.3s;
            background: #f9fafb;
            color: #1f2937;
            font-weight: 500;
        }
        
        .form-group input:focus {
            outline: none;
            border-color: #667eea;
            background: white;
            box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
        }
        
        .form-group input::placeholder {
            color: #9ca3af;
            font-weight: 400;
        }
        
        .password-toggle {
            position: absolute;
            right: 15px;
            top: 50%;
            transform: translateY(-50%);
            cursor: pointer;
            font-size: 18px;
            color: #9ca3af;
            transition: color 0.2s;
        }
        
        .password-toggle:hover {
            color: #667eea;
        }
        
        .form-options {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
        }
        
        .remember-me {
            display: flex;
            align-items: center;
        }
        
        .remember-me input[type="checkbox"] {
            width: 18px;
            height: 18px;
            margin-right: 8px;
            cursor: pointer;
            accent-color: #667eea;
        }
        
        .remember-me label {
            color: #4b5563;
            font-size: 14px;
            cursor: pointer;
            font-weight: 500;
        }
        
        .forgot-password {
            color: #667eea;
            font-size: 14px;
            text-decoration: none;
            font-weight: 600;
            transition: color 0.2s;
        }
        
        .forgot-password:hover {
            color: #5568d3;
            text-decoration: underline;
        }
        
        .btn-login {
            width: 100%;
            padding: 16px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.3s;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
            position: relative;
            overflow: hidden;
        }
        
        .btn-login::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
            transition: left 0.5s;
        }
        
        .btn-login:hover::before {
            left: 100%;
        }
        
        .btn-login:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
        }
        
        .btn-login:active {
            transform: translateY(0);
        }
        
        .default-credentials {
            background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
            border: 2px solid #fbbf24;
            border-radius: 10px;
            padding: 18px;
            margin-top: 25px;
        }
        
        .default-credentials-title {
            font-size: 14px;
            font-weight: 700;
            color: #92400e;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
        }
        
        .default-credentials-title::before {
            content: 'ℹ️';
            margin-right: 8px;
            font-size: 16px;
        }
        
        .credential-item {
            display: flex;
            align-items: center;
            margin: 8px 0;
            font-size: 13px;
            color: #78350f;
        }
        
        .credential-label {
            font-weight: 600;
            margin-right: 8px;
        }
        
        .credential-value {
            background: rgba(255, 255, 255, 0.7);
            padding: 4px 10px;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            font-weight: 600;
            color: #1f2937;
        }
        
        .footer-note {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
            text-align: center;
            color: #6b7280;
            font-size: 13px;
        }
        
        .footer-note strong {
            color: #374151;
        }
        
        /* Government Badge */
        .govt-badge {
            position: absolute;
            top: 20px;
            right: 20px;
            background: rgba(255, 255, 255, 0.95);
            padding: 10px 20px;
            border-radius: 30px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 12px;
            font-weight: 700;
            color: #1f2937;
            z-index: 10;
        }
        
        .govt-badge::before {
            content: '🇮🇳';
            font-size: 16px;
        }
        
        /* Mobile Responsive */
        @media (max-width: 968px) {
            .login-wrapper {
                grid-template-columns: 1fr;
                max-width: 500px;
            }
            
            .branding-section {
                padding: 40px 30px;
            }
            
            .logo-section img {
                width: 150px;
            }
            
            .system-title {
                font-size: 24px;
            }
            
            .login-section {
                padding: 40px 30px;
            }
        }
        
        @media (max-width: 480px) {
            body {
                padding: 10px;
            }
            
            .branding-section {
                padding: 30px 20px;
            }
            
            .login-section {
                padding: 30px 20px;
            }
            
            .login-header h2 {
                font-size: 24px;
            }
            
            .form-group input {
                padding: 12px 12px 12px 40px;
                font-size: 16px;
            }
            
            .gatee-section {
                padding: 20px;
            }
            
            .govt-badge {
                top: 10px;
                right: 10px;
                padding: 8px 15px;
                font-size: 11px;
            }
        }
    </style>
</head>
<body>
    <div class="govt-badge">
        Government of Maharashtra
    </div>
    
    <div class="login-wrapper">
        <!-- Left Side - Branding -->
        <div class="branding-section">
            <div class="logo-section">
                <img src="<%= request.getContextPath() %>/Document/GATEE LOGO.png?v=2" alt="GATEE Logo">
                <h1 class="system-title">GATEE</h1>
                <p class="system-subtitle">Growth • Ambition • Training • Education • Excellence</p>
            </div>
            
            <div class="gatee-section">
                <h3 class="gatee-title">Our Vision</h3>
                <ul class="gatee-list">
                    <li class="gatee-item">
                        <span class="gatee-letter">G</span>
                        <span class="gatee-text">Growth - Empowering Every Student</span>
                    </li>
                    <li class="gatee-item">
                        <span class="gatee-letter">A</span>
                        <span class="gatee-text">Ambition - Building Future Leaders</span>
                    </li>
                    <li class="gatee-item">
                        <span class="gatee-letter">T</span>
                        <span class="gatee-text">Training - Quality Education for All</span>
                    </li>
                    <li class="gatee-item">
                        <span class="gatee-letter">E</span>
                        <span class="gatee-text">Education - Knowledge & Skills</span>
                    </li>
                    <li class="gatee-item">
                        <span class="gatee-letter">E</span>
                        <span class="gatee-text">Excellence - Achieving Higher Standards</span>
                    </li>
                </ul>
            </div>
        </div>
        
        <!-- Right Side - Login Form -->
        <div class="login-section">
            <div class="login-header">
                <h2>Welcome Back</h2>
                <p>Please login to access the GATEE </p>
                <span class="security-badge">Secure Login Portal</span>
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
                    <div class="input-wrapper">
                        <span class="input-icon">👤</span>
                        <input type="text" id="username" name="username" 
                               placeholder="Enter your username" required autofocus>
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="password">Password</label>
                    <div class="input-wrapper">
                        <span class="input-icon">🔒</span>
                        <input type="password" id="password" name="password" 
                               placeholder="Enter your password" required>
                        <span class="password-toggle" onclick="togglePassword()">👁️</span>
                    </div>
                </div>
                
                <div class="form-options">
                    <div class="remember-me">
                        <input type="checkbox" id="remember" name="remember">
                        <label for="remember">Remember me</label>
                    </div>
                    <a href="#" class="forgot-password">Forgot Password?</a>
                </div>
                
                <button type="submit" class="btn-login">Sign In</button>
            </form>
            
            <div class="default-credentials">
                <div class="default-credentials-title">First Time Login Information</div>
                <div class="credential-item">
                    <span class="credential-label">Default Password:</span>
                    <span class="credential-value">Pass@123</span>
                </div>
                <div class="credential-item" style="margin-top: 10px; color: #92400e; font-weight: 600;">
                    ⚠️ You will be required to change your password on first login
                </div>
            </div>
            
            <div class="footer-note">
                <strong>Need Help?</strong> Contact your system administrator<br>
                <span style="font-size: 12px;">© 2025 GATEE . All rights reserved.</span>
            </div>
        </div>
    </div>
    
    <script>
        function togglePassword() {
            const passwordInput = document.getElementById('password');
            const toggleIcon = document.querySelector('.password-toggle');
            
            if (passwordInput.type === 'password') {
                passwordInput.type = 'text';
                toggleIcon.textContent = '🙈';
            } else {
                passwordInput.type = 'password';
                toggleIcon.textContent = '👁️';
            }
        }
    </script>
</body>
</html>
