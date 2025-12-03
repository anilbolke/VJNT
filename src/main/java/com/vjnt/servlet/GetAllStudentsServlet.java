package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.StudentDAO;
import com.vjnt.model.Student;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/getAllStudents")
public class GetAllStudentsServlet extends HttpServlet {
    private StudentDAO studentDAO = new StudentDAO();
    private Gson gson = new Gson();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        System.out.println("GetAllStudentsServlet: Request received");
        
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        
        if (user == null) {
            System.out.println("GetAllStudentsServlet: User not found in session");
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "User not logged in");
            return;
        }
        
        if (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
            !user.getUserType().equals(User.UserType.HEAD_MASTER)) {
            System.out.println("GetAllStudentsServlet: Invalid user type: " + user.getUserType());
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied");
            return;
        }
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            String udiseNo = request.getParameter("udiseNo");
            
            if (udiseNo == null || udiseNo.trim().isEmpty()) {
                udiseNo = user.getUdiseNo();
            }
            
            System.out.println("GetAllStudentsServlet: Fetching students for UDISE: " + udiseNo);
            
            if (udiseNo == null || udiseNo.trim().isEmpty()) {
                System.out.println("GetAllStudentsServlet: UDISE number is null or empty");
                Map<String, Object> error = new HashMap<>();
                error.put("success", false);
                error.put("error", "UDISE number not found for user");
                out.print(gson.toJson(error));
                return;
            }
            
            List<Student> students = studentDAO.getStudentsByUdise(udiseNo);
            System.out.println("GetAllStudentsServlet: Found " + students.size() + " students");
            
            out.print(gson.toJson(students));
            
        } catch (Exception e) {
            System.err.println("GetAllStudentsServlet: Error - " + e.getMessage());
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("error", e.getMessage());
            out.print(gson.toJson(error));
        }
    }
}
