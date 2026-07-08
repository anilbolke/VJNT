package com.vjnt.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.*;

/**
 * Super Division Officer version of the school-details lookup used by the dashboard's
 * "District-wise Student Count" → School(UDISE) Count drill-down.
 *
 * The existing {@code /api/schools} servlet filters {@code schools.district_name},
 * but that column holds unreliable (mostly numeric) values, so a real district name
 * matches nothing. This version resolves the district via {@code students.district}
 * (the reliable source) and joins to {@code schools} by UDISE for the school name.
 *
 * Returns the same JSON array shape as /api/schools. Existing servlets are untouched.
 */
@WebServlet("/super-api-schools")
public class SuperApiSchoolsServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.getWriter().write("[]");
            return;
        }

        User user = (User) session.getAttribute("user");
        if (user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
            response.getWriter().write("[]");
            return;
        }

        String districtName = request.getParameter("district");
        boolean hasDistrict = districtName != null && !districtName.trim().isEmpty();

        JsonArray schoolsArray = new JsonArray();

        try (Connection conn = DatabaseConnection.getConnection()) {

            // Base on students.udise_no with a LEFT JOIN to schools: the schools table is
            // incomplete (some UDISEs present in students have no schools row), so an INNER
            // JOIN would silently drop those schools. Fall back to the UDISE when no name exists.
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT st.udise_no, ");
            sql.append("COALESCE(MAX(s.school_name), st.udise_no) as school_name, ");
            sql.append("st.district as district_name, ");
            sql.append("COUNT(DISTINCT st.student_id) as student_count, ");
            sql.append("SUM(CASE WHEN st.gender = 'Male' OR st.gender = 'पुरुष' THEN 1 ELSE 0 END) as male_count, ");
            sql.append("SUM(CASE WHEN st.gender = 'Female' OR st.gender = 'स्त्री' THEN 1 ELSE 0 END) as female_count, ");
            sql.append("COUNT(DISTINCT CASE WHEN st.phase1_date IS NOT NULL THEN st.student_id END) as phase1_count, ");
            sql.append("COUNT(DISTINCT CASE WHEN st.phase2_date IS NOT NULL THEN st.student_id END) as phase2_count, ");
            sql.append("COUNT(DISTINCT CASE WHEN st.phase3_date IS NOT NULL THEN st.student_id END) as phase3_count, ");
            sql.append("COUNT(DISTINCT CASE WHEN st.phase4_date IS NOT NULL THEN st.student_id END) as phase4_count, ");
            sql.append("(SELECT COUNT(*) FROM teachers t WHERE t.udise_code COLLATE utf8mb4_unicode_ci = st.udise_no COLLATE utf8mb4_unicode_ci AND t.is_active = 1) as teacher_count ");
            sql.append("FROM students st ");
            sql.append("LEFT JOIN schools s ON st.udise_no COLLATE utf8mb4_unicode_ci = s.udise_no COLLATE utf8mb4_unicode_ci ");
            sql.append("WHERE st.is_active = 1 ");
            if (hasDistrict) {
                sql.append("AND st.district COLLATE utf8mb4_unicode_ci = ? ");
            }
            sql.append("GROUP BY st.udise_no, st.district ");
            sql.append("ORDER BY st.district, school_name");

            PreparedStatement stmt = conn.prepareStatement(sql.toString());
            if (hasDistrict) {
                stmt.setString(1, districtName);
            }

            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                JsonObject school = new JsonObject();
                school.addProperty("udiseNo", rs.getString("udise_no"));
                school.addProperty("schoolName", rs.getString("school_name"));
                school.addProperty("districtName", rs.getString("district_name"));
                school.addProperty("studentCount", rs.getInt("student_count"));
                school.addProperty("teacherCount", rs.getInt("teacher_count"));
                school.addProperty("maleCount", rs.getInt("male_count"));
                school.addProperty("femaleCount", rs.getInt("female_count"));
                school.addProperty("phase1Count", rs.getInt("phase1_count"));
                school.addProperty("phase2Count", rs.getInt("phase2_count"));
                school.addProperty("phase3Count", rs.getInt("phase3_count"));
                school.addProperty("phase4Count", rs.getInt("phase4_count"));
                schoolsArray.add(school);
            }

            response.getWriter().write(new Gson().toJson(schoolsArray));

        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().write("[]");
        }
    }
}
