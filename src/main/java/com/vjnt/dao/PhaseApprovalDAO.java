package com.vjnt.dao;

import com.vjnt.model.PhaseApproval;
import com.vjnt.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * PhaseApproval Data Access Object
 * Handles phase completion and approval operations
 */
public class PhaseApprovalDAO {
    
    /**
     * Submit phase for approval (by School Coordinator)
     */
    public boolean submitPhaseForApproval(PhaseApproval approval) {
        String sql = "INSERT INTO phase_approvals " +
                     "(udise_no, phase_number, completed_by, completed_date, completion_remarks, " +
                     "total_students, completed_students, pending_students, ignored_students, approval_status) " +
                     "VALUES (?, ?, ?, NOW(), ?, ?, ?, ?, ?, 'PENDING') " +
                     "ON DUPLICATE KEY UPDATE " +
                     "completed_by = VALUES(completed_by), " +
                     "completed_date = NOW(), " +
                     "completion_remarks = VALUES(completion_remarks), " +
                     "total_students = VALUES(total_students), " +
                     "completed_students = VALUES(completed_students), " +
                     "pending_students = VALUES(pending_students), " +
                     "ignored_students = VALUES(ignored_students), " +
                     "approval_status = 'PENDING'";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, approval.getUdiseNo());
            pstmt.setInt(2, approval.getPhaseNumber());
            pstmt.setString(3, approval.getCompletedBy());
            pstmt.setString(4, approval.getCompletionRemarks());
            pstmt.setInt(5, approval.getTotalStudents());
            pstmt.setInt(6, approval.getCompletedStudents());
            pstmt.setInt(7, approval.getPendingStudents());
            pstmt.setInt(8, approval.getIgnoredStudents());
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error submitting phase for approval: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Approve or reject phase (by Head Master)
     */
    public boolean updateApprovalStatus(String udiseNo, int phaseNumber, 
                                       PhaseApproval.ApprovalStatus status, 
                                       String approvedBy, String remarks) {
        String sql = "UPDATE phase_approvals SET " +
                     "approval_status = ?, " +
                     "approved_by = ?, " +
                     "approved_date = NOW(), " +
                     "approval_remarks = ? " +
                     "WHERE udise_no = ? AND phase_number = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, status.name());
            pstmt.setString(2, approvedBy);
            pstmt.setString(3, remarks);
            pstmt.setString(4, udiseNo);
            pstmt.setInt(5, phaseNumber);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating approval status: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Get phase approval status
     */
    public PhaseApproval getPhaseApproval(String udiseNo, int phaseNumber) {
        String sql = "SELECT * FROM phase_approvals WHERE udise_no = ? AND phase_number = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            pstmt.setInt(2, phaseNumber);
            
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return extractPhaseApproval(rs);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting phase approval: " + e.getMessage());
            e.printStackTrace();
        }
        
        return null;
    }
    
