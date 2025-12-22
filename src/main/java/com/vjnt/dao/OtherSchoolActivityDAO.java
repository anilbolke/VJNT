package com.vjnt.dao;

import com.vjnt.model.OtherSchoolActivity;
import com.vjnt.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class OtherSchoolActivityDAO {
    
    public boolean save(OtherSchoolActivity activity) throws SQLException {
        String sql = "INSERT INTO other_school_activities (udise_no, school_name, activity_date, " +
                     "activity_subject, guests_present, description, photo1_path, photo2_path, " +
                     "video_link, photo1_content, photo2_content, photo1_filename, photo2_filename, " +
                     "status, created_by, created_date) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            stmt.setString(1, activity.getUdiseNo());
            stmt.setString(2, activity.getSchoolName());
            stmt.setDate(3, activity.getActivityDate());
            stmt.setString(4, activity.getActivitySubject());
            stmt.setString(5, activity.getGuestsPresent());
            stmt.setString(6, activity.getDescription());
            stmt.setString(7, activity.getPhoto1Path());
            stmt.setString(8, activity.getPhoto2Path());
            stmt.setString(9, activity.getVideoLink());
            
            // Handle photo blobs
            if (activity.getPhoto1Content() != null) {
                stmt.setBytes(10, activity.getPhoto1Content());
            } else {
                stmt.setNull(10, Types.BLOB);
            }
            
            if (activity.getPhoto2Content() != null) {
                stmt.setBytes(11, activity.getPhoto2Content());
            } else {
                stmt.setNull(11, Types.BLOB);
            }
            
            stmt.setString(12, activity.getPhoto1FileName());
            stmt.setString(13, activity.getPhoto2FileName());
            stmt.setString(14, activity.getStatus());
            stmt.setString(15, activity.getCreatedBy());
            
            int result = stmt.executeUpdate();
            
            if (result > 0) {
                ResultSet rs = stmt.getGeneratedKeys();
                if (rs.next()) {
                    activity.setActivityId(rs.getInt(1));
                }
                return true;
            }
            return false;
        }
    }
    
    public boolean update(OtherSchoolActivity activity) throws SQLException {
        String sql = "UPDATE other_school_activities SET activity_date = ?, activity_subject = ?, " +
                     "guests_present = ?, description = ?, photo1_path = ?, photo2_path = ?, " +
                     "video_link = ?, photo1_content = ?, photo2_content = ?, photo1_filename = ?, " +
                     "photo2_filename = ?, status = ?, updated_by = ?, updated_date = NOW() " +
                     "WHERE activity_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setDate(1, activity.getActivityDate());
            stmt.setString(2, activity.getActivitySubject());
            stmt.setString(3, activity.getGuestsPresent());
            stmt.setString(4, activity.getDescription());
            stmt.setString(5, activity.getPhoto1Path());
            stmt.setString(6, activity.getPhoto2Path());
            stmt.setString(7, activity.getVideoLink());
            
            if (activity.getPhoto1Content() != null) {
                stmt.setBytes(8, activity.getPhoto1Content());
            } else {
                stmt.setNull(8, Types.BLOB);
            }
            
            if (activity.getPhoto2Content() != null) {
                stmt.setBytes(9, activity.getPhoto2Content());
            } else {
                stmt.setNull(9, Types.BLOB);
            }
            
            stmt.setString(10, activity.getPhoto1FileName());
            stmt.setString(11, activity.getPhoto2FileName());
            stmt.setString(12, activity.getStatus());
            stmt.setString(13, activity.getUpdatedBy());
            stmt.setInt(14, activity.getActivityId());
            
            return stmt.executeUpdate() > 0;
        }
    }
    
    public boolean submitForApproval(int activityId, String submittedBy) throws SQLException {
        String sql = "UPDATE other_school_activities SET status = 'SUBMITTED', " +
                     "approval_status = 'PENDING_APPROVAL', submitted_by = ?, " +
                     "submitted_date = NOW() WHERE activity_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, submittedBy);
            stmt.setInt(2, activityId);
            
            return stmt.executeUpdate() > 0;
        }
    }
    
    public boolean approve(int activityId, String approvedBy, String remarks) throws SQLException {
        String sql = "UPDATE other_school_activities SET approval_status = 'APPROVED', " +
                     "approved_by = ?, approval_date = NOW(), approval_remarks = ? " +
                     "WHERE activity_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, approvedBy);
            stmt.setString(2, remarks);
            stmt.setInt(3, activityId);
            
            return stmt.executeUpdate() > 0;
        }
    }
    
    public boolean reject(int activityId, String rejectedBy, String reason) throws SQLException {
        String sql = "UPDATE other_school_activities SET approval_status = 'REJECTED', " +
                     "approved_by = ?, approval_date = NOW(), rejection_reason = ? " +
                     "WHERE activity_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, rejectedBy);
            stmt.setString(2, reason);
            stmt.setInt(3, activityId);
            
            return stmt.executeUpdate() > 0;
        }
    }
    
    public List<OtherSchoolActivity> getByUdise(String udiseNo) throws SQLException {
        String sql = "SELECT * FROM other_school_activities WHERE udise_no = ? " +
                     "ORDER BY activity_date DESC, created_date DESC";
        
        List<OtherSchoolActivity> activities = new ArrayList<>();
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseNo);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                activities.add(extractFromResultSet(rs));
            }
        }
        
        return activities;
    }
    
    public List<OtherSchoolActivity> getPendingApprovals(String udiseNo) throws SQLException {
        String sql = "SELECT * FROM other_school_activities WHERE udise_no = ? " +
                     "AND approval_status = 'PENDING_APPROVAL' ORDER BY submitted_date DESC";
        
        List<OtherSchoolActivity> activities = new ArrayList<>();
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseNo);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                activities.add(extractFromResultSet(rs));
            }
        }
        
        return activities;
    }
    
    public OtherSchoolActivity getById(int activityId) throws SQLException {
        String sql = "SELECT * FROM other_school_activities WHERE activity_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, activityId);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                return extractFromResultSet(rs);
            }
        }
        
        return null;
    }
    
    public boolean delete(int activityId) throws SQLException {
        String sql = "DELETE FROM other_school_activities WHERE activity_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, activityId);
            return stmt.executeUpdate() > 0;
        }
    }
    
    private OtherSchoolActivity extractFromResultSet(ResultSet rs) throws SQLException {
        OtherSchoolActivity activity = new OtherSchoolActivity();
        
        activity.setActivityId(rs.getInt("activity_id"));
        activity.setUdiseNo(rs.getString("udise_no"));
        activity.setSchoolName(rs.getString("school_name"));
        activity.setActivityDate(rs.getDate("activity_date"));
        activity.setActivitySubject(rs.getString("activity_subject"));
        activity.setGuestsPresent(rs.getString("guests_present"));
        activity.setDescription(rs.getString("description"));
        activity.setPhoto1Path(rs.getString("photo1_path"));
        activity.setPhoto2Path(rs.getString("photo2_path"));
        activity.setVideoLink(rs.getString("video_link"));
        
        activity.setPhoto1Content(rs.getBytes("photo1_content"));
        activity.setPhoto2Content(rs.getBytes("photo2_content"));
        activity.setPhoto1FileName(rs.getString("photo1_filename"));
        activity.setPhoto2FileName(rs.getString("photo2_filename"));
        
        activity.setStatus(rs.getString("status"));
        activity.setSubmittedBy(rs.getString("submitted_by"));
        activity.setSubmittedDate(rs.getTimestamp("submitted_date"));
        
        activity.setApprovalStatus(rs.getString("approval_status"));
        activity.setApprovedBy(rs.getString("approved_by"));
        activity.setApprovalDate(rs.getTimestamp("approval_date"));
        activity.setApprovalRemarks(rs.getString("approval_remarks"));
        activity.setRejectionReason(rs.getString("rejection_reason"));
        
        activity.setCreatedBy(rs.getString("created_by"));
        activity.setCreatedDate(rs.getTimestamp("created_date"));
        activity.setUpdatedBy(rs.getString("updated_by"));
        activity.setUpdatedDate(rs.getTimestamp("updated_date"));
        
        return activity;
    }
}
