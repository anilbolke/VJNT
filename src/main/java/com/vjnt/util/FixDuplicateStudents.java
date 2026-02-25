package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;

/**
 * Fix Duplicate Students - Mark old/duplicate records as inactive
 * This will help achieve 100% phase completion
 */
public class FixDuplicateStudents {
    
    public static void main(String[] args) {
        String udiseNo = "27150401803";
        
        //System.out.println("=== Fix Duplicate Students Utility ===");
        //System.out.println("UDISE: " + udiseNo);
        //System.out.println("=====================================\n");
        
        Connection conn = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            // List of duplicate students with pending Phase 2
            String[] duplicateStudents = {
                "JAGDISH BABA HARGAONKAR",
                "KARAN CHANDU VANJARE", 
                "KRUSHNA RAMBHAU HARGAVKAR",
                "KRUSHNA RAMBHAU HARGAONKAR",
                "SAI LAXMAN GITTE",
                "SUMIT RANJIT PAWAR"
            };
            
            //System.out.println("📋 Checking duplicate students...\n");
            
            for (String studentName : duplicateStudents) {
                checkAndFixDuplicate(conn, udiseNo, studentName);
            }
            
            //System.out.println("\n=== Fix Complete ===");
            //System.out.println("Please refresh your dashboard to see updated Phase 2 completion percentage.");
            
        } catch (SQLException e) {
            System.err.println("\n✗ DATABASE ERROR:");
            System.err.println("  " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (conn != null) {
                try { conn.close(); } catch (SQLException e) { }
            }
        }
    }
    
    private static void checkAndFixDuplicate(Connection conn, String udiseNo, String studentName) throws SQLException {
        // Find all records for this student
        String query = "SELECT student_id, student_name, student_pen, class, section, " +
                      "phase2_date, is_active " +
                      "FROM students " +
                      "WHERE udise_no = ? AND student_name = ? " +
                      "ORDER BY student_pen DESC, student_id";
        
        PreparedStatement pstmt = conn.prepareStatement(query);
        pstmt.setString(1, udiseNo);
        pstmt.setString(2, studentName);
        ResultSet rs = pstmt.executeQuery();
        
        int recordCount = 0;
        int activeCount = 0;
        Integer keepStudentId = null;
        String keepPen = null;
        
        //System.out.println("Student: " + studentName);
        
        while (rs.next()) {
            recordCount++;
            int studentId = rs.getInt("student_id");
            String pen = rs.getString("student_pen");
            String studentClass = rs.getString("class");
            String section = rs.getString("section");
            java.sql.Timestamp phase2Date = rs.getTimestamp("phase2_date");
            boolean isActive = rs.getBoolean("is_active");
            
            if (isActive) {
                activeCount++;
            }
            
            //System.out.println("  Record " + recordCount + ":");
            //System.out.println("    ID: " + studentId + " | PEN: " + pen + " | Class: " + studentClass + "-" + section);
            //System.out.println("    Active: " + isActive + " | Phase2: " + (phase2Date != null ? "✓ COMPLETED" : "✗ PENDING"));
            
            // Keep the record with real PEN and Phase 2 completed
            if (!pen.startsWith("TEMP") && phase2Date != null && keepStudentId == null) {
                keepStudentId = studentId;
                keepPen = pen;
            } else if (keepStudentId == null && !pen.startsWith("TEMP")) {
                keepStudentId = studentId;
                keepPen = pen;
            } else if (keepStudentId == null) {
                keepStudentId = studentId;
                keepPen = pen;
            }
        }
        rs.close();
        pstmt.close();
        
        if (recordCount > 1) {
            //System.out.println("  ⚠ Found " + recordCount + " records (" + activeCount + " active)");
            //System.out.println("  → Keeping: ID " + keepStudentId + " (PEN: " + keepPen + ")");
            //System.out.println("  → Marking others as INACTIVE...");
            
            // Mark other records as inactive
            String updateSql = "UPDATE students SET is_active = 0 " +
                             "WHERE udise_no = ? AND student_name = ? AND student_id != ?";
            PreparedStatement updatePstmt = conn.prepareStatement(updateSql);
            updatePstmt.setString(1, udiseNo);
            updatePstmt.setString(2, studentName);
            updatePstmt.setInt(3, keepStudentId);
            int updated = updatePstmt.executeUpdate();
            updatePstmt.close();
            
            //System.out.println("  ✓ Marked " + updated + " duplicate record(s) as inactive");
        } else if (recordCount == 1) {
            //System.out.println("  ℹ Only 1 record found - no duplicates");
        } else {
            //System.out.println("  ⚠ Student not found!");
        }
        
        //System.out.println();
    }
}
