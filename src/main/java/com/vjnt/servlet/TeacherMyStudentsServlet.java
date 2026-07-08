package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.json.JSONArray;
import org.json.JSONObject;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

/**
 * Teacher "My Students" Servlet
 *
 * For the logged-in TEACHER user:
 *  1. Finds the teacher record (users.username = teachers.mobile_number at the same school).
 *  2. For every class-section assigned to the teacher, randomly maps a maximum
 *     of 5 students of that class to the teacher (teacher_student_mapping table,
 *     created automatically). Students already mapped to another teacher of the
 *     same class are not picked, so each student belongs to only one teacher.
 *     The mapping is random and idempotent — already-mapped students never move.
 *  3. Returns only the students mapped to THIS teacher.
 */
@WebServlet("/teacher-my-students")
public class TeacherMyStudentsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** Maximum students randomly mapped to a teacher per assigned class-section. */
    private static final int MAX_STUDENTS_PER_CLASS = 5;

    private static final String CREATE_MAPPING_TABLE =
            "CREATE TABLE IF NOT EXISTS teacher_student_mapping (" +
            "mapping_id INT AUTO_INCREMENT PRIMARY KEY, " +
            "teacher_id INT NOT NULL, " +
            "udise_code VARCHAR(20) DEFAULT NULL, " +
            "class VARCHAR(10) DEFAULT NULL, " +
            "section VARCHAR(10) DEFAULT NULL, " +
            "student_id INT NOT NULL, " +
            "created_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, " +
            "is_active TINYINT(1) DEFAULT 1, " +
            "UNIQUE KEY uq_teacher_student (teacher_id, student_id), " +
            "KEY idx_map_class (udise_code, class, section)" +
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("user");
        if (user == null || user.getUserType() != User.UserType.TEACHER) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"error\": \"Unauthorized access\"}");
            return;
        }

        JSONObject result = new JSONObject();

        try (Connection conn = DatabaseConnection.getConnection()) {

            // Ensure mapping table exists
            try (Statement st = conn.createStatement()) {
                st.execute(CREATE_MAPPING_TABLE);
            }

            // 1. Resolve the teacher record: username is the mobile number
            int teacherId = -1;
            String teacherName = null;
            String subjectsTaught = null;
            String udise = user.getUdiseNo();

            String teacherSql = "SELECT teacher_id, teacher_name, subjects_taught FROM teachers " +
                                "WHERE mobile_number = ? AND udise_code = ? AND is_active = 1 LIMIT 1";
            try (PreparedStatement ps = conn.prepareStatement(teacherSql)) {
                ps.setString(1, user.getUsername());
                ps.setString(2, udise);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        teacherId = rs.getInt("teacher_id");
                        teacherName = rs.getString("teacher_name");
                        subjectsTaught = rs.getString("subjects_taught");
                    }
                }
            }

            if (teacherId == -1) {
                result.put("error", "Teacher record not found for this login. Contact your School Coordinator.");
                out.print(result.toString());
                return;
            }

            result.put("teacherId", teacherId);
            result.put("teacherName", teacherName);
            result.put("subjectsTaught", subjectsTaught == null ? "" : subjectsTaught);
            result.put("udiseNo", udise);

            // 2. Assignments of this teacher
            JSONArray assignments = new JSONArray();
            List<String[]> classSections = new ArrayList<>();
            String asgSql = "SELECT class, section, subjects_assigned, is_class_teacher FROM teacher_assignments " +
                            "WHERE teacher_id = ? AND is_active = 1 ORDER BY class, section";
            try (PreparedStatement ps = conn.prepareStatement(asgSql)) {
                ps.setInt(1, teacherId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        JSONObject a = new JSONObject();
                        String cls = rs.getString("class");
                        String sec = rs.getString("section");
                        a.put("class", cls);
                        a.put("section", sec);
                        a.put("subjects", rs.getString("subjects_assigned"));
                        a.put("isClassTeacher", rs.getInt("is_class_teacher") == 1);
                        assignments.put(a);
                        classSections.add(new String[]{cls, sec});
                    }
                }
            }
            result.put("assignments", assignments);

            if (classSections.isEmpty()) {
                result.put("students", new JSONArray());
                result.put("totalStudents", 0);
                result.put("message", "No classes assigned yet. Contact your School Coordinator.");
                out.print(result.toString());
                return;
            }

            // 3. For each assigned class-section, randomly map up to 5 students
            //    of that class to this teacher.
            for (String[] cs : classSections) {
                mapRandomStudents(conn, teacherId, udise, cs[0], cs[1]);
            }

            // 4. Fetch only this teacher's mapped students.
            //    The mapping row must still match the student's CURRENT class-section:
            //    when students are promoted (class changes) or deactivated, they
            //    automatically disappear from the teacher's list, and step 3 will
            //    map replacement students from the current class on the next load.
            JSONArray students = new JSONArray();
            String stuSql = "SELECT s.student_id, s.student_name, s.gender, s.student_pen, s.class, s.section, " +
                            "s.marathi_level, s.math_level, s.english_level " +
                            "FROM teacher_student_mapping m " +
                            "JOIN students s ON m.student_id = s.student_id " +
                            "WHERE m.teacher_id = ? AND m.is_active = 1 AND s.is_active = 1 " +
                            "AND m.class COLLATE utf8mb4_unicode_ci = s.class COLLATE utf8mb4_unicode_ci " +
                            "AND m.section COLLATE utf8mb4_unicode_ci = s.section COLLATE utf8mb4_unicode_ci " +
                            "ORDER BY s.class, s.section, s.student_name";
            try (PreparedStatement ps = conn.prepareStatement(stuSql)) {
                ps.setInt(1, teacherId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        JSONObject s = new JSONObject();
                        s.put("studentId", rs.getInt("student_id"));
                        s.put("studentName", rs.getString("student_name"));
                        s.put("gender", rs.getString("gender") == null ? "" : rs.getString("gender"));
                        s.put("studentPen", rs.getString("student_pen") == null ? "" : rs.getString("student_pen"));
                        s.put("class", rs.getString("class"));
                        s.put("section", rs.getString("section"));
                        s.put("marathiLevel", rs.getString("marathi_level") == null ? "-" : rs.getString("marathi_level"));
                        s.put("mathLevel", rs.getString("math_level") == null ? "-" : rs.getString("math_level"));
                        s.put("englishLevel", rs.getString("english_level") == null ? "-" : rs.getString("english_level"));
                        students.put(s);
                    }
                }
            }
            result.put("students", students);
            result.put("totalStudents", students.length());

        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }

        out.print(result.toString());
        out.flush();
    }

    /**
     * Randomly maps up to {@link #MAX_STUDENTS_PER_CLASS} active students of
     * (udise, class, section) to the given teacher. Students already mapped to
     * ANY teacher of this class-section are skipped, so each student belongs to
     * only one teacher. Idempotent: if the teacher already has 5 students for
     * this class, nothing changes.
     */
    private void mapRandomStudents(Connection conn, int teacherId, String udise, String cls, String section)
            throws SQLException {

        // How many students does this teacher already have for this class-section?
        // Only count students who are STILL in this class and active — promoted or
        // deactivated students free up their slot for a replacement.
        int alreadyHave = 0;
        String cSql = "SELECT COUNT(*) FROM teacher_student_mapping m " +
                      "JOIN students s ON m.student_id = s.student_id " +
                      "WHERE m.teacher_id = ? AND m.udise_code = ? AND m.class = ? AND m.section = ? " +
                      "AND m.is_active = 1 AND s.is_active = 1 " +
                      "AND m.class COLLATE utf8mb4_unicode_ci = s.class COLLATE utf8mb4_unicode_ci " +
                      "AND m.section COLLATE utf8mb4_unicode_ci = s.section COLLATE utf8mb4_unicode_ci";
        try (PreparedStatement ps = conn.prepareStatement(cSql)) {
            ps.setInt(1, teacherId);
            ps.setString(2, udise);
            ps.setString(3, cls);
            ps.setString(4, section);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) alreadyHave = rs.getInt(1);
            }
        }
        int needed = MAX_STUDENTS_PER_CLASS - alreadyHave;
        if (needed <= 0) return;

        // Students of this class-section already mapped to any teacher
        Set<Integer> mapped = new HashSet<>();
        String mSql = "SELECT student_id FROM teacher_student_mapping " +
                      "WHERE udise_code = ? AND class = ? AND section = ? AND is_active = 1";
        try (PreparedStatement ps = conn.prepareStatement(mSql)) {
            ps.setString(1, udise);
            ps.setString(2, cls);
            ps.setString(3, section);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) mapped.add(rs.getInt(1));
            }
        }

        // Active students of this class-section not yet mapped
        List<Integer> unmapped = new ArrayList<>();
        String sSql = "SELECT student_id FROM students " +
                      "WHERE udise_no = ? AND class = ? AND section = ? AND is_active = 1";
        try (PreparedStatement ps = conn.prepareStatement(sSql)) {
            ps.setString(1, udise);
            ps.setString(2, cls);
            ps.setString(3, section);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int id = rs.getInt(1);
                    if (!mapped.contains(id)) unmapped.add(id);
                }
            }
        }
        if (unmapped.isEmpty()) return;

        // Pick the needed number of random students for this teacher
        Collections.shuffle(unmapped);
        List<Integer> picked = unmapped.subList(0, Math.min(needed, unmapped.size()));

        String insSql = "INSERT IGNORE INTO teacher_student_mapping (teacher_id, udise_code, class, section, student_id) " +
                        "VALUES (?, ?, ?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(insSql)) {
            for (Integer studentId : picked) {
                ps.setInt(1, teacherId);
                ps.setString(2, udise);
                ps.setString(3, cls);
                ps.setString(4, section);
                ps.setInt(5, studentId);
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }
}
