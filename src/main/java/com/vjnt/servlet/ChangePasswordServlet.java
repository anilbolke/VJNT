package com.vjnt.servlet;

import com.vjnt.dao.UserDAO;
import com.vjnt.model.User;
import com.vjnt.util.PasswordUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * Change Password Servlet
 * Handles password change functionality
 */
@WebServlet("/change-password")
public class ChangePasswordServlet extends HttpServlet {
    
    private UserDAO userDAO;
    
    @Override
    public void init() throws ServletException {
        userDAO = new UserDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Check if user is logged in
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        request.setAttribute("isFirstLogin", user.isFirstLogin());
        request.setAttribute("mustChangePassword", user.isMustChangePassword());
        
        request.getRequestDispatcher("/change-password.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Check if user is logged in
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        String currentPassword = request.getParameter("currentPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");
        
        // Validate inputs
        if (currentPassword == null || currentPassword.trim().isEmpty() ||
            newPassword == null || newPassword.trim().isEmpty() ||
            confirmPassword == null || confirmPassword.trim().isEmpty()) {
            request.setAttribute("errorMessage", "All fields are required");
            request.setAttribute("isFirstLogin", user.isFirstLogin());
            request.setAttribute("mustChangePassword", user.isMustChangePassword());
            request.getRequestDispatcher("/change-password.jsp").forward(request, response);
            return;
        }
        
        // Verify current password
        if (!user.getPassword().equals(PasswordUtil.hashPassword(currentPassword))) {
            request.setAttribute("errorMessage", "Current password is incorrect");
            request.setAttribute("isFirstLogin", user.isFirstLogin());
            request.setAttribute("mustChangePassword", user.isMustChangePassword());
            request.getRequestDispatcher("/change-password.jsp").forward(request, response);
            return;
        }
        
        // Validate new password matches confirm password
        if (!newPassword.equals(confirmPassword)) {
            request.setAttribute("errorMessage", "New password and confirm password do not match");
            request.setAttribute("isFirstLogin", user.isFirstLogin());
            request.setAttribute("mustChangePassword", user.isMustChangePassword());
            request.getRequestDispatcher("/change-password.jsp").forward(request, response);
            return;
        }
        
        // Validate password strength
        if (!PasswordUtil.isValidPassword(newPassword)) {
            request.setAttribute("errorMessage", 
                "Password must be at least 8 characters long and contain uppercase, lowercase, digit, and special character");
            request.setAttribute("isFirstLogin", user.isFirstLogin());
            request.setAttribute("mustChangePassword", user.isMustChangePassword());
            request.getRequestDispatcher("/change-password.jsp").forward(request, response);
            return;
        }
        
        // Check if new password is same as current password
        if (currentPassword.equals(newPassword)) {
            request.setAttribute("errorMessage", "New password must be different from current password");
            request.setAttribute("isFirstLogin", user.isFirstLogin());
            request.setAttribute("mustChangePassword", user.isMustChangePassword());
            request.getRequestDispatcher("/change-password.jsp").forward(request, response);
            return;
        }
        
        // Update password
        String hashedNewPassword = PasswordUtil.hashPassword(newPassword);
        if (userDAO.updatePassword(user.getUserId(), hashedNewPassword)) {
            // Update session user object
            user.setPassword(hashedNewPassword);
            user.setFirstLogin(false);
            user.setMustChangePassword(false);
            session.setAttribute("user", user);
            
            // Redirect to appropriate dashboard
            String dashboardUrl = getDashboardUrl(user.getUserType());
            request.setAttribute("successMessage", "Password changed successfully!");
            response.sendRedirect(request.getContextPath() + dashboardUrl);
        } else {
            request.setAttribute("errorMessage", "Failed to update password. Please try again.");
            request.setAttribute("isFirstLogin", user.isFirstLogin());
            request.setAttribute("mustChangePassword", user.isMustChangePassword());
            request.getRequestDispatcher("/change-password.jsp").forward(request, response);
        }
    }
    
    /**
     * Get dashboard URL based on user type
     */
    private String getDashboardUrl(User.UserType userType) {
        switch (userType) {
            case DIVISION:
                return "/division-dashboard.jsp";
            case DISTRICT_COORDINATOR:
            case DISTRICT_2ND_COORDINATOR:
                return "/district-dashboard.jsp";
            case SCHOOL_COORDINATOR:
            case HEAD_MASTER:
                return "/school-dashboard.jsp";
            default:
                return "/dashboard.jsp";
        }
    }
}
