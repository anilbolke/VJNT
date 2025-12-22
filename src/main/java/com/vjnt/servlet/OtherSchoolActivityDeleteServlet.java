package com.vjnt.servlet;

import com.vjnt.dao.OtherSchoolActivityDAO;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/OtherSchoolActivityDeleteServlet")
public class OtherSchoolActivityDeleteServlet extends HttpServlet {
    
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
            boolean deleted = dao.delete(activityId);
            
            if (deleted) {
                response.sendRedirect(request.getContextPath() + 
                    "/other-school-activity.jsp?success=Activity deleted successfully");
            } else {
                response.sendRedirect(request.getContextPath() + 
                    "/other-school-activity.jsp?error=Failed to delete activity");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + 
                "/other-school-activity.jsp?error=" + e.getMessage());
        }
    }
}
