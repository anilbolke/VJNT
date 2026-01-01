package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;
import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

/**
 * Servlet for headmasters to approve or reject videos
 */
@WebServlet("/approve-video")
public class ApproveVideoServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private Gson gson = new Gson();
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Check session and authorization
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("user") == null) {
                result.put("success", false);
                result.put("message", "Session expired. Please login again.");
                out.print(gson.toJson(result));
                return;
            }
            
            User user = (User) session.getAttribute("user");
            
            // Only headmasters can approve videos
            if (user.getUserType() != User.UserType.HEAD_MASTER) {
                result.put("success", false);
                result.put("message", "Access denied. Only headmasters can approve videos.");
                out.print(gson.toJson(result));
                return;
            }
            
            // Get parameters
            String videoIdStr = request.getParameter("videoId");
            String action = request.getParameter("action"); // "approve" or "reject"
            String rejectionReason = request.getParameter("rejectionReason");
            
            if (videoIdStr == null || action == null) {
                result.put("success", false);
                result.put("message", "Missing required parameters");
                out.print(gson.toJson(result));
                return;
            }
            
            int videoId = Integer.parseInt(videoIdStr);
            
            if ("reject".equals(action) && (rejectionReason == null || rejectionReason.trim().isEmpty())) {
                result.put("success", false);
                result.put("message", "Rejection reason is required");
                out.print(gson.toJson(result));
                return;
            }
            
            System.out.println("Video approval request - Video ID: " + videoId + ", Action: " + action + 
                             ", By: " + user.getUsername());
            
            // Process approval/rejection
            boolean success = false;
            String message = "";
            
            if ("approve".equals(action)) {
                success = approveVideo(videoId, user.getUserId(), user.getUsername());
                message = success ? "Video approved successfully" : "Failed to approve video";
            } else if ("reject".equals(action)) {
                success = rejectVideo(videoId, user.getUserId(), user.getUsername(), rejectionReason);
                message = success ? "Video rejected successfully" : "Failed to reject video";
            } else {
                result.put("success", false);
                result.put("message", "Invalid action. Use 'approve' or 'reject'");
                out.print(gson.toJson(result));
                return;
            }
            
            result.put("success", success);
            result.put("message", message);
            out.print(gson.toJson(result));
            
        } catch (Exception e) {
            System.err.println("Error processing video approval: " + e.getMessage());
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error: " + e.getMessage());
            out.print(gson.toJson(result));
        }
    }
    
    /**
     * Approve a video
     */
    private boolean approveVideo(int videoId, int approvedBy, String approvedByName) {
        String sql = "UPDATE student_videos SET " +
                     "approval_status = 'APPROVED', " +
                     "is_visible = TRUE, " +
                     "approved_by = ?, " +
                     "approved_by_name = ?, " +
                     "approval_date = ? " +
                     "WHERE video_id = ? AND approval_status = 'PENDING'";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            
            pstmt.setInt(1, approvedBy);
            pstmt.setString(2, approvedByName);
            pstmt.setTimestamp(3, new Timestamp(System.currentTimeMillis()));
            pstmt.setInt(4, videoId);
            
            int rowsAffected = pstmt.executeUpdate();
            
            if (rowsAffected > 0) {
                System.out.println("Video " + videoId + " approved by " + approvedByName);
                return true;
            } else {
                System.err.println("No pending video found with ID: " + videoId);
                return false;
            }
            
        } catch (Exception e) {
            System.err.println("Error approving video: " + e.getMessage());
            e.printStackTrace();
            return false;
        } finally {
            try {
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
    
    /**
     * Reject a video
     */
    private boolean rejectVideo(int videoId, int rejectedBy, String rejectedByName, String rejectionReason) {
        String sql = "UPDATE student_videos SET " +
                     "approval_status = 'REJECTED', " +
                     "is_visible = FALSE, " +
                     "approved_by = ?, " +
                     "approved_by_name = ?, " +
                     "approval_date = ?, " +
                     "rejection_reason = ? " +
                     "WHERE video_id = ? AND approval_status = 'PENDING'";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            
            pstmt.setInt(1, rejectedBy);
            pstmt.setString(2, rejectedByName);
            pstmt.setTimestamp(3, new Timestamp(System.currentTimeMillis()));
            pstmt.setString(4, rejectionReason);
            pstmt.setInt(5, videoId);
            
            int rowsAffected = pstmt.executeUpdate();
            
            if (rowsAffected > 0) {
                System.out.println("Video " + videoId + " rejected by " + rejectedByName + 
                                 ". Reason: " + rejectionReason);
                return true;
            } else {
                System.err.println("No pending video found with ID: " + videoId);
                return false;
            }
            
        } catch (Exception e) {
            System.err.println("Error rejecting video: " + e.getMessage());
            e.printStackTrace();
            return false;
        } finally {
            try {
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
