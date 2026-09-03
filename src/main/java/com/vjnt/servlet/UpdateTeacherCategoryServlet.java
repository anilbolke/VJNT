package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.json.JSONObject;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

/**
 * Sets a teacher's category (शिक्षक / पर्मनंट शिक्षक) from the District
 * Coordinator's "Teacher Category" page (district-teacher-category.jsp).
 *
 * POST /update-teacher-category   params: teacherId, category (REGULAR | PERMANENT)
 *
 * The category is a property of the teacher (teachers.teacher_category), so this
 * updates one teachers row. A District Coordinator may only touch teachers whose
 * school is in their own district; a Super Division Officer may touch any.
 */
@WebServlet("/update-teacher-category")
public class UpdateTeacherCategoryServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        JSONObject result = new JSONObject();

        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("user");
        if (user == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"success\":false,\"message\":\"Session expired. Please log in again.\"}");
            return;
        }
        boolean isDistrict = user.getUserType() == User.UserType.DISTRICT_COORDINATOR
                || user.getUserType() == User.UserType.DISTRICT_2ND_COORDINATOR;
        boolean isSdo = user.getUserType() == User.UserType.SUPER_DIVISION_OFFICER;
        if (!isDistrict && !isSdo) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print("{\"success\":false,\"message\":\"Unauthorized access\"}");
            return;
        }

        int teacherId;
        try {
            teacherId = Integer.parseInt(request.getParameter("teacherId"));
        } catch (NumberFormatException e) {
            result.put("success", false);
            result.put("message", "Invalid teacherId");
            out.print(result.toString());
            return;
        }

        String category = request.getParameter("category");
        if (!"REGULAR".equals(category) && !"PERMANENT".equals(category)) {
            result.put("success", false);
            result.put("message", "Invalid category");
            out.print(result.toString());
            return;
        }

        String sql = isDistrict
                ? "UPDATE teachers t "
                + "JOIN schools s ON s.udise_no COLLATE utf8mb4_unicode_ci = t.udise_code "
                + "SET t.teacher_category = ? "
                + "WHERE t.teacher_id = ? AND t.is_active = 1 AND s.district_name = ?"
                : "UPDATE teachers SET teacher_category = ? WHERE teacher_id = ? AND is_active = 1";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, category);
            ps.setInt(2, teacherId);
            if (isDistrict) {
                ps.setString(3, user.getDistrictName());
            }
            int rows = ps.executeUpdate();
            if (rows > 0) {
                result.put("success", true);
                result.put("category", category);
                result.put("message", "Category updated");
            } else {
                result.put("success", false);
                result.put("message", "Teacher not found in your district");
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
