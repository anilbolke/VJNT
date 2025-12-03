package com.vjnt.dao;

import com.vjnt.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * VideoAssignment Data Access Object
 * Handles assignment of videos to schools and students
 */
public class VideoAssignmentDAO {
    
    /**
     * Assign video to a school (by UDISE number)
     */
    public boolean assignVideoToSchool(int videoId, String udiseNo, int assignedBy, String notes) {
        String sql = "INSERT INTO video_assignments (video_id, udise_no, assigned_by, notes) VALUES (?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, videoId);
            pstmt.setString(2, udiseNo);
            pstmt.setInt(3, assignedBy);
            pstmt.setString(4, notes);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error assigning video to school: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Assign video to a student (by student ID and PEN)
     */
    public boolean assignVideoToStudent(int videoId, int studentId, String studentPen, int assignedBy, String notes) {
        String sql = "INSERT INTO video_assignments (video_id, student_id, student_pen, assigned_by, notes) VALUES (?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, videoId);
            pstmt.setInt(2, studentId);
            pstmt.setString(3, studentPen);
            pstmt.setInt(4, assignedBy);
            pstmt.setString(5, notes);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error assigning video to student: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Get all videos assigned to a school
     */
    public List<Map<String, Object>> getVideosForSchool(String udiseNo) {
        List<Map<String, Object>> videos = new ArrayList<>();
        String sql = "SELECT v.*, va.assigned_date, va.notes FROM videos v " +
                    "JOIN video_assignments va ON v.video_id = va.video_id " +
                    "WHERE va.udise_no = ? AND v.status = 'active' " +
                    "ORDER BY va.assigned_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> video = new HashMap<>();
                video.put("videoId", rs.getInt("video_id"));
                video.put("title", rs.getString("title"));
                video.put("description", rs.getString("description"));
                video.put("youtubeVideoId", rs.getString("youtube_video_id"));
                video.put("youtubeUrl", rs.getString("youtube_url"));
                video.put("thumbnailUrl", rs.getString("thumbnail_url"));
                video.put("category", rs.getString("category"));
                video.put("subCategory", rs.getString("sub_category"));
                video.put("viewCount", rs.getInt("view_count"));
                video.put("assignedDate", rs.getTimestamp("assigned_date"));
                video.put("notes", rs.getString("notes"));
                videos.add(video);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting videos for school: " + e.getMessage());
            e.printStackTrace();
        }
        return videos;
    }
    
    /**
     * Get all videos assigned to a student
     */
    public List<Map<String, Object>> getVideosForStudent(int studentId) {
        List<Map<String, Object>> videos = new ArrayList<>();
        String sql = "SELECT v.*, va.assigned_date, va.notes FROM videos v " +
                    "JOIN video_assignments va ON v.video_id = va.video_id " +
                    "WHERE va.student_id = ? AND v.status = 'active' " +
                    "ORDER BY va.assigned_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, studentId);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> video = new HashMap<>();
                video.put("videoId", rs.getInt("video_id"));
                video.put("title", rs.getString("title"));
                video.put("description", rs.getString("description"));
                video.put("youtubeVideoId", rs.getString("youtube_video_id"));
                video.put("youtubeUrl", rs.getString("youtube_url"));
                video.put("thumbnailUrl", rs.getString("thumbnail_url"));
                video.put("category", rs.getString("category"));
                video.put("subCategory", rs.getString("sub_category"));
                video.put("viewCount", rs.getInt("view_count"));
                video.put("assignedDate", rs.getTimestamp("assigned_date"));
                video.put("notes", rs.getString("notes"));
                videos.add(video);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting videos for student: " + e.getMessage());
            e.printStackTrace();
        }
        return videos;
    }
    
    /**
     * Get all videos assigned to a student by PEN
     */
    public List<Map<String, Object>> getVideosForStudentByPen(String studentPen) {
        List<Map<String, Object>> videos = new ArrayList<>();
        String sql = "SELECT v.*, va.assigned_date, va.notes FROM videos v " +
                    "JOIN video_assignments va ON v.video_id = va.video_id " +
                    "WHERE va.student_pen = ? AND v.status = 'active' " +
                    "ORDER BY va.assigned_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, studentPen);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> video = new HashMap<>();
                video.put("videoId", rs.getInt("video_id"));
                video.put("title", rs.getString("title"));
                video.put("description", rs.getString("description"));
                video.put("youtubeVideoId", rs.getString("youtube_video_id"));
                video.put("youtubeUrl", rs.getString("youtube_url"));
                video.put("thumbnailUrl", rs.getString("thumbnail_url"));
                video.put("category", rs.getString("category"));
                video.put("subCategory", rs.getString("sub_category"));
                video.put("viewCount", rs.getInt("view_count"));
                video.put("assignedDate", rs.getTimestamp("assigned_date"));
                video.put("notes", rs.getString("notes"));
                videos.add(video);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting videos for student by PEN: " + e.getMessage());
            e.printStackTrace();
        }
        return videos;
    }
    
    /**
     * Remove video assignment
     */
    public boolean removeAssignment(int assignmentId) {
        String sql = "DELETE FROM video_assignments WHERE assignment_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, assignmentId);
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error removing assignment: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Check if video is already assigned to school
     */
    public boolean isVideoAssignedToSchool(int videoId, String udiseNo) {
        String sql = "SELECT COUNT(*) FROM video_assignments WHERE video_id = ? AND udise_no = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, videoId);
            pstmt.setString(2, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking video assignment: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Check if video is already assigned to student
     */
    public boolean isVideoAssignedToStudent(int videoId, int studentId) {
        String sql = "SELECT COUNT(*) FROM video_assignments WHERE video_id = ? AND student_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, videoId);
            pstmt.setInt(2, studentId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking video assignment: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
}
