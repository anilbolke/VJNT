package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

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
 * Division School Contacts Analytics Servlet
 * Returns district-wise contact summary for division dashboard
 */
@WebServlet("/division-contacts-analytics")
public class DivisionSchoolContactsAnalyticsServlet extends HttpServlet {
    
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
        
        String divisionName = user.getDivisionName();
        
        JSONObject result = getDistrictWiseContactsSummary(divisionName);
        
        PrintWriter out = response.getWriter();
        out.print(result.toString());
        out.flush();
    }
    
    /**
     * Get district-wise contacts summary
     */
    private JSONObject getDistrictWiseContactsSummary(String divisionName) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // First, get districts in this division
            String districtsSql = "SELECT DISTINCT district_name FROM users WHERE division_name = ? AND user_type IN ('DISTRICT_COORDINATOR', 'DISTRICT_2ND_COORDINATOR')";
            PreparedStatement distPs = conn.prepareStatement(districtsSql);
            distPs.setString(1, divisionName);
            ResultSet distRs = distPs.executeQuery();
            
            java.util.List<String> districts = new java.util.ArrayList<>();
            while (distRs.next()) {
                districts.add(distRs.getString("district_name"));
            }
            distRs.close();
            distPs.close();
            
            if (districts.isEmpty()) {
                result.put("districts", new JSONArray());
                result.put("totalSchools", 0);
                result.put("totalContacts", 0);
                result.put("totalPrincipals", 0);
                result.put("totalVicePrincipals", 0);
                result.put("totalTeachers", 0);
                result.put("totalStaff", 0);
                result.put("totalOther", 0);
                return result;
            }
            
            // Build IN clause for districts
            StringBuilder inClause = new StringBuilder();
            for (int i = 0; i < districts.size(); i++) {
                if (i > 0) inClause.append(",");
                inClause.append("?");
            }
            
            // Get district-wise contact counts
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT sc.district_name, ");
            sql.append("COUNT(DISTINCT sc.udise_no) as school_count, ");
            sql.append("COUNT(*) as total_contacts, ");
            sql.append("SUM(CASE WHEN sc.contact_type = 'Principal' THEN 1 ELSE 0 END) as principal_count, ");
            sql.append("SUM(CASE WHEN sc.contact_type = 'Vice Principal' THEN 1 ELSE 0 END) as vice_principal_count, ");
            sql.append("SUM(CASE WHEN sc.contact_type = 'Teacher' THEN 1 ELSE 0 END) as teacher_count, ");
            sql.append("SUM(CASE WHEN sc.contact_type = 'Office Staff' THEN 1 ELSE 0 END) as staff_count, ");
            sql.append("SUM(CASE WHEN sc.contact_type = 'Other' THEN 1 ELSE 0 END) as other_count ");
            sql.append("FROM school_contacts sc ");
            sql.append("WHERE sc.district_name IN (").append(inClause).append(") ");
            sql.append("GROUP BY sc.district_name ");
            sql.append("ORDER BY sc.district_name");
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < districts.size(); i++) {
                ps.setString(i + 1, districts.get(i));
            }
            
            ResultSet rs = ps.executeQuery();
            
            JSONArray districtsArray = new JSONArray();
            int totalSchools = 0;
            int totalContacts = 0;
            int totalPrincipals = 0;
            int totalVicePrincipals = 0;
            int totalTeachers = 0;
            int totalStaff = 0;
            int totalOther = 0;
            
            while (rs.next()) {
                JSONObject district = new JSONObject();
                district.put("districtName", rs.getString("district_name"));
                district.put("schoolCount", rs.getInt("school_count"));
                district.put("totalContacts", rs.getInt("total_contacts"));
                district.put("principalCount", rs.getInt("principal_count"));
                district.put("vicePrincipalCount", rs.getInt("vice_principal_count"));
                district.put("teacherCount", rs.getInt("teacher_count"));
                district.put("staffCount", rs.getInt("staff_count"));
                district.put("otherCount", rs.getInt("other_count"));
                
                districtsArray.put(district);
                
                totalSchools += rs.getInt("school_count");
                totalContacts += rs.getInt("total_contacts");
                totalPrincipals += rs.getInt("principal_count");
                totalVicePrincipals += rs.getInt("vice_principal_count");
                totalTeachers += rs.getInt("teacher_count");
                totalStaff += rs.getInt("staff_count");
                totalOther += rs.getInt("other_count");
            }
            
            result.put("districts", districtsArray);
            result.put("totalSchools", totalSchools);
            result.put("totalContacts", totalContacts);
            result.put("totalPrincipals", totalPrincipals);
            result.put("totalVicePrincipals", totalVicePrincipals);
            result.put("totalTeachers", totalTeachers);
            result.put("totalStaff", totalStaff);
            result.put("totalOther", totalOther);
            
            rs.close();
            ps.close();
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
}
