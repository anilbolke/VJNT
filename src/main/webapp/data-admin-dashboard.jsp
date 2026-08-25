<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.vjnt.model.User" %>
<%
    // Check if user is logged in
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    // Only DATA_ADMIN can access
    if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Data Admin Dashboard - GATEE PORTAL Class Management</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f0f2f5;
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
        }
        
        .header {
            background: #f0f2f5;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
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
            color: #000;
            font-size: 24px;
            font-weight: 700;
        }
        
        .gatee-tooltip {
            position: relative;
            display: inline-block;
            cursor: help;
            margin-left: 8px;
            color: #667eea;
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
        
        .logout-btn {
            padding: 10px 20px;
            background: #f44336;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
        }
        
        .logout-btn:hover {
            background: #d32f2f;
        }
        
        .upload-section {
            background: #e8eaf0;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
        }
        
        .upload-section h2 {
            color: #000;
            margin-bottom: 20px;
            font-weight: 700;
        }
        
        .info-box {
            background: #d4d9e8;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        
        .info-box h3 {
            color: #000;
            font-size: 16px;
            margin-bottom: 10px;
            font-weight: 700;
        }
        
        .info-box ul {
            margin-left: 20px;
            color: #000;
        }
        
        .info-box li {
            margin: 5px 0;
        }
        
        .upload-area {
		    border: 3px dashed #ccc;
		    border-radius: 10px;
		    padding: 40px;
		    text-align: center;
		    cursor: pointer;
		    transition: all 0.3s;
		    margin-bottom: 20px;
		    position: relative;
		    z-index: 100;
		}
        
        .upload-area:hover {
            border-color: #667eea;
            background: #f8f9fa;
        }
        
        .upload-area.dragover {
            border-color: #667eea;
            background: #e3f2fd;
        }
        
        .upload-icon {
            font-size: 48px;
            margin-bottom: 15px;
        }
        
        .file-input {
            position: absolute;
            width: 1px;
            height: 1px;
            opacity: 0;
            overflow: hidden;
            pointer-events: none;
        }
        
        .btn-upload {
            padding: 12px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            cursor: pointer;
            transition: transform 0.2s;
        }
        
        .btn-upload:hover {
            transform: translateY(-2px);
        }
        
        .btn-upload:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        
        .file-info {
            margin: 20px 0;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 5px;
            display: none;
        }
        
        .file-info.show {
            display: block;
        }
        
        .progress-bar {
            width: 100%;
            height: 30px;
            background: #e0e0e0;
            border-radius: 15px;
            overflow: hidden;
            margin: 20px 0;
            display: none;
        }
        
        .progress-bar.show {
            display: block;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            width: 0%;
            transition: width 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
        }
        
        .result-box {
            padding: 20px;
            border-radius: 8px;
            margin-top: 20px;
            display: none;
        }
        
        .result-box.show {
            display: block;
        }
        
        .result-box.success {
            background: #e8f5e9;
            border: 1px solid #4caf50;
            color: #2e7d32;
        }
        
        .result-box.error {
            background: #ffebee;
            border: 1px solid #f44336;
            color: #c62828;
        }
        
        .result-box pre {
            white-space: pre-wrap;
            margin-top: 10px;
            font-family: monospace;
        }
        
    </style>
</head>
<body>
<jsp:include page="academic-year-bar.jsp" />
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div class="header-left">
                <!-- Logo Section - START -->
                 <div class="header-logo">
                    <img src="<%= request.getContextPath() %>/Document/GATEE LOGO.png?v=2" alt="GATEE Logo">
                </div> 
                <!-- Logo Section - END -->
                <!-- Admin Icon and Title Section - START -->
                <div class="school-icon">👨‍💼</div>
                <h1>Data Admin Dashboard</h1>
                <!-- Admin Icon and Title Section - END -->
                <p style="color: #666; margin-top: 5px;">Welcome, <%= user.getFullName() %></p>
            </div>
            <a href="<%= request.getContextPath() %>/helpdesk.jsp" class="logout-btn" style="background:#667eea;margin-right:8px;">🙋 मदत केंद्र</a>
            <a href="<%= request.getContextPath() %>/logout" class="logout-btn">Logout</a>
        </div>
        
        <!-- Quick Actions -->
        <div style="margin-bottom: 30px; display: flex; gap: 15px; flex-wrap: wrap;">
            <a href="<%= request.getContextPath() %>/upload-schools.jsp" 
               style="flex: 1; min-width: 200px; padding: 20px; background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); 
                      color: white; text-decoration: none; border-radius: 10px; text-align: center; 
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'" 
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">🏫</div>
                <div style="font-size: 18px; font-weight: 600;">Upload School Master</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.9;">UDISE & School Names</div>
            </a>
            <a href="<%= request.getContextPath() %>/manage-users.jsp"
               style="flex: 1; min-width: 200px; padding: 20px; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                      color: white; text-decoration: none; border-radius: 10px; text-align: center;
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'"
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">👥</div>
                <div style="font-size: 18px; font-weight: 600;">Manage Users</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.9;">Create & Edit Users</div>
            </a>
            <a href="<%= request.getContextPath() %>/all-users-credentials.jsp"
               style="flex: 1; min-width: 200px; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                      color: white; text-decoration: none; border-radius: 10px; text-align: center;
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'"
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">🔑</div>
                <div style="font-size: 18px; font-weight: 600;">All Users Credentials</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.9;">View Usernames & Passwords</div>
            </a>
            <a href="<%= request.getContextPath() %>/manage-activity-visibility.jsp"
               style="flex: 1; min-width: 200px; padding: 20px; background: linear-gradient(135deg, #38b2ac 0%, #234e52 100%);
                      color: white; text-decoration: none; border-radius: 10px; text-align: center;
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'"
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">🗂️</div>
                <div style="font-size: 18px; font-weight: 600;">Activity Visibility</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.9;">Division-wise School Coordinator activities</div>
            </a>
        </div>

        <!-- Year-End Actions -->
        <div style="margin-bottom: 10px; font-size: 13px; font-weight: 700; color: #718096;
                    text-transform: uppercase; letter-spacing: 1px;">Year-End Actions</div>
        <div style="margin-bottom: 30px; display: flex; gap: 15px; flex-wrap: wrap;">
            <a href="<%= request.getContextPath() %>/promote-classes.jsp"
               style="flex: 1; min-width: 200px; padding: 20px;
                      background: linear-gradient(135deg, #f6ad55 0%, #dd6b20 100%);
                      color: white; text-decoration: none; border-radius: 10px; text-align: center;
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'"
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">🎓</div>
                <div style="font-size: 18px; font-weight: 600;">Promote Classes</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.9;">Advance students to next class</div>
                <div style="margin-top: 10px; background: rgba(0,0,0,0.2); border-radius: 5px;
                            padding: 3px 10px; font-size: 11px; font-weight: 700; display: inline-block;">
                    ⚠ Year-End Action
                </div>
            </a>
            <a href="<%= request.getContextPath() %>/promotion-audit.jsp"
               style="flex: 1; min-width: 200px; padding: 20px;
                      background: linear-gradient(135deg, #48bb78 0%, #276749 100%);
                      color: white; text-decoration: none; border-radius: 10px; text-align: center;
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'"
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">📋</div>
                <div style="font-size: 18px; font-weight: 600;">Promotion Audit</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.9;">View all past promotion events</div>
            </a>
            <a href="<%= request.getContextPath() %>/school-max-class.jsp"
               style="flex: 1; min-width: 200px; padding: 20px;
                      background: linear-gradient(135deg, #4fd1c5 0%, #319795 100%);
                      color: white; text-decoration: none; border-radius: 10px; text-align: center;
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'"
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">🏫</div>
                <div style="font-size: 18px; font-weight: 600;">School Terminal Class</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.9;">Set the last class each school runs to</div>
                <div style="margin-top: 10px; background: rgba(0,0,0,0.2); border-radius: 5px;
                            padding: 3px 10px; font-size: 11px; font-weight: 700; display: inline-block;">
                    ⚙ Set Before Promoting
                </div>
            </a>
            <a href="<%= request.getContextPath() %>/promotion-correction.jsp"
               style="flex: 1; min-width: 200px; padding: 20px;
                      background: linear-gradient(135deg, #fc8181 0%, #c53030 100%);
                      color: white; text-decoration: none; border-radius: 10px; text-align: center;
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'"
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">🩺</div>
                <div style="font-size: 18px; font-weight: 600;">Promotion Correction</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.9;">Graduate schools ending below Class IX</div>
                <div style="margin-top: 10px; background: rgba(0,0,0,0.2); border-radius: 5px;
                            padding: 3px 10px; font-size: 11px; font-weight: 700; display: inline-block;">
                    ⚠ Corrects Promotion
                </div>
            </a>
            <a href="<%= request.getContextPath() %>/graduated-students.jsp"
               style="flex: 1; min-width: 200px; padding: 20px;
                      background: linear-gradient(135deg, #f6e05e 0%, #d69e2e 100%);
                      color: #744210; text-decoration: none; border-radius: 10px; text-align: center;
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'"
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">🏆</div>
                <div style="font-size: 18px; font-weight: 600;">Graduated Students</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.8;">Permanent Class 9 graduate records</div>
            </a>
            <a href="<%= request.getContextPath() %>/student-phase-history.jsp"
               style="flex: 1; min-width: 200px; padding: 20px;
                      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                      color: #fff; text-decoration: none; border-radius: 10px; text-align: center;
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'"
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">📋</div>
                <div style="font-size: 18px; font-weight: 600;">विद्यार्थी टप्पा इतिहास</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.85;">PEN / नावाने मागील सर्व वर्षांचा FLN इतिहास</div>
            </a>
            <a href="<%= request.getContextPath() %>/student-activity.jsp"
               style="flex: 1; min-width: 200px; padding: 20px;
                      background: linear-gradient(135deg, #f97316 0%, #ea580c 100%);
                      color: #fff; text-decoration: none; border-radius: 10px; text-align: center;
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'"
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">🏅</div>
                <div style="font-size: 18px; font-weight: 600;">विद्यार्थी उपक्रम</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.9;">क्रीडा, सांस्कृतिक, शैक्षणिक कामगिरी</div>
            </a>
            <a href="<%= request.getContextPath() %>/admin-sql-console.jsp"
               style="flex: 1; min-width: 200px; padding: 20px;
                      background: linear-gradient(135deg, #2d3748 0%, #1a202c 100%);
                      color: #fff; text-decoration: none; border-radius: 10px; text-align: center;
                      transition: transform 0.2s; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
               onmouseover="this.style.transform='translateY(-3px)'"
               onmouseout="this.style.transform='translateY(0)'">
                <div style="font-size: 36px; margin-bottom: 10px;">🛠️</div>
                <div style="font-size: 18px; font-weight: 600;">SQL Console</div>
                <div style="font-size: 13px; margin-top: 5px; opacity: 0.85;">Run database scripts (Admin only)</div>
            </a>
        </div>

        <!-- Application Settings -->
        <div style="background: white; padding: 25px; border-radius: 10px; margin-bottom: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.08);">
            <h2 style="color:#000; margin-bottom: 12px;">⚙️ Teacher Student Assignment Setting</h2>
            <p style="color:#666; font-size: 13px; margin-bottom: 15px;">
                प्रत्येक शिक्षकाला प्रति विषय वर्गातील किती टक्के विद्यार्थी नियुक्त करायचे ते ठरवा (फक्त स्तर १ ते ४ मधील विद्यार्थी नियुक्त होतात).<br>
                Percentage of a class's students assigned to each teacher per subject. Only students at subject level 1&ndash;4 are assigned.
            </p>
            <div style="display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
                <label for="mapPercentInput" style="font-weight: 600; color:#333;">Students per class per subject:</label>
                <input type="number" id="mapPercentInput" min="1" max="100" step="1" value="25"
                       style="width: 90px; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 15px; text-align: center;">
                <span style="font-weight:600; color:#333;">%</span>
                <button type="button" id="mapPercentSaveBtn" onclick="saveMapPercent()"
                        style="padding: 10px 24px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; border-radius: 6px; font-size: 14px; font-weight: 600; cursor: pointer;">
                    💾 Save
                </button>
                <span id="mapPercentMsg" style="font-size: 13px;"></span>
            </div>
        </div>

        <!-- Upload Section -->
        <div class="upload-section">
            <h2>📤 Upload Student Data (Excel)</h2>
            
            <!-- Information Box -->
     
            
            <!-- Upload Area -->
            <div class="upload-area" id="uploadArea">
                <div class="upload-icon">📁</div>
                <h3>Click to select Excel file or drag & drop here</h3>
                <p style="color: #666; margin-top: 10px;">Supported formats: .xlsx, .xls</p>
                <input type="file" id="fileInput" class="file-input" accept=".xlsx,.xls">
            </div>
            
            <!-- File Info -->
            <div class="file-info" id="fileInfo">
                <strong>Selected File:</strong> <span id="fileName"></span>
                <br>
                <strong>Size:</strong> <span id="fileSize"></span>
            </div>
            
            <!-- Upload Button -->
            <button class="btn-upload" id="uploadBtn" onclick="uploadFile()" disabled>
                📤 Upload and Process
            </button>
            
            <!-- Progress Bar -->
            <div class="progress-bar" id="progressBar">
                <div class="progress-fill" id="progressFill">0%</div>
            </div>
            
            <!-- Result Box -->
            <div class="result-box" id="resultBox">
                <strong id="resultTitle"></strong>
                <pre id="resultMessage"></pre>
            </div>
        </div>

        <!-- Pending Student Excel Sheets from Schools -->
        <div style="background: white; padding: 25px; border-radius: 10px; margin-top: 30px; margin-bottom: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.08);">
            <h2 style="color:#000; margin-bottom: 8px;">📥 Pending Student Excel Sheets (from Schools)</h2>
            <p style="color:#666; font-size: 13px; margin-bottom: 15px;">
                Sheets sent by School Coordinators for review. These are NOT loaded into the system automatically -
                download and verify each one, then use the "Upload Student Data (Excel)" section above to import it.
            </p>
            <div style="overflow-x: auto;">
                <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
                    <thead>
                        <tr style="background:#f5f5f5; text-align:left;">
                            <th style="padding: 10px; border-bottom: 2px solid #e0e0e0;">UDISE No</th>
                            <th style="padding: 10px; border-bottom: 2px solid #e0e0e0;">School</th>
                            <th style="padding: 10px; border-bottom: 2px solid #e0e0e0;">Uploaded At</th>
                            <th style="padding: 10px; border-bottom: 2px solid #e0e0e0;">Size</th>
                            <th style="padding: 10px; border-bottom: 2px solid #e0e0e0;">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="pendingUploadsBody">
                        <tr><td colspan="5" style="padding: 15px; color:#999;">Loading...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        // ---------- Teacher student assignment percentage setting ----------
        const settingsUrl = '<%= request.getContextPath() %>/admin-settings';

        function loadMapPercent() {
            fetch(settingsUrl)
                .then(r => r.json())
                .then(data => {
                    if (typeof data.teacherStudentMapPercent === 'number') {
                        document.getElementById('mapPercentInput').value = data.teacherStudentMapPercent;
                    }
                })
                .catch(() => {});
        }

        function saveMapPercent() {
            const input = document.getElementById('mapPercentInput');
            const msg = document.getElementById('mapPercentMsg');
            const btn = document.getElementById('mapPercentSaveBtn');
            const percent = parseInt(input.value, 10);

            if (isNaN(percent) || percent < 1 || percent > 100) {
                msg.style.color = '#c62828';
                msg.textContent = 'Enter a percentage between 1 and 100';
                return;
            }

            btn.disabled = true;
            msg.style.color = '#666';
            msg.textContent = 'Saving...';

            fetch(settingsUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({ teacherStudentMapPercent: percent })
            })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                if (data.success) {
                    msg.style.color = '#2e7d32';
                    msg.textContent = '✔ Saved (' + data.teacherStudentMapPercent + '%)';
                } else {
                    msg.style.color = '#c62828';
                    msg.textContent = data.error || 'Save failed';
                }
            })
            .catch(err => {
                btn.disabled = false;
                msg.style.color = '#c62828';
                msg.textContent = 'Save failed: ' + err;
            });
        }

        loadMapPercent();

        // ---------- Student data upload ----------
        let selectedFile = null;

        // Get elements
        const uploadArea = document.getElementById('uploadArea');
        const fileInput = document.getElementById('fileInput');
        const fileInfo = document.getElementById('fileInfo');
        const fileName = document.getElementById('fileName');
        const fileSize = document.getElementById('fileSize');
        const uploadBtn = document.getElementById('uploadBtn');
        const progressBar = document.getElementById('progressBar');
        const progressFill = document.getElementById('progressFill');
        const resultBox = document.getElementById('resultBox');
        const resultTitle = document.getElementById('resultTitle');
        const resultMessage = document.getElementById('resultMessage');
        
        // Click to select file
        uploadArea.addEventListener('click', function(e) {
            // Prevent recursion: fileInput.click() dispatches a synthetic click
            // that bubbles back here because fileInput is a child of uploadArea.
            if (e.target === fileInput) return;
            fileInput.click();
        });
        // File selected
        fileInput.addEventListener('change', (e) => {
            if (e.target.files.length > 0) {
                selectedFile = e.target.files[0];
                displayFileInfo(selectedFile);
            }
        });
        
        // Drag and drop
        uploadArea.addEventListener('dragover', (e) => {
            e.preventDefault();
            uploadArea.classList.add('dragover');
        });
        
        uploadArea.addEventListener('dragleave', () => {
            uploadArea.classList.remove('dragover');
        });
        
        uploadArea.addEventListener('drop', (e) => {
            e.preventDefault();
            uploadArea.classList.remove('dragover');
            
            if (e.dataTransfer.files.length > 0) {
                selectedFile = e.dataTransfer.files[0];
                displayFileInfo(selectedFile);
            }
        });
        
        // Display file info
        function displayFileInfo(file) {
            fileName.textContent = file.name;
            fileSize.textContent = formatFileSize(file.size);
            fileInfo.classList.add('show');
            uploadBtn.disabled = false;
            resultBox.classList.remove('show');
        }
        
        // Format file size
        function formatFileSize(bytes) {
            if (bytes < 1024) return bytes + ' B';
            if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
            return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
        }
        
        // Upload file
        function uploadFile() {
            if (!selectedFile) {
                alert('Please select a file first');
                return;
            }
            
            // Validate file type
            if (!selectedFile.name.endsWith('.xlsx') && !selectedFile.name.endsWith('.xls')) {
                showResult(false, 'Invalid file type. Please upload Excel file (.xlsx or .xls)');
                return;
            }
            
            // Show progress
            uploadBtn.disabled = true;
            uploadBtn.textContent = '⏳ Uploading...';
            progressBar.classList.add('show');
            resultBox.classList.remove('show');
            
            // Create form data
            const formData = new FormData();
            formData.append('excelFile', selectedFile);
            
            // Upload file
            fetch('<%= request.getContextPath() %>/upload-excel', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                progressFill.style.width = '100%';
                progressFill.textContent = '100%';
                
                setTimeout(() => {
                    showResult(data.success, data.message);
                    uploadBtn.disabled = false;
                    uploadBtn.textContent = '📤 Upload and Process';
                    progressBar.classList.remove('show');
                    progressFill.style.width = '0%';
                    
                    if (data.success) {
                        // Reset form
                        selectedFile = null;
                        fileInput.value = '';
                        fileInfo.classList.remove('show');
                        uploadBtn.disabled = true;
                    }
                }, 500);
            })
            .catch(error => {
                showResult(false, 'Error uploading file: ' + error.message);
                uploadBtn.disabled = false;
                uploadBtn.textContent = '📤 Upload and Process';
                progressBar.classList.remove('show');
            });
        }
        
        // Show result
        function showResult(success, message) {
            resultBox.classList.remove('success', 'error');
            resultBox.classList.add(success ? 'success' : 'error');
            resultTitle.textContent = success ? '✅ Success!' : '❌ Error!';
            resultMessage.textContent = message;
            resultBox.classList.add('show');
        }

        // ---------- Pending student excel sheets from schools ----------
        const pendingUploadsUrl = '<%= request.getContextPath() %>/pending-student-upload';

        function loadPendingUploads() {
            const body = document.getElementById('pendingUploadsBody');
            fetch(pendingUploadsUrl)
                .then(r => r.json())
                .then(data => {
                    if (!data.success || !data.files || data.files.length === 0) {
                        body.innerHTML = '<tr><td colspan="5" style="padding: 15px; color:#999;">No pending sheets.</td></tr>';
                        return;
                    }
                    body.innerHTML = data.files.map(f => {
                        const downloadUrl = pendingUploadsUrl + '?action=download&file=' + encodeURIComponent(f.fileName);
                        return '<tr>' +
                            '<td style="padding: 10px; border-bottom: 1px solid #eee;">' + escapeHtml(f.udiseNo) + '</td>' +
                            '<td style="padding: 10px; border-bottom: 1px solid #eee;">' + escapeHtml(f.schoolName) + '</td>' +
                            '<td style="padding: 10px; border-bottom: 1px solid #eee;">' + escapeHtml(f.uploadedAt) + '</td>' +
                            '<td style="padding: 10px; border-bottom: 1px solid #eee;">' + f.sizeKb + ' KB</td>' +
                            '<td style="padding: 10px; border-bottom: 1px solid #eee;">' +
                                '<a href="' + downloadUrl + '" style="margin-right: 12px; color: #667eea; font-weight: 600; text-decoration: none;">⬇ Download</a>' +
                                '<a href="javascript:void(0);" onclick="deletePendingUpload(\'' + f.fileName.replace(/'/g, "\\'") + '\')" style="color: #c62828; font-weight: 600; text-decoration: none;">🗑 Remove</a>' +
                            '</td>' +
                        '</tr>';
                    }).join('');
                })
                .catch(() => {
                    body.innerHTML = '<tr><td colspan="5" style="padding: 15px; color:#c62828;">Failed to load pending sheets.</td></tr>';
                });
        }

        function deletePendingUpload(fileName) {
            if (!confirm('Remove this sheet from the pending list? This cannot be undone.')) return;
            fetch(pendingUploadsUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({ action: 'delete', file: fileName })
            })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    loadPendingUploads();
                } else {
                    alert(data.message || 'Failed to remove file');
                }
            })
            .catch(err => alert('Failed to remove file: ' + err));
        }

        function escapeHtml(str) {
            const div = document.createElement('div');
            div.textContent = str == null ? '' : str;
            return div.innerHTML;
        }

        loadPendingUploads();

    </script>
<jsp:include page="chatbot-widget.jsp" />
</body>
</html>
