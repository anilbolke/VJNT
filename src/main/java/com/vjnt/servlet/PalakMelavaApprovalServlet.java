package com.vjnt.servlet;

import com.vjnt.dao.PalakMelavaDAO;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;

@WebServlet("/palak-melava-approval")
public class PalakMelavaApprovalServlet extends HttpServlet {
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            out.print("{\"success\": false, \"message\": \"Not authenticated\"}");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        if (!user.getUserType().equals(User.UserType.HEAD_MASTER)) {
            out.print("{\"success\": false, \"message\": \"Access denied. Only Head Masters can approve.\"}");
            return;
        }
        
        try {
            String action = request.getParameter("action");
            int melavaId = Integer.parseInt(request.getParameter("melavaId"));
            String remarks = request.getParameter("remarks");
            
            PalakMelavaDAO dao = new PalakMelavaDAO();
            boolean success = false;
            String message = "";
            
            if ("approve".equals(action)) {
                success = dao.approve(melavaId, user.getUsername(), remarks);
                message = success ? "Approved successfully" : "Failed to approve";
            } else if ("reject".equals(action)) {
                success = dao.reject(melavaId, user.getUsername(), remarks);
                message = success ? "Rejected successfully" : "Failed to reject";
            } else {
                out.print("{\"success\": false, \"message\": \"Invalid action\"}");
                return;
            }
            
            if (success) {
                out.print("{\"success\": true, \"message\": \"" + message + "\"}");
            } else {
                out.print("{\"success\": false, \"message\": \"" + message + "\"}");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
}
