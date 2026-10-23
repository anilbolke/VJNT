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

/**
 * VidnyanSetu Coordinator submits a phase (1-4) for Head Master approval —
 * mirrors SubmitPhaseServlet (/submit-phase) for the FLN subjects. "Total
 * students" is every active student at the school (same denominator as
 * vidnyansetu-coordinator-dashboard.jsp's stat cards / phase completion %),
 * not just those covered by a VidnyanSetu teacher assignment — the
 * Coordinator can set a level for any student school-wide.
 */
@WebServlet("/vidnyansetu-submit-phase")
public class VidnyanSetuSubmitPhaseServlet extends HttpServlet {
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
        VidnyanSetuUser coordinator = session == null ? null : (VidnyanSetuUser) session.getAttribute("vsUser");
        if (coordinator == null || coordinator.getRole() != VidnyanSetuUser.Role.COORDINATOR) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            result.put("success", false);
            result.put("message", "Only the VidnyanSetu School Coordinator can submit a phase for approval");
            out.print(result.toString());
            return;
        }

        int phaseNumber;
        try {
            phaseNumber = Integer.parseInt(request.getParameter("phaseNumber"));
        } catch (NumberFormatException e) {
            result.put("success", false);
            result.put("message", "Invalid phase number");
            out.print(result.toString());
            return;
        }
        if (phaseNumber < 1 || phaseNumber > 4) {
            result.put("success", false);
            result.put("message", "Phase must be between 1 and 4");
            out.print(result.toString());
            return;
        }

        String remarks = request.getParameter("remarks");
        String udiseNo = coordinator.getUdiseNo();

        // Gating: block resubmitting a phase that's already pending or approved.
        // Also require the previous phase to be approved before phase N can open
        // (Phase 1 has no prerequisite) — mirrors the dropdown gating in the JSP.
        if (phaseNumber > 1) {
            java.util.Map<String,Object> prev = approvalDAO.getPhaseApproval(udiseNo, phaseNumber - 1);
            boolean prevApproved = prev != null && "APPROVED".equals(prev.get("approvalStatus"));
            if (!prevApproved) {
                result.put("success", false);
                result.put("message", "Phase " + (phaseNumber - 1) + " must be approved before Phase " + phaseNumber + " can be submitted");
                out.print(result.toString());
                return;
            }
        }
        java.util.Map<String,Object> current = approvalDAO.getPhaseApproval(udiseNo, phaseNumber);
        if (current != null && !"REJECTED".equals(current.get("approvalStatus"))) {
            result.put("success", false);
            result.put("message", "Phase " + phaseNumber + " has already been submitted");
            out.print(result.toString());
            return;
        }
        String levelCol = "phase" + phaseNumber + "_vidnyan";

        int totalStudents = 0;
        int completedStudents = 0;
        try (Connection conn = DatabaseConnection.getConnection()) {
            String totalSql = "SELECT COUNT(*) FROM students WHERE is_active = 1 AND udise_no = ?";
            try (PreparedStatement ps = conn.prepareStatement(totalSql)) {
                ps.setString(1, udiseNo);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) totalStudents = rs.getInt(1);
                }
            }

            String completedSql =
                "SELECT COUNT(DISTINCT s.student_id) FROM students s " +
                "JOIN vidnyansetu_student_levels l ON l.student_id = s.student_id " +
                // > 0, not just "IS NOT NULL" — a saved level 0 (स्तर निश्चित केला नाही)
                // still writes phase{N}_date, but that's not an actual level being set.
                "WHERE s.is_active = 1 AND s.udise_no = ? AND l." + levelCol + " > 0";
            try (PreparedStatement ps = conn.prepareStatement(completedSql)) {
                ps.setString(1, udiseNo);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) completedStudents = rs.getInt(1);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Database error: " + e.getMessage());
            out.print(result.toString());
            return;
        }

        int pendingStudents = totalStudents - completedStudents;

        boolean success = approvalDAO.submitPhaseForApproval(udiseNo, phaseNumber, coordinator.getUsername(),
                remarks, totalStudents, completedStudents, pendingStudents);

        result.put("success", success);
        if (success) {
            result.put("message", "Phase " + phaseNumber + " submitted for approval. "
                    + completedStudents + "/" + totalStudents + " students completed.");
        } else {
            result.put("message", "Failed to submit phase for approval");
        }
        out.print(result.toString());
    }
}
