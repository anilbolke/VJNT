package com.vjnt.servlet;

import java.io.IOException;
import java.io.InputStream;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;
import java.sql.*;

@WebServlet("/student-activity")
@MultipartConfig(maxFileSize = 5 * 1024 * 1024)
public class StudentActivityServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        User user = (User) request.getSession().getAttribute("user");
        if (user == null) { response.sendRedirect("login.jsp"); return; }

        String userType = user.getUserType().toString();
        boolean canWrite = userType.equals("SCHOOL_COORDINATOR") || userType.equals("HEAD_MASTER") || userType.equals("DATA_ADMIN");
        if (!canWrite) { response.sendRedirect("login.jsp"); return; }

        String action = request.getParameter("action");

        if ("delete".equals(action)) {
            handleDelete(request, response, user);
            return;
        }

        // ── Save new activity ──────────────────────────────────────────────
        String studentPen   = request.getParameter("student_pen");
        String studentName  = request.getParameter("student_name");
        String udiseNo      = request.getParameter("udise_no");
        String studentClass = request.getParameter("student_class");
        String activityType = request.getParameter("activity_type");
        String activityName = request.getParameter("activity_name");
        String activityDate = request.getParameter("activity_date");
        String description  = request.getParameter("description");
        String achievement  = request.getParameter("achievement");
        String compLevel    = request.getParameter("competition_level");

        // Scope guard: coordinator can only add for their school
        if (userType.equals("SCHOOL_COORDINATOR") || userType.equals("HEAD_MASTER")) {
            if (user.getUdiseNo() != null && !user.getUdiseNo().equals(udiseNo)) {
                response.sendRedirect("student-activity.jsp?error=unauthorized");
                return;
            }
        }

        // Photo
        byte[] photoBytes = null;
        String photoFilename = null;
        String photoContentType = null;
        try {
            Part photoPart = request.getPart("photo");
            if (photoPart != null && photoPart.getSize() > 0) {
                photoFilename    = getFilename(photoPart);
                photoContentType = photoPart.getContentType();
                try (InputStream is = photoPart.getInputStream()) {
                    photoBytes = is.readAllBytes();
                }
            }
        } catch (Exception ex) { /* no photo */ }

        try (Connection conn = DatabaseConnection.getConnection()) {
            String sql = "INSERT INTO student_activities " +
                "(student_pen, student_name, udise_no, student_class, " +
                " activity_type, activity_name, activity_date, description, " +
                " achievement, competition_level, " +
                " photo_content, photo_filename, photo_content_type, created_by) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, studentPen);
                ps.setString(2, studentName);
                ps.setString(3, udiseNo);
                ps.setString(4, studentClass);
                ps.setString(5, activityType);
                ps.setString(6, activityName);
                ps.setDate(7, activityDate != null && !activityDate.isEmpty() ? java.sql.Date.valueOf(activityDate) : null);
                ps.setString(8, description);
                ps.setString(9, achievement);
                ps.setString(10, compLevel);
                if (photoBytes != null) {
                    ps.setBytes(11, photoBytes);
                    ps.setString(12, photoFilename);
                    ps.setString(13, photoContentType);
                } else {
                    ps.setNull(11, Types.BLOB);
                    ps.setNull(12, Types.VARCHAR);
                    ps.setNull(13, Types.VARCHAR);
                }
                ps.setString(14, user.getUsername());
                ps.executeUpdate();
            }
            response.sendRedirect("student-activity.jsp?success=1&udise=" + udiseNo);
        } catch (Exception ex) {
            ex.printStackTrace();
            response.sendRedirect("student-activity.jsp?error=" + java.net.URLEncoder.encode(ex.getMessage(), "UTF-8"));
        }
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException {
        String idStr   = request.getParameter("activity_id");
        String udise   = request.getParameter("udise_no");
        String userType = user.getUserType().toString();
        try {
            int id = Integer.parseInt(idStr);
            try (Connection conn = DatabaseConnection.getConnection()) {
                String sql = "DELETE FROM student_activities WHERE activity_id=?";
                if (userType.equals("SCHOOL_COORDINATOR") || userType.equals("HEAD_MASTER")) {
                    sql += " AND udise_no=?";
                }
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, id);
                    if (userType.equals("SCHOOL_COORDINATOR") || userType.equals("HEAD_MASTER")) {
                        ps.setString(2, user.getUdiseNo());
                    }
                    ps.executeUpdate();
                }
            }
            response.sendRedirect("student-activity.jsp?success=deleted&udise=" + (udise != null ? udise : ""));
        } catch (Exception ex) {
            response.sendRedirect("student-activity.jsp?error=" + java.net.URLEncoder.encode(ex.getMessage(), "UTF-8"));
        }
    }

    // ── GET: serve photo ──────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        User user = (User) request.getSession().getAttribute("user");
        if (user == null) { response.sendError(401); return; }

        String idStr = request.getParameter("photo");
        if (idStr == null) { response.sendError(400); return; }

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT photo_content, photo_content_type, photo_filename FROM student_activities WHERE activity_id=?")) {
            ps.setInt(1, Integer.parseInt(idStr));
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                byte[] data = rs.getBytes("photo_content");
                String ct   = rs.getString("photo_content_type");
                String fn   = rs.getString("photo_filename");
                if (data != null && data.length > 0) {
                    response.setContentType(ct != null ? ct : "image/jpeg");
                    response.setHeader("Content-Disposition", "inline; filename=\"" + (fn != null ? fn : "photo.jpg") + "\"");
                    response.setContentLength(data.length);
                    response.getOutputStream().write(data);
                    return;
                }
            }
            response.sendError(404);
        } catch (Exception ex) {
            response.sendError(500);
        }
    }

    private String getFilename(Part part) {
        String cd = part.getHeader("content-disposition");
        if (cd == null) return "photo.jpg";
        for (String token : cd.split(";")) {
            token = token.trim();
            if (token.startsWith("filename")) {
                return token.substring(token.indexOf('=') + 1).trim().replace("\"", "");
            }
        }
        return "photo.jpg";
    }
}
