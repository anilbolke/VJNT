<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.dao.UserDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String districtName = user.getDistrictName();
    SchoolDAO schoolDAO = new SchoolDAO();
    UserDAO userDAO = new UserDAO();
    
    // Get schools for this district
    List<School> schools = schoolDAO.getSchoolsByDistrict(districtName);
    
    // Get existing school users for this district
    List<User> schoolUsers = userDAO.getSchoolUsersByDistrict(districtName);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>School Users Directory - VJNT</title>
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
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .header h1 {
            font-size: 26px;
            margin: 0;
        }
        
        .header-subtitle {
            font-size: 14px;
            opacity: 0.9;
            margin-top: 5px;
        }
        
        .btn {
            padding: 10px 20px;
            border-radius: 6px;
            text-decoration: none;
            font-weight: 500;
            transition: all 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            border: none;
            font-size: 14px;
        }
        
        .btn-back {
            background: rgba(255,255,255,0.2);
            color: white;
            border: 1px solid rgba(255,255,255,0.3);
        }
        
        .btn-back:hover {
            background: rgba(255,255,255,0.3);
        }
        
        .btn-primary {
            background: #4caf50;
            color: white;
        }
        
        .btn-primary:hover {
            background: #45a049;
            transform: translateY(-2px);
        }
        
        .btn-edit {
            background: #2196f3;
            color: white;
            padding: 6px 12px;
            font-size: 12px;
        }
        
        .btn-edit:hover {
            background: #1976d2;
        }
        
        .btn-delete {
            background: #f44336;
            color: white;
            padding: 6px 12px;
            font-size: 12px;
        }
        
        .btn-delete:hover {
            background: #d32f2f;
        }
        
        .content {
            padding: 30px;
        }
        
        .section {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 25px;
        }
        
        .section-title {
            font-size: 20px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 3px solid #667eea;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .form-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .form-group {
            display: flex;
            flex-direction: column;
        }
        
        .form-group label {
            font-weight: 600;
            color: #333;
            margin-bottom: 8px;
            font-size: 14px;
        }
        
        .form-group label .required {
            color: #f44336;
            margin-left: 3px;
        }
        
        .form-group input,
        .form-group select,
        .form-group textarea {
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            font-size: 14px;
            transition: border-color 0.3s;
            font-family: inherit;
        }
        
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .form-group textarea {
            resize: vertical;
            min-height: 80px;
        }
        
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: none;
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
        
        .table-container {
            overflow-x: auto;
            margin-top: 20px;
        }
        
        .table {
            width: 100%;
            border-collapse: collapse;
            background: white;
        }
        
        .table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .table th,
        .table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e0e0e0;
            font-size: 13px;
        }
        
        .table th {
            font-weight: 600;
        }
        
        .table tbody tr:hover {
            background: #f5f5f5;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
        }
        
        .badge-coordinator {
            background: #e3f2fd;
            color: #1976d2;
        }
        
        .badge-headmaster {
            background: #f3e5f5;
            color: #7b1fa2;
        }
        
        .badge-active {
            background: #c8e6c9;
            color: #2e7d32;
        }
        
        .badge-inactive {
            background: #ffcdd2;
            color: #c62828;
        }
        
        .action-buttons {
            display: flex;
            gap: 8px;
        }
        
        .loading {
            display: none;
            text-align: center;
            padding: 20px;
            color: #666;
        }
        
        .loading.active {
            display: block;
        }
        
        @media (max-width: 768px) {
            .form-grid {
                grid-template-columns: 1fr;
            }
            
            .header {
                flex-direction: column;
                align-items: stretch;
            }
            
            .action-buttons {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div>
                <h1>👥 Manage School Users</h1>
                <div class="header-subtitle">Add/Modify School Coordinators and Head Masters - <%= districtName %></div>
            </div>
            <a href="<%= request.getContextPath() %>/district-dashboard.jsp" class="btn btn-back">
                <span>🏠</span>
                <span>Back to Dashboard</span>
            </a>
        </div>
        
        <!-- Content -->
        <div class="content">
            <!-- Alert Messages -->
            <div id="alertSuccess" class="alert alert-success"></div>
            <div id="alertError" class="alert alert-error"></div>
            
            <!-- Add/Edit Form -->
            <div class="section">
                <h2 class="section-title">
                    <span>➕</span>
                    <span id="formTitle">Add New School User</span>
                </h2>
                
                <form id="userForm">
                    <input type="hidden" id="userId" name="userId">
                    <input type="hidden" id="formMode" value="add">
                    
                    <div class="form-grid">
                        <!-- School Selection -->
                        <div class="form-group">
                            <label for="udiseNo">
                                School (UDISE) <span class="required">*</span>
                            </label>
                            <select id="udiseNo" name="udiseNo" required>
                                <option value="">-- Select School --</option>
                                <% for (School school : schools) { %>
                                    <option value="<%= school.getUdiseNo() %>">
                                        <%= school.getUdiseNo() %> - <%= school.getSchoolName() %>
                                    </option>
                                <% } %>
                            </select>
                        </div>
                        
                        <!-- User Type Selection -->
                        <div class="form-group">
                            <label for="userType">
                                User Type <span class="required">*</span>
                            </label>
                            <select id="userType" name="userType" required>
                                <option value="">-- Select User Type --</option>
                                <option value="SCHOOL_COORDINATOR">School Coordinator</option>
                                <option value="HEAD_MASTER">Head Master</option>
                            </select>
                        </div>
                        
                        <!-- Full Name -->
                        <div class="form-group">
                            <label for="fullName">
                                Full Name <span class="required">*</span>
                            </label>
                            <input type="text" id="fullName" name="fullName" placeholder="Enter full name" required>
                        </div>
                        
                        <!-- Username -->
                        <div class="form-group">
                            <label for="username">
                                Username <span class="required">*</span>
                            </label>
                            <input type="text" id="username" name="username" placeholder="Enter username" required>
                        </div>
                        
                        <!-- Mobile Number -->
                        <div class="form-group">
                            <label for="mobile">
                                Mobile Number <span class="required">*</span>
                            </label>
                            <input type="tel" id="mobile" name="mobile" placeholder="Enter mobile number" pattern="[0-9]{10}" required>
                        </div>
                        
                        <!-- WhatsApp Number -->
                        <div class="form-group">
                            <label for="whatsapp">
                                WhatsApp Number
                            </label>
                            <input type="tel" id="whatsapp" name="whatsapp" placeholder="Enter WhatsApp number" pattern="[0-9]{10}">
                        </div>
                        
                        <!-- Email -->
                        <div class="form-group">
                            <label for="email">
                                Email
                            </label>
                            <input type="email" id="email" name="email" placeholder="Enter email address">
                        </div>
                        
                        <!-- Password (for new users) -->
                        <div class="form-group" id="passwordGroup">
                            <label for="password">
                                Password <span class="required">*</span>
                            </label>
                            <input type="password" id="password" name="password" placeholder="Enter password" minlength="6">
                        </div>
                    </div>
                    
                    <!-- Remarks -->
                    <div class="form-group">
                        <label for="remarks">
                            Remarks
                        </label>
                        <textarea id="remarks" name="remarks" placeholder="Enter any additional remarks or notes..."></textarea>
                    </div>
                    
                    <!-- Form Actions -->
                    <div style="display: flex; gap: 15px; margin-top: 25px;">
                        <button type="submit" class="btn btn-primary">
                            <span>💾</span>
                            <span id="submitBtnText">Save User</span>
                        </button>
                        <button type="button" class="btn btn-back" onclick="resetForm()" style="background: #9e9e9e;">
                            <span>🔄</span>
                            <span>Reset Form</span>
                        </button>
                    </div>
                </form>
            </div>
            
            <!-- Existing Users List -->
            <div class="section">
                <h2 class="section-title">
                    <span>📋</span>
                    <span>Existing School Users (<%= schoolUsers.size() %>)</span>
                </h2>
                
                <div class="loading" id="loadingUsers">
                    <div>⏳ Loading users...</div>
                </div>
                
                <div class="table-container">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Sr No</th>
                                <th>School (UDISE)</th>
                                <th>User Type</th>
                                <th>Full Name</th>
                                <th>Username</th>
                                <th>Mobile</th>
                                <th>WhatsApp</th>
                                <th>Email</th>
                                <th>Status</th>
                                <th>Remarks</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="userTableBody">
                            <% 
                            int srNo = 1;
                            for (User u : schoolUsers) { 
                            %>
                            <tr>
                                <td><%= srNo++ %></td>
                                <td><strong><%= u.getUdiseNo() %></strong></td>
                                <td>
                                    <span class="badge <%= u.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) ? "badge-coordinator" : "badge-headmaster" %>">
                                        <%= u.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) ? "Coordinator" : "Head Master" %>
                                    </span>
                                </td>
                                <td><strong><%= u.getFullName() != null ? u.getFullName() : "-" %></strong></td>
                                <td><%= u.getUsername() %></td>
                                <td><%= u.getMobile() != null ? u.getMobile() : "-" %></td>
                                <td><%= u.getWhatsappNumber() != null ? u.getWhatsappNumber() : "-" %></td>
                                <td><%= u.getEmail() != null ? u.getEmail() : "-" %></td>
                                <td>
                                    <span class="badge <%= u.isActive() ? "badge-active" : "badge-inactive" %>">
                                        <%= u.isActive() ? "Active" : "Inactive" %>
                                    </span>
                                </td>
                                <td><%= u.getRemarks() != null ? u.getRemarks() : "-" %></td>
                                <td>
                                    <div class="action-buttons">
                                        <button class="btn btn-edit" onclick="editUser(<%= u.getUserId() %>)">
                                            ✏️ Edit
                                        </button>
                                        <button class="btn btn-delete" onclick="deleteUser(<%= u.getUserId() %>, '<%= u.getUsername() %>')">
                                            🗑️ Delete
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                            <% if (schoolUsers.isEmpty()) { %>
                            <tr>
                                <td colspan="11" style="text-align: center; padding: 30px; color: #999;">
                                    No school users found. Add your first user above.
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Form submission
        document.getElementById('userForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new FormData(this);
            const mode = document.getElementById('formMode').value;
            const districtName = '<%= districtName %>';
            const divisionName = '<%= user.getDivisionName() %>';
            
            formData.append('districtName', districtName);
            formData.append('divisionName', divisionName);
            formData.append('mode', mode);
            
            fetch('<%= request.getContextPath() %>/manage-school-user', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showAlert('success', data.message);
                    resetForm();
                    setTimeout(() => location.reload(), 1500);
                } else {
                    showAlert('error', data.message);
                }
            })
            .catch(error => {
                showAlert('error', 'Error: ' + error.message);
            });
        });
        
        // Edit user
        function editUser(userId) {
            fetch('<%= request.getContextPath() %>/get-user?userId=' + userId)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const user = data.user;
                        
                        document.getElementById('userId').value = user.userId;
                        document.getElementById('formMode').value = 'edit';
                        document.getElementById('udiseNo').value = user.udiseNo;
                        document.getElementById('userType').value = user.userType;
                        document.getElementById('fullName').value = user.fullName || '';
                        document.getElementById('username').value = user.username;
                        document.getElementById('mobile').value = user.mobile || '';
                        document.getElementById('whatsapp').value = user.whatsappNumber || '';
                        document.getElementById('email').value = user.email || '';
                        document.getElementById('remarks').value = user.remarks || '';
                        
                        // Hide password field when editing
                        document.getElementById('passwordGroup').style.display = 'none';
                        document.getElementById('password').removeAttribute('required');
                        
                        document.getElementById('formTitle').textContent = 'Edit School User';
                        document.getElementById('submitBtnText').textContent = 'Update User';
                        
                        // Scroll to form
                        document.getElementById('userForm').scrollIntoView({ behavior: 'smooth' });
                    }
                })
                .catch(error => {
                    showAlert('error', 'Error loading user data: ' + error.message);
                });
        }
        
        // Delete user
        function deleteUser(userId, username) {
            if (!confirm('Are you sure you want to delete user "' + username + '"?')) {
                return;
            }
            
            fetch('<%= request.getContextPath() %>/manage-school-user?action=delete&userId=' + userId, {
                method: 'POST'
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showAlert('success', data.message);
                    setTimeout(() => location.reload(), 1500);
                } else {
                    showAlert('error', data.message);
                }
            })
            .catch(error => {
                showAlert('error', 'Error: ' + error.message);
            });
        }
        
        // Reset form
        function resetForm() {
            document.getElementById('userForm').reset();
            document.getElementById('userId').value = '';
            document.getElementById('formMode').value = 'add';
            document.getElementById('passwordGroup').style.display = 'block';
            document.getElementById('password').setAttribute('required', 'required');
            document.getElementById('formTitle').textContent = 'Add New School User';
            document.getElementById('submitBtnText').textContent = 'Save User';
            hideAlerts();
        }
        
        // Show alert
        function showAlert(type, message) {
            hideAlerts();
            const alertId = type === 'success' ? 'alertSuccess' : 'alertError';
            const alertEl = document.getElementById(alertId);
            alertEl.textContent = message;
            alertEl.style.display = 'block';
            
            // Auto hide after 5 seconds
            setTimeout(() => {
                alertEl.style.display = 'none';
            }, 5000);
        }
        
        // Hide all alerts
        function hideAlerts() {
            document.getElementById('alertSuccess').style.display = 'none';
            document.getElementById('alertError').style.display = 'none';
        }
        
        // Auto-fill WhatsApp with mobile number if empty
        document.getElementById('mobile').addEventListener('blur', function() {
            const whatsapp = document.getElementById('whatsapp');
            if (!whatsapp.value && this.value) {
                whatsapp.value = this.value;
            }
        });
    </script>
</body>
</html>
