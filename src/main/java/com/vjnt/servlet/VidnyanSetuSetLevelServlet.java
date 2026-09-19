package com.vjnt.servlet;

import com.vjnt.dao.VidnyanSetuPhaseApprovalDAO;
import com.vjnt.model.VidnyanSetuUser;
import com.vjnt.util.DatabaseConnection;
import org.json.JSONObject;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;

/**
 * Sets/updates a student's विज्ञान level (0-4) for the given phase (1-4) —
 * mirrors students.phase{N}_marathi. Callable by a VidnyanSetu Teacher
 * (student must be in one of their own active vidnyansetu_teacher_assignments)
 * or a VidnyanSetu Coordinator (can set levels for any active student at
 * their own school — no assignment required). The phase must not be
 * read-only (already submitted for approval and not rejected) — same
 * gating as manage-students.jsp / vidnyansetu-manage-students.jsp.
 */
@WebServlet("/vidnyansetu-set-level")
public class VidnyanSetuSetLevelServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final VidnyanSetuPhaseApprovalDAO approvalDAO = new VidnyanSetuPhaseApprovalDAO();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        JSONObject result = new JSONObject();

        HttpSession session = request.getSession(false);
        VidnyanSetuUser caller = session == null ? null : (VidnyanSetuUser) session.getAttribute("vsUser");
        if (caller == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            result.put("success", false);
            result.put("message", "Unauthorized access");
            out.print(result.toString());
            return;
        }
        boolean isCoordinator = caller.getRole() == VidnyanSetuUser.Role.COORDINATOR;

        int studentId, level, phase;
        try {
            studentId = Integer.parseInt(request.getParameter("studentId"));
            level = Integer.parseInt(request.getParameter("level"));
            phase = Integer.parseInt(request.getParameter("phase"));
        } catch (NumberFormatException e) {
            result.put("success", false);
            result.put("message", "Invalid parameters");
            out.print(result.toString());
            return;
        }
        if (level < 0 || level > 4) {
            result.put("success", false);
            result.put("message", "Level must be between 0 and 4");
            out.print(result.toString());
            return;
        }
        if (phase < 1 || phase > 4) {
            result.put("success", false);
            result.put("message", "Invalid phase");
            out.print(result.toString());
            return;
        }

        // Phase gating: read-only once submitted for approval and not rejected.
        Map<String,Object> approval = approvalDAO.getPhaseApproval(caller.getUdiseNo(), phase);
        boolean rejected = approval != null && "REJECTED".equals(approval.get("approvalStatus"));
        if (approval != null && !rejected) {
            result.put("success", false);
            result.put("message", "Phase " + phase + " has already been submitted for approval and is read-only");
            out.print(result.toString());
            return;
        }

        try (Connection conn = DatabaseConnection.getConnection()) {

            // Authorization: a Coordinator may set any active student at their own
            // school; a Teacher only students in one of their own assigned class-sections.
            String checkSql = isCoordinator
                ? "SELECT 1 FROM students s WHERE s.student_id = ? AND s.is_active = 1 AND s.udise_no = ? LIMIT 1"
                : "SELECT 1 FROM students s " +
                  "JOIN vidnyansetu_teacher_assignments a " +
                  "  ON a.udise_code = s.udise_no AND a.class = s.class AND a.section = s.section " +
                  "WHERE s.student_id = ? AND s.is_active = 1 AND a.vs_user_id = ? AND a.is_active = 1 " +
                  "LIMIT 1";
            boolean authorized;
            try (PreparedStatement ps = conn.prepareStatement(checkSql)) {
                ps.setInt(1, studentId);
                if (isCoordinator) {
                    ps.setString(2, caller.getUdiseNo());
                } else {
                    ps.setInt(2, caller.getVsUserId());
                }
                try (ResultSet rs = ps.executeQuery()) {
                    authorized = rs.next();
                }
            }
            if (!authorized) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                result.put("success", false);
                result.put("message", isCoordinator ? "This student is not in your school" : "This student is not in your assigned class/section");
                out.print(result.toString());
                return;
            }

            String levelCol = "phase" + phase + "_vidnyan";
            String dateCol = "phase" + phase + "_date";
            String upsertSql =
                "INSERT INTO vidnyansetu_student_levels (student_id, " + levelCol + ", " + dateCol + ", updated_by) " +
                "VALUES (?, ?, NOW(), ?) " +
                "ON DUPLICATE KEY UPDATE " + levelCol + " = VALUES(" + levelCol + "), "
                + dateCol + " = NOW(), updated_by = VALUES(updated_by)";
            try (PreparedStatement ps = conn.prepareStatement(upsertSql)) {
                ps.setInt(1, studentId);
                ps.setInt(2, level);
                ps.setInt(3, caller.getVsUserId());
                ps.executeUpdate();
            }

            result.put("success", true);
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Database error: " + e.getMessage());
        }

        out.print(result.toString());
    }
}
