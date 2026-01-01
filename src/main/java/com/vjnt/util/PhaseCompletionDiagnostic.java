package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Phase Completion Diagnostic Tool
 * Checks why phase completion is not 100% for a specific school
 */
public class PhaseCompletionDiagnostic {
    
    public static void main(String[] args) {
        String username = "sr_27150401803";
        
        System.out.println("=== Phase 2 Completion Diagnostic ===");
        System.out.println("Username: " + username);
        System.out.println("Date: " + new java.util.Date());
        System.out.println("=====================================\n");
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            // Step 1: Get UDISE number for this user
            String udiseQuery = "SELECT udise_no, user_type FROM users WHERE username = ?";
            pstmt = conn.prepareStatement(udiseQuery);
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();
            
            if (!rs.next()) {
                System.out.println("✗ ERROR: User not found!");
                return;
            }
            
            String udiseNo = rs.getString("udise_no");
            String userType = rs.getString("user_type");
            
            System.out.println("✓ User Found:");
            System.out.println("  UDISE No: " + udiseNo);
            System.out.println("  User Type: " + userType);
            System.out.println();
            
            rs.close();
            pstmt.close();
            
            // Step 2: Check total active students
            String totalQuery = "SELECT COUNT(*) as total FROM students WHERE udise_no = ? AND is_active = 1";
            pstmt = conn.prepareStatement(totalQuery);
            pstmt.setString(1, udiseNo);
            rs = pstmt.executeQuery();
            
            int totalActive = 0;
            if (rs.next()) {
                totalActive = rs.getInt("total");
            }
            rs.close();
            pstmt.close();
            
            System.out.println("📊 Total Active Students: " + totalActive);
            System.out.println();
            
            // Step 3: Check Phase 2 completion for each student
            String phase2Query = "SELECT student_id, student_name, student_pen, class, section, " +
                                "phase2_date, phase2_marathi, phase2_math, phase2_english, is_active " +
                                "FROM students WHERE udise_no = ? AND is_active = 1 " +
                                "ORDER BY class, section, student_name";
            
            pstmt = conn.prepareStatement(phase2Query);
            pstmt.setString(1, udiseNo);
            rs = pstmt.executeQuery();
            
            int completed = 0;
            int pending = 0;
            
            System.out.println("📋 Phase 2 Status for Each Student:");
            System.out.println("─────────────────────────────────────────────────────────────────────────");
            
            while (rs.next()) {
                String studentName = rs.getString("student_name");
                String studentPen = rs.getString("student_pen");
                String studentClass = rs.getString("class");
                String section = rs.getString("section");
                java.sql.Timestamp phase2Date = rs.getTimestamp("phase2_date");
                String phase2Marathi = rs.getString("phase2_marathi");
                String phase2Math = rs.getString("phase2_math");
                String phase2English = rs.getString("phase2_english");
                
                String status;
                if (phase2Date != null) {
                    completed++;
                    status = "✓ COMPLETED";
                } else {
                    pending++;
                    status = "✗ PENDING";
                }
                
                System.out.printf("%s | Class: %s-%s | PEN: %s | Name: %s\n", 
                                status, studentClass, section, studentPen, studentName);
                
                if (phase2Date == null) {
                    System.out.println("  → Phase 2 NOT saved yet (phase2_date is NULL)");
                } else {
                    System.out.println("  → Saved on: " + phase2Date);
                    System.out.println("  → Values: Marathi=" + phase2Marathi + 
                                     ", Math=" + phase2Math + 
                                     ", English=" + phase2English);
                }
                System.out.println();
            }
            
            rs.close();
            pstmt.close();
            
            // Step 4: Calculate and display percentage
            System.out.println("─────────────────────────────────────────────────────────────────────────");
            System.out.println("📈 PHASE 2 SUMMARY:");
            System.out.println("  Total Active Students: " + totalActive);
            System.out.println("  Completed: " + completed);
            System.out.println("  Pending: " + pending);
            
            if (totalActive > 0) {
                double percentage = (completed * 100.0) / totalActive;
                int roundedPercentage = (int) Math.round(percentage);
                System.out.println("  Completion Percentage: " + String.format("%.2f", percentage) + "% (rounded: " + roundedPercentage + "%)");
            }
            
            System.out.println();
            
            if (pending > 0) {
                System.out.println("⚠ ISSUE FOUND:");
                System.out.println("  " + pending + " student(s) have NOT completed Phase 2 assessment.");
                System.out.println("  These students are marked as active but their phase2_date is NULL.");
                System.out.println();
                System.out.println("💡 SOLUTION:");
                System.out.println("  1. Go to the student list and complete Phase 2 assessment for pending students");
                System.out.println("  2. Or mark inactive students as inactive (is_active = 0)");
                System.out.println("  3. After completing all assessments, the percentage will show 100%");
            } else {
                System.out.println("✓ All active students have completed Phase 2!");
            }
            
            // Step 5: Check if there are any inactive students
            String inactiveQuery = "SELECT COUNT(*) as inactive_count FROM students WHERE udise_no = ? AND is_active = 0";
            pstmt = conn.prepareStatement(inactiveQuery);
            pstmt.setString(1, udiseNo);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int inactiveCount = rs.getInt("inactive_count");
                if (inactiveCount > 0) {
                    System.out.println();
                    System.out.println("ℹ INFO: There are " + inactiveCount + " inactive students (not counted in percentage)");
                }
            }
            
            System.out.println();
            System.out.println("=== Diagnostic Complete ===");
            
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
