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
 * Super Division Officer version of {@link DivisionStudentLevelDistributionServlet}.
 *
 * The {@code division} parameter is OPTIONAL: missing/empty/"ALL" aggregates the
 * level distribution across every division; a specific division drills down.
 * Existing division servlets are left untouched.
 */
@WebServlet("/super-student-level-distribution")
public class SuperDivisionStudentLevelDistributionServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String divisionName = request.getParameter("division");
        String districtName = request.getParameter("district");
        String viewType = request.getParameter("view"); // "district" or "school"
        String phaseFilter = request.getParameter("phase"); // "1".."4", "all", "current"

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

            if ("school".equalsIgnoreCase(viewType) && districtName != null && !districtName.isEmpty()) {
                result = getSchoolWiseLevelDistribution(divisionName, districtName, phaseFilter);
            } else {
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

    /** True when no specific division was requested (aggregate across all divisions). */
    private boolean isAllDivisions(String divisionName) {
        return divisionName == null || divisionName.trim().isEmpty()
                || "ALL".equalsIgnoreCase(divisionName.trim());
    }

    private JSONObject getDistrictWiseLevelDistribution(String divisionName, String phaseFilter) throws SQLException {
        JSONObject result = new JSONObject();
        JSONArray districtData = new JSONArray();

        boolean allDivisions = isAllDivisions(divisionName);

        try (Connection conn = DatabaseConnection.getConnection()) {

            String marathiCol = getPhaseColumn("marathi", phaseFilter);
            String mathCol = getPhaseColumn("math", phaseFilter);
            String englishCol = getPhaseColumn("english", phaseFilter);

            StringBuilder sql = new StringBuilder();
            sql.append("SELECT s.district, ");
            sql.append("COUNT(DISTINCT s.student_id) as total_students, ");

            for (int level = 0; level <= 6; level++) {
                sql.append("SUM(CASE WHEN ").append(marathiCol).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as marathi_level_").append(level).append(", ");
            }
            for (int level = 0; level <= 8; level++) {
                sql.append("SUM(CASE WHEN ").append(mathCol).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as math_level_").append(level).append(", ");
            }
            for (int level = 0; level <= 6; level++) {
                sql.append("SUM(CASE WHEN ").append(englishCol).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as english_level_").append(level);
                if (level < 6) sql.append(", ");
            }

            sql.append(" FROM students s ");
            if (allDivisions) {
                sql.append("WHERE s.is_active = 1 ");
            } else {
                sql.append("WHERE s.division = ? AND s.is_active = 1 ");
            }
            sql.append("GROUP BY s.district ");
            sql.append("ORDER BY s.district");

            PreparedStatement ps = conn.prepareStatement(sql.toString());
            if (!allDivisions) {
                ps.setString(1, divisionName);
            }

            ResultSet rs = ps.executeQuery();

            int totalStudentsAll = 0;
            int districtCount = 0;

            while (rs.next()) {
                JSONObject district = new JSONObject();
                String districtNameStr = rs.getString("district");
                int totalStudents = rs.getInt("total_students");

                district.put("districtName", districtNameStr);
                district.put("totalStudents", totalStudents);
                district.put("marathiDistribution", buildDistribution(rs, "marathi", 6, totalStudents));
                district.put("mathDistribution", buildDistribution(rs, "math", 8, totalStudents));
                district.put("englishDistribution", buildDistribution(rs, "english", 6, totalStudents));

                districtData.put(district);

                totalStudentsAll += totalStudents;
                districtCount++;
            }

            result.put("districts", districtData);
            result.put("totalStudents", totalStudentsAll);
            result.put("districtCount", districtCount);
            result.put("phaseFilter", phaseFilter != null ? phaseFilter : "all");
            result.put("scope", allDivisions ? "ALL" : divisionName);
        }

        return result;
    }

    private JSONObject getSchoolWiseLevelDistribution(String divisionName, String districtName, String phaseFilter) throws SQLException {
        JSONObject result = new JSONObject();
        JSONArray schoolData = new JSONArray();

        boolean allDivisions = isAllDivisions(divisionName);

        try (Connection conn = DatabaseConnection.getConnection()) {

            String marathiCol = getPhaseColumn("marathi", phaseFilter);
            String mathCol = getPhaseColumn("math", phaseFilter);
            String englishCol = getPhaseColumn("english", phaseFilter);

            StringBuilder sql = new StringBuilder();
            sql.append("SELECT s.udise_no, sch.school_name, s.district, ");
            sql.append("COUNT(DISTINCT s.student_id) as total_students, ");

            for (int level = 0; level <= 6; level++) {
                sql.append("SUM(CASE WHEN ").append(marathiCol).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as marathi_level_").append(level).append(", ");
            }
            for (int level = 0; level <= 8; level++) {
                sql.append("SUM(CASE WHEN ").append(mathCol).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as math_level_").append(level).append(", ");
            }
            for (int level = 0; level <= 6; level++) {
                sql.append("SUM(CASE WHEN ").append(englishCol).append(" = ").append(level).append(" THEN 1 ELSE 0 END) as english_level_").append(level);
                if (level < 6) sql.append(", ");
            }

            sql.append(" FROM students s ");
            sql.append("LEFT JOIN schools sch ON s.udise_no = sch.udise_no COLLATE utf8mb4_unicode_ci ");
            if (allDivisions) {
                sql.append("WHERE s.district = ? AND s.is_active = 1 ");
            } else {
                sql.append("WHERE s.division = ? AND s.district = ? AND s.is_active = 1 ");
            }
            sql.append("GROUP BY s.udise_no, sch.school_name, s.district ");
            sql.append("ORDER BY sch.school_name");

            PreparedStatement ps = conn.prepareStatement(sql.toString());
            if (allDivisions) {
                ps.setString(1, districtName);
            } else {
                ps.setString(1, divisionName);
                ps.setString(2, districtName);
            }

            ResultSet rs = ps.executeQuery();

            int totalStudentsAll = 0;
            int schoolCount = 0;

            while (rs.next()) {
                JSONObject school = new JSONObject();
                String udiseNo = rs.getString("udise_no");
                String schoolName = rs.getString("school_name");
                int totalStudents = rs.getInt("total_students");

                school.put("udiseNo", udiseNo);
                school.put("schoolName", schoolName != null ? schoolName : udiseNo);
                school.put("totalStudents", totalStudents);
                school.put("marathiDistribution", buildDistribution(rs, "marathi", 6, totalStudents));
                school.put("mathDistribution", buildDistribution(rs, "math", 8, totalStudents));
                school.put("englishDistribution", buildDistribution(rs, "english", 6, totalStudents));

                schoolData.put(school);

                totalStudentsAll += totalStudents;
                schoolCount++;
            }

            result.put("schools", schoolData);
            result.put("districtName", districtName);
            result.put("totalStudents", totalStudentsAll);
            result.put("schoolCount", schoolCount);
            result.put("phaseFilter", phaseFilter != null ? phaseFilter : "all");
            result.put("scope", allDivisions ? "ALL" : divisionName);
        }

        return result;
    }

    /** Build the per-level distribution array for a subject from the current result-set row. */
    private JSONArray buildDistribution(ResultSet rs, String subject, int maxLevel, int totalStudents) throws SQLException {
        JSONArray distribution = new JSONArray();
        for (int level = 0; level <= maxLevel; level++) {
            int count = rs.getInt(subject + "_level_" + level);
            double percentage = (totalStudents > 0) ? ((double) count / totalStudents) * 100 : 0;
            JSONObject levelData = new JSONObject();
            levelData.put("level", level);
            levelData.put("count", count);
            levelData.put("percentage", Math.round(percentage * 100.0) / 100.0);
            distribution.put(levelData);
        }
        return distribution;
    }

    private String getPhaseColumn(String subject, String phaseFilter) {
        if (phaseFilter == null || "current".equals(phaseFilter)) {
            return subject + "_level";
        }
        if ("all".equals(phaseFilter)) {
            return "GREATEST(COALESCE(phase1_" + subject + ", 0), COALESCE(phase2_" + subject + ", 0), " +
                   "COALESCE(phase3_" + subject + ", 0), COALESCE(phase4_" + subject + ", 0), " +
                   "COALESCE(" + subject + "_level, 0))";
        }
        switch (phaseFilter) {
            case "1": return "phase1_" + subject;
            case "2": return "phase2_" + subject;
            case "3": return "phase3_" + subject;
            case "4": return "phase4_" + subject;
            default:  return subject + "_level";
        }
    }
}
