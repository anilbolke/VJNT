package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.VideoDAO;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@WebServlet("/video-view")
public class VideoViewServlet extends HttpServlet {
    
    private VideoDAO videoDAO = new VideoDAO();
    private Gson gson = new Gson();
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            String videoIdStr = request.getParameter("videoId");
            
            if (videoIdStr == null || videoIdStr.isEmpty()) {
                result.put("success", false);
                result.put("message", "Video ID is required");
                response.getWriter().write(gson.toJson(result));
                return;
            }
            
            int videoId = Integer.parseInt(videoIdStr);
            
            // Get viewer info
            HttpSession session = request.getSession(false);
            Integer studentId = null;
            String viewerName = "Guest";
            
            if (session != null) {
                if (session.getAttribute("studentId") != null) {
                    studentId = (Integer) session.getAttribute("studentId");
                    viewerName = (String) session.getAttribute("studentName");
                } else if (session.getAttribute("userName") != null) {
                    viewerName = (String) session.getAttribute("userName");
                }
            }
            
            // Get IP address
            String ipAddress = request.getRemoteAddr();
            
            // Record view
            boolean viewRecorded = videoDAO.recordVideoView(videoId, studentId, viewerName, ipAddress);
            
            if (viewRecorded) {
                // Increment view count
                videoDAO.incrementViewCount(videoId);
                
                result.put("success", true);
                result.put("message", "View recorded");
            } else {
                result.put("success", false);
                result.put("message", "Failed to record view");
            }
            
        } catch (NumberFormatException e) {
            result.put("success", false);
            result.put("message", "Invalid video ID");
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error: " + e.getMessage());
        }
        
        response.getWriter().write(gson.toJson(result));
    }
}
