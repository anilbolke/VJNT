package com.vjnt.servlet;

import com.vjnt.model.User;
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
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Per-School Terminal Class — Promotion Correction Tool.
 *
 * Promotion assumed every school ends at Class IX (GRAD_CLASS_IN = "('IX','9')").
 * In a school whose last class is V/VII/VIII, the top row was promoted into a class
 * that does not exist there, stayed is_active=1, and never reached graduated_students.
 *
 * This servlet detects each school's real terminal class from student_phase_history
 * (the complete pre-promotion snapshot) and moves those students to graduated_students
 * with the truthful graduated_from_class.
 *
 * CRITICAL: all phase values are read from student_phase_history, never from students.
 * Promotion Step 5 already overwrote phase1_* with a COALESCE seed and nulled phases 2-4,
 * so the students table no longer holds these students' real marks.
 *
 * Endpoints:
 *   GET  /promotion-correction                              -> list promotion runs
 *   GET  /promotion-correction?promotionId=N&action=scan    -> all-schools damage report
 *   GET  /promotion-correction?promotionId=N&udise=X        -> dry run for one school
 *   POST /promotion-correction?promotionId=N&udise=X        -> apply for one school
 *   POST /promotion-correction?promotionId=N&scope=all      -> apply for every affected school
 *
 * All writes are idempotent: a corrected row has class_after='GRADUATED' in history and an
 * existing graduated_students row, and is excluded from every subsequent run.
 */
@WebServlet("/promotion-correction")
public class PromotionCorrectionServlet extends HttpServlet {

    /**
     * students.class holds BOTH Roman ('VII') and Arabic ('7') numerals.
     * FIELD() returns 0 for the unmatched form and MAX() on the raw string is wrong
     * (MAX('VIII','IX') = 'VIII'), so both forms are normalised to an integer rank.
     */
    private static String rank(String col) {
        return "CASE " + col + " " +
               "WHEN 'I'   THEN 1 WHEN '1' THEN 1 WHEN 'II'   THEN 2 WHEN '2' THEN 2 " +
               "WHEN 'III' THEN 3 WHEN '3' THEN 3 WHEN 'IV'   THEN 4 WHEN '4' THEN 4 " +
               "WHEN 'V'   THEN 5 WHEN '5' THEN 5 WHEN 'VI'   THEN 6 WHEN '6' THEN 6 " +
               "WHEN 'VII' THEN 7 WHEN '7' THEN 7 WHEN 'VIII' THEN 8 WHEN '8' THEN 8 " +
               "WHEN 'IX'  THEN 9 WHEN '9' THEN 9 ELSE 0 END";
    }

    /** Rows still needing correction: top class of their own school, not yet graduated. */
    private static final String NEEDS_CORRECTION =
        "h.promotion_id = ? AND h.udise_no = ? AND " + rank("h.class_before") + " = ? " +
        "AND (h.class_after IS NULL OR h.class_after <> 'GRADUATED')";

