package com.vjnt.servlet;

import com.vjnt.dao.VidnyanSetuPhaseApprovalDAO;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.Map;

/**
 * The school's real Head Master (main "user" session — VidnyanSetu has no
 * separate Head Master role) approves/rejects a submitted VidnyanSetu phase.
 * Mirrors ApprovePhaseServlet (/approve-phase) for the FLN subjects, against
 * vidnyansetu_phase_approvals instead of phase_approvals.
 */
@WebServlet("/vidnyansetu-approve-phase")
public class VidnyanSetuApprovePhaseServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final VidnyanSetuPhaseApprovalDAO approvalDAO = new VidnyanSetuPhaseApprovalDAO();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("user");
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        if (user.getUserType() != User.UserType.HEAD_MASTER) {
            session.setAttribute("errorMessage", "Only Head Master can approve VidnyanSetu phases");
            response.sendRedirect(request.getContextPath() + "/vidnyansetu-phase-approvals.jsp");
            return;
        }

        try {
            int approvalId = Integer.parseInt(request.getParameter("approvalId"));
            String action = request.getParameter("action"); // "approve" or "reject"
            String remarks = request.getParameter("remarks");

            Map<String,Object> approval = approvalDAO.getById(approvalId);
            if (approval == null || !user.getUdiseNo().equals(approval.get("udiseNo"))) {
                session.setAttribute("errorMessage", "This phase approval does not belong to your school");
                response.sendRedirect(request.getContextPath() + "/vidnyansetu-phase-approvals.jsp");
                return;
            }

            if ("reject".equals(action) && (remarks == null || remarks.trim().isEmpty())) {
                session.setAttribute("errorMessage", "Remarks are required when rejecting a phase");
                response.sendRedirect(request.getContextPath() + "/vidnyansetu-phase-approvals.jsp");
                return;
            }

            boolean success;
            String message;
            if ("approve".equals(action)) {
                success = approvalDAO.approvePhase(approvalId, user.getUsername(), remarks);
                message = success ? "Phase approved successfully!" : "Failed to approve phase";
            } else if ("reject".equals(action)) {
                success = approvalDAO.rejectPhase(approvalId, user.getUsername(), remarks);
                message = success ? "Phase rejected" : "Failed to reject phase";
            } else {
                session.setAttribute("errorMessage", "Invalid action");
                response.sendRedirect(request.getContextPath() + "/vidnyansetu-phase-approvals.jsp");
                return;
            }

            session.setAttribute(success ? "successMessage" : "errorMessage", message);
            response.sendRedirect(request.getContextPath() + "/vidnyansetu-phase-approvals.jsp");

        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("errorMessage", "Error: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/vidnyansetu-phase-approvals.jsp");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/vidnyansetu-phase-approvals.jsp");
    }
}
