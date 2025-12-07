package com.vjnt.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.vjnt.dao.UserDAO;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Servlet to get user details by ID
 */
@WebServlet("/get-user")
public class GetUserServlet extends HttpServlet {
    
    private UserDAO userDAO = new UserDAO();
    private Gson gson = new Gson();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String userIdStr = request.getParameter("userId");
        JsonObject result = new JsonObject();
        
        if (userIdStr == null || userIdStr.trim().isEmpty()) {
            result.addProperty("success", false);
            result.addProperty("message", "User ID is required");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        try {
            int userId = Integer.parseInt(userIdStr);
            User user = userDAO.getUserById(userId);
            
            if (user != null) {
                JsonObject userJson = new JsonObject();
                userJson.addProperty("userId", user.getUserId());
                userJson.addProperty("username", user.getUsername());
                userJson.addProperty("userType", user.getUserType().name());
                userJson.addProperty("udiseNo", user.getUdiseNo());
                userJson.addProperty("fullName", user.getFullName());
                userJson.addProperty("mobile", user.getMobile());
                userJson.addProperty("whatsappNumber", user.getWhatsappNumber());
                userJson.addProperty("email", user.getEmail());
                userJson.addProperty("remarks", user.getRemarks());
                userJson.addProperty("isActive", user.isActive());
                
                result.addProperty("success", true);
                result.add("user", userJson);
            } else {
                result.addProperty("success", false);
                result.addProperty("message", "User not found");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            result.addProperty("success", false);
            result.addProperty("message", "Error: " + e.getMessage());
        }
        
        response.getWriter().write(gson.toJson(result));
    }
}
