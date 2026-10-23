package com.vjnt.servlet;

import com.vjnt.model.VidnyanSetuUser;
import com.vjnt.util.DatabaseConnection;
import org.json.JSONArray;
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
 * GET list of students at the VidnyanSetu Coordinator's school who have been
 * EXPLICITLY SAVED for the given phase (1-4) — backs the "student data"
 * popup opened by clicking a phase card on vidnyansetu-coordinator-dashboard.jsp
 * / vidnyansetu-manage-students.jsp. Includes स्तर निश्चित केला नाही (level 0)
 * rows too, as long as they were actually saved (phase{N}_date IS NOT NULL) —
 * same "explicitly saved" signal vidnyansetu-manage-students.jsp's जतन झाले
 * button state uses. This is a different rule from VidnyanSetuSubmitPhaseServlet's
 * completedStudents count, which only counts level > 0 on purpose.
 */
@WebServlet("/vidnyansetu-phase-students")
public class VidnyanSetuPhaseStudentsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        VidnyanSetuUser coordinator = session == null ? null : (VidnyanSetuUser) session.getAttribute("vsUser");
        if (coordinator == null || coordinator.getRole() != VidnyanSetuUser.Role.COORDINATOR) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print(new JSONArray().toString());
            return;
        }

        int phase;
        try {
            phase = Integer.parseInt(request.getParameter("phase"));
        } catch (NumberFormatException e) {
            phase = -1;
        }
        if (phase < 1 || phase > 4) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print(new JSONArray().toString());
            return;
        }

        String levelCol = "phase" + phase + "_vidnyan";
        String dateCol = "phase" + phase + "_date";
        JSONArray result = new JSONArray();

        String sql =
            "SELECT s.student_pen, s.student_name, s.class, s.section, l." + levelCol + " AS lvl, l." + dateCol + " AS setDate " +
            "FROM students s " +
            "JOIN vidnyansetu_student_levels l ON l.student_id = s.student_id " +
            "WHERE s.is_active = 1 AND s.udise_no = ? AND l." + dateCol + " IS NOT NULL " +
            "ORDER BY s.class, s.section, s.student_name";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, coordinator.getUdiseNo());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    JSONObject s = new JSONObject();
                    s.put("pen", rs.getString("student_pen"));
                    s.put("name", rs.getString("student_name"));
                    s.put("class", rs.getString("class"));
                    s.put("section", rs.getString("section"));
                    s.put("level", rs.getInt("lvl"));
                    s.put("setDate", rs.getTimestamp("setDate") != null ? rs.getTimestamp("setDate").toString() : null);
                    result.put(s);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(new JSONArray().toString());
            return;
        }

        out.print(result.toString());
    }
}
