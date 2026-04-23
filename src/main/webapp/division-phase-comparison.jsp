<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
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
    <title>Phase-wise Comparison - <%= divisionName %></title>
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
            padding: 10px 15px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            min-width: 200px;
            background: white;
            cursor: pointer;
            transition: all 0.3s;
            font-weight: 500;
        }
        
        .filter-group select:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .school-search-container {
            display: flex;
            flex-direction: column;
            gap: 0;
        }
        
        .school-search-input {
            padding: 10px 15px 10px 35px;
            border: 2px solid #ddd;
            border-bottom: none;
            border-radius: 6px 6px 0 0;
            font-size: 14px;
            min-width: 200px;
            background: white url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="%23999" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><path d="m21 21-4.35-4.35"></path></svg>') no-repeat 10px center;
            background-size: 16px;
            cursor: text;
            transition: all 0.3s;
            font-weight: 500;
        }
        
        .school-search-input::placeholder {
            color: #999;
        }
        
        .school-search-input:disabled {
            background: #f5f5f5 url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="%23ccc" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><path d="m21 21-4.35-4.35"></path></svg>') no-repeat 10px center;
            background-size: 16px;
            cursor: not-allowed;
            opacity: 0.6;
        }
        
        .school-search-input:focus {
            outline: none;
            border-color: #667eea;
            border-bottom: none;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .school-select {
            padding: 10px 15px;
            border: 2px solid #ddd;
            border-radius: 0 0 6px 6px;
            border-top: none;
            font-size: 14px;
            min-width: 200px;
            background: white;
            cursor: pointer;
            transition: all 0.3s;
            font-weight: 500;
        }
        
        .school-select:disabled {
            background: #f5f5f5;
            cursor: not-allowed;
            opacity: 0.6;
        }
        
        .school-select:focus {
            outline: none;
            border-color: #667eea;
            border-top: none;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
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
        
        .phase-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        
        @media (max-width: 1400px) {
            .phase-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }
        
        @media (max-width: 768px) {
            .phase-grid {
                grid-template-columns: 1fr;
            }
        }
        
        .phase-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s, box-shadow 0.3s;
        }
        
        .phase-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }
        
        .phase-header {
            text-align: center;
            margin-bottom: 20px;
            padding: 15px;
            border-radius: 8px;
            font-size: 18px;
            font-weight: 700;
            color: white;
        }
        
        .phase-header.phase-1 {
            background: linear-gradient(135deg, #FF6B6B, #C92A2A);
        }
        
        .phase-header.phase-2 {
            background: linear-gradient(135deg, #4ECDC4, #1A936F);
        }
        
        .phase-header.phase-3 {
            background: linear-gradient(135deg, #FFE66D, #FF6B35);
        }
        
        .phase-header.phase-4 {
            background: linear-gradient(135deg, #A8DADC, #457B9D);
        }
        
        .total-students {
            text-align: center;
            font-size: 14px;
            color: #666;
            margin-bottom: 15px;
            padding: 10px;
            background: #f8f9fa;
            border-radius: 6px;
        }
        
        .total-students strong {
            color: #667eea;
            font-size: 24px;
            display: block;
            margin-bottom: 5px;
        }
        
        .level-section {
            margin-bottom: 15px;
        }
        
        .level-bar-container {
            margin-bottom: 12px;
        }
        
        .level-label {
            font-size: 11px;
            color: #666;
            margin-bottom: 4px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .level-label-text {
            flex: 1;
            font-weight: 500;
        }
        
        .level-label-value {
            font-weight: 700;
            color: #333;
        }
        
        .level-bar {
            height: 24px;
            background: #e0e0e0;
            border-radius: 6px;
            overflow: hidden;
            position: relative;
        }
        
        .level-bar-fill {
            height: 100%;
            transition: width 0.5s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 11px;
            font-weight: 700;
            color: white;
            text-shadow: 0 1px 2px rgba(0,0,0,0.2);
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
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
            font-size: 13px;
        }
        
        .legend-title {
            font-weight: 700;
            margin-bottom: 15px;
            color: #333;
            font-size: 16px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .legend-content {
            display: grid;
            grid-template-columns: 1fr;
            gap: 8px;
        }
        
        .legend-item {
            padding: 8px 12px;
            background: white;
            border-radius: 6px;
            color: #666;
            border-left: 4px solid #667eea;
        }
        
        .stats-summary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 25px;
            border-radius: 12px;
            margin-bottom: 30px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }
        
        .stat-card {
            background: rgba(255, 255, 255, 0.95);
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        .stat-value {
            font-size: 32px;
            font-weight: 700;
            color: #667eea;
            margin-bottom: 8px;
        }
        
        .stat-label {
            font-size: 13px;
            color: #666;
            text-transform: uppercase;
            font-weight: 600;
            letter-spacing: 0.5px;
        }
        
        .district-selector {
            margin-bottom: 30px;
        }
        
        .district-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }
        
        .district-card-selector {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            cursor: pointer;
            transition: all 0.3s;
            text-align: center;
            border: 3px solid transparent;
        }
        
        .district-card-selector:hover {
            transform: translateY(-3px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.15);
            border-color: #667eea;
        }
        
        .district-card-selector.selected {
            border-color: #667eea;
            background: linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%);
        }
        
        .district-name {
            font-size: 16px;
            font-weight: 600;
            color: #333;
            margin-bottom: 8px;
        }
        
        .district-students {
            font-size: 14px;
            color: #666;
        }
        
        .view-selector {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }
        
        .view-btn {
            padding: 10px 20px;
            border: 2px solid #667eea;
            background: white;
            color: #667eea;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .view-btn:hover {
            background: #667eea;
            color: white;
        }
        
        .view-btn.active {
            background: #667eea;
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-nav">
                <a href="<%= request.getContextPath() %>/division-dashboard.jsp" class="back-button">
                    ← Back to Dashboard
                </a>
            </div>
            <div class="header-content">
                <h1>
                    📊 Phase-wise Comparison Analysis
                </h1>
                <div class="header-subtitle">
                    Division: <%= divisionName %> | Compare Student Levels Across All Phases
                </div>
            </div>
        </div>
        
        <div class="breadcrumb" id="breadcrumb">
            <span>Phase Comparison</span>
            <span id="breadcrumbDetail"></span>
        </div>
        
        <div class="toolbar">
            <div class="filter-controls">
                <div class="filter-group">
                    <label>Select Subject</label>
                    <select id="subjectFilter" onchange="loadData()">
                        <option value="marathi" selected>मराठी (Marathi)</option>
                        <option value="math">गणित (Math)</option>
                        <option value="english">English</option>
                    </select>
                </div>
                
                <div class="filter-group">
                    <label>Select District</label>
                    <select id="districtFilter" onchange="onDistrictChange()">
                        <option value="" selected>All Districts (Division Level)</option>
                    </select>
                </div>
                
                <div class="filter-group">
                    <label>Select School</label>
                    <div class="school-search-container">
                        <input type="text" id="schoolSearchInput" placeholder="Type to search schools..." 
                               onkeyup="filterSchoolsDropdown()" oninput="filterSchoolsDropdown()" disabled class="school-search-input" title="Search by school name or UDISE">
                        <select id="schoolFilter" onchange="selectSchoolFromDropdown()" disabled class="school-select">
                            <option value="" selected>All Schools</option>
                        </select>
                    </div>
                </div>
                
                <div class="filter-group">
                    <label>Select Class</label>
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
            <div class="loading">Loading phase comparison data</div>
        </div>
    </div>
    
    <script>
        let currentView = 'division';
        let currentDistrict = null;
        let currentData = null;
        const divisionName = '<%= divisionName %>';
        
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
        
        const subjectNames = {
            marathi: 'मराठी (Marathi)',
            math: 'गणित (Math)',
            english: 'English'
        };
        
        // Initialize on page load
        window.onload = function() {
            loadDistrictsIntoDropdown();
        };
        
        // Load districts into dropdown
        function loadDistrictsIntoDropdown() {
            console.log('Loading districts into dropdown...');
            const url = '<%= request.getContextPath() %>/division-phase-comparison?division=' + 
                      encodeURIComponent(divisionName) + 
                      '&view=division&subject=marathi';
            
            fetch(url)
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.districts) {
                        const districtFilter = document.getElementById('districtFilter');
                        
                        // Clear existing options except the first one
                        districtFilter.innerHTML = '<option value="">All Districts (Division Level)</option>';
                        
                        // Add district options
                        data.districts.forEach(district => {
                            const option = document.createElement('option');
                            option.value = district.name;
                            option.textContent = district.name + ' (' + district.studentCount + ' students)';
                            districtFilter.appendChild(option);
                        });
                        
                        console.log('Loaded', data.districts.length, 'districts into dropdown');
                        
                        // Load initial data
                        loadData();
                    }
                })
                .catch(error => {
                    console.error('Error loading districts:', error);
                    loadData(); // Load data anyway
                });
        }
        
        // Handle district dropdown change
        function onDistrictChange() {
            const selectedDistrict = document.getElementById('districtFilter').value;
            console.log('District dropdown changed to:', selectedDistrict || 'All Districts');
            
            // Clear/disable school dropdown immediately to prevent stale selections
            clearSchoolsDropdown();
            
            if (selectedDistrict) {
                currentView = 'district';
                currentDistrict = selectedDistrict;
                // Load schools after clearing the dropdown
                loadSchoolsForDistrict(selectedDistrict);
            } else {
                currentView = 'division';
                currentDistrict = null;
            }
            
            // Load data after clearing school dropdown to avoid using stale value
            loadData();
        }
        
        // Load schools for selected district
        function loadSchoolsForDistrict(districtName) {
            console.log('Loading schools for district:', districtName);
            const schoolFilter = document.getElementById('schoolFilter');
            const schoolSearchInput = document.getElementById('schoolSearchInput');
            
            const url = '<%= request.getContextPath() %>/division-phase-comparison?action=getSchools&district=' + 
                       encodeURIComponent(districtName);
            
            fetch(url)
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.schools) {
                        schoolFilter.innerHTML = '<option value="" selected>All Schools</option>';
                        schoolSearchInput.value = '';
                        
                        data.schools.forEach(school => {
                            const option = document.createElement('option');
                            option.value = school.udiseNo;
                            option.textContent = (school.schoolName || school.udiseNo) + 
                                                 ' (' + (school.studentCount || 0) + ' students)';
                            schoolFilter.appendChild(option);
                        });
                        
                        schoolFilter.disabled = false;
                        schoolSearchInput.disabled = false;
                        console.log('Loaded', data.schools.length, 'schools');
                    } else {
                        clearSchoolsDropdown();
                    }
                })
                .catch(error => {
                    console.error('Error loading schools:', error);
                    clearSchoolsDropdown();
                });
        }
        
        // Filter schools dropdown based on search input
        function filterSchoolsDropdown() {
            const searchInput = document.getElementById('schoolSearchInput').value.toLowerCase().trim();
            const schoolSelect = document.getElementById('schoolFilter');
            const options = schoolSelect.getElementsByTagName('option');
            
            if (searchInput) {
                console.log('Searching schools for:', searchInput);
            }
            
            let visibleCount = 0;
            
            for (let i = 0; i < options.length; i++) {
                const option = options[i];
                
                // Always show "All Schools" option
                if (option.value === '') {
                    option.style.display = '';
                    continue;
                }
                
                const text = option.textContent.toLowerCase();
                
                // Search in both school name and UDISE number
                // Text format is: "School Name (X students)"
                if (searchInput === '' || text.includes(searchInput)) {
                    option.style.display = '';
                    visibleCount++;
                } else {
                    option.style.display = 'none';
                }
            }
            
            if (searchInput) {
                console.log('Found', visibleCount, 'matching schools for:', searchInput);
            }
        }
        
        // Load classes for selected school
        function loadClassesForSchool() {
            const selectedSchool = document.getElementById('schoolFilter').value;
            const classFilter = document.getElementById('classFilter');
            
            if (!selectedSchool) {
                // No school selected - show default classes
                classFilter.innerHTML = '<option value="">All Classes</option>' +
                                       '<option value="I">Class I</option>' +
                                       '<option value="II">Class II</option>' +
                                       '<option value="III">Class III</option>' +
                                       '<option value="IV">Class IV</option>' +
                                       '<option value="V">Class V</option>' +
                                       '<option value="VI">Class VI</option>' +
                                       '<option value="VII">Class VII</option>' +
                                       '<option value="VIII">Class VIII</option>' +
                                       '<option value="IX">Class IX</option>';
                classFilter.value = '';
                classFilter.disabled = false;
                return;
            }
            
            // Synchronously clear and disable the class filter to prevent stale values
            classFilter.innerHTML = '<option value="">Loading classes...</option>';
            classFilter.disabled = true;
            classFilter.value = '';
            
            // Store request ID to detect stale responses (race condition guard)
            const currentSchool = selectedSchool;
            window.classFilterRequestSchool = currentSchool;
            
            // Fetch classes for selected school
            const url = '<%= request.getContextPath() %>/division-phase-comparison?action=getClasses&school=' + 
                       encodeURIComponent(selectedSchool);
            
            console.log('Loading classes for school:', selectedSchool);
            
            fetch(url)
                .then(response => response.json())
                .then(data => {
                    // Ignore response if a different school is now selected (race condition guard)
                    if (window.classFilterRequestSchool !== currentSchool) {
                        console.log('Ignoring stale class response for school:', currentSchool);
                        return;
                    }
                    
                    if (data.success && data.classes && Array.isArray(data.classes)) {
                        console.log('Loaded', data.classes.length, 'classes for school');
                        classFilter.innerHTML = '<option value="">All Classes</option>';
                        
                        data.classes.forEach(classObj => {
                            const option = document.createElement('option');
                            option.value = classObj.class;
                            option.textContent = classObj.label;
                            classFilter.appendChild(option);
                        });
                        
                        classFilter.disabled = false;
                        classFilter.value = '';
                        // After class dropdown is updated, load data with current school/class values
                        loadData();
                    } else {
                        console.error('Error loading classes:', data.error);
                        // Show only "All Classes" option on error
                        classFilter.innerHTML = '<option value="">All Classes</option>';
                        classFilter.disabled = false;
                        classFilter.value = '';
                        // Load data after error recovery
                        loadData();
                    }
                })
                .catch(error => {
                    // Ignore error if a different school is now selected
                    if (window.classFilterRequestSchool !== currentSchool) {
                        console.log('Fetch cancelled for school:', currentSchool);
                        return;
                    }
                    
                    console.error('Error fetching classes:', error);
                    // On error, show only "All Classes" to avoid misleading data
                    classFilter.innerHTML = '<option value="">All Classes</option>';
                    classFilter.disabled = false;
                    classFilter.value = '';
                    // Load data after error recovery
                    loadData();
                });
        }
        
        // Select school from dropdown
        function selectSchoolFromDropdown() {
            loadClassesForSchool();
        }
        
        // Clear schools dropdown
        function clearSchoolsDropdown() {
            const schoolFilter = document.getElementById('schoolFilter');
            const schoolSearchInput = document.getElementById('schoolSearchInput');
            const classFilter = document.getElementById('classFilter');
            
            schoolFilter.innerHTML = '<option value="" selected>All Schools</option>';
            schoolFilter.disabled = true;
            schoolFilter.value = '';
            schoolSearchInput.value = '';
            schoolSearchInput.disabled = true;
            
            // Reset class dropdown to default
            classFilter.innerHTML = '<option value="">All Classes</option>' +
                                   '<option value="I">Class I</option>' +
                                   '<option value="II">Class II</option>' +
                                   '<option value="III">Class III</option>' +
                                   '<option value="IV">Class IV</option>' +
                                   '<option value="V">Class V</option>' +
                                   '<option value="VI">Class VI</option>' +
                                   '<option value="VII">Class VII</option>' +
                                   '<option value="VIII">Class VIII</option>' +
                                   '<option value="IX">Class IX</option>';
            classFilter.value = '';
        }
        
        // Load data from servlet
        function loadData() {
            const subject = document.getElementById('subjectFilter').value;
            const view = currentView;
            const district = currentDistrict;
            const school = document.getElementById('schoolFilter').value;
            const studentClass = document.getElementById('classFilter').value;
            
            console.log('loadData called - view:', view, 'district:', district, 'subject:', subject, 'school:', school, 'class:', studentClass);
            
            let url = '<%= request.getContextPath() %>/division-phase-comparison?division=' + 
                      encodeURIComponent(divisionName) + 
                      '&view=' + view + 
                      '&subject=' + subject;
            
            if (studentClass) {
                url += '&class=' + encodeURIComponent(studentClass);
            }
            
            if (view === 'district' && district) {
                url += '&district=' + encodeURIComponent(district);
            }
            
            if (school) {
                url += '&school=' + encodeURIComponent(school);
            }
            
            console.log('Fetching phase comparison from:', url);
            
            // Show loading
            document.getElementById('contentArea').innerHTML = '<div class="loading">Loading phase comparison data</div>';
            
            fetch(url)
                .then(response => {
                    console.log('Response status:', response.status);
                    return response.json();
                })
                .then(data => {
                    console.log('Received phase data:', data);
                    if (data.success) {
                        currentData = data;
                        displayPhaseComparison(data);
                    } else {
                        console.error('Error in response:', data.error);
                        showError(data.error || 'Failed to load data');
                    }
                })
                .catch(error => {
                    console.error('Error loading phase data:', error);
                    showError('Error loading data: ' + error.message);
                });
        }
        
        // Display phase comparison
        function displayPhaseComparison(data) {
            console.log('=== displayPhaseComparison called ===');
            console.log('Full data object:', data);
            console.log('Current district:', currentDistrict);
            
            const subject = document.getElementById('subjectFilter').value;
            const subjectName = subjectNames[subject];
            console.log('Selected subject:', subject, '-', subjectName);
            
            // Update breadcrumb
            let breadcrumbHtml = ' / <span>' + subjectName + '</span>';
            if (currentDistrict) {
                breadcrumbHtml += ' / <span>' + escapeHtml(currentDistrict) + '</span>';
            }
            document.getElementById('breadcrumbDetail').innerHTML = breadcrumbHtml;
            
            let html = '';
            
            // Add back button if viewing district
            if (currentDistrict) {
                html += '<div style="margin-bottom: 20px;">';
                html += '<button class="btn btn-primary" onclick="backToDivisionView()" style="background: #667eea;">';
                html += '← Back to Division View';
                html += '</button>';
                html += '</div>';
            }
            
            // Stats summary
            html += '<div class="stats-summary">';
            html += '<div class="stat-card">';
            html += '<div class="stat-value">' + (data.totalStudents || 0) + '</div>';
            html += '<div class="stat-label">Total Students</div>';
            html += '</div>';
            html += '<div class="stat-card">';
            html += '<div class="stat-value">' + subjectName + '</div>';
            html += '<div class="stat-label">Selected Subject</div>';
            html += '</div>';
            if (currentDistrict) {
                html += '<div class="stat-card">';
                html += '<div class="stat-value">' + escapeHtml(currentDistrict) + '</div>';
                html += '<div class="stat-label">Selected District</div>';
                html += '</div>';
            }
            html += '</div>';
            
            // Legend
            html += '<div class="level-legend">';
            html += '<div class="legend-title">📘 ' + subjectName + ' - Level Descriptions</div>';
            html += '<div class="legend-content">';
            const levels = levelDescriptions[subject];
            for (let level in levels) {
                html += '<div class="legend-item"><strong>Level ' + level + ':</strong> ' + levels[level] + '</div>';
            }
            html += '</div></div>';
            
            // Phase cards
            html += '<div class="phase-grid">';
            
            for (let phase = 1; phase <= 4; phase++) {
                const phaseData = data['phase' + phase];
                console.log('Phase', phase, 'data:', phaseData);
                
                if (!phaseData) {
                    console.log('Phase', phase, '- No data available');
                    html += '<div class="phase-card">';
                    html += '<div class="phase-header phase-' + phase + '">Phase ' + phase + '</div>';
                    html += '<div class="no-data" style="padding: 40px 20px;">No data available</div>';
                    html += '</div>';
                    continue;
                }
                
                console.log('Phase', phase, '- Total students:', phaseData.totalStudents);
                console.log('Phase', phase, '- Distribution:', phaseData.distribution);
                
                html += '<div class="phase-card">';
                html += '<div class="phase-header phase-' + phase + '">Phase ' + phase + '</div>';
                html += '<div class="total-students">';
                html += '<strong>' + (phaseData.totalStudents || 0) + '</strong>';
                html += 'Total Students';
                html += '</div>';
                
                // Level distribution
                html += '<div class="level-section">';
                const distribution = phaseData.distribution || [];
                
                if (distribution.length === 0) {
                    console.log('Phase', phase, '- No distribution data (empty array)');
                    html += '<div style="text-align: center; color: #999; padding: 20px;">No level data</div>';
                } else {
                    console.log('Phase', phase, '- Rendering', distribution.length, 'level bars');
                    distribution.forEach((levelData, idx) => {
                        console.log('  Level', idx, ':', levelData);
                        html += createLevelBar(levelData, subject);
                    });
                }
                
                html += '</div>';
                html += '</div>';
            }
            
            html += '</div>';
            
            console.log('Setting contentArea HTML - total length:', html.length, 'characters');
            document.getElementById('contentArea').innerHTML = html;
            console.log('Display complete');
        }
        
        // Create level bar HTML
        function createLevelBar(levelData, subject) {
            const level = levelData.level;
            const count = levelData.count;
            const percentage = levelData.percentage;
            const desc = levelDescriptions[subject][level];
            
            let html = '<div class="level-bar-container">';
            html += '<div class="level-label">';
            html += '<span class="level-label-text">L' + level + ': ' + desc + '</span>';
            html += '<span class="level-label-value">' + count + ' (' + percentage + '%)</span>';
            html += '</div>';
            html += '<div class="level-bar">';
            if (percentage > 0) {
                html += '<div class="level-bar-fill ' + subject + '" style="width: ' + percentage + '%">';
                if (percentage > 8) {
                    html += percentage + '%';
                }
                html += '</div>';
            }
            html += '</div>';
            html += '</div>';
            
            return html;
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
        
        // Back to division view
        function backToDivisionView() {
            currentView = 'division';
            currentDistrict = null;
            document.getElementById('districtFilter').value = '';
            loadData();
        }
        
        // Export to CSV
        function exportToCSV() {
            if (!currentData) {
                alert('No data to export');
                return;
            }
            
            const subject = document.getElementById('subjectFilter').value;
            const subjectName = subjectNames[subject];
            
            let csv = 'Phase,Level,Level Description,Count,Percentage\n';
            
            for (let phase = 1; phase <= 4; phase++) {
                const phaseData = currentData['phase' + phase];
                if (phaseData && phaseData.distribution) {
                    phaseData.distribution.forEach(level => {
                        csv += `"Phase ${phase}",${level.level},"${levelDescriptions[subject][level.level]}",${level.count},${level.percentage}\n`;
                    });
                }
            }
            
            const filename = 'phase_comparison_' + subject + '_' + (currentDistrict || 'division') + '_' + new Date().toISOString().split('T')[0] + '.csv';
            
            // Download CSV
            const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = filename;
            link.click();
        }
    </script>
</body>
</html>
