package com.vjnt.servlet;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.util.PromotionClassRules;
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

@WebServlet("/promote-classes")
public class PromoteClassesServlet extends HttpServlet {

    // Classes are stored as Roman numerals (I, II, … IX) but Arabic numerals also occur,
    // so every rule below normalises both forms. See PromotionClassRules.
    //
    // The graduating class is NOT global. It used to be the constant ('IX','9'), which silently
    // promoted the top class of every school that ends at V/VII/VIII into a class that does not
    // exist there. It is now resolved per school from schools.max_class, falling back to the
    // highest class that school actually has students in.

    /** SQL CASE: current class → next class. */
    private static final String CLASS_NEXT_CASE = PromotionClassRules.nextClassCase("s.class");

    /** SQL CASE: current class → class_after label, 'GRADUATED' at that school's terminal class. */
    private static final String CLASS_AFTER_CASE =
        PromotionClassRules.classAfterCase("s.class", "t.terminal_rank");

    /** SQL predicate: sits at or above their school's terminal class. */
    private static final String IS_GRADUATING =
        PromotionClassRules.isGraduating("s.class", "t.terminal_rank");

    /** SQL predicate: below their school's terminal class. */
    private static final String IS_PROMOTING =
        PromotionClassRules.isPromoting("s.class", "t.terminal_rank");

    /**
     * Snapshot of each school's terminal rank, taken once before any write.
     *
     * This MUST be materialised rather than joined as a live subquery. The derived fallback in
     * TERMINAL reads MAX(rank) over ACTIVE students, and Step 4b deactivates exactly those
     * top-class students — so a live subquery would see the terminal class drop one rung
     * mid-transaction and Step 5 would then graduate the next class down as well, cascading.
     */
    private static final String TERMINAL_TMP = "tmp_promotion_terminal";

    /** Materialise the per-school terminal rank into a connection-scoped temporary table. */
    private static void snapshotTerminals(Connection conn) throws SQLException {
        String terminal = PromotionClassRules.terminalSubquery(conn);
        try (Statement st = conn.createStatement()) {
            st.executeUpdate("DROP TEMPORARY TABLE IF EXISTS " + TERMINAL_TMP);
            // udise_no is declared as whatever students.udise_no actually is — type, character set
            // and collation. Both sides of the join below are IMPLICIT, and MySQL rejects an
            // IMPLICIT-vs-IMPLICIT collation mismatch outright, so nothing here may be hardcoded:
            // the databases this runs against disagree (utf8mb4_0900_ai_ci on live and UAT,
            // utf8mb4_unicode_ci elsewhere). See PromotionClassRules.udiseType.
            st.executeUpdate(
                "CREATE TEMPORARY TABLE " + TERMINAL_TMP + " (" +
                "  udise_no " + PromotionClassRules.udiseType(conn).scratchColumnDdl() + " NOT NULL, " +
                "  terminal_rank INT NOT NULL, " +
                "  PRIMARY KEY (udise_no)) ENGINE=InnoDB");
            int n = st.executeUpdate(
                "INSERT INTO " + TERMINAL_TMP + " (udise_no, terminal_rank) " +
                "SELECT t.udise_no, t.terminal_rank FROM (" + terminal + ") t");
            System.out.println("PromoteClasses: terminal class snapshot taken for " + n + " schools");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET — preview
    // ─────────────────────────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        if (!isDataAdmin(request)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print(new JSONObject().put("success", false).put("message", "Access denied").toString());
            return;
        }

        try (Connection conn = DatabaseConnection.getConnection()) {

            // Built per request: the terminal subquery shape depends on whether schools.max_class
            // exists yet (see PromotionClassRules.hasMaxClassColumn).
            String terminal = PromotionClassRules.terminalSubquery(conn);

            // Grouped by class AND by whether that class is terminal for the student's own school,
            // so the same class can legitimately appear twice: "Class VII → VIII" for schools that
            // continue, and "Class VII → GRADUATE" for schools that end there.
            String sql =
                "SELECT s.class AS class, " +
                "       CASE WHEN " + IS_GRADUATING + " THEN 1 ELSE 0 END AS is_grad, " +
                "       COUNT(*) AS cnt, " +
                "       COUNT(DISTINCT s.udise_no) AS school_cnt " +
                "FROM students s " +
                "JOIN (" + terminal + ") t ON t.udise_no = s.udise_no " +
                "WHERE s.is_active = 1 " +
                "GROUP BY s.class, is_grad " +
                "ORDER BY " + PromotionClassRules.rank("s.class") + ", is_grad";

            // How many schools terminate at each class — an at-a-glance check that max_class is sane.
            String sqlTerminals =
                "SELECT t.terminal_rank AS terminal_rank, COUNT(*) AS school_cnt " +
                "FROM (" + terminal + ") t GROUP BY t.terminal_rank ORDER BY t.terminal_rank";

            // Count students where Phase 4 is not yet complete (incomplete schools)
            String sqlIncomplete =
                "SELECT COUNT(*) AS cnt, " +
                "       COUNT(DISTINCT s.udise_no) AS school_cnt " +
                "FROM students s " +
                "JOIN (" + terminal + ") t ON t.udise_no = s.udise_no " +
                "WHERE s.is_active=1 " +
                "AND NOT (" + IS_GRADUATING + ") " +
                "AND (s.phase4_marathi IS NULL OR s.phase4_math IS NULL " +
                "     OR s.phase4_english IS NULL OR s.phase4_date IS NULL)";

            // Class breakdown
            JSONArray preview        = new JSONArray();
            int       totalStudents  = 0;
            int       totalGraduating = 0;

            try (PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String classVal = rs.getString("class");
                    int    count    = rs.getInt("cnt");
                    boolean isGrad  = rs.getInt("is_grad") == 1;
                    String  action  = isGrad
                        ? "→ GRADUATE"
                        : "→ " + PromotionClassRules.nextClass(classVal);

                    JSONObject row = new JSONObject();
                    row.put("class",     classVal);
                    row.put("count",     count);
                    row.put("action",    action);
                    row.put("isTerminal", isGrad);
                    row.put("schools",   rs.getInt("school_cnt"));
                    preview.put(row);

                    totalStudents += count;
                    if (isGrad) totalGraduating += count;
                }
            }

            // Terminal-class distribution across schools
            JSONArray terminals = new JSONArray();
            int schoolsBelowIX = 0;
            try (PreparedStatement ps = conn.prepareStatement(sqlTerminals);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int r = rs.getInt("terminal_rank");
                    int c = rs.getInt("school_cnt");
                    JSONObject row = new JSONObject();
                    row.put("terminalRank",  r);
                    row.put("terminalClass", PromotionClassRules.roman(r));
                    row.put("schools",       c);
                    terminals.put(row);
                    if (r > 0 && r < PromotionClassRules.MAX_RANK) schoolsBelowIX += c;
                }
            }

