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

@WebServlet("/delete-teacher")
public class DeleteTeacherServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        StringBuilder jsonResponse = new StringBuilder();
        
        try {
            // Check session
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
            
            // Get parameter
            String teacherIdStr = request.getParameter("teacherId");
            
            if (teacherIdStr == null) {
                jsonResponse.append("{\"success\":false,\"message\":\"Teacher ID is required\"}");
                out.print(jsonResponse.toString());
                return;
            }
            
            int teacherId = Integer.parseInt(teacherIdStr);
            String udiseCode = user.getUdiseNo();
            
            // Soft delete - set is_active = 0
            Connection conn = null;
            PreparedStatement pstmt = null;
            
            try {
                conn = DatabaseConnection.getConnection();
                
                String sql = "UPDATE teachers SET is_active = 0, updated_date = CURRENT_TIMESTAMP " +
                             "WHERE teacher_id = ? AND udise_code = ? AND is_active = 1";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, teacherId);
                pstmt.setString(2, udiseCode);
                
                int rowsAffected = pstmt.executeUpdate();
                
                if (rowsAffected > 0) {
                    jsonResponse.append("{\"success\":true,\"message\":\"Teacher deleted successfully\"}");
                } else {
                    jsonResponse.append("{\"success\":false,\"message\":\"Teacher not found\"}");
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
