package com.vjnt.util;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.SQLException;

/**
 * Database Schema Updater
 * Adds missing columns to student_videos table
 */
public class DatabaseSchemaUpdater {
    
    public static void main(String[] args) {
        
        Connection conn = null;
        Statement stmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            stmt = conn.createStatement();
            
            // Add approval_status column
            try {
                stmt.executeUpdate(
                    "ALTER TABLE student_videos ADD COLUMN approval_status VARCHAR(20) DEFAULT 'PENDING' " +
                    "COMMENT 'PENDING, APPROVED, REJECTED'"
                );
            } catch (SQLException e) {
                if (e.getMessage().contains("Duplicate column")) {
                } else {
                    throw e;
                }
            }
            
            // Add approved_by column
            try {
                stmt.executeUpdate(
                    "ALTER TABLE student_videos ADD COLUMN approved_by INT DEFAULT NULL " +
                    "COMMENT 'User ID of headmaster who approved/rejected'"
                );
            } catch (SQLException e) {
                if (e.getMessage().contains("Duplicate column")) {
                } else {
                    throw e;
                }
            }
            
            // Add approved_by_name column
            try {
                stmt.executeUpdate(
                    "ALTER TABLE student_videos ADD COLUMN approved_by_name VARCHAR(255) DEFAULT NULL " +
                    "COMMENT 'Name of headmaster who approved/rejected'"
                );
                //System.out.println("✓ Added column: approved_by_name");
            } catch (SQLException e) {
                if (e.getMessage().contains("Duplicate column")) {
                    //System.out.println("✓ Column approved_by_name already exists");
                } else {
                    throw e;
                }
            }
            
            // Add approval_date column
            try {
                stmt.executeUpdate(
                    "ALTER TABLE student_videos ADD COLUMN approval_date DATETIME DEFAULT NULL " +
                    "COMMENT 'Date and time of approval/rejection'"
                );
                //System.out.println("✓ Added column: approval_date");
            } catch (SQLException e) {
                if (e.getMessage().contains("Duplicate column")) {
                    //System.out.println("✓ Column approval_date already exists");
                } else {
                    throw e;
                }
            }
            
            // Add rejection_reason column
            try {
                stmt.executeUpdate(
                    "ALTER TABLE student_videos ADD COLUMN rejection_reason TEXT DEFAULT NULL " +
                    "COMMENT 'Reason for rejection if status is REJECTED'"
                );
                //System.out.println("✓ Added column: rejection_reason");
            } catch (SQLException e) {
                if (e.getMessage().contains("Duplicate column")) {
                    //System.out.println("✓ Column rejection_reason already exists");
                } else {
                    throw e;
                }
            }
            
            // Add is_visible column
            try {
                stmt.executeUpdate(
                    "ALTER TABLE student_videos ADD COLUMN is_visible BOOLEAN DEFAULT TRUE " +
                    "COMMENT 'Whether video is visible to students'"
                );
                //System.out.println("✓ Added column: is_visible");
            } catch (SQLException e) {
                if (e.getMessage().contains("Duplicate column")) {
                    //System.out.println("✓ Column is_visible already exists");
                } else {
                    throw e;
                }
            }
            
            // Add indexes
            try {
                stmt.executeUpdate("ALTER TABLE student_videos ADD INDEX idx_approval_status (approval_status)");
                //System.out.println("✓ Added index: idx_approval_status");
            } catch (SQLException e) {
                if (e.getMessage().contains("Duplicate key")) {
                    //System.out.println("✓ Index idx_approval_status already exists");
                } else {
                    //System.out.println("⚠ Warning: Could not add index idx_approval_status: " + e.getMessage());
                }
            }
            
            try {
                stmt.executeUpdate("ALTER TABLE student_videos ADD INDEX idx_udise_approval (udise_no, approval_status)");
                //System.out.println("✓ Added index: idx_udise_approval");
            } catch (SQLException e) {
                if (e.getMessage().contains("Duplicate key")) {
                    //System.out.println("✓ Index idx_udise_approval already exists");
                } else {
                    //System.out.println("⚠ Warning: Could not add index idx_udise_approval: " + e.getMessage());
                }
            }
            
            try {
                stmt.executeUpdate("ALTER TABLE student_videos ADD INDEX idx_approved_by (approved_by)");
                //System.out.println("✓ Added index: idx_approved_by");
            } catch (SQLException e) {
                if (e.getMessage().contains("Duplicate key")) {
                    //System.out.println("✓ Index idx_approved_by already exists");
                } else {
                    //System.out.println("⚠ Warning: Could not add index idx_approved_by: " + e.getMessage());
                }
            }
            
            // Update existing videos uploaded by headmasters to auto-approved
            int headmasterVideos = stmt.executeUpdate(
                "UPDATE student_videos sv " +
                "INNER JOIN users u ON sv.uploaded_by = u.user_id " +
                "SET sv.approval_status = 'APPROVED', " +
                "    sv.approved_by = u.user_id, " +
                "    sv.approved_by_name = u.username, " +
                "    sv.approval_date = sv.upload_date, " +
                "    sv.is_visible = TRUE " +
                "WHERE u.user_type = 'HEAD_MASTER' " +
                "AND (sv.approval_status IS NULL OR sv.approval_status = 'PENDING')"
            );
            //System.out.println("✓ Auto-approved " + headmasterVideos + " videos uploaded by headmasters");
            
            // Update existing videos to PENDING if uploaded by school coordinator
            int coordinatorVideos = stmt.executeUpdate(
                "UPDATE student_videos sv " +
                "INNER JOIN users u ON sv.uploaded_by = u.user_id " +
                "SET sv.approval_status = 'PENDING', " +
                "    sv.is_visible = FALSE " +
                "WHERE u.user_type = 'SCHOOL_COORDINATOR' " +
                "AND sv.approval_status IS NULL"
            );
            //System.out.println("✓ Set " + coordinatorVideos + " videos to PENDING status for coordinator uploads");
            
            //System.out.println("\n=== Schema Update Completed Successfully! ===");
            //System.out.println("The student_videos table now has all required columns.");
            //System.out.println("You can now restart your application.");
            
        } catch (SQLException e) {
            System.err.println("\n✗ ERROR updating database schema:");
            System.err.println("  " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (stmt != null) {
                try { stmt.close(); } catch (SQLException e) { }
            }
            if (conn != null) {
                try { conn.close(); } catch (SQLException e) { }
            }
        }
    }
}