            // Incomplete phase count
            int incompleteStudents = 0;
            int incompleteSchools  = 0;
            try (PreparedStatement ps = conn.prepareStatement(sqlIncomplete);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    incompleteStudents = rs.getInt("cnt");
                    incompleteSchools  = rs.getInt("school_cnt");
                }
            }

            JSONObject result = new JSONObject();
            result.put("success",             true);
            result.put("preview",             preview);
            result.put("totalStudents",       totalStudents);
            result.put("totalGraduating",     totalGraduating);
            result.put("incompleteStudents",  incompleteStudents);
            result.put("incompleteSchools",   incompleteSchools);
            result.put("terminals",           terminals);
            result.put("schoolsBelowIX",      schoolsBelowIX);
            out.print(result.toString());

        } catch (SQLException e) {
            System.err.println("PromoteClassesServlet GET error: " + e.getMessage());
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(new JSONObject().put("success", false).put("message", e.getMessage()).toString());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST — run promotion
    // ─────────────────────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        if (!isDataAdmin(request)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print(new JSONObject().put("success", false).put("message", "Access denied").toString());
            return;
        }

        User   user         = (User) session.getAttribute("user");
        String username     = user.getUsername();
        String academicYear = request.getParameter("academicYear");
        String remarks      = request.getParameter("remarks");

        if (academicYear == null || academicYear.trim().isEmpty()) {
            out.print(new JSONObject().put("success", false).put("message", "Academic year is required").toString());
            return;
        }

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            // ── Step 0: Freeze each school's terminal class BEFORE any write ──
            snapshotTerminals(conn);

            // ── Step 1: Promotion log entry ──────────────────────────────────
            long promotionId;
            String sqlLog = "INSERT INTO class_promotion_log " +
                            "(academic_year, promoted_by, promotion_date, remarks) VALUES (?,?,NOW(),?)";
            try (PreparedStatement ps = conn.prepareStatement(sqlLog, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, academicYear.trim());
                ps.setString(2, username);
                ps.setString(3, remarks != null ? remarks.trim() : "");
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                if (!keys.next()) throw new SQLException("Failed to obtain promotion_id");
                promotionId = keys.getLong(1);
            }
            System.out.println("PromoteClasses: log created id=" + promotionId);

            // ── Step 2: Archive ALL active student phase data ────────────────
            String sqlArchive =
                "INSERT INTO student_phase_history " +
                "  (promotion_id,student_id,student_name,student_pen,udise_no,division,district," +
                "   class_before,class_after," +
                "   phase1_marathi,phase1_math,phase1_english,phase1_date," +
                "   phase2_marathi,phase2_math,phase2_english,phase2_date," +
                "   phase3_marathi,phase3_math,phase3_english,phase3_date," +
                "   phase4_marathi,phase4_math,phase4_english,phase4_date,archived_at) " +
                "SELECT ?,s.student_id,s.student_name,s.student_pen,s.udise_no,s.division,s.district," +
                "   s.class, " + CLASS_AFTER_CASE + ", " +
                "   s.phase1_marathi,s.phase1_math,s.phase1_english,s.phase1_date," +
                "   s.phase2_marathi,s.phase2_math,s.phase2_english,s.phase2_date," +
                "   s.phase3_marathi,s.phase3_math,s.phase3_english,s.phase3_date," +
                "   s.phase4_marathi,s.phase4_math,s.phase4_english,s.phase4_date,NOW() " +
                "FROM students s " +
                "JOIN " + TERMINAL_TMP + " t ON t.udise_no = s.udise_no " +
                "WHERE s.is_active=1";
            try (PreparedStatement ps = conn.prepareStatement(sqlArchive)) {
                ps.setLong(1, promotionId);
                int rows = ps.executeUpdate();
                System.out.println("PromoteClasses: archived " + rows + " phase history rows");
            }

            // ── Step 3a: Archive phase approvals ────────────────────────────
            String sqlArchiveApprovals =
                "INSERT INTO phase_approvals_history " +
                "  (promotion_id,udise_no,phase_number,approval_status,approved_by,approval_date,remarks,archived_at) " +
                "SELECT ?,udise_no,phase_number,approval_status,approved_by,approved_date,approval_remarks,NOW() " +
                "FROM phase_approvals";
            try (PreparedStatement ps = conn.prepareStatement(sqlArchiveApprovals)) {
                ps.setLong(1, promotionId);
                int rows = ps.executeUpdate();
                System.out.println("PromoteClasses: archived " + rows + " approval records");
            }

            // ── Step 3b: Clear phase_approvals ───────────────────────────────
            try (PreparedStatement ps = conn.prepareStatement("DELETE FROM phase_approvals")) {
                ps.executeUpdate();
            }

            // ── Step 4a: Move Class IX students to graduated_students ─────────
            String sqlGraduate =
                "INSERT INTO graduated_students " +
                "  (promotion_id,student_id,student_name,student_pen,gender,udise_no," +
                "   division,district,section,graduated_from_class,academic_year," +
                "   final_marathi_level,final_math_level,final_english_level,fln_completed," +
                "   phase1_marathi,phase1_math,phase1_english," +
                "   phase2_marathi,phase2_math,phase2_english," +
                "   phase3_marathi,phase3_math,phase3_english," +
                "   phase4_marathi,phase4_math,phase4_english,graduated_at) " +
                // graduated_from_class = s.class, so a terminal-VII school truthfully records 'VII'
                "SELECT ?,s.student_id,s.student_name,s.student_pen,s.gender,s.udise_no," +
                "   s.division,s.district,s.section,s.class,?," +
                "   s.phase4_marathi,s.phase4_math,s.phase4_english,s.fln_completed," +
                "   s.phase1_marathi,s.phase1_math,s.phase1_english," +
                "   s.phase2_marathi,s.phase2_math,s.phase2_english," +
                "   s.phase3_marathi,s.phase3_math,s.phase3_english," +
                "   s.phase4_marathi,s.phase4_math,s.phase4_english,NOW() " +
                "FROM students s " +
                "JOIN " + TERMINAL_TMP + " t ON t.udise_no = s.udise_no " +
                "WHERE s.is_active=1 AND " + IS_GRADUATING;
            int graduatedCount;
            try (PreparedStatement ps = conn.prepareStatement(sqlGraduate)) {
                ps.setLong(1, promotionId);
                ps.setString(2, academicYear.trim());
                graduatedCount = ps.executeUpdate();
                System.out.println("PromoteClasses: graduated " + graduatedCount + " class-IX students");
            }

            // ── Step 4b: Mark Class IX students inactive ──────────────────────
            String sqlDeactivate =
                "UPDATE students s " +
                "JOIN " + TERMINAL_TMP + " t ON t.udise_no = s.udise_no " +
                "SET s.is_active=0, s.updated_by=?, s.updated_date=NOW() " +
                "WHERE s.is_active=1 AND " + IS_GRADUATING;
            try (PreparedStatement ps = conn.prepareStatement(sqlDeactivate)) {
                ps.setString(1, username);
                ps.executeUpdate();
            }

            // ── Step 5: Promote Classes I–VIII ───────────────────────────────
            // COALESCE seeds Phase 1 from the last phase the school actually completed:
            //   phase4 → phase3 → phase2 → phase1 → NULL (never had data)
            // This handles schools that did not finish all 4 phases.
            String sqlPromote =
                "UPDATE students s " +
                "JOIN " + TERMINAL_TMP + " t ON t.udise_no = s.udise_no " +
                "SET " +
                "  s.class          = " + CLASS_NEXT_CASE + ", " +
                "  s.phase1_marathi = COALESCE(s.phase4_marathi, s.phase3_marathi, s.phase2_marathi, s.phase1_marathi), " +
                "  s.phase1_math    = COALESCE(s.phase4_math,    s.phase3_math,    s.phase2_math,    s.phase1_math), " +
                "  s.phase1_english = COALESCE(s.phase4_english, s.phase3_english, s.phase2_english, s.phase1_english), " +
                "  s.phase1_date    = NULL, " +
                "  s.phase2_marathi=NULL, s.phase2_math=NULL, s.phase2_english=NULL, s.phase2_date=NULL, " +
                "  s.phase3_marathi=NULL, s.phase3_math=NULL, s.phase3_english=NULL, s.phase3_date=NULL, " +
                "  s.phase4_marathi=NULL, s.phase4_math=NULL, s.phase4_english=NULL, s.phase4_date=NULL, " +
                "  s.updated_by=?, s.updated_date=NOW() " +
                "WHERE s.is_active=1 AND " + IS_PROMOTING;
            int promotedCount;
            try (PreparedStatement ps = conn.prepareStatement(sqlPromote)) {
                ps.setString(1, username);
                promotedCount = ps.executeUpdate();
                System.out.println("PromoteClasses: promoted " + promotedCount + " students (I–VIII)");
            }

            // ── Step 6: Update log counts ─────────────────────────────────────
            // Record what this run actually did. The old query counted every active student in
            // classes II-IX, which is the size of the roster, not the number promoted.
            String sqlUpdateLog =
                "UPDATE class_promotion_log SET " +
                "  students_promoted  = ?, " +
                "  students_graduated = ? " +
                "WHERE promotion_id=?";
            try (PreparedStatement ps = conn.prepareStatement(sqlUpdateLog)) {
                ps.setInt(1, promotedCount);
                ps.setInt(2, graduatedCount);
                ps.setLong(3, promotionId);
                ps.executeUpdate();
            }

            conn.commit();
            System.out.println("PromoteClasses: committed. id=" + promotionId +
                               " promoted=" + promotedCount + " graduated=" + graduatedCount);

            JSONObject result = new JSONObject();
            result.put("success",           true);
            result.put("message",           "Class promotion completed successfully");
            result.put("promotionId",       promotionId);
            result.put("studentsPromoted",  promotedCount);
            result.put("studentsGraduated", graduatedCount);
            out.print(result.toString());

        } catch (Exception e) {
            System.err.println("PromoteClasses POST error: " + e.getMessage());
            if (conn != null) {
                try { conn.rollback(); System.out.println("PromoteClasses: rolled back"); }
                catch (SQLException ex) { System.err.println("Rollback failed: " + ex.getMessage()); }
            }
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(new JSONObject().put("success", false).put("message", e.getMessage()).toString());
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); }
                catch (SQLException e) { System.err.println("Conn close error: " + e.getMessage()); }
            }
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

    // isGraduatingClass() and nextClass() were removed: "graduating" is no longer a property of
    // the class label alone, it depends on the school. See PromotionClassRules.
}
