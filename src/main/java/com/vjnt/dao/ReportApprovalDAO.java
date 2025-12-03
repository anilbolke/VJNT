package com.vjnt.dao;

import com.vjnt.model.ReportApproval;
import com.vjnt.util.DatabaseConnection;
import java.sql.*;
import java.util.*;

public class ReportApprovalDAO {
    
    /**
     * Get all pending reports for a school
     */
    public List<ReportApproval> getPendingReportsByUdise(String udiseCode) {
        List<ReportApproval> reports = new ArrayList<>();
        String sql = "SELECT ra.*, u.username as requested_by_name FROM report_approvals ra " +
                    "LEFT JOIN users u ON ra.requested_by = u.user_id " +
                    "WHERE ra.udise_code = ? AND ra.approval_status = 'PENDING' " +
                    "ORDER BY ra.requested_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseCode);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                reports.add(mapResultSetToReportApproval(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return reports;
    }
    
    /**
     * Get all approved reports for a school
     */
    public List<ReportApproval> getApprovedReportsByUdise(String udiseCode) {
        List<ReportApproval> reports = new ArrayList<>();
        String sql = "SELECT ra.*, u.username as approved_by_name FROM report_approvals ra " +
                    "LEFT JOIN users u ON ra.approved_by = u.user_id " +
                    "WHERE ra.udise_code = ? AND ra.approval_status = 'APPROVED' " +
                    "ORDER BY ra.approval_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseCode);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                reports.add(mapResultSetToReportApproval(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return reports;
    }
    
    /**
     * Get report by approval ID
     */
    public ReportApproval getReportByApprovalId(int approvalId) {
        String sql = "SELECT ra.*, u1.username as requested_by_name, u2.username as approved_by_name " +
                    "FROM report_approvals ra " +
                    "LEFT JOIN users u1 ON ra.requested_by = u1.user_id " +
                    "LEFT JOIN users u2 ON ra.approved_by = u2.user_id " +
                    "WHERE ra.approval_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, approvalId);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                return mapResultSetToReportApproval(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return null;
    }
    
    /**
     * Create a report approval request
     */
    public int createReportApproval(ReportApproval report) {
        String sql = "INSERT INTO report_approvals " +
                    "(report_type, pen_number, student_name, class, section, udise_code, " +
                    "school_name, district, division, requested_by, approval_status) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING')";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            stmt.setString(1, report.getReportType());
            stmt.setString(2, report.getPenNumber());
            stmt.setString(3, report.getStudentName());
            stmt.setString(4, report.getStudentClass());
            stmt.setString(5, report.getSection());
            stmt.setString(6, report.getUdiseCode());
            stmt.setString(7, report.getSchoolName());
            stmt.setString(8, report.getDistrict());
            stmt.setString(9, report.getDivision());
            stmt.setInt(10, report.getRequestedBy());
            
            stmt.executeUpdate();
            
            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    return generatedKeys.getInt(1);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return -1;
    }
    
    /**
     * Approve a report
     */
    public boolean approveReport(int approvalId, int approvedBy, String remarks) {
        String sql = "UPDATE report_approvals SET approval_status = 'APPROVED', " +
                    "approved_by = ?, approval_date = NOW(), approval_remarks = ? " +
                    "WHERE approval_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, approvedBy);
            stmt.setString(2, remarks);
            stmt.setInt(3, approvalId);
            
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Reject a report
     */
    public boolean rejectReport(int approvalId, int rejectedBy, String reason) {
        String sql = "UPDATE report_approvals SET approval_status = 'REJECTED', " +
                    "approved_by = ?, approval_date = NOW(), approval_remarks = ? " +
                    "WHERE approval_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, rejectedBy);
            stmt.setString(2, reason);
            stmt.setInt(3, approvalId);
            
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Get pending count for a school
     */
    public int getPendingReportCount(String udiseCode) {
        String sql = "SELECT COUNT(*) as count FROM report_approvals " +
                    "WHERE udise_code = ? AND approval_status = 'PENDING'";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, udiseCode);
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
     * Check if report already exists for student
     */
    public boolean reportExists(String penNumber, String reportType) {
        String sql = "SELECT COUNT(*) as count FROM report_approvals " +
                    "WHERE pen_number = ? AND report_type = ? AND approval_status = 'PENDING'";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, penNumber);
            stmt.setString(2, reportType);
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
     * Get latest report by PEN number and user ID
     */
    public ReportApproval getLatestReportByPenAndUser(String penNumber, int userId) {
        String sql = "SELECT ra.*, u.username as requested_by_name FROM report_approvals ra " +
                    "LEFT JOIN users u ON ra.requested_by = u.user_id " +
                    "WHERE ra.pen_number = ? AND ra.requested_by = ? AND ra.is_active = 1 " +
                    "ORDER BY ra.requested_date DESC LIMIT 1";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, penNumber);
            stmt.setInt(2, userId);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                return mapResultSetToReportApproval(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return null;
    }
    
    /**
     * Map ResultSet to ReportApproval object
     */
    private ReportApproval mapResultSetToReportApproval(ResultSet rs) throws SQLException {
        ReportApproval report = new ReportApproval();
        report.setApprovalId(rs.getInt("approval_id"));
        report.setReportType(rs.getString("report_type"));
        report.setPenNumber(rs.getString("pen_number"));
        report.setStudentName(rs.getString("student_name"));
        report.setStudentClass(rs.getString("class"));
        report.setSection(rs.getString("section"));
        report.setUdiseCode(rs.getString("udise_code"));
        report.setSchoolName(rs.getString("school_name"));
        report.setDistrict(rs.getString("district"));
        report.setDivision(rs.getString("division"));
        report.setRequestedBy(rs.getInt("requested_by"));
        report.setRequestedDate(rs.getTimestamp("requested_date"));
        report.setApprovalStatus(rs.getString("approval_status"));
        report.setApprovedBy(rs.getInt("approved_by"));
        report.setApprovalDate(rs.getTimestamp("approval_date"));
        report.setApprovalRemarks(rs.getString("approval_remarks"));
        report.setReportGenerated(rs.getBoolean("report_generated"));
        report.setGeneratedDate(rs.getTimestamp("generated_date"));
        
        try {
            report.setRequestedByName(rs.getString("requested_by_name"));
        } catch (SQLException e) {
            // Column might not exist in all queries
        }
        
        try {
            report.setApprovedByName(rs.getString("approved_by_name"));
        } catch (SQLException e) {
            // Column might not exist in all queries
        }
        
        return report;
    }
}
