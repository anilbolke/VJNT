<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
    
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    // Check if user is district coordinator
    String userTypeStr = user.getUserType() != null ? user.getUserType().toString() : "";
    if (!userTypeStr.contains("DISTRICT")) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String districtName = user.getDistrictName();
    if (districtName == null || districtName.trim().isEmpty()) {
        out.println("<h3 style='color:red; text-align:center; padding:50px;'>Error: District name not found for user</h3>");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Activity Analysis - <%= districtName %></title>
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
            padding: 30px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 3px solid #667eea;
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
        
        .back-btn {
            display: inline-block;
            padding: 10px 20px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-bottom: 20px;
            transition: background 0.3s;
        }
        
        .back-btn:hover {
            background: #5568d3;
        }
        
        .loading {
            text-align: center;
            padding: 50px;
            font-size: 18px;
            color: #667eea;
        }
        
        .school-card {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .filter-section {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        
        .filter-title {
            font-size: 18px;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 15px;
        }
        
        .filter-controls {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            align-items: end;
        }
        
        .filter-group {
            display: flex;
            flex-direction: column;
        }
        
        .filter-label {
            font-size: 14px;
            font-weight: 600;
            color: #333;
            margin-bottom: 5px;
        }
        
        .filter-input {
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        
        .filter-input:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .filter-btn {
            padding: 10px 20px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: bold;
            transition: background 0.3s;
        }
        
        .filter-btn:hover {
            background: #5568d3;
        }
        
        .filter-btn.reset {
            background: #6c757d;
        }
        
        .filter-btn.reset:hover {
            background: #5a6268;
        }
        
        .school-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 10px;
        }
        
        .school-info {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        
        .school-name {
            font-size: 20px;
            font-weight: bold;
        }
        
        .school-udise {
            font-size: 14px;
            opacity: 0.9;
            background: rgba(255,255,255,0.15);
            padding: 3px 10px;
            border-radius: 12px;
            display: inline-block;
            width: fit-content;
        }
        
        .student-count {
            background: rgba(255,255,255,0.2);
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 14px;
        }
        
        .no-results {
            text-align: center;
            padding: 50px;
            color: #666;
            font-size: 18px;
        }
        
        .pagination-section {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin: 20px 0;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 8px;
        }
        
        .pagination-info {
            font-size: 14px;
            color: #666;
        }
        
        .pagination-controls {
            display: flex;
            gap: 5px;
            align-items: center;
        }
        
        .pagination-btn {
            padding: 8px 12px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            transition: background 0.3s;
        }
        
        .pagination-btn:hover:not(:disabled) {
            background: #5568d3;
        }
        
        .pagination-btn:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        
        .page-number {
            padding: 8px 12px;
            background: white;
            border: 2px solid #667eea;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .page-number:hover {
            background: #667eea;
            color: white;
        }
        
        .page-number.active {
            background: #667eea;
            color: white;
            font-weight: bold;
        }
        
        .page-size-selector {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .page-size-selector select {
            padding: 8px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
        }
        
        .phase-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }
        
        .phase-tab {
            padding: 10px 20px;
            background: #e9ecef;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: bold;
            transition: all 0.3s;
        }
        
        .phase-tab.active {
            background: #667eea;
            color: white;
        }
        
        .phase-content {
            display: none;
        }
        
        .phase-content.active {
            display: block;
        }
        
        .subject-section {
            margin-bottom: 25px;
        }
        
        .subject-title {
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 15px;
            padding: 10px;
            background: #e9ecef;
            border-left: 4px solid #667eea;
            border-radius: 5px;
        }
        
        .marathi-title { border-left-color: #2196F3; }
        .math-title { border-left-color: #9C27B0; }
        .english-title { border-left-color: #4CAF50; }
        
        .level-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 15px;
        }
        
        .level-card {
            background: white;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }
        
        .level-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 4px 10px rgba(0,0,0,0.15);
        }
        
        .level-name {
            font-size: 13px;
            color: #666;
            margin-bottom: 8px;
            font-weight: 500;
        }
        
        .level-count {
            font-size: 28px;
            font-weight: bold;
            color: #667eea;
        }
        
        .level-count-label {
            font-size: 12px;
            color: #999;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #667eea;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <a href="district-dashboard.jsp" class="back-btn">← Back to Dashboard</a>
        
        <div class="header">
            <h1>📊 Activity Level Analysis</h1>
            <p>District: <strong><%= districtName %></strong> | School-wise Phase Analysis</p>
        </div>
        
        <div id="content">
            <div class="loading">
                <div class="spinner"></div>
                <p style="margin-top: 15px;">Loading school data...</p>
            </div>
        </div>
    </div>
    
    <script>
        // Pagination and filtering state
        let allSchools = []; // Store all schools data
        let filteredSchools = []; // Store filtered schools
        let currentPage = 1;
        let itemsPerPage = 10;
        
        // Fetch data on page load
        window.onload = function() {
            const startTime = performance.now();
            
            fetch('GetSchoolActivityAnalysisServlet')
                .then(response => response.json())
                .then(data => {
                    const loadTime = performance.now() - startTime;
                    console.log('Data loaded in ' + loadTime.toFixed(2) + 'ms');
                    
                    if (data.success) {
                        displayData(data);
                    } else {
                        document.getElementById('content').innerHTML = 
                            '<div class="loading"><p style="color: #dc3545;">Error: ' + data.message + '</p></div>';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('content').innerHTML = 
                        '<div class="loading"><p style="color: #dc3545;">Failed to load data. Please try again.</p></div>';
                });
        };
        
        function displayData(data) {
            const content = document.getElementById('content');
            allSchools = data.schools || [];
            filteredSchools = allSchools;
            currentPage = 1;
            
            let html = '';
            
            if (!allSchools || allSchools.length === 0) {
                html = '<div class="loading"><p>No schools found in this district.</p></div>';
            } else {
                // Add filter section
                html += '<div class="filter-section">';
                html += '  <div class="filter-title">🔍 Filter Schools</div>';
                html += '  <div class="filter-controls">';
                html += '    <div class="filter-group">';
                html += '      <label class="filter-label">School Name</label>';
                html += '      <input type="text" id="filterSchoolName" class="filter-input" placeholder="Search by school name..." onkeyup="if(event.key===\'Enter\') applyFilter()">';
                html += '    </div>';
                html += '    <div class="filter-group">';
                html += '      <label class="filter-label">UDISE Number</label>';
                html += '      <input type="text" id="filterUdise" class="filter-input" placeholder="Search by UDISE..." onkeyup="if(event.key===\'Enter\') applyFilter()">';
                html += '    </div>';
                html += '    <div class="filter-group">';
                html += '      <button class="filter-btn" onclick="applyFilter()">Apply Filter</button>';
                html += '    </div>';
                html += '    <div class="filter-group">';
                html += '      <button class="filter-btn reset" onclick="resetFilter()">Reset</button>';
                html += '    </div>';
                html += '  </div>';
                html += '</div>';
                
                // Pagination and results container
                html += '<div id="paginationTop"></div>';
                html += '<div id="schoolsContainer"></div>';
                html += '<div id="paginationBottom"></div>';
            }
            
            content.innerHTML = html;
            renderPaginatedSchools();
        }
        
        function renderSchools(schools, startIndex = 0) {
            if (!schools || schools.length === 0) {
                return '<div class="no-results">No schools match your filter criteria.</div>';
            }
            
            let html = '';
            schools.forEach((school, index) => {
                const schoolIndex = startIndex + index; // Use global index for unique IDs
                html += '<div class="school-card">';
                html += '  <div class="school-header">';
                html += '    <div class="school-info">';
                html += '      <div class="school-name">🏫 ' + escapeHtml(school.schoolName) + '</div>';
                html += '      <div class="school-udise">UDISE: ' + escapeHtml(school.udiseNo || 'N/A') + '</div>';
                html += '    </div>';
                html += '    <div class="student-count">👥 ' + school.totalStudents + ' Students</div>';
                html += '  </div>';
                    
                    // Phase tabs
                    html += '  <div class="phase-tabs">';
                    for (let i = 1; i <= 4; i++) {
                        html += '    <button class="phase-tab ' + (i === 1 ? 'active' : '') + '" onclick="showPhase(' + schoolIndex + ', ' + i + ')">Phase ' + i + '</button>';
                    }
                    html += '  </div>';
                    
                    // Phase contents - render only Phase 1 initially for performance
                    school.phases.forEach((phase, phaseIndex) => {
                        html += '  <div class="phase-content ' + (phaseIndex === 0 ? 'active' : '') + '" id="school' + schoolIndex + '_phase' + phase.phaseNumber + '" data-phase="' + phase.phaseNumber + '" data-school="' + schoolIndex + '">';
                        
                        if (phaseIndex === 0) {
                            // Render Phase 1 immediately
                            html += renderPhaseContent(phase);
                        } else {
                            // Lazy load other phases
                            html += '    <div class="loading" style="padding: 40px; text-align: center; color: #667eea;">Loading phase data...</div>';
                        }
                        
                        html += '  </div>';
                    });
                    
                    html += '</div>';
                });
            
            return html;
        }
        
        function renderPaginatedSchools() {
            const startTime = performance.now();
            
            // Calculate pagination
            const totalItems = filteredSchools.length;
            const totalPages = Math.ceil(totalItems / itemsPerPage);
            const startIndex = (currentPage - 1) * itemsPerPage;
            const endIndex = Math.min(startIndex + itemsPerPage, totalItems);
            const schoolsToDisplay = filteredSchools.slice(startIndex, endIndex);
            
            // Render schools
            const container = document.getElementById('schoolsContainer');
            container.innerHTML = renderSchools(schoolsToDisplay, startIndex);
            
            // Render pagination
            renderPagination(totalItems, totalPages, startIndex, endIndex);
            
            const renderTime = performance.now() - startTime;
            console.log('Rendered ' + schoolsToDisplay.length + ' schools in ' + renderTime.toFixed(2) + 'ms');
        }
        
        function renderPagination(totalItems, totalPages, startIndex, endIndex) {
            let paginationHtml = '<div class="pagination-section">';
            
            // Left side - Info and page size selector
            paginationHtml += '<div style="display: flex; gap: 20px; align-items: center;">';
            paginationHtml += '  <div class="pagination-info">Showing ' + (startIndex + 1) + '-' + endIndex + ' of ' + totalItems + ' schools</div>';
            paginationHtml += '  <div class="page-size-selector">';
            paginationHtml += '    <label>Per page:</label>';
            paginationHtml += '    <select onchange="changePageSize(this.value)">';
            paginationHtml += '      <option value="5"' + (itemsPerPage === 5 ? ' selected' : '') + '>5</option>';
            paginationHtml += '      <option value="10"' + (itemsPerPage === 10 ? ' selected' : '') + '>10</option>';
            paginationHtml += '      <option value="20"' + (itemsPerPage === 20 ? ' selected' : '') + '>20</option>';
            paginationHtml += '      <option value="50"' + (itemsPerPage === 50 ? ' selected' : '') + '>50</option>';
            paginationHtml += '    </select>';
            paginationHtml += '  </div>';
            paginationHtml += '</div>';
            
            // Right side - Pagination controls
            paginationHtml += '<div class="pagination-controls">';
            paginationHtml += '  <button class="pagination-btn" onclick="goToPage(1)" ' + (currentPage === 1 ? 'disabled' : '') + '>First</button>';
            paginationHtml += '  <button class="pagination-btn" onclick="goToPage(' + (currentPage - 1) + ')" ' + (currentPage === 1 ? 'disabled' : '') + '>Previous</button>';
            
            // Page numbers (show max 5 pages)
            let startPage = Math.max(1, currentPage - 2);
            let endPage = Math.min(totalPages, startPage + 4);
            startPage = Math.max(1, endPage - 4);
            
            for (let i = startPage; i <= endPage; i++) {
                paginationHtml += '  <button class="page-number ' + (i === currentPage ? 'active' : '') + '" onclick="goToPage(' + i + ')">' + i + '</button>';
            }
            
            paginationHtml += '  <button class="pagination-btn" onclick="goToPage(' + (currentPage + 1) + ')" ' + (currentPage === totalPages ? 'disabled' : '') + '>Next</button>';
            paginationHtml += '  <button class="pagination-btn" onclick="goToPage(' + totalPages + ')" ' + (currentPage === totalPages ? 'disabled' : '') + '>Last</button>';
            paginationHtml += '</div>';
            
            paginationHtml += '</div>';
            
            document.getElementById('paginationTop').innerHTML = paginationHtml;
            document.getElementById('paginationBottom').innerHTML = paginationHtml;
        }
        
        function goToPage(page) {
            currentPage = page;
            renderPaginatedSchools();
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
        
        function changePageSize(newSize) {
            itemsPerPage = parseInt(newSize);
            currentPage = 1;
            renderPaginatedSchools();
        }
        
        function applyFilter() {
            const schoolNameFilter = document.getElementById('filterSchoolName').value.toLowerCase().trim();
            const udiseFilter = document.getElementById('filterUdise').value.toLowerCase().trim();
            
            filteredSchools = allSchools.filter(school => {
                const schoolNameMatch = !schoolNameFilter || 
                    (school.schoolName && school.schoolName.toLowerCase().includes(schoolNameFilter));
                const udiseMatch = !udiseFilter || 
                    (school.udiseNo && school.udiseNo.toLowerCase().includes(udiseFilter));
                
                return schoolNameMatch && udiseMatch;
            });
            
            currentPage = 1; // Reset to first page
            renderPaginatedSchools();
        }
        
        function resetFilter() {
            document.getElementById('filterSchoolName').value = '';
            document.getElementById('filterUdise').value = '';
            filteredSchools = allSchools;
            currentPage = 1;
            renderPaginatedSchools();
        }
        
        function renderPhaseContent(phase) {
            let html = '';
            
            // Marathi section
            html += '    <div class="subject-section">';
            html += '      <div class="subject-title marathi-title">📘 MARATHI LEVELS</div>';
            html += '      <div class="level-grid">';
            phase.marathiLevels.forEach(level => {
                html += '        <div class="level-card">';
                html += '          <div class="level-name">' + escapeHtml(level.levelName) + '</div>';
                html += '          <div class="level-count">' + level.studentCount + '</div>';
                html += '          <div class="level-count-label">students</div>';
                html += '        </div>';
            });
            html += '      </div>';
            html += '    </div>';
            
            // Math section
            html += '    <div class="subject-section">';
            html += '      <div class="subject-title math-title">🔢 MATH LEVELS</div>';
            html += '      <div class="level-grid">';
            phase.mathLevels.forEach(level => {
                html += '        <div class="level-card">';
                html += '          <div class="level-name">' + escapeHtml(level.levelName) + '</div>';
                html += '          <div class="level-count">' + level.studentCount + '</div>';
                html += '          <div class="level-count-label">students</div>';
                html += '        </div>';
            });
            html += '      </div>';
            html += '    </div>';
            
            // English section
            html += '    <div class="subject-section">';
            html += '      <div class="subject-title english-title">🔤 ENGLISH LEVELS</div>';
            html += '      <div class="level-grid">';
            phase.englishLevels.forEach(level => {
                html += '        <div class="level-card">';
                html += '          <div class="level-name">' + escapeHtml(level.levelName) + '</div>';
                html += '          <div class="level-count">' + level.studentCount + '</div>';
                html += '          <div class="level-count-label">students</div>';
                html += '        </div>';
            });
            html += '      </div>';
            html += '    </div>';
            
            return html;
        }
        
        function showPhase(schoolIndex, phaseNumber) {
            const pageStartIndex = (currentPage - 1) * itemsPerPage;
            const actualSchoolIndex = schoolIndex - pageStartIndex;
            
            // Get the actual school card within current page
            const schoolCards = document.querySelectorAll('.school-card');
            if (actualSchoolIndex < 0 || actualSchoolIndex >= schoolCards.length) {
                return;
            }
            
            const school = schoolCards[actualSchoolIndex];
            const phaseContents = school.querySelectorAll('.phase-content');
            const phaseTabs = school.querySelectorAll('.phase-tab');
            
            phaseContents.forEach(content => content.classList.remove('active'));
            phaseTabs.forEach(tab => tab.classList.remove('active'));
            
            // Show selected phase
            const selectedContent = school.querySelector('#school' + schoolIndex + '_phase' + phaseNumber);
            const selectedTab = phaseTabs[phaseNumber - 1];
            
            if (selectedContent) {
                // Check if phase content needs to be loaded
                if (selectedContent.querySelector('.loading')) {
                    // Find the school data and render the phase
                    const globalSchoolIndex = schoolIndex - (currentPage - 1) * itemsPerPage;
                    const schoolData = filteredSchools[schoolIndex];
                    
                    if (schoolData && schoolData.phases) {
                        const phaseData = schoolData.phases.find(p => p.phaseNumber === phaseNumber);
                        if (phaseData) {
                            selectedContent.innerHTML = renderPhaseContent(phaseData);
                        }
                    }
                }
                selectedContent.classList.add('active');
            }
            if (selectedTab) selectedTab.classList.add('active');
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
