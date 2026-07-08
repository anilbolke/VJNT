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

@WebServlet("/promote-classes")
public class PromoteClassesServlet extends HttpServlet {

    // Classes are stored as Roman numerals (I, II, … IX).
    // These CASE expressions handle both Roman and Arabic numerals defensively.

    /** SQL CASE: maps current class → next class (for classes I–VIII / 1–8) */
    private static final String CLASS_NEXT_CASE =
        "CASE class " +
        "WHEN 'I'    THEN 'II'   WHEN 'II'   THEN 'III'  WHEN 'III'  THEN 'IV' " +
        "WHEN 'IV'   THEN 'V'    WHEN 'V'    THEN 'VI'   WHEN 'VI'   THEN 'VII' " +
        "WHEN 'VII'  THEN 'VIII' WHEN 'VIII' THEN 'IX' " +
        "WHEN '1' THEN '2' WHEN '2' THEN '3' WHEN '3' THEN '4' WHEN '4' THEN '5' " +
        "WHEN '5' THEN '6' WHEN '6' THEN '7' WHEN '7' THEN '8' WHEN '8' THEN '9' " +
        "ELSE class END";

    /** SQL CASE: maps current class → class_after label (IX/9 → 'GRADUATED') */
    private static final String CLASS_AFTER_CASE =
        "CASE class " +
        "WHEN 'I'    THEN 'II'        WHEN 'II'   THEN 'III'       WHEN 'III'  THEN 'IV' " +
        "WHEN 'IV'   THEN 'V'         WHEN 'V'    THEN 'VI'        WHEN 'VI'   THEN 'VII' " +
        "WHEN 'VII'  THEN 'VIII'      WHEN 'VIII' THEN 'IX'        WHEN 'IX'   THEN 'GRADUATED' " +
        "WHEN '1' THEN '2' WHEN '2' THEN '3' WHEN '3' THEN '4' WHEN '4' THEN '5' " +
        "WHEN '5' THEN '6' WHEN '6' THEN '7' WHEN '7' THEN '8' WHEN '8' THEN '9' " +
        "WHEN '9' THEN 'GRADUATED' " +
        "ELSE class END";

    /** IN list for classes that should be promoted (not the final class) */
    private static final String PROMOTE_CLASS_IN =
        "('I','II','III','IV','V','VI','VII','VIII','1','2','3','4','5','6','7','8')";

    /** IN list for the graduating (final) class */
    private static final String GRAD_CLASS_IN = "('IX','9')";

    /** IN list for promoted result classes (used for count query after promotion) */
    private static final String PROMOTED_RESULT_IN =
        "('II','III','IV','V','VI','VII','VIII','IX','2','3','4','5','6','7','8','9')";

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

        String sql = "SELECT class, COUNT(*) AS cnt FROM students " +
                     "WHERE is_active = 1 GROUP BY class ORDER BY " +
                     "FIELD(class,'I','II','III','IV','V','VI','VII','VIII','IX'," +
                           "'1','2','3','4','5','6','7','8','9')";

        // Count students where Phase 4 is not yet complete (incomplete schools)
        String sqlIncomplete =
            "SELECT COUNT(*) AS cnt, " +
            "       COUNT(DISTINCT udise_no) AS school_cnt " +
            "FROM students " +
            "WHERE is_active=1 " +
            "AND class NOT IN ('IX','9') " +
            "AND (phase4_marathi IS NULL OR phase4_math IS NULL OR phase4_english IS NULL OR phase4_date IS NULL)";

