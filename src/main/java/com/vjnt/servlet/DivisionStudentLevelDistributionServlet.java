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
 * Servlet to fetch Student Level Distribution data for Division Dashboard
 * Shows percentage of students at each level (0-6 for Marathi/English, 0-8 for Math)
 */
@WebServlet("/division-student-level-distribution")
public class DivisionStudentLevelDistributionServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String divisionName = request.getParameter("division");
        String districtName = request.getParameter("district");
        String viewType = request.getParameter("view"); // "district" or "school"
        String phaseFilter = request.getParameter("phase"); // "1", "2", "3", "4", "all", or "current"
        
        JSONObject result = new JSONObject();
        
        try {
            if (divisionName == null || divisionName.isEmpty()) {
                result.put("error", "Division name is required");
                response.getWriter().write(result.toString());
                return;
            }
            
            if ("school".equalsIgnoreCase(viewType) && districtName != null && !districtName.isEmpty()) {
                // Get school-wise level distribution for selected district
                result = getSchoolWiseLevelDistribution(divisionName, districtName, phaseFilter);
            } else {
                // Get district-wise level distribution
                result = getDistrictWiseLevelDistribution(divisionName, phaseFilter);
            }
            
            result.put("success", true);
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("error", e.getMessage());
        }
        
        PrintWriter out = response.getWriter();
        out.print(result.toString());
        out.flush();
    }
    
    /**
     * Get district-wise student level distribution
     */
    private JSONObject getDistrictWiseLevelDistribution(String divisionName, String phaseFilter) throws SQLException {
        JSONObject result = new JSONObject();
        JSONArray districtData = new JSONArray();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Determine which level columns to use based on phase filter
            String marathiCol = getPhaseColumn("marathi", phaseFilter);
            String mathCol = getPhaseColumn("math", phaseFilter);
            String englishCol = getPhaseColumn("english", phaseFilter);
            
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT s.district, ");
            sql.append("COUNT(DISTINCT s.student_id) as total_students, ");
            
            // Marathi level distribution (0-6)
            for (int level = 0; level <= 6; level++) {
                sql.append("SUM(CASE WHEN ").append(marathiCol).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as marathi_level_").append(level).append(", ");
            }
            
            // Math level distribution (0-8)
            for (int level = 0; level <= 8; level++) {
                sql.append("SUM(CASE WHEN ").append(mathCol).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as math_level_").append(level).append(", ");
            }
            
            // English level distribution (0-6)
            for (int level = 0; level <= 6; level++) {
                sql.append("SUM(CASE WHEN ").append(englishCol).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as english_level_").append(level);
                if (level < 6) sql.append(", ");
            }
            
            sql.append(" FROM students s ");
            sql.append("WHERE s.division = ? AND s.is_active = 1 ");
            sql.append("GROUP BY s.district ");
            sql.append("ORDER BY s.district");
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            ps.setString(1, divisionName);
            
            ResultSet rs = ps.executeQuery();
            
            int totalStudentsAll = 0;
            int districtCount = 0;
            
            while (rs.next()) {
                JSONObject district = new JSONObject();
                String districtNameStr = rs.getString("district");
                int totalStudents = rs.getInt("total_students");
                
                // Marathi distribution
                JSONArray marathiDistribution = new JSONArray();
                for (int level = 0; level <= 6; level++) {
                    int count = rs.getInt("marathi_level_" + level);
                    double percentage = (totalStudents > 0) ? ((double) count / totalStudents) * 100 : 0;
                    JSONObject levelData = new JSONObject();
                    levelData.put("level", level);
                    levelData.put("count", count);
                    levelData.put("percentage", Math.round(percentage * 100.0) / 100.0);
                    marathiDistribution.put(levelData);
                }
                
                // Math distribution
                JSONArray mathDistribution = new JSONArray();
                for (int level = 0; level <= 8; level++) {
                    int count = rs.getInt("math_level_" + level);
                    double percentage = (totalStudents > 0) ? ((double) count / totalStudents) * 100 : 0;
                    JSONObject levelData = new JSONObject();
                    levelData.put("level", level);
                    levelData.put("count", count);
                    levelData.put("percentage", Math.round(percentage * 100.0) / 100.0);
                    mathDistribution.put(levelData);
                }
                
                // English distribution
                JSONArray englishDistribution = new JSONArray();
                for (int level = 0; level <= 6; level++) {
                    int count = rs.getInt("english_level_" + level);
                    double percentage = (totalStudents > 0) ? ((double) count / totalStudents) * 100 : 0;
                    JSONObject levelData = new JSONObject();
                    levelData.put("level", level);
                    levelData.put("count", count);
                    levelData.put("percentage", Math.round(percentage * 100.0) / 100.0);
                    englishDistribution.put(levelData);
                }
                
                district.put("districtName", districtNameStr);
                district.put("totalStudents", totalStudents);
                district.put("marathiDistribution", marathiDistribution);
                district.put("mathDistribution", mathDistribution);
                district.put("englishDistribution", englishDistribution);
                
                districtData.put(district);
                
                totalStudentsAll += totalStudents;
                districtCount++;
            }
            
            result.put("districts", districtData);
            result.put("totalStudents", totalStudentsAll);
            result.put("districtCount", districtCount);
            result.put("phaseFilter", phaseFilter != null ? phaseFilter : "all");
        }
        
        return result;
    }
    
    /**
     * Get school-wise student level distribution for a specific district
     */
    private JSONObject getSchoolWiseLevelDistribution(String divisionName, String districtName, String phaseFilter) throws SQLException {
        JSONObject result = new JSONObject();
        JSONArray schoolData = new JSONArray();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Determine which level columns to use based on phase filter
            String marathiCol = getPhaseColumn("marathi", phaseFilter);
            String mathCol = getPhaseColumn("math", phaseFilter);
            String englishCol = getPhaseColumn("english", phaseFilter);
            
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT s.udise_no, sch.school_name, s.district, ");
            sql.append("COUNT(DISTINCT s.student_id) as total_students, ");
            
            // Marathi level distribution (0-6)
            for (int level = 0; level <= 6; level++) {
                sql.append("SUM(CASE WHEN ").append(marathiCol).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as marathi_level_").append(level).append(", ");
            }
            
            // Math level distribution (0-8)
            for (int level = 0; level <= 8; level++) {
                sql.append("SUM(CASE WHEN ").append(mathCol).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as math_level_").append(level).append(", ");
            }
            
            // English level distribution (0-6)
            for (int level = 0; level <= 6; level++) {
                sql.append("SUM(CASE WHEN ").append(englishCol).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as english_level_").append(level);
                if (level < 6) sql.append(", ");
            }
            
            sql.append(" FROM students s ");
            sql.append("LEFT JOIN schools sch ON s.udise_no = sch.udise_no ");
            sql.append("WHERE s.division = ? AND s.district = ? AND s.is_active = 1 ");
            sql.append("GROUP BY s.udise_no, sch.school_name, s.district ");
            sql.append("ORDER BY sch.school_name");
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            ps.setString(1, divisionName);
            ps.setString(2, districtName);
            
            ResultSet rs = ps.executeQuery();
            
            int totalStudentsAll = 0;
            int schoolCount = 0;
            
            while (rs.next()) {
                JSONObject school = new JSONObject();
                String udiseNo = rs.getString("udise_no");
                String schoolName = rs.getString("school_name");
                int totalStudents = rs.getInt("total_students");
                
                // Marathi distribution
                JSONArray marathiDistribution = new JSONArray();
                for (int level = 0; level <= 6; level++) {
                    int count = rs.getInt("marathi_level_" + level);
                    double percentage = (totalStudents > 0) ? ((double) count / totalStudents) * 100 : 0;
                    JSONObject levelData = new JSONObject();
                    levelData.put("level", level);
                    levelData.put("count", count);
                    levelData.put("percentage", Math.round(percentage * 100.0) / 100.0);
                    marathiDistribution.put(levelData);
                }
                
                // Math distribution
                JSONArray mathDistribution = new JSONArray();
                for (int level = 0; level <= 8; level++) {
                    int count = rs.getInt("math_level_" + level);
                    double percentage = (totalStudents > 0) ? ((double) count / totalStudents) * 100 : 0;
                    JSONObject levelData = new JSONObject();
                    levelData.put("level", level);
                    levelData.put("count", count);
                    levelData.put("percentage", Math.round(percentage * 100.0) / 100.0);
                    mathDistribution.put(levelData);
                }
                
                // English distribution
                JSONArray englishDistribution = new JSONArray();
                for (int level = 0; level <= 6; level++) {
                    int count = rs.getInt("english_level_" + level);
                    double percentage = (totalStudents > 0) ? ((double) count / totalStudents) * 100 : 0;
                    JSONObject levelData = new JSONObject();
                    levelData.put("level", level);
                    levelData.put("count", count);
                    levelData.put("percentage", Math.round(percentage * 100.0) / 100.0);
                    englishDistribution.put(levelData);
                }
                
                school.put("udiseNo", udiseNo);
                school.put("schoolName", schoolName != null ? schoolName : udiseNo);
                school.put("totalStudents", totalStudents);
                school.put("marathiDistribution", marathiDistribution);
                school.put("mathDistribution", mathDistribution);
                school.put("englishDistribution", englishDistribution);
                
                schoolData.put(school);
                
                totalStudentsAll += totalStudents;
                schoolCount++;
            }
            
            result.put("schools", schoolData);
            result.put("districtName", districtName);
            result.put("totalStudents", totalStudentsAll);
            result.put("schoolCount", schoolCount);
            result.put("phaseFilter", phaseFilter != null ? phaseFilter : "all");
        }
        
        return result;
    }
    
    /**
     * Get the appropriate column name based on phase filter
     */
    private String getPhaseColumn(String subject, String phaseFilter) {
        if (phaseFilter == null || "current".equals(phaseFilter)) {
            return subject + "_level";
        }
        
        // If "all" is selected, use GREATEST to get the maximum value across all phases
        if ("all".equals(phaseFilter)) {
            return "GREATEST(COALESCE(phase1_" + subject + ", 0), COALESCE(phase2_" + subject + ", 0), " +
                   "COALESCE(phase3_" + subject + ", 0), COALESCE(phase4_" + subject + ", 0), " +
                   "COALESCE(" + subject + "_level, 0))";
        }
        
        switch (phaseFilter) {
            case "1":
                return "phase1_" + subject;
            case "2":
                return "phase2_" + subject;
            case "3":
                return "phase3_" + subject;
            case "4":
                return "phase4_" + subject;
            default:
                return subject + "_level";
        }
    }
}
