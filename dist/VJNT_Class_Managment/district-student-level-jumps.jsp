<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.model.Student" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.stream.Collectors" %>

<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                        !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String districtName = user.getDistrictName();
    StudentDAO studentDAO = new StudentDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    
    // Get all active students from district
    List<Student> allStudents = studentDAO.getStudentsByDistrict(districtName);
    
    // Filter: Keep only students with level jumps (>1 level difference in any subject/phase transition)
    List<Student> levelJumpStudents = new ArrayList<>();
    
    for (Student student : allStudents) {
        boolean hasLevelJump = false;
        
        // Check Marathi jumps
        if (student.getPhase1Marathi() != null && student.getPhase2Marathi() != null) {
            if (student.getPhase2Marathi() - student.getPhase1Marathi() > 1) {
                hasLevelJump = true;
            }
        }
        if (student.getPhase2Marathi() != null && student.getPhase3Marathi() != null) {
            if (student.getPhase3Marathi() - student.getPhase2Marathi() > 1) {
                hasLevelJump = true;
            }
        }
        if (student.getPhase3Marathi() != null && student.getPhase4Marathi() != null) {
            if (student.getPhase4Marathi() - student.getPhase3Marathi() > 1) {
                hasLevelJump = true;
            }
        }
        
        // Check Math jumps
        if (student.getPhase1Math() != null && student.getPhase2Math() != null) {
            if (student.getPhase2Math() - student.getPhase1Math() > 1) {
                hasLevelJump = true;
            }
        }
        if (student.getPhase2Math() != null && student.getPhase3Math() != null) {
            if (student.getPhase3Math() - student.getPhase2Math() > 1) {
                hasLevelJump = true;
            }
        }
        if (student.getPhase3Math() != null && student.getPhase4Math() != null) {
            if (student.getPhase4Math() - student.getPhase3Math() > 1) {
                hasLevelJump = true;
            }
        }
        
        // Check English jumps
        if (student.getPhase1English() != null && student.getPhase2English() != null) {
            if (student.getPhase2English() - student.getPhase1English() > 1) {
                hasLevelJump = true;
            }
        }
        if (student.getPhase2English() != null && student.getPhase3English() != null) {
            if (student.getPhase3English() - student.getPhase2English() > 1) {
                hasLevelJump = true;
            }
        }
        if (student.getPhase3English() != null && student.getPhase4English() != null) {
            if (student.getPhase4English() - student.getPhase3English() > 1) {
                hasLevelJump = true;
            }
        }
        
        if (hasLevelJump) {
            levelJumpStudents.add(student);
        }
    }
    
    // Cache school names to avoid repeated database lookups
    Map<String, String> schoolNameCache = new HashMap<>();
    
    // Create maps for total counts (all students) by school and class
    Map<String, Integer> schoolTotalCounts = new HashMap<>();  // schoolName -> total count
    Map<String, Map<String, Integer>> classTotalCounts = new HashMap<>();  // schoolName -> (className -> total count)
    
    // First pass: Count ALL students by school and class
    for (Student student : allStudents) {
        String udiseNo = student.getUdiseNo();
        String schoolName = schoolNameCache.get(udiseNo);
        
        if (schoolName == null) {
            schoolName = udiseNo;
            School school = schoolDAO.getSchoolByUdise(udiseNo);
            if (school != null) {
                schoolName = school.getSchoolName() + " (" + udiseNo + ")";
            }
            schoolNameCache.put(udiseNo, schoolName);
        }
        
        String studentClass = student.getStudentClass() != null ? student.getStudentClass() : "N/A";
        
        // Count by school
        schoolTotalCounts.put(schoolName, schoolTotalCounts.getOrDefault(schoolName, 0) + 1);
        
        // Count by class within school
        classTotalCounts.computeIfAbsent(schoolName, k -> new HashMap<>())
                       .put(studentClass, classTotalCounts.get(schoolName).getOrDefault(studentClass, 0) + 1);
    }
    
    // Group JUMPED students by School, then by Class, then by Section
    Map<String, Map<String, Map<String, List<Student>>>> groupedStudents = new TreeMap<>();
    
    for (Student student : levelJumpStudents) {
        String udiseNo = student.getUdiseNo();
        String schoolName = schoolNameCache.get(udiseNo);
        
        if (schoolName == null) {
            schoolName = udiseNo;
            School school = schoolDAO.getSchoolByUdise(udiseNo);
            if (school != null) {
                schoolName = school.getSchoolName() + " (" + udiseNo + ")";
            }
            schoolNameCache.put(udiseNo, schoolName);
        }
        
        String studentClass = student.getStudentClass() != null ? student.getStudentClass() : "N/A";
        String section = student.getSection() != null ? student.getSection() : "N/A";
        
        groupedStudents.computeIfAbsent(schoolName, k -> new TreeMap<>())
                      .computeIfAbsent(studentClass, k -> new TreeMap<>())
                      .computeIfAbsent(section, k -> new ArrayList<>())
                      .add(student);
    }
%>

