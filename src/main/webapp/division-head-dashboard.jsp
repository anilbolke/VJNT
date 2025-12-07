<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.DIVISION)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String divisionName = user.getDivisionName();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Division Head Dashboard - <%= divisionName %></title>
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
        
        .header {
            background: white;
            padding: 25px 30px;
            border-radius: 15px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.15);
            margin-bottom: 30px;
        }
        
        .header-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 20px;
        }
        
        .header-left h1 {
            font-size: 28px;
            color: #333;
            margin-bottom: 8px;
        }
        
        .header-subtitle {
            color: #666;
            font-size: 16px;
        }
        
        .header-right {
            display: flex;
            gap: 15px;
            align-items: center;
            flex-wrap: wrap;
        }
        
        .user-info-box {
            background: #f8f9fa;
            padding: 15px 20px;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        
        .user-info {
            font-size: 14px;
            color: #333;
            margin-bottom: 5px;
        }
        
        .user-info:last-child {
            margin-bottom: 0;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
        }
        
        .btn-analytics {
            background: #4CAF50;
            color: white;
        }
        
        .btn-analytics:hover {
            background: #45a049;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(76, 175, 80, 0.3);
        }
        
        .btn-contacts {
            background: #9c27b0;
            color: white;
        }
        
        .btn-contacts:hover {
            background: #7b1fa2;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(156, 39, 176, 0.3);
        }
        
        .btn-users {
            background: #ff9800;
            color: white;
        }
        
        .btn-users:hover {
            background: #f57c00;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(255, 152, 0, 0.3);
        }
        
        .btn-change-password {
            background: #2196F3;
            color: white;
        }
        
        .btn-change-password:hover {
            background: #0b7dda;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(33, 150, 243, 0.3);
        }
        
        .btn-logout {
            background: #f44336;
            color: white;
        }
        
        .btn-logout:hover {
            background: #da190b;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(244, 67, 54, 0.3);
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.15);
            transition: transform 0.3s ease;
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 32px rgba(0,0,0,0.2);
        }
        
        .stat-icon {
            font-size: 48px;
            margin-bottom: 15px;
        }
        
        .stat-value {
            font-size: 36px;
            font-weight: bold;
            color: #333;
            margin-bottom: 5px;
        }
        
        .stat-label {
            color: #666;
            font-size: 14px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .districts-section {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.15);
            margin-bottom: 30px;
        }
        
        .section-title {
            font-size: 24px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 3px solid #667eea;
        }
        
        .districts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 20px;
        }
        
        .district-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px;
            border-radius: 12px;
            cursor: pointer;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        
        .district-card::before {
            content: '';
            position: absolute;
            top: -50%;
            right: -50%;
            width: 200%;
            height: 200%;
            background: rgba(255, 255, 255, 0.1);
            transform: rotate(45deg);
            transition: all 0.5s ease;
        }
        
        .district-card:hover::before {
            top: -100%;
            right: -100%;
        }
        
        .district-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 32px rgba(102, 126, 234, 0.4);
        }
        
        .district-name {
            font-size: 22px;
            font-weight: bold;
            margin-bottom: 15px;
            position: relative;
            z-index: 1;
        }
        
        .district-stats {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 10px;
            position: relative;
            z-index: 1;
        }
        
        .district-stat {
            background: rgba(255, 255, 255, 0.2);
            padding: 10px;
            border-radius: 8px;
            text-align: center;
        }
        
        .district-stat-value {
            font-size: 24px;
            font-weight: bold;
            display: block;
        }
        
        .district-stat-label {
            font-size: 12px;
            opacity: 0.9;
            text-transform: uppercase;
        }
        
        .loading {
            text-align: center;
            padding: 50px;
            color: white;
            font-size: 18px;
        }
        
        .schools-modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            overflow: auto;
            background-color: rgba(0,0,0,0.7);
        }
        
        .modal-content {
            background-color: #fefefe;
            margin: 2% auto;
            padding: 0;
            border-radius: 15px;
            width: 95%;
            max-width: 1400px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
            max-height: 90vh;
            overflow: auto;
        }
        
        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px 30px;
            border-radius: 15px 15px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-header h2 {
            margin: 0;
            font-size: 26px;
        }
        
        .close {
            color: white;
            font-size: 35px;
            font-weight: bold;
            cursor: pointer;
            line-height: 1;
        }
        
        .close:hover {
            opacity: 0.8;
        }
        
        .modal-body {
            padding: 30px;
        }
        
        .schools-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        .schools-table th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
            position: sticky;
            top: 0;
            z-index: 10;
        }
        
        .schools-table td {
            padding: 12px 15px;
            border-bottom: 1px solid #ddd;
        }
        
        .schools-table tr:hover {
            background: #f0f4ff;
        }
        
        .view-students-btn {
            background: #4CAF50;
            color: white;
            border: none;
            padding: 8px 15px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 13px;
            transition: all 0.3s ease;
        }
        
        .view-students-btn:hover {
            background: #45a049;
            transform: scale(1.05);
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #667eea;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div class="header-left">
                <h1>
                    <span style="font-size: 36px;">🏛️</span>
                    VJNT Class Management System
                </h1>
                <p class="header-subtitle">📍 Division Head Dashboard - <%= divisionName %> Division</p>
            </div>
            <div class="header-right">
                <div class="user-info-box">
                    <div class="user-info">
                        <span>👤</span>
                        <span>Welcome, <strong><%= user.getFullName() != null && !user.getFullName().isEmpty() ? user.getFullName() : user.getUsername() %></strong></span>
                    </div>
                    <div class="user-info">
                        <span>🎭</span>
                        <span><strong>Division Head - Latur Division</strong></span>
                    </div>
                </div>
                <a href="<%= request.getContextPath() %>/manage-school-users.jsp" class="btn btn-users">
                    <span>👤</span>
                    <span>Manage Users</span>
                </a>
                <a href="<%= request.getContextPath() %>/change-password" class="btn btn-change-password">
                    <span>🔐</span>
                    <span>Change Password</span>
                </a>
                <a href="<%= request.getContextPath() %>/logout" class="btn btn-logout">
                    <span>🚪</span>
                    <span>Logout</span>
                </a>
            </div>
        </div>
    </div>
    
    <div class="container">
        <!-- Overall Division Statistics -->
        <div class="stats-grid" id="divisionStats">
            <div class="stat-card">
                <div class="stat-icon">🏛️</div>
                <div class="stat-value" id="totalDistricts">-</div>
                <div class="stat-label">Total Districts</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">🏫</div>
                <div class="stat-value" id="totalSchools">-</div>
                <div class="stat-label">Total Schools</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">👨‍🎓</div>
                <div class="stat-value" id="totalStudents">-</div>
                <div class="stat-label">Total Students</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">📚</div>
                <div class="stat-value" id="totalActivities">-</div>
                <div class="stat-label">Total Activities</div>
            </div>
        </div>
        
        <!-- Districts Section -->
        <div class="districts-section">
            <h2 class="section-title">📊 District-wise Overview</h2>
            <div id="loadingIndicator" class="loading">
                <div class="spinner"></div>
                <p>Loading district data...</p>
            </div>
            <div class="districts-grid" id="districtsGrid" style="display: none;">
                <!-- Districts will be loaded here dynamically -->
            </div>
        </div>
    </div>
    
    <!-- Schools Modal -->
    <div id="schoolsModal" class="schools-modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2 id="modalTitle">Schools in District</h2>
                <span class="close" onclick="closeSchoolsModal()">&times;</span>
            </div>
            <div class="modal-body">
                <div id="schoolsContent">
                    <div class="spinner"></div>
                    <p style="text-align: center;">Loading schools...</p>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Student Details Modal (reusing from district dashboard) -->
    <div id="studentDetailsModal" style="display: none; position: fixed; z-index: 1001; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.6);">
        <div style="background-color: #fefefe; margin: 2% auto; padding: 0; border-radius: 10px; width: 90%; max-width: 1200px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <h2 style="margin: 0; font-size: 24px;">📊 Student Details</h2>
                <span onclick="closeStudentModal()" style="cursor: pointer; font-size: 28px; font-weight: bold;">&times;</span>
            </div>
            <div style="padding: 25px; max-height: 70vh; overflow-y: auto;">
                <div id="modalSchoolInfo" style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #667eea;">
                    <h3 style="margin: 0 0 5px 0; color: #333;">Loading...</h3>
                    <p style="margin: 0; color: #666;">Please wait...</p>
                </div>
                <div id="studentSearchContainer" style="display: none; margin-bottom: 20px;">
                    <div style="position: relative;">
                        <input type="text" 
                               id="studentSearchInput" 
                               placeholder="🔍 Search by Name, PEN Number, or Class..." 
                               onkeyup="filterStudents()"
                               style="width: 100%; padding: 12px 40px 12px 15px; border: 2px solid #667eea; border-radius: 8px; font-size: 14px; outline: none;">
                        <button onclick="clearStudentSearch()" 
                                id="clearSearchBtn"
                                style="display: none; position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: #dc3545; color: white; border: none; border-radius: 50%; width: 28px; height: 28px; cursor: pointer; font-size: 14px;">✕</button>
                    </div>
                    <div id="searchResultsInfo" style="margin-top: 8px; font-size: 13px; color: #666;"></div>
                </div>
                <div id="studentDetailsContent" style="min-height: 200px;">
                    <div style="text-align: center; padding: 50px;">
                        <div class="spinner"></div>
                        <p style="margin-top: 15px; color: #666;">Loading student details...</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Load division analytics on page load
        window.onload = function() {
            loadDivisionAnalytics();
        };
        
        function loadDivisionAnalytics() {
            fetch('<%= request.getContextPath() %>/division-analytics')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // Update overall statistics
                        document.getElementById('totalDistricts').textContent = data.divisionStats.districtCount || 0;
                        document.getElementById('totalSchools').textContent = data.divisionStats.totalSchools || 0;
                        document.getElementById('totalStudents').textContent = data.divisionStats.totalStudents || 0;
                        document.getElementById('totalActivities').textContent = data.divisionStats.totalActivities || 0;
                        
                        // Display districts
                        displayDistricts(data.districtStats);
                    } else {
                        console.error('Error loading analytics:', data.message);
                        document.getElementById('loadingIndicator').innerHTML = '<p style="color: red;">Error loading data: ' + (data.message || 'Unknown error') + '</p>';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('loadingIndicator').innerHTML = '<p style="color: red;">Error loading data. Please refresh the page.</p>';
                });
        }
        
        function displayDistricts(districts) {
            const grid = document.getElementById('districtsGrid');
            const loading = document.getElementById('loadingIndicator');
            
            if (!districts || districts.length === 0) {
                loading.innerHTML = '<p>No districts found.</p>';
                return;
            }
            
            let html = '';
            districts.forEach(district => {
                html += '<div class="district-card" onclick="showDistrictSchools(\'' + escapeHtml(district.districtName) + '\')">';
                html += '    <div class="district-name">📍 ' + escapeHtml(district.districtName) + '</div>';
                html += '    <div class="district-stats">';
                html += '        <div class="district-stat">';
                html += '            <span class="district-stat-value">' + (district.schoolCount || 0) + '</span>';
                html += '            <span class="district-stat-label">Schools</span>';
                html += '        </div>';
                html += '        <div class="district-stat">';
                html += '            <span class="district-stat-value">' + (district.studentCount || 0) + '</span>';
                html += '            <span class="district-stat-label">Students</span>';
                html += '        </div>';
                html += '        <div class="district-stat">';
                html += '            <span class="district-stat-value">' + (district.maleCount || 0) + '</span>';
                html += '            <span class="district-stat-label">Male</span>';
                html += '        </div>';
                html += '        <div class="district-stat">';
                html += '            <span class="district-stat-value">' + (district.femaleCount || 0) + '</span>';
                html += '            <span class="district-stat-label">Female</span>';
                html += '        </div>';
                html += '    </div>';
                html += '</div>';
            });
            
            grid.innerHTML = html;
            loading.style.display = 'none';
            grid.style.display = 'grid';
        }
        
        function showDistrictSchools(districtName) {
            const modal = document.getElementById('schoolsModal');
            const title = document.getElementById('modalTitle');
            const content = document.getElementById('schoolsContent');
            
            title.textContent = '🏫 Schools in ' + districtName;
            modal.style.display = 'block';
            
            content.innerHTML = '<div class="spinner"></div><p style="text-align: center;">Loading schools...</p>';
            
            fetch('<%= request.getContextPath() %>/GetDistrictSchoolsServlet?district=' + encodeURIComponent(districtName))
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.schools) {
                        displaySchools(data.schools);
                    } else {
                        content.innerHTML = '<p style="text-align: center; color: red;">Error loading schools: ' + (data.message || 'Unknown error') + '</p>';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    content.innerHTML = '<p style="text-align: center; color: red;">Error loading schools. Please try again.</p>';
                });
        }
        
        function displaySchools(schools) {
            const content = document.getElementById('schoolsContent');
            
            if (!schools || schools.length === 0) {
                content.innerHTML = '<p style="text-align: center;">No schools found in this district.</p>';
                return;
            }
            
            let html = '<table class="schools-table">';
            html += '<thead><tr>';
            html += '<th>Sr No</th>';
            html += '<th>School Name</th>';
            html += '<th>UDISE</th>';
            html += '<th>Students</th>';
            html += '<th>Male</th>';
            html += '<th>Female</th>';
            html += '<th>Activities</th>';
            html += '<th>Phases (1/2/3/4)</th>';
            html += '<th>Action</th>';
            html += '</tr></thead><tbody>';
            
            schools.forEach((school, index) => {
                html += '<tr>';
                html += '<td>' + (index + 1) + '</td>';
                html += '<td><strong>' + escapeHtml(school.schoolName) + '</strong></td>';
                html += '<td>' + escapeHtml(school.udiseNo) + '</td>';
                html += '<td>' + (school.studentCount || 0) + '</td>';
                html += '<td>' + (school.maleCount || 0) + '</td>';
                html += '<td>' + (school.femaleCount || 0) + '</td>';
                html += '<td>' + (school.activityCount || 0) + '</td>';
                html += '<td>' + (school.phase1Count || 0) + '/' + (school.phase2Count || 0) + '/' + (school.phase3Count || 0) + '/' + (school.phase4Count || 0) + '</td>';
                html += '<td><button class="view-students-btn" onclick="showStudentDetails(\'' + escapeHtml(school.udiseNo) + '\', \'' + escapeHtml(school.schoolName) + '\')">👁️ View Students</button></td>';
                html += '</tr>';
            });
            
            html += '</tbody></table>';
            content.innerHTML = html;
        }
        
        function closeSchoolsModal() {
            document.getElementById('schoolsModal').style.display = 'none';
        }
        
        function closeStudentModal() {
            document.getElementById('studentDetailsModal').style.display = 'none';
            clearStudentSearch();
        }
        
        // Student details functions (from district dashboard)
        let currentStudentsData = [];
        
        function showStudentDetails(udise, schoolName) {
            const modal = document.getElementById('studentDetailsModal');
            const modalSchoolInfo = document.getElementById('modalSchoolInfo');
            const content = document.getElementById('studentDetailsContent');
            
            modal.style.display = 'block';
            
            modalSchoolInfo.innerHTML = '<h3 style="margin: 0 0 5px 0; color: #333;">🏫 ' + escapeHtml(schoolName) + '</h3>' +
                '<p style="margin: 0; color: #666;">UDISE: ' + escapeHtml(udise) + '</p>';
            
            content.innerHTML = '<div style="text-align: center; padding: 50px;"><div class="spinner"></div><p style="margin-top: 15px; color: #666;">Loading student details...</p></div>';
            
            fetch('<%= request.getContextPath() %>/GetSchoolStudentsServlet?udise=' + encodeURIComponent(udise))
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.students && data.students.length > 0) {
                        displayStudents(data.students);
                    } else {
                        content.innerHTML = '<div style="text-align: center; color: #999;">No students found for this school.</div>';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    content.innerHTML = '<div style="text-align: center; color: #dc3545;">Error loading student details. Please try again.</div>';
                });
        }
        
        function displayStudents(students) {
            currentStudentsData = students;
            const content = document.getElementById('studentDetailsContent');
            
            let html = '<div style="overflow-x: auto;">';
            html += '<table style="width: 100%; border-collapse: collapse; font-size: 13px;">';
            html += '<thead><tr style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Sr No</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Student Name</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">PEN Number</th>';
            html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Class</th>';
            html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd;">Gender</th>';
            html += '</tr></thead><tbody>';
            
            students.forEach((student, index) => {
                html += '<tr style="background: ' + (index % 2 === 0 ? '#f8f9fa' : '#ffffff') + ';">';
                html += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">' + (index + 1) + '</td>';
                html += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: 600; color: #333;">' + escapeHtml(student.name) + '</td>';
                html += '<td style="padding: 10px; border: 1px solid #ddd; color: #666;">' + escapeHtml(student.penNumber || 'N/A') + '</td>';
                html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">' + escapeHtml(student.studentClass || 'N/A') + '</td>';
                html += '<td style="padding: 10px; border: 1px solid #ddd; text-align: center;">' + escapeHtml(student.gender || 'N/A') + '</td>';
                html += '</tr>';
            });
            
            html += '</tbody></table></div>';
            content.innerHTML = html;
            
            document.getElementById('studentSearchContainer').style.display = 'block';
            updateSearchResultsInfo(students.length, students.length);
        }
        
        function filterStudents() {
            const searchInput = document.getElementById('studentSearchInput');
            const filter = searchInput.value.toUpperCase();
            const table = document.querySelector('#studentDetailsContent table');
            const tbody = table.getElementsByTagName('tbody')[0];
            const tr = tbody.getElementsByTagName('tr');
            
            const clearBtn = document.getElementById('clearSearchBtn');
            clearBtn.style.display = filter ? 'block' : 'none';
            
            let visibleCount = 0;
            
            for (let i = 0; i < tr.length; i++) {
                const tdName = tr[i].getElementsByTagName('td')[1];
                const tdPEN = tr[i].getElementsByTagName('td')[2];
                const tdClass = tr[i].getElementsByTagName('td')[3];
                
                if (tdName || tdPEN || tdClass) {
                    const nameValue = tdName.textContent || tdName.innerText;
                    const penValue = tdPEN.textContent || tdPEN.innerText;
                    const classValue = tdClass.textContent || tdClass.innerText;
                    
                    if (nameValue.toUpperCase().indexOf(filter) > -1 || 
                        penValue.toUpperCase().indexOf(filter) > -1 || 
                        classValue.toUpperCase().indexOf(filter) > -1) {
                        tr[i].style.display = '';
                        visibleCount++;
                    } else {
                        tr[i].style.display = 'none';
                    }
                }
            }
            
            updateSearchResultsInfo(visibleCount, tr.length);
        }
        
        function clearStudentSearch() {
            const searchInput = document.getElementById('studentSearchInput');
            searchInput.value = '';
            filterStudents();
        }
        
        function updateSearchResultsInfo(visibleCount, totalCount) {
            const infoDiv = document.getElementById('searchResultsInfo');
            if (visibleCount === totalCount) {
                infoDiv.innerHTML = '<span style="color: #666;">Showing all <strong>' + totalCount + '</strong> students</span>';
            } else {
                infoDiv.innerHTML = '<span style="color: #667eea;">Showing <strong>' + visibleCount + '</strong> of <strong>' + totalCount + '</strong> students</span>';
            }
        }
        
        function escapeHtml(text) {
            if (!text) return '';
            const map = {
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&#039;'
            };
            return text.toString().replace(/[&<>"']/g, m => map[m]);
        }
        
        // Close modals when clicking outside
        window.onclick = function(event) {
            const schoolsModal = document.getElementById('schoolsModal');
            const studentModal = document.getElementById('studentDetailsModal');
            if (event.target == schoolsModal) {
                closeSchoolsModal();
            }
            if (event.target == studentModal) {
                closeStudentModal();
            }
        }
    </script>
</body>
</html>
