<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.HEAD_MASTER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String udiseNo = user.getUdiseNo();
    SchoolDAO schoolDAO = new SchoolDAO();
    School school = schoolDAO.getSchoolByUdise(udiseNo);
    String schoolName = school != null ? school.getSchoolName() : "Unknown School";
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Phase-wise Subject Statistics - विद्यार्थी टप्पा-निहाय आकडेवारी</title>
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
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        
        .header-subtitle {
            font-size: 16px;
            opacity: 0.95;
        }
        
        .toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px 30px;
            background: #f8f9fa;
            border-bottom: 2px solid #e9ecef;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .filter-controls {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            align-items: center;
        }
        
        .filter-controls label {
            font-weight: 600;
            color: #495057;
        }
        
        .filter-controls select,
        .filter-controls input {
            padding: 8px 12px;
            border: 1px solid #ced4da;
            border-radius: 5px;
            font-size: 14px;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            text-decoration: none;
            display: inline-block;
        }
        
        .btn-primary {
            background: #667eea;
            color: white;
        }
        
        .btn-primary:hover {
            background: #5568d3;
            transform: translateY(-2px);
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
        }
        
        .btn-export:hover {
            background: #218838;
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
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        
        .summary-card h3 {
            font-size: 32px;
            margin-bottom: 5px;
        }
        
        .summary-card p {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .phase-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            border-bottom: 2px solid #e9ecef;
            flex-wrap: wrap;
        }
        
        .phase-tab {
            padding: 12px 24px;
            background: #f8f9fa;
            border: none;
            border-radius: 8px 8px 0 0;
            cursor: pointer;
            font-weight: 600;
            color: #495057;
            transition: all 0.3s;
        }
        
        .phase-tab.active {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            transform: translateY(2px);
        }
        
        .phase-tab:hover {
            background: #e9ecef;
        }
        
        .phase-tab.active:hover {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        
        .phase-content {
            display: none;
        }
        
        .phase-content.active {
            display: block;
        }
        
        .aggregate-stats {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        
        .aggregate-stats h3 {
            margin-bottom: 15px;
            color: #495057;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 15px;
        }
        
        .subject-stats {
            background: white;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .subject-stats h4 {
            margin-bottom: 10px;
            color: #667eea;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .level-count {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #e9ecef;
        }
        
        .level-count:last-child {
            border-bottom: none;
        }
        
        .level-label {
            font-weight: 600;
            color: #495057;
        }
        
        .level-value {
            background: #667eea;
            color: white;
            padding: 3px 10px;
            border-radius: 12px;
            font-weight: 600;
            min-width: 30px;
            text-align: center;
        }
        
        .table-container {
            overflow-x: auto;
            margin-top: 20px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 1200px;
        }
        
        thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            position: sticky;
            top: 0;
            z-index: 10;
        }
        
        th {
            padding: 12px;
            text-align: left;
            font-weight: 600;
            font-size: 14px;
        }
        
        tbody tr {
            border-bottom: 1px solid #e9ecef;
            transition: all 0.3s;
        }
        
        tbody tr:hover {
            background: #f8f9fa;
        }
        
        td {
            padding: 12px;
            font-size: 14px;
        }
        
        .level-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-weight: 600;
            font-size: 13px;
            text-align: center;
            min-width: 35px;
            cursor: help;
        }
        
        .level-0 { background: #dc3545; color: white; }
        .level-1 { background: #fd7e14; color: white; }
        .level-2 { background: #ffc107; color: #000; }
        .level-3 { background: #28a745; color: white; }
        .level-4 { background: #007bff; color: white; }
        .level-5 { background: #6610f2; color: white; }
        .level-6 { background: #20c997; color: white; }
        .level-7 { background: #e83e8c; color: white; }
        .level-8 { background: #17a2b8; color: white; }
        .level-null { background: #6c757d; color: white; }
        
        .loading {
            text-align: center;
            padding: 40px;
            font-size: 18px;
            color: #667eea;
        }
        
        .error {
            background: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
        
        .legend {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            margin: 20px 0;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 8px;
        }
        
        .legend-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .legend-box {
            width: 24px;
            height: 24px;
            border-radius: 4px;
        }
        
        @media (max-width: 768px) {
            .toolbar {
                flex-direction: column;
                align-items: stretch;
            }
            
            .filter-controls {
                flex-direction: column;
                width: 100%;
            }
            
            .filter-controls select,
            .filter-controls input {
                width: 100%;
            }
            
            .summary-cards {
                grid-template-columns: 1fr;
            }
        }
        
        @media print {
            .toolbar,
            .phase-tabs {
                display: none;
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
            <h1>📊 Phase-wise Subject Statistics</h1>
            <h1>टप्पा-निहाय विषय आकडेवारी</h1>
            <div class="header-subtitle">
                <%= schoolName %> | UDISE: <%= udiseNo %>
            </div>
        </div>
        
        <div class="toolbar">
            <div class="filter-controls">
                <label style="font-weight: 600; color: #495057;">📊 Aggregate Statistics View</label>
                <span style="color: #666;">Showing count of students at each level for all subjects</span>
            </div>
            
            <div>
                <a href="school-dashboard-enhanced.jsp" class="btn btn-secondary">← Back to Dashboard</a>
            </div>
        </div>
        
        <div class="content">
            <div class="summary-cards" id="summaryCards">
                <div class="summary-card">
                    <h3 id="totalStudents">-</h3>
                    <p>Total Students</p>
                </div>
                <div class="summary-card">
                    <h3 id="phase1Complete">-</h3>
                    <p>Phase 1 Completed</p>
                </div>
                <div class="summary-card">
                    <h3 id="phase2Complete">-</h3>
                    <p>Phase 2 Completed</p>
                </div>
                <div class="summary-card">
                    <h3 id="phase3Complete">-</h3>
                    <p>Phase 3 Completed</p>
                </div>
                <div class="summary-card">
                    <h3 id="phase4Complete">-</h3>
                    <p>Phase 4 Completed</p>
                </div>
            </div>
            
            <!-- Legends showing actual level values -->
            
            
            <div class="phase-tabs">
                <button class="phase-tab active" onclick="showPhase(1)">Phase 1</button>
                <button class="phase-tab" onclick="showPhase(2)">Phase 2</button>
                <button class="phase-tab" onclick="showPhase(3)">Phase 3</button>
                <button class="phase-tab" onclick="showPhase(4)">Phase 4</button>
                <button class="phase-tab" onclick="showPhase('all')">All Phases</button>
            </div>
            
            <div id="phase1Content" class="phase-content active">
                <div class="aggregate-stats" id="phase1Aggregate"></div>
                <!-- Student data table hidden as per requirement -->
            </div>
            
            <div id="phase2Content" class="phase-content">
                <div class="aggregate-stats" id="phase2Aggregate"></div>
                <!-- Student data table hidden as per requirement -->
            </div>
            
            <div id="phase3Content" class="phase-content">
                <div class="aggregate-stats" id="phase3Aggregate"></div>
                <!-- Student data table hidden as per requirement -->
            </div>
            
            <div id="phase4Content" class="phase-content">
                <div class="aggregate-stats" id="phase4Aggregate"></div>
                <!-- Student data table hidden as per requirement -->
            </div>
            
            <div id="allPhasesContent" class="phase-content">
                <!-- All phases combined statistics -->
                <div class="aggregate-stats" id="allPhasesAggregate">
                    <h3 style="color: #667eea; margin-bottom: 20px;">📊 All Phases Combined Statistics</h3>
                    <p style="color: #666; margin-bottom: 20px;">Comprehensive view of student distribution across all levels for each subject in all 4 phases.</p>
                    
                    <div style="display: grid; gap: 30px;">
                        <!-- Marathi - All Phases -->
                        <div style="background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                            <h4 style="color: #667eea; margin-bottom: 15px; font-size: 18px;">📚 Marathi (मराठी) - All Phases</h4>
                            <div class="stats-grid" id="allPhasesMarathi"></div>
                        </div>
                        
                        <!-- Math - All Phases -->
                        <div style="background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                            <h4 style="color: #667eea; margin-bottom: 15px; font-size: 18px;">🔢 Math (गणित) - All Phases</h4>
                            <div class="stats-grid" id="allPhasesMath"></div>
                        </div>
                        
                        <!-- English - All Phases -->
                        <div style="background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                            <h4 style="color: #667eea; margin-bottom: 15px; font-size: 18px;">🔤 English - All Phases</h4>
                            <div class="stats-grid" id="allPhasesEnglish"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        let allStudentsData = [];
        let aggregateCounts = {};
        
        // Level description mappings - ACTUAL DROPDOWN VALUES
        function getMarathiLevelLabel(level) {
            if (level === null || level === undefined) return 'Not Set';
            switch(parseInt(level)) {
                case 0: return 'स्थर निश्चित केला नाही (Not Set)';
                case 1: return 'प्रारंभिक स्तर (Beginning Level)';
                case 2: return 'अक्षर स्तर (Letter Level)';
                case 3: return 'शब्द स्तर (Word Level)';
                case 4: return 'वाक्य स्तर (Sentence Level)';
                case 5: return 'समजपूर्वक उतारा वाचन स्तर (Comprehension)';
                case 6: return 'मराठी वाचन व लेखन FLN स्तर 100% पूर्ण (100% Complete)';
                default: return 'Level ' + level;
            }
        }
        
        function getMathLevelLabel(level) {
            if (level === null || level === undefined) return 'Not Set';
            switch(parseInt(level)) {
                case 0: return 'स्थर निश्चित केला नाही (Not Set)';
                case 1: return 'प्रारंभिक स्तर (Beginning Level)';
                case 2: return 'अंक ज्ञान स्तर (Digit Knowledge)';
                case 3: return 'संख्याज्ञान स्तर (Number Knowledge)';
                case 4: return 'बेरीज स्तर (Addition Level)';
                case 5: return 'वजाबाकी स्तर (Subtraction Level)';
                case 6: return 'गुणाकार स्तर (Multiplication Level)';
                case 7: return 'भागाकार स्तर (Division Level)';
                case 8: return 'गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण (100% Complete)';
                default: return 'Level ' + level;
            }
        }
        
        function getEnglishLevelLabel(level) {
            if (level === null || level === undefined) return 'Not Set';
            switch(parseInt(level)) {
                case 0: return 'स्थर निश्चित केला नाही (Not Set)';
                case 1: return 'Beginner level';
                case 2: return 'Alphabet level';
                case 3: return 'Word level';
                case 4: return 'Sentence level';
                case 5: return 'Paragraph Reading with Understanding';
                case 6: return 'English reading and writing FLN level 100% complete';
                default: return 'Level ' + level;
            }
        }
        
        function getLevelShortLabel(level) {
            if (level === null || level === undefined) return '-';
            return 'L' + level;
        }
        
        // Load data on page load
        document.addEventListener('DOMContentLoaded', function() {
            loadData();
        });
        
        // Load phase-wise statistics data
        function loadData() {
            fetch('phase-subject-statistics')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        allStudentsData = data.students;
                        aggregateCounts = data.aggregateCounts;
                        updateSummaryCards();
                        populateAllTables();
                    } else {
                        showError(data.message);
                    }
                })
                .catch(error => {
                    console.error('Error loading data:', error);
                    showError('Failed to load data: ' + error.message);
                });
        }
        
        // Update summary cards
        function updateSummaryCards() {
            const total = aggregateCounts.totalStudents || 0;
            document.getElementById('totalStudents').textContent = total;
            
            // Count completed phases
            let p1 = 0, p2 = 0, p3 = 0, p4 = 0;
            allStudentsData.forEach(student => {
                if (student.phase1Date) p1++;
                if (student.phase2Date) p2++;
                if (student.phase3Date) p3++;
                if (student.phase4Date) p4++;
            });
            
            document.getElementById('phase1Complete').textContent = p1;
            document.getElementById('phase2Complete').textContent = p2;
            document.getElementById('phase3Complete').textContent = p3;
            document.getElementById('phase4Complete').textContent = p4;
        }
        
        // Populate all aggregate statistics only (student tables removed)
        function populateAllTables() {
            populatePhaseTable(1);
            populatePhaseTable(2);
            populatePhaseTable(3);
            populatePhaseTable(4);
            populateAllPhasesStats();
        }
        
        // Populate individual phase aggregate statistics only
        function populatePhaseTable(phase) {
            const aggregateDiv = document.getElementById('phase' + phase + 'Aggregate');
            // Only populate aggregate stats
            aggregateDiv.innerHTML = getAggregateStatsHTML(phase);
        }
        
        // Get aggregate stats HTML
        function getAggregateStatsHTML(phase) {
            const marathiCounts = aggregateCounts['phase' + phase + '_marathi'] || {};
            const mathCounts = aggregateCounts['phase' + phase + '_math'] || {};
            const englishCounts = aggregateCounts['phase' + phase + '_english'] || {};
            
            return '<h3>📊 Aggregate Statistics - Phase ' + phase + '</h3>' +
                '<div class="stats-grid">' +
                    '<div class="subject-stats">' +
                        '<h4>🔤 Marathi (मराठी)</h4>' +
                        getLevelCountsHTML(marathiCounts, 'marathi') +
                    '</div>' +
                    '<div class="subject-stats">' +
                        '<h4>🔢 Math (गणित)</h4>' +
                        getLevelCountsHTML(mathCounts, 'math') +
                    '</div>' +
                    '<div class="subject-stats">' +
                        '<h4>🔤 English</h4>' +
                        getLevelCountsHTML(englishCounts, 'english') +
                    '</div>' +
                '</div>';
        }
        
        // Get level counts HTML with descriptive labels
        function getLevelCountsHTML(counts, subject) {
            let html = '';
            let maxLevel = 4; // default
            
            // Determine max level based on subject
            if (subject === 'math') {
                maxLevel = 8; // Math goes up to level 8
            } else if (subject === 'marathi' || subject === 'english') {
                maxLevel = 6; // Marathi and English go up to level 6
            }
            
            for (let i = 0; i <= maxLevel; i++) {
                const count = counts[i] || 0;
                let levelLabel = '';
                
                switch(subject) {
                    case 'marathi':
                        levelLabel = getMarathiLevelLabel(i);
                        break;
                    case 'math':
                        levelLabel = getMathLevelLabel(i);
                        break;
                    case 'english':
                        levelLabel = getEnglishLevelLabel(i);
                        break;
                    default:
                        levelLabel = 'Level ' + i;
                }
                
                html += '<div class="level-count">' +
                    '<span class="level-label">' + levelLabel + '</span>' +
                    '<span class="level-value">' + count + '</span>' +
                    '</div>';
            }
            return html;
        }
        
        // Populate All Phases combined statistics
        function populateAllPhasesStats() {
            // Marathi - All Phases
            const marathiDiv = document.getElementById('allPhasesMarathi');
            let marathiHTML = '';
            for (let phase = 1; phase <= 4; phase++) {
                const marathiCounts = aggregateCounts['phase' + phase + '_marathi'] || {};
                marathiHTML += '<div class="subject-stats">' +
                    '<h4 style="color: #764ba2; font-size: 16px;">Phase ' + phase + '</h4>' +
                    getLevelCountsHTML(marathiCounts, 'marathi') +
                    '</div>';
            }
            marathiDiv.innerHTML = marathiHTML;
            
            // Math - All Phases
            const mathDiv = document.getElementById('allPhasesMath');
            let mathHTML = '';
            for (let phase = 1; phase <= 4; phase++) {
                const mathCounts = aggregateCounts['phase' + phase + '_math'] || {};
                mathHTML += '<div class="subject-stats">' +
                    '<h4 style="color: #764ba2; font-size: 16px;">Phase ' + phase + '</h4>' +
                    getLevelCountsHTML(mathCounts, 'math') +
                    '</div>';
            }
            mathDiv.innerHTML = mathHTML;
            
            // English - All Phases
            const englishDiv = document.getElementById('allPhasesEnglish');
            let englishHTML = '';
            for (let phase = 1; phase <= 4; phase++) {
                const englishCounts = aggregateCounts['phase' + phase + '_english'] || {};
                englishHTML += '<div class="subject-stats">' +
                    '<h4 style="color: #764ba2; font-size: 16px;">Phase ' + phase + '</h4>' +
                    getLevelCountsHTML(englishCounts, 'english') +
                    '</div>';
            }
            englishDiv.innerHTML = englishHTML;
        }
        
        
        // Get level badge HTML with labels (kept for potential future use)
        function getLevelBadgeWithLabel(level, subject) {
            if (level === null || level === undefined) {
                return '<td><span class="level-badge level-null" title="Not Set">-</span></td>';
            }
            
            let label = '';
            switch(subject) {
                case 'marathi':
                    label = getMarathiLevelLabel(level);
                    break;
                case 'math':
                    label = getMathLevelLabel(level);
                    break;
                case 'english':
                    label = getEnglishLevelLabel(level);
                    break;
                default:
                    label = 'L' + level;
            }
            
            return '<td><span class="level-badge level-' + level + '" title="' + label + '">' + getLevelShortLabel(level) + '</span></td>';
        }
        
        // Show specific phase
        function showPhase(phase) {
            // Update tabs
            document.querySelectorAll('.phase-tab').forEach(tab => tab.classList.remove('active'));
            event.target.classList.add('active');
            
            // Update content
            document.querySelectorAll('.phase-content').forEach(content => content.classList.remove('active'));
            if (phase === 'all') {
                document.getElementById('allPhasesContent').classList.add('active');
            } else {
                document.getElementById('phase' + phase + 'Content').classList.add('active');
            }
        }
        
        // Export to Excel
        function exportToExcel() {
            alert('Export functionality will be implemented. Data will be exported to Excel format.');
            // TODO: Implement Excel export using a library like SheetJS
        }
        
        // Show error message
        function showError(message) {
            const content = document.querySelector('.content');
            content.innerHTML = '<div class="error">❌ ' + message + '</div>';
        }
        
        // Escape HTML
        function escapeHtml(text) {
            if (!text) return '-';
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
    </script>
</body>
</html>
