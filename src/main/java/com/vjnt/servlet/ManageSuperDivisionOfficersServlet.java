package com.vjnt.servlet;

import com.vjnt.dao.UserDAO;
import com.vjnt.model.User;
import org.json.JSONArray;
import org.json.JSONObject;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

/**
 * Manage Super Division Officers Servlet
 * Handles CRUD operations for Super Division Officer accounts
 * Only DATA_ADMIN and existing SUPER_DIVISION_OFFICER can access this
 */
@WebServlet("/manage-super-officers")
public class ManageSuperDivisionOfficersServlet extends HttpServlet {
    
    private UserDAO userDAO;
    
    @Override
    public void init() throws ServletException {
        userDAO = new UserDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        User user = (User) session.getAttribute("user");
        if (user == null || (!user.getUserType().equals(User.UserType.DATA_ADMIN) &&
                             !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        String action = request.getParameter("action");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            JSONObject result = new JSONObject();
            
            if (action == null || action.equals("list")) {
                // Get all Super Division Officers
                List<User> superOfficers = userDAO.getUsersByType(User.UserType.SUPER_DIVISION_OFFICER);
                
                JSONArray officers = new JSONArray();
                for (User officer : superOfficers) {
                    officers.put(new JSONObject()
                        .put("userId", officer.getUserId())
                        .put("username", officer.getUsername())
                        .put("fullName", officer.getFullName())
                        .put("email", officer.getEmail())
                        .put("mobile", officer.getMobile())
                        .put("isActive", officer.isActive())
                        .put("createdDate", officer.getCreatedDate())
                        .put("lastLoginDate", officer.getLastLoginDate())
                    );
                }
                
                result.put("success", true)
                      .put("count", officers.length())
                      .put("officers", officers);
                
            } else if (action.equals("create")) {
                // Create new Super Division Officer
                String username = request.getParameter("username");
                String password = request.getParameter("password");
                String fullName = request.getParameter("fullName");
                String email = request.getParameter("email");
                String mobile = request.getParameter("mobile");
                
                // Validate inputs
                if (username == null || username.trim().isEmpty() ||
                    password == null || password.trim().isEmpty() ||
                    fullName == null || fullName.trim().isEmpty()) {
                    result.put("success", false)
                          .put("message", "Username, password, and full name are required");
                    out.print(result.toString());
                    return;
                }
                
                // Check if username already exists
                if (userDAO.getUserByUsername(username) != null) {
                    result.put("success", false)
                          .put("message", "Username already exists");
                    out.print(result.toString());
                    return;
                }
                
                // Create new user
                User newOfficer = new User();
                newOfficer.setUsername(username.trim());
                newOfficer.setPassword(password.trim());
                newOfficer.setFullName(fullName.trim());
                newOfficer.setEmail(email != null ? email.trim() : null);
                newOfficer.setMobile(mobile != null ? mobile.trim() : null);
                newOfficer.setUserType(User.UserType.SUPER_DIVISION_OFFICER);
                newOfficer.setActive(true);
                newOfficer.setFirstLogin(true);
                newOfficer.setCreatedBy(user.getUsername());
                
                // Division/District/School assignments are NULL for Super Officer
                newOfficer.setDivisionName(null);
                newOfficer.setDistrictName(null);
                newOfficer.setUdiseNo(null);
                
                boolean created = userDAO.createUser(newOfficer);
                
                if (created) {
                    result.put("success", true)
                          .put("message", "Super Division Officer created successfully")
                          .put("userId", newOfficer.getUserId());
                } else {
                    result.put("success", false)
                          .put("message", "Failed to create Super Division Officer");
                }
                
            } else if (action.equals("update")) {
                // Update existing Super Division Officer
                String userIdStr = request.getParameter("userId");
                String email = request.getParameter("email");
                String mobile = request.getParameter("mobile");
                String fullName = request.getParameter("fullName");
                
                if (userIdStr == null || userIdStr.trim().isEmpty()) {
                    result.put("success", false)
                          .put("message", "User ID is required");
                    out.print(result.toString());
                    return;
                }
                
                int userId = Integer.parseInt(userIdStr);
                User officer = userDAO.getUserById(userId);
                
                if (officer == null || !officer.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER)) {
                    result.put("success", false)
                          .put("message", "Super Division Officer not found");
                    out.print(result.toString());
                    return;
                }
                
                // Update fields
                if (email != null && !email.trim().isEmpty()) {
                    officer.setEmail(email.trim());
                }
                if (mobile != null && !mobile.trim().isEmpty()) {
                    officer.setMobile(mobile.trim());
                }
                if (fullName != null && !fullName.trim().isEmpty()) {
                    officer.setFullName(fullName.trim());
                }
                
                boolean updated = userDAO.updateUser(officer);
                
                if (updated) {
                    result.put("success", true)
                          .put("message", "Super Division Officer updated successfully");
                } else {
                    result.put("success", false)
                          .put("message", "Failed to update Super Division Officer");
                }
                
            } else if (action.equals("deactivate")) {
                // Deactivate account
                String userIdStr = request.getParameter("userId");
                
                if (userIdStr == null || userIdStr.trim().isEmpty()) {
                    result.put("success", false)
                          .put("message", "User ID is required");
                    out.print(result.toString());
                    return;
                }
                
                int userId = Integer.parseInt(userIdStr);
                User officer = userDAO.getUserById(userId);
                
                if (officer == null || !officer.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER)) {
                    result.put("success", false)
                          .put("message", "Super Division Officer not found");
                    out.print(result.toString());
                    return;
                }
                
                officer.setActive(false);
                boolean updated = userDAO.updateUser(officer);
                
                if (updated) {
                    result.put("success", true)
                          .put("message", "Super Division Officer deactivated successfully");
                } else {
                    result.put("success", false)
                          .put("message", "Failed to deactivate Super Division Officer");
                }
                
            } else {
                result.put("success", false)
                      .put("message", "Unknown action: " + action);
            }
            
            out.print(result.toString());
            
        } catch (Exception e) {
            JSONObject error = new JSONObject();
            error.put("success", false)
                 .put("message", "Error: " + e.getMessage());
            out.print(error.toString());
            e.printStackTrace();
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}
