package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.json.JSONArray;
import org.json.JSONObject;

import com.vjnt.model.SchoolContact;
import com.vjnt.model.User;
import com.vjnt.util.AlertCriterion;
import com.vjnt.util.CriteriaAlertMessages;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.util.PhaseBucketSql;
import com.vjnt.util.PhaseRosterSql;
import com.vjnt.util.SchoolAlertSender;
import com.vjnt.util.WhatsAppConfig;
import com.vjnt.util.WhatsAppService;
import com.vjnt.util.WhatsAppService.WhatsAppResponse;

/**
 * Criteria Alerts console for the Division login.
 *
 * Lets the division chase schools by follow-up bucket rather than one at a time: pick a phase, see
 * how many schools in each district fall into each of the five {@link AlertCriterion} buckets, open
 * a bucket, tick the schools to chase, and send the gatee_com_alert1 template to each one's Head
 * Master and School Coordinator.
 *
 * Progress is measured on the phase ROSTER (see {@link PhaseRosterSql}) — the same students
 * manage-students lists and the same percentage the school's own चरण अहवाल card shows, so a school
 * chased for "below 25%" sees 25% too.
 *
 *   GET  ?phase=N                                → per-district counts for all five buckets
 *   GET  ?phase=N&district=X&criterion=KEY       → the schools in one bucket, with their contacts
 *   POST  phase=N&criterion=KEY&udises=a,b,c     → send to those schools' HM + School Coordinator
 *
 * Division users are confined to districts in their own division; a super-division officer is not.
 */
