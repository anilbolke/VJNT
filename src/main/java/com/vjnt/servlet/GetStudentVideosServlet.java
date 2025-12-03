package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.VideoDAO;
import com.vjnt.model.Video;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Servlet to retrieve videos uploaded by a specific student
 */
@WebServlet("/getStudentVideos")
public class GetStudentVideosServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private VideoDAO videoDAO;
    private Gson gson;

    @Override
    public void init() throws ServletException {
        super.init();
        videoDAO = new VideoDAO();
        gson = new Gson();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Get parameters
            String studentIdStr = request.getParameter("studentId");
            String studentPen = request.getParameter("studentPen");
            
            System.out.println("========== GetStudentVideos Request ==========");
            System.out.println("Student ID: " + studentIdStr);
            System.out.println("Student PEN: " + studentPen);
            
            if (studentIdStr == null || studentIdStr.isEmpty()) {
                result.put("success", false);
                result.put("message", "Student ID is required");
                result.put("videos", new ArrayList<>());
                response.getWriter().write(gson.toJson(result));
                return;
            }
            
            int studentId = Integer.parseInt(studentIdStr);
            
            // Fetch all videos first, then filter by uploadedBy
            List<Video> allVideos = videoDAO.getAllVideos();
            List<Video> studentVideos = new ArrayList<>();
            
            System.out.println("Total videos in database: " + allVideos.size());
            
            // Filter videos uploaded by this student
            for (Video video : allVideos) {
                System.out.println("Checking video: ID=" + video.getVideoId() + 
                                 ", uploadedBy=" + video.getUploadedBy() + 
                                 ", title=" + video.getTitle());
                
                if (video.getUploadedBy() == studentId) {
                    studentVideos.add(video);
                    System.out.println("  -> MATCHED! Added to student videos");
                }
            }
            
            System.out.println("Retrieved " + studentVideos.size() + " videos for student ID: " + studentId);
            System.out.println("============================================");
            
            result.put("success", true);
            result.put("videos", studentVideos);
            result.put("studentId", studentId);
            result.put("studentPen", studentPen);
            result.put("totalVideos", studentVideos.size());
            
        } catch (NumberFormatException e) {
            System.err.println("Error parsing student ID: " + e.getMessage());
            result.put("success", false);
            result.put("message", "Invalid student ID format");
            result.put("videos", new ArrayList<>());
        } catch (Exception e) {
            System.err.println("Error fetching student videos: " + e.getMessage());
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error fetching videos: " + e.getMessage());
            result.put("videos", new ArrayList<>());
        }
        
        response.getWriter().write(gson.toJson(result));
    }
}
