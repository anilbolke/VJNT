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
     * Get Phase status by district with school details
     * Returns list of all schools with their Phase completion status for all 4 phases
     * Checks both phase_approvals table and actual student phase completion dates
     */
    public List<java.util.Map<String, Object>> getPhaseStatusByDistrict(String districtName) {
        List<java.util.Map<String, Object>> statusList = new ArrayList<>();
        
        String sql = "SELECT " +
                     "s.udise_no, " +
                     "s.school_name, " +
                     "sc_hm.full_name as headmaster_name, " +
                     "sc_hm.mobile as headmaster_mobile, " +
                     "sc_hm.whatsapp_number as headmaster_whatsapp, " +
                     "COUNT(DISTINCT st.student_id) as total_students, " +
                     // Phase 1 - Check both approval status and actual student completion
                     "MAX(CASE WHEN pa.phase_number = 1 THEN pa.approval_status END) as phase1_approval_status, " +
                     "COUNT(DISTINCT CASE WHEN st.phase1_date IS NOT NULL THEN st.student_id END) as phase1_completed, " +
                     "MAX(CASE WHEN pa.phase_number = 1 THEN pa.pending_students END) as phase1_pending, " +
                     "MAX(CASE WHEN pa.phase_number = 1 THEN pa.completed_date END) as phase1_date, " +
                     // Phase 2
                     "MAX(CASE WHEN pa.phase_number = 2 THEN pa.approval_status END) as phase2_approval_status, " +
                     "COUNT(DISTINCT CASE WHEN st.phase2_date IS NOT NULL THEN st.student_id END) as phase2_completed, " +
                     "MAX(CASE WHEN pa.phase_number = 2 THEN pa.pending_students END) as phase2_pending, " +
                     "MAX(CASE WHEN pa.phase_number = 2 THEN pa.completed_date END) as phase2_date, " +
                     // Phase 3
                     "MAX(CASE WHEN pa.phase_number = 3 THEN pa.approval_status END) as phase3_approval_status, " +
                     "COUNT(DISTINCT CASE WHEN st.phase3_date IS NOT NULL THEN st.student_id END) as phase3_completed, " +
                     "MAX(CASE WHEN pa.phase_number = 3 THEN pa.pending_students END) as phase3_pending, " +
                     "MAX(CASE WHEN pa.phase_number = 3 THEN pa.completed_date END) as phase3_date, " +
                     // Phase 4
                     "MAX(CASE WHEN pa.phase_number = 4 THEN pa.approval_status END) as phase4_approval_status, " +
                     "COUNT(DISTINCT CASE WHEN st.phase4_date IS NOT NULL THEN st.student_id END) as phase4_completed, " +
                     "MAX(CASE WHEN pa.phase_number = 4 THEN pa.pending_students END) as phase4_pending, " +
                     "MAX(CASE WHEN pa.phase_number = 4 THEN pa.completed_date END) as phase4_date " +
                     "FROM schools s " +
                     "LEFT JOIN school_contacts sc_hm ON s.udise_no COLLATE utf8mb4_unicode_ci = sc_hm.udise_no COLLATE utf8mb4_unicode_ci AND sc_hm.contact_type = 'Head Master' " +
                     "LEFT JOIN phase_approvals pa ON s.udise_no COLLATE utf8mb4_unicode_ci = pa.udise_no COLLATE utf8mb4_unicode_ci " +
                     "LEFT JOIN students st ON s.udise_no COLLATE utf8mb4_unicode_ci = st.udise_no COLLATE utf8mb4_unicode_ci " +
                     "WHERE s.district_name COLLATE utf8mb4_unicode_ci = ? COLLATE utf8mb4_unicode_ci " +
                     "GROUP BY s.udise_no, s.school_name, sc_hm.full_name, sc_hm.mobile, sc_hm.whatsapp_number " +
                     "ORDER BY s.school_name";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, districtName);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                java.util.Map<String, Object> schoolStatus = new java.util.HashMap<>();
                schoolStatus.put("udiseNo", rs.getString("udise_no"));
                schoolStatus.put("schoolName", rs.getString("school_name"));
                schoolStatus.put("headmasterName", rs.getString("headmaster_name"));
                schoolStatus.put("headmasterMobile", rs.getString("headmaster_mobile"));
                schoolStatus.put("headmasterWhatsapp", rs.getString("headmaster_whatsapp"));
                
                int totalStudents = rs.getInt("total_students");
                schoolStatus.put("totalStudents", totalStudents);
                
                // Process each phase - determine status based on approval status AND actual student completions
                int phasesApproved = 0;
                int phasesDone = 0; // Completed but not submitted
                int phasesPending = 0;
                int phasesNotStarted = 0;
                
                for (int phaseNum = 1; phaseNum <= 4; phaseNum++) {
                    String approvalStatus = rs.getString("phase" + phaseNum + "_approval_status");
                    int completedCount = rs.getInt("phase" + phaseNum + "_completed");
                    int pendingCount = rs.getInt("phase" + phaseNum + "_pending");
                    java.sql.Date completedDate = rs.getDate("phase" + phaseNum + "_date");
                    
                    // Determine actual phase status
                    String phaseStatus;
                    if ("APPROVED".equals(approvalStatus)) {
                        // Phase is officially approved
                        phaseStatus = "APPROVED";
                        phasesApproved++;
                    } else if ("PENDING".equals(approvalStatus)) {
                        // Phase submitted but waiting for approval
                        phaseStatus = "PENDING";
                        phasesPending++;
                    } else if (completedCount > 0) {
                        // Students have completed phase but not submitted for approval yet
                        phaseStatus = "COMPLETED_NOT_SUBMITTED";
                        phasesDone++;
                    } else {
                        // Phase not started
                        phaseStatus = "NOT_STARTED";
                        phasesNotStarted++;
                    }
                    
                    // Store phase data
                    schoolStatus.put("phase" + phaseNum + "Status", phaseStatus);
                    schoolStatus.put("phase" + phaseNum + "Completed", completedCount);
                    schoolStatus.put("phase" + phaseNum + "Pending", pendingCount);
                    schoolStatus.put("phase" + phaseNum + "Date", completedDate);
                    
                    // Calculate percentage for display
                    int percentage = (totalStudents > 0) ? (completedCount * 100 / totalStudents) : 0;
                    schoolStatus.put("phase" + phaseNum + "Percentage", percentage);
                }
                
                // Total phases that have some completion (approved, done, or pending)
                int phasesCompleted = phasesApproved + phasesDone + phasesPending;
                
                schoolStatus.put("phasesCompleted", phasesCompleted);
                schoolStatus.put("phasesPending", phasesPending);
                schoolStatus.put("phasesNotStarted", phasesNotStarted);
                
                // Overall status - prioritize based on actual state
                String overallStatus;
                if (phasesApproved == 4) {
                    // All 4 phases are officially APPROVED
                    overallStatus = "ALL_COMPLETED";
                } else if (phasesPending > 0) {
                    // Has some pending approvals
                    overallStatus = "PENDING_APPROVAL";
                } else if (phasesDone > 0 || phasesApproved > 0) {
                    // Has some completed or approved phases but not all 4 approved
                    overallStatus = "IN_PROGRESS";
                } else {
                    // Nothing started at all
                    overallStatus = "NOT_STARTED";
                }
                schoolStatus.put("overallStatus", overallStatus);
                
                statusList.add(schoolStatus);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting phase status by district: " + e.getMessage());
            e.printStackTrace();
        }
        
        return statusList;
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
