package com.vjnt.servlet;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;
import org.json.JSONArray;
import org.json.JSONObject;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * Servlet to check which students have been saved for a specific phase
 * This allows the save indicators to work across all systems/browsers
 */
@WebServlet("/check-saved-students")
public class CheckSavedStudentsServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\": \"Not authenticated\"}");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        String udiseNo = user.getUdiseNo();
        String phaseParam = request.getParameter("phase");
        
        if (phaseParam == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("{\"error\": \"Phase parameter required\"}");
            return;
        }
        
        int phase = Integer.parseInt(phaseParam);
        
        JSONObject result = new JSONObject();
        JSONArray savedStudents = new JSONArray();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            // Query to get all students actually saved for the specified phase.
            // phase{N}_date is the authoritative "a teacher saved this" marker:
            // saveStudentPhaseData() always writes date = NOW(), while promotion
            // seeds phase1 levels from the previous year with phase1_date = NULL.
            // Keying off the level columns would flag every promoted student as saved.
            String sql = "SELECT student_id, " +
                        "phase" + phase + "_marathi, " +
                        "phase" + phase + "_math, " +
                        "phase" + phase + "_english, " +
                        "phase" + phase + "_date " +
                        "FROM students " +
                        "WHERE udise_no = ? " +
                        "AND is_active = 1 " +
                        "AND phase" + phase + "_date IS NOT NULL";
            
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, udiseNo);
            
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                JSONObject studentInfo = new JSONObject();
                studentInfo.put("studentId", rs.getInt("student_id"));
                studentInfo.put("marathi", rs.getObject("phase" + phase + "_marathi"));
                studentInfo.put("math", rs.getObject("phase" + phase + "_math"));
                studentInfo.put("english", rs.getObject("phase" + phase + "_english"));
                
                java.sql.Timestamp timestamp = rs.getTimestamp("phase" + phase + "_date");
                if (timestamp != null) {
                    studentInfo.put("savedDate", timestamp.toString());
                }
                
                savedStudents.put(studentInfo);
            }
            
            result.put("success", true);
            result.put("savedStudents", savedStudents);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("error", e.getMessage());
        }
        
        response.getWriter().write(result.toString());
    }
}
