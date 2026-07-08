<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
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
    <title>All Users - Credentials - GATEE PORTAL</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f0f2f5;
            min-height: 100vh;
            padding: 20px;
        }

        .container { max-width: 1200px; margin: 0 auto; }

        .header {
            background: #f0f2f5;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 10px;
        }

        .header h1 {
            color: #000;
            font-size: 22px;
            font-weight: 700;
        }

        .back-btn {
            padding: 10px 20px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
        }

        .back-btn:hover { background: #5566d6; }

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

        .logout-btn:hover { background: #d32f2f; }

        .users-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
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

        .users-table th { font-weight: 600; font-size: 14px; }
        .users-table tbody tr:hover { background: #f8f9fa; }
        .users-table td { font-size: 13px; color: #333; }

        .badge {
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
            display: inline-block;
        }

        .badge-admin       { background: #ff6b6b; color: white; }
        .badge-division    { background: #4ecdc4; color: white; }
        .badge-district    { background: #95e1d3; color: #333; }
        .badge-school      { background: #f38181; color: white; }
        .badge-coordinator { background: #aa96da; color: white; }
        .badge-headmaster  { background: #fcbad3; color: #333; }

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
        <div class="header">
            <div>
                <h1>👥 All Users - Usernames &amp; Passwords</h1>
                <p style="color: #666; margin-top: 5px;">Welcome, <%= user.getFullName() %></p>
            </div>
            <div style="display: flex; gap: 10px;">
                <a href="<%= request.getContextPath() %>/data-admin-dashboard.jsp" class="back-btn">&larr; Back to Dashboard</a>
                <a href="<%= request.getContextPath() %>/logout" class="logout-btn">Logout</a>
            </div>
        </div>

        <div class="users-section">
            <h2>
                <span>👥</span>
                <span>All Users - Usernames &amp; Passwords</span>
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
    </div>

    <script>
        let allUsers = [];

        window.addEventListener('DOMContentLoaded', function() {
            loadAllUsers();
        });

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

        function displayUsers(users) {
            const tbody = document.getElementById('usersTableBody');

            if (!users || users.length === 0) {
                tbody.innerHTML = '<tr><td colspan="9" class="no-data"><div style="font-size: 48px; margin-bottom: 15px;">📭</div>No users found</td></tr>';
                return;
            }

            let html = '';
            users.forEach((u, index) => {
                const badgeClass = getBadgeClass(u.userType);
                const statusBadge = u.isActive
                    ? '<span class="badge" style="background: #4caf50; color: white;">Active</span>'
                    : '<span class="badge" style="background: #f44336; color: white;">Locked</span>';

                html += `
                    <tr>
                        <td>${index + 1}</td>
                        <td><strong>${escapeHtml(u.username)}</strong></td>
                        <td><span class="password-field">${escapeHtml(u.password || '******')}</span></td>
                        <td>${escapeHtml(u.fullName || '-')}</td>
                        <td><span class="badge ${badgeClass}">${formatUserType(u.userType)}</span></td>
                        <td>${escapeHtml(u.divisionName || '-')}</td>
                        <td>${escapeHtml(u.districtName || '-')}</td>
                        <td>${escapeHtml(u.udiseNo || '-')}</td>
                        <td>${statusBadge}</td>
                    </tr>
                `;
            });

            tbody.innerHTML = html;
        }

        function filterUsers() {
            const searchTerm = document.getElementById('userSearch').value.toLowerCase().trim();
            const userType = document.getElementById('userTypeFilter').value;

            let filtered = allUsers;

            if (userType) {
                filtered = filtered.filter(u => u.userType === userType);
            }

            if (searchTerm) {
                filtered = filtered.filter(u => {
                    return (u.username && u.username.toLowerCase().includes(searchTerm)) ||
                           (u.fullName && u.fullName.toLowerCase().includes(searchTerm)) ||
                           (u.udiseNo && u.udiseNo.toLowerCase().includes(searchTerm)) ||
                           (u.districtName && u.districtName.toLowerCase().includes(searchTerm)) ||
                           (u.divisionName && u.divisionName.toLowerCase().includes(searchTerm));
                });
            }

            displayUsers(filtered);
        }

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

        function formatUserType(userType) {
            if (!userType) return '-';
            return userType.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
        }

        function showUsersError(message) {
            const tbody = document.getElementById('usersTableBody');
            tbody.innerHTML = `<tr><td colspan="9" class="no-data"><div style="font-size: 48px; margin-bottom: 15px; color: #f44336;">❌</div>${escapeHtml(message)}</td></tr>`;
        }

        function escapeHtml(text) {
            if (!text) return '';
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
    </script>
</body>
</html>
