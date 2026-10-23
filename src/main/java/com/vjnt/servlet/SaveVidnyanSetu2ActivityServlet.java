package com.vjnt.servlet;

import com.vjnt.dao.VidnyanSetu2ActivityDAO;
import com.vjnt.model.User;
import com.vjnt.model.VidnyanSetuUser;
import com.vjnt.util.BunnyCDNService;
import org.json.JSONObject;

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
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;

/**
 * Saves (POST) and lists (GET) VidnyanSetu 2 STEM activities — see
 * vidnyansetu2-activity.jsp for the Class -> Activity form that posts here.
 *
 * Same rules as SaveVidnyanSetuActivityServlet (video mandatory, uploaded to
 * Bunny CDN, VS Teacher limited to their own class-sections, saved PENDING
 * for Head Master approval), plus: class must be VI..IX, and the activity
 * name is taken from vidnyansetu2_activity_master, not from the request.
 */
@WebServlet("/save-vidnyansetu2-activity")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 10,   // 10 MB
    maxFileSize = 1024 * 1024 * 100,        // 100 MB per video
    maxRequestSize = 1024 * 1024 * 110      // 110 MB
)
public class SaveVidnyanSetu2ActivityServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final VidnyanSetu2ActivityDAO activityDAO = new VidnyanSetu2ActivityDAO();

    private static final long MIN_VIDEO_SIZE = 100 * 1024;             // 100 KB
    private static final long MAX_VIDEO_SIZE = 100L * 1024 * 1024;     // 100 MB
    private static final String[] VALID_VIDEO_EXT = {".mp4", ".avi", ".mov", ".mkv", ".wmv", ".flv", ".webm", ".m4v"};

    private static boolean canWrite(User user, VidnyanSetuUser vsUser) {
        if (user != null) {
            return user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) ||
                   user.getUserType().equals(User.UserType.HEAD_MASTER) ||
                   user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER) ||
                   user.getUserType().equals(User.UserType.DATA_ADMIN);
        }
        return vsUser != null;
    }

    /** For a VS Teacher, the class-section must be one of their active assignments. Others are unrestricted. */
    private static boolean isClassAllowed(VidnyanSetuUser vsUser, String studentClass, String studentSection) {
        if (vsUser == null || vsUser.getRole() != VidnyanSetuUser.Role.TEACHER) return true;
        if (studentSection == null) return false;
        String sql = "SELECT 1 FROM vidnyansetu_teacher_assignments WHERE vs_user_id = ? AND class = ? AND section = ? AND is_active = 1 LIMIT 1";
        try (java.sql.Connection conn = com.vjnt.util.DatabaseConnection.getConnection();
             java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, vsUser.getVsUserId());
            ps.setString(2, studentClass);
            ps.setString(3, studentSection);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (java.sql.SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    private static String udiseOf(User user, VidnyanSetuUser vsUser) {
        return user != null ? user.getUdiseNo() : (vsUser != null ? vsUser.getUdiseNo() : null);
    }

    private static String displayNameOf(User user, VidnyanSetuUser vsUser) {
        if (user != null) return user.getFullName() != null ? user.getFullName() : user.getUsername();
        return vsUser != null ? (vsUser.getFullName() != null ? vsUser.getFullName() : vsUser.getUsername()) : null;
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        VidnyanSetuUser vsUser = (session != null) ? (VidnyanSetuUser) session.getAttribute("vsUser") : null;

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        JSONObject result = new JSONObject();

        if (!canWrite(user, vsUser)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            result.put("success", false);
            result.put("message", "Unauthorized");
            out.print(result.toString());
            return;
        }

        File tempFile = null;
        try {
            String studentClass = required(request, "studentClass").toUpperCase();
            String studentSection = request.getParameter("studentSection");
            studentSection = (studentSection == null || studentSection.trim().isEmpty()) ? null : studentSection.trim();

            if (!VidnyanSetu2ActivityDAO.isAllowedClass(studentClass)) {
                result.put("success", false);
                result.put("message", "विज्ञानसेतू 2 फक्त इयत्ता VI, VII, VIII, IX साठी आहे.");
                out.print(result.toString());
                return;
            }
            if (!isClassAllowed(vsUser, studentClass, studentSection)) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                result.put("success", false);
                result.put("message", "You are not assigned to class " + studentClass
                        + (studentSection != null ? "-" + studentSection : " (section missing)"));
                out.print(result.toString());
                return;
            }

            int activityNo = Integer.parseInt(required(request, "activityNo"));
            String activityName = activityDAO.getMasterName(activityNo);
            if (activityName == null) {
                result.put("success", false);
                result.put("message", "अवैध उपक्रम निवडला आहे.");
                out.print(result.toString());
                return;
            }
            String activityDate = required(request, "activityDate");

            // ── Video: mandatory ──
            Part videoPart = request.getPart("video");
            if (videoPart == null || videoPart.getSize() == 0) {
                result.put("success", false);
                result.put("message", "व्हिडिओ अनिवार्य आहे. कृपया उपक्रमाचा व्हिडिओ जोडा. (Video is mandatory.)");
                out.print(result.toString());
                return;
            }

            String fileName = getFileName(videoPart);
            if (fileName == null || fileName.isEmpty() || fileName.lastIndexOf('.') < 0) {
                result.put("success", false);
                result.put("message", "अवैध व्हिडिओ फाईल नाव.");
                out.print(result.toString());
                return;
            }
            String ext = fileName.substring(fileName.lastIndexOf('.')).toLowerCase();
            if (!isValidVideoExtension(ext)) {
                result.put("success", false);
                result.put("message", "अवैध फाईल प्रकार. फक्त व्हिडिओ फाईल्स (mp4, mov, avi, mkv, webm...) परवानगी आहेत.");
                out.print(result.toString());
                return;
            }
            long videoSize = videoPart.getSize();
            if (videoSize < MIN_VIDEO_SIZE) {
                result.put("success", false);
                result.put("message", "व्हिडिओ फाईल खूप लहान आहे (किमान 100 KB आवश्यक).");
                out.print(result.toString());
                return;
            }
            if (videoSize > MAX_VIDEO_SIZE) {
                result.put("success", false);
                result.put("message", "व्हिडिओ फाईल खूप मोठी आहे (कमाल 100 MB).");
                out.print(result.toString());
                return;
            }

            tempFile = File.createTempFile("vidnyansetu2_video_", "_" + fileName);
            try (InputStream is = videoPart.getInputStream();
                 FileOutputStream fos = new FileOutputStream(tempFile)) {
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = is.read(buffer)) != -1) {
                    fos.write(buffer, 0, bytesRead);
                }
            }

            String udiseNo = udiseOf(user, vsUser);
            String cdnUrl;
            try {
                cdnUrl = BunnyCDNService.uploadVideo(tempFile, fileName, udiseNo);
            } catch (Exception e) {
                e.printStackTrace();
                result.put("success", false);
                result.put("message", "व्हिडिओ अपलोड अयशस्वी: " + e.getMessage());
                out.print(result.toString());
                return;
            }

            VidnyanSetu2ActivityDAO.NewActivity a = new VidnyanSetu2ActivityDAO.NewActivity();
            a.udiseNo = udiseNo;
            a.studentClass = studentClass;
            a.studentSection = studentSection;
            a.activityNo = activityNo;
            a.activityName = activityName;
            a.activityDate = activityDate;
            a.description = request.getParameter("description");
            a.createdBy = displayNameOf(user, vsUser);
            a.videoUrl = cdnUrl;
            a.videoFilename = fileName;
            a.videoSize = videoSize;
            a.videoThumbnailUrl = BunnyCDNService.getThumbnailUrl(cdnUrl);

            boolean success = activityDAO.saveActivity(a);
            result.put("success", success);
            if (success) {
                result.put("videoUrl", cdnUrl);
            } else {
                result.put("message", "Failed to save activity");
            }

        } catch (IllegalArgumentException e) {
            result.put("success", false);
            result.put("message", e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error: " + e.getMessage());
        } finally {
            if (tempFile != null && tempFile.exists()) {
                try { tempFile.delete(); } catch (Exception ignore) { }
            }
        }

        out.print(result.toString());
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        VidnyanSetuUser vsUser = (session != null) ? (VidnyanSetuUser) session.getAttribute("vsUser") : null;
        if (user == null && vsUser == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        try {
            List<Map<String, Object>> activities;
            if (vsUser != null && vsUser.getRole() == VidnyanSetuUser.Role.TEACHER) {
                activities = activityDAO.getActivitiesBySchoolForClassSections(udiseOf(user, vsUser), assignedClassSections(vsUser), 100);
            } else {
                activities = activityDAO.getActivitiesBySchool(udiseOf(user, vsUser), 100);
            }
            out.print(new org.json.JSONArray(activities).toString());
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("[]");
        }
    }

    /** {class, section} pairs a VS Teacher is actively assigned to (see isClassAllowed). */
    private static java.util.List<String[]> assignedClassSections(VidnyanSetuUser vsUser) {
        java.util.List<String[]> out = new java.util.ArrayList<>();
        String sql = "SELECT DISTINCT class, section FROM vidnyansetu_teacher_assignments WHERE vs_user_id = ? AND is_active = 1";
        try (java.sql.Connection conn = com.vjnt.util.DatabaseConnection.getConnection();
             java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, vsUser.getVsUserId());
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(new String[]{ rs.getString("class"), rs.getString("section") });
            }
        } catch (java.sql.SQLException e) {
            e.printStackTrace();
        }
        return out;
    }

    private static String required(HttpServletRequest request, String name) {
        String v = request.getParameter(name);
        if (v == null || v.trim().isEmpty()) {
            throw new IllegalArgumentException("Missing required parameter: " + name);
        }
        return v.trim();
    }

    private static String getFileName(Part part) {
        String cd = part.getHeader("content-disposition");
        if (cd != null) {
            for (String token : cd.split(";")) {
                if (token.trim().startsWith("filename")) {
                    return token.substring(token.indexOf('=') + 1).trim().replace("\"", "");
                }
            }
        }
        return null;
    }

    private static boolean isValidVideoExtension(String ext) {
        for (String v : VALID_VIDEO_EXT) if (v.equals(ext)) return true;
        return false;
    }
}
