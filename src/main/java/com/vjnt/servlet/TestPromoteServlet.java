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

@WebServlet("/test-promote")
public class TestPromoteServlet extends HttpServlet {

    private static final String CLASS_NEXT_CASE =
        "CASE class " +
        "WHEN 'I'    THEN 'II'   WHEN 'II'   THEN 'III'  WHEN 'III'  THEN 'IV' " +
        "WHEN 'IV'   THEN 'V'    WHEN 'V'    THEN 'VI'   WHEN 'VI'   THEN 'VII' " +
        "WHEN 'VII'  THEN 'VIII' WHEN 'VIII' THEN 'IX' " +
        "WHEN '1' THEN '2' WHEN '2' THEN '3' WHEN '3' THEN '4' WHEN '4' THEN '5' " +
        "WHEN '5' THEN '6' WHEN '6' THEN '7' WHEN '7' THEN '8' WHEN '8' THEN '9' " +
        "ELSE class END";

    private static final String CLASS_AFTER_CASE =
        "CASE class " +
        "WHEN 'I'    THEN 'II'        WHEN 'II'   THEN 'III'       WHEN 'III'  THEN 'IV' " +
        "WHEN 'IV'   THEN 'V'         WHEN 'V'    THEN 'VI'        WHEN 'VI'   THEN 'VII' " +
        "WHEN 'VII'  THEN 'VIII'      WHEN 'VIII' THEN 'IX'        WHEN 'IX'   THEN 'GRADUATED' " +
        "WHEN '1' THEN '2' WHEN '2' THEN '3' WHEN '3' THEN '4' WHEN '4' THEN '5' " +
        "WHEN '5' THEN '6' WHEN '6' THEN '7' WHEN '7' THEN '8' WHEN '8' THEN '9' " +
        "WHEN '9' THEN 'GRADUATED' " +
        "ELSE class END";

    private static final String PROMOTE_CLASS_IN =
        "('I','II','III','IV','V','VI','VII','VIII','1','2','3','4','5','6','7','8')";

    private static final String GRAD_CLASS_IN = "('IX','9')";

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
            "WHERE is_active=1 AND udise_no=? AND class NOT IN ('IX','9') " +
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
                        boolean isGrad  = isGraduatingClass(classVal);
                        String  action  = isGrad ? "→ GRADUATE" : "→ " + nextClass(classVal);
                        JSONObject row  = new JSONObject();
                        row.put("class",  classVal);
                        row.put("count",  count);
                        row.put("action", action);
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
                ps.setString(2, udise);
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

            // Step 4a: Graduate Class IX students from this school
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
                "FROM students WHERE class IN " + GRAD_CLASS_IN + " AND is_active=1 AND udise_no=?";
            int graduatedCount;
            try (PreparedStatement ps = conn.prepareStatement(sqlGraduate)) {
                ps.setLong(1, promotionId);
                ps.setString(2, academicYear);
                ps.setString(3, udise);
                graduatedCount = ps.executeUpdate();
                System.out.println("TestPromote: graduated " + graduatedCount + " Class IX students for " + udise);
            }

            // Step 4b: Mark Class IX inactive for this school
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE students SET is_active=0, updated_by=?, updated_date=NOW() " +
                    "WHERE class IN " + GRAD_CLASS_IN + " AND is_active=1 AND udise_no=?")) {
                ps.setString(1, username);
                ps.setString(2, udise);
                ps.executeUpdate();
            }

            // Step 5: Promote Classes I–VIII for this school (COALESCE seeding)
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
                "WHERE is_active=1 AND class IN " + PROMOTE_CLASS_IN + " AND udise_no=?";
            int promotedCount;
            try (PreparedStatement ps = conn.prepareStatement(sqlPromote)) {
                ps.setString(1, username);
                ps.setString(2, udise);
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
