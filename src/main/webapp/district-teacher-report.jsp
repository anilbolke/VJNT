<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.vjnt.util.DatabaseConnection" %>
<%@ page import="java.util.*" %>

<%
    // Check if user is logged in and is a district coordinator
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String districtName = user.getDistrictName();
    
    // Get school-wise teacher count
    List<Map<String, Object>> schoolData = new ArrayList<>();
    int totalTeachers = 0;
    int totalSchools = 0;
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        
        // Get school-wise teacher count for this district
        String sql = "SELECT s.udise_no, s.school_name, s.district_name, " +
                     "COUNT(t.teacher_id) as teacher_count " +
                     "FROM schools s " +
                     "LEFT JOIN teachers t ON s.udise_no = t.udise_code AND t.is_active = 1 " +
                     "WHERE s.district_name = ? " +
                     "GROUP BY s.udise_no, s.school_name, s.district_name " +
                     "ORDER BY s.school_name";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, districtName);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> school = new HashMap<>();
            school.put("udiseCode", rs.getString("udise_no"));
            school.put("schoolName", rs.getString("school_name"));
            school.put("district", rs.getString("district_name"));
            school.put("teacherCount", rs.getInt("teacher_count"));
            schoolData.add(school);
            
            totalTeachers += rs.getInt("teacher_count");
            totalSchools++;
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
        if (conn != null) try { conn.close(); } catch (SQLException e) { }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>District Teacher Report - <%= districtName %></title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f7fa;
            min-height: 100vh;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .header-content {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .header-left h1 {
            font-size: 24px;
            margin-bottom: 5px;
        }
        
        .header-left p {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .btn {
            padding: 10px 20px;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: all 0.3s;
            border: none;
            cursor: pointer;
            display: inline-block;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.3);
        }
        
        .btn-back {
            background: rgba(255,255,255,0.2);
            color: white;
            margin-right: 10px;
        }
        
        .btn-back:hover {
            background: rgba(255,255,255,0.3);
        }
        
        .container {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 30px;
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
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            text-align: center;
        }
        
        .stat-icon {
            font-size: 48px;
            margin-bottom: 10px;
        }
        
        .stat-value {
            font-size: 36px;
            font-weight: 700;
            color: #667eea;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 14px;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .section {
            background: white;
            border-radius: 12px;
            padding: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            margin-bottom: 30px;
        }
        
        .section-title {
            font-size: 20px;
            color: #333;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .search-box {
            margin-bottom: 20px;
            display: flex;
            gap: 15px;
            align-items: center;
            flex-wrap: wrap;
        }
        
        .search-input {
            flex: 1;
            min-width: 250px;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .search-input:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .table-container {
            overflow-x: auto;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
        }
        
        thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 12px;
            letter-spacing: 1px;
        }
        
        td {
            padding: 15px;
            border-bottom: 1px solid #f0f0f0;
        }
        
        tbody tr {
            transition: background 0.2s;
        }
        
        tbody tr:hover {
            background: #f8f9fa;
        }
        
        .teacher-count-badge {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .teacher-count-badge:hover {
            background: #764ba2;
            transform: scale(1.05);
        }
        
        .teacher-count-badge.zero {
            background: #e0e0e0;
            color: #666;
            cursor: default;
        }
        
        .teacher-count-badge.zero:hover {
            background: #e0e0e0;
            transform: none;
        }
        
        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.5);
            animation: fadeIn 0.3s;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        .modal-content {
            background-color: white;
            margin: 2% auto;
            padding: 0;
            border-radius: 15px;
            width: 90%;
            max-width: 1000px;
            max-height: 90vh;
            overflow: hidden;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            animation: slideDown 0.3s;
        }
        
        @keyframes slideDown {
            from {
                transform: translateY(-50px);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }
        
        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-header h2 {
            font-size: 22px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .modal-header .school-info {
            font-size: 14px;
            opacity: 0.9;
            margin-top: 5px;
        }
        
        .close {
            color: white;
            font-size: 35px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s;
            line-height: 1;
        }
        
        .close:hover {
            transform: rotate(90deg);
        }
        
        .modal-body {
            padding: 30px;
            max-height: calc(90vh - 150px);
            overflow-y: auto;
            overflow-x: hidden;
        }
        
        /* Custom scrollbar for modal */
        .modal-body::-webkit-scrollbar {
            width: 8px;
        }
        
        .modal-body::-webkit-scrollbar-track {
            background: #f1f1f1;
            border-radius: 10px;
        }
        
        .modal-body::-webkit-scrollbar-thumb {
            background: #667eea;
            border-radius: 10px;
        }
        
        .modal-body::-webkit-scrollbar-thumb:hover {
            background: #764ba2;
        }
        
        .teacher-card {
            background: #ffffff;
            border: 1px solid #e0e0e0;
            border-left: 5px solid #667eea;
            padding: 25px;
            margin-bottom: 20px;
            border-radius: 10px;
            transition: all 0.3s;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            clear: both;
            display: block;
            width: 100%;
        }
        
        .teacher-card:last-child {
            margin-bottom: 0;
        }
        
        .teacher-card:hover {
            background: #f8f9fa;
            transform: translateX(5px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
            border-left-color: #764ba2;
        }
        
        .teacher-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 18px;
            flex-wrap: wrap;
            gap: 10px;
        }
        
        .teacher-name {
            font-size: 20px;
            font-weight: 700;
            color: #333;
            display: flex;
            align-items: center;
            gap: 10px;
            flex: 1;
            min-width: 200px;
        }
        
        .teacher-info {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-bottom: 12px;
            width: 100%;
        }
        
        .info-item {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            font-size: 14px;
            color: #555;
            background: #f8f9fa;
            padding: 10px 12px;
            border-radius: 6px;
            word-wrap: break-word;
            word-break: break-word;
        }
        
        .info-item span:last-child {
            flex: 1;
            word-wrap: break-word;
            overflow-wrap: break-word;
        }
        
        .info-icon {
            font-size: 18px;
            flex-shrink: 0;
        }
        
        .info-label {
            font-weight: 600;
            color: #667eea;
            margin-right: 5px;
        }
        
        .teacher-description {
            margin-top: 15px;
            padding-top: 15px;
            border-top: 2px solid #e0e0e0;
            font-size: 14px;
            color: #666;
            line-height: 1.8;
            background: #f8f9fa;
            padding: 15px;
            border-radius: 6px;
            word-wrap: break-word;
            word-break: break-word;
        }
        
        .teacher-description strong {
            color: #667eea;
            display: block;
            margin-bottom: 8px;
        }
        
        .no-teachers {
            text-align: center;
            padding: 40px;
            color: #999;
            font-size: 16px;
        }
        
        .no-teachers-icon {
            font-size: 64px;
            margin-bottom: 15px;
        }
        
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }
        
        .empty-state-icon {
            font-size: 80px;
            margin-bottom: 20px;
        }
        
        .badge {
            display: inline-block;
            padding: 6px 14px;
            border-radius: 15px;
            font-size: 13px;
            font-weight: 700;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            box-shadow: 0 2px 6px rgba(102, 126, 234, 0.3);
            white-space: nowrap;
        }
        
        @media (max-width: 768px) {
            .container {
                padding: 0 15px;
            }
            
            .header-content {
                flex-direction: column;
                align-items: stretch;
            }
            
            .stats-grid {
                grid-template-columns: 1fr;
            }
            
            .modal-content {
                width: 95%;
                margin: 5% auto;
            }
            
            .table-container {
                overflow-x: auto;
            }
            
            table {
                font-size: 14px;
            }
            
            th, td {
                padding: 10px 8px;
            }
            
            .teacher-info {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <div class="header">
        <div class="header-content">
            <div class="header-left">
                <h1>👨‍🏫 District Teacher Report</h1>
                <p>District: <%= districtName %> | User: <%= user.getFullName() != null && !user.getFullName().isEmpty() ? user.getFullName() : user.getUsername() %></p>
            </div>
            <div>
                <a href="<%= request.getContextPath() %>/district-dashboard.jsp" class="btn btn-back">
                    ← Back to Dashboard
                </a>
                <a href="<%= request.getContextPath() %>/district-profile" class="btn" style="background: #2196F3;">👤 My Profile</a>
                <a href="<%= request.getContextPath() %>/logout" class="btn">Logout</a>
            </div>
        </div>
    </div>

    <div class="container">
        <!-- Statistics -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon">🏫</div>
                <div class="stat-value"><%= totalSchools %></div>
                <div class="stat-label">Total Schools</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">👨‍🏫</div>
                <div class="stat-value"><%= totalTeachers %></div>
                <div class="stat-label">Total Teachers</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">📊</div>
                <div class="stat-value"><%= totalSchools > 0 ? String.format("%.1f", (double)totalTeachers/totalSchools) : "0" %></div>
                <div class="stat-label">Avg Teachers/School</div>
            </div>
        </div>

        <!-- School-wise Teacher List -->
        <div class="section">
            <h2 class="section-title">
                <span>🏫</span>
                School-wise Teacher Count
            </h2>
            
            <div class="search-box">
                <input type="text" id="searchInput" class="search-input" 
                       placeholder="🔍 Search by School Name or UDISE Code..." 
                       onkeyup="filterTable()">
                <span id="resultCount" style="color: #666; font-size: 14px;">
                    Showing <%= schoolData.size() %> schools
                </span>
            </div>

            <% if (schoolData.isEmpty()) { %>
                <div class="empty-state">
                    <div class="empty-state-icon">📋</div>
                    <h3>No Schools Found</h3>
                    <p>No schools registered in <%= districtName %> district.</p>
                </div>
            <% } else { %>
                <div class="table-container">
                    <table id="schoolTable">
                        <thead>
                            <tr>
                                <th>Sr. No.</th>
                                <th>UDISE Code</th>
                                <th>School Name</th>
                                <th style="text-align: center;">Teacher Count</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% 
                            int srNo = 1;
                            for (Map<String, Object> school : schoolData) { 
                                String udiseCode = (String) school.get("udiseCode");
                                String schoolName = (String) school.get("schoolName");
                                int teacherCount = (int) school.get("teacherCount");
                            %>
                                <tr>
                                    <td><%= srNo++ %></td>
                                    <td><strong><%= udiseCode %></strong></td>
                                    <td><%= schoolName %></td>
                                    <td style="text-align: center;">
                                        <% if (teacherCount > 0) { %>
                                            <span class="teacher-count-badge" 
                                                  onclick="showTeachers('<%= udiseCode %>', '<%= schoolName.replace("'", "\\'") %>')">
                                                <%= teacherCount %> <%= teacherCount == 1 ? "Teacher" : "Teachers" %>
                                            </span>
                                        <% } else { %>
                                            <span class="teacher-count-badge zero">
                                                0 Teachers
                                            </span>
                                        <% } %>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            <% } %>
        </div>
    </div>

    <!-- Teacher Details Modal -->
    <div id="teacherModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <div>
                    <h2 id="modalTitle">👨‍🏫 Teacher Details</h2>
                    <div class="school-info">
                        <span id="modalSchoolName"></span> | UDISE: <span id="modalUdiseCode"></span>
                    </div>
                </div>
                <span class="close" onclick="closeModal()">&times;</span>
            </div>
            <div class="modal-body" id="modalBody">
                <div style="text-align: center; padding: 40px;">
                    <div style="font-size: 48px; margin-bottom: 15px;">⏳</div>
                    <p>Loading teacher details...</p>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Filter table based on search input
        function filterTable() {
            const input = document.getElementById('searchInput');
            const filter = input.value.toUpperCase();
            const table = document.getElementById('schoolTable');
            const tbody = table.getElementsByTagName('tbody')[0];
            const rows = tbody.getElementsByTagName('tr');
            let visibleCount = 0;

            for (let i = 0; i < rows.length; i++) {
                const cells = rows[i].getElementsByTagName('td');
                let found = false;
                
                // Search in UDISE and School Name columns (columns 1-2)
                for (let j = 1; j <= 2; j++) {
                    if (cells[j]) {
                        const txtValue = cells[j].textContent || cells[j].innerText;
                        if (txtValue.toUpperCase().indexOf(filter) > -1) {
                            found = true;
                            break;
                        }
                    }
                }
                
                if (found) {
                    rows[i].style.display = '';
                    visibleCount++;
                } else {
                    rows[i].style.display = 'none';
                }
            }
            
            document.getElementById('resultCount').textContent = 
                'Showing ' + visibleCount + ' school' + (visibleCount !== 1 ? 's' : '');
        }

        // Show teacher details in modal
        function showTeachers(udiseCode, schoolName) {
            const modal = document.getElementById('teacherModal');
            const modalBody = document.getElementById('modalBody');
            const modalSchoolName = document.getElementById('modalSchoolName');
            const modalUdiseCode = document.getElementById('modalUdiseCode');
            
            modalSchoolName.textContent = schoolName;
            modalUdiseCode.textContent = udiseCode;
            
            // Show loading state
            modalBody.innerHTML = '<div style="text-align: center; padding: 40px;">' +
                '<div style="font-size: 48px; margin-bottom: 15px;">⏳</div>' +
                '<p>Loading teacher details...</p>' +
                '</div>';
            
            modal.style.display = 'block';
            
            // Fetch teacher details using AJAX
            fetch('getTeachersBySchool.jsp?udiseCode=' + encodeURIComponent(udiseCode))
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.teachers.length > 0) {
                        let html = '';
                        data.teachers.forEach((teacher, index) => {
                            // Escape HTML to prevent XSS
                            const safeName = escapeHtml(teacher.name);
                            const safeMobile = escapeHtml(teacher.mobile);
                            const safeSubjects = escapeHtml(teacher.subjects);
                            const safeDate = escapeHtml(teacher.createdDate);
                            const safeDescription = teacher.description ? escapeHtml(teacher.description) : null;
                            
                            html += '<div class="teacher-card">' +
                                '<div class="teacher-header">' +
                                '<div class="teacher-name">' +
                                '<span>👤</span>' +
                                '<span>' + safeName + '</span>' +
                                '</div>' +
                                '<span class="badge">ID: ' + teacher.id + '</span>' +
                                '</div>' +
                                '<div class="teacher-info">' +
                                '<div class="info-item">' +
                                '<span class="info-icon">📱</span>' +
                                '<span><span class="info-label">Mobile:</span>' + safeMobile + '</span>' +
                                '</div>' +
                                '<div class="info-item">' +
                                '<span class="info-icon">📚</span>' +
                                '<span><span class="info-label">Subjects:</span>' + safeSubjects + '</span>' +
                                '</div>' +
                                '<div class="info-item">' +
                                '<span class="info-icon">📅</span>' +
                                '<span><span class="info-label">Added:</span>' + safeDate + '</span>' +
                                '</div>' +
                                '</div>';
                            
                            if (safeDescription) {
                                html += '<div class="teacher-description">' +
                                    '<strong>📝 Description:</strong>' +
                                    '<div>' + safeDescription + '</div>' +
                                    '</div>';
                            }
                            
                            html += '</div>';
                        });
                        modalBody.innerHTML = html;
                    } else {
                        modalBody.innerHTML = '<div class="no-teachers">' +
                            '<div class="no-teachers-icon">👨‍🏫</div>' +
                            '<p>No teachers found for this school.</p>' +
                            '</div>';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    modalBody.innerHTML = '<div class="no-teachers">' +
                        '<div class="no-teachers-icon">❌</div>' +
                        '<p>Error loading teacher details. Please try again.</p>' +
                        '</div>';
                });
        }
        
        // Escape HTML to prevent XSS attacks
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        // Close modal
        function closeModal() {
            document.getElementById('teacherModal').style.display = 'none';
        }

        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('teacherModal');
            if (event.target == modal) {
                modal.style.display = 'none';
            }
        }

        // Close modal with Escape key
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeModal();
            }
        });
    </script>
</body>
</html>
