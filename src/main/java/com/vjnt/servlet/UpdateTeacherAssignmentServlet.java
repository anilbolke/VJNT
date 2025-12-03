package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

@WebServlet("/update-teacher-assignment")
public class UpdateTeacherAssignmentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        StringBuilder jsonResponse = new StringBuilder();
        
        try {
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("user") == null) {
                jsonResponse.append("{\"success\":false,\"message\":\"Session expired. Please login again.\"}");
                out.print(jsonResponse.toString());
                return;
            }
            
            User user = (User) session.getAttribute("user");
            if (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) {
                jsonResponse.append("{\"success\":false,\"message\":\"Unauthorized access.\"}");
                out.print(jsonResponse.toString());
                return;
            }
            
            String assignmentIdStr = request.getParameter("assignmentId");
            String classValue = request.getParameter("class");
            String section = request.getParameter("section");
            String subjects = request.getParameter("subjects");
            
            if (assignmentIdStr == null || classValue == null || section == null || subjects == null) {
                jsonResponse.append("{\"success\":false,\"message\":\"All fields are required\"}");
                out.print(jsonResponse.toString());
                return;
            }
            
            int assignmentId = Integer.parseInt(assignmentIdStr);
            String udiseCode = user.getUdiseNo();
            
            Connection conn = null;
            PreparedStatement pstmt = null;
            
            try {
                conn = DatabaseConnection.getConnection();
                
                String sql = "UPDATE teacher_assignments SET class = ?, section = ?, subjects_assigned = ?, updated_date = CURRENT_TIMESTAMP " +
                             "WHERE assignment_id = ? AND udise_code = ? AND is_active = 1";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, classValue);
                pstmt.setString(2, section);
                pstmt.setString(3, subjects);
                pstmt.setInt(4, assignmentId);
                pstmt.setString(5, udiseCode);
                
                int rowsAffected = pstmt.executeUpdate();
                
                if (rowsAffected > 0) {
                    jsonResponse.append("{\"success\":true,\"message\":\"Assignment updated successfully\"}");
                } else {
                    jsonResponse.append("{\"success\":false,\"message\":\"Assignment not found or no changes made\"}");
                }
                
            } catch (SQLException e) {
                e.printStackTrace();
                jsonResponse.append("{\"success\":false,\"message\":\"Database error: ").append(e.getMessage().replace("\"", "'")).append("\"}");
            } finally {
                if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
                if (conn != null) try { conn.close(); } catch (SQLException e) { }
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            jsonResponse.append("{\"success\":false,\"message\":\"Server error: ").append(e.getMessage().replace("\"", "'")).append("\"}");
        }
        
        out.print(jsonResponse.toString());
        out.flush();
    }
}
