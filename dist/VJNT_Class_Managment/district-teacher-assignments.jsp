<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.vjnt.util.DatabaseConnection" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String districtName = user.getDistrictName();
    
    // Get unique UDISE codes for filter dropdown
    List<Map<String, String>> schools = new ArrayList<>();
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        String sql = "SELECT DISTINCT s.udise_no, s.school_name " +
                     "FROM schools s " +
                     "INNER JOIN teacher_assignments ta ON s.udise_no COLLATE utf8mb4_unicode_ci = ta.udise_code COLLATE utf8mb4_unicode_ci " +
                     "WHERE ta.district = ? AND ta.is_active = 1 " +
                     "ORDER BY s.school_name";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, districtName);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, String> school = new HashMap<>();
            school.put("udise", rs.getString("udise_no"));
            school.put("name", rs.getString("school_name"));
            schools.add(school);
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
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Teacher Assignments - <%= districtName %> District</title>
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
            max-width: 1600px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .header p {
            opacity: 0.9;
            font-size: 14px;
        }
        
        .content {
            padding: 30px;
        }
        
        .filters {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            align-items: end;
        }
        
        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        
        .filter-group label {
            font-size: 13px;
            font-weight: 600;
            color: #333;
        }
        
        .filter-group select,
        .filter-group input {
            padding: 10px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .filter-group select:focus,
        .filter-group input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .btn-primary {
            background: #667eea;
            color: white;
        }
        
        .btn-primary:hover {
            background: #5568d3;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
        }
        
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        
        .btn-secondary:hover {
            background: #5a6268;
        }
        
        .btn-export {
            background: #28a745;
            color: white;
            margin-left: auto;
        }
        
        .btn-export:hover {
            background: #218838;
        }
        
        .stats-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        
        .stat-card h3 {
            font-size: 32px;
            margin-bottom: 5px;
        }
        
        .stat-card p {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .table-container {
            overflow-x: auto;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
        }
        
        thead {
            background: #f8f9fa;
            position: sticky;
            top: 0;
            z-index: 10;
        }
        
        th {
            padding: 15px 12px;
            text-align: left;
            font-weight: 600;
            color: #333;
            font-size: 13px;
            border-bottom: 2px solid #e0e0e0;
            white-space: nowrap;
        }
        
        td {
            padding: 12px;
            border-bottom: 1px solid #f0f0f0;
            font-size: 13px;
            color: #555;
        }
        
        tbody tr:hover {
            background: #f8f9fa;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
        }
        
        .badge-success {
            background: #d4edda;
            color: #155724;
        }
        
        .badge-info {
            background: #d1ecf1;
            color: #0c5460;
        }
        
        .badge-warning {
            background: #fff3cd;
            color: #856404;
        }
        
        .subjects-list {
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
        }
        
        .subject-tag {
            background: #e3f2fd;
            color: #1976d2;
            padding: 3px 8px;
            border-radius: 6px;
            font-size: 11px;
            font-weight: 500;
        }
        
        .loading {
            text-align: center;
            padding: 40px;
            color: #666;
        }
        
        .spinner {
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
        
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }
        
        .empty-state-icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        
        .back-link {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            color: white;
            text-decoration: none;
            margin-bottom: 20px;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .back-link:hover {
            opacity: 0.8;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .filters, .btn-export, .back-link {
                display: none !important;
            }
            
            .container {
                box-shadow: none;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <a href="<%= request.getContextPath() %>/district-dashboard.jsp" class="back-link">
                ← Back to Dashboard
            </a>
            <h1>👨‍🏫 Teacher Assignment Details</h1>
            <p><%= districtName %> District - Complete Teacher Assignment Report</p>
        </div>
        
        <div class="content">
            <!-- Filters -->
            <div class="filters">
                <div class="filter-group" style="position: relative;">
                    <label for="schoolSearchInput">School (Type Name or UDISE)</label>
                    <input type="text" 
                           id="schoolSearchInput" 
                           placeholder="🔍 Type school name or UDISE code..." 
                           autocomplete="off"
                           style="width: 100%;">
                    <input type="hidden" id="schoolFilter" value="">
                    <div id="schoolDropdownList" style="display: none; position: absolute; top: 100%; left: 0; right: 0; background: white; border: 2px solid #667eea; border-radius: 6px; max-height: 300px; overflow-y: auto; z-index: 1000; margin-top: 5px; box-shadow: 0 4px 12px rgba(0,0,0,0.15);">
                        <!-- Dropdown options will be populated by JavaScript -->
                    </div>
                    <div id="selectedSchoolBadge" style="display: none; margin-top: 8px; padding: 8px 12px; background: #e8f5e9; border-radius: 6px; border-left: 4px solid #4caf50; font-size: 13px; color: #2e7d32;">
                        <span id="selectedSchoolText"></span>
                        <button type="button" onclick="clearSchoolFilter()" style="background: #f44336; color: white; border: none; padding: 2px 8px; border-radius: 4px; margin-left: 10px; cursor: pointer; font-size: 11px;">✕ Clear</button>
                    </div>
                </div>
                
                <div class="filter-group">
                    <label for="classFilter">Class</label>
                    <select id="classFilter">
                        <option value="">All Classes</option>
                        <option value="1">Class 1</option>
                        <option value="2">Class 2</option>
                        <option value="3">Class 3</option>
                        <option value="4">Class 4</option>
                        <option value="5">Class 5</option>
                    </select>
                </div>
                
                <div class="filter-group">
                    <label for="sectionFilter">Section</label>
                    <select id="sectionFilter">
                        <option value="">All Sections</option>
                        <option value="A">Section A</option>
                        <option value="B">Section B</option>
                        <option value="C">Section C</option>
                        <option value="D">Section D</option>
                    </select>
                </div>
                
                <div class="filter-group" style="display: flex; flex-direction: row; gap: 10px;">
                    <button class="btn btn-primary" onclick="applyFilters()">🔍 Search</button>
                    <button class="btn btn-secondary" onclick="resetFilters()">🔄 Reset</button>
                    <button class="btn btn-export" onclick="exportToExcel()">📊 Export Excel</button>
                </div>
            </div>
            
            <!-- Statistics Cards -->
            <div class="stats-cards" id="statsCards" style="display: none;">
                <div class="stat-card">
                    <h3 id="totalAssignments">0</h3>
                    <p>Total Assignments</p>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);">
                    <h3 id="totalTeachers">0</h3>
                    <p>Unique Teachers</p>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);">
                    <h3 id="totalSchools">0</h3>
                    <p>Schools</p>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);">
                    <h3 id="classTeachers">0</h3>
                    <p>Class Teachers</p>
                </div>
            </div>
            
            <!-- Loading State -->
            <div id="loadingState" class="loading">
                <div class="spinner"></div>
                <p>Loading teacher assignments...</p>
            </div>
            
            <!-- Table -->
            <div class="table-container" id="tableContainer" style="display: none;">
                <table id="assignmentsTable">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>UDISE Code</th>
                            <th>School Name</th>
                            <th>School Type</th>
                            <th>Teacher Name</th>
                            <th>Class</th>
                            <th>Section</th>
                            <th>Subjects Assigned</th>
                            <th>Class Teacher</th>
                            <th>Division</th>
                            <th>Assigned Date</th>
                        </tr>
                    </thead>
                    <tbody id="assignmentsBody">
                        <!-- Data will be loaded here -->
                    </tbody>
                </table>
            </div>
            
            <!-- Pagination Controls -->
            <div id="paginationControls" style="display: none; margin-top: 30px; padding: 20px; background: #f8f9fa; border-radius: 10px;">
                <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 15px;">
                    <div style="font-size: 14px; color: #666;">
                        Showing <strong id="showingStart">1</strong> to <strong id="showingEnd">50</strong> of <strong id="totalRecords">0</strong> assignments
                    </div>
                    <div style="display: flex; gap: 10px; align-items: center;">
                        <button id="prevPageBtn" onclick="previousPage()" class="btn btn-secondary" style="padding: 8px 16px;">
                            ← Previous
                        </button>
                        <div style="display: flex; gap: 5px;" id="pageNumbers"></div>
                        <button id="nextPageBtn" onclick="nextPage()" class="btn btn-secondary" style="padding: 8px 16px;">
                            Next →
                        </button>
                    </div>
                    <div>
                        <label for="pageSizeSelect" style="margin-right: 8px; font-size: 14px; color: #666;">Records per page:</label>
                        <select id="pageSizeSelect" onchange="changePageSize()" style="padding: 6px 10px; border: 2px solid #e0e0e0; border-radius: 6px;">
                            <option value="25">25</option>
                            <option value="50" selected>50</option>
                            <option value="100">100</option>
                            <option value="200">200</option>
                        </select>
                    </div>
                </div>
            </div>
            
            <!-- Empty State -->
            <div id="emptyState" class="empty-state" style="display: none;">
                <div class="empty-state-icon">📋</div>
                <p>No teacher assignments found</p>
            </div>
        </div>
    </div>
    
    <script>
        // Pagination state
        let currentPage = 1;
        let pageSize = 50;
        let totalPages = 1;
        let totalCount = 0;
        
        // Schools data for search
        const schoolsData = [
            <% for (int i = 0; i < schools.size(); i++) { 
                Map<String, String> s = schools.get(i);
            %>
            {
                udise: "<%= s.get("udise") %>",
                name: "<%= s.get("name") != null ? s.get("name").replace("\"", "\\\"") : "" %>"
            }<%= i < schools.size() - 1 ? "," : "" %>
            <% } %>
        ];
        
        // School search functionality
        const schoolSearchInput = document.getElementById('schoolSearchInput');
        const schoolDropdownList = document.getElementById('schoolDropdownList');
        const schoolFilterHidden = document.getElementById('schoolFilter');
        const selectedSchoolBadge = document.getElementById('selectedSchoolBadge');
        const selectedSchoolText = document.getElementById('selectedSchoolText');
        
        schoolSearchInput.addEventListener('input', function() {
            const searchTerm = this.value.toLowerCase().trim();
            
            if (searchTerm.length === 0) {
                schoolDropdownList.style.display = 'none';
                return;
            }
            
            // Filter schools by name OR UDISE
            const filtered = schoolsData.filter(school => 
                school.udise.toLowerCase().includes(searchTerm) || 
                school.name.toLowerCase().includes(searchTerm)
            );
            
            // Display results
            if (filtered.length > 0) {
                let html = '';
                filtered.slice(0, 15).forEach(school => {
                    html += '<div style="padding: 10px 15px; cursor: pointer; border-bottom: 1px solid #f0f0f0; transition: background 0.2s;" ' +
                            'onmouseover="this.style.background=\'#f5f5ff\'" ' +
                            'onmouseout="this.style.background=\'white\'" ' +
                            'onclick="selectSchool(\'' + school.udise + '\', \'' + school.name.replace(/'/g, "\\'") + '\')">' +
                            '<div style="font-weight: 600; color: #667eea; font-size: 13px;">🏫 ' + school.udise + '</div>' +
                            '<div style="color: #333; font-size: 12px; margin-top: 3px;">' + school.name + '</div>' +
                            '</div>';
                });
                schoolDropdownList.innerHTML = html;
                schoolDropdownList.style.display = 'block';
            } else {
                schoolDropdownList.innerHTML = '<div style="padding: 15px; text-align: center; color: #999; font-size: 13px;">No schools found</div>';
                schoolDropdownList.style.display = 'block';
            }
        });
        
        // Select school function
        function selectSchool(udise, name) {
            schoolFilterHidden.value = udise;
            schoolSearchInput.value = '';
            schoolDropdownList.style.display = 'none';
            
            // Show selected school badge
            selectedSchoolText.innerHTML = '<strong>Selected:</strong> ' + name + ' (' + udise + ')';
            selectedSchoolBadge.style.display = 'block';
        }
        
        // Clear school filter
        function clearSchoolFilter() {
            schoolFilterHidden.value = '';
            schoolSearchInput.value = '';
            selectedSchoolBadge.style.display = 'none';
            schoolDropdownList.style.display = 'none';
        }
        
        // Close dropdown when clicking outside
        document.addEventListener('click', function(e) {
            if (!schoolSearchInput.contains(e.target) && !schoolDropdownList.contains(e.target)) {
                schoolDropdownList.style.display = 'none';
            }
        });
        
        // Load assignments on page load
        window.addEventListener('DOMContentLoaded', function() {
            loadAssignments();
        });
        
        function loadAssignments() {
            const udise = document.getElementById('schoolFilter').value;
            const classValue = document.getElementById('classFilter').value;
            const section = document.getElementById('sectionFilter').value;
            
            // Build URL with filters and pagination
            let url = '<%= request.getContextPath() %>/get-district-teacher-assignments?';
            url += 'page=' + currentPage + '&';
            url += 'pageSize=' + pageSize + '&';
            if (udise) url += 'udise=' + encodeURIComponent(udise) + '&';
            if (classValue) url += 'class=' + encodeURIComponent(classValue) + '&';
            if (section) url += 'section=' + encodeURIComponent(section);
            
            // Show loading state
            document.getElementById('loadingState').style.display = 'block';
            document.getElementById('tableContainer').style.display = 'none';
            document.getElementById('emptyState').style.display = 'none';
            document.getElementById('statsCards').style.display = 'none';
            document.getElementById('paginationControls').style.display = 'none';
            
            fetch(url)
                .then(response => response.json())
                .then(data => {
                    document.getElementById('loadingState').style.display = 'none';
                    
                    if (data.success && data.assignments.length > 0) {
                        totalPages = data.totalPages;
                        totalCount = data.totalCount;
                        
                        displayAssignments(data.assignments);
                        updateStatistics(data.assignments, data.totalCount);
                        updatePaginationControls(data);
                        
                        document.getElementById('tableContainer').style.display = 'block';
                        document.getElementById('statsCards').style.display = 'grid';
                        document.getElementById('paginationControls').style.display = 'block';
                    } else {
                        document.getElementById('emptyState').style.display = 'block';
                    }
                })
                .catch(error => {
                    console.error('Error loading assignments:', error);
                    document.getElementById('loadingState').style.display = 'none';
                    document.getElementById('emptyState').style.display = 'block';
                    alert('Error loading teacher assignments. Please try again.');
                });
        }
        
        function displayAssignments(assignments) {
            const tbody = document.getElementById('assignmentsBody');
            tbody.innerHTML = '';
            
            assignments.forEach((assignment, index) => {
                const row = tbody.insertRow();
                
                // Build subjects HTML
                const subjectsArray = assignment.subjects.split(',');
                let subjectsHtml = '<div class="subjects-list">';
                subjectsArray.forEach(subject => {
                    subjectsHtml += '<span class="subject-tag">' + subject.trim() + '</span>';
                });
                subjectsHtml += '</div>';
                
                // Build class teacher HTML
                const classTeacherHtml = assignment.isClassTeacher ? 
                    '<span class="badge badge-success">✓ Yes</span>' : 
                    '<span style="color: #999;">No</span>';
                
                row.innerHTML = 
                    '<td>' + (index + 1) + '</td>' +
                    '<td><strong>' + assignment.udiseCode + '</strong></td>' +
                    '<td>' + (assignment.schoolName || 'N/A') + '</td>' +
                    '<td><span class="badge badge-info">' + (assignment.schoolType || 'N/A') + '</span></td>' +
                    '<td><strong>' + assignment.teacherName + '</strong></td>' +
                    '<td><span class="badge badge-warning">Class ' + assignment.classValue + '</span></td>' +
                    '<td><span class="badge badge-warning">Section ' + assignment.section + '</span></td>' +
                    '<td>' + subjectsHtml + '</td>' +
                    '<td>' + classTeacherHtml + '</td>' +
                    '<td>' + (assignment.division || 'N/A') + '</td>' +
                    '<td>' + new Date(assignment.createdDate).toLocaleDateString('en-IN') + '</td>';
            });
        }
        
        function updateStatistics(assignments, totalCount) {
            const uniqueTeachers = new Set(assignments.map(a => a.teacherId)).size;
            const uniqueSchools = new Set(assignments.map(a => a.udiseCode)).size;
            const classTeachersCount = assignments.filter(a => a.isClassTeacher).length;
            
            document.getElementById('totalAssignments').textContent = totalCount || assignments.length;
            document.getElementById('totalTeachers').textContent = uniqueTeachers;
            document.getElementById('totalSchools').textContent = uniqueSchools;
            document.getElementById('classTeachers').textContent = classTeachersCount;
        }
        
        function updatePaginationControls(data) {
            // Update showing text
            const start = (data.currentPage - 1) * data.pageSize + 1;
            const end = Math.min(data.currentPage * data.pageSize, data.totalCount);
            document.getElementById('showingStart').textContent = start;
            document.getElementById('showingEnd').textContent = end;
            document.getElementById('totalRecords').textContent = data.totalCount;
            
            // Update buttons
            document.getElementById('prevPageBtn').disabled = !data.hasPrevious;
            document.getElementById('nextPageBtn').disabled = !data.hasNext;
            
            // Generate page numbers
            const pageNumbersDiv = document.getElementById('pageNumbers');
            pageNumbersDiv.innerHTML = '';
            
            const maxVisiblePages = 5;
            let startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
            let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);
            
            if (endPage - startPage < maxVisiblePages - 1) {
                startPage = Math.max(1, endPage - maxVisiblePages + 1);
            }
            
            for (let i = startPage; i <= endPage; i++) {
                const pageBtn = document.createElement('button');
                pageBtn.textContent = i;
                pageBtn.className = 'btn btn-secondary';
                pageBtn.style.padding = '8px 12px';
                pageBtn.style.minWidth = '40px';
                if (i === currentPage) {
                    pageBtn.style.background = '#667eea';
                    pageBtn.style.color = 'white';
                }
                pageBtn.onclick = () => goToPage(i);
                pageNumbersDiv.appendChild(pageBtn);
            }
        }
        
        function goToPage(page) {
            currentPage = page;
            loadAssignments();
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
        
        function previousPage() {
            if (currentPage > 1) {
                currentPage--;
                loadAssignments();
                window.scrollTo({ top: 0, behavior: 'smooth' });
            }
        }
        
        function nextPage() {
            if (currentPage < totalPages) {
                currentPage++;
                loadAssignments();
                window.scrollTo({ top: 0, behavior: 'smooth' });
            }
        }
        
        function changePageSize() {
            pageSize = parseInt(document.getElementById('pageSizeSelect').value);
            currentPage = 1; // Reset to first page
            loadAssignments();
        }
        
        function applyFilters() {
            currentPage = 1; // Reset to page 1 when applying filters
            loadAssignments();
        }
        
        function resetFilters() {
            document.getElementById('schoolFilter').value = '';
            document.getElementById('classFilter').value = '';
            document.getElementById('sectionFilter').value = '';
            clearSchoolFilter();
            currentPage = 1; // Reset to first page
            loadAssignments();
        }
        
        function exportToExcel() {
            const table = document.getElementById('assignmentsTable');
            let html = table.outerHTML;
            const url = 'data:application/vnd.ms-excel,' + encodeURIComponent(html);
            const link = document.createElement('a');
            link.href = url;
            link.download = 'Teacher_Assignments_<%= districtName %>_' + new Date().toISOString().split('T')[0] + '.xls';
            link.click();
        }
    </script>
</body>
</html>
