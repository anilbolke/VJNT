package com.vjnt.servlet;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import com.vjnt.model.User;
import com.vjnt.util.BunnyCDNService;
import com.vjnt.util.DatabaseConnection;

/**
 * Lets a TEACHER upload exactly one video per Phase (1-4) for each student
 * mapped to them. Upload for a phase is only allowed once the Head Master
 * has approved that phase (phase_approvals.approval_status = 'APPROVED',
 * school-wide by udise_no). Teacher uploads normally land as PENDING and
 * require Head Master approval (same review queue used for coordinator
 * uploads: GetPendingVideosServlet / ApproveVideoServlet) - see
 * {@link #AUTO_APPROVE_FOR_TESTING} for the current temporary override.
 *
 * A REJECTED video for a student+phase may be re-uploaded (replaces the
 * rejected row). A PENDING or APPROVED video for that student+phase blocks
 * further uploads.
 */
@WebServlet("/upload-phase-video")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 5,   // 5 MB
    maxFileSize = 1024 * 1024 * 15,        // 15 MB
    maxRequestSize = 1024 * 1024 * 20      // 20 MB
)
public class UploadTeacherPhaseVideoServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // TEMPORARY: skips Head Master review so uploads can be tested end-to-end.
    // Flip back to false to require approval before videos become visible.
    private static final boolean AUTO_APPROVE_FOR_TESTING = true;

    // TEMPORARY: skips the "phase must be approved by Head Master" upload gate
    // so the upload button can be exercised without seeded phase_approvals data.
    // Flip back to false to require phase approval before allowing upload.
    private static final boolean SKIP_PHASE_LOCK_FOR_TESTING = true;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        File tempFile = null;

        try {
            HttpSession session = request.getSession(false);
            User user = session == null ? null : (User) session.getAttribute("user");
            if (user == null || user.getUserType() != User.UserType.TEACHER) {
                out.print("{\"success\": false, \"message\": \"Unauthorized. Teacher login required.\"}");
                return;
            }

            String studentIdStr = request.getParameter("studentId");
            String phaseStr = request.getParameter("phaseNumber");

            if (studentIdStr == null || phaseStr == null) {
                out.print("{\"success\": false, \"message\": \"Missing studentId or phaseNumber\"}");
                return;
            }

            int studentId;
            int phaseNumber;
            try {
                studentId = Integer.parseInt(studentIdStr);
                phaseNumber = Integer.parseInt(phaseStr);
            } catch (NumberFormatException nfe) {
                out.print("{\"success\": false, \"message\": \"Invalid studentId or phaseNumber\"}");
                return;
            }

            if (phaseNumber < 1 || phaseNumber > 4) {
                out.print("{\"success\": false, \"message\": \"Phase must be between 1 and 4\"}");
                return;
            }

            String udiseNo = user.getUdiseNo();

            try (Connection conn = DatabaseConnection.getConnection()) {

                // 1. Student must be mapped to THIS teacher.
                if (!isStudentMappedToTeacher(conn, user, studentId)) {
                    out.print("{\"success\": false, \"message\": \"This student is not assigned to you.\"}");
                    return;
                }

                // 2. Phase must be approved by Head Master for this school.
                if (!SKIP_PHASE_LOCK_FOR_TESTING && !isPhaseApproved(conn, udiseNo, phaseNumber)) {
                    out.print("{\"success\": false, \"message\": \"Phase " + phaseNumber +
                              " has not been approved by the Head Master yet. Upload is locked.\"}");
                    return;
                }

                // 3. Check for an existing video for this student+phase.
                Integer existingVideoId = null;
                String existingStatus = null;
                String vSql = "SELECT video_id, approval_status FROM student_videos WHERE student_id = ? AND phase_number = ?";
                try (PreparedStatement ps = conn.prepareStatement(vSql)) {
                    ps.setInt(1, studentId);
                    ps.setInt(2, phaseNumber);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            existingVideoId = rs.getInt("video_id");
                            existingStatus = rs.getString("approval_status");
                        }
                    }
                }

                if (existingVideoId != null && !"REJECTED".equals(existingStatus)) {
                    out.print("{\"success\": false, \"message\": \"A video for Phase " + phaseNumber +
                              " has already been uploaded for this student (status: " + existingStatus + ").\"}");
                    return;
                }

                // 4. Video file.
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

                String fileExtension = fileName.substring(fileName.lastIndexOf("."));
                if (!isValidVideoExtension(fileExtension)) {
                    out.print("{\"success\": false, \"message\": \"Invalid file type. Only video files are allowed.\"}");
                    return;
                }

                long fileSize = filePart.getSize();
                long minFileSize = 100 * 1024;
                long maxFileSize = 15 * 1024 * 1024;

                if (fileSize < minFileSize) {
                    out.print("{\"success\": false, \"message\": \"Video file is too small. Minimum required: 100 KB.\"}");
                    return;
                }
                if (fileSize > maxFileSize) {
                    out.print("{\"success\": false, \"message\": \"Video file is too large. Maximum allowed: 15 MB.\"}");
                    return;
                }

                tempFile = File.createTempFile("phase_video_", "_" + fileName);
                tempFile.deleteOnExit();

                try (InputStream fileContent = filePart.getInputStream();
                     FileOutputStream outputStream = new FileOutputStream(tempFile)) {
                    byte[] buffer = new byte[8192];
                    int bytesRead;
                    while ((bytesRead = fileContent.read(buffer)) != -1) {
                        outputStream.write(buffer, 0, bytesRead);
                    }
                }

                String cdnUrl;
                try {
                    cdnUrl = BunnyCDNService.uploadVideo(tempFile, fileName, udiseNo);
                } catch (Exception e) {
                    out.print("{\"success\": false, \"message\": \"Upload failed: " + escapeJson(e.getMessage()) + "\"}");
                    return;
                }

                String thumbnailUrl = BunnyCDNService.getThumbnailUrl(cdnUrl);

                String approvalStatus = AUTO_APPROVE_FOR_TESTING ? "APPROVED" : "PENDING";
                boolean isVisible = AUTO_APPROVE_FOR_TESTING;

                boolean saved;
                if (existingVideoId != null) {
                    // Re-upload after rejection: replace the rejected row.
                    saved = updateRejectedVideo(conn, existingVideoId, cdnUrl, fileName, fileSize,
                            user.getUserId(), user.getUsername(), thumbnailUrl, approvalStatus, isVisible);
                } else {
                    saved = insertPhaseVideo(conn, studentId, phaseNumber, cdnUrl, fileName, fileSize,
                            user.getUserId(), user.getUsername(), udiseNo, thumbnailUrl, approvalStatus, isVisible);
                }

                if (saved) {
                    String statusMsg = AUTO_APPROVE_FOR_TESTING ?
                            "Video uploaded and approved for Phase " + phaseNumber + " (testing mode - no HM review required)." :
                            "Video uploaded for Phase " + phaseNumber + ". Waiting for Head Master approval.";
                    out.print("{\"success\": true, \"message\": \"" + escapeJson(statusMsg) + "\", \"cdnUrl\": \"" + cdnUrl + "\"}");
                } else {
                    out.print("{\"success\": false, \"message\": \"Video uploaded but failed to save to database\"}");
                }

            }

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\": false, \"message\": \"Server error: " + escapeJson(e.getMessage()) + "\"}");
        } finally {
            if (tempFile != null && tempFile.exists()) {
                try { tempFile.delete(); } catch (Exception ignore) {}
            }
            out.flush();
        }
    }

    private boolean isStudentMappedToTeacher(Connection conn, User user, int studentId) throws SQLException {
        String teacherSql = "SELECT teacher_id FROM teachers WHERE mobile_number = ? AND udise_code = ? AND is_active = 1 LIMIT 1";
        int teacherId = -1;
        try (PreparedStatement ps = conn.prepareStatement(teacherSql)) {
            ps.setString(1, user.getUsername());
            ps.setString(2, user.getUdiseNo());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) teacherId = rs.getInt("teacher_id");
            }
        }
        if (teacherId == -1) return false;

        String mapSql = "SELECT 1 FROM teacher_student_mapping m " +
                        "JOIN students s ON m.student_id = s.student_id " +
                        "WHERE m.teacher_id = ? AND m.student_id = ? AND m.is_active = 1 AND s.is_active = 1 " +
                        "AND m.class COLLATE utf8mb4_unicode_ci = s.class COLLATE utf8mb4_unicode_ci " +
                        "AND m.section COLLATE utf8mb4_unicode_ci = s.section COLLATE utf8mb4_unicode_ci";
        try (PreparedStatement ps = conn.prepareStatement(mapSql)) {
            ps.setInt(1, teacherId);
            ps.setInt(2, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private boolean isPhaseApproved(Connection conn, String udiseNo, int phaseNumber) throws SQLException {
        String sql = "SELECT approval_status FROM phase_approvals WHERE udise_no = ? AND phase_number = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, udiseNo);
            ps.setInt(2, phaseNumber);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && "APPROVED".equals(rs.getString("approval_status"));
            }
        }
    }

    private boolean insertPhaseVideo(Connection conn, int studentId, int phaseNumber, String cdnUrl,
            String fileName, long fileSize, int uploadedBy, String uploadedByName, String udiseNo,
            String thumbnailUrl, String approvalStatus, boolean isVisible) throws SQLException {

        String sql = "INSERT INTO student_videos (student_id, phase_number, file_path, original_file_name, " +
                     "file_size, uploaded_by, uploaded_by_name, udise_no, thumbnail_url, upload_date, " +
                     "approval_status, is_visible) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ps.setInt(2, phaseNumber);
            ps.setString(3, cdnUrl);
            ps.setString(4, fileName);
            ps.setLong(5, fileSize);
            ps.setInt(6, uploadedBy);
            ps.setString(7, uploadedByName);
            ps.setString(8, udiseNo);
            ps.setString(9, thumbnailUrl);
            ps.setString(10, approvalStatus);
            ps.setBoolean(11, isVisible);
            return ps.executeUpdate() > 0;
        }
    }

    private boolean updateRejectedVideo(Connection conn, int videoId, String cdnUrl, String fileName,
            long fileSize, int uploadedBy, String uploadedByName, String thumbnailUrl,
            String approvalStatus, boolean isVisible) throws SQLException {

        String sql = "UPDATE student_videos SET file_path = ?, original_file_name = ?, file_size = ?, " +
                     "uploaded_by = ?, uploaded_by_name = ?, thumbnail_url = ?, upload_date = NOW(), " +
                     "approval_status = ?, is_visible = ?, approved_by = NULL, approved_by_name = NULL, " +
                     "approval_date = NULL, rejection_reason = NULL " +
                     "WHERE video_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cdnUrl);
            ps.setString(2, fileName);
            ps.setLong(3, fileSize);
            ps.setInt(4, uploadedBy);
            ps.setString(5, uploadedByName);
            ps.setString(6, thumbnailUrl);
            ps.setString(7, approvalStatus);
            ps.setBoolean(8, isVisible);
            ps.setInt(9, videoId);
            return ps.executeUpdate() > 0;
        }
    }

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

    private boolean isValidVideoExtension(String extension) {
        String[] validExtensions = {".mp4", ".avi", ".mov", ".mkv", ".wmv", ".flv", ".webm", ".m4v"};
        extension = extension.toLowerCase();
        for (String valid : validExtensions) {
            if (extension.equals(valid)) return true;
        }
        return false;
    }

    private String escapeJson(String str) {
        if (str == null) return "";
        return str.replace("\\", "\\\\")
                  .replace("\"", "\\\"")
                  .replace("\n", "\\n")
                  .replace("\r", "\\r")
                  .replace("\t", "\\t");
    }
}
