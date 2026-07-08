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
    if (user == null || (!user.getUserType().equals(User.UserType.DIVISION) && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String divisionName = user.getDivisionName();
    StudentDAO studentDAO = new StudentDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    
    // Get all active students from all districts in division
    List<Student> allStudents = studentDAO.getStudentsByDivision(divisionName);
    
    // Extract unique districts from all students
    Set<String> districtSet = new TreeSet<>();
    for (Student student : allStudents) {
        if (student.getDistrict() != null && !student.getDistrict().isEmpty()) {
            districtSet.add(student.getDistrict());
        }
    }
    List<String> distinctDistricts = new ArrayList<>(districtSet);
    
    // Filter: Keep only students with level jumps
    List<Student> levelJumpStudents = new ArrayList<>();
    
    for (Student student : allStudents) {
        boolean hasLevelJump = false;
        
        // Check all subjects and phases for level jumps (>1 level difference)
        // Marathi
        if (student.getPhase1Marathi() != null && student.getPhase2Marathi() != null && student.getPhase2Marathi() - student.getPhase1Marathi() > 1) hasLevelJump = true;
        if (student.getPhase2Marathi() != null && student.getPhase3Marathi() != null && student.getPhase3Marathi() - student.getPhase2Marathi() > 1) hasLevelJump = true;
        if (student.getPhase3Marathi() != null && student.getPhase4Marathi() != null && student.getPhase4Marathi() - student.getPhase3Marathi() > 1) hasLevelJump = true;
        
        // Math
        if (student.getPhase1Math() != null && student.getPhase2Math() != null && student.getPhase2Math() - student.getPhase1Math() > 1) hasLevelJump = true;
        if (student.getPhase2Math() != null && student.getPhase3Math() != null && student.getPhase3Math() - student.getPhase2Math() > 1) hasLevelJump = true;
        if (student.getPhase3Math() != null && student.getPhase4Math() != null && student.getPhase4Math() - student.getPhase3Math() > 1) hasLevelJump = true;
        
        // English
        if (student.getPhase1English() != null && student.getPhase2English() != null && student.getPhase2English() - student.getPhase1English() > 1) hasLevelJump = true;
        if (student.getPhase2English() != null && student.getPhase3English() != null && student.getPhase3English() - student.getPhase2English() > 1) hasLevelJump = true;
        if (student.getPhase3English() != null && student.getPhase4English() != null && student.getPhase4English() - student.getPhase3English() > 1) hasLevelJump = true;
        
        if (hasLevelJump) {
            levelJumpStudents.add(student);
        }
    }
    
    // Load school names
    Map<String, String> schoolNameCache = new HashMap<>();
    Set<String> allUdiseNumbers = new HashSet<>();
    for (Student student : levelJumpStudents) {
        if (student.getUdiseNo() != null) {
            allUdiseNumbers.add(student.getUdiseNo());
        }
    }
    
    if (!allUdiseNumbers.isEmpty()) {
        try {
            List<School> schools = schoolDAO.getSchoolsByUdises(new ArrayList<>(allUdiseNumbers));
            if (schools != null) {
                for (School school : schools) {
                    schoolNameCache.put(school.getUdiseNo(), school.getSchoolName() + " (" + school.getUdiseNo() + ")");
                }
            }
        } catch (Exception e) {
            System.err.println("Error loading schools: " + e.getMessage());
        }
    }
    
    // Calculate chart data
    
    // 1. District Distribution
    Map<String, Integer> districtCount = new TreeMap<>();
    for (Student student : levelJumpStudents) {
        String district = student.getDistrict();
        if (district != null && !district.isEmpty()) {
            districtCount.put(district, districtCount.getOrDefault(district, 0) + 1);
        }
    }
    
    // 2. Subject Analysis
    int marathiJumps = 0, mathJumps = 0, englishJumps = 0;
    for (Student student : levelJumpStudents) {
        // Marathi
        if ((student.getPhase1Marathi() != null && student.getPhase2Marathi() != null && student.getPhase2Marathi() - student.getPhase1Marathi() > 1) ||
            (student.getPhase2Marathi() != null && student.getPhase3Marathi() != null && student.getPhase3Marathi() - student.getPhase2Marathi() > 1) ||
            (student.getPhase3Marathi() != null && student.getPhase4Marathi() != null && student.getPhase4Marathi() - student.getPhase3Marathi() > 1)) {
            marathiJumps++;
        }
        // Math
        if ((student.getPhase1Math() != null && student.getPhase2Math() != null && student.getPhase2Math() - student.getPhase1Math() > 1) ||
            (student.getPhase2Math() != null && student.getPhase3Math() != null && student.getPhase3Math() - student.getPhase2Math() > 1) ||
            (student.getPhase3Math() != null && student.getPhase4Math() != null && student.getPhase4Math() - student.getPhase3Math() > 1)) {
            mathJumps++;
        }
        // English
        if ((student.getPhase1English() != null && student.getPhase2English() != null && student.getPhase2English() - student.getPhase1English() > 1) ||
            (student.getPhase2English() != null && student.getPhase3English() != null && student.getPhase3English() - student.getPhase2English() > 1) ||
            (student.getPhase3English() != null && student.getPhase4English() != null && student.getPhase4English() - student.getPhase3English() > 1)) {
            englishJumps++;
        }
    }
    
    // 3. Class Distribution
    Map<String, Integer> classCount = new TreeMap<>();
    for (Student student : levelJumpStudents) {
        String studentClass = student.getStudentClass();
        if (studentClass != null && !studentClass.isEmpty()) {
            classCount.put(studentClass, classCount.getOrDefault(studentClass, 0) + 1);
        }
    }
    
    // 4. Phase Transitions
    int phase1To2 = 0, phase2To3 = 0, phase3To4 = 0;
    for (Student student : levelJumpStudents) {
        // Phase 1 to 2
        if ((student.getPhase1Marathi() != null && student.getPhase2Marathi() != null && student.getPhase2Marathi() - student.getPhase1Marathi() > 1) ||
            (student.getPhase1Math() != null && student.getPhase2Math() != null && student.getPhase2Math() - student.getPhase1Math() > 1) ||
            (student.getPhase1English() != null && student.getPhase2English() != null && student.getPhase2English() - student.getPhase1English() > 1)) {
            phase1To2++;
        }
        // Phase 2 to 3
        if ((student.getPhase2Marathi() != null && student.getPhase3Marathi() != null && student.getPhase3Marathi() - student.getPhase2Marathi() > 1) ||
            (student.getPhase2Math() != null && student.getPhase3Math() != null && student.getPhase3Math() - student.getPhase2Math() > 1) ||
            (student.getPhase2English() != null && student.getPhase3English() != null && student.getPhase3English() - student.getPhase2English() > 1)) {
            phase2To3++;
        }
        // Phase 3 to 4
        if ((student.getPhase3Marathi() != null && student.getPhase4Marathi() != null && student.getPhase4Marathi() - student.getPhase3Marathi() > 1) ||
            (student.getPhase3Math() != null && student.getPhase4Math() != null && student.getPhase4Math() - student.getPhase3Math() > 1) ||
            (student.getPhase3English() != null && student.getPhase4English() != null && student.getPhase4English() - student.getPhase3English() > 1)) {
            phase3To4++;
        }
    }
    
    // 5. Top 10 Schools
    Map<String, Integer> schoolCount = new HashMap<>();
    for (Student student : levelJumpStudents) {
        String udiseNo = student.getUdiseNo();
        String schoolName = schoolNameCache.getOrDefault(udiseNo, udiseNo);
        schoolCount.put(schoolName, schoolCount.getOrDefault(schoolName, 0) + 1);
    }
    
    List<Map.Entry<String, Integer>> topSchools = schoolCount.entrySet().stream()
        .sorted((a, b) -> b.getValue().compareTo(a.getValue()))
        .limit(10)
        .collect(Collectors.toList());
    
    // 6. District vs Subject Matrix
    Map<String, Map<String, Integer>> districtSubjectMatrix = new TreeMap<>();
    for (String district : districtCount.keySet()) {
        districtSubjectMatrix.put(district, new HashMap<>());
        districtSubjectMatrix.get(district).put("Marathi", 0);
        districtSubjectMatrix.get(district).put("Math", 0);
        districtSubjectMatrix.get(district).put("English", 0);
    }
    
    for (Student student : levelJumpStudents) {
        String district = student.getDistrict();
        if (district != null && districtSubjectMatrix.containsKey(district)) {
            if ((student.getPhase1Marathi() != null && student.getPhase2Marathi() != null && student.getPhase2Marathi() - student.getPhase1Marathi() > 1) ||
                (student.getPhase2Marathi() != null && student.getPhase3Marathi() != null && student.getPhase3Marathi() - student.getPhase2Marathi() > 1) ||
                (student.getPhase3Marathi() != null && student.getPhase4Marathi() != null && student.getPhase4Marathi() - student.getPhase3Marathi() > 1)) {
                districtSubjectMatrix.get(district).put("Marathi", districtSubjectMatrix.get(district).get("Marathi") + 1);
            }
            if ((student.getPhase1Math() != null && student.getPhase2Math() != null && student.getPhase2Math() - student.getPhase1Math() > 1) ||
                (student.getPhase2Math() != null && student.getPhase3Math() != null && student.getPhase3Math() - student.getPhase2Math() > 1) ||
                (student.getPhase3Math() != null && student.getPhase4Math() != null && student.getPhase4Math() - student.getPhase3Math() > 1)) {
                districtSubjectMatrix.get(district).put("Math", districtSubjectMatrix.get(district).get("Math") + 1);
            }
            if ((student.getPhase1English() != null && student.getPhase2English() != null && student.getPhase2English() - student.getPhase1English() > 1) ||
                (student.getPhase2English() != null && student.getPhase3English() != null && student.getPhase3English() - student.getPhase2English() > 1) ||
                (student.getPhase3English() != null && student.getPhase4English() != null && student.getPhase4English() - student.getPhase3English() > 1)) {
                districtSubjectMatrix.get(district).put("English", districtSubjectMatrix.get(district).get("English") + 1);
            }
        }
    }
    
    // 7. District Percentages with Ranking
    Map<String, Double> districtPercentage = new LinkedHashMap<>();
    int totalStudents = levelJumpStudents.size();
    
    // Sort districts by count (descending) for ranking
    List<Map.Entry<String, Integer>> sortedDistricts = new ArrayList<>(districtCount.entrySet());
    sortedDistricts.sort((a, b) -> b.getValue().compareTo(a.getValue()));
    
    // Calculate percentages and create ranking
    Map<String, Integer> districtRank = new HashMap<>();
    int rank = 1;
    for (Map.Entry<String, Integer> entry : sortedDistricts) {
        String district = entry.getKey();
        double percentage = (totalStudents > 0) ? (entry.getValue() * 100.0) / totalStudents : 0;
        districtPercentage.put(district, percentage);
        districtRank.put(district, rank);
        rank++;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Level Jump Analytics - <%= divisionName %></title>
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
            max-width: 1400px;
            margin: 0 auto;
        }
        
        .header {
            background: white;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            color: #333;
            font-size: 28px;
        }
        
        .header-subtitle {
            color: #666;
            font-size: 14px;
            margin-top: 5px;
        }
        
        .back-button {
            display: inline-block;
            padding: 10px 20px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-weight: 600;
            cursor: pointer;
            border: none;
            transition: background 0.3s;
        }
        
        .back-button:hover {
            background: #764ba2;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        
        .stat-card .number {
            font-size: 32px;
            font-weight: bold;
            color: #667eea;
        }
        
        .stat-card .label {
            color: #666;
            margin-top: 10px;
            font-size: 14px;
        }
        
        .charts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 25px;
            margin-bottom: 30px;
        }
        
        .chart-container {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .chart-title {
            font-size: 18px;
            font-weight: 600;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        
        .chart-wrapper {
            position: relative;
            height: 400px;
            overflow: visible;
        }
        
        .chart-wrapper.schools-chart {
            height: 600px;
            overflow: visible;
        }
        
        .chart-container.schools-full-width {
            grid-column: 1 / -1;
        }
        
        .heatmap-container {
            grid-column: 1 / -1;
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .heatmap-title {
            font-size: 18px;
            font-weight: 600;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        
        .heatmap {
            display: grid;
            gap: 2px;
            background: #f5f5f5;
            padding: 10px;
            border-radius: 5px;
            overflow-x: auto;
        }
        
        .heatmap-row {
            display: grid;
            grid-template-columns: 180px repeat(3, 1fr);
            gap: 2px;
            min-width: max-content;
        }
        
        .heatmap-cell {
            padding: 15px 10px;
            text-align: center;
            font-weight: 500;
            border-radius: 3px;
            color: white;
            font-size: 13px;
            min-width: 80px;
            display: flex;
            align-items: center;
            justify-content: center;
            word-wrap: break-word;
            white-space: normal;
        }
        
        .heatmap-cell.header {
            background: #667eea;
            color: white;
            font-weight: 600;
            font-size: 13px;
        }
        
        .heatmap-cell.label {
            background: #999;
            color: white;
            text-align: center;
            font-weight: 500;
            padding: 15px 5px;
            word-break: break-word;
            white-space: normal;
            font-size: 12px;
        }
        
        .heatmap-cell.low {
            background: #90EE90;
            color: #333;
        }
        
        .heatmap-cell.medium {
            background: #FFD700;
            color: #333;
        }
        
        .heatmap-cell.high {
            background: #FF6B6B;
            color: white;
        }
        
        .district-percentage-container {
            grid-column: 1 / -1;
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            margin-bottom: 30px;
        }
        
        .district-percentage-title {
            font-size: 18px;
            font-weight: 600;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        
        .total-students-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            text-align: center;
        }
        
        .total-students-card .number {
            font-size: 48px;
            font-weight: bold;
        }
        
        .total-students-card .label {
            font-size: 16px;
            margin-top: 10px;
            opacity: 0.9;
        }
        
        .district-cards-wrapper {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        
        .district-card {
            background: white;
            padding: 25px;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
            border-top: 4px solid #667eea;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        
        .district-card:hover {
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.12);
            transform: translateY(-2px);
        }
        
        .district-card.high {
            border-top-color: #2ecc71;
            background: linear-gradient(135deg, rgba(46, 204, 113, 0.05) 0%, rgba(46, 204, 113, 0.02) 100%);
        }
        
        .district-card.medium {
            border-top-color: #f39c12;
            background: linear-gradient(135deg, rgba(243, 156, 18, 0.05) 0%, rgba(243, 156, 18, 0.02) 100%);
        }
        
        .district-card.low {
            border-top-color: #e74c3c;
            background: linear-gradient(135deg, rgba(231, 76, 60, 0.05) 0%, rgba(231, 76, 60, 0.02) 100%);
        }
        
        .district-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 15px;
        }
        
        .district-rank-badge {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            width: 50px;
            height: 50px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            font-weight: bold;
            box-shadow: 0 4px 8px rgba(102, 126, 234, 0.3);
        }
        
        .district-name-large {
            font-size: 20px;
            font-weight: 700;
            color: #333;
            margin-bottom: 15px;
            flex: 1;
            padding-right: 10px;
        }
        
        .district-stats-large {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-bottom: 15px;
        }
        
        .stat-box {
            background: white;
            padding: 12px;
            border-radius: 8px;
            text-align: center;
            border: 1px solid #e0e0e0;
        }
        
        .stat-box .number {
            font-size: 24px;
            font-weight: bold;
            color: #667eea;
        }
        
        .stat-box .label {
            font-size: 12px;
            color: #999;
            margin-top: 5px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .percentage-bar-large {
            width: 100%;
            height: 28px;
            background: #e8e8e8;
            border-radius: 14px;
            overflow: hidden;
            display: flex;
            align-items: center;
            justify-content: flex-end;
            padding-right: 10px;
            margin-top: 10px;
        }
        
        .percentage-fill-large {
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            height: 100%;
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 13px;
            font-weight: 700;
            padding: 0 12px;
            transition: width 0.5s ease;
        }
        
        .district-card.high .percentage-fill-large {
            background: linear-gradient(90deg, #2ecc71 0%, #27ae60 100%);
        }
        
        .district-card.medium .percentage-fill-large {
            background: linear-gradient(90deg, #f39c12 0%, #e67e22 100%);
        }
        
        .district-card.low .percentage-fill-large {
            background: linear-gradient(90deg, #e74c3c 0%, #c0392b 100%);
        }
        
        .performance-label {
            font-size: 12px;
            font-weight: 600;
            margin-top: 10px;
            padding: 6px 12px;
            border-radius: 20px;
            display: inline-block;
            margin-right: 10px;
        }
        
        .performance-label.high {
            background: #d5f4e6;
            color: #27ae60;
        }
        
        .performance-label.medium {
            background: #fce8cd;
            color: #e67e22;
        }
        
        .performance-label.low {
            background: #fadbd8;
            color: #c0392b;
        }
        
        .district-list {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 15px;
        }
        
        .district-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .district-name {
            font-weight: 600;
            color: #333;
            flex: 1;
        }
        
        .district-stats {
            display: flex;
            gap: 20px;
            align-items: center;
        }
        
        .student-count {
            background: white;
            padding: 8px 12px;
            border-radius: 6px;
            font-weight: 600;
            color: #667eea;
            min-width: 50px;
            text-align: center;
        }
        
        .percentage-bar {
            width: 150px;
            height: 24px;
            background: #e0e0e0;
            border-radius: 12px;
            overflow: hidden;
            display: flex;
            align-items: center;
            justify-content: flex-end;
            padding-right: 8px;
        }
        
        .percentage-fill {
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            height: 100%;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 12px;
            font-weight: 600;
            padding: 0 8px;
        }
        
        .footer {
            background: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            color: #666;
            font-size: 13px;
        }
        
        @media (max-width: 768px) {
            .charts-grid {
                grid-template-columns: 1fr;
            }
            
            .header {
                flex-direction: column;
                text-align: center;
                gap: 15px;
            }
            
            .heatmap-row {
                grid-template-columns: auto repeat(3, 1fr) !important;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div>
                <h1>📊 Level Jump Analytics Dashboard</h1>
                <p class="header-subtitle"><%= divisionName %> Division | Total Students with Level Jumps: <%= levelJumpStudents.size() %></p>
            </div>
            <a href="<%= request.getContextPath() %>/division-dashboard.jsp" class="back-button">← Back to Dashboard</a>
        </div>
        
        <!-- Stats Cards -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="number"><%= levelJumpStudents.size() %></div>
                <div class="label">Total Students</div>
            </div>
            <div class="stat-card">
                <div class="number"><%= districtCount.size() %></div>
                <div class="label">Districts</div>
            </div>
            <div class="stat-card">
                <div class="number"><%= schoolCount.size() %></div>
                <div class="label">Schools</div>
            </div>
            <div class="stat-card">
                <div class="number"><%= classCount.size() %></div>
                <div class="label">Classes</div>
            </div>
            <div class="stat-card">
                <div class="number"><%= (marathiJumps + mathJumps + englishJumps) / 3 %></div>
                <div class="label">Avg per Subject</div>
            </div>
        </div>
        
        <!-- District Percentage Section -->
        <div class="charts-grid">
            <div class="district-percentage-container">
                <div class="district-percentage-title">📊 District-wise Distribution & Performance</div>
                
                <div class="total-students-card">
                    <div class="number"><%= totalStudents %></div>
                    <div class="label">Total Students with Level Jumps</div>
                </div>
                
                <div class="district-cards-wrapper">
                    <% for (Map.Entry<String, Double> entry : districtPercentage.entrySet()) { 
                        String districtName = entry.getKey();
                        double percentage = entry.getValue();
                        int count = districtCount.get(districtName);
                        int districtRankPosition = districtRank.get(districtName);
                        
                        // Determine performance level
                        String performanceClass = "low";
                        String performanceLabel = "Below Average";
                        String rankEmoji = "🥇";
                        
                        if (districtRankPosition == 1) {
                            rankEmoji = "🥇";
                        } else if (districtRankPosition == 2) {
                            rankEmoji = "🥈";
                        } else if (districtRankPosition == 3) {
                            rankEmoji = "🥉";
                        }
                        
                        // Color code based on percentage (high: >30%, medium: 15-30%, low: <15%)
                        if (percentage >= 30) {
                            performanceClass = "high";
                            performanceLabel = "High Performance";
                        } else if (percentage >= 15) {
                            performanceClass = "medium";
                            performanceLabel = "Medium Performance";
                        }
                    %>
                    <div class="district-card <%= performanceClass %>">
                        <div class="district-header">
                            <div class="district-name-large"><%= districtName %></div>
                            <div class="district-rank-badge"><%= rankEmoji %></div>
                        </div>
                        
                        <div class="district-stats-large">
                            <div class="stat-box">
                                <div class="number"><%= count %></div>
                                <div class="label">Students</div>
                            </div>
                            <div class="stat-box">
                                <div class="number"><%= String.format("%.1f", percentage) %>%</div>
                                <div class="label">Share</div>
                            </div>
                        </div>
                        
                        <div class="percentage-bar-large">
                            <div class="percentage-fill-large" style="width: <%= percentage %>%;">
                                <%= String.format("%.1f%%", percentage) %>
                            </div>
                        </div>
                        
                        <span class="performance-label <%= performanceClass %>"><%= performanceLabel %></span>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>
        
        <!-- Charts -->
        <div class="charts-grid">
            <!-- 1. District Distribution -->
            <div class="chart-container">
                <div class="chart-title">📍 Distribution by District</div>
                <div class="chart-wrapper">
                    <canvas id="districtChart"></canvas>
                </div>
            </div>
            
            <!-- 2. Subject Analysis -->
            <div class="chart-container">
                <div class="chart-title">📚 Subject Analysis</div>
                <div class="chart-wrapper">
                    <canvas id="subjectChart"></canvas>
                </div>
            </div>
            
            <!-- 3. Class Distribution -->
            <div class="chart-container">
                <div class="chart-title">🎓 Class-wise Distribution</div>
                <div class="chart-wrapper">
                    <canvas id="classChart"></canvas>
                </div>
            </div>
            
            <!-- 4. Phase Transitions -->
            <div class="chart-container">
                <div class="chart-title">📈 Phase Transition Analysis</div>
                <div class="chart-wrapper">
                    <canvas id="phaseChart"></canvas>
                </div>
            </div>
            
            <!-- 5. Top Schools -->
            <div class="chart-container schools-full-width">
                <div class="chart-title">🏆 Top 10 Schools</div>
                <div class="chart-wrapper schools-chart">
                    <canvas id="schoolChart"></canvas>
                </div>
            </div>
        </div>
        
        <!-- 6. Heatmap -->
        <div class="heatmap-container">
            <div class="heatmap-title">🔥 District vs Subject Heatmap</div>
            <% 
                int maxValue = 0;
                for (Map.Entry<String, Map<String, Integer>> entry : districtSubjectMatrix.entrySet()) {
                    for (Integer val : entry.getValue().values()) {
                        maxValue = Math.max(maxValue, val);
                    }
                }
                
                if (districtSubjectMatrix.isEmpty()) {
                    out.println("<div style='padding: 20px; color: #999;'>No data available for heatmap</div>");
                } else {
            %>
            <div class="heatmap">
                <div class="heatmap-row">
                    <div class="heatmap-cell header">District</div>
                    <div class="heatmap-cell header">Marathi</div>
                    <div class="heatmap-cell header">Math</div>
                    <div class="heatmap-cell header">English</div>
                </div>
                <% 
                    for (Map.Entry<String, Map<String, Integer>> entry : districtSubjectMatrix.entrySet()) {
                        String district = entry.getKey();
                        Map<String, Integer> subjects = entry.getValue();
                %>
                <div class="heatmap-row">
                    <div class="heatmap-cell label"><%= district %></div>
                    <%
                        for (String subject : new String[]{"Marathi", "Math", "English"}) {
                            int val = subjects.get(subject);
                            String intensity = "low";
                            if (maxValue > 0) {
                                intensity = val == 0 ? "low" : (val < maxValue / 2 ? "medium" : "high");
                            }
                    %>
                    <div class="heatmap-cell <%= intensity %>"><%= val %></div>
                    <%
                        }
                    %>
                </div>
                <% } %>
            </div>
            <% } %>
        </div>
        
        <!-- Footer -->
        <div class="footer">
            <p>Last updated: <%= new java.text.SimpleDateFormat("dd MMM yyyy HH:mm:ss").format(new java.util.Date()) %></p>
        </div>
    </div>
    
    <script>
        // Wait for DOM to be ready and Chart.js to be loaded
        function initializeCharts() {
            // Check if Chart library is available
            if (typeof Chart === 'undefined') {
                console.error('Chart.js library not loaded');
                setTimeout(initializeCharts, 500);
                return;
            }
            
            // Color scheme
            const chartColors = {
                primary: '#667eea',
                secondary: '#764ba2',
                success: '#51cf66',
                danger: '#ff6b6b',
                warning: '#ffd93d',
                info: '#4ecdc4'
            };
            
            const defaultOptions = {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        labels: {
                            font: { size: 12 },
                            padding: 15,
                            color: '#333'  // Dark text for legend
                        }
                    }
                }
            };
            
            try {
                // 1. District Distribution Chart
                const districtChartElement = document.getElementById('districtChart');
                if (districtChartElement) {
                    const districtCtx = districtChartElement.getContext('2d');
                    new Chart(districtCtx, {
                        type: 'bar',
                        data: {
                            labels: [<% for (String d : districtCount.keySet()) { %>'<%= d %>',<% } %>],
                            datasets: [{
                                label: 'Number of Students',
                                data: [<% for (Integer c : districtCount.values()) { %><%= c %>,<% } %>],
                                backgroundColor: chartColors.primary,
                                borderColor: chartColors.secondary,
                                borderWidth: 2,
                                borderRadius: 5
                            }]
                        },
                        options: {
                            ...defaultOptions,
                            indexAxis: 'y',
                            plugins: {
                                legend: { display: false }
                            },
                            scales: {
                                x: {
                                    beginAtZero: true,
                                    ticks: { stepSize: 1 }
                                },
                                y: {
                                    ticks: {
                                        color: '#333'
                                    }
                                }
                            }
                        }
                    });
                    console.log('✓ District chart initialized');
                }
            } catch (e) {
                console.error('Error initializing district chart:', e);
            }
            
            try {
                // 2. Subject Analysis Chart
                const subjectChartElement = document.getElementById('subjectChart');
                if (subjectChartElement) {
                    const subjectCtx = subjectChartElement.getContext('2d');
                    new Chart(subjectCtx, {
                        type: 'doughnut',
                        data: {
                            labels: ['Marathi', 'Math', 'English'],
                            datasets: [{
                                data: [<%= marathiJumps %>, <%= mathJumps %>, <%= englishJumps %>],
                                backgroundColor: [
                                    chartColors.primary,
                                    chartColors.secondary,
                                    chartColors.success
                                ],
                                borderWidth: 2,
                                borderColor: '#ffffff'
                            }]
                        },
                        options: {
                            ...defaultOptions,
                            plugins: {
                                legend: {
                                    position: 'bottom'
                                }
                            }
                        }
                    });
                    console.log('✓ Subject chart initialized');
                }
            } catch (e) {
                console.error('Error initializing subject chart:', e);
            }
            
            try {
                // 3. Class Distribution Chart
                const classChartElement = document.getElementById('classChart');
                if (classChartElement) {
                    const classCtx = classChartElement.getContext('2d');
                    new Chart(classCtx, {
                        type: 'bar',
                        data: {
                            labels: [<% for (String c : classCount.keySet()) { %>'<%= c %>',<% } %>],
                            datasets: [{
                                label: 'Number of Students',
                                data: [<% for (Integer c : classCount.values()) { %><%= c %>,<% } %>],
                                backgroundColor: [
                                    chartColors.primary,
                                    chartColors.secondary,
                                    chartColors.success,
                                    chartColors.danger,
                                    chartColors.warning,
                                    chartColors.info
                                ],
                                borderWidth: 2,
                                borderRadius: 5
                            }]
                        },
                        options: {
                            ...defaultOptions,
                            plugins: {
                                legend: { display: false }
                            },
                            scales: {
                                y: {
                                    beginAtZero: true,
                                    ticks: { stepSize: 1, color: '#333' }
                                },
                                x: {
                                    ticks: { color: '#333' }
                                }
                            }
                        }
                    });
                    console.log('✓ Class chart initialized');
                }
            } catch (e) {
                console.error('Error initializing class chart:', e);
            }
            
            try {
                // 4. Phase Transitions Chart
                const phaseChartElement = document.getElementById('phaseChart');
                if (phaseChartElement) {
                    const phaseCtx = phaseChartElement.getContext('2d');
                    new Chart(phaseCtx, {
                        type: 'bar',
                        data: {
                            labels: ['Phase 1→2', 'Phase 2→3', 'Phase 3→4'],
                            datasets: [{
                                label: 'Number of Students',
                                data: [<%= phase1To2 %>, <%= phase2To3 %>, <%= phase3To4 %>],
                                backgroundColor: [
                                    chartColors.primary,
                                    chartColors.secondary,
                                    chartColors.success
                                ],
                                borderWidth: 2,
                                borderRadius: 5
                            }]
                        },
                        options: {
                            ...defaultOptions,
                            plugins: {
                                legend: { display: false }
                            },
                            scales: {
                                y: {
                                    beginAtZero: true,
                                    ticks: { stepSize: 1, color: '#333' }
                                },
                                x: {
                                    ticks: { color: '#333' }
                                }
                            }
                        }
                    });
                    console.log('✓ Phase chart initialized');
                }
            } catch (e) {
                console.error('Error initializing phase chart:', e);
            }
            
            try {
                // 5. Top Schools Chart
                const schoolChartElement = document.getElementById('schoolChart');
                if (schoolChartElement) {
                    const schoolCtx = schoolChartElement.getContext('2d');
                    new Chart(schoolCtx, {
                        type: 'bar',
                        data: {
                            labels: [<% for (Map.Entry<String, Integer> entry : topSchools) { %>'<%= entry.getKey() %>',<% } %>],
                            datasets: [{
                                label: 'Students',
                                data: [<% for (Map.Entry<String, Integer> entry : topSchools) { %><%= entry.getValue() %>,<% } %>],
                                backgroundColor: chartColors.primary,
                                borderColor: chartColors.secondary,
                                borderWidth: 2,
                                borderRadius: 3
                            }]
                        },
                        options: {
                            ...defaultOptions,
                            indexAxis: 'y',
                            layout: {
                                padding: {
                                    left: 150,
                                    right: 20,
                                    top: 10,
                                    bottom: 10
                                }
                            },
                            plugins: {
                                legend: { display: false }
                            },
                            scales: {
                                x: {
                                    beginAtZero: true,
                                    ticks: { stepSize: 1, color: '#333' }
                                },
                                y: {
                                    ticks: {
                                        font: { size: 11 },
                                        padding: 5,
                                        color: '#333'  // Dark gray/black text
                                    },
                                    clip: false
                                }
                            }
                        }
                    });
                    console.log('✓ School chart initialized');
                }
            } catch (e) {
                console.error('Error initializing school chart:', e);
            }
            
            console.log('✓ All charts initialized successfully');
        }
        
        // Initialize charts when DOM is ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initializeCharts);
        } else {
            initializeCharts();
        }
    </script>
</body>
</html>
