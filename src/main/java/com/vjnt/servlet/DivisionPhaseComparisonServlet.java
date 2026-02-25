package com.vjnt.servlet;

import com.vjnt.util.DatabaseConnection;
import org.json.JSONArray;
import org.json.JSONObject;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Servlet to fetch Phase-wise Comparison data for Division Dashboard
 * Shows side-by-side comparison of student levels across Phase 1, 2, 3, and 4
 */
@WebServlet("/division-phase-comparison")
public class DivisionPhaseComparisonServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String divisionName = request.getParameter("division");
        String districtName = request.getParameter("district");
        String viewType = request.getParameter("view"); // "division" or "district"
        String subject = request.getParameter("subject"); // "marathi", "math", or "english"
        
        
        JSONObject result = new JSONObject();
        
        try {
            if (divisionName == null || divisionName.isEmpty()) {
                result.put("error", "Division name is required");
                result.put("success", false);
                response.getWriter().write(result.toString());
                return;
            }
            
            if (subject == null || subject.isEmpty()) {
                subject = "marathi"; // Default to Marathi
            }
            
            if ("district".equalsIgnoreCase(viewType) && districtName != null && !districtName.isEmpty()) {
                // Get district-level phase comparison
                result = getDistrictPhaseComparison(divisionName, districtName, subject);
            } else {
                // Get division-level phase comparison
                result = getDivisionPhaseComparison(divisionName, subject);
            }
            
            result.put("success", true);
            
        } catch (Exception e) {
            // System.err.println("Error in DivisionPhaseComparisonServlet: " + e.getMessage());
            e.printStackTrace();
            result.put("success", false);
            result.put("error", e.getMessage());
        }
        
        PrintWriter out = response.getWriter();
        out.print(result.toString());
        out.flush();
    }
    
    /**
     * Get division-level phase comparison for all 4 phases
     */
    private JSONObject getDivisionPhaseComparison(String divisionName, String subject) throws SQLException {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get max level for the subject
            int maxLevel = getMaxLevel(subject);
            
            // Get data for each phase
            for (int phase = 1; phase <= 4; phase++) {
                JSONObject phaseData = getPhaseData(conn, divisionName, null, subject, phase, maxLevel);
                result.put("phase" + phase, phaseData);
            }
            
            // Calculate total students across all phases
            int totalStudents = 0;
            for (int phase = 1; phase <= 4; phase++) {
                if (result.has("phase" + phase)) {
                    JSONObject phaseData = result.getJSONObject("phase" + phase);
                    if (phaseData.has("totalStudents")) {
                        totalStudents = Math.max(totalStudents, phaseData.getInt("totalStudents"));
                    }
                }
            }
            result.put("totalStudents", totalStudents);
            result.put("subject", subject);
            result.put("viewType", "division");
            
            // Get list of districts for selection
            JSONArray districts = getDistrictList(conn, divisionName);
            result.put("districts", districts);
            
        }
        
        return result;
    }
    
    /**
     * Get list of districts in the division with student counts
     */
    private JSONArray getDistrictList(Connection conn, String divisionName) throws SQLException {
        JSONArray districts = new JSONArray();
        
        String sql = "SELECT district, COUNT(DISTINCT student_id) as student_count " +
                     "FROM students " +
                     "WHERE division = ? AND is_active = 1 " +
                     "GROUP BY district " +
                     "ORDER BY district";
        
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, divisionName);
        ResultSet rs = ps.executeQuery();
        
        while (rs.next()) {
            JSONObject district = new JSONObject();
            district.put("name", rs.getString("district"));
            district.put("studentCount", rs.getInt("student_count"));
            districts.put(district);
        }
        
        rs.close();
        ps.close();
        
        return districts;
    }
    
    /**
     * Get district-level phase comparison for all 4 phases
     */
    private JSONObject getDistrictPhaseComparison(String divisionName, String districtName, String subject) throws SQLException {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get max level for the subject
            int maxLevel = getMaxLevel(subject);
            
            // Get data for each phase
            for (int phase = 1; phase <= 4; phase++) {
                JSONObject phaseData = getPhaseData(conn, divisionName, districtName, subject, phase, maxLevel);
                result.put("phase" + phase, phaseData);
            }
            
            // Calculate total students across all phases
            int totalStudents = 0;
            for (int phase = 1; phase <= 4; phase++) {
                if (result.has("phase" + phase)) {
                    JSONObject phaseData = result.getJSONObject("phase" + phase);
                    if (phaseData.has("totalStudents")) {
                        totalStudents = Math.max(totalStudents, phaseData.getInt("totalStudents"));
                    }
                }
            }
            result.put("totalStudents", totalStudents);
            result.put("subject", subject);
            result.put("viewType", "district");
            result.put("districtName", districtName);
            
        }
        
        return result;
    }
    
    /**
     * Get phase data for a specific phase
     */
    private JSONObject getPhaseData(Connection conn, String divisionName, String districtName, 
                                    String subject, int phase, int maxLevel) throws SQLException {
        
        
        JSONObject phaseData = new JSONObject();
        JSONArray distribution = new JSONArray();
        
        String levelColumn = getPhaseColumn(subject, phase);
        
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT ");
        sql.append("COUNT(DISTINCT s.student_id) as total_students, ");
        
        // Count for each level
        for (int level = 0; level <= maxLevel; level++) {
            sql.append("SUM(CASE WHEN ").append(levelColumn).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as level_").append(level);
            if (level < maxLevel) sql.append(", ");
        }
        
        sql.append(" FROM students s ");
        sql.append("WHERE s.division = ? AND s.is_active = 1 ");
        
        PreparedStatement ps;
        if (districtName != null && !districtName.isEmpty()) {
            sql.append("AND s.district = ?");
            ps = conn.prepareStatement(sql.toString());
            ps.setString(1, divisionName);
            ps.setString(2, districtName);
        } else {
            ps = conn.prepareStatement(sql.toString());
            ps.setString(1, divisionName);
        }
        
        
        ResultSet rs = ps.executeQuery();
        
        if (rs.next()) {
            int totalStudents = rs.getInt("total_students");
            phaseData.put("totalStudents", totalStudents);
            phaseData.put("phase", phase);
            
            // Build level distribution
            for (int level = 0; level <= maxLevel; level++) {
                int count = rs.getInt("level_" + level);
                double percentage = (totalStudents > 0) ? ((double) count / totalStudents) * 100 : 0;
                
                
                JSONObject levelData = new JSONObject();
                levelData.put("level", level);
                levelData.put("count", count);
                levelData.put("percentage", Math.round(percentage * 100.0) / 100.0);
                distribution.put(levelData);
            }
            
            phaseData.put("distribution", distribution);
        } else {
            phaseData.put("totalStudents", 0);
            phaseData.put("phase", phase);
            phaseData.put("distribution", distribution);
        }
        
        rs.close();
        ps.close();
        
        return phaseData;
    }
    
    /**
     * Get the database column name for the subject and phase
     */
    private String getPhaseColumn(String subject, int phase) {
        String subjectName;
        
        switch (subject.toLowerCase()) {
            case "marathi":
                subjectName = "marathi";
                break;
            case "math":
                subjectName = "math";
                break;
            case "english":
                subjectName = "english";
                break;
            default:
                subjectName = "marathi";
        }
        
        // For current phase (phase 0 or no phase), use base column
        if (phase == 0) {
            return subjectName + "_level";
        }
        
        // For phases 1-4, use phase-specific columns (e.g., phase1_marathi, phase2_math)
        return "phase" + phase + "_" + subjectName;
    }
    
    /**
     * Get maximum level for a subject
     */
    private int getMaxLevel(String subject) {
        switch (subject.toLowerCase()) {
            case "math":
                return 8; // Math has levels 0-8
            case "marathi":
            case "english":
            default:
                return 6; // Marathi and English have levels 0-6
        }
    }
}
