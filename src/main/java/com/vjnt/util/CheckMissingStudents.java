package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Check FLN Completed Status for Missing Students
 */
public class CheckMissingStudents {
    
    public static void main(String[] args) {
        String udiseNo = "27150401803";
        
        System.out.println("=== Check Missing Students ===");
        System.out.println("UDISE: " + udiseNo);
        System.out.println("==============================\n");
        
        String[] missingStudents = {
            "JAGDISH BABA HARGAONKAR",
            "KRUSHNA RAMBHAU HARGAONKAR",
            "KRUSHNA RAMBHAU HARGAVKAR",
            "SAI LAXMAN GITTE",
            "SUMIT RANJIT PAWAR"
        };
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            for (String studentName : missingStudents) {
                String query = "SELECT student_id, student_name, student_pen, class, section, " +
                              "is_active, fln_completed, phase2_date " +
                              "FROM students " +
                              "WHERE udise_no = ? AND student_name = ? " +
                              "ORDER BY student_id DESC LIMIT 1";
                
                pstmt = conn.prepareStatement(query);
                pstmt.setString(1, udiseNo);
                pstmt.setString(2, studentName);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    int studentId = rs.getInt("student_id");
                    String pen = rs.getString("student_pen");
                    String studentClass = rs.getString("class");
                    String section = rs.getString("section");
                    boolean isActive = rs.getBoolean("is_active");
                    Boolean flnCompleted = rs.getBoolean("fln_completed");
                    if (rs.wasNull()) {
                        flnCompleted = null;
                    }
                    java.sql.Timestamp phase2Date = rs.getTimestamp("phase2_date");
                    
                    System.out.println("Student: " + studentName);
                    System.out.println("  ID: " + studentId);
                    System.out.println("  PEN: " + pen);
                    System.out.println("  Class: " + studentClass + "-" + section);
                    System.out.println("  is_active: " + isActive);
                    System.out.println("  fln_completed: " + flnCompleted);
                    System.out.println("  phase2_date: " + (phase2Date != null ? phase2Date : "NULL (NOT COMPLETED)"));
                    
                    if (flnCompleted != null && flnCompleted) {
                        System.out.println("  ⚠ ISSUE: fln_completed is TRUE - This is why student is hidden!");
                        System.out.println("  → Fixing: Setting fln_completed to FALSE...");
                        
                        String updateSql = "UPDATE students SET fln_completed = FALSE WHERE student_id = ?";
                        PreparedStatement updatePstmt = conn.prepareStatement(updateSql);
                        updatePstmt.setInt(1, studentId);
                        int updated = updatePstmt.executeUpdate();
                        updatePstmt.close();
                        
                        if (updated > 0) {
                            System.out.println("  ✓ Fixed! Student will now be visible in manage-students page.");
                        }
                    } else if (!isActive) {
                        System.out.println("  ⚠ ISSUE: is_active is FALSE - Student is marked as inactive!");
                        System.out.println("  → Fixing: Setting is_active to TRUE...");
                        
                        String updateSql = "UPDATE students SET is_active = TRUE WHERE student_id = ?";
                        PreparedStatement updatePstmt = conn.prepareStatement(updateSql);
                        updatePstmt.setInt(1, studentId);
                        int updated = updatePstmt.executeUpdate();
                        updatePstmt.close();
                        
                        if (updated > 0) {
                            System.out.println("  ✓ Fixed! Student is now active.");
                        }
                    } else {
                        System.out.println("  ✓ No issues - Student should be visible");
                    }
                } else {
                    System.out.println("Student: " + studentName);
                    System.out.println("  ✗ NOT FOUND in database!");
                }
                
                System.out.println();
                
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
            }
            
            System.out.println("==============================");
            System.out.println("✓ Check Complete!");
            System.out.println("Please refresh the manage-students page to see the students.");
            
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
