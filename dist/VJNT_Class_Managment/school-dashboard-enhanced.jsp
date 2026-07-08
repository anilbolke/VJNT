<!-- VERSION: 2024-11-30-v12 - Reordered Quick Actions -->
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
<%@ page import="java.sql.*" %>
<%@ page import="com.vjnt.util.DatabaseConnection" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.HEAD_MASTER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    
    // Fetch active notifications for this school
    List<Map<String, Object>> notifications = new ArrayList<>();
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        // Get notifications that are:
        // 1. Active (is_active = 1)
        // 2. Not expired (expiry_date is NULL or > NOW())
        // 3. Targeted to this school (ALL, or specific division/district/udise)
        // 4. Target audience matches user type (ALL, SCHOOL_COORDINATOR, or HEAD_MASTER)
        String userTypeStr = user.getUserType().toString(); // SCHOOL_COORDINATOR or HEAD_MASTER
        
        // Debug: Print user info
        //System.out.println("=== NOTIFICATION DEBUG ===");
        //System.out.println("User Type: " + userTypeStr);
        //System.out.println("Division: [" + user.getDivisionName() + "]");
        //System.out.println("District: [" + user.getDistrictName() + "]");
        //System.out.println("UDISE: [" + user.getUdiseNo() + "]");
        
        // Use TRIM to handle any whitespace issues
        String notifSql = "SELECT notification_id, title, message, notification_type, priority, " +
                         "created_by_name, created_date, expiry_date, division, district, udise_code, target_audience " +
                         "FROM notifications " +
                         "WHERE is_active = 1 " +
                         "AND (expiry_date IS NULL OR expiry_date > NOW()) " +
                         "AND (division IS NULL OR TRIM(division) = '' OR TRIM(division) = TRIM(?)) " +
                         "AND (district IS NULL OR TRIM(district) = '' OR TRIM(district) = TRIM(?)) " +
                         "AND (udise_code IS NULL OR TRIM(udise_code) = '' OR TRIM(udise_code) = TRIM(?)) " +
                         "AND (target_audience = 'ALL' OR target_audience = ?) " +
                         "ORDER BY priority DESC, created_date DESC " +
                         "LIMIT 5";
        pstmt = conn.prepareStatement(notifSql);
        pstmt.setString(1, user.getDivisionName());
        pstmt.setString(2, user.getDistrictName());
        pstmt.setString(3, user.getUdiseNo());
        pstmt.setString(4, userTypeStr);
        
        //System.out.println("Executing query with parameters:");
        //System.out.println("1 (Division): [" + user.getDivisionName() + "]");
        //System.out.println("2 (District): [" + user.getDistrictName() + "]");
        //System.out.println("3 (UDISE): [" + user.getUdiseNo() + "]");
        //System.out.println("4 (UserType): [" + userTypeStr + "]");
        
        rs = pstmt.executeQuery();
        
        int count = 0;
        while (rs.next()) {
            count++;
            //System.out.println("Found notification #" + count + ": " + rs.getString("title"));
            //System.out.println("  - Division: [" + rs.getString("division") + "]");
            //System.out.println("  - District: [" + rs.getString("district") + "]");
            //System.out.println("  - UDISE: [" + rs.getString("udise_code") + "]");
            //System.out.println("  - Target: [" + rs.getString("target_audience") + "]");
            
            Map<String, Object> notification = new HashMap<>();
            notification.put("id", rs.getInt("notification_id"));
            notification.put("title", rs.getString("title"));
            notification.put("message", rs.getString("message"));
            notification.put("type", rs.getString("notification_type"));
            notification.put("priority", rs.getInt("priority"));
            notification.put("createdBy", rs.getString("created_by_name"));
            notification.put("createdDate", rs.getTimestamp("created_date"));
            notification.put("expiryDate", rs.getTimestamp("expiry_date"));
            notifications.add(notification);
        }
        
        //System.out.println("Total notifications found: " + count);
        //System.out.println("Notifications list size: " + notifications.size());
        //System.out.println("========================");
        
    } catch (Exception e) {
        //System.out.println("ERROR fetching notifications: " + e.getMessage());
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
        if (conn != null) try { conn.close(); } catch (SQLException e) { }
    }
    
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
    List<com.vjnt.model.Student> allStudents = studentDAO.getStudentsByUdiseFOrView(udiseNo);
    int totalStudents = studentDAO.getStudentCountByUdiseFORDASHBOARD(udiseNo);
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
    // Calculate phase completion percentages
    int phase1Completion = studentDAO.getPhaseCompletionPercentage(udiseNo, 1);
    int phase2Completion = studentDAO.getPhaseCompletionPercentage(udiseNo, 2);
    int phase3Completion = studentDAO.getPhaseCompletionPercentage(udiseNo, 3);
    int phase4Completion = studentDAO.getPhaseCompletionPercentage(udiseNo, 4);
    
    // Check if all students have completed their assessments for each phase
    boolean phase1Complete = studentDAO.isPhaseComplete(udiseNo, 1);
    boolean phase2Complete = studentDAO.isPhaseComplete(udiseNo, 2);
    boolean phase3Complete = studentDAO.isPhaseComplete(udiseNo, 3);
    boolean phase4Complete = studentDAO.isPhaseComplete(udiseNo, 4);
    
    // Check if phases are approved by Head Master
    boolean phase1Approved = studentDAO.isPhaseApproved(udiseNo, 1);
    boolean phase2Approved = studentDAO.isPhaseApproved(udiseNo, 2);
    boolean phase3Approved = studentDAO.isPhaseApproved(udiseNo, 3);
    boolean phase4Approved = studentDAO.isPhaseApproved(udiseNo, 4);
    
    // Get phase approval details
    PhaseApprovalDAO approvalDAO = new PhaseApprovalDAO();
    PhaseApproval phase1Approval = approvalDAO.getPhaseApproval(udiseNo, 1);
    PhaseApproval phase2Approval = approvalDAO.getPhaseApproval(udiseNo, 2);
    PhaseApproval phase3Approval = approvalDAO.getPhaseApproval(udiseNo, 3);
    PhaseApproval phase4Approval = approvalDAO.getPhaseApproval(udiseNo, 4);
    
    int pendingApprovalsCount = approvalDAO.getPendingApprovalCount(udiseNo);
    
    // Get Palak Melava pending count
    PalakMelavaDAO melavaDAO = new PalakMelavaDAO();
    int palakMelavaPendingCount = melavaDAO.getPendingCount(udiseNo);
    
    // Get pending videos count for Head Master approval
    int pendingVideosCount = 0;
    if (user.getUserType().equals(User.UserType.HEAD_MASTER)) {
        Connection videoConn = null;
        PreparedStatement videoPstmt = null;
        ResultSet videoRs = null;
        try {
            videoConn = DatabaseConnection.getConnection();
            String videoCountSql = "SELECT COUNT(*) as count FROM student_videos WHERE udise_no = ? AND approval_status = 'PENDING'";
            videoPstmt = videoConn.prepareStatement(videoCountSql);
            videoPstmt.setString(1, udiseNo);
            videoRs = videoPstmt.executeQuery();
            if (videoRs.next()) {
                pendingVideosCount = videoRs.getInt("count");
            }
        } catch (Exception e) {
            System.err.println("Error getting pending videos count: " + e.getMessage());
        } finally {
            try {
                if (videoRs != null) videoRs.close();
                if (videoPstmt != null) videoPstmt.close();
                if (videoConn != null) videoConn.close();
            } catch (Exception e) {}
        }
    }
    
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
            background: #f0f2f5;
            min-height: 100vh;
        }
        
        .header {
            background: #f0f2f5;
            color: #000;
            padding: 20px 30px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        
        .header-old {
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
        
        .school-icon {
            font-size: 24px;
            animation: bounce 2s infinite;
        }
        
        .gatee-tooltip {
            position: relative;
            display: inline-block;
            cursor: help;
            margin-left: 8px;
            color: #667eea;
            font-size: 18px;
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
            align-items: center;
            flex-wrap: wrap;
        }
        
        /* Quick Actions Dropdown */
        .quick-actions-dropdown {
            position: relative;
            display: inline-block;
        }
        
        .quick-actions-btn {
            padding: 10px 20px;
            border: 2px solid rgba(255,255,255,0.3);
            border-radius: 25px;
            cursor: pointer;
            font-size: 14px;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s;
            font-weight: 600;
            background: rgba(255,255,255,0.95);
            color: #333;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        .quick-actions-btn:hover {
            background: white;
            border-color: rgba(255,255,255,0.5);
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }
        
        .badge {
            background: #ff4757;
            color: white;
            font-size: 11px;
            padding: 2px 8px;
            border-radius: 12px;
            font-weight: 700;
            min-width: 20px;
            text-align: center;
        }
        
        .dropdown-menu {
            display: none;
            position: absolute;
            top: 100%;
            right: 0;
            margin-top: 8px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.15);
            min-width: 280px;
            max-height: 400px;
            overflow-y: auto;
            z-index: 1000;
            animation: dropdownFadeIn 0.2s ease;
        }
        
        @keyframes dropdownFadeIn {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .dropdown-menu.show {
            display: block;
        }
        
        .dropdown-section {
            padding: 12px 0;
        }
        
        .section-title {
            padding: 8px 16px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            color: #999;
            letter-spacing: 0.5px;
        }
        
        .dropdown-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 12px 16px;
            color: #333;
            text-decoration: none;
            transition: all 0.2s;
            font-size: 14px;
        }
        
        .dropdown-item:hover {
            background: #f8f9fa;
            padding-left: 20px;
        }
        
        .dropdown-item-content {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .dropdown-item span:first-child {
            font-size: 18px;
        }
        
        .item-badge {
            background: #ff4757;
            color: white;
            font-size: 10px;
            padding: 3px 8px;
            border-radius: 10px;
            font-weight: 700;
            min-width: 20px;
            text-align: center;
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
            background: rgba(255,255,255,0.95);
            color: #333;
            border: 2px solid rgba(255,255,255,0.3);
        }
        
        .btn-change-password:hover {
            background: white;
            border-color: rgba(255,255,255,0.5);
        }
        
        .container {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 20px 30px 20px;
        }
        
        .welcome-card {
		    background: linear-gradient(135deg, #fff 0%, #fff 100%);
		    color: #333;
		    padding: 25px 30px;
		    border-radius: 15px;
		    margin-bottom: 25px;
		    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
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
        
        /* Notification Styles */
        .notifications-section {
            width: 100%;
            margin-top: 20px;
            padding-top: 20px;
            border-top: 2px solid #e0e0e0;
        }
        
        .notifications-header {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 15px;
            font-size: 18px;
            font-weight: 700;
            color: #333;
        }
        
        .notification-icon {
            font-size: 24px;
            animation: bell-ring 2s infinite;
        }
        
        @keyframes bell-ring {
            0%, 100% { transform: rotate(0deg); }
            10%, 30% { transform: rotate(-10deg); }
            20%, 40% { transform: rotate(10deg); }
        }
        
        .notifications-list {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        
        .notification-item {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            border-radius: 8px;
            padding: 15px;
            transition: all 0.3s;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }
        
        .notification-item:hover {
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            transform: translateX(5px);
        }
        
        .notification-item.type-INFO {
            border-left-color: #2196f3;
            background: #e3f2fd;
        }
        
        .notification-item.type-WARNING {
            border-left-color: #ff9800;
            background: #fff3e0;
        }
        
        .notification-item.type-URGENT {
            border-left-color: #f44336;
            background: #ffebee;
            animation: pulse-urgent 2s infinite;
        }
        
        .notification-item.type-SUCCESS {
            border-left-color: #4caf50;
            background: #e8f5e9;
        }
        
        @keyframes pulse-urgent {
            0%, 100% { box-shadow: 0 2px 5px rgba(244, 67, 54, 0.2); }
            50% { box-shadow: 0 4px 15px rgba(244, 67, 54, 0.4); }
        }
        
        .notification-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 8px;
        }
        
        .notification-title {
            font-weight: 700;
            font-size: 15px;
            color: #333;
            flex: 1;
        }
        
        .notification-priority {
            padding: 3px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
            margin-left: 10px;
        }
        
        .priority-0 {
            background: #e0e0e0;
            color: #666;
        }
        
        .priority-1 {
            background: #ff9800;
            color: white;
        }
        
        .priority-2 {
            background: #f44336;
            color: white;
            animation: blink 1.5s infinite;
        }
        
        @keyframes blink {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.6; }
        }
        
        .notification-message {
            font-size: 14px;
            color: #555;
            line-height: 1.6;
            margin-bottom: 10px;
        }
        
        .notification-footer {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 12px;
            color: #777;
            margin-top: 10px;
            padding-top: 10px;
            border-top: 1px solid rgba(0,0,0,0.05);
        }
        
        .notification-author {
            font-weight: 600;
        }
        
        .notification-date {
            font-style: italic;
        }
        
        .no-notifications {
            text-align: center;
            padding: 20px;
            color: #999;
            font-style: italic;
        }
        
        .notification-badge {
            background: #f44336;
            color: white;
            border-radius: 50%;
            padding: 2px 8px;
            font-size: 12px;
            font-weight: 700;
            margin-left: 8px;
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
        
        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            overflow: auto;
            background-color: rgba(0,0,0,0.5);
            animation: fadeIn 0.3s ease;
        }
        
        .modal.show {
            display: block !important;
        }
        
        .modal-content {
            background-color: #fefefe;
            margin: 2% auto;
            padding: 0;
            border: 1px solid #888;
            width: 90%;
            max-width: 1200px;
            border-radius: 15px;
            box-shadow: 0 4px 30px rgba(0,0,0,0.3);
            animation: slideDown 0.3s ease;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        @keyframes slideDown {
            from { 
                transform: translateY(-50px);
                opacity: 0;
            }
            to { 
                transform: translateY(0);
                opacity: 1;
            }
        }
        
        .modal-header {
            padding: 20px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 15px 15px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-header h2 {
            margin: 0;
            font-size: 24px;
        }
        
        .close {
            color: white;
            font-size: 35px;
            font-weight: bold;
            cursor: pointer;
            transition: color 0.3s ease;
        }
        
        .close:hover,
        .close:focus {
            color: #f44336;
        }
        
        .modal-body {
            padding: 30px;
            max-height: 70vh;
            overflow-y: auto;
        }
        
        /* Modal Controls */
        .modal-controls {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .search-box {
            flex: 1;
            min-width: 250px;
            position: relative;
        }
        
        .search-box input {
            width: 100%;
            padding: 10px 15px 10px 40px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        
        .search-box input:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .search-box::before {
            content: "🔍";
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
        }
        
        .filter-group {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .filter-select {
            padding: 8px 12px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            background: white;
            cursor: pointer;
        }
        
        .export-btn {
            padding: 10px 20px;
            background: #4caf50;
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            transition: background 0.3s;
        }
        
        .export-btn:hover {
            background: #45a049;
        }
        
        /* Student Table */
        .student-table-container {
            overflow-x: auto;
            margin-top: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .student-table {
            width: 100%;
            border-collapse: collapse;
            background: white;
        }
        
        .student-table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .student-table th {
            padding: 15px 10px;
            text-align: left;
            font-weight: 600;
            font-size: 13px;
            white-space: nowrap;
            position: sticky;
            top: 0;
            z-index: 10;
        }
        
        .student-table td {
            padding: 12px 10px;
            border-bottom: 1px solid #e0e0e0;
            font-size: 13px;
        }
        
        .student-table tbody tr:hover {
            background: #f5f7fa;
        }
        
        .student-table tbody tr:nth-child(even) {
            background: #fafbfc;
        }
        
        /* Pagination */
        .modal-pagination {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 20px;
            padding: 15px;
            background: #f5f7fa;
            border-radius: 8px;
        }
        
        .pagination-info {
            font-size: 14px;
            color: #666;
        }
        
        .pagination-buttons {
            display: flex;
            gap: 5px;
        }
        
        .page-btn {
            padding: 8px 12px;
            border: 1px solid #e0e0e0;
            background: white;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .page-btn:hover {
            background: #667eea;
            color: white;
            border-color: #667eea;
        }
        
        .page-btn.active {
            background: #667eea;
            color: white;
            border-color: #667eea;
        }
        
        .page-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
        
        /* Level badges */
        .level-badge {
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
            display: inline-block;
            white-space: nowrap;
        }
        
        .level-0 { background: #f44336; color: white; }
        .level-1 { background: #ff9800; color: white; }
        .level-2 { background: #ffc107; color: #333; }
        .level-3 { background: #4caf50; color: white; }
        .level-4 { background: #2196f3; color: white; }
        .level-5 { background: #9c27b0; color: white; }
        .level-6 { background: #673ab7; color: white; }
        .level-7 { background: #3f51b5; color: white; }
        
        .phase-card.clickable {
            cursor: pointer;
        }
        
        .phase-card.clickable:hover {
            border-color: #667eea;
        }
        
        .modal-summary {
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .summary-item {
            text-align: center;
        }
        
        .summary-item .summary-value {
            font-size: 32px;
            font-weight: 700;
            color: #667eea;
        }
        
        .summary-item .summary-label {
            font-size: 14px;
            color: #666;
            margin-top: 5px;
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
        // Test that script is loading - VERSION 12 - REORDERED
        console.log('=== SCRIPT LOADED - VERSION 12 - REORDERED ===');
        console.log('Page loaded at:', new Date());
        
        // Global variable for selected student
        let selectedVideoStudentData = null;
        
        // Define video modal functions early to prevent "not defined" errors
        function openVideoUploadModal() {
            const modal = document.getElementById('videoUploadModal');
            if (modal) {
                modal.style.display = 'block';
                const step1 = document.getElementById('videoStep1');
                const step2 = document.getElementById('videoStep2');
                if (step1) step1.style.display = 'block';
                if (step2) step2.style.display = 'none';
                document.body.style.overflow = 'hidden';
                
                // Reset selections
                const radios = document.getElementsByName('selectedVideoStudent');
                if (radios) radios.forEach(r => r.checked = false);
            } else {
                console.error('Video upload modal not found!');
            }
        }
        
        function closeVideoUploadModal() {
            const modal = document.getElementById('videoUploadModal');
            if (modal) {
                modal.style.display = 'none';
                document.body.style.overflow = 'auto';
                
                // Reset form
                const form = document.getElementById('videoUploadForm');
                if (form) form.reset();
                const fileName = document.getElementById('videoFileName');
                if (fileName) fileName.textContent = '';
                
                // Reset selected student
                selectedVideoStudentData = null;
            }
        }
        
        // Open Uploaded Videos Modal
        function openUploadedVideosModal() {
            console.log('Opening uploaded videos modal...');
            const modal = document.getElementById('uploadedVideosModal');
            if (modal) {
                modal.style.display = 'block';
                document.body.style.overflow = 'hidden';
                console.log('✅ Uploaded videos modal opened successfully');
                
                // Debug: Check if modal has content
                const modalBody = modal.querySelector('.modal-body');
                if (modalBody) {
                    console.log('Modal body found, innerHTML length:', modalBody.innerHTML.length);
                    console.log('Modal body preview:', modalBody.innerHTML.substring(0, 200));
                } else {
                    console.error('❌ Modal body not found!');
                }
                
                // Debug: Check for video cards
                const videoCards = modal.querySelectorAll('[style*="background: white"]');
                console.log('Number of video cards found:', videoCards.length);
                
                // Debug: Check for "No Videos" message
                const noVideosMsg = modal.querySelector('h3');
                if (noVideosMsg) {
                    console.log('Message in modal:', noVideosMsg.textContent);
                }
            } else {
                console.error('❌ Uploaded videos modal element not found! Check if id="uploadedVideosModal" exists');
            }
        }
        
        // Close Uploaded Videos Modal
        function closeUploadedVideosModal() {
            const modal = document.getElementById('uploadedVideosModal');
            if (modal) {
                modal.style.display = 'none';
                document.body.style.overflow = 'auto';
                console.log('Uploaded videos modal closed');
            }
        }
        
        function filterVideoStudents() {
            const searchText = document.getElementById('videoStudentSearch')?.value.toLowerCase() || '';
            const classFilter = document.getElementById('videoClassFilter')?.value || '';
            const sectionFilter = document.getElementById('videoSectionFilter')?.value || '';
            
            const rows = document.querySelectorAll('.video-student-row');
            
            rows.forEach(row => {
                const name = row.getAttribute('data-name')?.toLowerCase() || '';
                const pen = row.getAttribute('data-pen')?.toLowerCase() || '';
                const studentClass = row.getAttribute('data-class') || '';
                const section = row.getAttribute('data-section') || '';
                
                const matchesSearch = name.includes(searchText) || pen.includes(searchText);
                const matchesClass = !classFilter || studentClass === classFilter;
                const matchesSection = !sectionFilter || section === sectionFilter;
                
                if (matchesSearch && matchesClass && matchesSection) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        }
        
        function selectVideoStudent(radio) {
            if (radio) {
                selectedVideoStudentData = {
                    id: radio.value,
                    name: radio.getAttribute('data-name'),
                    pen: radio.getAttribute('data-pen'),
                    star: radio.getAttribute('data-star')
                };
            }
        }
        
        function proceedToVideoUpload() {
            if (!selectedVideoStudentData) {
                alert('कृपया विद्यार्थी निवडा!\nPlease select a student!');
                return;
            }
            
            // Update student info in step 2
            const nameEl = document.getElementById('selectedStudentName');
            const penEl = document.getElementById('selectedStudentPEN');
            const starEl = document.getElementById('selectedStudentStar');
            const idEl = document.getElementById('videoStudentId');
            
            if (nameEl) nameEl.textContent = selectedVideoStudentData.name;
            if (penEl) penEl.textContent = selectedVideoStudentData.pen;
            if (starEl) starEl.innerHTML = '⭐ ' + selectedVideoStudentData.star;
            if (idEl) idEl.value = selectedVideoStudentData.id;
            
            // Switch to step 2
            const step1 = document.getElementById('videoStep1');
            const step2 = document.getElementById('videoStep2');
            if (step1) step1.style.display = 'none';
            if (step2) step2.style.display = 'block';
        }
        
        function backToStudentSelection() {
            const step1 = document.getElementById('videoStep1');
            const step2 = document.getElementById('videoStep2');
            if (step1) step1.style.display = 'block';
            if (step2) step2.style.display = 'none';
        }
        
        function displayVideoFileName(input) {
            if (input && input.files && input.files[0]) {
                const file = input.files[0];
                const fileName = file.name;
                const fileSizeBytes = file.size;
                const fileSizeMB = (fileSizeBytes / (1024 * 1024)).toFixed(2);
                const fileSizeKB = (fileSizeBytes / 1024).toFixed(2);
                const fileNameEl = document.getElementById('videoFileName');
                
                // Validation: Min 100 KB (102400 bytes) and Max 15 MB (15728640 bytes)
                const minSizeBytes = 100 * 1024; // 100 KB
                const maxSizeBytes = 15 * 1024 * 1024; // 15 MB
                
                if (fileSizeBytes < minSizeBytes) {
                    alert('❌ File too small!\nफाईल खूप लहान आहे!\n\nMinimum size: 100 KB\nYour file: ' + fileSizeKB + ' KB\n\nPlease select a larger video file.');
                    input.value = ''; // Clear the input
                    if (fileNameEl) {
                        fileNameEl.textContent = '';
                        fileNameEl.style.color = '#f44336';
                    }
                    return;
                }
                
                if (fileSizeBytes > maxSizeBytes) {
                    alert('❌ File too large!\nफाईल खूप मोठी आहे!\n\nMaximum size: 15 MB\nYour file: ' + fileSizeMB + ' MB\n\nPlease select a smaller video file or compress it.');
                    input.value = ''; // Clear the input
                    if (fileNameEl) {
                        fileNameEl.textContent = '';
                        fileNameEl.style.color = '#f44336';
                    }
                    return;
                }
                
                // File size is valid
                if (fileNameEl) {
                    const displaySize = fileSizeMB >= 1 ? fileSizeMB + ' MB' : fileSizeKB + ' KB';
                    fileNameEl.textContent = '✓ Selected: ' + fileName + ' (' + displaySize + ')';
                    fileNameEl.style.color = '#4caf50';
                }
            }
        }
        
        console.log('Video modal functions defined early');
        
        // Helper functions to get level display text - EXACT DROPDOWN VALUES
        function getMarathiLevelText(level) {
            const levels = {
             0:  'स्थर निश्चित केला नाही',
        	 1:  'प्रारंभिक स्तर',
             2:  'अक्षर स्तर',
             3:  'शब्द स्तर',
             4:  'वाक्य स्तर',
             5:  'समजपूर्वक उतारा वाचन स्तर',
             6:  'मराठी वाचन व लेखन FLN स्तर 100% पूर्ण',
            default:  'स्तर निश्चित केला नाही'
            };
            return levels[level] || 'स्तर निश्चित केला नाही';
        }
        
        function getMathLevelText(level) {
            const levels = {
             0:  'स्थर निश्चित केला नाही',
            1:  'प्रारंभिक स्तर',
            2:  'अंक ज्ञान स्तर',
            3:  'संख्याज्ञान स्तर',
            4:  'बेरीज स्तर',
            5:  'वजाबाकी स्तर',
            6:  'गुणाकार स्तर',
            7:  'भागाकार स्तर',
            8:  'गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण'
            };
            return levels[level] || 'स्थर निश्चित केला नाही';
        }
        
        function getEnglishLevelText(level) {
            const levels = {
            0: 'स्थर निश्चित केला नाही',
            1: 'Beginner level',
            2: 'Alphabet level',
            3: 'Word level',
            4: 'Sentence level',
            5: 'Paragraph Reading with Understanding',
            6: 'English reading and writing FLN level 100% complete'
            };
            return levels[level] || 'स्थर निश्चित केला नाही';
        }
        
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
        
        // Global variables for table display
        let currentPhaseData = [];
        let filteredData = [];
        let currentModalPage = 1;
        let rowsPerPage = 20;
        
        // Show phase details in modal with table view
        function showPhaseDetails(phaseNumber, event) {
            try {
                console.log('=== showPhaseDetails START ===');
                
                // Prevent click if clicking on a button
                if (event && event.target && event.target.tagName === 'BUTTON') {
                    return;
                }
                
                const modal = document.getElementById('phaseModal');
                const modalTitle = document.getElementById('modalPhaseTitle');
                const modalBody = document.getElementById('modalStudentList');
                
                if (!modal) {
                    alert('Error: Modal element not found. Please refresh the page.');
                    return;
                }
                
                modalTitle.textContent = 'चरण ' + phaseNumber + ' विद्यार्थी डेटा (Phase ' + phaseNumber + ' Student Data)';
                modal.style.display = 'block';
                modal.classList.add('show');
                
                // Get student data
                const students = window['phase' + phaseNumber + 'Students'];
                console.log('Students array:', students);
                console.log('Number of students:', students ? students.length : 0);
                
                if (students && students.length > 0) {
                    currentPhaseData = students;
                    filteredData = [...students];
                    currentModalPage = 1;
                    
                    // Build the UI
                    let html = '';
                    
                    // Summary
                    html += '<div class="modal-summary">';
                    html += '<div class="summary-item"><div class="summary-value">' + students.length + '</div><div class="summary-label">Total Students</div></div>';
                    let maleCount = students.filter(s => s.gender === 'Male' || s.gender === 'पुरुष').length;
                    let femaleCount = students.filter(s => s.gender === 'Female' || s.gender === 'स्त्री').length;
                    html += '<div class="summary-item"><div class="summary-value">' + maleCount + '</div><div class="summary-label">Male</div></div>';
                    html += '<div class="summary-item"><div class="summary-value">' + femaleCount + '</div><div class="summary-label">Female</div></div>';
                    html += '</div>';
                    
                    // Controls
                    html += '<div class="modal-controls">';
                    html += '<div class="search-box"><input type="text" id="studentSearch" placeholder="Search by PEN, name, class, section..." onkeyup="filterStudents()"></div>';
                    html += '<div class="filter-group">';
                    html += '<select id="classFilter" class="filter-select" onchange="filterStudents()"><option value="">All Classes</option></select>';
                    html += '<select id="sectionFilter" class="filter-select" onchange="filterStudents()"><option value="">All Sections</option></select>';
                    html += '</div>';
                    html += '<button class="export-btn" onclick="exportToExcel(' + phaseNumber + ')">📥 Export Excel</button>';
                    html += '</div>';
                    
                    // Table container
                    html += '<div id="tableContainer"></div>';
                    
                    modalBody.innerHTML = html;
                    
                    // Populate filter options
                    populateFilters();
                    
                    // Render table
                    renderStudentTable();
                } else {
                    modalBody.innerHTML = '<div style="text-align: center; padding: 40px; color: #999;"><h3>No students have completed Phase ' + phaseNumber + ' yet.</h3></div>';
                }
                
                console.log('=== showPhaseDetails END ===');
            } catch (error) {
                console.error('ERROR in showPhaseDetails:', error);
                alert('Error opening modal: ' + error.message);
            }
        }
        
        // Populate filter dropdowns
        function populateFilters() {
            const classes = [...new Set(currentPhaseData.map(s => s.class))].sort();
            const sections = [...new Set(currentPhaseData.map(s => s.section))].sort();
            
            const classFilter = document.getElementById('classFilter');
            const sectionFilter = document.getElementById('sectionFilter');
            
            classes.forEach(c => {
                const opt = document.createElement('option');
                opt.value = c;
                opt.textContent = 'Class ' + c;
                classFilter.appendChild(opt);
            });
            
            sections.forEach(s => {
                const opt = document.createElement('option');
                opt.value = s;
                opt.textContent = 'Section ' + s;
                sectionFilter.appendChild(opt);
            });
        }
        
        // Filter students based on search and filters
        function filterStudents() {
            const searchTerm = document.getElementById('studentSearch').value.toLowerCase();
            const classFilter = document.getElementById('classFilter').value;
            const sectionFilter = document.getElementById('sectionFilter').value;
            
            filteredData = currentPhaseData.filter(student => {
                const matchesSearch = student.name.toLowerCase().includes(searchTerm) ||
                                     student.class.toLowerCase().includes(searchTerm) ||
                                     student.section.toLowerCase().includes(searchTerm) ||
                                     (student.pen && student.pen.toLowerCase().includes(searchTerm));
                const matchesClass = !classFilter || student.class === classFilter;
                const matchesSection = !sectionFilter || student.section === sectionFilter;
                
                return matchesSearch && matchesClass && matchesSection;
            });
            
            currentModalPage = 1;
            renderStudentTable();
        }
        
        // Render student table with pagination
        function renderStudentTable() {
            const container = document.getElementById('tableContainer');
            if (!container) return;
            
            const start = (currentModalPage - 1) * rowsPerPage;
            const end = start + rowsPerPage;
            const pageData = filteredData.slice(start, end);
            const totalPages = Math.ceil(filteredData.length / rowsPerPage);
            
            let html = '<div class="student-table-container">';
            html += '<table class="student-table">';
            html += '<thead><tr>';
            html += '<th>#</th>';
            html += '<th>PEN</th>';
            html += '<th>Student Name</th>';
            html += '<th>Class</th>';
            html += '<th>Section</th>';
            html += '<th>Gender</th>';
            html += '<th>मराठी Level</th>';
            html += '<th>गणित Level</th>';
            html += '<th>English Level</th>';
            html += '<th>Completed Date</th>';
            html += '</tr></thead>';
            html += '<tbody>';
            
            if (pageData.length === 0) {
                html += '<tr><td colspan="10" style="text-align:center; padding:20px;">No students found</td></tr>';
            } else {
                pageData.forEach((student, index) => {
                    html += '<tr>';
                    html += '<td>' + (start + index + 1) + '</td>';
                    html += '<td><strong>' + (student.pen || 'N/A') + '</strong></td>';
                    html += '<td>' + student.name + '</td>';
                    html += '<td>' + student.class + '</td>';
                    html += '<td>' + student.section + '</td>';
                    html += '<td>' + student.gender + '</td>';
                    html += '<td><span class="level-badge level-' + student.marathiLevel + '">' + getMarathiLevelText(student.marathiLevel) + '</span></td>';
                    html += '<td><span class="level-badge level-' + student.mathLevel + '">' + getMathLevelText(student.mathLevel) + '</span></td>';
                    html += '<td><span class="level-badge level-' + student.englishLevel + '">' + getEnglishLevelText(student.englishLevel) + '</span></td>';
                    html += '<td>' + (student.phaseDate || '-') + '</td>';
                    html += '</tr>';
                });
            }
            
            html += '</tbody></table></div>';
            
            // Pagination
            if (totalPages > 1) {
                html += '<div class="modal-pagination">';
                html += '<div class="pagination-info">Showing ' + (start + 1) + ' to ' + Math.min(end, filteredData.length) + ' of ' + filteredData.length + ' students</div>';
                html += '<div class="pagination-buttons">';
                html += '<button class="page-btn" onclick="changeModalPage(' + (currentModalPage - 1) + ')" ' + (currentModalPage === 1 ? 'disabled' : '') + '>« Prev</button>';
                
                for (let i = 1; i <= totalPages; i++) {
                    if (i === 1 || i === totalPages || (i >= currentModalPage - 2 && i <= currentModalPage + 2)) {
                        html += '<button class="page-btn ' + (i === currentModalPage ? 'active' : '') + '" onclick="changeModalPage(' + i + ')">' + i + '</button>';
                    } else if (i === currentModalPage - 3 || i === currentModalPage + 3) {
                        html += '<span style="padding: 8px;">...</span>';
                    }
                }
                
                html += '<button class="page-btn" onclick="changeModalPage(' + (currentModalPage + 1) + ')" ' + (currentModalPage === totalPages ? 'disabled' : '') + '>Next »</button>';
                html += '</div></div>';
            }
            
            container.innerHTML = html;
        }
        
        // Change page
        function changeModalPage(page) {
            const totalPages = Math.ceil(filteredData.length / rowsPerPage);
            if (page < 1 || page > totalPages) return;
            currentModalPage = page;
            renderStudentTable();
        }
        
        // Export to Excel
        function exportToExcel(phaseNumber) {
            let csv = 'Sr No,PEN,Student Name,Class,Section,Gender,Marathi Level,Math Level,English Level,Completed Date\n';
            
            filteredData.forEach((student, index) => {
                csv += (index + 1) + ',';
                csv += '"' + (student.pen || 'N/A') + '",';
                csv += '"' + student.name + '",';
                csv += student.class + ',';
                csv += student.section + ',';
                csv += student.gender + ',';
                csv += '"' + getMarathiLevelText(student.marathiLevel) + '",';
                csv += '"' + getMathLevelText(student.mathLevel) + '",';
                csv += '"' + getEnglishLevelText(student.englishLevel) + '",';
                csv += (student.phaseDate || '') + '\n';
            });
            
            const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = 'Phase_' + phaseNumber + '_Students_' + new Date().toISOString().split('T')[0] + '.csv';
            link.click();
        }
        
        // Close modal
        function closeModal() {
            console.log('closeModal called');
            const modal = document.getElementById('phaseModal');
            if (modal) {
                modal.style.display = 'none';
                modal.classList.remove('show');
            }
        }
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            const phaseModal = document.getElementById('phaseModal');
            const teacherModal = document.getElementById('addTeacherModal');
            if (event.target === phaseModal) {
                closeModal();
            }
            if (event.target === teacherModal) {
                closeAddTeacherModal();
            }
        }
        
        // Open Add Teacher Modal
        function openAddTeacherModal() {
            console.log('Opening Add Teacher Modal');
            const modal = document.getElementById('addTeacherModal');
            if (modal) {
                modal.style.display = 'block';
                modal.classList.add('show');
            }
        }
        
        // Close Add Teacher Modal
        function closeAddTeacherModal() {
            console.log('Closing Add Teacher Modal');
            const modal = document.getElementById('addTeacherModal');
            if (modal) {
                modal.style.display = 'none';
                modal.classList.remove('show');
            }
            // Reset form
            document.getElementById('addTeacherForm').reset();
            document.getElementById('subjectError').style.display = 'none';
            // Hide other subject input
            document.getElementById('otherSubjectInputContainer').style.display = 'none';
            document.getElementById('otherSubjectName').value = '';
        }
        
        // Toggle Other Subject Input Field
        function toggleOtherSubjectInput() {
            const checkbox = document.getElementById('otherSubjectCheckbox');
            const container = document.getElementById('otherSubjectInputContainer');
            const input = document.getElementById('otherSubjectName');
            
            if (checkbox.checked) {
                container.style.display = 'block';
                input.focus();
            } else {
                container.style.display = 'none';
                input.value = '';
            }
        }
        
        // Submit Teacher Form
        function submitTeacher(event) {
            event.preventDefault();
            
            // Get form data
            const name = document.getElementById('teacherName').value.trim();
            const mobile = document.getElementById('teacherMobile').value.trim();
            const description = document.getElementById('teacherDescription').value.trim();
            
            // Get selected subjects from checkboxes
            const subjectCheckboxes = document.querySelectorAll('.subject-checkbox:checked');
            let subjects = Array.from(subjectCheckboxes).map(cb => cb.value);
            
            // Validate at least one subject is selected
            if (subjects.length === 0) {
                document.getElementById('subjectError').style.display = 'block';
                alert('कृपया किमान एक विषय निवडा / Please select at least one subject');
                return;
            } else {
                document.getElementById('subjectError').style.display = 'none';
            }
            
            // Check if "Other Subject" is selected
            const otherSubjectCheckbox = document.getElementById('otherSubjectCheckbox');
            const otherSubjectName = document.getElementById('otherSubjectName').value.trim();
            
            if (otherSubjectCheckbox.checked) {
                if (!otherSubjectName) {
                    alert('कृपया इतर विषयाचे नाव लिहा / Please enter the इतर (Other) name');
                    document.getElementById('otherSubjectName').focus();
                    return;
                }
                // Replace "Other Subject" with the custom name
                subjects = subjects.map(subject => 
                    subject === 'इतर (Other)' ? otherSubjectName : subject
                );
            }
            
            // Prepare data - Use URLSearchParams instead of FormData
            const formData = new URLSearchParams();
            formData.append('teacherName', name);
            formData.append('teacherMobile', mobile);
            formData.append('subjects', subjects.join(','));
            formData.append('description', description);
            
            console.log('Submitting teacher data:', {name, mobile, subjects: subjects.join(','), description});
            console.log('FormData entries:');
            for (let pair of formData.entries()) {
                console.log(pair[0] + ': ' + pair[1]);
            }
            
            // Submit to server
            console.log('Sending request to:', '<%= request.getContextPath() %>/add-teacher');
            
            fetch('<%= request.getContextPath() %>/add-teacher', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: formData.toString()
            })
            .then(response => {
                console.log('Response status:', response.status);
                console.log('Response ok:', response.ok);
                
                if (!response.ok) {
                    console.error('HTTP error:', response.status, response.statusText);
                    
                    // Check if it's a 404 - servlet not found
                    if (response.status === 404) {
                        alert('❌ Error: Add Teacher servlet not found!\n\n' +
                              'The backend servlet "/add-teacher" is not deployed.\n\n' +
                              'Please create AddTeacherServlet.java and deploy it.');
                        return;
                    }
                    
                    // Try to get error text
                    return response.text().then(text => {
                        console.error('Error response:', text);
                        alert('Server error: ' + response.status + '\n' + text);
                    });
                }
                
                return response.json();
            })
            .then(data => {
                if (!data) return; // Already handled error above
                
                console.log('Response data:', data);
                
                if (data.success) {
                    alert('✓ Teacher added successfully!\n\nName: ' + name + '\nMobile: ' + mobile + '\nSubjects: ' + subjects.join(', '));
                    closeAddTeacherModal();
                } else {
                    alert('Error: ' + (data.message || 'Failed to add teacher'));
                }
            })
            .catch(error => {
                console.error('Fetch error:', error);
                alert('❌ Error adding teacher!\n\n' +
                      'Error: ' + error.message + '\n\n' +
                      'Check browser console (F12) for details.\n\n' +
                      'Make sure AddTeacherServlet.java is created and deployed.');
            });
        }
        
        // Verify functions are defined
        console.log('showPhaseDetails function defined:', typeof showPhaseDetails);
        console.log('closeModal function defined:', typeof closeModal);
        console.log('getMarathiLevelText function defined:', typeof getMarathiLevelText);
        console.log('getMathLevelText function defined:', typeof getMathLevelText);
        console.log('getEnglishLevelText function defined:', typeof getEnglishLevelText);
        
        // Test the conversion functions with actual dropdown values
        console.log('Test Marathi Level 1:', getMarathiLevelText(1));
        console.log('Test Math Level 1:', getMathLevelText(1));
        console.log('Test English Level 2:', getEnglishLevelText(2));
        
        // Wait for page to fully load, then check student data
        window.addEventListener('DOMContentLoaded', function() {
            console.log('=== PAGE LOADED - Checking Student Data ===');
            
            // Direct test with exact values from user's data
            console.log('DIRECT TEST - marathiLevel 1:', getMarathiLevelText(1));
            console.log('DIRECT TEST - mathLevel 1:', getMathLevelText(1));
            console.log('DIRECT TEST - englishLevel 2:', getEnglishLevelText(2));
            
            if (typeof window.phase1Students !== 'undefined') {
                console.log('Phase 1 Students array exists:', window.phase1Students.length, 'students');
                if (window.phase1Students.length > 0) {
                    console.log('First student full data:', JSON.stringify(window.phase1Students[0], null, 2));
                    console.log('First student Marathi level VALUE:', window.phase1Students[0].marathiLevel);
                    console.log('First student Marathi level TYPE:', typeof window.phase1Students[0].marathiLevel);
                    var convertedText = getMarathiLevelText(window.phase1Students[0].marathiLevel);
                    console.log('CONVERTED TEXT RESULT:', convertedText);
                    console.log('CONVERTED TEXT TYPE:', typeof convertedText);
                }
            } else {
                console.log('Phase 1 Students array NOT FOUND - modal will not work!');
            }
        });
        
        // ===== VIDEO APPROVAL FUNCTIONS (Headmaster Only) =====
        
        // Approve video
        function approveSchoolVideo(videoId) {
            if (!confirm('Are you sure you want to approve this video? It will become visible to students.')) {
                return;
            }
            
            const formData = new FormData();
            formData.append('videoId', videoId);
            formData.append('action', 'approve');
            
            fetch('approve-video', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✅ ' + data.message);
                    location.reload(); // Reload to update the video list
                } else {
                    alert('❌ ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('❌ Failed to approve video. Please try again.');
            });
        }
        
        // Reject video
        function rejectSchoolVideo(videoId) {
            const reason = prompt('Please enter the reason for rejecting this video:');
            
            if (!reason || reason.trim() === '') {
                alert('Rejection reason is required!');
                return;
            }
            
            const formData = new FormData();
            formData.append('videoId', videoId);
            formData.append('action', 'reject');
            formData.append('rejectionReason', reason.trim());
            
            fetch('approve-video', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✅ ' + data.message);
                    location.reload(); // Reload to update the video list
                } else {
                    alert('❌ ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('❌ Failed to reject video. Please try again.');
            });
        }
    </script>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div class="header-left">
                 <div class="header-logo">
                    <img src="<%= request.getContextPath() %>/Document/GATEE LOGO.png?v=2" alt="GATEE Logo">
                </div> 
                <div class="school-icon">🏫</div>
                <h1><%= schoolName %></h1>
                <div class="header-subtitle">UDISE: <%= udiseNo %> | <%= user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) ? "School Coordinator" : "Head Master" %></div>
            </div>
            <div class="header-info">
               <%--  <div class="user-badge">
                    🏷️ <%= user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) ? "School Coordinator" : "Head Master" %>
                </div> --%>
                <div class="header-actions">
                    <% if (user.getUserType().equals(User.UserType.HEAD_MASTER)) { %>
                        <!-- Quick Actions Dropdown for Head Master -->
                        <div class="quick-actions-dropdown">
                            <button class="quick-actions-btn" onclick="toggleQuickActions()">
                                <span>⚡</span>
                                <span>Quick Actions</span>
                                <% 
                                    int totalPending = pendingApprovalsCount + palakMelavaPendingCount + pendingVideosCount;
                                    if (totalPending > 0) { 
                                %>
                                    <span class="badge"><%= totalPending %></span>
                                <% } %>
                                <span style="font-size: 10px;">▼</span>
                            </button>
                            <div class="dropdown-menu" id="quickActionsMenu">
                                <div class="dropdown-section">
                                    <div class="section-title">Approval Actions</div>
                                    
                                    <a href="<%= request.getContextPath() %>/phase-approvals.jsp" class="dropdown-item" title="Approve student phase completions">
                                        <div class="dropdown-item-content">
                                            <span>📋</span>
                                            <span>Phase Approvals</span>
                                        </div>
                                        <% if (pendingApprovalsCount > 0) { %>
                                            <span class="item-badge"><%= pendingApprovalsCount %></span>
                                        <% } %>
                                    </a>
                                    
                                    <a href="<%= request.getContextPath() %>/palak-melava-approvals.jsp" class="dropdown-item" title="Approve Palak Melava (Parent Meeting) submissions">
                                        <div class="dropdown-item-content">
                                            <span>👥</span>
                                            <span>Palak Melava</span>
                                        </div>
                                        <% if (palakMelavaPendingCount > 0) { %>
                                            <span class="item-badge"><%= palakMelavaPendingCount %></span>
                                        <% } %>
                                    </a>
                                    
                                    <a href="<%= request.getContextPath() %>/approve-videos.jsp" class="dropdown-item" title="Approve uploaded videos">
                                        <div class="dropdown-item-content">
                                            <span>🎥</span>
                                            <span>Approve Videos</span>
                                        </div>
                                        <% if (pendingVideosCount > 0) { %>
                                            <span class="item-badge"><%= pendingVideosCount %></span>
                                        <% } %>
                                    </a>
                                </div>
                            </div>
                        </div>
                    <% } %>
                    
                    <!-- Account Actions -->
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
    
    <script>
        // Quick Actions Dropdown Toggle
        function toggleQuickActions() {
            const menu = document.getElementById('quickActionsMenu');
            if (menu) {
                menu.classList.toggle('show');
            }
        }
        
        // Close dropdown when clicking outside
        window.addEventListener('click', function(e) {
            if (!e.target.closest('.quick-actions-dropdown')) {
                const menu = document.getElementById('quickActionsMenu');
                if (menu) {
                    menu.classList.remove('show');
                }
            }
        });
    </script>
    
    <div class="container">
        <!-- Welcome Card -->
        <div class="welcome-card">
            <div class="welcome-content">
                <!-- Notifications Section -->
                <% if (notifications != null && notifications.size() > 0) { %>
                <div class="notifications-section">
                    <div class="notifications-header">
                        <span class="notification-icon">🔔</span>
                        <span>Announcements from Division Head</span>
                        <span class="notification-badge"><%= notifications.size() %></span>
                    </div>
                    <div class="notifications-list">
                        <% 
                        int displayCount = 0;
                        for (Map<String, Object> notif : notifications) {
                            if (displayCount >= 3) break; // Show max 3 notifications
                            displayCount++;
                            
                            String type = (String) notif.get("type");
                            int priority = (Integer) notif.get("priority");
                            String priorityLabel = priority == 2 ? "URGENT" : (priority == 1 ? "HIGH" : "NORMAL");
                            String priorityClass = "priority-" + priority;
                            
                            java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("MMM dd, yyyy hh:mm a");
                            String createdDate = sdf.format((java.util.Date) notif.get("createdDate"));
                        %>
                        <div class="notification-item type-<%= type %>">
                            <div class="notification-header">
                                <span class="notification-title">
                                    <% if (type.equals("URGENT")) { %>⚠️<% } %>
                                    <% if (type.equals("WARNING")) { %>⚡<% } %>
                                    <% if (type.equals("INFO")) { %>ℹ️<% } %>
                                    <% if (type.equals("SUCCESS")) { %>✅<% } %>
                                    <%= notif.get("title") %>
                                </span>
                                <span class="notification-priority <%= priorityClass %>">
                                    <%= priorityLabel %>
                                </span>
                            </div>
                            <div class="notification-message">
                                <%= notif.get("message") %>
                            </div>
                            <div class="notification-footer">
                                <span class="notification-author">
                                    📢 <%= notif.get("createdBy") %>
                                </span>
                                <span class="notification-date">
                                    <%= createdDate %>
                                </span>
                            </div>
                        </div>
                        <% } %>
                        
                        <% if (notifications.size() > 3) { %>
                        <div style="text-align: center; padding: 10px;">
                            <a href="#" style="color: #667eea; font-weight: 600; text-decoration: none;">
                                View <%= notifications.size() - 3 %> more notifications →
                            </a>
                        </div>
                        <% } %>
                    </div>
                </div>
                <% } else { %>
                <div class="notifications-section">
                    <div class="notifications-header">
                        <span class="notification-icon">🔔</span>
                        <span>Announcements from Division Head</span>
                    </div>
                    <div class="no-notifications">
                        📭 No new announcements at this time
                    </div>
                </div>
                <% } %>
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
        
        <!-- Quick Actions -->
        <div class="section" style="margin-bottom: 30px;">
            <h2 class="section-title">⚡ Quick Actions</h2>
            <p style="margin-bottom: 20px; color: #666;">त्वरित क्रिया (Quick access to important features)</p>
            
            <div class="grid-3">
                <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) { %>
                <!-- 1. Manage Students - DISABLED -->
                 <a href="<%= request.getContextPath() %>/manage-students.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">📚</div>
                    <div class="quick-action-title">Manage Students</div>
                    <div class="quick-action-subtitle">विद्यार्थी स्तर निश्चिती</div>
                    <div class="quick-action-desc">Complete student management with view, edit, delete options. Search, filter, and export student data.</div>
                </a>
                
                <!-- 2. View All Student Data - ENABLED -->
              <%--   <a href="<%= request.getContextPath() %>/view-all-students.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">📊</div>
                    <div class="quick-action-title">Students Activity</div>
                    <div class="quick-action-subtitle">विद्यार्थी अक्टिव्हिटी </div>
                    <div class="quick-action-desc">Display all student information registered against this UDISE number with filtering and search capabilities.</div>
                </a>
                 --%>
                <!-- 3. Palak Melava - ENABLED -->
                <a href="<%= request.getContextPath() %>/palak-melava.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">👥</div>
                    <div class="quick-action-title">Parents Meeting</div>
                    <div class="quick-action-subtitle">पालक मेळावा</div>
                    <div class="quick-action-desc">Register parent meetings, upload photos, and manage approvals. Track all Palak Melava activities.</div>
                </a> 
                
                <!-- 4. Add Student - DISABLED -->
                 <a href="<%= request.getContextPath() %>/add-modify-student.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">➕</div>
                    <div class="quick-action-title">Add Student</div>
                    <div class="quick-action-subtitle">विद्यार्थी जोडा</div>
                    <div class="quick-action-desc">Add new student records with personal, academic details and language proficiency information.</div>
                </a>
                
                <!-- 5. Add Teacher - ENABLED -->
                <a href="javascript:void(0);" onclick="openAddTeacherModal()" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">👨‍🏫</div>
                    <div class="quick-action-title">Add Teacher</div>
                    <div class="quick-action-subtitle">शिक्षक जोडा</div>
                    <div class="quick-action-desc">Add new teacher with name, contact details, subjects taught, and additional information.</div>
                </a>
                
                <!-- 6. Edit Student - DISABLED -->
               <a href="<%= request.getContextPath() %>/select-student-to-edit.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">✏️</div>
                    <div class="quick-action-title">Edit Student</div>
                    <div class="quick-action-subtitle">विद्यार्थी संपादित करा</div>
                    <div class="quick-action-desc">Modify existing student information. Select a student from the list and update their details.</div>
                </a>
                
                <!-- 7. Manage Teachers - ENABLED -->
                <a href="<%= request.getContextPath() %>/manage-teachers.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">👨‍🏫</div>
                    <div class="quick-action-title">Manage Teachers</div>
                    <div class="quick-action-subtitle">शिक्षक व्यवस्थापन</div>
                    <div class="quick-action-desc">View, edit, and manage all teachers. Search by name, mobile, or subject. Update details and assignments.</div>
                </a>
                
                <!-- 8. Assign Teacher to Class - ENABLED -->
                <a href="<%= request.getContextPath() %>/assign-teacher.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">📋</div>
                    <div class="quick-action-title">Class teacher / Subject teacher assignment</div>
                    <div class="quick-action-subtitle">(वर्ग शिक्षक / विषय शिक्षक निश्चिती)</div>
                    <div class="quick-action-desc">Assign teachers to specific classes, sections and subjects. Manage teacher assignments and schedules.</div>
                </a>
                
                 <a href="<%= request.getContextPath() %>/other-school-activity.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">🎯</div>
                    <div class="quick-action-title">Other School Activity</div>
                    <div class="quick-action-subtitle">इतर शालेय उपक्रम</div>
                    <div class="quick-action-desc">Record other school activities with date, subject, guests, description, photos and video link. Requires headmaster approval.</div>
                </a>
                
                  <!-- <a href="javascript:void(0);" onclick="openVideoUploadModal()" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">🎥</div>
                    <div class="quick-action-title">Video Upload</div>
                    <div class="quick-action-subtitle">व्हिडिओ अपलोड</div>
                    <div class="quick-action-desc">Upload student progress videos. Select student, subject, month and track their development journey.</div>
                </a>  -->
                
                 <a href="<%= request.getContextPath() %>/view-student-data.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">📊</div>
                    <div class="quick-action-title">View All Student Data</div>
                    <div class="quick-action-subtitle">सर्व विद्यार्थी डेटा</div>
                    <div class="quick-action-desc">Display all student information registered against this UDISE number with filtering and search capabilities.</div>
                </a>
                
                <!-- 12. VIEW UPLOADED VIDEOS - ENABLED -->
               <!--  <a href="javascript:void(0);" onclick="openUploadedVideosModal()" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">📹</div>
                    <div class="quick-action-title">View Uploaded Videos</div>
                    <div class="quick-action-subtitle">अपलोड केलेले व्हिडिओ पहा</div>
                    <div class="quick-action-desc">View all uploaded student progress videos. Filter by subject, month, student and track learning progress with video playback.</div>
                </a> -->
                 <a href="<%= request.getContextPath() %>/fln-completed-students.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">🏆</div>
                    <div class="quick-action-title">FLN Completed Students</div>
                    <div class="quick-action-subtitle">FLN 100% पूर्ण विद्यार्थी</div>
                    <div class="quick-action-desc">View students who achieved 100% FLN in all subjects (Marathi=6, Math=8, English=6). These students are excluded from phase activities.</div>
                </a>
                <!-- 9. Student Comprehensive Report (School Coordinator) - ENABLED -->
                <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) { %>
                  <a href="<%= request.getContextPath() %>/student-comprehensive-report-new.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">📊</div>
                    <div class="quick-action-title">Generate Student Report</div>
                    <div class="quick-action-subtitle">विद्यार्थी अहवाल तयार करा</div>
                    <div class="quick-action-desc">Request comprehensive student reports with academic data, activities, and progress tracking. Submit for headmaster approval.</div>
                </a>  
                
                <!-- 10. Phase-wise Subject Statistics - ENABLED -->
                <%-- <a href="<%= request.getContextPath() %>/phase-statistics.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">📊</div>
                    <div class="quick-action-title">Phase-wise Subject Statistics</div>
                    <div class="quick-action-subtitle">टप्पा-निहाय विषय आकडेवारी</div>
                    <div class="quick-action-desc">View detailed phase-wise subject level counts for all students. Track dropdown values across all 4 phases with aggregate statistics.</div>
                </a> --%>
                
                <!-- 11. VIDEO UPLOAD - ENABLED -->
               
                
                <!-- 13. FLN Completed Students - DISABLED -->
                <!-- <div class="quick-action-card quick-action-disabled" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">🏆</div>
                    <div class="quick-action-title">FLN Completed Students</div>
                    <div class="quick-action-subtitle">FLN 100% पूर्ण विद्यार्थी</div>
                    <div class="quick-action-desc">View students who achieved 100% FLN in all subjects (Marathi=6, Math=8, English=6). These students are excluded from phase activities.</div>
                </div> -->
                
                 <!-- 14. Other School Activity (School Coordinator) - DISABLED -->
                <!-- <div class="quick-action-card quick-action-disabled" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">🎯</div>
                    <div class="quick-action-title">Other School Activity</div>
                    <div class="quick-action-subtitle">इतर शालेय उपक्रम</div>
                    <div class="quick-action-desc">Record other school activities with date, subject, guests, description, photos and video link. Requires headmaster approval.</div>
                </div> -->
                
               <%--  <!-- 10. My Report Requests -->
                <a href="<%= request.getContextPath() %>/my-report-requests.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">📋</div>
                    <div class="quick-action-title">My Report Requests</div>
                    <div class="quick-action-subtitle">माझ्या अहवालांची विनंती</div>
                    <div class="quick-action-desc">Track all your report requests. View approval status and print approved reports.</div>
                </a> --%>
                <%-- <a href="<%= request.getContextPath() %>/phase-wise-subject-statistics.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">📊</div>
                    <div class="quick-action-title">Phase-wise Subject Statistics</div>
                    <div class="quick-action-subtitle">टप्पा-निहाय विषय आकडेवारी</div>
                    <div class="quick-action-desc">View detailed phase-wise subject level counts for all students. Track dropdown values across all 4 phases with aggregate statistics.</div>
                </a> --%>
                <% } %>
                <% } %>
                
                <!-- Headmaster Only Actions -->
                <% if (user.getUserType().equals(User.UserType.HEAD_MASTER)) { %>
                <!-- 11. Approve Reports (Headmaster Only) - DISABLED -->
                 <a href="<%= request.getContextPath() %>/approve-student-reports.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">✅</div>
                    <div class="quick-action-title">Approve Reports</div>
                    <div class="quick-action-subtitle">अहवाल मंजूर करा</div>
                    <div class="quick-action-desc">Review and approve pending student comprehensive reports. View student data and approve or reject requests.</div>
                </a> 
                
                <!-- Other School Activity Approvals (Headmaster Only) - ENABLED -->
                <a href="<%= request.getContextPath() %>/other-school-activity-approvals.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">🎯</div>
                    <div class="quick-action-title">Approve School Activities</div>
                    <div class="quick-action-subtitle">शालेय उपक्रम मंजूर करा</div>
                    <div class="quick-action-desc">Review and approve pending other school activities submitted by coordinator. View details, photos and approve or reject.</div>
                </a>
                <a href="<%= request.getContextPath() %>/fln-completed-students.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">🏆</div>
                    <div class="quick-action-title">FLN Completed Students</div>
                    <div class="quick-action-subtitle">FLN 100% पूर्ण विद्यार्थी</div>
                    <div class="quick-action-desc">View students who achieved 100% FLN in all subjects (Marathi=6, Math=8, English=6). These students are excluded from phase activities.</div>
                </a>
                <!-- 12. Phase-wise Subject Statistics (Headmaster) - DISABLED -->
               <%--  <a href="<%= request.getContextPath() %>/phase-wise-stats.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">📊</div>
                    <div class="quick-action-title">Phase-wise Subject Statistics</div>
                    <div class="quick-action-subtitle">टप्पा-निहाय विषय आकडेवारी</div>
                    <div class="quick-action-desc">View detailed phase-wise subject level counts for all students. Track dropdown values across all 4 phases with aggregate statistics.</div>
                </a> --%>
                
                <!-- 13. FLN Completed Students (Headmaster) - DISABLED -->
               <%--  <a href="<%= request.getContextPath() %>/fln-completed-students.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">🏆</div>
                    <div class="quick-action-title">FLN Completed Students</div>
                    <div class="quick-action-subtitle">FLN 100% पूर्ण विद्यार्थी</div>
                    <div class="quick-action-desc">View students who achieved 100% FLN in all subjects (Marathi=6, Math=8, English=6). These students are excluded from phase activities.</div>
                </a>
                
                 <!-- 14. Other School Activity (School Coordinator) -->
                <a href="<%= request.getContextPath() %>/other-school-activity.jsp" class="quick-action-card" style="text-decoration: none; color: inherit;">
                    <div class="quick-action-icon">🎯</div>
                    <div class="quick-action-title">Other School Activity</div>
                    <div class="quick-action-subtitle">इतर शालेय उपक्रम</div>
                    <div class="quick-action-desc">Record other school activities with date, subject, guests, description, photos and video link. Requires headmaster approval.</div>
                </a> --%>
                <% } %>
            </div>
        </div>
        
        <!-- Phase Reports - School Coordinator Only -->
        <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) { %>
        <div class="section">
            <h2 class="section-title">📈 चरण अहवाल (Phase Completion Reports)</h2>
            <p style="margin-bottom: 20px; color: #666;">Track the progress of each phase for your school</p>
            
            <div class="phase-reports">
                <!-- Phase 1 -->
                <div class="phase-card clickable <%= phase1Approved ? "complete" : (phase1Complete ? "complete" : (phase1Completion > 0 ? "in-progress" : "not-started")) %>" onclick="console.log('Phase 1 card clicked!'); showPhaseDetails(1, event);" style="position: relative;">
                    <div class="phase-header">
                        <div class="phase-title">चरण 1 (Phase 1)</div>
                        <div class="phase-icon"><%= phase1Approved ? "✅" : (phase1Complete ? "✓" : (phase1Completion > 0 ? "⏳" : "🔒")) %></div>
                    </div>
                    
                    <div class="phase-progress">
                        <div class="progress-label">
                            <span>Progress</span>
                            <span><strong><%= phase1Completion %>%</strong></span>
                        </div>
                        <div class="progress-bar-container">
                            <div class="progress-bar <%= phase1Approved ? "complete" : (phase1Complete ? "complete" : (phase1Completion > 0 ? "in-progress" : "")) %>" 
                                 style="width: <%= phase1Completion %>%">
                                <%= phase1Completion > 10 ? phase1Completion + "%" : "" %>
                            </div>
                        </div>
                    </div>
                    
                    <% if (phase1Approval != null && phase1Approval.isPending()) { %>
                        <div class="phase-status pending-approval">⏳ Pending Approval</div>
                    <% } else if (phase1Approved) { %>
                        <div class="phase-status complete">✅ Approved by Head Master</div>
                    <% } else if (phase1Approval != null && phase1Approval.isRejected()) { %>
                        <div class="phase-status rejected">✗ Rejected - Resubmit Required</div>
                    <% } else if (phase1Complete) { %>
                        <div class="phase-status complete">✓ Completed - Ready to Submit</div>
                    <% } else if (phase1Completion > 0) { %>
                        <div class="phase-status in-progress">⏳ In Progress (<%= phase1Completion %>%)</div>
                    <% } else { %>
                        <div class="phase-status not-started">🔒 Not Started</div>
                    <% } %>
                    
                    <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && phase1Complete && !phase1Approved && (phase1Approval == null || phase1Approval.isRejected())) { %>
                        <button class="btn-submit-phase" onclick="event.stopPropagation(); submitPhaseForApproval(1);">
                            📤 Submit for Approval
                        </button>
                    <% } %>
                </div>
                
                <!-- Phase 2 -->
                <div class="phase-card clickable <%= phase2Approved ? "complete" : (phase2Complete ? "complete" : (phase2Completion > 0 ? "in-progress" : "not-started")) %>" onclick="showPhaseDetails(2, event)">
                    <div class="phase-header">
                        <div class="phase-title">चरण 2 (Phase 2)</div>
                        <div class="phase-icon"><%= phase2Approved ? "✅" : (phase2Complete ? "✓" : (phase2Completion > 0 ? "⏳" : "🔒")) %></div>
                    </div>
                    
                    <div class="phase-progress">
                        <div class="progress-label">
                            <span>Progress</span>
                            <span><strong><%= phase2Completion %>%</strong></span>
                        </div>
                        <div class="progress-bar-container">
                            <div class="progress-bar <%= phase2Approved ? "complete" : (phase2Complete ? "complete" : (phase2Completion > 0 ? "in-progress" : "")) %>" 
                                 style="width: <%= phase2Completion %>%">
                                <%= phase2Completion > 10 ? phase2Completion + "%" : "" %>
                            </div>
                        </div>
                    </div>
                    
                    <% if (phase2Approval != null && phase2Approval.isPending()) { %>
                        <div class="phase-status pending-approval">⏳ Pending Approval</div>
                    <% } else if (phase2Approved) { %>
                        <div class="phase-status complete">✅ Approved by Head Master</div>
                    <% } else if (phase2Approval != null && phase2Approval.isRejected()) { %>
                        <div class="phase-status rejected">✗ Rejected - Resubmit Required</div>
                    <% } else if (phase2Complete) { %>
                        <div class="phase-status complete">✓ Completed - Ready to Submit</div>
                    <% } else if (phase2Completion > 0) { %>
                        <div class="phase-status in-progress">⏳ In Progress (<%= phase2Completion %>%)</div>
                    <% } else { %>
                        <div class="phase-status not-started">🔒 Not Started</div>
                    <% } %>
                    
                    <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && phase2Complete && !phase2Approved && (phase2Approval == null || phase2Approval.isRejected())) { %>
                        <button class="btn-submit-phase" onclick="event.stopPropagation(); submitPhaseForApproval(2);">
                            📤 Submit for Approval
                        </button>
                    <% } %>
                </div>
                
                <!-- Phase 3 -->
                <div class="phase-card clickable <%= phase3Approved ? "complete" : (phase3Complete ? "complete" : (phase3Completion > 0 ? "in-progress" : "not-started")) %>" onclick="showPhaseDetails(3, event)">
                    <div class="phase-header">
                        <div class="phase-title">चरण 3 (Phase 3)</div>
                        <div class="phase-icon"><%= phase3Approved ? "✅" : (phase3Complete ? "✓" : (phase3Completion > 0 ? "⏳" : "🔒")) %></div>
                    </div>
                    
                    <div class="phase-progress">
                        <div class="progress-label">
                            <span>Progress</span>
                            <span><strong><%= phase3Completion %>%</strong></span>
                        </div>
                        <div class="progress-bar-container">
                            <div class="progress-bar <%= phase3Approved ? "complete" : (phase3Complete ? "complete" : (phase3Completion > 0 ? "in-progress" : "")) %>" 
                                 style="width: <%= phase3Completion %>%">
                                <%= phase3Completion > 10 ? phase3Completion + "%" : "" %>
                            </div>
                        </div>
                    </div>
                    
                    <% if (phase3Approval != null && phase3Approval.isPending()) { %>
                        <div class="phase-status pending-approval">⏳ Pending Approval</div>
                    <% } else if (phase3Approved) { %>
                        <div class="phase-status complete">✅ Approved by Head Master</div>
                    <% } else if (phase3Approval != null && phase3Approval.isRejected()) { %>
                        <div class="phase-status rejected">✗ Rejected - Resubmit Required</div>
                    <% } else if (phase3Complete) { %>
                        <div class="phase-status complete">✓ Completed - Ready to Submit</div>
                    <% } else if (phase3Completion > 0) { %>
                        <div class="phase-status in-progress">⏳ In Progress (<%= phase3Completion %>%)</div>
                    <% } else { %>
                        <div class="phase-status not-started">🔒 Not Started</div>
                    <% } %>
                    
                    <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && phase3Complete && !phase3Approved && (phase3Approval == null || phase3Approval.isRejected())) { %>
                        <button class="btn-submit-phase" onclick="event.stopPropagation(); submitPhaseForApproval(3);">
                            📤 Submit for Approval
                        </button>
                    <% } %>
                </div>
                
                <!-- Phase 4 -->
                <div class="phase-card clickable <%= phase4Approved ? "complete" : (phase4Complete ? "complete" : (phase4Completion > 0 ? "in-progress" : "not-started")) %>" onclick="showPhaseDetails(4, event)">
                    <div class="phase-header">
                        <div class="phase-title">चरण 4 (Phase 4)</div>
                        <div class="phase-icon"><%= phase4Approved ? "✅" : (phase4Complete ? "✓" : (phase4Completion > 0 ? "⏳" : "🔒")) %></div>
                    </div>
                    
                    <div class="phase-progress">
                        <div class="progress-label">
                            <span>Progress</span>
                            <span><strong><%= phase4Completion %>%</strong></span>
                        </div>
                        <div class="progress-bar-container">
                            <div class="progress-bar <%= phase4Approved ? "complete" : (phase4Complete ? "complete" : (phase4Completion > 0 ? "in-progress" : "")) %>" 
                                 style="width: <%= phase4Completion %>%">
                                <%= phase4Completion > 10 ? phase4Completion + "%" : "" %>
                            </div>
                        </div>
                    </div>
                    
                    <% if (phase4Approval != null && phase4Approval.isPending()) { %>
                        <div class="phase-status pending-approval">⏳ Pending Approval</div>
                    <% } else if (phase4Approved) { %>
                        <div class="phase-status complete">✅ Approved by Head Master</div>
                    <% } else if (phase4Approval != null && phase4Approval.isRejected()) { %>
                        <div class="phase-status rejected">✗ Rejected - Resubmit Required</div>
                    <% } else if (phase4Complete) { %>
                        <div class="phase-status complete">✓ Completed - Ready to Submit</div>
                    <% } else if (phase4Completion > 0) { %>
                        <div class="phase-status in-progress">⏳ In Progress (<%= phase4Completion %>%)</div>
                    <% } else { %>
                        <div class="phase-status not-started">🔒 Not Started</div>
                    <% } %>
                    
                    <% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && phase4Complete && !phase4Approved && (phase4Approval == null || phase4Approval.isRejected())) { %>
                        <button class="btn-submit-phase" onclick="event.stopPropagation(); submitPhaseForApproval(4);">
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
        
        <!-- Uploaded Videos Modal -->
        <div id="uploadedVideosModal" class="modal" style="display: none;">
            <div class="modal-content" style="max-width: 1400px; max-height: 90vh; overflow-y: auto;">
                <div class="modal-header" style="background: linear-gradient(135deg, #ff6b35 0%, #f7931e 100%); color: white;">
                    <h2>🎥 Uploaded Videos - अपलोड केलेले व्हिडिओ</h2>
                    <span class="close" onclick="closeUploadedVideosModal()">&times;</span>
                </div>
                <div class="modal-body">
                    <p style="margin-bottom: 20px; color: #666;">View all student progress videos (विद्यार्थी प्रगती व्हिडिओ पहा)</p>
            
            <%
            // Fetch uploaded videos from database with approval filtering
            List<Map<String, Object>> uploadedVideos = new ArrayList<>();
            Connection videoConn = null;
            PreparedStatement videoPstmt = null;
            ResultSet videoRs = null;
            String videoFetchError = null;
            
            try {
                videoConn = DatabaseConnection.getConnection();
                
                // First, check if student_videos table has any data at all
                String countSql = "SELECT COUNT(*) as total FROM student_videos WHERE is_active = TRUE";
                PreparedStatement countPstmt = videoConn.prepareStatement(countSql);
                ResultSet countRs = countPstmt.executeQuery();
                int totalVideosInDb = 0;
                if (countRs.next()) {
                    totalVideosInDb = countRs.getInt("total");
                }
                countRs.close();
                countPstmt.close();
                
                //System.out.println("=== VIDEO FETCH DEBUG START ===");
                //System.out.println("Total videos in database: " + totalVideosInDb);
                //System.out.println("User Type: " + user.getUserType());
                //System.out.println("UDISE Number: " + udiseNo);
                
                // Build query based on user role
                String videoSql;
                if (user.getUserType().equals(User.UserType.HEAD_MASTER)) {
                    // Headmaster sees ALL videos (approved, pending, rejected)
                    videoSql = "SELECT v.video_id, v.student_id, s.student_name, s.student_pen, s.class, s.section, " +
                              "v.subject, v.month, v.has_progress, v.original_file_name, v.file_path, " +
                              "v.file_size, v.uploaded_by_name, v.upload_date, v.thumbnail_url, " +
                              "COALESCE(v.approval_status, 'PENDING') as approval_status, v.is_visible " +
                              "FROM student_videos v " +
                              "LEFT JOIN students s ON v.student_id = s.student_id " +
                              "WHERE v.udise_no = ? AND v.is_active = TRUE " +
                              "ORDER BY v.upload_date DESC";
                    //System.out.println("Query: Fetching ALL videos for HEAD_MASTER");
                } else {
                    // School Coordinator sees only APPROVED videos
                    videoSql = "SELECT v.video_id, v.student_id, s.student_name, s.student_pen, s.class, s.section, " +
                              "v.subject, v.month, v.has_progress, v.original_file_name, v.file_path, " +
                              "v.file_size, v.uploaded_by_name, v.upload_date, v.thumbnail_url, " +
                              "COALESCE(v.approval_status, 'PENDING') as approval_status, v.is_visible " +
                              "FROM student_videos v " +
                              "LEFT JOIN students s ON v.student_id = s.student_id " +
                              "WHERE v.udise_no = ? AND v.is_active = TRUE " +
                              "AND v.approval_status = 'APPROVED' AND v.is_visible = TRUE " +
                              "ORDER BY v.upload_date DESC";
                    //System.out.println("Query: Fetching only APPROVED videos for SCHOOL_COORDINATOR");
                }
                
                videoPstmt = videoConn.prepareStatement(videoSql);
                videoPstmt.setString(1, udiseNo);
                //System.out.println("Executing query with UDISE: " + udiseNo);
                videoRs = videoPstmt.executeQuery();
                
                while (videoRs.next()) {
                    Map<String, Object> video = new HashMap<>();
                    video.put("videoId", videoRs.getInt("video_id"));
                    video.put("studentId", videoRs.getInt("student_id"));
                    video.put("studentName", videoRs.getString("student_name"));
                    video.put("studentPen", videoRs.getString("student_pen"));
                    video.put("studentClass", videoRs.getString("class"));
                    video.put("section", videoRs.getString("section"));
                    video.put("subject", videoRs.getString("subject"));
                    video.put("month", videoRs.getString("month"));
                    video.put("hasProgress", videoRs.getString("has_progress"));
                    video.put("fileName", videoRs.getString("original_file_name"));
                    video.put("filePath", videoRs.getString("file_path"));
                    video.put("fileSize", videoRs.getLong("file_size"));
                    video.put("uploadedBy", videoRs.getString("uploaded_by_name"));
                    video.put("uploadDate", videoRs.getTimestamp("upload_date"));
                    video.put("thumbnailUrl", videoRs.getString("thumbnail_url"));
                    video.put("approvalStatus", videoRs.getString("approval_status"));
                    video.put("isVisible", videoRs.getBoolean("is_visible"));
                    uploadedVideos.add(video);
                    //System.out.println("Added video: " + videoRs.getString("subject") + " - " + videoRs.getString("month"));
                }
                
                //System.out.println("Successfully fetched " + uploadedVideos.size() + " videos for this school");
                if (uploadedVideos.isEmpty() && totalVideosInDb > 0) {
                    //System.out.println("WARNING: Database has videos but none match the filters for this UDISE/user");
                }
                if (!uploadedVideos.isEmpty()) {
                    //System.out.println("First video - Status: " + uploadedVideos.get(0).get("approvalStatus") + 
                                      //", Subject: " + uploadedVideos.get(0).get("subject"));
                }
                //System.out.println("=== VIDEO FETCH DEBUG END ===");
                
            } catch (Exception e) {
                videoFetchError = e.getMessage();
                System.err.println("ERROR fetching uploaded videos: " + e.getMessage());
                System.err.println("Error type: " + e.getClass().getName());
                e.printStackTrace();
            } finally {
                if (videoRs != null) try { videoRs.close(); } catch (SQLException e) { }
                if (videoPstmt != null) try { videoPstmt.close(); } catch (SQLException e) { }
                if (videoConn != null) try { videoConn.close(); } catch (SQLException e) { }
            }
            %>
            
            <% if (videoFetchError != null) { %>
            <!-- Database Error Message -->
            <div style="text-align: center; padding: 60px 20px; background: linear-gradient(135deg, #ffebee 0%, #ffcdd2 100%); border-radius: 12px; border: 2px solid #f44336;">
                <div style="font-size: 64px; margin-bottom: 20px;">⚠️</div>
                <h3 style="color: #c62828; margin-bottom: 10px;">Database Error</h3>
                <p style="color: #d32f2f; margin-bottom: 10px;">Unable to fetch videos from database</p>
                <p style="color: #666; font-size: 14px; font-family: monospace; background: white; padding: 10px; border-radius: 5px;"><%= videoFetchError %></p>
                <p style="color: #999; font-size: 12px; margin-top: 10px;">Check server console logs for details</p>
            </div>
            <% } else if (uploadedVideos.isEmpty()) { %>
            <!-- No Videos Message -->
            <%
            // Check if there are pending videos for school coordinator
            int pendingCount = 0;
            if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) {
                try (Connection checkConn = DatabaseConnection.getConnection();
                     PreparedStatement checkPstmt = checkConn.prepareStatement(
                         "SELECT COUNT(*) as pending FROM student_videos WHERE udise_no = ? AND is_active = TRUE AND approval_status = 'PENDING'")) {
                    checkPstmt.setString(1, udiseNo);
                    try (ResultSet checkRs = checkPstmt.executeQuery()) {
                        if (checkRs.next()) {
                            pendingCount = checkRs.getInt("pending");
                        }
                    }
                } catch (Exception e) {
                    System.err.println("Error checking pending videos: " + e.getMessage());
                }
            }
            %>
            
            <div style="text-align: center; padding: 60px 20px; background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%); border-radius: 12px;">
                <div style="font-size: 64px; margin-bottom: 20px;">🎥</div>
                
                <% if (user.getUserType().equals(User.UserType.HEAD_MASTER)) { %>
                    <h3 style="color: #333; margin-bottom: 10px;">No Videos Uploaded Yet</h3>
                    <p style="color: #666;">अद्याप कोणतेही व्हिडिओ अपलोड केलेले नाहीत</p>
                <% } else if (pendingCount > 0) { %>
                    <h3 style="color: #ff9800; margin-bottom: 10px;">⏳ Videos Pending Approval</h3>
                    <p style="color: #666; margin-bottom: 10px;">तुम्ही <%= pendingCount %> व्हिडिओ अपलोड केले आहेत</p>
                    <p style="color: #666; margin-bottom: 15px;">You have uploaded <%= pendingCount %> video(s)</p>
                    <div style="background: #fff3e0; border: 2px solid #ff9800; border-radius: 8px; padding: 15px; margin: 20px auto; max-width: 500px;">
                        <p style="color: #e65100; font-weight: 600; margin-bottom: 10px;">📋 Waiting for Head Master Approval</p>
                        <p style="color: #666; font-size: 14px; line-height: 1.6;">
                            Your uploaded videos are pending approval from the Head Master. 
                            Once approved, they will appear here and become visible to students.
                        </p>
                        <p style="color: #999; font-size: 13px; margin-top: 10px;">
                            मुख्याध्यापकांच्या मंजुरीची प्रतीक्षा आहे
                        </p>
                    </div>
                <% } else { %>
                    <h3 style="color: #333; margin-bottom: 10px;">No Approved Videos Yet</h3>
                    <p style="color: #666;">अद्याप कोणतेही मंजूर व्हिडिओ नाहीत</p>
                    <p style="color: #999; font-size: 14px; margin-top: 15px;">Upload videos to see them here after Head Master approval</p>
                <% } %>
            </div>
            <% } else { %>
            
            <!-- Video Statistics -->
            <div style="background: linear-gradient(135deg, #ff6b35 0%, #f7931e 100%); color: white; padding: 20px; border-radius: 12px; text-align: center; margin-bottom: 30px;">
                <div style="font-size: 48px; font-weight: 700;"><%= uploadedVideos.size() %></div>
                <div style="font-size: 18px; opacity: 0.95; margin-top: 5px;">Total Videos Uploaded</div>
            </div>
            
            <!-- Videos Grid -->
            <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 20px;">
                <%
                java.text.SimpleDateFormat dateFormat = new java.text.SimpleDateFormat("dd MMM yyyy, hh:mm a");
                for (Map<String, Object> video : uploadedVideos) {
                    int videoId = (Integer) video.get("videoId");
                    String studentName = (String) video.get("studentName");
                    String subject = (String) video.get("subject");
                    String month = (String) video.get("month");
                    String hasProgress = (String) video.get("hasProgress");
                    String cdnUrl = (String) video.get("filePath");
                    long fileSize = (Long) video.get("fileSize");
                    String uploadDate = dateFormat.format((java.util.Date) video.get("uploadDate"));
                    String approvalStatus = (String) video.get("approvalStatus");
                    
                    double fileSizeMB = fileSize / (1024.0 * 1024.0);
                    String progressBadge = "yes".equals(hasProgress) ? "✅ Progress" : "⏳ No Progress";
                    String progressColor = "yes".equals(hasProgress) ? "#4caf50" : "#ff9800";
                    
                    // Approval status badge
                    String approvalBadge = "";
                    String approvalBgColor = "";
                    if ("APPROVED".equals(approvalStatus)) {
                        approvalBadge = "✅ Approved";
                        approvalBgColor = "#4caf50";
                    } else if ("REJECTED".equals(approvalStatus)) {
                        approvalBadge = "❌ Rejected";
                        approvalBgColor = "#f44336";
                    } else {
                        approvalBadge = "⏳ Pending";
                        approvalBgColor = "#ff9800";
                    }
                %>
                
                <!-- Video Card -->
                <div style="background: white; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); overflow: hidden; transition: transform 0.3s;"
                     onmouseover="this.style.transform='translateY(-5px)'; this.style.boxShadow='0 8px 25px rgba(0,0,0,0.15)'"
                     onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 4px 15px rgba(0,0,0,0.1)'">
                    
                    <!-- Thumbnail -->
                    <div style="background: linear-gradient(135deg, #ff6b35 0%, #f7931e 100%); height: 180px; display: flex; align-items: center; justify-content: center; position: relative;">
                        <div style="font-size: 64px; color: white;">🎥</div>
                        
                        <!-- Progress Badge -->
                        <div style="position: absolute; top: 10px; right: 10px; background: <%= progressColor %>; color: white; padding: 5px 12px; border-radius: 20px; font-size: 12px; font-weight: 600;">
                            <%= progressBadge %>
                        </div>
                        
                        <!-- Approval Status Badge -->
                        <% if (user.getUserType().equals(User.UserType.HEAD_MASTER)) { %>
                        <div style="position: absolute; top: 10px; left: 10px; background: <%= approvalBgColor %>; color: white; padding: 5px 12px; border-radius: 20px; font-size: 12px; font-weight: 600;">
                            <%= approvalBadge %>
                        </div>
                        <% } %>
                    </div>
                    
                    <!-- Video Info -->
                    <div style="padding: 20px;">
                        <h3 style="margin: 0 0 10px 0; font-size: 18px; color: #333;"><%= studentName %></h3>
                        
                        <div style="margin-bottom: 15px;">
                            <div style="color: #666; font-size: 14px; margin-bottom: 5px;">
                                📖 <strong><%= subject %></strong>
                            </div>
                            <div style="color: #666; font-size: 14px; margin-bottom: 5px;">
                                📅 <%= month %>
                            </div>
                            <div style="color: #999; font-size: 13px; margin-bottom: 5px;">
                                📦 <%= String.format("%.2f MB", fileSizeMB) %>
                            </div>
                            <div style="color: #999; font-size: 12px;">
                                ⏰ <%= uploadDate %>
                            </div>
                        </div>
                        
                        <!-- Watch Video Button -->
                        <button onclick="window.open('<%= cdnUrl %>', '_blank')"
                                style="width: 100%; background: linear-gradient(135deg, #ff6b35 0%, #f7931e 100%); color: white; border: none; padding: 12px; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; transition: all 0.3s; margin-bottom: 10px;"
                                onmouseover="this.style.transform='scale(1.05)'"
                                onmouseout="this.style.transform='scale(1)'">
                            ▶️ Watch Video
                        </button>
                        
                        <!-- Approval Buttons (Headmaster Only) -->
                        <% if (user.getUserType().equals(User.UserType.HEAD_MASTER) && "PENDING".equals(approvalStatus)) { %>
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
                            <button onclick="approveSchoolVideo(<%= videoId %>)"
                                    style="background: #4caf50; color: white; border: none; padding: 10px; border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.3s;"
                                    onmouseover="this.style.background='#45a049'"
                                    onmouseout="this.style.background='#4caf50'">
                                ✅ Approve
                            </button>
                            <button onclick="rejectSchoolVideo(<%= videoId %>)"
                                    style="background: #f44336; color: white; border: none; padding: 10px; border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.3s;"
                                    onmouseover="this.style.background='#da190b'"
                                    onmouseout="this.style.background='#f44336'">
                                ❌ Reject
                            </button>
                        </div>
                        <% } %>
                    </div>
                </div>
                <% } %>
            </div>
            <% } %>
            
            <div id="noVideosMessage" style="display: none; text-align: center; padding: 40px; background: #f5f5f5; border-radius: 12px; margin-top: 20px;">
                <div style="font-size: 48px; margin-bottom: 15px;">🔍</div>
                <h3 style="color: #666;">No videos found matching your filters</h3>
                <p style="color: #999;">Try adjusting your search criteria</p>
            </div>
                </div>
            </div>
        </div>
        
        <script>
        // Debug: Log information about uploaded videos modal rendering
        (function() {
            console.log('=== UPLOADED VIDEOS MODAL DEBUG (Server-side rendering) ===');
            console.log('Video count from server: <%= uploadedVideos.size() %>');
            console.log('User type: <%= user.getUserType() %>');
            console.log('UDISE Number: <%= udiseNo %>');
            console.log('Modal element exists:', document.getElementById('uploadedVideosModal') !== null);
            
            const modal = document.getElementById('uploadedVideosModal');
            if (modal) {
                const modalBody = modal.querySelector('.modal-body');
                if (modalBody) {
                    const videoGrid = modalBody.querySelector('[style*="grid-template-columns"]');
                    console.log('Video grid found:', videoGrid !== null);
                    if (videoGrid) {
                        console.log('Video grid children count:', videoGrid.children.length);
                    }
                }
            }
            console.log('===================================');
        })();
        </script>
        
        <!-- Video Player Modal -->
        <div id="videoPlayerModal" style="display: none; position: fixed; z-index: 10000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.9);">
            <div style="position: relative; margin: 3% auto; max-width: 900px;">
                <div style="background: #1a1a1a; border-radius: 12px; overflow: hidden;">
                    <!-- Modal Header -->
                    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <h2 id="videoPlayerTitle" style="margin: 0; font-size: 20px;"></h2>
                            <p id="videoPlayerSubtitle" style="margin: 5px 0 0 0; font-size: 14px; opacity: 0.9;"></p>
                        </div>
                        <button onclick="closeVideoPlayer()" 
                                style="background: rgba(255,255,255,0.2); border: none; color: white; font-size: 32px; cursor: pointer; width: 40px; height: 40px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                            ×
                        </button>
                    </div>
                    
                    <!-- Video Player -->
                    <div style="background: #000; padding: 0;">
                        <video id="videoPlayer"
                               controls
                               controlsList="nodownload"
                               crossorigin="anonymous"
                               preload="metadata"
                               style="width: 100%; height: auto; max-height: 70vh; display: block;">
                            Your browser does not support HTML5 video.
                        </video>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Add Teacher Modal -->
        <div id="addTeacherModal" class="modal">
            <div class="modal-content" style="max-width: 700px;">
                <div class="modal-header">
                    <h2>👨‍🏫 Add Teacher / शिक्षक जोडा</h2>
                    <span class="close" onclick="closeAddTeacherModal()">&times;</span>
                </div>
                <div class="modal-body">
                    <form id="addTeacherForm" onsubmit="submitTeacher(event)">
                        <div style="display: grid; gap: 20px;">
                            <!-- Teacher Name -->
                            <div>
                                <label style="display: block; font-weight: 600; margin-bottom: 8px; color: #333;">
                                    Teacher Name / शिक्षकाचे नाव <span style="color: red;">*</span>
                                </label>
                                <input type="text" id="teacherName" name="teacherName" required
                                       style="width: 100%; padding: 12px; border: 2px solid #e0e0e0; border-radius: 8px; font-size: 14px;"
                                       placeholder="Enter teacher's full name">
                            </div>
                            
                            <!-- Mobile Number -->
                            <div>
                                <label style="display: block; font-weight: 600; margin-bottom: 8px; color: #333;">
                                    Mobile Number / मोबाईल नंबर <span style="color: red;">*</span>
                                </label>
                                <input type="tel" id="teacherMobile" name="teacherMobile" required
                                       pattern="[0-9]{10}" maxlength="10"
                                       style="width: 100%; padding: 12px; border: 2px solid #e0e0e0; border-radius: 8px; font-size: 14px;"
                                       placeholder="10-digit mobile number">
                            </div>
                            
                            <!-- Subjects -->
                            <div>
                                <label style="display: block; font-weight: 600; margin-bottom: 12px; color: #333;">
                                    Subjects Taught / विषय <span style="color: red;">*</span>
                                </label>
                                
                                <!-- Subject Checkboxes -->
                                <div style="max-height: 400px; overflow-y: auto; padding: 15px; background: #f9f9f9; border-radius: 8px; border: 2px solid #e0e0e0;">
                                    <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 12px;">
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="मराठी" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">मराठी</span>
                                        </label>
                                        
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="इंग्रजी" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">इंग्रजी</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="हिंदी" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">हिंदी</span>
                                        </label>
                                        
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="गणित" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">गणित</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="परिसर अभ्यास /विज्ञान (भाग १ व २)" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">परिसर अभ्यास /विज्ञान (भाग १ व २)</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="इतिहास /नागरिकशास्त्र" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">इतिहास /नागरिकशास्त्र</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="भूगोल" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">भूगोल</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="जलसुरक्षा" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">जलसुरक्षा</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="संरक्षण शास्त्र" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">संरक्षण शास्त्र</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="शारीरिक शिक्षण" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">शारीरिक शिक्षण</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="कला शिक्षण" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">कला शिक्षण</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="कार्यअनुभव" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">कार्यअनुभव</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="भौतिकशास्त्र (Physics)" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">भौतिकशास्त्र (Physics)</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="रसायनशास्त्र (Chemistry)" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">रसायनशास्त्र (Chemistry)</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="जीवशास्त्र (Biology)" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">जीवशास्त्र (Biology)</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="राज्यशास्त्र" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">राज्यशास्त्र</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="अर्थशास्त्र" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">अर्थशास्त्र</span>
                                        </label>
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="समाजशास्त्र" class="subject-checkbox"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">समाजशास्त्र</span>
                                        </label>
                                       
                                        <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 8px; border-radius: 6px; transition: background 0.2s;" onmouseover="this.style.background='#fff'" onmouseout="this.style.background='transparent'">
                                            <input type="checkbox" name="subjects" value="इतर (Other)" class="subject-checkbox" id="otherSubjectCheckbox" onchange="toggleOtherSubjectInput()"
                                                   style="width: 18px; height: 18px; cursor: pointer; accent-color: #667eea;">
                                            <span style="font-size: 14px;">इतर (Other)</span>
                                        </label>
                                    </div>
                                </div>
                                
                                <!-- Other Subject Input Field (Hidden by default) -->
                                <div id="otherSubjectInputContainer" style="display: none; margin-top: 15px; padding: 15px; background: #fff3cd; border: 2px solid #ffc107; border-radius: 8px;">
                                    <label style="display: block; font-weight: 600; margin-bottom: 8px; color: #856404;">
                                        📝 Enter Other Subject Name / इतर विषयाचे नाव लिहा <span style="color: red;">*</span>
                                    </label>
                                    <input type="text" id="otherSubjectName" name="otherSubjectName"
                                           style="width: 100%; padding: 12px; border: 2px solid #ffc107; border-radius: 8px; font-size: 14px; background: white;"
                                           placeholder="Enter custom subject name / विषयाचे नाव लिहा">
                                    <small style="display: block; margin-top: 5px; color: #856404; font-size: 12px;">
                                        💡 This field is required when "Other Subject" is selected
                                    </small>
                                </div>
                                
                                <span id="subjectError" style="color: red; font-size: 12px; display: none; margin-top: 5px;">कृपया किमान एक विषय निवडा / Please select at least one subject</span>
                            </div>
                            
                            <!-- Description -->
                            <div>
                                <label style="display: block; font-weight: 600; margin-bottom: 8px; color: #333;">
                                    Description / वर्णन
                                </label>
                                <textarea id="teacherDescription" name="teacherDescription" rows="4"
                                          style="width: 100%; padding: 12px; border: 2px solid #e0e0e0; border-radius: 8px; font-size: 14px; resize: vertical;"
                                          placeholder="Additional information about the teacher (qualifications, experience, etc.)"></textarea>
                            </div>
                            
                            <!-- Buttons -->
                            <div style="display: flex; gap: 15px; justify-content: flex-end; margin-top: 10px;">
                                <button type="button" onclick="closeAddTeacherModal()"
                                        style="padding: 12px 30px; border: 2px solid #e0e0e0; background: white; color: #666; border-radius: 8px; font-weight: 600; cursor: pointer; transition: all 0.3s;">
                                    Cancel
                                </button>
                                <button type="submit"
                                        style="padding: 12px 30px; border: none; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 8px; font-weight: 600; cursor: pointer; transition: all 0.3s;">
                                    👨‍🏫 Add Teacher
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
        
        <!-- Test button for debugging -->
        
        <script>
            // Prepare student data for each phase
            <% 
            // Phase 1 Students
            List<Student> phase1List = phaseCompletedStudents.get(1);
            %>
        window.phase1Students = [
            <% 
            for (int i = 0; i < phase1List.size(); i++) {
                Student s = phase1List.get(i);
                if (i > 0) out.print(",");
            %>
            {
                pen: '<%= s.getStudentPen() != null ? s.getStudentPen() : "N/A" %>',
                name: '<%= s.getFullName().replace("'", "\\'") %>',
                class: '<%= s.getStudentClass() %>',
                section: '<%= s.getSection() %>',
                gender: '<%= s.getGender() %>',
                marathiLevel: <%= s.getPhase1Marathi() != null ? s.getPhase1Marathi() : 0 %>,
                mathLevel: <%= s.getPhase1Math() != null ? s.getPhase1Math() : 0 %>,
                englishLevel: <%= s.getPhase1English() != null ? s.getPhase1English() : 0 %>,
                phaseDate: '<%= s.getPhase1Date() != null ? new java.text.SimpleDateFormat("dd/MM/yyyy").format(s.getPhase1Date()) : "" %>'
            }
            <% } %>
        ];
        
        <% 
        // Phase 2 Students
        List<Student> phase2List = phaseCompletedStudents.get(2);
        %>
        window.phase2Students = [
            <% 
            for (int i = 0; i < phase2List.size(); i++) {
                Student s = phase2List.get(i);
                if (i > 0) out.print(",");
            %>
            {
                pen: '<%= s.getStudentPen() != null ? s.getStudentPen() : "N/A" %>',
                name: '<%= s.getFullName().replace("'", "\\'") %>',
                class: '<%= s.getStudentClass() %>',
                section: '<%= s.getSection() %>',
                gender: '<%= s.getGender() %>',
                marathiLevel: <%= s.getPhase2Marathi() != null ? s.getPhase2Marathi() : 0 %>,
                mathLevel: <%= s.getPhase2Math() != null ? s.getPhase2Math() : 0 %>,
                englishLevel: <%= s.getPhase2English() != null ? s.getPhase2English() : 0 %>,
                phaseDate: '<%= s.getPhase2Date() != null ? new java.text.SimpleDateFormat("dd/MM/yyyy").format(s.getPhase2Date()) : "" %>'
            }
            <% } %>
        ];
        
        <% 
        // Phase 3 Students
        List<Student> phase3List = phaseCompletedStudents.get(3);
        %>
        window.phase3Students = [
            <% 
            for (int i = 0; i < phase3List.size(); i++) {
                Student s = phase3List.get(i);
                if (i > 0) out.print(",");
            %>
            {
                pen: '<%= s.getStudentPen() != null ? s.getStudentPen() : "N/A" %>',
                name: '<%= s.getFullName().replace("'", "\\'") %>',
                class: '<%= s.getStudentClass() %>',
                section: '<%= s.getSection() %>',
                gender: '<%= s.getGender() %>',
                marathiLevel: <%= s.getPhase3Marathi() != null ? s.getPhase3Marathi() : 0 %>,
                mathLevel: <%= s.getPhase3Math() != null ? s.getPhase3Math() : 0 %>,
                englishLevel: <%= s.getPhase3English() != null ? s.getPhase3English() : 0 %>,
                phaseDate: '<%= s.getPhase3Date() != null ? new java.text.SimpleDateFormat("dd/MM/yyyy").format(s.getPhase3Date()) : "" %>'
            }
            <% } %>
        ];
        
        <% 
        // Phase 4 Students
        List<Student> phase4List = phaseCompletedStudents.get(4);
        %>
        window.phase4Students = [
            <% 
            for (int i = 0; i < phase4List.size(); i++) {
                Student s = phase4List.get(i);
                if (i > 0) out.print(",");
            %>
            {
                pen: '<%= s.getStudentPen() != null ? s.getStudentPen() : "N/A" %>',
                name: '<%= s.getFullName().replace("'", "\\'") %>',
                class: '<%= s.getStudentClass() %>',
                section: '<%= s.getSection() %>',
                gender: '<%= s.getGender() %>',
                marathiLevel: <%= s.getPhase4Marathi() != null ? s.getPhase4Marathi() : 0 %>,
                mathLevel: <%= s.getPhase4Math() != null ? s.getPhase4Math() : 0 %>,
                englishLevel: <%= s.getPhase4English() != null ? s.getPhase4English() : 0 %>,
                phaseDate: '<%= s.getPhase4Date() != null ? new java.text.SimpleDateFormat("dd/MM/yyyy").format(s.getPhase4Date()) : "" %>'
            }
            <% } %>
        ];
        </script>
        
        <!-- VIDEO UPLOAD MODAL -->
        <div id="videoUploadModal" style="display: none; position: fixed; z-index: 9999; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.5);">
            <div style="background-color: #fefefe; margin: 2% auto; padding: 0; border: 1px solid #888; border-radius: 12px; width: 90%; max-width: 1200px; box-shadow: 0 10px 40px rgba(0,0,0,0.3); max-height: 90vh; overflow-y: auto;">
                <!-- Modal Header -->
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 25px 30px; border-radius: 12px 12px 0 0; display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <h2 style="margin: 0; font-size: 28px; display: flex; align-items: center; gap: 12px;">
                            <span>🎥</span>
                            <span>Video Upload - व्हिडिओ अपलोड</span>
                        </h2>
                        <p style="margin: 8px 0 0 0; opacity: 0.95; font-size: 14px;">विद्यार्थ्याची प्रगती व्हिडिओ अपलोड करा</p>
                    </div>
                    <button onclick="closeVideoUploadModal()" style="background: rgba(255,255,255,0.2); border: none; color: white; font-size: 28px; cursor: pointer; width: 40px; height: 40px; border-radius: 50%; display: flex; align-items: center; justify-content: center; transition: all 0.3s;">×</button>
                </div>
                
                <!-- Modal Body -->
                <div style="padding: 30px;">
                    <!-- Step 1: Student Selection -->
                    <div id="videoStep1" style="display: block;">
                        <div style="background: #e3f2fd; border-left: 4px solid #2196F3; padding: 15px; margin-bottom: 25px; border-radius: 8px;">
                            <p style="margin: 0; color: #1565c0; font-weight: 600;">📋 Step 1: Select Student - विद्यार्थी निवडा</p>
                        </div>
                        
                        <!-- Search and Filter -->
                        <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 15px; margin-bottom: 20px;">
                            <div>
                                <label style="display: block; margin-bottom: 8px; font-weight: 600; color: #333;">🔍 Search by Name / PEN</label>
                                <input type="text" id="videoStudentSearch" placeholder="विद्यार्थ्याचे नाव किंवा PEN" 
                                       onkeyup="filterVideoStudents()"
                                       style="width: 100%; padding: 12px; border: 2px solid #ddd; border-radius: 8px; font-size: 14px;">
                            </div>
                            <div>
                                <label style="display: block; margin-bottom: 8px; font-weight: 600; color: #333;">📚 Filter by Class</label>
                                <select id="videoClassFilter" onchange="filterVideoStudents()" 
                                        style="width: 100%; padding: 12px; border: 2px solid #ddd; border-radius: 8px; font-size: 14px;">
                                    <option value="">All Classes - सर्व वर्ग</option>
                                    <% 
                                    Set<String> uniqueClasses = new TreeSet<>();
                                    for (com.vjnt.model.Student s : allStudents) {
                                        if (s.getStudentClass() != null && !s.getStudentClass().isEmpty()) {
                                            uniqueClasses.add(s.getStudentClass());
                                        }
                                    }
                                    for (String cls : uniqueClasses) { %>
                                        <option value="<%= cls %>"><%= cls %></option>
                                    <% } %>
                                </select>
                            </div>
                            <div>
                                <label style="display: block; margin-bottom: 8px; font-weight: 600; color: #333;">📋 Filter by Section</label>
                                <select id="videoSectionFilter" onchange="filterVideoStudents()" 
                                        style="width: 100%; padding: 12px; border: 2px solid #ddd; border-radius: 8px; font-size: 14px;">
                                    <option value="">All Sections - सर्व विभाग</option>
                                    <% 
                                    Set<String> uniqueSections = new TreeSet<>();
                                    for (com.vjnt.model.Student s : allStudents) {
                                        if (s.getSection() != null && !s.getSection().isEmpty()) {
                                            uniqueSections.add(s.getSection());
                                        }
                                    }
                                    for (String sec : uniqueSections) { %>
                                        <option value="<%= sec %>"><%= sec %></option>
                                    <% } %>
                                </select>
                            </div>
                        </div>
                        
                        <!-- Students List -->
                        <div style="max-height: 400px; overflow-y: auto; border: 2px solid #ddd; border-radius: 8px;">
                            <table id="videoStudentsTable" style="width: 100%; border-collapse: collapse;">
                                <thead style="background: #f5f5f5; position: sticky; top: 0;">
                                    <tr>
                                        <th style="padding: 12px; text-align: left; border-bottom: 2px solid #ddd;">Select</th>
                                        <th style="padding: 12px; text-align: left; border-bottom: 2px solid #ddd;">Student Name</th>
                                        <th style="padding: 12px; text-align: left; border-bottom: 2px solid #ddd;">PEN</th>
                                        <th style="padding: 12px; text-align: center; border-bottom: 2px solid #ddd;">Class</th>
                                        <th style="padding: 12px; text-align: center; border-bottom: 2px solid #ddd;">Section</th>
                                        <th style="padding: 12px; text-align: center; border-bottom: 2px solid #ddd;">Gender</th>
                                    </tr>
                                </thead>
                                <tbody id="videoStudentsBody">
                                    <% 
                                    for (com.vjnt.model.Student s : allStudents) {
                                        // Calculate current star (highest level across subjects)
                                        int currentStar = Math.max(s.getMarathiAksharaLevel(), 
                                                          Math.max(s.getMathAksharaLevel(), s.getEnglishAksharaLevel()));
                                    %>
                                    <tr class="video-student-row" 
                                        data-name="<%= s.getStudentName() %>" 
                                        data-pen="<%= s.getStudentPen() %>"
                                        data-class="<%= s.getStudentClass() %>"
                                        data-section="<%= s.getSection() %>"
                                        data-student-id="<%= s.getStudentId() %>"
                                        style="cursor: pointer; transition: background 0.3s;"
                                        onmouseover="this.style.background='#f0f8ff'"
                                        onmouseout="this.style.background='white'">
                                        <td style="padding: 12px; border-bottom: 1px solid #eee;">
                                            <input type="radio" name="selectedVideoStudent" 
                                                   value="<%= s.getStudentId() %>"
                                                   data-name="<%= s.getStudentName() %>"
                                                   data-pen="<%= s.getStudentPen() %>"
                                                   onclick="selectVideoStudent(this)">
                                        </td>
                                        <td style="padding: 12px; border-bottom: 1px solid #eee; font-weight: 600;"><%= s.getStudentName() %></td>
                                        <td style="padding: 12px; border-bottom: 1px solid #eee; font-family: monospace;"><%= s.getStudentPen() %></td>
                                        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;"><%= s.getStudentClass() %></td>
                                        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;"><%= s.getSection() %></td>
                                        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;"><%= s.getGender() %></td>
                                        
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                        
                        <div style="margin-top: 20px; text-align: right;">
                            <button onclick="proceedToVideoUpload()" 
                                    style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; padding: 12px 30px; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer;">
                                Next - पुढे जा →
                            </button>
                        </div>
                    </div>
                    
                    <!-- Step 2: Video Upload Form -->
                    <div id="videoStep2" style="display: none;">
                        <div style="background: #e8f5e9; border-left: 4px solid #4caf50; padding: 15px; margin-bottom: 25px; border-radius: 8px;">
                            <p style="margin: 0; color: #2e7d32; font-weight: 600;">📤 Step 2: Upload Video Details - व्हिडिओ तपशील भरा</p>
                        </div>
                        
                        <form id="videoUploadForm" enctype="multipart/form-data">
                            <!-- Student Info Display -->
                            <div style="background: #f5f5f5; padding: 20px; border-radius: 8px; margin-bottom: 25px;">
                                <h3 style="margin: 0 0 15px 0; color: #333;">Selected Student Information</h3>
                                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                                    <div>
                                        <label style="font-weight: 600; color: #666;">Student Name:</label>
                                        <p id="selectedStudentName" style="margin: 5px 0 0 0; font-size: 18px; color: #333;"></p>
                                    </div>
                                    <div>
                                        <label style="font-weight: 600; color: #666;">Student PEN:</label>
                                        <p id="selectedStudentPEN" style="margin: 5px 0 0 0; font-size: 18px; color: #333; font-family: monospace;"></p>
                                    </div>
                                    <div>
                                        <label style="font-weight: 600; color: #666;">Current Star Level:</label>
                                        <p id="selectedStudentStar" style="margin: 5px 0 0 0; font-size: 18px; color: #333;"></p>
                                    </div>
                                </div>
                                <input type="hidden" id="videoStudentId" name="studentId">
                            </div>
                            
                            <!-- Video Upload Details -->
                            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 25px;">
                                <div>
                                    <label style="display: block; margin-bottom: 8px; font-weight: 600; color: #333;">
                                        Select Subject - विषय निवडा <span style="color: red;">*</span>
                                    </label>
                                    <select name="subject" required
                                            style="width: 100%; padding: 12px; border: 2px solid #ddd; border-radius: 8px; font-size: 14px;">
                                        <option value="">-- Select Subject --</option>
                                        <option value="Marathi">मराठी (Marathi)</option>
                                        <option value="Math">गणित (Math)</option>
                                        <option value="English">इंग्रजी (English)</option>
                                    </select>
                                </div>
                                
                                <div>
                                    <label style="display: block; margin-bottom: 8px; font-weight: 600; color: #333;">
                                        Select Month - महिना निवडा <span style="color: red;">*</span>
                                    </label>
                                    <select name="month" required
                                            style="width: 100%; padding: 12px; border: 2px solid #ddd; border-radius: 8px; font-size: 14px;">
                                        <option value="">-- Select Month --</option>
                                        <option value="January">जानेवारी (January)</option>
                                        <option value="February">फेब्रुवारी (February)</option>
                                        <option value="March">मार्च (March)</option>
                                        <option value="April">एप्रिल (April)</option>
                                        <option value="May">मे (May)</option>
                                        <option value="June">जून (June)</option>
                                        <option value="July">जुलै (July)</option>
                                        <option value="August">ऑगस्ट (August)</option>
                                        <option value="September">सप्टेंबर (September)</option>
                                        <option value="October">ऑक्टोबर (October)</option>
                                        <option value="November">नोव्हेंबर (November)</option>
                                        <option value="December">डिसेंबर (December)</option>
                                    </select>
                                </div>
                            </div>
                            
                            <!-- Progress Question -->
                            <div style="margin-bottom: 25px;">
                                <label style="display: block; margin-bottom: 12px; font-weight: 600; color: #333; font-size: 16px;">
                                    विद्यार्थ्याची प्रगती झाली आहे का? (Has the student made progress?) <span style="color: red;">*</span>
                                </label>
                                <div style="display: flex; gap: 30px;">
                                    <label style="display: flex; align-items: center; gap: 10px; cursor: pointer; padding: 12px 20px; border: 2px solid #ddd; border-radius: 8px; transition: all 0.3s;">
                                        <input type="radio" name="hasProgress" value="no" required 
                                               onchange="this.parentElement.style.borderColor='#f44336'; this.parentElement.style.background='#ffebee';">
                                        <span style="font-size: 16px;">❌ नाही (No)</span>
                                    </label>
                                    <label style="display: flex; align-items: center; gap: 10px; cursor: pointer; padding: 12px 20px; border: 2px solid #ddd; border-radius: 8px; transition: all 0.3s;">
                                        <input type="radio" name="hasProgress" value="yes" required
                                               onchange="this.parentElement.style.borderColor='#4caf50'; this.parentElement.style.background='#e8f5e9';">
                                        <span style="font-size: 16px;">✅ होय (Yes)</span>
                                    </label>
                                </div>
                            </div>
                            
                            <!-- Video Upload Section -->
                            <div style="border: 2px dashed #667eea; border-radius: 8px; padding: 30px; text-align: center; background: #f8f9ff; margin-bottom: 25px;">
                                <div style="font-size: 48px; margin-bottom: 15px;">🎥</div>
                                <label style="display: block; margin-bottom: 12px; font-weight: 600; color: #333; font-size: 16px;">
                                    Upload Video - व्हिडिओ अपलोड करा <span style="color: red;">*</span>
                                </label>
                                <input type="file" name="videoFile" accept="video/*" required
                                       onchange="displayVideoFileName(this)"
                                       style="display: block; margin: 15px auto; padding: 12px; border: 2px solid #ddd; border-radius: 8px; background: white; max-width: 400px;">
                                <p id="videoFileName" style="margin-top: 10px; color: #4caf50; font-weight: 600;"></p>
                                <p style="color: #666; font-size: 14px; margin-top: 10px;">
                                    Supported formats: MP4, AVI, MOV, MKV (Min 100 KB and Max size: 15 MB)
                                </p>
                            </div>
                            
                            <!-- Action Buttons -->
                            <div style="display: flex; gap: 15px; justify-content: flex-end;">
                                <button type="button" onclick="backToStudentSelection()" 
                                        style="background: #e0e0e0; color: #333; border: none; padding: 12px 30px; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; transition: all 0.3s;">
                                    ← Back - मागे जा
                                </button>
                                <button type="submit" 
                                        style="background: linear-gradient(135deg, #4caf50 0%, #45a049 100%); color: white; border: none; padding: 12px 30px; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; transition: all 0.3s;">
                                    🎥 Upload Video - व्हिडिओ अपलोड करा
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- VIDEO UPLOAD JAVASCRIPT -->
        <script>
        // Scroll to section function
        function scrollToSection(sectionId) {
            const section = document.getElementById(sectionId);
            if (section) {
                section.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }
        
        // Open Video Upload Modal (already defined at page start)
        // Keeping this comment for reference - function defined at line ~1755
        
        // Close Video Upload Modal (already defined at page start)
        // Keeping this comment for reference - function defined at line ~1770
        
        // Video functions already defined at page start (line ~1750+)
        // - filterVideoStudents()
        // - selectVideoStudent()
        // - proceedToVideoUpload()
        // - backToStudentSelection()
        // - displayVideoFileName()
        
        // Handle video upload form submission
        document.getElementById('videoUploadForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            console.log('=== VIDEO UPLOAD STARTED ===');
            console.log('Timestamp:', new Date().toISOString());
            
            const formData = new FormData(this);
            const submitButton = this.querySelector('button[type="submit"]');
            
            // Log form data being sent
            console.log('Form Data Contents:');
            for (let pair of formData.entries()) {
                if (pair[0] === 'videoFile') {
                    const file = pair[1];
                    console.log('  ' + pair[0] + ': ' + file.name + ' (' + (file.size / (1024*1024)).toFixed(2) + ' MB, ' + file.type + ')');
                } else {
                    console.log('  ' + pair[0] + ': ' + pair[1]);
                }
            }
            
            // Disable submit button
            submitButton.disabled = true;
            submitButton.textContent = '⏳ Uploading... कृपया प्रतीक्षा करा...';
            
            console.log('Sending request to: <%= request.getContextPath() %>/upload-student-video');
            const uploadStartTime = Date.now();
            
            // Submit to backend
            fetch('<%= request.getContextPath() %>/upload-student-video', {
                method: 'POST',
                body: formData
            })
            .then(response => {
                const uploadDuration = ((Date.now() - uploadStartTime) / 1000).toFixed(2);
                console.log('Response received after ' + uploadDuration + 's');
                console.log('Response status:', response.status);
                console.log('Response headers:', Object.fromEntries([...response.headers]));
                return response.json();
            })
            .then(data => {
                console.log('Response data:', data);
                console.log('=== VIDEO UPLOAD COMPLETED ===');
                
                if (data.success) {
                    console.log('✅ Upload successful!');
                    console.log('YouTube Video ID:', data.youtubeId);
                    console.log('YouTube URL:', data.youtubeUrl);
                    alert('✅ Video uploaded to YouTube successfully!\nव्हिडिओ यशस्वीरित्या YouTube वर अपलोड केला!\n\nStudent: ' + selectedVideoStudentData.name + '\nYouTube URL: ' + data.youtubeUrl);
                    closeVideoUploadModal();
                    location.reload(); // Refresh to show updated data
                } else {
                    console.error('❌ Upload failed!');
                    console.error('Error message:', data.message);
                    console.error('Auth expired:', data.authExpired);
                    console.error('Auth required:', data.authRequired);
                    
                    // Check if authorization is needed
                    if (data.authExpired || data.authRequired) {
                        const authUrl = data.authUrl || '<%= request.getContextPath() %>/authorize-youtube';
                        
                        if (confirm('❌ YouTube Authorization Needed!\n\n' + data.message + 
                                   '\n\nClick OK to open the authorization page.\n\nयूट्यूब प्राधिकरण आवश्यक आहे!')) {
                            window.open(authUrl, '_blank');
                        }
                    } else {
                        alert('❌ Error uploading video!\n' + (data.message || 'Unknown error') + 
                             '\n\nकृपया पुन्हा प्रयत्न करा!');
                    }
                    submitButton.disabled = false;
                    submitButton.textContent = '🎥 Upload Video - व्हिडिओ अपलोड करा';
                }
            })
            .catch(error => {
                const uploadDuration = ((Date.now() - uploadStartTime) / 1000).toFixed(2);
                console.error('=== VIDEO UPLOAD FAILED after ' + uploadDuration + 's ===');
                console.error('Error type:', error.name);
                console.error('Error message:', error.message);
                console.error('Full error:', error);
                alert('❌ Error uploading video!\nकृपया पुन्हा प्रयत्न करा!\n\n' + error.message);
                submitButton.disabled = false;
                submitButton.textContent = '🎥 Upload Video - व्हिडिओ अपलोड करा';
            });
        });
        
        // Close modal when clicking outside
        document.getElementById('videoUploadModal').addEventListener('click', function(e) {
            if (e.target === this) {
                closeVideoUploadModal();
            }
        });
        </script>
        
    <!-- Phase Details Modal -->
    <div id="phaseModal" class="modal" style="display: none;">
        <div class="modal-content" style="max-width: 1200px; max-height: 90vh; overflow-y: auto;">
            <div class="modal-header">
                <h2 id="modalPhaseTitle">Phase Student Data</h2>
                <button class="modal-close" onclick="closePhaseModal()">&times;</button>
            </div>
            <div class="modal-body">
                <div id="modalStudentList"></div>
            </div>
        </div>
    </div>
    
    <style>
        /* Phase Modal Styles */
        #phaseModal.modal {
            display: none;
            position: fixed;
            z-index: 10000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.6);
            animation: fadeIn 0.3s ease;
        }
        
        #phaseModal.show {
            display: flex !important;
            align-items: center;
            justify-content: center;
        }
        
        #phaseModal .modal-content {
            background: white;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
            animation: slideDown 0.3s ease;
            margin: 20px;
        }
        
        #phaseModal .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px 30px;
            border-bottom: 2px solid #f0f0f0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 12px 12px 0 0;
        }
        
        #phaseModal .modal-header h2 {
            margin: 0;
            font-size: 1.5rem;
            font-weight: 700;
        }
        
        #phaseModal .modal-close {
            background: rgba(255, 255, 255, 0.2);
            border: none;
            color: white;
            font-size: 32px;
            font-weight: 300;
            cursor: pointer;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s;
            line-height: 1;
        }
        
        #phaseModal .modal-close:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: rotate(90deg);
        }
        
        #phaseModal .modal-body {
            padding: 30px;
        }
        
        .modal-summary {
            display: flex;
            gap: 20px;
            margin-bottom: 25px;
            flex-wrap: wrap;
        }
        
        .summary-item {
            flex: 1;
            min-width: 150px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
        }
        
        .summary-value {
            font-size: 2.5rem;
            font-weight: 800;
            margin-bottom: 5px;
        }
        
        .summary-label {
            font-size: 0.9rem;
            opacity: 0.9;
            font-weight: 500;
        }
        
        .modal-controls {
            margin-bottom: 20px;
        }
        
        .search-box input {
            width: 100%;
            padding: 12px 20px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .search-box input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
    </style>
    
    <script>
        // Close Phase Modal Function
        function closePhaseModal() {
            const modal = document.getElementById('phaseModal');
            if (modal) {
                modal.classList.remove('show');
                modal.style.display = 'none';
            }
        }
        
        // Close modal when clicking outside the content
        document.addEventListener('click', function(e) {
            const modal = document.getElementById('phaseModal');
            if (modal && e.target === modal) {
                closePhaseModal();
            }
        });
        
        // Close modal with Escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                closePhaseModal();
            }
        });
    </script>
        
</body>
</html>
