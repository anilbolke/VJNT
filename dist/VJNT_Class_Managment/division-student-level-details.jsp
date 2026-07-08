<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.DIVISION)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String divisionName = user.getDivisionName();
    // Cache busting version
    String version = "v2.0." + System.currentTimeMillis();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">
    <title>Student Level Details - <%= divisionName %> (<%= version %>)</title>
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
            font-size: 28px;
            margin-bottom: 10px;
        }
        
        .header-subtitle {
            font-size: 16px;
            opacity: 0.9;
        }
        
        .toolbar {
            background: #f8f9fa;
            padding: 20px;
            border-bottom: 2px solid #e0e0e0;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .filter-controls {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            align-items: center;
        }
        
        .filter-controls label {
            font-weight: 600;
            color: #333;
        }
        
        .filter-controls select,
        .filter-controls input[type="text"] {
            padding: 8px 12px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            min-width: 150px;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            text-decoration: none;
            display: inline-block;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        
        .btn-success {
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
            color: white;
        }
        
        .btn-success:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(56, 239, 125, 0.4);
        }
        
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        
        .btn-secondary:hover {
            background: #5a6268;
        }
        
        .content {
            padding: 30px;
        }
        
        .summary-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .summary-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px;
            border-radius: 12px;
            text-align: center;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        
        .summary-card h3 {
            font-size: 36px;
            margin-bottom: 10px;
        }
        
        .summary-card p {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .table-container {
            overflow-x: auto;
            margin-top: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
        }
        
        thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            font-size: 14px;
            white-space: nowrap;
        }
        
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #e0e0e0;
            font-size: 14px;
        }
        
        tbody tr:hover {
            background: #f8f9fa;
        }
        
        tbody tr:nth-child(even) {
            background: #fafbfc;
        }
        
        tbody tr:nth-child(even):hover {
            background: #f0f2f5;
        }
        
        .level-badge {
            display: inline-block;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            text-align: center;
            min-width: 180px;
            max-width: 350px;
            white-space: normal;
            line-height: 1.4;
        }
        
        .level-1 { background: #ffebee; color: #c62828; }
        .level-2 { background: #fff3e0; color: #ef6c00; }
        .level-3 { background: #fff9c4; color: #f57f17; }
        .level-4 { background: #e8f5e9; color: #2e7d32; }
        .level-5 { background: #e3f2fd; color: #1565c0; }
        .level-6 { background: #f3e5f5; color: #6a1b9a; }
        .level-7 { background: #e0f2f1; color: #00695c; }
        .level-8 { background: #e8eaf6; color: #283593; }
        .level-9 { background: #fce4ec; color: #ad1457; }
        .level-0, .level-not-started { background: #f5f5f5; color: #757575; }
        .level-not-started { background: #f5f5f5; color: #757575; }
        
        .phase-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 15px;
            font-size: 11px;
            font-weight: 600;
            background: #667eea;
            color: white;
        }
        
        .no-data {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }
        
        .no-data i {
            font-size: 64px;
            margin-bottom: 20px;
            display: block;
        }
        
        .loading {
            text-align: center;
            padding: 60px 20px;
            color: #667eea;
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
        
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 10px;
            margin-top: 30px;
        }
        
        .pagination button {
            padding: 8px 15px;
            border: 2px solid #667eea;
            background: white;
            color: #667eea;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
        }
        
        .pagination button:hover:not(:disabled) {
            background: #667eea;
            color: white;
        }
        
        .pagination button:disabled {
            opacity: 0.3;
            cursor: not-allowed;
        }
        
        .pagination .page-info {
            font-weight: 600;
            color: #333;
        }
        
        .action-buttons {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
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
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-nav">
                <a href="division-dashboard.jsp" class="back-button">
                    ← Back to Dashboard
                </a>
                <div style="opacity: 0;"><!-- Spacer for centering --></div>
            </div>
            <div class="header-content">
                <h1>👨‍🎓 Student Level Details - विद्यार्थी स्तर तपशील</h1>
                <div class="header-subtitle">
                    <%= divisionName %> Division - Individual Student Progress Tracking
                </div>
            </div>
        </div>
        
        <div class="toolbar">
            <div class="filter-controls">
                <label>🏛️ District:</label>
                <select id="districtFilter" onchange="onDistrictChange()">
                    <option value="">All Districts</option>
                </select>
                
                <label>🏫 School:</label>
                <select id="schoolFilter" onchange="loadData()">
                    <option value="">All Schools</option>
                </select>
                
                <label>📚 Class:</label>
                <select id="classFilter" onchange="loadData()">
                    <option value="">All Classes</option>
                    <option value="I">Class I</option>
                    <option value="II">Class II</option>
                    <option value="III">Class III</option>
                    <option value="IV">Class IV</option>
                    <option value="V">Class V</option>
                    <option value="VI">Class VI</option>
                    <option value="VII">Class VII</option>
                    <option value="VIII">Class VIII</option>
                    <option value="IX">Class IX</option>
                </select>
                
                <label>🔍 Search:</label>
                <input type="text" id="searchInput" placeholder="Student name, PEN, UDISE..." oninput="debouncedFilterTable()">
                
                <button class="btn btn-primary" onclick="resetFilters()">🔄 Reset</button>
            </div>
            
            <div>
                <button class="btn btn-success" onclick="exportToExcel()">📥 Export Excel</button>
                <a href="division-dashboard.jsp" class="btn btn-secondary">← Back</a>
            </div>
        </div>
        
        <div class="content">
            <div class="summary-cards">
                <div class="summary-card">
                    <h3 id="totalStudents">0</h3>
                    <p>Total Students</p>
                </div>
                <div class="summary-card">
                    <h3 id="totalSchools">0</h3>
                    <p>Schools</p>
                </div>
                <div class="summary-card">
                    <h3 id="totalDistricts">0</h3>
                    <p>Districts</p>
                </div>
                <div class="summary-card">
                    <h3 id="avgLevel">-</h3>
                    <p>Avg Level</p>
                </div>
            </div>
            
            <div class="action-buttons">
                <button style="display: none;" class="btn btn-primary" onclick="showAllColumns()">📊 Show All Subjects</button>
                <button class="btn btn-primary" onclick="showPhaseColumns()">📋 Show Phase Only</button>
                <button class="btn btn-primary" onclick="toggleLegend()">ℹ️ Show Level Guide</button>
            </div>
            
            <!-- Level Legend -->
            <div id="levelLegend" style="display: none; background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px; border: 2px solid #667eea;">
                <h3 style="margin-bottom: 15px; color: #667eea;">📚 FLN Subject Level Guide - Official Levels</h3>
                
                <!-- Marathi Levels -->
                <div style="margin-bottom: 20px;">
                    <h4 style="color: #1976d2; margin-bottom: 10px;">📖 मराठी - Marathi (6 Levels)</h4>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 10px;">
                        <div><span class="level-badge level-0">स्थर निश्चित केला नाही</span></div>
                        <div><span class="level-badge level-1">प्रारंभिक स्तर</span></div>
                        <div><span class="level-badge level-2">अक्षर स्तर</span></div>
                        <div><span class="level-badge level-3">शब्द स्तर</span></div>
                        <div><span class="level-badge level-4">वाक्य स्तर</span></div>
                        <div><span class="level-badge level-5">समजपूर्वक उतारा वाचन स्तर</span></div>
                        <div><span class="level-badge level-6">मराठी वाचन व लेखन FLN स्तर 100% पूर्ण</span> ✅</div>
                    </div>
                </div>
                
                <!-- Math Levels -->
                <div style="margin-bottom: 20px;">
                    <h4 style="color: #7b1fa2; margin-bottom: 10px;">🔢 गणित - Math (8 Levels)</h4>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 10px;">
                        <div><span class="level-badge level-0">स्थर निश्चित केला नाही</span></div>
                        <div><span class="level-badge level-1">प्रारंभिक स्तर</span></div>
                        <div><span class="level-badge level-2">अंक ज्ञान स्तर</span></div>
                        <div><span class="level-badge level-3">संख्याज्ञान स्तर</span></div>
                        <div><span class="level-badge level-4">बेरीज स्तर</span></div>
                        <div><span class="level-badge level-5">वजाबाकी स्तर</span></div>
                        <div><span class="level-badge level-6">गुणाकार स्तर</span></div>
                        <div><span class="level-badge level-7">भागाकार स्तर</span></div>
                        <div><span class="level-badge level-8">गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण</span> ✅</div>
                    </div>
                </div>
                
                <!-- English Levels -->
                <div>
                    <h4 style="color: #388e3c; margin-bottom: 10px;">🔤 English (6 Levels)</h4>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 10px;">
                        <div><span class="level-badge level-0">स्थर निश्चित केला नाही</span></div>
                        <div><span class="level-badge level-1">Beginner level</span></div>
                        <div><span class="level-badge level-2">Letter level</span></div>
                        <div><span class="level-badge level-3">Word level</span></div>
                        <div><span class="level-badge level-4">Sentence level</span></div>
                        <div><span class="level-badge level-5">Reading comprehension and dictation level</span></div>
                        <div><span class="level-badge level-6">English reading and writing FLN level 100% complete</span> ✅</div>
                    </div>
                </div>
                
                <p style="margin-top: 20px; color: #666; font-style: italic; border-top: 1px solid #ddd; padding-top: 15px;">
                    💡 <strong>Full level descriptions</strong> displayed in table<br>
                    ✅ Level 6 (Marathi/English) and Level 8 (Math) indicate <strong>100% FLN completion</strong>
                </p>
            </div>
            
            <div class="table-container">
                <table id="studentTable">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Student Name<br>विद्यार्थ्याचे नाव</th>
                            <th>PEN Number</th>
                            <th>UDISE Number</th>
                            <th>School Name<br>शाळेचे नाव</th>
                            <th>District<br>जिल्हा</th>
                            <th>Class<br>वर्ग</th>
                            <th>Current Phase<br>सध्याचा टप्पा</th>
                            <th>Marathi<br>मराठी</th>
                            <th>Math<br>गणित</th>
                            <th>English<br>इंग्रजी</th>
                            <th class="extra-subject" style="display:none;">EVS<br>पर्यावरण</th>
                            <th class="extra-subject" style="display:none;">Science<br>विज्ञान</th>
                            <th class="extra-subject" style="display:none;">History<br>इतिहास</th>
                            <th>Phase Details<br>टप्प्याचे तपशील</th>
                        </tr>
                    </thead>
                    <tbody id="studentTableBody">
                        <tr>
                            <td colspan="15" class="loading">Loading student data...</td>
                        </tr>
                    </tbody>
                </table>
            </div>
            
            <div class="pagination">
                <button onclick="changePage(-1)" id="prevBtn">← Previous</button>
                <span class="page-info">Page <span id="currentPage">1</span> of <span id="totalPages">1</span></span>
                <button onclick="changePage(1)" id="nextBtn">Next →</button>
            </div>
        </div>
    </div>
    
    <script>
        let allStudents = [];
        let filteredStudents = [];
        let currentPage = 1;
        const rowsPerPage = 100; // Increased from 50 for better performance
        let isLoading = false;
        let cachedDistricts = null;
        let cachedSchools = {};
        
        // Load initial data
        window.onload = function() {
            loadDistricts();
            loadData();
        };
        
        // Load districts for filter with caching
        function loadDistricts() {
            if (cachedDistricts) {
                populateDistrictDropdown(cachedDistricts);
                return;
            }
            
            fetch('GetDivisionDistrictsServlet?division=<%= divisionName %>')
                .then(response => response.json())
                .then(districts => {
                    cachedDistricts = districts;
                    populateDistrictDropdown(districts);
                })
                .catch(error => console.error('Error loading districts:', error));
        }
        
        function populateDistrictDropdown(districts) {
            const select = document.getElementById('districtFilter');
            const fragment = document.createDocumentFragment();
            districts.forEach(district => {
                const option = document.createElement('option');
                option.value = district;
                option.textContent = district;
                fragment.appendChild(option);
            });
            select.appendChild(fragment);
        }
        
        // Handle district change - load schools then data with caching
        function onDistrictChange() {
            const district = document.getElementById('districtFilter').value;
            const schoolSelect = document.getElementById('schoolFilter');
            
            // Reset school selection
            schoolSelect.innerHTML = '<option value="">All Schools</option>';
            
            if (district) {
                // Check cache first
                if (cachedSchools[district]) {
                    populateSchoolDropdown(cachedSchools[district]);
                    loadData();
                    return;
                }
                
                // Load schools for selected district
                fetch('GetDistrictSchoolsServlet?district=' + encodeURIComponent(district))
                    .then(response => {
                        if (!response.ok) {
                            throw new Error('Network response was not ok');
                        }
                        return response.json();
                    })
                    .then(data => {
                        // Handle both response formats
                        let schools = [];
                        if (data.success && data.schools) {
                            schools = data.schools;
                        } else if (Array.isArray(data)) {
                            schools = data;
                        }
                        
                        // Cache schools
                        cachedSchools[district] = schools;
                        populateSchoolDropdown(schools);
                        loadData();
                    })
                    .catch(error => {
                        console.error('Error loading schools:', error);
                        loadData();
                    });
            } else {
                loadData();
            }
        }
        
        function populateSchoolDropdown(schools) {
            const schoolSelect = document.getElementById('schoolFilter');
            if (schools.length > 0) {
                const fragment = document.createDocumentFragment();
                schools.forEach(school => {
                    const option = document.createElement('option');
                    option.value = school.udiseNo || school.udise;
                    option.textContent = (school.schoolName || school.name) + ' (' + (school.udiseNo || school.udise) + ')';
                    fragment.appendChild(option);
                });
                schoolSelect.appendChild(fragment);
            }
        }
        
        // Load student data with loading state management
        function loadData() {
            if (isLoading) return; // Prevent multiple simultaneous requests
            
            isLoading = true;
            const district = document.getElementById('districtFilter').value;
            const school = document.getElementById('schoolFilter').value;
            const classFilter = document.getElementById('classFilter').value;
            
            let url = 'GetDivisionStudentLevelsServlet?division=<%= divisionName %>';
            if (district) url += '&district=' + encodeURIComponent(district);
            if (school) url += '&school=' + encodeURIComponent(school);
            if (classFilter) url += '&class=' + encodeURIComponent(classFilter);
            
            document.getElementById('studentTableBody').innerHTML = 
                '<tr><td colspan="15" class="loading">Loading student data...</td></tr>';
            
            const startTime = performance.now();
            
            fetch(url)
                .then(response => response.json())
                .then(data => {
                    const loadTime = ((performance.now() - startTime) / 1000).toFixed(2);
                    console.log('Loaded ' + data.length + ' students in ' + loadTime + 's');
                    
                    allStudents = data;
                    filteredStudents = data;
                    updateSummary();
                    displayPage(1);
                })
                .catch(error => {
                    console.error('Error loading data:', error);
                    document.getElementById('studentTableBody').innerHTML = 
                        '<tr><td colspan="15" class="no-data">❌ Error loading data</td></tr>';
                })
                .finally(() => {
                    isLoading = false;
                });
        }
        
        // Update summary cards
        function updateSummary() {
            const uniqueSchools = new Set(filteredStudents.map(s => s.udiseNo));
            const uniqueDistricts = new Set(filteredStudents.map(s => s.district));
            
            let totalLevels = 0;
            let levelCount = 0;
            filteredStudents.forEach(student => {
                ['marathi', 'math', 'english'].forEach(subject => {
                    if (student[subject + 'Level']) {
                        totalLevels += parseInt(student[subject + 'Level']) || 0;
                        levelCount++;
                    }
                });
            });
            
            document.getElementById('totalStudents').textContent = filteredStudents.length;
            document.getElementById('totalSchools').textContent = uniqueSchools.size;
            document.getElementById('totalDistricts').textContent = uniqueDistricts.size;
            document.getElementById('avgLevel').textContent = levelCount > 0 ? 
                (totalLevels / levelCount).toFixed(1) : '-';
        }
        
        // Display current page with optimized DOM manipulation
        function displayPage(page) {
            currentPage = page;
            const startIdx = (page - 1) * rowsPerPage;
            const endIdx = startIdx + rowsPerPage;
            const pageData = filteredStudents.slice(startIdx, endIdx);
            
            const tbody = document.getElementById('studentTableBody');
            
            if (pageData.length === 0) {
                tbody.innerHTML = '<tr><td colspan="15" class="no-data">📭 No students found</td></tr>';
                return;
            }
            
            const renderStart = performance.now();
            
            // Use DocumentFragment for better performance
            const fragment = document.createDocumentFragment();
            
            pageData.forEach((student, idx) => {
                const row = document.createElement('tr');
                row.innerHTML = 
                    '<td>' + (startIdx + idx + 1) + '</td>' +
                    '<td><strong>' + student.studentName + '</strong></td>' +
                    '<td>' + (student.studentPen || '-') + '</td>' +
                    '<td>' + student.udiseNo + '</td>' +
                    '<td>' + student.schoolName + '</td>' +
                    '<td>' + student.district + '</td>' +
                    '<td><strong>' + student.studentClass + '</strong></td>' +
                    '<td><span class="phase-badge">Phase ' + (student.currentPhase || '1') + '</span></td>' +
                    '<td>' + getLevelBadge(student.marathiLevel, 'marathi') + '</td>' +
                    '<td>' + getLevelBadge(student.mathLevel, 'math') + '</td>' +
                    '<td>' + getLevelBadge(student.englishLevel, 'english') + '</td>' +
                    '<td class="extra-subject" style="display:none;">' + getLevelBadge(student.evsLevel) + '</td>' +
                    '<td class="extra-subject" style="display:none;">' + getLevelBadge(student.scienceLevel) + '</td>' +
                    '<td class="extra-subject" style="display:none;">' + getLevelBadge(student.historyLevel) + '</td>' +
                    '<td style="text-align: center;">' +
                        '<button class="view-phase-btn" onclick="viewPhaseDetails(\'' + student.studentPen + '\', \'' + escapeHtml(student.studentName) + '\')" ' +
                        'style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-size: 12px; font-weight: 600; transition: all 0.3s; display: inline-flex; align-items: center; gap: 5px;" ' +
                        'onmouseover="this.style.transform=\'scale(1.05)\'; this.style.boxShadow=\'0 4px 12px rgba(102, 126, 234, 0.4)\'" ' +
                        'onmouseout="this.style.transform=\'scale(1)\'; this.style.boxShadow=\'none\'">' +
                        '📊 View All Phases' +
                        '</button>' +
                    '</td>';
                fragment.appendChild(row);
            });
            
            // Clear and append all at once
            tbody.innerHTML = '';
            tbody.appendChild(fragment);
            
            const renderTime = ((performance.now() - renderStart) / 1000).toFixed(3);
            console.log('Rendered ' + pageData.length + ' rows in ' + renderTime + 's');
            
            updatePagination();
        }
        
        // Helper function to escape HTML
        function escapeHtml(text) {
            return text.replace(/'/g, "\\'");
        }
        
        // Get level badge HTML with subject-specific FLN competency values
        function getLevelBadge(level, subject) {
            if (!level || level === '' || level === '0' || level === 0) {
                return '<span class="level-badge level-not-started">स्थर निश्चित केला नाही</span>';
            }
            
            // Subject-specific level descriptions - Official FLN Program
            const levelDescriptions = {
                'marathi': {
                    '1': 'प्रारंभिक स्तर',
                    '2': 'अक्षर स्तर',
                    '3': 'शब्द स्तर',
                    '4': 'वाक्य स्तर',
                    '5': 'समजपूर्वक उतारा वाचन स्तर',
                    '6': 'मराठी वाचन व लेखन FLN स्तर 100% पूर्ण'
                },
                'math': {
                    '1': 'प्रारंभिक स्तर',
                    '2': 'अंक ज्ञान स्तर',
                    '3': 'संख्याज्ञान स्तर',
                    '4': 'बेरीज स्तर',
                    '5': 'वजाबाकी स्तर',
                    '6': 'गुणाकार स्तर',
                    '7': 'भागाकार स्तर',
                    '8': 'गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण'
                },
                'english': {
                    '1': 'Beginner level',
                    '2': 'Letter level',
                    '3': 'Word level',
                    '4': 'Sentence level',
                    '5': 'Reading comprehension and dictation level',
                    '6': 'English reading and writing FLN level 100% complete'
                }
            };
            
            // Use generic descriptions if subject not specified
            const subjectLevels = subject ? (levelDescriptions[subject] || levelDescriptions['marathi']) : levelDescriptions['marathi'];
            const levelText = subjectLevels[level] || 'Level ' + level;
            
            return '<span class="level-badge level-' + level + '">' + levelText + '</span>';
        }
        
        // Update pagination
        function updatePagination() {
            const totalPages = Math.ceil(filteredStudents.length / rowsPerPage);
            document.getElementById('currentPage').textContent = currentPage;
            document.getElementById('totalPages').textContent = totalPages;
            document.getElementById('prevBtn').disabled = currentPage === 1;
            document.getElementById('nextBtn').disabled = currentPage === totalPages;
        }
        
        // Change page
        function changePage(direction) {
            const totalPages = Math.ceil(filteredStudents.length / rowsPerPage);
            const newPage = currentPage + direction;
            if (newPage >= 1 && newPage <= totalPages) {
                displayPage(newPage);
            }
        }
        
        // Debounce timer for search
        let searchDebounceTimer;
        
        // Debounced filter function to reduce excessive filtering
        function debouncedFilterTable() {
            clearTimeout(searchDebounceTimer);
            searchDebounceTimer = setTimeout(filterTable, 300); // Wait 300ms after user stops typing
        }
        
        // Filter table by search (optimized)
        function filterTable() {
            const searchText = document.getElementById('searchInput').value.toLowerCase().trim();
            
            if (!searchText) {
                filteredStudents = allStudents;
            } else {
                const filterStart = performance.now();
                filteredStudents = allStudents.filter(student => {
                    // Check most common fields first for early exit
                    return student.studentName.toLowerCase().includes(searchText) ||
                        (student.studentPen && student.studentPen.toLowerCase().includes(searchText)) ||
                        student.udiseNo.includes(searchText) ||
                        student.schoolName.toLowerCase().includes(searchText);
                });
                const filterTime = ((performance.now() - filterStart) / 1000).toFixed(3);
                console.log('Filtered ' + allStudents.length + ' students to ' + filteredStudents.length + ' in ' + filterTime + 's');
            }
            
            updateSummary();
            displayPage(1);
        }
        
        // Reset filters
        function resetFilters() {
            document.getElementById('districtFilter').value = '';
            document.getElementById('schoolFilter').value = '';
            document.getElementById('classFilter').value = '';
            document.getElementById('searchInput').value = '';
            loadData();
        }
        
        // Show/hide columns
        function showAllColumns() {
            document.querySelectorAll('.extra-subject').forEach(el => el.style.display = '');
        }
        
        function showPhaseColumns() {
            document.querySelectorAll('.extra-subject').forEach(el => el.style.display = 'none');
        }
        
        // Toggle level legend
        function toggleLegend() {
            const legend = document.getElementById('levelLegend');
            const btn = event.target;
            if (legend.style.display === 'none') {
                legend.style.display = 'block';
                btn.textContent = 'ℹ️ Hide Level Guide';
            } else {
                legend.style.display = 'none';
                btn.textContent = 'ℹ️ Show Level Guide';
            }
        }
        
        // Export to Excel
        function exportToExcel() {
            let csv = 'Student Name,PEN,UDISE,School,District,Class,Phase,Marathi,Math,English\n';
            
            filteredStudents.forEach(student => {
                csv += `"${student.studentName}","${student.studentPen || ''}","${student.udiseNo}","${student.schoolName}","${student.district}","${student.studentClass}","${student.currentPhase || '1'}","${student.marathiLevel || '0'}","${student.mathLevel || '0'}","${student.englishLevel || '0'}"\n`;
            });
            
            const blob = new Blob([csv], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'student_level_details_' + new Date().toISOString().split('T')[0] + '.csv';
            a.click();
        }
        
        // View Phase Details - Load all phase-wise subject levels for a student
        function viewPhaseDetails(studentPen, studentName) {
            console.log('Opening phase details for:', studentName, 'PEN:', studentPen);
            
            // Show modal
            document.getElementById('phaseDetailsModal').style.display = 'block';
            document.getElementById('modalStudentName').textContent = studentName;
            document.getElementById('modalStudentPen').textContent = studentPen || 'N/A';
            
            // Show loading state
            document.getElementById('phaseDetailsContent').innerHTML = 
                '<div style="text-align: center; padding: 40px;"><div class="spinner"></div><p style="margin-top: 15px;">Loading phase details...</p></div>';
            
            // Fetch phase-wise data from servlet
            const url = 'GetStudentPhaseDetailsServlet?studentPen=' + encodeURIComponent(studentPen);
            console.log('Fetching from URL:', url);
            
            fetch(url)
                .then(response => {
                    console.log('Response status:', response.status);
                    if (!response.ok) {
                        throw new Error('HTTP error! status: ' + response.status);
                    }
                    return response.json();
                })
                .then(data => {
                    console.log('Received data:', data);
                    
                    if (data.error) {
                        document.getElementById('phaseDetailsContent').innerHTML = 
                            '<div style="text-align: center; padding: 40px; color: #d32f2f;">' +
                            '<div style="font-size: 48px; margin-bottom: 15px;">❌</div>' +
                            '<h3 style="margin-bottom: 10px;">Error Loading Data</h3>' +
                            '<p>' + data.error + '</p>' +
                            '</div>';
                        return;
                    }
                    
                    renderPhaseDetails(data);
                })
                .catch(error => {
                    console.error('Error loading phase details:', error);
                    document.getElementById('phaseDetailsContent').innerHTML = 
                        '<div style="text-align: center; padding: 40px; color: #d32f2f;">' +
                        '<div style="font-size: 48px; margin-bottom: 15px;">❌</div>' +
                        '<h3 style="margin-bottom: 10px;">Error Loading Phase Details</h3>' +
                        '<p>' + error.message + '</p>' +
                        '<p style="margin-top: 10px; font-size: 12px; color: #666;">Please check the browser console for more details.</p>' +
                        '</div>';
                });
        }
        
        // Render phase-wise details in modal
        function renderPhaseDetails(data) {
            const phases = data.phases || [];
            
            if (phases.length === 0) {
                document.getElementById('phaseDetailsContent').innerHTML = 
                    '<div style="text-align: center; padding: 40px; color: #666;">📭 No phase data available for this student</div>';
                return;
            }
            
            let html = '<div style="display: grid; gap: 20px;">';
            
            phases.forEach(phase => {
                // Determine phase status
                const isCompleted = phase.completed === true;
                const bgColor = isCompleted ? '#f1f8e9' : '#fafafa';
                const borderColor = isCompleted ? '#7cb342' : '#bdbdbd';
                const statusIcon = isCompleted ? '✓' : '○';
                const statusText = isCompleted ? 'Completed' : 'Not Completed';
                const statusColor = isCompleted ? '#7cb342' : '#999';
                
                // Build date display separately to avoid JSP EL conflict
                let dateDisplay = '';
                if (phase.lastUpdated) {
                    dateDisplay = '<div style="font-size: 10px; color: #666; margin-top: 3px;">📅 ' + phase.lastUpdated + '</div>';
                }
                
                // Build Marathi level display
                const marathiColor = (phase.marathiLevel && phase.marathiLevel !== 'स्तर निश्चित केला नाही') ? '#333' : '#999';
                const marathiStyle = (!phase.marathiLevel || phase.marathiLevel === 'स्तर निश्चित केला नाही') ? 'font-style: italic;' : '';
                const marathiText = phase.marathiLevel || 'स्तर निश्चित केला नाही';
                
                // Build Math level display
                const mathColor = (phase.mathLevel && phase.mathLevel !== 'स्तर निश्चित केला नाही') ? '#333' : '#999';
                const mathStyle = (!phase.mathLevel || phase.mathLevel === 'स्तर निश्चित केला नाही') ? 'font-style: italic;' : '';
                const mathText = phase.mathLevel || 'स्तर निश्चित केला नाही';
                
                // Build English level display
                const englishColor = (phase.englishLevel && phase.englishLevel !== 'स्तर निश्चित केला नाही') ? '#333' : '#999';
                const englishStyle = (!phase.englishLevel || phase.englishLevel === 'स्तर निश्चित केला नाही') ? 'font-style: italic;' : '';
                const englishText = phase.englishLevel || 'स्तर निश्चित केला नाही';
                
                html += '<div style="background: ' + bgColor + '; padding: 18px; border-radius: 10px; margin-bottom: 15px; border: 2px solid ' + borderColor + '; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">';
                html += '<!-- Phase Header -->';
                html += '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; padding-bottom: 10px; border-bottom: 2px solid ' + borderColor + ';">';
                html += '<h3 style="margin: 0; color: #333; font-size: 18px;">📋 Phase ' + phase.phaseNumber + '</h3>';
                html += '<div style="text-align: right;">';
                html += '<div style="font-size: 20px; color: ' + statusColor + ';">' + statusIcon + '</div>';
                html += '<div style="font-size: 11px; color: ' + statusColor + '; font-weight: 600;">' + statusText + '</div>';
                html += dateDisplay;
                html += '</div>';
                html += '</div>';
                
                html += '<!-- Subject Levels Grid -->';
                html += '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 12px;">';
                
                // Marathi
                html += '<div style="background: white; padding: 12px; border-radius: 8px; border-left: 4px solid #ff9800;">';
                html += '<div style="font-weight: 600; color: #e65100; margin-bottom: 6px; font-size: 13px;">📚 मराठी (Marathi)</div>';
                html += '<div style="font-size: 12px; color: ' + marathiColor + '; line-height: 1.4; ' + marathiStyle + '">';
                html += marathiText;
                html += '</div>';
                html += '</div>';
                
                // Math
                html += '<div style="background: white; padding: 12px; border-radius: 8px; border-left: 4px solid #9c27b0;">';
                html += '<div style="font-weight: 600; color: #6a1b9a; margin-bottom: 6px; font-size: 13px;">🔢 गणित (Math)</div>';
                html += '<div style="font-size: 12px; color: ' + mathColor + '; line-height: 1.4; ' + mathStyle + '">';
                html += mathText;
                html += '</div>';
                html += '</div>';
                
                // English
                html += '<div style="background: white; padding: 12px; border-radius: 8px; border-left: 4px solid #4caf50;">';
                html += '<div style="font-weight: 600; color: #2e7d32; margin-bottom: 6px; font-size: 13px;">🔤 English</div>';
                html += '<div style="font-size: 12px; color: ' + englishColor + '; line-height: 1.4; ' + englishStyle + '">';
                html += englishText;
                html += '</div>';
                html += '</div>';
                
                html += '</div>'; // End grid
                html += '</div>'; // End phase card
            });
            
            html += '</div>';
            
            // Add summary at the bottom
            const completedPhases = phases.filter(p => p.completed).length;
            const completionPercent = Math.round((completedPhases / 4) * 100);
            
            html += '<div style="background: linear-gradient(135deg, #7b1fa2 0%, #4a148c 100%); color: white; padding: 15px; border-radius: 8px; margin-top: 20px; text-align: center;">';
            html += '<div style="font-size: 16px; font-weight: 600;">Progress Summary</div>';
            html += '<div style="font-size: 28px; font-weight: bold; margin: 8px 0;">' + completedPhases + ' / 4 Phases Completed</div>';
            html += '<div style="font-size: 13px; opacity: 0.9;">(' + completionPercent + '% Complete)</div>';
            html += '</div>';
            
            document.getElementById('phaseDetailsContent').innerHTML = html;
        }
        
        // Close phase details modal
        function closePhaseDetailsModal() {
            document.getElementById('phaseDetailsModal').style.display = 'none';
        }
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('phaseDetailsModal');
            if (event.target === modal) {
                modal.style.display = 'none';
            }
        }
    </script>
    
    <!-- Phase Details Modal -->
    <div id="phaseDetailsModal" style="display: none; position: fixed; z-index: 10000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.7);">
        <div style="position: relative; margin: 2% auto; max-width: 1200px; background: white; border-radius: 12px; box-shadow: 0 10px 50px rgba(0,0,0,0.3);">
            <!-- Modal Header -->
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 25px 30px; border-radius: 12px 12px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <h2 style="margin: 0; font-size: 24px; font-weight: 700;">📊 <span id="modalStudentName"></span> - Phase Details</h2>
                    <p style="margin: 8px 0 0 0; font-size: 14px; opacity: 0.95;">PEN: <span id="modalStudentPen"></span> | Phase-wise Subject Level Progress</p>
                </div>
                <button onclick="closePhaseDetailsModal()" 
                        style="background: rgba(255,255,255,0.2); border: none; color: white; font-size: 32px; cursor: pointer; width: 45px; height: 45px; border-radius: 50%; display: flex; align-items: center; justify-content: center; transition: all 0.3s; font-weight: 300;"
                        onmouseover="this.style.background='rgba(255,255,255,0.3)'"
                        onmouseout="this.style.background='rgba(255,255,255,0.2)'">
                    ×
                </button>
            </div>
            
            <!-- Modal Content -->
            <div id="phaseDetailsContent" style="padding: 30px; max-height: 70vh; overflow-y: auto;">
                <!-- Content will be loaded here -->
            </div>
            
            <!-- Modal Footer -->
            <div style="padding: 20px 30px; background: #f8f9fa; border-top: 1px solid #e0e0e0; border-radius: 0 0 12px 12px; text-align: right;">
                <button onclick="closePhaseDetailsModal()" 
                        style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; padding: 12px 30px; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; transition: all 0.3s;"
                        onmouseover="this.style.transform='scale(1.05)'"
                        onmouseout="this.style.transform='scale(1)'">
                    Close
                </button>
            </div>
        </div>
    </div>
</body>
</html>
