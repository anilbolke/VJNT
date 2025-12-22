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
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get student's UDISE number
            String udiseNo = getStudentUdiseNo(conn, penNumber);
            
            // Get Assessment Levels from student_weekly_activities
            comprehensiveData.put("assessmentLevels", getAssessmentLevelsFromActivities(conn, penNumber));
            
            // Get ALL Activities for the student
            comprehensiveData.put("allActivities", getAllStudentActivities(conn, penNumber));
            
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
        case 0: return "स्तर निश्चित केला नाही";
    	case 1: return "प्रारंभिक स्तर";
        case 2: return "अक्षर स्तर";
        case 3: return "शब्द स्तर";
        case 4: return "वाक्य स्तर";
        case 5: return "समजपूर्वक उतारा वाचन स्तर";
        case 6: return "मराठी वाचन व लेखन FLN स्तर 100% पूर्ण";
        default: return "स्तर निश्चित केला नाही";
        }
    }
    
    // Get Math level text based on level number
    private String getMathLevelText(int level) {
        switch (level) {
        case 0: return "स्तर निश्चित केला नाही";
        case 1: return "प्रारंभिक स्तर";
        case 2: return "अंक ज्ञान स्तर";
        case 3: return "संख्याज्ञान स्तर";
        case 4: return "बेरीज स्तर";
        case 5: return "वजाबाकी स्तर";
        case 6: return "गुणाकार स्तर";
        case 7: return "भागाकार स्तर";
        case 8: return "गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण";
        default: return "स्तर निश्चित केला नाही";
        }
    }
    
    // Get English level text based on level number
    private String getEnglishLevelText(int level) {
        switch (level) {
        case 0: return "स्तर निश्चित केला नाही";
        case 1: return "Beginner level";
        case 2: return "Alphabet level";
        case 3: return "Word level";
        case 4: return "Sentence level";
        case 5: return "Paragraph Reading with Understanding";
        case 6: return "English reading and writing FLN level 100% complete";
        default: return "स्तर निश्चित केला नाही";
        }
    }
    
    // Get all activities for the student from student_weekly_activities table
    private List<Map<String, Object>> getAllStudentActivities(Connection conn, String penNumber) throws SQLException {
        List<Map<String, Object>> activities = new ArrayList<>();
        
        // Join with teacher_assignments table to get teacher's name based on school, class, section, and subject
        // Use COLLATE to fix collation mismatch between tables
        String sql = "SELECT swa.language, swa.week_number, swa.day_number, swa.activity_text, " +
                    "swa.activity_identifier, swa.activity_count, swa.completed, swa.assigned_by, " +
                    "swa.assigned_date, ta.teacher_name " +
                    "FROM student_weekly_activities swa " +
                    "LEFT JOIN teacher_assignments ta ON swa.udise_no COLLATE utf8mb4_0900_ai_ci = ta.udise_code COLLATE utf8mb4_0900_ai_ci " +
                    "    AND swa.student_class COLLATE utf8mb4_0900_ai_ci = ta.class COLLATE utf8mb4_0900_ai_ci " +
                    "    AND swa.section COLLATE utf8mb4_0900_ai_ci = ta.section COLLATE utf8mb4_0900_ai_ci " +
                    "    AND ta.is_active = 1 " +
                    "    AND FIND_IN_SET(swa.language COLLATE utf8mb4_0900_ai_ci, ta.subjects_assigned COLLATE utf8mb4_0900_ai_ci) > 0 " +
                    "WHERE swa.student_pen = ? " +
                    "ORDER BY swa.language, swa.week_number, swa.day_number";
        
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
                
                // Use teacher's name from teacher_assignments table if available
                String teacherName = rs.getString("teacher_name");
                String assignedBy = rs.getString("assigned_by");
                
                // Priority: teacher_name from teacher_assignments, then assigned_by username
                activity.put("assignedBy", teacherName != null ? teacherName : (assignedBy != null ? assignedBy : "Not Assigned"));
                
                activity.put("assignedDate", rs.getTimestamp("assigned_date") != null ? 
                           rs.getTimestamp("assigned_date").toString() : null);
                activities.add(activity);
            }
        }
        
        return activities;
    }
    
    // Get student's UDISE number
    private String getStudentUdiseNo(Connection conn, String penNumber) throws SQLException {
        String sql = "SELECT udise_no FROM students WHERE student_pen = ? AND is_active = 1";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, penNumber);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getString("udise_no");
            }
        }
        return null;
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
}
