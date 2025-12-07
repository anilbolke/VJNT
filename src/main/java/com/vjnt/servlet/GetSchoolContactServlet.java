package com.vjnt.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.vjnt.dao.SchoolContactDAO;
import com.vjnt.model.SchoolContact;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Servlet to get school contact details by ID
 */
@WebServlet("/get-school-contact")
public class GetSchoolContactServlet extends HttpServlet {
    
    private SchoolContactDAO contactDAO = new SchoolContactDAO();
    private Gson gson = new Gson();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String contactIdStr = request.getParameter("contactId");
        JsonObject result = new JsonObject();
        
        if (contactIdStr == null || contactIdStr.trim().isEmpty()) {
            result.addProperty("success", false);
            result.addProperty("message", "Contact ID is required");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        try {
            int contactId = Integer.parseInt(contactIdStr);
            SchoolContact contact = contactDAO.getContactById(contactId);
            
            if (contact != null) {
                JsonObject contactJson = new JsonObject();
                contactJson.addProperty("contactId", contact.getContactId());
                contactJson.addProperty("udiseNo", contact.getUdiseNo());
                contactJson.addProperty("schoolName", contact.getSchoolName());
                contactJson.addProperty("contactType", contact.getContactType());
                contactJson.addProperty("fullName", contact.getFullName());
                contactJson.addProperty("mobile", contact.getMobile());
                contactJson.addProperty("whatsappNumber", contact.getWhatsappNumber());
                contactJson.addProperty("remarks", contact.getRemarks());
                
                result.addProperty("success", true);
                result.add("contact", contactJson);
            } else {
                result.addProperty("success", false);
                result.addProperty("message", "Contact not found");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            result.addProperty("success", false);
            result.addProperty("message", "Error: " + e.getMessage());
        }
        
        response.getWriter().write(gson.toJson(result));
    }
}
