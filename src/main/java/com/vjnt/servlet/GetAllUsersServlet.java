package com.vjnt.servlet;

import com.vjnt.dao.UserDAO;
import com.vjnt.model.User;
import com.google.gson.Gson;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Get All Users Servlet
 * Returns all users in JSON format for the Data Admin Dashboard
 */
@WebServlet("/getAllUsers")
public class GetAllUsersServlet extends HttpServlet {
    
    private UserDAO userDAO;
    
    @Override
    public void init() throws ServletException {
        userDAO = new UserDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        System.out.println("GetAllUsersServlet: Request received");
        
        // Set response type to JSON
        response.setContentType("application/json;charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            // Check user session
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("user") == null) {
                System.out.println("GetAllUsersServlet: User not found in session");
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "Unauthorized");
                out.println(new Gson().toJson(errorResponse));
                return;
            }
            
            // Verify user is DATA_ADMIN
            User sessionUser = (User) session.getAttribute("user");
            if (!sessionUser.getUserType().equals(User.UserType.DATA_ADMIN)) {
                System.out.println("GetAllUsersServlet: Invalid user type: " + sessionUser.getUserType());
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "Access Denied - Only DATA_ADMIN can view users");
                out.println(new Gson().toJson(errorResponse));
                return;
            }
            
            // Get all users
            List<User> users = userDAO.getAllUsers();
            System.out.println("GetAllUsersServlet: Retrieved " + users.size() + " users");
            
            // Build response with user details
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("success", true);
            responseData.put("totalUsers", users.size());
            responseData.put("users", users);
            
            String jsonResponse = new Gson().toJson(responseData);
            out.println(jsonResponse);
            out.flush();
            
        } catch (Exception e) {
            System.err.println("GetAllUsersServlet: Error - " + e.getMessage());
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Server error: " + e.getMessage());
            out.println(new Gson().toJson(errorResponse));
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}
