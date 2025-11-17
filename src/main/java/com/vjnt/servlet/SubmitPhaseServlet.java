package com.vjnt.servlet;

import com.vjnt.dao.PhaseApprovalDAO;
import com.vjnt.dao.StudentDAO;
import com.vjnt.model.PhaseApproval;
import com.vjnt.model.Student;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;

/**
 * Servlet to submit phase for approval by School Coordinator
 */
@WebServlet("/submit-phase")
public class SubmitPhaseServlet extends HttpServlet {
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json;charset=UTF-8");
        
        // Check authentication
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.getWriter().write("{\"success\": false, \"message\": \"Not authenticated\"}");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        
        // Only School Coordinator can submit
        if (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) {
            response.getWriter().write("{\"success\": false, \"message\": \"Only School Coordinator can submit phases\"}");
            return;
        }
        
        try {
            int phaseNumber = Integer.parseInt(request.getParameter("phaseNumber"));
            String remarks = request.getParameter("remarks");
            String udiseNo = user.getUdiseNo();
            
            // Calculate phase statistics
            StudentDAO studentDAO = new StudentDAO();
            List<Student> students = studentDAO.getStudentsByUdise(udiseNo);
            
            int totalStudents = students.size();
            int completedStudents = 0;
            int ignoredStudents = 0;
            
            for (Student student : students) {
                // Check if student has default values (ignored)
                boolean hasDefaultValues = (student.getMarathiAksharaLevel() == 0 && 
                                           student.getMathAksharaLevel() == 0 && 
                                           student.getEnglishAksharaLevel() == 0);
                
                if (hasDefaultValues) {
                    ignoredStudents++;
                } else {
                    // Check phase completion based on phase number
                    boolean phaseCompleted = false;
                    
                    switch (phaseNumber) {
                        case 1:
                            phaseCompleted = student.getPhase1Date() != null;
                            break;
                        case 2:
                            phaseCompleted = student.getPhase2Date() != null;
                            break;
                        case 3:
                            phaseCompleted = student.getPhase3Date() != null;
                            break;
                        case 4:
                            phaseCompleted = student.getPhase4Date() != null;
                            break;
                    }
                    
                    if (phaseCompleted) {
                        completedStudents++;
                    }
                }
            }
            
            int pendingStudents = totalStudents - completedStudents - ignoredStudents;
            
            // Create phase approval record
            PhaseApproval approval = new PhaseApproval(udiseNo, phaseNumber);
            approval.setCompletedBy(user.getUsername());
            approval.setCompletionRemarks(remarks);
            approval.setTotalStudents(totalStudents);
            approval.setCompletedStudents(completedStudents);
            approval.setPendingStudents(pendingStudents);
            approval.setIgnoredStudents(ignoredStudents);
            
            PhaseApprovalDAO approvalDAO = new PhaseApprovalDAO();
            boolean success = approvalDAO.submitPhaseForApproval(approval);
            
            if (success) {
                String message = String.format("Phase %d submitted for approval. %d/%d students completed (ignoring %d students).", 
                                             phaseNumber, completedStudents, totalStudents - ignoredStudents, ignoredStudents);
                response.getWriter().write("{\"success\": true, \"message\": \"" + message + "\"}");
            } else {
                response.getWriter().write("{\"success\": false, \"message\": \"Failed to submit phase\"}");
            }
            
        } catch (Exception e) {
            System.err.println("Error submitting phase: " + e.getMessage());
            e.printStackTrace();
            response.getWriter().write("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
}
