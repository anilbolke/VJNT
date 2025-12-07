package com.vjnt.dao;

import com.vjnt.model.Video;
import com.vjnt.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Video Data Access Object
 * Handles all database operations for Video entity
 */
public class VideoDAO {
    
    /**
     * Save a new video
     */
    public boolean saveVideo(Video video) {
        String sql = "INSERT INTO videos (title, description, youtube_video_id, youtube_url, " +
                    "thumbnail_url, category, sub_category, uploaded_by, uploader_name, status) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            pstmt.setString(1, video.getTitle());
            pstmt.setString(2, video.getDescription());
            pstmt.setString(3, video.getYoutubeVideoId());
            pstmt.setString(4, video.getYoutubeUrl());
            pstmt.setString(5, video.getThumbnailUrl());
            pstmt.setString(6, video.getCategory());
            pstmt.setString(7, video.getSubCategory());
            pstmt.setInt(8, video.getUploadedBy());
            pstmt.setString(9, video.getUploaderName());
            pstmt.setString(10, video.getStatus());
            
            int affected = pstmt.executeUpdate();
            
            if (affected > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    video.setVideoId(rs.getInt(1));
                }
                return true;
            }
            
        } catch (SQLException e) {
            System.err.println("Error saving video: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Get all videos
     */
    public List<Video> getAllVideos() {
        List<Video> videos = new ArrayList<>();
        String sql = "SELECT * FROM videos WHERE status = 'active' ORDER BY upload_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            while (rs.next()) {
                videos.add(extractVideoFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting all videos: " + e.getMessage());
            e.printStackTrace();
        }
        return videos;
    }
    
    /**
     * Get videos by category
     */
    public List<Video> getVideosByCategory(String category) {
        List<Video> videos = new ArrayList<>();
        String sql = "SELECT * FROM videos WHERE category = ? AND status = 'active' ORDER BY upload_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, category);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                videos.add(extractVideoFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting videos by category: " + e.getMessage());
            e.printStackTrace();
        }
        return videos;
    }
    
    /**
     * Get videos by category and sub-category
     */
    public List<Video> getVideosByCategoryAndSub(String category, String subCategory) {
        List<Video> videos = new ArrayList<>();
        String sql = "SELECT * FROM videos WHERE category = ? AND sub_category = ? AND status = 'active' ORDER BY upload_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, category);
            pstmt.setString(2, subCategory);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                videos.add(extractVideoFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting videos: " + e.getMessage());
            e.printStackTrace();
        }
        return videos;
    }
    
    /**
     * Get video by ID
     */
    public Video getVideoById(int videoId) {
        String sql = "SELECT * FROM videos WHERE video_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, videoId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return extractVideoFromResultSet(rs);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting video by ID: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    /**
     * Update video
     */
    public boolean updateVideo(Video video) {
        String sql = "UPDATE videos SET title = ?, description = ?, category = ?, " +
                    "sub_category = ?, status = ? WHERE video_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, video.getTitle());
            pstmt.setString(2, video.getDescription());
            pstmt.setString(3, video.getCategory());
            pstmt.setString(4, video.getSubCategory());
            pstmt.setString(5, video.getStatus());
            pstmt.setInt(6, video.getVideoId());
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating video: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Delete video (soft delete by setting status to inactive)
     */
    public boolean deleteVideo(int videoId) {
        String sql = "UPDATE videos SET status = 'inactive' WHERE video_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, videoId);
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error deleting video: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Increment view count
     */
    public boolean incrementViewCount(int videoId) {
        String sql = "UPDATE videos SET view_count = view_count + 1 WHERE video_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, videoId);
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error incrementing view count: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Record video view
     */
    public boolean recordVideoView(int videoId, Integer studentId, String viewerName, String ipAddress) {
        String sql = "INSERT INTO video_views (video_id, student_id, viewer_name, ip_address) VALUES (?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, videoId);
            if (studentId != null) {
                pstmt.setInt(2, studentId);
            } else {
                pstmt.setNull(2, Types.INTEGER);
            }
            pstmt.setString(3, viewerName);
            pstmt.setString(4, ipAddress);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error recording video view: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Get video count by district
     */
    public int getVideoCountByDistrict(String districtName) {
        String sql = "SELECT COUNT(DISTINCT v.video_id) as video_count " +
                    "FROM videos v " +
                    "INNER JOIN students s ON v.uploaded_by = s.student_id " +
                    "WHERE s.district = ? AND v.status = 'active'";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, districtName);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt("video_count");
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting video count by district: " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }
    
    /**
     * Get videos by district
     */
    public List<Video> getVideosByDistrict(String districtName) {
        List<Video> videos = new ArrayList<>();
        String sql = "SELECT v.* FROM videos v " +
                    "INNER JOIN students s ON v.uploaded_by = s.student_id " +
                    "WHERE s.district = ? AND v.status = 'active' " +
                    "ORDER BY v.upload_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, districtName);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                videos.add(extractVideoFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting videos by district: " + e.getMessage());
            e.printStackTrace();
        }
        return videos;
    }
    
    /**
     * Extract Video object from ResultSet
     */
    private Video extractVideoFromResultSet(ResultSet rs) throws SQLException {
        Video video = new Video();
        video.setVideoId(rs.getInt("video_id"));
        video.setTitle(rs.getString("title"));
        video.setDescription(rs.getString("description"));
        video.setYoutubeVideoId(rs.getString("youtube_video_id"));
        video.setYoutubeUrl(rs.getString("youtube_url"));
        video.setThumbnailUrl(rs.getString("thumbnail_url"));
        video.setCategory(rs.getString("category"));
        video.setSubCategory(rs.getString("sub_category"));
        video.setUploadedBy(rs.getInt("uploaded_by"));
        video.setUploaderName(rs.getString("uploader_name"));
        video.setUploadDate(rs.getTimestamp("upload_date"));
        video.setViewCount(rs.getInt("view_count"));
        video.setStatus(rs.getString("status"));
        return video;
    }
}
