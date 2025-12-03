package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.VideoDAO;
import com.vjnt.model.Video;
import com.vjnt.util.YouTubeUploader;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Servlet to handle video upload to YouTube
 * Uploads video file directly to YouTube channel and saves metadata to database
 */
@WebServlet("/upload-to-youtube")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 10,  // 10 MB
    maxFileSize = 1024 * 1024 * 500,        // 500 MB
    maxRequestSize = 1024 * 1024 * 600      // 600 MB
)
public class UploadVideoToYouTubeServlet extends HttpServlet {
    
    private VideoDAO videoDAO = new VideoDAO();
    private Gson gson = new Gson();
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Get form parameters
            String title = request.getParameter("title");
            String description = request.getParameter("description");
            String category = request.getParameter("category");
            String subCategory = request.getParameter("subCategory");
            String udiseNo = request.getParameter("udiseNo");
            String studentPen = request.getParameter("studentPen");
            String studentIdStr = request.getParameter("studentId");
            String privacyStatus = request.getParameter("privacyStatus"); // public, private, unlisted
            
            // Log received parameters for debugging
            System.out.println("========== Upload Video Request ==========");
            System.out.println("Raw Title: [" + title + "]");
            System.out.println("Title null: " + (title == null));
            System.out.println("Title length: " + (title != null ? title.length() : 0));
            System.out.println("Description: " + description);
            System.out.println("Category: " + category);
            System.out.println("SubCategory: " + subCategory);
            System.out.println("Student ID: " + studentIdStr);
            System.out.println("Student PEN: " + studentPen);
            System.out.println("Privacy: " + privacyStatus);
            System.out.println("==========================================");
            
            // Validate required fields
            if (title == null || title.trim().isEmpty()) {
                result.put("success", false);
                result.put("message", "Title is required");
                System.err.println("ERROR: Title validation failed - title is null or empty");
                response.getWriter().write(gson.toJson(result));
                return;
            }
            
            // Clean and validate title
            title = title.trim();
            System.out.println("Trimmed Title: [" + title + "]");
            System.out.println("Trimmed Title length: " + title.length());
            
            if (title.length() > 100) {
                title = title.substring(0, 100); // YouTube title max length is 100 chars
            }
            
            System.out.println("Final Title for upload: [" + title + "]");
            
            // Get uploaded file
            Part filePart = request.getPart("videoFile");
            if (filePart == null || filePart.getSize() == 0) {
                result.put("success", false);
                result.put("message", "Please select a video file");
                response.getWriter().write(gson.toJson(result));
                return;
            }
            
            // Get filename
            String fileName = getFileName(filePart);
            if (!isValidVideoFile(fileName)) {
                result.put("success", false);
                result.put("message", "Invalid video format. Supported: MP4, AVI, MOV, WMV, FLV");
                response.getWriter().write(gson.toJson(result));
                return;
            }
            
            // Create temp file to store upload
            File tempFile = File.createTempFile("video_upload_", "_" + fileName);
            tempFile.deleteOnExit();
            
