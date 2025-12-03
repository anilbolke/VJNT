package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.VideoDAO;
import com.vjnt.model.Video;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.BufferedReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@WebServlet("/save-video")
public class SaveVideoServlet extends HttpServlet {
    
    private VideoDAO videoDAO = new VideoDAO();
    private Gson gson = new Gson();
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Read JSON from request body
            BufferedReader reader = request.getReader();
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
            
            // Parse JSON to Map
            @SuppressWarnings("unchecked")
            Map<String, String> videoData = gson.fromJson(sb.toString(), Map.class);
            
            // Validate required fields
            if (videoData.get("youtubeVideoId") == null || videoData.get("title") == null) {
                result.put("success", false);
                result.put("message", "Required fields missing");
                response.getWriter().write(gson.toJson(result));
                return;
            }
            
            // Create Video object
            Video video = new Video();
            video.setTitle(videoData.get("title"));
            video.setDescription(videoData.get("description"));
            video.setYoutubeVideoId(videoData.get("youtubeVideoId"));
            video.setYoutubeUrl(videoData.get("youtubeUrl"));
            video.setThumbnailUrl(videoData.get("thumbnailUrl"));
            video.setCategory(videoData.get("category"));
            video.setSubCategory(videoData.get("subCategory"));
            video.setStatus("active");
            
            // Get uploader info from session
            HttpSession session = request.getSession(false);
            if (session != null && session.getAttribute("userId") != null) {
                video.setUploadedBy((Integer) session.getAttribute("userId"));
                video.setUploaderName((String) session.getAttribute("userName"));
            } else {
                video.setUploadedBy(0);
                video.setUploaderName("Anonymous");
            }
            
            // Save to database
            boolean saved = videoDAO.saveVideo(video);
            
            if (saved) {
                result.put("success", true);
                result.put("message", "Video added successfully");
                result.put("videoId", video.getVideoId());
            } else {
                result.put("success", false);
                result.put("message", "Failed to save video");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error: " + e.getMessage());
        }
        
        response.getWriter().write(gson.toJson(result));
    }
}
