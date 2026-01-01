package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Diagnostic Tool for Student Videos
 * Checks why videos are not displaying
 */
public class DiagnoseStudentVideos {
    
    public static void main(String[] args) {
        String udiseNo = "27150401803";
        
        System.out.println("╔══════════════════════════════════════════════════════════╗");
        System.out.println("║         STUDENT VIDEOS DIAGNOSTIC TOOL                   ║");
        System.out.println("╚══════════════════════════════════════════════════════════╝");
        System.out.println();
        System.out.println("UDISE: " + udiseNo);
        System.out.println("Date: " + new java.util.Date());
        System.out.println();
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            // Check total videos in database
            System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            System.out.println("  TOTAL VIDEOS IN DATABASE");
            System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            
            String totalSql = "SELECT COUNT(*) as total FROM student_videos";
            pstmt = conn.prepareStatement(totalSql);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int total = rs.getInt("total");
                System.out.println("  Total videos (all schools): " + total);
            }
            rs.close();
            pstmt.close();
            
            // Check videos for this UDISE
            System.out.println();
            System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            System.out.println("  VIDEOS FOR UDISE: " + udiseNo);
            System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            
            String udiseSql = "SELECT COUNT(*) as total FROM student_videos WHERE udise_no = ?";
            pstmt = conn.prepareStatement(udiseSql);
            pstmt.setString(1, udiseNo);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int total = rs.getInt("total");
                System.out.println("  Total videos for this school: " + total);
            }
            rs.close();
            pstmt.close();
            
            // Check by approval status
            System.out.println();
            System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            System.out.println("  BREAKDOWN BY APPROVAL STATUS");
            System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            
            String statusSql = "SELECT " +
                             "COUNT(*) as total, " +
                             "SUM(CASE WHEN approval_status = 'APPROVED' THEN 1 ELSE 0 END) as approved, " +
                             "SUM(CASE WHEN approval_status = 'PENDING' THEN 1 ELSE 0 END) as pending, " +
                             "SUM(CASE WHEN approval_status = 'REJECTED' THEN 1 ELSE 0 END) as rejected, " +
                             "SUM(CASE WHEN approval_status IS NULL THEN 1 ELSE 0 END) as null_status, " +
                             "SUM(CASE WHEN is_active = TRUE THEN 1 ELSE 0 END) as active, " +
                             "SUM(CASE WHEN is_active = FALSE THEN 1 ELSE 0 END) as inactive, " +
                             "SUM(CASE WHEN is_visible = TRUE THEN 1 ELSE 0 END) as visible, " +
                             "SUM(CASE WHEN is_visible = FALSE THEN 1 ELSE 0 END) as not_visible " +
                             "FROM student_videos WHERE udise_no = ?";
            
            pstmt = conn.prepareStatement(statusSql);
            pstmt.setString(1, udiseNo);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                System.out.println("  Total:     " + rs.getInt("total"));
                System.out.println("  Approved:  " + rs.getInt("approved"));
                System.out.println("  Pending:   " + rs.getInt("pending"));
                System.out.println("  Rejected:  " + rs.getInt("rejected"));
                System.out.println("  NULL:      " + rs.getInt("null_status"));
                System.out.println();
                System.out.println("  Active:    " + rs.getInt("active"));
                System.out.println("  Inactive:  " + rs.getInt("inactive"));
                System.out.println();
                System.out.println("  Visible:   " + rs.getInt("visible"));
                System.out.println("  Not Visible: " + rs.getInt("not_visible"));
            }
            rs.close();
            pstmt.close();
            
            // List all videos with details
            System.out.println();
            System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            System.out.println("  VIDEO DETAILS");
            System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            
            String detailSql = "SELECT v.video_id, v.student_id, s.student_name, v.subject, v.month, " +
                             "v.approval_status, v.is_active, v.is_visible, v.uploaded_by_name, v.upload_date " +
                             "FROM student_videos v " +
                             "LEFT JOIN students s ON v.student_id = s.student_id " +
                             "WHERE v.udise_no = ? " +
                             "ORDER BY v.upload_date DESC";
            
            pstmt = conn.prepareStatement(detailSql);
            pstmt.setString(1, udiseNo);
            rs = pstmt.executeQuery();
            
            int count = 0;
            while (rs.next()) {
                count++;
                System.out.println();
                System.out.println("Video #" + count + ":");
                System.out.println("  ID: " + rs.getInt("video_id"));
                System.out.println("  Student: " + rs.getString("student_name") + " (ID: " + rs.getInt("student_id") + ")");
                System.out.println("  Subject: " + rs.getString("subject") + " - " + rs.getString("month"));
                System.out.println("  Approval: " + rs.getString("approval_status"));
                System.out.println("  Active: " + rs.getBoolean("is_active"));
                System.out.println("  Visible: " + rs.getBoolean("is_visible"));
                System.out.println("  Uploaded by: " + rs.getString("uploaded_by_name"));
                System.out.println("  Upload date: " + rs.getTimestamp("upload_date"));
            }
            
            if (count == 0) {
                System.out.println();
                System.out.println("  ⚠ NO VIDEOS FOUND FOR THIS SCHOOL!");
            }
            
            rs.close();
            pstmt.close();
            
            System.out.println();
            System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            System.out.println("  ISSUES DETECTED");
            System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            System.out.println();
            
            // Re-check for issues
            pstmt = conn.prepareStatement(statusSql);
            pstmt.setString(1, udiseNo);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int total = rs.getInt("total");
                int approved = rs.getInt("approved");
                int pending = rs.getInt("pending");
                int nullStatus = rs.getInt("null_status");
                int inactive = rs.getInt("inactive");
                int notVisible = rs.getInt("not_visible");
                
                if (total == 0) {
                    System.out.println("  ⚠ ISSUE: No videos exist for this school");
                    System.out.println("    → Upload videos first");
                } else {
                    if (nullStatus > 0) {
                        System.out.println("  ⚠ ISSUE: " + nullStatus + " video(s) have NULL approval_status");
                        System.out.println("    → These should be set to 'PENDING'");
                    }
                    
                    if (pending > 0) {
                        System.out.println("  ℹ INFO: " + pending + " video(s) are PENDING approval");
                        System.out.println("    → Headmaster needs to approve them");
                        System.out.println("    → School coordinators cannot see these");
                    }
                    
                    if (approved == 0 && total > 0) {
                        System.out.println("  ⚠ ISSUE: No videos are APPROVED");
                        System.out.println("    → School coordinators won't see any videos");
                    }
                    
                    if (inactive > 0) {
                        System.out.println("  ⚠ ISSUE: " + inactive + " video(s) are INACTIVE");
                        System.out.println("    → These won't be displayed");
                    }
                    
                    if (notVisible > 0) {
                        System.out.println("  ⚠ ISSUE: " + notVisible + " video(s) are NOT VISIBLE");
                        System.out.println("    → Check is_visible flag");
                    }
                }
            }
            
            System.out.println();
            System.out.println("╚══════════════════════════════════════════════════════════╝");
            
        } catch (SQLException e) {
            System.err.println("\n✗ DATABASE ERROR:");
            System.err.println("  " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { }
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
            if (conn != null) try { conn.close(); } catch (SQLException e) { }
        }
    }
}
