package com.vjnt.servlet;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;
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
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Deactivate several students in one action, from select-student-to-edit.jsp.
 *
 * Previously the only way to deactivate was the full edit form, one student at a time.
 *
 * Deactivate only — there is deliberately no bulk re-activate. Reversing a mistake is done
 * per student through the edit form, which is why the batch is capped, audited, and the caller
 * is told exactly how many rows actually changed.
 *
 * SCHOOL_COORDINATOR only. select-student-to-edit.jsp is also reachable by
 * SUPER_DIVISION_OFFICER, so the role is checked here rather than assumed from page access.
 *
 * POST /bulk-deactivate-students
 *   studentIds = 12,34,56      (comma separated, or repeated parameter)
 *   reason     = optional free text
 */
@WebServlet("/bulk-deactivate-students")
public class BulkDeactivateStudentsServlet extends HttpServlet {

    /** Upper bound on one batch. A request larger than this is far more likely a mistake. */
    private static final int MAX_BATCH = 500;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("user");

        if (user == null || !User.UserType.SCHOOL_COORDINATOR.equals(user.getUserType())) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print(err("Access denied"));
            return;
        }

        // Taken from the session, never from the request: this is what stops a coordinator
        // deactivating another school's students by editing the ids in the POST body.
        String udiseNo = user.getUdiseNo();
        if (udiseNo == null || udiseNo.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print(err("No school is associated with this login"));
            return;
        }

        List<Integer> ids = parseIds(request);
        if (ids.isEmpty()) {
            out.print(err("No students selected"));
            return;
        }
        if (ids.size() > MAX_BATCH) {
            out.print(err("Too many students in one action (" + ids.size() + "). " +
                          "The limit is " + MAX_BATCH + " — narrow the filter and repeat."));
            return;
        }

        String reason = request.getParameter("reason");
        if (reason != null) {
            reason = reason.trim();
            if (reason.length() > 255) reason = reason.substring(0, 255);
            if (reason.isEmpty()) reason = null;
        }

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            String placeholders = placeholders(ids.size());

            // Resolve which of the requested ids this school may actually touch, BEFORE updating.
            // Ids belonging to another school, already inactive, or simply not present are
            // reported back as skipped rather than silently dropped.
            List<Integer> eligible = new ArrayList<>();
            String sqlEligible =
                "SELECT student_id FROM students " +
                "WHERE student_id IN (" + placeholders + ") AND udise_no = ? AND is_active = 1";
            try (PreparedStatement ps = conn.prepareStatement(sqlEligible)) {
                int p = 1;
                for (Integer id : ids) ps.setInt(p++, id);
                ps.setString(p, udiseNo);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) eligible.add(rs.getInt("student_id"));
                }
            }

            if (eligible.isEmpty()) {
                conn.rollback();
                JSONObject o = new JSONObject();
                o.put("success", true);
                o.put("deactivated", 0);
                o.put("requested", ids.size());
                o.put("skipped", ids.size());
                o.put("message", "Nothing to do — the selected students are already inactive " +
                                 "or do not belong to this school.");
                out.print(o.toString());
                return;
            }

            String eligiblePlaceholders = placeholders(eligible.size());
            int updated;
            String sqlUpdate =
                "UPDATE students SET is_active = 0, updated_by = ?, updated_date = NOW() " +
                "WHERE student_id IN (" + eligiblePlaceholders + ") AND udise_no = ? AND is_active = 1";
            try (PreparedStatement ps = conn.prepareStatement(sqlUpdate)) {
                int p = 1;
                ps.setString(p++, user.getUsername());
                for (Integer id : eligible) ps.setInt(p++, id);
                ps.setString(p, udiseNo);
                updated = ps.executeUpdate();
            }

            writeAudit(conn, eligible, udiseNo, user.getUsername(), reason);

            conn.commit();
            System.out.println("BulkDeactivate: udise=" + udiseNo + " by=" + user.getUsername() +
                               " requested=" + ids.size() + " deactivated=" + updated);

            JSONObject o = new JSONObject();
            o.put("success",     true);
            o.put("deactivated", updated);
            o.put("requested",   ids.size());
            o.put("skipped",     ids.size() - updated);
            out.print(o.toString());

        } catch (Exception e) {
            System.err.println("BulkDeactivate error: " + e.getMessage());
            if (conn != null) {
                try { conn.rollback(); }
                catch (SQLException ex) { System.err.println("Rollback failed: " + ex.getMessage()); }
            }
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(err(e.getMessage()));
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); }
                catch (SQLException e) { System.err.println("Conn close error: " + e.getMessage()); }
            }
        }
    }

    /**
     * Record who deactivated whom.
     *
     * A missing audit table must not cost the school its actual edit, so this logs and returns
     * instead of throwing — the deactivation is the user's intent, the audit row is our bookkeeping.
     */
    private void writeAudit(Connection conn, List<Integer> ids, String udiseNo,
                            String username, String reason) {
        String sql = "INSERT INTO student_status_audit " +
                     "(student_id, udise_no, action, source, reason, changed_by, changed_at) " +
                     "VALUES (?,?,'DEACTIVATE','BULK_SELECT_STUDENT',?,?,NOW())";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (Integer id : ids) {
                ps.setInt(1, id);
                ps.setString(2, udiseNo);
                ps.setString(3, reason);
                ps.setString(4, username);
                ps.addBatch();
            }
            ps.executeBatch();
        } catch (SQLException e) {
            System.err.println("BulkDeactivate: audit write failed (run " +
                               "ADD_STUDENT_STATUS_AUDIT_2026-08-06.sql): " + e.getMessage());
        }
    }

    /** Accepts both a repeated studentIds parameter and a single comma separated one. */
    private List<Integer> parseIds(HttpServletRequest request) {
        Set<Integer> unique = new LinkedHashSet<>();
        String[] values = request.getParameterValues("studentIds");
        if (values != null) {
            for (String value : values) {
                if (value == null) continue;
                for (String part : value.split(",")) {
                    part = part.trim();
                    if (part.isEmpty()) continue;
                    try {
                        unique.add(Integer.parseInt(part));
                    } catch (NumberFormatException ignored) {
                        // A non-numeric id is not actionable; skip rather than fail the batch.
                    }
                }
            }
        }
        return new ArrayList<>(unique);
    }

    private static String placeholders(int n) {
        StringBuilder sb = new StringBuilder(n * 2);
        for (int i = 0; i < n; i++) {
            if (i > 0) sb.append(',');
            sb.append('?');
        }
        return sb.toString();
    }

    private static String err(String msg) {
        return new JSONObject().put("success", false).put("message", msg).toString();
    }
}
