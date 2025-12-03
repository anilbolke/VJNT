package com.vjnt.servlet;

import java.io.IOException;
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
import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet("/debug-activity-count")
public class DebugActivityCountServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        try {
            String studentIdStr = request.getParameter("studentId");
            String subject = request.getParameter("subject");
            String weekStr = request.getParameter("week");
            String dayStr = request.getParameter("day");
            String activity = request.getParameter("activity");

            Map<String, Object> debugInfo = new HashMap<>();
            
            // Log input parameters
            Map<String, String> inputs = new HashMap<>();
            inputs.put("studentId", studentIdStr);
            inputs.put("subject", subject);
            inputs.put("week", weekStr);
            inputs.put("day", dayStr);
            inputs.put("activity", activity != null ? activity.substring(0, Math.min(50, activity.length())) + "..." : "null");
            debugInfo.put("inputParams", inputs);

            int studentId = Integer.parseInt(studentIdStr != null ? studentIdStr : "0");
            int week = Integer.parseInt(weekStr != null ? weekStr : "0");
            int day = Integer.parseInt(dayStr != null ? dayStr : "0");

            // Debug 1: Check total records in table
            int totalRecords = getTotalRecords();
            debugInfo.put("totalRecordsInTable", totalRecords);

            // Debug 2: Check all records (first 10)
            List<Map<String, Object>> allRecords = getAllRecords();
            debugInfo.put("allRecords", allRecords);

            // Debug 3: Try the exact query used
            int countResult = getSpecificActivityCountDebug(studentId, subject, week, day, activity);
            debugInfo.put("countResult", countResult);

            // Debug 4: Check for records with matching studentId and language
            List<Map<String, Object>> matchingByStudentAndLanguage = getRecordsByStudentAndLanguage(studentId, subject);
            debugInfo.put("recordsByStudentAndLanguage", matchingByStudentAndLanguage);

            // Debug 5: Check for records matching week and day
            List<Map<String, Object>> matchingByWeekAndDay = getRecordsByWeekAndDay(week, day);
            debugInfo.put("recordsByWeekAndDay", matchingByWeekAndDay);

            Map<String, Object> responseMap = new HashMap<>();
            responseMap.put("success", true);
            responseMap.put("debug", debugInfo);
            
            Gson gson = new Gson();
            response.getWriter().write(gson.toJson(responseMap));

        } catch (Exception e) {
            e.printStackTrace();
            response.setContentType("application/json");
            response.getWriter().write("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }

    private int getTotalRecords() {
        try (Connection conn = DatabaseConnection.getConnection()) {
            String query = "SELECT COUNT(*) as total FROM student_weekly_activities";
            PreparedStatement ps = conn.prepareStatement(query);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt("total");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    private List<Map<String, Object>> getAllRecords() {
        List<Map<String, Object>> records = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection()) {
            String query = "SELECT * FROM student_weekly_activities LIMIT 10";
            PreparedStatement ps = conn.prepareStatement(query);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> record = new HashMap<>();
                record.put("id", rs.getInt("id"));
                record.put("student_id", rs.getInt("student_id"));
                record.put("language", rs.getString("language"));
                record.put("week_number", rs.getInt("week_number"));
                record.put("day_number", rs.getInt("day_number"));
                record.put("activity_text", rs.getString("activity_text"));
                record.put("activity_count", rs.getInt("activity_count"));
                records.add(record);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return records;
    }

    private int getSpecificActivityCountDebug(int studentId, String subject, int week, int day, String activity) {
        try (Connection conn = DatabaseConnection.getConnection()) {
            // Use activity_identifier for reliable matching
            String activityIdentifier = String.format("%d_%s_%d_%d", studentId, subject, week, day);
            
            String query = "SELECT activity_count FROM student_weekly_activities " +
                          "WHERE activity_identifier = ?";
            
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setString(1, activityIdentifier);
            
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt("activity_count");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    private List<Map<String, Object>> getRecordsByStudentAndLanguage(int studentId, String subject) {
        List<Map<String, Object>> records = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection()) {
            String query = "SELECT * FROM student_weekly_activities WHERE student_id = ? AND language = ?";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setInt(1, studentId);
            ps.setString(2, subject);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> record = new HashMap<>();
                record.put("id", rs.getInt("id"));
                record.put("student_id", rs.getInt("student_id"));
                record.put("language", rs.getString("language"));
                record.put("week_number", rs.getInt("week_number"));
                record.put("day_number", rs.getInt("day_number"));
                record.put("activity_text", rs.getString("activity_text"));
                record.put("activity_count", rs.getInt("activity_count"));
                records.add(record);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return records;
    }

    private List<Map<String, Object>> getRecordsByWeekAndDay(int week, int day) {
        List<Map<String, Object>> records = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection()) {
            String query = "SELECT * FROM student_weekly_activities WHERE week_number = ? AND day_number = ?";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setInt(1, week);
            ps.setInt(2, day);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> record = new HashMap<>();
                record.put("id", rs.getInt("id"));
                record.put("student_id", rs.getInt("student_id"));
                record.put("language", rs.getString("language"));
                record.put("week_number", rs.getInt("week_number"));
                record.put("day_number", rs.getInt("day_number"));
                record.put("activity_text", rs.getString("activity_text"));
                record.put("activity_count", rs.getInt("activity_count"));
                records.add(record);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return records;
    }
}