    /**
     * Get all pending approvals for a UDISE (for Head Master)
     */
    public List<PhaseApproval> getPendingApprovals(String udiseNo) {
        List<PhaseApproval> approvals = new ArrayList<>();
        String sql = "SELECT * FROM phase_approvals " +
                     "WHERE udise_no = ? AND approval_status = 'PENDING' " +
                     "ORDER BY phase_number";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                approvals.add(extractPhaseApproval(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting pending approvals: " + e.getMessage());
            e.printStackTrace();
        }
        
        return approvals;
    }
    
    /**
     * Get all phase approvals for a UDISE
     */
    public List<PhaseApproval> getAllPhaseApprovals(String udiseNo) {
        List<PhaseApproval> approvals = new ArrayList<>();
        String sql = "SELECT * FROM phase_approvals WHERE udise_no = ? ORDER BY phase_number";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                approvals.add(extractPhaseApproval(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting all phase approvals: " + e.getMessage());
            e.printStackTrace();
        }
        
        return approvals;
    }
    
    /**
     * Check if phase is approved
     */
    public boolean isPhaseApproved(String udiseNo, int phaseNumber) {
        PhaseApproval approval = getPhaseApproval(udiseNo, phaseNumber);
        return approval != null && approval.isApproved();
    }
    
    /**
     * Get count of pending approvals for UDISE
     */
    public int getPendingApprovalCount(String udiseNo) {
        String sql = "SELECT COUNT(*) FROM phase_approvals " +
                     "WHERE udise_no = ? AND approval_status = 'PENDING'";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting pending approval count: " + e.getMessage());
            e.printStackTrace();
        }
        
        return 0;
    }
    
    /**
     * Approve phase by approval ID
     */
    public boolean approvePhase(int approvalId, String approvedBy, String remarks) {
        String sql = "UPDATE phase_approvals SET " +
                     "approval_status = 'APPROVED', " +
                     "approved_by = ?, " +
                     "approved_date = NOW(), " +
                     "approval_remarks = ? " +
                     "WHERE approval_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, approvedBy);
            pstmt.setString(2, remarks);
            pstmt.setInt(3, approvalId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error approving phase: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Reject phase by approval ID
     */
    public boolean rejectPhase(int approvalId, String approvedBy, String remarks) {
        String sql = "UPDATE phase_approvals SET " +
                     "approval_status = 'REJECTED', " +
                     "approved_by = ?, " +
                     "approved_date = NOW(), " +
                     "approval_remarks = ? " +
                     "WHERE approval_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, approvedBy);
            pstmt.setString(2, remarks);
            pstmt.setInt(3, approvalId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error rejecting phase: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Get phase approval by ID
     */
    public PhaseApproval getPhaseApprovalById(int approvalId) {
        String sql = "SELECT * FROM phase_approvals WHERE approval_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, approvalId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return extractPhaseApproval(rs);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting phase approval by ID: " + e.getMessage());
            e.printStackTrace();
        }
        
        return null;
    }
    
    /**
     * Extract PhaseApproval from ResultSet
     */
    private PhaseApproval extractPhaseApproval(ResultSet rs) throws SQLException {
        PhaseApproval approval = new PhaseApproval();
        
        approval.setApprovalId(rs.getInt("approval_id"));
        approval.setUdiseNo(rs.getString("udise_no"));
        approval.setPhaseNumber(rs.getInt("phase_number"));
        
        approval.setCompletedBy(rs.getString("completed_by"));
        approval.setCompletedDate(rs.getTimestamp("completed_date"));
        approval.setCompletionRemarks(rs.getString("completion_remarks"));
        
        String statusStr = rs.getString("approval_status");
        if (statusStr != null && !statusStr.isEmpty()) {
            approval.setApprovalStatus(PhaseApproval.ApprovalStatus.valueOf(statusStr));
        } else {
            approval.setApprovalStatus(PhaseApproval.ApprovalStatus.PENDING);
        }
        approval.setApprovedBy(rs.getString("approved_by"));
        approval.setApprovedDate(rs.getTimestamp("approved_date"));
        approval.setApprovalRemarks(rs.getString("approval_remarks"));
        
        approval.setTotalStudents(rs.getInt("total_students"));
        approval.setCompletedStudents(rs.getInt("completed_students"));
        approval.setPendingStudents(rs.getInt("pending_students"));
        approval.setIgnoredStudents(rs.getInt("ignored_students"));
        
        // Try to get audit timestamps (may not exist in old schema)
        try {
            approval.setCreatedDate(rs.getTimestamp("created_at"));
            approval.setUpdatedDate(rs.getTimestamp("updated_at"));
        } catch (SQLException e) {
            // Columns don't exist yet, use completed_date as fallback
            approval.setCreatedDate(rs.getTimestamp("completed_date"));
            approval.setUpdatedDate(rs.getTimestamp("completed_date"));
        }
        
        return approval;
    }
}
