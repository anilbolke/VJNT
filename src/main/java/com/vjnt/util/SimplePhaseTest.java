package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import com.vjnt.util.DatabaseConnection;

/**
 * Simple Direct Test for Phase 2 Completion
 */
public class SimplePhaseTest {
    
    public static void main(String[] args) {
        String udiseNo = "27150401803";
        int phase = 2;
        
        System.out.println("=== Simple Phase 2 Test ===");
        System.out.println("UDISE: " + udiseNo);
        System.out.println("==========================\n");
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            // Test NEW query (with fln_completed filter)
            String sqlNew = "SELECT " +
                          "COUNT(*) as total_students, " +
                          "SUM(CASE WHEN phase2_date IS NOT NULL THEN 1 ELSE 0 END) as completed_students " +
                          "FROM students " +
                          "WHERE udise_no = ? " +
                          "AND is_active = 1 " +
                          "AND (fln_completed IS NULL OR fln_completed = FALSE)";
            
            pstmt = conn.prepareStatement(sqlNew);
            pstmt.setString(1, udiseNo);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int totalStudents = rs.getInt("total_students");
                int completedStudents = rs.getInt("completed_students");
                int percentage = totalStudents > 0 ? (int) Math.round((completedStudents * 100.0) / totalStudents) : 0;
                
                System.out.println("📊 NEW CALCULATION (excluding fln_completed = TRUE):");
                System.out.println("  Total Active Students (fln_completed = FALSE/NULL): " + totalStudents);
                System.out.println("  Phase 2 Completed: " + completedStudents);
                System.out.println("  Percentage: " + percentage + "%");
                
                if (percentage == 100) {
                    System.out.println("\n✓✓✓ SUCCESS! Phase 2 is now 100% ✓✓✓");
                } else {
                    System.out.println("\n⚠ Phase 2 is at " + percentage + "%");
                }
            }
            
            rs.close();
            pstmt.close();
            
            // Also show OLD calculation for comparison
            System.out.println("\n" + "─".repeat(50));
            
            String sqlOld = "SELECT " +
                          "COUNT(*) as total_students, " +
                          "SUM(CASE WHEN phase2_date IS NOT NULL THEN 1 ELSE 0 END) as completed_students " +
                          "FROM students " +
                          "WHERE udise_no = ? " +
                          "AND is_active = 1";
            
            pstmt = conn.prepareStatement(sqlOld);
            pstmt.setString(1, udiseNo);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int totalStudents = rs.getInt("total_students");
                int completedStudents = rs.getInt("completed_students");
                int percentage = totalStudents > 0 ? (int) Math.round((completedStudents * 100.0) / totalStudents) : 0;
                
                System.out.println("📊 OLD CALCULATION (including all active students):");
                System.out.println("  Total Active Students (all): " + totalStudents);
                System.out.println("  Phase 2 Completed: " + completedStudents);
                System.out.println("  Percentage: " + percentage + "%");
            }
            
            System.out.println("\n==========================");
            System.out.println("✓ Test Complete!");
            
        } catch (SQLException e) {
            System.err.println("\n✗ ERROR:");
            System.err.println("  " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { }
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
            if (conn != null) try { conn.close(); } catch (SQLException e) { }
        }
    }
}
