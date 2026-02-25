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
import java.util.Date;
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
import com.vjnt.util.BunnyCDNService;

@WebServlet("/upload-student-video")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 5,   // 5 MB
    maxFileSize = 1024 * 1024 * 15,         // 15 MB
    maxRequestSize = 1024 * 1024 * 20       // 20 MB
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
                System.err.println("Missing required fields - studentId: " + studentId + ", subject: " + subject + ", month: " + month);
                out.print("{\"success\": false, \"message\": \"Missing required fields\"}");
                return;
            }
            
            
            // Get student info from database for YouTube title
            String studentName = getStudentName(Integer.parseInt(studentId));
            String studentPen = getStudentPen(Integer.parseInt(studentId));
            
            // Get the video file
            Part filePart = request.getPart("videoFile");
            if (filePart == null || filePart.getSize() == 0) {
                System.err.println("No video file uploaded in request");
                out.print("{\"success\": false, \"message\": \"No video file uploaded\"}");
                return;
            }
            
            String fileName = getFileName(filePart);
            if (fileName == null || fileName.isEmpty()) {
                System.err.println("Invalid or missing filename");
                out.print("{\"success\": false, \"message\": \"Invalid file name\"}");
                return;
            }
            
            
            // Validate file extension
            String fileExtension = fileName.substring(fileName.lastIndexOf("."));
            if (!isValidVideoExtension(fileExtension)) {
                System.err.println("Invalid file extension: " + fileExtension);
                out.print("{\"success\": false, \"message\": \"Invalid file type. Only video files are allowed.\"}");
                return;
            }
            
            // Validate file size - must be between 100 KB and 15 MB
            long fileSize = filePart.getSize();
            long minFileSize = 100 * 1024; // 100 KB
            long maxFileSize = 15 * 1024 * 1024; // 15 MB
            
            double fileSizeMB = fileSize / (1024.0 * 1024.0);
            double fileSizeKB = fileSize / 1024.0;
            
            if (fileSize < minFileSize) {
                out.print("{\"success\": false, \"message\": \"Video file is too small. Minimum required: 100 KB. Your file: " + 
                         String.format("%.2f", fileSizeKB) + " KB\"}");
                return;
            }
            
            if (fileSize > maxFileSize) {
                out.print("{\"success\": false, \"message\": \"Video file is too large. Maximum allowed: 15 MB. Your file: " + 
                         String.format("%.2f", fileSizeMB) + " MB\"}");
                return;
            }
            
            String fileSizeDisplay = fileSizeMB >= 1 ? String.format("%.2f MB", fileSizeMB) : String.format("%.2f KB", fileSizeKB);
            
            // Create temp file to store upload
            tempFile = File.createTempFile("student_video_", "_" + fileName);
            tempFile.deleteOnExit();
            
            //System.out.println("Created temp file: " + tempFile.getAbsolutePath());
            
            // Save uploaded file to temp location
            try (InputStream fileContent = filePart.getInputStream();
                 FileOutputStream outputStream = new FileOutputStream(tempFile)) {
                
                byte[] buffer = new byte[8192];
                int bytesRead;
                long totalBytesWritten = 0;
                while ((bytesRead = fileContent.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
                    totalBytesWritten += bytesRead;
                }
                
            }
            
            
            // Upload to Bunny CDN
            String cdnUrl;
            
            try {
                cdnUrl = BunnyCDNService.uploadVideo(tempFile, fileName, user.getUdiseNo());
                
            } catch (Exception e) {
                System.err.println("Bunny CDN upload failed: " + e.getMessage());
                e.printStackTrace();
                
                String errorMessage = "Upload failed: " + e.getMessage();
                out.print("{\"success\": false, \"message\": \"" + escapeJson(errorMessage) + "\"}");
                return;
            }
            
            // Generate thumbnail URL
            String thumbnailUrl = BunnyCDNService.getThumbnailUrl(cdnUrl);
            
            
            // Determine approval status based on user role
            String approvalStatus = "PENDING";
            boolean isVisible = false;
            
            if (user.getUserType() == User.UserType.HEAD_MASTER) {
                // Headmaster uploads are auto-approved
                approvalStatus = "APPROVED";
                isVisible = true;
            } else if (user.getUserType() == User.UserType.SCHOOL_COORDINATOR) {
                // School coordinator uploads need approval
                approvalStatus = "PENDING";
                isVisible = false;
            }
            
            boolean saved = saveVideoToDatabase(
                Integer.parseInt(studentId),
                subject,
                month,
                hasProgress,
                cdnUrl,
                fileName,
                fileSize,
                user.getUserId(),
                user.getUsername(),
                user.getUdiseNo(),
                null, // No YouTube video ID for Bunny CDN
                thumbnailUrl,
                approvalStatus,
                isVisible,
                user.getUserType() == User.UserType.HEAD_MASTER ? user.getUserId() : null,
                user.getUserType() == User.UserType.HEAD_MASTER ? user.getUsername() : null
            );
            
            if (saved) {
                out.print("{\"success\": true, \"message\": \"Video uploaded to Bunny CDN successfully!\", " +
                         "\"cdnUrl\": \"" + cdnUrl + "\", \"thumbnailUrl\": \"" + thumbnailUrl + "\"}");
                out.flush();
            } else {
                System.err.println("Failed to save video info to database");
                out.print("{\"success\": false, \"message\": \"Video uploaded but failed to save to database\"}");
                out.flush();
            }
            
            } catch (Exception e) {
                System.err.println("ERROR in video upload: " + e.getMessage());
                e.printStackTrace();
                if (out != null) {
                    out.print("{\"success\": false, \"message\": \"Error: " + escapeJson(e.getMessage()) + "\"}");
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
                out.print("{\"success\": false, \"message\": \"Server error: " + escapeJson(outerException.getMessage()) + "\"}");
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
     * Escape special characters for JSON string
     */
    private String escapeJson(String str) {
        if (str == null) {
            return "";
        }
        return str.replace("\\", "\\\\")
                  .replace("\"", "\\\"")
                  .replace("\n", "\\n")
                  .replace("\r", "\\r")
                  .replace("\t", "\\t")
                  .replace("\b", "\\b")
                  .replace("\f", "\\f");
    }
    
    /**
     * Save video information to database with approval status
     */
    private boolean saveVideoToDatabase(int studentId, String subject, String month, 
                                       String hasProgress, String youtubeUrl, String originalFileName,
                                       long fileSize, int uploadedBy, String uploadedByName,
                                       String udiseNo, String youtubeVideoId, String thumbnailUrl,
                                       String approvalStatus, boolean isVisible,
                                       Integer approvedBy, String approvedByName) {
        
        String sql = "INSERT INTO student_videos (student_id, subject, month, has_progress, " +
                     "file_path, original_file_name, file_size, uploaded_by, uploaded_by_name, " +
                     "udise_no, youtube_video_id, thumbnail_url, upload_date, " +
                     "approval_status, is_visible, approved_by, approved_by_name, approval_date) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, ?, ?, ?, " +
                     "CASE WHEN ? = 'APPROVED' THEN NOW() ELSE NULL END)";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            
            pstmt.setInt(1, studentId);
            pstmt.setString(2, subject);
            pstmt.setString(3, month);
            pstmt.setString(4, hasProgress);
            pstmt.setString(5, youtubeUrl); // Store CDN URL
            pstmt.setString(6, originalFileName);
            pstmt.setLong(7, fileSize);
            pstmt.setInt(8, uploadedBy);
            pstmt.setString(9, uploadedByName);
            pstmt.setString(10, udiseNo);
            pstmt.setString(11, youtubeVideoId);
            pstmt.setString(12, thumbnailUrl);
            pstmt.setString(13, approvalStatus);
            pstmt.setBoolean(14, isVisible);
            
            if (approvedBy != null) {
                pstmt.setInt(15, approvedBy);
            } else {
                pstmt.setNull(15, java.sql.Types.INTEGER);
            }
            
            pstmt.setString(16, approvedByName);
            pstmt.setString(17, approvalStatus); // For the CASE statement
            
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
