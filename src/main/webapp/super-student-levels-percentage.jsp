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

    // Populate the division dropdown (All Divisions + each distinct division)
    StudentDAO studentDAO = new StudentDAO();
    List<String> divisions = studentDAO.getDistinctDivisions();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Levels Percentage - All Divisions</title>
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

        /* Highlight the division selector so the "all divisions" scope is obvious */
        #divisionFilter {
            border-color: #667eea;
            font-weight: 600;
            color: #4a4a8a;
        }

        .stats-summary {
            padding: 20px 30px;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
        }

        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
            transition: transform 0.3s;
        }

        .stat-card:hover {
            transform: translateY(-5px);
        }

        .stat-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
            font-weight: 600;
            margin-bottom: 8px;
        }

        .stat-value {
            font-size: 28px;
            font-weight: 700;
            color: #333;
        }

        .stat-value.marathi {
            color: #2196f3;
        }

        .stat-value.math {
            color: #4caf50;
        }

        .stat-value.english {
            color: #ff9800;
        }

        .stat-value.overall {
            color: #9c27b0;
        }

        .chart-container {
            padding: 30px;
            background: white;
        }

        .chart-wrapper {
            position: relative;
            height: 600px;
            margin-bottom: 30px;
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

        .legend-container {
            display: flex;
            justify-content: center;
            gap: 30px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }

        .legend-item {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
            font-weight: 600;
        }

        .legend-color {
            width: 20px;
            height: 20px;
            border-radius: 4px;
        }

        .export-buttons {
            display: flex;
            gap: 10px;
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

        .chart-title {
            font-size: 24px;
            font-weight: 700;
            color: #333;
            margin-bottom: 20px;
            text-align: center;
        }

        .no-data {
            text-align: center;
            padding: 60px;
            color: #999;
            font-size: 18px;
        }

        @media (max-width: 768px) {
            .toolbar {
                flex-direction: column;
                align-items: stretch;
            }

            .filter-controls {
                flex-direction: column;
            }

            .chart-wrapper {
                height: 400px;
            }

            .stats-summary {
                grid-template-columns: repeat(2, 1fr);
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
                    📊 Student Levels Percentage Analysis
                </h1>
                <div class="header-subtitle" id="scopeSubtitle">
                    All Divisions | Marathi, Math &amp; English Achievement
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

        <div class="stats-summary" id="statsSummary">
            <!-- Stats will be populated dynamically -->
        </div>

        <div class="chart-container">
            <div class="legend-container">
                <div class="legend-item">
                    <div class="legend-color" style="background: #2196f3;"></div>
                    <span>Marathi (Max: 6)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color" style="background: #4caf50;"></div>
                    <span>Math (Max: 8)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color" style="background: #ff9800;"></div>
                    <span>English (Max: 6)</span>
                </div>
            </div>

            <div class="chart-wrapper">
                <canvas id="levelsChart"></canvas>
            </div>
        </div>
    </div>

    <script>
        let currentChart = null;
        let currentView = 'district';
        let currentDistrict = null;
        let currentData = null;
        // Selected division scope: 'ALL' aggregates across every division.
        let selectedDivision = 'ALL';

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
            document.getElementById('scopeSubtitle').innerHTML =
                label + ' | Marathi, Math &amp; English Achievement';

            loadData();
        }

        // Load data from servlet
        function loadData() {
            const phaseFilter = document.getElementById('phaseFilter').value;
            const view = currentView;
            const district = currentDistrict;

            let url = '<%= request.getContextPath() %>/super-student-levels-percentage?division=' +
                      encodeURIComponent(selectedDivision) +
                      '&view=' + view +
                      '&phase=' + phaseFilter;

            if (view === 'school' && district) {
                url += '&district=' + encodeURIComponent(district);
            }

            // Show loading
            document.querySelector('.chart-container').innerHTML = '<div class="loading">Loading data</div>';

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

            // Update stats
            updateStats(data);

            // Prepare chart data
            const districts = data.districts || [];

            if (districts.length === 0) {
                document.querySelector('.chart-container').innerHTML =
                    '<div class="no-data">No data available for the selected filters</div>';
                return;
            }

            const labels = districts.map(d => d.districtName);
            const marathiData = districts.map(d => d.marathiPercentage);
            const mathData = districts.map(d => d.mathPercentage);
            const englishData = districts.map(d => d.englishPercentage);

            // Recreate chart container
            document.querySelector('.chart-container').innerHTML = `
                <div class="legend-container">
                    <div class="legend-item">
                        <div class="legend-color" style="background: #2196f3;"></div>
                        <span>Marathi (Max: 6)</span>
                    </div>
                    <div class="legend-item">
                        <div class="legend-color" style="background: #4caf50;"></div>
                        <span>Math (Max: 8)</span>
                    </div>
                    <div class="legend-item">
                        <div class="legend-color" style="background: #ff9800;"></div>
                        <span>English (Max: 6)</span>
                    </div>
                </div>
                <div class="chart-title">District-wise Student Achievement Percentage</div>
                <div class="chart-wrapper">
                    <canvas id="levelsChart"></canvas>
                </div>
            `;

            // Create chart
            const ctx = document.getElementById('levelsChart').getContext('2d');

            if (currentChart) {
                currentChart.destroy();
            }

            currentChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [
                        {
                            label: 'Marathi %',
                            data: marathiData,
                            backgroundColor: 'rgba(33, 150, 243, 0.8)',
                            borderColor: 'rgba(33, 150, 243, 1)',
                            borderWidth: 2
                        },
                        {
                            label: 'Math %',
                            data: mathData,
                            backgroundColor: 'rgba(76, 175, 80, 0.8)',
                            borderColor: 'rgba(76, 175, 80, 1)',
                            borderWidth: 2
                        },
                        {
                            label: 'English %',
                            data: englishData,
                            backgroundColor: 'rgba(255, 152, 0, 0.8)',
                            borderColor: 'rgba(255, 152, 0, 1)',
                            borderWidth: 2
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    onClick: (event, elements) => {
                        if (elements.length > 0) {
                            const index = elements[0].index;
                            const district = districts[index];
                            showSchoolView(district.districtName);
                        }
                    },
                    plugins: {
                        title: {
                            display: false
                        },
                        legend: {
                            display: true,
                            position: 'top',
                            labels: {
                                font: {
                                    size: 14,
                                    weight: 'bold'
                                }
                            }
                        },
                        tooltip: {
                            callbacks: {
                                afterLabel: function(context) {
                                    const index = context.dataIndex;
                                    const district = districts[index];
                                    return [
                                        'Total Students: ' + district.totalStudents,
                                        'Avg Marathi Level: ' + district.avgMarathiLevel,
                                        'Avg Math Level: ' + district.avgMathLevel,
                                        'Avg English Level: ' + district.avgEnglishLevel,
                                        '',
                                        'Click to view schools →'
                                    ];
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100,
                            title: {
                                display: true,
                                text: 'Achievement Percentage (%)',
                                font: {
                                    size: 14,
                                    weight: 'bold'
                                }
                            },
                            ticks: {
                                callback: function(value) {
                                    return value + '%';
                                }
                            }
                        },
                        x: {
                            title: {
                                display: true,
                                text: 'Districts',
                                font: {
                                    size: 14,
                                    weight: 'bold'
                                }
                            }
                        }
                    }
                }
            });
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

            // Update stats
            updateStats(data);

            // Prepare chart data
            const schools = data.schools || [];

            if (schools.length === 0) {
                document.querySelector('.chart-container').innerHTML =
                    '<div class="no-data">No schools found in this district</div>';
                return;
            }

            const labels = schools.map(s => s.schoolName || s.udiseNo);
            const marathiData = schools.map(s => s.marathiPercentage);
            const mathData = schools.map(s => s.mathPercentage);
            const englishData = schools.map(s => s.englishPercentage);

            // Recreate chart container
            document.querySelector('.chart-container').innerHTML = `
                <div class="legend-container">
                    <div class="legend-item">
                        <div class="legend-color" style="background: #2196f3;"></div>
                        <span>Marathi (Max: 6)</span>
                    </div>
                    <div class="legend-item">
                        <div class="legend-color" style="background: #4caf50;"></div>
                        <span>Math (Max: 8)</span>
                    </div>
                    <div class="legend-item">
                        <div class="legend-color" style="background: #ff9800;"></div>
                        <span>English (Max: 6)</span>
                    </div>
                </div>
                <div class="chart-title">School-wise Student Achievement Percentage - \${data.districtName}</div>
                <div class="chart-wrapper">
                    <canvas id="levelsChart"></canvas>
                </div>
            `;

            // Create chart
            const ctx = document.getElementById('levelsChart').getContext('2d');

            if (currentChart) {
                currentChart.destroy();
            }

            currentChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [
                        {
                            label: 'Marathi %',
                            data: marathiData,
                            backgroundColor: 'rgba(33, 150, 243, 0.8)',
                            borderColor: 'rgba(33, 150, 243, 1)',
                            borderWidth: 2
                        },
                        {
                            label: 'Math %',
                            data: mathData,
                            backgroundColor: 'rgba(76, 175, 80, 0.8)',
                            borderColor: 'rgba(76, 175, 80, 1)',
                            borderWidth: 2
                        },
                        {
                            label: 'English %',
                            data: englishData,
                            backgroundColor: 'rgba(255, 152, 0, 0.8)',
                            borderColor: 'rgba(255, 152, 0, 1)',
                            borderWidth: 2
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        title: {
                            display: false
                        },
                        legend: {
                            display: true,
                            position: 'top',
                            labels: {
                                font: {
                                    size: 14,
                                    weight: 'bold'
                                }
                            }
                        },
                        tooltip: {
                            callbacks: {
                                afterLabel: function(context) {
                                    const index = context.dataIndex;
                                    const school = schools[index];
                                    return [
                                        'UDISE: ' + school.udiseNo,
                                        'Total Students: ' + school.totalStudents,
                                        'Avg Marathi Level: ' + school.avgMarathiLevel,
                                        'Avg Math Level: ' + school.avgMathLevel,
                                        'Avg English Level: ' + school.avgEnglishLevel
                                    ];
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100,
                            title: {
                                display: true,
                                text: 'Achievement Percentage (%)',
                                font: {
                                    size: 14,
                                    weight: 'bold'
                                }
                            },
                            ticks: {
                                callback: function(value) {
                                    return value + '%';
                                }
                            }
                        },
                        x: {
                            title: {
                                display: true,
                                text: 'Schools',
                                font: {
                                    size: 14,
                                    weight: 'bold'
                                }
                            },
                            ticks: {
                                maxRotation: 45,
                                minRotation: 45
                            }
                        }
                    }
                }
            });
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

        // Update stats summary
        function updateStats(data) {
            let html = '';

            if (currentView === 'district') {
                html = `
                    <div class="stat-card">
                        <div class="stat-label">Total Students</div>
                        <div class="stat-value">\${data.totalStudents || 0}</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-label">Districts</div>
                        <div class="stat-value">\${data.districtCount || 0}</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-label">Avg Marathi %</div>
                        <div class="stat-value marathi">\${data.avgMarathiPercentage || 0}%</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-label">Avg Math %</div>
                        <div class="stat-value math">\${data.avgMathPercentage || 0}%</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-label">Avg English %</div>
                        <div class="stat-value english">\${data.avgEnglishPercentage || 0}%</div>
                    </div>
                `;
            } else {
                const overallAvg = ((data.avgMarathiPercentage || 0) + (data.avgMathPercentage || 0) + (data.avgEnglishPercentage || 0)) / 3;
                html = `
                    <div class="stat-card">
                        <div class="stat-label">Total Students</div>
                        <div class="stat-value">\${data.totalStudents || 0}</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-label">Schools</div>
                        <div class="stat-value">\${data.schoolCount || 0}</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-label">Avg Marathi %</div>
                        <div class="stat-value marathi">\${data.avgMarathiPercentage || 0}%</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-label">Avg Math %</div>
                        <div class="stat-value math">\${data.avgMathPercentage || 0}%</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-label">Avg English %</div>
                        <div class="stat-value english">\${data.avgEnglishPercentage || 0}%</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-label">Overall Avg %</div>
                        <div class="stat-value overall">\${Math.round(overallAvg * 100) / 100}%</div>
                    </div>
                `;
            }

            document.getElementById('statsSummary').innerHTML = html;
        }

        // Show error message
        function showError(message) {
            document.querySelector('.chart-container').innerHTML =
                '<div class="error">Error: ' + message + '</div>';
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
                csv = 'District,Total Students,Marathi %,Math %,English %,Overall %,Avg Marathi Level,Avg Math Level,Avg English Level\n';
                currentData.districts.forEach(d => {
                    csv += `"\${d.districtName}",\${d.totalStudents},\${d.marathiPercentage},\${d.mathPercentage},\${d.englishPercentage},\${d.overallPercentage},\${d.avgMarathiLevel},\${d.avgMathLevel},\${d.avgEnglishLevel}\n`;
                });
                filename = 'district_levels_percentage_' + scopeTag + '_' + new Date().toISOString().split('T')[0] + '.csv';
            } else {
                csv = 'School Name,UDISE,Total Students,Marathi %,Math %,English %,Overall %,Avg Marathi Level,Avg Math Level,Avg English Level\n';
                currentData.schools.forEach(s => {
                    csv += `"\${s.schoolName}","\${s.udiseNo}",\${s.totalStudents},\${s.marathiPercentage},\${s.mathPercentage},\${s.englishPercentage},\${s.overallPercentage},\${s.avgMarathiLevel},\${s.avgMathLevel},\${s.avgEnglishLevel}\n`;
                });
                filename = 'school_levels_percentage_' + currentData.districtName + '_' + new Date().toISOString().split('T')[0] + '.csv';
            }

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
