package com.vjnt.servlet;

import com.vjnt.util.DatabaseConnection;
import com.google.gson.Gson;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.*;
import java.util.*;

/**
 * Super Division Officer version of {@link GetDivisionStudentLevelsServlet}.
 *
 * The {@code division} parameter is OPTIONAL: missing/empty/"ALL" returns students
 * across every division; a specific division drills down. Unlike the original, the
 * division placeholder is only bound when a real division filter is applied (the
 * original bound it unconditionally, breaking the all-divisions path).
 * Existing division servlets are left untouched.
 */
@WebServlet("/super-student-levels")
public class SuperGetDivisionStudentLevelsServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // Restrict to Super Division Officer sessions
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        if (user == null || user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.getWriter().write("[]");
            return;
        }

        String division = request.getParameter("division");
        String district = request.getParameter("district");
        String school = request.getParameter("school");
        String classFilter = request.getParameter("class");

        boolean allDivisions = division == null || division.trim().isEmpty()
                || "ALL".equalsIgnoreCase(division.trim());

        List<Map<String, Object>> students = new ArrayList<>();
        int totalCount = 0;
        int totalSchools = 0;
        int totalDistricts = 0;

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();

            // WHERE clause shared by both COUNT and data queries
            StringBuilder where = new StringBuilder("WHERE s.is_active = 1 ");
            // The FLN programme covers classes I-IX only; anything else is out of scope.
            where.append("AND TRIM(s.class) IN ").append(com.vjnt.dao.StudentDAO.CLASS_I_TO_IX).append(" ");
            if (!allDivisions) {
                where.append("AND s.division = ? ");
            }
            if (district != null && !district.isEmpty()) {
                // Coalesced, so students at a UDISE missing from the schools master are still
                // reachable by their district instead of being unfilterable.
                where.append("AND COALESCE(sch.district_name, s.district) = ? ");
            }
            if (school != null && !school.isEmpty()) {
                where.append("AND s.udise_no = ? ");
            }
            if (classFilter != null && !classFilter.isEmpty()) {
                where.append("AND TRIM(s.class) = ? ");
            }

            // COUNT query for accurate summary totals (no LIMIT)
            // LEFT JOIN, not INNER: a UDISE missing from the schools master would otherwise
            // take its students off this listing entirely and out of the summary totals.
            String countSql = "SELECT COUNT(*) AS total_students, " +
                    "COUNT(DISTINCT s.udise_no) AS total_schools, " +
                    "COUNT(DISTINCT COALESCE(sch.district_name, s.district)) AS total_districts " +
                    "FROM students s " +
                    "LEFT JOIN schools sch ON s.udise_no = sch.udise_no COLLATE utf8mb4_unicode_ci " +
                    where.toString();

            pstmt = conn.prepareStatement(countSql);
            int paramIndex = 1;
            if (!allDivisions) pstmt.setString(paramIndex++, division);
            if (district != null && !district.isEmpty()) pstmt.setString(paramIndex++, district);
            if (school != null && !school.isEmpty()) pstmt.setString(paramIndex++, school);
            if (classFilter != null && !classFilter.isEmpty()) pstmt.setString(paramIndex++, classFilter);

            rs = pstmt.executeQuery();
            if (rs.next()) {
                totalCount = rs.getInt("total_students");
                totalSchools = rs.getInt("total_schools");
                totalDistricts = rs.getInt("total_districts");
            }
            rs.close();
            pstmt.close();

            // Data query (LIMIT 5000 for performance)
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT s.student_id, s.student_name, s.student_pen, s.class, ");
            sql.append("s.udise_no, ");
            sql.append("COALESCE(sch.school_name, CONCAT('UDISE ', s.udise_no, ' (not in schools master)')) AS school_name, ");
            sql.append("COALESCE(sch.district_name, s.district, 'Unknown District') AS district_name, ");
            sql.append("s.phase1_marathi, s.phase1_math, s.phase1_english, ");
            sql.append("s.phase2_marathi, s.phase2_math, s.phase2_english, ");
            sql.append("s.phase3_marathi, s.phase3_math, s.phase3_english, ");
            sql.append("s.phase4_marathi, s.phase4_math, s.phase4_english ");
            sql.append("FROM students s ");
            sql.append("LEFT JOIN schools sch ON s.udise_no = sch.udise_no COLLATE utf8mb4_unicode_ci ");
            sql.append(where);
            sql.append("ORDER BY district_name, school_name, s.class, s.student_name ");
            sql.append("LIMIT 5000");

            pstmt = conn.prepareStatement(sql.toString());

            paramIndex = 1;
            if (!allDivisions) {
                pstmt.setString(paramIndex++, division);
            }
            if (district != null && !district.isEmpty()) {
                pstmt.setString(paramIndex++, district);
            }
            if (school != null && !school.isEmpty()) {
                pstmt.setString(paramIndex++, school);
            }
            if (classFilter != null && !classFilter.isEmpty()) {
                pstmt.setString(paramIndex++, classFilter);
            }

            rs = pstmt.executeQuery();

            while (rs.next()) {
                Map<String, Object> student = new HashMap<>();
                student.put("studentId", rs.getInt("student_id"));
                student.put("studentName", rs.getString("student_name"));
                student.put("studentPen", rs.getString("student_pen"));
                student.put("studentClass", rs.getString("class"));
                student.put("udiseNo", rs.getString("udise_no"));
                student.put("schoolName", rs.getString("school_name"));
                student.put("district", rs.getString("district_name"));

                int maxMarathi = Math.max(
                    Math.max(getIntOrZero(rs.getString("phase1_marathi")), getIntOrZero(rs.getString("phase2_marathi"))),
                    Math.max(getIntOrZero(rs.getString("phase3_marathi")), getIntOrZero(rs.getString("phase4_marathi")))
                );
                int maxMath = Math.max(
                    Math.max(getIntOrZero(rs.getString("phase1_math")), getIntOrZero(rs.getString("phase2_math"))),
                    Math.max(getIntOrZero(rs.getString("phase3_math")), getIntOrZero(rs.getString("phase4_math")))
                );
                int maxEnglish = Math.max(
                    Math.max(getIntOrZero(rs.getString("phase1_english")), getIntOrZero(rs.getString("phase2_english"))),
                    Math.max(getIntOrZero(rs.getString("phase3_english")), getIntOrZero(rs.getString("phase4_english")))
                );

                student.put("marathiLevel", String.valueOf(maxMarathi));
                student.put("mathLevel", String.valueOf(maxMath));
                student.put("englishLevel", String.valueOf(maxEnglish));

                int maxLevel = Math.max(Math.max(maxMarathi, maxMath), maxEnglish);
                int currentPhase = maxLevel > 0 ? Math.min(((maxLevel - 1) / 3) + 1, 4) : 1;
                student.put("currentPhase", currentPhase);

                student.put("evsLevel", "0");
                student.put("scienceLevel", "0");
                student.put("historyLevel", "0");

                students.add(student);
            }

        } catch (Exception e) {
            System.err.println("Error fetching super student levels: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { }
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
            if (conn != null) try { conn.close(); } catch (SQLException e) { }
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("totalCount", totalCount);
        result.put("totalSchools", totalSchools);
        result.put("totalDistricts", totalDistricts);
        result.put("students", students);
        response.getWriter().write(new Gson().toJson(result));
    }

    private int getIntOrZero(String value) {
        if (value == null || value.isEmpty() || value.equals("null")) {
            return 0;
        }
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return 0;
        }
    }
}
