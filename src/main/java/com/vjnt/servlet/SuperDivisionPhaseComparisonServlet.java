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
 * Super Division Officer version of {@link DivisionPhaseComparisonServlet}.
 *
 * The {@code division} parameter is OPTIONAL: missing/empty/"ALL" compares phases
 * across every division; a specific division drills down. The getSchools/getClasses
 * helper actions are division-agnostic (district/UDISE based) and behave identically.
 * Existing division servlets are left untouched.
 */
@WebServlet("/super-phase-comparison")
public class SuperDivisionPhaseComparisonServlet extends HttpServlet {

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
        String studentClass = request.getParameter("class"); // Class filter
        String action = request.getParameter("action"); // Special action like "getSchools"

        JSONObject result = new JSONObject();

        try {
            // Restrict to Super Division Officer sessions
            HttpSession session = request.getSession(false);
            User user = (session != null) ? (User) session.getAttribute("user") : null;
            if (user == null || user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.getWriter().write(new JSONObject().put("success", false)
                        .put("error", "Access denied").toString());
                return;
            }

            // Handle special actions (division-agnostic)
            if ("getSchools".equals(action) && districtName != null && !districtName.isEmpty()) {
                result = getSchoolsForDistrict(districtName);
                result.put("success", true);
                writeJson(response, result);
                return;
            }

            if ("getClasses".equals(action) && schoolUdise != null && !schoolUdise.isEmpty()) {
                result = getClassesForSchool(schoolUdise);
                result.put("success", true);
                writeJson(response, result);
                return;
            }

            if (subject == null || subject.isEmpty()) {
                subject = "marathi"; // Default to Marathi
            }

            if ("district".equalsIgnoreCase(viewType) && districtName != null && !districtName.isEmpty()) {
                result = getDistrictPhaseComparison(divisionName, districtName, subject, schoolUdise, studentClass);
            } else {
                result = getDivisionPhaseComparison(divisionName, subject, schoolUdise, studentClass);
            }

            result.put("success", true);

        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("error", e.getMessage());
        }

