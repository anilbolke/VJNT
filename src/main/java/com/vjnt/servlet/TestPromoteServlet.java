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

@WebServlet("/test-promote")
public class TestPromoteServlet extends HttpServlet {

    // The graduating class is per school, not the old global ('IX','9'). See PromotionClassRules.
    // Here the school is fixed, so its terminal rank is resolved once as an int and bound as a
    // parameter — no snapshot table is needed as it is read before any write.

    private static final String CLASS_NEXT_CASE = PromotionClassRules.nextClassCase("class");

    /** class_after label; ? is the school's terminal rank. */
    private static final String CLASS_AFTER_CASE =
        PromotionClassRules.classAfterCase("class", "?");

    /** Sits at or above the school's terminal class; ? is the terminal rank. */
    private static final String IS_GRADUATING = PromotionClassRules.isGraduating("class", "?");

    /** Below the school's terminal class; ? is the terminal rank. */
    private static final String IS_PROMOTING = PromotionClassRules.isPromoting("class", "?");

    /**
     * Terminal class rank for one school: schools.max_class when set, else the highest class
     * that school currently has active students in.
     */
    private int terminalRankFor(Connection conn, String udise) throws SQLException {
        return PromotionClassRules.terminalRankFor(conn, udise);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET — preview for one school
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

        String udise = request.getParameter("udise");
        if (udise == null || udise.trim().isEmpty()) {
            out.print(new JSONObject().put("success", false).put("message", "UDISE number is required").toString());
            return;
        }
        udise = udise.trim();

        String sqlClass =
            "SELECT class, COUNT(*) AS cnt FROM students " +
            "WHERE is_active=1 AND udise_no=? " +
            "GROUP BY class ORDER BY " +
            "FIELD(class,'I','II','III','IV','V','VI','VII','VIII','IX','1','2','3','4','5','6','7','8','9')";

        String sqlSchool =
            "SELECT MAX(st.division) AS division, MAX(st.district) AS district, " +
            "       MAX(sc.school_name) AS school_name " +
            "FROM students st " +
            "LEFT JOIN schools sc ON sc.udise_no COLLATE utf8mb4_unicode_ci = st.udise_no " +
            "WHERE st.udise_no=? AND st.is_active=1";

        String sqlIncomplete =
            "SELECT COUNT(*) AS cnt FROM students " +
            "WHERE is_active=1 AND udise_no=? AND NOT (" + IS_GRADUATING + ") " +
            "AND (phase4_marathi IS NULL OR phase4_math IS NULL OR phase4_english IS NULL OR phase4_date IS NULL)";

        try (Connection conn = DatabaseConnection.getConnection()) {

            // School info
            String schoolName = null, division = null, district = null;
            try (PreparedStatement ps = conn.prepareStatement(sqlSchool)) {
                ps.setString(1, udise);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        schoolName = rs.getString("school_name");
                        division   = rs.getString("division");
                        district   = rs.getString("district");
                    }
                }
            }
            if (division == null) {
                out.print(new JSONObject().put("success", false)
                    .put("message", "No active students found for UDISE: " + udise).toString());
                return;
            }
            if (schoolName == null) schoolName = "UDISE: " + udise;

            // This school's terminal class — what actually decides who graduates
            int terminalRank = terminalRankFor(conn, udise);

