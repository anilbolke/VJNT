package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/**
 * Revert FLN Completed Status for 5 Students
 * Set them back to fln_completed = TRUE so they are excluded from phase calculations
 */
public class RevertFLNCompletedStatus {
    
    public static void main(String[] args) {
        String udiseNo = "27150401803";
        
        //System.out.println("=== Revert FLN Completed Status ===");
        //System.out.println("Setting fln_completed = TRUE for 5 students");
        //System.out.println("====================================\n");
        
        String[] studentNames = {
            "JAGDISH BABA HARGAONKAR",
            "KRUSHNA RAMBHAU HARGAONKAR",
            "KRUSHNA RAMBHAU HARGAVKAR",
            "SAI LAXMAN GITTE",
            "SUMIT RANJIT PAWAR"
        };
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            for (String studentName : studentNames) {
                String updateSql = "UPDATE students SET fln_completed = TRUE " +
                                 "WHERE udise_no = ? AND student_name = ? AND is_active = 1";
                
                pstmt = conn.prepareStatement(updateSql);
                pstmt.setString(1, udiseNo);
                pstmt.setString(2, studentName);
                
                int updated = pstmt.executeUpdate();
                
                if (updated > 0) {
                    //System.out.println("✓ " + studentName + " - Set fln_completed = TRUE");
                } else {
                    //System.out.println("⚠ " + studentName + " - No records updated");
                }
                
                pstmt.close();
            }
            
            //System.out.println("\n====================================");
            //System.out.println("✓ Revert Complete!");
            //System.out.println("These students will now be excluded from phase completion calculations.");
            
        } catch (SQLException e) {
            System.err.println("\n✗ DATABASE ERROR:");
            System.err.println("  " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
            if (conn != null) try { conn.close(); } catch (SQLException e) { }
        }
    }
}
