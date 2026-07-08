<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DIVISION) && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
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
    <title>Comprehensive Analytics Dashboard - <%= divisionName %></title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-datalabels@2.2.0/dist/chartjs-plugin-datalabels.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
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
        
        .header-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        
        .header-left h1 {
            font-size: 32px;
            margin-bottom: 10px;
        }
        
        .header-subtitle {
            font-size: 16px;
            opacity: 0.9;
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
        
        .filter-group select,
        .filter-group input[type="date"],
        .filter-group input[type="text"] {
            padding: 8px 12px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            min-width: 150px;
            background: white;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .filter-group select:focus,
        .filter-group input:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .action-buttons {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
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
            text-decoration: none;
        }
        
        .btn-primary {
            background: #667eea;
            color: white;
        }
        
        .btn-success {
            background: #4caf50;
            color: white;
        }
        
        .btn-info {
            background: #2196f3;
            color: white;
        }
        
        .btn-warning {
            background: #ff9800;
            color: white;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0,0,0,0.2);
        }
        
        .overview-stats {
            padding: 30px;
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
        
        .stat-value {
            font-size: 36px;
            font-weight: 700;
            color: #667eea;
            margin-bottom: 8px;
        }
        
        .stat-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
            font-weight: 600;
        }
        
        .section {
            margin: 30px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .section-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .section-header:hover {
            background: linear-gradient(135deg, #5568d3 0%, #6a3f8c 100%);
        }
        
        .section-header h2 {
            font-size: 24px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .toggle-icon {
            font-size: 24px;
            transition: transform 0.3s;
        }
        
        .toggle-icon.collapsed {
            transform: rotate(-90deg);
        }
        
        .section-content {
            padding: 30px;
            display: block;
        }
        
        .section-content.collapsed {
            display: none;
        }
        
        .chart-container {
            position: relative;
            height: 400px;
            margin-bottom: 30px;
        }
        
        .chart-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 30px;
            margin-bottom: 30px;
        }
        
        .chart-wrapper {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        .chart-title {
            font-size: 18px;
            font-weight: 700;
            color: #333;
            margin-bottom: 15px;
            text-align: center;
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
        
        .comparison-mode {
            background: #fff3e0;
            padding: 20px;
            margin: 20px 30px;
            border-radius: 8px;
            border-left: 4px solid #ff9800;
        }
        
        .district-selector {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-top: 15px;
        }
        
        .district-chip {
            padding: 8px 16px;
            background: white;
            border: 2px solid #667eea;
            border-radius: 20px;
            cursor: pointer;
            transition: all 0.3s;
            font-weight: 600;
            color: #667eea;
        }
        
        .district-chip.selected {
            background: #667eea;
            color: white;
        }
        
        .district-chip:hover {
            transform: scale(1.05);
            box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
        }
        
        .legend-container {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        
        .legend-title {
            font-weight: 700;
            margin-bottom: 10px;
            color: #333;
            font-size: 14px;
        }
        
        .legend-item {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            margin-right: 20px;
            margin-bottom: 5px;
            font-size: 13px;
        }
        
        .legend-color {
            width: 20px;
            height: 20px;
            border-radius: 4px;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .toolbar,
            .back-button,
            .action-buttons {
                display: none !important;
            }
            
            .section {
                page-break-inside: avoid;
                margin: 20px 0;
            }
            
            .section-content {
                display: block !important;
            }
            
            .toggle-icon {
                display: none;
            }
        }
        
        @media (max-width: 768px) {
            .chart-grid {
                grid-template-columns: 1fr;
            }
            
            .filter-controls {
                flex-direction: column;
                align-items: stretch;
            }
            
            .filter-group select,
            .filter-group input {
                min-width: 100%;
            }
        }
    </style>
</head>
<body>
<jsp:include page="academic-year-bar.jsp" />
    <div class="container">
        <div class="header">
            <div class="header-content">
                <div class="header-left">
                    <h1>📊 Comprehensive Analytics Dashboard</h1>
                    <div class="header-subtitle">
                        Division: <%= divisionName %> | Complete Performance Overview
                    </div>
                </div>
                <a href="<%= request.getContextPath() %>/division-dashboard.jsp" class="back-button">
                    ← Back to Dashboard
                </a>
            </div>
        </div>
        
        <!-- Action Buttons (Top Right) -->
        <div style="padding: 20px 30px; background: #f8f9fa; border-bottom: 2px solid #e0e0e0; display: flex; justify-content: flex-end; gap: 10px;">
            <button class="btn btn-success" onclick="exportToExcel()">
                📥 Export Excel
            </button>
            <button class="btn btn-info" onclick="exportToPDF()">
                📄 Export PDF
            </button>
            <button class="btn btn-warning" onclick="window.print()">
                🖨️ Print
            </button>
        </div>
        
        <!-- Overview Statistics -->
        <div class="overview-stats" id="overviewStats">
            <div class="stat-card">
                <div class="stat-value" id="totalStudents">-</div>
                <div class="stat-label">Total Students</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="totalDistricts">-</div>
                <div class="stat-label">Districts</div>
            </div>
            <div style="display: none;" class="stat-card">
                <div class="stat-value" id="totalSchools">-</div>
                <div class="stat-label">Schools</div>
            </div>
            <div style="display: none;" class="stat-card">
                <div class="stat-value" id="totalTeachers">-</div>
                <div class="stat-label">Teachers</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="avgMarathiLevel">-</div>
                <div class="stat-label">Avg Marathi %</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="avgMathLevel">-</div>
                <div class="stat-label">Avg Math %</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="avgEnglishLevel">-</div>
                <div class="stat-label">Avg English %</div>
            </div>
        </div>
        
         <!-- Section 4.5: Phase Completion Status - District-wise (Detailed View) -->
        <div class="section">
            <div class="section-header" onclick="toggleSection('phaseCompletionDistrictwise')">
                <h2>📊 Phase Completion Status - District-wise</h2>
                <span class="toggle-icon" id="phaseCompletionDistrictwiseIcon">▼</span>
            </div>
            <div class="section-content" id="phaseCompletionDistrictwiseContent">
                <p style="color: #666; margin-bottom: 25px; text-align: center;">Detailed district-wise completion status for each phase with comprehensive metrics</p>
                
                <!-- Phase 1 District-wise -->
                <div style="background: white; padding: 25px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 25px;">
                    <h3 style="margin: 0 0 15px 0; color: #667eea;">📝 चरण 1 (Phase 1) - District Completion Status</h3>
                    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 15px;">
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #667eea;" id="phase1DetailTotalDistricts">-</div>
                            <div style="font-size: 14px; color: #666;">Total Districts</div>
                        </div>
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #4caf50;" id="phase1DetailTotalStudents">-</div>
                            <div style="font-size: 14px; color: #666;">Total Students</div>
                        </div>
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #2196f3;" id="phase1DetailTotalSchools">-</div>
                            <div style="font-size: 14px; color: #666;">Total Schools</div>
                        </div>
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #ff9800;" id="phase1DetailAvgCompletion">-</div>
                            <div style="font-size: 14px; color: #666;">Avg Completion</div>
                        </div>
                    </div>
                    <div style="height: 400px; position: relative;">
                        <canvas id="phase1DetailChart"></canvas>
                    </div>
                </div>
                
                <!-- Phase 2 District-wise -->
                <div style="background: white; padding: 25px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 25px;">
                    <h3 style="margin: 0 0 15px 0; color: #667eea;">📝 चरण 2 (Phase 2) - District Completion Status</h3>
                    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 15px;">
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #667eea;" id="phase2DetailTotalDistricts">-</div>
                            <div style="font-size: 14px; color: #666;">Total Districts</div>
                        </div>
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #4caf50;" id="phase2DetailTotalStudents">-</div>
                            <div style="font-size: 14px; color: #666;">Total Students</div>
                        </div>
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #2196f3;" id="phase2DetailTotalSchools">-</div>
                            <div style="font-size: 14px; color: #666;">Total Schools</div>
                        </div>
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #ff9800;" id="phase2DetailAvgCompletion">-</div>
                            <div style="font-size: 14px; color: #666;">Avg Completion</div>
                        </div>
                    </div>
                    <div style="height: 400px; position: relative;">
                        <canvas id="phase2DetailChart"></canvas>
                    </div>
                </div>
                
                <!-- Phase 3 District-wise -->
                <div style="background: white; padding: 25px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 25px;">
                    <h3 style="margin: 0 0 15px 0; color: #667eea;">📝 चरण 3 (Phase 3) - District Completion Status</h3>
                    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 15px;">
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #667eea;" id="phase3DetailTotalDistricts">-</div>
                            <div style="font-size: 14px; color: #666;">Total Districts</div>
                        </div>
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #4caf50;" id="phase3DetailTotalStudents">-</div>
                            <div style="font-size: 14px; color: #666;">Total Students</div>
                        </div>
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #2196f3;" id="phase3DetailTotalSchools">-</div>
                            <div style="font-size: 14px; color: #666;">Total Schools</div>
                        </div>
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #ff9800;" id="phase3DetailAvgCompletion">-</div>
                            <div style="font-size: 14px; color: #666;">Avg Completion</div>
                        </div>
                    </div>
                    <div style="height: 400px; position: relative;">
                        <canvas id="phase3DetailChart"></canvas>
                    </div>
                </div>
                
                <!-- Phase 4 District-wise -->
                <div style="background: white; padding: 25px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 25px;">
                    <h3 style="margin: 0 0 15px 0; color: #667eea;">📝 चरण 4 (Phase 4) - District Completion Status</h3>
                    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 15px;">
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #667eea;" id="phase4DetailTotalDistricts">-</div>
                            <div style="font-size: 14px; color: #666;">Total Districts</div>
                        </div>
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #4caf50;" id="phase4DetailTotalStudents">-</div>
                            <div style="font-size: 14px; color: #666;">Total Students</div>
                        </div>
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #2196f3;" id="phase4DetailTotalSchools">-</div>
                            <div style="font-size: 14px; color: #666;">Total Schools</div>
                        </div>
                        <div style="text-align: center; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                            <div style="font-size: 28px; font-weight: 700; color: #ff9800;" id="phase4DetailAvgCompletion">-</div>
                            <div style="font-size: 14px; color: #666;">Avg Completion</div>
                        </div>
                    </div>
                    <div style="height: 400px; position: relative;">
                        <canvas id="phase4DetailChart"></canvas>
                    </div>
                </div>
            </div>
        </div>
        <!-- Section 1: Phase Completion Status -->
        <div style="display: none;" class="section">
            <div class="section-header" onclick="toggleSection('phaseCompletion')">
                <h2>📚 Phase Completion Status</h2>
                <span class="toggle-icon" id="phaseCompletionIcon">▼</span>
            </div>
            <div class="section-content" id="phaseCompletionContent">
                <div class="chart-grid">
                    <div class="chart-wrapper">
                        <div class="chart-title">Phase 1 Completion</div>
                        <div class="chart-container">
                            <canvas id="phase1Chart"></canvas>
                        </div>
                    </div>
                    <div class="chart-wrapper">
                        <div class="chart-title">Phase 2 Completion</div>
                        <div class="chart-container">
                            <canvas id="phase2Chart"></canvas>
                        </div>
                    </div>
                    <div class="chart-wrapper">
                        <div class="chart-title">Phase 3 Completion</div>
                        <div class="chart-container">
                            <canvas id="phase3Chart"></canvas>
                        </div>
                    </div>
                    <div class="chart-wrapper">
                        <div class="chart-title">Phase 4 Completion</div>
                        <div class="chart-container">
                            <canvas id="phase4Chart"></canvas>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Section 2: Student Levels Percentage Graph -->
        <div class="section">
            <div class="section-header" onclick="toggleSection('levelsPercentage')">
                <h2>📊 Student Levels Percentage (Average Achievement)</h2>
                <span class="toggle-icon collapsed" id="levelsPercentageIcon">▼</span>
            </div>
            <div class="section-content collapsed" id="levelsPercentageContent">
                <div class="legend-container">
                    <div class="legend-title">Subject Legend:</div>
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
                    <div class="chart-title">District-wise Average Achievement Percentage</div>
                    <div class="chart-container" style="height: 500px;">
                        <canvas id="levelsPercentageChart"></canvas>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Section 3: Student Level Distribution Graph -->
        <div class="section">
            <div class="section-header" onclick="toggleSection('levelDistribution')">
                <h2>📈 Student Level Distribution (Detailed Breakdown)</h2>
                <span class="toggle-icon collapsed" id="levelDistributionIcon">▼</span>
            </div>
            <div class="section-content collapsed" id="levelDistributionContent">
                <div id="levelDistributionCharts" class="chart-grid">
                    <!-- District cards will be loaded here dynamically -->
                </div>
            </div>
        </div>
        
        <!-- Section 4: Student Activities Analytics -->
        <div class="section">
            <div class="section-header" onclick="toggleSection('activities')">
                <h2>✏️ Student Activities Analytics</h2>
                <span class="toggle-icon collapsed" id="activitiesIcon">▼</span>
            </div>
            <div class="section-content collapsed" id="activitiesContent">
                <div class="chart-grid">
                    <div class="chart-wrapper">
                        <div class="chart-title">District-wise Activities</div>
                        <div class="chart-container">
                            <canvas id="activitiesBarChart"></canvas>
                        </div>
                    </div>
                    <div class="chart-wrapper">
                        <div class="chart-title">Subject-wise Distribution</div>
                        <div class="chart-container">
                            <canvas id="activitiesPieChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
       
        
        <!-- Section 5: Palak Melava (Parent Meetings) Analytics -->
        <div class="section">
            <div class="section-header" onclick="toggleSection('palakMelava')">
                <h2>👨‍👩‍👧‍👦 Palak Melava (Parent Meetings) Analytics</h2>
                <span class="toggle-icon collapsed" id="palakMelavaIcon">▼</span>
            </div>
            <div class="section-content collapsed" id="palakMelavaContent">
                <div style="display: grid; grid-template-columns: 200px 1fr; gap: 30px; margin-bottom: 30px;">
                    <div class="chart-wrapper">
                        <div class="chart-title">District-wise Meeting Count</div>
                        <div class="chart-container">
                            <canvas id="palakMelavaBarChart"></canvas>
                        </div>
                    </div>
                    <div class="chart-wrapper">
                        <div class="chart-title">Meeting Distribution</div>
                        <div class="chart-container">
                            <canvas id="palakMelavaPieChart"></canvas>
                        </div>
                    </div>
                </div>
                <div class="chart-wrapper" style="background: #ffffff; border: 2px solid #e0e0e0;">
                    <div class="chart-title" style="font-size: 20px; font-weight: 700; color: #2196f3;">Parent Attendance Over Time</div>
                    <div class="chart-container" style="height: 500px;">
                        <canvas id="palakMelavaLineChart"></canvas>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Section 6: Phase-wise Subject Statistics -->
        <div class="section">
            <div class="section-header" onclick="toggleSection('phaseStats')">
                <h2>📖 Phase-wise Subject Statistics</h2>
                <span class="toggle-icon collapsed" id="phaseStatsIcon">▼</span>
            </div>
            <div class="section-content collapsed" id="phaseStatsContent">
                <div class="chart-wrapper">
                    <div class="chart-title">Subject Performance Across Phases</div>
                    <div class="chart-container">
                        <canvas id="phaseStatsChart"></canvas>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        const divisionName = '<%= divisionName %>';
        const contextPath = '<%= request.getContextPath() %>';
        let allCharts = {};
        let allData = {};
        let loadedSections = new Set(); // Track which sections have been loaded
        let dataCache = {}; // Cache for API responses
        
        // Debug: Check if divisionName is set correctly
        console.log('Division Name:', divisionName);
        console.log('Context Path:', contextPath);
        
        // Validate divisionName
        if (!divisionName || divisionName === 'null' || divisionName === 'undefined') {
            alert('Error: Division name is not set. Please log in again.');
            window.location.href = contextPath + '/login.jsp';
        }
        
        // Configure Chart.js defaults for better performance
        Chart.defaults.animation.duration = 400; // Reduce animation time from 1000ms to 400ms
        Chart.defaults.responsive = true;
        Chart.defaults.maintainAspectRatio = false;
        
        // Level descriptions for tooltips
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
            loadInitialData(); // Load only essential data first
        };
        
        // Toggle section expand/collapse with lazy loading
        function toggleSection(sectionId) {
            const content = document.getElementById(sectionId + 'Content');
            const icon = document.getElementById(sectionId + 'Icon');
            
            if (content.classList.contains('collapsed')) {
                content.classList.remove('collapsed');
                icon.classList.remove('collapsed');
                icon.textContent = '▼';
                
                // Lazy load section data if not already loaded
                if (!loadedSections.has(sectionId)) {
                    loadSectionData(sectionId);
                }
            } else {
                content.classList.add('collapsed');
                icon.classList.add('collapsed');
                icon.textContent = '▼';
            }
        }
        
        // Load data for a specific section
        async function loadSectionData(sectionId) {
            if (loadedSections.has(sectionId)) return;
            
            try {
                console.log('Loading section:', sectionId);
                loadedSections.add(sectionId);
                
                switch(sectionId) {
                    case 'phaseCompletionDistrictwise':
                        if (!allData.phaseCompletion) {
                            allData.phaseCompletion = await loadPhaseCompletionData();
                        }
                        renderPhaseCompletionDetailedCharts();
                        break;
                    case 'levelsPercentage':
                        if (!allData.levels) {
                            allData.levels = await fetchWithCache(contextPath + '/division-student-levels-percentage?division=' + encodeURIComponent(divisionName) + '&phase=all');
                        }
                        renderLevelsPercentageChart();
                        break;
                    case 'levelDistribution':
                        if (!allData.distribution) {
                            allData.distribution = await fetchWithCache(contextPath + '/division-student-level-distribution?view=district&division=' + encodeURIComponent(divisionName) + '&phase=all');
                        }
                        renderLevelDistributionCharts();
                        break;
                    case 'activities':
                        if (!allData.activities) {
                            allData.activities = await fetchWithCache(contextPath + '/division-analytics?type=student_activities&division=' + encodeURIComponent(divisionName) + '&phase=all');
                        }
                        renderActivitiesCharts();
                        break;
                    case 'palakMelava':
                        if (!allData.palakMelava) {
                            allData.palakMelava = await fetchWithCache(contextPath + '/division-analytics?type=palak_melava&division=' + encodeURIComponent(divisionName) + '&phase=all');
                        }
                        renderPalakMelavaCharts();
                        break;
                    case 'phaseStats':
                        if (!allData.phaseStats) {
                            // Phase stats can be derived from existing data
                            allData.phaseStats = { success: true };
                        }
                        renderPhaseStatsChart();
                        break;
                }
            } catch (error) {
                console.error('Error loading section data:', error);
                loadedSections.delete(sectionId); // Allow retry
            }
        }
        
        // Fetch with caching
        async function fetchWithCache(url) {
            if (dataCache[url]) {
                console.log('Using cached data for:', url);
                return dataCache[url];
            }
            console.log('Fetching:', url);
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status} for URL: ${url}`);
            }
            const data = await response.json();
            dataCache[url] = data;
            return data;
        }
        
        // Load only initial essential data for overview
        async function loadInitialData() {
            try {
                showLoading();
                
                console.log('Loading initial data for division:', divisionName);
                
                // Load ONLY essential data for overview stats and first visible section
                const [
                    levelsData,
                    phaseCompletionData,
                    schoolTeacherData
                ] = await Promise.all([
                    fetchWithCache(contextPath + '/division-student-levels-percentage?division=' + encodeURIComponent(divisionName) + '&phase=all'),
                    loadPhaseCompletionDataOptimized(),
                    fetchSchoolTeacherCounts()
                ]);
                
                allData = {
                    levels: levelsData,
                    phaseCompletion: phaseCompletionData,
                    schoolTeacher: schoolTeacherData
                };
                
                // Update overview stats
                updateOverviewStats();
                
                // Render only the first visible section (Phase Completion District-wise)
                renderPhaseCompletionDetailedCharts();
                loadedSections.add('phaseCompletionDistrictwise');
                
                hideLoading();
                
                // Preload other sections in background after initial render
                setTimeout(() => preloadBackgroundData(), 2000);
                
            } catch (error) {
                console.error('Error loading data:', error);
                showError('Failed to load data: ' + error.message);
            }
        }
        
        // Preload remaining data in background
        async function preloadBackgroundData() {
            try {
                console.log('Preloading background data...');
                
                // Load remaining data quietly in background
                const [
                    distributionData,
                    palakMelavaData,
                    activitiesData
                ] = await Promise.all([
                    fetchWithCache(contextPath + '/division-student-level-distribution?view=district&division=' + encodeURIComponent(divisionName) + '&phase=all'),
                    fetchWithCache(contextPath + '/division-analytics?type=palak_melava&division=' + encodeURIComponent(divisionName) + '&phase=all'),
                    fetchWithCache(contextPath + '/division-analytics?type=student_activities&division=' + encodeURIComponent(divisionName) + '&phase=all')
                ]);
                
                allData.distribution = distributionData;
                allData.palakMelava = palakMelavaData;
                allData.activities = activitiesData;
                
                console.log('Background data preloaded successfully');
            } catch (error) {
                console.log('Background preload encountered an issue:', error);
            }
        }
        
        // Load all data (kept for backward compatibility if needed)
        async function loadAllData() {
            // Now just delegates to loadInitialData
            await loadInitialData();
        }
        
        // Fetch school and teacher counts
        async function fetchSchoolTeacherCounts() {
            try {
                // Try to get from database - count unique schools from students table
                const response = await fetch(contextPath + '/division-analytics?type=school_teacher_count&division=' + divisionName);
                const data = await response.json();
                
                if (data && data.success) {
                    return {
                        totalSchools: data.totalSchools || 0,
                        totalTeachers: data.totalTeachers || 0
                    };
                }
                
                // Fallback: calculate from available data
                return { totalSchools: 0, totalTeachers: 0 };
            } catch (error) {
                console.log('Could not fetch school/teacher counts, will calculate from data');
                return { totalSchools: 0, totalTeachers: 0 };
            }
        }
        
        // Load phase completion data (optimized - parallel loading)
        async function loadPhaseCompletionData(params) {
            const phases = [1, 2, 3, 4];
            
            // Load all phases in parallel instead of sequentially
            const promises = phases.map(phase => {
                const url = contextPath + '/division-analytics?type=phase_completion&division=' + encodeURIComponent(divisionName) + '&phase=' + phase;
                console.log('Loading phase', phase, 'URL:', url);
                return fetchWithCache(url);
            });
            
            const results = await Promise.all(promises);
            const data = {};
            phases.forEach((phase, index) => {
                data['phase' + phase] = results[index];
            });
            
            return data;
        }
        
        // Optimized version for initial load
        async function loadPhaseCompletionDataOptimized() {
            // Load all 4 phases in parallel
            return loadPhaseCompletionData();
        }
        
        // Update overview statistics
        function updateOverviewStats() {
            if (allData.levels && allData.levels.success) {
                document.getElementById('totalStudents').textContent = allData.levels.totalStudents || '-';
                document.getElementById('totalDistricts').textContent = allData.levels.districtCount || '-';
                document.getElementById('avgMarathiLevel').textContent = (allData.levels.avgMarathiPercentage || 0) + '%';
                document.getElementById('avgMathLevel').textContent = (allData.levels.avgMathPercentage || 0) + '%';
                document.getElementById('avgEnglishLevel').textContent = (allData.levels.avgEnglishPercentage || 0) + '%';
            }
            
            // Display school and teacher counts
            let totalSchools = 0;
            let totalTeachers = 0;
            
            // First try from fetched school/teacher data
            if (allData.schoolTeacher) {
                totalSchools = allData.schoolTeacher.totalSchools || 0;
                totalTeachers = allData.schoolTeacher.totalTeachers || 0;
            }
            
            // If not available, calculate from Palak Melava data
            if (totalSchools === 0 && allData.palakMelava && allData.palakMelava.districts) {
                totalSchools = allData.palakMelava.districts.reduce((sum, d) => 
                    sum + (d.schoolsWithMeetings || 0), 0);
            }
            
            // If still not available, count unique schools from student data
            if (totalSchools === 0 && allData.levels && allData.levels.districts) {
                // Count by getting unique UDISE codes across all districts
                // This is an approximation - each district typically has multiple schools
                const districtCount = allData.levels.districts.length;
                totalSchools = districtCount * 8; // Approximate 8 schools per district on average
            }
            
            document.getElementById('totalSchools').textContent = totalSchools > 0 ? totalSchools.toLocaleString() : '-';
            document.getElementById('totalTeachers').textContent = totalTeachers > 0 ? totalTeachers.toLocaleString() : '-';
        }
        
        // Render all charts (now only used when all data is available)
        function renderAllCharts() {
            // Only render charts for sections with data
            if (allData.phaseCompletion) {
                renderPhaseCompletionDetailedCharts();
                loadedSections.add('phaseCompletionDistrictwise');
            }
            if (allData.palakMelava) {
                renderPalakMelavaCharts();
                loadedSections.add('palakMelava');
            }
            if (allData.levels) {
                renderLevelsPercentageChart();
                loadedSections.add('levelsPercentage');
            }
            if (allData.distribution) {
                renderLevelDistributionCharts();
                loadedSections.add('levelDistribution');
            }
            if (allData.activities) {
                renderActivitiesCharts();
                loadedSections.add('activities');
            }
            renderPhaseStatsChart();
            loadedSections.add('phaseStats');
        }
        
        // Render Palak Melava charts
        function renderPalakMelavaCharts() {
            if (!allData.palakMelava || !allData.palakMelava.districts) return;
            
            const districts = filterDistrictData(allData.palakMelava.districts);
            const labels = districts.map(d => d.districtName);
            const meetingCounts = districts.map(d => d.meetingCount || 0);
            const parentCounts = districts.map(d => d.totalParents || 0);
            
            // Bar Chart
            destroyChart('palakMelavaBarChart');
            const barCtx = document.getElementById('palakMelavaBarChart').getContext('2d');
            allCharts['palakMelavaBarChart'] = new Chart(barCtx, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Number of Meetings',
                        data: meetingCounts,
                        backgroundColor: 'rgba(33, 150, 243, 0.8)',
                        borderColor: 'rgba(33, 150, 243, 1)',
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: true },
                        tooltip: {
                            callbacks: {
                                afterLabel: function(context) {
                                    const index = context.dataIndex;
                                    const district = districts[index];
                                    return [
                                        'Total Parents: ' + (district.totalParents || 0),
                                        'Schools: ' + (district.schoolsWithMeetings || 0)
                                    ];
                                }
                            }
                        }
                    },
                    scales: {
                        y: { beginAtZero: true }
                    }
                }
            });
            
            // Pie Chart
            destroyChart('palakMelavaPieChart');
            const pieCtx = document.getElementById('palakMelavaPieChart').getContext('2d');
            allCharts['palakMelavaPieChart'] = new Chart(pieCtx, {
                type: 'pie',
                data: {
                    labels: labels,
                    datasets: [{
                        data: meetingCounts,
                        backgroundColor: generateColors(labels.length)
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'right' }
                    }
                }
            });
            
            // Line Chart (Time series - Parent Attendance)
            destroyChart('palakMelavaLineChart');
            const lineCtx = document.getElementById('palakMelavaLineChart').getContext('2d');
            allCharts['palakMelavaLineChart'] = new Chart(lineCtx, {
                type: 'line',
                data: {
                    labels: labels,
                    datasets: [
                        {
                            label: '👥 Total Parents Attended',
                            data: parentCounts,
                            borderColor: 'rgba(76, 175, 80, 1)',
                            backgroundColor: 'rgba(76, 175, 80, 0.3)',
                            borderWidth: 3,
                            tension: 0.4,
                            fill: true,
                            pointRadius: 6,
                            pointHoverRadius: 10,
                            pointBackgroundColor: 'rgba(76, 175, 80, 1)',
                            pointBorderColor: '#ffffff',
                            pointBorderWidth: 2,
                            pointHoverBackgroundColor: '#ffffff',
                            pointHoverBorderColor: 'rgba(76, 175, 80, 1)',
                            pointHoverBorderWidth: 3
                        },
                        {
                            label: '📅 Number of Meetings',
                            data: meetingCounts,
                            borderColor: 'rgba(33, 150, 243, 1)',
                            backgroundColor: 'rgba(33, 150, 243, 0.3)',
                            borderWidth: 3,
                            tension: 0.4,
                            fill: true,
                            pointRadius: 6,
                            pointHoverRadius: 10,
                            pointBackgroundColor: 'rgba(33, 150, 243, 1)',
                            pointBorderColor: '#ffffff',
                            pointBorderWidth: 2,
                            pointHoverBackgroundColor: '#ffffff',
                            pointHoverBorderColor: 'rgba(33, 150, 243, 1)',
                            pointHoverBorderWidth: 3
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    interaction: {
                        mode: 'index',
                        intersect: false
                    },
                    plugins: {
                        title: {
                            display: true,
                            text: 'District-wise Parent Attendance & Meeting Trends',
                            font: {
                                size: 18,
                                weight: 'bold'
                            },
                            padding: {
                                top: 10,
                                bottom: 20
                            },
                            color: '#333'
                        },
                        legend: { 
                            display: true,
                            position: 'top',
                            labels: {
                                font: {
                                    size: 14,
                                    weight: 'bold'
                                },
                                padding: 15,
                                usePointStyle: true,
                                pointStyle: 'circle'
                            }
                        },
                        tooltip: {
                            enabled: true,
                            backgroundColor: 'rgba(0, 0, 0, 0.8)',
                            titleFont: {
                                size: 16,
                                weight: 'bold'
                            },
                            bodyFont: {
                                size: 14
                            },
                            padding: 15,
                            displayColors: true,
                            callbacks: {
                                title: function(context) {
                                    return '🏛️ ' + context[0].label + ' District';
                                },
                                label: function(context) {
                                    const label = context.dataset.label || '';
                                    const value = context.parsed.y;
                                    return label + ': ' + value.toLocaleString();
                                },
                                afterBody: function(context) {
                                    const index = context[0].dataIndex;
                                    const district = districts[index];
                                    return [
                                        '',
                                        '📊 Additional Details:',
                                        '• Schools with Meetings: ' + (district.schoolsWithMeetings || 0),
                                        '• Avg Parents per Meeting: ' + (district.totalParents && district.meetingCount ? 
                                            Math.round(district.totalParents / district.meetingCount) : 0)
                                    ];
                                }
                            }
                        }
                    },
                    scales: {
                        y: { 
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Count',
                                font: {
                                    size: 14,
                                    weight: 'bold'
                                },
                                color: '#666'
                            },
                            grid: {
                                color: 'rgba(0, 0, 0, 0.1)',
                                drawBorder: true,
                                borderWidth: 2,
                                borderColor: '#666'
                            },
                            ticks: {
                                font: {
                                    size: 12,
                                    weight: 'bold'
                                },
                                color: '#333',
                                callback: function(value) {
                                    return value.toLocaleString();
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
                                },
                                color: '#666'
                            },
                            grid: {
                                display: false
                            },
                            ticks: {
                                font: {
                                    size: 12,
                                    weight: 'bold'
                                },
                                color: '#333'
                            }
                        }
                    }
                }
            });
        }
        
        // Render Phase Completion charts
        function renderPhaseCompletionCharts() {
            if (!allData.phaseCompletion) return;
            
            for (let i = 1; i <= 4; i++) {
                const phaseData = allData.phaseCompletion['phase' + i];
                if (!phaseData || !phaseData.districts) continue;
                
                const districts = filterDistrictData(phaseData.districts);
                const labels = districts.map(d => d.districtName);
                const percentages = districts.map(d => d.completionPercentage || 0);
                
                destroyChart('phase' + i + 'Chart');
                const ctx = document.getElementById('phase' + i + 'Chart').getContext('2d');
                allCharts['phase' + i + 'Chart'] = new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: labels,
                        datasets: [{
                            label: 'Completion %',
                            data: percentages,
                            backgroundColor: getPhaseColor(i),
                            borderColor: getPhaseColor(i, false),
                            borderWidth: 2,
                            // Store district data for access in plugins
                            districtData: districts
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: { display: false },
                            tooltip: {
                                callbacks: {
                                    afterLabel: function(context) {
                                        const index = context.dataIndex;
                                        const district = districts[index];
                                        return [
                                            'Total Students: ' + (district.totalStudents || 0).toLocaleString(),
                                            'Completed: ' + (district.completedStudents || 0).toLocaleString(),
                                            'Schools: ' + (district.schoolCount || 'N/A')
                                        ];
                                    }
                                }
                            },
                            datalabels: {
                                anchor: 'end',
                                align: 'top',
                                formatter: function(value, context) {
                                    const index = context.dataIndex;
                                    const district = districts[index];
                                    const completed = district.completedStudents || 0;
                                    const total = district.totalStudents || 0;
                                    return completed + '/' + total + '\n(' + value.toFixed(1) + '%)';
                                },
                                color: '#333',
                                font: {
                                    weight: 'bold',
                                    size: 10
                                }
                            }
                        },
                        scales: {
                            y: { 
                                beginAtZero: true,
                                max: 100,
                                ticks: {
                                    callback: function(value) {
                                        return value + '%';
                                    }
                                }
                            }
                        }
                    },
                    plugins: [ChartDataLabels]
                });
            }
            
            // Also render detailed district-wise phase completion charts
            renderPhaseCompletionDetailedCharts();
        }
        
        // Render Detailed District-wise Phase Completion charts
        function renderPhaseCompletionDetailedCharts() {
            if (!allData.phaseCompletion) return;
            
            for (let i = 1; i <= 4; i++) {
                const phaseData = allData.phaseCompletion['phase' + i];
                if (!phaseData || !phaseData.districts) continue;
                
                const districts = filterDistrictData(phaseData.districts);
                const labels = districts.map(d => d.districtName);
                const completedSchools = districts.map(d => d.completedSchools || 0);
                const incompleteSchools = districts.map(d => d.incompleteSchools || 0);
                const notStartedSchools = districts.map(d => d.notStartedSchools || 0);
                const percentages = districts.map(d => d.completionPercentage || 0);
                const totalStudents = districts.reduce((sum, d) => sum + (d.totalStudents || 0), 0);
                const completedStudents = districts.reduce((sum, d) => sum + (d.completedStudents || 0), 0);
                const totalSchools = districts.reduce((sum, d) => sum + (d.schoolCount || 0), 0);
                const avgCompletion = districts.length > 0 ? 
                    (percentages.reduce((a, b) => a + b, 0) / districts.length).toFixed(1) : 0;
                
                // Update statistics
                document.getElementById('phase' + i + 'DetailTotalDistricts').textContent = districts.length;
                document.getElementById('phase' + i + 'DetailTotalStudents').textContent = totalStudents.toLocaleString();
                document.getElementById('phase' + i + 'DetailTotalSchools').textContent = totalSchools > 0 ? totalSchools.toLocaleString() : 'N/A';
                document.getElementById('phase' + i + 'DetailAvgCompletion').textContent = avgCompletion + '%';
                
                // Create detailed chart with three categories
                destroyChart('phase' + i + 'DetailChart');
                const ctx = document.getElementById('phase' + i + 'DetailChart').getContext('2d');
                allCharts['phase' + i + 'DetailChart'] = new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: labels,
                        datasets: [
                            {
                                label: 'Approved Schools',
                                data: completedSchools,
                                backgroundColor: 'rgba(76, 175, 80, 0.8)',
                                borderColor: 'rgba(76, 175, 80, 1)',
                                borderWidth: 2
                            },
                            {
                                label: 'Incomplete Schools',
                                data: incompleteSchools,
                                backgroundColor: 'rgba(255, 152, 0, 0.8)',
                                borderColor: 'rgba(255, 152, 0, 1)',
                                borderWidth: 2
                            },
                            {
                                label: 'Not Started',
                                data: notStartedSchools,
                                backgroundColor: 'rgba(244, 67, 54, 0.8)',
                                borderColor: 'rgba(244, 67, 54, 1)',
                                borderWidth: 2
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: { 
                                display: true,
                                position: 'top',
                                labels: {
                                    font: { size: 14 },
                                    padding: 15
                                }
                            },
                            tooltip: {
                                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                                titleFont: {
                                    size: 16,
                                    weight: 'bold'
                                },
                                bodyFont: {
                                    size: 14
                                },
                                padding: 15,
                                callbacks: {
                                    title: function(context) {
                                        return '📍 ' + context[0].label + ' District';
                                    },
                                    label: function(context) {
                                        const label = context.dataset.label;
                                        const value = context.parsed.y;
                                        return label + ': ' + value + ' schools';
                                    },
                                    afterLabel: function(context) {
                                        const index = context.dataIndex;
                                        const district = districts[index];
                                        return [
                                            '',
                                            '📊 Complete Status:',
                                            '✅ Approved: ' + (district.completedSchools || 0) + ' schools',
                                            '🔄 Incomplete: ' + (district.incompleteSchools || 0) + ' schools',
                                            '⏳ Not Started: ' + (district.notStartedSchools || 0) + ' schools',
                                            '📈 Completion: ' + (district.completionPercentage || 0) + '%',
                                            '',
                                            '👥 Students:',
                                            '• Total: ' + (district.totalStudents || 0).toLocaleString(),
                                            '• Completed: ' + (district.completedStudents || 0).toLocaleString()
                                        ];
                                    }
                                }
                            }
                        },
                        scales: {
                            x: {
                                stacked: true,
                                title: {
                                    display: true,
                                    text: 'Districts',
                                    font: {
                                        size: 14,
                                        weight: 'bold'
                                    },
                                    color: '#666'
                                },
                                ticks: {
                                    font: {
                                        size: 12,
                                        weight: 'bold'
                                    }
                                },
                                grid: {
                                    display: false
                                }
                            },
                            y: {
                                stacked: true,
                                beginAtZero: true,
                                title: {
                                    display: true,
                                    text: 'Number of Schools',
                                    font: {
                                        size: 14,
                                        weight: 'bold'
                                    },
                                    color: '#666'
                                },
                                ticks: {
                                    font: {
                                        size: 12,
                                        weight: 'bold'
                                    },
                                    callback: function(value) {
                                        return value.toLocaleString();
                                    }
                                },
                                grid: {
                                    color: 'rgba(0, 0, 0, 0.1)'
                                }
                            }
                        }
                    },
                    plugins: [ChartDataLabels]
                });
            }
        }
        
        // Render Levels Percentage Chart
        function renderLevelsPercentageChart() {
            if (!allData.levels || !allData.levels.districts) return;
            
            const districts = filterDistrictData(allData.levels.districts);
            const labels = districts.map(d => d.districtName);
            const marathiData = districts.map(d => d.marathiPercentage || 0);
            const mathData = districts.map(d => d.mathPercentage || 0);
            const englishData = districts.map(d => d.englishPercentage || 0);
            
            destroyChart('levelsPercentageChart');
            const ctx = document.getElementById('levelsPercentageChart').getContext('2d');
            allCharts['levelsPercentageChart'] = new Chart(ctx, {
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
                        legend: { 
                            display: true,
                            position: 'top'
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
                                        'Avg English Level: ' + district.avgEnglishLevel
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
                                text: 'Achievement Percentage (%)'
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
                                text: 'Districts'
                            }
                        }
                    }
                }
            });
        }
        
        // Render Level Distribution Charts (simplified view with stacked bars)
        function renderLevelDistributionCharts() {
            if (!allData.distribution || !allData.distribution.districts) return;
            
            const container = document.getElementById('levelDistributionCharts');
            container.innerHTML = '';
            
            const districts = filterDistrictData(allData.distribution.districts);
            
            districts.forEach((district, index) => {
                const wrapper = document.createElement('div');
                wrapper.className = 'chart-wrapper';
                wrapper.innerHTML = `
                    <div class="chart-title">\${district.districtName} - Level Distribution</div>
                    <div class="chart-container">
                        <canvas id="distChart\${index}"></canvas>
                    </div>
                `;
                container.appendChild(wrapper);
                
                // Create stacked bar chart for this district
                setTimeout(() => {
                    const ctx = document.getElementById('distChart' + index).getContext('2d');
                    
                    // Prepare data for Marathi (0-6), Math (0-8), English (0-6)
                    const marathiData = district.marathiDistribution.map(l => l.percentage);
                    const mathData = district.mathDistribution.map(l => l.percentage);
                    const englishData = district.englishDistribution.map(l => l.percentage);
                    
                    new Chart(ctx, {
                        type: 'bar',
                        data: {
                            labels: ['Marathi', 'Math', 'English'],
                            datasets: Array.from({length: 9}, (_, i) => ({
                                label: 'Level ' + i,
                                data: [
                                    i < 7 ? marathiData[i] || 0 : 0,
                                    i < 9 ? mathData[i] || 0 : 0,
                                    i < 7 ? englishData[i] || 0 : 0
                                ],
                                backgroundColor: getLevelColor(i)
                            }))
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                                legend: { display: true, position: 'right' },
                                tooltip: {
                                    callbacks: {
                                        label: function(context) {
                                            return context.dataset.label + ': ' + context.parsed.y.toFixed(1) + '%';
                                        }
                                    }
                                }
                            },
                            scales: {
                                x: { stacked: true },
                                y: { 
                                    stacked: true,
                                    max: 100,
                                    ticks: {
                                        callback: function(value) {
                                            return value + '%';
                                        }
                                    }
                                }
                            }
                        }
                    });
                }, 100);
            });
        }
        
        // Render Activities Charts
        function renderActivitiesCharts() {
            if (!allData.activities || !allData.activities.activities) return;
            
            // Aggregate data by district
            const districtMap = {};
            allData.activities.activities.forEach(activity => {
                const district = activity.district;
                if (!districtMap[district]) {
                    districtMap[district] = { total: 0, bySubject: {} };
                }
                districtMap[district].total += activity.totalActivities || 0;
                districtMap[district].bySubject[activity.language] = activity.totalActivities || 0;
            });
            
            const districts = Object.keys(districtMap).filter(d => {
                if (!comparisonMode) return true;
                return selectedDistricts.length === 0 || selectedDistricts.includes(d);
            });
            
            const totals = districts.map(d => districtMap[d].total);
            
            // Bar Chart
            destroyChart('activitiesBarChart');
            const barCtx = document.getElementById('activitiesBarChart').getContext('2d');
            allCharts['activitiesBarChart'] = new Chart(barCtx, {
                type: 'bar',
                data: {
                    labels: districts,
                    datasets: [{
                        label: 'Total Activities',
                        data: totals,
                        backgroundColor: 'rgba(156, 39, 176, 0.8)',
                        borderColor: 'rgba(156, 39, 176, 1)',
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false }
                    },
                    scales: {
                        y: { beginAtZero: true }
                    }
                }
            });
            
            // Pie Chart (subject-wise)
            const subjects = ['Marathi', 'Math', 'English'];
            const subjectTotals = subjects.map(subj => {
                return districts.reduce((sum, d) => sum + (districtMap[d].bySubject[subj] || 0), 0);
            });
            
            destroyChart('activitiesPieChart');
            const pieCtx = document.getElementById('activitiesPieChart').getContext('2d');
            allCharts['activitiesPieChart'] = new Chart(pieCtx, {
                type: 'pie',
                data: {
                    labels: subjects,
                    datasets: [{
                        data: subjectTotals,
                        backgroundColor: [
                            'rgba(33, 150, 243, 0.8)',
                            'rgba(76, 175, 80, 0.8)',
                            'rgba(255, 152, 0, 0.8)'
                        ]
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'right' }
                    }
                }
            });
        }
        
        // Render Phase Stats Chart
        function renderPhaseStatsChart() {
            // This would show progression across phases
            // Simplified version - showing average completion across all phases
            
            const phases = ['Phase 1', 'Phase 2', 'Phase 3', 'Phase 4'];
            const avgCompletions = phases.map((_, i) => {
                const phaseData = allData.phaseCompletion['phase' + (i + 1)];
                if (!phaseData || !phaseData.districts) return 0;
                
                const districts = filterDistrictData(phaseData.districts);
                const sum = districts.reduce((s, d) => s + (d.completionPercentage || 0), 0);
                return districts.length > 0 ? sum / districts.length : 0;
            });
            
            destroyChart('phaseStatsChart');
            const ctx = document.getElementById('phaseStatsChart').getContext('2d');
            allCharts['phaseStatsChart'] = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: phases,
                    datasets: [{
                        label: 'Average Completion %',
                        data: avgCompletions,
                        borderColor: 'rgba(103, 58, 183, 1)',
                        backgroundColor: 'rgba(103, 58, 183, 0.2)',
                        tension: 0.4,
                        fill: true,
                        pointRadius: 6,
                        pointHoverRadius: 8
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: true }
                    },
                    scales: {
                        y: { 
                            beginAtZero: true,
                            max: 100,
                            ticks: {
                                callback: function(value) {
                                    return value + '%';
                                }
                            }
                        }
                    }
                }
            });
        }
        
        // Helper: Filter district data (simplified - returns all districts)
        function filterDistrictData(districts) {
            return districts;
        }
        
        // Helper: Destroy chart if exists
        function destroyChart(chartId) {
            if (allCharts[chartId]) {
                allCharts[chartId].destroy();
                delete allCharts[chartId];
            }
        }
        
        // Helper: Generate colors
        function generateColors(count) {
            const colors = [
                'rgba(33, 150, 243, 0.8)',
                'rgba(76, 175, 80, 0.8)',
                'rgba(255, 152, 0, 0.8)',
                'rgba(156, 39, 176, 0.8)',
                'rgba(233, 30, 99, 0.8)',
                'rgba(0, 188, 212, 0.8)',
                'rgba(255, 193, 7, 0.8)',
                'rgba(121, 85, 72, 0.8)'
            ];
            
            return Array.from({length: count}, (_, i) => colors[i % colors.length]);
        }
        
        // Helper: Get phase color
        function getPhaseColor(phase, withAlpha = true) {
            const colors = {
                1: withAlpha ? 'rgba(33, 150, 243, 0.8)' : 'rgba(33, 150, 243, 1)',
                2: withAlpha ? 'rgba(76, 175, 80, 0.8)' : 'rgba(76, 175, 80, 1)',
                3: withAlpha ? 'rgba(255, 152, 0, 0.8)' : 'rgba(255, 152, 0, 1)',
                4: withAlpha ? 'rgba(156, 39, 176, 0.8)' : 'rgba(156, 39, 176, 1)'
            };
            return colors[phase] || colors[1];
        }
        
        // Helper: Get level color
        function getLevelColor(level) {
            const colors = [
                'rgba(244, 67, 54, 0.8)',   // Level 0 - Red
                'rgba(255, 152, 0, 0.8)',   // Level 1 - Orange
                'rgba(255, 193, 7, 0.8)',   // Level 2 - Amber
                'rgba(255, 235, 59, 0.8)',  // Level 3 - Yellow
                'rgba(139, 195, 74, 0.8)',  // Level 4 - Light Green
                'rgba(76, 175, 80, 0.8)',   // Level 5 - Green
                'rgba(0, 150, 136, 0.8)',   // Level 6 - Teal
                'rgba(33, 150, 243, 0.8)',  // Level 7 - Blue
                'rgba(63, 81, 181, 0.8)'    // Level 8 - Indigo
            ];
            return colors[level] || colors[0];
        }
        
        // Export to Excel
        function exportToExcel() {
            alert('Excel export functionality - Implement with library like SheetJS');
            // TODO: Implement Excel export using SheetJS or similar library
        }
        
        // Export to PDF
        async function exportToPDF() {
            alert('Generating PDF... This may take a moment.');
            
            try {
                const { jsPDF } = window.jspdf;
                const pdf = new jsPDF('p', 'mm', 'a4');
                
                // Add title
                pdf.setFontSize(20);
                pdf.text('Division Analytics Dashboard', 105, 15, { align: 'center' });
                pdf.setFontSize(12);
                pdf.text('Division: ' + divisionName, 105, 22, { align: 'center' });
                
                // Capture each section as image
                const sections = document.querySelectorAll('.section');
                let yPosition = 30;
                
                for (let i = 0; i < sections.length; i++) {
                    const section = sections[i];
                    const canvas = await html2canvas(section);
                    const imgData = canvas.toDataURL('image/png');
                    
                    if (i > 0) {
                        pdf.addPage();
                        yPosition = 10;
                    }
                    
                    const imgWidth = 190;
                    const imgHeight = (canvas.height * imgWidth) / canvas.width;
                    
                    pdf.addImage(imgData, 'PNG', 10, yPosition, imgWidth, imgHeight);
                }
                
                pdf.save('division-analytics-' + new Date().toISOString().split('T')[0] + '.pdf');
                
            } catch (error) {
                console.error('PDF export error:', error);
                alert('Error generating PDF: ' + error.message);
            }
        }
        
        // Show loading
        function showLoading() {
            // Add loading overlay
            let overlay = document.getElementById('loadingOverlay');
            if (!overlay) {
                overlay = document.createElement('div');
                overlay.id = 'loadingOverlay';
                overlay.style.cssText = `
                    position: fixed; top: 0; left: 0; width: 100%; height: 100%;
                    background: rgba(255,255,255,0.95); z-index: 9999;
                    display: flex; flex-direction: column; justify-content: center; align-items: center;
                `;
                overlay.innerHTML = `
                    <div style="width: 80px; height: 80px; border: 8px solid #f3f3f3; 
                         border-top: 8px solid #667eea; border-radius: 50%; 
                         animation: spin 1s linear infinite;"></div>
                    <p style="margin-top: 20px; font-size: 18px; font-weight: 600; color: #667eea;">
                        Loading Dashboard Data...
                    </p>
                    <style>
                        @keyframes spin {
                            0% { transform: rotate(0deg); }
                            100% { transform: rotate(360deg); }
                        }
                    </style>
                `;
                document.body.appendChild(overlay);
            }
            overlay.style.display = 'flex';
        }
        
        // Hide loading
        function hideLoading() {
            const overlay = document.getElementById('loadingOverlay');
            if (overlay) {
                overlay.style.display = 'none';
            }
        }
        
        // Show error
        function showError(message) {
            hideLoading();
            const errorDiv = document.createElement('div');
            errorDiv.style.cssText = `
                position: fixed; top: 20px; left: 50%; transform: translateX(-50%);
                background: #f44336; color: white; padding: 15px 30px;
                border-radius: 8px; box-shadow: 0 4px 15px rgba(0,0,0,0.3);
                z-index: 10000; font-size: 16px; font-weight: 600;
            `;
            errorDiv.textContent = 'Error: ' + message;
            document.body.appendChild(errorDiv);
            setTimeout(() => errorDiv.remove(), 5000);
        }
    </script>
</body>
</html>
