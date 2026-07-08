package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

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
 * Returns teacher-wise FLN progress summaries for a division.
 *
 * Progress is defined per class:
 *   Class 1-2  : Marathi/English >= 2, Math >= 2/3
 *   Class 3-4  : Marathi/English >= 3, Math >= 3/4
 *   Class 5-6  : Marathi/English >= 4, Math >= 5
 *   Class 7-8  : Marathi/English >= 5, Math >= 6/7
 *   Class 9    : Marathi/English >= 6, Math >= 8
 *
 * A student is "progress" only if ALL three subjects meet the class minimum.
 */
@WebServlet("/teacher-progress")
public class TeacherProgressServlet extends HttpServlet {

    // Pre-aggregated student subquery — computed once per (udise,class,section)
    // instead of per teacher-row, eliminating the expensive outer GROUP BY.
    private static final String STUDENT_AGG_SUBQUERY =
        "(SELECT udise_no, class, section, " +
        "COUNT(*) AS total_students, " +
        "SUM(CASE WHEN " +
        "  GREATEST(COALESCE(CAST(phase1_marathi  AS UNSIGNED),0),COALESCE(CAST(phase2_marathi  AS UNSIGNED),0),COALESCE(CAST(phase3_marathi  AS UNSIGNED),0),COALESCE(CAST(phase4_marathi  AS UNSIGNED),0)) " +
        "    >= CASE class WHEN '1' THEN 2 WHEN '2' THEN 2 WHEN '3' THEN 3 WHEN '4' THEN 3 WHEN '5' THEN 4 WHEN '6' THEN 4 WHEN '7' THEN 5 WHEN '8' THEN 5 WHEN '9' THEN 6 ELSE 2 END " +
        "  AND " +
        "  GREATEST(COALESCE(CAST(phase1_math     AS UNSIGNED),0),COALESCE(CAST(phase2_math     AS UNSIGNED),0),COALESCE(CAST(phase3_math     AS UNSIGNED),0),COALESCE(CAST(phase4_math     AS UNSIGNED),0)) " +
        "    >= CASE class WHEN '1' THEN 2 WHEN '2' THEN 3 WHEN '3' THEN 3 WHEN '4' THEN 4 WHEN '5' THEN 5 WHEN '6' THEN 5 WHEN '7' THEN 6 WHEN '8' THEN 7 WHEN '9' THEN 8 ELSE 2 END " +
        "  AND " +
        "  GREATEST(COALESCE(CAST(phase1_english  AS UNSIGNED),0),COALESCE(CAST(phase2_english  AS UNSIGNED),0),COALESCE(CAST(phase3_english  AS UNSIGNED),0),COALESCE(CAST(phase4_english  AS UNSIGNED),0)) " +
        "    >= CASE class WHEN '1' THEN 2 WHEN '2' THEN 2 WHEN '3' THEN 3 WHEN '4' THEN 3 WHEN '5' THEN 4 WHEN '6' THEN 4 WHEN '7' THEN 5 WHEN '8' THEN 5 WHEN '9' THEN 6 ELSE 2 END " +
        "THEN 1 ELSE 0 END) AS progress_count " +
        "FROM students WHERE is_active = 1 GROUP BY udise_no, class, section) stg";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;

