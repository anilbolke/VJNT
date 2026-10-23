package com.vjnt.dao;

import com.vjnt.util.DatabaseConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Mirrors {@link PhaseApprovalDAO} (School Coordinator submits a phase ->
 * Head Master approves/rejects) but against vidnyansetu_phase_approvals —
 * see "databse Scripts/ALTER_VIDNYANSETU_PHASE_SYSTEM_2026-09-19.sql".
 * Submitter is the VidnyanSetu Coordinator (vidnyansetu_users session);
 * approver is the school's real Head Master (main "user" session) — there is
 * no separate VidnyanSetu Head Master role.
 */
public class VidnyanSetuPhaseApprovalDAO {

    public boolean submitPhaseForApproval(String udiseNo, int phaseNumber, String completedBy, String remarks,
                                           int totalStudents, int completedStudents, int pendingStudents) {
        String sql = "INSERT INTO vidnyansetu_phase_approvals " +
                "(udise_no, phase_number, completed_by, completed_date, completion_remarks, " +
                " total_students, completed_students, pending_students, approval_status) " +
                "VALUES (?, ?, ?, NOW(), ?, ?, ?, ?, 'PENDING') " +
                "ON DUPLICATE KEY UPDATE " +
                "completed_by = VALUES(completed_by), completed_date = NOW(), " +
                "completion_remarks = VALUES(completion_remarks), " +
                "total_students = VALUES(total_students), completed_students = VALUES(completed_students), " +
                "pending_students = VALUES(pending_students), approval_status = 'PENDING'";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, udiseNo);
            ps.setInt(2, phaseNumber);
            ps.setString(3, completedBy);
            ps.setString(4, remarks);
            ps.setInt(5, totalStudents);
            ps.setInt(6, completedStudents);
            ps.setInt(7, pendingStudents);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuPhaseApprovalDAO] submitPhaseForApproval error: " + e.getMessage());
            return false;
        }
    }

    public Map<String,Object> getPhaseApproval(String udiseNo, int phaseNumber) {
        String sql = "SELECT * FROM vidnyansetu_phase_approvals WHERE udise_no = ? AND phase_number = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, udiseNo);
            ps.setInt(2, phaseNumber);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return extract(rs);
            }
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuPhaseApprovalDAO] getPhaseApproval error: " + e.getMessage());
        }
        return null;
    }

    public boolean isPhaseApproved(String udiseNo, int phaseNumber) {
        Map<String,Object> a = getPhaseApproval(udiseNo, phaseNumber);
        return a != null && "APPROVED".equals(a.get("approvalStatus"));
    }

    public boolean isPhaseComplete(String udiseNo, int phaseNumber) {
        Map<String,Object> a = getPhaseApproval(udiseNo, phaseNumber);
        return a != null;
    }

    public boolean isPhaseRejected(String udiseNo, int phaseNumber) {
        Map<String,Object> a = getPhaseApproval(udiseNo, phaseNumber);
        return a != null && "REJECTED".equals(a.get("approvalStatus"));
    }

    public List<Map<String,Object>> getPendingApprovals(String udiseNo) {
        List<Map<String,Object>> out = new ArrayList<>();
        String sql = "SELECT * FROM vidnyansetu_phase_approvals WHERE udise_no = ? AND approval_status = 'PENDING' ORDER BY phase_number";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, udiseNo);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(extract(rs));
            }
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuPhaseApprovalDAO] getPendingApprovals error: " + e.getMessage());
        }
        return out;
    }

    public int getPendingApprovalCount(String udiseNo) {
        String sql = "SELECT COUNT(*) FROM vidnyansetu_phase_approvals WHERE udise_no = ? AND approval_status = 'PENDING'";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, udiseNo);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuPhaseApprovalDAO] getPendingApprovalCount error: " + e.getMessage());
        }
        return 0;
    }

    public Map<String,Object> getById(int approvalId) {
        String sql = "SELECT * FROM vidnyansetu_phase_approvals WHERE approval_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, approvalId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return extract(rs);
            }
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuPhaseApprovalDAO] getById error: " + e.getMessage());
        }
        return null;
    }

    public boolean approvePhase(int approvalId, String approvedBy, String remarks) {
        return updateStatus(approvalId, "APPROVED", approvedBy, remarks);
    }

    public boolean rejectPhase(int approvalId, String approvedBy, String remarks) {
        return updateStatus(approvalId, "REJECTED", approvedBy, remarks);
    }

    private boolean updateStatus(int approvalId, String status, String approvedBy, String remarks) {
        String sql = "UPDATE vidnyansetu_phase_approvals SET approval_status = ?, approved_by = ?, " +
                "approved_date = NOW(), approval_remarks = ? WHERE approval_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setString(2, approvedBy);
            ps.setString(3, remarks);
            ps.setInt(4, approvalId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuPhaseApprovalDAO] updateStatus error: " + e.getMessage());
            return false;
        }
    }

    private Map<String,Object> extract(ResultSet rs) throws SQLException {
        Map<String,Object> m = new LinkedHashMap<>();
        m.put("approvalId", rs.getInt("approval_id"));
        m.put("udiseNo", rs.getString("udise_no"));
        m.put("phaseNumber", rs.getInt("phase_number"));
        m.put("completedBy", rs.getString("completed_by"));
        m.put("completedDate", rs.getTimestamp("completed_date"));
        m.put("completionRemarks", rs.getString("completion_remarks"));
        m.put("approvalStatus", rs.getString("approval_status"));
        m.put("approvedBy", rs.getString("approved_by"));
        m.put("approvedDate", rs.getTimestamp("approved_date"));
        m.put("approvalRemarks", rs.getString("approval_remarks"));
        m.put("totalStudents", rs.getInt("total_students"));
        m.put("completedStudents", rs.getInt("completed_students"));
        m.put("pendingStudents", rs.getInt("pending_students"));
        return m;
    }
}
