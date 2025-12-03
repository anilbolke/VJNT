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

@WebServlet("/update-teacher")
public class UpdateTeacherServlet extends HttpServlet {
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
            
            // Get parameters
            String teacherIdStr = request.getParameter("teacherId");
            String teacherName = request.getParameter("teacherName");
            String teacherMobile = request.getParameter("teacherMobile");
            String subjects = request.getParameter("subjects");
            String description = request.getParameter("description");
            
            // Validate
            if (teacherIdStr == null || teacherName == null || teacherName.trim().isEmpty()) {
                jsonResponse.append("{\"success\":false,\"message\":\"Teacher ID and name are required\"}");
                out.print(jsonResponse.toString());
                return;
            }
            
            int teacherId = Integer.parseInt(teacherIdStr);
            String udiseCode = user.getUdiseNo();
            
            // Update database
            Connection conn = null;
            PreparedStatement pstmt = null;
            
            try {
                conn = DatabaseConnection.getConnection();
                
                String sql = "UPDATE teachers SET teacher_name = ?, mobile_number = ?, subjects_taught = ?, description = ?, updated_date = CURRENT_TIMESTAMP " +
                             "WHERE teacher_id = ? AND udise_code = ? AND is_active = 1";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, teacherName.trim());
                pstmt.setString(2, teacherMobile);
                pstmt.setString(3, subjects);
                pstmt.setString(4, description);
                pstmt.setInt(5, teacherId);
                pstmt.setString(6, udiseCode);
                
                int rowsAffected = pstmt.executeUpdate();
                
                if (rowsAffected > 0) {
                    jsonResponse.append("{\"success\":true,\"message\":\"Teacher updated successfully\"}");
                } else {
                    jsonResponse.append("{\"success\":false,\"message\":\"Teacher not found or no changes made\"}");
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
