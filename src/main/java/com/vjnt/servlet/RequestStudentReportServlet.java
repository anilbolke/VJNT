package com.vjnt.servlet;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.google.gson.JsonObject;
import com.vjnt.util.DatabaseConnection;

@WebServlet("/RequestStudentReportServlet")
public class RequestStudentReportServlet extends HttpServlet {
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        JsonObject jsonResponse = new JsonObject();
        
        if (session == null || session.getAttribute("userId") == null) {
            jsonResponse.addProperty("success", false);
            jsonResponse.addProperty("message", "Unauthorized");
            response.getWriter().write(jsonResponse.toString());
            return;
        }
        
        Integer userId = (Integer) session.getAttribute("userId");
        String udiseCode = (String) session.getAttribute("udiseCode");
        String penNumber = request.getParameter("penNumber");
        String studentName = request.getParameter("studentName");
        String classVal = request.getParameter("class");
        String section = request.getParameter("section");
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Check if already requested
            String checkSql = "SELECT approval_id FROM report_approvals " +
                             "WHERE pen_number = ? AND approval_status = 'PENDING'";
            PreparedStatement checkStmt = conn.prepareStatement(checkSql);
            checkStmt.setString(1, penNumber);
            ResultSet rs = checkStmt.executeQuery();
            
            if (rs.next()) {
                jsonResponse.addProperty("success", false);
                jsonResponse.addProperty("message", "A pending request already exists for this student");
                response.setContentType("application/json");
                response.getWriter().write(jsonResponse.toString());
                return;
            }
            
            // Get school info from students table
            String schoolSql = "SELECT DISTINCT udise_no, district, division FROM students WHERE udise_no = ?";
            PreparedStatement schoolStmt = conn.prepareStatement(schoolSql);
            schoolStmt.setString(1, udiseCode);
            ResultSet schoolRs = schoolStmt.executeQuery();
            
            String schoolName = "School-" + udiseCode;
            String district = null, division = null;
            if (schoolRs.next()) {
                district = schoolRs.getString("district");
                division = schoolRs.getString("division");
            }
            
            // Insert approval request
            String insertSql = "INSERT INTO report_approvals " +
                              "(report_type, pen_number, student_name, class, section, udise_code, " +
                              "school_name, district, division, requested_by) " +
                              "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            PreparedStatement insertStmt = conn.prepareStatement(insertSql);
            insertStmt.setString(1, "STUDENT_COMPREHENSIVE");
            insertStmt.setString(2, penNumber);
            insertStmt.setString(3, studentName);
            insertStmt.setString(4, classVal);
            insertStmt.setString(5, section);
            insertStmt.setString(6, udiseCode);
            insertStmt.setString(7, schoolName);
            insertStmt.setString(8, district);
            insertStmt.setString(9, division);
            insertStmt.setInt(10, userId);
            
            int rows = insertStmt.executeUpdate();
            
            if (rows > 0) {
                jsonResponse.addProperty("success", true);
                jsonResponse.addProperty("message", "Report request submitted successfully");
            } else {
                jsonResponse.addProperty("success", false);
                jsonResponse.addProperty("message", "Failed to submit request");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            jsonResponse.addProperty("success", false);
            jsonResponse.addProperty("message", "Error: " + e.getMessage());
        }
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(jsonResponse.toString());
    }
}