        writeJson(response, result);
    }

    private void writeJson(HttpServletResponse response, JSONObject result) throws IOException {
        PrintWriter out = response.getWriter();
        out.print(result.toString());
        out.flush();
    }

    /** True when no specific division was requested (aggregate across all divisions). */
    private boolean isAllDivisions(String divisionName) {
        return divisionName == null || divisionName.trim().isEmpty()
                || "ALL".equalsIgnoreCase(divisionName.trim());
    }

    private JSONObject getDivisionPhaseComparison(String divisionName, String subject, String schoolUdise, String studentClass) throws SQLException {
        JSONObject result = new JSONObject();

        try (Connection conn = DatabaseConnection.getConnection()) {

            int maxLevel = getMaxLevel(subject);

            for (int phase = 1; phase <= 4; phase++) {
                JSONObject phaseData = getPhaseData(conn, divisionName, null, subject, phase, maxLevel, schoolUdise, studentClass);
                result.put("phase" + phase, phaseData);
            }

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
            result.put("scope", isAllDivisions(divisionName) ? "ALL" : divisionName);

            // Get list of districts for selection (division-aware; null/empty = all)
            JSONArray districts = getDistrictList(conn, isAllDivisions(divisionName) ? null : divisionName);
            result.put("districts", districts);
        }

        return result;
    }

    private JSONArray getDistrictList(Connection conn, String divisionName) throws SQLException {
        JSONArray districts = new JSONArray();

        String sql;
        PreparedStatement ps;
        if (divisionName != null && !divisionName.isEmpty()) {
            sql = "SELECT district, COUNT(DISTINCT student_id) as student_count " +
                  "FROM students WHERE division = ? AND is_active = 1 " +
                  "GROUP BY district ORDER BY district";
            ps = conn.prepareStatement(sql);
            ps.setString(1, divisionName);
        } else {
            sql = "SELECT district, COUNT(DISTINCT student_id) as student_count " +
                  "FROM students WHERE is_active = 1 " +
                  "GROUP BY district ORDER BY district";
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

    private JSONObject getDistrictPhaseComparison(String divisionName, String districtName, String subject, String schoolUdise, String studentClass) throws SQLException {
        JSONObject result = new JSONObject();

        try (Connection conn = DatabaseConnection.getConnection()) {

            int maxLevel = getMaxLevel(subject);

            for (int phase = 1; phase <= 4; phase++) {
                JSONObject phaseData = getPhaseData(conn, divisionName, districtName, subject, phase, maxLevel, schoolUdise, studentClass);
                result.put("phase" + phase, phaseData);
            }

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
            result.put("scope", isAllDivisions(divisionName) ? "ALL" : divisionName);
        }

        return result;
    }

    private JSONObject getPhaseData(Connection conn, String divisionName, String districtName,
                                    String subject, int phase, int maxLevel, String schoolUdise, String studentClass) throws SQLException {

        boolean allDivisions = isAllDivisions(divisionName);

        JSONObject phaseData = new JSONObject();
        JSONArray distribution = new JSONArray();

        String levelColumn = getPhaseColumn(subject, phase);

        StringBuilder sql = new StringBuilder();
        sql.append("SELECT ");
        sql.append("COUNT(DISTINCT s.student_id) as total_students, ");

        for (int level = 0; level <= maxLevel; level++) {
            sql.append("SUM(CASE WHEN ").append(levelColumn).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as level_").append(level);
            if (level < maxLevel) sql.append(", ");
        }

        sql.append(" FROM students s ");
        sql.append("WHERE s.is_active = 1 ");

        if (!allDivisions) {
            sql.append("AND s.division = ? ");
        }
        if (studentClass != null && !studentClass.isEmpty()) {
            sql.append("AND s.class = ? ");
        }
        if (districtName != null && !districtName.isEmpty()) {
            sql.append("AND s.district = ? ");
        }
        if (schoolUdise != null && !schoolUdise.isEmpty()) {
            sql.append("AND s.udise_no = ? ");
        }

        PreparedStatement ps = conn.prepareStatement(sql.toString());
        int paramIndex = 1;
        if (!allDivisions) {
            ps.setString(paramIndex++, divisionName);
        }
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

    private String getPhaseColumn(String subject, int phase) {
        String subjectName;
        switch (subject.toLowerCase()) {
            case "marathi": subjectName = "marathi"; break;
            case "math":    subjectName = "math";    break;
            case "english": subjectName = "english"; break;
            default:        subjectName = "marathi";
        }
        if (phase == 0) {
            return subjectName + "_level";
        }
        return "phase" + phase + "_" + subjectName;
    }

    private int getMaxLevel(String subject) {
        switch (subject.toLowerCase()) {
            case "math": return 8;
            case "marathi":
            case "english":
            default: return 6;
        }
    }

    private JSONObject getSchoolsForDistrict(String districtName) throws SQLException {
        JSONObject result = new JSONObject();
        JSONArray schools = new JSONArray();

        try (Connection conn = DatabaseConnection.getConnection()) {

            String sql = "SELECT DISTINCT s.udise_no, " +
                        "MAX(sc.school_name) as school_name, " +
                        "COUNT(DISTINCT s.student_id) as student_count " +
                        "FROM students s " +
                        "LEFT JOIN schools sc ON s.udise_no = sc.udise_no COLLATE utf8mb4_unicode_ci " +
                        "WHERE s.district = ? AND s.is_active = 1 " +
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

    private JSONObject getClassesForSchool(String schoolUdise) {
        JSONObject result = new JSONObject();
        JSONArray classes = new JSONArray();

        try {
            Connection conn = DatabaseConnection.getConnection();

            String sql = "SELECT DISTINCT class FROM students " +
                        "WHERE udise_no = ? AND is_active = 1 " +
                        "ORDER BY FIELD(class, 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII')";

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
