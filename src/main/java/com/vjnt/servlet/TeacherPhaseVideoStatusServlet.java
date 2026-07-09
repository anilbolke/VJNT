package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.json.JSONObject;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

/**
 * Returns, for the logged-in TEACHER, the school-wide Phase 1-4 approval
 * status (from phase_approvals) and the phase-video status (none / PENDING /
 * APPROVED / REJECTED) for every student mapped to this teacher.
 *
 * The dashboard uses this to decide, per student and per phase, whether the
 * upload control is locked (phase not yet approved by Head Master), open
 * (approved, no video yet), pending review, approved, or rejected.
 */
@WebServlet("/teacher-phase-video-status")
public class TeacherPhaseVideoStatusServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("user");
        if (user == null || user.getUserType() != User.UserType.TEACHER) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"error\": \"Unauthorized access\"}");
            return;
        }

        JSONObject result = new JSONObject();
        String udise = user.getUdiseNo();

        try (Connection conn = DatabaseConnection.getConnection()) {

            // 1. School-wide phase approval status (1-4), same table Head Master uses.
            JSONObject phaseApprovals = new JSONObject();
            String paSql = "SELECT phase_number, approval_status FROM phase_approvals WHERE udise_no = ?";
            try (PreparedStatement ps = conn.prepareStatement(paSql)) {
                ps.setString(1, udise);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        phaseApprovals.put(String.valueOf(rs.getInt("phase_number")), rs.getString("approval_status"));
                    }
                }
            }
            result.put("phaseApprovals", phaseApprovals);

            // 2. Resolve teacher_id (same lookup as TeacherMyStudentsServlet).
            int teacherId = -1;
            String teacherSql = "SELECT teacher_id FROM teachers WHERE mobile_number = ? AND udise_code = ? AND is_active = 1 LIMIT 1";
            try (PreparedStatement ps = conn.prepareStatement(teacherSql)) {
                ps.setString(1, user.getUsername());
                ps.setString(2, udise);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) teacherId = rs.getInt("teacher_id");
                }
            }

            if (teacherId == -1) {
                result.put("error", "Teacher record not found for this login.");
                out.print(result.toString());
                return;
            }

            // 3. This teacher's mapped student IDs.
            List<Integer> studentIds = new ArrayList<>();
            String mapSql = "SELECT m.student_id FROM teacher_student_mapping m " +
                            "JOIN students s ON m.student_id = s.student_id " +
                            "WHERE m.teacher_id = ? AND m.is_active = 1 AND s.is_active = 1 " +
                            "AND m.class COLLATE utf8mb4_unicode_ci = s.class COLLATE utf8mb4_unicode_ci " +
                            "AND m.section COLLATE utf8mb4_unicode_ci = s.section COLLATE utf8mb4_unicode_ci";
            try (PreparedStatement ps = conn.prepareStatement(mapSql)) {
                ps.setInt(1, teacherId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) studentIds.add(rs.getInt("student_id"));
                }
            }

            // 4. Existing phase-video rows for those students.
            JSONObject videos = new JSONObject();
            if (!studentIds.isEmpty()) {
                StringBuilder placeholders = new StringBuilder();
                for (int i = 0; i < studentIds.size(); i++) {
                    if (i > 0) placeholders.append(",");
                    placeholders.append("?");
                }
                String vSql = "SELECT video_id, student_id, phase_number, approval_status, rejection_reason, " +
                             "upload_date, original_file_name, file_path, thumbnail_url " +
                             "FROM student_videos WHERE student_id IN (" + placeholders + ") AND phase_number IS NOT NULL";
                try (PreparedStatement ps = conn.prepareStatement(vSql)) {
                    for (int i = 0; i < studentIds.size(); i++) {
                        ps.setInt(i + 1, studentIds.get(i));
                    }
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            String studentKey = String.valueOf(rs.getInt("student_id"));
                            JSONObject studentPhases = videos.has(studentKey) ? videos.getJSONObject(studentKey) : new JSONObject();

                            JSONObject v = new JSONObject();
                            v.put("videoId", rs.getInt("video_id"));
                            v.put("approvalStatus", rs.getString("approval_status"));
                            v.put("rejectionReason", rs.getString("rejection_reason") == null ? "" : rs.getString("rejection_reason"));
                            v.put("uploadDate", rs.getTimestamp("upload_date") == null ? "" : rs.getTimestamp("upload_date").toString());
                            v.put("fileName", rs.getString("original_file_name"));
                            v.put("filePath", rs.getString("file_path"));
                            v.put("thumbnailUrl", rs.getString("thumbnail_url"));

                            studentPhases.put(String.valueOf(rs.getInt("phase_number")), v);
                            videos.put(studentKey, studentPhases);
                        }
                    }
                }
            }
            result.put("videos", videos);

        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }

        out.print(result.toString());
        out.flush();
    }
}
