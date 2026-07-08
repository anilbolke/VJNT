<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    // Only DATA_ADMIN and SUPER_DIVISION_OFFICER can manage Super Officers
    if (!user.getUserType().equals(User.UserType.DATA_ADMIN) &&
        !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER)) {
        response.sendRedirect("unauthorized.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Super Division Officers - VJNT</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body {
            background: #f5f7fa;
            padding-top: 20px;
        }
        .page-header {
            background: white;
            padding: 25px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        .page-header h2 {
            color: #333;
            margin: 0;
        }
        .btn-create {
            background: #667eea;
            border: none;
            color: white;
            padding: 10px 25px;
            border-radius: 5px;
            cursor: pointer;
            float: right;
        }
        .btn-create:hover {
            background: #5568d3;
            color: white;
            text-decoration: none;
        }
        .table-container {
            background: white;
            padding: 25px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        table {
            margin-bottom: 0;
        }
        .action-btn {
            padding: 5px 10px;
            margin: 0 2px;
            font-size: 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            transition: all 0.2s;
        }
        .btn-edit {
            background: #4CAF50;
            color: white;
        }
        .btn-edit:hover {
            background: #45a049;
        }
        .btn-deactivate {
            background: #f44336;
            color: white;
        }
        .btn-deactivate:hover {
            background: #da190b;
        }
        .status-active {
            color: #4CAF50;
            font-weight: bold;
        }
        .status-inactive {
            color: #f44336;
            font-weight: bold;
        }
        .modal {
            display: none;
        }
        .modal.show {
            display: block;
            background-color: rgba(0,0,0,0.5);
        }
        .modal-content {
            background: white;
            padding: 25px;
            border-radius: 8px;
            max-width: 500px;
            margin: 50px auto;
        }
        .close-btn {
            background: none;
            border: none;
            font-size: 25px;
            cursor: pointer;
            float: right;
            color: #999;
        }
        .form-group {
            margin-bottom: 15px;
        }
        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #333;
        }
        .form-group input {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
        }
        .form-group input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 5px rgba(102, 126, 234, 0.1);
        }
        .btn-submit {
            background: #667eea;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            width: 100%;
            margin-top: 10px;
        }
        .btn-submit:hover {
            background: #5568d3;
        }
        .alert {
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 4px;
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
        .empty-state {
            text-align: center;
            padding: 50px;
            color: #999;
        }
        .empty-state i {
            font-size: 48px;
            color: #ddd;
            margin-bottom: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="page-header">
            <button class="btn-create" onclick="showCreateModal()"><i class="fas fa-plus"></i> Create New Officer</button>
            <h2><i class="fas fa-users-cog"></i> Manage Super Division Officers</h2>
            <p class="text-muted">Create, edit, and manage Super Division Officer accounts</p>
        </div>

        <!-- Alert Messages -->
        <div id="alert-container"></div>

        <!-- Officers Table -->
        <div class="table-container">
            <h5>Super Division Officers</h5>
            <hr>
            <div id="officers-list">
                <div class="text-center" style="padding: 30px;">
                    <i class="fas fa-spinner fa-spin"></i> Loading officers...
                </div>
            </div>
        </div>
    </div>

    <!-- Create/Edit Modal -->
    <div id="modal" class="modal">
        <div class="modal-content">
            <button class="close-btn" onclick="closeModal()">&times;</button>
            <h4 id="modal-title">Create New Officer</h4>
            <form id="officer-form">
                <input type="hidden" id="userId">
                <input type="hidden" id="action" value="create">
                
                <div class="form-group">
                    <label for="username">Username <span style="color: red;">*</span></label>
                    <input type="text" id="username" placeholder="Enter username" required>
                </div>
                
                <div class="form-group">
                    <label for="password">Password <span style="color: red;">*</span></label>
                    <input type="password" id="password" placeholder="Enter password" required>
                </div>
                
                <div class="form-group">
                    <label for="fullName">Full Name <span style="color: red;">*</span></label>
                    <input type="text" id="fullName" placeholder="Enter full name" required>
                </div>
                
                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" placeholder="Enter email address">
                </div>
                
                <div class="form-group">
                    <label for="mobile">Mobile</label>
                    <input type="tel" id="mobile" placeholder="Enter mobile number">
                </div>
                
                <button type="submit" class="btn-submit">Save Officer</button>
            </form>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Load officers on page load
        document.addEventListener('DOMContentLoaded', function() {
            loadOfficers();
            document.getElementById('officer-form').addEventListener('submit', saveOfficer);
        });

        function loadOfficers() {
            fetch('manage-super-officers?action=list')
                .then(response => response.json())
                .then(data => {
                    displayOfficers(data);
                })
                .catch(error => {
                    console.error('Error:', error);
                    showAlert('Error loading officers', 'error');
                });
        }

        function displayOfficers(data) {
            const container = document.getElementById('officers-list');
            
            if (!data.success) {
                container.innerHTML = `<div class="alert alert-error">${data.message}</div>`;
                return;
            }
            
            if (data.count === 0) {
                container.innerHTML = `
                    <div class="empty-state">
                        <i class="fas fa-user-slash"></i>
                        <p>No Super Division Officers found</p>
                    </div>
                `;
                return;
            }
            
            let html = `
                <table class="table table-hover">
                    <thead>
                        <tr style="border-bottom: 2px solid #667eea;">
                            <th>Username</th>
                            <th>Full Name</th>
                            <th>Email</th>
                            <th>Mobile</th>
                            <th>Status</th>
                            <th>Last Login</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
            `;
            
            data.officers.forEach(officer => {
                const status = officer.isActive ? '<span class="status-active">Active</span>' : '<span class="status-inactive">Inactive</span>';
                const lastLogin = officer.lastLoginDate ? new Date(officer.lastLoginDate).toLocaleDateString() : 'Never';
                
                html += `
                    <tr>
                        <td><strong>${officer.username}</strong></td>
                        <td>${officer.fullName}</td>
                        <td>${officer.email || '-'}</td>
                        <td>${officer.mobile || '-'}</td>
                        <td>${status}</td>
                        <td>${lastLogin}</td>
                        <td>
                            <button class="action-btn btn-edit" onclick="editOfficer(${officer.userId})">
                                <i class="fas fa-edit"></i> Edit
                            </button>
                            <button class="action-btn btn-deactivate" onclick="deactivateOfficer(${officer.userId})">
                                <i class="fas fa-ban"></i> Deactivate
                            </button>
                        </td>
                    </tr>
                `;
            });
            
            html += `
                    </tbody>
                </table>
            `;
            
            container.innerHTML = html;
        }

        function showCreateModal() {
            document.getElementById('modal-title').textContent = 'Create New Officer';
            document.getElementById('action').value = 'create';
            document.getElementById('officer-form').reset();
            document.getElementById('password').style.display = 'block';
            document.getElementById('modal').classList.add('show');
        }

        function editOfficer(userId) {
            // This would fetch officer details and populate the form
            document.getElementById('modal-title').textContent = 'Edit Officer';
            document.getElementById('action').value = 'update';
            document.getElementById('userId').value = userId;
            document.getElementById('password').style.display = 'none'; // Don't show password when editing
            document.getElementById('modal').classList.add('show');
        }

        function closeModal() {
            document.getElementById('modal').classList.remove('show');
        }

        function saveOfficer(e) {
            e.preventDefault();
            
            const action = document.getElementById('action').value;
            const formData = new FormData();
            formData.append('action', action);
            formData.append('username', document.getElementById('username').value);
            formData.append('password', document.getElementById('password').value);
            formData.append('fullName', document.getElementById('fullName').value);
            formData.append('email', document.getElementById('email').value);
            formData.append('mobile', document.getElementById('mobile').value);
            
            if (action === 'update') {
                formData.append('userId', document.getElementById('userId').value);
            }
            
            fetch('manage-super-officers', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showAlert(data.message, 'success');
                    closeModal();
                    loadOfficers();
                } else {
                    showAlert(data.message, 'error');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                showAlert('Error saving officer', 'error');
            });
        }

        function deactivateOfficer(userId) {
            if (confirm('Are you sure you want to deactivate this officer?')) {
                const formData = new FormData();
                formData.append('action', 'deactivate');
                formData.append('userId', userId);
                
                fetch('manage-super-officers', {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showAlert(data.message, 'success');
                        loadOfficers();
                    } else {
                        showAlert(data.message, 'error');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    showAlert('Error deactivating officer', 'error');
                });
            }
        }

        function showAlert(message, type) {
            const container = document.getElementById('alert-container');
            const alertClass = type === 'success' ? 'alert-success' : 'alert-error';
            container.innerHTML = `<div class="alert ${alertClass}"><i class="fas fa-${type === 'success' ? 'check-circle' : 'exclamation-circle'}"></i> ${message}</div>`;
            
            setTimeout(() => {
                container.innerHTML = '';
            }, 5000);
        }

        // Close modal when clicking outside
        document.addEventListener('click', function(event) {
            const modal = document.getElementById('modal');
            if (event.target === modal) {
                closeModal();
            }
        });
    </script>
</body>
</html>