<%!
    // Level descriptions from manage-students.jsp
    
    // Helper function to get Marathi level description
    String getMarathiLevelDescription(Integer level) {
        String[] marathiLevels = {"स्थर निश्चित केला नाही", "प्रारंभिक स्तर", "अक्षर स्तर", "शब्द स्तर", "वाक्य स्तर", "समजपूर्वक उतारा वाचन स्तर", "मराठी वाचन व लेखन FLN स्तर 100% पूर्ण"};
        if (level == null || level < 0 || level >= marathiLevels.length) return "N/A";
        return marathiLevels[level];
    }
    
    // Helper function to get Math level description
    String getMathLevelDescription(Integer level) {
        String[] mathLevels = {"स्तर निश्चित केला नाही", "प्रारंभिक स्तर", "अंक ज्ञान स्तर", "संख्याज्ञान स्तर", "बेरीज स्तर", "वजाबाकी स्तर", "गुणाकार स्तर", "भागाकार स्तर", "गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण"};
        if (level == null || level < 0 || level >= mathLevels.length) return "N/A";
        return mathLevels[level];
    }
    
    // Helper function to get English level description
    String getEnglishLevelDescription(Integer level) {
        String[] englishLevels = {"स्तर निश्चित केला नाही", "Beginner level", "Alphabet level", "Word level", "Sentence level", "Paragraph Reading with Understanding"};
        if (level == null || level < 0 || level >= englishLevels.length) return "N/A";
        return englishLevels[level];
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Level Jumps - District Management</title>
    <style type="text/css">
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 15px;
        }
        
        .container {
            max-width: 1800px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgb(0,0,0,0.3);
            padding: 25px;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 25px;
            border-radius: 10px;
            margin-bottom: 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 5px;
        }
        
        .header p {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .header-right {
            text-align: right;
        }
        
        .stats {
            display: flex;
            gap: 20px;
            margin-bottom: 25px;
            flex-wrap: wrap;
        }
        
        .stat-card {
            background: #f8f9fa;
            padding: 15px 20px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        
        .stat-label {
            font-size: 12px;
            color: #666;
            margin-bottom: 5px;
        }
        
        .stat-value {
            font-size: 24px;
            font-weight: bold;
            color: #667eea;
        }
        
        .school-section {
            margin-bottom: 30px;
            border: 1px solid #e0e0e0;
            border-radius: 10px;
            overflow: hidden;
        }
        
        .school-header {
            background: #f0f2f5;
            padding: 15px 20px;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-weight: 600;
            color: #333;
        }
        
        .school-header:hover {
            background: #e8eaef;
        }
        
        .school-toggle {
            font-size: 18px;
        }
        
        .class-section {
            margin: 0;
            border-bottom: 1px solid #e0e0e0;
            background: #ffffff;
        }
        
        .class-header {
            background: #f8f9fa;
            padding: 12px 20px;
            padding-left: 40px;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-weight: 500;
            color: #555;
        }
        
        .class-header:hover {
            background: #f0f2f5;
        }
        
        .section-header {
            background: white;
            padding: 10px 20px;
            padding-left: 60px;
            font-weight: 500;
            color: #666;
            border-bottom: 1px solid #eee;
        }
        
        .student-table {
            width: 100%;
            border-collapse: collapse;
            margin: 0;
        }
        
        .student-table thead {
            background: #f0f2f5;
        }
        
        .student-table th {
            padding: 12px 15px;
            text-align: left;
            font-size: 13px;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #ddd;
        }
        
        .student-table td {
            padding: 12px 15px;
            border-bottom: 1px solid #eee;
            font-size: 13px;
        }
        
        .student-table tbody tr:hover {
            background: #f9f9f9;
        }
        
        .phase-box {
            background: #f8f9fa;
            padding: 8px 12px;
            border-radius: 5px;
            margin: 3px 0;
            font-size: 12px;
        }
        
        .phase-title {
            font-weight: 600;
            color: #333;
            margin-bottom: 3px;
        }
        
        .level-jump {
            color: #fff;
            background: #d32f2f;
            padding: 6px 10px;
            border-radius: 20px;
            font-weight: 700;
            box-shadow: 0 2px 8px rgb(211, 47, 47, 0.3);
            animation: jumpPulse 2s infinite;
        }
        
        @keyframes jumpPulse {
            0%, 100% {
                box-shadow: 0 2px 8px rgb(211, 47, 47, 0.3);
            }
            50% {
                box-shadow: 0 4px 12px rgb(211, 47, 47, 0.6);
            }
        }
        
        .level-normal {
            color: #388e3c;
            background: #e8f5e9;
            padding: 4px 8px;
            border-radius: 15px;
            font-weight: 600;
        }
        
        .level-description {
            font-size: 11px;
            color: #666;
            margin-top: 4px;
            font-weight: normal;
        }
        
        .jump-badge {
            display: inline-block;
            background: #d32f2f;
            color: white;
            padding: 3px 8px;
            border-radius: 10px;
            font-size: 10px;
            font-weight: 700;
            margin-left: 8px;
            animation: jumpBlink 1.5s infinite;
        }
        
        @keyframes jumpBlink {
            0%, 100% {
                opacity: 1;
            }
            50% {
                opacity: 0.6;
            }
        }
        
        .progression-row {
            display: flex;
            align-items: center;
            gap: 8px;
            margin: 6px 0;
            padding: 8px;
            background: #fafafa;
            border-radius: 5px;
        }
        
        .progression-arrow {
            color: #999;
            font-weight: bold;
        }
        
        .level-box {
            min-width: 120px;
            text-align: center;
        }
        
        .empty-state {
            text-align: center;
            padding: 40px 20px;
            color: #999;
        }
        
        .empty-state-icon {
            font-size: 48px;
            margin-bottom: 15px;
        }
        
        .toggle-all {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }
        
        .toggle-btn {
            padding: 8px 15px;
            border: none;
            border-radius: 5px;
            background: #667eea;
            color: white;
            cursor: pointer;
            font-size: 13px;
            transition: background 0.3s;
        }
        
        .toggle-btn:hover {
            background: #764ba2;
        }
        
        .content {
            display: none;
        }
        
        .content.show {
            display: table;
        }
        
        .class-content {
            display: none;
        }
        
        .class-content.show {
            display: block;
        }
        
        .jump-indicator {
            display: inline-block;
            width: 8px;
            height: 8px;
            background: #d32f2f;
            border-radius: 50%;
            margin-left: 5px;
        }
        
        /* School Search Dropdown Styles */
        #schoolDropdownList > div {
            padding: 10px 12px;
            cursor: pointer;
            border-bottom: 1px solid #f0f0f0;
            transition: background-color 0.2s;
            font-size: 14px;
        }
        
        #schoolDropdownList > div:first-child {
            font-weight: 600;
            background-color: #f8f9fa;
        }
        
        #schoolDropdownList > div:hover {
            background-color: #e8eaf6;
            color: #667eea;
        }
        
        #schoolDropdownList > div:last-child {
            border-bottom: none;
        }
        
        #schoolSearchInput {
            transition: border-color 0.3s;
        }
        
        #schoolSearchInput:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 5px rgba(102, 126, 234, 0.3);
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div>
                <h1>📊 Student Level Jump Analysis</h1>
                <p>District: <strong><%= districtName %></strong></p>
            </div>
            <div class="header-right">
                <a href="<%= request.getContextPath() %>/district-dashboard.jsp" style="display: inline-block; padding: 10px 20px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin-right: 15px; font-weight: 600; cursor: pointer; border: none;">← Back to Dashboard</a>
                <p style="margin-bottom: 5px;">Last Updated: <strong><%= new java.text.SimpleDateFormat("dd-MMM-yyyy HH:mm").format(new java.util.Date()) %></strong></p>
            </div>
        </div>
        
        <!-- Statistics -->
        <div class="stats">
            <div class="stat-card">
                <div class="stat-label">📍 Total Schools</div>
                <div class="stat-value"><%= groupedStudents.size() %></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">👥 Students with Level Jumps</div>
                <div class="stat-value"><%= levelJumpStudents.size() %></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">📈 Total Students in District</div>
                <div class="stat-value"><%= allStudents.size() %></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">⚠️ Jump Percentage</div>
                <div class="stat-value"><%= allStudents.size() > 0 ? String.format("%.1f%%", (levelJumpStudents.size() * 100.0) / allStudents.size()) : "0%" %></div>
            </div>
        </div>
        
        <!-- Filter Section -->
        <div style="background: #f8f9fa; padding: 20px; border-radius: 10px; margin-bottom: 25px; border: 1px solid #e0e0e0;">
            <h3 style="margin-bottom: 15px; color: #333;">🔍 Filters</h3>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px;">
                <!-- Student Name Filter -->
                <div>
                    <label style="display: block; font-weight: 600; margin-bottom: 5px; color: #555;">Student Name:</label>
                    <input type="text" id="filterStudentName" placeholder="Search by student name..." 
                           style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;">
                </div>
                
                <!-- School Filter with Search -->
                <div>
                    <label style="display: block; font-weight: 600; margin-bottom: 5px; color: #555;">School:</label>
                    <div style="position: relative;">
                        <input type="text" id="schoolSearchInput" placeholder="🔍 Search school name..." 
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px; box-sizing: border-box;">
                        <select id="filterSchool" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px; display: none;">
                            <option value="">-- All Schools --</option>
                            <% for (String schoolName : groupedStudents.keySet()) { %>
                                <option value="<%= schoolName %>"><%= schoolName %></option>
                            <% } %>
                        </select>
                        <div id="schoolDropdownList" style="position: absolute; top: 100%; left: 0; right: 0; background: white; border: 1px solid #ddd; border-top: none; border-radius: 0 0 5px 5px; max-height: 250px; overflow-y: auto; z-index: 1000; display: none;">
                            <div style="padding: 8px 10px; cursor: pointer; hover-color: #f0f0f0;" onclick="selectSchool('', this)">-- All Schools --</div>
                            <% for (String schoolName : groupedStudents.keySet()) { %>
                                <div style="padding: 8px 10px; cursor: pointer;" onclick="selectSchool('<%= schoolName.replace("'", "\\'") %>', this)" title="<%= schoolName %>">
                                    <%= schoolName %>
                                </div>
                            <% } %>
                        </div>
                    </div>
                </div>
                
                <!-- Class Filter -->
                <div>
                    <label style="display: block; font-weight: 600; margin-bottom: 5px; color: #555;">Class:</label>
                    <select id="filterClass" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;">
                        <option value="">-- All Classes --</option>
                        <option value="1">Class 1</option>
                        <option value="2">Class 2</option>
                        <option value="3">Class 3</option>
                        <option value="4">Class 4</option>
                        <option value="5">Class 5</option>
                    </select>
                </div>
                
                <!-- Subject Filter -->
                <div>
                    <label style="display: block; font-weight: 600; margin-bottom: 5px; color: #555;">Subject with Jump:</label>
                    <select id="filterSubject" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;">
                        <option value="">-- All Subjects --</option>
                        <option value="marathi">मराठी (Marathi)</option>
                        <option value="math">गणित (Math)</option>
                        <option value="english">English</option>
                    </select>
                </div>
                
                <!-- Action Buttons -->
                <div>
                    <label style="display: block; font-weight: 600; margin-bottom: 5px; color: #555;">&nbsp;</label>
                    <button onclick="applyFilters()" style="width: 100%; padding: 10px; background: #667eea; color: white; border: none; border-radius: 5px; cursor: pointer; font-weight: 600;">
                        🔍 Apply Filters
                    </button>
                </div>
                
                <!-- Clear Filters Button -->
                <div>
                    <label style="display: block; font-weight: 600; margin-bottom: 5px; color: #555;">&nbsp;</label>
                    <button onclick="clearFilters()" style="width: 100%; padding: 10px; background: #999; color: white; border: none; border-radius: 5px; cursor: pointer; font-weight: 600;">
                        ✕ Clear Filters
                    </button>
                </div>
            </div>
        </div>
        
        <!-- Toggle Controls -->
        <div class="toggle-all">
            <button class="toggle-btn" onclick="expandAllSchools()">📂 Expand All</button>
            <button class="toggle-btn" onclick="collapseAllSchools()">📁 Collapse All</button>
        </div>
        
        <!-- Data Display -->
        <% if (levelJumpStudents.isEmpty()) { %>
            <div class="empty-state">
                <div class="empty-state-icon">✅</div>
                <h3>No Level Jumps Found</h3>
                <p>All students in the district have normal level progression (no skipped levels).</p>
            </div>
        <% } else { %>
            <% for (String schoolName : groupedStudents.keySet()) { 
                Map<String, Map<String, List<Student>>> classBySchool = groupedStudents.get(schoolName);
                int schoolJumpedCount = classBySchool.values().stream().mapToInt(m -> m.values().stream().mapToInt(List::size).sum()).sum();
                int schoolTotalCount = schoolTotalCounts.getOrDefault(schoolName, 0);
            %>
                <div class="school-section">
                    <div class="school-header" onclick="toggleSchool(this)">
                        <span>
                            🏫 <%= schoolName %>
                            <span class="jump-indicator"></span>
                            <small style="margin-left: 10px; font-weight: normal; opacity: 0.7;">
                                Active Students: <%= schoolTotalCount %> | 
                                <span style="color: #d32f2f; font-weight: 600;">🎯 Jumped: <%= schoolJumpedCount %></span>
                            </small>
                        </span>
                        <span class="school-toggle">▼</span>
                    </div>
                    
                    <% for (String studentClass : classBySchool.keySet()) { 
                        Map<String, List<Student>> sectionByClass = classBySchool.get(studentClass);
                        int classJumpedCount = sectionByClass.values().stream().mapToInt(List::size).sum();
                        int classTotalCount = classTotalCounts.getOrDefault(schoolName, new HashMap<>()).getOrDefault(studentClass, 0);
                    %>
                        <div class="class-section">
                            <div class="class-header" onclick="toggleClass(event)">
                                <span>
                                    📚 Class <%= studentClass %>
                                    <small style="margin-left: 10px; font-weight: normal; opacity: 0.7;">
                                        Active Students: <%= classTotalCount %> | 
                                        <span style="color: #d32f2f; font-weight: 600;">🎯 Jumped: <%= classJumpedCount %></span>
                                    </small>
                                </span>
                                <span>▼</span>
                            </div>
                            
                            <div class="class-content">
                                <% for (String section : sectionByClass.keySet()) { 
                                    List<Student> sectionStudents = sectionByClass.get(section);
                                %>
                                    <div class="section-header">
                                        📋 Section <%= section %> (<%= sectionStudents.size() %> students)
                                    </div>
                                    
                                    <table class="student-table">
                                        <thead>
                                            <tr>
                                                <th>Student Name</th>
                                                <th>PEN</th>
                                                <th>Marathi Progress</th>
                                                <th>Math Progress</th>
                                                <th>English Progress</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% for (Student s : sectionStudents) { %>
                                                <tr>
                                                    <td><strong><%= s.getStudentName() %></strong></td>
                                                    <td><%= s.getStudentPen() %></td>
                                                    
                                                    <!-- Marathi Levels -->
                                                    <td>
                                                        <div class="phase-box">
                                                            <div class="phase-title">मराठी (Marathi)</div>
                                                            <% 
                                                                Integer p1m = s.getPhase1Marathi();
                                                                Integer p2m = s.getPhase2Marathi();
                                                                Integer p3m = s.getPhase3Marathi();
                                                                Integer p4m = s.getPhase4Marathi();
                                                                
                                                                boolean jump1m = (p2m != null && p1m != null && p2m - p1m > 1);
                                                                boolean jump2m = (p3m != null && p2m != null && p3m - p2m > 1);
                                                                boolean jump3m = (p4m != null && p3m != null && p4m - p3m > 1);
                                                            %>
                                                            <div class="progression-row">
                                                                <div class="level-box">
                                                                    <span class="<%= jump1m ? "level-jump" : "level-normal" %>"><%= p1m != null ? p1m : "-" %></span>
                                                                    <div class="level-description"><%= getMarathiLevelDescription(p1m) %></div>
                                                                </div>
                                                                <div class="progression-arrow">→</div>
                                                                <div class="level-box">
                                                                    <span class="<%= jump1m ? "level-jump" : "level-normal" %>"><%= p2m != null ? p2m : "-" %></span>
                                                                    <div class="level-description"><%= getMarathiLevelDescription(p2m) %></div>
                                                                    <% if (jump1m) { %><span class="jump-badge">⚠️ JUMP</span><% } %>
                                                                </div>
                                                            </div>
                                                            <div class="progression-row">
                                                                <div class="level-box">
                                                                    <span class="<%= jump2m && p3m != null ? "level-jump" : "level-normal" %>"><%= p3m != null ? p3m : "-" %></span>
                                                                    <div class="level-description"><%= getMarathiLevelDescription(p3m) %></div>
                                                                </div>
                                                                <div class="progression-arrow">→</div>
                                                                <div class="level-box">
                                                                    <span class="<%= jump2m && p4m != null ? "level-jump" : "level-normal" %>"><%= p4m != null ? p4m : "-" %></span>
                                                                    <div class="level-description"><%= getMarathiLevelDescription(p4m) %></div>
                                                                    <% if (jump2m && p4m != null) { %><span class="jump-badge">⚠️ JUMP</span><% } %>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </td>
                                                    
                                                    <!-- Math Levels -->
                                                    <td>
                                                        <div class="phase-box">
                                                            <div class="phase-title">गणित (Math)</div>
                                                            <% 
                                                                Integer p1ma = s.getPhase1Math();
                                                                Integer p2ma = s.getPhase2Math();
                                                                Integer p3ma = s.getPhase3Math();
                                                                Integer p4ma = s.getPhase4Math();
                                                                
                                                                boolean jump1ma = (p2ma != null && p1ma != null && p2ma - p1ma > 1);
                                                                boolean jump2ma = (p3ma != null && p2ma != null && p3ma - p2ma > 1);
                                                                boolean jump3ma = (p4ma != null && p3ma != null && p4ma - p3ma > 1);
                                                            %>
                                                            <div class="progression-row">
                                                                <div class="level-box">
                                                                    <span class="<%= jump1ma ? "level-jump" : "level-normal" %>"><%= p1ma != null ? p1ma : "-" %></span>
                                                                    <div class="level-description"><%= getMathLevelDescription(p1ma) %></div>
                                                                </div>
                                                                <div class="progression-arrow">→</div>
                                                                <div class="level-box">
                                                                    <span class="<%= jump1ma ? "level-jump" : "level-normal" %>"><%= p2ma != null ? p2ma : "-" %></span>
                                                                    <div class="level-description"><%= getMathLevelDescription(p2ma) %></div>
                                                                    <% if (jump1ma) { %><span class="jump-badge">⚠️ JUMP</span><% } %>
                                                                </div>
                                                            </div>
                                                            <div class="progression-row">
                                                                <div class="level-box">
                                                                    <span class="<%= jump2ma && p3ma != null ? "level-jump" : "level-normal" %>"><%= p3ma != null ? p3ma : "-" %></span>
                                                                    <div class="level-description"><%= getMathLevelDescription(p3ma) %></div>
                                                                </div>
                                                                <div class="progression-arrow">→</div>
                                                                <div class="level-box">
                                                                    <span class="<%= jump2ma && p4ma != null ? "level-jump" : "level-normal" %>"><%= p4ma != null ? p4ma : "-" %></span>
                                                                    <div class="level-description"><%= getMathLevelDescription(p4ma) %></div>
                                                                    <% if (jump2ma && p4ma != null) { %><span class="jump-badge">⚠️ JUMP</span><% } %>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </td>
                                                    
                                                    <!-- English Levels -->
                                                    <td>
                                                        <div class="phase-box">
                                                            <div class="phase-title">English</div>
                                                            <% 
                                                                Integer p1e = s.getPhase1English();
                                                                Integer p2e = s.getPhase2English();
                                                                Integer p3e = s.getPhase3English();
                                                                Integer p4e = s.getPhase4English();
                                                                
                                                                boolean jump1e = (p2e != null && p1e != null && p2e - p1e > 1);
                                                                boolean jump2e = (p3e != null && p2e != null && p3e - p2e > 1);
                                                                boolean jump3e = (p4e != null && p3e != null && p4e - p3e > 1);
                                                            %>
                                                            <div class="progression-row">
                                                                <div class="level-box">
                                                                    <span class="<%= jump1e ? "level-jump" : "level-normal" %>"><%= p1e != null ? p1e : "-" %></span>
                                                                    <div class="level-description"><%= getEnglishLevelDescription(p1e) %></div>
                                                                </div>
                                                                <div class="progression-arrow">→</div>
                                                                <div class="level-box">
                                                                    <span class="<%= jump1e ? "level-jump" : "level-normal" %>"><%= p2e != null ? p2e : "-" %></span>
                                                                    <div class="level-description"><%= getEnglishLevelDescription(p2e) %></div>
                                                                    <% if (jump1e) { %><span class="jump-badge">⚠️ JUMP</span><% } %>
                                                                </div>
                                                            </div>
                                                            <div class="progression-row">
                                                                <div class="level-box">
                                                                    <span class="<%= jump2e && p3e != null ? "level-jump" : "level-normal" %>"><%= p3e != null ? p3e : "-" %></span>
                                                                    <div class="level-description"><%= getEnglishLevelDescription(p3e) %></div>
                                                                </div>
                                                                <div class="progression-arrow">→</div>
                                                                <div class="level-box">
                                                                    <span class="<%= jump2e && p4e != null ? "level-jump" : "level-normal" %>"><%= p4e != null ? p4e : "-" %></span>
                                                                    <div class="level-description"><%= getEnglishLevelDescription(p4e) %></div>
                                                                    <% if (jump2e && p4e != null) { %><span class="jump-badge">⚠️ JUMP</span><% } %>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </td>
                                                </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                <% } %>
                            </div>
                        </div>
                    <% } %>
                </div>
            <% } %>
            <% } %>
    </div>
    
    <script>
        function toggleSchool(element) {
            const classContents = element.parentElement.querySelectorAll('.class-content');
            const toggle = element.querySelector('.school-toggle');
            const isOpen = classContents[0]?.classList.contains('show');
            
            classContents.forEach(content => {
                if (isOpen) {
                    content.classList.remove('show');
                } else {
                    content.classList.add('show');
                }
            });
            
            toggle.textContent = isOpen ? '▶' : '▼';
        }
        
        function toggleClass(event) {
            event.stopPropagation();
            const classHeader = event.currentTarget;
            const classContent = classHeader.nextElementSibling;
            const toggle = classHeader.querySelector('span:last-child');
            
            classContent.classList.toggle('show');
            toggle.textContent = classContent.classList.contains('show') ? '▼' : '▶';
        }
        
        function expandAllSchools() {
            document.querySelectorAll('.class-content').forEach(el => {
                el.classList.add('show');
            });
            document.querySelectorAll('.school-toggle').forEach(el => {
                el.textContent = '▼';
            });
            document.querySelectorAll('.class-header span:last-child').forEach(el => {
                el.textContent = '▼';
            });
        }
        
        function collapseAllSchools() {
            document.querySelectorAll('.class-content').forEach(el => {
                el.classList.remove('show');
            });
            document.querySelectorAll('.school-toggle').forEach(el => {
                el.textContent = '▶';
            });
            document.querySelectorAll('.class-header span:last-child').forEach(el => {
                el.textContent = '▶';
            });
        }
        
        // Dynamic Class Dropdown Population
        function updateClassDropdown() {
            const selectedSchool = document.getElementById('filterSchool').value.trim();
            const classDropdown = document.getElementById('filterClass');
            
            console.log('=== Updating class dropdown for school:', selectedSchool);
            
            // Extract available classes for selected school
            let availableClasses = new Set();
            
            if (selectedSchool) {
                // Find the selected school's section
                let schoolFound = false;
                document.querySelectorAll('.school-section').forEach(schoolSection => {
                    const schoolHeader = schoolSection.querySelector('.school-header');
                    const schoolText = schoolHeader ? schoolHeader.textContent.trim() : '';
                    
                    console.log('Checking school header:', schoolText);
                    
                    // Match the selected school - check both with and without spaces
                    if (schoolText.includes(selectedSchool) || schoolText.replace(/\s+/g, ' ').includes(selectedSchool)) {
                        schoolFound = true;
                        console.log('✓ School found:', selectedSchool);
                        
                        // Extract all class numbers from this school
                        const classHeaders = schoolSection.querySelectorAll('.class-header');
                        console.log('Found class headers:', classHeaders.length);
                        
                        classHeaders.forEach(classHeader => {
                            const classText = classHeader.textContent.trim();
                            console.log('Class header text:', classText);
                            
                            // Clean up the text - remove extra whitespace and newlines
                            const cleanedText = classText.replace(/\s+/g, ' ');
                            console.log('Cleaned text:', cleanedText);
                            
                            // Try multiple patterns to extract class identifier
                            let classNum = null;
                            
                            // Pattern 1: Digit-based (Class 1, Class 2, etc.)
                            let match = cleanedText.match(/Class\s+(\d+)/i);
                            if (match) {
                                classNum = match[1];
                                console.log('Matched digit pattern:', classNum);
                            }
                            
                            // Pattern 2: Roman numeral (Class I, Class II, Class III, etc.)
                            if (!classNum) {
                                match = cleanedText.match(/Class\s+([IVXLC]+)/i);
                                if (match) {
                                    const roman = match[1].toUpperCase();
                                    console.log('Matched Roman pattern:', roman);
                                    
                                    // Convert Roman to number for consistent sorting
                                    const romanMap = {
                                        'I': '1', 'II': '2', 'III': '3', 'IV': '4', 'V': '5',
                                        'VI': '6', 'VII': '7', 'VIII': '8', 'IX': '9', 'X': '10'
                                    };
                                    classNum = romanMap[roman] || roman;
                                    console.log('Converted to number:', classNum);
                                }
                            }
                            
                            // Pattern 3: Just letters (Nursery, KG, etc.)
                            if (!classNum) {
                                match = cleanedText.match(/^(Nursery|KG|LKG|UKG|Play)/i);
                                if (match) {
                                    classNum = match[1];
                                    console.log('Matched letter pattern:', classNum);
                                }
                            }
                            
                            if (classNum) {
                                availableClasses.add(classNum);
                                console.log('Added to set:', classNum);
                            } else {
                                console.log('Could not extract class from:', cleanedText);
                            }
                        });
                    }
                });
                
                if (!schoolFound) {
                    console.log('✗ School not found in DOM. Checking available schools:');
                    document.querySelectorAll('.school-header').forEach(h => {
                        console.log('  Available:', h.textContent.trim());
                    });
                }
                
                // Sort available classes
                // Try numeric sort first, fall back to alphabetic
                availableClasses = Array.from(availableClasses).sort((a, b) => {
                    const aNum = parseInt(a);
                    const bNum = parseInt(b);
                    if (!isNaN(aNum) && !isNaN(bNum)) {
                        return aNum - bNum;  // Numeric sort
                    }
                    return a.localeCompare(b);  // Alphabetic sort
                });
                
                console.log('Available classes for school:', availableClasses);
            }
            
            // Rebuild class dropdown
            classDropdown.innerHTML = '<option value="">-- All Classes --</option>';
            
            if (selectedSchool && availableClasses.length > 0) {
                // Add only available classes
                availableClasses.forEach(classNum => {
                    const option = document.createElement('option');
                    option.value = classNum;
                    option.textContent = 'Class ' + classNum;
                    classDropdown.appendChild(option);
                });
                console.log('✓ Added ' + availableClasses.length + ' classes to dropdown');
            } else if (!selectedSchool) {
                // If no school selected, show all classes
                for (let i = 1; i <= 5; i++) {
                    const option = document.createElement('option');
                    option.value = i.toString();
                    option.textContent = 'Class ' + i;
                    classDropdown.appendChild(option);
                }
                console.log('✓ No school selected, showing all classes');
            } else {
                console.log('✗ School selected but no classes found. availableClasses.length:', availableClasses.length);
            }
            
            // Reset class filter to "All Classes"
            classDropdown.value = '';
            
            console.log('Class dropdown updated:', {
                selectedSchool: selectedSchool || '(none)',
                classOptions: classDropdown.querySelectorAll('option').length - 1 // exclude "All Classes"
            });
        }
        
        // Helper function to convert Roman numerals to numbers
        function romanToNumber(roman) {
            const romanMap = {
                'I': 1, 'II': 2, 'III': 3, 'IV': 4, 'V': 5,
                'VI': 6, 'VII': 7, 'VIII': 8, 'IX': 9, 'X': 10
            };
            return romanMap[roman.toUpperCase()] || null;
        }
        
        // Helper function to extract class from header text and normalize
        function extractNormalizedClass(headerText) {
            // Examples: "📚 Class I (15 students)" or "📚 Class 1 (20 students)"
            let match = headerText.match(/Class\s+([IVXLC0-9]+)/i);
            if (match) {
                let classStr = match[1].trim();
                // If it's a Roman numeral, convert to number
                let asNumber = romanToNumber(classStr);
                if (asNumber !== null) {
                    return asNumber.toString();
                }
                // If it's already a number, return as is
                if (/^\d+$/.test(classStr)) {
                    return classStr;
                }
                // For letters (Nursery, KG, etc.), return as is
                return classStr;
            }
            return null;
        }
        
        // School Search Functions
        function toggleSchoolDropdown() {
            const dropdown = document.getElementById('schoolDropdownList');
            dropdown.style.display = dropdown.style.display === 'none' ? 'block' : 'none';
        }
        
        function filterSchools(searchText) {
            const dropdown = document.getElementById('schoolDropdownList');
            const items = dropdown.querySelectorAll('div[onclick*="selectSchool"]');
            const searchLower = searchText.toLowerCase().trim();
            
            let visibleCount = 0;
            
            items.forEach(item => {
                const schoolName = item.textContent.toLowerCase();
                if (searchLower === '' || schoolName.includes(searchLower)) {
                    item.style.display = 'block';
                    visibleCount++;
                } else {
                    item.style.display = 'none';
                }
            });
            
            console.log('School search:', {searchText, visibleCount, totalItems: items.length});
        }
        
        function selectSchool(schoolName, element) {
            const searchInput = document.getElementById('schoolSearchInput');
            const filterSchoolSelect = document.getElementById('filterSchool');
            const dropdown = document.getElementById('schoolDropdownList');
            
            // Update search input with school name
            searchInput.value = schoolName || '';
            
            // Update hidden select dropdown
            filterSchoolSelect.value = schoolName || '';
            
            // Close dropdown
            dropdown.style.display = 'none';
            
            // Clear search
            searchInput.style.borderColor = '#ddd';
            
            // Trigger filter
            console.log('School selected:', schoolName || '(All Schools)');
            updateClassDropdown();
            applyFilters();
        }
        
        function applyFilters() {
            const studentName = document.getElementById('filterStudentName').value.toLowerCase().trim();
            const school = document.getElementById('filterSchool').value.trim();
            const studentClass = document.getElementById('filterClass').value.trim();
            const subject = document.getElementById('filterSubject').value.trim();
            
            console.log('Applying filters:', {studentName, school, studentClass, subject});
            
            let visibleSchoolCount = 0;
            
            // Iterate through each school section
            document.querySelectorAll('.school-section').forEach(schoolSection => {
                const schoolHeader = schoolSection.querySelector('.school-header');
                const schoolText = schoolHeader ? schoolHeader.textContent.trim() : '';
                
                // Check school match
                let schoolMatches = true;
                if (school) {
                    schoolMatches = schoolText.includes(school);
                }
                
                if (!schoolMatches) {
                    schoolSection.style.display = 'none';
                    return;
                }
                
                let schoolHasVisibleRows = false;
                
                // Iterate through each class in this school
                schoolSection.querySelectorAll('.class-section').forEach(classSection => {
                    const classHeader = classSection.querySelector('.class-header');
                    const classHeaderText = classHeader ? classHeader.textContent.trim() : '';
                    
                    let classMatches = true;
                    if (studentClass) {
                        // Extract and normalize class from header (handles Roman numerals like I, II, III)
                        const normalizedHeaderClass = extractNormalizedClass(classHeaderText);
                        console.log('Class filter check:', {
                            selectedClass: studentClass,
                            headerText: classHeaderText,
                            normalizedHeaderClass: normalizedHeaderClass,
                            matches: normalizedHeaderClass === studentClass
                        });
                        classMatches = (normalizedHeaderClass === studentClass);
                    }
                    
                    if (!classMatches) {
                        classSection.style.display = 'none';
                        return;
                    }
                    
                    let classHasVisibleRows = false;
                    
                    // Check each table in this class
                    classSection.querySelectorAll('table tbody').forEach(tbody => {
                        tbody.querySelectorAll('tr').forEach(row => {
                            let shouldShow = true;
                            
                            // Get student name from first column
                            const nameCell = row.querySelector('td:nth-child(1)');
                            const studentNameText = nameCell ? nameCell.textContent.toLowerCase().trim() : '';
                            
                            // Filter 1: Student Name
                            if (studentName && !studentNameText.includes(studentName)) {
                                shouldShow = false;
                            }
                            
                            // Filter 2: Subject with Jump
                            if (shouldShow && subject) {
                                let hasSubjectJump = false;
                                
                                if (subject === 'marathi') {
                                    // Check Marathi column (3rd <td>) for any JUMP badge
                                    const marathiCell = row.querySelector('td:nth-child(3)');
                                    hasSubjectJump = marathiCell && marathiCell.innerHTML.includes('⚠️ JUMP');
                                } else if (subject === 'math') {
                                    // Check Math column (4th <td>) for any JUMP badge
                                    const mathCell = row.querySelector('td:nth-child(4)');
                                    hasSubjectJump = mathCell && mathCell.innerHTML.includes('⚠️ JUMP');
                                } else if (subject === 'english') {
                                    // Check English column (5th <td>) for any JUMP badge
                                    const englishCell = row.querySelector('td:nth-child(5)');
                                    hasSubjectJump = englishCell && englishCell.innerHTML.includes('⚠️ JUMP');
                                }
                                
                                if (!hasSubjectJump) {
                                    shouldShow = false;
                                }
                            }
                            
                            // Apply visibility
                            row.style.display = shouldShow ? '' : 'none';
                            if (shouldShow) {
                                classHasVisibleRows = true;
                                schoolHasVisibleRows = true;
                            }
                        });
                    });
                    
                    // Show/hide class section based on visible rows
                    classSection.style.display = classHasVisibleRows ? '' : 'none';
                });
                
                // Show/hide school section based on visible rows
                schoolSection.style.display = schoolHasVisibleRows ? '' : 'none';
                if (schoolHasVisibleRows) {
                    visibleSchoolCount++;
                }
            });
            
            console.log('Visible schools:', visibleSchoolCount);
        }
        
         function clearFilters() {
             document.getElementById('filterStudentName').value = '';
             document.getElementById('filterSchool').value = '';
             document.getElementById('filterClass').value = '';
             document.getElementById('filterSubject').value = '';
             
             // Reset class dropdown to all classes
             updateClassDropdown();
             
             // Show all
             document.querySelectorAll('.school-section').forEach(el => {
                 el.style.display = '';
             });
             document.querySelectorAll('.class-section').forEach(el => {
                 el.style.display = '';
             });
             document.querySelectorAll('tbody tr').forEach(el => {
                el.style.display = '';
            });
            
            console.log('Filters cleared');
        }
        
        // Real-time search as user types
        const filterStudentName = document.getElementById('filterStudentName');
        if (filterStudentName) {
            filterStudentName.addEventListener('keyup', function() {
                if (this.value.length >= 2 || this.value.length === 0) {
                    applyFilters();
                }
            });
        }
        
        // School search with dropdown
        const schoolSearchInput = document.getElementById('schoolSearchInput');
        if (schoolSearchInput) {
            schoolSearchInput.addEventListener('focus', function() {
                document.getElementById('schoolDropdownList').style.display = 'block';
            });
            
            schoolSearchInput.addEventListener('input', function() {
                filterSchools(this.value);
                document.getElementById('schoolDropdownList').style.display = 'block';
            });
            
            schoolSearchInput.addEventListener('keyup', function(e) {
                if (e.key === 'Escape') {
                    document.getElementById('schoolDropdownList').style.display = 'none';
                }
            });
        }
        
        // Close school dropdown when clicking outside
        document.addEventListener('click', function(event) {
            const schoolDiv = document.querySelector('[id="schoolSearchInput"]')?.parentElement.parentElement;
            const dropdown = document.getElementById('schoolDropdownList');
            const searchInput = document.getElementById('schoolSearchInput');
            
            if (!event.target.closest('#schoolSearchInput') && !event.target.closest('#schoolDropdownList')) {
                dropdown.style.display = 'none';
            }
        });
        
        
        // Add filter triggers to other dropdowns - fires on change
        ['filterClass', 'filterSubject'].forEach(id => {
            const el = document.getElementById(id);
            if (el) {
                el.addEventListener('change', function() {
                    console.log('Filter changed:', id, '=', this.value);
                    applyFilters();
                });
            }
        });
        
        // Make applyFilters and updateClassDropdown globally accessible for Apply button
        window.applyFilters = applyFilters;
        window.clearFilters = clearFilters;
        window.selectSchool = selectSchool;
        window.filterSchools = filterSchools;
    </script>
</body>
</html>
