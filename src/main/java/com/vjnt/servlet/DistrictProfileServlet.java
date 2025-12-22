package com.vjnt.servlet;

import com.vjnt.dao.UserDAO;
import com.vjnt.model.User;
import com.vjnt.util.PasswordUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * District Profile Servlet
 * Handles district profile viewing and password reset functionality
 */
@WebServlet("/district-profile")
public class DistrictProfileServlet extends HttpServlet {
    
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
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        
        // Check if user is district coordinator
        if (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
            !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        // Forward to profile page
        request.getRequestDispatcher("/district-profile.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Check if user is logged in
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        
        // Check if user is district coordinator
        if (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
            !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        String action = request.getParameter("action");
        
        if ("resetPassword".equals(action)) {
            handlePasswordReset(request, response, user);
        } else {
            request.setAttribute("errorMessage", "Invalid action");
            request.getRequestDispatcher("/district-profile.jsp").forward(request, response);
        }
    }
    
    /**
     * Handle password reset
     */
    private void handlePasswordReset(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException {
        
        String currentPassword = request.getParameter("currentPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");
        
        // Validate inputs
        if (currentPassword == null || currentPassword.trim().isEmpty() ||
            newPassword == null || newPassword.trim().isEmpty() ||
            confirmPassword == null || confirmPassword.trim().isEmpty()) {
            request.setAttribute("errorMessage", "All fields are required");
            request.getRequestDispatcher("/district-profile.jsp").forward(request, response);
            return;
        }
        
        // Verify current password
        if (!user.getPassword().equals(PasswordUtil.hashPassword(currentPassword))) {
            request.setAttribute("errorMessage", "Current password is incorrect");
            request.getRequestDispatcher("/district-profile.jsp").forward(request, response);
            return;
        }
        
        // Validate new password matches confirm password
        if (!newPassword.equals(confirmPassword)) {
            request.setAttribute("errorMessage", "New password and confirm password do not match");
            request.getRequestDispatcher("/district-profile.jsp").forward(request, response);
            return;
        }
        
        // Validate password strength
        if (!PasswordUtil.isValidPassword(newPassword)) {
            request.setAttribute("errorMessage", 
                "Password must be at least 8 characters long and contain uppercase, lowercase, digit, and special character");
            request.getRequestDispatcher("/district-profile.jsp").forward(request, response);
            return;
        }
        
        // Check if new password is same as current password
        if (currentPassword.equals(newPassword)) {
            request.setAttribute("errorMessage", "New password must be different from current password");
            request.getRequestDispatcher("/district-profile.jsp").forward(request, response);
            return;
        }
        
        // Update password
        boolean success = userDAO.updatePassword(user.getUserId(), newPassword);
        
        if (success) {
            // Update user object in session
            user.setPassword(PasswordUtil.hashPassword(newPassword));
            user.setFirstLogin(false);
            user.setMustChangePassword(false);
            request.getSession().setAttribute("user", user);
            
            request.setAttribute("successMessage", "Password changed successfully!");
            request.getRequestDispatcher("/district-profile.jsp").forward(request, response);
        } else {
            request.setAttribute("errorMessage", "Failed to change password. Please try again.");
            request.getRequestDispatcher("/district-profile.jsp").forward(request, response);
        }
    }
}
