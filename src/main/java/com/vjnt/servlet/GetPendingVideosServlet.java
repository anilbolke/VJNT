package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
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
 * Servlet to get pending videos for headmaster approval
 */
@WebServlet("/get-pending-videos")
public class GetPendingVideosServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private Gson gson = new Gson();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
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
            
            // Only headmasters can view pending videos
            if (user.getUserType() != User.UserType.HEAD_MASTER && user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
                result.put("success", false);
                result.put("message", "Access denied. Only headmasters can approve videos.");
                out.print(gson.toJson(result));
                return;
            }
            
            String udiseNo = user.getUdiseNo();
            
            // Get pending videos for this school
            List<Map<String, Object>> pendingVideos = getPendingVideos(udiseNo);
            
            result.put("success", true);
            result.put("videos", pendingVideos);
            result.put("count", pendingVideos.size());
            
            out.print(gson.toJson(result));
            
        } catch (Exception e) {
            System.err.println("Error fetching pending videos: " + e.getMessage());
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error: " + e.getMessage());
            out.print(gson.toJson(result));
        }
    }
    
    /**
     * Get all pending videos for a school
     */
    private List<Map<String, Object>> getPendingVideos(String udiseNo) {
        List<Map<String, Object>> videos = new ArrayList<>();
        
        String sql = "SELECT sv.video_id, sv.student_id, s.student_name, s.student_pen, " +
                     "sv.subject, sv.month, sv.phase_number, sv.has_progress, sv.file_path, sv.thumbnail_url, " +
                     "sv.original_file_name, sv.file_size, sv.uploaded_by, sv.uploaded_by_name, " +
                     "sv.upload_date, sv.approval_status " +
                     "FROM student_videos sv " +
                     "INNER JOIN students s ON sv.student_id = s.student_id " +
                     "WHERE sv.udise_no = ? AND sv.approval_status = 'PENDING' " +
                     "ORDER BY sv.upload_date DESC";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, udiseNo);
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> video = new HashMap<>();
                video.put("videoId", rs.getInt("video_id"));
                video.put("studentId", rs.getInt("student_id"));
                video.put("studentName", rs.getString("student_name"));
                video.put("studentPen", rs.getString("student_pen"));
                video.put("subject", rs.getString("subject"));
                video.put("month", rs.getString("month"));
                int phaseNumber = rs.getInt("phase_number");
                video.put("phaseNumber", rs.wasNull() ? null : phaseNumber);
                video.put("hasProgress", rs.getString("has_progress"));
                video.put("filePath", rs.getString("file_path"));
                video.put("thumbnailUrl", rs.getString("thumbnail_url"));
                video.put("originalFileName", rs.getString("original_file_name"));
                video.put("fileSize", rs.getLong("file_size"));
                video.put("uploadedBy", rs.getInt("uploaded_by"));
                video.put("uploadedByName", rs.getString("uploaded_by_name"));
                video.put("uploadDate", rs.getTimestamp("upload_date").toString());
                video.put("approvalStatus", rs.getString("approval_status"));
                
                videos.add(video);
            }
            
            
        } catch (Exception e) {
            System.err.println("Error querying pending videos: " + e.getMessage());
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
        
        return videos;
    }
}

