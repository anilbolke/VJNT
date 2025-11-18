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

@WebServlet("/palak-melava-submit")
public class PalakMelavaSubmitServlet extends HttpServlet {
    
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
        if (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) {
            out.print("{\"success\": false, \"message\": \"Access denied\"}");
            return;
        }
        
        try {
            int melavaId = Integer.parseInt(request.getParameter("melavaId"));
            
            PalakMelavaDAO dao = new PalakMelavaDAO();
            boolean success = dao.submitForApproval(melavaId, user.getUsername());
            
            if (success) {
                out.print("{\"success\": true, \"message\": \"Submitted for approval successfully\"}");
            } else {
                out.print("{\"success\": false, \"message\": \"Failed to submit\"}");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
}
