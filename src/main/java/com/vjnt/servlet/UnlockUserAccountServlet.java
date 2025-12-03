package com.vjnt.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.gson.JsonObject;
import com.vjnt.util.DatabaseConnection;
import java.sql.*;

@WebServlet("/UnlockUserAccountServlet")
public class UnlockUserAccountServlet extends HttpServlet {
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String username = request.getParameter("username");
        
        if (username == null || username.trim().isEmpty()) {
            sendJsonResponse(response, false, "Username is required");
            return;
        }
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            // Unlock the user account
            String sql = "UPDATE users SET failed_login_attempts = 0, account_locked = 0, " +
                        "locked_date = NULL WHERE username = ?";
            
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, username);
                int rows = pstmt.executeUpdate();
                
                if (rows > 0) {
                    sendJsonResponse(response, true, "Account unlocked successfully! User can now login.");
                } else {
                    sendJsonResponse(response, false, "User not found.");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            sendJsonResponse(response, false, "Database error: " + e.getMessage());
        }
    }
    
    private void sendJsonResponse(HttpServletResponse response, boolean success, String message) 
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        JsonObject json = new JsonObject();
        json.addProperty("success", success);
        json.addProperty("message", message);
        
        response.getWriter().write(json.toString());
    }
}
