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
                    
                    
                    if (flnCompleted != null && flnCompleted) {
                        
                        String updateSql = "UPDATE students SET fln_completed = FALSE WHERE student_id = ?";
                        PreparedStatement updatePstmt = conn.prepareStatement(updateSql);
                        updatePstmt.setInt(1, studentId);
                        int updated = updatePstmt.executeUpdate();
                        updatePstmt.close();
                        
                        if (updated > 0) {
                        }
                    } else if (!isActive) {
                        
                        String updateSql = "UPDATE students SET is_active = TRUE WHERE student_id = ?";
                        PreparedStatement updatePstmt = conn.prepareStatement(updateSql);
                        updatePstmt.setInt(1, studentId);
                        int updated = updatePstmt.executeUpdate();
                        updatePstmt.close();
                        
                        if (updated > 0) {
                        }
                    } else {
                    }
                } else {
                }
                
                
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
            }
            
            
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
