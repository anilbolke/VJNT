package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Test Head Master Video View
 * Check what Head Master sees when viewing uploaded videos
 */
public class TestHeadMasterVideoView {
    
    public static void main(String[] args) {
        String udiseNo = "27150401803";
        
        //System.out.println("╔══════════════════════════════════════════════════════════╗");
        //System.out.println("║      HEAD MASTER VIDEO VIEW TEST                         ║");
        //System.out.println("╚══════════════════════════════════════════════════════════╝");
        //System.out.println();
        //System.out.println("UDISE: " + udiseNo);
        //System.out.println();
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            // Test the EXACT query used by Head Master in JSP
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            //System.out.println("  TESTING HEAD MASTER QUERY");
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            //System.out.println();
            
            String headMasterSql = "SELECT v.video_id, v.student_id, s.student_name, s.student_pen, s.class, s.section, " +
                                  "v.subject, v.month, v.has_progress, v.original_file_name, v.file_path, " +
                                  "v.file_size, v.uploaded_by_name, v.upload_date, v.thumbnail_url, " +
                                  "COALESCE(v.approval_status, 'PENDING') as approval_status, v.is_visible " +
                                  "FROM student_videos v " +
                                  "LEFT JOIN students s ON v.student_id = s.student_id " +
                                  "WHERE v.udise_no = ? AND v.is_active = TRUE " +
                                  "ORDER BY v.upload_date DESC";
            
            //System.out.println("Query being executed:");
            //System.out.println(headMasterSql.replace("?", "'" + udiseNo + "'"));
            //System.out.println();
            
            pstmt = conn.prepareStatement(headMasterSql);
            pstmt.setString(1, udiseNo);
            rs = pstmt.executeQuery();
            
            int count = 0;
            //System.out.println("Results:");
            //System.out.println("─────────────────────────────────────────────────────────");
            
            while (rs.next()) {
                count++;
                //System.out.println("Video #" + count + ":");
                //System.out.println("  Video ID: " + rs.getInt("video_id"));
                //System.out.println("  Student: " + rs.getString("student_name"));
                //System.out.println("  Student PEN: " + rs.getString("student_pen"));
                //System.out.println("  Class: " + rs.getString("class"));
                //System.out.println("  Section: " + rs.getString("section"));
                //System.out.println("  Subject: " + rs.getString("subject"));
                //System.out.println("  Month: " + rs.getString("month"));
                //System.out.println("  Has Progress: " + rs.getString("has_progress"));
                //System.out.println("  File Name: " + rs.getString("original_file_name"));
                //System.out.println("  File Path: " + rs.getString("file_path"));
                //System.out.println("  File Size: " + rs.getLong("file_size") + " bytes");
                //System.out.println("  Uploaded By: " + rs.getString("uploaded_by_name"));
                //System.out.println("  Upload Date: " + rs.getTimestamp("upload_date"));
                //System.out.println("  Approval Status: " + rs.getString("approval_status"));
                //System.out.println("  Is Visible: " + rs.getBoolean("is_visible"));
                //System.out.println();
            }
            
            if (count == 0) {
                //System.out.println("⚠ NO VIDEOS RETURNED FROM QUERY!");
                //System.out.println();
                //System.out.println("Checking why...");
                //System.out.println();
                
                // Check if videos exist at all
                String checkSql = "SELECT COUNT(*) as total FROM student_videos WHERE udise_no = ?";
                PreparedStatement checkPstmt = conn.prepareStatement(checkSql);
                checkPstmt.setString(1, udiseNo);
                ResultSet checkRs = checkPstmt.executeQuery();
                
                if (checkRs.next()) {
                    int total = checkRs.getInt("total");
                    //System.out.println("  Total videos in DB for this UDISE: " + total);
                }
                checkRs.close();
                checkPstmt.close();
                
                // Check is_active status
                checkSql = "SELECT COUNT(*) as active FROM student_videos WHERE udise_no = ? AND is_active = TRUE";
                checkPstmt = conn.prepareStatement(checkSql);
                checkPstmt.setString(1, udiseNo);
                checkRs = checkPstmt.executeQuery();
                
                if (checkRs.next()) {
                    int active = checkRs.getInt("active");
                    //System.out.println("  Active videos: " + active);
                }
                checkRs.close();
                checkPstmt.close();
                
                // Check if student exists
                checkSql = "SELECT v.video_id, v.student_id, s.student_id as student_exists " +
                          "FROM student_videos v " +
                          "LEFT JOIN students s ON v.student_id = s.student_id " +
                          "WHERE v.udise_no = ?";
                checkPstmt = conn.prepareStatement(checkSql);
                checkPstmt.setString(1, udiseNo);
                checkRs = checkPstmt.executeQuery();
                
                //System.out.println();
                //System.out.println("  Checking student_id JOIN:");
                while (checkRs.next()) {
                    int videoId = checkRs.getInt("video_id");
                    int studentId = checkRs.getInt("student_id");
                    Object studentExists = checkRs.getObject("student_exists");
                    
                    //System.out.println("    Video ID " + videoId + ": student_id=" + studentId + 
                                    // ", student exists=" + (studentExists != null ? "YES" : "NO"));
                }
                checkRs.close();
                checkPstmt.close();
                
            } else {
                //System.out.println("✓ SUCCESS! Head Master query returned " + count + " video(s)");
                //System.out.println();
                //System.out.println("These videos SHOULD be visible to Head Master in the JSP.");
            }
            
            rs.close();
            pstmt.close();
            
            //System.out.println();
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            //System.out.println("  CONCLUSION");
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            //System.out.println();
            
            if (count > 0) {
                //System.out.println("✓ Query works correctly - videos found!");
                //System.out.println();
                //System.out.println("If Head Master still can't see videos, check:");
                //System.out.println("  1. Is user logged in as HEAD_MASTER user type?");
                //System.out.println("  2. Is JSP file updated on server?");
                //System.out.println("  3. Is Tomcat restarted?");
                //System.out.println("  4. Are there JavaScript errors in browser console?");
            } else {
                //System.out.println("⚠ Query returns no results - this is the problem!");
                //System.out.println();
                //System.out.println("Possible causes:");
                //System.out.println("  1. Video is_active = FALSE");
                //System.out.println("  2. Student record doesn't exist (JOIN fails)");
                //System.out.println("  3. UDISE number mismatch");
            }
            
            //System.out.println();
            //System.out.println("╚══════════════════════════════════════════════════════════╝");
            
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
