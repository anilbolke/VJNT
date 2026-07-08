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
    if (user == null || !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    StudentDAO studentDAO = new StudentDAO();
    SchoolDAO schoolDAO = new SchoolDAO();

    // Division scope: "ALL"/empty aggregates across every division; otherwise a single division.
    String divisionScope = request.getParameter("division");
    boolean allDivisions = divisionScope == null || divisionScope.trim().isEmpty()
            || "ALL".equalsIgnoreCase(divisionScope.trim());

    // List of divisions for the dropdown
    List<String> divisions = studentDAO.getDistinctDivisions();

    // Get all active students for the selected scope
    List<Student> allStudents = allDivisions
            ? studentDAO.getAllStudents()
            : studentDAO.getStudentsByDivision(divisionScope);

    // Extract unique districts from all students
    Set<String> districtSet = new TreeSet<>();
    for (Student student : allStudents) {
        if (student.getDistrict() != null && !student.getDistrict().isEmpty()) {
            districtSet.add(student.getDistrict());
        }
    }
    List<String> distinctDistricts = new ArrayList<>(districtSet);

    // Filter: Keep only students with level jumps (>1 level difference in any subject/phase transition)
    List<Student> levelJumpStudents = new ArrayList<>();

    for (Student student : allStudents) {
        boolean hasLevelJump = false;

        if (student.getPhase1Marathi() != null && student.getPhase2Marathi() != null) {
            if (student.getPhase2Marathi() - student.getPhase1Marathi() > 1) { hasLevelJump = true; }
        }
        if (student.getPhase2Marathi() != null && student.getPhase3Marathi() != null) {
            if (student.getPhase3Marathi() - student.getPhase2Marathi() > 1) { hasLevelJump = true; }
        }
        if (student.getPhase3Marathi() != null && student.getPhase4Marathi() != null) {
            if (student.getPhase4Marathi() - student.getPhase3Marathi() > 1) { hasLevelJump = true; }
        }

        if (student.getPhase1Math() != null && student.getPhase2Math() != null) {
            if (student.getPhase2Math() - student.getPhase1Math() > 1) { hasLevelJump = true; }
        }
        if (student.getPhase2Math() != null && student.getPhase3Math() != null) {
            if (student.getPhase3Math() - student.getPhase2Math() > 1) { hasLevelJump = true; }
        }
        if (student.getPhase3Math() != null && student.getPhase4Math() != null) {
            if (student.getPhase4Math() - student.getPhase3Math() > 1) { hasLevelJump = true; }
        }

        if (student.getPhase1English() != null && student.getPhase2English() != null) {
            if (student.getPhase2English() - student.getPhase1English() > 1) { hasLevelJump = true; }
        }
        if (student.getPhase2English() != null && student.getPhase3English() != null) {
            if (student.getPhase3English() - student.getPhase2English() > 1) { hasLevelJump = true; }
        }
        if (student.getPhase3English() != null && student.getPhase4English() != null) {
            if (student.getPhase4English() - student.getPhase3English() > 1) { hasLevelJump = true; }
        }

        if (hasLevelJump) {
            levelJumpStudents.add(student);
        }
    }

    // Batch-load all schools at once
    Set<String> allUdiseNumbers = new HashSet<>();
    for (Student student : allStudents) {
        if (student.getUdiseNo() != null) {
            allUdiseNumbers.add(student.getUdiseNo());
        }
    }

    Map<String, School> schoolMap = new HashMap<>();
    Map<String, String> schoolNameCache = new HashMap<>();

    if (!allUdiseNumbers.isEmpty()) {
        try {
            List<School> schools = schoolDAO.getSchoolsByUdises(new ArrayList<>(allUdiseNumbers));
            if (schools != null && !schools.isEmpty()) {
                for (School school : schools) {
                    schoolMap.put(school.getUdiseNo(), school);
                }
                for (String udiseNo : allUdiseNumbers) {
                    School school = schoolMap.get(udiseNo);
                    String schoolName = (school != null) ? school.getSchoolName() + " (" + udiseNo + ")" : udiseNo;
                    schoolNameCache.put(udiseNo, schoolName);
                }
            } else {
                for (String udiseNo : allUdiseNumbers) {
                    School school = schoolDAO.getSchoolByUdise(udiseNo);
                    if (school != null) {
                        schoolMap.put(udiseNo, school);
                        schoolNameCache.put(udiseNo, school.getSchoolName() + " (" + udiseNo + ")");
                    } else {
                        schoolNameCache.put(udiseNo, udiseNo);
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Warning: Batch school loading failed, falling back to individual queries: " + e.getMessage());
            for (String udiseNo : allUdiseNumbers) {
                School school = schoolDAO.getSchoolByUdise(udiseNo);
                if (school != null) {
                    schoolMap.put(udiseNo, school);
                    schoolNameCache.put(udiseNo, school.getSchoolName() + " (" + udiseNo + ")");
                } else {
                    schoolNameCache.put(udiseNo, udiseNo);
                }
            }
        }
    }

    // Total counts (all students) by school and class
    Map<String, Integer> schoolTotalCounts = new HashMap<>();
    Map<String, Map<String, Integer>> classTotalCounts = new HashMap<>();

    for (Student student : allStudents) {
        String udiseNo = student.getUdiseNo();
        String schoolName = schoolNameCache.get(udiseNo);
        if (schoolName == null) schoolName = udiseNo;

        String studentClass = student.getStudentClass() != null ? student.getStudentClass() : "N/A";

        schoolTotalCounts.put(schoolName, schoolTotalCounts.getOrDefault(schoolName, 0) + 1);
        classTotalCounts.computeIfAbsent(schoolName, k -> new HashMap<>())
                       .put(studentClass, classTotalCounts.get(schoolName).getOrDefault(studentClass, 0) + 1);
    }

    // Group JUMPED students by School -> Class -> Section
    Map<String, Map<String, Map<String, List<Student>>>> groupedStudents = new TreeMap<>();

    for (Student student : levelJumpStudents) {
        String udiseNo = student.getUdiseNo();
        String schoolName = schoolNameCache.get(udiseNo);
        if (schoolName == null) schoolName = udiseNo;

        String studentClass = student.getStudentClass() != null ? student.getStudentClass() : "N/A";
        String section = student.getSection() != null ? student.getSection() : "N/A";

        groupedStudents.computeIfAbsent(schoolName, k -> new TreeMap<>())
                      .computeIfAbsent(studentClass, k -> new TreeMap<>())
                      .computeIfAbsent(section, k -> new ArrayList<>())
                      .add(student);
    }

    // District-to-schools map for JavaScript
    Map<String, Set<String>> districtSchoolsMap = new TreeMap<>();
    for (Student student : levelJumpStudents) {
        String district = student.getDistrict();
        if (district == null || district.isEmpty()) continue;

        String udiseNo = student.getUdiseNo();
        String schoolName = schoolNameCache.get(udiseNo);
        if (schoolName == null) schoolName = udiseNo;

        districtSchoolsMap.computeIfAbsent(district, k -> new TreeSet<>()).add(schoolName);
    }

    // PAGINATION
    int studentsPerPage = 50;
    int currentPage = 1;
    String pageParam = request.getParameter("page");
    if (pageParam != null && !pageParam.isEmpty()) {
        try {
            currentPage = Integer.parseInt(pageParam);
            if (currentPage < 1) currentPage = 1;
        } catch (NumberFormatException e) {
            currentPage = 1;
        }
    }

    // FILTER BY DISTRICT
    String districtParam = request.getParameter("district");
    if (districtParam != null && !districtParam.isEmpty()) {
        List<Student> filteredStudents = new ArrayList<>();
        for (Student student : levelJumpStudents) {
            if (student.getDistrict() != null && student.getDistrict().equals(districtParam)) {
                filteredStudents.add(student);
            }
        }
        levelJumpStudents = filteredStudents;
    }

    // FILTER BY STUDENT NAME
    String studentNameParam = request.getParameter("studentName");
    if (studentNameParam != null && !studentNameParam.isEmpty()) {
        String searchName = studentNameParam.toLowerCase().trim();
        List<Student> filteredStudents = new ArrayList<>();
        for (Student student : levelJumpStudents) {
            if (student.getStudentName() != null && student.getStudentName().toLowerCase().contains(searchName)) {
                filteredStudents.add(student);
            }
        }
        levelJumpStudents = filteredStudents;
    }

    // FILTER BY SCHOOL
    String schoolParam = request.getParameter("school");
    if (schoolParam != null && !schoolParam.isEmpty()) {
        List<Student> filteredStudents = new ArrayList<>();
        for (Student student : levelJumpStudents) {
            String udiseNo = student.getUdiseNo();
            String schoolName = schoolNameCache.get(udiseNo);
            if (schoolName == null) schoolName = udiseNo;
            if (schoolName.contains(schoolParam)) {
                filteredStudents.add(student);
            }
        }
        levelJumpStudents = filteredStudents;
    }

    // FILTER BY CLASS
    String classParam = request.getParameter("class");
    if (classParam != null && !classParam.isEmpty()) {
        List<Student> filteredStudents = new ArrayList<>();
        for (Student student : levelJumpStudents) {
            if (student.getStudentClass() != null && student.getStudentClass().equals(classParam)) {
                filteredStudents.add(student);
            }
        }
        levelJumpStudents = filteredStudents;
    }

    // FILTER BY SUBJECT
    String subjectParam = request.getParameter("subject");
    if (subjectParam != null && !subjectParam.isEmpty()) {
        List<Student> filteredStudents = new ArrayList<>();
        for (Student student : levelJumpStudents) {
            boolean hasSubjectJump = false;
            if ("marathi".equalsIgnoreCase(subjectParam)) {
                if ((student.getPhase1Marathi() != null && student.getPhase2Marathi() != null && student.getPhase2Marathi() - student.getPhase1Marathi() > 1) ||
                    (student.getPhase2Marathi() != null && student.getPhase3Marathi() != null && student.getPhase3Marathi() - student.getPhase2Marathi() > 1) ||
                    (student.getPhase3Marathi() != null && student.getPhase4Marathi() != null && student.getPhase4Marathi() - student.getPhase3Marathi() > 1)) {
                    hasSubjectJump = true;
                }
            } else if ("math".equalsIgnoreCase(subjectParam)) {
                if ((student.getPhase1Math() != null && student.getPhase2Math() != null && student.getPhase2Math() - student.getPhase1Math() > 1) ||
                    (student.getPhase2Math() != null && student.getPhase3Math() != null && student.getPhase3Math() - student.getPhase2Math() > 1) ||
                    (student.getPhase3Math() != null && student.getPhase4Math() != null && student.getPhase4Math() - student.getPhase3Math() > 1)) {
                    hasSubjectJump = true;
                }
            } else if ("english".equalsIgnoreCase(subjectParam)) {
                if ((student.getPhase1English() != null && student.getPhase2English() != null && student.getPhase2English() - student.getPhase1English() > 1) ||
                    (student.getPhase2English() != null && student.getPhase3English() != null && student.getPhase3English() - student.getPhase2English() > 1) ||
                    (student.getPhase3English() != null && student.getPhase4English() != null && student.getPhase4English() - student.getPhase3English() > 1)) {
                    hasSubjectJump = true;
                }
            }
            if (hasSubjectJump) {
                filteredStudents.add(student);
            }
        }
        levelJumpStudents = filteredStudents;
    }

    int totalStudents = levelJumpStudents.size();
    int totalPages = (int) Math.ceil((double) totalStudents / studentsPerPage);
    if (totalPages < 1) totalPages = 1;
    if (currentPage > totalPages) currentPage = totalPages;

    int startIndex = (currentPage - 1) * studentsPerPage;
    int endIndex = Math.min(startIndex + studentsPerPage, totalStudents);
    List<Student> paginatedStudents = levelJumpStudents.subList(startIndex, endIndex);

    Map<String, Map<String, Map<String, List<Student>>>> paginatedGroupedStudents = new TreeMap<>();

    for (Student student : paginatedStudents) {
        String udiseNo = student.getUdiseNo();
        String schoolName = schoolNameCache.get(udiseNo);
        if (schoolName == null) schoolName = udiseNo;

        String studentClass = student.getStudentClass() != null ? student.getStudentClass() : "N/A";
        String section = student.getSection() != null ? student.getSection() : "N/A";

        paginatedGroupedStudents.computeIfAbsent(schoolName, k -> new TreeMap<>())
                               .computeIfAbsent(studentClass, k -> new TreeMap<>())
                               .computeIfAbsent(section, k -> new ArrayList<>())
                               .add(student);
    }

    String scopeLabel = allDivisions ? "All Divisions" : (divisionScope + " Division");
%>

<%!
    String getMarathiLevelDescription(Integer level) {
        String[] marathiLevels = {"स्थर निश्चित केला नाही", "प्रारंभिक स्तर", "अक्षर स्तर", "शब्द स्तर", "वाक्य स्तर", "समजपूर्वक उतारा वाचन स्तर", "मराठी वाचन व लेखन FLN स्तर 100% पूर्ण"};
        if (level == null || level < 0 || level >= marathiLevels.length) return "N/A";
        return marathiLevels[level];
    }

    String getMathLevelDescription(Integer level) {
        String[] mathLevels = {"स्तर निश्चित केला नाही", "प्रारंभिक स्तर", "अंक ज्ञान स्तर", "संख्याज्ञान स्तर", "बेरीज स्तर", "वजाबाकी स्तर", "गुणाकार स्तर", "भागाकार स्तर", "गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण"};
        if (level == null || level < 0 || level >= mathLevels.length) return "N/A";
        return mathLevels[level];
    }

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
    <title>Student Level Jumps - All Divisions</title>
    <style type="text/css">
        * { margin: 0; padding: 0; box-sizing: border-box; }

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

        .header h1 { font-size: 28px; margin-bottom: 5px; }
        .header p { font-size: 14px; opacity: 0.9; }
        .header-right { text-align: right; }

        .stats { display: flex; gap: 20px; margin-bottom: 25px; flex-wrap: wrap; }

        .stat-card {
            background: #f8f9fa;
            padding: 15px 20px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }

        .stat-label { font-size: 12px; color: #666; margin-bottom: 5px; }
        .stat-value { font-size: 24px; font-weight: bold; color: #667eea; }

        .school-section { margin-bottom: 30px; border: 1px solid #e0e0e0; border-radius: 10px; overflow: hidden; }
        .school-header { background: #f0f2f5; padding: 15px 20px; cursor: pointer; display: flex; justify-content: space-between; align-items: center; font-weight: 600; color: #333; }
        .school-header:hover { background: #e8eaef; }
        .school-toggle { font-size: 18px; }
        .class-section { margin: 0; border-bottom: 1px solid #e0e0e0; background: #ffffff; }
        .class-header { background: #f8f9fa; padding: 12px 20px; padding-left: 40px; cursor: pointer; display: flex; justify-content: space-between; align-items: center; font-weight: 500; color: #555; }
        .class-header:hover { background: #f0f2f5; }
        .section-header { background: white; padding: 10px 20px; padding-left: 60px; font-weight: 500; color: #666; border-bottom: 1px solid #eee; }
        .student-table { width: 100%; border-collapse: collapse; margin: 0; }
        .student-table thead { background: #f0f2f5; }
        .student-table th { padding: 12px 15px; text-align: left; font-size: 13px; font-weight: 600; color: #333; border-bottom: 2px solid #ddd; }
        .student-table td { padding: 12px 15px; border-bottom: 1px solid #eee; font-size: 13px; }
        .student-table tbody tr:hover { background: #f9f9f9; }
        .phase-box { background: #f8f9fa; padding: 8px 12px; border-radius: 5px; margin: 3px 0; font-size: 12px; }
        .phase-title { font-weight: 600; color: #333; margin-bottom: 3px; }
        .level-jump { color: #fff; background: #d32f2f; padding: 6px 10px; border-radius: 20px; font-weight: 700; box-shadow: 0 2px 8px rgb(211, 47, 47, 0.3); animation: jumpPulse 2s infinite; }
        @keyframes jumpPulse { 0%, 100% { box-shadow: 0 2px 8px rgb(211, 47, 47, 0.3); } 50% { box-shadow: 0 4px 12px rgb(211, 47, 47, 0.6); } }
        .level-normal { color: #388e3c; background: #e8f5e9; padding: 4px 8px; border-radius: 15px; font-weight: 600; }
        .level-description { font-size: 11px; color: #666; margin-top: 4px; font-weight: normal; }
        .jump-badge { display: inline-block; background: #d32f2f; color: white; padding: 3px 8px; border-radius: 10px; font-size: 10px; font-weight: 700; margin-left: 8px; animation: jumpBlink 1.5s infinite; }
        @keyframes jumpBlink { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }
        .progression-row { display: flex; align-items: center; gap: 8px; margin: 6px 0; padding: 8px; background: #fafafa; border-radius: 5px; }
        .progression-arrow { color: #999; font-weight: bold; }
        .level-box { min-width: 120px; text-align: center; }
        .empty-state { text-align: center; padding: 40px 20px; color: #999; }
        .empty-state-icon { font-size: 48px; margin-bottom: 15px; }
        .toggle-all { display: flex; gap: 10px; margin-bottom: 20px; }
        .toggle-btn { padding: 8px 15px; border: none; border-radius: 5px; background: #667eea; color: white; cursor: pointer; font-size: 13px; transition: background 0.3s; }
        .toggle-btn:hover { background: #764ba2; }
        .content { display: none; }
        .content.show { display: table; }
        .class-content { display: none; }
        .class-content.show { display: block; }
        .jump-indicator { display: inline-block; width: 8px; height: 8px; background: #d32f2f; border-radius: 50%; margin-left: 5px; }
        #divisionFilter { border: 2px solid #667eea !important; font-weight: 600; color: #4a4a8a; }
        #schoolDropdownList > div { padding: 10px 12px; cursor: pointer; border-bottom: 1px solid #f0f0f0; transition: background-color 0.2s; font-size: 14px; }
        #schoolDropdownList > div:first-child { font-weight: 600; background-color: #f8f9fa; }
        #schoolDropdownList > div:hover { background-color: #e8eaf6; color: #667eea; }
        #schoolDropdownList > div:last-child { border-bottom: none; }
        #schoolSearchInput { transition: border-color 0.3s; }
        #schoolSearchInput:focus { outline: none; border-color: #667eea; box-shadow: 0 0 5px rgba(102, 126, 234, 0.3); }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div>
                <h1>📊 Student Level Jump Analysis</h1>
                <p>Scope: <strong id="scopeLabel"><%= scopeLabel %></strong> (All Districts)</p>
            </div>
            <div class="header-right">
                <a href="<%= request.getContextPath() %>/super-officer-dashboard.jsp" style="display: inline-block; padding: 10px 20px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin-right: 15px; font-weight: 600; cursor: pointer; border: none;">← Back to Dashboard</a>
                <p style="margin-bottom: 5px;">Last Updated: <strong><%= new java.text.SimpleDateFormat("dd-MMM-yyyy HH:mm").format(new java.util.Date()) %></strong></p>
            </div>
        </div>

        <!-- Statistics -->
        <div class="stats">
            <div class="stat-card">
                <div class="stat-label">📍 Schools on This Page</div>
                <div class="stat-value"><%= paginatedGroupedStudents.size() %></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">👥 Students on This Page</div>
                <div class="stat-value"><%= paginatedStudents.size() %></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">📄 Page <%= currentPage %> of <%= totalPages %></div>
                <div class="stat-value"><%= startIndex + 1 %>-<%= endIndex %> / <%= totalStudents %></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">👥 Total Students with Jumps</div>
                <div class="stat-value"><%= levelJumpStudents.size() %></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">📈 Total Students in Scope</div>
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
                <!-- Division Filter -->
                <div>
                    <label style="display: block; font-weight: 600; margin-bottom: 5px; color: #555;">🌐 Division:</label>
                    <select id="divisionFilter" onchange="onDivisionChange()" style="width: 100%; padding: 10px; border-radius: 5px; font-size: 14px;">
                        <option value="ALL" <%= allDivisions ? "selected" : "" %>>🌐 All Divisions</option>
                        <% for (String div : divisions) { %>
                            <option value="<%= div %>" <%= (!allDivisions && div.equals(divisionScope)) ? "selected" : "" %>><%= div %></option>
                        <% } %>
                    </select>
                </div>

                <!-- District Filter -->
                <div>
                    <label style="display: block; font-weight: 600; margin-bottom: 5px; color: #555;">District:</label>
                    <select id="filterDistrict" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;">
                        <option value="">-- All Districts --</option>
                        <% for (String district : distinctDistricts) { %>
                            <option value="<%= district %>" <%= districtParam != null && district.equals(districtParam) ? "selected" : "" %>><%= district %></option>
                        <% } %>
                    </select>
                </div>

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
                        </select>
                        <div id="schoolDropdownList" style="position: absolute; top: 100%; left: 0; right: 0; background: white; border: 1px solid #ddd; border-top: none; border-radius: 0 0 5px 5px; max-height: 250px; overflow-y: auto; z-index: 1000; display: none;">
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
                <p>All students in this scope have normal level progression (no skipped levels).</p>
            </div>
        <% } else { %>
            <% for (String schoolName : paginatedGroupedStudents.keySet()) {
                Map<String, Map<String, List<Student>>> classBySchool = groupedStudents.get(schoolName);
                int schoolJumpedCount = classBySchool.values().stream().mapToInt(m -> m.values().stream().mapToInt(List::size).sum()).sum();
                int schoolTotalCount = schoolTotalCounts.getOrDefault(schoolName, 0);

                String districtForSchool = "Unknown";
                for (Student student : levelJumpStudents) {
                    School school = schoolDAO.getSchoolByUdise(student.getUdiseNo());
                    if (school != null && (school.getSchoolName() + " (" + student.getUdiseNo() + ")").equals(schoolName)) {
                        districtForSchool = student.getDistrict() != null ? student.getDistrict() : "Unknown";
                        break;
                    }
                }
            %>
                <div class="school-section" data-district="<%= districtForSchool %>">
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
                                                <tr class="student-row" data-student-id="<%= s.getStudentId() %>">
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

        <!-- Pagination Controls -->
        <div style="background: #f8f9fa; padding: 20px; border-radius: 10px; margin-bottom: 25px; border: 1px solid #e0e0e0; text-align: center;">
            <h3 style="margin-bottom: 15px; color: #333;">📄 Pagination</h3>
            <div style="display: flex; justify-content: center; gap: 10px; flex-wrap: wrap; align-items: center;">
                <%
                    StringBuilder paginationQueryBuilder = new StringBuilder("?");
                    boolean firstParam = true;

                    if (!allDivisions) {
                        paginationQueryBuilder.append("division=").append(java.net.URLEncoder.encode(divisionScope, "UTF-8"));
                        firstParam = false;
                    }
                    if (districtParam != null && !districtParam.isEmpty()) {
                        if (!firstParam) paginationQueryBuilder.append("&");
                        paginationQueryBuilder.append("district=").append(java.net.URLEncoder.encode(districtParam, "UTF-8"));
                        firstParam = false;
                    }
                    if (studentNameParam != null && !studentNameParam.isEmpty()) {
                        if (!firstParam) paginationQueryBuilder.append("&");
                        paginationQueryBuilder.append("studentName=").append(java.net.URLEncoder.encode(studentNameParam, "UTF-8"));
                        firstParam = false;
                    }
                    if (schoolParam != null && !schoolParam.isEmpty()) {
                        if (!firstParam) paginationQueryBuilder.append("&");
                        paginationQueryBuilder.append("school=").append(java.net.URLEncoder.encode(schoolParam, "UTF-8"));
                        firstParam = false;
                    }
                    if (classParam != null && !classParam.isEmpty()) {
                        if (!firstParam) paginationQueryBuilder.append("&");
                        paginationQueryBuilder.append("class=").append(java.net.URLEncoder.encode(classParam, "UTF-8"));
                        firstParam = false;
                    }
                    if (subjectParam != null && !subjectParam.isEmpty()) {
                        if (!firstParam) paginationQueryBuilder.append("&");
                        paginationQueryBuilder.append("subject=").append(java.net.URLEncoder.encode(subjectParam, "UTF-8"));
                        firstParam = false;
                    }

                    String paginationQueryString = paginationQueryBuilder.toString();
                    if (paginationQueryString.equals("?")) {
                        paginationQueryString = "?page=";
                    } else {
                        paginationQueryString += "&page=";
                    }
                %>

                <% if (currentPage > 1) { %>
                    <a href="<%= paginationQueryString %>1" style="padding: 8px 12px; border: 1px solid #667eea; color: #667eea; text-decoration: none; border-radius: 5px; background: white; cursor: pointer;">« First</a>
                    <a href="<%= paginationQueryString %><%= currentPage - 1 %>" style="padding: 8px 12px; border: 1px solid #667eea; color: #667eea; text-decoration: none; border-radius: 5px; background: white; cursor: pointer;">‹ Previous</a>
                <% } else { %>
                    <span style="padding: 8px 12px; border: 1px solid #ccc; color: #999; border-radius: 5px; background: #f0f0f0;">« First</span>
                    <span style="padding: 8px 12px; border: 1px solid #ccc; color: #999; border-radius: 5px; background: #f0f0f0;">‹ Previous</span>
                <% } %>

                <div style="display: flex; gap: 5px; align-items: center;">
                    <%
                        int startPage = Math.max(1, currentPage - 2);
                        int endPage = Math.min(totalPages, currentPage + 2);
                    %>
                    <% if (startPage > 1) { %>
                        <a href="<%= paginationQueryString %>1" style="padding: 6px 10px; border: 1px solid #ddd; color: #333; text-decoration: none; border-radius: 3px; background: white;">1</a>
                        <% if (startPage > 2) { %><span style="padding: 6px 10px;">...</span><% } %>
                    <% } %>

                    <% for (int i = startPage; i <= endPage; i++) { %>
                        <% if (i == currentPage) { %>
                            <span style="padding: 6px 10px; border: 2px solid #667eea; color: white; background: #667eea; border-radius: 3px; font-weight: bold;"><%= i %></span>
                        <% } else { %>
                            <a href="<%= paginationQueryString %><%= i %>" style="padding: 6px 10px; border: 1px solid #ddd; color: #333; text-decoration: none; border-radius: 3px; background: white; cursor: pointer;"><%= i %></a>
                        <% } %>
                    <% } %>

                    <% if (endPage < totalPages) { %>
                        <% if (endPage < totalPages - 1) { %><span style="padding: 6px 10px;">...</span><% } %>
                        <a href="<%= paginationQueryString %><%= totalPages %>" style="padding: 6px 10px; border: 1px solid #ddd; color: #333; text-decoration: none; border-radius: 3px; background: white;"><%= totalPages %></a>
                    <% } %>
                </div>

                <% if (currentPage < totalPages) { %>
                    <a href="<%= paginationQueryString %><%= currentPage + 1 %>" style="padding: 8px 12px; border: 1px solid #667eea; color: #667eea; text-decoration: none; border-radius: 5px; background: white; cursor: pointer;">Next ›</a>
                    <a href="<%= paginationQueryString %><%= totalPages %>" style="padding: 8px 12px; border: 1px solid #667eea; color: #667eea; text-decoration: none; border-radius: 5px; background: white; cursor: pointer;">Last »</a>
                <% } else { %>
                    <span style="padding: 8px 12px; border: 1px solid #ccc; color: #999; border-radius: 5px; background: #f0f0f0;">Next ›</span>
                    <span style="padding: 8px 12px; border: 1px solid #ccc; color: #999; border-radius: 5px; background: #f0f0f0;">Last »</span>
                <% } %>
            </div>
            <div style="margin-top: 15px; color: #666; font-size: 13px;">
                Showing <%= startIndex + 1 %> to <%= endIndex %> of <%= totalStudents %> students with level jumps
                (Page <%= currentPage %> of <%= totalPages %>)
            </div>
        </div>

    <!-- Pass complete district-schools map to JavaScript as JSON -->
    <script>
        const allSchoolsByDistrict = <%
            StringBuilder json = new StringBuilder();
            json.append("{");
            int districtCount = 0;
            for (String district : districtSchoolsMap.keySet()) {
                if (districtCount > 0) json.append(",");
                json.append("\"").append(district).append("\":[");
                java.util.List<String> schools = new java.util.ArrayList<>(districtSchoolsMap.get(district));
                java.util.Collections.sort(schools);
                int schoolCount = 0;
                for (String school : schools) {
                    if (schoolCount > 0) json.append(",");
                    json.append("\"").append(school.replace("\"", "\\\"")).append("\"");
                    schoolCount++;
                }
                json.append("]");
                districtCount++;
            }
            json.append("}");
            out.print(json.toString());
        %>;

        // Selected division scope ('ALL' aggregates across every division)
        const SELECTED_DIVISION = '<%= allDivisions ? "ALL" : divisionScope %>';

        // Query fragment carrying the division scope (empty for All Divisions)
        function divQuery() {
            return (SELECTED_DIVISION && SELECTED_DIVISION !== 'ALL')
                ? 'division=' + encodeURIComponent(SELECTED_DIVISION) : '';
        }
    </script>

    <script>
        // Division dropdown changed: reload page scoped to the new division (reset other filters)
        function onDivisionChange() {
            const div = document.getElementById('divisionFilter').value;
            const base = window.location.pathname;
            if (div && div !== 'ALL') {
                window.location.href = base + '?division=' + encodeURIComponent(div) + '&page=1';
            } else {
                window.location.href = base + '?page=1';
            }
        }

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
            document.querySelectorAll('.class-content').forEach(el => el.classList.add('show'));
            document.querySelectorAll('.school-toggle').forEach(el => el.textContent = '▼');
            document.querySelectorAll('.class-header span:last-child').forEach(el => el.textContent = '▼');
        }

        function collapseAllSchools() {
            document.querySelectorAll('.class-content').forEach(el => el.classList.remove('show'));
            document.querySelectorAll('.school-toggle').forEach(el => el.textContent = '▶');
            document.querySelectorAll('.class-header span:last-child').forEach(el => el.textContent = '▶');
        }

        function applyFilters() {
            const district = document.getElementById('filterDistrict').value.trim();
            const studentName = document.getElementById('filterStudentName').value.trim();
            const school = document.getElementById('filterSchool').value.trim();
            const studentClass = document.getElementById('filterClass').value.trim();
            const subject = document.getElementById('filterSubject').value.trim();

            let filterParams = [];
            const dq = divQuery();
            if (dq) filterParams.push(dq);
            if (district) filterParams.push('district=' + encodeURIComponent(district));
            if (studentName) filterParams.push('studentName=' + encodeURIComponent(studentName));
            if (school) filterParams.push('school=' + encodeURIComponent(school));
            if (studentClass) filterParams.push('class=' + encodeURIComponent(studentClass));
            if (subject) filterParams.push('subject=' + encodeURIComponent(subject));

            let url = window.location.pathname;
            if (filterParams.length > 0) {
                url += '?' + filterParams.join('&') + '&page=1';
            } else {
                url += '?page=1';
            }

            window.location.href = url;
        }

        function clearFilters() {
            // Clearing keeps the current division scope
            const base = window.location.pathname;
            const dq = divQuery();
            window.location.href = base + '?' + (dq ? dq + '&' : '') + 'page=1';
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

        const filterSchoolSelect = document.getElementById('filterSchool');
        if (filterSchoolSelect) {
            filterSchoolSelect.addEventListener('change', function() { applyFilters(); });
        }

        const filterClass = document.getElementById('filterClass');
        if (filterClass) {
            filterClass.addEventListener('change', function() { applyFilters(); });
        }

        const filterSubject = document.getElementById('filterSubject');
        if (filterSubject) {
            filterSubject.addEventListener('change', function() { applyFilters(); });
        }

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

        document.addEventListener('click', function(event) {
            const dropdown = document.getElementById('schoolDropdownList');
            if (!event.target.closest('#schoolSearchInput') && !event.target.closest('#schoolDropdownList')) {
                dropdown.style.display = 'none';
            }
        });

        function filterSchools(searchText) {
            const dropdown = document.getElementById('schoolDropdownList');
            const items = dropdown.querySelectorAll('div[onclick*="selectSchool"]');
            const searchLower = searchText.toLowerCase().trim();

            items.forEach(item => {
                const schoolName = item.textContent.toLowerCase();
                if (searchLower === '' || schoolName.includes(searchLower)) {
                    item.style.display = 'block';
                } else {
                    item.style.display = 'none';
                }
            });
        }

        function selectSchool(schoolName, element) {
            const searchInput = document.getElementById('schoolSearchInput');
            const filterSchoolSelect = document.getElementById('filterSchool');
            const dropdown = document.getElementById('schoolDropdownList');

            searchInput.value = schoolName || '';
            filterSchoolSelect.value = schoolName || '';
            dropdown.style.display = 'none';
            searchInput.style.borderColor = '#ddd';

            applyFilters();
        }

        // Populate schools dropdown based on selected district
        function populateSchoolsByDistrict(selectedDistrict) {
            const schoolSearchInput = document.getElementById('schoolSearchInput');
            const schoolDropdownList = document.getElementById('schoolDropdownList');
            const filterSchool = document.getElementById('filterSchool');

            const urlParams = new URLSearchParams(window.location.search);
            const selectedSchool = urlParams.get('school') || '';

            schoolSearchInput.value = selectedSchool;
            schoolDropdownList.innerHTML = '';

            if (filterSchool) {
                while (filterSchool.options.length > 1) {
                    filterSchool.remove(1);
                }
                filterSchool.value = selectedSchool;
            }

            const allOption = document.createElement('div');
            allOption.style.cssText = 'padding: 8px 10px; cursor: pointer;';
            allOption.textContent = '-- All Schools --';
            allOption.onclick = function() { selectSchool('', this); };
            schoolDropdownList.appendChild(allOption);

            if (selectedDistrict && allSchoolsByDistrict[selectedDistrict]) {
                allSchoolsByDistrict[selectedDistrict].forEach(schoolName => {
                    const option = document.createElement('div');
                    option.style.cssText = 'padding: 8px 10px; cursor: pointer;';
                    option.title = schoolName;
                    option.textContent = schoolName;
                    option.onclick = function() { selectSchool(schoolName, this); };
                    schoolDropdownList.appendChild(option);

                    if (filterSchool) {
                        const optionElement = document.createElement('option');
                        optionElement.value = schoolName;
                        optionElement.textContent = schoolName;
                        filterSchool.appendChild(optionElement);
                    }
                });
            } else if (!selectedDistrict) {
                const allSchools = new Set();
                Object.values(allSchoolsByDistrict).forEach(schools => {
                    schools.forEach(school => allSchools.add(school));
                });

                allSchools.forEach(schoolName => {
                    const optionDiv = document.createElement('div');
                    optionDiv.style.cssText = 'padding: 8px 10px; cursor: pointer;';
                    optionDiv.title = schoolName;
                    optionDiv.textContent = schoolName;
                    optionDiv.onclick = function() { selectSchool(schoolName, this); };
                    schoolDropdownList.appendChild(optionDiv);

                    if (filterSchool) {
                        const optionElement = document.createElement('option');
                        optionElement.value = schoolName;
                        optionElement.textContent = schoolName;
                        filterSchool.appendChild(optionElement);
                    }
                });
            }
        }

        // District filter: reload page scoped to division + district
        try {
            const districtFilter = document.getElementById('filterDistrict');
            if (districtFilter) {
                districtFilter.addEventListener('change', function() {
                    const base = window.location.pathname;
                    const dq = divQuery();
                    if (this.value) {
                        window.location.href = base + '?' + (dq ? dq + '&' : '') + 'district=' + encodeURIComponent(this.value) + '&page=1';
                    } else {
                        window.location.href = base + '?' + (dq ? dq + '&' : '') + 'page=1';
                    }
                });
            }
        } catch (error) {
            console.error('Error setting up district filter:', error);
        }

        // On load: restore school selection and populate schools dropdown
        window.addEventListener('load', function() {
            const urlParams = new URLSearchParams(window.location.search);
            const selectedSchool = urlParams.get('school') || '';

            const filterSchool = document.getElementById('filterSchool');
            if (filterSchool) {
                filterSchool.value = selectedSchool;
            }

            const districtFilter = document.getElementById('filterDistrict');
            const currentDistrict = districtFilter ? districtFilter.value : '';
            populateSchoolsByDistrict(currentDistrict);
        });
    </script>
</body>
</html>
