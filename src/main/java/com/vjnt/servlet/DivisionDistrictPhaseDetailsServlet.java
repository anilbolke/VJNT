package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.SimpleDateFormat;

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
 * Division District Phase Details Servlet
 * Returns school-wise phase completion data for a specific district
 */
@WebServlet("/division-district-phase-details")
public class DivisionDistrictPhaseDetailsServlet extends HttpServlet {
    
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
        String phaseParam = request.getParameter("phase");
        String startDate = request.getParameter("startDate");
        String endDate = request.getParameter("endDate");
        
        // If district missing: allow only SUPER_DIVISION_OFFICER to request across all districts
        if (districtName == null || districtName.trim().isEmpty()) {
            if (user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
                response.getWriter().print("{\"error\": \"District parameter is required\"}");
                return;
            }
            districtName = null; // SDO can request across all districts
        }
        
        int phase = 1;
        try {
            if (phaseParam != null && !phaseParam.trim().isEmpty()) {
                phase = Integer.parseInt(phaseParam);
            }
        } catch (NumberFormatException e) {
            response.getWriter().print("{\"error\": \"Invalid phase number\"}");
            return;
        }
        
        String divisionName = user.getDivisionName();
        if (user.getUserType() == User.UserType.SUPER_DIVISION_OFFICER) {
            divisionName = null; // SDO can access all divisions
        }
        
        JSONObject result = getDistrictSchoolsPhaseData(divisionName, districtName, phase, startDate, endDate);
        
        PrintWriter out = response.getWriter();
        out.print(result.toString());
        out.flush();
    }
    
    /**
     * Get school-wise phase completion data for a specific district
     */
    private JSONObject getDistrictSchoolsPhaseData(String divisionName, String districtName, 
                                                   int phase, String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get schools from this district with phase approval status
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT s.school_name, s.udise_no, ");
            sql.append("pa.approval_status, pa.approved_date, pa.approved_by ");
            sql.append("FROM schools s ");
            sql.append("LEFT JOIN phase_approvals pa ON s.udise_no COLLATE utf8mb4_unicode_ci = pa.udise_no COLLATE utf8mb4_unicode_ci ");
            sql.append("AND pa.phase_number = ? ");
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                sql.append("AND pa.approved_date BETWEEN ? AND ? ");
            }
            
            // Build SQL dynamically based on available filters (district and division may be null for SDO)
            sql.append("ORDER BY s.school_name");
            
            // Replace WHERE clauses constructed earlier with dynamic handling
            String baseSql = sql.toString();
            StringBuilder finalSql = new StringBuilder();
            finalSql.append("SELECT s.school_name, s.udise_no, pa.approval_status, pa.approved_date, pa.approved_by FROM schools s LEFT JOIN phase_approvals pa ON s.udise_no COLLATE utf8mb4_unicode_ci = pa.udise_no COLLATE utf8mb4_unicode_ci AND pa.phase_number = ? ");
            boolean hasWhere = false;
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                finalSql.append("WHERE pa.approved_date BETWEEN ? AND ? ");
                hasWhere = true;
            }
            if (districtName != null) {
                if (!hasWhere) {
                    finalSql.append("WHERE s.district_name COLLATE utf8mb4_unicode_ci = ? ");
                    hasWhere = true;
                } else {
                    finalSql.append("AND s.district_name COLLATE utf8mb4_unicode_ci = ? ");
                }
            }
            if (divisionName != null) {
                if (!hasWhere) {
                    finalSql.append("WHERE s.district_name COLLATE utf8mb4_unicode_ci IN (SELECT DISTINCT district COLLATE utf8mb4_unicode_ci FROM students WHERE division = ?) ");
                } else {
                    finalSql.append("AND s.district_name COLLATE utf8mb4_unicode_ci IN (SELECT DISTINCT district COLLATE utf8mb4_unicode_ci FROM students WHERE division = ?) ");
                }
            }
            finalSql.append("ORDER BY s.school_name");
            
            PreparedStatement stmt = conn.prepareStatement(finalSql.toString());
            int paramIndex = 1;
            stmt.setInt(paramIndex++, phase);
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                stmt.setString(paramIndex++, startDate);
                stmt.setString(paramIndex++, endDate);
            }
            if (districtName != null) {
                stmt.setString(paramIndex++, districtName);
            }
            if (divisionName != null) {
                stmt.setString(paramIndex++, divisionName);
            }
            
            ResultSet rs = stmt.executeQuery();
            
            JSONArray schools = new JSONArray();
            SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
            
            while (rs.next()) {
                JSONObject school = new JSONObject();
                
                String schoolName = rs.getString("school_name");
                String udiseNo = rs.getString("udise_no");
                String approvalStatus = rs.getString("approval_status");
                java.sql.Timestamp approvedDate = rs.getTimestamp("approved_date");
                String approvedBy = rs.getString("approved_by");
                
                boolean isApproved = "APPROVED".equals(approvalStatus);
                
                school.put("schoolName", schoolName);
                school.put("udiseNo", udiseNo);
                school.put("isApproved", isApproved);
                school.put("approvalStatus", approvalStatus != null ? approvalStatus : "NOT_SUBMITTED");
                school.put("approvedDate", approvedDate != null ? dateFormat.format(approvedDate) : null);
                school.put("approvedBy", approvedBy);
                
                schools.put(school);
            }
            
            result.put("schools", schools);
            result.put("district", districtName);
            result.put("phase", phase);
            result.put("totalSchools", schools.length());
            
            // Count approved schools
            int approvedCount = 0;
            for (int i = 0; i < schools.length(); i++) {
                if (schools.getJSONObject(i).getBoolean("isApproved")) {
                    approvedCount++;
                }
            }
            result.put("approvedSchools", approvedCount);
            
            rs.close();
            stmt.close();
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
}