@WebServlet("/division-criteria-alert")
public class DivisionCriteriaAlertServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** Upper bound on one send, so a crafted POST cannot fan out without limit. */
    private static final int MAX_SCHOOLS_PER_SEND = 300;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        PrintWriter out = beginJson(response);
        User user = authorize(request, response, out);
        if (user == null) return;

        int phase;
        try {
            phase = PhaseRosterSql.validatePhase(parseInt(request.getParameter("phase"), 1));
        } catch (IllegalArgumentException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print(new JSONObject().put("error", "Invalid phase").toString());
            return;
        }

        String divisionName = divisionOf(user);
        String district = trimToNull(request.getParameter("district"));
        AlertCriterion criterion = AlertCriterion.from(request.getParameter("criterion"));

        JSONObject result = (district != null && criterion != null)
                ? getSchoolsInBucket(divisionName, district, criterion, phase)
                : getDistrictSummary(divisionName, phase);

        out.print(result.toString());
        out.flush();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        PrintWriter out = beginJson(response);
        User user = authorize(request, response, out);
        if (user == null) return;

        int phase;
        try {
            phase = PhaseRosterSql.validatePhase(parseInt(request.getParameter("phase"), 0));
        } catch (IllegalArgumentException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print(new JSONObject().put("error", "Invalid phase").toString());
            return;
        }

        AlertCriterion criterion = AlertCriterion.from(request.getParameter("criterion"));
        if (criterion == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print(new JSONObject().put("error", "Unknown criterion").toString());
            return;
        }

        Collection<String> udiseNos = parseUdises(request.getParameter("udises"));
        if (udiseNos.isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print(new JSONObject().put("error", "No schools selected").toString());
            return;
        }
        if (udiseNos.size() > MAX_SCHOOLS_PER_SEND) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print(new JSONObject()
                    .put("error", "Too many schools in one send (max " + MAX_SCHOOLS_PER_SEND + ")")
                    .toString());
            return;
        }

        JSONObject result = sendAlerts(divisionOf(user), user.getUsername(), criterion, phase, udiseNos);
        out.print(result.toString());
        out.flush();
    }

    // ------------------------------------------------------------------
    // Reads
    // ------------------------------------------------------------------

    /** One row per district: how many of its schools sit in each bucket. */
    private JSONObject getDistrictSummary(String divisionName, int phase) {
        JSONObject result = baseResult(phase);

        StringBuilder sql = new StringBuilder("SELECT district_name, COUNT(*) AS total_schools");
        for (AlertCriterion c : AlertCriterion.values()) {
            sql.append(", SUM(CASE WHEN ").append(bucketCondition(c))
               .append(" THEN 1 ELSE 0 END) AS ").append(c.name().toLowerCase());
        }
        sql.append(" FROM (").append(schoolPhaseSubquery(phase, divisionName != null, false))
           .append(") sch GROUP BY district_name ORDER BY district_name");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {

            if (divisionName != null) {
                ps.setString(1, divisionName);
            }

            JSONArray districts = new JSONArray();
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    JSONObject d = new JSONObject();
                    d.put("districtName", rs.getString("district_name"));
                    d.put("totalSchools", rs.getInt("total_schools"));
                    JSONObject counts = new JSONObject();
                    for (AlertCriterion c : AlertCriterion.values()) {
                        counts.put(c.name(), rs.getInt(c.name().toLowerCase()));
                    }
                    d.put("counts", counts);
                    districts.put(d);
                }
            }
            result.put("districts", districts);

        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        return result;
    }

    /** The schools in one bucket, with the contacts that would actually be messaged. */
    private JSONObject getSchoolsInBucket(String divisionName, String district,
                                          AlertCriterion criterion, int phase) {
        JSONObject result = baseResult(phase);
        result.put("criterion", criterion.name());
        result.put("heading", criterion.getHeading());
        result.put("districtName", district);

        try (Connection conn = DatabaseConnection.getConnection()) {

            if (!SchoolAlertSender.districtInDivision(conn, divisionName, district)) {
                result.put("error", "District does not belong to this division");
                return result;
            }

            List<JSONObject> schools = loadBucket(conn, divisionName, district, criterion, phase);

            List<String> udiseNos = new ArrayList<>();
            for (JSONObject s : schools) {
                udiseNos.add(s.getString("udiseNo"));
            }

            Map<String, JSONArray> contactsByUdise = contactsByUdise(conn, udiseNos);
            Map<String, Timestamp> lastAlerted = lastAlertedByUdise(conn, udiseNos, criterion, phase);

            JSONArray array = new JSONArray();
            for (JSONObject s : schools) {
                String udise = s.getString("udiseNo");
                JSONArray contacts = contactsByUdise.get(udise);
                if (contacts == null) contacts = new JSONArray();

                int reachable = 0;
                for (int i = 0; i < contacts.length(); i++) {
                    if (contacts.getJSONObject(i).getBoolean("hasNumber")) reachable++;
                }

                s.put("contacts", contacts);
                s.put("messageCount", reachable);
                Timestamp ts = lastAlerted.get(udise);
                s.put("lastAlertedAt", ts == null ? JSONObject.NULL : ts.toString());
                array.put(s);
            }
            result.put("schools", array);

        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        return result;
    }

    /**
     * Schools in one district that satisfy the criterion. Shared by the preview list and by the
     * POST re-validation, so what is sent can never drift from what was shown.
     */
    private List<JSONObject> loadBucket(Connection conn, String divisionName, String district,
                                        AlertCriterion criterion, int phase) throws SQLException {
        List<JSONObject> schools = new ArrayList<>();

        String sql = "SELECT udise_no, school_name, district_name, p_total, p_done, approval_status"
                   + " FROM (" + schoolPhaseSubquery(phase, divisionName != null, district != null) + ") sch"
                   + " WHERE " + bucketCondition(criterion)
                   + " ORDER BY school_name";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            int idx = 1;
            if (divisionName != null) ps.setString(idx++, divisionName);
            if (district != null) ps.setString(idx, district);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int total = rs.getInt("p_total");
                    int done = rs.getInt("p_done");
                    JSONObject s = new JSONObject();
                    s.put("udiseNo", rs.getString("udise_no"));
                    s.put("schoolName", nullToEmpty(rs.getString("school_name")));
                    s.put("districtName", nullToEmpty(rs.getString("district_name")));
                    s.put("total", total);
                    s.put("done", done);
                    s.put("percentage", total > 0 ? (int) Math.round(done * 100.0 / total) : 0);
                    String approval = rs.getString("approval_status");
                    s.put("approvalStatus", approval == null ? JSONObject.NULL : approval);
                    schools.add(s);
                }
            }
        }
        return schools;
    }

    /** @see PhaseBucketSql#schoolPhaseSubquery — shared with the coordinator alerts console. */
    private String schoolPhaseSubquery(int phase, boolean filterDivision, boolean filterDistrict) {
        return PhaseBucketSql.schoolPhaseSubquery(phase, filterDivision, filterDistrict);
    }

    /** @see PhaseBucketSql#bucketCondition */
    private String bucketCondition(AlertCriterion criterion) {
        return PhaseBucketSql.bucketCondition(criterion);
    }

    private Map<String, JSONArray> contactsByUdise(Connection conn, List<String> udiseNos)
            throws SQLException {
        Map<String, JSONArray> byUdise = new HashMap<>();
        for (SchoolContact c : SchoolAlertSender.loadAlertContacts(conn, udiseNos)) {
            String number = SchoolAlertSender.resolveNumber(c);
            JSONObject j = new JSONObject();
            j.put("contactId", c.getContactId());
            j.put("contactType", nullToEmpty(c.getContactType()));
            j.put("fullName", nullToEmpty(c.getFullName()));
            j.put("number", number == null ? "" : number);
            j.put("hasNumber", number != null);
            byUdise.computeIfAbsent(c.getUdiseNo(), k -> new JSONArray()).put(j);
        }
        return byUdise;
    }

    /** Latest send per school for this bucket and phase, so the preview can warn about re-sends. */
    private Map<String, Timestamp> lastAlertedByUdise(Connection conn, List<String> udiseNos,
                                                      AlertCriterion criterion, int phase)
            throws SQLException {
        Map<String, Timestamp> result = new HashMap<>();
        if (udiseNos.isEmpty()) return result;

        StringBuilder in = new StringBuilder();
        for (int i = 0; i < udiseNos.size(); i++) {
            in.append(i == 0 ? "?" : ",?");
        }
        String sql = "SELECT udise_no, MAX(sent_at) AS last_sent FROM whatsapp_alert_log "
                   + "WHERE alert_type = ? AND phase_number = ? AND success = 1 "
                   + "AND udise_no IN (" + in + ") GROUP BY udise_no";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, criterion.name());
            ps.setInt(2, phase);
            int idx = 3;
            for (String udise : udiseNos) {
                ps.setString(idx++, udise);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.put(rs.getString("udise_no"), rs.getTimestamp("last_sent"));
                }
            }
        } catch (SQLException e) {
            // The log table is a convenience, not a prerequisite. If it has not been created yet the
            // console must still work, so a missing table costs the "last alerted" column and nothing
            // more.
            System.err.println("[CriteriaAlert] last-alerted lookup skipped: " + e.getMessage());
        }
        return result;
    }

    // ------------------------------------------------------------------
    // Send
    // ------------------------------------------------------------------

    private JSONObject sendAlerts(String divisionName, String sentBy, AlertCriterion criterion,
                                  int phase, Collection<String> requestedUdises) {
        JSONObject result = baseResult(phase);
        result.put("criterion", criterion.name());

        JSONArray results = new JSONArray();
        int sent = 0;
        int failed = 0;
        int skipped = 0;

        try (Connection conn = DatabaseConnection.getConnection()) {

            // Re-derive the bucket server-side instead of trusting the posted list: a preview left
            // open while a school finished its work must not still alert that school.
            Map<String, JSONObject> eligible = new LinkedHashMap<>();
            for (String district : districtsOf(conn, requestedUdises)) {
                if (!SchoolAlertSender.districtInDivision(conn, divisionName, district)) {
                    continue;
                }
                for (JSONObject s : loadBucket(conn, divisionName, district, criterion, phase)) {
                    eligible.put(s.getString("udiseNo"), s);
                }
            }

            List<String> toSend = new ArrayList<>();
            for (String udise : requestedUdises) {
                if (eligible.containsKey(udise)) {
                    toSend.add(udise);
                } else {
                    results.put(new JSONObject()
                            .put("udiseNo", udise)
                            .put("success", false)
                            .put("error", "School is no longer in this list"));
                    skipped++;
                }
            }

            List<SchoolContact> contacts = SchoolAlertSender.loadAlertContacts(conn, toSend);

            for (SchoolContact contact : contacts) {
                JSONObject school = eligible.get(contact.getUdiseNo());
                if (school == null) continue;

                JSONObject r = new JSONObject();
                r.put("udiseNo", contact.getUdiseNo());
                r.put("contactId", contact.getContactId());
                r.put("contactType", nullToEmpty(contact.getContactType()));
                r.put("fullName", nullToEmpty(contact.getFullName()));

                String number = SchoolAlertSender.resolveNumber(contact);
                if (number == null) {
                    r.put("success", false);
                    r.put("error", "No WhatsApp/mobile number available");
                    results.put(r);
                    skipped++;
                    continue;
                }

                // schools.school_name is blank for a few UDISEs; school_contacts carries a copy, so
                // fall back to it rather than sending a message that names no school.
                String schoolName = school.optString("schoolName", "");
                if (schoolName.trim().isEmpty()) {
                    schoolName = nullToEmpty(contact.getSchoolName());
                }

                String[] params = CriteriaAlertMessages.build(
                        criterion, phase, contact.getUdiseNo(), schoolName,
                        school.getInt("done"), school.getInt("total"));

                String destination = SchoolAlertSender.destinationFor(number);
                WhatsAppResponse waResponse = SchoolAlertSender.sendTemplate(
                        number, WhatsAppConfig.TPL_CRITERIA_ALERT,
                        WhatsAppConfig.LANG_CRITERIA_ALERT, params);

                r.put("number", WhatsAppService.normalizeNumber(destination));
                r.put("success", waResponse.isSuccess());
                if (waResponse.isSuccess()) {
                    sent++;
                    String messageId = waResponse.getMessageId();
                    r.put("messageId", messageId == null ? JSONObject.NULL : messageId);
                } else {
                    failed++;
                    r.put("error", waResponse.getBody());
                }
                results.put(r);

                logSend(conn, criterion, phase, divisionName, contact, destination,
                        waResponse, sentBy);
            }

        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }

        result.put("success", failed == 0 && sent > 0);
        result.put("sent", sent);
        result.put("failed", failed);
        result.put("skipped", skipped);
        result.put("results", results);
        return result;
    }

    /** Districts of the posted schools, so ownership is checked before anything is sent. */
    private Collection<String> districtsOf(Connection conn, Collection<String> udiseNos)
            throws SQLException {
        Collection<String> districts = new LinkedHashSet<>();
        if (udiseNos.isEmpty()) return districts;

        StringBuilder in = new StringBuilder();
        for (int i = 0; i < udiseNos.size(); i++) {
            in.append(i == 0 ? "?" : ",?");
        }
        String sql = "SELECT DISTINCT district_name FROM schools WHERE udise_no IN (" + in + ")";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            int idx = 1;
            for (String udise : udiseNos) {
                ps.setString(idx++, udise);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String d = rs.getString("district_name");
                    if (d != null) districts.add(d);
                }
            }
        }
        return districts;
    }

    /** One row per recipient. A logging failure must never lose an alert that was actually sent. */
    private void logSend(Connection conn, AlertCriterion criterion, int phase, String divisionName,
                         SchoolContact contact, String destination, WhatsAppResponse waResponse,
                         String sentBy) {
        String sql = "INSERT INTO whatsapp_alert_log (alert_type, phase_number, division_name, "
                   + "district_name, udise_no, contact_id, contact_type, recipient_name, "
                   + "recipient_number, template_name, success, response_body, sent_by) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, criterion.name());
            ps.setInt(2, phase);
            ps.setString(3, divisionName);
            ps.setString(4, contact.getDistrictName());
            ps.setString(5, contact.getUdiseNo());
            ps.setInt(6, contact.getContactId());
            ps.setString(7, contact.getContactType());
            ps.setString(8, contact.getFullName());
            ps.setString(9, WhatsAppService.normalizeNumber(destination));
            ps.setString(10, WhatsAppConfig.TPL_CRITERIA_ALERT);
            ps.setBoolean(11, waResponse.isSuccess());
            ps.setString(12, waResponse.getBody());
            ps.setString(13, sentBy);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println("[CriteriaAlert] could not log send for " + contact.getUdiseNo()
                    + ": " + e.getMessage());
        }
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    private PrintWriter beginJson(HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        return response.getWriter();
    }

    /** Same guard as DivisionPhaseStatusServlet. Returns null once the error has been written. */
    private User authorize(HttpServletRequest request, HttpServletResponse response, PrintWriter out) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print(new JSONObject().put("error", "Session expired").toString());
            return null;
        }
        User user = (User) session.getAttribute("user");
        if (user == null || (!user.getUserType().equals(User.UserType.DIVISION)
                && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print(new JSONObject().put("error", "Unauthorized access").toString());
            return null;
        }
        return user;
    }

    /** null for a super-division officer, who is not confined to one division. */
    private String divisionOf(User user) {
        return user.getUserType() == User.UserType.SUPER_DIVISION_OFFICER
                ? null : user.getDivisionName();
    }

    /** Envelope fields every response carries, so the UI can always render its test-mode banner. */
    private JSONObject baseResult(int phase) {
        JSONObject result = new JSONObject();
        result.put("phase", phase);
        result.put("testMode", WhatsAppConfig.ALERT_TEST_MODE);
        result.put("testNumber", WhatsAppConfig.ALERT_TEST_NUMBER);
        return result;
    }

    private Collection<String> parseUdises(String csv) {
        Collection<String> udiseNos = new LinkedHashSet<>();
        if (csv == null) return udiseNos;
        for (String part : csv.split(",")) {
            String value = part.trim();
            if (!value.isEmpty()) {
                udiseNos.add(value);
            }
        }
        return udiseNos;
    }

    private int parseInt(String value, int fallback) {
        try {
            return Integer.parseInt(value == null ? "" : value.trim());
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    private String trimToNull(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