        if (user == null ||
            (user.getUserType() != User.UserType.DIVISION &&
             user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.getWriter().write("{\"error\":\"Unauthorized\"}");
            return;
        }

        String division = (user.getUserType() == User.UserType.DIVISION)
            ? user.getDivisionName()
            : request.getParameter("division");

        String districtParam = request.getParameter("district");
        String classParam    = request.getParameter("class");

        if (division == null || division.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("{\"error\":\"division required\"}");
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();

            // Optimised query: student aggregation done once in a derived table (stg),
            // then joined to teacher_assignments — eliminates outer GROUP BY entirely.
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT ta.assignment_id, ta.teacher_id, ta.teacher_name, ta.class, ta.section, ");
            sql.append("ta.is_class_teacher, ta.udise_code, s.school_name, s.district_name, t.mobile_number, ");
            sql.append("COALESCE(stg.total_students, 0)  AS total_students, ");
            sql.append("COALESCE(stg.progress_count, 0)  AS progress_count ");
            sql.append("FROM teacher_assignments ta ");
            sql.append("INNER JOIN teachers t ON ta.teacher_id = t.teacher_id AND t.is_active = 1 ");
            sql.append("INNER JOIN schools s ON s.udise_no COLLATE utf8mb4_unicode_ci = ta.udise_code COLLATE utf8mb4_unicode_ci ");
            sql.append("LEFT JOIN ").append(STUDENT_AGG_SUBQUERY);
            sql.append("  ON stg.udise_no COLLATE utf8mb4_unicode_ci = ta.udise_code COLLATE utf8mb4_unicode_ci ");
            sql.append("  AND stg.class = ta.class AND stg.section = ta.section ");
            sql.append("WHERE ta.is_active = 1 AND ta.division = ? ");

            if (districtParam != null && !districtParam.trim().isEmpty()) {
                sql.append("AND s.district_name COLLATE utf8mb4_unicode_ci = ? ");
            }
            if (classParam != null && !classParam.trim().isEmpty()) {
                sql.append("AND ta.class = ? ");
            }

            sql.append("ORDER BY s.district_name, s.school_name, ta.class, ta.section, ta.teacher_name");

            pstmt = conn.prepareStatement(sql.toString());
            pstmt.setQueryTimeout(60);
            int idx = 1;
            pstmt.setString(idx++, division);
            if (districtParam != null && !districtParam.trim().isEmpty()) pstmt.setString(idx++, districtParam);
            if (classParam    != null && !classParam.trim().isEmpty())    pstmt.setString(idx++, classParam);

            rs = pstmt.executeQuery();

            // Build nested structure: district -> school -> teachers
            // Use LinkedHashMap to preserve insertion order
            Map<String, Map<String, List<Map<String, Object>>>> districtMap = new LinkedHashMap<>();

            int totalTeachers = 0, excellent = 0, good = 0, average = 0, needsImprovement = 0;
            double totalPct = 0;

            while (rs.next()) {
                String district  = rs.getString("district_name");
                String school    = rs.getString("school_name");
                String udise     = rs.getString("udise_code");
                int    teacherId = rs.getInt("teacher_id");
                String teacherName  = rs.getString("teacher_name");
                String mobile       = rs.getString("mobile_number");
                String cls          = rs.getString("class");
                String section      = rs.getString("section");
                boolean isClassTeacher = rs.getInt("is_class_teacher") == 1;
                int totalStudents   = rs.getInt("total_students");
                int progressCount   = rs.getInt("progress_count");
                int nonProgressCount = totalStudents - progressCount;
                double progressPct  = totalStudents > 0
                    ? Math.round((progressCount * 100.0 / totalStudents) * 10.0) / 10.0
                    : 0.0;

                String badge = badge(progressPct, totalStudents);

                totalTeachers++;
                totalPct += progressPct;
                if ("excellent".equals(badge)) excellent++;
                else if ("good".equals(badge)) good++;
                else if ("average".equals(badge)) average++;
                else if ("needs-improvement".equals(badge)) needsImprovement++;

                Map<String, Object> teacher = new LinkedHashMap<>();
                teacher.put("teacherId", teacherId);
                teacher.put("teacherName", teacherName);
                teacher.put("mobile", mobile != null ? mobile : "");
                teacher.put("classAssigned", cls);
                teacher.put("sectionAssigned", section);
                teacher.put("isClassTeacher", isClassTeacher);
                teacher.put("udiseCode", udise);
                teacher.put("totalStudents", totalStudents);
                teacher.put("progressCount", progressCount);
                teacher.put("nonProgressCount", nonProgressCount);
                teacher.put("progressPct", progressPct);
                teacher.put("badge", badge);

                districtMap
                    .computeIfAbsent(district, k -> new LinkedHashMap<>())
                    .computeIfAbsent(school + "||" + udise, k -> new ArrayList<>())
                    .add(teacher);
            }

            // Convert to array structure
            List<Map<String, Object>> districts = new ArrayList<>();
            for (Map.Entry<String, Map<String, List<Map<String, Object>>>> de : districtMap.entrySet()) {
                Map<String, Object> districtObj = new LinkedHashMap<>();
                districtObj.put("districtName", de.getKey());

                List<Map<String, Object>> schools = new ArrayList<>();
                for (Map.Entry<String, List<Map<String, Object>>> se : de.getValue().entrySet()) {
                    String[] parts = se.getKey().split("\\|\\|", 2);
                    Map<String, Object> schoolObj = new LinkedHashMap<>();
                    schoolObj.put("schoolName", parts[0]);
                    schoolObj.put("udiseNo", parts.length > 1 ? parts[1] : "");
                    schoolObj.put("teachers", se.getValue());
                    schools.add(schoolObj);
                }
                districtObj.put("schools", schools);
                districtObj.put("totalTeachers", schools.stream()
                    .mapToInt(s -> ((List<?>) s.get("teachers")).size()).sum());
                districts.add(districtObj);
            }

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("summary", buildSummary(totalTeachers, excellent, good, average,
                                               needsImprovement, totalPct));
            result.put("districts", districts);

            response.getWriter().write(new Gson().toJson(result));

        } catch (Exception e) {
            System.err.println("TeacherProgressServlet error: " + e.getMessage());
            e.printStackTrace();
            String errMsg = e.getMessage() != null ? e.getMessage().replace("\"", "'") : e.getClass().getSimpleName();
            response.getWriter().write("{\"error\":\"" + errMsg + "\"}");
        } finally {
            if (rs    != null) try { rs.close();    } catch (SQLException ignored) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
            if (conn  != null) try { conn.close();  } catch (SQLException ignored) {}
        }
    }

    private String badge(double pct, int totalStudents) {
        if (totalStudents == 0) return "no-data";
        if (pct >= 80) return "excellent";
        if (pct >= 60) return "good";
        if (pct >= 40) return "average";
        return "needs-improvement";
    }

    private Map<String, Object> buildSummary(int total, int excellent, int good, int average,
                                              int needsImprovement, double totalPct) {
        Map<String, Object> s = new LinkedHashMap<>();
        s.put("totalTeachers", total);
        s.put("excellentTeachers", excellent);
        s.put("goodTeachers", good);
        s.put("averageTeachers", average);
        s.put("needsImprovementTeachers", needsImprovement);
        s.put("avgProgressPct", total > 0
            ? Math.round((totalPct / total) * 10.0) / 10.0 : 0.0);
        return s;
    }
}