    // ─────────────────────────────────────────────────────────────────────────
    // GET
    // ─────────────────────────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        if (!isDataAdmin(request)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print(err("Access denied"));
            return;
        }

        String pidParam = request.getParameter("promotionId");
        String action   = request.getParameter("action");
        String udise    = request.getParameter("udise");

        try (Connection conn = DatabaseConnection.getConnection()) {

            if (pidParam == null || pidParam.trim().isEmpty()) {
                out.print(listRuns(conn).toString());
                return;
            }

            long pid;
            try {
                pid = Long.parseLong(pidParam.trim());
            } catch (NumberFormatException e) {
                out.print(err("Invalid promotionId"));
                return;
            }

            if ("scan".equals(action)) {
                out.print(scanAllSchools(conn, pid).toString());
            } else if (udise != null && !udise.trim().isEmpty()) {
                out.print(dryRunSchool(conn, pid, udise.trim()).toString());
            } else {
                out.print(err("Provide either action=scan or a udise"));
            }

        } catch (SQLException e) {
            System.err.println("PromotionCorrection GET error: " + e.getMessage());
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(err(e.getMessage()));
        }
    }

    /** Every promotion run, newest first, so the admin can pick the all-schools one. */
    private JSONObject listRuns(Connection conn) throws SQLException {
        String sql =
            "SELECT l.promotion_id, l.academic_year, l.promoted_by, l.promotion_date, " +
            "       l.students_promoted, l.students_graduated, l.remarks, " +
            "       (SELECT COUNT(*) FROM student_phase_history h WHERE h.promotion_id = l.promotion_id) AS archived, " +
            "       (SELECT COUNT(DISTINCT h.udise_no) FROM student_phase_history h WHERE h.promotion_id = l.promotion_id) AS schools " +
            "FROM class_promotion_log l ORDER BY l.promotion_id DESC";

        JSONArray runs = new JSONArray();
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String remarks = rs.getString("remarks");
                JSONObject r = new JSONObject();
                r.put("promotionId",       rs.getLong("promotion_id"));
                r.put("academicYear",      str(rs.getString("academic_year")));
                r.put("promotedBy",        str(rs.getString("promoted_by")));
                r.put("promotionDate",     String.valueOf(rs.getTimestamp("promotion_date")));
                r.put("studentsPromoted",  rs.getInt("students_promoted"));
                r.put("studentsGraduated", rs.getInt("students_graduated"));
                r.put("remarks",           str(remarks));
                r.put("archived",          rs.getInt("archived"));
                r.put("schools",           rs.getInt("schools"));
                r.put("isTest",            remarks != null && remarks.contains("[TEST-SINGLE-SCHOOL"));
                runs.put(r);
            }
        }
        JSONObject o = new JSONObject();
        o.put("success", true);
        o.put("runs", runs);
        return o;
    }

    /**
     * Damage report across every school in the run: derived terminal class and how many
     * students sat in it but were promoted instead of graduated.
     */
    private JSONObject scanAllSchools(Connection conn, long pid) throws SQLException {
        String sql =
            "SELECT h.udise_no, " +
            "       MAX(sc.school_name) AS school_name, " +
            "       MAX(h.division) AS division, " +
            "       MAX(h.district) AS district, " +
            "       MAX(" + rank("h.class_before") + ") AS terminal_rank, " +
            "       COUNT(*) AS total_students, " +
            "       SUM(CASE WHEN " + rank("h.class_before") + " = tr.terminal_rank " +
            "                 AND (h.class_after IS NULL OR h.class_after <> 'GRADUATED') " +
            "           THEN 1 ELSE 0 END) AS affected, " +
            "       SUM(CASE WHEN " + rank("h.class_before") + " = tr.terminal_rank " +
            "                 AND h.class_after = 'GRADUATED' " +
            "           THEN 1 ELSE 0 END) AS already_graduated " +
            "FROM student_phase_history h " +
            "JOIN ( SELECT udise_no, MAX(" + rank("class_before") + ") AS terminal_rank " +
            "       FROM student_phase_history WHERE promotion_id = ? GROUP BY udise_no " +
            "     ) tr ON tr.udise_no = h.udise_no " +
            "LEFT JOIN schools sc ON sc.udise_no COLLATE utf8mb4_unicode_ci = h.udise_no " +
            "WHERE h.promotion_id = ? " +
            "GROUP BY h.udise_no, tr.terminal_rank " +
            "ORDER BY affected DESC, terminal_rank ASC, h.udise_no";

        JSONArray schools = new JSONArray();
        int totalAffected = 0, schoolsAffected = 0, shortSchools = 0;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, pid);
            ps.setLong(2, pid);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int terminalRank = rs.getInt("terminal_rank");
                    int affected     = rs.getInt("affected");
                    String udise     = rs.getString("udise_no");
                    String name      = rs.getString("school_name");

                    JSONObject s = new JSONObject();
                    s.put("udise",            str(udise));
                    s.put("schoolName",       name != null ? name : "UDISE: " + udise);
                    s.put("division",         str(rs.getString("division")));
                    s.put("district",         str(rs.getString("district")));
                    s.put("terminalRank",     terminalRank);
                    s.put("terminalClass",    roman(terminalRank));
                    s.put("totalStudents",    rs.getInt("total_students"));
                    s.put("affected",         affected);
                    s.put("alreadyGraduated", rs.getInt("already_graduated"));
                    schools.put(s);

                    totalAffected += affected;
                    if (affected > 0) schoolsAffected++;
                    if (terminalRank > 0 && terminalRank < 9) shortSchools++;
                }
            }
        }

        JSONObject o = new JSONObject();
        o.put("success",         true);
        o.put("promotionId",     pid);
        o.put("schools",         schools);
        o.put("totalAffected",   totalAffected);
        o.put("schoolsAffected", schoolsAffected);
        o.put("shortSchools",    shortSchools);
        o.put("totalSchools",    schools.length());
        return o;
    }

    /** Terminal rank for one school within one promotion run; 0 if the school is not in the run. */
    private int terminalRank(Connection conn, long pid, String udise) throws SQLException {
        String sql = "SELECT MAX(" + rank("class_before") + ") AS tr " +
                     "FROM student_phase_history WHERE promotion_id = ? AND udise_no = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, pid);
            ps.setString(2, udise);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("tr");
            }
        }
        return 0;
    }

    /** Dry run: exactly who would move, with zero writes. */
    private JSONObject dryRunSchool(Connection conn, long pid, String udise) throws SQLException {

        int tr = terminalRank(conn, pid, udise);
        if (tr == 0) {
            return errObj("No archived students for UDISE " + udise + " in promotion #" + pid);
        }

        String schoolName = null, division = null, district = null;
        String sqlSchool =
            "SELECT MAX(sc.school_name) AS school_name, MAX(h.division) AS division, " +
            "       MAX(h.district) AS district " +
            "FROM student_phase_history h " +
            "LEFT JOIN schools sc ON sc.udise_no COLLATE utf8mb4_unicode_ci = h.udise_no " +
            "WHERE h.promotion_id = ? AND h.udise_no = ?";
        try (PreparedStatement ps = conn.prepareStatement(sqlSchool)) {
            ps.setLong(1, pid);
            ps.setString(2, udise);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    schoolName = rs.getString("school_name");
                    division   = rs.getString("division");
                    district   = rs.getString("district");
                }
            }
        }
        if (schoolName == null) schoolName = "UDISE: " + udise;

        // Class-wise shape of the school before promotion
        JSONArray breakdown = new JSONArray();
        String sqlBreak =
            "SELECT h.class_before, COUNT(*) AS cnt, " + rank("h.class_before") + " AS r " +
            "FROM student_phase_history h WHERE h.promotion_id = ? AND h.udise_no = ? " +
            "GROUP BY h.class_before ORDER BY r";
        try (PreparedStatement ps = conn.prepareStatement(sqlBreak)) {
            ps.setLong(1, pid);
            ps.setString(2, udise);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    JSONObject b = new JSONObject();
                    b.put("classBefore", str(rs.getString("class_before")));
                    b.put("count",       rs.getInt("cnt"));
                    b.put("isTerminal",  rs.getInt("r") == tr);
                    breakdown.put(b);
                }
            }
        }

        // The students that would move
        JSONArray students = new JSONArray();
        String sqlStudents =
            "SELECT h.student_id, h.student_name, h.student_pen, h.class_before, h.class_after, " +
            "       h.phase4_marathi, h.phase4_math, h.phase4_english, " +
            "       s.student_id IS NOT NULL AS still_present, s.class AS current_class, s.is_active " +
            "FROM student_phase_history h " +
            "LEFT JOIN students s ON s.student_id = h.student_id " +
            "WHERE " + NEEDS_CORRECTION + " " +
            "ORDER BY h.student_name";
        try (PreparedStatement ps = conn.prepareStatement(sqlStudents)) {
            ps.setLong(1, pid);
            ps.setString(2, udise);
            ps.setInt(3, tr);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    JSONObject st = new JSONObject();
                    st.put("studentId",    rs.getInt("student_id"));
                    st.put("studentName",  str(rs.getString("student_name")));
                    st.put("studentPen",   str(rs.getString("student_pen")));
                    st.put("classBefore",  str(rs.getString("class_before")));
                    st.put("classAfter",   str(rs.getString("class_after")));
                    st.put("currentClass", str(rs.getString("current_class")));
                    st.put("stillPresent", rs.getBoolean("still_present"));
                    st.put("isActive",     rs.getInt("is_active") == 1);
                    st.put("marathi",      rs.getObject("phase4_marathi"));
                    st.put("math",         rs.getObject("phase4_math"));
                    st.put("english",      rs.getObject("phase4_english"));
                    students.put(st);
                }
            }
        }

        int alreadyDone = countAlreadyCorrected(conn, pid, udise, tr);

        JSONObject o = new JSONObject();
        o.put("success",        true);
        o.put("promotionId",    pid);
        o.put("udise",          udise);
        o.put("schoolName",     schoolName);
        o.put("division",       str(division));
        o.put("district",       str(district));
        o.put("terminalRank",   tr);
        o.put("terminalClass",  roman(tr));
        o.put("isShortSchool",  tr < 9);
        o.put("breakdown",      breakdown);
        o.put("students",       students);
        o.put("affected",       students.length());
        o.put("alreadyCorrected", alreadyDone);
        return o;
    }

    private int countAlreadyCorrected(Connection conn, long pid, String udise, int tr) throws SQLException {
        String sql = "SELECT COUNT(*) AS c FROM student_phase_history h " +
                     "WHERE h.promotion_id = ? AND h.udise_no = ? AND " + rank("h.class_before") + " = ? " +
                     "AND h.class_after = 'GRADUATED'";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, pid);
            ps.setString(2, udise);
            ps.setInt(3, tr);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("c");
            }
        }
        return 0;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST — apply the correction
    // ─────────────────────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        if (!isDataAdmin(request)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print(err("Access denied"));
            return;
        }

        HttpSession session = request.getSession(false);
        User user = (User) session.getAttribute("user");
        String username = user.getUsername();

        String pidParam = request.getParameter("promotionId");
        String udise    = request.getParameter("udise");
        String scope    = request.getParameter("scope");

        long pid;
        try {
            pid = Long.parseLong(pidParam == null ? "" : pidParam.trim());
        } catch (NumberFormatException e) {
            out.print(err("Invalid promotionId"));
            return;
        }

        boolean allSchools = "all".equalsIgnoreCase(scope);
        if (!allSchools && (udise == null || udise.trim().isEmpty())) {
            out.print(err("UDISE number is required"));
            return;
        }

        try (Connection conn = DatabaseConnection.getConnection()) {

            String academicYear = academicYearOf(conn, pid);
            if (academicYear == null) {
                out.print(err("Promotion #" + pid + " not found in class_promotion_log"));
                return;
            }

            List<String> targets = new ArrayList<>();
            if (allSchools) {
                targets = schoolsNeedingCorrection(conn, pid);
            } else {
                targets.add(udise.trim());
            }

            JSONArray perSchool = new JSONArray();
            int totalGraduated = 0, totalFailed = 0;

            // One transaction per school: each school's correction is self-contained, so a
            // failure on one school cannot leave another half-applied. Re-running is safe.
            for (String u : targets) {
                JSONObject r = new JSONObject();
                r.put("udise", u);
                try {
                    int n = correctOneSchool(conn, pid, u, academicYear, username);
                    r.put("success",   true);
                    r.put("graduated", n);
                    totalGraduated += n;
                } catch (SQLException e) {
                    System.err.println("PromotionCorrection: FAILED udise=" + u + " : " + e.getMessage());
                    r.put("success", false);
                    r.put("message", e.getMessage());
                    totalFailed++;
                }
                perSchool.put(r);
            }

            if (totalGraduated > 0) {
                stampLog(conn, pid, totalGraduated, username, allSchools ? "ALL SCHOOLS" : targets.get(0));
            }

            JSONObject o = new JSONObject();
            o.put("success",         totalFailed == 0);
            o.put("promotionId",     pid);
            o.put("scope",           allSchools ? "all" : "single");
            o.put("schoolsAttempted", targets.size());
            o.put("schoolsFailed",   totalFailed);
            o.put("totalGraduated",  totalGraduated);
            o.put("perSchool",       perSchool);
            if (totalFailed > 0) {
                o.put("message", totalFailed + " school(s) failed; the rest were corrected. "
                               + "Nothing is half-applied — re-run to retry the failures.");
            }
            out.print(o.toString());

        } catch (Exception e) {
            System.err.println("PromotionCorrection POST error: " + e.getMessage());
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(err(e.getMessage()));
        }
    }

    /**
     * Correct one school inside a single transaction. Returns how many students were graduated.
     *
     * 1. INSERT into graduated_students, phase values sourced from student_phase_history
     * 2. Restore students.class + is_active=0 + the real phase columns from history
     * 3. Flip student_phase_history.class_after to 'GRADUATED' so the archive is self-consistent
     *
     * Step 1 must precede step 2 (it reads students.gender/section/fln_completed), and step 3
     * must come last (it is the flag every step filters on).
     */
    private int correctOneSchool(Connection conn, long pid, String udise,
                                 String academicYear, String username) throws SQLException {

        int tr = terminalRank(conn, pid, udise);
        if (tr == 0) throw new SQLException("No archived students for UDISE " + udise);

        boolean oldAutoCommit = conn.getAutoCommit();
        conn.setAutoCommit(false);
        try {
            // ── Step 1: graduate them, with the truthful graduated_from_class ──────────
            String sqlGraduate =
                "INSERT INTO graduated_students " +
                "  (promotion_id,student_id,student_name,student_pen,gender,udise_no," +
                "   division,district,section,graduated_from_class,academic_year," +
                "   final_marathi_level,final_math_level,final_english_level,fln_completed," +
                "   phase1_marathi,phase1_math,phase1_english," +
                "   phase2_marathi,phase2_math,phase2_english," +
                "   phase3_marathi,phase3_math,phase3_english," +
                "   phase4_marathi,phase4_math,phase4_english,graduated_at) " +
                "SELECT h.promotion_id,h.student_id,h.student_name,h.student_pen,s.gender,h.udise_no," +
                "   h.division,h.district,s.section,h.class_before,?," +
                "   h.phase4_marathi,h.phase4_math,h.phase4_english,COALESCE(s.fln_completed,0)," +
                "   h.phase1_marathi,h.phase1_math,h.phase1_english," +
                "   h.phase2_marathi,h.phase2_math,h.phase2_english," +
                "   h.phase3_marathi,h.phase3_math,h.phase3_english," +
                "   h.phase4_marathi,h.phase4_math,h.phase4_english,NOW() " +
                "FROM student_phase_history h " +
                "LEFT JOIN students s ON s.student_id = h.student_id " +
                "WHERE " + NEEDS_CORRECTION + " " +
                // Gotcha #1: a second click must not double every graduate.
                "AND NOT EXISTS (SELECT 1 FROM graduated_students g " +
                "                WHERE g.student_id = h.student_id AND g.promotion_id = h.promotion_id)";
            int graduated;
            try (PreparedStatement ps = conn.prepareStatement(sqlGraduate)) {
                ps.setString(1, academicYear);
                ps.setLong(2, pid);
                ps.setString(3, udise);
                ps.setInt(4, tr);
                graduated = ps.executeUpdate();
            }

            // ── Step 2: restore the real class and the real marks, then deactivate ────
            String sqlRestore =
                "UPDATE students s " +
                "JOIN student_phase_history h ON h.student_id = s.student_id " +
                "SET s.is_active = 0, " +
                "    s.class = h.class_before, " +
                "    s.phase1_marathi=h.phase1_marathi, s.phase1_math=h.phase1_math, " +
                "    s.phase1_english=h.phase1_english, s.phase1_date=h.phase1_date, " +
                "    s.phase2_marathi=h.phase2_marathi, s.phase2_math=h.phase2_math, " +
                "    s.phase2_english=h.phase2_english, s.phase2_date=h.phase2_date, " +
                "    s.phase3_marathi=h.phase3_marathi, s.phase3_math=h.phase3_math, " +
                "    s.phase3_english=h.phase3_english, s.phase3_date=h.phase3_date, " +
                "    s.phase4_marathi=h.phase4_marathi, s.phase4_math=h.phase4_math, " +
                "    s.phase4_english=h.phase4_english, s.phase4_date=h.phase4_date, " +
                "    s.updated_by=?, s.updated_date=NOW() " +
                "WHERE " + NEEDS_CORRECTION;
            int restored;
            try (PreparedStatement ps = conn.prepareStatement(sqlRestore)) {
                ps.setString(1, username);
                ps.setLong(2, pid);
                ps.setString(3, udise);
                ps.setInt(4, tr);
                restored = ps.executeUpdate();
            }

            // ── Step 3: make the archive self-consistent ──────────────────────────────
            String sqlFlip =
                "UPDATE student_phase_history h SET h.class_after = 'GRADUATED' " +
                "WHERE " + NEEDS_CORRECTION;
            try (PreparedStatement ps = conn.prepareStatement(sqlFlip)) {
                ps.setLong(1, pid);
                ps.setString(2, udise);
                ps.setInt(3, tr);
                ps.executeUpdate();
            }

            conn.commit();
            System.out.println("PromotionCorrection: udise=" + udise + " terminal=" + roman(tr) +
                               " graduated=" + graduated + " restored=" + restored);
            return graduated;

        } catch (SQLException e) {
            try { conn.rollback(); }
            catch (SQLException ex) { System.err.println("Rollback failed: " + ex.getMessage()); }
            throw e;
        } finally {
            try { conn.setAutoCommit(oldAutoCommit); }
            catch (SQLException ex) { System.err.println("autoCommit restore failed: " + ex.getMessage()); }
        }
    }

    /** Schools in this run that still have uncorrected terminal-class students. */
    private List<String> schoolsNeedingCorrection(Connection conn, long pid) throws SQLException {
        String sql =
            "SELECT h.udise_no " +
            "FROM student_phase_history h " +
            "JOIN ( SELECT udise_no, MAX(" + rank("class_before") + ") AS terminal_rank " +
            "       FROM student_phase_history WHERE promotion_id = ? GROUP BY udise_no " +
            "     ) tr ON tr.udise_no = h.udise_no " +
            "WHERE h.promotion_id = ? " +
            "  AND " + rank("h.class_before") + " = tr.terminal_rank " +
            "  AND (h.class_after IS NULL OR h.class_after <> 'GRADUATED') " +
            "GROUP BY h.udise_no ORDER BY h.udise_no";
        List<String> list = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, pid);
            ps.setLong(2, pid);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(rs.getString("udise_no"));
            }
        }
        return list;
    }

    private String academicYearOf(Connection conn, long pid) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT academic_year FROM class_promotion_log WHERE promotion_id = ?")) {
            ps.setLong(1, pid);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("academic_year");
            }
        }
        return null;
    }

    /**
     * Keep the original log row as the single record of this academic year's cohort — the plan
     * calls for reusing promotion_id rather than inventing a phantom promotion, which also keeps
     * fk_gs_promotion satisfied. Counts are adjusted and the correction is noted in remarks.
     */
    private void stampLog(Connection conn, long pid, int corrected, String username, String scopeLabel)
            throws SQLException {
        String sql =
            "UPDATE class_promotion_log SET " +
            "  students_graduated = students_graduated + ?, " +
            "  students_promoted  = GREATEST(students_promoted - ?, 0), " +
            "  remarks = CONCAT(COALESCE(remarks,''), ?) " +
            "WHERE promotion_id = ?";
        String note = " | [TERMINAL-CLASS CORRECTION " + scopeLabel + " +" + corrected +
                      " graduated by " + username + "]";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, corrected);
            ps.setInt(2, corrected);
            ps.setString(3, note);
            ps.setLong(4, pid);
            ps.executeUpdate();
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────
    private boolean isDataAdmin(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return false;
        User user = (User) session.getAttribute("user");
        return user != null && User.UserType.DATA_ADMIN.equals(user.getUserType());
    }

    private static String roman(int r) {
        switch (r) {
            case 1: return "I";
            case 2: return "II";
            case 3: return "III";
            case 4: return "IV";
            case 5: return "V";
            case 6: return "VI";
            case 7: return "VII";
            case 8: return "VIII";
            case 9: return "IX";
            default: return "?";
        }
    }

    private static String str(String s) { return s == null ? "" : s; }

    private static JSONObject errObj(String msg) {
        return new JSONObject().put("success", false).put("message", msg);
    }

    private static String err(String msg) {
        return errObj(msg).toString();
    }
}
