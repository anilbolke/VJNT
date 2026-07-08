<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String successMessage = (String) request.getAttribute("successMessage");
    String errorMessage = (String) request.getAttribute("errorMessage");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>District Profile - <%= user.getDistrictName() %></title>
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
            padding: 20px;
        }
        
        .container {
            max-width: 900px;
            margin: 0 auto;
        }
        
        .header {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
            margin-bottom: 25px;
            text-align: center;
        }
        
        .header h1 {
            color: #667eea;
            font-size: 32px;
            margin-bottom: 10px;
        }
        
        .header p {
            color: #666;
            font-size: 16px;
        }
        
        .back-button {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 10px 20px;
            border-radius: 8px;
            text-decoration: none;
            margin-bottom: 20px;
            transition: background 0.3s;
            font-weight: 600;
        }
        
        .back-button:hover {
            background: #764ba2;
        }
        
        .profile-card {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
            margin-bottom: 25px;
        }
        
        .card-title {
            font-size: 24px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 3px solid #667eea;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .card-title i {
            color: #667eea;
        }
        
        .profile-info {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .info-item {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        
        .info-label {
            font-size: 14px;
            color: #666;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .info-value {
            font-size: 18px;
            color: #333;
            font-weight: 500;
            padding: 12px;
            background: #f8f9fa;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        
        .password-reset-form {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: 600;
            font-size: 14px;
        }
        
        .form-group input {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e1e8ed;
            border-radius: 8px;
            font-size: 16px;
            transition: all 0.3s;
        }
        
        .form-group input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .password-requirements {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            border-left: 4px solid #667eea;
        }
        
        .password-requirements h4 {
            color: #333;
            margin-bottom: 10px;
            font-size: 14px;
        }
        
        .password-requirements ul {
            margin-left: 20px;
            color: #666;
            font-size: 13px;
        }
        
        .password-requirements li {
            margin-bottom: 5px;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 14px 30px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            width: 100%;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        
        .btn-primary:active {
            transform: translateY(0);
        }
        
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
            font-weight: 500;
        }
        
        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .alert-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .alert-icon {
            font-size: 20px;
        }
        
        .user-type-badge {
            display: inline-block;
            padding: 6px 12px;
            background: #667eea;
            color: white;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .toggle-password {
            position: absolute;
            right: 15px;
            top: 50%;
            transform: translateY(-50%);
            cursor: pointer;
            color: #666;
            font-size: 18px;
        }
        
        .input-wrapper {
            position: relative;
        }
        
        @media (max-width: 768px) {
            .profile-info {
                grid-template-columns: 1fr;
            }
            
            .header h1 {
                font-size: 24px;
            }
            
            .card-title {
                font-size: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <a href="<%= request.getContextPath() %>/district-dashboard.jsp" class="back-button">
            ← Back to Dashboard
        </a>
        
        <div class="header">
            <h1>🔐 District Profile & Security</h1>
            <p>View your profile information and manage your password</p>
        </div>
        
        <% if (successMessage != null && !successMessage.isEmpty()) { %>
            <div class="alert alert-success">
                <span class="alert-icon">✓</span>
                <span><%= successMessage %></span>
            </div>
        <% } %>
        
        <% if (errorMessage != null && !errorMessage.isEmpty()) { %>
            <div class="alert alert-error">
                <span class="alert-icon">✗</span>
                <span><%= errorMessage %></span>
            </div>
        <% } %>
        
        <!-- Profile Information Card -->
        <div class="profile-card">
            <h2 class="card-title">
                <span>👤</span> Profile Information
            </h2>
            
            <div class="profile-info">
                <div class="info-item">
                    <span class="info-label">Username</span>
                    <span class="info-value"><%= user.getUsername() %></span>
                </div>
                
                <div class="info-item">
                    <span class="info-label">User Type</span>
                    <span class="info-value">
                        <span class="user-type-badge">
                            <%= user.getUserType() == User.UserType.DISTRICT_COORDINATOR ? 
                                "District Coordinator" : "District 2nd Coordinator" %>
                        </span>
                    </span>
                </div>
                
                <div class="info-item">
                    <span class="info-label">District Name</span>
                    <span class="info-value"><%= user.getDistrictName() != null ? user.getDistrictName() : "N/A" %></span>
                </div>
                
                <div class="info-item">
                    <span class="info-label">Division Name</span>
                    <span class="info-value"><%= user.getDivisionName() != null ? user.getDivisionName() : "N/A" %></span>
                </div>
                
                <% if (user.getFullName() != null && !user.getFullName().isEmpty()) { %>
                <div class="info-item">
                    <span class="info-label">Full Name</span>
                    <span class="info-value"><%= user.getFullName() %></span>
                </div>
                <% } %>
                
                <% if (user.getMobile() != null && !user.getMobile().isEmpty()) { %>
                <div class="info-item">
                    <span class="info-label">Mobile Number</span>
                    <span class="info-value"><%= user.getMobile() %></span>
                </div>
                <% } %>
                
                <% if (user.getEmail() != null && !user.getEmail().isEmpty()) { %>
                <div class="info-item">
                    <span class="info-label">Email Address</span>
                    <span class="info-value"><%= user.getEmail() %></span>
                </div>
                <% } %>
                
                <% if (user.getWhatsappNumber() != null && !user.getWhatsappNumber().isEmpty()) { %>
                <div class="info-item">
                    <span class="info-label">WhatsApp Number</span>
                    <span class="info-value"><%= user.getWhatsappNumber() %></span>
                </div>
                <% } %>
                
                <div class="info-item">
                    <span class="info-label">Account Status</span>
                    <span class="info-value">
                        <%= user.isActive() ? "✓ Active" : "✗ Inactive" %>
                    </span>
                </div>
                
                <% if (user.getLastLoginDate() != null) { %>
                <div class="info-item">
                    <span class="info-label">Last Login</span>
                    <span class="info-value"><%= user.getLastLoginDate() %></span>
                </div>
                <% } %>
            </div>
        </div>
        
        <!-- Password Reset Form -->
        <div class="password-reset-form">
            <h2 class="card-title">
                <span>🔑</span> Reset Password
            </h2>
            
            <div class="password-requirements">
                <h4>Password Requirements:</h4>
                <ul>
                    <li>At least 8 characters long</li>
                    <li>Contains at least one uppercase letter (A-Z)</li>
                    <li>Contains at least one lowercase letter (a-z)</li>
                    <li>Contains at least one digit (0-9)</li>
                    <li>Contains at least one special character (!@#$%^&*)</li>
                    <li>Must be different from your current password</li>
                </ul>
            </div>
            
            <form method="post" action="<%= request.getContextPath() %>/district-profile" onsubmit="return validateForm()">
                <input type="hidden" name="action" value="resetPassword">
                
                <div class="form-group">
                    <label for="currentPassword">Current Password *</label>
                    <div class="input-wrapper">
                        <input type="password" id="currentPassword" name="currentPassword" required>
                        <span class="toggle-password" onclick="togglePassword('currentPassword')">👁️</span>
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="newPassword">New Password *</label>
                    <div class="input-wrapper">
                        <input type="password" id="newPassword" name="newPassword" required>
                        <span class="toggle-password" onclick="togglePassword('newPassword')">👁️</span>
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="confirmPassword">Confirm New Password *</label>
                    <div class="input-wrapper">
                        <input type="password" id="confirmPassword" name="confirmPassword" required>
                        <span class="toggle-password" onclick="togglePassword('confirmPassword')">👁️</span>
                    </div>
                </div>
                
                <button type="submit" class="btn-primary">Reset Password</button>
            </form>
        </div>
    </div>
    
    <script>
        function togglePassword(fieldId) {
            const field = document.getElementById(fieldId);
            if (field.type === 'password') {
                field.type = 'text';
            } else {
                field.type = 'password';
            }
        }
        
        function validateForm() {
            const currentPassword = document.getElementById('currentPassword').value;
            const newPassword = document.getElementById('newPassword').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            
            if (!currentPassword || !newPassword || !confirmPassword) {
                alert('All fields are required');
                return false;
            }
            
            if (newPassword !== confirmPassword) {
                alert('New password and confirm password do not match');
                return false;
            }
            
            if (currentPassword === newPassword) {
                alert('New password must be different from current password');
                return false;
            }
            
            // Validate password strength
            const minLength = 8;
            const hasUpperCase = /[A-Z]/.test(newPassword);
            const hasLowerCase = /[a-z]/.test(newPassword);
            const hasDigit = /\d/.test(newPassword);
            const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(newPassword);
            
            if (newPassword.length < minLength) {
                alert('Password must be at least 8 characters long');
                return false;
            }
            
            if (!hasUpperCase) {
                alert('Password must contain at least one uppercase letter');
                return false;
            }
            
            if (!hasLowerCase) {
                alert('Password must contain at least one lowercase letter');
                return false;
            }
            
            if (!hasDigit) {
                alert('Password must contain at least one digit');
                return false;
            }
            
            if (!hasSpecialChar) {
                alert('Password must contain at least one special character');
                return false;
            }
            
            return true;
        }
        
        // Auto-hide success message after 5 seconds
        window.onload = function() {
            const successAlert = document.querySelector('.alert-success');
            if (successAlert) {
                setTimeout(() => {
                    successAlert.style.transition = 'opacity 0.5s';
                    successAlert.style.opacity = '0';
                    setTimeout(() => successAlert.remove(), 500);
                }, 5000);
            }
        };
    </script>
</body>
</html>
