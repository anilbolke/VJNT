<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.dao.PhaseApprovalDAO" %>
<%@ page import="com.vjnt.dao.PalakMelavaDAO" %>
<%@ page import="com.vjnt.model.Student" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="com.vjnt.model.PhaseApproval" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.HEAD_MASTER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    
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
    
    // Get school name from schools table
    School school = schoolDAO.getSchoolByUdise(udiseNo);
    String schoolName = school != null ? school.getSchoolName() : "Unknown School";
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
        // Skip students with all default values (0) - they are not assessed yet
        boolean hasValidData = !(student.getMarathiAksharaLevel() == 0 && 
                                 student.getMathAksharaLevel() == 0 && 
                                 student.getEnglishAksharaLevel() == 0);
        
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
        
        // Only count students with valid assessment data in statistics
        if (hasValidData) {
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
    }
    
    // Calculate phase completion percentages
    int phase1Completion = studentDAO.getPhaseCompletionPercentage(udiseNo, 1);
    int phase2Completion = studentDAO.getPhaseCompletionPercentage(udiseNo, 2);
    int phase3Completion = studentDAO.getPhaseCompletionPercentage(udiseNo, 3);
    int phase4Completion = studentDAO.getPhaseCompletionPercentage(udiseNo, 4);
    
    boolean phase1Complete = studentDAO.isPhaseComplete(udiseNo, 1);
    boolean phase2Complete = studentDAO.isPhaseComplete(udiseNo, 2);
    boolean phase3Complete = studentDAO.isPhaseComplete(udiseNo, 3);
    boolean phase4Complete = studentDAO.isPhaseComplete(udiseNo, 4);
    
    // Get phase approval status
    PhaseApprovalDAO approvalDAO = new PhaseApprovalDAO();
    PhaseApproval phase1Approval = approvalDAO.getPhaseApproval(udiseNo, 1);
    PhaseApproval phase2Approval = approvalDAO.getPhaseApproval(udiseNo, 2);
    PhaseApproval phase3Approval = approvalDAO.getPhaseApproval(udiseNo, 3);
    PhaseApproval phase4Approval = approvalDAO.getPhaseApproval(udiseNo, 4);
    
    int pendingApprovalsCount = approvalDAO.getPendingApprovalCount(udiseNo);
    
    // Get Palak Melava pending count
    PalakMelavaDAO melavaDAO = new PalakMelavaDAO();
    int palakMelavaPendingCount = melavaDAO.getPendingCount(udiseNo);
    
    // Separate students by phase completion status
    Map<Integer, List<com.vjnt.model.Student>> phaseCompletedStudents = new HashMap<>();
    Map<Integer, List<com.vjnt.model.Student>> phasePendingStudents = new HashMap<>();
    
    for (int phase = 1; phase <= 4; phase++) {
        phaseCompletedStudents.put(phase, new ArrayList<>());
        phasePendingStudents.put(phase, new ArrayList<>());
    }
    
    for (com.vjnt.model.Student student : allStudents) {
        // Check Phase 1 - Based on save button click (phase1_date), includes students with all 0s if saved
        if (student.getPhase1Date() != null) {
            phaseCompletedStudents.get(1).add(student);
        } else {
            phasePendingStudents.get(1).add(student);
        }
        
        // Check Phase 2 - Based on save button click (phase2_date), includes students with all 0s if saved
        if (student.getPhase2Date() != null) {
            phaseCompletedStudents.get(2).add(student);
        } else {
            phasePendingStudents.get(2).add(student);
        }
        
        // Check Phase 3 - Based on save button click (phase3_date), includes students with all 0s if saved
        if (student.getPhase3Date() != null) {
            phaseCompletedStudents.get(3).add(student);
        } else {
            phasePendingStudents.get(3).add(student);
        }
        
        // Check Phase 4 - Based on save button click (phase4_date), includes students with all 0s if saved
        if (student.getPhase4Date() != null) {
            phaseCompletedStudents.get(4).add(student);
        } else {
            phasePendingStudents.get(4).add(student);
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= schoolName %> - UDISE <%= udiseNo %></title>
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
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px 30px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            position: sticky;
            top: 0;
            z-index: 1000;
        }
        
        .header-content {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .header-left {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .school-icon {
            font-size: 48px;
            animation: bounce 2s infinite;
        }
        
        @keyframes bounce {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-10px); }
        }
        
        .header-title {
            display: flex;
            flex-direction: column;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 5px;
            font-weight: 700;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }
        
        .header-subtitle {
            font-size: 14px;
            opacity: 0.9;
            font-weight: 400;
        }
        
        .header-info {
            display: flex;
            align-items: center;
            gap: 15px;
            flex-wrap: wrap;
        }
        
        .user-badge {
            background: rgba(255,255,255,0.15);
            padding: 10px 15px;
            border-radius: 25px;
            font-size: 14px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
        }
        
        .user-badge strong {
            font-weight: 600;
        }
        
        .header-actions {
            display: flex;
            gap: 10px;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 25px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }
        
        .btn-logout {
            background: #ff4757;
            color: white;
        }
        
        .btn-logout:hover {
            background: #ff3838;
        }
        
        .btn-change-password {
            background: rgba(255,255,255,0.2);
            color: white;
            border: 2px solid rgba(255,255,255,0.3);
        }
        
        .btn-change-password:hover {
            background: rgba(255,255,255,0.3);
            border-color: rgba(255,255,255,0.5);
        }
        
        .container {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 20px 30px 20px;
        }
        
        .welcome-card {
            background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
            color: white;
            padding: 25px 30px;
            border-radius: 15px;
            margin-bottom: 25px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 20px;
        }
        
        .welcome-content h2 {
            font-size: 26px;
            margin-bottom: 8px;
            font-weight: 700;
        }
        
        .welcome-content p {
            font-size: 15px;
            opacity: 0.95;
        }
        
        .welcome-icon {
            font-size: 64px;
            animation: wave 3s infinite;
        }
        
        @keyframes wave {
            0%, 100% { transform: rotate(0deg); }
            25% { transform: rotate(20deg); }
            75% { transform: rotate(-20deg); }
        }
        
        .breadcrumb {
            background: white;
            padding: 15px 25px;
            border-radius: 12px;
            margin-bottom: 25px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.08);
            border-left: 5px solid #667eea;
        }
        
        .breadcrumb span {
            color: #666;
        }
        
        .breadcrumb strong {
            color: #333;
        }
        
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
            gap: 12px;
            margin-bottom: 20px;
        }
        
        .stat-card {
            background: white;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
            transition: all 0.2s;
            border-left: 3px solid transparent;
            text-align: center;
        }
        
        .stat-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        
        .stat-card:nth-child(1) { border-left-color: #667eea; }
        .stat-card:nth-child(2) { border-left-color: #f093fb; }
        .stat-card:nth-child(3) { border-left-color: #4facfe; }
        .stat-card:nth-child(4) { border-left-color: #43e97b; }
        .stat-card:nth-child(5) { border-left-color: #fa709a; }
        
        .stat-icon {
            font-size: 28px;
            margin-bottom: 6px;
            display: block;
        }
        
        .stat-value {
            font-size: 26px;
            font-weight: 700;
            color: #2d3748;
            margin-bottom: 4px;
        }
        
        .stat-label {
            font-size: 11px;
            color: #718096;
            font-weight: 500;
        }
        
        .section {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            margin-bottom: 30px;
            border: 1px solid rgba(102, 126, 234, 0.1);
        }
        
        .section-title {
            font-size: 22px;
            color: #333;
            margin-bottom: 25px;
            padding-bottom: 15px;
            border-bottom: 3px solid transparent;
            border-image: linear-gradient(90deg, #667eea, #764ba2) 1;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
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
            background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
            padding: 25px;
            border-radius: 15px;
            margin-bottom: 15px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.06);
            border: 2px solid transparent;
            transition: all 0.3s;
        }
        
        .level-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.1);
            border-color: rgba(102, 126, 234, 0.3);
        }
        
        .level-title {
            font-size: 18px;
            font-weight: 700;
            color: #333;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 3px solid;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .level-card:nth-child(1) .level-title { border-color: #ff9a9e; }
        .level-card:nth-child(2) .level-title { border-color: #a18cd1; }
        .level-card:nth-child(3) .level-title { border-color: #fbc2eb; }
        
        .level-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 15px;
            border-radius: 8px;
            margin-bottom: 8px;
            background: white;
            transition: all 0.2s;
        }
        
        .level-row:hover {
            background: #f8f9fa;
            transform: translateX(5px);
        }
        
        .level-row:last-child {
            margin-bottom: 0;
        }
        
        .level-name {
            font-size: 14px;
            color: #555;
            font-weight: 500;
        }
        
        .level-count {
            font-weight: 700;
            font-size: 16px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
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
        
        /* Responsive Design */
        @media (max-width: 768px) {
            .header-content {
                flex-direction: column;
                text-align: center;
            }
            
            .header-left {
                flex-direction: column;
            }
            
            .dashboard-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 10px;
            }
            
            .stat-card {
                padding: 12px;
            }
            
            .stat-icon {
                font-size: 24px;
                margin-bottom: 4px;
            }
            
            .stat-value {
                font-size: 22px;
            }
            
            .stat-label {
                font-size: 10px;
            }
            
            .welcome-card {
                flex-direction: column;
                text-align: center;
            }
            
            .grid-3 {
                grid-template-columns: 1fr;
            }
            
            .quick-action-card {
                padding: 20px;
            }
        }
        
        @media (max-width: 480px) {
            .dashboard-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 8px;
            }
            
            .stat-card {
                padding: 10px;
            }
            
            .stat-icon {
                font-size: 20px;
            }
            
            .stat-value {
                font-size: 20px;
            }
            
            .stat-label {
                font-size: 9px;
            }
        }
        
        /* Scrollbar Styling */
        ::-webkit-scrollbar {
            width: 10px;
        }
        
        ::-webkit-scrollbar-track {
            background: #f1f1f1;
        }
        
        ::-webkit-scrollbar-thumb {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 5px;
        }
        
        ::-webkit-scrollbar-thumb:hover {
            background: #667eea;
        }
        
        /* Phase Report Styles */
        .phase-reports {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        
        .phase-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            border: 3px solid transparent;
        }
        
        .phase-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }
        
        .phase-card.complete {
            border-color: #4caf50;
            background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%);
        }
        
        .phase-card.in-progress {
            border-color: #ff9800;
            background: linear-gradient(135deg, #fff3e0 0%, #ffe0b2 100%);
        }
        
        .phase-card.not-started {
            border-color: #9e9e9e;
            background: linear-gradient(135deg, #f5f5f5 0%, #eeeeee 100%);
        }
        
        .phase-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid rgba(0,0,0,0.1);
        }
        
        .phase-title {
            font-size: 20px;
            font-weight: 700;
            color: #333;
        }
        
        .phase-icon {
            font-size: 32px;
        }
        
        .phase-progress {
            margin: 20px 0;
        }
        
        .progress-label {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            font-size: 14px;
            color: #666;
        }
        
        .progress-bar-container {
            width: 100%;
            height: 25px;
            background: #e0e0e0;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: inset 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .progress-bar {
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            border-radius: 15px;
            transition: width 0.5s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 700;
            font-size: 12px;
        }
        
        .progress-bar.complete {
            background: linear-gradient(90deg, #4caf50 0%, #8bc34a 100%);
        }
        
        .progress-bar.in-progress {
            background: linear-gradient(90deg, #ff9800 0%, #ffc107 100%);
        }
        
        .phase-status {
            display: inline-block;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 600;
            margin-top: 15px;
        }
        
        .phase-status.complete {
            background: #4caf50;
            color: white;
        }
        
        .phase-status.in-progress {
            background: #ff9800;
            color: white;
        }
        
        .phase-status.not-started {
            background: #9e9e9e;
            color: white;
        }
        
        .phase-status.pending-approval {
            background: #ff9800;
            color: white;
        }
        
        .phase-status.rejected {
            background: #f44336;
            color: white;
        }
        
        .btn-submit-phase {
            width: 100%;
            padding: 12px;
            margin-top: 15px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .btn-submit-phase:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        
        .phase-stats {
            margin-top: 15px;
            padding-top: 15px;
            border-top: 1px solid rgba(0,0,0,0.1);
            font-size: 13px;
            color: #666;
        }
        
        .phase-stat-row {
            display: flex;
            justify-content: space-between;
            padding: 5px 0;
        }
        
        /* Student Details Styles */
        .view-details-btn {
            width: 100%;
            padding: 12px;
            margin-top: 15px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        
        .view-details-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }
        
        .view-details-btn.active {
            background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
        }
        
        .student-details {
            display: none;
            margin-top: 15px;
            padding: 15px;
            background: rgba(255,255,255,0.5);
            border-radius: 8px;
            max-height: 400px;
            overflow-y: auto;
        }
        
        .student-details.show {
            display: block;
            animation: slideDown 0.3s ease;
        }
        
        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .student-list-header {
            display: grid;
            grid-template-columns: 50px 1fr 100px;
            gap: 10px;
            padding: 10px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 6px;
            font-weight: 700;
            font-size: 13px;
            margin-bottom: 10px;
        }
        
        .student-item {
            display: grid;
            grid-template-columns: 50px 1fr 100px;
            gap: 10px;
            padding: 10px;
            background: white;
            border-radius: 6px;
            margin-bottom: 5px;
            font-size: 13px;
            border-left: 3px solid transparent;
            transition: all 0.2s ease;
        }
        
        .student-item:hover {
            border-left-color: #667eea;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            transform: translateX(3px);
        }
        
        .student-item.completed {
            border-left-color: #4caf50;
            background: #f1f8f4;
        }
        
        .student-item.pending {
            border-left-color: #ff9800;
            background: #fff8f0;
        }
        
        .student-no {
            font-weight: 700;
            color: #667eea;
        }
        
        .student-name {
            font-weight: 600;
            color: #333;
        }
        
        .student-status {
            text-align: center;
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
        }
        
        .student-status.completed {
            background: #4caf50;
            color: white;
        }
        
        .student-status.pending {
            background: #ff9800;
            color: white;
        }
        
        .no-students {
            text-align: center;
            padding: 20px;
            color: #999;
            font-style: italic;
        }
        
        .student-details::-webkit-scrollbar {
            width: 6px;
        }
        
        .student-details::-webkit-scrollbar-track {
            background: #f1f1f1;
            border-radius: 3px;
        }
        
        .student-details::-webkit-scrollbar-thumb {
            background: #667eea;
            border-radius: 3px;
        }
    </style>
    <script>
        function toggleStudentDetails(phaseNum) {
            const detailsDiv = document.getElementById('phase' + phaseNum + 'Details');
            const btn = document.getElementById('phase' + phaseNum + 'Btn');
            
            if (detailsDiv.classList.contains('show')) {
                detailsDiv.classList.remove('show');
                btn.innerHTML = '👁️ View Student Details';
                btn.classList.remove('active');
            } else {
                detailsDiv.classList.add('show');
                btn.innerHTML = '👁️ Hide Student Details';
                btn.classList.add('active');
            }
        }
        
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
        
        // Submit phase for approval
        function submitPhaseForApproval(phaseNumber) {
            const remarks = prompt('Enter remarks for Phase ' + phaseNumber + ' submission (optional):');
            if (remarks === null) return; // User cancelled
            
            if (!confirm('Submit Phase ' + phaseNumber + ' for Head Master approval?')) {
                return;
            }
            
            fetch('<%= request.getContextPath() %>/submit-phase', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'phaseNumber=' + phaseNumber + '&remarks=' + encodeURIComponent(remarks)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ ' + data.message);
                    location.reload();
                } else {
                    alert('Error: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error submitting phase: ' + error);
            });
        }
    </script>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div class="header-left">
                <div class="school-icon">🏫</div>
                <div class="header-title">
                    <h1><%= schoolName %></h1>
                    <div class="header-subtitle">UDISE: <%= udiseNo %> | <%= user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) ? "School Coordinator" : "Head Master" %></div>
                </div>
            </div>
            <div class="header-info">
                <div class="user-badge">
                    👤 <strong><%= user.getFullName() %></strong>
                </div>
                <div class="user-badge">
                    🏷️ <%= user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) ? "School Coordinator" : "Head Master" %>
                </div>
                <div class="header-actions">
                    <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) { %>
                        <a href="<%= request.getContextPath() %>/manage-students.jsp" class="btn" style="background: #43e97b; color: white;">
                            📝 Manage Students
                        </a>
                        <a href="<%= request.getContextPath() %>/palak-melava.jsp" class="btn" style="background: #ffc107; color: black;">
                            👥 Palak Melava
                        </a>
                    <% } %>
                    <% if (user.getUserType().equals(User.UserType.HEAD_MASTER)) { %>
                        <% if (pendingApprovalsCount > 0) { %>
                        <a href="<%= request.getContextPath() %>/phase-approvals.jsp" class="btn" style="background: #ff9800; color: white;">
                            ⏳ Phase Approvals (<%= pendingApprovalsCount %>)
                        </a>
                        <% } else { %>
                        <a href="<%= request.getContextPath() %>/phase-approvals.jsp" class="btn" style="background: #2196f3; color: white;">
                            📋 Phase Approvals
                        </a>
                        <% } %>
                        
                        <% if (palakMelavaPendingCount > 0) { %>
                        <a href="<%= request.getContextPath() %>/palak-melava-approvals.jsp" class="btn" style="background: #ff5722; color: white;">
                            👥 Palak Melava (<%= palakMelavaPendingCount %>)
                        </a>
                        <% } else { %>
                        <a href="<%= request.getContextPath() %>/palak-melava-approvals.jsp" class="btn" style="background: #4caf50; color: white;">
                            👥 Palak Melava
                        </a>
                        <% } %>
                    <% } %>
                    <a href="<%= request.getContextPath() %>/change-password" class="btn btn-change-password">
                        🔐 Change Password
                    </a>
                    <a href="<%= request.getContextPath() %>/logout" class="btn btn-logout">
                        🚪 Logout
                    </a>
                </div>
            </div>
        </div>
    </div>
    
    <div class="container">
        <!-- Welcome Card -->
        <div class="welcome-card">
            <div class="welcome-content">
                <h2>नमस्कार <%= user.getFullName() %>! 🙏</h2>
                <p>Welcome to your dashboard. Manage your school's student data and track language proficiency levels.</p>
            </div>
            <div class="welcome-icon">👋</div>
        </div>
        
        <!-- Breadcrumb -->
        <div class="breadcrumb">
            <span>📍 Division:</span> <strong><%= user.getDivisionName() %></strong> 
            <span style="margin: 0 10px;">→</span> 
            <span>🏛️ District:</span> <strong><%= user.getDistrictName() %></strong>
            <span style="margin: 0 10px;">→</span>
            <span>🏫 School:</span> <strong><%= schoolName %></strong> (<%= udiseNo %>)
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
        

                </div>
            </div>
        </div>
        
        <!-- Phase Reports - School Coordinator Only -->
        <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) { %>
        <div class="section">
            <h2 class="section-title">📈 चरण अहवाल (Phase Completion Reports)</h2>
            <p style="margin-bottom: 20px; color: #666;">Track the progress of each phase for your school</p>
            
            <div class="phase-reports">
                <!-- Phase 1 -->
                <div class="phase-card <%= phase1Complete ? "complete" : (phase1Completion > 0 ? "in-progress" : "not-started") %>">
                    <div class="phase-header">
                        <div class="phase-title">चरण 1 (Phase 1)</div>
                        <div class="phase-icon"><%= phase1Complete ? "✅" : (phase1Completion > 0 ? "⏳" : "🔒") %></div>
                    </div>
                    
                    <div class="phase-progress">
                        <div class="progress-label">
                            <span>Progress</span>
                            <span><strong><%= phase1Completion %>%</strong></span>
                        </div>
                        <div class="progress-bar-container">
                            <div class="progress-bar <%= phase1Complete ? "complete" : (phase1Completion > 0 ? "in-progress" : "") %>" 
                                 style="width: <%= phase1Completion %>%">
                                <%= phase1Completion > 10 ? phase1Completion + "%" : "" %>
                            </div>
                        </div>
                    </div>
                    
                    <% if (phase1Approval != null && phase1Approval.isPending()) { %>
                        <div class="phase-status pending-approval">⏳ Pending Approval</div>
                    <% } else if (phase1Approval != null && phase1Approval.isApproved()) { %>
                        <div class="phase-status complete">✓ Approved by Head Master</div>
                    <% } else if (phase1Approval != null && phase1Approval.isRejected()) { %>
                        <div class="phase-status rejected">✗ Rejected - Resubmit Required</div>
                    <% } else { %>
                        <div class="phase-status <%= phase1Complete ? "complete" : (phase1Completion > 0 ? "in-progress" : "not-started") %>">
                            <%= phase1Complete ? "✓ Completed" : (phase1Completion > 0 ? "⏳ In Progress" : "🔒 Not Started") %>
                        </div>
                    <% } %>
                    
                    <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && phase1Complete && (phase1Approval == null || phase1Approval.isRejected())) { %>
                        <button class="btn-submit-phase" onclick="submitPhaseForApproval(1)">
                            📤 Submit for Approval
                        </button>
                    <% } %>
                </div>
                
                <!-- Phase 2 -->
                <div class="phase-card <%= phase2Complete ? "complete" : (phase2Completion > 0 ? "in-progress" : "not-started") %>">
                    <div class="phase-header">
                        <div class="phase-title">चरण 2 (Phase 2)</div>
                        <div class="phase-icon"><%= phase2Complete ? "✅" : (phase2Completion > 0 ? "⏳" : "🔒") %></div>
                    </div>
                    
                    <div class="phase-progress">
                        <div class="progress-label">
                            <span>Progress</span>
                            <span><strong><%= phase2Completion %>%</strong></span>
                        </div>
                        <div class="progress-bar-container">
                            <div class="progress-bar <%= phase2Complete ? "complete" : (phase2Completion > 0 ? "in-progress" : "") %>" 
                                 style="width: <%= phase2Completion %>%">
                                <%= phase2Completion > 10 ? phase2Completion + "%" : "" %>
                            </div>
                        </div>
                    </div>
                    
                    <% if (phase2Approval != null && phase2Approval.isPending()) { %>
                        <div class="phase-status pending-approval">⏳ Pending Approval</div>
                    <% } else if (phase2Approval != null && phase2Approval.isApproved()) { %>
                        <div class="phase-status complete">✓ Approved by Head Master</div>
                    <% } else if (phase2Approval != null && phase2Approval.isRejected()) { %>
                        <div class="phase-status rejected">✗ Rejected - Resubmit Required</div>
                    <% } else { %>
                        <div class="phase-status <%= phase2Complete ? "complete" : (phase2Completion > 0 ? "in-progress" : "not-started") %>">
                            <%= phase2Complete ? "✓ Completed" : (phase2Completion > 0 ? "⏳ In Progress" : "🔒 Not Started") %>
                        </div>
                    <% } %>
                    
                    <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && phase2Complete && (phase2Approval == null || phase2Approval.isRejected())) { %>
                        <button class="btn-submit-phase" onclick="submitPhaseForApproval(2)">
                            📤 Submit for Approval
                        </button>
                    <% } %>
                </div>
                
                <!-- Phase 3 -->
                <div class="phase-card <%= phase3Complete ? "complete" : (phase3Completion > 0 ? "in-progress" : "not-started") %>">
                    <div class="phase-header">
                        <div class="phase-title">चरण 3 (Phase 3)</div>
                        <div class="phase-icon"><%= phase3Complete ? "✅" : (phase3Completion > 0 ? "⏳" : "🔒") %></div>
                    </div>
                    
                    <div class="phase-progress">
                        <div class="progress-label">
                            <span>Progress</span>
                            <span><strong><%= phase3Completion %>%</strong></span>
                        </div>
                        <div class="progress-bar-container">
                            <div class="progress-bar <%= phase3Complete ? "complete" : (phase3Completion > 0 ? "in-progress" : "") %>" 
                                 style="width: <%= phase3Completion %>%">
                                <%= phase3Completion > 10 ? phase3Completion + "%" : "" %>
                            </div>
                        </div>
                    </div>
                    
                    <% if (phase3Approval != null && phase3Approval.isPending()) { %>
                        <div class="phase-status pending-approval">⏳ Pending Approval</div>
                    <% } else if (phase3Approval != null && phase3Approval.isApproved()) { %>
                        <div class="phase-status complete">✓ Approved by Head Master</div>
                    <% } else if (phase3Approval != null && phase3Approval.isRejected()) { %>
                        <div class="phase-status rejected">✗ Rejected - Resubmit Required</div>
                    <% } else { %>
                        <div class="phase-status <%= phase3Complete ? "complete" : (phase3Completion > 0 ? "in-progress" : "not-started") %>">
                            <%= phase3Complete ? "✓ Completed" : (phase3Completion > 0 ? "⏳ In Progress" : "🔒 Not Started") %>
                        </div>
                    <% } %>
                    
                    <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && phase3Complete && (phase3Approval == null || phase3Approval.isRejected())) { %>
                        <button class="btn-submit-phase" onclick="submitPhaseForApproval(3)">
                            📤 Submit for Approval
                        </button>
                    <% } %>
                </div>
                
                <!-- Phase 4 -->
                <div class="phase-card <%= phase4Complete ? "complete" : (phase4Completion > 0 ? "in-progress" : "not-started") %>">
                    <div class="phase-header">
                        <div class="phase-title">चरण 4 (Phase 4)</div>
                        <div class="phase-icon"><%= phase4Complete ? "✅" : (phase4Completion > 0 ? "⏳" : "🔒") %></div>
                    </div>
                    
                    <div class="phase-progress">
                        <div class="progress-label">
                            <span>Progress</span>
                            <span><strong><%= phase4Completion %>%</strong></span>
                        </div>
                        <div class="progress-bar-container">
                            <div class="progress-bar <%= phase4Complete ? "complete" : (phase4Completion > 0 ? "in-progress" : "") %>" 
                                 style="width: <%= phase4Completion %>%">
                                <%= phase4Completion > 10 ? phase4Completion + "%" : "" %>
                            </div>
                        </div>
                    </div>
                    
                    <% if (phase4Approval != null && phase4Approval.isPending()) { %>
                        <div class="phase-status pending-approval">⏳ Pending Approval</div>
                    <% } else if (phase4Approval != null && phase4Approval.isApproved()) { %>
                        <div class="phase-status complete">✓ Approved by Head Master</div>
                    <% } else if (phase4Approval != null && phase4Approval.isRejected()) { %>
                        <div class="phase-status rejected">✗ Rejected - Resubmit Required</div>
                    <% } else { %>
                        <div class="phase-status <%= phase4Complete ? "complete" : (phase4Completion > 0 ? "in-progress" : "not-started") %>">
                            <%= phase4Complete ? "✓ Completed" : (phase4Completion > 0 ? "⏳ In Progress" : "🔒 Not Started") %>
                        </div>
                    <% } %>
                    
                    <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && phase4Complete && (phase4Approval == null || phase4Approval.isRejected())) { %>
                        <button class="btn-submit-phase" onclick="submitPhaseForApproval(4)">
                            📤 Submit for Approval
                        </button>
                    <% } %>
                </div>
            </div>
            
            <!-- Phase Summary -->
            <div style="margin-top: 30px; padding: 20px; background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%); border-radius: 10px; border-left: 5px solid #2196f3;">
                <h3 style="margin-bottom: 15px; color: #1976d2;">📊 Overall Progress Summary</h3>
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px;">
                    <div style="text-align: center;">
                        <div style="font-size: 32px; font-weight: 700; color: #4caf50;"><%= (phase1Complete ? 1 : 0) + (phase2Complete ? 1 : 0) + (phase3Complete ? 1 : 0) + (phase4Complete ? 1 : 0) %></div>
                        <div style="color: #666; font-size: 14px; margin-top: 5px;">Phases Completed</div>
                    </div>
                    <div style="text-align: center;">
                        <div style="font-size: 32px; font-weight: 700; color: #ff9800;"><%= (phase1Completion + phase2Completion + phase3Completion + phase4Completion) / 4 %>%</div>
                        <div style="color: #666; font-size: 14px; margin-top: 5px;">Average Progress</div>
                    </div>
                </div>
            </div>
        </div>
        <% } %>
        
</body>
</html>
