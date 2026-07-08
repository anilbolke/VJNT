package com.vjnt.servlet;

import com.vjnt.util.DatabaseConnection;
import com.google.gson.Gson;
import com.google.gson.JsonObject;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.*;

@WebServlet("/super-officer-statistics")
public class SuperOfficerStatisticsServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession session = request.getSession(false);
        com.vjnt.model.User sessionUser = null;
        if (session != null) sessionUser = (com.vjnt.model.User) session.getAttribute("user");
        
        // Verify user is Super Division Officer
        if (sessionUser == null || sessionUser.getUserType() != com.vjnt.model.User.UserType.SUPER_DIVISION_OFFICER) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.getWriter().write("{\"error\":\"Access denied\"}");
            return;
        }
        
        JsonObject stats = new JsonObject();
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            // Count all divisions (from students table)
            int divisionCount = 0;
            String divisionSql = "SELECT COUNT(DISTINCT division) as count FROM students";
            pstmt = conn.prepareStatement(divisionSql);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                divisionCount = rs.getInt("count");
            }
            rs.close();
            pstmt.close();
            
            // Count all districts (from students table, which has district data)
            int districtCount = 0;
            String districtSql = "SELECT COUNT(DISTINCT district) as count FROM students";
            pstmt = conn.prepareStatement(districtSql);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                districtCount = rs.getInt("count");
            }
            rs.close();
            pstmt.close();
            
            // Count all schools (unique UDISE codes from students)
            int schoolCount = 0;
            String schoolSql = "SELECT COUNT(DISTINCT udise_no) as count FROM students";
            pstmt = conn.prepareStatement(schoolSql);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                schoolCount = rs.getInt("count");
            }
            rs.close();
            pstmt.close();
            
            // Count all students
            int studentCount = 0;
            String studentSql = "SELECT COUNT(*) as count FROM students";
            pstmt = conn.prepareStatement(studentSql);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                studentCount = rs.getInt("count");
            }
            rs.close();
            pstmt.close();
            
            stats.addProperty("divisions", divisionCount);
            stats.addProperty("districts", districtCount);
            stats.addProperty("schools", schoolCount);
            stats.addProperty("students", studentCount);
            stats.addProperty("success", true);
            
        } catch (Exception e) {
            System.err.println("Error fetching Super Officer statistics: " + e.getMessage());
            e.printStackTrace();
            stats.addProperty("success", false);
            stats.addProperty("error", e.getMessage());
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { }
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
            if (conn != null) try { conn.close(); } catch (SQLException e) { }
        }
        
        Gson gson = new Gson();
        response.getWriter().write(gson.toJson(stats));
    }
}
