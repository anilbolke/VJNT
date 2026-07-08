<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="java.util.List" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    StudentDAO studentDAO = new StudentDAO();
    List<String> divisions = studentDAO.getDistinctDivisions();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Level Distribution - All Divisions</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script>
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
            max-width: 1800px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            position: relative;
        }

        .header-nav {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }

        .back-button {
            background: rgba(255, 255, 255, 0.2);
            color: white;
            border: 2px solid white;
            padding: 10px 20px;
            border-radius: 25px;
            text-decoration: none;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
        }

        .back-button:hover {
            background: white;
            color: #667eea;
            transform: translateX(-5px);
        }

        .header-content {
            text-align: center;
        }

        .header h1 {
            font-size: 32px;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 15px;
        }

        .header-subtitle {
            font-size: 16px;
            opacity: 0.9;
        }

        .toolbar {
            background: #f8f9fa;
            padding: 20px 30px;
            border-bottom: 2px solid #e0e0e0;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }

        .filter-controls {
            display: flex;
            gap: 15px;
            align-items: center;
            flex-wrap: wrap;
        }

        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }

        .filter-group label {
            font-size: 12px;
            font-weight: 600;
            color: #555;
            text-transform: uppercase;
        }

        .filter-group select {
            padding: 8px 12px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            min-width: 150px;
            background: white;
            cursor: pointer;
            transition: all 0.3s;
        }

        .filter-group select:focus {
            outline: none;
            border-color: #667eea;
        }

        #divisionFilter {
            border-color: #667eea;
            font-weight: 600;
            color: #4a4a8a;
        }

        .breadcrumb {
            padding: 15px 30px;
            background: #fff;
            border-bottom: 1px solid #e0e0e0;
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 14px;
        }

        .breadcrumb a {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
        }

        .breadcrumb a:hover {
            text-decoration: underline;
        }

        .breadcrumb span {
            color: #999;
        }

        .content-area {
            padding: 30px;
        }

        .district-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 30px;
        }

        .district-card, .school-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s, box-shadow 0.3s;
            cursor: pointer;
        }

        .district-card:hover, .school-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }

        .school-card {
            cursor: default;
        }

        .card-header {
            text-align: center;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #f0f0f0;
        }

        .card-title {
            font-size: 18px;
            font-weight: 700;
            color: #333;
            margin-bottom: 5px;
        }

        .card-subtitle {
            font-size: 13px;
            color: #666;
        }

        .subject-section {
            margin-bottom: 20px;
        }

        .subject-section:last-child {
            margin-bottom: 0;
        }

        .subject-title {
            font-size: 14px;
            font-weight: 700;
            margin-bottom: 10px;
            padding: 8px 12px;
            border-radius: 6px;
            text-align: center;
        }

        .subject-title.marathi {
            background: linear-gradient(135deg, #2196f3, #1976d2);
            color: white;
        }

        .subject-title.math {
            background: linear-gradient(135deg, #4caf50, #388e3c);
            color: white;
        }

        .subject-title.english {
            background: linear-gradient(135deg, #ff9800, #f57c00);
            color: white;
        }

        .level-bar-container {
            margin-bottom: 8px;
        }

        .level-label {
            font-size: 11px;
            color: #666;
            margin-bottom: 3px;
            display: flex;
            justify-content: space-between;
        }

        .level-bar {
            height: 20px;
            background: #e0e0e0;
            border-radius: 4px;
            overflow: hidden;
            position: relative;
        }

        .level-bar-fill {
            height: 100%;
            transition: width 0.5s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 10px;
            font-weight: 600;
            color: white;
        }

        .level-bar-fill.marathi {
            background: linear-gradient(90deg, #2196f3, #1976d2);
        }

        .level-bar-fill.math {
            background: linear-gradient(90deg, #4caf50, #388e3c);
        }

        .level-bar-fill.english {
            background: linear-gradient(90deg, #ff9800, #f57c00);
        }

        .loading {
            text-align: center;
            padding: 60px;
            font-size: 18px;
            color: #666;
        }

        .loading::after {
            content: '...';
            animation: dots 1.5s steps(4, end) infinite;
        }

        @keyframes dots {
            0%, 20% { content: '.'; }
            40% { content: '..'; }
            60%, 100% { content: '...'; }
        }

        .error {
            padding: 30px;
            text-align: center;
            color: #d32f2f;
            font-size: 16px;
        }

        .no-data {
            text-align: center;
            padding: 60px;
            color: #999;
            font-size: 18px;
        }

        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        .btn-primary {
            background: #667eea;
            color: white;
        }

        .btn-primary:hover {
            background: #5568d3;
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(102, 126, 234, 0.4);
        }

        .btn-success {
            background: #4caf50;
            color: white;
        }

        .btn-success:hover {
            background: #45a049;
        }

        .export-buttons {
            display: flex;
            gap: 10px;
        }

        .level-legend {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 12px;
        }

        .legend-title {
            font-weight: 700;
            margin-bottom: 10px;
            color: #333;
        }

        .legend-item {
            margin-bottom: 5px;
            color: #666;
        }

        .stats-summary {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }

        .stat-card {
            background: white;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .stat-value {
            font-size: 28px;
            font-weight: 700;
            color: #667eea;
            margin-bottom: 5px;
        }

        .stat-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
            font-weight: 600;
        }

        @media (max-width: 768px) {
            .district-grid {
                grid-template-columns: 1fr;
            }

            .toolbar {
                flex-direction: column;
                align-items: stretch;
            }

            .filter-controls {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-nav">
                <a href="<%= request.getContextPath() %>/super-officer-dashboard.jsp" class="back-button">
                    ← Back to Dashboard
                </a>
            </div>
            <div class="header-content">
                <h1>
                    📊 Student Level Distribution Analysis
                </h1>
                <div class="header-subtitle" id="scopeSubtitle">
                    All Divisions | Detailed Level-wise Breakdown
                </div>
            </div>
        </div>

        <div class="breadcrumb" id="breadcrumb">
            <a href="#" onclick="showDistrictView(); return false;">All Districts</a>
        </div>

        <div class="toolbar">
            <div class="filter-controls">
                <div class="filter-group">
                    <label>Division</label>
                    <select id="divisionFilter" onchange="onDivisionChange()">
                        <option value="ALL" selected>🌐 All Divisions</option>
                        <% for (String div : divisions) { %>
                            <option value="<%= div %>"><%= div %></option>
                        <% } %>
                    </select>
                </div>

                <div class="filter-group">
                    <label>Phase Filter</label>
                    <select id="phaseFilter" onchange="loadData()">
                        <option value="all" selected>All Phases</option>
                        <option value="1">Phase 1</option>
                        <option value="2">Phase 2</option>
                        <option value="3">Phase 3</option>
                        <option value="4">Phase 4</option>
                        <option value="current">Current Levels</option>
                    </select>
                </div>

                <div class="filter-group">
                    <label>Search by UDISE</label>
                    <input type="text" id="udiseSearch" placeholder="Enter UDISE number"
                           style="padding: 8px 12px; border: 2px solid #ddd; border-radius: 6px; font-size: 14px; min-width: 200px;">
                </div>

                <div class="filter-group" style="justify-content: flex-end;">
                    <label>&nbsp;</label>
                    <button class="btn btn-primary" onclick="searchByUdise()" style="margin-top: 0;">
                        🔍 Search
                    </button>
                </div>

                <div class="filter-group" style="justify-content: flex-end;" id="clearFilterGroup" style="display: none;">
                    <label>&nbsp;</label>
                    <button class="btn" onclick="clearUdiseFilter()" style="background: #ff5722; color: white; margin-top: 0;">
                        ✖ Clear Filter
                    </button>
                </div>
            </div>

            <div class="export-buttons">
                <button class="btn btn-success" onclick="exportToCSV()">
                    📥 Export CSV
                </button>
                <button class="btn btn-primary" onclick="window.print()">
                    🖨️ Print
                </button>
            </div>
        </div>

        <div class="content-area" id="contentArea">
            <div class="loading">Loading data</div>
        </div>
    </div>

    <script>
        let currentView = 'district';
        let currentDistrict = null;
        let currentData = null;
        // Selected division scope: 'ALL' aggregates across every division.
        let selectedDivision = 'ALL';

        // Level descriptions
        const levelDescriptions = {
            marathi: {
                0: 'स्थर निश्चित केला नाही',
                1: 'प्रारंभिक स्तर',
                2: 'अक्षर स्तर',
                3: 'शब्द स्तर',
                4: 'वाक्य स्तर',
                5: 'समजपूर्वक उतारा वाचन स्तर',
                6: 'मराठी वाचन व लेखन FLN स्तर 100% पूर्ण'
            },
            math: {
                0: 'स्थर निश्चित केला नाही',
                1: 'प्रारंभिक स्तर',
                2: 'अंक ज्ञान स्तर',
                3: 'संख्याज्ञान स्तर',
                4: 'बेरीज स्तर',
                5: 'वजाबाकी स्तर',
                6: 'गुणाकार स्तर',
                7: 'भागाकार स्तर',
                8: 'गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण'
            },
            english: {
                0: 'स्थर निश्चित केला नाही',
                1: 'Beginner level',
                2: 'Letter level',
                3: 'Word level',
                4: 'Sentence level',
                5: 'Reading comprehension and dictation level',
                6: 'English reading and writing FLN level 100% complete'
            }
        };

        // Initialize on page load
        window.onload = function() {
            loadData();
        };

        // Division dropdown changed: reset to district view for the new scope
        function onDivisionChange() {
            selectedDivision = document.getElementById('divisionFilter').value;
            currentView = 'district';
            currentDistrict = null;

            const label = (selectedDivision === 'ALL')
                ? 'All Divisions'
                : selectedDivision + ' Division';
            document.getElementById('scopeSubtitle').textContent =
                label + ' | Detailed Level-wise Breakdown';

            loadData();
        }

        // Load data from servlet
        function loadData() {
            const phaseFilter = document.getElementById('phaseFilter').value;
            const view = currentView;
            const district = currentDistrict;

            let url = '<%= request.getContextPath() %>/super-student-level-distribution?division=' +
                      encodeURIComponent(selectedDivision) +
                      '&view=' + view +
                      '&phase=' + phaseFilter;

            if (view === 'school' && district) {
                url += '&district=' + encodeURIComponent(district);
            }

            // Show loading
            document.getElementById('contentArea').innerHTML = '<div class="loading">Loading data</div>';

            fetch(url)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        currentData = data;
                        if (view === 'district') {
                            displayDistrictView(data);
                        } else {
                            displaySchoolView(data);
                        }
                    } else {
                        showError(data.error || 'Failed to load data');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    showError('Error loading data: ' + error.message);
                });
        }

        // Display district view
        function displayDistrictView(data) {
            currentView = 'district';
            currentDistrict = null;

            // Update breadcrumb
            document.getElementById('breadcrumb').innerHTML = '<span>All Districts</span>';

            const districts = data.districts || [];

            if (districts.length === 0) {
                document.getElementById('contentArea').innerHTML =
                    '<div class="no-data">No data available for the selected filters</div>';
                return;
            }

            let html = '<div class="stats-summary">';
            html += '<div class="stat-card"><div class="stat-value">' + data.totalStudents + '</div><div class="stat-label">Total Students</div></div>';
            html += '<div class="stat-card"><div class="stat-value">' + data.districtCount + '</div><div class="stat-label">Districts</div></div>';
            html += '</div>';

            html += '<div class="level-legend">';
            html += '<div class="legend-title">📘 Level Descriptions</div>';
            html += '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 15px; margin-top: 10px;">';

            // Marathi legend
            html += '<div><strong style="color: #2196f3;">मराठी (Marathi):</strong><br>';
            for (let i = 0; i <= 6; i++) {
                html += '<div class="legend-item">' + i + ': ' + levelDescriptions.marathi[i] + '</div>';
            }
            html += '</div>';

            // Math legend
            html += '<div><strong style="color: #4caf50;">गणित (Math):</strong><br>';
            for (let i = 0; i <= 8; i++) {
                html += '<div class="legend-item">' + i + ': ' + levelDescriptions.math[i] + '</div>';
            }
            html += '</div>';

            // English legend
            html += '<div><strong style="color: #ff9800;">English:</strong><br>';
            for (let i = 0; i <= 6; i++) {
                html += '<div class="legend-item">' + i + ': ' + levelDescriptions.english[i] + '</div>';
            }
            html += '</div>';

            html += '</div></div>';

            html += '<div class="district-grid">';

            districts.forEach(district => {
                html += '<div class="district-card" onclick="showSchoolView(\'' + escapeHtml(district.districtName) + '\')">';
                html += '<div class="card-header">';
                html += '<div class="card-title">🏛️ ' + escapeHtml(district.districtName) + '</div>';
                html += '<div class="card-subtitle">Total Students: ' + district.totalStudents + '</div>';
                html += '<div class="card-subtitle" style="color: #667eea; margin-top: 5px;">Click to view schools →</div>';
                html += '</div>';

                // Marathi section
                html += '<div class="subject-section">';
                html += '<div class="subject-title marathi">मराठी (Marathi)</div>';
                district.marathiDistribution.forEach(level => {
                    html += createLevelBar(level, 'marathi', 'marathi');
                });
                html += '</div>';

                // Math section
                html += '<div class="subject-section">';
                html += '<div class="subject-title math">गणित (Math)</div>';
                district.mathDistribution.forEach(level => {
                    html += createLevelBar(level, 'math', 'math');
                });
                html += '</div>';

                // English section
                html += '<div class="subject-section">';
                html += '<div class="subject-title english">English</div>';
                district.englishDistribution.forEach(level => {
                    html += createLevelBar(level, 'english', 'english');
                });
                html += '</div>';

                html += '</div>';
            });

            html += '</div>';

            document.getElementById('contentArea').innerHTML = html;
        }

        // Display school view
        function displaySchoolView(data) {
            currentView = 'school';

            // Update breadcrumb
            document.getElementById('breadcrumb').innerHTML = `
                <a href="#" onclick="showDistrictView(); return false;">All Districts</a>
                <span> / </span>
                <span>\${data.districtName}</span>
            `;

            const schools = data.schools || [];

            if (schools.length === 0) {
                document.getElementById('contentArea').innerHTML =
                    '<div class="no-data">No schools found in this district</div>';
                return;
            }

            let html = '<div class="stats-summary">';
            html += '<div class="stat-card"><div class="stat-value">' + data.totalStudents + '</div><div class="stat-label">Total Students</div></div>';
            html += '<div class="stat-card"><div class="stat-value">' + data.schoolCount + '</div><div class="stat-label">Schools</div></div>';
            html += '</div>';

            html += '<div class="level-legend">';
            html += '<div class="legend-title">📘 Level Descriptions</div>';
            html += '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 15px; margin-top: 10px;">';

            // Marathi legend
            html += '<div><strong style="color: #2196f3;">मराठी (Marathi):</strong><br>';
            for (let i = 0; i <= 6; i++) {
                html += '<div class="legend-item">' + i + ': ' + levelDescriptions.marathi[i] + '</div>';
            }
            html += '</div>';

            // Math legend
            html += '<div><strong style="color: #4caf50;">गणित (Math):</strong><br>';
            for (let i = 0; i <= 8; i++) {
                html += '<div class="legend-item">' + i + ': ' + levelDescriptions.math[i] + '</div>';
            }
            html += '</div>';

            // English legend
            html += '<div><strong style="color: #ff9800;">English:</strong><br>';
            for (let i = 0; i <= 6; i++) {
                html += '<div class="legend-item">' + i + ': ' + levelDescriptions.english[i] + '</div>';
            }
            html += '</div>';

            html += '</div></div>';

            html += '<div class="district-grid">';

            schools.forEach(school => {
                html += '<div class="school-card">';
                html += '<div class="card-header">';
                html += '<div class="card-title">🏫 ' + escapeHtml(school.schoolName) + '</div>';
                html += '<div class="card-subtitle">UDISE: ' + escapeHtml(school.udiseNo) + '</div>';
                html += '<div class="card-subtitle">Total Students: ' + school.totalStudents + '</div>';
                html += '</div>';

                // Marathi section
                html += '<div class="subject-section">';
                html += '<div class="subject-title marathi">मराठी (Marathi)</div>';
                school.marathiDistribution.forEach(level => {
                    html += createLevelBar(level, 'marathi', 'marathi');
                });
                html += '</div>';

                // Math section
                html += '<div class="subject-section">';
                html += '<div class="subject-title math">गणित (Math)</div>';
                school.mathDistribution.forEach(level => {
                    html += createLevelBar(level, 'math', 'math');
                });
                html += '</div>';

                // English section
                html += '<div class="subject-section">';
                html += '<div class="subject-title english">English</div>';
                school.englishDistribution.forEach(level => {
                    html += createLevelBar(level, 'english', 'english');
                });
                html += '</div>';

                html += '</div>';
            });

            html += '</div>';

            document.getElementById('contentArea').innerHTML = html;
        }

        // Create level bar HTML
        function createLevelBar(levelData, subject, cssClass) {
            const level = levelData.level;
            const count = levelData.count;
            const percentage = levelData.percentage;
            const desc = levelDescriptions[subject][level];

            let html = '<div class="level-bar-container">';
            html += '<div class="level-label">';
            html += '<span>Level ' + level + ': ' + desc + '</span>';
            html += '<span><strong>' + count + '</strong> (' + percentage + '%)</span>';
            html += '</div>';
            html += '<div class="level-bar">';
            if (percentage > 0) {
                html += '<div class="level-bar-fill ' + cssClass + '" style="width: ' + percentage + '%">';
                if (percentage > 10) {
                    html += percentage + '%';
                }
                html += '</div>';
            }
            html += '</div>';
            html += '</div>';

            return html;
        }

        // Show school view for a district
        function showSchoolView(districtName) {
            currentDistrict = districtName;
            currentView = 'school';
            loadData();
        }

        // Show district view
        function showDistrictView() {
            currentView = 'district';
            currentDistrict = null;
            loadData();
        }

        // Show error message
        function showError(message) {
            document.getElementById('contentArea').innerHTML =
                '<div class="error">Error: ' + escapeHtml(message) + '</div>';
        }

        // Escape HTML
        function escapeHtml(text) {
            if (!text) return '';
            const map = {
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&#039;'
            };
            return text.toString().replace(/[&<>"']/g, function(m) { return map[m]; });
        }

        // Export to CSV
        function exportToCSV() {
            if (!currentData) {
                alert('No data to export');
                return;
            }

            let csv = '';
            let filename = '';
            const scopeTag = (selectedDivision === 'ALL') ? 'all_divisions' : selectedDivision;

            if (currentView === 'district') {
                csv = 'District,Total Students,Subject,Level,Level Description,Count,Percentage\n';
                currentData.districts.forEach(d => {
                    d.marathiDistribution.forEach(level => {
                        csv += `"\${d.districtName}",\${d.totalStudents},"Marathi",\${level.level},"\${levelDescriptions.marathi[level.level]}",\${level.count},\${level.percentage}\n`;
                    });
                    d.mathDistribution.forEach(level => {
                        csv += `"\${d.districtName}",\${d.totalStudents},"Math",\${level.level},"\${levelDescriptions.math[level.level]}",\${level.count},\${level.percentage}\n`;
                    });
                    d.englishDistribution.forEach(level => {
                        csv += `"\${d.districtName}",\${d.totalStudents},"English",\${level.level},"\${levelDescriptions.english[level.level]}",\${level.count},\${level.percentage}\n`;
                    });
                });
                filename = 'district_level_distribution_' + scopeTag + '_' + new Date().toISOString().split('T')[0] + '.csv';
            } else {
                csv = 'School Name,UDISE,Total Students,Subject,Level,Level Description,Count,Percentage\n';
                currentData.schools.forEach(s => {
                    s.marathiDistribution.forEach(level => {
                        csv += `"\${s.schoolName}","\${s.udiseNo}",\${s.totalStudents},"Marathi",\${level.level},"\${levelDescriptions.marathi[level.level]}",\${level.count},\${level.percentage}\n`;
                    });
                    s.mathDistribution.forEach(level => {
                        csv += `"\${s.schoolName}","\${s.udiseNo}",\${s.totalStudents},"Math",\${level.level},"\${levelDescriptions.math[level.level]}",\${level.count},\${level.percentage}\n`;
                    });
                    s.englishDistribution.forEach(level => {
                        csv += `"\${s.schoolName}","\${s.udiseNo}",\${s.totalStudents},"English",\${level.level},"\${levelDescriptions.english[level.level]}",\${level.count},\${level.percentage}\n`;
                    });
                });
                filename = 'school_level_distribution_' + currentData.districtName + '_' + new Date().toISOString().split('T')[0] + '.csv';
            }

            // Download CSV
            const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = filename;
            link.click();
        }

        // Search by UDISE number
        function searchByUdise() {
            const udiseInput = document.getElementById('udiseSearch').value.trim();

            if (!udiseInput) {
                alert('Please enter a UDISE number to search');
                return;
            }

            // Show clear filter button
            document.getElementById('clearFilterGroup').style.display = 'flex';

            if (currentView === 'district') {
                findAndShowSchoolByUdise(udiseInput);
            } else {
                filterSchoolsByUdise(udiseInput);
            }
        }

        // Find school by UDISE and show its district's school view
        function findAndShowSchoolByUdise(udiseNumber) {
            if (!currentData || !currentData.districts) {
                alert('Please wait for data to load first');
                return;
            }

            if (currentView === 'school') {
                filterSchoolsByUdise(udiseNumber);
            } else {
                alert('Please enter district view first by clicking on a district, then search for UDISE number.');
                filterDistrictView(udiseNumber);
            }
        }

        // Filter schools by UDISE number in school view
        function filterSchoolsByUdise(udiseNumber) {
            if (!currentData || !currentData.schools) {
                alert('No school data available to filter');
                return;
            }

            const filteredSchools = currentData.schools.filter(school =>
                school.udiseNo.toLowerCase().includes(udiseNumber.toLowerCase())
            );

            if (filteredSchools.length === 0) {
                showError('No schools found matching UDISE: ' + udiseNumber);
                return;
            }

            const filteredData = {
                ...currentData,
                schools: filteredSchools,
                schoolCount: filteredSchools.length,
                totalStudents: filteredSchools.reduce((sum, s) => sum + s.totalStudents, 0)
            };

            displaySchoolView(filteredData);

            document.getElementById('breadcrumb').innerHTML = `
                <a href="#" onclick="showDistrictView(); return false;">All Districts</a>
                <span> / </span>
                <span>\${filteredData.districtName}</span>
                <span> / </span>
                <span style="color: #ff5722;">🔍 Filtered by UDISE: \${udiseNumber}</span>
            `;
        }

        // Filter district view (show message about UDISE search)
        function filterDistrictView(udiseNumber) {
            document.getElementById('contentArea').innerHTML = `
                <div style="text-align: center; padding: 60px;">
                    <h3 style="color: #667eea; margin-bottom: 20px;">🔍 Searching for UDISE: \${udiseNumber}</h3>
                    <p style="color: #666; margin-bottom: 30px;">To search for a specific school by UDISE number, please:</p>
                    <ol style="text-align: left; max-width: 500px; margin: 0 auto; color: #666;">
                        <li style="margin-bottom: 10px;">Click on the district where the school is located</li>
                        <li style="margin-bottom: 10px;">Then use the UDISE search to filter schools in that district</li>
                    </ol>
                    <button class="btn btn-primary" onclick="clearUdiseFilter()" style="margin-top: 30px;">
                        ← Back to All Districts
                    </button>
                </div>
            `;
        }

        // Clear UDISE filter
        function clearUdiseFilter() {
            document.getElementById('udiseSearch').value = '';
            document.getElementById('clearFilterGroup').style.display = 'none';

            if (currentView === 'school' && currentDistrict) {
                loadData();
            } else {
                showDistrictView();
            }
        }

        // Add Enter key support for UDISE search
        document.addEventListener('DOMContentLoaded', function() {
            const udiseInput = document.getElementById('udiseSearch');
            if (udiseInput) {
                udiseInput.addEventListener('keypress', function(e) {
                    if (e.key === 'Enter') {
                        searchByUdise();
                    }
                });
            }
        });
    </script>
</body>
</html>
