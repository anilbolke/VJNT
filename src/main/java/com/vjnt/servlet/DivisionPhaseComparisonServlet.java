package com.vjnt.servlet;

import com.vjnt.util.DatabaseConnection;
import org.json.JSONArray;
import org.json.JSONObject;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
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

    /** Level bucket for students whose level was never recorded (NULL in the DB). */
    private static final int NOT_RECORDED = -1;
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String divisionName = request.getParameter("division");
        String districtName = request.getParameter("district");
        String viewType = request.getParameter("view"); // "division" or "district"
        String subject = request.getParameter("subject"); // "marathi", "math", or "english"
        String schoolUdise = request.getParameter("school"); // School UDISE filter
        String studentClass = request.getParameter("class"); // Class filter (Roman numerals or empty)
        String action = request.getParameter("action"); // Special action like "getSchools"
        
        JSONObject result = new JSONObject();
        
        try {
            // Handle special actions
            if ("getSchools".equals(action) && districtName != null && !districtName.isEmpty()) {
                // Return list of schools for a district
                result = getSchoolsForDistrict(districtName);
                result.put("success", true);
                PrintWriter out = response.getWriter();
                out.print(result.toString());
                out.flush();
                return;
            }
            
            if ("getClasses".equals(action) && schoolUdise != null && !schoolUdise.isEmpty()) {
                // Return list of classes for a school
                result = getClassesForSchool(schoolUdise);
                result.put("success", true);
                PrintWriter out = response.getWriter();
                out.print(result.toString());
                out.flush();
                return;
            }
            
            HttpSession session = request.getSession(false);
            User user = null;
            if (session != null) user = (User) session.getAttribute("user");

            if (divisionName == null || divisionName.isEmpty()) {
                // Only SUPER_DIVISION_OFFICER may omit division parameter
                if (user == null || user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
                    result.put("error", "Division name is required");
                    result.put("success", false);
                    response.getWriter().write(result.toString());
                    return;
                }
            }
            
            if (subject == null || subject.isEmpty()) {
                subject = "marathi"; // Default to Marathi
            }
            
            if ("district".equalsIgnoreCase(viewType) && districtName != null && !districtName.isEmpty()) {
                // Get district-level phase comparison
                result = getDistrictPhaseComparison(divisionName, districtName, subject, schoolUdise, studentClass);
            } else {
                // Get division-level phase comparison
                result = getDivisionPhaseComparison(divisionName, subject, schoolUdise, studentClass);
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
    private JSONObject getDivisionPhaseComparison(String divisionName, String subject, String schoolUdise, String studentClass) throws SQLException {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get max level for the subject
            int maxLevel = getMaxLevel(subject);
            
            // Get data for each phase
            for (int phase = 1; phase <= 4; phase++) {
                JSONObject phaseData = getPhaseData(conn, divisionName, null, subject, phase, maxLevel, schoolUdise, studentClass);
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
        
        String sql;
        PreparedStatement ps;
        if (divisionName != null && !divisionName.isEmpty()) {
           sql = "SELECT district, COUNT(DISTINCT student_id) as student_count " +
                 "FROM students " +
                 "WHERE division = ? AND is_active = 1 " +
                 "AND TRIM(class) IN " + com.vjnt.dao.StudentDAO.CLASS_I_TO_IX + " " +
                 "GROUP BY district " +
                 "ORDER BY district";
           ps = conn.prepareStatement(sql);
           ps.setString(1, divisionName);
        } else {
           sql = "SELECT district, COUNT(DISTINCT student_id) as student_count " +
                 "FROM students " +
                 "WHERE is_active = 1 " +
                 "AND TRIM(class) IN " + com.vjnt.dao.StudentDAO.CLASS_I_TO_IX + " " +
                 "GROUP BY district " +
                 "ORDER BY district";
           ps = conn.prepareStatement(sql);
        }
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
    private JSONObject getDistrictPhaseComparison(String divisionName, String districtName, String subject, String schoolUdise, String studentClass) throws SQLException {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get max level for the subject
            int maxLevel = getMaxLevel(subject);
            
            // Get data for each phase
            for (int phase = 1; phase <= 4; phase++) {
                JSONObject phaseData = getPhaseData(conn, divisionName, districtName, subject, phase, maxLevel, schoolUdise, studentClass);
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
     * Get phase data for a specific phase with school and class filters
     */
    private JSONObject getPhaseData(Connection conn, String divisionName, String districtName, 
                                    String subject, int phase, int maxLevel, String schoolUdise, String studentClass) throws SQLException {
        
        
        JSONObject phaseData = new JSONObject();
        JSONArray distribution = new JSONArray();
        
        String levelColumn = getPhaseColumn(subject, phase);
        
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT ");
        sql.append("COUNT(DISTINCT s.student_id) as total_students, ");
        
        // Never-recorded levels. Without this the bars below silently omit NULL rows, so the
        // distribution never accounts for every student in total_students.
        sql.append("SUM(CASE WHEN ").append(levelColumn).append(" IS NULL THEN 1 ELSE 0 END) as level_null, ");
        
        // Count for each level
        for (int level = 0; level <= maxLevel; level++) {
            sql.append("SUM(CASE WHEN ").append(levelColumn).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as level_").append(level);
            if (level < maxLevel) sql.append(", ");
        }
        
        sql.append(" FROM students s ");
        sql.append("WHERE s.division = ? AND s.is_active = 1 ");
        // The FLN programme covers classes I-IX only; anything else must not reach the bars.
        sql.append("AND TRIM(s.class) IN ").append(com.vjnt.dao.StudentDAO.CLASS_I_TO_IX).append(" ");
        
        // Add class filter if provided
        if (studentClass != null && !studentClass.isEmpty()) {
            sql.append("AND TRIM(s.class) = ? ");
        }
        
        // Add district filter if provided
        if (districtName != null && !districtName.isEmpty()) {
            sql.append("AND s.district = ? ");
        }
        
        // Add school filter if provided
        if (schoolUdise != null && !schoolUdise.isEmpty()) {
            sql.append("AND s.udise_no = ? ");
        }
        
        PreparedStatement ps = conn.prepareStatement(sql.toString());
        int paramIndex = 1;
        ps.setString(paramIndex++, divisionName);
        
        if (studentClass != null && !studentClass.isEmpty()) {
            ps.setString(paramIndex++, studentClass);
        }
        
        if (districtName != null && !districtName.isEmpty()) {
            ps.setString(paramIndex++, districtName);
        }
        
        if (schoolUdise != null && !schoolUdise.isEmpty()) {
            ps.setString(paramIndex++, schoolUdise);
        }
        
        ResultSet rs = ps.executeQuery();
        
        if (rs.next()) {
            int totalStudents = rs.getInt("total_students");
            phaseData.put("totalStudents", totalStudents);
            phaseData.put("phase", phase);
            
            // Build level distribution, NOT_RECORDED first so the bars add up to 100%
            for (int level = NOT_RECORDED; level <= maxLevel; level++) {
                int count = rs.getInt(level == NOT_RECORDED ? "level_null" : "level_" + level);
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
    
    /**
     * Get schools for a specific district filtered by class range
     */
    private JSONObject getSchoolsForDistrict(String districtName) throws SQLException {
        JSONObject result = new JSONObject();
        JSONArray schools = new JSONArray();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get distinct schools from students table for the district
            // Include only schools that have students in the specified class range
            String sql = "SELECT DISTINCT s.udise_no, " +
                        "MAX(sc.school_name) as school_name, " +
                        "COUNT(DISTINCT s.student_id) as student_count " +
                        "FROM students s " +
                        "LEFT JOIN schools sc ON s.udise_no = sc.udise_no COLLATE utf8mb4_unicode_ci " +
                        "WHERE s.district = ? AND s.is_active = 1 " +
                        "AND TRIM(s.class) IN " + com.vjnt.dao.StudentDAO.CLASS_I_TO_IX + " " +
                        "GROUP BY s.udise_no " +
                        "ORDER BY school_name";
            
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, districtName);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                JSONObject school = new JSONObject();
                school.put("udiseNo", rs.getString("udise_no"));
                school.put("schoolName", rs.getString("school_name"));
                school.put("studentCount", rs.getInt("student_count"));
                schools.put(school);
            }
            
            result.put("schools", schools);
            result.put("districtName", districtName);
            
            rs.close();
            ps.close();
        }
        
        return result;
    }
    
    /**
     * Get distinct classes for a selected school
     */
    private JSONObject getClassesForSchool(String schoolUdise) {
        JSONObject result = new JSONObject();
        JSONArray classes = new JSONArray();
        
        try {
            Connection conn = DatabaseConnection.getConnection();
            
            String sql = "SELECT DISTINCT class FROM students " +
                        "WHERE udise_no = ? AND is_active = 1 " +
                        "AND TRIM(class) IN " + com.vjnt.dao.StudentDAO.CLASS_I_TO_IX + " " +
                        "ORDER BY FIELD(TRIM(class), 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', " +
                        "'1', '2', '3', '4', '5', '6', '7', '8', '9')";
            
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, schoolUdise);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                JSONObject classObj = new JSONObject();
                String classValue = rs.getString("class");
                classObj.put("class", classValue);
                classObj.put("label", "Class " + classValue);
                classes.put(classObj);
            }
            
            result.put("classes", classes);
            result.put("schoolUdise", schoolUdise);
            
            rs.close();
            ps.close();
            conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", "Failed to fetch classes");
        }
        
        return result;
    }
}
