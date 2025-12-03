package com.vjnt.dao;

import com.vjnt.model.Student;
import com.vjnt.model.StudentWeeklyActivity;
import com.vjnt.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class StudentWeeklyActivityDAO {
    
    /**
     * Assign activity to a student. If the same activity exists for the same week/day, increment count
     */
    public boolean assignActivityToStudent(StudentWeeklyActivity activity) {
        // First check if this exact activity already exists for this student
        StudentWeeklyActivity existingActivity = getExistingActivity(
            activity.getStudentId(), 
            activity.getLanguage(), 
            activity.getWeekNumber(), 
            activity.getDayNumber(), 
            activity.getActivityText()
        );
        
        if (existingActivity != null) {
            // Increment count
            return incrementActivityCount(existingActivity.getId());
        } else {
            // Create new activity
            return createActivity(activity);
        }
    }
    
    /**
     * Get existing activity for student using activity_identifier
     * This is more reliable than comparing full activity text
     */
    private StudentWeeklyActivity getExistingActivity(int studentId, String language, int weekNumber, int dayNumber, String activityText) {
        // Generate identifier from mandatory fields
        String activityIdentifier = String.format("%d_%s_%d_%d", studentId, language, weekNumber, dayNumber);
        
        String sql = "SELECT * FROM student_weekly_activities WHERE activity_identifier = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, activityIdentifier);
            
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToActivity(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return null;
    }
    
    /**
     * Increment activity count
     */
    private boolean incrementActivityCount(int activityId) {
        String sql = "UPDATE student_weekly_activities SET activity_count = activity_count + 1, updated_at = NOW() WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, activityId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Create new activity record
     */
    private boolean createActivity(StudentWeeklyActivity activity) {
        // Generate activity identifier before saving
        activity.setActivityIdentifierFromFields();
        
        String sql = "INSERT INTO student_weekly_activities (student_id, student_pen, udise_no, student_class, section, student_name, language, week_number, day_number, activity_text, activity_identifier, activity_count, assigned_by, assigned_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            stmt.setInt(1, activity.getStudentId());
            stmt.setString(2, activity.getStudentPen());
            stmt.setString(3, activity.getUdiseNo());
            stmt.setString(4, activity.getStudentClass());
            stmt.setString(5, activity.getSection());
            stmt.setString(6, activity.getStudentName());
            stmt.setString(7, activity.getLanguage());
            stmt.setInt(8, activity.getWeekNumber());
            stmt.setInt(9, activity.getDayNumber());
            stmt.setString(10, activity.getActivityText());
            stmt.setString(11, activity.getActivityIdentifier());
            stmt.setInt(12, activity.getActivityCount());
            stmt.setString(13, activity.getAssignedBy());
            
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
    
    /**
     * Get all activities for a student
     */
    public List<StudentWeeklyActivity> getActivitiesForStudent(int studentId) {
        List<StudentWeeklyActivity> activities = new ArrayList<>();
        String sql = "SELECT * FROM student_weekly_activities WHERE student_id = ? ORDER BY language, week_number, day_number";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, studentId);
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
     * Get activities for student by language and week
     */
    public List<StudentWeeklyActivity> getActivitiesForStudentByWeek(int studentId, String language, int weekNumber) {
        List<StudentWeeklyActivity> activities = new ArrayList<>();
        String sql = "SELECT * FROM student_weekly_activities WHERE student_id = ? AND language = ? AND week_number = ? ORDER BY day_number";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, studentId);
            stmt.setString(2, language);
            stmt.setInt(3, weekNumber);
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
     * Mark activity as completed
     */
    public boolean markActivityComplete(int activityId) {
        String sql = "UPDATE student_weekly_activities SET completed = true, completed_date = NOW(), updated_at = NOW() WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, activityId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Mark activity as incomplete
     */
    public boolean markActivityIncomplete(int activityId) {
        String sql = "UPDATE student_weekly_activities SET completed = false, completed_date = NULL, updated_at = NOW() WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, activityId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Delete an activity
     */
    public boolean deleteActivity(int activityId) {
        String sql = "DELETE FROM student_weekly_activities WHERE id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, activityId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Get students by class and section
     */
    public List<Student> getStudentsByClassSection(String udiseNo, String studentClass, String section) {
        List<Student> students = new ArrayList<>();
        String sql = "SELECT * FROM students WHERE udise_no = ? AND class = ? AND section = ? ORDER BY student_name";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseNo);
            stmt.setString(2, studentClass);
            stmt.setString(3, section);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                students.add(mapResultSetToStudent(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return students;
    }
    
    /**
     * Map ResultSet to StudentWeeklyActivity
     */
    private StudentWeeklyActivity mapResultSetToActivity(ResultSet rs) throws SQLException {
        StudentWeeklyActivity activity = new StudentWeeklyActivity();
        activity.setId(rs.getInt("id"));
        activity.setStudentId(rs.getInt("student_id"));
        activity.setStudentPen(rs.getString("student_pen"));
        activity.setUdiseNo(rs.getString("udise_no"));
        activity.setStudentClass(rs.getString("student_class"));
        activity.setSection(rs.getString("section"));
        activity.setStudentName(rs.getString("student_name"));
        activity.setLanguage(rs.getString("language"));
        activity.setWeekNumber(rs.getInt("week_number"));
        activity.setDayNumber(rs.getInt("day_number"));
        activity.setActivityText(rs.getString("activity_text"));
        activity.setActivityIdentifier(rs.getString("activity_identifier"));
        activity.setActivityCount(rs.getInt("activity_count"));
        activity.setCompleted(rs.getBoolean("completed"));
        activity.setCompletedDate(rs.getTimestamp("completed_date"));
        activity.setAssignedBy(rs.getString("assigned_by"));
        activity.setAssignedDate(rs.getTimestamp("assigned_date"));
        activity.setUpdatedAt(rs.getTimestamp("updated_at"));
        return activity;
    }
    
    /**
     * Map ResultSet to Student
     */
    private Student mapResultSetToStudent(ResultSet rs) throws SQLException {
        Student student = new Student();
        student.setStudentId(rs.getInt("student_id"));
        student.setDivision(rs.getString("division"));
        student.setDistrict(rs.getString("district"));
        student.setUdiseNo(rs.getString("udise_no"));
        student.setStudentClass(rs.getString("class"));
        student.setSection(rs.getString("section"));
        student.setClassCategory(rs.getString("class_category"));
        student.setStudentName(rs.getString("student_name"));
        student.setGender(rs.getString("gender"));
        student.setStudentPen(rs.getString("student_pen"));
        student.setMarathiLevel(rs.getString("marathi_level"));
        student.setMathLevel(rs.getString("math_level"));
        student.setEnglishLevel(rs.getString("english_level"));
        return student;
    }
}
