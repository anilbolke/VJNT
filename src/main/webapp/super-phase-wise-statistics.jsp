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
    <title>Phase-wise Statistics - All Divisions</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 1600px; margin: 0 auto; background: white; border-radius: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); overflow: hidden; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
        .header h1 { font-size: 28px; margin-bottom: 10px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        .header-subtitle { font-size: 16px; opacity: 0.95; }
        .toolbar { display: flex; justify-content: space-between; align-items: center; padding: 20px 30px; background: #f8f9fa; border-bottom: 2px solid #e9ecef; flex-wrap: wrap; gap: 15px; }
        .filter-controls { display: flex; gap: 15px; flex-wrap: wrap; align-items: center; }
        .filter-controls label { font-weight: 600; color: #495057; }
        .filter-controls select { padding: 8px 12px; border: 1px solid #ced4da; border-radius: 5px; font-size: 14px; min-width: 200px; }
        #divisionFilter { border: 2px solid #667eea; font-weight: 600; color: #4a4a8a; }
        .filter-controls input[type="text"] { padding: 8px 12px; border: 1px solid #ced4da; border-radius: 5px; font-size: 14px; min-width: 300px; }
        .filter-controls input[type="text"]:focus { outline: none; border-color: #667eea; box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1); }
        .btn { padding: 10px 20px; border: none; border-radius: 5px; font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.3s; text-decoration: none; display: inline-block; }
        .btn-primary { background: #667eea; color: white; }
        .btn-primary:hover { background: #5568d3; transform: translateY(-2px); }
        .btn-secondary { background: #6c757d; color: white; }
        .btn-secondary:hover { background: #5a6268; }
        .content { padding: 30px; }
        .summary-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .summary-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; text-align: center; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .summary-card h3 { font-size: 32px; margin-bottom: 5px; }
        .summary-card p { font-size: 14px; opacity: 0.9; }
        .view-tabs { display: flex; gap: 10px; margin-bottom: 20px; border-bottom: 2px solid #e9ecef; flex-wrap: wrap; }
        .view-tab { padding: 12px 24px; background: #f8f9fa; border: none; border-radius: 8px 8px 0 0; cursor: pointer; font-weight: 600; color: #495057; transition: all 0.3s; }
        .view-tab.active { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; transform: translateY(2px); }
        .view-tab:hover { background: #e9ecef; }
        .view-tab.active:hover { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
        .view-content { display: none; }
        .view-content.active { display: block; }
        .district-section { margin-bottom: 30px; border: 2px solid #e9ecef; border-radius: 10px; overflow: hidden; }
        .district-header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px 20px; cursor: pointer; display: flex; justify-content: space-between; align-items: center; }
        .district-header:hover { background: linear-gradient(135deg, #5568d3 0%, #653a8b 100%); }
        .district-header h3 { font-size: 18px; }
        .district-body { padding: 20px; background: #f8f9fa; }
        .school-card { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); cursor: pointer; transition: all 0.3s; }
        .school-card:hover { box-shadow: 0 4px 8px rgba(0,0,0,0.15); transform: translateY(-2px); }
        .school-card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; padding-bottom: 10px; border-bottom: 2px solid #e9ecef; }
        .school-name { font-size: 16px; font-weight: 600; color: #667eea; }
        .school-udise { font-size: 13px; color: #666; }
        .phase-tabs { display: flex; gap: 10px; margin: 15px 0; flex-wrap: wrap; }
        .phase-tab { padding: 8px 16px; background: #e9ecef; border: none; border-radius: 5px; cursor: pointer; font-weight: 600; color: #495057; transition: all 0.3s; font-size: 13px; }
        .phase-tab.active { background: #667eea; color: white; }
        .phase-tab:hover { background: #dee2e6; }
        .phase-tab.active:hover { background: #5568d3; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 15px; margin-top: 15px; }
        .subject-stats { background: #f8f9fa; padding: 15px; border-radius: 8px; border: 1px solid #e9ecef; }
        .subject-stats h4 { margin-bottom: 10px; color: #667eea; display: flex; align-items: center; gap: 8px; font-size: 14px; }
        .level-count { display: flex; justify-content: space-between; padding: 6px 0; border-bottom: 1px solid #e9ecef; font-size: 13px; }
        .level-count:last-child { border-bottom: none; }
        .level-label { font-weight: 600; color: #495057; }
        .level-value { background: #667eea; color: white; padding: 2px 8px; border-radius: 10px; font-weight: 600; min-width: 25px; text-align: center; font-size: 12px; }
        .aggregate-section { background: #f8f9fa; padding: 20px; border-radius: 10px; margin-bottom: 20px; }
        .aggregate-section h3 { margin-bottom: 15px; color: #495057; }
        .loading { text-align: center; padding: 40px; font-size: 18px; color: #667eea; }
        .error { background: #f8d7da; color: #721c24; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .toggle-icon { transition: transform 0.3s; }
        .toggle-icon.collapsed { transform: rotate(-90deg); }
        .school-stats-container { display: none; margin-top: 15px; }
        .school-stats-container.active { display: block; }
        @media (max-width: 768px) {
            .toolbar { flex-direction: column; align-items: stretch; }
            .filter-controls { flex-direction: column; width: 100%; }
            .filter-controls select { width: 100%; }
            .summary-cards { grid-template-columns: 1fr; }
            .stats-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Phase-wise Subject Statistics</h1>
            <h1>टप्पा-निहाय विषय आकडेवारी</h1>
            <div class="header-subtitle" id="scopeSubtitle">
                All Divisions
            </div>
        </div>

        <div class="toolbar">
            <div class="filter-controls">
                <label>🌐 Division:</label>
                <select id="divisionFilter" onchange="onDivisionChange()">
                    <option value="ALL" selected>All Divisions</option>
                    <% for (String div : divisions) { %>
                        <option value="<%= div %>"><%= div %></option>
                    <% } %>
                </select>

                <label>🏛️ Filter by District:</label>
                <select id="districtFilter" onchange="filterData()">
                    <option value="">All Districts</option>
                </select>

                <label>🔍 Search School:</label>
                <input type="text" id="schoolSearchInput" placeholder="Type school name or UDISE..."
                       oninput="searchSchool()" style="margin-right: 10px;">

                <label>🏫 Filter by School:</label>
                <select id="schoolFilter" onchange="filterData()">
                    <option value="">All Schools</option>
                </select>

                <label>📚 Filter by Class:</label>
                <select id="classFilter" onchange="filterData()">
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

                <button class="btn btn-primary" onclick="resetFilters()">🔄 Reset Filters</button>
            </div>

            <div>
                <a href="<%= request.getContextPath() %>/super-officer-dashboard.jsp" class="btn btn-secondary">← Back to Dashboard</a>
            </div>
        </div>

        <div class="content">
            <div class="summary-cards" id="summaryCards">
                <div class="summary-card">
                    <h3 id="totalSchools">-</h3>
                    <p>Total Schools</p>
                </div>
                <div class="summary-card">
                    <h3 id="totalDistricts">-</h3>
                    <p>Total Districts</p>
                </div>
                <div class="summary-card">
                    <h3 id="totalStudents">-</h3>
                    <p>Total Students</p>
                </div>
            </div>

            <div class="view-tabs">
                <button class="view-tab active" onclick="showView('division')">📊 Overall Summary</button>
                <button class="view-tab" onclick="showView('district')">🏛️ District-wise View</button>
                <button class="view-tab" onclick="showView('school')">🏫 School-wise View</button>
            </div>

            <!-- Overall Summary View -->
            <div id="divisionView" class="view-content active">
                <div class="aggregate-section">
                    <h3>📊 Aggregate Statistics</h3>
                    <p style="color: #666; margin-bottom: 20px;" id="aggregateScopeNote">Combined statistics from all schools across all divisions</p>

                    <div class="phase-tabs">
                        <button class="phase-tab active" onclick="showDivisionPhase(1)">Phase 1</button>
                        <button class="phase-tab" onclick="showDivisionPhase(2)">Phase 2</button>
                        <button class="phase-tab" onclick="showDivisionPhase(3)">Phase 3</button>
                        <button class="phase-tab" onclick="showDivisionPhase(4)">Phase 4</button>
                    </div>

                    <div id="divisionPhase1" class="stats-grid" style="display: grid;"></div>
                    <div id="divisionPhase2" class="stats-grid" style="display: none;"></div>
                    <div id="divisionPhase3" class="stats-grid" style="display: none;"></div>
                    <div id="divisionPhase4" class="stats-grid" style="display: none;"></div>
                </div>
            </div>

            <!-- District-wise View -->
            <div id="districtView" class="view-content">
                <div id="districtContainer"></div>
            </div>

            <!-- School-wise View -->
            <div id="schoolView" class="view-content">
                <div id="schoolContainer"></div>
            </div>

            <div id="loadingMessage" class="loading">⏳ Loading statistics...</div>
        </div>
    </div>

    <script>
        let allData = null;
        let currentFilters = {
            division: 'ALL',
            district: '',
            school: '',
            studentClass: ''
        };

        document.addEventListener('DOMContentLoaded', function() {
            loadData();
        });

        // Division dropdown changed: reset dependent filters and reload for new scope
        function onDivisionChange() {
            currentFilters.division = document.getElementById('divisionFilter').value;
            currentFilters.district = '';
            currentFilters.school = '';
            currentFilters.studentClass = '';
            document.getElementById('classFilter').value = '';
            document.getElementById('schoolSearchInput').value = '';

            const label = (currentFilters.division === 'ALL') ? 'All Divisions' : currentFilters.division + ' Division';
            document.getElementById('scopeSubtitle').textContent = label;
            document.getElementById('aggregateScopeNote').textContent =
                (currentFilters.division === 'ALL')
                    ? 'Combined statistics from all schools across all divisions'
                    : 'Combined statistics from all schools in ' + currentFilters.division + ' Division';

            document.getElementById('loadingMessage').style.display = 'block';
            document.querySelectorAll('.view-content').forEach(v => v.classList.remove('active'));
            loadData();
        }

        // Division scope query fragment ('' when All Divisions)
        function divisionParam() {
            return (currentFilters.division && currentFilters.division !== 'ALL')
                ? 'division=' + encodeURIComponent(currentFilters.division) : '';
        }

        function loadData() {
            let urlParams = [];
            const dq = divisionParam();
            if (dq) urlParams.push(dq);
            if (currentFilters.district) {
                urlParams.push('district=' + encodeURIComponent(currentFilters.district));
            }
            if (currentFilters.school) {
                urlParams.push('school=' + encodeURIComponent(currentFilters.school));
            }
            if (currentFilters.studentClass) {
                urlParams.push('class=' + encodeURIComponent(currentFilters.studentClass));
            }

            const url = '<%= request.getContextPath() %>/super-phase-statistics' + (urlParams.length > 0 ? '?' + urlParams.join('&') : '');

            fetch(url)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        allData = data;

                        if (data.filteredSchools === 0) {
                            showError('No data found for the selected filters. Try adjusting your filter criteria.');
                            document.getElementById('loadingMessage').style.display = 'none';
                            return;
                        }

                        populateFilters();
                        updateSummaryCards();
                        populateAllViews();
                        document.getElementById('loadingMessage').style.display = 'none';

                        const activeTab = document.querySelector('.view-tab.active');
                        let viewToShow = 'divisionView';

                        if (activeTab) {
                            if (activeTab.textContent.includes('District')) {
                                viewToShow = 'districtView';
                            } else if (activeTab.textContent.includes('School')) {
                                viewToShow = 'schoolView';
                            }
                        }

                        document.getElementById(viewToShow).classList.add('active');
                    } else {
                        showError(data.message);
                        document.getElementById('loadingMessage').style.display = 'none';
                    }
                })
                .catch(error => {
                    console.error('Error loading data:', error);
                    showError('Failed to load data: ' + error.message);
                    document.getElementById('loadingMessage').style.display = 'none';
                });
        }

        function populateFilters() {
            const districtFilter = document.getElementById('districtFilter');
            const schoolFilter = document.getElementById('schoolFilter');

            districtFilter.innerHTML = '<option value="">All Districts</option>';
            schoolFilter.innerHTML = '<option value="">All Schools</option>';

            allData.districts.forEach(district => {
                const option = document.createElement('option');
                option.value = district;
                option.textContent = district;
                if (district === currentFilters.district) option.selected = true;
                districtFilter.appendChild(option);
            });

            Object.values(allData.schoolData).forEach(school => {
                const option = document.createElement('option');
                option.value = school.udiseNo;
                option.textContent = school.schoolName + ' - UDISE: ' + school.udiseNo + ' (' + school.districtName + ')';
                if (school.udiseNo === currentFilters.school) option.selected = true;
                schoolFilter.appendChild(option);
            });
        }

        function updateSummaryCards() {
            document.getElementById('totalSchools').textContent = allData.filteredSchools;
            document.getElementById('totalDistricts').textContent = allData.districts.length;
            document.getElementById('totalStudents').textContent = allData.divisionSummary.totalStudents || 0;
        }

        function populateAllViews() {
            populateDivisionView();
            populateDistrictView();
            populateSchoolView();
        }

        function populateDivisionView() {
            for (let phase = 1; phase <= 4; phase++) {
                const container = document.getElementById('divisionPhase' + phase);
                container.innerHTML = getPhaseStatsHTML(allData.divisionSummary, phase);
            }
        }

        function populateDistrictView() {
            const container = document.getElementById('districtContainer');
            let html = '';

            allData.districts.forEach(district => {
                const districtStats = allData.districtData[district];
                const districtId = 'district_' + district.replace(/[^a-zA-Z0-9]/g, '_');

                html += '<div class="district-section">' +
                    '<div class="district-header" onclick="toggleDistrict(\'' + districtId + '\')">' +
                        '<h3>🏛️ ' + escapeHtml(district) + ' District (' + districtStats.totalStudents + ' students)</h3>' +
                        '<span class="toggle-icon" id="' + districtId + '_icon">▼</span>' +
                    '</div>' +
                    '<div class="district-body" id="' + districtId + '">' +
                        '<div class="phase-tabs">' +
                            '<button class="phase-tab active" onclick="showDistrictPhase(\'' + districtId + '\', 1)">Phase 1</button>' +
                            '<button class="phase-tab" onclick="showDistrictPhase(\'' + districtId + '\', 2)">Phase 2</button>' +
                            '<button class="phase-tab" onclick="showDistrictPhase(\'' + districtId + '\', 3)">Phase 3</button>' +
                            '<button class="phase-tab" onclick="showDistrictPhase(\'' + districtId + '\', 4)">Phase 4</button>' +
                        '</div>' +
                        '<div id="' + districtId + '_phase1" class="stats-grid" style="display: grid;">' +
                            getPhaseStatsHTML(districtStats, 1) +
                        '</div>' +
                        '<div id="' + districtId + '_phase2" class="stats-grid" style="display: none;">' +
                            getPhaseStatsHTML(districtStats, 2) +
                        '</div>' +
                        '<div id="' + districtId + '_phase3" class="stats-grid" style="display: none;">' +
                            getPhaseStatsHTML(districtStats, 3) +
                        '</div>' +
                        '<div id="' + districtId + '_phase4" class="stats-grid" style="display: none;">' +
                            getPhaseStatsHTML(districtStats, 4) +
                        '</div>' +
                    '</div>' +
                '</div>';
            });

            container.innerHTML = html || '<p style="text-align: center; color: #666; padding: 40px;">No district data available</p>';
        }

        function populateSchoolView() {
            const container = document.getElementById('schoolContainer');
            let html = '';

            Object.values(allData.schoolData).forEach(school => {
                const schoolId = 'school_' + school.udiseNo.replace(/[^a-zA-Z0-9]/g, '_');
                const stats = school.statistics;

                html += '<div class="school-card">' +
                    '<div class="school-card-header" onclick="toggleSchool(\'' + schoolId + '\')">' +
                        '<div>' +
                            '<div class="school-name">🏫 ' + escapeHtml(school.schoolName) + '</div>' +
                            '<div class="school-udise">📍 ' + escapeHtml(school.districtName) + ' | UDISE: ' + school.udiseNo + ' | ' + (stats.totalStudents || 0) + ' students</div>' +
                        '</div>' +
                        '<span class="toggle-icon collapsed" id="' + schoolId + '_icon">▼</span>' +
                    '</div>' +
                    '<div class="school-stats-container" id="' + schoolId + '">' +
                        '<div class="phase-tabs">' +
                            '<button class="phase-tab active" onclick="showSchoolPhase(\'' + schoolId + '\', 1)">Phase 1</button>' +
                            '<button class="phase-tab" onclick="showSchoolPhase(\'' + schoolId + '\', 2)">Phase 2</button>' +
                            '<button class="phase-tab" onclick="showSchoolPhase(\'' + schoolId + '\', 3)">Phase 3</button>' +
                            '<button class="phase-tab" onclick="showSchoolPhase(\'' + schoolId + '\', 4)">Phase 4</button>' +
                        '</div>' +
                        '<div id="' + schoolId + '_phase1" class="stats-grid" style="display: grid;">' +
                            getPhaseStatsHTML(stats, 1) +
                        '</div>' +
                        '<div id="' + schoolId + '_phase2" class="stats-grid" style="display: none;">' +
                            getPhaseStatsHTML(stats, 2) +
                        '</div>' +
                        '<div id="' + schoolId + '_phase3" class="stats-grid" style="display: none;">' +
                            getPhaseStatsHTML(stats, 3) +
                        '</div>' +
                        '<div id="' + schoolId + '_phase4" class="stats-grid" style="display: none;">' +
                            getPhaseStatsHTML(stats, 4) +
                        '</div>' +
                    '</div>' +
                '</div>';
            });

            container.innerHTML = html || '<p style="text-align: center; color: #666; padding: 40px;">No school data available</p>';
        }

        function getPhaseStatsHTML(stats, phase) {
            const marathiCounts = stats['phase' + phase + '_marathi'] || {};
            const mathCounts = stats['phase' + phase + '_math'] || {};
            const englishCounts = stats['phase' + phase + '_english'] || {};

            return '<div class="subject-stats">' +
                    '<h4>📚 Marathi (मराठी)</h4>' +
                    getLevelCountsHTML(marathiCounts, 'marathi') +
                '</div>' +
                '<div class="subject-stats">' +
                    '<h4>🔢 Math (गणित)</h4>' +
                    getLevelCountsHTML(mathCounts, 'math') +
                '</div>' +
                '<div class="subject-stats">' +
                    '<h4>🔤 English</h4>' +
                    getLevelCountsHTML(englishCounts, 'english') +
                '</div>';
        }

        function getLevelCountsHTML(counts, subject) {
            let html = '';
            let maxLevel = 4;

            if (subject === 'math') {
                maxLevel = 8;
            } else if (subject === 'marathi' || subject === 'english') {
                maxLevel = 6;
            }

            for (let i = 0; i <= maxLevel; i++) {
                const count = counts[i] || 0;
                const levelLabel = getLevelLabel(i, subject);

                html += '<div class="level-count">' +
                    '<span class="level-label">' + levelLabel + '</span>' +
                    '<span class="level-value">' + count + '</span>' +
                    '</div>';
            }
            return html;
        }

        function getLevelLabel(level, subject) {
            const marathiLabels = {
                0: 'स्थर निश्चित केला नाही', 1: 'प्रारंभिक स्तर', 2: 'अक्षर स्तर', 3: 'शब्द स्तर',
                4: 'वाक्य स्तर', 5: 'समजपूर्वक उतारा वाचन स्तर', 6: 'मराठी वाचन व लेखन FLN स्तर 100% पूर्ण'
            };
            const mathLabels = {
                0: 'स्थर निश्चित केला नाही', 1: 'प्रारंभिक स्तर', 2: 'अंक ज्ञान स्तर', 3: 'संख्याज्ञान स्तर',
                4: 'बेरीज स्तर', 5: 'वजाबाकी स्तर', 6: 'गुणाकार स्तर', 7: 'भागाकार स्तर',
                8: 'गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण'
            };
            const englishLabels = {
                0: 'स्थर निश्चित केला नाही', 1: 'Beginner level', 2: 'Alphabet level', 3: 'Word level',
                4: 'Sentence level', 5: 'Paragraph Reading with Understanding', 6: 'English reading and writing FLN level 100% complete'
            };

            if (subject === 'marathi') return marathiLabels[level] || 'L' + level;
            if (subject === 'math') return mathLabels[level] || 'L' + level;
            if (subject === 'english') return englishLabels[level] || 'L' + level;
            return 'Level ' + level;
        }

        function showView(view) {
            document.querySelectorAll('.view-tab').forEach(tab => tab.classList.remove('active'));
            event.target.classList.add('active');

            document.querySelectorAll('.view-content').forEach(content => content.classList.remove('active'));
            document.getElementById(view + 'View').classList.add('active');
        }

        function showDivisionPhase(phase) {
            const parent = event.target.parentElement;
            parent.querySelectorAll('.phase-tab').forEach(tab => tab.classList.remove('active'));
            event.target.classList.add('active');

            for (let i = 1; i <= 4; i++) {
                const phaseDiv = document.getElementById('divisionPhase' + i);
                phaseDiv.style.display = (i === phase) ? 'grid' : 'none';
            }
        }

        function showDistrictPhase(districtId, phase) {
            const parent = event.target.parentElement;
            parent.querySelectorAll('.phase-tab').forEach(tab => tab.classList.remove('active'));
            event.target.classList.add('active');

            for (let i = 1; i <= 4; i++) {
                const phaseDiv = document.getElementById(districtId + '_phase' + i);
                phaseDiv.style.display = (i === phase) ? 'grid' : 'none';
            }
        }

        function showSchoolPhase(schoolId, phase) {
            const parent = event.target.parentElement;
            parent.querySelectorAll('.phase-tab').forEach(tab => tab.classList.remove('active'));
            event.target.classList.add('active');

            for (let i = 1; i <= 4; i++) {
                const phaseDiv = document.getElementById(schoolId + '_phase' + i);
                phaseDiv.style.display = (i === phase) ? 'grid' : 'none';
            }
        }

        function toggleDistrict(districtId) {
            const body = document.getElementById(districtId);
            const icon = document.getElementById(districtId + '_icon');

            if (body.style.display === 'none') {
                body.style.display = 'block';
                icon.classList.remove('collapsed');
            } else {
                body.style.display = 'none';
                icon.classList.add('collapsed');
            }
        }

        function toggleSchool(schoolId) {
            const container = document.getElementById(schoolId);
            const icon = document.getElementById(schoolId + '_icon');

            container.classList.toggle('active');
            icon.classList.toggle('collapsed');
        }

        function filterData() {
            currentFilters.district = document.getElementById('districtFilter').value;
            currentFilters.school = document.getElementById('schoolFilter').value;
            currentFilters.studentClass = document.getElementById('classFilter').value;

            document.getElementById('loadingMessage').style.display = 'block';

            document.querySelectorAll('.view-content').forEach(v => {
                v.classList.remove('active');
            });

            loadData();
        }

        let searchTimeout = null;

        function searchSchool() {
            if (searchTimeout) {
                clearTimeout(searchTimeout);
            }

            searchTimeout = setTimeout(() => {
                const searchInput = document.getElementById('schoolSearchInput').value.toLowerCase().trim();
                const schoolFilter = document.getElementById('schoolFilter');

                if (searchInput === '') {
                    const options = schoolFilter.querySelectorAll('option');
                    options.forEach(option => option.style.display = '');
                    schoolFilter.value = '';
                    return;
                }

                const options = schoolFilter.querySelectorAll('option');
                let matchCount = 0;
                let firstMatch = null;

                options.forEach((option, index) => {
                    if (index === 0) {
                        option.style.display = '';
                        return;
                    }

                    const optionText = option.textContent.toLowerCase();
                    const optionValue = option.value.toLowerCase();

                    if (optionText.includes(searchInput) || optionValue.includes(searchInput)) {
                        option.style.display = '';
                        matchCount++;
                        if (!firstMatch) {
                            firstMatch = option;
                        }
                    } else {
                        option.style.display = 'none';
                    }
                });

                if (firstMatch && matchCount === 1) {
                    schoolFilter.value = firstMatch.value;
                    filterData();
                } else if (matchCount === 0) {
                    schoolFilter.value = '';
                } else {
                    schoolFilter.value = '';
                }
            }, 300);
        }

        function resetFilters() {
            currentFilters.district = '';
            currentFilters.school = '';
            currentFilters.studentClass = '';
            document.getElementById('districtFilter').value = '';
            document.getElementById('schoolFilter').value = '';
            document.getElementById('classFilter').value = '';
            document.getElementById('schoolSearchInput').value = '';

            const schoolFilter = document.getElementById('schoolFilter');
            schoolFilter.querySelectorAll('option').forEach(option => option.style.display = '');

            loadData();
        }

        function showError(message) {
            const content = document.querySelector('.content');
            content.innerHTML = '<div class="error">❌ ' + message + '</div>';
            document.getElementById('loadingMessage').style.display = 'none';
        }

        function escapeHtml(text) {
            if (!text) return '-';
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
    </script>
</body>
</html>