            // Save uploaded file to temp location
            try (InputStream fileContent = filePart.getInputStream();
                 FileOutputStream outputStream = new FileOutputStream(tempFile)) {
                
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = fileContent.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
                }
            }
            
            System.out.println("File saved to temp: " + tempFile.getAbsolutePath());
            System.out.println("File size: " + tempFile.length() + " bytes");
            
            // Prepare tags for YouTube
            List<String> tags = Arrays.asList(category, subCategory, "Education", "VJNT");
            
            // Upload to YouTube
            String youtubeVideoId;
            try {
                youtubeVideoId = YouTubeUploader.uploadVideo(
                    tempFile, 
                    title, 
                    description != null ? description : "", 
                    tags,
                    "27", // Education category
                    privacyStatus != null ? privacyStatus : "unlisted"
                );
                
                System.out.println("Video uploaded to YouTube: " + youtubeVideoId);
                
            } catch (Exception e) {
                e.printStackTrace();
                result.put("success", false);
                result.put("message", "Failed to upload to YouTube: " + e.getMessage());
                response.getWriter().write(gson.toJson(result));
                return;
            } finally {
                // Delete temp file
                tempFile.delete();
            }
            
            // Save video info to database
            Video video = new Video();
            video.setTitle(title);
            video.setDescription(description);
            video.setYoutubeVideoId(youtubeVideoId);
            video.setYoutubeUrl("https://www.youtube.com/watch?v=" + youtubeVideoId);
            video.setThumbnailUrl("https://img.youtube.com/vi/" + youtubeVideoId + "/maxresdefault.jpg");
            video.setCategory(category);
            video.setSubCategory(subCategory);
            video.setStatus("active");
            
            // Map video to student
            // Priority: studentId > studentPen lookup
            int uploadedByStudentId = 0;
            String uploaderName = "System";
            
            if (studentIdStr != null && !studentIdStr.isEmpty()) {
                try {
                    uploadedByStudentId = Integer.parseInt(studentIdStr);
                    System.out.println("Video will be mapped to student ID: " + uploadedByStudentId);
                } catch (NumberFormatException e) {
                    System.err.println("Invalid student ID: " + studentIdStr);
                }
            } else if (studentPen != null && !studentPen.isEmpty()) {
                // Try to look up student ID by PEN
                try {
                    com.vjnt.dao.StudentDAO studentDAO = new com.vjnt.dao.StudentDAO();
                    com.vjnt.model.Student student = studentDAO.getStudentByPen(studentPen);
                    if (student != null) {
                        uploadedByStudentId = student.getStudentId();
                        uploaderName = student.getStudentName();
                        System.out.println("Found student by PEN: " + studentPen + " -> ID: " + uploadedByStudentId);
                    }
                } catch (Exception e) {
                    System.err.println("Error looking up student by PEN: " + e.getMessage());
                }
            }
            
            // If no student found, fall back to logged-in user
            if (uploadedByStudentId == 0) {
                HttpSession session = request.getSession(false);
                if (session != null && session.getAttribute("userId") != null) {
                    uploadedByStudentId = (Integer) session.getAttribute("userId");
                    uploaderName = (String) session.getAttribute("userName");
                    System.out.println("No student specified, using logged-in user: " + uploadedByStudentId);
                }
            }
            
            video.setUploadedBy(uploadedByStudentId);
            video.setUploaderName(uploaderName);
            
            System.out.println("Video will be saved with uploadedBy=" + uploadedByStudentId + ", uploaderName=" + uploaderName);
            
            // Save to database
            boolean saved = videoDAO.saveVideo(video);
            
            if (saved) {
                // If UDISE or Student PEN provided, create assignment
                if ((udiseNo != null && !udiseNo.trim().isEmpty()) || 
                    (studentPen != null && !studentPen.trim().isEmpty())) {
                    
                    // TODO: Create video assignment record
                    // This would link video to specific school or student
                }
                
                result.put("success", true);
                result.put("message", "Video uploaded successfully to YouTube!");
                result.put("videoId", video.getVideoId());
                result.put("youtubeVideoId", youtubeVideoId);
                result.put("youtubeUrl", video.getYoutubeUrl());
                result.put("thumbnailUrl", video.getThumbnailUrl());
                
            } else {
                result.put("success", false);
                result.put("message", "Video uploaded to YouTube but failed to save to database");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error: " + e.getMessage());
        }
        
        response.getWriter().write(gson.toJson(result));
    }
    
    /**
     * Extract filename from content-disposition header
     */
    private String getFileName(Part part) {
        String contentDisp = part.getHeader("content-disposition");
        String[] tokens = contentDisp.split(";");
        for (String token : tokens) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf("=") + 2, token.length() - 1);
            }
        }
        return "";
    }
    
    /**
     * Validate video file extension
     */
    private boolean isValidVideoFile(String fileName) {
        String[] validExtensions = {".mp4", ".avi", ".mov", ".wmv", ".flv", ".mkv", ".webm"};
        String lowerFileName = fileName.toLowerCase();
        for (String ext : validExtensions) {
            if (lowerFileName.endsWith(ext)) {
                return true;
            }
        }
        return false;
    }
}
