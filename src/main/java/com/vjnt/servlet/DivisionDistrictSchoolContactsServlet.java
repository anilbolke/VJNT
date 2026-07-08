package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.json.JSONArray;
import org.json.JSONObject;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

/**
 * Division District School Contacts Servlet
 * Returns school-wise contact details for a specific district
 */
@WebServlet("/division-district-contacts")
public class DivisionDistrictSchoolContactsServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession session = request.getSession(false);
        if (session == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().print("{\"error\": \"Session expired\"}");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        if (user == null || (!user.getUserType().equals(User.UserType.DIVISION) && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().print("{\"error\": \"Unauthorized access\"}");
            return;
        }
        
        String districtName = request.getParameter("district");
        
        if ((districtName == null || districtName.trim().isEmpty()) && user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
            response.getWriter().print("{\"error\": \"District parameter is required\"}");
            return;
        }
        
        String divisionName = user.getDivisionName();
        if (user.getUserType() == User.UserType.SUPER_DIVISION_OFFICER) {
            divisionName = null; // SDO can access all divisions
            if (districtName != null && districtName.trim().isEmpty()) districtName = null;
        }
        
        JSONObject result = getDistrictSchoolContacts(divisionName, districtName);
        
        PrintWriter out = response.getWriter();
        out.print(result.toString());
        out.flush();
    }
    
    /**
     * Get all school contacts for a specific district
     */
    private JSONObject getDistrictSchoolContacts(String divisionName, String districtName) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Verify district belongs to this division (skip for SDO)
            if (divisionName != null) {
                String verifySQL = "SELECT COUNT(*) as count FROM users WHERE division_name = ? AND district_name = ? AND user_type IN ('DISTRICT_COORDINATOR', 'DISTRICT_2ND_COORDINATOR')";
                PreparedStatement verifyPs = conn.prepareStatement(verifySQL);
                verifyPs.setString(1, divisionName);
                verifyPs.setString(2, districtName);
                ResultSet verifyRs = verifyPs.executeQuery();
                
                boolean isValidDistrict = false;
                if (verifyRs.next()) {
                    isValidDistrict = verifyRs.getInt("count") > 0;
                }
                verifyRs.close();
                verifyPs.close();
                
                if (!isValidDistrict) {
                    result.put("error", "District does not belong to this division");
                    return result;
                }
            }
            
            // Get all contacts for this district (or across districts if districtName is null)
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT contact_id, udise_no, school_name, district_name, contact_type, full_name, mobile, whatsapp_number, remarks, created_date FROM school_contacts ");
            if (districtName != null) {
                sql.append("WHERE district_name = ? ");
            }
            sql.append("ORDER BY udise_no, contact_type, full_name");

            PreparedStatement ps = conn.prepareStatement(sql.toString());
            if (districtName != null) {
                ps.setString(1, districtName);
            }

            ResultSet rs = ps.executeQuery();
            
            JSONArray contacts = new JSONArray();
            int totalContacts = 0;
            int schoolsWithContacts = 0;
            String lastUdise = "";
            
            while (rs.next()) {
                JSONObject contact = new JSONObject();
                contact.put("contactId", rs.getInt("contact_id"));
                contact.put("udiseNo", rs.getString("udise_no"));
                contact.put("schoolName", rs.getString("school_name"));
                contact.put("districtName", rs.getString("district_name"));
                contact.put("contactType", rs.getString("contact_type"));
                contact.put("fullName", rs.getString("full_name"));
                contact.put("mobile", rs.getString("mobile"));
                contact.put("whatsappNumber", rs.getString("whatsapp_number"));
                contact.put("remarks", rs.getString("remarks"));
                contact.put("createdAt", rs.getString("created_date"));
                
                contacts.put(contact);
                totalContacts++;
                
                // Count unique schools
                String currentUdise = rs.getString("udise_no");
                if (!currentUdise.equals(lastUdise)) {
                    schoolsWithContacts++;
                    lastUdise = currentUdise;
                }
            }
            
            result.put("contacts", contacts);
            result.put("district", districtName);
            result.put("totalContacts", totalContacts);
            result.put("schoolsWithContacts", schoolsWithContacts);
            
            rs.close();
            ps.close();
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
}
