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
        
        // Wrap entire method in try-catch to prevent 502 errors
        try {
            
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
            
            if (title.length() > 100) {
                title = title.substring(0, 100); // YouTube title max length is 100 chars
            }
            
            
            // Get uploaded file
            Part filePart = request.getPart("videoFile");
            if (filePart == null || filePart.getSize() == 0) {
                result.put("success", false);
                result.put("message", "Please select a video file");
                response.getWriter().write(gson.toJson(result));
                return;
            }
            
            // Validate file size - minimum 10 MB required
            long fileSize = filePart.getSize();
            long minFileSize = 10 * 1024 * 1024; // 10 MB in bytes
            
            if (fileSize < minFileSize) {
                double fileSizeMB = fileSize / (1024.0 * 1024.0);
                result.put("success", false);
                result.put("message", String.format("Video file is too small. Minimum required size is 10 MB. Your file is %.2f MB", fileSizeMB));
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
                
                
            } catch (com.google.api.client.auth.oauth2.TokenResponseException e) {
                // Token has expired or been revoked
                System.err.println("YouTube OAuth token error: " + e.getMessage());
                e.printStackTrace();
                
                // Clear expired credentials to force re-authorization
                YouTubeUploader.clearCredentials();
                
                result.put("success", false);
                result.put("message", "YouTube authorization has expired. Please try uploading again - a new browser window will open for re-authorization.");
                result.put("errorType", "AUTH_EXPIRED");
                response.getWriter().write(gson.toJson(result));
                return;
                
            } catch (Exception e) {
                e.printStackTrace();
                result.put("success", false);
                result.put("message", "Failed to upload to YouTube: " + e.getMessage());
                response.getWriter().write(gson.toJson(result));
                return;
            } finally {
                // Delete temp file
                if (tempFile.exists()) {
                    tempFile.delete();
                }
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
                    //System.out.println("No student specified, using logged-in user: " + uploadedByStudentId);
                }
            }
            
            video.setUploadedBy(uploadedByStudentId);
            video.setUploaderName(uploaderName);
            
            //System.out.println("Video will be saved with uploadedBy=" + uploadedByStudentId + ", uploaderName=" + uploaderName);
            
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
        
        } catch (Throwable t) {
            // Catch ALL errors including OutOfMemoryError, etc. to prevent 502
            System.err.println("!!! CRITICAL ERROR in YouTube Upload Servlet !!!");
            t.printStackTrace();
            
            result.clear();
            result.put("success", false);
            
            // Provide specific error messages based on error type
            String errorMessage = t.getMessage();
            if (errorMessage == null) {
                errorMessage = "Unknown error: " + t.getClass().getSimpleName();
            }
            
            // Check for common issues
            if (errorMessage.contains("client_secret.json")) {
                result.put("message", "YouTube API not configured. Missing client_secret.json file. Please contact administrator.");
                result.put("errorType", "CONFIG_MISSING");
            } else if (errorMessage.contains("Address already in use")) {
                result.put("message", "YouTube authentication server is busy. Please try again in a few moments.");
                result.put("errorType", "PORT_CONFLICT");
            } else if (errorMessage.contains("OutOfMemory")) {
                result.put("message", "Video file is too large. Maximum size is 500MB. Please reduce file size and try again.");
                result.put("errorType", "FILE_TOO_LARGE");
            } else if (errorMessage.contains("Connection")) {
                result.put("message", "Network connection error. Please check your internet connection and try again.");
                result.put("errorType", "NETWORK_ERROR");
            } else {
                result.put("message", "Upload failed: " + errorMessage);
                result.put("errorType", "UNKNOWN");
            }
            
            try {
                response.setStatus(HttpServletResponse.SC_OK); // Send 200 with error details instead of 502
                response.getWriter().write(gson.toJson(result));
            } catch (IOException ioe) {
                // Last resort - at least log it
                System.err.println("Failed to send error response: " + ioe.getMessage());
            }
        }
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
