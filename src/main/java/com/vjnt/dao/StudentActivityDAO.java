package com.vjnt.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import com.vjnt.model.StudentActivity;
import com.vjnt.util.DatabaseConnection;

public class StudentActivityDAO {

    /**
     * Save or update student activity
     * If same activity for same student/week/day exists, increment count
     * Otherwise create new record
     */
    public boolean saveOrUpdateStudentActivity(int studentId, String subject, int week, 
                                                int day, String activityText, String assignedBy) {
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // First, get student details
            String studentQuery = "SELECT student_pen, udise_no, class, section, student_name " +
                                 "FROM students WHERE student_id = ?";
            PreparedStatement ps = conn.prepareStatement(studentQuery);
            ps.setInt(1, studentId);
            ResultSet rs = ps.executeQuery();
            
            if (!rs.next()) {
                return false;
            }
            
            String studentPen = rs.getString("student_pen");
            String udiseNo = rs.getString("udise_no");
            String studentClass = rs.getString("class");
            String section = rs.getString("section");
            String studentName = rs.getString("student_name");
            
            // Generate activity identifier from mandatory fields
            String activityIdentifier = String.format("%d_%s_%d_%d", studentId, subject, week, day);
            
            // Check if activity already exists using activity_identifier
            String checkQuery = "SELECT id, activity_count FROM student_weekly_activities " +
                               "WHERE activity_identifier = ?";
            ps = conn.prepareStatement(checkQuery);
            ps.setString(1, activityIdentifier);
            rs = ps.executeQuery();
            
            if (rs.next()) {
                // Update existing record - increment count
                int existingId = rs.getInt("id");
                int currentCount = rs.getInt("activity_count");
                
                String updateQuery = "UPDATE student_weekly_activities " +
                                    "SET activity_count = ?, updated_at = CURRENT_TIMESTAMP " +
                                    "WHERE id = ?";
                ps = conn.prepareStatement(updateQuery);
                ps.setInt(1, currentCount + 1);
                ps.setInt(2, existingId);
                ps.executeUpdate();
                
                System.out.println("DEBUG: Updated activity count to " + (currentCount + 1) + " for identifier: " + activityIdentifier);
                
            } else {
                // Insert new record with activity_identifier
                String insertQuery = "INSERT INTO student_weekly_activities " +
                                    "(student_id, student_pen, udise_no, student_class, section, " +
                                    "student_name, language, week_number, day_number, activity_text, " +
                                    "activity_identifier, activity_count, assigned_by, assigned_date) " +
                                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)";
                ps = conn.prepareStatement(insertQuery);
                ps.setInt(1, studentId);
                ps.setString(2, studentPen);
                ps.setString(3, udiseNo);
                ps.setString(4, studentClass);
                ps.setString(5, section);
                ps.setString(6, studentName);
                ps.setString(7, subject);
                ps.setInt(8, week);
                ps.setInt(9, day);
                ps.setString(10, activityText);
                ps.setString(11, activityIdentifier);
                ps.setInt(12, 1);
                ps.setString(13, assignedBy);
                ps.executeUpdate();
                
                System.out.println("DEBUG: Inserted new activity with identifier: " + activityIdentifier);
            }
            
            return true;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Get activity count for a specific student and week
     */
    public List<Map<String, Object>> getActivityCountByWeek(int studentId, String subject, int week) {
        List<Map<String, Object>> activities = new ArrayList<>();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            String query = "SELECT day_number, activity_text, activity_count " +
                          "FROM student_weekly_activities " +
                          "WHERE student_id = ? AND language = ? AND week_number = ? " +
                          "ORDER BY day_number ASC";
            
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setInt(1, studentId);
            ps.setString(2, subject);
            ps.setInt(3, week);
            
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> activity = new HashMap<>();
                activity.put("day", rs.getInt("day_number"));
                activity.put("activity", rs.getString("activity_text"));
                activity.put("count", rs.getInt("activity_count"));
                activities.add(activity);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return activities;
    }

