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
            
            // Calculate phase statistics using direct database queries
            // This matches the logic used in school-dashboard-enhanced.jsp
            StudentDAO studentDAO = new StudentDAO();
            
            // Get total active students (excluding FLN completed)
            int totalStudents = studentDAO.getTotalActiveStudentCount(udiseNo);
            
            // Get count of students who have completed this phase (phase_date IS NOT NULL)
            // This includes ALL students with phase date, even if they have 0-0-0 assessment scores
            int completedStudents = studentDAO.getPhaseCompletedCount(udiseNo, phaseNumber);
            
            // Calculate pending students
            int pendingStudents = totalStudents - completedStudents;
            
            // No more "ignored students" - this was incorrect logic that excluded students with 0-0-0
            int ignoredStudents = 0;
            
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
                String message = String.format("Phase %d submitted for approval. %d/%d students completed.", 
                                             phaseNumber, completedStudents, totalStudents);
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
