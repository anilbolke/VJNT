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
    <title>Activity Analysis - <%= divisionName %></title>
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
            padding-bottom: 20px;
            border-bottom: 3px solid #667eea;
        }
        
        .header h1 {
            color: #667eea;
            font-size: 32px;
            margin-bottom: 10px;
        }
        
        .header p {
            color: #666;
            font-size: 16px;
        }
        
        .back-btn {
            display: inline-block;
            padding: 10px 20px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-bottom: 20px;
            transition: background 0.3s;
        }
        
        .back-btn:hover {
            background: #5568d3;
        }
        
        .loading {
            text-align: center;
            padding: 50px;
            font-size: 18px;
            color: #667eea;
        }
        
        .district-card {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .district-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .district-name {
            font-size: 20px;
            font-weight: bold;
        }
        
        .student-count {
            background: rgba(255,255,255,0.2);
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 14px;
        }
        
        .phase-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }
        
        .phase-tab {
            padding: 10px 20px;
            background: #e9ecef;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: bold;
            transition: all 0.3s;
        }
        
        .phase-tab.active {
            background: #667eea;
            color: white;
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
            background: white;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }
        
        .level-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 4px 10px rgba(0,0,0,0.15);
        }
        
        .level-name {
            font-size: 13px;
            color: #666;
            margin-bottom: 8px;
            font-weight: 500;
        }
        
        .level-count {
            font-size: 28px;
            font-weight: bold;
            color: #667eea;
        }
        
        .level-count-label {
            font-size: 12px;
            color: #999;
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
    <div class="container">
        <a href="division-dashboard.jsp" class="back-btn">← Back to Dashboard</a>
        
        <div class="header">
            <h1>📊 Activity Level Analysis</h1>
            <p>Division: <strong><%= divisionName %></strong> | District-wise Phase Analysis</p>
        </div>
        
        <div id="content">
            <div class="loading">
                <div class="spinner"></div>
                <p style="margin-top: 15px;">Loading district data...</p>
            </div>
        </div>
    </div>
    
    <script>
        // Fetch data on page load
        window.onload = function() {
            fetch('GetDistrictActivityAnalysisServlet')
                .then(response => response.json())
                .then(data => {
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
            const content = document.getElementById('content');
            let html = '';
            
            if (!data.districts || data.districts.length === 0) {
                html = '<div class="loading"><p>No districts found in this division.</p></div>';
            } else {
                data.districts.forEach((district, districtIndex) => {
                    html += '<div class="district-card">';
                    html += '  <div class="district-header">';
                    html += '    <div class="district-name">🏛️ ' + escapeHtml(district.districtName) + '</div>';
                    html += '    <div class="student-count">👥 ' + district.totalStudents + ' Students</div>';
                    html += '  </div>';
                    
                    // Phase tabs
                    html += '  <div class="phase-tabs">';
                    for (let i = 1; i <= 4; i++) {
                        html += '    <button class="phase-tab ' + (i === 1 ? 'active' : '') + '" onclick="showPhase(' + districtIndex + ', ' + i + ')">Phase ' + i + '</button>';
                    }
                    html += '  </div>';
                    
                    // Phase contents
                    district.phases.forEach((phase, phaseIndex) => {
                        html += '  <div class="phase-content ' + (phaseIndex === 0 ? 'active' : '') + '" id="district' + districtIndex + '_phase' + phase.phaseNumber + '">';
                        
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
                        
                        html += '  </div>';
                    });
                    
                    html += '</div>';
                });
            }
            
            content.innerHTML = html;
        }
        
        function showPhase(districtIndex, phaseNumber) {
            // Hide all phase contents for this district
            const district = document.querySelectorAll('.district-card')[districtIndex];
            const phaseContents = district.querySelectorAll('.phase-content');
            const phaseTabs = district.querySelectorAll('.phase-tab');
            
            phaseContents.forEach(content => content.classList.remove('active'));
            phaseTabs.forEach(tab => tab.classList.remove('active'));
            
            // Show selected phase
            const selectedContent = district.querySelector('#district' + districtIndex + '_phase' + phaseNumber);
            const selectedTab = phaseTabs[phaseNumber - 1];
            
            if (selectedContent) selectedContent.classList.add('active');
            if (selectedTab) selectedTab.classList.add('active');
        }
        
        function escapeHtml(text) {
            if (!text) return '';
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
    </script>
</body>
</html>
