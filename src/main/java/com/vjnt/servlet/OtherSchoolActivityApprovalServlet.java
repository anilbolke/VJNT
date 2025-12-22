package com.vjnt.servlet;

import com.vjnt.dao.OtherSchoolActivityDAO;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/OtherSchoolActivityApprovalServlet")
public class OtherSchoolActivityApprovalServlet extends HttpServlet {
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        User user = (User) session.getAttribute("user");
        
        if (user == null || !user.getUserType().equals(User.UserType.HEAD_MASTER)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        try {
            int activityId = Integer.parseInt(request.getParameter("activityId"));
            String action = request.getParameter("action");
            String remarks = request.getParameter("remarks");
            
            OtherSchoolActivityDAO dao = new OtherSchoolActivityDAO();
            boolean success = false;
            
            if ("approve".equals(action)) {
                success = dao.approve(activityId, user.getUsername(), remarks);
                if (success) {
                    response.sendRedirect(request.getContextPath() + 
                        "/other-school-activity-approvals.jsp?success=Activity approved successfully");
                }
            } else if ("reject".equals(action)) {
                success = dao.reject(activityId, user.getUsername(), remarks);
                if (success) {
                    response.sendRedirect(request.getContextPath() + 
                        "/other-school-activity-approvals.jsp?success=Activity rejected");
                }
            }
            
            if (!success) {
                response.sendRedirect(request.getContextPath() + 
                    "/other-school-activity-approvals.jsp?error=Failed to process approval");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + 
                "/other-school-activity-approvals.jsp?error=" + e.getMessage());
        }
    }
}
