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

@WebServlet("/api/teachers")
public class GetDistrictTeachersServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("[]");
            return;
        }

        User sessionUser = (User) session.getAttribute("user");
        String district = request.getParameter("district");

        // Allow SUPER_DIVISION_OFFICER to omit district and view all teachers
        if (district == null || district.trim().isEmpty()) {
            if (sessionUser.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.getWriter().write("[]");
                return;
            }
        }

        // Verify user has permission to view this district's data (district coordinators restricted)
        if (sessionUser.getUserType() == User.UserType.DISTRICT_COORDINATOR || 
            sessionUser.getUserType() == User.UserType.DISTRICT_2ND_COORDINATOR) {
            // District coordinators can only see their own district
            if (district != null && !district.equals(sessionUser.getDistrictName())) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.getWriter().write("[]");
                return;
            }
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            // Query to get teachers from teachers table joined with schools to filter by district
            String sql;
            if (district == null || district.trim().isEmpty()) {
                sql = "SELECT t.teacher_id, t.teacher_name, t.mobile_number, t.subjects_taught, " +
                      "t.description, t.udise_code, t.created_date, t.is_active, " +
                      "s.school_name, s.district_name " +
                      "FROM teachers t " +
                      "INNER JOIN schools s ON t.udise_code COLLATE utf8mb4_unicode_ci = s.udise_no COLLATE utf8mb4_unicode_ci " +
                      "WHERE t.is_active = 1 " +
                      "ORDER BY s.district_name, s.school_name, t.teacher_name";
                pstmt = conn.prepareStatement(sql);
            } else {
                sql = "SELECT t.teacher_id, t.teacher_name, t.mobile_number, t.subjects_taught, " +
                      "t.description, t.udise_code, t.created_date, t.is_active, " +
                      "s.school_name, s.district_name " +
                      "FROM teachers t " +
                      "INNER JOIN schools s ON t.udise_code COLLATE utf8mb4_unicode_ci = s.udise_no COLLATE utf8mb4_unicode_ci " +
                      "WHERE t.udise_code COLLATE utf8mb4_unicode_ci IN (SELECT DISTINCT udise_no COLLATE utf8mb4_unicode_ci FROM students WHERE district COLLATE utf8mb4_unicode_ci = ? AND is_active = 1) " +
                      "AND t.is_active = 1 " +
                      "ORDER BY s.school_name, t.teacher_name";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, district);
            }
            rs = pstmt.executeQuery();
            
            JsonArray teachersArray = new JsonArray();
            int teacherCount = 0;
            
            
            while (rs.next()) {
                teacherCount++;
                
                JsonObject teacher = new JsonObject();
                teacher.addProperty("teacherId", rs.getInt("teacher_id"));
                teacher.addProperty("teacherName", rs.getString("teacher_name"));
                teacher.addProperty("mobile", rs.getString("mobile_number") != null ? rs.getString("mobile_number") : "");
                teacher.addProperty("subjects", rs.getString("subjects_taught") != null ? rs.getString("subjects_taught") : "");
                teacher.addProperty("description", rs.getString("description") != null ? rs.getString("description") : "");
                teacher.addProperty("udiseNo", rs.getString("udise_code"));
                teacher.addProperty("schoolName", rs.getString("school_name"));
                teacher.addProperty("districtName", rs.getString("district_name"));
                teacher.addProperty("isActive", rs.getBoolean("is_active"));
                
                Timestamp createdDate = rs.getTimestamp("created_date");
                teacher.addProperty("createdDate", createdDate != null ? createdDate.toString() : "");
                
                teachersArray.add(teacher);
                
            }
            
            
            response.getWriter().write(new Gson().toJson(teachersArray));
            
        } catch (SQLException e) {
            System.err.println("Error fetching teachers: " + e.getMessage());
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("[]");
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            if (conn != null) try { conn.close(); } catch (SQLException e) {}
        }
    }
}
