package com.vjnt.servlet;

import com.vjnt.dao.VidnyanSetuUserDAO;
import com.vjnt.model.VidnyanSetuUser;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.util.PasswordUtil;
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
import java.sql.SQLException;

/**
 * VidnyanSetu Coordinator adds a VidnyanSetu Teacher: creates a vidnyansetu_users
 * login (role TEACHER, username = mobile) + a vidnyansetu_teacher_assignments
 * row for the chosen class/section. Mirrors AddTeacherServlet's flow for the
 * main portal, but writes to the separate vidnyansetu_* tables.
 */
@WebServlet("/vidnyansetu-add-teacher")
public class VidnyanSetuAddTeacherServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final VidnyanSetuUserDAO vsUserDAO = new VidnyanSetuUserDAO();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        JSONObject result = new JSONObject();

        HttpSession session = request.getSession(false);
        VidnyanSetuUser coordinator = session == null ? null : (VidnyanSetuUser) session.getAttribute("vsUser");
        if (coordinator == null || coordinator.getRole() != VidnyanSetuUser.Role.COORDINATOR) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            result.put("success", false);
            result.put("message", "Unauthorized access");
            out.print(result.toString());
            return;
        }

        String teacherName = request.getParameter("teacherName");
        String mobile = request.getParameter("mobile");
        String cls = request.getParameter("class");
        String section = request.getParameter("section");

        if (teacherName == null || teacherName.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "Teacher name is required");
            out.print(result.toString());
            return;
        }
        if (mobile == null || !mobile.matches("\\d{10}")) {
            result.put("success", false);
            result.put("message", "Valid 10-digit mobile number is required");
            out.print(result.toString());
            return;
        }
        if (cls == null || cls.trim().isEmpty() || section == null || section.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "Class and section are required");
            out.print(result.toString());
            return;
        }

        // Teacher username is derived from mobile number — vs_<mobile>.
        String username = "vs_" + mobile;
        if (vsUserDAO.usernameExists(username)) {
            result.put("success", false);
            result.put("message", "A VidnyanSetu login already exists for mobile " + mobile
                    + " (username " + username + ")");
            out.print(result.toString());
            return;
        }

        boolean created = vsUserDAO.createUser(username,
                PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()),
                VidnyanSetuUser.Role.TEACHER, coordinator.getUdiseNo(), teacherName.trim(), mobile,
                coordinator.getUsername());

        if (!created) {
            result.put("success", false);
            result.put("message", "Failed to create teacher login");
            out.print(result.toString());
            return;
        }

        VidnyanSetuUser newTeacher = vsUserDAO.findByUsername(username);

        String asgSql = "INSERT INTO vidnyansetu_teacher_assignments (vs_user_id, udise_code, class, section) VALUES (?,?,?,?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(asgSql)) {
            ps.setInt(1, newTeacher.getVsUserId());
            ps.setString(2, coordinator.getUdiseNo());
            ps.setString(3, cls.trim());
            ps.setString(4, section.trim());
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Teacher login created but assigning class/section failed: " + e.getMessage());
            out.print(result.toString());
            return;
        }

        result.put("success", true);
        result.put("username", username);
        result.put("password", PasswordUtil.getDefaultPassword());
        result.put("message", "Teacher added — Username: " + username + ", Password: " + PasswordUtil.getDefaultPassword());
        out.print(result.toString());
    }
}
