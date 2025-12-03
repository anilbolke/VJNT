package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.PalakMelavaDAO;
import com.vjnt.model.PalakMelava;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.Map;

@WebServlet("/palak-melava-data")
public class PalakMelavaDataServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
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
            int melavaId = Integer.parseInt(request.getParameter("id"));
            
            PalakMelavaDAO dao = new PalakMelavaDAO();
            PalakMelava melava = dao.getById(melavaId);
            
            if (melava != null) {
                Map<String, Object> result = new HashMap<>();
                result.put("success", true);
                
                Map<String, Object> melavaData = new HashMap<>();
                melavaData.put("melavaId", melava.getMelavaId());
                melavaData.put("meetingDate", melava.getMeetingDate().toString());
                melavaData.put("chiefAttendeeInfo", melava.getChiefAttendeeInfo());
                melavaData.put("totalParentsAttended", melava.getTotalParentsAttended());
                melavaData.put("photo1Path", melava.getPhoto1Path());
                melavaData.put("photo2Path", melava.getPhoto2Path());
                melavaData.put("approvalDate", melava.getApprovalDate() != null ? melava.getApprovalDate().toString() : "");
                melavaData.put("approvedBy", melava.getApprovedBy() != null ? melava.getApprovedBy() : "");
                melavaData.put("approvalRemarks", melava.getApprovalRemarks() != null ? melava.getApprovalRemarks() : "");
                melavaData.put("status", melava.getStatus());
                
                result.put("melava", melavaData);
                
                Gson gson = new Gson();
                out.print(gson.toJson(result));
            } else {
                out.print("{\"success\": false, \"message\": \"Record not found\"}");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
}
