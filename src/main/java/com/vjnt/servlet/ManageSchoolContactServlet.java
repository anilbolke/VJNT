package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.SchoolContactDAO;
import com.vjnt.dao.SchoolDAO;
import com.vjnt.model.SchoolContact;
import com.vjnt.model.School;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Servlet to manage school contacts (contact directory data, NOT login users)
 */
@WebServlet("/manage-school-contact")
@MultipartConfig
public class ManageSchoolContactServlet extends HttpServlet {
    
    private SchoolContactDAO contactDAO = new SchoolContactDAO();
    private SchoolDAO schoolDAO = new SchoolDAO();
    private Gson gson = new Gson();
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        
        Map<String, Object> result = new HashMap<>();
        
        // Check authorization - Only district coordinators allowed
        if (loggedInUser == null || 
            (!loggedInUser.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
             !loggedInUser.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR))) {
            result.put("success", false);
            result.put("message", "Unauthorized access");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        String action = request.getParameter("action");
        
        // Handle delete action
        if ("delete".equals(action)) {
            handleDelete(request, response, result);
            return;
        }
        
        // Handle add/edit action
        String mode = request.getParameter("mode");
        String contactIdStr = request.getParameter("contactId");
        String udiseNo = request.getParameter("udiseNo");
        String contactType = request.getParameter("contactType");
        String fullName = request.getParameter("fullName");
        String mobile = request.getParameter("mobile");
        String whatsapp = request.getParameter("whatsapp");
        String remarks = request.getParameter("remarks");
        String districtName = request.getParameter("districtName");
        
        // Debug logging
        System.out.println("=== ManageSchoolContactServlet Debug ===");
        System.out.println("Mode: " + mode);
        System.out.println("UDISE: [" + udiseNo + "]");
        System.out.println("ContactType: [" + contactType + "]");
        System.out.println("FullName: [" + fullName + "]");
        System.out.println("Mobile: [" + mobile + "]");
        System.out.println("WhatsApp: [" + whatsapp + "]");
        System.out.println("District: [" + districtName + "]");
        System.out.println("========================================");
        
        // Validate required fields
        if (udiseNo == null || udiseNo.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "School (UDISE) is required");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        if (contactType == null || contactType.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "Contact Type is required");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        if (fullName == null || fullName.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "Full Name is required");
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
            // Get school name
            School school = schoolDAO.getSchoolByUdise(udiseNo.trim());
            String schoolName = school != null ? school.getSchoolName() : null;
            
            // Validate: Check if this contact type already exists for this school
            List<SchoolContact> existingContactsForSchool = contactDAO.getContactsByUdise(udiseNo.trim());
            
            if ("edit".equals(mode)) {
                // Edit existing contact - check if changing to a type that already exists
                int contactId = Integer.parseInt(contactIdStr);
                SchoolContact existingContact = contactDAO.getContactById(contactId);
                
                // Check if the contact type already exists for this school (excluding current contact)
                for (SchoolContact c : existingContactsForSchool) {
                    if (c.getContactId() != contactId && 
                        c.getContactType().equals(contactType.trim()) && 
                        c.getUdiseNo().equals(udiseNo.trim())) {
                        result.put("success", false);
                        result.put("message", "A " + contactType + " already exists for this school. Each school can have only one School Coordinator and one Head Master.");
                        response.getWriter().write(gson.toJson(result));
                        return;
                    }
                }
                
                if (existingContact == null) {
                    result.put("success", false);
                    result.put("message", "Contact not found");
                    response.getWriter().write(gson.toJson(result));
                    return;
                }
                
                // Update contact details
                existingContact.setUdiseNo(udiseNo.trim());
                existingContact.setSchoolName(schoolName);
                existingContact.setDistrictName(districtName);
                existingContact.setContactType(contactType.trim());
                existingContact.setFullName(fullName.trim());
                existingContact.setMobile(mobile.trim());
                existingContact.setWhatsappNumber(whatsapp != null && !whatsapp.trim().isEmpty() ? whatsapp.trim() : null);
                existingContact.setRemarks(remarks != null && !remarks.trim().isEmpty() ? remarks.trim() : null);
                existingContact.setUpdatedBy(loggedInUser.getUsername());
                
                boolean updated = contactDAO.updateContact(existingContact);
                
                if (updated) {
                    result.put("success", true);
                    result.put("message", "Contact updated successfully!");
                } else {
                    result.put("success", false);
                    result.put("message", "Failed to update contact");
                }
                
            } else {
                // Add new contact - Check if this contact type already exists for this school
                for (SchoolContact c : existingContactsForSchool) {
                    if (c.getContactType().equals(contactType.trim()) && 
                        c.getUdiseNo().equals(udiseNo.trim())) {
                        result.put("success", false);
                        result.put("message", "A " + contactType + " already exists for this school (" + (schoolName != null ? schoolName : udiseNo) + "). Each school can have only one School Coordinator and one Head Master.");
                        response.getWriter().write(gson.toJson(result));
                        return;
                    }
                }
                
                // Add new contact
                SchoolContact newContact = new SchoolContact();
                newContact.setUdiseNo(udiseNo.trim());
                newContact.setSchoolName(schoolName);
                newContact.setDistrictName(districtName);
                newContact.setContactType(contactType.trim());
                newContact.setFullName(fullName.trim());
                newContact.setMobile(mobile.trim());
                newContact.setWhatsappNumber(whatsapp != null && !whatsapp.trim().isEmpty() ? whatsapp.trim() : null);
                newContact.setRemarks(remarks != null && !remarks.trim().isEmpty() ? remarks.trim() : null);
                newContact.setCreatedBy(loggedInUser.getUsername());
                
                boolean created = contactDAO.createContact(newContact);
                
                if (created) {
                    result.put("success", true);
                    result.put("message", "Contact created successfully!");
                } else {
                    result.put("success", false);
                    result.put("message", "Failed to create contact");
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
                             Map<String, Object> result) throws IOException {
        String contactIdStr = request.getParameter("contactId");
        
        if (contactIdStr == null || contactIdStr.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "Contact ID is required");
            response.getWriter().write(gson.toJson(result));
            return;
        }
        
        try {
            int contactId = Integer.parseInt(contactIdStr);
            boolean deleted = contactDAO.deleteContact(contactId);
            
            if (deleted) {
                result.put("success", true);
                result.put("message", "Contact deleted successfully!");
            } else {
                result.put("success", false);
                result.put("message", "Failed to delete contact");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error: " + e.getMessage());
        }
        
        response.getWriter().write(gson.toJson(result));
    }
}
