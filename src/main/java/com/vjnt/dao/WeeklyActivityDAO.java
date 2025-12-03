package com.vjnt.dao;

import com.vjnt.model.WeeklyActivity;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.util.PDFDataExtractor;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class WeeklyActivityDAO {
    
    public List<WeeklyActivity> getActivitiesByClassSection(String udiseNo, String studentClass, String section, int weekNumber) {
        List<WeeklyActivity> activities = new ArrayList<>();
        String sql = "SELECT * FROM weekly_activities WHERE udise_no = ? AND student_class = ? AND section = ? AND week_number = ? ORDER BY FIELD(subject, 'Marathi', 'English', 'Math'), FIELD(day, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseNo);
            stmt.setString(2, studentClass);
            stmt.setString(3, section);
            stmt.setInt(4, weekNumber);
            
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                activities.add(mapResultSetToActivity(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return activities;
    }
    
    public boolean markActivityComplete(int activityId, String completedBy) {
        String sql = "UPDATE weekly_activities SET completed = true, completed_date = NOW(), completed_by = ?, updated_at = NOW() WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, completedBy);
            stmt.setInt(2, activityId);
            
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean markActivityIncomplete(int activityId) {
        String sql = "UPDATE weekly_activities SET completed = false, completed_date = NULL, completed_by = NULL, updated_at = NOW() WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, activityId);
            
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean createActivity(WeeklyActivity activity) {
        String sql = "INSERT INTO weekly_activities (udise_no, student_class, section, subject, week_number, day, activity, completed, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, false, NOW(), NOW())";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            stmt.setString(1, activity.getUdiseNo());
            stmt.setString(2, activity.getStudentClass());
            stmt.setString(3, activity.getSection());
            stmt.setString(4, activity.getSubject());
            stmt.setInt(5, activity.getWeekNumber());
            stmt.setString(6, activity.getDay());
            stmt.setString(7, activity.getActivity());
            
            int rowsAffected = stmt.executeUpdate();
            
            if (rowsAffected > 0) {
                ResultSet rs = stmt.getGeneratedKeys();
                if (rs.next()) {
                    activity.setId(rs.getInt(1));
                }
                return true;
            }
            return false;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean updateActivity(int activityId, String newActivity) {
        String sql = "UPDATE weekly_activities SET activity = ?, updated_at = NOW() WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, newActivity);
            stmt.setInt(2, activityId);
            
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public List<String> getAvailableClasses(String udiseNo) {
        List<String> classes = new ArrayList<>();
        String sql = "SELECT DISTINCT class FROM students WHERE udise_no = ? ORDER BY CAST(class AS UNSIGNED)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseNo);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                classes.add(rs.getString("class"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return classes;
    }
    
    public List<String> getAvailableSections(String udiseNo, String studentClass) {
        List<String> sections = new ArrayList<>();
        String sql = "SELECT DISTINCT section FROM students WHERE udise_no = ? AND class = ? ORDER BY section";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseNo);
            stmt.setString(2, studentClass);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                sections.add(rs.getString("section"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return sections;
    }
    
    public int getCompletedActivitiesCount(String udiseNo, String studentClass, String section, int weekNumber) {
        String sql = "SELECT COUNT(*) as count FROM weekly_activities WHERE udise_no = ? AND student_class = ? AND section = ? AND week_number = ? AND completed = true";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseNo);
            stmt.setString(2, studentClass);
            stmt.setString(3, section);
            stmt.setInt(4, weekNumber);
            
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("count");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return 0;
    }
    
    private WeeklyActivity mapResultSetToActivity(ResultSet rs) throws SQLException {
        WeeklyActivity activity = new WeeklyActivity();
        activity.setId(rs.getInt("id"));
        activity.setUdiseNo(rs.getString("udise_no"));
        activity.setStudentClass(rs.getString("student_class"));
        activity.setSection(rs.getString("section"));
        activity.setSubject(rs.getString("subject"));
        activity.setWeekNumber(rs.getInt("week_number"));
        activity.setDay(rs.getString("day"));
        activity.setActivity(rs.getString("activity"));
        activity.setCompleted(rs.getBoolean("completed"));
        activity.setCompletedDate(rs.getTimestamp("completed_date"));
        activity.setCompletedBy(rs.getString("completed_by"));
        activity.setCreatedAt(rs.getTimestamp("created_at"));
        activity.setUpdatedAt(rs.getTimestamp("updated_at"));
        return activity;
    }
    
    /**
     * Load PDF data for a specific language and populate activities
     * @param udiseNo - School's UDISE number
     * @param studentClass - Student class
     * @param section - Section
     * @param language - Language/Subject (Marathi, English, Math)
     * @return List of activities populated from PDF data
     */
    public List<WeeklyActivity> loadActivitiesFromPDF(String udiseNo, String studentClass, String section, String language) {
        List<WeeklyActivity> activities = new ArrayList<>();
        
        try {
            // Extract data from PDF using PDFDataExtractor
            Map<Integer, Map<String, String>> weeklyData = PDFDataExtractor.generateSampleData(language);
            
            // Process each week
            for (Map.Entry<Integer, Map<String, String>> weekEntry : weeklyData.entrySet()) {
                int weekNumber = weekEntry.getKey();
                Map<String, String> dayActivities = weekEntry.getValue();
                
                // Process each day
                for (Map.Entry<String, String> dayEntry : dayActivities.entrySet()) {
                    String day = dayEntry.getKey();
                    String activityDescription = dayEntry.getValue();
                    
                    // Check if activity already exists
                    if (!activityExists(udiseNo, studentClass, section, language, weekNumber, day)) {
                        // Create new activity
                        WeeklyActivity activity = new WeeklyActivity(
                            udiseNo,
                            studentClass,
                            section,
                            language,
                            weekNumber,
                            day,
                            activityDescription
                        );
                        
                        if (createActivity(activity)) {
                            activities.add(activity);
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        return activities;
    }
    
    /**
     * Check if an activity already exists
     */
    private boolean activityExists(String udiseNo, String studentClass, String section, String subject, int weekNumber, String day) {
        String sql = "SELECT COUNT(*) as count FROM weekly_activities WHERE udise_no = ? AND student_class = ? AND section = ? AND subject = ? AND week_number = ? AND day = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseNo);
            stmt.setString(2, studentClass);
            stmt.setString(3, section);
            stmt.setString(4, subject);
            stmt.setInt(5, weekNumber);
            stmt.setString(6, day);
            
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("count") > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Get activities filtered by language/subject
     */
    public List<WeeklyActivity> getActivitiesByLanguage(String udiseNo, String studentClass, String section, String language, int weekNumber) {
        List<WeeklyActivity> activities = new ArrayList<>();
        String sql = "SELECT * FROM weekly_activities WHERE udise_no = ? AND student_class = ? AND section = ? AND subject = ? AND week_number = ? ORDER BY FIELD(day, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseNo);
            stmt.setString(2, studentClass);
            stmt.setString(3, section);
            stmt.setString(4, language);
            stmt.setInt(5, weekNumber);
            
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                activities.add(mapResultSetToActivity(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return activities;
    }
    
    /**
     * Get all available languages for a school
     */
    public List<String> getAvailableLanguages() {
        List<String> languages = new ArrayList<>();
        languages.add("Marathi");
        languages.add("English");
        languages.add("Math");
        return languages;
    }
    
    /**
     * Get completed activities count by language
     */
    public int getCompletedActivitiesCountByLanguage(String udiseNo, String studentClass, String section, String language, int weekNumber) {
        String sql = "SELECT COUNT(*) as count FROM weekly_activities WHERE udise_no = ? AND student_class = ? AND section = ? AND subject = ? AND week_number = ? AND completed = true";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseNo);
            stmt.setString(2, studentClass);
            stmt.setString(3, section);
            stmt.setString(4, language);
            stmt.setInt(5, weekNumber);
            
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("count");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return 0;
    }
    
    /**
     * Delete all activities for a specific class and section (for resetting)
     */
    public boolean deleteActivities(String udiseNo, String studentClass, String section, String language) {
        String sql = "DELETE FROM weekly_activities WHERE udise_no = ? AND student_class = ? AND section = ? AND subject = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseNo);
            stmt.setString(2, studentClass);
            stmt.setString(3, section);
            stmt.setString(4, language);
            
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
