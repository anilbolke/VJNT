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
        if (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && !user.getUserType().equals(User.UserType.HEAD_MASTER) &&                     !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER)) {
            out.print("{\"success\": false, \"message\": \"Access denied\"}");
            return;
        }
        
        try {
            // Debug logging
            
            // Get parameters
            String studentIdStr = request.getParameter("studentId");
            String phaseStr = request.getParameter("phase");
            String marathiStr = request.getParameter("marathi_akshara");
            String mathStr = request.getParameter("math_akshara");
            String englishStr = request.getParameter("english_akshara");
            
            // Validate parameters are not null.
            // The three subject levels are optional: the client sends only the subjects the
            // teacher actually assessed, so an absent one means "leave that subject alone".
            if (studentIdStr == null || phaseStr == null) {
                String missing = "";
                if (studentIdStr == null) missing += "studentId ";
                if (phaseStr == null) missing += "phase ";
                out.print("{\"success\": false, \"message\": \"Missing parameters: " + missing + "\"}");
                return;
            }

            int studentId = Integer.parseInt(studentIdStr);
            int phase = Integer.parseInt(phaseStr);
            Integer marathiLevel = parseOptionalLevel(marathiStr);
            Integer mathLevel = parseOptionalLevel(mathStr);
            Integer englishLevel = parseOptionalLevel(englishStr);

            if (marathiLevel == null && mathLevel == null && englishLevel == null) {
                out.print("{\"success\": false, \"message\": \"No subject selected\"}");
                return;
            }

            
            // Update database with phase-specific method
            StudentDAO studentDAO = new StudentDAO();
            String username = user.getUsername();
            
            boolean success = studentDAO.updatePhaseLanguageLevels(
                studentId, phase, marathiLevel, mathLevel, englishLevel, username
            );
            
            if (success) {
                
                // Check if phase is now complete
                String udiseNo = user.getUdiseNo();
                boolean phaseComplete = studentDAO.isPhaseComplete(udiseNo, phase);
                
                if (phaseComplete) {
                    out.print("{\"success\": true, \"message\": \"Phase " + phase + " data saved successfully\", \"phaseComplete\": true}");
                } else {
                    out.print("{\"success\": true, \"message\": \"Phase " + phase + " data saved successfully\", \"phaseComplete\": false}");
                }
            } else {
                //System.out.println("Update failed!");
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

    /**
     * A subject the teacher did not assess is simply absent from the request (or blank),
     * which maps to null = "do not touch this subject's columns".
     */
    private static Integer parseOptionalLevel(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return Integer.valueOf(value.trim());
    }
}

