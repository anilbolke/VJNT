package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
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
 * Division District Palak Melava Details Servlet
 * Returns school-wise Palak Melava data for a specific district
 */
@WebServlet("/division-district-palak-details")
public class DivisionDistrictPalakMelavaDetailsServlet extends HttpServlet {
    
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
        if (user == null || !user.getUserType().equals(User.UserType.DIVISION)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().print("{\"error\": \"Unauthorized access\"}");
            return;
        }
        
        String districtName = request.getParameter("district");
        String startDate = request.getParameter("startDate");
        String endDate = request.getParameter("endDate");
        
        if (districtName == null || districtName.trim().isEmpty()) {
            response.getWriter().print("{\"error\": \"District parameter is required\"}");
            return;
        }
        
        String divisionName = user.getDivisionName();
        
        JSONObject result = getDistrictSchoolsPalakMelavaData(divisionName, districtName, startDate, endDate);
        
        PrintWriter out = response.getWriter();
        out.print(result.toString());
        out.flush();
    }
    
    /**
     * Get school-wise Palak Melava data for a specific district
     */
    private JSONObject getDistrictSchoolsPalakMelavaData(String divisionName, String districtName, 
                                                         String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // First, get all schools in this district
            String schoolSql = "SELECT DISTINCT s.udise_no, s.school_name " +
                              "FROM students st " +
                              "LEFT JOIN schools s ON st.udise_no = s.udise_no " +
                              "WHERE st.district = ? AND st.division = ?";
            PreparedStatement schoolPs = conn.prepareStatement(schoolSql);
            schoolPs.setString(1, districtName);
            schoolPs.setString(2, divisionName);
            ResultSet schoolRs = schoolPs.executeQuery();
            
            List<String> udiseList = new ArrayList<>();
            Map<String, String> schoolNames = new HashMap<>();
            
            while (schoolRs.next()) {
                String udise = schoolRs.getString("udise_no");
                String schoolName = schoolRs.getString("school_name");
                if (udise != null) {
                    udiseList.add(udise);
                    schoolNames.put(udise, schoolName != null ? schoolName : udise);
                }
            }
            schoolRs.close();
            schoolPs.close();
            
            if (udiseList.isEmpty()) {
                result.put("schools", new JSONArray());
                result.put("district", districtName);
                result.put("totalSchools", 0);
                result.put("schoolsWithMeetings", 0);
                result.put("totalMeetings", 0);
                result.put("totalParents", 0);
                return result;
            }
            
            // Get Palak Melava data for these schools
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT pm.udise_no, pm.school_name, ");
            sql.append("COUNT(*) as meeting_count, ");
            sql.append("SUM(CAST(pm.total_parents_attended AS UNSIGNED)) as total_parents, ");
            sql.append("MAX(pm.meeting_date) as last_meeting_date ");
            sql.append("FROM palak_melava pm ");
            sql.append("WHERE pm.udise_no IN (");
            
            for (int i = 0; i < udiseList.size(); i++) {
                sql.append("?");
                if (i < udiseList.size() - 1) sql.append(",");
            }
            sql.append(") ");
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                sql.append("AND pm.meeting_date BETWEEN ? AND ? ");
            }
            
            sql.append("GROUP BY pm.udise_no, pm.school_name ");
            sql.append("ORDER BY meeting_count DESC, pm.school_name");
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            int paramIndex = 1;
            for (String udise : udiseList) {
                ps.setString(paramIndex++, udise);
            }
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                ps.setString(paramIndex++, startDate);
                ps.setString(paramIndex++, endDate);
            }
            
            ResultSet rs = ps.executeQuery();
            
            // Build school data map
            Map<String, JSONObject> schoolDataMap = new HashMap<>();
            int totalMeetings = 0;
            int totalParents = 0;
            
            while (rs.next()) {
                String udise = rs.getString("udise_no");
                JSONObject school = new JSONObject();
                school.put("udiseNo", udise);
                school.put("schoolName", rs.getString("school_name"));
                school.put("meetingCount", rs.getInt("meeting_count"));
                school.put("totalParents", rs.getInt("total_parents"));
                school.put("lastMeeting", rs.getString("last_meeting_date"));
                school.put("hasMeetings", true);
                
                schoolDataMap.put(udise, school);
                
                totalMeetings += rs.getInt("meeting_count");
                totalParents += rs.getInt("total_parents");
            }
            rs.close();
            ps.close();
            
            // Include all schools, even those without meetings
            JSONArray schools = new JSONArray();
            for (String udise : udiseList) {
                JSONObject school;
                if (schoolDataMap.containsKey(udise)) {
                    school = schoolDataMap.get(udise);
                } else {
                    school = new JSONObject();
                    school.put("udiseNo", udise);
                    school.put("schoolName", schoolNames.get(udise));
                    school.put("meetingCount", 0);
                    school.put("totalParents", 0);
                    school.put("lastMeeting", false);
                    school.put("hasMeetings", false);
                }
                schools.put(school);
            }
            
            result.put("schools", schools);
            result.put("district", districtName);
            result.put("totalSchools", udiseList.size());
            result.put("schoolsWithMeetings", schoolDataMap.size());
            result.put("totalMeetings", totalMeetings);
            result.put("totalParents", totalParents);
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
}