    /**
     * Get all activities for a student across all weeks
     */
    public List<StudentActivity> getStudentActivities(int studentId, String subject) {
        List<StudentActivity> activities = new ArrayList<>();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            String query = "SELECT * FROM student_weekly_activities " +
                          "WHERE student_id = ? AND language = ? " +
                          "ORDER BY week_number DESC, day_number ASC";
            
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setInt(1, studentId);
            ps.setString(2, subject);
            
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                StudentActivity activity = new StudentActivity();
                activity.setId(rs.getInt("id"));
                activity.setStudentId(rs.getInt("student_id"));
                activity.setLanguage(rs.getString("language"));
                activity.setWeekNumber(rs.getInt("week_number"));
                activity.setDayNumber(rs.getInt("day_number"));
                activity.setActivityText(rs.getString("activity_text"));
                activity.setActivityCount(rs.getInt("activity_count"));
                activity.setAssignedDate(rs.getTimestamp("assigned_date"));
                activity.setUpdatedAt(rs.getTimestamp("updated_at"));
                activities.add(activity);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return activities;
    }

    /**
     * Get activity summary for a student
     */
    public Map<String, Integer> getActivitySummary(int studentId, String subject, int week) {
        Map<String, Integer> summary = new HashMap<>();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            String query = "SELECT day_number, COUNT(*) as totalActivities, SUM(activity_count) as totalCount " +
                          "FROM student_weekly_activities " +
                          "WHERE student_id = ? AND language = ? AND week_number = ? " +
                          "GROUP BY day_number";
            
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setInt(1, studentId);
            ps.setString(2, subject);
            ps.setInt(3, week);
            
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                String dayKey = "day_" + rs.getInt("day_number");
                summary.put(dayKey, rs.getInt("totalCount"));
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return summary;
    }

    /**
     * Get count for a specific activity (day-wise) using activity_identifier
     * This is more reliable than comparing activity text
     */
    public int getSpecificActivityCount(int studentId, String subject, int week, int day, String activityText) {
        try (Connection conn = DatabaseConnection.getConnection()) {
            // Generate activity identifier from mandatory fields
            String activityIdentifier = String.format("%d_%s_%d_%d", studentId, subject, week, day);
            
            System.out.println("DEBUG: Looking for activity with identifier: " + activityIdentifier);
            
            // Query using activity_identifier for reliable matching
            String query = "SELECT activity_count FROM student_weekly_activities " +
                          "WHERE activity_identifier = ?";
            
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setString(1, activityIdentifier);
            
            ResultSet rs = ps.executeQuery();
            
            if (rs.next()) {
                int count = rs.getInt("activity_count");
                System.out.println("DEBUG: Found activity count = " + count);
                return count;
            }
            
            System.out.println("DEBUG: No activity found with identifier: " + activityIdentifier);
            
        } catch (SQLException e) {
            e.printStackTrace();
            System.out.println("DEBUG: SQL Error in getSpecificActivityCount: " + e.getMessage());
        }
        
        return 0;
    }

    /**
     * Get all activity counts from the table
     */
    public List<Map<String, Object>> getAllActivityCounts() {
        List<Map<String, Object>> activities = new ArrayList<>();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            String query = "SELECT student_id, language, week_number, day_number, activity_text, activity_count " +
                          "FROM student_weekly_activities " +
                          "ORDER BY student_id, language, week_number, day_number";
            
            PreparedStatement ps = conn.prepareStatement(query);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> activity = new HashMap<>();
                activity.put("studentId", rs.getInt("student_id"));
                activity.put("language", rs.getString("language"));
                activity.put("weekNumber", rs.getInt("week_number"));
                activity.put("dayNumber", rs.getInt("day_number"));
                activity.put("activityText", rs.getString("activity_text"));
                activity.put("activityCount", rs.getInt("activity_count"));
                activities.add(activity);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return activities;
    }
}