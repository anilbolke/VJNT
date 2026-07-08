package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

/**
 * Servlet to handle adding new teachers
 * Endpoint: /add-teacher
 * Method: POST
 * Access: School Coordinator only
 */
@WebServlet("/add-teacher")
public class AddTeacherServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        StringBuilder jsonResponse = new StringBuilder();
        
        try {
            
            // Get session and verify user is School Coordinator
            HttpSession session = request.getSession(false);
            if (session == null) {
                jsonResponse.append("{\"success\":false,\"message\":\"Session expired. Please login again.\"}");
                out.print(jsonResponse.toString());
                return;
            }
            
            User user = (User) session.getAttribute("user");
            if (user == null) {
                jsonResponse.append("{\"success\":false,\"message\":\"Session expired. Please login again.\"}");
                out.print(jsonResponse.toString());
                return;
            }
            
            if (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER)) {
                jsonResponse.append("{\"success\":false,\"message\":\"Unauthorized access. Only School Coordinators can add teachers.\"}");
                out.print(jsonResponse.toString());
                return;
            }
            
            // Get form parameters
            String teacherName = request.getParameter("teacherName");
            String teacherMobile = request.getParameter("teacherMobile");
            String subjects = request.getParameter("subjects");
            String description = request.getParameter("description");
            String udiseCode = user.getUdiseNo();
            int userId = user.getUserId();
            
            
            // Validate inputs
            if (teacherName == null || teacherName.trim().isEmpty()) {
                jsonResponse.append("{\"success\":false,\"message\":\"Teacher name is required\"}");
                out.print(jsonResponse.toString());
                return;
            }
            
            if (teacherMobile == null || !teacherMobile.matches("\\d{10}")) {
                jsonResponse.append("{\"success\":false,\"message\":\"Valid 10-digit mobile number is required\"}");
                out.print(jsonResponse.toString());
                return;
            }
            
            if (subjects == null || subjects.trim().isEmpty()) {
                jsonResponse.append("{\"success\":false,\"message\":\"At least one subject must be selected\"}");
                out.print(jsonResponse.toString());
                return;
            }
            
            // Database insertion
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            
            try {
                conn = DatabaseConnection.getConnection();
                
                // Check if mobile number already exists for this school
                String checkSql = "SELECT COUNT(*) FROM teachers WHERE udise_code = ? AND mobile_number = ? AND is_active = 1";
                pstmt = conn.prepareStatement(checkSql);
                pstmt.setString(1, udiseCode);
                pstmt.setString(2, teacherMobile);
                rs = pstmt.executeQuery();
                
                if (rs.next() && rs.getInt(1) > 0) {
                    jsonResponse.append("{\"success\":false,\"message\":\"A teacher with this mobile number already exists\"}");
                    out.print(jsonResponse.toString());
                    return;
                }
                rs.close();
                pstmt.close();
                
                // Insert new teacher
                String insertSql = "INSERT INTO teachers (udise_code, teacher_name, mobile_number, subjects_taught, description, created_by) VALUES (?, ?, ?, ?, ?, ?)";
                pstmt = conn.prepareStatement(insertSql, PreparedStatement.RETURN_GENERATED_KEYS);
                pstmt.setString(1, udiseCode);
                pstmt.setString(2, teacherName.trim());
                pstmt.setString(3, teacherMobile);
                pstmt.setString(4, subjects);
                pstmt.setString(5, description != null ? description.trim() : null);
                pstmt.setInt(6, userId);
                
                int rowsAffected = pstmt.executeUpdate();
                
                if (rowsAffected > 0) {
                    // Get generated teacher ID
                    ResultSet generatedKeys = pstmt.getGeneratedKeys();
                    int teacherId = 0;
                    if (generatedKeys.next()) {
                        teacherId = generatedKeys.getInt(1);
                    }
                    generatedKeys.close();
                    pstmt.close();

                    // Create portal login for the teacher:
                    // username = mobile number, password = default (Pass@123),
                    // must change password on first login.
                    String loginMessage;
                    String checkUserSql = "SELECT COUNT(*) FROM users WHERE username = ?";
                    pstmt = conn.prepareStatement(checkUserSql);
                    pstmt.setString(1, teacherMobile);
                    rs = pstmt.executeQuery();
                    boolean loginExists = rs.next() && rs.getInt(1) > 0;
                    rs.close();
                    pstmt.close();

                    if (loginExists) {
                        loginMessage = "Login already exists for mobile " + teacherMobile;
                    } else {
                        String userSql = "INSERT INTO users (username, password, user_type, division_name, district_name, " +
                                         "udise_no, is_first_login, must_change_password, is_active, created_by, full_name, mobile) " +
                                         "VALUES (?, ?, 'TEACHER', ?, ?, ?, 1, 1, 1, ?, ?, ?)";
                        pstmt = conn.prepareStatement(userSql);
                        pstmt.setString(1, teacherMobile);
                        pstmt.setString(2, com.vjnt.util.PasswordUtil.hashPassword(com.vjnt.util.PasswordUtil.getDefaultPassword()));
                        pstmt.setString(3, user.getDivisionName());
                        pstmt.setString(4, user.getDistrictName());
                        pstmt.setString(5, udiseCode);
                        pstmt.setString(6, user.getUsername());
                        pstmt.setString(7, teacherName.trim());
                        pstmt.setString(8, teacherMobile);
                        int userRows = pstmt.executeUpdate();
                        loginMessage = userRows > 0
                                ? "Login created - Username: " + teacherMobile + ", Password: " + com.vjnt.util.PasswordUtil.getDefaultPassword()
                                : "Failed to create login";
                    }

                    jsonResponse.append("{\"success\":true,\"message\":\"Teacher added successfully\",");
                    jsonResponse.append("\"teacherId\":").append(teacherId).append(",");
                    jsonResponse.append("\"teacherName\":\"").append(teacherName.trim().replace("\"", "\\\"")).append("\",");
                    jsonResponse.append("\"mobile\":\"").append(teacherMobile).append("\",");
                    jsonResponse.append("\"loginInfo\":\"").append(loginMessage.replace("\"", "\\\"")).append("\",");
                    jsonResponse.append("\"subjects\":\"").append(subjects.replace("\"", "\\\"")).append("\"}");
                } else {
                    jsonResponse.append("{\"success\":false,\"message\":\"Failed to add teacher. Please try again.\"}");
                }
                
            } catch (SQLException e) {
                System.err.println("AddTeacherServlet: SQL Error: " + e.getMessage());
                e.printStackTrace();
                jsonResponse.append("{\"success\":false,\"message\":\"Database error: ").append(e.getMessage().replace("\"", "'")).append("\"}");
            } finally {
                if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
                if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
                if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
            
        } catch (Exception e) {
            System.err.println("AddTeacherServlet: General Error: " + e.getMessage());
            e.printStackTrace();
            jsonResponse.append("{\"success\":false,\"message\":\"Server error: ").append(e.getMessage().replace("\"", "'")).append("\"}");
        }
        
        out.print(jsonResponse.toString());
        out.flush();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        out.print("{\"success\":false,\"message\":\"GET method not supported. Use POST to add teacher.\"}");
    }
}
