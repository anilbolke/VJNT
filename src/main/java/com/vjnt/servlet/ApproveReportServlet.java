package com.vjnt.servlet;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.google.gson.JsonObject;
import com.vjnt.util.DatabaseConnection;

@WebServlet("/ApproveReportServlet")
public class ApproveReportServlet extends HttpServlet {
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        JsonObject jsonResponse = new JsonObject();
        
        // Log for debugging
        System.out.println("=== ApproveReportServlet Called ===");
        
        if (session == null || session.getAttribute("userId") == null) {
            System.out.println("ERROR: Unauthorized - No session or userId");
            jsonResponse.addProperty("success", false);
            jsonResponse.addProperty("message", "Unauthorized");
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write(jsonResponse.toString());
            return;
        }
        
        Integer userId = (Integer) session.getAttribute("userId");
        String approvalIdStr = request.getParameter("approvalId");
        String action = request.getParameter("action");
        String remarks = request.getParameter("remarks");
        
        System.out.println("User ID: " + userId);
        System.out.println("Approval ID param: " + approvalIdStr);
        System.out.println("Action: " + action);
        System.out.println("Remarks: " + remarks);
        
        if (approvalIdStr == null || approvalIdStr.trim().isEmpty()) {
            System.out.println("ERROR: Missing approval ID");
            jsonResponse.addProperty("success", false);
            jsonResponse.addProperty("message", "Missing approval ID");
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write(jsonResponse.toString());
            return;
        }
        
        int approvalId = Integer.parseInt(approvalIdStr);
        
        // Convert action to status
        String status = "";
        if ("approve".equalsIgnoreCase(action)) {
            status = "APPROVED";
        } else if ("reject".equalsIgnoreCase(action)) {
            status = "REJECTED";
        } else {
            System.out.println("ERROR: Invalid action - " + action);
            jsonResponse.addProperty("success", false);
            jsonResponse.addProperty("message", "Invalid action: " + action);
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write(jsonResponse.toString());
            return;
        }
        
        System.out.println("Converted status: " + status);
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            System.out.println("Database connection obtained");
            
            String sql = "UPDATE report_approvals SET " +
                        "approval_status = ?, " +
                        "approved_by = ?, " +
                        "approval_date = NOW(), " +
                        "approval_remarks = ? " +
                        "WHERE approval_id = ?";
            
            System.out.println("SQL: " + sql);
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, status);
            stmt.setInt(2, userId);
            stmt.setString(3, remarks);
            stmt.setInt(4, approvalId);
            
            System.out.println("Executing UPDATE...");
            int rows = stmt.executeUpdate();
            System.out.println("Rows updated: " + rows);
            
            if (rows > 0) {
                System.out.println("SUCCESS: Status updated to " + status);
                jsonResponse.addProperty("success", true);
                jsonResponse.addProperty("message", "Status updated successfully");
            } else {
                System.out.println("WARNING: No rows updated - approval_id may not exist: " + approvalId);
                jsonResponse.addProperty("success", false);
                jsonResponse.addProperty("message", "No rows updated - approval_id may not exist");
            }
            
        } catch (Exception e) {
            System.out.println("ERROR: Exception occurred");
            e.printStackTrace();
            jsonResponse.addProperty("success", false);
            jsonResponse.addProperty("message", "Error: " + e.getMessage());
        }
        
        System.out.println("=== End ApproveReportServlet ===");
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(jsonResponse.toString());
    }
}
