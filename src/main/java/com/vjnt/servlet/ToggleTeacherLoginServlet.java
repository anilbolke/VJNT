package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

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
 * Enables or disables an existing teacher's portal login, from the
 * "Enable / Disable" button on manage-teachers.jsp.
 *
 * POST /toggle-teacher-login   params: teacherId, enable ("true" | "false")
 *
 * Flips users.is_active for the teacher's login row (username = mobile number,
 * user_type = 'TEACHER'). A disabled login cannot authenticate (UserDAO checks
 * is_active) but the row and password are kept, so re-enabling restores the
 * same credentials. School Coordinators may only act on teachers of their own
 * school; Super Division Officers on any.
 */
@WebServlet("/toggle-teacher-login")
public class ToggleTeacherLoginServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("user");
        if (user == null || (user.getUserType() != User.UserType.SCHOOL_COORDINATOR
                && user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"success\":false,\"message\":\"Unauthorized access\"}");
            return;
        }

        JSONObject result = new JSONObject();

        int teacherId;
        try {
            teacherId = Integer.parseInt(request.getParameter("teacherId"));
        } catch (NumberFormatException e) {
            result.put("success", false);
            result.put("message", "Invalid teacherId");
            out.print(result.toString());
            return;
        }
        boolean enable = "true".equalsIgnoreCase(request.getParameter("enable"));

        try (Connection conn = DatabaseConnection.getConnection()) {

            // 1. Load the teacher
            String teacherName = null, mobile = null, teacherUdise = null;
            String tSql = "SELECT teacher_name, mobile_number, udise_code FROM teachers " +
                          "WHERE teacher_id = ? AND is_active = 1";
            try (PreparedStatement ps = conn.prepareStatement(tSql)) {
                ps.setInt(1, teacherId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        teacherName = rs.getString("teacher_name");
                        mobile = rs.getString("mobile_number");
                        teacherUdise = rs.getString("udise_code");
                    }
                }
            }
            if (mobile == null) {
                result.put("success", false);
                result.put("message", "Teacher not found");
                out.print(result.toString());
                return;
            }

            // School coordinator may only act on teachers of their own school
            if (user.getUserType() == User.UserType.SCHOOL_COORDINATOR
                    && (user.getUdiseNo() == null || !user.getUdiseNo().equals(teacherUdise))) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                result.put("success", false);
                result.put("message", "This teacher belongs to another school");
                out.print(result.toString());
                return;
            }

            // 2. Find the login row (username = mobile)
            int userId = -1;
            String existingType = null;
            boolean currentlyActive = false;
            String uSql = "SELECT user_id, user_type, is_active FROM users WHERE username = ? LIMIT 1";
            try (PreparedStatement ps = conn.prepareStatement(uSql)) {
                ps.setString(1, mobile);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        userId = rs.getInt("user_id");
                        existingType = rs.getString("user_type");
                        currentlyActive = rs.getBoolean("is_active");
                    }
                }
            }
            if (userId == -1) {
                result.put("success", false);
                result.put("message", "No login exists for this teacher. Create one first.");
                out.print(result.toString());
                return;
            }
            if (!"TEACHER".equals(existingType)) {
                result.put("success", false);
                result.put("message", "Mobile " + mobile + " belongs to a " + existingType
                        + " account and cannot be changed here.");
                out.print(result.toString());
                return;
            }
            if (currentlyActive == enable) {
                result.put("success", true);
                result.put("active", enable);
                result.put("message", "Login is already " + (enable ? "enabled" : "disabled"));
                out.print(result.toString());
                return;
            }

            // 3. Flip is_active; also clear an account lock when re-enabling
            String updSql = enable
                    ? "UPDATE users SET is_active = 1, account_locked = 0, failed_login_attempts = 0 WHERE user_id = ?"
                    : "UPDATE users SET is_active = 0 WHERE user_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(updSql)) {
                ps.setInt(1, userId);
                int rows = ps.executeUpdate();
                if (rows > 0) {
                    result.put("success", true);
                    result.put("active", enable);
                    result.put("message", "Login " + (enable ? "enabled" : "disabled")
                            + " for " + teacherName);
                } else {
                    result.put("success", false);
                    result.put("message", "Update failed");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Database error: " + e.getMessage());
        }

        out.print(result.toString());
        out.flush();
    }
}
