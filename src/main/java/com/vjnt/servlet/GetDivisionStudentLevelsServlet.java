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

@WebServlet("/GetDivisionStudentLevelsServlet")
public class GetDivisionStudentLevelsServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String division = request.getParameter("division");
        String district = request.getParameter("district");
        String school = request.getParameter("school");
        String classFilter = request.getParameter("class");
        
        List<Map<String, Object>> students = new ArrayList<>();
        int totalCount = 0;
        int totalSchools = 0;
        int totalDistricts = 0;

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();

            HttpSession session = request.getSession(false);
            User user = null;
            if (session != null) user = (User) session.getAttribute("user");

            boolean hasDivision = division != null && !division.isEmpty();
            if (!hasDivision) {
                if (user == null || user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
                    response.getWriter().write("[]");
                    return;
                }
            }

            // Shared WHERE clause
            StringBuilder where = new StringBuilder("WHERE s.is_active = 1 ");
            if (hasDivision) {
                where.append("AND s.division = ? ");
            }
            if (district != null && !district.isEmpty()) {
                where.append("AND sch.district_name = ? ");
            }
            if (school != null && !school.isEmpty()) {
                where.append("AND s.udise_no = ? ");
            }
            if (classFilter != null && !classFilter.isEmpty()) {
                where.append("AND s.class = ? ");
            }

            // COUNT query for accurate summary totals (no LIMIT)
            String countSql = "SELECT COUNT(*) AS total_students, " +
                    "COUNT(DISTINCT s.udise_no) AS total_schools, " +
                    "COUNT(DISTINCT sch.district_name) AS total_districts " +
                    "FROM students s " +
                    "INNER JOIN schools sch ON s.udise_no = sch.udise_no COLLATE utf8mb4_unicode_ci " +
                    where.toString();

            pstmt = conn.prepareStatement(countSql);
            int paramIndex = 1;
            if (hasDivision) pstmt.setString(paramIndex++, division);
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
            sql.append("s.udise_no, sch.school_name, sch.district_name, ");
            sql.append("s.phase1_marathi, s.phase1_math, s.phase1_english, ");
            sql.append("s.phase2_marathi, s.phase2_math, s.phase2_english, ");
            sql.append("s.phase3_marathi, s.phase3_math, s.phase3_english, ");
            sql.append("s.phase4_marathi, s.phase4_math, s.phase4_english ");
            sql.append("FROM students s ");
            sql.append("INNER JOIN schools sch ON s.udise_no = sch.udise_no COLLATE utf8mb4_unicode_ci ");
            sql.append(where);
            sql.append("ORDER BY sch.district_name, sch.school_name, s.class, s.student_name ");
            sql.append("LIMIT 5000");

            pstmt = conn.prepareStatement(sql.toString());

            paramIndex = 1;
            if (hasDivision) {
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
            System.err.println("Error fetching student levels: " + e.getMessage());
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
    
    // Helper method to safely parse integer from string (returns null)
    private Integer getIntOrNull(String value) {
        if (value == null || value.isEmpty() || value.equals("null")) {
            return null;
        }
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return null;
        }
    }
    
    // Helper method to safely parse integer from string (returns 0)
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
