package com.vjnt.servlet;

import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.List;

/**
 * Lets a School Coordinator drop a student Excel sheet for Admin review,
 * without touching the database. The file is only ever written to / read
 * from disk here; the actual DB import still happens through the existing
 * "/upload-excel" (ExcelUploadServlet) flow once Admin has manually
 * downloaded and checked the sheet.
 *
 * POST /pending-student-upload           - School Coordinator uploads a sheet
 * GET  /pending-student-upload            - Data Admin lists pending sheets (JSON)
 * GET  /pending-student-upload?action=download&file=... - Data Admin downloads a sheet
 * POST /pending-student-upload  action=delete&file=...   - Data Admin removes a sheet
 */
@WebServlet("/pending-student-upload")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,  // 2MB
    maxFileSize = 1024 * 1024 * 50,       // 50MB
    maxRequestSize = 1024 * 1024 * 60     // 60MB
)
public class PendingStudentUploadServlet extends HttpServlet {

    private static final String SUBDIR = "uploads" + File.separator + "pending-student-sheets";
    private static final String PART_SEP = "__";

    // ------------------------------------------------------------------
    // POST: School Coordinator upload, or Data Admin delete
    // ------------------------------------------------------------------
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("user");
        if (user == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().print("{\"success\": false, \"message\": \"Not authenticated\"}");
            return;
        }

        String action = request.getParameter("action");

