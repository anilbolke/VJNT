package com.vjnt.servlet;

import com.vjnt.util.DatabaseConnection;
import org.json.JSONArray;
import org.json.JSONObject;

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
 * Super Division Officer version of {@link DivisionStudentLevelsPercentageServlet}.
 *
 * The {@code division} parameter is OPTIONAL here: when it is missing, empty or
 * "ALL", the data is aggregated across every division. When a specific division
 * is supplied, the result is scoped to that division (drill-down).
 *
 * Existing division servlets are left untouched.
 */
@WebServlet("/super-student-levels-percentage")
public class SuperDivisionStudentLevelsPercentageServlet extends HttpServlet {

    private static final int MAX_MARATHI_LEVEL = 6;
    private static final int MAX_MATH_LEVEL = 8;
    private static final int MAX_ENGLISH_LEVEL = 6;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // Restrict to Super Division Officer sessions
        HttpSession session = request.getSession(false);
        com.vjnt.model.User user = (session != null)
                ? (com.vjnt.model.User) session.getAttribute("user") : null;
        if (user == null || user.getUserType() != com.vjnt.model.User.UserType.SUPER_DIVISION_OFFICER) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.getWriter().write(new JSONObject().put("success", false)
                    .put("error", "Access denied").toString());
            return;
        }

        String divisionName = request.getParameter("division");
        String districtName = request.getParameter("district");
        String viewType = request.getParameter("view"); // "district" or "school"
        String phaseFilter = request.getParameter("phase"); // "1", "2", "3", "4", "current", "all"

        JSONObject result = new JSONObject();

        try {
            if ("school".equalsIgnoreCase(viewType) && districtName != null && !districtName.isEmpty()) {
                result = getSchoolWiseData(divisionName, districtName, phaseFilter);
            } else {
                result = getDistrictWiseData(divisionName, phaseFilter);
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

    private JSONObject getDistrictWiseData(String divisionName, String phaseFilter) throws SQLException {
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
            sql.append("SUM(CASE WHEN ").append(marathiCol).append(" IS NOT NULL AND ").append(marathiCol).append(" > 0 THEN ").append(marathiCol).append(" ELSE 0 END) as marathi_total, ");
            sql.append("SUM(CASE WHEN ").append(mathCol).append(" IS NOT NULL AND ").append(mathCol).append(" > 0 THEN ").append(mathCol).append(" ELSE 0 END) as math_total, ");
            sql.append("SUM(CASE WHEN ").append(englishCol).append(" IS NOT NULL AND ").append(englishCol).append(" > 0 THEN ").append(englishCol).append(" ELSE 0 END) as english_total, ");
            sql.append("COUNT(CASE WHEN ").append(marathiCol).append(" IS NOT NULL AND ").append(marathiCol).append(" > 0 THEN 1 END) as marathi_student_count, ");
            sql.append("COUNT(CASE WHEN ").append(mathCol).append(" IS NOT NULL AND ").append(mathCol).append(" > 0 THEN 1 END) as math_student_count, ");
            sql.append("COUNT(CASE WHEN ").append(englishCol).append(" IS NOT NULL AND ").append(englishCol).append(" > 0 THEN 1 END) as english_student_count ");
            sql.append("FROM students s ");
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
            double totalMarathiPercentage = 0;
            double totalMathPercentage = 0;
            double totalEnglishPercentage = 0;
            int districtCount = 0;

            while (rs.next()) {
                JSONObject district = new JSONObject();
                String districtNameStr = rs.getString("district");
                int totalStudents = rs.getInt("total_students");
                int marathiTotal = rs.getInt("marathi_total");
                int mathTotal = rs.getInt("math_total");
                int englishTotal = rs.getInt("english_total");
                int marathiStudentCount = rs.getInt("marathi_student_count");
                int mathStudentCount = rs.getInt("math_student_count");
                int englishStudentCount = rs.getInt("english_student_count");

                double marathiPercentage = (totalStudents > 0) ?
                    ((double) marathiTotal / (totalStudents * MAX_MARATHI_LEVEL)) * 100 : 0;
                double mathPercentage = (totalStudents > 0) ?
                    ((double) mathTotal / (totalStudents * MAX_MATH_LEVEL)) * 100 : 0;
                double englishPercentage = (totalStudents > 0) ?
                    ((double) englishTotal / (totalStudents * MAX_ENGLISH_LEVEL)) * 100 : 0;
                double overallPercentage = (marathiPercentage + mathPercentage + englishPercentage) / 3;

                double avgMarathi = (marathiStudentCount > 0) ? (double) marathiTotal / marathiStudentCount : 0;
                double avgMath = (mathStudentCount > 0) ? (double) mathTotal / mathStudentCount : 0;
                double avgEnglish = (englishStudentCount > 0) ? (double) englishTotal / englishStudentCount : 0;

                district.put("districtName", districtNameStr);
                district.put("totalStudents", totalStudents);
                district.put("marathiPercentage", Math.round(marathiPercentage * 100.0) / 100.0);
                district.put("mathPercentage", Math.round(mathPercentage * 100.0) / 100.0);
                district.put("englishPercentage", Math.round(englishPercentage * 100.0) / 100.0);
                district.put("overallPercentage", Math.round(overallPercentage * 100.0) / 100.0);
                district.put("avgMarathiLevel", Math.round(avgMarathi * 100.0) / 100.0);
                district.put("avgMathLevel", Math.round(avgMath * 100.0) / 100.0);
                district.put("avgEnglishLevel", Math.round(avgEnglish * 100.0) / 100.0);
                district.put("marathiStudentCount", marathiStudentCount);
                district.put("mathStudentCount", mathStudentCount);
                district.put("englishStudentCount", englishStudentCount);

                districtData.put(district);

                totalStudentsAll += totalStudents;
                totalMarathiPercentage += marathiPercentage;
                totalMathPercentage += mathPercentage;
                totalEnglishPercentage += englishPercentage;
                districtCount++;
            }

            result.put("districts", districtData);
            result.put("totalStudents", totalStudentsAll);
            result.put("districtCount", districtCount);
            result.put("avgMarathiPercentage", districtCount > 0 ? Math.round((totalMarathiPercentage / districtCount) * 100.0) / 100.0 : 0);
            result.put("avgMathPercentage", districtCount > 0 ? Math.round((totalMathPercentage / districtCount) * 100.0) / 100.0 : 0);
            result.put("avgEnglishPercentage", districtCount > 0 ? Math.round((totalEnglishPercentage / districtCount) * 100.0) / 100.0 : 0);
            result.put("phaseFilter", phaseFilter != null ? phaseFilter : "current");
            result.put("scope", allDivisions ? "ALL" : divisionName);
        }

        return result;
    }

    private JSONObject getSchoolWiseData(String divisionName, String districtName, String phaseFilter) throws SQLException {
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
            sql.append("SUM(CASE WHEN ").append(marathiCol).append(" IS NOT NULL AND ").append(marathiCol).append(" > 0 THEN ").append(marathiCol).append(" ELSE 0 END) as marathi_total, ");
            sql.append("SUM(CASE WHEN ").append(mathCol).append(" IS NOT NULL AND ").append(mathCol).append(" > 0 THEN ").append(mathCol).append(" ELSE 0 END) as math_total, ");
            sql.append("SUM(CASE WHEN ").append(englishCol).append(" IS NOT NULL AND ").append(englishCol).append(" > 0 THEN ").append(englishCol).append(" ELSE 0 END) as english_total, ");
            sql.append("COUNT(CASE WHEN ").append(marathiCol).append(" IS NOT NULL AND ").append(marathiCol).append(" > 0 THEN 1 END) as marathi_student_count, ");
            sql.append("COUNT(CASE WHEN ").append(mathCol).append(" IS NOT NULL AND ").append(mathCol).append(" > 0 THEN 1 END) as math_student_count, ");
            sql.append("COUNT(CASE WHEN ").append(englishCol).append(" IS NOT NULL AND ").append(englishCol).append(" > 0 THEN 1 END) as english_student_count ");
            sql.append("FROM students s ");
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
            double totalMarathiPercentage = 0;
            double totalMathPercentage = 0;
            double totalEnglishPercentage = 0;
            int schoolCount = 0;

            while (rs.next()) {
                JSONObject school = new JSONObject();
                String udiseNo = rs.getString("udise_no");
                String schoolName = rs.getString("school_name");
                int totalStudents = rs.getInt("total_students");
                int marathiTotal = rs.getInt("marathi_total");
                int mathTotal = rs.getInt("math_total");
                int englishTotal = rs.getInt("english_total");
                int marathiStudentCount = rs.getInt("marathi_student_count");
                int mathStudentCount = rs.getInt("math_student_count");
                int englishStudentCount = rs.getInt("english_student_count");

                double marathiPercentage = (totalStudents > 0) ?
                    ((double) marathiTotal / (totalStudents * MAX_MARATHI_LEVEL)) * 100 : 0;
                double mathPercentage = (totalStudents > 0) ?
                    ((double) mathTotal / (totalStudents * MAX_MATH_LEVEL)) * 100 : 0;
                double englishPercentage = (totalStudents > 0) ?
                    ((double) englishTotal / (totalStudents * MAX_ENGLISH_LEVEL)) * 100 : 0;
                double overallPercentage = (marathiPercentage + mathPercentage + englishPercentage) / 3;

                double avgMarathi = (marathiStudentCount > 0) ? (double) marathiTotal / marathiStudentCount : 0;
                double avgMath = (mathStudentCount > 0) ? (double) mathTotal / mathStudentCount : 0;
                double avgEnglish = (englishStudentCount > 0) ? (double) englishTotal / englishStudentCount : 0;

                school.put("udiseNo", udiseNo);
                school.put("schoolName", schoolName != null ? schoolName : udiseNo);
                school.put("totalStudents", totalStudents);
                school.put("marathiPercentage", Math.round(marathiPercentage * 100.0) / 100.0);
                school.put("mathPercentage", Math.round(mathPercentage * 100.0) / 100.0);
                school.put("englishPercentage", Math.round(englishPercentage * 100.0) / 100.0);
                school.put("overallPercentage", Math.round(overallPercentage * 100.0) / 100.0);
                school.put("avgMarathiLevel", Math.round(avgMarathi * 100.0) / 100.0);
                school.put("avgMathLevel", Math.round(avgMath * 100.0) / 100.0);
                school.put("avgEnglishLevel", Math.round(avgEnglish * 100.0) / 100.0);
                school.put("marathiStudentCount", marathiStudentCount);
                school.put("mathStudentCount", mathStudentCount);
                school.put("englishStudentCount", englishStudentCount);

                schoolData.put(school);

                totalStudentsAll += totalStudents;
                totalMarathiPercentage += marathiPercentage;
                totalMathPercentage += mathPercentage;
                totalEnglishPercentage += englishPercentage;
                schoolCount++;
            }

            result.put("schools", schoolData);
            result.put("districtName", districtName);
            result.put("totalStudents", totalStudentsAll);
            result.put("schoolCount", schoolCount);
            result.put("avgMarathiPercentage", schoolCount > 0 ? Math.round((totalMarathiPercentage / schoolCount) * 100.0) / 100.0 : 0);
            result.put("avgMathPercentage", schoolCount > 0 ? Math.round((totalMathPercentage / schoolCount) * 100.0) / 100.0 : 0);
            result.put("avgEnglishPercentage", schoolCount > 0 ? Math.round((totalEnglishPercentage / schoolCount) * 100.0) / 100.0 : 0);
            result.put("phaseFilter", phaseFilter != null ? phaseFilter : "current");
            result.put("scope", allDivisions ? "ALL" : divisionName);
        }

        return result;
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
