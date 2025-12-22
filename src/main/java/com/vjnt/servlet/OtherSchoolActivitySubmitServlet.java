package com.vjnt.servlet;

import com.vjnt.dao.OtherSchoolActivityDAO;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/OtherSchoolActivitySubmitServlet")
public class OtherSchoolActivitySubmitServlet extends HttpServlet {
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        User user = (User) session.getAttribute("user");
        
        if (user == null || !user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        try {
            int activityId = Integer.parseInt(request.getParameter("activityId"));
            
            OtherSchoolActivityDAO dao = new OtherSchoolActivityDAO();
            boolean submitted = dao.submitForApproval(activityId, user.getUsername());
            
            if (submitted) {
                response.sendRedirect(request.getContextPath() + 
                    "/other-school-activity.jsp?success=Activity submitted for approval");
            } else {
                response.sendRedirect(request.getContextPath() + 
                    "/other-school-activity.jsp?error=Failed to submit activity");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + 
                "/other-school-activity.jsp?error=" + e.getMessage());
        }
    }
}
