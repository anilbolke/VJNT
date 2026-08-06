package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

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
 * Division Phase Status Servlet
 *
 * Returns every school in the division with the current stage of all 4 phases,
 * so the division user can see which schools have not filled data and trigger
 * a WhatsApp hm_approval_alert to them.
 *
 * Per-phase status values:
 *   APPROVED    - phase approved by Head Master
 *   PENDING     - submitted, waiting for HM approval
 *   IN_PROGRESS - students have data but not submitted for approval
 *   NOT_STARTED - no data filled for this phase
 *
 * GET parameters:
 *   district (optional) - restrict to one district of the division
 */
@WebServlet("/division-phase-status")
public class DivisionPhaseStatusServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        if (session == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"error\": \"Session expired\"}");
            return;
        }

        User user = (User) session.getAttribute("user");
        if (user == null || (!user.getUserType().equals(User.UserType.DIVISION)
                && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"error\": \"Unauthorized access\"}");
            return;
        }

        String divisionName = user.getUserType() == User.UserType.SUPER_DIVISION_OFFICER
                ? null : user.getDivisionName();
        String districtName = request.getParameter("district");
        if (districtName != null && districtName.trim().isEmpty()) {
            districtName = null;
        }

        JSONObject result = getPhaseStatus(divisionName, districtName);
        out.print(result.toString());
        out.flush();
    }

    private JSONObject getPhaseStatus(String divisionName, String districtName) {
        JSONObject result = new JSONObject();

        StringBuilder sql = new StringBuilder();
        sql.append("SELECT s.udise_no, s.school_name, s.district_name, ");
        sql.append("COALESCE(stu.total_students, 0) AS total_students, ");
        sql.append("COALESCE(stu.p1_done, 0) AS p1_done, ");
        sql.append("COALESCE(stu.p2_done, 0) AS p2_done, ");
        sql.append("COALESCE(stu.p3_done, 0) AS p3_done, ");
        sql.append("COALESCE(stu.p4_done, 0) AS p4_done, ");
        sql.append("MAX(CASE WHEN pa.phase_number = 1 THEN pa.approval_status END) AS p1_approval, ");
        sql.append("MAX(CASE WHEN pa.phase_number = 2 THEN pa.approval_status END) AS p2_approval, ");
        sql.append("MAX(CASE WHEN pa.phase_number = 3 THEN pa.approval_status END) AS p3_approval, ");
        sql.append("MAX(CASE WHEN pa.phase_number = 4 THEN pa.approval_status END) AS p4_approval, ");
        sql.append("COALESCE(ct.alert_contacts, 0) AS alert_contacts ");
        sql.append("FROM schools s ");
        sql.append("LEFT JOIN (SELECT udise_no, COUNT(*) AS total_students, ");
        sql.append("COUNT(CASE WHEN phase1_date IS NOT NULL THEN 1 END) AS p1_done, ");
        sql.append("COUNT(CASE WHEN phase2_date IS NOT NULL THEN 1 END) AS p2_done, ");
        sql.append("COUNT(CASE WHEN phase3_date IS NOT NULL THEN 1 END) AS p3_done, ");
        sql.append("COUNT(CASE WHEN phase4_date IS NOT NULL THEN 1 END) AS p4_done ");
        // is_active = 1 keeps last year's graduates out of both the roster size and the phase
        // completion counts. Promotion sets is_active = 0 on the graduating class but never
        // clears their phase columns, so their phase1_date..phase4_date stay populated and the
        // division dashboard reported phases as already done for the new academic year.
        // Filtering inside this derived table (not outside it) preserves the LEFT JOIN, so
        // schools with no active students still appear with zero counts.
        sql.append("FROM students WHERE is_active = 1 GROUP BY udise_no) stu ");
        sql.append("ON s.udise_no COLLATE utf8mb4_unicode_ci = stu.udise_no COLLATE utf8mb4_unicode_ci ");
        sql.append("LEFT JOIN phase_approvals pa ");
        sql.append("ON s.udise_no COLLATE utf8mb4_unicode_ci = pa.udise_no COLLATE utf8mb4_unicode_ci ");
        sql.append("LEFT JOIN (SELECT udise_no, COUNT(*) AS alert_contacts FROM school_contacts ");
        sql.append("WHERE contact_type IN ('Head Master', 'School Coordinator') ");
        sql.append("AND (COALESCE(whatsapp_number, '') <> '' OR COALESCE(mobile, '') <> '') ");
        sql.append("GROUP BY udise_no) ct ");
        sql.append("ON s.udise_no COLLATE utf8mb4_unicode_ci = ct.udise_no COLLATE utf8mb4_unicode_ci ");
        sql.append("WHERE 1=1 ");
        if (divisionName != null) {
            sql.append("AND s.district_name COLLATE utf8mb4_unicode_ci IN ");
            sql.append("(SELECT DISTINCT district COLLATE utf8mb4_unicode_ci FROM students WHERE division = ?) ");
        }
        if (districtName != null) {
            sql.append("AND s.district_name COLLATE utf8mb4_unicode_ci = ? COLLATE utf8mb4_unicode_ci ");
        }
        sql.append("GROUP BY s.udise_no, s.school_name, s.district_name, ");
        sql.append("stu.total_students, stu.p1_done, stu.p2_done, stu.p3_done, stu.p4_done, ct.alert_contacts ");
        sql.append("ORDER BY s.district_name, s.school_name");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {

            int paramIndex = 1;
            if (divisionName != null) {
                ps.setString(paramIndex++, divisionName);
            }
            if (districtName != null) {
                ps.setString(paramIndex++, districtName);
            }

            JSONArray schools = new JSONArray();
            int totalSchools = 0;
            int schoolsAllApproved = 0;
            int schoolsNeedingAlert = 0;

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    JSONObject school = new JSONObject();
                    school.put("udiseNo", rs.getString("udise_no"));
                    school.put("schoolName", rs.getString("school_name"));
                    school.put("districtName", rs.getString("district_name"));
                    int totalStudents = rs.getInt("total_students");
                    school.put("totalStudents", totalStudents);
                    school.put("hasAlertContact", rs.getInt("alert_contacts") > 0);

                    JSONArray phases = new JSONArray();
                    int approvedPhases = 0;
                    String currentStage = null;
                    for (int p = 1; p <= 4; p++) {
                        String approval = rs.getString("p" + p + "_approval");
                        int done = rs.getInt("p" + p + "_done");

                        String status;
                        if ("APPROVED".equals(approval)) {
                            status = "APPROVED";
                            approvedPhases++;
                        } else if ("PENDING".equals(approval)) {
                            status = "PENDING";
                        } else if (done > 0) {
                            status = "IN_PROGRESS";
                        } else {
                            status = "NOT_STARTED";
                        }

                        JSONObject phase = new JSONObject();
                        phase.put("phase", p);
                        phase.put("status", status);
                        phase.put("completedStudents", done);
                        phase.put("percentage", totalStudents > 0 ? (done * 100 / totalStudents) : 0);
                        phases.put(phase);

                        // Current stage = first phase that is not yet approved
                        if (currentStage == null && !"APPROVED".equals(status)) {
                            currentStage = "Phase " + p + " - " + status;
                        }
                    }
                    if (currentStage == null) {
                        currentStage = "ALL_APPROVED";
                    }

                    school.put("phases", phases);
                    school.put("approvedPhases", approvedPhases);
                    school.put("currentStage", currentStage);

                    boolean allApproved = "ALL_APPROVED".equals(currentStage);
                    // Needs alert = data not fully filled/approved yet
                    boolean needsAlert = !allApproved;
                    school.put("needsAlert", needsAlert);

                    totalSchools++;
                    if (allApproved) schoolsAllApproved++;
                    if (needsAlert) schoolsNeedingAlert++;

                    schools.put(school);
                }
            }

            result.put("schools", schools);
            result.put("totalSchools", totalSchools);
            result.put("schoolsAllApproved", schoolsAllApproved);
            result.put("schoolsNeedingAlert", schoolsNeedingAlert);

        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }

        return result;
    }
}
