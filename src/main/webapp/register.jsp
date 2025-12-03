<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title id="pageTitle">Register - VJNT Class Management System</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, 'Noto Sans Devanagari', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 15px;
        }
        
        .register-container {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
            width: 100%;
            max-width: 450px;
        }
        
        .register-header {
            text-align: center;
            margin-bottom: 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: #f0f2f5;
            padding: 20px;
            border-radius: 8px;
        }
        
        .header-title {
            flex: 1;
        }
        
        .header-title h1 {
            color: #000;
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 5px;
        }
        
        .header-title p {
            color: #000;
            font-size: 13px;
        }
        
        .language-toggle {
            display: flex;
            gap: 8px;
        }
        
        .lang-btn {
            padding: 8px 12px;
            border: 2px solid #e2e8f0;
            background: white;
            border-radius: 6px;
            cursor: pointer;
            font-size: 12px;
            font-weight: 600;
            transition: all 0.2s;
            color: #718096;
        }
        
        .lang-btn.active {
            border-color: #667eea;
            background: #667eea;
            color: white;
        }
        
        .lang-btn:hover {
            border-color: #667eea;
        }
        
        .form-group {
            margin-bottom: 18px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 6px;
            color: #4a5568;
            font-size: 14px;
            font-weight: 500;
        }
        
        .form-group input,
        .form-group select {
            width: 100%;
            padding: 11px 14px;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            font-size: 14px;
            font-family: inherit;
            transition: all 0.2s;
        }
        
        .form-group input:focus,
        .form-group select:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .password-requirements {
            background: #f7fafc;
            padding: 10px 12px;
            border-radius: 6px;
            font-size: 12px;
            color: #718096;
            margin-top: 6px;
            border: 1px solid #e2e8f0;
        }
        
        .password-requirements ul {
            margin-left: 18px;
            margin-top: 5px;
        }
        
        .password-requirements li {
            margin-bottom: 3px;
        }
        
        .btn-register {
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
        
        .btn-register:hover {
            background: #5568d3;
        }
        
        .btn-register:active {
            transform: scale(0.98);
        }
        
        .alert {
            padding: 10px 14px;
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
        
        .login-link {
            text-align: center;
            margin-top: 18px;
            font-size: 13px;
            color: #718096;
        }
        
        .login-link a {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
        }
        
        .login-link a:hover {
            text-decoration: underline;
        }
        
        /* Mobile Responsive */
        @media (max-width: 480px) {
            .register-container {
                padding: 25px 20px;
            }
            
            .register-header {
                flex-direction: column;
                gap: 15px;
            }
            
            .header-title h1 {
                font-size: 22px;
            }
            
            .header-title p {
                font-size: 12px;
            }
            
            .form-group input,
            .form-group select {
                padding: 10px 12px;
                font-size: 16px;
            }
            
            .btn-register {
                padding: 11px;
                font-size: 14px;
            }
            
            .language-toggle {
                justify-content: center;
                width: 100%;
            }
        }
        
        @media (max-width: 360px) {
            body {
                padding: 10px;
            }
            
            .register-container {
                padding: 20px 15px;
            }
            
            .header-title h1 {
                font-size: 20px;
            }
            
            .language-toggle {
                gap: 5px;
            }
            
            .lang-btn {
                padding: 6px 10px;
                font-size: 11px;
            }
        }
    </style>
</head>
<body>
    <div class="register-container">
        <div class="register-header">
            <div class="header-title">
                <h1>🎓 VJNT</h1>
                <p id="subtitle">Class Management System</p>
            </div>
            <div class="language-toggle">
                <button type="button" class="lang-btn active" onclick="switchLanguage('en')" id="langEnBtn">EN</button>
                <button type="button" class="lang-btn" onclick="switchLanguage('mr')" id="langMrBtn">मराठी</button>
            </div>
        </div>
        
        <% 
            String errorMessage = (String) request.getAttribute("errorMessage");
            String successMessage = (String) request.getAttribute("successMessage");
            
            if (errorMessage != null && !errorMessage.isEmpty()) {
        %>
            <div class="alert alert-error" id="errorAlert">
                <%= errorMessage %>
            </div>
        <% } %>
        
        <% if (successMessage != null && !successMessage.isEmpty()) { %>
            <div class="alert alert-success" id="successAlert">
                <%= successMessage %>
            </div>
        <% } %>
        
        <form method="post" action="<%= request.getContextPath() %>/register" id="registerForm">
            <div class="form-group">
                <label for="firstName" id="lblFirstName">First Name</label>
                <input type="text" id="firstName" name="firstName" 
                       placeholder="Enter your first name" required autofocus>
            </div>
            
            <div class="form-group">
                <label for="lastName" id="lblLastName">Last Name</label>
                <input type="text" id="lastName" name="lastName" 
                       placeholder="Enter your last name" required>
            </div>
            
            <div class="form-group">
                <label for="email" id="lblEmail">Email Address</label>
                <input type="email" id="email" name="email" 
                       placeholder="Enter your email" required>
            </div>
            
            <div class="form-group">
                <label for="username" id="lblUsername">Username</label>
                <input type="text" id="username" name="username" 
                       placeholder="Choose a username" required>
            </div>
            
            <div class="form-group">
                <label for="password" id="lblPassword">Password</label>
                <input type="password" id="password" name="password" 
                       placeholder="Enter a strong password" required>
                <div class="password-requirements" id="pwdReq">
                    <strong id="pwdReqTitle">Password Requirements:</strong>
                    <ul>
                        <li id="pwdReq1">Minimum 8 characters</li>
                        <li id="pwdReq2">At least one uppercase letter</li>
                        <li id="pwdReq3">At least one number</li>
                        <li id="pwdReq4">At least one special character (@, #, $, %, etc.)</li>
                    </ul>
                </div>
            </div>
            
            <div class="form-group">
                <label for="confirmPassword" id="lblConfirmPassword">Confirm Password</label>
                <input type="password" id="confirmPassword" name="confirmPassword" 
                       placeholder="Confirm your password" required>
            </div>
            
            <div class="form-group">
                <label for="userRole" id="lblUserRole">User Role</label>
                <select id="userRole" name="userRole" required>
                    <option value="">Select a role</option>
                    <option value="HEADMASTER" id="roleHeadmaster">Headmaster</option>
                    <option value="TEACHER" id="roleTeacher">Teacher</option>
                    <option value="DISTRICT_ADMIN" id="roleDistrictAdmin">District Admin</option>
                    <option value="DIVISION_ADMIN" id="roleDivisionAdmin">Division Admin</option>
                </select>
            </div>
            
            <button type="submit" class="btn-register" id="btnRegister">Register</button>
        </form>
        
        <div class="login-link">
            <span id="haveAccount">Already have an account?</span>
            <a href="<%= request.getContextPath() %>/login" id="loginLink">Login here</a>
        </div>
    </div>
    
    <script>
        // Language translations
        const translations = {
            en: {
                pageTitle: "Register - VJNT Class Management System",
                subtitle: "Class Management System",
                lblFirstName: "First Name",
                lblLastName: "Last Name",
                lblEmail: "Email Address",
                lblUsername: "Username",
                lblPassword: "Password",
                lblConfirmPassword: "Confirm Password",
                lblUserRole: "User Role",
                roleHeadmaster: "Headmaster",
                roleTeacher: "Teacher",
                roleDistrictAdmin: "District Admin",
                roleDivisionAdmin: "Division Admin",
                btnRegister: "Register",
                haveAccount: "Already have an account?",
                loginLink: "Login here",
                pwdReqTitle: "Password Requirements:",
                pwdReq1: "Minimum 8 characters",
                pwdReq2: "At least one uppercase letter",
                pwdReq3: "At least one number",
                pwdReq4: "At least one special character (@, #, $, %, etc.)",
                plFirstName: "Enter your first name",
                plLastName: "Enter your last name",
                plEmail: "Enter your email",
                plUsername: "Choose a username",
                plPassword: "Enter a strong password",
                plConfirmPassword: "Confirm your password",
                selectRole: "Select a role"
            },
            mr: {
                pageTitle: "नोंदणी - VJNT वर्ग व्यवस्थापन प्रणाली",
                subtitle: "वर्ग व्यवस्थापन प्रणाली",
                lblFirstName: "पहिले नाव",
                lblLastName: "आडनाव",
                lblEmail: "ईमेल पत्ता",
                lblUsername: "वापरकर्ता नाव",
                lblPassword: "पासवर्ड",
                lblConfirmPassword: "पासवर्डची पुष्टी करा",
                lblUserRole: "वापरकर्ता भूमिका",
                roleHeadmaster: "प्रधानाध्यापक",
                roleTeacher: "शिक्षक",
                roleDistrictAdmin: "जिल्हा व्यवस्थापक",
                roleDivisionAdmin: "विभाग व्यवस्थापक",
                btnRegister: "नोंदणी करा",
                haveAccount: "आधीच खाते आहे का?",
                loginLink: "येथे लॉगिन करा",
                pwdReqTitle: "पासवर्ड आवश्यकता:",
                pwdReq1: "किमान 8 वर्ण",
                pwdReq2: "किमान एक मोठे अक्षर",
                pwdReq3: "किमान एक संख्या",
                pwdReq4: "किमान एक विशेष वर्ण (@, #, $, %, इत्यादी)",
                plFirstName: "आपले पहिले नाव प्रविष्ट करा",
                plLastName: "आपली आडनाव प्रविष्ट करा",
                plEmail: "आपला ईमेल प्रविष्ट करा",
                plUsername: "वापरकर्ता नाव निवडा",
                plPassword: "मजबूत पासवर्ड प्रविष्ट करा",
                plConfirmPassword: "आपले पासवर्ड पुष्टी करा",
                selectRole: "भूमिका निवडा"
            }
        };
        
        // Current language
        let currentLanguage = 'en';
        
        // Switch language function
        function switchLanguage(lang) {
            currentLanguage = lang;
            const langEnBtn = document.getElementById('langEnBtn');
            const langMrBtn = document.getElementById('langMrBtn');
            
            // Update button active state
            if (lang === 'en') {
                langEnBtn.classList.add('active');
                langMrBtn.classList.remove('active');
            } else {
                langMrBtn.classList.add('active');
                langEnBtn.classList.remove('active');
            }
            
            // Update all text elements
            const trans = translations[lang];
            
            document.getElementById('pageTitle').textContent = trans.pageTitle;
            document.getElementById('subtitle').textContent = trans.subtitle;
            document.getElementById('lblFirstName').textContent = trans.lblFirstName;
            document.getElementById('lblLastName').textContent = trans.lblLastName;
            document.getElementById('lblEmail').textContent = trans.lblEmail;
            document.getElementById('lblUsername').textContent = trans.lblUsername;
            document.getElementById('lblPassword').textContent = trans.lblPassword;
            document.getElementById('lblConfirmPassword').textContent = trans.lblConfirmPassword;
            document.getElementById('lblUserRole').textContent = trans.lblUserRole;
            document.getElementById('roleHeadmaster').textContent = trans.roleHeadmaster;
            document.getElementById('roleTeacher').textContent = trans.roleTeacher;
            document.getElementById('roleDistrictAdmin').textContent = trans.roleDistrictAdmin;
            document.getElementById('roleDivisionAdmin').textContent = trans.roleDivisionAdmin;
            document.getElementById('btnRegister').textContent = trans.btnRegister;
            document.getElementById('haveAccount').textContent = trans.haveAccount;
            document.getElementById('loginLink').textContent = trans.loginLink;
            document.getElementById('pwdReqTitle').textContent = trans.pwdReqTitle;
            document.getElementById('pwdReq1').textContent = trans.pwdReq1;
            document.getElementById('pwdReq2').textContent = trans.pwdReq2;
            document.getElementById('pwdReq3').textContent = trans.pwdReq3;
            document.getElementById('pwdReq4').textContent = trans.pwdReq4;
            
            // Update placeholders
            document.getElementById('firstName').placeholder = trans.plFirstName;
            document.getElementById('lastName').placeholder = trans.plLastName;
            document.getElementById('email').placeholder = trans.plEmail;
            document.getElementById('username').placeholder = trans.plUsername;
            document.getElementById('password').placeholder = trans.plPassword;
            document.getElementById('confirmPassword').placeholder = trans.plConfirmPassword;
            
            // Update select option
            document.querySelector('option[value=""]').textContent = trans.selectRole;
            
            // Update page direction for Marathi
            if (lang === 'mr') {
                document.documentElement.lang = 'mr';
            } else {
                document.documentElement.lang = 'en';
            }
        }
        
        // Form validation
        document.getElementById('registerForm').addEventListener('submit', function(e) {
            const password = document.getElementById('password').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            
            // Check if passwords match
            if (password !== confirmPassword) {
                e.preventDefault();
                alert(currentLanguage === 'mr' ? 'पासवर्ड मेल खात नाहीत!' : 'Passwords do not match!');
                return false;
            }
            
            // Validate password strength
            const passwordRegex = /^(?=.*[A-Z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,}$/;
            if (!passwordRegex.test(password)) {
                e.preventDefault();
                alert(currentLanguage === 'mr' 
                    ? 'पासवर्ड सर्व आवश्यकता पूरी करणे आवश्यक आहे!' 
                    : 'Password must meet all requirements!');
                return false;
            }
            
            return true;
        });
        
        // Initialize page in English
        switchLanguage('en');
    </script>
</body>
</html>
