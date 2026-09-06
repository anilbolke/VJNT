package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.json.JSONArray;
import org.json.JSONObject;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

/**
 * District "Teacher Student Videos" activity.
 *
 * GET /district-teacher-videos?teacherId=NN
 *
 * For a District Coordinator (or District 2nd Coordinator), returns the students
 * currently mapped to the given teacher (teacher_student_mapping, the same set
 * the teacher sees in "My Students"), grouped by subject, with every phase video
 * (student_videos where phase_number IS NOT NULL) for each student.
 *
 * The district login only gets: student name, class-section, PEN, and the phase
 * videos (URL, thumbnail, approval status, upload date). No levels / phase data.
 *
 * Scope guard: the teacher must have an active assignment row whose
 * teacher_assignments.district matches the coordinator's district.
 *
 * Note: teacher_student_mapping is populated lazily the first time a teacher
 * opens their dashboard. A teacher who has never logged in returns an empty
 * subject list (the JSP shows an explanatory note).
 */
@WebServlet("/district-teacher-videos")
public class DistrictTeacherVideosServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("user");
        if (user == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"success\":false,\"message\":\"Session expired. Please log in again.\"}");
            return;
        }
        if (user.getUserType() != User.UserType.DISTRICT_COORDINATOR
                && user.getUserType() != User.UserType.DISTRICT_2ND_COORDINATOR) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print("{\"success\":false,\"message\":\"Unauthorized access\"}");
            return;
        }

        int teacherId;
        try {
            teacherId = Integer.parseInt(request.getParameter("teacherId"));
        } catch (NumberFormatException e) {
            out.print("{\"success\":false,\"message\":\"Invalid teacherId\"}");
            return;
        }

        String districtName = user.getDistrictName();
        JSONObject result = new JSONObject();

        try (Connection conn = DatabaseConnection.getConnection()) {

            // 1. Scope + identity check: teacher must belong to this district.
            String teacherName = null;
            String schoolName = null;
            String tSql = "SELECT ta.teacher_name, MIN(s.school_name) AS school_name " +
                          "FROM teacher_assignments ta " +
                          "LEFT JOIN schools s ON ta.udise_code COLLATE utf8mb4_unicode_ci = s.udise_no COLLATE utf8mb4_unicode_ci " +
                          "WHERE ta.teacher_id = ? AND ta.is_active = 1 AND ta.district = ? " +
                          "GROUP BY ta.teacher_name";
            try (PreparedStatement ps = conn.prepareStatement(tSql)) {
                ps.setInt(1, teacherId);
                ps.setString(2, districtName);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        teacherName = rs.getString("teacher_name");
                        schoolName = rs.getString("school_name");
                    }
                }
            }

            if (teacherName == null) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                out.print("{\"success\":false,\"message\":\"Teacher not found in your district\"}");
                return;
            }

            result.put("success", true);
            result.put("teacherId", teacherId);
            result.put("teacherName", teacherName);
            result.put("schoolName", schoolName == null ? "" : schoolName);

            // 2. This teacher's mapped students + their phase videos.
            //    students collation (utf8mb4_0900_ai_ci) differs from
            //    teacher_student_mapping (utf8mb4_unicode_ci) -> COLLATE on the join.
            String sql =
                "SELECT m.subject, s.student_id, s.student_name, s.class, s.section, s.student_pen, " +
                "       v.video_id, v.phase_number, v.approval_status, v.rejection_reason, v.upload_date " +
                "FROM teacher_student_mapping m " +
                "JOIN students s ON m.student_id = s.student_id " +
                "LEFT JOIN student_videos v ON v.student_id = s.student_id " +
                "     AND v.phase_number IS NOT NULL AND v.is_active = 1 " +
                "WHERE m.teacher_id = ? AND m.is_active = 1 AND s.is_active = 1 " +
                "  AND TRIM(m.class) COLLATE utf8mb4_unicode_ci = TRIM(s.class) COLLATE utf8mb4_unicode_ci " +
                "  AND TRIM(m.section) COLLATE utf8mb4_unicode_ci = TRIM(s.section) COLLATE utf8mb4_unicode_ci " +
                "ORDER BY m.subject, s.student_name, s.student_id, v.phase_number";

            // subject -> (studentId -> student JSONObject)
            Map<String, Map<Integer, JSONObject>> bySubject = new LinkedHashMap<>();

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, teacherId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        // Only the three FLN subjects — मराठी / इंग्रजी / गणित.
                        // Any other assigned subject is ignored.
                        String subject = canonicalSubject(rs.getString("subject"));
                        if (subject == null) continue;

                        Map<Integer, JSONObject> students =
                                bySubject.computeIfAbsent(subject, k -> new LinkedHashMap<>());

                        int studentId = rs.getInt("student_id");
                        JSONObject stu = students.get(studentId);
                        if (stu == null) {
                            stu = new JSONObject();
                            stu.put("studentId", studentId);
                            stu.put("name", rs.getString("student_name"));
                            stu.put("class", rs.getString("class") == null ? "" : rs.getString("class"));
                            stu.put("section", rs.getString("section") == null ? "" : rs.getString("section"));
                            stu.put("pen", rs.getString("student_pen") == null ? "" : rs.getString("student_pen"));
                            stu.put("videos", new JSONArray());
                            students.put(studentId, stu);
                        }

                        int videoId = rs.getInt("video_id");
                        if (!rs.wasNull()) {
                            // District login gets only the STATUS of each phase video,
                            // never the video file/URL itself.
                            JSONObject v = new JSONObject();
                            v.put("phase", rs.getInt("phase_number"));
                            v.put("status", rs.getString("approval_status") == null ? "" : rs.getString("approval_status"));
                            v.put("rejectionReason", rs.getString("rejection_reason") == null ? "" : rs.getString("rejection_reason"));
                            v.put("uploadDate", rs.getTimestamp("upload_date") == null ? "" : rs.getTimestamp("upload_date").toString());
                            stu.getJSONArray("videos").put(v);
                        }
                    }
                }
            }

            JSONArray subjects = new JSONArray();
            int totalStudents = 0;
            int totalVideos = 0;
            for (Map.Entry<String, Map<Integer, JSONObject>> e : bySubject.entrySet()) {
                JSONObject subjObj = new JSONObject();
                subjObj.put("subject", e.getKey());
                JSONArray stuArr = new JSONArray();
                for (JSONObject stu : e.getValue().values()) {
                    stuArr.put(stu);
                    totalStudents++;
                    totalVideos += stu.getJSONArray("videos").length();
                }
                subjObj.put("students", stuArr);
                subjObj.put("studentCount", stuArr.length());
                subjects.put(subjObj);
            }

            result.put("subjects", subjects);
            result.put("totalStudents", totalStudents);
            result.put("totalVideos", totalVideos);

        } catch (SQLException e) {
            e.printStackTrace();
            result = new JSONObject();
            result.put("success", false);
            result.put("message", "Database error: " + e.getMessage());
        }

        out.print(result.toString());
        out.flush();
    }

    /**
     * Maps a stored subject value to one of the three FLN subjects
     * (मराठी / इंग्रजी / गणित), accepting Marathi or English spellings.
     * Returns null for any other subject, which the caller then skips.
     */
    private static String canonicalSubject(String subject) {
        if (subject == null) return null;
        String s = subject.trim().toLowerCase();
        if (s.isEmpty()) return null;
        if (s.contains("मराठी") || s.contains("marathi")) return "मराठी";
        if (s.contains("इंग्रजी") || s.contains("इंग्लिश") || s.contains("english")) return "इंग्रजी";
        if (s.contains("गणित") || s.contains("math")) return "गणित";
        return null;
    }
}
