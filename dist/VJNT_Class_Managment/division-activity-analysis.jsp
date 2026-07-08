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
    
    // Check if user is division admin
    String userTypeStr = user.getUserType() != null ? user.getUserType().toString() : "";
    if (!userTypeStr.contains("DIVISION")) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String divisionName = user.getDivisionName();
    if (divisionName == null || divisionName.trim().isEmpty()) {
        out.println("<h3 style='color:red; text-align:center; padding:50px;'>Error: Division name not found for user</h3>");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 Activity Analysis - <%= divisionName %></title>
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
        
        .top-nav {
            display: flex;
            justify-content: space-between;
            align-items: center;
            max-width: 1400px;
            margin: 0 auto 20px;
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
            padding: 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 10px;
            color: white;
        }
        
        .header h1 {
            font-size: 36px;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }
        
        .header p {
            font-size: 18px;
            opacity: 0.95;
        }
        
        .info-banner {
            background: #e3f2fd;
            border-left: 4px solid #2196F3;
            padding: 15px 20px;
            margin-bottom: 25px;
            border-radius: 5px;
        }
        
        .info-banner h3 {
            color: #1976D2;
            margin-bottom: 8px;
            font-size: 16px;
        }
        
        .info-banner ul {
            margin-left: 20px;
            color: #555;
            font-size: 14px;
            line-height: 1.8;
        }
        
        .stats-overview {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .stat-box {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 4px 10px rgba(0,0,0,0.15);
        }
        
        .stat-box .number {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .stat-box .label {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .back-btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 24px;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: all 0.3s;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .back-btn:hover {
            background: #667eea;
            color: white;
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }
        
        .help-btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 24px;
            background: #FF9800;
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: all 0.3s;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            cursor: pointer;
            border: none;
        }
        
        .help-btn:hover {
            background: #F57C00;
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }
        
        .loading {
            text-align: center;
            padding: 50px;
            font-size: 18px;
            color: #667eea;
        }
        
        .search-filter {
            margin-bottom: 25px;
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
            padding: 12px 20px;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            font-size: 14px;
            transition: border 0.3s;
        }
        
        .search-box input:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .district-card {
            background: #fff;
            border: 2px solid #e9ecef;
            border-radius: 12px;
            padding: 25px;
            margin-bottom: 30px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.08);
            transition: all 0.3s;
        }
        
        .district-card:hover {
            border-color: #667eea;
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.15);
            transform: translateY(-2px);
        }
        
        .district-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 25px;
            border-radius: 10px;
            margin-bottom: 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 4px 10px rgba(0,0,0,0.1);
        }
        
        .district-name {
            font-size: 24px;
            font-weight: bold;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .student-count {
            background: rgba(255,255,255,0.25);
            padding: 8px 20px;
            border-radius: 25px;
            font-size: 16px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .phase-tabs {
            display: flex;
            gap: 12px;
            margin-bottom: 25px;
            flex-wrap: wrap;
            justify-content: center;
            background: #f8f9fa;
            padding: 15px;
            border-radius: 10px;
        }
        
        .phase-tab {
            padding: 14px 30px;
            background: white;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            cursor: pointer;
            font-weight: bold;
            font-size: 15px;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .phase-tab:hover {
            border-color: #667eea;
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0,0,0,0.1);
        }
        
        .phase-tab.active {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-color: #667eea;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
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
            background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
            padding: 20px;
            border-radius: 10px;
            border: 2px solid #e9ecef;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            transition: all 0.3s;
            cursor: pointer;
        }
        
        .level-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 20px rgba(0,0,0,0.15);
            border-color: #667eea;
        }
        
        .level-name {
            font-size: 14px;
            color: #555;
            margin-bottom: 12px;
            font-weight: 600;
            line-height: 1.4;
        }
        
        .level-count {
            font-size: 36px;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 5px;
        }
        
        .level-count-label {
            font-size: 13px;
            color: #999;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .no-data {
            text-align: center;
            padding: 60px 20px;
            color: #999;
            font-size: 16px;
        }
        
        .no-data-icon {
            font-size: 48px;
            margin-bottom: 15px;
        }
        
        .help-modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.6);
            backdrop-filter: blur(5px);
        }
        
        .help-content {
            background: white;
            margin: 3% auto;
            padding: 30px;
            border-radius: 15px;
            width: 90%;
            max-width: 700px;
            max-height: 80vh;
            overflow-y: auto;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
        }
        
        .help-content h2 {
            color: #667eea;
            margin-bottom: 20px;
            font-size: 24px;
        }
        
        .help-content h3 {
            color: #333;
            margin-top: 20px;
            margin-bottom: 10px;
            font-size: 18px;
        }
        
        .help-content p, .help-content li {
            color: #666;
            line-height: 1.8;
            margin-bottom: 10px;
        }
        
        .close-modal {
            float: right;
            font-size: 32px;
            font-weight: bold;
            color: #999;
            cursor: pointer;
            transition: color 0.3s;
        }
        
        .close-modal:hover {
            color: #667eea;
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
    <!-- Top Navigation -->
    <div class="top-nav">
        <a href="division-dashboard.jsp" class="back-btn">
            <span>←</span> Back to Dashboard
        </a>
        <button class="help-btn" onclick="showHelp()">
            <span>❓</span> How to Use
        </button>
    </div>

    <div class="container">
        <!-- Header -->
        <div class="header">
            <h1>📊 Activity Level Analysis</h1>
            <p>Division: <strong><%= divisionName %></strong></p>
            <p style="font-size: 16px; margin-top: 8px;">District-wise Student Performance Analysis</p>
        </div>
        
        <!-- Info Banner -->
        <div class="info-banner">
            <h3>📌 What You Can See Here:</h3>
            <ul>
                <li><strong>District-wise Analysis:</strong> View student counts for each district in your division</li>
                <li><strong>Phase-wise Data:</strong> Switch between Phase 1, 2, 3, and 4 using tabs</li>
                <li><strong>Subject Levels:</strong> See Marathi, Math, and English level distribution</li>
                <li><strong>Student Counts:</strong> Each card shows how many students are at that specific level</li>
            </ul>
        </div>
        
        <!-- Stats Overview -->
        <div id="statsOverview" style="display: none;">
            <div class="stats-overview">
                <div class="stat-box">
                    <div class="number" id="totalDistricts">0</div>
                    <div class="label">📍 Total Districts</div>
                </div>
                <div class="stat-box">
                    <div class="number" id="totalStudents">0</div>
                    <div class="label">👥 Total Students</div>
                </div>
                <div class="stat-box">
                    <div class="number" id="currentPhase">Phase 1</div>
                    <div class="label">📋 Viewing Phase</div>
                </div>
            </div>
        </div>
        
        <!-- Search/Filter -->
        <div class="search-filter" id="searchFilter" style="display: none;">
            <div class="search-box">
                <input type="text" id="searchInput" placeholder="🔍 Search district by name..." onkeyup="if(event.key==='Enter') applyFilter()">
            </div>
            <button class="pagination-btn" onclick="applyFilter()" style="padding: 12px 24px;">Apply Filter</button>
            <button class="pagination-btn" onclick="resetFilter()" style="padding: 12px 24px; background: #6c757d;">Reset</button>
        </div>
        
        <!-- Pagination Top -->
        <div id="paginationTop"></div>
        
        <!-- Content -->
        <div id="content">
            <div class="loading">
                <div class="spinner"></div>
                <p style="margin-top: 15px; font-size: 16px;">Loading district data...</p>
                <p style="margin-top: 8px; font-size: 14px; color: #999;">Please wait while we fetch the information</p>
            </div>
        </div>
        
        <!-- Pagination Bottom -->
        <div id="paginationBottom"></div>
    </div>
    
    <!-- Help Modal -->
    <div id="helpModal" class="help-modal" onclick="if(event.target==this) closeHelp()">
        <div class="help-content">
            <span class="close-modal" onclick="closeHelp()">&times;</span>
            <h2>📖 How to Use Activity Analysis</h2>
            
            <h3>🎯 Overview</h3>
            <p>This page shows student performance analysis across all districts in your division. You can see how many students are at each learning level for Marathi, Math, and English subjects.</p>
            
            <h3>📊 Understanding the Layout</h3>
            <ul>
                <li><strong>District Cards:</strong> Each card represents one district in your division</li>
                <li><strong>Phase Tabs:</strong> Click Phase 1, 2, 3, or 4 to switch between assessment phases</li>
                <li><strong>Subject Sections:</strong> Three sections show Marathi (Blue), Math (Purple), and English (Green) levels</li>
                <li><strong>Level Cards:</strong> Each card shows the level name and student count</li>
            </ul>
            
            <h3>🔍 Search Feature</h3>
            <p>Use the search box to quickly find a specific district by typing its name.</p>
            
            <h3>📘 Level Meanings</h3>
            <p><strong>Marathi Levels:</strong></p>
            <ul>
                <li>Level 0: Not yet assessed</li>
                <li>Level 1: Beginning level (प्रारंभिक स्तर)</li>
                <li>Level 2: Alphabet level (अक्षर स्तर)</li>
                <li>Level 3: Word level (शब्द स्तर)</li>
                <li>Level 4: Sentence level (वाक्य स्तर)</li>
                <li>Level 5: Reading comprehension (समजपूर्वक उतारा वाचन)</li>
                <li>Level 6: FLN 100% Complete</li>
            </ul>
            
            <h3>💡 Tips</h3>
            <ul>
                <li>Hover over cards to see them highlighted</li>
                <li>Click phase tabs to compare student progress across phases</li>
                <li>Use search to quickly locate specific districts</li>
                <li>Student counts are updated in real-time from the database</li>
            </ul>
            
            <h3>❓ Need Help?</h3>
            <p>If you encounter any issues or have questions, please contact your system administrator.</p>
        </div>
    </div>
    
    <script>
        // Pagination and filtering state
        let allDistricts = []; // Store all districts data
        let filteredDistricts = []; // Store filtered districts
        let currentPage = 1;
        let itemsPerPage = 5;
        
        // Fetch data on page load
        window.onload = function() {
            const startTime = performance.now();
            
            fetch('GetDistrictActivityAnalysisServlet')
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
            allDistricts = data.districts || [];
            filteredDistricts = allDistricts;
            currentPage = 1;
            
            if (!allDistricts || allDistricts.length === 0) {
                document.getElementById('content').innerHTML = 
                    '<div class="no-data">' +
                    '  <div class="no-data-icon">📊</div>' +
                    '  <h3>No Data Available</h3>' +
                    '  <p>There are no districts found in this division.</p>' +
                    '</div>';
                return;
            }
            
            // Update stats overview
            updateStats(data);
            
            // Show search filter
            document.getElementById('searchFilter').style.display = 'flex';
            
            // Render paginated districts
            renderPaginatedDistricts();
        }
        
        function renderPaginatedDistricts() {
            const startTime = performance.now();
            
            // Calculate pagination
            const totalItems = filteredDistricts.length;
            const totalPages = Math.ceil(totalItems / itemsPerPage);
            const startIndex = (currentPage - 1) * itemsPerPage;
            const endIndex = Math.min(startIndex + itemsPerPage, totalItems);
            const districtsToDisplay = filteredDistricts.slice(startIndex, endIndex);
            
            // Render districts
            const content = document.getElementById('content');
            let html = '';
            
            if (districtsToDisplay.length === 0) {
                html = '<div class="no-results">No districts match your filter criteria.</div>';
            } else {
                districtsToDisplay.forEach((district, index) => {
                    const districtIndex = startIndex + index; // Use global index for unique IDs
                    html += '<div class="district-card">';
                    html += '  <div class="district-header">';
                    html += '    <div class="district-name">🏛️ ' + escapeHtml(district.districtName) + '</div>';
                    html += '    <div class="student-count">👥 ' + district.totalStudents + ' Students</div>';
                    html += '  </div>';
                    
                    // Phase tabs
                    html += '  <div class="phase-tabs">';
                    const phaseIcons = ['1️⃣', '2️⃣', '3️⃣', '4️⃣'];
                    for (let i = 1; i <= 4; i++) {
                        html += '    <button class="phase-tab ' + (i === 1 ? 'active' : '') + '" onclick="showPhase(' + districtIndex + ', ' + i + ')">';
                        html += '      <span>' + phaseIcons[i-1] + '</span> Phase ' + i;
                        html += '    </button>';
                    }
                    html += '  </div>';
                    
                    // Phase contents - render only Phase 1 initially for performance
                    district.phases.forEach((phase, phaseIndex) => {
                        html += '  <div class="phase-content ' + (phaseIndex === 0 ? 'active' : '') + '" id="district' + districtIndex + '_phase' + phase.phaseNumber + '" data-phase="' + phase.phaseNumber + '" data-district="' + districtIndex + '">';
                        
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
            }
            
            content.innerHTML = html;
            
            // Render pagination
            renderPagination(totalItems, totalPages, startIndex, endIndex);
            
            const renderTime = performance.now() - startTime;
            console.log('Rendered ' + districtsToDisplay.length + ' districts in ' + renderTime.toFixed(2) + 'ms');
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
        
        function renderPagination(totalItems, totalPages, startIndex, endIndex) {
            let paginationHtml = '<div class="pagination-section">';
            
            // Left side - Info and page size selector
            paginationHtml += '<div style="display: flex; gap: 20px; align-items: center;">';
            paginationHtml += '  <div class="pagination-info">Showing ' + (startIndex + 1) + '-' + endIndex + ' of ' + totalItems + ' districts</div>';
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
            renderPaginatedDistricts();
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
        
        function changePageSize(newSize) {
            itemsPerPage = parseInt(newSize);
            currentPage = 1;
            renderPaginatedDistricts();
        }
        
        function applyFilter() {
            const searchTerm = document.getElementById('searchInput').value.toLowerCase().trim();
            
            filteredDistricts = allDistricts.filter(district => {
                const districtNameMatch = !searchTerm || 
                    (district.districtName && district.districtName.toLowerCase().includes(searchTerm));
                
                return districtNameMatch;
            });
            
            currentPage = 1; // Reset to first page
            renderPaginatedDistricts();
        }
        
        function resetFilter() {
            document.getElementById('searchInput').value = '';
            filteredDistricts = allDistricts;
            currentPage = 1;
            renderPaginatedDistricts();
        }
        
        function showPhase(districtIndex, phaseNumber) {
            const pageStartIndex = (currentPage - 1) * itemsPerPage;
            const actualDistrictIndex = districtIndex - pageStartIndex;
            
            // Get the actual district card within current page
            const districtCards = document.querySelectorAll('.district-card');
            if (actualDistrictIndex < 0 || actualDistrictIndex >= districtCards.length) {
                return;
            }
            
            const district = districtCards[actualDistrictIndex];
            const phaseContents = district.querySelectorAll('.phase-content');
            const phaseTabs = district.querySelectorAll('.phase-tab');
            
            phaseContents.forEach(content => content.classList.remove('active'));
            phaseTabs.forEach(tab => tab.classList.remove('active'));
            
            // Show selected phase
            const selectedContent = district.querySelector('#district' + districtIndex + '_phase' + phaseNumber);
            const selectedTab = phaseTabs[phaseNumber - 1];
            
            if (selectedContent) {
                // Check if phase content needs to be loaded
                if (selectedContent.querySelector('.loading')) {
                    // Find the district data and render the phase
                    const districtData = filteredDistricts[districtIndex];
                    
                    if (districtData && districtData.phases) {
                        const phaseData = districtData.phases.find(p => p.phaseNumber === phaseNumber);
                        if (phaseData) {
                            selectedContent.innerHTML = renderPhaseContent(phaseData);
                        }
                    }
                }
                selectedContent.classList.add('active');
            }
            if (selectedTab) selectedTab.classList.add('active');
            
            // Update current phase display
            document.getElementById('currentPhase').textContent = 'Phase ' + phaseNumber;
        }
        
        function escapeHtml(text) {
            if (!text) return '';
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        // Show help modal
        function showHelp() {
            document.getElementById('helpModal').style.display = 'block';
        }
        
        // Close help modal
        function closeHelp() {
            document.getElementById('helpModal').style.display = 'none';
        }
        
        // Filter districts by search
        function filterDistricts() {
            const searchValue = document.getElementById('searchInput').value.toLowerCase();
            const districtCards = document.querySelectorAll('.district-card');
            
            districtCards.forEach(card => {
                const districtName = card.querySelector('.district-name').textContent.toLowerCase();
                if (districtName.includes(searchValue)) {
                    card.style.display = 'block';
                } else {
                    card.style.display = 'none';
                }
            });
        }
        
        // Update stats overview
        function updateStats(data) {
            if (data.districts && data.districts.length > 0) {
                // Calculate total students
                let totalStudents = 0;
                data.districts.forEach(district => {
                    totalStudents += district.totalStudents;
                });
                
                // Update stats
                document.getElementById('totalDistricts').textContent = data.districts.length;
                document.getElementById('totalStudents').textContent = totalStudents;
                
                // Show stats and search
                document.getElementById('statsOverview').style.display = 'block';
                document.getElementById('searchFilter').style.display = 'flex';
            }
        }
        
        // Close modal on ESC key
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeHelp();
            }
        });
    </script>
</body>
</html>
