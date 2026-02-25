package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;

/**
 * Diagnostic and Fix Tool for Video Approval Issues
 * Checks if approval columns exist and adds them if missing
 */
public class FixVideoApprovalIssue {
    
    public static void main(String[] args) {
        //System.out.println("╔══════════════════════════════════════════════════════════╗");
        //System.out.println("║     VIDEO APPROVAL SYSTEM - DIAGNOSTIC & FIX TOOL        ║");
        //System.out.println("╚══════════════════════════════════════════════════════════╝");
        //System.out.println();
        
        Connection conn = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            //System.out.println("✓ Database connection successful\n");
            
            // Step 1: Check if student_videos table exists
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            //System.out.println("  STEP 1: Checking if student_videos table exists");
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery("SHOW TABLES LIKE 'student_videos'");
            
            if (!rs.next()) {
                //System.out.println("✗ ERROR: student_videos table does not exist!");
                //System.out.println("  Please create the table first using DATABASE_SCHEMA_YOUTUBE.sql");
                return;
            }
            
            //System.out.println("✓ student_videos table exists\n");
            rs.close();
            
            // Step 2: Check existing columns
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            //System.out.println("  STEP 2: Checking existing columns");
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            
            rs = stmt.executeQuery("SELECT * FROM student_videos LIMIT 1");
            ResultSetMetaData metaData = rs.getMetaData();
            int columnCount = metaData.getColumnCount();
            
            boolean hasApprovalStatus = false;
            boolean hasApprovedBy = false;
            boolean hasApprovedByName = false;
            boolean hasApprovalDate = false;
            boolean hasRejectionReason = false;
            boolean hasIsVisible = false;
            
            //System.out.println("  Existing columns:");
            for (int i = 1; i <= columnCount; i++) {
                String columnName = metaData.getColumnName(i);
                //System.out.println("    - " + columnName);
                
                if (columnName.equals("approval_status")) hasApprovalStatus = true;
                if (columnName.equals("approved_by")) hasApprovedBy = true;
                if (columnName.equals("approved_by_name")) hasApprovedByName = true;
                if (columnName.equals("approval_date")) hasApprovalDate = true;
                if (columnName.equals("rejection_reason")) hasRejectionReason = true;
                if (columnName.equals("is_visible")) hasIsVisible = true;
            }
            rs.close();
            
            //System.out.println();
            //System.out.println("  Approval columns status:");
            //System.out.println("    - approval_status:   " + (hasApprovalStatus ? "✓ EXISTS" : "✗ MISSING"));
            //System.out.println("    - approved_by:       " + (hasApprovedBy ? "✓ EXISTS" : "✗ MISSING"));
            //System.out.println("    - approved_by_name:  " + (hasApprovedByName ? "✓ EXISTS" : "✗ MISSING"));
            //System.out.println("    - approval_date:     " + (hasApprovalDate ? "✓ EXISTS" : "✗ MISSING"));
            //System.out.println("    - rejection_reason:  " + (hasRejectionReason ? "✓ EXISTS" : "✗ MISSING"));
            //System.out.println("    - is_visible:        " + (hasIsVisible ? "✓ EXISTS" : "✗ MISSING"));
            //System.out.println();
            
            // Step 3: Add missing columns
            boolean needsFix = !hasApprovalStatus || !hasApprovedBy || !hasApprovedByName || 
                              !hasApprovalDate || !hasRejectionReason || !hasIsVisible;
            
            if (needsFix) {
                //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                //System.out.println("  STEP 3: Adding missing columns");
                //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                
                if (!hasApprovalStatus) {
                    System.out.print("  Adding approval_status column... ");
                    stmt.executeUpdate("ALTER TABLE student_videos ADD COLUMN approval_status VARCHAR(20) DEFAULT 'PENDING'");
                    //System.out.println("✓ DONE");
                }
                
                if (!hasApprovedBy) {
                    System.out.print("  Adding approved_by column... ");
                    stmt.executeUpdate("ALTER TABLE student_videos ADD COLUMN approved_by INT DEFAULT NULL");
                    //System.out.println("✓ DONE");
                }
                
                if (!hasApprovedByName) {
                    System.out.print("  Adding approved_by_name column... ");
                    stmt.executeUpdate("ALTER TABLE student_videos ADD COLUMN approved_by_name VARCHAR(255) DEFAULT NULL");
                    //System.out.println("✓ DONE");
                }
                
                if (!hasApprovalDate) {
                    System.out.print("  Adding approval_date column... ");
                    stmt.executeUpdate("ALTER TABLE student_videos ADD COLUMN approval_date DATETIME DEFAULT NULL");
                    //System.out.println("✓ DONE");
                }
                
                if (!hasRejectionReason) {
                    System.out.print("  Adding rejection_reason column... ");
                    stmt.executeUpdate("ALTER TABLE student_videos ADD COLUMN rejection_reason TEXT DEFAULT NULL");
                    //System.out.println("✓ DONE");
                }
                
                if (!hasIsVisible) {
                    System.out.print("  Adding is_visible column... ");
                    stmt.executeUpdate("ALTER TABLE student_videos ADD COLUMN is_visible BOOLEAN DEFAULT TRUE");
                    //System.out.println("✓ DONE");
                }
                
                //System.out.println();
                //System.out.println("  Adding indexes for performance...");
                
                try {
                    stmt.executeUpdate("ALTER TABLE student_videos ADD INDEX idx_approval_status (approval_status)");
                    //System.out.println("    - idx_approval_status ✓");
                } catch (Exception e) {
                    //System.out.println("    - idx_approval_status (already exists)");
                }
                
                try {
                    stmt.executeUpdate("ALTER TABLE student_videos ADD INDEX idx_udise_approval (udise_no, approval_status)");
                    //System.out.println("    - idx_udise_approval ✓");
                } catch (Exception e) {
                    //System.out.println("    - idx_udise_approval (already exists)");
                }
                
                try {
                    stmt.executeUpdate("ALTER TABLE student_videos ADD INDEX idx_approved_by (approved_by)");
                    //System.out.println("    - idx_approved_by ✓");
                } catch (Exception e) {
                    //System.out.println("    - idx_approved_by (already exists)");
                }
                
                //System.out.println();
            } else {
                //System.out.println("✓ All approval columns already exist\n");
            }
            
            // Step 4: Check video data
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            //System.out.println("  STEP 4: Checking video data");
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            
            PreparedStatement pstmt = conn.prepareStatement(
                "SELECT COUNT(*) as total, " +
                "SUM(CASE WHEN approval_status = 'PENDING' THEN 1 ELSE 0 END) as pending, " +
                "SUM(CASE WHEN approval_status = 'APPROVED' THEN 1 ELSE 0 END) as approved, " +
                "SUM(CASE WHEN approval_status = 'REJECTED' THEN 1 ELSE 0 END) as rejected " +
                "FROM student_videos"
            );
            
            rs = pstmt.executeQuery();
            if (rs.next()) {
                //System.out.println("  Total videos:    " + rs.getInt("total"));
                //System.out.println("  Pending:         " + rs.getInt("pending"));
                //System.out.println("  Approved:        " + rs.getInt("approved"));
                //System.out.println("  Rejected:        " + rs.getInt("rejected"));
            }
            rs.close();
            pstmt.close();
            
            // Check by UDISE
            //System.out.println();
            //System.out.println("  Videos by school (UDISE):");
            pstmt = conn.prepareStatement(
                "SELECT udise_no, COUNT(*) as total, " +
                "SUM(CASE WHEN approval_status = 'PENDING' THEN 1 ELSE 0 END) as pending " +
                "FROM student_videos GROUP BY udise_no"
            );
            
            rs = pstmt.executeQuery();
            while (rs.next()) {
            }
            rs.close();
            pstmt.close();
            
            //System.out.println();
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            //System.out.println("  ✓ DIAGNOSTIC COMPLETE");
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            //System.out.println();
            //System.out.println("NEXT STEPS:");
            //System.out.println("1. If columns were added, restart your Tomcat server");
            //System.out.println("2. Have school coordinator upload a test video");
            //System.out.println("3. Log in as Head Master to approve-videos.jsp");
            //System.out.println("4. The pending video should now appear for approval");
            //System.out.println();
            
            stmt.close();
            
        } catch (Exception e) {
            System.err.println("ERROR: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
