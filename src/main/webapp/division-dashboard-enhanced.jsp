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
        
        .header-left {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 10px;
            width: 100%;
            text-align: center;
        }
        
        .header-logo {
            display: flex;
            justify-content: center;
            width: 100%;
        }
        
        .header-logo img {
            max-width: 150px;
            width: 150px;
            height: auto;
            display: block;
        }
        
        .header h1 {
            font-size: 24px;
        }
        
        .gatee-tooltip {
            position: relative;
            display: inline-block;
            cursor: help;
            margin-left: 8px;
            color: #ffd700;
            font-size: 16px;
        }
        
        .gatee-tooltip:hover .tooltip-content {
            visibility: visible;
            opacity: 1;
        }
        
        .tooltip-content {
            visibility: hidden;
            opacity: 0;
            position: absolute;
            z-index: 1000;
            background: #2d3748;
            color: white;
            padding: 12px 15px;
            border-radius: 8px;
            font-size: 12px;
            white-space: nowrap;
            bottom: 125%;
            left: 50%;
            transform: translateX(-50%);
            transition: opacity 0.3s;
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }
        
        .tooltip-content::after {
            content: "";
            position: absolute;
            top: 100%;
            left: 50%;
            margin-left: -5px;
            border-width: 5px;
            border-style: solid;
            border-color: #2d3748 transparent transparent transparent;
        }
        
        .tooltip-content div {
            margin: 3px 0;
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
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
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
            <div class="header-left">
                <!-- Logo Section - START -->
                 <div class="header-logo">
                    <img src="<%= request.getContextPath() %>/Document/GATEE LOGO.png?v=2" alt="GATEE Logo">
                </div> 
                <!-- Logo Section - END -->
                <!-- Division Icon and Name Section - START -->
                <div class="school-icon">🏛️</div>
                <h1><%= divisionName %> Division</h1>
                <!-- Division Icon and Name Section - END -->
                <p>Division Analytics Dashboard</p>
            </div>
            <div>
                <button onclick="togglePhaseCompletion()" class="btn btn-logout" style="background: #9C27B0; margin-right: 10px;" title="Show/Hide Phase Completion Status">
                    📊 Phase Completion
                </button>
               <%--  <a href="<%= request.getContextPath() %>/authorize-youtube" class="btn btn-logout" style="background: #FF0000; margin-right: 10px;" target="_blank" title="Authorize YouTube for video uploads">
                    🎥 YouTube Setup
                </a> --%>
                <a href="<%= request.getContextPath() %>/division-student-level-details.jsp" class="btn btn-logout" style="background: #4CAF50;" title="View Student Level Details">
                    📚 Student Levels
                </a>
                <a href="<%= request.getContextPath() %>/division-dashboard.jsp" class="btn btn-logout">Basic View</a>
                <a href="<%= request.getContextPath() %>/division-activity-analysis.jsp" class="btn btn-logout" style="background: #FF9800;">📈 Activity Analysis</a>
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
            
            <!-- Palak Melava with Charts - Enhanced User-Friendly Design -->
            <div class="chart-card" style="background: linear-gradient(to bottom, #ffffff 0%, #f8f9ff 100%); border: 2px solid #e3e8ff;">
                <!-- Header with Title and Chart Toggle -->
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding-bottom: 15px; border-bottom: 3px solid #667eea;">
                    <div>
                        <h3 style="margin: 0; font-size: 20px; color: #667eea; display: flex; align-items: center; gap: 10px;">
                            👨‍👩‍👧‍👦 Palak Melava (Parent Meetings)
                            <span style="font-size: 12px; background: #667eea; color: white; padding: 4px 10px; border-radius: 12px; font-weight: normal;">District Overview</span>
                        </h3>
                        <p style="margin: 5px 0 0 0; font-size: 13px; color: #666; font-style: italic;">
                            📍 Click on any district to view detailed school-wise meeting information
                        </p>
                    </div>
                    <div class="chart-toggle-buttons">
                        <button class="toggle-btn active" onclick="togglePalakChart('bar')" id="palakBarBtn" style="box-shadow: 0 2px 5px rgba(0,0,0,0.1);">
                            📊 Bar Chart
                        </button>
                        <button class="toggle-btn" onclick="togglePalakChart('pie')" id="palakPieBtn" style="box-shadow: 0 2px 5px rgba(0,0,0,0.1);">
                            🥧 Pie Chart
                        </button>
                    </div>
                </div>
                
                <!-- Enhanced Statistics Grid with More Details -->
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin-bottom: 20px;">
                    <div class="stat-box" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); position: relative; overflow: hidden;">
                        <div style="position: absolute; top: -10px; right: -10px; font-size: 60px; opacity: 0.2;">📅</div>
                        <div class="stat-value" id="totalMeetings" style="position: relative; z-index: 1;">-</div>
                        <div class="stat-label" style="position: relative; z-index: 1;">Total Meetings Held</div>
                    </div>
                    <div class="stat-box" style="background: linear-gradient(135deg, #4caf50 0%, #45a049 100%); position: relative; overflow: hidden;">
                        <div style="position: absolute; top: -10px; right: -10px; font-size: 60px; opacity: 0.2;">👥</div>
                        <div class="stat-value" id="totalParents" style="position: relative; z-index: 1;">-</div>
                        <div class="stat-label" style="position: relative; z-index: 1;">Parents Participated</div>
                    </div>
                    <div class="stat-box" style="background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%); position: relative; overflow: hidden;">
                        <div style="position: absolute; top: -10px; right: -10px; font-size: 60px; opacity: 0.2;">🏫</div>
                        <div class="stat-value" id="totalPalakSchools">-</div>
                        <div class="stat-label">Schools Involved</div>
                    </div>
                    <div class="stat-box" style="background: linear-gradient(135deg, #2196f3 0%, #1976d2 100%); position: relative; overflow: hidden;">
                        <div style="position: absolute; top: -10px; right: -10px; font-size: 60px; opacity: 0.2;">📊</div>
                        <div class="stat-value" id="avgParentsPerMeeting">-</div>
                        <div class="stat-label">Avg Parents/Meeting</div>
                    </div>
                </div>
                
                <!-- Info Banner -->
                <div style="background: #e3f2fd; border-left: 4px solid #2196f3; padding: 12px 15px; margin-bottom: 15px; border-radius: 4px; display: flex; align-items: center; gap: 10px;">
                    <span style="font-size: 20px;">💡</span>
                    <span style="font-size: 13px; color: #1565c0; font-weight: 500;">
                        <strong>Tip:</strong> Click on any bar or pie slice to view detailed school-wise meeting data for that district
                    </span>
                </div>
                
                <!-- Chart Container with Enhanced Styling -->
                <div style="background: white; padding: 15px; border-radius: 8px; box-shadow: inset 0 2px 4px rgba(0,0,0,0.06);">
                    <div class="chart-container">
                        <canvas id="palakMelavaChart"></canvas>
                    </div>
                </div>
                
                <!-- Quick Actions -->
                <div style="margin-top: 15px; padding-top: 15px; border-top: 2px solid #e0e0e0; display: flex; justify-content: space-between; align-items: center;">
                    <div style="font-size: 12px; color: #666;">
                        <span style="font-weight: 600;">Last Updated:</span> <span id="palakLastUpdate">Just now</span>
                    </div>
                    <button onclick="loadPalakMelavaData()" style="background: #667eea; color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 600; display: flex; align-items: center; gap: 6px; transition: all 0.3s;" onmouseover="this.style.background='#5568d3'" onmouseout="this.style.background='#667eea'">
                        🔄 Refresh Data
                    </button>
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
            
            <!-- Phase Completion Section - Hidden by default, toggle with button -->
            <div id="phaseCompletionSection" style="display: none;">
            
            <!-- Phase 1 with Charts -->
            <div class="chart-card">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                    <h3 style="margin: 0;">📝 चरण 1 (Phase 1) - District Completion Status</h3>
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
                        <div class="stat-label">Approved Schools</div>
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
                    <h3 style="margin: 0;">📝 चरण 2 (Phase 2) - District Completion Status</h3>
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
                        <div class="stat-label">Approved Schools</div>
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
                    <h3 style="margin: 0;">📝 चरण 3 (Phase 3) - District Completion Status</h3>
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
                        <div class="stat-label">Approved Schools</div>
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
                    <h3 style="margin: 0;">📝 चरण 4 (Phase 4) - District Completion Status</h3>
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
                        <div class="stat-label">Approved Schools</div>
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
            <!-- End Phase Completion Section -->

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
            
            // Format dates as YYYY-MM-DD
            const formatDate = (date) => {
                const year = date.getFullYear();
                const month = String(date.getMonth() + 1).padStart(2, '0');
                const day = String(date.getDate()).padStart(2, '0');
                return year + '-' + month + '-' + day;
            };
            
            const formattedStartDate = formatDate(startDate);
            const formattedEndDate = formatDate(endDate);
            
            document.getElementById('startDate').value = formattedStartDate;
            document.getElementById('endDate').value = formattedEndDate;
            
            // Store initial dates in sessionStorage
            sessionStorage.setItem('filterStartDate', formattedStartDate);
            sessionStorage.setItem('filterEndDate', formattedEndDate);
            
            console.log('🗓️ Initial dates set - Start:', formattedStartDate, 'End:', formattedEndDate);
            console.log('📦 Initial dates stored in sessionStorage');
            
            // Load all data
            loadAllData();
        });
        
        function showMessage(message, type) {
            const messageArea = document.getElementById('messageArea');
            messageArea.innerHTML = '<div class="' + type + '">' + message + '</div>';
            setTimeout(() => {
                messageArea.innerHTML = '';
            }, 5000);
        }
        
        function applyFilters() {
            const startDateInput = document.getElementById('startDate');
            const endDateInput = document.getElementById('endDate');
            
            console.log('🔍 Date Input Elements:', {
                startDateInput: startDateInput,
                endDateInput: endDateInput,
                startDateValue: startDateInput ? startDateInput.value : 'NULL',
                endDateValue: endDateInput ? endDateInput.value : 'NULL'
            });
            
            if (!startDateInput || !endDateInput) {
                showMessage('Error: Date input fields not found', 'error');
                return;
            }
            
            const startDate = (startDateInput.value || '').trim();
            const endDate = (endDateInput.value || '').trim();

            console.log('🔍 Applying filters - Start:', startDate, 'End:', endDate);
            console.log('🔍 Start length:', startDate.length, 'End length:', endDate.length);

            if (!startDate || !endDate) {
                showMessage('कृपया start आणि end दोन्ही तारखा निवडा', 'error');
                return;
            }

            if (new Date(startDate) > new Date(endDate)) {
                showMessage('Start date हा end date च्या आधीचा असावा', 'error');
                return;
            }

            console.log('✅ Date validation passed, reloading data with filters...');
            console.log('📅 Filter URL will include: startDate=' + startDate + '&endDate=' + endDate);
            
            // Store dates in sessionStorage so they persist
            sessionStorage.setItem('filterStartDate', startDate);
            sessionStorage.setItem('filterEndDate', endDate);
            
            console.log('📦 Stored in sessionStorage:', {
                start: sessionStorage.getItem('filterStartDate'),
                end: sessionStorage.getItem('filterEndDate')
            });
            
            loadAllData();
            showMessage('Filters applied: ' + startDate + ' to ' + endDate, 'success');
        }
        
        function clearFilters() {
            document.getElementById('startDate').value = '';
            document.getElementById('endDate').value = '';
            // Clear sessionStorage
            sessionStorage.removeItem('filterStartDate');
            sessionStorage.removeItem('filterEndDate');
            loadAllData();
            showMessage('Filters cleared', 'success');
        }
        
        function loadAllData() {
            loadPalakMelavaData();
            loadStudentActivitiesData();
            // Phase data will only be loaded when user clicks the Phase Completion button
        }
        
        function getDateParams() {
            // Try to get dates from sessionStorage first, then fall back to input elements
            let startDate = sessionStorage.getItem('filterStartDate') || '';
            let endDate = sessionStorage.getItem('filterEndDate') || '';
            
            console.log('📅 getDateParams - from sessionStorage:', {start: startDate, end: endDate});
            
            // If not in sessionStorage, try to get from input elements
            if (!startDate || !endDate) {
                const startDateElement = document.getElementById('startDate');
                const endDateElement = document.getElementById('endDate');
                
                startDate = startDateElement ? (startDateElement.value || '').trim() : '';
                endDate = endDateElement ? (endDateElement.value || '').trim() : '';
                
                console.log('📅 getDateParams - from input elements:', {start: startDate, end: endDate});
            }
            
            console.log('📅 getDateParams final values:');
            console.log('   Start Date value:', startDate, '(length:', startDate ? startDate.length : 0, ')');
            console.log('   End Date value:', endDate, '(length:', endDate ? endDate.length : 0, ')');
            
            const params = (startDate && endDate && startDate.length > 0 && endDate.length > 0) ? '&startDate=' + encodeURIComponent(startDate) + '&endDate=' + encodeURIComponent(endDate) : '';
            console.log('   Generated params:', params || '(NO PARAMS - Empty dates)');
            return params;
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
            const url = contextPath + '/division-analytics?type=palak_melava' + getDateParams();
            console.log('🔄 Loading Palak Melava data from:', url);
            fetch(url)
                .then(response => response.json())
                .then(data => {
                    console.log('📊 Palak Melava data received:', data);
                    if (data.error) {
                        console.error('Error:', data.error);
                        return;
                    }
                    
                    // Store data
                    palakMelavaData = data;
                    
                    // Calculate enhanced statistics
                    const districts = data.districts || [];
                    const totalMeetings = data.totalMeetings || 0;
                    const totalParents = data.totalParentsAttended || 0;
                    
                    // Calculate total schools involved
                    const totalSchools = districts.reduce((sum, d) => sum + (d.schoolsWithMeetings || 0), 0);
                    
                    // Calculate average parents per meeting
                    const avgParents = totalMeetings > 0 ? Math.round(totalParents / totalMeetings) : 0;
                    
                    // Update all statistics with animations
                    document.getElementById('totalMeetings').textContent = totalMeetings.toLocaleString();
                    document.getElementById('totalParents').textContent = totalParents.toLocaleString();
                    document.getElementById('totalPalakSchools').textContent = totalSchools.toLocaleString();
                    document.getElementById('avgParentsPerMeeting').textContent = avgParents.toLocaleString();
                    
                    // Update last update timestamp
                    const now = new Date();
                    const timeStr = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
                    document.getElementById('palakLastUpdate').textContent = timeStr;
                    
                    // Render chart
                    renderPalakChart(data, palakChartType);
                })
                .catch(error => {
                    console.error('Error loading Palak Melava data:', error);
                    // Show error state in UI
                    document.getElementById('totalMeetings').textContent = 'Error';
                    document.getElementById('totalParents').textContent = 'Error';
                    document.getElementById('totalPalakSchools').textContent = 'Error';
                    document.getElementById('avgParentsPerMeeting').textContent = 'Error';
                });
        }
        
        // Render Palak Melava Chart (Bar or Pie) - District-wise with Click Handler
        function renderPalakChart(data, chartType) {
            const districts = data.districts || [];
            
            // Destroy existing chart
            if (charts.palakMelava) {
                charts.palakMelava.destroy();
            }
            
            const ctx = document.getElementById('palakMelavaChart').getContext('2d');
            
            if (chartType === 'pie') {
                // PIE CHART - Show district-wise meetings
                const districtNames = districts.map(d => d.districtName);
                const meetingCounts = districts.map(d => d.meetingCount);
                
                charts.palakMelava = new Chart(ctx, {
                    type: 'pie',
                    data: {
                        labels: districtNames,
                        datasets: [{
                            data: meetingCounts,
                            backgroundColor: [
                                'rgba(102, 126, 234, 0.85)',
                                'rgba(76, 175, 80, 0.85)',
                                'rgba(255, 193, 7, 0.85)',
                                'rgba(156, 39, 176, 0.85)',
                                'rgba(255, 87, 34, 0.85)',
                                'rgba(33, 150, 243, 0.85)',
                                'rgba(233, 30, 99, 0.85)',
                                'rgba(0, 150, 136, 0.85)',
                                'rgba(255, 152, 0, 0.85)',
                                'rgba(63, 81, 181, 0.85)'
                            ],
                            borderColor: '#ffffff',
                            borderWidth: 3,
                            hoverBorderWidth: 5,
                            hoverBorderColor: '#ffffff',
                            hoverOffset: 15
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        onClick: function(event, elements) {
                            if (elements.length > 0) {
                                const index = elements[0].index;
                                const districtName = districtNames[index];
                                openPalakMelavaModal(districtName, districts[index]);
                            }
                        },
                        plugins: {
                            legend: {
                                position: 'bottom',
                                labels: {
                                    font: { 
                                        size: 13,
                                        weight: '600'
                                    },
                                    padding: 15,
                                    usePointStyle: true,
                                    pointStyle: 'circle',
                                    color: '#333',
                                    generateLabels: function(chart) {
                                        const data = chart.data;
                                        if (data.labels.length && data.datasets.length) {
                                            return data.labels.map((label, i) => {
                                                const value = data.datasets[0].data[i];
                                                const total = data.datasets[0].data.reduce((a, b) => a + b, 0);
                                                const percentage = ((value / total) * 100).toFixed(1);
                                                return {
                                                    text: label + ' (' + percentage + '%)',
                                                    fillStyle: data.datasets[0].backgroundColor[i],
                                                    hidden: false,
                                                    index: i
                                                };
                                            });
                                        }
                                        return [];
                                    }
                                }
                            },
                            tooltip: {
                                backgroundColor: 'rgba(0, 0, 0, 0.85)',
                                titleFont: {
                                    size: 15,
                                    weight: 'bold'
                                },
                                bodyFont: {
                                    size: 13
                                },
                                padding: 15,
                                cornerRadius: 8,
                                displayColors: true,
                                callbacks: {
                                    title: function(context) {
                                        return '📍 ' + context[0].label + ' District';
                                    },
                                    label: function(context) {
                                        const district = districts[context.dataIndex];
                                        const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                        const percentage = ((district.meetingCount / total) * 100).toFixed(1);
                                        return [
                                            '📅 Meetings: ' + district.meetingCount + ' (' + percentage + '%)',
                                            '👥 Parents: ' + district.totalParents.toLocaleString()
                                        ];
                                    },
                                    afterBody: function(context) {
                                        const district = districts[context[0].dataIndex];
                                        const avgParents = district.meetingCount > 0 ? 
                                            Math.round(district.totalParents / district.meetingCount) : 0;
                                        
                                        return [
                                            '',
                                            '🏫 Schools: ' + (district.schoolsWithMeetings || 0),
                                            '📊 Avg Parents/Meeting: ' + avgParents,
                                            '',
                                            '💡 Click to view school details →'
                                        ];
                                    }
                                }
                            }
                        }
                    }
                });
            } else {
                // BAR CHART - Show district-wise meetings and parents (Clickable)
                const districtNames = districts.map(d => d.districtName);
                const meetingCounts = districts.map(d => d.meetingCount);
                const parentCounts = districts.map(d => d.totalParents);
                
                charts.palakMelava = new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: districtNames,
                        datasets: [
                            {
                                label: '📅 Meetings Held',
                                data: meetingCounts,
                                backgroundColor: 'rgba(102, 126, 234, 0.85)',
                                borderColor: 'rgba(102, 126, 234, 1)',
                                borderWidth: 2,
                                borderRadius: 8,
                                hoverBackgroundColor: 'rgba(102, 126, 234, 1)',
                                hoverBorderWidth: 3
                            },
                            {
                                label: '👥 Parents Attended',
                                data: parentCounts,
                                backgroundColor: 'rgba(76, 175, 80, 0.85)',
                                borderColor: 'rgba(76, 175, 80, 1)',
                                borderWidth: 2,
                                borderRadius: 8,
                                hoverBackgroundColor: 'rgba(76, 175, 80, 1)',
                                hoverBorderWidth: 3
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        onClick: function(event, elements) {
                            if (elements.length > 0) {
                                const index = elements[0].index;
                                const districtName = districtNames[index];
                                openPalakMelavaModal(districtName, districts[index]);
                            }
                        },
                        scales: {
                            x: {
                                ticks: {
                                    font: { 
                                        size: 12,
                                        weight: 'bold'
                                    },
                                    color: '#333'
                                },
                                grid: {
                                    display: false
                                }
                            },
                            y: {
                                beginAtZero: true,
                                ticks: {
                                    font: { 
                                        size: 12,
                                        weight: '600'
                                    },
                                    color: '#666',
                                    callback: function(value) {
                                        return value.toLocaleString();
                                    }
                                },
                                grid: {
                                    color: 'rgba(0, 0, 0, 0.05)',
                                    drawBorder: false
                                },
                                title: {
                                    display: true,
                                    text: 'Count',
                                    font: {
                                        size: 13,
                                        weight: 'bold'
                                    },
                                    color: '#555'
                                }
                            }
                        },
                        plugins: {
                            legend: {
                                position: 'top',
                                labels: {
                                    font: { 
                                        size: 14,
                                        weight: '600'
                                    },
                                    padding: 15,
                                    usePointStyle: true,
                                    pointStyle: 'circle',
                                    color: '#333'
                                }
                            },
                            tooltip: {
                                backgroundColor: 'rgba(0, 0, 0, 0.85)',
                                titleFont: {
                                    size: 15,
                                    weight: 'bold'
                                },
                                bodyFont: {
                                    size: 13
                                },
                                padding: 15,
                                cornerRadius: 8,
                                displayColors: true,
                                callbacks: {
                                    title: function(context) {
                                        return '📍 ' + context[0].label + ' District';
                                    },
                                    label: function(context) {
                                        const value = context.parsed.y.toLocaleString();
                                        return context.dataset.label + ': ' + value;
                                    },
                                    afterBody: function(context) {
                                        const index = context[0].dataIndex;
                                        const district = districts[index];
                                        const avgParents = district.meetingCount > 0 ? 
                                            Math.round(district.totalParents / district.meetingCount) : 0;
                                        
                                        return [
                                            '',
                                            '🏫 Schools: ' + (district.schoolsWithMeetings || 0),
                                            '📊 Avg Parents/Meeting: ' + avgParents,
                                            '',
                                            '💡 Click to view school details →'
                                        ];
                                    }
                                }
                            }
                        },
                        interaction: {
                            mode: 'index',
                            intersect: false
                        }
                    }
                });
            }
        }
        
        // Open Palak Melava Modal for District Schools
        function openPalakMelavaModal(districtName, districtData) {
            document.getElementById('modalPalakDistrictName').textContent = districtName;
            document.getElementById('modalPalakMeetings').textContent = districtData.meetingCount;
            document.getElementById('modalPalakParents').textContent = districtData.totalParents;
            document.getElementById('modalPalakSchoolsCount').textContent = districtData.schoolsWithMeetings;
            
            // Show loading
            document.getElementById('palakSchoolsTableBody').innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 40px;"><div class="spinner"></div>Loading schools...</td></tr>';
            
            // Show modal
            document.getElementById('palakMelavaModal').style.display = 'block';
            document.body.style.overflow = 'hidden';
            
            // Fetch school-wise data
            fetch(contextPath + '/division-district-palak-details?district=' + encodeURIComponent(districtName) + getDateParams())
                .then(response => response.json())
                .then(data => {
                    if (data.error) {
                        document.getElementById('palakSchoolsTableBody').innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 20px; color: red;">Error: ' + data.error + '</td></tr>';
                        return;
                    }
                    
                    const schools = data.schools || [];
                    if (schools.length === 0) {
                        document.getElementById('palakSchoolsTableBody').innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 20px;">No schools found</td></tr>';
                        return;
                    }
                    
                    // Populate table
                    let html = '';
                    schools.forEach((school, index) => {
                        const statusBadge = school.hasMeetings 
                            ? '<span style="background: #4caf50; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">✅ Active</span>'
                            : '<span style="background: #ff9800; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">⏳ No Meetings</span>';
                        
                        const lastMeeting = school.lastMeeting || '-';
                        const meetingCount = school.meetingCount || 0;
                        const totalParents = school.totalParents || 0;
                        
                        html += '<tr style="border-bottom: 1px solid #e0e0e0;">';
                        html += '<td style="padding: 12px;">' + (index + 1) + '</td>';
                        html += '<td style="padding: 12px; font-weight: 600;">' + school.schoolName + '</td>';
                        html += '<td style="padding: 12px; font-family: monospace; color: #666;">' + school.udiseNo + '</td>';
                        html += '<td style="padding: 12px; text-align: center;">' + meetingCount + '</td>';
                        html += '<td style="padding: 12px; text-align: center;">' + totalParents + '</td>';
                        html += '<td style="padding: 12px;">' + lastMeeting + '</td>';
                        html += '</tr>';
                    });
                    
                    document.getElementById('palakSchoolsTableBody').innerHTML = html;
                })
                .catch(error => {
                    console.error('Error loading schools:', error);
                    document.getElementById('palakSchoolsTableBody').innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 20px; color: red;">Failed to load schools</td></tr>';
                });
        }
        
        // Close Palak Melava Modal
        function closePalakMelavaModal() {
            document.getElementById('palakMelavaModal').style.display = 'none';
            document.body.style.overflow = 'auto';
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
            const url = contextPath + '/division-analytics?type=student_activities' + getDateParams();
            console.log('🔄 Loading Student Activities data from:', url);
            fetch(url)
                .then(response => response.json())
                .then(data => {
                    console.log('📊 Student Activities data received:', data);
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
        
        // Toggle Phase Completion Section
        function togglePhaseCompletion() {
            const section = document.getElementById('phaseCompletionSection');
            const isHidden = section.style.display === 'none';
            
            if (isHidden) {
                section.style.display = 'block';
                // Load phase data if not already loaded
                if (!phaseData[1]) {
                    loadPhaseData(1);
                    loadPhaseData(2);
                    loadPhaseData(3);
                    loadPhaseData(4);
                }
                // Scroll to section
                setTimeout(() => {
                    section.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }, 100);
            } else {
                section.style.display = 'none';
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
                    // Show SCHOOLS completed, not districts at 100%
                    const completedSchools = data.completedSchools || 0;
                    const avgCompletion = districts.length > 0 
                        ? (districts.reduce((sum, s) => sum + s.completionPercentage, 0) / districts.length).toFixed(1) 
                        : 0;
                    
                    // Update statistics
                    document.getElementById('phase' + phaseNumber + 'TotalDistricts').textContent = totalDistricts;
                    document.getElementById('phase' + phaseNumber + 'Completed').textContent = completedSchools;
                    document.getElementById('phase' + phaseNumber + 'AvgCompletion').textContent = avgCompletion + '%';
                    
                    // Render chart
                    renderPhaseChart(phaseNumber, data, phaseChartTypes[phaseNumber]);
                })
                .catch(error => console.error('Error loading phase ' + phaseNumber + ' data:', error));
        }
        
        // Render Phase Chart (Bar or Pie) - Using Summary Numbers Only
        function renderPhaseChart(phaseNumber, data, chartType) {
            const districts = data.districts || [];
            const totalSchools = data.totalSchools || 0;
            const completedSchools = data.completedSchools || 0;
            const incompleteSchools = totalSchools - completedSchools;
            
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
                        labels: ['Approved Schools', 'Pending Schools'],
                        datasets: [{
                            data: [completedSchools, incompleteSchools],
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
                                        const percentage = ((value / totalSchools) * 100).toFixed(1);
                                        return label + ': ' + value + ' Schools (' + percentage + '%)';
                                    }
                                }
                            }
                        }
                    }
                });
            } else {
                // BAR CHART - Show District-wise breakdown (Clickable)
                const districtNames = districts.map(d => d.districtName);
                const completedData = districts.map(d => d.completedSchools);
                const pendingData = districts.map(d => d.totalSchools - d.completedSchools);
                
                charts[chartId] = new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: districtNames,
                        datasets: [
                            {
                                label: 'Approved Schools',
                                data: completedData,
                                backgroundColor: 'rgba(76, 175, 80, 0.8)',
                                borderColor: 'rgba(76, 175, 80, 1)',
                                borderWidth: 2
                            },
                            {
                                label: 'Pending Schools',
                                data: pendingData,
                                backgroundColor: 'rgba(255, 193, 7, 0.8)',
                                borderColor: 'rgba(255, 193, 7, 1)',
                                borderWidth: 2
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        onClick: function(event, elements) {
                            if (elements.length > 0) {
                                const index = elements[0].index;
                                const districtName = districtNames[index];
                                openDistrictSchoolsModal(districtName, phaseNumber, districts[index]);
                            }
                        },
                        scales: {
                            x: {
                                stacked: true,
                                ticks: {
                                    font: { size: 11 }
                                }
                            },
                            y: {
                                stacked: true,
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
                                position: 'top',
                                labels: {
                                    font: { size: 14 },
                                    padding: 15
                                }
                            },
                            tooltip: {
                                callbacks: {
                                    label: function(context) {
                                        const district = districts[context.dataIndex];
                                        const label = context.dataset.label;
                                        const value = context.parsed.y;
                                        const percentage = district.completionPercentage;
                                        return label + ': ' + value + ' (' + percentage + '% complete)';
                                    },
                                    afterLabel: function(context) {
                                        return 'Click to view schools';
                                    }
                                }
                            }
                        }
                    }
                });
            }
        }
        
        // Open District Schools Modal
        function openDistrictSchoolsModal(districtName, phaseNumber, districtData) {
            document.getElementById('modalDistrictName').textContent = districtName;
            document.getElementById('modalPhaseNumber').textContent = phaseNumber;
            document.getElementById('modalDistrictTotalSchools').textContent = districtData.totalSchools;
            document.getElementById('modalDistrictCompletedSchools').textContent = districtData.completedSchools;
            document.getElementById('modalDistrictCompletionPercentage').textContent = districtData.completionPercentage + '%';
            
            // Show loading
            document.getElementById('districtSchoolsTableBody').innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 40px;"><div class="spinner"></div>Loading schools...</td></tr>';
            
            // Show modal
            document.getElementById('districtSchoolsModal').style.display = 'block';
            document.body.style.overflow = 'hidden';
            
            // Fetch school-wise data
            fetch(contextPath + '/division-district-phase-details?district=' + encodeURIComponent(districtName) + '&phase=' + phaseNumber + getDateParams())
                .then(response => response.json())
                .then(data => {
                    if (data.error) {
                        document.getElementById('districtSchoolsTableBody').innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 20px; color: red;">Error: ' + data.error + '</td></tr>';
                        return;
                    }
                    
                    const schools = data.schools || [];
                    if (schools.length === 0) {
                        document.getElementById('districtSchoolsTableBody').innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 20px;">No schools found</td></tr>';
                        return;
                    }
                    
                    // Populate table
                    let html = '';
                    schools.forEach((school, index) => {
                        const statusBadge = school.isApproved 
                            ? '<span style="background: #4caf50; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">✅ Approved</span>'
                            : '<span style="background: #ff9800; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">⏳ Pending</span>';
                        
                        const approvedDate = school.approvedDate || '-';
                        const approvedBy = school.approvedBy || '-';
                        
                        html += '<tr style="border-bottom: 1px solid #e0e0e0;">';
                        html += '<td style="padding: 12px;">' + (index + 1) + '</td>';
                        html += '<td style="padding: 12px; font-weight: 600;">' + school.schoolName + '</td>';
                        html += '<td style="padding: 12px; font-family: monospace; color: #666;">' + school.udiseNo + '</td>';
                        html += '<td style="padding: 12px; text-align: center;">' + statusBadge + '</td>';
                        html += '<td style="padding: 12px;">' + approvedDate + '</td>';
                        html += '<td style="padding: 12px;">' + approvedBy + '</td>';
                        html += '</tr>';
                    });
                    
                    document.getElementById('districtSchoolsTableBody').innerHTML = html;
                })
                .catch(error => {
                    console.error('Error loading schools:', error);
                    document.getElementById('districtSchoolsTableBody').innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 20px; color: red;">Failed to load schools</td></tr>';
                });
        }
        
        // Close District Schools Modal
        function closeDistrictSchoolsModal() {
            document.getElementById('districtSchoolsModal').style.display = 'none';
            document.body.style.overflow = 'auto';
        }

    </script>
    
    <!-- District Schools Modal -->
    <div id="districtSchoolsModal" style="display: none; position: fixed; z-index: 10000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.7);">
        <div style="position: relative; margin: 2% auto; max-width: 1400px; background: white; border-radius: 12px; box-shadow: 0 10px 50px rgba(0,0,0,0.3);">
            <!-- Modal Header -->
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 25px 30px; border-radius: 12px 12px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <h2 style="margin: 0; font-size: 24px; font-weight: 700;">🏫 <span id="modalDistrictName"></span> - Phase <span id="modalPhaseNumber"></span></h2>
                    <p style="margin: 8px 0 0 0; font-size: 14px; opacity: 0.95;">School-wise Phase Completion Status</p>
                </div>
                <button onclick="closeDistrictSchoolsModal()" 
                        style="background: rgba(255,255,255,0.2); border: none; color: white; font-size: 32px; cursor: pointer; width: 45px; height: 45px; border-radius: 50%; display: flex; align-items: center; justify-content: center; transition: all 0.3s; font-weight: 300;"
                        onmouseover="this.style.background='rgba(255,255,255,0.3)'"
                        onmouseout="this.style.background='rgba(255,255,255,0.2)'">
                    ×
                </button>
            </div>
            
            <!-- Statistics Bar -->
            <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; padding: 25px 30px; background: #f8f9fa; border-bottom: 2px solid #e0e0e0;">
                <div style="text-align: center; padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <div style="font-size: 32px; font-weight: 700; color: #667eea;" id="modalDistrictTotalSchools">-</div>
                    <div style="font-size: 14px; color: #666; margin-top: 5px;">Total Schools</div>
                </div>
                <div style="text-align: center; padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <div style="font-size: 32px; font-weight: 700; color: #4caf50;" id="modalDistrictCompletedSchools">-</div>
                    <div style="font-size: 14px; color: #666; margin-top: 5px;">Approved Schools</div>
                </div>
                <div style="text-align: center; padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <div style="font-size: 32px; font-weight: 700; color: #ff9800;" id="modalDistrictCompletionPercentage">-</div>
                    <div style="font-size: 14px; color: #666; margin-top: 5px;">Completion %</div>
                </div>
            </div>
            
            <!-- Schools Table -->
            <div style="padding: 30px; max-height: 600px; overflow-y: auto;">
                <table style="width: 100%; border-collapse: collapse; background: white; box-shadow: 0 2px 8px rgba(0,0,0,0.1); border-radius: 8px; overflow: hidden;">
                    <thead>
                        <tr style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
                            <th style="padding: 15px; text-align: left; font-weight: 600;">#</th>
                            <th style="padding: 15px; text-align: left; font-weight: 600;">School Name</th>
                            <th style="padding: 15px; text-align: left; font-weight: 600;">UDISE No</th>
                            <th style="padding: 15px; text-align: center; font-weight: 600;">Status</th>
                            <th style="padding: 15px; text-align: left; font-weight: 600;">Approved Date</th>
                            <th style="padding: 15px; text-align: left; font-weight: 600;">Approved By</th>
                        </tr>
                    </thead>
                    <tbody id="districtSchoolsTableBody">
                        <tr>
                            <td colspan="6" style="text-align: center; padding: 40px;">
                                <div class="spinner"></div>
                                Loading schools...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
            
            <!-- Modal Footer -->
            <div style="padding: 20px 30px; background: #f8f9fa; border-top: 1px solid #e0e0e0; border-radius: 0 0 12px 12px; text-align: right;">
                <button onclick="closeDistrictSchoolsModal()" 
                        style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; padding: 12px 30px; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; transition: all 0.3s;"
                        onmouseover="this.style.transform='scale(1.05)'"
                        onmouseout="this.style.transform='scale(1)'">
                    Close
                </button>
            </div>
        </div>
    </div>
    
    <style>
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
        
        #districtSchoolsModal tbody tr:hover {
            background-color: #f8f9fa;
        }
        
        #palakMelavaModal tbody tr:hover {
            background-color: #f8f9fa;
        }
    </style>
    
    <!-- Palak Melava Schools Modal -->
    <div id="palakMelavaModal" style="display: none; position: fixed; z-index: 10000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.7);">
        <div style="position: relative; margin: 2% auto; max-width: 1400px; background: white; border-radius: 12px; box-shadow: 0 10px 50px rgba(0,0,0,0.3);">
            <!-- Modal Header -->
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 25px 30px; border-radius: 12px 12px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <h2 style="margin: 0; font-size: 24px; font-weight: 700;">👨‍👩‍👧‍👦 <span id="modalPalakDistrictName"></span> - Palak Melava</h2>
                    <p style="margin: 8px 0 0 0; font-size: 14px; opacity: 0.95;">School-wise Parent Meeting Statistics</p>
                </div>
                <button onclick="closePalakMelavaModal()" 
                        style="background: rgba(255,255,255,0.2); border: none; color: white; font-size: 32px; cursor: pointer; width: 45px; height: 45px; border-radius: 50%; display: flex; align-items: center; justify-content: center; transition: all 0.3s; font-weight: 300;"
                        onmouseover="this.style.background='rgba(255,255,255,0.3)'"
                        onmouseout="this.style.background='rgba(255,255,255,0.2)'">
                    ×
                </button>
            </div>
            
            <!-- Statistics Bar -->
            <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; padding: 25px 30px; background: #f8f9fa; border-bottom: 2px solid #e0e0e0;">
                <div style="text-align: center; padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <div style="font-size: 32px; font-weight: 700; color: #667eea;" id="modalPalakMeetings">-</div>
                    <div style="font-size: 14px; color: #666; margin-top: 5px;">Total Meetings</div>
                </div>
                <div style="text-align: center; padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <div style="font-size: 32px; font-weight: 700; color: #4caf50;" id="modalPalakParents">-</div>
                    <div style="font-size: 14px; color: #666; margin-top: 5px;">Parents Attended</div>
                </div>
                <div style="text-align: center; padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <div style="font-size: 32px; font-weight: 700; color: #ff9800;" id="modalPalakSchoolsCount">-</div>
                    <div style="font-size: 14px; color: #666; margin-top: 5px;">Active Schools</div>
                </div>
            </div>
            
            <!-- Schools Table -->
            <div style="padding: 30px; max-height: 600px; overflow-y: auto;">
                <table style="width: 100%; border-collapse: collapse; background: white; box-shadow: 0 2px 8px rgba(0,0,0,0.1); border-radius: 8px; overflow: hidden;">
                    <thead>
                        <tr style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
                            <th style="padding: 15px; text-align: left; font-weight: 600;">#</th>
                            <th style="padding: 15px; text-align: left; font-weight: 600;">School Name</th>
                            <th style="padding: 15px; text-align: left; font-weight: 600;">UDISE No</th>
                            <th style="padding: 15px; text-align: center; font-weight: 600;">Meetings</th>
                            <th style="padding: 15px; text-align: center; font-weight: 600;">Parents</th>
                            <th style="padding: 15px; text-align: left; font-weight: 600;">Last Meeting</th>
                        </tr>
                    </thead>
                    <tbody id="palakSchoolsTableBody">
                        <tr>
                            <td colspan="6" style="text-align: center; padding: 40px;">
                                <div class="spinner"></div>
                                Loading schools...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
            
            <!-- Modal Footer -->
            <div style="padding: 20px 30px; background: #f8f9fa; border-top: 1px solid #e0e0e0; border-radius: 0 0 12px 12px; text-align: right;">
                <button onclick="closePalakMelavaModal()" 
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
