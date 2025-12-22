package com.vjnt.servlet;

import com.vjnt.dao.UserDAO;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

/**
 * District Credentials Servlet
 * Displays district coordinator credentials and allows managing school coordinator passwords
 */
@WebServlet("/district-credentials")
public class DistrictCredentialsServlet extends HttpServlet {
    
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
        
        // Get all school coordinators in this district
        List<User> allUsers = userDAO.getUsersByDistrict(user.getDistrictName());
        List<User> schoolCoordinators = allUsers.stream()
            .filter(u -> u.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) || 
                        u.getUserType().equals(User.UserType.HEAD_MASTER))
            .collect(Collectors.toList());
        
        request.setAttribute("schoolCoordinators", schoolCoordinators);
        
        // Forward to credentials page
        request.getRequestDispatcher("/district-credentials.jsp").forward(request, response);
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
        
        if ("resetSchoolPassword".equals(action)) {
            handleSchoolPasswordReset(request, response, user);
        } else {
            request.setAttribute("errorMessage", "Invalid action");
            doGet(request, response);
        }
    }
    
    /**
     * Handle password reset for school coordinators
     */
    private void handleSchoolPasswordReset(HttpServletRequest request, HttpServletResponse response, User districtUser)
            throws ServletException, IOException {
        
        String schoolUserId = request.getParameter("schoolUserId");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");
        
        // Validate inputs
        if (schoolUserId == null || schoolUserId.trim().isEmpty() ||
            newPassword == null || newPassword.trim().isEmpty() ||
            confirmPassword == null || confirmPassword.trim().isEmpty()) {
            request.setAttribute("errorMessage", "All fields are required");
            doGet(request, response);
            return;
        }
        
        // Validate new password matches confirm password
        if (!newPassword.equals(confirmPassword)) {
            request.setAttribute("errorMessage", "New password and confirm password do not match");
            doGet(request, response);
            return;
        }
        
        // Validate password length (minimum 6 characters)
        if (newPassword.length() < 6) {
            request.setAttribute("errorMessage", "Password must be at least 6 characters long");
            doGet(request, response);
            return;
        }
        
        try {
            int userId = Integer.parseInt(schoolUserId);
            
            // Verify that this user belongs to the district
            User schoolUser = userDAO.getUserById(userId);
            if (schoolUser == null) {
                request.setAttribute("errorMessage", "School coordinator not found");
                doGet(request, response);
                return;
            }
            
            if (!schoolUser.getDistrictName().equals(districtUser.getDistrictName())) {
                request.setAttribute("errorMessage", "You can only reset passwords for coordinators in your district");
                doGet(request, response);
                return;
            }
            
            if (!schoolUser.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
                !schoolUser.getUserType().equals(User.UserType.HEAD_MASTER)) {
                request.setAttribute("errorMessage", "You can only reset passwords for school coordinators");
                doGet(request, response);
                return;
            }
            
            // Update password
            boolean success = userDAO.updatePassword(userId, newPassword);
            
            if (success) {
                request.setAttribute("successMessage", 
                    "Password reset successfully for " + schoolUser.getUsername() + "!");
                doGet(request, response);
            } else {
                request.setAttribute("errorMessage", "Failed to reset password. Please try again.");
                doGet(request, response);
            }
            
        } catch (NumberFormatException e) {
            request.setAttribute("errorMessage", "Invalid user ID");
            doGet(request, response);
        }
    }
}
