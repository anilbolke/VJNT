<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.model.Student" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.HEAD_MASTER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    
    // Pagination parameters
    int currentPage = 1;
    int pageSize = 10;
    String pageParam = request.getParameter("page");
    if (pageParam != null) {
        try {
            currentPage = Integer.parseInt(pageParam);
        } catch (NumberFormatException e) {
            currentPage = 1;
        }
    }
    
    // Get statistics for this school (UDISE)
    String udiseNo = user.getUdiseNo();
    List<com.vjnt.model.Student> allStudents = studentDAO.getStudentsByUdise(udiseNo);
    int totalStudents = studentDAO.getStudentCountByUdise(udiseNo);
    int totalPages = (int) Math.ceil((double) totalStudents / pageSize);
    
    // Get paginated students
    List<com.vjnt.model.Student> students = studentDAO.getStudentsByUdiseWithPagination(udiseNo, currentPage, pageSize);
    
    // Calculate statistics
    Map<String, Integer> classCount = new HashMap<>();
    Map<String, Integer> sectionCount = new HashMap<>();
    int maleCount = 0, femaleCount = 0;
    
    // Language level statistics - count students at each level
    int marathiNone = 0, marathiLevel1 = 0, marathiLevel2 = 0, marathiLevel3 = 0, marathiLevel4 = 0;
    int mathNone = 0, mathLevel1 = 0, mathLevel2 = 0, mathLevel3 = 0, mathLevel4 = 0, mathLevel5 = 0, mathLevel6 = 0, mathLevel7 = 0;
    int englishNone = 0, englishLevel1 = 0, englishLevel2 = 0, englishLevel3 = 0, englishLevel4 = 0, englishLevel5 = 0;
    
    // Count totals for student numbers
    int marathiShabdaTotal = 0, marathiVakyaTotal = 0, marathiSamajpurvakTotal = 0;
    int mathShabdaTotal = 0, mathVakyaTotal = 0, mathSamajpurvakTotal = 0;
    int englishShabdaTotal = 0, englishVakyaTotal = 0, englishSamajpurvakTotal = 0;
    
    for (com.vjnt.model.Student student : allStudents) {
        String studentClass = student.getStudentClass();
        String section = student.getSection();
        
        if (studentClass != null) {
            classCount.put(studentClass, classCount.getOrDefault(studentClass, 0) + 1);
        }
        if (section != null) {
            sectionCount.put(section, sectionCount.getOrDefault(section, 0) + 1);
        }
        
        String gender = student.getGender();
        if ("Male".equalsIgnoreCase(gender) || "पुरुष".equals(gender)) {
            maleCount++;
        } else if ("Female".equalsIgnoreCase(gender) || "स्त्री".equals(gender)) {
            femaleCount++;
        }
        
        // Count students by Marathi level
        switch (student.getMarathiAksharaLevel()) {
            case 0: marathiNone++; break;
            case 1: marathiLevel1++; break;
            case 2: marathiLevel2++; break;
            case 3: marathiLevel3++; break;
            case 4: marathiLevel4++; break;
        }
        marathiShabdaTotal += student.getMarathiShabdaLevel();
        marathiVakyaTotal += student.getMarathiVakyaLevel();
        marathiSamajpurvakTotal += student.getMarathiSamajpurvakLevel();
        
        // Count students by Math level
        switch (student.getMathAksharaLevel()) {
            case 0: mathNone++; break;
            case 1: mathLevel1++; break;
            case 2: mathLevel2++; break;
            case 3: mathLevel3++; break;
            case 4: mathLevel4++; break;
            case 5: mathLevel5++; break;
            case 6: mathLevel6++; break;
            case 7: mathLevel7++; break;
        }
        mathShabdaTotal += student.getMathShabdaLevel();
        mathVakyaTotal += student.getMathVakyaLevel();
        mathSamajpurvakTotal += student.getMathSamajpurvakLevel();
        
        // Count students by English level
        switch (student.getEnglishAksharaLevel()) {
            case 0: englishNone++; break;
            case 1: englishLevel1++; break;
            case 2: englishLevel2++; break;
            case 3: englishLevel3++; break;
            case 4: englishLevel4++; break;
            case 5: englishLevel5++; break;
        }
        englishShabdaTotal += student.getEnglishShabdaLevel();
        englishVakyaTotal += student.getEnglishVakyaLevel();
        englishSamajpurvakTotal += student.getEnglishSamajpurvakLevel();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>School Dashboard - UDISE <%= udiseNo %></title>
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
            background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
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
        
        .header-info {
            text-align: right;
        }
        
        .user-info {
            font-size: 14px;
            margin-bottom: 5px;
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
        
        .btn-change-password {
            background: rgba(255,255,255,0.2);
            color: white;
        }
        
        .btn-change-password:hover {
            background: rgba(255,255,255,0.3);
        }
        
        .container {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 30px;
        }
        
        .breadcrumb {
            background: white;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }
        
        .breadcrumb span {
            color: #666;
        }
        
        .breadcrumb strong {
            color: #333;
        }
        
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            transition: transform 0.3s;
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 4px 20px rgba(0,0,0,0.12);
        }
        
        .stat-icon {
            font-size: 36px;
            margin-bottom: 10px;
        }
        
        .stat-value {
            font-size: 32px;
            font-weight: bold;
            color: #43e97b;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 14px;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .section {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            margin-bottom: 30px;
        }
        
        .section-title {
            font-size: 20px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #43e97b;
        }
        
        .table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .table th {
            background: #f8f9fa;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #dee2e6;
            font-size: 13px;
        }
        
        .table td {
            padding: 12px;
            border-bottom: 1px solid #dee2e6;
            font-size: 13px;
        }
        
        .table tr:hover {
            background: #f8f9fa;
        }
        
        .table input[type="number"] {
            width: 60px;
            padding: 5px;
            border: 1px solid #dee2e6;
            border-radius: 4px;
            text-align: center;
        }
        
        .level-select {
            width: 140px;
            padding: 6px 8px;
            border: 2px solid #43e97b;
            border-radius: 5px;
            background: white;
            font-size: 12px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .level-select:hover {
            border-color: #38d16b;
            box-shadow: 0 2px 5px rgba(67, 233, 123, 0.3);
        }
        
        .level-select:focus {
            outline: none;
            border-color: #38d16b;
            box-shadow: 0 0 0 3px rgba(67, 233, 123, 0.2);
        }
        
        .level-select option {
            padding: 5px;
        }
        
        .count-input {
            width: 65px;
            padding: 6px;
            border: 1px solid #dee2e6;
            border-radius: 4px;
            text-align: center;
            font-size: 12px;
        }
        
        .count-input:focus {
            outline: none;
            border-color: #43e97b;
            box-shadow: 0 0 0 2px rgba(67, 233, 123, 0.2);
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .badge-primary {
            background: #e3f2fd;
            color: #1976d2;
        }
        
        .badge-success {
            background: #e8f5e9;
            color: #388e3c;
        }
        
        .badge-warning {
            background: #fff3e0;
            color: #f57c00;
        }
        
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 10px;
            margin-top: 20px;
        }
        
        .pagination a, .pagination span {
            padding: 8px 12px;
            border: 1px solid #dee2e6;
            border-radius: 5px;
            text-decoration: none;
            color: #333;
            transition: all 0.3s;
        }
        
        .pagination a:hover {
            background: #43e97b;
            color: white;
            border-color: #43e97b;
        }
        
        .pagination .active {
            background: #43e97b;
            color: white;
            border-color: #43e97b;
        }
        
        .pagination .disabled {
            opacity: 0.5;
            cursor: not-allowed;
            pointer-events: none;
        }
        
        .level-card {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 15px;
        }
        
        .level-title {
            font-size: 16px;
            font-weight: 600;
            color: #333;
            margin-bottom: 10px;
            border-bottom: 2px solid #43e97b;
            padding-bottom: 5px;
        }
        
        .level-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #dee2e6;
        }
        
        .level-row:last-child {
            border-bottom: none;
        }
        
        .level-name {
            font-size: 14px;
            color: #666;
        }
        
        .level-count {
            font-weight: 600;
            color: #43e97b;
        }
        
        .btn-save {
            background: #43e97b;
            color: white;
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
        }
        
        .btn-save:hover {
            background: #38d16b;
        }
        
        .grid-3 {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        
        /* Quick Action Cards */
        .quick-action-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            text-decoration: none;
            color: #333;
            transition: all 0.3s;
            cursor: pointer;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            display: block;
        }
        
        .quick-action-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.2);
        }
        
        .quick-action-disabled {
            opacity: 0.6;
            cursor: not-allowed;
        }
        
        .quick-action-disabled:hover {
            transform: none;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        
        .quick-action-icon {
            font-size: 48px;
            margin-bottom: 15px;
        }
        
        .quick-action-title {
            font-size: 18px;
            font-weight: 600;
            color: #667eea;
            margin-bottom: 5px;
        }
        
        .quick-action-subtitle {
            font-size: 14px;
            color: #666;
            margin-bottom: 10px;
        }
        
        .quick-action-desc {
            font-size: 13px;
            color: #888;
            line-height: 1.5;
        }
    </style>
    <script>
        function changePhase() {
            const phaseSelector = document.getElementById('phaseSelector');
            const selectedPhase = phaseSelector.value;
            const currentUrl = new URL(window.location.href);
            currentUrl.searchParams.set('phase', selectedPhase);
            currentUrl.searchParams.set('page', '1'); // Reset to first page
            window.location.href = currentUrl.toString();
        }
        
        function updateLanguageLevels(studentId) {
            console.log('Updating student ID:', studentId);
            
            // Get the values directly from select elements
            const marathiSelect = document.querySelector('#row-' + studentId + ' select[name="marathi_akshara"]');
            const mathSelect = document.querySelector('#row-' + studentId + ' select[name="math_akshara"]');
            const englishSelect = document.querySelector('#row-' + studentId + ' select[name="english_akshara"]');
            
            console.log('Marathi Select:', marathiSelect, 'Value:', marathiSelect ? marathiSelect.value : 'NULL');
            console.log('Math Select:', mathSelect, 'Value:', mathSelect ? mathSelect.value : 'NULL');
            console.log('English Select:', englishSelect, 'Value:', englishSelect ? englishSelect.value : 'NULL');
            
            // Validate elements exist
            if (!marathiSelect || !mathSelect || !englishSelect) {
                alert('Error: Could not find dropdown elements');
                return;
            }
            
            // Get current phase
            const phaseSelector = document.getElementById('phaseSelector');
            const currentPhase = phaseSelector ? phaseSelector.value : '1';
            
            // Create URL-encoded form data
            const params = new URLSearchParams();
            params.append('studentId', studentId);
            params.append('marathi_akshara', marathiSelect.value);
            params.append('math_akshara', mathSelect.value);
            params.append('english_akshara', englishSelect.value);
            params.append('phase', currentPhase);
            
            // Debug - log what we're sending
            console.log('Sending data:');
            console.log('studentId: ' + studentId);
            console.log('marathi_akshara: ' + marathiSelect.value);
            console.log('math_akshara: ' + mathSelect.value);
            console.log('english_akshara: ' + englishSelect.value);
            console.log('URL params: ' + params.toString());
            
            // Show loading indicator
            const btn = event.target;
            btn.disabled = true;
            btn.textContent = 'Saving...';
            
            // Send AJAX request with URL-encoded data
            fetch('<%= request.getContextPath() %>/update-language-levels', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: params.toString()
            })
            .then(response => response.json())
            .then(data => {
                console.log('Response:', data);
                if (data.success) {
                    btn.textContent = 'Saved ✓';
                    btn.style.background = '#4caf50';
                    
                    // Check if phase is complete
                    if (data.phaseComplete) {
                        console.log('Phase is now complete! Disabling all save buttons...');
                        
                        // Show phase completion message
                        alert('🎉 Phase ' + document.getElementById('phaseSelector').value + ' completed for all students!\n\nAll save buttons have been disabled for this phase.\n\nPlease refresh the page to proceed to the next phase.');
                        
                        // Disable all save buttons
                        const allSaveBtns = document.querySelectorAll('.btn-save');
                        allSaveBtns.forEach(button => {
                            button.disabled = true;
                            button.textContent = '✓ Phase Complete';
                            button.style.background = '#9e9e9e';
                            button.style.cursor = 'not-allowed';
                        });
                        
                        // Disable phase selector
                        const phaseSelector = document.getElementById('phaseSelector');
                        if (phaseSelector) {
                            phaseSelector.disabled = true;
                        }
                        
                        // Disable all dropdowns
                        const allDropdowns = document.querySelectorAll('.level-select');
                        allDropdowns.forEach(dropdown => {
                            dropdown.disabled = true;
                        });
                    } else {
                        setTimeout(() => {
                            btn.textContent = 'Save';
                            btn.style.background = '#43e97b';
                            btn.disabled = false;
                        }, 2000);
                    }
                } else {
                    alert('Error: ' + data.message);
                    btn.textContent = 'Save';
                    btn.disabled = false;
                }
            })
            .catch(error => {
                console.error('Fetch error:', error);
                alert('Error updating language levels: ' + error);
                btn.textContent = 'Save';
                btn.disabled = false;
            });
        }
    </script>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div>
                <h1>🏫 VJNT Class Management System</h1>
                <p>School Dashboard - UDISE <%= udiseNo %></p>
            </div>
            <div class="header-info">
                <div class="user-info">
                    Welcome, <strong><%= user.getFullName() %></strong>
                </div>
                <div class="user-info">
                    Role: <strong><%= user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) ? "School Coordinator" : "Head Master" %></strong>
                </div>
                <a href="<%= request.getContextPath() %>/change-password" class="btn btn-change-password">Change Password</a>
                <a href="<%= request.getContextPath() %>/logout" class="btn btn-logout">Logout</a>
            </div>
        </div>
    </div>
    
    <div class="container">
        <!-- Breadcrumb -->
        <div class="breadcrumb">
            <span>Division:</span> <strong><%= user.getDivisionName() %></strong> 
            <span style="margin: 0 10px;">→</span> 
            <span>District:</span> <strong><%= user.getDistrictName() %></strong>
            <span style="margin: 0 10px;">→</span>
            <span>School UDISE:</span> <strong><%= udiseNo %></strong>
        </div>
        
        <!-- Statistics Cards -->
        <div class="dashboard-grid">
            <div class="stat-card">
                <div class="stat-icon">👥</div>
                <div class="stat-value"><%= totalStudents %></div>
                <div class="stat-label">Total Students</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">📚</div>
                <div class="stat-value"><%= classCount.size() %></div>
                <div class="stat-label">Classes</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">📋</div>
                <div class="stat-value"><%= sectionCount.size() %></div>
                <div class="stat-label">Sections</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">👨‍🎓</div>
                <div class="stat-value"><%= maleCount %></div>
                <div class="stat-label">Male Students</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">👩‍🎓</div>
                <div class="stat-value"><%= femaleCount %></div>
                <div class="stat-label">Female Students</div>
            </div>
        </div>
        
        <!-- Quick Actions -->
        <div class="section" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
            <h2 class="section-title" style="color: white; border-bottom: 2px solid rgba(255,255,255,0.3);">⚡ त्वरित कृती (Quick Actions)</h2>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px;">
                <a href="<%= request.getContextPath() %>/manage-students.jsp" class="quick-action-card">
                    <div class="quick-action-icon">📋</div>
                    <div class="quick-action-title">विद्यार्थी यादी व्यवस्थापन</div>
                    <div class="quick-action-subtitle">Manage Student List</div>
                    <div class="quick-action-desc">View and update student language levels by phase</div>
                </a>
                
                <div class="quick-action-card quick-action-disabled">
                    <div class="quick-action-icon">📊</div>
                    <div class="quick-action-title">प्रगती अहवाल</div>
                    <div class="quick-action-subtitle">Progress Reports</div>
                    <div class="quick-action-desc">Generate and view detailed reports</div>
                    <div style="margin-top: 10px; font-size: 11px; opacity: 0.7;">Coming Soon</div>
                </div>
                
                <div class="quick-action-card quick-action-disabled">
                    <div class="quick-action-icon">🎯</div>
                    <div class="quick-action-title">लक्ष्य ट्रॅकिंग</div>
                    <div class="quick-action-subtitle">Goal Tracking</div>
                    <div class="quick-action-desc">Monitor phase completion targets</div>
                    <div style="margin-top: 10px; font-size: 11px; opacity: 0.7;">Coming Soon</div>
                </div>
            </div>
        </div>
        
        <!-- Language Proficiency Summary -->
        <div class="section">
            <h2 class="section-title">📊 भाषा स्तर सांख्यिकी (Language Proficiency Statistics)</h2>
            <div class="grid-3">
                <!-- Marathi -->
                <div class="level-card">
                    <div class="level-title">🇮🇳 मराठी भाषा स्तर</div>
                    <div class="level-row">
                        <span class="level-name">निरांक</span>
                        <span class="level-count"><%= marathiNone %> विद्यार्थी</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">अक्षर स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)</span>
                        <span class="level-count"><%= marathiLevel1 %> विद्यार्थी</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">शब्द स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)</span>
                        <span class="level-count"><%= marathiLevel2 %> विद्यार्थी</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">वाक्य स्तरावरील विद्यार्थी संख्या</span>
                        <span class="level-count"><%= marathiLevel3 %> विद्यार्थी</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">समजपुर्वक उतार वाचन स्तरावरील विद्यार्थी संख्या</span>
                        <span class="level-count"><%= marathiLevel4 %> विद्यार्थी</span>
                    </div>
                    <hr style="margin: 10px 0; border: none; border-top: 1px solid #dee2e6;">
                    <div class="level-row">
                        <span class="level-name">एकूण विद्यार्थी संख्या</span>
                        <span class="level-count"><%= totalStudents %></span>
                    </div>
                </div>
                
                <!-- Math -->
                <div class="level-card">
                    <div class="level-title">🔢 गणित स्तर</div>
                    <div class="level-row">
                        <span class="level-name">निरांक</span>
                        <span class="level-count"><%= mathNone %> विद्यार्थी</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">प्रारंभीक स्तरावरील विद्यार्थी संख्या</span>
                        <span class="level-count"><%= mathLevel1 %> विद्यार्थी</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">अंक स्तरावरील विद्यार्थी संख्या</span>
                        <span class="level-count"><%= mathLevel2 %> विद्यार्थी</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">संख्या वाचन स्तरावरील विद्यार्थी संख्या</span>
                        <span class="level-count"><%= mathLevel3 %> विद्यार्थी</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">बेरीज स्तरावरील विद्यार्थी संख्या</span>
                        <span class="level-count"><%= mathLevel4 %> विद्यार्थी</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">वजाबाकी स्तरावरील विद्यार्थी संख्या</span>
                        <span class="level-count"><%= mathLevel5 %> विद्यार्थी</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">गुणाकार स्तरावरील विद्यार्थी संख्या</span>
                        <span class="level-count"><%= mathLevel6 %> विद्यार्थी</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">भागाकर स्तरावरील विद्यार्थी संख्या</span>
                        <span class="level-count"><%= mathLevel7 %> विद्यार्थी</span>
                    </div>
                    <hr style="margin: 10px 0; border: none; border-top: 1px solid #dee2e6;">
                    <div class="level-row">
                        <span class="level-name">एकूण विद्यार्थी संख्या</span>
                        <span class="level-count"><%= totalStudents %></span>
                    </div>
                </div>
                
                <!-- English -->
                <div class="level-card">
                    <div class="level-title">🇬🇧 इंग्रजी स्तर</div>
                    <div class="level-row">
                        <span class="level-name">NA</span>
                        <span class="level-count"><%= englishNone %> Students</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">BEGINER LEVEL</span>
                        <span class="level-count"><%= englishLevel1 %> Students</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">ALPHABET LEVEL Reading and Writing</span>
                        <span class="level-count"><%= englishLevel2 %> Students</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">WORD LEVEL Reading and Writing</span>
                        <span class="level-count"><%= englishLevel3 %> Students</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">SENTENCE LEVEL</span>
                        <span class="level-count"><%= englishLevel4 %> Students</span>
                    </div>
                    <div class="level-row">
                        <span class="level-name">Paragraph Reading with Understanding</span>
                        <span class="level-count"><%= englishLevel5 %> Students</span>
                    </div>
                    <hr style="margin: 10px 0; border: none; border-top: 1px solid #dee2e6;">
                    <div class="level-row">
                        <span class="level-name">Total Student Count</span>
                        <span class="level-count"><%= totalStudents %></span>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Student List Section REMOVED - Now available via Quick Action -->
        <!-- Use the "Manage Student List" quick action button above to access this feature -->
        <!--
        <div class="section">
            <h2 class="section-title">📋 विद्यार्थी यादी आणि भाषा स्तर व्यवस्थापन (Student List & Language Level Management)</h2>
            
            <!-- Debug Information -->
            <div style="background: #fff3cd; border: 1px solid #ffc107; padding: 10px; margin-bottom: 15px; border-radius: 5px;">
                <strong>🔍 Debug Info:</strong><br>
                UDISE Number: <code><%= udiseNo %></code><br>
                Total Students: <strong><%= totalStudents %></strong><br>
                Students List Size: <strong><%= students != null ? students.size() : 0 %></strong><br>
                All Students Size: <strong><%= allStudents != null ? allStudents.size() : 0 %></strong>
            </div>
            
            <%
            // Check phase completion status
            StudentDAO phaseDAO = new StudentDAO();
            boolean phase1Complete = phaseDAO.isPhaseComplete(udiseNo, 1);
            boolean phase2Complete = phaseDAO.isPhaseComplete(udiseNo, 2);
            boolean phase3Complete = phaseDAO.isPhaseComplete(udiseNo, 3);
            boolean phase4Complete = phaseDAO.isPhaseComplete(udiseNo, 4);
            
            // Get current selected phase from request parameter (default to Phase 1)
            String selectedPhaseStr = request.getParameter("phase");
            int selectedPhase = 1;
            if (selectedPhaseStr != null) {
                try {
                    selectedPhase = Integer.parseInt(selectedPhaseStr);
                } catch (NumberFormatException e) {
                    selectedPhase = 1;
                }
            }
            
            // Check if current selected phase is complete
            boolean currentPhaseComplete = false;
            switch(selectedPhase) {
                case 1: currentPhaseComplete = phase1Complete; break;
                case 2: currentPhaseComplete = phase2Complete; break;
                case 3: currentPhaseComplete = phase3Complete; break;
                case 4: currentPhaseComplete = phase4Complete; break;
            }
            %>
            
            <!-- Phase Selection -->
            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <label style="font-weight: 600; font-size: 16px; color: #333; margin-right: 15px;">
                            📊 Select Phase (चरण निवडा):
                        </label>
                        <select id="phaseSelector" onchange="changePhase()" style="padding: 10px 15px; border: 2px solid #43e97b; border-radius: 5px; font-size: 14px; font-weight: 500; min-width: 150px;">
                            <option value="1" <%= selectedPhase == 1 ? "selected" : "" %> <%= phase1Complete ? "disabled" : "" %>>Phase 1 <%= phase1Complete ? "✓ Completed" : "" %></option>
                            <option value="2" <%= selectedPhase == 2 ? "selected" : "" %> <%= !phase1Complete || phase2Complete ? "disabled" : "" %>>Phase 2 <%= phase2Complete ? "✓ Completed" : "" %></option>
                            <option value="3" <%= selectedPhase == 3 ? "selected" : "" %> <%= !phase2Complete || phase3Complete ? "disabled" : "" %>>Phase 3 <%= phase3Complete ? "✓ Completed" : "" %></option>
                            <option value="4" <%= selectedPhase == 4 ? "selected" : "" %> <%= !phase3Complete || phase4Complete ? "disabled" : "" %>>Phase 4 <%= phase4Complete ? "✓ Completed" : "" %></option>
                        </select>
                    </div>
                    <div>
                        <span style="font-size: 14px; color: #666;">
                            Current Phase: <strong style="color: #43e97b;">Phase <%= selectedPhase %></strong>
                        </span>
                    </div>
                </div>
                
                <!-- Phase Status Indicators -->
                <div style="margin-top: 15px; display: flex; gap: 10px;">
                    <span style="padding: 5px 12px; border-radius: 15px; font-size: 12px; <%= phase1Complete ? "background: #4caf50; color: white;" : "background: #fff3e0; color: #f57c00;" %>">
                        Phase 1: <%= phase1Complete ? "✓ Complete" : "⏳ In Progress" %>
                    </span>
                    <span style="padding: 5px 12px; border-radius: 15px; font-size: 12px; <%= phase2Complete ? "background: #4caf50; color: white;" : "background: #e0e0e0; color: #666;" %>">
                        Phase 2: <%= phase2Complete ? "✓ Complete" : (phase1Complete ? "⏳ Available" : "🔒 Locked") %>
                    </span>
                    <span style="padding: 5px 12px; border-radius: 15px; font-size: 12px; <%= phase3Complete ? "background: #4caf50; color: white;" : "background: #e0e0e0; color: #666;" %>">
                        Phase 3: <%= phase3Complete ? "✓ Complete" : (phase2Complete ? "⏳ Available" : "🔒 Locked") %>
                    </span>
                    <span style="padding: 5px 12px; border-radius: 15px; font-size: 12px; <%= phase4Complete ? "background: #4caf50; color: white;" : "background: #e0e0e0; color: #666;" %>">
                        Phase 4: <%= phase4Complete ? "✓ Complete" : (phase3Complete ? "⏳ Available" : "🔒 Locked") %>
                    </span>
                </div>
            </div>
            
            <% if (currentPhaseComplete) { %>
            <!-- Phase Complete Notification -->
            <div style="background: #4caf50; color: white; padding: 15px 20px; border-radius: 8px; margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <strong style="font-size: 16px;">✓ Phase <%= selectedPhase %> Completed!</strong>
                    <p style="margin: 5px 0 0 0; font-size: 14px;">All students have been assigned language levels for this phase. Data is now read-only.</p>
                </div>
                <span style="font-size: 24px;">🎉</span>
            </div>
            <% } %>
            
            <p style="margin-bottom: 15px; color: #666;">
                Showing <%= (currentPage - 1) * pageSize + 1 %> to <%= Math.min(currentPage * pageSize, totalStudents) %> of <%= totalStudents %> students
                <% if (currentPhaseComplete) { %>
                <span style="color: #4caf50; font-weight: 600; margin-left: 10px;">● Phase <%= selectedPhase %> Complete</span>
                <% } %>
            </p>
            
            <div style="overflow-x: auto;">
                <table class="table">
                    <thead>
                        <tr>
                            <th style="vertical-align: middle;">PEN</th>
                            <th style="vertical-align: middle;">Name</th>
                            <th style="vertical-align: middle;">Class</th>
                            <th style="vertical-align: middle;">Section</th>
                            <th style="text-align: center; background: #fff3e0;">🇮🇳 मराठी भाषा स्तर</th>
                            <th style="text-align: center; background: #e3f2fd;">🔢 गणित स्तर</th>
                            <th style="text-align: center; background: #f3e5f5;">🇬🇧 इंग्रजी स्तर</th>
                            <th style="vertical-align: middle;">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% 
                        for (com.vjnt.model.Student s : students) {
                        %>
                        <tr id="row-<%= s.getStudentId() %>">
                            <td><%= s.getStudentPen() != null ? s.getStudentPen() : "N/A" %></td>
                            <td><strong><%= s.getStudentName() %></strong></td>
                            <td><%= s.getStudentClass() %></td>
                            <td><%= s.getSection() %></td>
                            <!-- Marathi Levels -->
                            <td>
                                <select name="marathi_akshara" class="level-select" <%= currentPhaseComplete ? "disabled" : "" %>>
                                    <option value="0" <%= s.getMarathiAksharaLevel() == 0 ? "selected" : "" %>>निरांक</option>
                                    <option value="1" <%= s.getMarathiAksharaLevel() == 1 ? "selected" : "" %>>अक्षर स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)</option>
                                    <option value="2" <%= s.getMarathiAksharaLevel() == 2 ? "selected" : "" %>>शब्द स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)</option>
                                    <option value="3" <%= s.getMarathiAksharaLevel() == 3 ? "selected" : "" %>>वाक्य स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="4" <%= s.getMarathiAksharaLevel() == 4 ? "selected" : "" %>>समजपुर्वक उतार वाचन स्तरावरील विद्यार्थी संख्या</option>
                                </select>
                            </td>
                            <!-- Math Levels -->
                            <td>
                                <select name="math_akshara" class="level-select" <%= currentPhaseComplete ? "disabled" : "" %>>
                                    <option value="0" <%= s.getMathAksharaLevel() == 0 ? "selected" : "" %>>निरांक</option>
                                    <option value="1" <%= s.getMathAksharaLevel() == 1 ? "selected" : "" %>>प्रारंभीक स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="2" <%= s.getMathAksharaLevel() == 2 ? "selected" : "" %>>अंक स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="3" <%= s.getMathAksharaLevel() == 3 ? "selected" : "" %>>संख्या वाचन स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="4" <%= s.getMathAksharaLevel() == 4 ? "selected" : "" %>>बेरीज स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="5" <%= s.getMathAksharaLevel() == 5 ? "selected" : "" %>>वजाबाकी स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="6" <%= s.getMathAksharaLevel() == 6 ? "selected" : "" %>>गुणाकार स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="7" <%= s.getMathAksharaLevel() == 7 ? "selected" : "" %>>भागाकर स्तरावरील विद्यार्थी संख्या</option>
                                </select>
                            </td>
                            <!-- English Levels -->
                            <td>
                                <select name="english_akshara" class="level-select" <%= currentPhaseComplete ? "disabled" : "" %>>
                                    <option value="0" <%= s.getEnglishAksharaLevel() == 0 ? "selected" : "" %>>NA</option>
                                    <option value="1" <%= s.getEnglishAksharaLevel() == 1 ? "selected" : "" %>>BEGINER LEVEL</option>
                                    <option value="2" <%= s.getEnglishAksharaLevel() == 2 ? "selected" : "" %>>ALPHABET LEVEL Reading and Writing</option>
                                    <option value="3" <%= s.getEnglishAksharaLevel() == 3 ? "selected" : "" %>>WORD LEVEL Reading and Writing</option>
                                    <option value="4" <%= s.getEnglishAksharaLevel() == 4 ? "selected" : "" %>>SENTENCE LEVEL</option>
                                    <option value="5" <%= s.getEnglishAksharaLevel() == 5 ? "selected" : "" %>>Paragraph Reading with Understanding</option>
                                </select>
                            </td>
                            <td>
                                <% if (currentPhaseComplete) { %>
                                    <button type="button" class="btn-save" disabled style="background: #9e9e9e; cursor: not-allowed;">✓ Complete</button>
                                <% } else { %>
                                    <button type="button" class="btn-save" onclick="updateLanguageLevels(<%= s.getStudentId() %>)">Save</button>
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
            
            <!-- Pagination -->
            <div class="pagination">
                <% if (currentPage > 1) { %>
                    <a href="?page=1">First</a>
                    <a href="?page=<%= currentPage - 1 %>">Previous</a>
                <% } else { %>
                    <span class="disabled">First</span>
                    <span class="disabled">Previous</span>
                <% } %>
                
                <% 
                int startPage = Math.max(1, currentPage - 2);
                int endPage = Math.min(totalPages, currentPage + 2);
                for (int i = startPage; i <= endPage; i++) {
                    if (i == currentPage) {
                %>
                    <span class="active"><%= i %></span>
                <% } else { %>
                    <a href="?page=<%= i %>"><%= i %></a>
                <% 
                    }
                }
                %>
                
                <% if (currentPage < totalPages) { %>
                    <a href="?page=<%= currentPage + 1 %>">Next</a>
                    <a href="?page=<%= totalPages %>">Last</a>
                <% } else { %>
                    <span class="disabled">Next</span>
                    <span class="disabled">Last</span>
                <% } %>
            </div>
        </div>
        -->
        <!-- End of commented student list section -->
    </div>
</body>
</html>
