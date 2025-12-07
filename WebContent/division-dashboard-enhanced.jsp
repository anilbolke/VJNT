<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.UserDAO" %>
<%@ page import="java.util.*" %>
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
    <title>Division Analytics Dashboard - <%= divisionName %></title>
    
    <!-- Chart.js Library -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f7fa;
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
        }
        
        .header h1 {
            font-size: 24px;
        }
        
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
            display: inline-block;
            transition: all 0.3s;
        }
        
        .btn-logout {
            background: rgba(255,255,255,0.2);
            color: white;
            margin-left: 10px;
        }
        
        .btn-logout:hover {
            background: rgba(255,255,255,0.3);
        }
        
        .container {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 30px;
        }
        
        .date-filter {
            background: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
        }
        
        .date-filter h3 {
            margin-bottom: 15px;
            color: #333;
        }
        
        .filter-controls {
            display: flex;
            gap: 15px;
            align-items: end;
            flex-wrap: wrap;
        }
        
        .form-group {
            flex: 1;
            min-width: 200px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 5px;
            color: #666;
            font-size: 14px;
        }
        
        .form-group input {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 10px 25px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            transition: transform 0.2s;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
        }
        
        .btn-secondary {
            background: #6c757d;
            color: white;
            padding: 10px 25px;
        }
        
        .chart-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .chart-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
        }
        
        .chart-card h3 {
            margin-bottom: 20px;
            color: #333;
            font-size: 18px;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        
        .chart-container {
            position: relative;
            height: 300px;
        }
        
        .phase-chart-container {
            position: relative;
            height: 500px;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        
        .stat-box {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        
        .stat-value {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .loading {
            text-align: center;
            padding: 50px;
            color: #666;
        }
        
        .error {
            background: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .success {
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .chart-toggle-buttons {
            display: flex;
            gap: 8px;
        }
        
        .toggle-btn {
            padding: 8px 16px;
            border: 2px solid #667eea;
            background: white;
            color: #667eea;
            border-radius: 5px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .toggle-btn:hover {
            background: #f0f2ff;
        }
        
        .toggle-btn.active {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-color: #667eea;
        }
        
        @media (max-width: 768px) {
            .chart-grid {
                grid-template-columns: 1fr;
            }
            
            .filter-controls {
                flex-direction: column;
            }
            
            .form-group {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div>
                <h1>🏛️ Division Analytics Dashboard</h1>
                <p>Division: <%= divisionName %></p>
            </div>
            <div>
                <a href="<%= request.getContextPath() %>/division-dashboard.jsp" class="btn btn-logout">Basic View</a>
                <a href="<%= request.getContextPath() %>/logout" class="btn btn-logout">Logout</a>
            </div>
        </div>
    </div>
    
    <div class="container">
        
        <!-- Date Filter Section -->
        <div class="date-filter">
            <h3>📅 Filter Data by Date Range</h3>
            <div class="filter-controls">
                <div class="form-group">
                    <label for="startDate">Start Date</label>
                    <input type="date" id="startDate" name="startDate">
                </div>
                <div class="form-group">
                    <label for="endDate">End Date</label>
                    <input type="date" id="endDate" name="endDate">
                </div>
                <button class="btn btn-primary" onclick="applyFilters()">Apply Filter</button>
                <button class="btn btn-secondary" onclick="clearFilters()">Clear</button>
            </div>
        </div>
        
        <div id="messageArea"></div>
        
        <!-- Charts Section -->
        <div class="chart-grid">
            
            <!-- Palak Melava with Charts -->
            <div class="chart-card">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                    <h3 style="margin: 0;">👨‍👩‍👧‍👦 Palak Melava (Parent Meetings)</h3>
                    <div class="chart-toggle-buttons">
                        <button class="toggle-btn active" onclick="togglePalakChart('bar')" id="palakBarBtn">
                            📊 Bar Chart
                        </button>
                        <button class="toggle-btn" onclick="togglePalakChart('pie')" id="palakPieBtn">
                            🥧 Pie Chart
                        </button>
                    </div>
                </div>
                <div class="stats-grid" style="margin-bottom: 15px;">
                    <div class="stat-box">
                        <div class="stat-value" id="totalMeetings">-</div>
                        <div class="stat-label">Total Meetings</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value" id="totalParents">-</div>
                        <div class="stat-label">Parents Attended</div>
                    </div>
                </div>
                <div class="chart-container">
                    <canvas id="palakMelavaChart"></canvas>
                </div>
            </div>
            
            <!-- Student Activities with Charts -->
            <div class="chart-card">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                    <h3 style="margin: 0;">📚 Student Activities</h3>
                    <div class="chart-toggle-buttons">
                        <button class="toggle-btn active" onclick="toggleActivitiesChart('bar')" id="activitiesBarBtn">
                            📊 Bar Chart
                        </button>
                        <button class="toggle-btn" onclick="toggleActivitiesChart('pie')" id="activitiesPieBtn">
                            🥧 Pie Chart
                        </button>
                    </div>
                </div>
                <div class="stats-grid" style="margin-bottom: 15px;">
                    <div class="stat-box">
                        <div class="stat-value" id="totalActivities">-</div>
                        <div class="stat-label">Total Activities</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value" id="activeStudents">-</div>
                        <div class="stat-label">Active Students</div>
                    </div>
                </div>
                <div class="chart-container">
                    <canvas id="activitiesChart"></canvas>
                </div>
            </div>
            
            <!-- Phase 1 with Charts -->
            <div class="chart-card">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                    <h3 style="margin: 0;">📝 चरण 1 (Phase 1) - district Completion Status</h3>
                    <div class="chart-toggle-buttons">
                        <button class="toggle-btn active" onclick="togglePhaseChart(1, 'bar')" id="phase1BarBtn">
                            📊 Bar Chart
                        </button>
                        <button class="toggle-btn" onclick="togglePhaseChart(1, 'pie')" id="phase1PieBtn">
                            🥧 Pie Chart
                        </button>
                    </div>
                </div>
                <div class="stats-grid" style="margin-bottom: 15px;">
                    <div class="stat-box">
                        <div class="stat-value" id="phase1TotalDistricts">-</div>
                        <div class="stat-label">Total Districts</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value" id="phase1Completed">-</div>
                        <div class="stat-label">100% Complete</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value" id="phase1AvgCompletion">-</div>
                        <div class="stat-label">Avg Completion</div>
                    </div>
                </div>
                <div class="chart-container">
                    <canvas id="phase1Chart"></canvas>
                </div>
            </div>
            
            <!-- Phase 2 with Charts -->
            <div class="chart-card">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                    <h3 style="margin: 0;">📝 चरण 2 (Phase 2) - district Completion Status</h3>
                    <div class="chart-toggle-buttons">
                        <button class="toggle-btn active" onclick="togglePhaseChart(2, 'bar')" id="phase2BarBtn">
                            📊 Bar Chart
                        </button>
                        <button class="toggle-btn" onclick="togglePhaseChart(2, 'pie')" id="phase2PieBtn">
                            🥧 Pie Chart
                        </button>
                    </div>
                </div>
                <div class="stats-grid" style="margin-bottom: 15px;">
                    <div class="stat-box">
                        <div class="stat-value" id="phase2TotalDistricts">-</div>
                        <div class="stat-label">Total Districts</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value" id="phase2Completed">-</div>
                        <div class="stat-label">100% Complete</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value" id="phase2AvgCompletion">-</div>
                        <div class="stat-label">Avg Completion</div>
                    </div>
                </div>
                <div class="chart-container">
                    <canvas id="phase2Chart"></canvas>
                </div>
            </div>
            
            <!-- Phase 3 with Charts -->
            <div class="chart-card">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                    <h3 style="margin: 0;">📝 चरण 3 (Phase 3) - district Completion Status</h3>
                    <div class="chart-toggle-buttons">
                        <button class="toggle-btn active" onclick="togglePhaseChart(3, 'bar')" id="phase3BarBtn">
                            📊 Bar Chart
                        </button>
                        <button class="toggle-btn" onclick="togglePhaseChart(3, 'pie')" id="phase3PieBtn">
                            🥧 Pie Chart
                        </button>
                    </div>
                </div>
                <div class="stats-grid" style="margin-bottom: 15px;">
                    <div class="stat-box">
                        <div class="stat-value" id="phase3TotalDistricts">-</div>
                        <div class="stat-label">Total Districts</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value" id="phase3Completed">-</div>
                        <div class="stat-label">100% Complete</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value" id="phase3AvgCompletion">-</div>
                        <div class="stat-label">Avg Completion</div>
                    </div>
                </div>
                <div class="chart-container">
                    <canvas id="phase3Chart"></canvas>
                </div>
            </div>
            
            <!-- Phase 4 with Charts -->
            <div class="chart-card">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                    <h3 style="margin: 0;">📝 चरण 4 (Phase 4) - district Completion Status</h3>
                    <div class="chart-toggle-buttons">
                        <button class="toggle-btn active" onclick="togglePhaseChart(4, 'bar')" id="phase4BarBtn">
                            📊 Bar Chart
                        </button>
                        <button class="toggle-btn" onclick="togglePhaseChart(4, 'pie')" id="phase4PieBtn">
                            🥧 Pie Chart
                        </button>
                    </div>
                </div>
                <div class="stats-grid" style="margin-bottom: 15px;">
                    <div class="stat-box">
                        <div class="stat-value" id="phase4TotalDistricts">-</div>
                        <div class="stat-label">Total Districts</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value" id="phase4Completed">-</div>
                        <div class="stat-label">100% Complete</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value" id="phase4AvgCompletion">-</div>
                        <div class="stat-label">Avg Completion</div>
                    </div>
                </div>
                <div class="chart-container">
                    <canvas id="phase4Chart"></canvas>
                </div>
            </div>
            
        </div>
        
    </div>
    
    <script>
        let charts = {};
        let palakMelavaData = null;
        let palakChartType = 'bar';
        let activitiesData = null;
        let activitiesChartType = 'bar';
        let phaseData = {1: null, 2: null, 3: null, 4: null};
        let phaseChartTypes = {1: 'bar', 2: 'bar', 3: 'bar', 4: 'bar'};
        const contextPath = '<%= request.getContextPath() %>';
        
        // Initialize charts on page load
        window.addEventListener('DOMContentLoaded', function() {
            // Set default dates (last 30 days)
            const endDate = new Date();
            const startDate = new Date();
            startDate.setDate(startDate.getDate() - 30);
            
            document.getElementById('endDate').valueAsDate = endDate;
            document.getElementById('startDate').valueAsDate = startDate;
            
            // Load all data
            loadAllData();
        });
        
        function showMessage(message, type) {
            const messageArea = document.getElementById('messageArea');
            messageArea.innerHTML = `<div class="${type}">${message}</div>`;
            setTimeout(() => {
                messageArea.innerHTML = '';
            }, 5000);
        }
        
        function applyFilters() {
            const startDate = document.getElementById('startDate').value;
            const endDate = document.getElementById('endDate').value;
            
            if (!startDate || !endDate) {
                showMessage('Please select both start and end dates', 'error');
                return;
            }
            
            if (new Date(startDate) > new Date(endDate)) {
                showMessage('Start date must be before end date', 'error');
                return;
            }
            
            loadAllData();
            showMessage('Filters applied successfully', 'success');
        }
        
        function clearFilters() {
            document.getElementById('startDate').value = '';
            document.getElementById('endDate').value = '';
            loadAllData();
            showMessage('Filters cleared', 'success');
        }
        
        function loadAllData() {
            loadPalakMelavaData();
            loadStudentActivitiesData();
            loadPhaseData(1);
            loadPhaseData(2);
            loadPhaseData(3);
            loadPhaseData(4);
        }
        
        function getDateParams() {
            const startDate = document.getElementById('startDate').value;
            const endDate = document.getElementById('endDate').value;
            return startDate && endDate ? `&startDate=${startDate}&endDate=${endDate}` : '';
        }
        
        // Toggle Palak Melava Chart
        function togglePalakChart(chartType) {
            palakChartType = chartType;
            
            // Update button states
            document.getElementById('palakBarBtn').classList.toggle('active', chartType === 'bar');
            document.getElementById('palakPieBtn').classList.toggle('active', chartType === 'pie');
            
            // Re-render chart with stored data
            if (palakMelavaData) {
                renderPalakChart(palakMelavaData, chartType);
            }
        }
        
        // Load Palak Melava Data
        function loadPalakMelavaData() {
            fetch(contextPath + '/division-analytics?type=palak_melava' + getDateParams())
                .then(response => response.json())
                .then(data => {
                    if (data.error) {
                        console.error('Error:', data.error);
                        return;
                    }
                    
                    // Store data
                    palakMelavaData = data;
                    
                    // Update statistics
                    document.getElementById('totalMeetings').textContent = data.totalMeetings || 0;
                    document.getElementById('totalParents').textContent = data.totalParentsAttended || 0;
                    
                    // Render chart
                    renderPalakChart(data, palakChartType);
                })
                .catch(error => console.error('Error loading Palak Melava data:', error));
        }
        
        // Render Palak Melava Chart (Bar or Pie) - Using Total Numbers Only
        function renderPalakChart(data, chartType) {
            // Use total numbers, not individual Districts
            const totalMeetings = data.totalMeetings || 0;
            const totalParents = data.totalParentsAttended || 0;
            
            // Destroy existing chart
            if (charts.palakMelava) {
                charts.palakMelava.destroy();
            }
            
            const ctx = document.getElementById('palakMelavaChart').getContext('2d');
            
            if (chartType === 'pie') {
                // PIE CHART - Show Total Meetings vs Total Parents
                charts.palakMelava = new Chart(ctx, {
                    type: 'pie',
                    data: {
                        labels: ['Total Meetings', 'Parents Attended'],
                        datasets: [{
                            data: [totalMeetings, totalParents],
                            backgroundColor: [
                                'rgba(102, 126, 234, 0.8)',
                                'rgba(76, 175, 80, 0.8)'
                            ],
                            borderColor: [
                                'rgba(102, 126, 234, 1)',
                                'rgba(76, 175, 80, 1)'
                            ],
                            borderWidth: 2
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                position: 'bottom',
                                labels: {
                                    font: { size: 14 },
                                    padding: 20
                                }
                            },
                            tooltip: {
                                callbacks: {
                                    label: function(context) {
                                        const label = context.label || '';
                                        const value = context.parsed || 0;
                                        return label + ': ' + value.toLocaleString();
                                    }
                                }
                            }
                        }
                    }
                });
            } else {
                // BAR CHART - Show Total Meetings and Total Parents as bars
                charts.palakMelava = new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: ['Total Meetings', 'Parents Attended'],
                        datasets: [{
                            label: 'Count',
                            data: [totalMeetings, totalParents],
                            backgroundColor: [
                                'rgba(102, 126, 234, 0.7)',
                                'rgba(76, 175, 80, 0.7)'
                            ],
                            borderColor: [
                                'rgba(102, 126, 234, 1)',
                                'rgba(76, 175, 80, 1)'
                            ],
                            borderWidth: 2
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            y: {
                                beginAtZero: true,
                                ticks: {
                                    callback: function(value) {
                                        return value.toLocaleString();
                                    }
                                }
                            }
                        },
                        plugins: {
                            legend: {
                                display: false
                            },
                            tooltip: {
                                callbacks: {
                                    label: function(context) {
                                        return context.label + ': ' + context.parsed.y.toLocaleString();
                                    }
                                }
                            }
                        }
                    }
                });
            }
        }
        
        // Toggle Student Activities Chart
        function toggleActivitiesChart(chartType) {
            activitiesChartType = chartType;
            
            // Update button states
            document.getElementById('activitiesBarBtn').classList.toggle('active', chartType === 'bar');
            document.getElementById('activitiesPieBtn').classList.toggle('active', chartType === 'pie');
            
            // Re-render chart with stored data
            if (activitiesData) {
                renderActivitiesChart(activitiesData, chartType);
            }
        }
        
        // Load Student Activities Data
        function loadStudentActivitiesData() {
            fetch(contextPath + '/division-analytics?type=student_activities' + getDateParams())
                .then(response => response.json())
                .then(data => {
                    if (data.error) {
                        console.error('Error:', data.error);
                        return;
                    }
                    
                    // Store data
                    activitiesData = data;
                    
                    // Update statistics
                    document.getElementById('totalActivities').textContent = data.totalActivities || 0;
                    document.getElementById('activeStudents').textContent = data.totalStudentsWithActivities || 0;
                    
                    // Render chart
                    renderActivitiesChart(data, activitiesChartType);
                })
                .catch(error => console.error('Error loading activities data:', error));
        }
        
        // Render Student Activities Chart (Bar or Pie) - Using Total Numbers Only
        function renderActivitiesChart(data, chartType) {
            // Use total numbers only
            const totalActivities = data.totalActivities || 0;
            const activeStudents = data.totalStudentsWithActivities || 0;
            
            // Destroy existing chart
            if (charts.activities) {
                charts.activities.destroy();
            }
            
            const ctx = document.getElementById('activitiesChart').getContext('2d');
            
            if (chartType === 'pie') {
                // PIE CHART - Show Total Activities vs Active Students
                charts.activities = new Chart(ctx, {
                    type: 'pie',
                    data: {
                        labels: ['Total Activities', 'Active Students'],
                        datasets: [{
                            data: [totalActivities, activeStudents],
                            backgroundColor: [
                                'rgba(255, 99, 132, 0.8)',
                                'rgba(54, 162, 235, 0.8)'
                            ],
                            borderColor: [
                                'rgba(255, 99, 132, 1)',
                                'rgba(54, 162, 235, 1)'
                            ],
                            borderWidth: 2
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                position: 'bottom',
                                labels: {
                                    font: { size: 14 },
                                    padding: 20
                                }
                            },
                            tooltip: {
                                callbacks: {
                                    label: function(context) {
                                        const label = context.label || '';
                                        const value = context.parsed || 0;
                                        return label + ': ' + value.toLocaleString();
                                    }
                                }
                            }
                        }
                    }
                });
            } else {
                // BAR CHART - Show Total Activities and Active Students as bars
                charts.activities = new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: ['Total Activities', 'Active Students'],
                        datasets: [{
                            label: 'Count',
                            data: [totalActivities, activeStudents],
                            backgroundColor: [
                                'rgba(255, 99, 132, 0.7)',
                                'rgba(54, 162, 235, 0.7)'
                            ],
                            borderColor: [
                                'rgba(255, 99, 132, 1)',
                                'rgba(54, 162, 235, 1)'
                            ],
                            borderWidth: 2
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            y: {
                                beginAtZero: true,
                                ticks: {
                                    callback: function(value) {
                                        return value.toLocaleString();
                                    }
                                }
                            }
                        },
                        plugins: {
                            legend: {
                                display: false
                            },
                            tooltip: {
                                callbacks: {
                                    label: function(context) {
                                        return context.label + ': ' + context.parsed.y.toLocaleString();
                                    }
                                }
                            }
                        }
                    }
                });
            }
        }

        
        // Toggle Phase Chart
        function togglePhaseChart(phaseNumber, chartType) {
            phaseChartTypes[phaseNumber] = chartType;
            
            // Update button states
            document.getElementById('phase' + phaseNumber + 'BarBtn').classList.toggle('active', chartType === 'bar');
            document.getElementById('phase' + phaseNumber + 'PieBtn').classList.toggle('active', chartType === 'pie');
            
            // Re-render chart with stored data
            if (phaseData[phaseNumber]) {
                renderPhaseChart(phaseNumber, phaseData[phaseNumber], chartType);
            }
        }
        
        // Load Phase Completion Data
        function loadPhaseData(phaseNumber) {
            fetch(contextPath + '/division-analytics?type=phase_completion&phase=' + phaseNumber + getDateParams())
                .then(response => response.json())
                .then(data => {
                    if (data.error) {
                        console.error('Error:', data.error);
                        return;
                    }
                    
                    // Store data
                    phaseData[phaseNumber] = data;
                    
                    // Calculate statistics
                    const districts = data.districts || [];
                    const totalDistricts = districts.length;
                    const completedDistricts = districts.filter(s => s.completionPercentage === 100).length;
                    const avgCompletion = districts.length > 0 
                        ? (districts.reduce((sum, s) => sum + s.completionPercentage, 0) / districts.length).toFixed(1) 
                        : 0;
                    
                    // Update statistics
                    document.getElementById('phase' + phaseNumber + 'TotalDistricts').textContent = totalDistricts;
                    document.getElementById('phase' + phaseNumber + 'Completed').textContent = completedDistricts;
                    document.getElementById('phase' + phaseNumber + 'AvgCompletion').textContent = avgCompletion + '%';
                    
                    // Render chart
                    renderPhaseChart(phaseNumber, data, phaseChartTypes[phaseNumber]);
                })
                .catch(error => console.error('Error loading phase ' + phaseNumber + ' data:', error));
        }
        
        // Render Phase Chart (Bar or Pie) - Using Summary Numbers Only
        function renderPhaseChart(phaseNumber, data, chartType) {
            const districts = data.districts || [];
            const totalDistricts = districts.length;
            const completedDistricts = districts.filter(s => s.completionPercentage === 100).length;
            const incompleteDistricts = totalDistricts - completedDistricts;
            
            const chartId = 'phase' + phaseNumber + 'Chart';
            
            // Destroy existing chart
            if (charts[chartId]) {
                charts[chartId].destroy();
            }
            
            const ctx = document.getElementById(chartId).getContext('2d');
            
            if (chartType === 'pie') {
                // PIE CHART - Show Completed vs Incomplete
                charts[chartId] = new Chart(ctx, {
                    type: 'pie',
                    data: {
                        labels: ['100% Complete', 'Incomplete'],
                        datasets: [{
                            data: [completedDistricts, incompleteDistricts],
                            backgroundColor: [
                                'rgba(76, 175, 80, 0.8)',
                                'rgba(255, 193, 7, 0.8)'
                            ],
                            borderColor: [
                                'rgba(76, 175, 80, 1)',
                                'rgba(255, 193, 7, 1)'
                            ],
                            borderWidth: 2
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                position: 'bottom',
                                labels: {
                                    font: { size: 14 },
                                    padding: 20
                                }
                            },
                            tooltip: {
                                callbacks: {
                                    label: function(context) {
                                        const label = context.label || '';
                                        const value = context.parsed || 0;
                                        const percentage = ((value / totalDistricts) * 100).toFixed(1);
                                        return label + ': ' + value + ' Districts (' + percentage + '%)';
                                    }
                                }
                            }
                        }
                    }
                });
            } else {
                // BAR CHART - Show Total, Completed, and Incomplete
                charts[chartId] = new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: ['Total Districts', '100% Complete', 'Incomplete'],
                        datasets: [{
                            label: 'Count',
                            data: [totalDistricts, completedDistricts, incompleteDistricts],
                            backgroundColor: [
                                'rgba(102, 126, 234, 0.7)',
                                'rgba(76, 175, 80, 0.7)',
                                'rgba(255, 193, 7, 0.7)'
                            ],
                            borderColor: [
                                'rgba(102, 126, 234, 1)',
                                'rgba(76, 175, 80, 1)',
                                'rgba(255, 193, 7, 1)'
                            ],
                            borderWidth: 2
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            y: {
                                beginAtZero: true,
                                ticks: {
                                    callback: function(value) {
                                        return value.toLocaleString();
                                    }
                                }
                            }
                        },
                        plugins: {
                            legend: {
                                display: false
                            },
                            tooltip: {
                                callbacks: {
                                    label: function(context) {
                                        return context.label + ': ' + context.parsed.y + ' Districts';
                                    }
                                }
                            }
                        }
                    }
                });
            }
        }

    </script>
</body>
</html>
