package com.vjnt.servlet;

import com.vjnt.dao.UserDAO;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * Login Servlet
 * Handles user authentication
 */
@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    
    private UserDAO userDAO;
    
    @Override
    public void init() throws ServletException {
        userDAO = new UserDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Forward to login page
        request.getRequestDispatcher("/login.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        
        // Validate input
        if (username == null || username.trim().isEmpty() ||
            password == null || password.trim().isEmpty()) {
            request.setAttribute("errorMessage", "Username and password are required");
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }
        
        // Authenticate user
        User user = userDAO.authenticateUser(username.trim(), password);
        
        if (user != null) {
            // Create session
            HttpSession session = request.getSession();
            session.setAttribute("user", user);
            session.setAttribute("userId", user.getUserId());
            session.setAttribute("username", user.getUsername());
            session.setAttribute("userType", user.getUserType().name());
            session.setMaxInactiveInterval(30 * 60); // 30 minutes
            
            // Check if first login or must change password
            if (user.isFirstLogin() || user.isMustChangePassword()) {
                response.sendRedirect(request.getContextPath() + "/change-password");
            } else {
                // Redirect to dashboard based on user type
                String dashboardUrl = getDashboardUrl(user.getUserType());
                response.sendRedirect(request.getContextPath() + dashboardUrl);
            }
            
        } else {
            // Authentication failed
            User checkUser = userDAO.findByUsername(username.trim());
            String errorMessage = "Invalid username or password";
            
            if (checkUser != null && checkUser.isAccountLocked()) {
                errorMessage = "Your account has been locked due to multiple failed login attempts. Please contact administrator.";
            } else if (checkUser != null && !checkUser.isActive()) {
                errorMessage = "Your account is inactive. Please contact administrator.";
            }
            
            request.setAttribute("errorMessage", errorMessage);
            request.getRequestDispatcher("/login.jsp").forward(request, response);
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
                return "/school-dashboard-enhanced.jsp";
            case DATA_ADMIN:
                return "/data-admin-dashboard.jsp";
            default:
                return "/dashboard.jsp";
        }
    }
}
