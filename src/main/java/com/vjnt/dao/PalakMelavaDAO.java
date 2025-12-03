package com.vjnt.dao;

import com.vjnt.model.PalakMelava;
import com.vjnt.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO for Palak Melava operations
 */
public class PalakMelavaDAO {
    
    /**
     * Get all Palak Melava records for a school
     */
    public List<PalakMelava> getByUdise(String udiseNo) {
        List<PalakMelava> list = new ArrayList<>();
        String sql = "SELECT * FROM palak_melava WHERE udise_no = ? ORDER BY meeting_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                list.add(extractFromResultSet(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
    
    /**
     * Get single record by ID
     */
    public PalakMelava getById(int melavaId) {
        String sql = "SELECT * FROM palak_melava WHERE melava_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, melavaId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return extractFromResultSet(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    /**
     * Create new Palak Melava record
     */
    public boolean create(PalakMelava melava) {
        String sql = "INSERT INTO palak_melava (udise_no, school_name, meeting_date, " +
                     "chief_attendee_info, total_parents_attended, photo_1_path, photo_2_path, " +
                     "photo_1_content, photo_2_content, photo_1_filename, photo_2_filename, " +
                     "status, submitted_by, submitted_date, created_by, created_date) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, NOW())";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            pstmt.setString(1, melava.getUdiseNo());
            pstmt.setString(2, melava.getSchoolName());
            pstmt.setDate(3, melava.getMeetingDate());
            pstmt.setString(4, melava.getChiefAttendeeInfo());
            pstmt.setString(5, melava.getTotalParentsAttended());
            pstmt.setString(6, melava.getPhoto1Path());
            pstmt.setString(7, melava.getPhoto2Path());
            
            // Store image content as BLOB
            if (melava.getPhoto1Content() != null) {
                pstmt.setBytes(8, melava.getPhoto1Content());
            } else {
                pstmt.setNull(8, java.sql.Types.LONGVARBINARY);
            }
            
            if (melava.getPhoto2Content() != null) {
                pstmt.setBytes(9, melava.getPhoto2Content());
            } else {
                pstmt.setNull(9, java.sql.Types.LONGVARBINARY);
            }
            
            pstmt.setString(10, melava.getPhoto1FileName());
            pstmt.setString(11, melava.getPhoto2FileName());
            pstmt.setString(12, melava.getStatus());
            pstmt.setString(13, melava.getSubmittedBy());
            pstmt.setString(14, melava.getCreatedBy());
            
            int rows = pstmt.executeUpdate();
            
            if (rows > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    melava.setMelavaId(rs.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Update existing Palak Melava record
     */
    public boolean update(PalakMelava melava) {
        String sql = "UPDATE palak_melava SET meeting_date = ?, " +
                     "chief_attendee_info = ?, total_parents_attended = ?, " +
                     "photo_1_path = ?, photo_2_path = ?, " +
                     "photo_1_content = ?, photo_2_content = ?, " +
                     "photo_1_filename = ?, photo_2_filename = ?, " +
                     "updated_by = ?, updated_date = NOW() WHERE melava_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setDate(1, melava.getMeetingDate());
            pstmt.setString(2, melava.getChiefAttendeeInfo());
            pstmt.setString(3, melava.getTotalParentsAttended());
            pstmt.setString(4, melava.getPhoto1Path());
            pstmt.setString(5, melava.getPhoto2Path());
            
            // Update image content as BLOB
            if (melava.getPhoto1Content() != null) {
                pstmt.setBytes(6, melava.getPhoto1Content());
            } else {
                pstmt.setNull(6, java.sql.Types.LONGVARBINARY);
            }
            
            if (melava.getPhoto2Content() != null) {
                pstmt.setBytes(7, melava.getPhoto2Content());
            } else {
                pstmt.setNull(7, java.sql.Types.LONGVARBINARY);
            }
            
            pstmt.setString(8, melava.getPhoto1FileName());
            pstmt.setString(9, melava.getPhoto2FileName());
            pstmt.setString(10, melava.getUpdatedBy());
            pstmt.setInt(11, melava.getMelavaId());
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Submit for approval
     */
    public boolean submitForApproval(int melavaId, String submittedBy) {
        String sql = "UPDATE palak_melava SET status = 'PENDING_APPROVAL', " +
                     "submitted_by = ?, submitted_date = NOW() WHERE melava_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, submittedBy);
            pstmt.setInt(2, melavaId);
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Approve record
     */
    public boolean approve(int melavaId, String approvedBy, String remarks) {
        String sql = "UPDATE palak_melava SET status = 'APPROVED', " +
                     "approved_by = ?, approval_date = NOW(), approval_remarks = ? " +
                     "WHERE melava_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, approvedBy);
            pstmt.setString(2, remarks);
            pstmt.setInt(3, melavaId);
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Reject record
     */
    public boolean reject(int melavaId, String rejectedBy, String reason) {
        String sql = "UPDATE palak_melava SET status = 'REJECTED', " +
                     "approved_by = ?, approval_date = NOW(), rejection_reason = ? " +
                     "WHERE melava_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, rejectedBy);
            pstmt.setString(2, reason);
            pstmt.setInt(3, melavaId);
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Get pending approvals for Head Master
     */
    public List<PalakMelava> getPendingApprovals(String udiseNo) {
        List<PalakMelava> list = new ArrayList<>();
        String sql = "SELECT * FROM palak_melava WHERE udise_no = ? AND status = 'PENDING_APPROVAL' " +
                     "ORDER BY submitted_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                list.add(extractFromResultSet(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
    
    /**
     * Get count of pending approvals
     */
    public int getPendingCount(String udiseNo) {
        String sql = "SELECT COUNT(*) FROM palak_melava WHERE udise_no = ? AND status = 'PENDING_APPROVAL'";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    /**
     * Delete record
     */
    public boolean delete(int melavaId) {
        String sql = "DELETE FROM palak_melava WHERE melava_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, melavaId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Extract PalakMelava from ResultSet
     */
    private PalakMelava extractFromResultSet(ResultSet rs) throws SQLException {
        PalakMelava melava = new PalakMelava();
        melava.setMelavaId(rs.getInt("melava_id"));
        melava.setUdiseNo(rs.getString("udise_no"));
        melava.setSchoolName(rs.getString("school_name"));
        melava.setMeetingDate(rs.getDate("meeting_date"));
        melava.setChiefAttendeeInfo(rs.getString("chief_attendee_info"));
        melava.setTotalParentsAttended(rs.getString("total_parents_attended"));
        melava.setPhoto1Path(rs.getString("photo_1_path"));
        melava.setPhoto2Path(rs.getString("photo_2_path"));
        
        // Retrieve image content from database (BLOB)
        byte[] photo1Content = rs.getBytes("photo_1_content");
        byte[] photo2Content = rs.getBytes("photo_2_content");
        
        melava.setPhoto1Content(photo1Content);
        melava.setPhoto2Content(photo2Content);
        melava.setPhoto1FileName(rs.getString("photo_1_filename"));
        melava.setPhoto2FileName(rs.getString("photo_2_filename"));
        
        melava.setStatus(rs.getString("status"));
        melava.setSubmittedBy(rs.getString("submitted_by"));
        melava.setSubmittedDate(rs.getTimestamp("submitted_date"));
        melava.setApprovedBy(rs.getString("approved_by"));
        melava.setApprovalDate(rs.getTimestamp("approval_date"));
        melava.setApprovalRemarks(rs.getString("approval_remarks"));
        melava.setRejectionReason(rs.getString("rejection_reason"));
        melava.setCreatedBy(rs.getString("created_by"));
        melava.setCreatedDate(rs.getTimestamp("created_date"));
        melava.setUpdatedBy(rs.getString("updated_by"));
        melava.setUpdatedDate(rs.getTimestamp("updated_date"));
        return melava;
    }
}