        try (Connection conn = DatabaseConnection.getConnection()) {

            // Class breakdown
            JSONArray preview        = new JSONArray();
            int       totalStudents  = 0;
            int       totalGraduating = 0;

            try (PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String classVal = rs.getString("class");
                    int    count    = rs.getInt("cnt");
                    boolean isGrad  = isGraduatingClass(classVal);
                    String  action  = isGrad ? "→ GRADUATE" : "→ " + nextClass(classVal);

                    JSONObject row = new JSONObject();
                    row.put("class",  classVal);
                    row.put("count",  count);
                    row.put("action", action);
                    preview.put(row);

                    totalStudents += count;
                    if (isGrad) totalGraduating += count;
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
                "SELECT ?,student_id,student_name,student_pen,udise_no,division,district," +
                "   class, " + CLASS_AFTER_CASE + ", " +
                "   phase1_marathi,phase1_math,phase1_english,phase1_date," +
                "   phase2_marathi,phase2_math,phase2_english,phase2_date," +
                "   phase3_marathi,phase3_math,phase3_english,phase3_date," +
                "   phase4_marathi,phase4_math,phase4_english,phase4_date,NOW() " +
                "FROM students WHERE is_active=1";
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
                "SELECT ?,student_id,student_name,student_pen,gender,udise_no," +
                "   division,district,section,class,?," +
                "   phase4_marathi,phase4_math,phase4_english,fln_completed," +
                "   phase1_marathi,phase1_math,phase1_english," +
                "   phase2_marathi,phase2_math,phase2_english," +
                "   phase3_marathi,phase3_math,phase3_english," +
                "   phase4_marathi,phase4_math,phase4_english,NOW() " +
                "FROM students WHERE class IN " + GRAD_CLASS_IN + " AND is_active=1";
            int graduatedCount;
            try (PreparedStatement ps = conn.prepareStatement(sqlGraduate)) {
                ps.setLong(1, promotionId);
                ps.setString(2, academicYear.trim());
                graduatedCount = ps.executeUpdate();
                System.out.println("PromoteClasses: graduated " + graduatedCount + " class-IX students");
            }

            // ── Step 4b: Mark Class IX students inactive ──────────────────────
            String sqlDeactivate =
                "UPDATE students SET is_active=0, updated_by=?, updated_date=NOW() " +
                "WHERE class IN " + GRAD_CLASS_IN + " AND is_active=1";
            try (PreparedStatement ps = conn.prepareStatement(sqlDeactivate)) {
                ps.setString(1, username);
                ps.executeUpdate();
            }

            // ── Step 5: Promote Classes I–VIII ───────────────────────────────
            // COALESCE seeds Phase 1 from the last phase the school actually completed:
            //   phase4 → phase3 → phase2 → phase1 → NULL (never had data)
            // This handles schools that did not finish all 4 phases.
            String sqlPromote =
                "UPDATE students SET " +
                "  class          = " + CLASS_NEXT_CASE + ", " +
                "  phase1_marathi = COALESCE(phase4_marathi, phase3_marathi, phase2_marathi, phase1_marathi), " +
                "  phase1_math    = COALESCE(phase4_math,    phase3_math,    phase2_math,    phase1_math), " +
                "  phase1_english = COALESCE(phase4_english, phase3_english, phase2_english, phase1_english), " +
                "  phase1_date    = NULL, " +
                "  phase2_marathi=NULL, phase2_math=NULL, phase2_english=NULL, phase2_date=NULL, " +
                "  phase3_marathi=NULL, phase3_math=NULL, phase3_english=NULL, phase3_date=NULL, " +
                "  phase4_marathi=NULL, phase4_math=NULL, phase4_english=NULL, phase4_date=NULL, " +
                "  updated_by=?, updated_date=NOW() " +
                "WHERE is_active=1 AND class IN " + PROMOTE_CLASS_IN;
            int promotedCount;
            try (PreparedStatement ps = conn.prepareStatement(sqlPromote)) {
                ps.setString(1, username);
                promotedCount = ps.executeUpdate();
                System.out.println("PromoteClasses: promoted " + promotedCount + " students (I–VIII)");
            }

            // ── Step 6: Update log counts ─────────────────────────────────────
            String sqlUpdateLog =
                "UPDATE class_promotion_log SET " +
                "  students_promoted  = (SELECT COUNT(*) FROM students " +
                "                        WHERE is_active=1 AND class IN " + PROMOTED_RESULT_IN + "), " +
                "  students_graduated = (SELECT COUNT(*) FROM graduated_students WHERE promotion_id=?) " +
                "WHERE promotion_id=?";
            try (PreparedStatement ps = conn.prepareStatement(sqlUpdateLog)) {
                ps.setLong(1, promotionId);
                ps.setLong(2, promotionId);
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

    private boolean isGraduatingClass(String cls) {
        return cls != null && (cls.trim().equals("IX") || cls.trim().equals("9"));
    }

    private String nextClass(String cls) {
        if (cls == null) return "?";
        switch (cls.trim()) {
            case "I":    return "II";
            case "II":   return "III";
            case "III":  return "IV";
            case "IV":   return "V";
            case "V":    return "VI";
            case "VI":   return "VII";
            case "VII":  return "VIII";
            case "VIII": return "IX";
            case "1":    return "2";
            case "2":    return "3";
            case "3":    return "4";
            case "4":    return "5";
            case "5":    return "6";
            case "6":    return "7";
            case "7":    return "8";
            case "8":    return "9";
            default:     return cls;
        }
    }
}
