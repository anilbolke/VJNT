package com.vjnt.servlet;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.google.gson.Gson;
import com.vjnt.util.DatabaseConnection;

@WebServlet("/SearchStudentsForReportServlet")
public class SearchStudentsForReportServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        String pen = request.getParameter("pen");
        String name = request.getParameter("name");
        String classVal = request.getParameter("class");
        String udise = request.getParameter("udise");
        
        List<StudentInfo> students = new ArrayList<>();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            StringBuilder sql = new StringBuilder(
                "SELECT student_pen, student_name, class, section, gender, udise_no, district, division " +
                "FROM students " +
                "WHERE udise_no = ?"
            );
            
            List<Object> params = new ArrayList<>();
            params.add(udise);
            
            if (pen != null && !pen.trim().isEmpty()) {
                sql.append(" AND student_pen LIKE ?");
                params.add("%" + pen + "%");
            }
            
            if (name != null && !name.trim().isEmpty()) {
                sql.append(" AND student_name LIKE ?");
                params.add("%" + name + "%");
            }
            
            if (classVal != null && !classVal.trim().isEmpty()) {
                sql.append(" AND class = ?");
                params.add(classVal);
            }
            
            sql.append(" ORDER BY class, section, student_name");
            
            PreparedStatement stmt = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                stmt.setObject(i + 1, params.get(i));
            }
            
            ResultSet rs = stmt.executeQuery();
            
            int count = 0;
            while (rs.next() && count < 50) {
                StudentInfo student = new StudentInfo();
                student.penNumber = rs.getString("student_pen");
                student.studentName = rs.getString("student_name");
                student.studentClass = rs.getString("class");
                student.section = rs.getString("section");
                student.gender = rs.getString("gender");
                student.schoolName = "UDISE: " + rs.getString("udise_no");
                students.add(student);
                count++;
            }
            
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(new Gson().toJson(students));
    }
    
    class StudentInfo {
        String penNumber;
        String studentName;
        @com.google.gson.annotations.SerializedName("class")
        String studentClass;
        String section;
        String gender;
        String schoolName;
    }
}
