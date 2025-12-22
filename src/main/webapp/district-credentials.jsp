<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="java.util.List" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String successMessage = (String) request.getAttribute("successMessage");
    String errorMessage = (String) request.getAttribute("errorMessage");
    List<User> schoolCoordinators = (List<User>) request.getAttribute("schoolCoordinators");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>District Credentials - <%= user.getDistrictName() %></title>
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
            max-width: 1200px;
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
        
        .credentials-card {
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
        
        .credentials-box {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 30px;
            border-radius: 12px;
            margin-bottom: 20px;
            color: white;
        }
        
        .credential-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 15px;
            background: rgba(255,255,255,0.1);
            border-radius: 8px;
            margin-bottom: 15px;
        }
        
        .credential-item:last-child {
            margin-bottom: 0;
        }
        
        .credential-label {
            font-size: 16px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .credential-value {
            font-size: 20px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .copy-button {
            background: rgba(255,255,255,0.2);
            border: 2px solid white;
            color: white;
            padding: 8px 15px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .copy-button:hover {
            background: white;
            color: #667eea;
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
        
        .school-coordinators-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        .school-coordinators-table th {
            background: #667eea;
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 12px;
            letter-spacing: 0.5px;
        }
        
        .school-coordinators-table td {
            padding: 15px;
            border-bottom: 1px solid #e1e8ed;
        }
        
        .school-coordinators-table tr:hover {
            background: #f8f9fa;
        }
        
        .btn-reset {
            background: #28a745;
            color: white;
            padding: 8px 16px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .btn-reset:hover {
            background: #218838;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(40, 167, 69, 0.3);
        }
        
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            overflow: auto;
            background-color: rgba(0,0,0,0.6);
        }
        
        .modal-content {
            background-color: white;
            margin: 5% auto;
            padding: 30px;
            border-radius: 15px;
            width: 90%;
            max-width: 500px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
        }
        
        .modal-header {
            font-size: 24px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 3px solid #667eea;
        }
        
        .close {
            color: #aaa;
            float: right;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
        }
        
        .close:hover,
        .close:focus {
            color: #000;
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
        
        .btn-secondary {
            background: #6c757d;
            color: white;
            padding: 14px 30px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            width: 100%;
            margin-top: 10px;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .btn-secondary:hover {
            background: #5a6268;
        }
        
        .password-warning {
            background: #fff3cd;
            color: #856404;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            border-left: 4px solid #ffc107;
        }
        
        .user-type-badge {
            display: inline-block;
            padding: 4px 10px;
            background: #667eea;
            color: white;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .badge-coordinator {
            background: #28a745;
        }
        
        .badge-headmaster {
            background: #17a2b8;
        }
        
        .info-note {
            background: #e7f3ff;
            color: #004085;
            padding: 15px;
            border-radius: 8px;
            margin-top: 20px;
            border-left: 4px solid #007bff;
        }
        
        .filter-section {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            border: 1px solid #e1e8ed;
        }
        
        .filter-title {
            font-size: 16px;
            font-weight: 600;
            color: #333;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .filter-controls {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        
        .filter-group {
            display: flex;
            flex-direction: column;
        }
        
        .filter-group label {
            font-size: 13px;
            font-weight: 600;
            color: #555;
            margin-bottom: 5px;
        }
        
        .filter-input {
            padding: 10px 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .filter-input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .filter-buttons {
            display: flex;
            gap: 10px;
            margin-top: 15px;
            flex-wrap: wrap;
        }
        
        .btn-filter {
            background: #667eea;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .btn-filter:hover {
            background: #764ba2;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(102, 126, 234, 0.3);
        }
        
        .btn-clear {
            background: #dc3545;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .btn-clear:hover {
            background: #c82333;
        }
        
        .filter-info {
            color: #666;
            font-size: 13px;
            margin-top: 10px;
            padding: 8px 12px;
            background: white;
            border-radius: 6px;
            border-left: 3px solid #667eea;
        }
        
        .no-results {
            text-align: center;
            padding: 40px 20px;
            color: #999;
            font-size: 16px;
        }
        
        @media (max-width: 768px) {
            .header h1 {
                font-size: 24px;
            }
            
            .card-title {
                font-size: 20px;
            }
            
            .school-coordinators-table {
                font-size: 14px;
            }
            
            .school-coordinators-table th,
            .school-coordinators-table td {
                padding: 10px;
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
            <h1>🔐 District Login Credentials & Management</h1>
            <p>View your login credentials and manage school coordinator passwords</p>
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
        
        <!-- District Credentials Card -->
        <div class="credentials-card">
            <h2 class="card-title">
                <span>👤</span> Your District Login Credentials
            </h2>
            
            <div class="password-warning">
                <strong>⚠️ Important:</strong> Keep your credentials secure and do not share them with unauthorized persons. 
                You can change your password anytime from the <a href="<%= request.getContextPath() %>/district-profile" style="color: #667eea; text-decoration: underline;">Profile Page</a>.
            </div>
            
            <div class="credentials-box">
                <div class="credential-item">
                    <span class="credential-label">Username:</span>
                    <span class="credential-value">
                        <span id="username"><%= user.getUsername() %></span>
                        <button class="copy-button" onclick="copyToClipboard('username', this)">📋 Copy</button>
                    </span>
                </div>
                
                <div class="credential-item">
                    <span class="credential-label">Password:</span>
                    <span class="credential-value">
                        <span id="password" style="filter: blur(5px); cursor: pointer;" onclick="togglePasswordVisibility()">
                            ••••••••
                        </span>
                        <button class="copy-button" onclick="showPasswordInfo()">👁️ View</button>
                    </span>
                </div>
                
                <div class="credential-item">
                    <span class="credential-label">District:</span>
                    <span class="credential-value"><%= user.getDistrictName() %></span>
                </div>
                
                <div class="credential-item">
                    <span class="credential-label">User Type:</span>
                    <span class="credential-value">
                        <%= user.getUserType() == User.UserType.DISTRICT_COORDINATOR ? 
                            "District Coordinator" : "District 2nd Coordinator" %>
                    </span>
                </div>
            </div>
            
            <div class="info-note">
                <strong>ℹ️ Note:</strong> For security reasons, your actual password is hidden. 
                You can reset your password from the <strong>Profile Page</strong>. 
                If you've forgotten your password, please contact the system administrator.
            </div>
        </div>
        
        <!-- School Coordinators Password Management -->
        <div class="credentials-card">
            <h2 class="card-title">
                <span>🏫</span> School Coordinators Password Management
            </h2>
            
            <p style="color: #666; margin-bottom: 20px;">
                As a District Coordinator, you can reset passwords for School Coordinators and Head Masters in your district.
            </p>
            
            <!-- Filter Section -->
            <div class="filter-section">
                <div class="filter-title">
                    🔍 Search & Filter
                </div>
                <div class="filter-controls">
                    <div class="filter-group">
                        <label for="searchUsername">🔐 Username</label>
                        <input type="text" 
                               id="searchUsername" 
                               class="filter-input" 
                               placeholder="Search by username..."
                               oninput="applyFilters()">
                    </div>
                    <div class="filter-group">
                        <label for="searchFullName">👤 Full Name</label>
                        <input type="text" 
                               id="searchFullName" 
                               class="filter-input" 
                               placeholder="Search by name..."
                               oninput="applyFilters()">
                    </div>
                    <div class="filter-group">
                        <label for="searchUdise">🏫 UDISE Number</label>
                        <input type="text" 
                               id="searchUdise" 
                               class="filter-input" 
                               placeholder="Search by UDISE..."
                               oninput="applyFilters()">
                    </div>
                    <div class="filter-group">
                        <label for="filterUserType">📋 User Type</label>
                        <select id="filterUserType" 
                                class="filter-input" 
                                onchange="applyFilters()">
                            <option value="">All Types</option>
                            <option value="SCHOOL_COORDINATOR">School Coordinator</option>
                            <option value="HEAD_MASTER">Head Master</option>
                        </select>
                    </div>
                    <div class="filter-group">
                        <label for="filterStatus">✓ Status</label>
                        <select id="filterStatus" 
                                class="filter-input" 
                                onchange="applyFilters()">
                            <option value="">All Status</option>
                            <option value="active">Active</option>
                            <option value="inactive">Inactive</option>
                            <option value="locked">Locked</option>
                        </select>
                    </div>
                </div>
                <div class="filter-buttons">
                    <button class="btn-filter" onclick="applyFilters()">✓ Apply Filters</button>
                    <button class="btn-clear" onclick="clearFilters()">✕ Clear All</button>
                </div>
                <div id="filterInfo" class="filter-info" style="display: none;"></div>
            </div>
            
            <% if (schoolCoordinators != null && !schoolCoordinators.isEmpty()) { %>
                <table class="school-coordinators-table">
                    <thead>
                        <tr>
                            <th>Username</th>
                            <th>Password</th>
                            <th>Full Name</th>
                            <th>User Type</th>
                            <th>School (UDISE)</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (User coordinator : schoolCoordinators) { %>
                            <tr>
                                <td><strong><%= coordinator.getUsername() %></strong></td>
                                <td>
                                    <div style="display: flex; align-items: center; gap: 8px;">
                                        <span style="font-family: monospace; font-weight: bold; color: #28a745;">
                                            <%= coordinator.getPassword() != null ? coordinator.getPassword() : "Pass@123" %>
                                        </span>
                                        <button class="copy-button" 
                                                style="padding: 4px 10px; font-size: 12px;"
                                                onclick="copySchoolCredential('<%= coordinator.getUsername() %>', '<%= coordinator.getPassword() != null ? coordinator.getPassword() : "Pass@123" %>')">
                                            📋
                                        </button>
                                    </div>
                                </td>
                                <td><%= coordinator.getFullName() != null ? coordinator.getFullName() : "N/A" %></td>
                                <td>
                                    <span class="user-type-badge <%= coordinator.getUserType() == User.UserType.SCHOOL_COORDINATOR ? "badge-coordinator" : "badge-headmaster" %>">
                                        <%= coordinator.getUserType() == User.UserType.SCHOOL_COORDINATOR ? "Coordinator" : "Head Master" %>
                                    </span>
                                </td>
                                <td><%= coordinator.getUdiseNo() != null ? coordinator.getUdiseNo() : "N/A" %></td>
                                <td>
                                    <%= coordinator.isActive() ? "✓ Active" : "✗ Inactive" %>
                                    <%= coordinator.isAccountLocked() ? " (🔒 Locked)" : "" %>
                                </td>
                                <td>
                                    <button class="btn-reset" 
                                            onclick="openResetModal('<%= coordinator.getUserId() %>', '<%= coordinator.getUsername() %>', '<%= coordinator.getFullName() != null ? coordinator.getFullName() : coordinator.getUsername() %>')">
                                        Reset Password
                                    </button>
                                </td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            <% } else { %>
                <p style="color: #666; text-align: center; padding: 20px;">
                    No school coordinators found in your district.
                </p>
            <% } %>
        </div>
    </div>
    
    <!-- Reset Password Modal -->
    <div id="resetModal" class="modal">
        <div class="modal-content">
            <span class="close" onclick="closeResetModal()">&times;</span>
            <h2 class="modal-header">Reset School Coordinator Password</h2>
            
            <p id="resetUserInfo" style="color: #666; margin-bottom: 20px;"></p>
            
            <form method="post" action="<%= request.getContextPath() %>/district-credentials" onsubmit="return validateResetForm()">
                <input type="hidden" name="action" value="resetSchoolPassword">
                <input type="hidden" id="resetUserId" name="schoolUserId">
                
                <div class="form-group">
                    <label for="newPassword">New Password *</label>
                    <input type="password" id="newPassword" name="newPassword" required 
                           placeholder="Enter new password (min. 6 characters)">
                </div>
                
                <div class="form-group">
                    <label for="confirmPassword">Confirm New Password *</label>
                    <input type="password" id="confirmPassword" name="confirmPassword" required 
                           placeholder="Re-enter new password">
                </div>
                
                <button type="submit" class="btn-primary">Reset Password</button>
                <button type="button" class="btn-secondary" onclick="closeResetModal()">Cancel</button>
            </form>
        </div>
    </div>
    
    <script>
        function copyToClipboard(elementId, button) {
            const element = document.getElementById(elementId);
            const text = element.textContent;
            
            navigator.clipboard.writeText(text).then(function() {
                const originalText = button.textContent;
                button.textContent = '✓ Copied!';
                button.style.background = 'rgba(40, 167, 69, 0.5)';
                
                setTimeout(function() {
                    button.textContent = originalText;
                    button.style.background = 'rgba(255,255,255,0.2)';
                }, 2000);
            }).catch(function(err) {
                alert('Failed to copy: ' + err);
            });
        }
        
        function showPasswordInfo() {
            alert('For security reasons, your actual password cannot be displayed here.\n\n' +
                  'If you need to reset your password, please visit the Profile Page.\n\n' +
                  'If you have forgotten your password, contact your system administrator.');
        }
        
        function togglePasswordVisibility() {
            showPasswordInfo();
        }
        
        function openResetModal(userId, username, fullName) {
            document.getElementById('resetModal').style.display = 'block';
            document.getElementById('resetUserId').value = userId;
            document.getElementById('resetUserInfo').textContent = 
                'Resetting password for: ' + fullName + ' (' + username + ')';
            
            // Clear form fields
            document.getElementById('newPassword').value = '';
            document.getElementById('confirmPassword').value = '';
        }
        
        function closeResetModal() {
            document.getElementById('resetModal').style.display = 'none';
        }
        
        function validateResetForm() {
            const newPassword = document.getElementById('newPassword').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            
            if (!newPassword || !confirmPassword) {
                alert('All fields are required');
                return false;
            }
            
            if (newPassword.length < 6) {
                alert('Password must be at least 6 characters long');
                return false;
            }
            
            if (newPassword !== confirmPassword) {
                alert('New password and confirm password do not match');
                return false;
            }
            
            return confirm('Are you sure you want to reset this user\'s password?');
        }
        
        // Close modal when clicking outside of it
        window.onclick = function(event) {
            const modal = document.getElementById('resetModal');
            if (event.target == modal) {
                closeResetModal();
            }
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
        }
        
        // Toggle password visibility in School Coordinators table
        function togglePasswordVisibility(userId) {
            const element = document.getElementById('pwd_' + userId);
            if (element.style.filter === 'blur(4px)' || element.style.filter === '') {
                element.style.filter = 'none';
                element.style.color = '#28a745';
                element.style.fontWeight = 'bold';
            } else {
                element.style.filter = 'blur(4px)';
                element.style.color = '';
                element.style.fontWeight = 'bold';
            }
        }
        
        // Copy school coordinator credentials
        function copySchoolCredential(username, password) {
            const text = 'Username: ' + username + '\nPassword: ' + password;
            
            // Use modern clipboard API
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).then(function() {
                    alert('✓ Login credentials copied to clipboard!\n\nUsername: ' + username + '\nPassword: ' + password);
                }).catch(function(err) {
                    // Fallback to old method
                    copySchoolCredentialFallback(text, username, password);
                });
            } else {
                // Fallback for older browsers
                copySchoolCredentialFallback(text, username, password);
            }
        }
        
        // Fallback copy method for older browsers
        function copySchoolCredentialFallback(text, username, password) {
            const textarea = document.createElement('textarea');
            textarea.value = text;
            textarea.style.position = 'fixed';
            textarea.style.opacity = '0';
            document.body.appendChild(textarea);
            textarea.select();
            
            try {
                document.execCommand('copy');
                alert('✓ Login credentials copied to clipboard!\n\nUsername: ' + username + '\nPassword: ' + password);
            } catch (err) {
                alert('Unable to copy automatically. Please copy manually:\n\n' + text);
            }
            
            document.body.removeChild(textarea);
        }
        
        // Filter functionality for School Coordinators table
        let allRows = [];
        
        // Initialize on page load
        document.addEventListener('DOMContentLoaded', function() {
            const table = document.querySelector('.school-coordinators-table tbody');
            if (table) {
                allRows = Array.from(table.querySelectorAll('tr'));
            }
        });
        
        // Apply all filters
        function applyFilters() {
            const searchUsername = document.getElementById('searchUsername').value.toLowerCase().trim();
            const searchFullName = document.getElementById('searchFullName').value.toLowerCase().trim();
            const searchUdise = document.getElementById('searchUdise').value.toLowerCase().trim();
            const filterUserType = document.getElementById('filterUserType').value;
            const filterStatus = document.getElementById('filterStatus').value;
            
            let visibleCount = 0;
            let totalCount = allRows.length;
            
            allRows.forEach(row => {
                const username = row.cells[0].textContent.toLowerCase();
                const password = row.cells[1].textContent.toLowerCase();
                const fullName = row.cells[2].textContent.toLowerCase();
                const userTypeBadge = row.cells[3].querySelector('.user-type-badge');
                const userTypeText = userTypeBadge ? userTypeBadge.textContent.toLowerCase() : '';
                const udise = row.cells[4].textContent.toLowerCase();
                const status = row.cells[5].textContent.toLowerCase();
                
                // Check username filter
                const matchUsername = !searchUsername || username.includes(searchUsername);
                
                // Check full name filter
                const matchFullName = !searchFullName || fullName.includes(searchFullName);
                
                // Check UDISE filter
                const matchUdise = !searchUdise || udise.includes(searchUdise);
                
                // Check user type filter
                let matchUserType = true;
                if (filterUserType) {
                    if (filterUserType === 'SCHOOL_COORDINATOR') {
                        matchUserType = userTypeText.includes('coordinator') && !userTypeText.includes('master');
                    } else if (filterUserType === 'HEAD_MASTER') {
                        matchUserType = userTypeText.includes('master');
                    }
                }
                
                // Check status filter
                let matchStatus = true;
                if (filterStatus) {
                    if (filterStatus === 'active') {
                        matchStatus = status.includes('✓ active') && !status.includes('locked');
                    } else if (filterStatus === 'inactive') {
                        matchStatus = status.includes('✗ inactive');
                    } else if (filterStatus === 'locked') {
                        matchStatus = status.includes('locked');
                    }
                }
                
                // Show/hide row based on all filters
                const shouldShow = matchUsername && matchFullName && matchUdise && matchUserType && matchStatus;
                
                if (shouldShow) {
                    row.style.display = '';
                    visibleCount++;
                } else {
                    row.style.display = 'none';
                }
            });
            
            // Update filter info
            const filterInfo = document.getElementById('filterInfo');
            if (searchUsername || searchFullName || searchUdise || filterUserType || filterStatus) {
                filterInfo.style.display = 'block';
                filterInfo.innerHTML = `<strong>Filter Results:</strong> Showing ${visibleCount} of ${totalCount} school coordinators`;
                
                if (visibleCount === 0) {
                    filterInfo.innerHTML += '<br><span style="color: #dc3545;">No results found. Try adjusting your filters.</span>';
                }
            } else {
                filterInfo.style.display = 'none';
            }
        }
        
        // Clear all filters
        function clearFilters() {
            document.getElementById('searchUsername').value = '';
            document.getElementById('searchFullName').value = '';
            document.getElementById('searchUdise').value = '';
            document.getElementById('filterUserType').value = '';
            document.getElementById('filterStatus').value = '';
            
            // Show all rows
            allRows.forEach(row => {
                row.style.display = '';
            });
            
            // Hide filter info
            document.getElementById('filterInfo').style.display = 'none';
        }
    </script>
</body>
</html>
