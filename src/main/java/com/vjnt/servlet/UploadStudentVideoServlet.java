package com.vjnt.servlet;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.Arrays;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.util.YouTubeUploader;

@WebServlet("/upload-student-video")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 10,  // 10 MB
    maxFileSize = 1024 * 1024 * 100,        // 100 MB
    maxRequestSize = 1024 * 1024 * 150      // 150 MB
)
public class UploadStudentVideoServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    // Video upload directory (relative to application)
    private static final String UPLOAD_DIR = "student_videos";
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = null;
        
        // Wrap ENTIRE method in try-catch to prevent ERR_CONNECTION_RESET
        try {
            out = response.getWriter();
            
            System.out.println("=== Student Video Upload to YouTube Started ===");
            
            // Check session
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("user") == null) {
                out.print("{\"success\": false, \"message\": \"Session expired. Please login again.\"}");
                out.flush();
                return;
            }
            
            User user = (User) session.getAttribute("user");
            File tempFile = null;
            
            try {
            // Get form parameters
            String studentId = request.getParameter("studentId");
            String subject = request.getParameter("subject");
            String month = request.getParameter("month");
            String hasProgress = request.getParameter("hasProgress");
            
            // Validate parameters
            if (studentId == null || subject == null || month == null || hasProgress == null) {
                out.print("{\"success\": false, \"message\": \"Missing required fields\"}");
                return;
            }
            
            // Get student info from database for YouTube title
            String studentName = getStudentName(Integer.parseInt(studentId));
            String studentPen = getStudentPen(Integer.parseInt(studentId));
            
            // Get the video file
            Part filePart = request.getPart("videoFile");
            if (filePart == null || filePart.getSize() == 0) {
                out.print("{\"success\": false, \"message\": \"No video file uploaded\"}");
                return;
            }
            
            String fileName = getFileName(filePart);
            if (fileName == null || fileName.isEmpty()) {
                out.print("{\"success\": false, \"message\": \"Invalid file name\"}");
                return;
            }
            
            // Validate file extension
            String fileExtension = fileName.substring(fileName.lastIndexOf("."));
            if (!isValidVideoExtension(fileExtension)) {
                out.print("{\"success\": false, \"message\": \"Invalid file type. Only video files are allowed.\"}");
                return;
            }
            
            // Validate file size - must be between 1 MB and 10 MB
            long fileSize = filePart.getSize();
            long minFileSize = 1 * 1024 * 1024; // 1 MB
            long maxFileSize = 10 * 1024 * 1024; // 10 MB
            
            double fileSizeMB = fileSize / (1024.0 * 1024.0);
            
            if (fileSize < minFileSize) {
                out.print("{\"success\": false, \"message\": \"Video file is too small. Minimum required: 1 MB. Your file: " + 
                         String.format("%.2f", fileSizeMB) + " MB\"}");
                return;
            }
            
            if (fileSize > maxFileSize) {
                out.print("{\"success\": false, \"message\": \"Video file is too large. Maximum allowed: 10 MB. Your file: " + 
                         String.format("%.2f", fileSizeMB) + " MB\"}");
                return;
            }
            
            System.out.println("Video file size: " + fileSize + " bytes (" + (fileSize / (1024.0 * 1024.0)) + " MB)");
            
            // Create temp file to store upload
            tempFile = File.createTempFile("student_video_", "_" + fileName);
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
            
            // Create YouTube title with student info
            String youtubeTitle = String.format("%s - %s - %s - %s", 
                studentName, subject, month, (hasProgress.equals("yes") ? "Progress" : "No Progress"));
            
            // Create description
            String description = String.format(
                "Student: %s\nPEN: %s\nSubject: %s\nMonth: %s\nProgress: %s\nSchool UDISE: %s\nUploaded by: %s",
                studentName, studentPen, subject, month, hasProgress, user.getUdiseNo(), user.getUsername()
            );
            
            // Prepare tags for YouTube
            List<String> tags = Arrays.asList(subject, month, "Education", "VJNT", "Student Progress", user.getUdiseNo());
            
            System.out.println("YouTube Title: " + youtubeTitle);
            System.out.println("Starting YouTube upload...");
            
            // Upload to YouTube
            String youtubeVideoId;
            try {
                youtubeVideoId = YouTubeUploader.uploadVideo(
                    tempFile, 
                    youtubeTitle, 
                    description, 
                    tags,
                    "27", // Education category
                    "unlisted" // Default to unlisted for student videos
                );
                
                System.out.println("✓ Video uploaded to YouTube: " + youtubeVideoId);
                
            } catch (com.google.api.client.auth.oauth2.TokenResponseException e) {
                // Token has expired or been revoked
                System.err.println("YouTube OAuth token error: " + e.getMessage());
                e.printStackTrace();
                
                // Build helpful error message with solution
                String errorMessage = "YouTube authorization has expired or been revoked. " +
                                    "Please refresh authorization: Open this page in a new tab: " +
                                    request.getContextPath() + "/refresh-youtube-auth and follow the instructions.";
                
                out.print("{\"success\": false, \"message\": \"" + errorMessage + "\", \"authExpired\": true}");
                return;
                
            } catch (Exception e) {
                System.err.println("YouTube upload failed: " + e.getMessage());
                e.printStackTrace();
                
                // Build detailed error message for user (since they don't have server log access)
                StringBuilder errorDetails = new StringBuilder();
                errorDetails.append("Failed to upload to YouTube:\\n\\n");
                errorDetails.append("Error: ").append(e.getMessage()).append("\\n\\n");
                errorDetails.append("Debug Info:\\n");
                errorDetails.append("- Server: Production Cloud Server\\n");
                errorDetails.append("- Time: ").append(new java.util.Date()).append("\\n");
                errorDetails.append("- User: ").append(user.getUsername()).append("\\n\\n");
                
                // Check if credentials exist in classpath
                try {
                    java.io.InputStream credCheck = getClass().getClassLoader()
                        .getResourceAsStream("credentials/StoredCredential");
                    if (credCheck != null) {
                        errorDetails.append("✓ Credentials FOUND in WAR classpath\\n");
                        credCheck.close();
                    } else {
                        errorDetails.append("✗ Credentials NOT FOUND in WAR classpath\\n");
                        errorDetails.append("  WAR needs to be rebuilt with credentials\\n");
                    }
                } catch (Exception ex) {
                    errorDetails.append("✗ Error checking credentials: ").append(ex.getMessage()).append("\\n");
                }
                
                // Check if client_secret.json exists
                try {
                    java.io.InputStream clientSecretCheck = getClass().getClassLoader()
                        .getResourceAsStream("client_secret.json");
                    if (clientSecretCheck != null) {
                        errorDetails.append("✓ client_secret.json found\\n");
                        clientSecretCheck.close();
                    } else {
                        errorDetails.append("✗ client_secret.json NOT found\\n");
                    }
                } catch (Exception ex) {
                    errorDetails.append("✗ Error checking client_secret.json\\n");
                }
                
                errorDetails.append("\\nStack Trace (first 5 lines):\\n");
                StackTraceElement[] stackTrace = e.getStackTrace();
                for (int i = 0; i < Math.min(5, stackTrace.length); i++) {
                    errorDetails.append("  ").append(stackTrace[i].toString()).append("\\n");
                }
                
                out.print("{\"success\": false, \"message\": \"" + errorDetails.toString().replace("\"", "\\\"") + "\"}");
                out.flush();
                return;
            }
            
            // Save to database with YouTube info
            String youtubeUrl = "https://www.youtube.com/watch?v=" + youtubeVideoId;
            String thumbnailUrl = "https://img.youtube.com/vi/" + youtubeVideoId + "/maxresdefault.jpg";
            
            boolean saved = saveVideoToDatabase(
                Integer.parseInt(studentId),
                subject,
                month,
                hasProgress,
                youtubeUrl,
                fileName,
                fileSize,
                user.getUserId(),
                user.getUsername(),
                user.getUdiseNo(),
                youtubeVideoId,
                thumbnailUrl
            );
            
            if (saved) {
                out.print("{\"success\": true, \"message\": \"Video uploaded to YouTube successfully!\", " +
                         "\"youtubeUrl\": \"" + youtubeUrl + "\", \"youtubeId\": \"" + youtubeVideoId + "\"}");
                out.flush();
                System.out.println("✓ Video saved to database with YouTube URL");
            } else {
                out.print("{\"success\": false, \"message\": \"Video uploaded to YouTube but failed to save to database\"}");
                out.flush();
            }
            
            } catch (Exception e) {
                System.err.println("ERROR in video upload: " + e.getMessage());
                e.printStackTrace();
                if (out != null) {
                    out.print("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
                    out.flush();
                }
            } finally {
                // Clean up temp file
                if (tempFile != null && tempFile.exists()) {
                    try {
                        tempFile.delete();
                    } catch (Exception e) {
                        System.err.println("Failed to delete temp file: " + e.getMessage());
                    }
                }
            }
            
        } catch (Exception outerException) {
            // Outer catch to prevent ERR_CONNECTION_RESET
            System.err.println("CRITICAL ERROR in video upload servlet: " + outerException.getMessage());
            outerException.printStackTrace();
            
            try {
                if (out == null) {
                    out = response.getWriter();
                }
                out.print("{\"success\": false, \"message\": \"Server error: " + outerException.getMessage() + "\"}");
                out.flush();
            } catch (Exception e) {
                System.err.println("Failed to send error response: " + e.getMessage());
            }
        } finally {
            // Always close the output stream
            if (out != null) {
                try {
                    out.close();
                } catch (Exception e) {
                    System.err.println("Failed to close output stream: " + e.getMessage());
                }
            }
        }
    }
    
    /**
     * Extract file name from content-disposition header
     */
    private String getFileName(Part part) {
        String contentDisposition = part.getHeader("content-disposition");
        if (contentDisposition != null) {
            for (String content : contentDisposition.split(";")) {
                if (content.trim().startsWith("filename")) {
                    return content.substring(content.indexOf('=') + 1).trim().replace("\"", "");
                }
            }
        }
        return null;
    }
    
    /**
     * Validate video file extension
     */
    private boolean isValidVideoExtension(String extension) {
        String[] validExtensions = {".mp4", ".avi", ".mov", ".mkv", ".wmv", ".flv", ".webm", ".m4v"};
        extension = extension.toLowerCase();
        for (String valid : validExtensions) {
            if (extension.equals(valid)) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Get student name by ID
     */
    private String getStudentName(int studentId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement("SELECT student_name FROM students WHERE student_id = ?");
            pstmt.setInt(1, studentId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getString("student_name");
            }
        } catch (Exception e) {
            System.err.println("Error getting student name: " + e.getMessage());
        } finally {
            try {
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (Exception e) {}
        }
        
        return "Unknown Student";
    }
    
    /**
     * Get student PEN by ID
     */
    private String getStudentPen(int studentId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement("SELECT student_pen FROM students WHERE student_id = ?");
            pstmt.setInt(1, studentId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getString("student_pen");
            }
        } catch (Exception e) {
            System.err.println("Error getting student PEN: " + e.getMessage());
        } finally {
            try {
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (Exception e) {}
        }
        
        return "Unknown";
    }
    
    /**
     * Save video information to database with YouTube URL
     */
    private boolean saveVideoToDatabase(int studentId, String subject, String month, 
                                       String hasProgress, String youtubeUrl, String originalFileName,
                                       long fileSize, int uploadedBy, String uploadedByName,
                                       String udiseNo, String youtubeVideoId, String thumbnailUrl) {
        
        String sql = "INSERT INTO student_videos (student_id, subject, month, has_progress, " +
                     "file_path, original_file_name, file_size, uploaded_by, uploaded_by_name, " +
                     "udise_no, youtube_video_id, thumbnail_url, upload_date) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            
            pstmt.setInt(1, studentId);
            pstmt.setString(2, subject);
            pstmt.setString(3, month);
            pstmt.setString(4, hasProgress);
            pstmt.setString(5, youtubeUrl); // Store YouTube URL instead of local path
            pstmt.setString(6, originalFileName);
            pstmt.setLong(7, fileSize);
            pstmt.setInt(8, uploadedBy);
            pstmt.setString(9, uploadedByName);
            pstmt.setString(10, udiseNo);
            pstmt.setString(11, youtubeVideoId);
            pstmt.setString(12, thumbnailUrl);
            
            int result = pstmt.executeUpdate();
            return result > 0;
            
        } catch (Exception e) {
            System.err.println("Error saving video to database: " + e.getMessage());
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
