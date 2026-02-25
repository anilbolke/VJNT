package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * Test tool to verify GetPendingVideosServlet logic
 */
public class TestPendingVideosQuery {
    
    public static void main(String[] args) {
        //System.out.println("╔══════════════════════════════════════════════════════════╗");
        //System.out.println("║     TEST PENDING VIDEOS QUERY                            ║");
        //System.out.println("╚══════════════════════════════════════════════════════════╝");
        //System.out.println();
        
        // Test with the UDISE that has pending video
        String testUdise = "27150401803";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            //System.out.println("✓ Database connected\n");
            
            // This is the EXACT query used by GetPendingVideosServlet
            String sql = "SELECT sv.video_id, sv.student_id, s.student_name, s.student_pen, " +
                         "sv.subject, sv.month, sv.has_progress, sv.file_path, sv.thumbnail_url, " +
                         "sv.original_file_name, sv.file_size, sv.uploaded_by, sv.uploaded_by_name, " +
                         "sv.upload_date, sv.approval_status " +
                         "FROM student_videos sv " +
                         "INNER JOIN students s ON sv.student_id = s.student_id " +
                         "WHERE sv.udise_no = ? AND sv.approval_status = 'PENDING' " +
                         "ORDER BY sv.upload_date DESC";
            
            //System.out.println("Testing query with UDISE: " + testUdise);
            //System.out.println();
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, testUdise);
            rs = pstmt.executeQuery();
            
            int count = 0;
            while (rs.next()) {
                count++;
                //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                //System.out.println("  PENDING VIDEO #" + count);
                //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                //System.out.println("  Video ID:       " + rs.getInt("video_id"));
                //System.out.println("  Student ID:     " + rs.getInt("student_id"));
                //System.out.println("  Student Name:   " + rs.getString("student_name"));
                //System.out.println("  Student PEN:    " + rs.getString("student_pen"));
                //System.out.println("  Subject:        " + rs.getString("subject"));
                //System.out.println("  Month:          " + rs.getString("month"));
                //System.out.println("  Has Progress:   " + rs.getString("has_progress"));
                //System.out.println("  File Path:      " + rs.getString("file_path"));
                //System.out.println("  File Name:      " + rs.getString("original_file_name"));
                //System.out.println("  File Size:      " + rs.getLong("file_size") + " bytes");
                //System.out.println("  Uploaded By:    " + rs.getInt("uploaded_by"));
                //System.out.println("  Uploader Name:  " + rs.getString("uploaded_by_name"));
                //System.out.println("  Upload Date:    " + rs.getTimestamp("upload_date"));
                //System.out.println("  Status:         " + rs.getString("approval_status"));
                //System.out.println();
            }
            
            if (count == 0) {
                //System.out.println("✗ NO PENDING VIDEOS FOUND for UDISE: " + testUdise);
                //System.out.println();
                //System.out.println("Possible reasons:");
                //System.out.println("1. Student record doesn't exist in students table");
                //System.out.println("2. student_id mismatch between tables");
                //System.out.println("3. approval_status is not 'PENDING'");
                //System.out.println();
                
                // Check if video exists without JOIN
                //System.out.println("Checking videos without student JOIN...");
                String simpleQuery = "SELECT * FROM student_videos WHERE udise_no = ? AND approval_status = 'PENDING'";
                pstmt = conn.prepareStatement(simpleQuery);
                pstmt.setString(1, testUdise);
                rs = pstmt.executeQuery();
                
                int videoCount = 0;
                while (rs.next()) {
                    videoCount++;
                    //System.out.println("  Video " + videoCount + ": student_id=" + rs.getInt("student_id") + 
                                   //  ", status=" + rs.getString("approval_status"));
                }
                
                if (videoCount > 0) {
                    //System.out.println();
                    //System.out.println("⚠️ ISSUE FOUND: Videos exist but student JOIN is failing!");
                    //System.out.println("   Check if student records exist in students table.");
                }
            } else {
                //System.out.println("✓ SUCCESS: Found " + count + " pending video(s) for Head Master approval");
            }
            
            //System.out.println();
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            //System.out.println("  TEST COMPLETE");
            //System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            //System.out.println();
            
            // Check Head Master users
            //System.out.println("Checking Head Master users...");
            String userQuery = "SELECT user_id, username, udise_no, user_type FROM users WHERE user_type = 'HEAD_MASTER'";
            pstmt = conn.prepareStatement(userQuery);
            rs = pstmt.executeQuery();
            
            //System.out.println();
            while (rs.next()) {
                //System.out.println("  User: " + rs.getString("username") + 
                                // " | UDISE: " + rs.getString("udise_no") + 
                              //   " | Type: " + rs.getString("user_type"));
            }
            
            //System.out.println();
            //System.out.println("IMPORTANT: Head Master must log in with UDISE: " + testUdise);
            //System.out.println("           to see the pending video!");
            
        } catch (Exception e) {
            System.err.println("ERROR: " + e.getMessage());
            e.printStackTrace();
        } finally {
            try {
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
