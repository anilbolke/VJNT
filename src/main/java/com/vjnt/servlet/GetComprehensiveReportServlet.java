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
import com.google.gson.Gson;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.dao.PalakMelavaDAO;
import com.vjnt.model.PalakMelava;

@WebServlet("/GetComprehensiveReportServlet")
public class GetComprehensiveReportServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String approvalIdStr = request.getParameter("approvalId");
        
        if (approvalIdStr == null || approvalIdStr.trim().isEmpty()) {
            sendError(response, "Missing approval ID");
            return;
        }
        
        int approvalId = Integer.parseInt(approvalIdStr);
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            // First, get the PEN number from report_approvals
            String penNumber = null;
            String sql = "SELECT pen_number FROM report_approvals WHERE approval_id = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, approvalId);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                penNumber = rs.getString("pen_number");
            } else {
                sendError(response, "Report not found");
                return;
            }
            
            // Now get comprehensive data for this student
            Map<String, Object> reportData = new HashMap<>();
            
            // Get student info
            sql = "SELECT student_pen, student_name, class, section FROM students WHERE student_pen = ?";
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, penNumber);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                reportData.put("penNumber", rs.getString("student_pen"));
                reportData.put("studentName", rs.getString("student_name"));
                reportData.put("studentClass", rs.getString("class"));
                reportData.put("section", rs.getString("section"));
            } else {
                sendError(response, "Student not found");
                return;
            }
            
            // Get assessment levels from students table
            Map<String, String> assessmentLevels = new HashMap<>();
            sql = "SELECT marathi_akshara_level, math_akshara_level, english_akshara_level " +
                  "FROM students WHERE student_pen = ?";
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, penNumber);
            rs = stmt.executeQuery();
            
            int marathiLevel = 0;
            int mathLevel = 0;
            int englishLevel = 0;
            
            if (rs.next()) {
                marathiLevel = rs.getInt("marathi_akshara_level");
                mathLevel = rs.getInt("math_akshara_level");
                englishLevel = rs.getInt("english_akshara_level");
            }
            
            // Convert level numbers to text
            assessmentLevels.put("marathi", getMarathiLevelText(marathiLevel));
            assessmentLevels.put("math", getMathLevelText(mathLevel));
            assessmentLevels.put("english", getEnglishLevelText(englishLevel));
            
            // Calculate overall progress
            int assessedCount = 0;
            if (marathiLevel > 0) assessedCount++;
            if (mathLevel > 0) assessedCount++;
            if (englishLevel > 0) assessedCount++;
            
            String overall = assessedCount == 3 ? "All Subjects Assessed" :
                            assessedCount == 2 ? "2 of 3 Assessed" :
                            assessedCount == 1 ? "1 of 3 Assessed" : "Not Yet Assessed";
            assessmentLevels.put("overall", overall);
            
            reportData.put("assessmentLevels", assessmentLevels);
            
            // Get all activities
            List<Map<String, Object>> activities = new ArrayList<>();
            sql = "SELECT language, week_number, day_number, activity_text, " +
                  "activity_identifier, activity_count, completed, assigned_by, assigned_date " +
                  "FROM student_weekly_activities " +
                  "WHERE student_pen = ? " +
                  "ORDER BY language, week_number, day_number";
            
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, penNumber);
            rs = stmt.executeQuery();
            
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
            
            reportData.put("allActivities", activities);
            
            // Get student's UDISE number for Palak Melava
            String udiseNo = null;
            sql = "SELECT udise_no FROM students WHERE student_pen = ?";
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, penNumber);
            rs = stmt.executeQuery();
            if (rs.next()) {
                udiseNo = rs.getString("udise_no");
            }
            
            // Get Palak Melava data using DAO
            List<Map<String, Object>> palakMelavaData = new ArrayList<>();
            if (udiseNo != null) {
                palakMelavaData = getPalakMelavaData(udiseNo);
            }
            
            reportData.put("palakMelavaData", palakMelavaData);
            
            // Send response
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write(new Gson().toJson(reportData));
            
        } catch (Exception e) {
            e.printStackTrace();
            sendError(response, "Error loading report: " + e.getMessage());
        }
    }
    
    private void sendError(HttpServletResponse response, String message) throws IOException {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(new Gson().toJson(error));
    }
    
    // Get Marathi level text based on level number
    private String getMarathiLevelText(int level) {
        switch (level) {
            case 1: return "अक्षर स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)";
            case 2: return "शब्द स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)";
            case 3: return "वाक्य स्तरावरील विद्यार्थी संख्या";
            case 4: return "समजपुर्वक उतार वाचन स्तरावरील विद्यार्थी संख्या";
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
            default: return "स्तर निश्चित केला नाही";
        }
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
