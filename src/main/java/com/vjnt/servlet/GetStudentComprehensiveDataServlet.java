package com.vjnt.servlet;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.google.gson.Gson;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.dao.PalakMelavaDAO;
import com.vjnt.model.PalakMelava;

@WebServlet("/GetStudentComprehensiveDataServlet")
public class GetStudentComprehensiveDataServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        String penNumber = request.getParameter("penNumber");
        
        if (penNumber == null || penNumber.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "PEN number is required");
            return;
        }
        
        Map<String, Object> comprehensiveData = new HashMap<>();
        
        System.out.println("=== GetStudentComprehensiveDataServlet called for PEN: " + penNumber + " ===");
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get student's UDISE number, class, and section
            Map<String, String> studentInfo = getStudentInfo(conn, penNumber);
            String udiseNo = studentInfo.get("udise_no");
            String studentClass = studentInfo.get("class");
            String section = studentInfo.get("section");
            
            System.out.println("Student Info - UDISE: " + udiseNo + ", Class: " + studentClass + ", Section: " + section);
            
            // Get Assessment Levels from student_weekly_activities
            comprehensiveData.put("assessmentLevels", getAssessmentLevelsFromActivities(conn, penNumber));
            
            // Get ALL Activities for the student
            comprehensiveData.put("allActivities", getAllStudentActivities(conn, penNumber));
            
            // Get subject teachers for this student's class/section
            if (udiseNo != null && studentClass != null && section != null) {
                Map<String, String> teachers = getSubjectTeachers(conn, udiseNo, studentClass, section);
                comprehensiveData.put("subjectTeachers", teachers);
                System.out.println("Adding subjectTeachers to response: " + teachers);
            } else {
                System.out.println("WARNING: Cannot fetch teachers - UDISE, class, or section is null!");
            }
            
            // Get Palak Melava (Parent Meetings) data
            if (udiseNo != null) {
                comprehensiveData.put("palakMelavaData", getPalakMelavaData(udiseNo));
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Error fetching comprehensive data");
            return;
        }
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(new Gson().toJson(comprehensiveData));
    }
    
    // Get assessment levels from student record
    private Map<String, String> getAssessmentLevelsFromActivities(Connection conn, String penNumber) throws SQLException {
        Map<String, String> levels = new HashMap<>();
        
        // Get student's level values from students table
        String sql = "SELECT marathi_akshara_level, math_akshara_level, english_akshara_level " +
                    "FROM students WHERE student_pen = ?";
        
        int marathiLevel = 0;
        int mathLevel = 0;
        int englishLevel = 0;
        
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, penNumber);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                marathiLevel = rs.getInt("marathi_akshara_level");
                mathLevel = rs.getInt("math_akshara_level");
                englishLevel = rs.getInt("english_akshara_level");
            }
        }
        
        // Convert level numbers to actual level descriptions
        levels.put("marathi", getMarathiLevelText(marathiLevel));
        levels.put("math", getMathLevelText(mathLevel));
        levels.put("english", getEnglishLevelText(englishLevel));
        
        // Calculate overall progress based on how many subjects are assessed
        int assessedCount = 0;
        if (marathiLevel > 0) assessedCount++;
        if (mathLevel > 0) assessedCount++;
        if (englishLevel > 0) assessedCount++;
        
        String overall = assessedCount == 3 ? "All Subjects Assessed" :
                        assessedCount == 2 ? "2 of 3 Assessed" :
                        assessedCount == 1 ? "1 of 3 Assessed" : "Not Yet Assessed";
        levels.put("overall", overall);
        
        return levels;
    }
    
    // Get Marathi level text based on level number
    private String getMarathiLevelText(int level) {
        switch (level) {
            case 1: return "अक्षर स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)";
            case 2: return "शब्द स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)";
            case 3: return "वाक्य स्तरावरील विद्यार्थी संख्या";
            case 4: return "समजपुर्वक उतार वाचन स्तरावरील विद्यार्थी संख्या";
            case 5: return "वाचन–लेखन FLN स्तर 100%पूर्ण.";
            default: return "स्तर निश्चित केला नाही";
        }
    }
    
    // Get Math level text based on level number
    private String getMathLevelText(int level) {
        switch (level) {
            case 1: return "प्रारंभीक स्तरावरील विद्यार्थी संख्या";
            case 2: return "अंक स्तरावरील विद्यार्थी संख्या";
            case 3: return "संख्या वाचन स्तरावरील विद्यार्थी संख्या";
            case 4: return "बेरीज स्तरावरील विद्यार्थी संख्या";
            case 5: return "वजाबाकी स्तरावरील विद्यार्थी संख्या";
            case 6: return "गुणाकार स्तरावरील विद्यार्थी संख्या";
            case 7: return "भागाकर स्तरावरील विद्यार्थी संख्या";
            case 8: return "संख्या व मूलभूत क्रिया FLN स्तर 100%पूर्ण.";
            default: return "स्तर निश्चित केला नाही";
        }
    }
    
    // Get English level text based on level number
    private String getEnglishLevelText(int level) {
        switch (level) {
            case 1: return "BEGINER LEVEL";
            case 2: return "ALPHABET LEVEL Reading and Writing";
            case 3: return "WORD LEVEL Reading and Writing";
            case 4: return "SENTENCE LEVEL";
            case 5: return "Paragraph Reading with Understanding";
            case 6: return "Reading and Writing FLN Level 100% Complete.";
            default: return "स्तर निश्चित केला नाही";
        }
    }
    
    // Get all activities for the student from student_weekly_activities table
    private List<Map<String, Object>> getAllStudentActivities(Connection conn, String penNumber) throws SQLException {
        List<Map<String, Object>> activities = new ArrayList<>();
        
        String sql = "SELECT language, week_number, day_number, activity_text, activity_identifier, " +
                    "activity_count, completed, assigned_by, assigned_date " +
                    "FROM student_weekly_activities " +
                    "WHERE student_pen = ? " +
                    "ORDER BY language, week_number, day_number";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, penNumber);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> activity = new HashMap<>();
                activity.put("language", rs.getString("language"));
                activity.put("weekNumber", rs.getInt("week_number"));
                activity.put("dayNumber", rs.getInt("day_number"));
                activity.put("activityText", rs.getString("activity_text"));
                activity.put("activityIdentifier", rs.getString("activity_identifier"));
                activity.put("activityCount", rs.getInt("activity_count"));
                activity.put("completed", rs.getBoolean("completed"));
                activity.put("assignedBy", rs.getString("assigned_by"));
                activity.put("assignedDate", rs.getTimestamp("assigned_date") != null ? 
                           rs.getTimestamp("assigned_date").toString() : null);
                activities.add(activity);
            }
        }
        
        return activities;
    }
    
    // Get student's UDISE number, class, and section
    private Map<String, String> getStudentInfo(Connection conn, String penNumber) throws SQLException {
        Map<String, String> info = new HashMap<>();
        String sql = "SELECT udise_no, class, section FROM students WHERE student_pen = ?";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, penNumber);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                info.put("udise_no", rs.getString("udise_no"));
                info.put("class", rs.getString("class"));
                info.put("section", rs.getString("section"));
            }
        }
        return info;
    }
    
    // Get Palak Melava data for the school
    private List<Map<String, Object>> getPalakMelavaData(String udiseNo) {
        List<Map<String, Object>> palakMelavaList = new ArrayList<>();
        PalakMelavaDAO palakMelavaDAO = new PalakMelavaDAO();
        
        // Get approved palak melava records
        List<PalakMelava> records = palakMelavaDAO.getByUdise(udiseNo);
        
        for (PalakMelava melava : records) {
            // Only include approved records
            if ("APPROVED".equals(melava.getStatus())) {
                Map<String, Object> data = new HashMap<>();
                data.put("melavaId", melava.getMelavaId());
                data.put("meetingDate", melava.getMeetingDate() != null ? melava.getMeetingDate().toString() : null);
                data.put("chiefAttendeeInfo", melava.getChiefAttendeeInfo());
                data.put("totalParentsAttended", melava.getTotalParentsAttended());
                
                palakMelavaList.add(data);
            }
        }
        
        return palakMelavaList;
    }
    
    // Get subject teachers for a specific class and section
    private Map<String, String> getSubjectTeachers(Connection conn, String udiseCode, String studentClass, String section) {
        Map<String, String> subjectTeachers = new HashMap<>();
        
        System.out.println("=== DEBUG: getSubjectTeachers called ===");
        System.out.println("UDISE: " + udiseCode);
        System.out.println("Class: " + studentClass);
        System.out.println("Section: " + section);
        
        if (udiseCode == null || studentClass == null || section == null) {
            System.out.println("ERROR: One or more parameters is null!");
            return subjectTeachers;
        }
        
        String sql = "SELECT teacher_name, subjects_assigned FROM teacher_assignments " +
                     "WHERE udise_code = ? AND class = ? AND section = ? AND is_active = 1";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, udiseCode);
            stmt.setString(2, studentClass);
            stmt.setString(3, section);
            
            System.out.println("Executing query: " + sql);
            ResultSet rs = stmt.executeQuery();
            
            int rowCount = 0;
            while (rs.next()) {
                rowCount++;
                String teacherName = rs.getString("teacher_name");
                String subjects = rs.getString("subjects_assigned");
                
                System.out.println("Found teacher: " + teacherName + ", Subjects: " + subjects);
                
                if (teacherName != null && subjects != null) {
                    // subjects_assigned is a comma-separated list like "Marathi,Math,English"
                    String[] subjectArray = subjects.split(",");
                    for (String subject : subjectArray) {
                        subject = subject.trim();
                        if (!subject.isEmpty()) {
                            // Store the teacher name for each subject
                            subjectTeachers.put(subject, teacherName);
                            System.out.println("Mapped: " + subject + " -> " + teacherName);
                        }
                    }
                }
            }
            
            System.out.println("Total teachers found: " + rowCount);
            System.out.println("Final subjectTeachers map: " + subjectTeachers);
            
        } catch (SQLException e) {
            System.out.println("SQL ERROR: " + e.getMessage());
            e.printStackTrace();
        }
        
        return subjectTeachers;
    }
}
