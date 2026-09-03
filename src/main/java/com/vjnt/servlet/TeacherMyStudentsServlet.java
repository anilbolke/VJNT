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
 *  2. For every class-section assigned to the teacher and for EVERY SUBJECT the
 *     teacher teaches in that class-section, randomly maps a percentage of the
 *     class's active students to the teacher (teacher_student_mapping table,
 *     created automatically). The percentage comes from the app_settings key
 *     teacher_student_map_percent (default 25, maintained by the Data Admin via
 *     /admin-settings). Only students whose CURRENT level in that subject
 *     (latest phase level) is 1 to 4 are eligible for mapping.
 *     A teacher with multiple subjects therefore gets a separate set of
 *     students per subject. Students already mapped to another teacher for the
 *     SAME subject of the same class are not picked, so each student belongs
 *     to only one teacher per subject.
 *     The mapping is random and idempotent — already-mapped students never move.
 *  3. Returns only the students mapped to THIS teacher, each row tagged with
 *     its subject (the dashboard shows students only after the teacher selects
 *     a class AND a subject).
 */
@WebServlet("/teacher-my-students")
public class TeacherMyStudentsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** Only students whose current subject level is within this range are mapped. */
    private static final int MIN_ELIGIBLE_LEVEL = 1;
    private static final int MAX_ELIGIBLE_LEVEL = 4;

    private static final String CREATE_MAPPING_TABLE =
            "CREATE TABLE IF NOT EXISTS teacher_student_mapping (" +
            "mapping_id INT AUTO_INCREMENT PRIMARY KEY, " +
            "teacher_id INT NOT NULL, " +
            "udise_code VARCHAR(20) DEFAULT NULL, " +
            "class VARCHAR(10) DEFAULT NULL, " +
            "section VARCHAR(10) DEFAULT NULL, " +
            "subject VARCHAR(50) DEFAULT NULL, " +
            "student_id INT NOT NULL, " +
            "created_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, " +
            "is_active TINYINT(1) DEFAULT 1, " +
            "UNIQUE KEY uq_teacher_student_subject (teacher_id, student_id, subject), " +
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

            // Ensure mapping table exists (and has the per-subject column)
            try (Statement st = conn.createStatement()) {
                st.execute(CREATE_MAPPING_TABLE);
            }
            ensureSubjectColumn(conn);

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

            // 2. Assignments of this teacher. Each assignment may carry multiple
            //    comma-separated subjects — students are mapped per subject.
            JSONArray assignments = new JSONArray();
            List<String[]> classSectionSubjects = new ArrayList<>(); // [class, section, subject]
            String asgSql = "SELECT class, section, subjects_assigned, is_class_teacher FROM teacher_assignments " +
                            "WHERE teacher_id = ? AND is_active = 1 ORDER BY class, section";
            try (PreparedStatement ps = conn.prepareStatement(asgSql)) {
                ps.setInt(1, teacherId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        JSONObject a = new JSONObject();
                        String cls = rs.getString("class");
                        String sec = rs.getString("section");
                        String subjectsAssigned = rs.getString("subjects_assigned");
                        a.put("class", cls);
                        a.put("section", sec);
                        a.put("subjects", subjectsAssigned);
                        a.put("isClassTeacher", rs.getInt("is_class_teacher") == 1);
                        assignments.put(a);
                        for (String subject : splitSubjects(subjectsAssigned, subjectsTaught)) {
                            classSectionSubjects.add(new String[]{cls, sec, subject});
                        }
                    }
                }
            }
            result.put("assignments", assignments);

            if (classSectionSubjects.isEmpty()) {
                result.put("students", new JSONArray());
                result.put("totalStudents", 0);
                result.put("message", "No classes assigned yet. Contact your School Coordinator.");
                out.print(result.toString());
                return;
            }

            // 3. For each assigned class-section-subject, randomly map the
            //    admin-configured percentage of that class's students (only
            //    those at subject level 1-4) to this teacher for that subject.
            int mapPercent = AdminSettingsServlet.getIntSetting(conn,
                    AdminSettingsServlet.KEY_MAP_PERCENT, AdminSettingsServlet.DEFAULT_MAP_PERCENT);
            result.put("mapPercent", mapPercent);
            for (String[] css : classSectionSubjects) {
                mapRandomStudents(conn, teacherId, udise, css[0], css[1], css[2], mapPercent);
            }

            // 4. Fetch only this teacher's mapped students (one row per subject).
            //    The mapping row must still match the student's CURRENT class-section:
            //    when students are promoted (class changes) or deactivated, they
            //    automatically disappear from the teacher's list, and step 3 will
            //    map replacement students from the current class on the next load.
            JSONArray students = new JSONArray();
            // The mapping row must match the student's CURRENT class AND section
            // (TRIM/COLLATE so stray spaces or a collation difference don't drop
            // rows). Promoted / moved / deactivated students fall off the list and
            // step 3 maps replacements from the current class-section next load.
            String stuSql = "SELECT s.student_id, s.student_name, s.gender, s.student_pen, s.class, s.section, " +
                            "s.marathi_level, s.math_level, s.english_level, m.subject " +
                            "FROM teacher_student_mapping m " +
                            "JOIN students s ON m.student_id = s.student_id " +
                            "WHERE m.teacher_id = ? AND m.is_active = 1 AND s.is_active = 1 " +
                            "AND TRIM(m.class) COLLATE utf8mb4_unicode_ci = TRIM(s.class) COLLATE utf8mb4_unicode_ci " +
                            "AND TRIM(m.section) COLLATE utf8mb4_unicode_ci = TRIM(s.section) COLLATE utf8mb4_unicode_ci " +
                            "ORDER BY s.class, s.section, m.subject, s.student_name";
            try (PreparedStatement ps = conn.prepareStatement(stuSql)) {
                ps.setInt(1, teacherId);
                try (ResultSet rs = ps.executeQuery()) {
                    Set<Integer> distinctStudents = new HashSet<>();
                    while (rs.next()) {
                        JSONObject s = new JSONObject();
                        s.put("studentId", rs.getInt("student_id"));
                        s.put("studentName", rs.getString("student_name"));
                        s.put("gender", rs.getString("gender") == null ? "" : rs.getString("gender"));
                        s.put("studentPen", rs.getString("student_pen") == null ? "" : rs.getString("student_pen"));
                        s.put("class", rs.getString("class"));
                        s.put("section", rs.getString("section"));
                        s.put("subject", rs.getString("subject") == null ? "" : rs.getString("subject"));
                        s.put("marathiLevel", rs.getString("marathi_level") == null ? "-" : rs.getString("marathi_level"));
                        s.put("mathLevel", rs.getString("math_level") == null ? "-" : rs.getString("math_level"));
                        s.put("englishLevel", rs.getString("english_level") == null ? "-" : rs.getString("english_level"));
                        students.put(s);
                        distinctStudents.add(rs.getInt("student_id"));
                    }
                    result.put("totalStudents", distinctStudents.size());
                }
            }
            result.put("students", students);

        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }

        out.print(result.toString());
        out.flush();
    }

    /**
     * Splits a comma-separated subjects_assigned value into trimmed, non-empty,
     * de-duplicated subject names. Falls back to the teacher's subjects_taught,
     * then to "General", so every assignment always yields at least one subject.
     */
    private List<String> splitSubjects(String subjectsAssigned, String subjectsTaught) {
        List<String> subjects = new ArrayList<>();
        String source = (subjectsAssigned != null && !subjectsAssigned.trim().isEmpty())
                ? subjectsAssigned : subjectsTaught;
        if (source != null) {
            for (String part : source.split(",")) {
                String subject = part.trim();
                if (!subject.isEmpty() && !subjects.contains(subject)) {
                    subjects.add(subject);
                }
            }
        }
        if (subjects.isEmpty()) {
            subjects.add("General");
        }
        return subjects;
    }

    /**
     * One-time migration for installations where teacher_student_mapping was
     * created before per-subject mapping existed:
     *  - adds the subject column,
     *  - replaces uq_teacher_student (teacher_id, student_id) with
     *    uq_teacher_student_subject (teacher_id, student_id, subject),
     *  - backfills legacy rows with the first subject of that teacher's
     *    assignment for the same class-section, so existing teachers keep
     *    their already-mapped students for their first subject.
     */
    private void ensureSubjectColumn(Connection conn) throws SQLException {
        boolean hasSubject = false;
        String checkSql = "SELECT COUNT(*) FROM information_schema.columns " +
                          "WHERE table_schema = DATABASE() AND table_name = 'teacher_student_mapping' " +
                          "AND column_name = 'subject'";
        try (Statement st = conn.createStatement(); ResultSet rs = st.executeQuery(checkSql)) {
            if (rs.next()) hasSubject = rs.getInt(1) > 0;
        }
        if (hasSubject) return;

        try (Statement st = conn.createStatement()) {
            st.execute("ALTER TABLE teacher_student_mapping ADD COLUMN subject VARCHAR(50) DEFAULT NULL AFTER section");
            try {
                st.execute("ALTER TABLE teacher_student_mapping DROP INDEX uq_teacher_student");
            } catch (SQLException ignore) {
                // index name differs or was already dropped — the ADD below still applies
            }
            st.execute("ALTER TABLE teacher_student_mapping " +
                       "ADD UNIQUE KEY uq_teacher_student_subject (teacher_id, student_id, subject)");
            // Backfill legacy rows: first subject of the matching assignment.
            // COLLATE needed: teacher_assignments and teacher_student_mapping
            // may use different utf8mb4 collations.
            st.executeUpdate(
                "UPDATE teacher_student_mapping m " +
                "JOIN teacher_assignments ta ON ta.teacher_id = m.teacher_id AND ta.is_active = 1 " +
                "AND ta.udise_code COLLATE utf8mb4_unicode_ci = m.udise_code COLLATE utf8mb4_unicode_ci " +
                "AND ta.class COLLATE utf8mb4_unicode_ci = m.class COLLATE utf8mb4_unicode_ci " +
                "AND ta.section COLLATE utf8mb4_unicode_ci = m.section COLLATE utf8mb4_unicode_ci " +
                "SET m.subject = TRIM(SUBSTRING_INDEX(ta.subjects_assigned, ',', 1)) " +
                "WHERE m.subject IS NULL");
        }
    }

    /**
     * Maps the phase-level column prefix for a subject name (Marathi or English
     * spelling). Returns null for unrecognized subjects — no level filter then.
     */
    private String levelColumnFor(String subject) {
        if (subject == null) return null;
        String s = subject.trim().toLowerCase();
        if (s.contains("marathi") || s.contains("मराठी")) return "marathi";
        if (s.contains("math") || s.contains("गणित")) return "math";
        if (s.contains("english") || s.contains("इंग्रजी") || s.contains("इंग्लिश")) return "english";
        return null;
    }

    /**
     * Randomly maps the given percentage of the class-section's active students
     * to the given teacher FOR THE GIVEN SUBJECT. Only students whose current
     * level in that subject (latest recorded phase level) is between
     * {@link #MIN_ELIGIBLE_LEVEL} and {@link #MAX_ELIGIBLE_LEVEL} are eligible.
     * Students already mapped to ANY teacher for this subject of this
     * class-section are skipped, so each student belongs to only one teacher
     * per subject. Idempotent: if the teacher already has enough students for
     * this class-subject, nothing changes.
     */
    private void mapRandomStudents(Connection conn, int teacherId, String udise, String cls, String section,
            String subject, int percent) throws SQLException {

        // Mapping is per class-SECTION: a teacher assigned VIII-A gets VIII-A
        // students, a teacher assigned VIII-B gets VIII-B students. TRIM() guards
        // against stray spaces in the stored class/section values.
        cls = cls == null ? null : cls.trim();
        section = section == null ? null : section.trim();
        if (cls == null || cls.isEmpty() || section == null || section.isEmpty()) return;

        // Class-section size: all active students of this class-section
        int totalInClass = 0;
        String tSql = "SELECT COUNT(*) FROM students WHERE udise_no = ? AND TRIM(class) = ? AND TRIM(section) = ? AND is_active = 1";
        try (PreparedStatement ps = conn.prepareStatement(tSql)) {
            ps.setString(1, udise);
            ps.setString(2, cls);
            ps.setString(3, section);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) totalInClass = rs.getInt(1);
            }
        }
        if (totalInClass == 0) return;

        // Target: the configured percentage of the class-section, at least 1 student
        int target = Math.max(1, (int) Math.ceil(totalInClass * percent / 100.0));

        // Current level in this subject = latest recorded phase level
        String levelCol = levelColumnFor(subject);
        String currentLevel = null;
        if (levelCol != null) {
            currentLevel = "COALESCE(s.phase4_" + levelCol + ", s.phase3_" + levelCol +
                           ", s.phase2_" + levelCol + ", s.phase1_" + levelCol + ")";
        }

        // Deactivate mappings whose student is no longer eligible (level not 1-4).
        if (currentLevel != null) {
            String deactSql = "UPDATE teacher_student_mapping m " +
                              "JOIN students s ON m.student_id = s.student_id " +
                              "SET m.is_active = 0 " +
                              "WHERE m.teacher_id = ? AND m.udise_code = ? AND TRIM(m.class) = ? AND TRIM(m.section) = ? " +
                              "AND m.subject = ? AND m.is_active = 1 " +
                              "AND (" + currentLevel + " IS NULL OR " + currentLevel +
                              " NOT BETWEEN " + MIN_ELIGIBLE_LEVEL + " AND " + MAX_ELIGIBLE_LEVEL + ")";
            try (PreparedStatement ps = conn.prepareStatement(deactSql)) {
                ps.setInt(1, teacherId);
                ps.setString(2, udise);
                ps.setString(3, cls);
                ps.setString(4, section);
                ps.setString(5, subject);
                ps.executeUpdate();
            }
        }

        // How many students does this teacher already have for this class-section-subject?
        int alreadyHave = 0;
        String cSql = "SELECT COUNT(*) FROM teacher_student_mapping m " +
                      "JOIN students s ON m.student_id = s.student_id " +
                      "WHERE m.teacher_id = ? AND m.udise_code = ? AND TRIM(m.class) = ? AND TRIM(m.section) = ? " +
                      "AND m.subject = ? " +
                      "AND m.is_active = 1 AND s.is_active = 1 " +
                      "AND TRIM(m.class) COLLATE utf8mb4_unicode_ci = TRIM(s.class) COLLATE utf8mb4_unicode_ci " +
                      "AND TRIM(m.section) COLLATE utf8mb4_unicode_ci = TRIM(s.section) COLLATE utf8mb4_unicode_ci";
        try (PreparedStatement ps = conn.prepareStatement(cSql)) {
            ps.setInt(1, teacherId);
            ps.setString(2, udise);
            ps.setString(3, cls);
            ps.setString(4, section);
            ps.setString(5, subject);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) alreadyHave = rs.getInt(1);
            }
        }
        int needed = target - alreadyHave;
        if (needed <= 0) return;

        // Students of this class-section already mapped to any teacher for this subject
        Set<Integer> mapped = new HashSet<>();
        String mSql = "SELECT student_id FROM teacher_student_mapping " +
                      "WHERE udise_code = ? AND TRIM(class) = ? AND TRIM(section) = ? AND subject = ? AND is_active = 1";
        try (PreparedStatement ps = conn.prepareStatement(mSql)) {
            ps.setString(1, udise);
            ps.setString(2, cls);
            ps.setString(3, section);
            ps.setString(4, subject);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) mapped.add(rs.getInt(1));
            }
        }

        // Active, ELIGIBLE students of this class-section not yet mapped for this subject.
        String levelFilter = currentLevel == null ? "" :
                " AND " + currentLevel + " BETWEEN " + MIN_ELIGIBLE_LEVEL + " AND " + MAX_ELIGIBLE_LEVEL;
        List<Integer> unmapped = new ArrayList<>();
        String sSql = "SELECT s.student_id FROM students s " +
                      "WHERE s.udise_no = ? AND TRIM(s.class) = ? AND TRIM(s.section) = ? AND s.is_active = 1" + levelFilter;
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

        // ON DUPLICATE: a previously deactivated mapping is reactivated instead of
        // violating the unique key (teacher_id, student_id, subject).
        String insSql = "INSERT INTO teacher_student_mapping (teacher_id, udise_code, class, section, subject, student_id) " +
                        "VALUES (?, ?, ?, ?, ?, ?) " +
                        "ON DUPLICATE KEY UPDATE is_active = 1";
        try (PreparedStatement ps = conn.prepareStatement(insSql)) {
            for (Integer studentId : picked) {
                ps.setInt(1, teacherId);
                ps.setString(2, udise);
                ps.setString(3, cls);
                ps.setString(4, section);
                ps.setString(5, subject);
                ps.setInt(6, studentId);
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }
}
