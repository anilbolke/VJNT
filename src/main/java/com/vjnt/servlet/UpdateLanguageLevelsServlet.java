package com.vjnt.servlet;

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

/**
 * Servlet to handle language level updates
 */
@WebServlet("/update-language-levels")
public class UpdateLanguageLevelsServlet extends HttpServlet {
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        // Check authentication
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            out.print("{\"success\": false, \"message\": \"Not authenticated\"}");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        
        // Only school coordinators and head masters can update
        if (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
            !user.getUserType().equals(User.UserType.HEAD_MASTER)) {
            out.print("{\"success\": false, \"message\": \"Access denied\"}");
            return;
        }
        
        try {
            // Debug logging
            System.out.println("=== Update Language Levels Request ===");
            System.out.println("studentId param: " + request.getParameter("studentId"));
            System.out.println("phase param: " + request.getParameter("phase"));
            System.out.println("marathi_akshara param: " + request.getParameter("marathi_akshara"));
            System.out.println("math_akshara param: " + request.getParameter("math_akshara"));
            System.out.println("english_akshara param: " + request.getParameter("english_akshara"));
            
            // Get parameters
            String studentIdStr = request.getParameter("studentId");
            String phaseStr = request.getParameter("phase");
            String marathiStr = request.getParameter("marathi_akshara");
            String mathStr = request.getParameter("math_akshara");
            String englishStr = request.getParameter("english_akshara");
            
            // Validate parameters are not null
            if (studentIdStr == null || phaseStr == null || marathiStr == null || mathStr == null || englishStr == null) {
                String missing = "";
                if (studentIdStr == null) missing += "studentId ";
                if (phaseStr == null) missing += "phase ";
                if (marathiStr == null) missing += "marathi_akshara ";
                if (mathStr == null) missing += "math_akshara ";
                if (englishStr == null) missing += "english_akshara ";
                out.print("{\"success\": false, \"message\": \"Missing parameters: " + missing + "\"}");
                return;
            }
            
            int studentId = Integer.parseInt(studentIdStr);
            int phase = Integer.parseInt(phaseStr);
            int marathiLevel = Integer.parseInt(marathiStr);
            int mathLevel = Integer.parseInt(mathStr);
            int englishLevel = Integer.parseInt(englishStr);
            
            System.out.println("Parsed values - Student: " + studentId + 
                             ", Phase: " + phase +
                             ", Marathi: " + marathiLevel + 
                             ", Math: " + mathLevel + 
                             ", English: " + englishLevel);
            
            // Update database with phase-specific method
            StudentDAO studentDAO = new StudentDAO();
            String username = user.getUsername();
            
            boolean success = studentDAO.updatePhaseLanguageLevels(
                studentId, phase, marathiLevel, mathLevel, englishLevel, username
            );
            
            if (success) {
                System.out.println("Phase " + phase + " update successful!");
                
                // Check if phase is now complete
                String udiseNo = user.getUdiseNo();
                boolean phaseComplete = studentDAO.isPhaseComplete(udiseNo, phase);
                
                if (phaseComplete) {
                    System.out.println("Phase " + phase + " is now COMPLETE for school " + udiseNo);
                    out.print("{\"success\": true, \"message\": \"Phase " + phase + " data saved successfully\", \"phaseComplete\": true}");
                } else {
                    out.print("{\"success\": true, \"message\": \"Phase " + phase + " data saved successfully\", \"phaseComplete\": false}");
                }
            } else {
                System.out.println("Update failed!");
                out.print("{\"success\": false, \"message\": \"Failed to update phase data\"}");
            }
            
        } catch (NumberFormatException e) {
            System.err.println("NumberFormatException: " + e.getMessage());
            e.printStackTrace();
            out.print("{\"success\": false, \"message\": \"Invalid input data: " + e.getMessage() + "\"}");
        } catch (Exception e) {
            System.err.println("Exception: " + e.getMessage());
            e.printStackTrace();
            out.print("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
}
