<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    // Check if user is logged in
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    // Verify user is DATA_ADMIN
    if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Users - VJNT Class Management System</title>
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
            max-width: 1400px;
            margin: 0 auto;
        }
        
        .header {
            background: #f0f2f5;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            margin-bottom: 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .header-left {
            display: flex;
            align-items: center;
            gap: 15px;
            flex: 1;
            min-width: 300px;
        }
        
        .back-btn {
            background: #95a5a6;
            color: white;
            padding: 8px 15px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: 600;
            transition: background 0.3s;
            text-decoration: none;
            display: inline-block;
        }
        
        .back-btn:hover {
            background: #7f8c8d;
        }
        
        .header h1 {
            color: #000;
            font-size: 24px;
            font-weight: 700;
        }
        
        .header-right {
            display: flex;
            gap: 10px;
            align-items: center;
        }
        
        .user-info span {
            color: #000;
            font-weight: 600;
        }
        
        .logout-btn {
            background: #e74c3c;
            color: white;
            padding: 8px 15px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: 600;
            transition: background 0.3s;
        }
        
        .logout-btn:hover {
            background: #c0392b;
        }
        
        .controls-section {
            background: #e8eaf0;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            margin-bottom: 20px;
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            align-items: center;
        }
        
        .search-box {
            flex: 1;
            min-width: 250px;
        }
        
        .search-box input {
            width: 100%;
            padding: 10px 15px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
            transition: border-color 0.3s;
            background: #fff;
            color: #000;
        }
        
        .search-box input:focus {
            outline: none;
            border-color: #667eea;
            background: #fff;
        }
        
        .filter-box {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .filter-box select {
            padding: 10px 15px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
            cursor: pointer;
            transition: border-color 0.3s;
            background: #fff;
            color: #000;
        }
        
        .filter-box select:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .action-buttons {
            display: flex;
            gap: 10px;
        }
        
        .btn {
            padding: 10px 15px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: 600;
            transition: opacity 0.3s;
        }
        
        .btn-add {
            background: #27ae60;
            color: white;
        }
        
        .btn-add:hover {
            opacity: 0.9;
        }
        
        .btn-export {
            background: #3498db;
            color: white;
        }
        
        .btn-export:hover {
            opacity: 0.9;
        }
        
        .table-container {
            background: #e8eaf0;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            overflow: auto;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 1000px;
        }
        
        thead {
            background: #d4d9e8;
            border-bottom: 2px solid #667eea;
        }
        
        thead th {
            padding: 15px;
            text-align: left;
            color: #000;
            font-weight: 700;
            font-size: 14px;
            white-space: nowrap;
        }
        
        tbody tr {
            border-bottom: 1px solid #ddd;
            transition: background 0.3s;
        }
        
        tbody tr:hover {
            background: #d9dce8;
        }
        
        tbody td {
            padding: 12px 15px;
            color: #000;
            font-size: 13px;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            white-space: nowrap;
        }
        
        .badge-admin {
            background: #e74c3c;
            color: white;
        }
        
        .badge-division {
            background: #3498db;
            color: white;
        }
        
        .badge-district {
            background: #9b59b6;
            color: white;
        }
        
        .badge-school {
            background: #f39c12;
            color: white;
        }
        
        .badge-active {
            background: #27ae60;
            color: white;
        }
        
        .badge-inactive {
            background: #e74c3c;
            color: white;
        }
        
        .badge-locked {
            background: #c0392b;
            color: white;
        }
        
        .action-links {
            display: flex;
            gap: 8px;
            white-space: nowrap;
        }
        
        .action-links a {
            padding: 5px 10px;
            border-radius: 3px;
            text-decoration: none;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: opacity 0.3s;
        }
        
        .link-view {
            background: #3498db;
            color: white;
        }
        
        .link-edit {
            background: #f39c12;
            color: white;
        }
        
        .link-delete {
            background: #e74c3c;
            color: white;
        }
        
        .action-links a:hover {
            opacity: 0.8;
        }
        
        .loading {
            text-align: center;
            padding: 40px;
            color: #666;
            font-size: 16px;
        }
        
        .loading-spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #667eea;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .no-data {
            text-align: center;
            padding: 40px;
            color: #999;
            font-size: 16px;
        }
        
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 5px;
            padding: 20px;
            background: white;
            border-radius: 8px;
            margin-top: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            flex-wrap: wrap;
        }
        
        .pagination button {
            padding: 10px 12px;
            border: 1px solid #ddd;
            background: white;
            cursor: pointer;
            border-radius: 5px;
            transition: all 0.3s;
            font-weight: 600;
            color: #333;
            min-width: 40px;
        }
        
        .pagination button:hover:not(:disabled) {
            background: #667eea;
            color: white;
            border-color: #667eea;
            transform: translateY(-2px);
        }
        
        .pagination button.active {
            background: #667eea;
            color: white;
            border-color: #667eea;
            box-shadow: 0 4px 8px rgba(102, 126, 234, 0.3);
        }
        
        .pagination button:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
        
        .pagination span {
            margin: 0 5px;
            color: #666;
            font-weight: 500;
        }
        
        .error {
            background: #e74c3c;
            color: white;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .success {
            background: #27ae60;
            color: white;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .stats-info {
            background: #e8eaf0;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
        }
        
        .stat {
            text-align: center;
        }
        
        .stat-value {
            font-size: 24px;
            font-weight: bold;
            color: #000;
        }
        
        .stat-label {
            font-size: 12px;
            color: #000;
            margin-top: 5px;
            font-weight: 600;
        }
        
        .user-detail-modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 1000;
            align-items: center;
            justify-content: center;
        }
        
        .user-detail-modal.active {
            display: flex;
        }
        
        .modal-content {
            background: #e8eaf0;
            border-radius: 8px;
            max-width: 600px;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: 0 5px 30px rgba(0,0,0,0.3);
        }
        
        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px 8px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-header h2 {
            font-size: 20px;
            font-weight: 700;
        }
        
        .modal-close {
            background: none;
            border: none;
            color: white;
            font-size: 24px;
            cursor: pointer;
            width: 30px;
            height: 30px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .modal-body {
            padding: 25px;
            background: #e8eaf0;
        }
        
        .detail-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 15px;
        }
        
        .detail-row.full {
            grid-template-columns: 1fr;
        }
        
        .detail-item {
            display: flex;
            flex-direction: column;
        }
        
        .detail-label {
            font-weight: 700;
            color: #000;
            margin-bottom: 5px;
            font-size: 12px;
            text-transform: uppercase;
        }
        
        .detail-value {
            color: #000;
            font-size: 14px;
            word-break: break-word;
        }
        
        .modal-footer {
            padding: 20px;
            border-top: 1px solid #eee;
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }
        
        .modal-footer button {
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: 600;
            transition: opacity 0.3s;
        }
        
        .btn-close-modal {
            background: #95a5a6;
            color: white;
        }
        
        .btn-close-modal:hover {
            opacity: 0.8;
        }
        
        @media (max-width: 768px) {
            .header {
                flex-direction: column;
                align-items: flex-start;
            }
            
            .controls-section {
                flex-direction: column;
            }
            
            .search-box {
                min-width: auto;
            }
            
            .filter-box {
                width: 100%;
            }
            
            .detail-row {
                grid-template-columns: 1fr;
            }
            
            .modal-content {
                max-width: 95%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div class="header-left">
                <a href="<%= request.getContextPath() %>/data-admin-dashboard.jsp" class="back-btn">← Back to Dashboard</a>
                <h1>👥 Manage Users</h1>
            </div>
            <div class="header-right">
                <div class="user-info">
                    <span><%= user.getFullName() != null ? user.getFullName() : user.getUsername() %></span>
                </div>
                <form action="<%= request.getContextPath() %>/logout" method="POST" style="margin: 0;">
                    <button type="submit" class="logout-btn">Logout</button>
                </form>
            </div>
        </div>
        
        <!-- Message Area -->
        <div id="messageContainer"></div>
        
        <!-- Statistics -->
        <div class="stats-info">
            <div class="stat">
                <div class="stat-value" id="totalUsersCount">0</div>
                <div class="stat-label">Total Users</div>
            </div>
        </div>
        
        <!-- Controls Section -->
        <div class="controls-section">
            <div class="search-box">
                <input type="text" id="searchInput" placeholder="Search by username, email, or full name...">
            </div>
            <div class="filter-box">
                <select id="userTypeFilter">
                    <option value="">All User Types</option>
                    <option value="DIVISION">Division</option>
                    <option value="DISTRICT_COORDINATOR">District Coordinator</option>
                    <option value="DISTRICT_2ND_COORDINATOR">District 2nd Coordinator</option>
                    <option value="SCHOOL_COORDINATOR">School Coordinator</option>
                    <option value="HEAD_MASTER">Head Master</option>
                    <option value="DATA_ADMIN">Data Admin</option>
                </select>
                <select id="statusFilter">
                    <option value="">All Status</option>
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="locked">Locked</option>
                </select>
            </div>
            <div class="action-buttons">
                <button class="btn btn-export" onclick="exportUsers()">📥 Export</button>
            </div>
        </div>
        
        <!-- Table Section -->
        <div class="table-container">
            <div id="loadingIndicator" class="loading">
                <div class="loading-spinner"></div>
                Loading users...
            </div>
            <table id="usersTable" style="display: none;">
                <thead>
                    <tr>
                        <th>Username</th>
                        <th>Full Name</th>
                        <th>User Type</th>
                        <th>Division</th>
                        <th>District</th>
                        <th>Last Login</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="usersTableBody">
                </tbody>
            </table>
            <div id="noDataMessage" class="no-data" style="display: none;">
                No users found
            </div>
            
            <!-- Pagination Controls -->
            <div id="paginationContainer" class="pagination" style="display: none;">
                <button id="prevBtn" onclick="previousPage()" style="margin-right: 10px;">← Previous</button>
                <span id="pageInfo">Page 1 of 1</span>
                <button id="nextBtn" onclick="nextPage()" style="margin-left: 10px;">Next →</button>
            </div>
        </div>
    </div>
    
    <!-- User Detail Modal -->
    <div id="userDetailModal" class="user-detail-modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>User Details</h2>
                <button class="modal-close" onclick="closeUserDetailModal()">×</button>
            </div>
            <div class="modal-body" id="userDetailBody">
            </div>
            <div class="modal-footer">
                <button class="modal-footer button btn-close-modal" onclick="closeUserDetailModal()">Close</button>
            </div>
        </div>
    </div>
    
    <script>
        let allUsers = [];
        let filteredUsers = [];
        const itemsPerPage = 10;
        let currentPage = 1;
        
        // Load users on page load
        document.addEventListener('DOMContentLoaded', function() {
            loadAllUsers();
            setupEventListeners();
        });
        
        function setupEventListeners() {
            document.getElementById('searchInput').addEventListener('input', filterUsers);
            document.getElementById('userTypeFilter').addEventListener('change', filterUsers);
            document.getElementById('statusFilter').addEventListener('change', filterUsers);
        }
        
        function loadAllUsers() {
            fetch('<%= request.getContextPath() %>/getAllUsers', {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json'
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    allUsers = data.users || [];
                    filteredUsers = [...allUsers];
                    updateStatistics();
                    displayUsers(filteredUsers);
                    document.getElementById('loadingIndicator').style.display = 'none';
                    document.getElementById('usersTable').style.display = 'table';
                } else {
                    showError('Failed to load users: ' + (data.error || 'Unknown error'));
                    document.getElementById('loadingIndicator').innerHTML = '<div class="error">' + (data.error || 'Failed to load users') + '</div>';
                }
            })
            .catch(error => {
                console.error('Error:', error);
                showError('Error loading users: ' + error.message);
                document.getElementById('loadingIndicator').innerHTML = '<div class="error">Error loading users: ' + error.message + '</div>';
            });
        }
        
        function updateStatistics() {
            const total = allUsers.length;
            document.getElementById('totalUsersCount').textContent = total;
        }
        
        function filterUsers() {
            const searchTerm = document.getElementById('searchInput').value.toLowerCase();
            const userTypeFilter = document.getElementById('userTypeFilter').value;
            const statusFilter = document.getElementById('statusFilter').value;
            
            filteredUsers = allUsers.filter(user => {
                const matchesSearch = !searchTerm || 
                    user.username.toLowerCase().includes(searchTerm) ||
                    (user.email && user.email.toLowerCase().includes(searchTerm)) ||
                    (user.fullName && user.fullName.toLowerCase().includes(searchTerm));
                
                const matchesType = !userTypeFilter || user.userType === userTypeFilter;
                
                let matchesStatus = true;
                if (statusFilter === 'active') {
                    matchesStatus = user.active && !user.accountLocked;
                } else if (statusFilter === 'inactive') {
                    matchesStatus = !user.active;
                } else if (statusFilter === 'locked') {
                    matchesStatus = user.accountLocked;
                }
                
                return matchesSearch && matchesType && matchesStatus;
            });
            
            currentPage = 1;
            displayUsers(filteredUsers);
        }
        
        function displayUsers(users) {
            const tbody = document.getElementById('usersTableBody');
            tbody.innerHTML = '';
            
            if (users.length === 0) {
                document.getElementById('usersTable').style.display = 'none';
                document.getElementById('noDataMessage').style.display = 'block';
                document.getElementById('paginationContainer').style.display = 'none';
                return;
            }
            
            document.getElementById('usersTable').style.display = 'table';
            document.getElementById('noDataMessage').style.display = 'none';
            
            // Calculate pagination
            const totalPages = Math.ceil(users.length / itemsPerPage);
            const startIndex = (currentPage - 1) * itemsPerPage;
            const endIndex = Math.min(startIndex + itemsPerPage, users.length);
            const paginatedUsers = users.slice(startIndex, endIndex);
            
            // Display current page users
            paginatedUsers.forEach(user => {
                const row = document.createElement('tr');
                let html = '<td><strong>' + escapeHtml(user.username) + '</strong></td>' +
                           '<td>' + escapeHtml(user.fullName || '-') + '</td>' +
                           '<td>' + getUserTypeBadge(user.userType) + '</td>' +
                           '<td>' + escapeHtml(user.divisionName || '-') + '</td>' +
                           '<td>' + escapeHtml(user.districtName || '-') + '</td>' +
                           '<td>' + formatDate(user.lastLoginDate) + '</td>' +
                           '<td><div class="action-links"><a class="link-view" onclick="viewUserDetails(' + user.userId + ')">View</a></div></td>';
                row.innerHTML = html;
                tbody.appendChild(row);
            });
            
            // Update pagination controls
            updatePaginationControls(totalPages, users.length);
        }
        
        function updatePaginationControls(totalPages, totalUsers) {
            const paginationContainer = document.getElementById('paginationContainer');
            const pageInfo = document.getElementById('pageInfo');
            const prevBtn = document.getElementById('prevBtn');
            const nextBtn = document.getElementById('nextBtn');
            
            if (totalUsers > itemsPerPage) {
                paginationContainer.style.display = 'flex';
                pageInfo.textContent = 'Page ' + currentPage + ' of ' + totalPages + ' (Total: ' + totalUsers + ' users)';
                prevBtn.disabled = currentPage === 1;
                nextBtn.disabled = currentPage === totalPages;
            } else {
                paginationContainer.style.display = 'none';
            }
        }
        
        function previousPage() {
            if (currentPage > 1) {
                currentPage--;
                displayUsers(filteredUsers);
                document.querySelector('.table-container').scrollIntoView({ behavior: 'smooth' });
            }
        }
        
        function nextPage() {
            const totalPages = Math.ceil(filteredUsers.length / itemsPerPage);
            if (currentPage < totalPages) {
                currentPage++;
                displayUsers(filteredUsers);
                document.querySelector('.table-container').scrollIntoView({ behavior: 'smooth' });
            }
        }
        
        function getUserTypeBadge(userType) {
            const typeMap = {
                'DIVISION': 'Division',
                'DISTRICT_COORDINATOR': 'District Coordinator',
                'DISTRICT_2ND_COORDINATOR': 'District 2nd Coordinator',
                'SCHOOL_COORDINATOR': 'School Coordinator',
                'HEAD_MASTER': 'Head Master',
                'DATA_ADMIN': 'Data Admin'
            };
            
            const badgeClass = userType.includes('ADMIN') ? 'badge-admin' : 
                              userType.includes('DISTRICT') ? 'badge-district' :
                              userType.includes('SCHOOL') ? 'badge-school' :
                              'badge-division';
            
            return '<span class="badge ' + badgeClass + '">' + (typeMap[userType] || userType) + '</span>';
        }
        
        function getStatusBadge(user) {
            if (user.accountLocked) {
                return '<span class="badge badge-locked">🔒 Locked</span>';
            }
            if (!user.active) {
                return '<span class="badge badge-inactive">Inactive</span>';
            }
            return '<span class="badge badge-active">✓ Active</span>';
        }
        
        function formatDate(dateString) {
            if (!dateString) return '-';
            const date = new Date(dateString);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        }
        
        function viewUserDetails(userId) {
            const user = allUsers.find(u => u.userId === userId);
            if (!user) return;
            
            const detailBody = document.getElementById('userDetailBody');
            let html = '<div class="detail-row full">' +
                '<div class="detail-item">' +
                '<span class="detail-label">Username</span>' +
                '<span class="detail-value">' + escapeHtml(user.username) + '</span>' +
                '</div>' +
                '</div>' +
                '<div class="detail-row">' +
                '<div class="detail-item">' +
                '<span class="detail-label">Full Name</span>' +
                '<span class="detail-value">' + escapeHtml(user.fullName || '-') + '</span>' +
                '</div>' +
                '<div class="detail-item">' +
                '<span class="detail-label">User Type</span>' +
                '<span class="detail-value">' + getUserTypeLabel(user.userType) + '</span>' +
                '</div>' +
                '</div>' +
                '<div class="detail-row">' +
                '<div class="detail-item">' +
                '<span class="detail-label">Email</span>' +
                '<span class="detail-value">' + escapeHtml(user.email || '-') + '</span>' +
                '</div>' +
                '<div class="detail-item">' +
                '<span class="detail-label">Mobile</span>' +
                '<span class="detail-value">' + escapeHtml(user.mobile || '-') + '</span>' +
                '</div>' +
                '</div>' +
                '<div class="detail-row">' +
                '<div class="detail-item">' +
                '<span class="detail-label">Division</span>' +
                '<span class="detail-value">' + escapeHtml(user.divisionName || '-') + '</span>' +
                '</div>' +
                '<div class="detail-item">' +
                '<span class="detail-label">District</span>' +
                '<span class="detail-value">' + escapeHtml(user.districtName || '-') + '</span>' +
                '</div>' +
                '</div>' +
                '<div class="detail-row">' +
                '<div class="detail-item">' +
                '<span class="detail-label">UDISE Number</span>' +
                '<span class="detail-value">' + escapeHtml(user.udiseNo || '-') + '</span>' +
                '</div>' +
                '<div class="detail-item">' +
                '<span class="detail-label">Status</span>' +
                '<span class="detail-value">' + getStatusBadge(user) + '</span>' +
                '</div>' +
                '</div>' +
                '<div class="detail-row">' +
                '<div class="detail-item">' +
                '<span class="detail-label">Account Status</span>' +
                '<span class="detail-value">' +
                (user.active ? '✓ Active' : '✗ Inactive') +
                (user.accountLocked ? ' (Locked)' : '') +
                '</span>' +
                '</div>' +
                '<div class="detail-item">' +
                '<span class="detail-label">Failed Login Attempts</span>' +
                '<span class="detail-value">' + user.failedLoginAttempts + '</span>' +
                '</div>' +
                '</div>' +
                '<div class="detail-row">' +
                '<div class="detail-item">' +
                '<span class="detail-label">Last Login</span>' +
                '<span class="detail-value">' + formatDate(user.lastLoginDate) + '</span>' +
                '</div>' +
                '<div class="detail-item">' +
                '<span class="detail-label">Created Date</span>' +
                '<span class="detail-value">' + formatDate(user.createdDate) + '</span>' +
                '</div>' +
                '</div>' +
                '<div class="detail-row full">' +
                '<div class="detail-item">' +
                '<span class="detail-label">Created By</span>' +
                '<span class="detail-value">' + escapeHtml(user.createdBy || '-') + '</span>' +
                '</div>' +
                '</div>' +
                '<div class="detail-row">' +
                '<div class="detail-item">' +
                '<span class="detail-label">First Login</span>' +
                '<span class="detail-value">' + (user.firstLogin ? 'Yes' : 'No') + '</span>' +
                '</div>' +
                '<div class="detail-item">' +
                '<span class="detail-label">Must Change Password</span>' +
                '<span class="detail-value">' + (user.mustChangePassword ? 'Yes' : 'No') + '</span>' +
                '</div>' +
                '</div>';
            
            detailBody.innerHTML = html;
            document.getElementById('userDetailModal').classList.add('active');
        }
        
        function getUserTypeLabel(userType) {
            const typeMap = {
                'DIVISION': 'Division',
                'DISTRICT_COORDINATOR': 'District Coordinator',
                'DISTRICT_2ND_COORDINATOR': 'District 2nd Coordinator',
                'SCHOOL_COORDINATOR': 'School Coordinator',
                'HEAD_MASTER': 'Head Master',
                'DATA_ADMIN': 'Data Admin'
            };
            return typeMap[userType] || userType;
        }
        
        function closeUserDetailModal() {
            document.getElementById('userDetailModal').classList.remove('active');
        }
        
        function exportUsers() {
            if (filteredUsers.length === 0) {
                showError('No users to export');
                return;
            }
            
            // Prepare CSV data
            let csvContent = "data:text/csv;charset=utf-8,";
            csvContent += "Username,Full Name,User Type,Division,District,UDISE Number,Status,Email,Mobile,Last Login\n";
            
            filteredUsers.forEach(user => {
                const status = user.accountLocked ? 'Locked' : (user.active ? 'Active' : 'Inactive');
                csvContent += '"' + user.username + '","' + (user.fullName || '') + '","' + getUserTypeLabel(user.userType) + '","' + (user.divisionName || '') + '","' + (user.districtName || '') + '","' + (user.udiseNo || '') + '","' + status + '","' + (user.email || '') + '","' + (user.mobile || '') + '","' + formatDate(user.lastLoginDate) + '"\n';
            });
            
            const encodedUri = encodeURI(csvContent);
            const link = document.createElement("a");
            link.setAttribute("href", encodedUri);
            link.setAttribute("download", "users_export_" + new Date().getTime() + ".csv");
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            showMessage('Users exported successfully', 'success');
        }
        
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        function showMessage(message, type = 'info') {
            const container = document.getElementById('messageContainer');
            const div = document.createElement('div');
            div.className = type === 'error' ? 'error' : (type === 'success' ? 'success' : 'info');
            div.textContent = message;
            container.appendChild(div);
            
            if (type !== 'error') {
                setTimeout(() => div.remove(), 3000);
            }
        }
        
        function showError(message) {
            showMessage(message, 'error');
        }
        
        // Close modal when clicking outside
        document.getElementById('userDetailModal').addEventListener('click', function(e) {
            if (e.target === this) {
                closeUserDetailModal();
            }
        });
    </script>
</body>
</html>
