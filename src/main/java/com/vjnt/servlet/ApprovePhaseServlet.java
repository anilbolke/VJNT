package com.vjnt.servlet;

import com.vjnt.dao.PhaseApprovalDAO;
import com.vjnt.model.PhaseApproval;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Servlet to approve/reject phase by Head Master
 */
@WebServlet("/approve-phase")
public class ApprovePhaseServlet extends HttpServlet {
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("text/html;charset=UTF-8");
        
        // Check authentication
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        
        // Only Head Master can approve
        if (!user.getUserType().equals(User.UserType.HEAD_MASTER)) {
            session.setAttribute("errorMessage", "Only Head Master can approve phases");
            response.sendRedirect(request.getContextPath() + "/phase-approvals.jsp");
            return;
        }
        
        try {
            // Get parameters from form
            String approvalIdStr = request.getParameter("approvalId");
            String action = request.getParameter("action"); // "approve" or "reject"
            String remarks = request.getParameter("remarks");
            
            if (approvalIdStr == null || action == null) {
                session.setAttribute("errorMessage", "Missing required parameters");
                response.sendRedirect(request.getContextPath() + "/phase-approvals.jsp");
                return;
            }
            
            int approvalId = Integer.parseInt(approvalIdStr);
            String approvedBy = user.getUsername();
            
            // Validate remarks for rejection
            if ("reject".equals(action) && (remarks == null || remarks.trim().isEmpty())) {
                session.setAttribute("errorMessage", "Remarks are required when rejecting a phase");
                response.sendRedirect(request.getContextPath() + "/phase-approvals.jsp");
                return;
            }
            
            PhaseApprovalDAO approvalDAO = new PhaseApprovalDAO();
            boolean success = false;
            String message = "";
            
            if ("approve".equals(action)) {
                success = approvalDAO.approvePhase(approvalId, approvedBy, remarks);
                message = success ? 
                    "✅ Phase approved successfully!" : 
                    "❌ Failed to approve phase";
            } else if ("reject".equals(action)) {
                success = approvalDAO.rejectPhase(approvalId, approvedBy, remarks);
                message = success ? 
                    "✅ Phase rejected successfully" : 
                    "❌ Failed to reject phase";
            }
            
            if (success) {
                session.setAttribute("successMessage", message);
            } else {
                session.setAttribute("errorMessage", message);
            }
            
            response.sendRedirect(request.getContextPath() + "/phase-approvals.jsp");
            
        } catch (Exception e) {
            System.err.println("Error approving phase: " + e.getMessage());
            e.printStackTrace();
            session.setAttribute("errorMessage", "Error: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/phase-approvals.jsp");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/phase-approvals.jsp");
    }
}
