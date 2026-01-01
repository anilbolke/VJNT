<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    // Check if user is logged in
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    // Only DATA_ADMIN can access
    if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Data Admin Dashboard - GATEE PORTAL Class Management</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f0f2f5;
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
        }
        
        .header {
            background: #f0f2f5;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header-left {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 10px;
            width: 100%;
            text-align: center;
        }
        
        .header-logo {
            display: flex;
            justify-content: center;
            width: 100%;
        }
        
        .header-logo img {
            max-width: 150px;
            width: 150px;
            height: auto;
            display: block;
        }
        
        .header h1 {
            color: #000;
            font-size: 24px;
            font-weight: 700;
        }
        
        .gatee-tooltip {
            position: relative;
            display: inline-block;
            cursor: help;
            margin-left: 8px;
            color: #667eea;
            font-size: 16px;
        }
        
        .gatee-tooltip:hover .tooltip-content {
            visibility: visible;
            opacity: 1;
        }
        
        .tooltip-content {
            visibility: hidden;
            opacity: 0;
            position: absolute;
            z-index: 1000;
            background: #2d3748;
            color: white;
            padding: 12px 15px;
            border-radius: 8px;
            font-size: 12px;
            white-space: nowrap;
            bottom: 125%;
            left: 50%;
            transform: translateX(-50%);
            transition: opacity 0.3s;
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }
        
        .tooltip-content::after {
            content: "";
            position: absolute;
            top: 100%;
            left: 50%;
            margin-left: -5px;
            border-width: 5px;
            border-style: solid;
            border-color: #2d3748 transparent transparent transparent;
        }
        
        .tooltip-content div {
            margin: 3px 0;
        }
        
        .logout-btn {
            padding: 10px 20px;
            background: #f44336;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
        }
        
        .logout-btn:hover {
            background: #d32f2f;
        }
        
        .upload-section {
            background: #e8eaf0;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
        }
        
        .upload-section h2 {
            color: #000;
            margin-bottom: 20px;
            font-weight: 700;
        }
        
        .info-box {
            background: #d4d9e8;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        
        .info-box h3 {
            color: #000;
            font-size: 16px;
            margin-bottom: 10px;
            font-weight: 700;
        }
        
        .info-box ul {
            margin-left: 20px;
            color: #000;
        }
        
        .info-box li {
            margin: 5px 0;
        }
        
        .upload-area {
            border: 3px dashed #ccc;
            border-radius: 10px;
            padding: 40px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
            margin-bottom: 20px;
        }
        
        .upload-area:hover {
            border-color: #667eea;
            background: #f8f9fa;
        }
        
        .upload-area.dragover {
            border-color: #667eea;
            background: #e3f2fd;
        }
        
        .upload-icon {
            font-size: 48px;
            margin-bottom: 15px;
        }
        
        .file-input {
            display: none;
        }
        
        .btn-upload {
            padding: 12px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            cursor: pointer;
            transition: transform 0.2s;
        }
        
        .btn-upload:hover {
            transform: translateY(-2px);
        }
        
        .btn-upload:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        
        .file-info {
            margin: 20px 0;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 5px;
            display: none;
        }
        
        .file-info.show {
            display: block;
        }
        
        .progress-bar {
            width: 100%;
            height: 30px;
            background: #e0e0e0;
            border-radius: 15px;
            overflow: hidden;
            margin: 20px 0;
            display: none;
        }
        
        .progress-bar.show {
            display: block;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            width: 0%;
            transition: width 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
        }
        
        .result-box {
            padding: 20px;
            border-radius: 8px;
            margin-top: 20px;
            display: none;
        }
        
        .result-box.show {
            display: block;
        }
        
        .result-box.success {
            background: #e8f5e9;
            border: 1px solid #4caf50;
            color: #2e7d32;
        }
        
        .result-box.error {
            background: #ffebee;
            border: 1px solid #f44336;
            color: #c62828;
        }
        
        .result-box pre {
            white-space: pre-wrap;
            margin-top: 10px;
            font-family: monospace;
        }
        
        /* Users Table Styles */
        .users-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        
        .users-section h2 {
            color: #000;
            margin-bottom: 20px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .search-filter {
            margin-bottom: 20px;
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
        }
        
        .search-filter input,
        .search-filter select {
            padding: 10px 15px;
            border: 2px solid #ddd;
            border-radius: 8px;
            font-size: 14px;
            flex: 1;
            min-width: 200px;
        }
        
        .search-filter input:focus,
        .search-filter select:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .users-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            overflow-x: auto;
            display: block;
        }
        
        .users-table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .users-table th,
        .users-table td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        .users-table th {
            font-weight: 600;
            font-size: 14px;
        }
        
        .users-table tbody tr:hover {
            background: #f8f9fa;
        }
        
        .users-table td {
            font-size: 13px;
            color: #333;
        }
        
        .badge {
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
            display: inline-block;
        }
        
        .badge-admin {
            background: #ff6b6b;
            color: white;
        }
        
        .badge-division {
            background: #4ecdc4;
            color: white;
        }
        
        .badge-district {
            background: #95e1d3;
            color: #333;
        }
        
        .badge-school {
            background: #f38181;
            color: white;
        }
        
        .badge-coordinator {
            background: #aa96da;
            color: white;
        }
        
        .badge-headmaster {
            background: #fcbad3;
            color: #333;
        }
        
        .password-field {
            font-family: monospace;
            background: #f8f9fa;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
        }
        
        .no-data {
            text-align: center;
            padding: 40px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div class="header-left">
                <!-- Logo Section - START -->
               <%--  <div class="header-logo">
                    <img src="<%= request.getContextPath() %>/Document/GATEE LOGO.png?v=2" alt="GATEE Logo">
                </div> --%>
                <!-- Logo Section - END -->
                <!-- Admin Icon and Title Section - START -->
                <div class="school-icon">👨‍💼</div>
                <h1>Data Admin Dashboard</h1>
                <!-- Admin Icon and Title Section - END -->
                <p style="color: #666; margin-top: 5px;">Welcome, <%= user.getFullName() %></p>
            </div>
            <a href="<%= request.getContextPath() %>/logout" class="logout-btn">Logout</a>
        </div>
        
        <!-- Quick Actions -->
        <div style="margin-bottom: 30px; display: flex; gap: 15px; flex-wrap: wrap;">
            <a href="<%= request.getContextPath() %>/upload-schools.jsp" 
               style="flex: 1; min-width: 200px; padding: 20px; background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); 
                      color: white; text-decoration: none; border-radius: 10px; text-align: center; 
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'" 
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">🏫</div>
                <div style="font-size: 18px; font-weight: 600;">Upload School Master</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.9;">UDISE & School Names</div>
            </a>
            <a href="<%= request.getContextPath() %>/manage-users.jsp" 
               style="flex: 1; min-width: 200px; padding: 20px; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); 
                      color: white; text-decoration: none; border-radius: 10px; text-align: center; 
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'" 
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">👥</div>
                <div style="font-size: 18px; font-weight: 600;">Manage Users</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.9;">Create & Edit Users</div>
            </a>
        </div>
        
        <!-- All Users Section -->
        <div class="users-section">
            <h2>
                <span>👥</span>
                <span>All Users - Usernames & Passwords</span>
            </h2>
            
            <div class="search-filter">
                <input type="text" id="userSearch" placeholder="🔍 Search by username, name, or UDISE..." oninput="filterUsers()">
                <select id="userTypeFilter" onchange="filterUsers()">
                    <option value="">All User Types</option>
                    <option value="DATA_ADMIN">Data Admin</option>
                    <option value="DIVISION">Division</option>
                    <option value="DISTRICT">District</option>
                    <option value="SCHOOL_COORDINATOR">School Coordinator</option>
                    <option value="HEAD_MASTER">Head Master</option>
                </select>
            </div>
            
            <div style="overflow-x: auto;">
                <table class="users-table" id="usersTable">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Username</th>
                            <th>Password</th>
                            <th>Full Name</th>
                            <th>User Type</th>
                            <th>Division</th>
                            <th>District</th>
                            <th>UDISE</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody id="usersTableBody">
                        <tr>
                            <td colspan="9" class="no-data">
                                <div style="font-size: 48px; margin-bottom: 15px;">⏳</div>
                                Loading users...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
        
        <!-- Upload Section -->
        <div class="upload-section">
            <h2>📤 Upload Student Data (Excel)</h2>
            
            <!-- Information Box -->
     
            
            <!-- Upload Area -->
            <div class="upload-area" id="uploadArea">
                <div class="upload-icon">📁</div>
                <h3>Click to select Excel file or drag & drop here</h3>
                <p style="color: #666; margin-top: 10px;">Supported formats: .xlsx, .xls</p>
                <input type="file" id="fileInput" class="file-input" accept=".xlsx,.xls">
            </div>
            
            <!-- File Info -->
            <div class="file-info" id="fileInfo">
                <strong>Selected File:</strong> <span id="fileName"></span>
                <br>
                <strong>Size:</strong> <span id="fileSize"></span>
            </div>
            
            <!-- Upload Button -->
            <button class="btn-upload" id="uploadBtn" onclick="uploadFile()" disabled>
                📤 Upload and Process
            </button>
            
            <!-- Progress Bar -->
            <div class="progress-bar" id="progressBar">
                <div class="progress-fill" id="progressFill">0%</div>
            </div>
            
            <!-- Result Box -->
            <div class="result-box" id="resultBox">
                <strong id="resultTitle"></strong>
                <pre id="resultMessage"></pre>
            </div>
        </div>
    </div>
    
    <script>
        let selectedFile = null;
        
        // Get elements
        const uploadArea = document.getElementById('uploadArea');
        const fileInput = document.getElementById('fileInput');
        const fileInfo = document.getElementById('fileInfo');
        const fileName = document.getElementById('fileName');
        const fileSize = document.getElementById('fileSize');
        const uploadBtn = document.getElementById('uploadBtn');
        const progressBar = document.getElementById('progressBar');
        const progressFill = document.getElementById('progressFill');
        const resultBox = document.getElementById('resultBox');
        const resultTitle = document.getElementById('resultTitle');
        const resultMessage = document.getElementById('resultMessage');
        
        // Click to select file
        uploadArea.addEventListener('click', () => {
            fileInput.click();
        });
        
        // File selected
        fileInput.addEventListener('change', (e) => {
            if (e.target.files.length > 0) {
                selectedFile = e.target.files[0];
                displayFileInfo(selectedFile);
            }
        });
        
        // Drag and drop
        uploadArea.addEventListener('dragover', (e) => {
            e.preventDefault();
            uploadArea.classList.add('dragover');
        });
        
        uploadArea.addEventListener('dragleave', () => {
            uploadArea.classList.remove('dragover');
        });
        
        uploadArea.addEventListener('drop', (e) => {
            e.preventDefault();
            uploadArea.classList.remove('dragover');
            
            if (e.dataTransfer.files.length > 0) {
                selectedFile = e.dataTransfer.files[0];
                displayFileInfo(selectedFile);
            }
        });
        
        // Display file info
        function displayFileInfo(file) {
            fileName.textContent = file.name;
            fileSize.textContent = formatFileSize(file.size);
            fileInfo.classList.add('show');
            uploadBtn.disabled = false;
            resultBox.classList.remove('show');
        }
        
        // Format file size
        function formatFileSize(bytes) {
            if (bytes < 1024) return bytes + ' B';
            if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
            return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
        }
        
        // Upload file
        function uploadFile() {
            if (!selectedFile) {
                alert('Please select a file first');
                return;
            }
            
            // Validate file type
            if (!selectedFile.name.endsWith('.xlsx') && !selectedFile.name.endsWith('.xls')) {
                showResult(false, 'Invalid file type. Please upload Excel file (.xlsx or .xls)');
                return;
            }
            
            // Show progress
            uploadBtn.disabled = true;
            uploadBtn.textContent = '⏳ Uploading...';
            progressBar.classList.add('show');
            resultBox.classList.remove('show');
            
            // Create form data
            const formData = new FormData();
            formData.append('excelFile', selectedFile);
            
            // Upload file
            fetch('<%= request.getContextPath() %>/upload-excel', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                progressFill.style.width = '100%';
                progressFill.textContent = '100%';
                
                setTimeout(() => {
                    showResult(data.success, data.message);
                    uploadBtn.disabled = false;
                    uploadBtn.textContent = '📤 Upload and Process';
                    progressBar.classList.remove('show');
                    progressFill.style.width = '0%';
                    
                    if (data.success) {
                        // Reset form
                        selectedFile = null;
                        fileInput.value = '';
                        fileInfo.classList.remove('show');
                        uploadBtn.disabled = true;
                    }
                }, 500);
            })
            .catch(error => {
                showResult(false, 'Error uploading file: ' + error.message);
                uploadBtn.disabled = false;
                uploadBtn.textContent = '📤 Upload and Process';
                progressBar.classList.remove('show');
            });
        }
        
        // Show result
        function showResult(success, message) {
            resultBox.classList.remove('success', 'error');
            resultBox.classList.add(success ? 'success' : 'error');
            resultTitle.textContent = success ? '✅ Success!' : '❌ Error!';
            resultMessage.textContent = message;
            resultBox.classList.add('show');
        }
        
        // ===== USERS TABLE FUNCTIONALITY =====
        let allUsers = [];
        
        // Load all users on page load
        window.addEventListener('DOMContentLoaded', function() {
            loadAllUsers();
        });
        
        // Fetch all users from server
        function loadAllUsers() {
            fetch('<%= request.getContextPath() %>/getAllUsers')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        allUsers = data.users;
                        displayUsers(allUsers);
                    } else {
                        showUsersError('Failed to load users: ' + (data.error || data.message || 'Unknown error'));
                    }
                })
                .catch(error => {
                    console.error('Error loading users:', error);
                    showUsersError('Error loading users. Please refresh the page.');
                });
        }
        
        // Display users in table
        function displayUsers(users) {
            const tbody = document.getElementById('usersTableBody');
            
            if (!users || users.length === 0) {
                tbody.innerHTML = '<tr><td colspan="9" class="no-data"><div style="font-size: 48px; margin-bottom: 15px;">📭</div>No users found</td></tr>';
                return;
            }
            
            let html = '';
            users.forEach((user, index) => {
                const badgeClass = getBadgeClass(user.userType);
                const statusBadge = user.isActive ? '<span class="badge" style="background: #4caf50; color: white;">Active</span>' : '<span class="badge" style="background: #f44336; color: white;">Locked</span>';
                
                html += `
                    <tr>
                        <td>${index + 1}</td>
                        <td><strong>${escapeHtml(user.username)}</strong></td>
                        <td><span class="password-field">${escapeHtml(user.password || '******')}</span></td>
                        <td>${escapeHtml(user.fullName || '-')}</td>
                        <td><span class="badge ${badgeClass}">${formatUserType(user.userType)}</span></td>
                        <td>${escapeHtml(user.divisionName || '-')}</td>
                        <td>${escapeHtml(user.districtName || '-')}</td>
                        <td>${escapeHtml(user.udiseNo || '-')}</td>
                        <td>${statusBadge}</td>
                    </tr>
                `;
            });
            
            tbody.innerHTML = html;
        }
        
        // Filter users based on search and type
        function filterUsers() {
            const searchTerm = document.getElementById('userSearch').value.toLowerCase().trim();
            const userType = document.getElementById('userTypeFilter').value;
            
            let filtered = allUsers;
            
            // Filter by user type
            if (userType) {
                filtered = filtered.filter(user => user.userType === userType);
            }
            
            // Filter by search term
            if (searchTerm) {
                filtered = filtered.filter(user => {
                    return (user.username && user.username.toLowerCase().includes(searchTerm)) ||
                           (user.fullName && user.fullName.toLowerCase().includes(searchTerm)) ||
                           (user.udiseNo && user.udiseNo.toLowerCase().includes(searchTerm)) ||
                           (user.districtName && user.districtName.toLowerCase().includes(searchTerm)) ||
                           (user.divisionName && user.divisionName.toLowerCase().includes(searchTerm));
                });
            }
            
            displayUsers(filtered);
        }
        
        // Get badge class based on user type
        function getBadgeClass(userType) {
            const typeMap = {
                'DATA_ADMIN': 'badge-admin',
                'DIVISION': 'badge-division',
                'DISTRICT': 'badge-district',
                'SCHOOL_COORDINATOR': 'badge-coordinator',
                'HEAD_MASTER': 'badge-headmaster'
            };
            return typeMap[userType] || 'badge-school';
        }
        
        // Format user type for display
        function formatUserType(userType) {
            if (!userType) return '-';
            return userType.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
        }
        
        // Show error in users table
        function showUsersError(message) {
            const tbody = document.getElementById('usersTableBody');
            tbody.innerHTML = `<tr><td colspan="9" class="no-data"><div style="font-size: 48px; margin-bottom: 15px; color: #f44336;">❌</div>${escapeHtml(message)}</td></tr>`;
        }
        
        // Escape HTML to prevent XSS
        function escapeHtml(text) {
            if (!text) return '';
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
    </script>
</body>
</html>
