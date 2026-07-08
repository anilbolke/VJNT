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
 * Returns individual student list for a specific teacher's class-section.
 * Called on demand when user expands a teacher card.
 *
 * Params:
 *   udise    - school UDISE code
 *   class    - class number (e.g. "3")
 *   section  - section (e.g. "A")
 *   type     - "progress" | "non-progress" | "all"  (default: all)
 */
@WebServlet("/teacher-progress-students")
public class TeacherProgressStudentsServlet extends HttpServlet {

    // Class-appropriate minimum levels (same logic as TeacherProgressServlet)
    private static final int[][] CLASS_MINS = {
        // {class, minMarathiEnglish, minMath}
        {1, 2, 2}, {2, 2, 3},
        {3, 3, 3}, {4, 3, 4},
        {5, 4, 5}, {6, 4, 5},
        {7, 5, 6}, {8, 5, 7},
        {9, 6, 8}
    };

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
            response.getWriter().write("[]");
            return;
        }

        String udise   = request.getParameter("udise");
        String cls     = request.getParameter("class");
        String section = request.getParameter("section");
        String type    = request.getParameter("type"); // progress | non-progress | all

        if (udise == null || cls == null || section == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("{\"error\":\"udise, class, section required\"}");
            return;
        }

        int[] mins = getClassMins(cls);
        int minME   = mins[0];
        int minMath = mins[1];

        Connection conn  = null;
        PreparedStatement pstmt = null;
        ResultSet rs     = null;

        try {
            conn = DatabaseConnection.getConnection();

            String sql =
                "SELECT student_id, student_name, student_pen, class, section, " +
                "GREATEST(COALESCE(CAST(phase1_marathi AS UNSIGNED),0),COALESCE(CAST(phase2_marathi AS UNSIGNED),0)," +
                "COALESCE(CAST(phase3_marathi AS UNSIGNED),0),COALESCE(CAST(phase4_marathi AS UNSIGNED),0)) AS max_marathi," +
                "GREATEST(COALESCE(CAST(phase1_math AS UNSIGNED),0),COALESCE(CAST(phase2_math AS UNSIGNED),0)," +
                "COALESCE(CAST(phase3_math AS UNSIGNED),0),COALESCE(CAST(phase4_math AS UNSIGNED),0)) AS max_math," +
                "GREATEST(COALESCE(CAST(phase1_english AS UNSIGNED),0),COALESCE(CAST(phase2_english AS UNSIGNED),0)," +
                "COALESCE(CAST(phase3_english AS UNSIGNED),0),COALESCE(CAST(phase4_english AS UNSIGNED),0)) AS max_english " +
                "FROM students " +
                "WHERE udise_no = ? " +
                "AND class = ? " +
                "AND section = ? " +
                "AND is_active = 1 " +
                "ORDER BY student_name";

            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, udise);
            pstmt.setString(2, cls);
            pstmt.setString(3, section);

            rs = pstmt.executeQuery();

            List<Map<String, Object>> result = new ArrayList<>();

            while (rs.next()) {
                int maxMarathi = rs.getInt("max_marathi");
                int maxMath    = rs.getInt("max_math");
                int maxEnglish = rs.getInt("max_english");
                boolean isProgress = maxMarathi >= minME && maxMath >= minMath && maxEnglish >= minME;

                if ("progress".equals(type) && !isProgress)     continue;
                if ("non-progress".equals(type) && isProgress)  continue;

                Map<String, Object> student = new LinkedHashMap<>();
                student.put("studentId", rs.getInt("student_id"));
                student.put("studentName", rs.getString("student_name"));
                student.put("studentPen", rs.getString("student_pen"));
                student.put("classNo", rs.getString("class"));
                student.put("section", rs.getString("section"));
                student.put("marathiLevel", maxMarathi);
                student.put("mathLevel", maxMath);
                student.put("englishLevel", maxEnglish);
                student.put("isProgress", isProgress);
                student.put("minME", minME);
                student.put("minMath", minMath);
                result.add(student);
            }

            response.getWriter().write(new Gson().toJson(result));

        } catch (Exception e) {
            System.err.println("TeacherProgressStudentsServlet error: " + e.getMessage());
            e.printStackTrace();
            response.getWriter().write("[]");
        } finally {
            if (rs    != null) try { rs.close();    } catch (SQLException ignored) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
            if (conn  != null) try { conn.close();  } catch (SQLException ignored) {}
        }
    }

    private int[] getClassMins(String cls) {
        try {
            int c = Integer.parseInt(cls.trim());
            for (int[] row : CLASS_MINS) {
                if (row[0] == c) return new int[]{row[1], row[2]};
            }
        } catch (NumberFormatException ignored) {}
        return new int[]{2, 2}; // default
    }
}
