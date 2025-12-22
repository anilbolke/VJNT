package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.StudentDAO;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;

/**
 * Servlet to provide phase-wise subject statistics data
 */
@WebServlet("/phase-subject-statistics")
public class PhaseSubjectStatisticsServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Set UTF-8 encoding
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            out.print("{\"success\": false, \"message\": \"Not authenticated\"}");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        
        // Only School Coordinators and Head Masters can access this
        if (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
            !user.getUserType().equals(User.UserType.HEAD_MASTER)) {
            out.print("{\"success\": false, \"message\": \"Access denied. Only School Coordinators and Head Masters can view this data.\"}");
            return;
        }
        
        try {
            String udiseNo = user.getUdiseNo();
            StudentDAO studentDAO = new StudentDAO();
            
            // Get detailed student-wise data
            List<Map<String, Object>> studentData = studentDAO.getPhaseWiseSubjectStatistics(udiseNo);
            
            // Get aggregate counts
            Map<String, Object> aggregateCounts = studentDAO.getPhaseWiseSubjectCounts(udiseNo);
            
            // Prepare response
            Map<String, Object> responseData = new java.util.HashMap<>();
            responseData.put("success", true);
            responseData.put("students", studentData);
            responseData.put("aggregateCounts", aggregateCounts);
            responseData.put("udiseNo", udiseNo);
            
            Gson gson = new Gson();
            out.print(gson.toJson(responseData));
            
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
}