        if ("delete".equals(action)) {
            if (user.getUserType() != User.UserType.DATA_ADMIN) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.getWriter().print("{\"success\": false, \"message\": \"Access denied. Only Data Admin can remove pending sheets.\"}");
                return;
            }
            handleDelete(request, response);
            return;
        }

        if (user.getUserType() != User.UserType.SCHOOL_COORDINATOR) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.getWriter().print("{\"success\": false, \"message\": \"Access denied. Only School Coordinator can upload here.\"}");
            return;
        }

        handleUpload(request, response, user);
    }

    private void handleUpload(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException, ServletException {

        String udiseNo = user.getUdiseNo();
        if (udiseNo == null || udiseNo.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().print("{\"success\": false, \"message\": \"No UDISE number on this account.\"}");
            return;
        }

        Part filePart = request.getPart("excelFile");
        if (filePart == null || filePart.getSize() == 0) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().print("{\"success\": false, \"message\": \"Please select a file to upload.\"}");
            return;
        }

        String originalName = getFileName(filePart);
        String lower = originalName.toLowerCase();
        String ext;
        if (lower.endsWith(".xlsx")) {
            ext = ".xlsx";
        } else if (lower.endsWith(".xls")) {
            ext = ".xls";
        } else {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().print("{\"success\": false, \"message\": \"Invalid file type. Please upload an Excel file (.xlsx or .xls)\"}");
            return;
        }

        String schoolName = sanitize(request.getParameter("schoolName"));
        if (schoolName.isEmpty()) schoolName = "School";

        String baseName = sanitize(stripExtension(originalName));
        if (baseName.isEmpty()) baseName = "sheet";

        String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
        String storedName = sanitize(udiseNo) + PART_SEP + schoolName + PART_SEP + timestamp + PART_SEP + baseName + ext;

        File uploadDir = getUploadDir();
        File target = new File(uploadDir, storedName);

        try (InputStream in = filePart.getInputStream();
             OutputStream out = java.nio.file.Files.newOutputStream(target.toPath())) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
        }

        response.getWriter().print("{\"success\": true, \"message\": \"File uploaded. Admin will review and process it.\"}");
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) throws IOException {
        File target = resolveExistingFile(request, response);
        if (target == null) return; // error already written

        if (target.delete()) {
            response.getWriter().print("{\"success\": true, \"message\": \"File removed.\"}");
        } else {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().print("{\"success\": false, \"message\": \"Could not delete file.\"}");
        }
    }

    // ------------------------------------------------------------------
    // GET: Data Admin lists or downloads pending sheets
    // ------------------------------------------------------------------
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("user");
        if (user == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Not authenticated");
            return;
        }
        if (user.getUserType() != User.UserType.DATA_ADMIN) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied. Only Data Admin can view pending sheets.");
            return;
        }

        String action = request.getParameter("action");
        if ("download".equals(action)) {
            handleDownload(request, response);
        } else {
            handleList(request, response);
        }
    }

    private void handleList(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        File uploadDir = getUploadDir();
        File[] files = uploadDir.listFiles(File::isFile);
        List<File> fileList = new ArrayList<>();
        if (files != null) fileList.addAll(Arrays.asList(files));
        fileList.sort(Comparator.comparingLong(File::lastModified).reversed());

        StringBuilder json = new StringBuilder("{\"success\": true, \"files\": [");
        for (int i = 0; i < fileList.size(); i++) {
            File f = fileList.get(i);
            String[] parts = f.getName().split(PART_SEP, 4);
            String udiseNo = parts.length > 0 ? parts[0] : "";
            String schoolName = parts.length > 1 ? parts[1] : "";
            String timestamp = parts.length > 2 ? parts[2] : "";

            if (i > 0) json.append(",");
            json.append("{")
                .append("\"fileName\":\"").append(escapeJson(f.getName())).append("\",")
                .append("\"udiseNo\":\"").append(escapeJson(udiseNo)).append("\",")
                .append("\"schoolName\":\"").append(escapeJson(schoolName)).append("\",")
                .append("\"uploadedAt\":\"").append(escapeJson(formatTimestamp(timestamp))).append("\",")
                .append("\"sizeKb\":").append(Math.max(1, f.length() / 1024))
                .append("}");
        }
        json.append("]}");

        response.getWriter().print(json.toString());
    }

    private void handleDownload(HttpServletRequest request, HttpServletResponse response) throws IOException {
        File target = resolveExistingFile(request, response);
        if (target == null) return; // error already written

        String lower = target.getName().toLowerCase();
        String contentType = lower.endsWith(".xlsx")
                ? "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                : "application/vnd.ms-excel";

        response.setContentType(contentType);
        response.setHeader("Content-Disposition", "attachment; filename=\"" + target.getName().replace("\"", "") + "\"");
        response.setContentLengthLong(target.length());

        try (InputStream in = java.nio.file.Files.newInputStream(target.toPath());
             OutputStream out = response.getOutputStream()) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
        }
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    /**
     * Resolves the "file" request parameter to a file strictly inside the
     * pending-uploads directory, guarding against path traversal. Writes a
     * JSON error to the response and returns null if the file is missing
     * or invalid.
     */
    private File resolveExistingFile(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String fileName = request.getParameter("file");
        if (fileName == null || fileName.isEmpty()
                || fileName.contains("/") || fileName.contains("\\") || fileName.contains("..")) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().print("{\"success\": false, \"message\": \"Invalid file name.\"}");
            return null;
        }

        File uploadDir = getUploadDir();
        File target = new File(uploadDir, fileName);

        File canonicalDir = uploadDir.getCanonicalFile();
        File canonicalTarget = target.getCanonicalFile();
        if (!canonicalTarget.getParentFile().equals(canonicalDir) || !canonicalTarget.isFile()) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            response.getWriter().print("{\"success\": false, \"message\": \"File not found.\"}");
            return null;
        }

        return canonicalTarget;
    }

    private File getUploadDir() {
        File dir = new File(getServletContext().getRealPath("/") + File.separator + SUBDIR);
        if (!dir.exists()) {
            dir.mkdirs();
        }
        return dir;
    }

    private String stripExtension(String name) {
        int dot = name.lastIndexOf('.');
        return dot > 0 ? name.substring(0, dot) : name;
    }

    private String sanitize(String s) {
        if (s == null) return "";
        return s.trim().replaceAll("[^a-zA-Z0-9\\-]", "_");
    }

    private String formatTimestamp(String stamp) {
        try {
            Date d = new SimpleDateFormat("yyyyMMdd_HHmmss").parse(stamp);
            return new SimpleDateFormat("dd-MMM-yyyy hh:mm a").format(d);
        } catch (Exception e) {
            return stamp;
        }
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private String getFileName(Part part) {
        String contentDisposition = part.getHeader("content-disposition");
        String[] tokens = contentDisposition.split(";");
        for (String token : tokens) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf("=") + 2, token.length() - 1);
            }
        }
        return "";
    }
}