            // Class breakdown
            JSONArray preview       = new JSONArray();
            int totalStudents       = 0;
            int totalGraduating     = 0;
            try (PreparedStatement ps = conn.prepareStatement(sqlClass)) {
                ps.setString(1, udise);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String classVal = rs.getString("class");
                        int    count    = rs.getInt("cnt");
                        int    r        = PromotionClassRules.rankOf(classVal);
                        boolean isGrad  = r > 0 && r >= terminalRank;
                        String  action  = isGrad
                            ? "→ GRADUATE"
                            : "→ " + PromotionClassRules.nextClass(classVal);
                        JSONObject row  = new JSONObject();
                        row.put("class",      classVal);
                        row.put("count",      count);
                        row.put("action",     action);
                        row.put("isTerminal", isGrad);
                        preview.put(row);
                        totalStudents += count;
                        if (isGrad) totalGraduating += count;
                    }
                }
            }

            // Incomplete count
            int incompleteStudents = 0;
            try (PreparedStatement ps = conn.prepareStatement(sqlIncomplete)) {
                ps.setString(1, udise);
                ps.setInt(2, terminalRank);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) incompleteStudents = rs.getInt("cnt");
                }
            }

            JSONObject result = new JSONObject();
            result.put("success",            true);
            result.put("udise",       udise);
            result.put("schoolName",  schoolName);
            result.put("division",    division);
            result.put("district",    district);
            result.put("preview",            preview);
            result.put("totalStudents",      totalStudents);
            result.put("totalGraduating",    totalGraduating);
            result.put("incompleteStudents", incompleteStudents);
            result.put("terminalRank",       terminalRank);
            result.put("terminalClass",      PromotionClassRules.roman(terminalRank));
            out.print(result.toString());

        } catch (SQLException e) {
            System.err.println("TestPromoteServlet GET error: " + e.getMessage());
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(new JSONObject().put("success", false).put("message", e.getMessage()).toString());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST — run promotion for one school
    // ─────────────────────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        if (!isDataAdmin(request)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print(new JSONObject().put("success", false).put("message", "Access denied").toString());
            return;
        }

        HttpSession session     = request.getSession(false);
        User   user             = (User) session.getAttribute("user");
        String username         = user.getUsername();
        String udise            = request.getParameter("udise");
        String academicYear     = request.getParameter("academicYear");
        String remarks          = request.getParameter("remarks");

        if (udise == null || udise.trim().isEmpty()) {
            out.print(new JSONObject().put("success", false).put("message", "UDISE number is required").toString());
            return;
        }
        if (academicYear == null || academicYear.trim().isEmpty()) {
            out.print(new JSONObject().put("success", false).put("message", "Academic year is required").toString());
            return;
        }

        udise       = udise.trim();
        academicYear = academicYear.trim();
        String testRemarks = "[TEST-SINGLE-SCHOOL udise=" + udise + "] " +
                             (remarks != null ? remarks.trim() : "");

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            // Step 0: resolve this school's terminal class BEFORE any write. Read afterwards it
            // would shift, because Step 4b deactivates exactly the top-class students the
            // derived fallback is computed from.
            int terminalRank = terminalRankFor(conn, udise);
            if (terminalRank == 0) throw new SQLException("No active students for UDISE " + udise);
            System.out.println("TestPromote: terminal class for " + udise + " = " +
                               PromotionClassRules.roman(terminalRank));

            // Step 1: Promotion log
            long promotionId;
            String sqlLog = "INSERT INTO class_promotion_log " +
                            "(academic_year, promoted_by, promotion_date, remarks) VALUES (?,?,NOW(),?)";
            try (PreparedStatement ps = conn.prepareStatement(sqlLog, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, academicYear);
                ps.setString(2, username);
                ps.setString(3, testRemarks);
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                if (!keys.next()) throw new SQLException("Failed to obtain promotion_id");
                promotionId = keys.getLong(1);
            }

            // Step 2: Archive this school's student phase data
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
                "FROM students WHERE is_active=1 AND udise_no=?";
            try (PreparedStatement ps = conn.prepareStatement(sqlArchive)) {
                ps.setLong(1, promotionId);
                ps.setInt(2, terminalRank);   // inside CLASS_AFTER_CASE
                ps.setString(3, udise);
                int rows = ps.executeUpdate();
                System.out.println("TestPromote: archived " + rows + " phase history rows for " + udise);
            }

            // Step 3a: Archive this school's approvals
            String sqlArchiveApprovals =
                "INSERT INTO phase_approvals_history " +
                "  (promotion_id,udise_no,phase_number,approval_status,approved_by,approval_date,remarks,archived_at) " +
                "SELECT ?,udise_no,phase_number,approval_status,approved_by,approved_date,approval_remarks,NOW() " +
                "FROM phase_approvals WHERE udise_no=?";
            try (PreparedStatement ps = conn.prepareStatement(sqlArchiveApprovals)) {
                ps.setLong(1, promotionId);
                ps.setString(2, udise);
                int rows = ps.executeUpdate();
                System.out.println("TestPromote: archived " + rows + " approval records for " + udise);
            }

            // Step 3b: Delete this school's approvals
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM phase_approvals WHERE udise_no=?")) {
                ps.setString(1, udise);
                ps.executeUpdate();
            }

            // Step 4a: Graduate this school's terminal-class students
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
                // graduated_from_class = class, so a terminal-VII school records 'VII', not '9'
                "FROM students WHERE " + IS_GRADUATING + " AND is_active=1 AND udise_no=?";
            int graduatedCount;
            try (PreparedStatement ps = conn.prepareStatement(sqlGraduate)) {
                ps.setLong(1, promotionId);
                ps.setString(2, academicYear);
                ps.setInt(3, terminalRank);
                ps.setString(4, udise);
                graduatedCount = ps.executeUpdate();
                System.out.println("TestPromote: graduated " + graduatedCount + " Class " +
                                   PromotionClassRules.roman(terminalRank) + " students for " + udise);
            }

            // Step 4b: Mark this school's terminal-class students inactive
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE students SET is_active=0, updated_by=?, updated_date=NOW() " +
                    "WHERE " + IS_GRADUATING + " AND is_active=1 AND udise_no=?")) {
                ps.setString(1, username);
                ps.setInt(2, terminalRank);
                ps.setString(3, udise);
                ps.executeUpdate();
            }

            // Step 5: Promote everyone below the terminal class (COALESCE seeding)
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
                "WHERE is_active=1 AND " + IS_PROMOTING + " AND udise_no=?";
            int promotedCount;
            try (PreparedStatement ps = conn.prepareStatement(sqlPromote)) {
                ps.setString(1, username);
                ps.setInt(2, terminalRank);
                ps.setString(3, udise);
                promotedCount = ps.executeUpdate();
                System.out.println("TestPromote: promoted " + promotedCount + " students for " + udise);
            }

            // Step 6: Update log counts
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE class_promotion_log SET " +
                    "  students_promoted  = ?, " +
                    "  students_graduated = ? " +
                    "WHERE promotion_id=?")) {
                ps.setInt(1, promotedCount);
                ps.setInt(2, graduatedCount);
                ps.setLong(3, promotionId);
                ps.executeUpdate();
            }

            conn.commit();
            System.out.println("TestPromote: committed. id=" + promotionId + " udise=" + udise);

            JSONObject result = new JSONObject();
            result.put("success",           true);
            result.put("promotionId",       promotionId);
            result.put("studentsPromoted",  promotedCount);
            result.put("studentsGraduated", graduatedCount);
            out.print(result.toString());

        } catch (Exception e) {
            System.err.println("TestPromoteServlet POST error: " + e.getMessage());
            if (conn != null) {
                try { conn.rollback(); }
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

    private boolean isDataAdmin(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return false;
        User user = (User) session.getAttribute("user");
        return user != null && User.UserType.DATA_ADMIN.equals(user.getUserType());
    }

    // isGraduatingClass() and nextClass() were removed: "graduating" depends on the school's
    // terminal class, not on the class label alone. See PromotionClassRules.
}
