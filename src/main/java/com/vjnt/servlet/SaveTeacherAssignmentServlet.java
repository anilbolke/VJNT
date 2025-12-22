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

@WebServlet("/save-teacher-assignment")
public class SaveTeacherAssignmentServlet extends HttpServlet {
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
            
            String udiseCode = request.getParameter("udiseCode");
            String district = request.getParameter("district");
            String division = request.getParameter("division");
            String classValue = request.getParameter("class");
            String section = request.getParameter("section");
            String teacherIdStr = request.getParameter("teacherId");
            String teacherName = request.getParameter("teacherName");
            String subjects = request.getParameter("subjects");
            String isClassTeacherStr = request.getParameter("isClassTeacher");
            
            if (udiseCode == null || classValue == null || section == null || 
                teacherIdStr == null || teacherName == null || subjects == null) {
                jsonResponse.append("{\"success\":false,\"message\":\"All fields are required\"}");
                out.print(jsonResponse.toString());
                return;
            }
            
            int teacherId = Integer.parseInt(teacherIdStr);
            int isClassTeacher = (isClassTeacherStr != null && isClassTeacherStr.equals("1")) ? 1 : 0;
            
            Connection conn = null;
            PreparedStatement pstmt = null;
            
            try {
                conn = DatabaseConnection.getConnection();
                conn.setAutoCommit(false); // Start transaction
                
                // If this teacher is being marked as class teacher, unmark any existing class teacher for this class-section
                if (isClassTeacher == 1) {
                    String updateSql = "UPDATE teacher_assignments SET is_class_teacher = 0 " +
                                      "WHERE udise_code = ? AND class = ? AND section = ? AND is_class_teacher = 1";
                    pstmt = conn.prepareStatement(updateSql);
                    pstmt.setString(1, udiseCode);
                    pstmt.setString(2, classValue);
                    pstmt.setString(3, section);
                    pstmt.executeUpdate();
                    pstmt.close();
                }
                
                // Insert the new assignment
                String sql = "INSERT INTO teacher_assignments (udise_code, district, division, teacher_id, teacher_name, class, section, subjects_assigned, is_class_teacher, created_by) " +
                             "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, udiseCode);
                pstmt.setString(2, district);
                pstmt.setString(3, division);
                pstmt.setInt(4, teacherId);
                pstmt.setString(5, teacherName);
                pstmt.setString(6, classValue);
                pstmt.setString(7, section);
                pstmt.setString(8, subjects);
                pstmt.setInt(9, isClassTeacher);
                pstmt.setInt(10, user.getUserId());
                
                int rowsAffected = pstmt.executeUpdate();
                
                if (rowsAffected > 0) {
                    conn.commit(); // Commit transaction
                    jsonResponse.append("{\"success\":true,\"message\":\"Teacher assigned successfully\"}");
                } else {
                    conn.rollback(); // Rollback on failure
                    jsonResponse.append("{\"success\":false,\"message\":\"Failed to assign teacher\"}");
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
