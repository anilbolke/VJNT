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

@WebServlet({"/GetDistrictSchoolsServlet", "/api/schools"})
public class GetDistrictSchoolsServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            // Return empty array for /api/schools endpoint
            if (request.getRequestURI().contains("/api/schools")) {
                response.getWriter().write("[]");
            } else {
                response.getWriter().write("{\"success\": false, \"message\": \"Not authenticated\"}");
            }
            return;
        }

        User user = (User) session.getAttribute("user");
        String districtName = request.getParameter("district");

        // Check if this is the new API endpoint
        boolean isApiEndpoint = request.getRequestURI().contains("/api/schools");
        
        JsonArray schoolsArray = new JsonArray();

        try (Connection conn = DatabaseConnection.getConnection()) {

            String sql;
            PreparedStatement stmt;

            if (districtName == null || districtName.trim().isEmpty()) {
                // Only SUPER_DIVISION_OFFICER can request without a district
                if (user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
                    if (isApiEndpoint) {
                        response.getWriter().write("[]");
                    } else {
                        response.getWriter().write("{\"success\": false, \"message\": \"District name required\"}");
                    }
                    return;
                }

                sql = "SELECT " +
                      "    s.udise_no, " +
                      "    s.school_name, " +
                      "    s.district_name, " +
                      "    COUNT(DISTINCT st.student_id) as student_count, " +
                      "    SUM(CASE WHEN st.gender = 'Male' OR st.gender = 'पुरुष' THEN 1 ELSE 0 END) as male_count, " +
                      "    SUM(CASE WHEN st.gender = 'Female' OR st.gender = 'स्त्री' THEN 1 ELSE 0 END) as female_count, " +
                      "    COUNT(DISTINCT CASE WHEN st.phase1_date IS NOT NULL THEN st.student_id END) as phase1_count, " +
                      "    COUNT(DISTINCT CASE WHEN st.phase2_date IS NOT NULL THEN st.student_id END) as phase2_count, " +
                      "    COUNT(DISTINCT CASE WHEN st.phase3_date IS NOT NULL THEN st.student_id END) as phase3_count, " +
                      "    COUNT(DISTINCT CASE WHEN st.phase4_date IS NOT NULL THEN st.student_id END) as phase4_count, " +
                      "    (SELECT COUNT(*) FROM teachers t WHERE t.udise_code COLLATE utf8mb4_unicode_ci = s.udise_no COLLATE utf8mb4_unicode_ci AND t.is_active = 1) as teacher_count " +
                      "FROM schools s " +
                      "LEFT JOIN students st ON s.udise_no COLLATE utf8mb4_unicode_ci = st.udise_no COLLATE utf8mb4_unicode_ci " +
                      "GROUP BY s.udise_no, s.school_name, s.district_name " +
                      "ORDER BY s.district_name, s.school_name";

                stmt = conn.prepareStatement(sql);

            } else {
                sql = "SELECT " +
                      "    s.udise_no, " +
                      "    s.school_name, " +
                      "    s.district_name, " +
                      "    COUNT(DISTINCT st.student_id) as student_count, " +
                      "    SUM(CASE WHEN st.gender = 'Male' OR st.gender = 'पुरुष' THEN 1 ELSE 0 END) as male_count, " +
                      "    SUM(CASE WHEN st.gender = 'Female' OR st.gender = 'स्त्री' THEN 1 ELSE 0 END) as female_count, " +
                      "    COUNT(DISTINCT CASE WHEN st.phase1_date IS NOT NULL THEN st.student_id END) as phase1_count, " +
                      "    COUNT(DISTINCT CASE WHEN st.phase2_date IS NOT NULL THEN st.student_id END) as phase2_count, " +
                      "    COUNT(DISTINCT CASE WHEN st.phase3_date IS NOT NULL THEN st.student_id END) as phase3_count, " +
                      "    COUNT(DISTINCT CASE WHEN st.phase4_date IS NOT NULL THEN st.student_id END) as phase4_count, " +
                      "    (SELECT COUNT(*) FROM teachers t WHERE t.udise_code COLLATE utf8mb4_unicode_ci = s.udise_no COLLATE utf8mb4_unicode_ci AND t.is_active = 1) as teacher_count " +
                      "FROM schools s " +
                      "INNER JOIN students st ON s.udise_no COLLATE utf8mb4_unicode_ci = st.udise_no COLLATE utf8mb4_unicode_ci " +
                      "WHERE st.district COLLATE utf8mb4_unicode_ci = ? " +
                      "GROUP BY s.udise_no, s.school_name, s.district_name " +
                      "ORDER BY s.school_name";

                stmt = conn.prepareStatement(sql);
                stmt.setString(1, districtName);
            }

            ResultSet rs = stmt.executeQuery();
            
            int count = 0;

            while (rs.next()) {
                count++;
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
            

            // Return format based on endpoint
            if (isApiEndpoint) {
                response.getWriter().write(new Gson().toJson(schoolsArray));
            } else {
                JsonObject result = new JsonObject();
                result.addProperty("success", true);
                result.add("schools", schoolsArray);
                response.getWriter().write(new Gson().toJson(result));
            }

        } catch (Exception e) {
            e.printStackTrace();
            if (isApiEndpoint) {
                response.getWriter().write("[]");
            } else {
                JsonObject result = new JsonObject();
                result.addProperty("success", false);
                result.addProperty("message", "Error: " + e.getMessage());
                response.getWriter().write(new Gson().toJson(result));
            }
        }
    }
}
