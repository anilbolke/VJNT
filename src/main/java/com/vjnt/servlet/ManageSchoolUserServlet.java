package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.UserDAO;
import com.vjnt.dao.SchoolDAO;
import com.vjnt.model.User;
import com.vjnt.model.User.UserType;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * Servlet to manage school users (School Coordinators and Head Masters)
 * Allows District Coordinators to add, edit, and delete school users
 */
@WebServlet("/manage-school-user")
public class ManageSchoolUserServlet extends HttpServlet {
    
    private UserDAO userDAO = new UserDAO();
    private Gson gson = new Gson();
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        
        Map<String, Object> result = new HashMap<>();
        
        // Check authorization
        if (loggedInUser == null || 
            (!loggedInUser.getUserType().equals(UserType.DISTRICT_COORDINATOR) && 
             !loggedInUser.getUserType().equals(UserType.DISTRICT_2ND_COORDINATOR) &&
             !loggedInUser.getUserType().equals(UserType.DIVISION))) {
            result.put("success", false);
            result.put("message", "Unauthorized access");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        String action = request.getParameter("action");
        
        // Handle delete action
        if ("delete".equals(action)) {
            handleDelete(request, response, result, loggedInUser);
            return;
        }
        
        // Handle add/edit action
        String mode = request.getParameter("mode");
        String userIdStr = request.getParameter("userId");
        String udiseNo = request.getParameter("udiseNo");
        String userTypeStr = request.getParameter("userType");
        String fullName = request.getParameter("fullName");
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String mobile = request.getParameter("mobile");
        String whatsapp = request.getParameter("whatsapp");
        String email = request.getParameter("email");
        String remarks = request.getParameter("remarks");
        String districtName = request.getParameter("districtName");
        String divisionName = request.getParameter("divisionName");
        
        // Validate required fields
        if (udiseNo == null || udiseNo.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "School (UDISE) is required");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        if (userTypeStr == null || userTypeStr.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "User Type is required");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        if (fullName == null || fullName.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "Full Name is required");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        if (username == null || username.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "Username is required");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        if (mobile == null || mobile.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "Mobile Number is required");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        // Validate mobile number format
        if (!mobile.matches("\\d{10}")) {
            result.put("success", false);
            result.put("message", "Mobile number must be 10 digits");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        // Validate WhatsApp number if provided
        if (whatsapp != null && !whatsapp.trim().isEmpty() && !whatsapp.matches("\\d{10}")) {
            result.put("success", false);
            result.put("message", "WhatsApp number must be 10 digits");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        try {
            UserType userType = UserType.valueOf(userTypeStr);
            
            if ("edit".equals(mode)) {
                // Edit existing user
                int userId = Integer.parseInt(userIdStr);
                User existingUser = userDAO.getUserById(userId);
                
                if (existingUser == null) {
                    result.put("success", false);
                    result.put("message", "User not found");
                    response.getWriter().write(gson.toJson(result));
                    return;
                }
                
                // Update user details
                existingUser.setUdiseNo(udiseNo.trim());
                existingUser.setUserType(userType);
                existingUser.setFullName(fullName.trim());
                existingUser.setUsername(username.trim());
                existingUser.setMobile(mobile.trim());
                existingUser.setWhatsappNumber(whatsapp != null && !whatsapp.trim().isEmpty() ? whatsapp.trim() : null);
                existingUser.setEmail(email != null && !email.trim().isEmpty() ? email.trim() : null);
                existingUser.setRemarks(remarks != null && !remarks.trim().isEmpty() ? remarks.trim() : null);
                existingUser.setUpdatedBy(loggedInUser.getUsername());
                
                // Update password only if provided
                if (password != null && !password.trim().isEmpty()) {
                    existingUser.setPassword(password); // Will be hashed in DAO
                }
                
                boolean updated = userDAO.updateUser(existingUser);
                
                if (updated) {
                    result.put("success", true);
                    result.put("message", "User updated successfully!");
                } else {
                    result.put("success", false);
                    result.put("message", "Failed to update user");
                }
                
            } else {
                // Add new user
                if (password == null || password.trim().isEmpty()) {
                    result.put("success", false);
                    result.put("message", "Password is required for new users");
                    response.getWriter().write(gson.toJson(result));
                    return;
                }
                
                // Check if username already exists
                if (userDAO.getUserByUsername(username.trim()) != null) {
                    result.put("success", false);
                    result.put("message", "Username already exists. Please choose a different username.");
                    response.getWriter().write(gson.toJson(result));
                    return;
                }
                
                // For DIVISION users, get district from the school
                if (districtName == null || districtName.trim().isEmpty()) {
                    SchoolDAO schoolDAO = new SchoolDAO();
                    com.vjnt.model.School school = schoolDAO.getSchoolByUdise(udiseNo.trim());
                    if (school != null) {
                        districtName = school.getDistrictName();
                    }
                }
                
                User newUser = new User();
                newUser.setUsername(username.trim());
                newUser.setPassword(password); // Will be hashed in DAO
                newUser.setUserType(userType);
                newUser.setDivisionName(divisionName);
                newUser.setDistrictName(districtName);
                newUser.setUdiseNo(udiseNo.trim());
                newUser.setFullName(fullName.trim());
                newUser.setMobile(mobile.trim());
                newUser.setWhatsappNumber(whatsapp != null && !whatsapp.trim().isEmpty() ? whatsapp.trim() : null);
                newUser.setEmail(email != null && !email.trim().isEmpty() ? email.trim() : null);
                newUser.setRemarks(remarks != null && !remarks.trim().isEmpty() ? remarks.trim() : null);
                newUser.setFirstLogin(true);
                newUser.setMustChangePassword(true);
                newUser.setActive(true);
                newUser.setCreatedBy(loggedInUser.getUsername());
                
                boolean created = userDAO.createUser(newUser);
                
                if (created) {
                    result.put("success", true);
                    result.put("message", "User created successfully!");
                } else {
                    result.put("success", false);
                    result.put("message", "Failed to create user");
                }
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error: " + e.getMessage());
        }
        
        response.getWriter().write(gson.toJson(result));
    }
    
    private void handleDelete(HttpServletRequest request, HttpServletResponse response, 
                             Map<String, Object> result, User loggedInUser) throws IOException {
        String userIdStr = request.getParameter("userId");
        
        if (userIdStr == null || userIdStr.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "User ID is required");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        try {
            int userId = Integer.parseInt(userIdStr);
            boolean deleted = userDAO.deleteUser(userId);
            
            if (deleted) {
                result.put("success", true);
                result.put("message", "User deleted successfully!");
            } else {
                result.put("success", false);
                result.put("message", "Failed to delete user");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error: " + e.getMessage());
        }
        
        response.getWriter().write(gson.toJson(result));
    }
}
