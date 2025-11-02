package com.vjnt.servlet;

import com.vjnt.dao.UserDAO;
import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;

@WebServlet("/debug")
public class DebugServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        
        out.println("<html><head><title>Debug Info</title></head><body>");
        out.println("<h1>VJNT Debug Information</h1>");
        
        // Test database connection
        out.println("<h2>1. Database Connection Test</h2>");
        try {
            Connection conn = DatabaseConnection.getConnection();
            if (conn != null && !conn.isClosed()) {
                out.println("<p style='color:green'>✓ Database connection successful!</p>");
                conn.close();
            } else {
                out.println("<p style='color:red'>✗ Database connection failed!</p>");
            }
        } catch (Exception e) {
            out.println("<p style='color:red'>✗ Error: " + e.getMessage() + "</p>");
            e.printStackTrace(out);
        }
        
        // Test user authentication
        out.println("<h2>2. Authentication Test (admin/admin123)</h2>");
        try {
            UserDAO userDAO = new UserDAO();
            User user = userDAO.authenticateUser("admin", "admin123");
            
            if (user != null) {
                out.println("<p style='color:green'>✓ Authentication successful!</p>");
                out.println("<p>User ID: " + user.getUserId() + "</p>");
                out.println("<p>Username: " + user.getUsername() + "</p>");
                out.println("<p>User Type: " + user.getUserType() + "</p>");
                out.println("<p>Active: " + user.isActive() + "</p>");
                out.println("<p>Account Locked: " + user.isAccountLocked() + "</p>");
                out.println("<p>First Login: " + user.isFirstLogin() + "</p>");
                out.println("<p>Must Change Password: " + user.isMustChangePassword() + "</p>");
            } else {
                out.println("<p style='color:red'>✗ Authentication failed!</p>");
                
                // Check if user exists
                User checkUser = userDAO.findByUsername("admin");
                if (checkUser != null) {
                    out.println("<p style='color:orange'>User exists but authentication failed</p>");
                    out.println("<p>Password in DB: " + checkUser.getPassword() + "</p>");
                } else {
                    out.println("<p style='color:red'>User 'admin' not found in database</p>");
                }
            }
        } catch (Exception e) {
            out.println("<p style='color:red'>✗ Error: " + e.getMessage() + "</p>");
            e.printStackTrace(out);
        }
        
        out.println("</body></html>");
    }
}
