package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashMap;
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

import com.vjnt.model.User;
import com.vjnt.util.AlertCriterion;
import com.vjnt.util.AlertScope;
import com.vjnt.util.CoordinatorAlertMessages;
import com.vjnt.util.CoordinatorAlertSender;
import com.vjnt.util.CoordinatorAlertSummary;
import com.vjnt.util.CoordinatorAlertType;
import com.vjnt.util.CoordinatorContact;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.util.Java2DReportRenderer;
import com.vjnt.util.PdfRenderer;
import com.vjnt.util.PhaseBucketSql;
import com.vjnt.util.PhaseRosterSql;
import com.vjnt.util.PhaseSchoolRow;
import com.vjnt.util.SchoolAlertSender;
import com.vjnt.util.WhatsAppConfig;
import com.vjnt.util.WhatsAppService;
import com.vjnt.util.WhatsAppService.WhatsAppResponse;

/**
 * Coordinator Alerts console for the Division login.
 *
 * The upward counterpart of {@link DivisionCriteriaAlertServlet}: instead of chasing schools, it
 * tells the officers who supervise them how their district or division stands. Same five
 * {@link AlertCriterion} buckets, computed with the same SQL ({@link PhaseBucketSql}) so the two
 * consoles can never quote different numbers, plus a sixth roll-up status report.
 *
 * Each message carries the matching school list as an attached PDF — or, while the document-header
 * templates are still pending Meta approval, as a portal link. See
 * {@link WhatsAppConfig#COORDINATOR_DOC_TEMPLATES_APPROVED}.
 *
 * <pre>
 *   GET  ?phase=N                                    → per-district counts + division roll-up,
 *                                                      with recipients and reachability
 *   GET  ?phase=N&amp;scope=DISTRICT&amp;name=X&amp;type=KEY   → the schools that would be listed, and who
 *                                                      would be messaged
 *   POST  phase=N&amp;type=KEY&amp;scope=DISTRICT&amp;names=a,b  → send to those scopes' coordinators
 * </pre>
 *
 * Division users are confined to their own division; a super-division officer is not. District
 * coordinators cannot use this console at all — it exists to message them.
 */
@WebServlet("/coordinator-criteria-alert")
public class CoordinatorCriteriaAlertServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /**
     * Upper bound on one send, counted in scopes rather than recipients. A division has tens of
     * districts, not hundreds, so anything larger is a crafted request rather than a real click.
     */
    private static final int MAX_SCOPES_PER_SEND = 40;

    /** Schools listed in one PDF. Beyond this the document is unreadable and the render is slow. */
    private static final int MAX_ROWS_PER_DOCUMENT = 2000;

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
            badRequest(response, out, "Invalid phase");
            return;
        }

        String divisionName = divisionOf(user);
        AlertScope scope = AlertScope.from(request.getParameter("scope"));
        String name = trimToNull(request.getParameter("name"));
        CoordinatorAlertType type = CoordinatorAlertType.from(request.getParameter("type"));

        JSONObject result = (scope != null && scope.isCoordinatorScope() && name != null && type != null)
                ? getScopeDetail(user, divisionName, scope, name, type, phase)
                : getOverview(divisionName, phase);

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
            badRequest(response, out, "Invalid phase");
            return;
        }

        CoordinatorAlertType type = CoordinatorAlertType.from(request.getParameter("type"));
        if (type == null) {
            badRequest(response, out, "Unknown alert type");
            return;
        }

        AlertScope scope = AlertScope.from(request.getParameter("scope"));
        if (scope == null || !scope.isCoordinatorScope()) {
            badRequest(response, out, "Scope must be DISTRICT or DIVISION");
            return;
        }

        List<String> names = parseList(request.getParameter("names"));
        if (names.isEmpty()) {
            badRequest(response, out, "Nothing selected");
            return;
        }
        if (names.size() > MAX_SCOPES_PER_SEND) {
            badRequest(response, out, "Too many in one send (max " + MAX_SCOPES_PER_SEND + ")");
            return;
        }

        out.print(sendAlerts(user, scope, type, phase, names).toString());
        out.flush();
    }

    // ------------------------------------------------------------------
    // Reads
    // ------------------------------------------------------------------

    /**
     * Per-district bucket counts, plus the division roll-up built by summing them, plus how many
     * coordinators each scope can actually be reached on.
     */
    private JSONObject getOverview(String divisionName, int phase) {
        JSONObject result = baseResult(phase);

        try (Connection conn = DatabaseConnection.getConnection()) {
            Map<String, CoordinatorAlertSummary> districts = loadDistrictSummaries(conn, divisionName, phase);

            JSONArray array = new JSONArray();
            for (CoordinatorAlertSummary summary : districts.values()) {
                JSONObject d = summaryJson(summary);
                d.put("recipients", recipientsJson(
                        CoordinatorAlertSender.loadDistrictCoordinators(conn, summary.getName())));
                array.put(d);
            }
            result.put("districts", array);

            // The division roll-up is the sum of the rows above, never a separately-derived figure —
            // a division officer and their district coordinators must never be quoted totals that
            // disagree. Only meaningful for a single division, so a super-division officer (who sees
            // every district) gets no roll-up rather than a meaningless statewide one.
            if (divisionName != null) {
                CoordinatorAlertSummary division =
                        new CoordinatorAlertSummary(AlertScope.DIVISION, divisionName, divisionName, phase);
                for (CoordinatorAlertSummary d : districts.values()) {
                    division.add(d);
                }
                JSONObject j = summaryJson(division);
                j.put("recipients", recipientsJson(
                        CoordinatorAlertSender.loadDivisionCoordinators(conn, divisionName)));
                result.put("division", j);
            }

        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        return result;
    }

    /** The schools that would be listed in the document, and the coordinators who would be messaged. */
    private JSONObject getScopeDetail(User user, String divisionName, AlertScope scope, String name,
                                      CoordinatorAlertType type, int phase) {
        JSONObject result = baseResult(phase);
        result.put("scope", scope.name());
        result.put("name", name);
        result.put("type", type.name());
        result.put("heading", type.getHeading());

        try (Connection conn = DatabaseConnection.getConnection()) {
            if (!mayAlert(conn, user, divisionName, scope, name)) {
                result.put("error", "Not permitted for this " + scope.name().toLowerCase());
                return result;
            }

            CoordinatorAlertSummary summary = buildSummary(conn, divisionName, scope, name, phase);
            List<PhaseSchoolRow> rows = loadRows(conn, divisionName, scope, name, type, phase);

            result.put("summary", summaryJson(summary));
            result.put("params", new JSONArray(CoordinatorAlertMessages.build(type, summary)));
            result.put("schoolCount", rows.size());

            JSONArray schools = new JSONArray();
            for (PhaseSchoolRow r : rows) {
                schools.put(new JSONObject()
                        .put("udiseNo", r.getUdiseNo())
                        .put("schoolName", r.getDisplayName())
                        .put("districtName", nullToEmpty(r.getDistrictName()))
                        .put("total", r.getTotal())
                        .put("done", r.getDone())
                        .put("percentage", r.getPercentage())
                        .put("approvalStatus", r.getApprovalLabel()));
            }
            result.put("schools", schools);

            List<CoordinatorContact> recipients = loadRecipients(conn, scope, name);
            result.put("recipients", recipientsJson(recipients));
            result.put("lastAlertedAt", tsJson(
                    CoordinatorAlertSender.lastAlertedAt(conn, scope, name, type, phase)));

        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        return result;
    }

    /**
     * One summary per district in scope, keyed by district name and ordered by it.
     *
     * Bucket counts, the school total and the roster totals all come from one pass over
     * {@link PhaseBucketSql#schoolPhaseSubquery}, so the percentage in the message and the counts in
     * the message cannot be computed off different reads.
     */
    private Map<String, CoordinatorAlertSummary> loadDistrictSummaries(Connection conn,
                                                                       String divisionName, int phase)
            throws SQLException {
        Map<String, CoordinatorAlertSummary> byDistrict = new LinkedHashMap<>();

        StringBuilder sql = new StringBuilder("SELECT district_name, COUNT(*) AS total_schools, ");
        sql.append("SUM(").append(PhaseBucketSql.COL_TOTAL).append(") AS roster_total, ");
        sql.append("SUM(").append(PhaseBucketSql.COL_DONE).append(") AS roster_done");
        for (AlertCriterion c : AlertCriterion.values()) {
            sql.append(", SUM(CASE WHEN ").append(PhaseBucketSql.bucketCondition(c))
               .append(" THEN 1 ELSE 0 END) AS ").append(c.name().toLowerCase());
        }
        sql.append(" FROM (")
           .append(PhaseBucketSql.schoolPhaseSubquery(phase, divisionName != null, false))
           .append(") sch GROUP BY district_name ORDER BY district_name");

        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            if (divisionName != null) {
                ps.setString(1, divisionName);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String district = rs.getString("district_name");
                    CoordinatorAlertSummary s = new CoordinatorAlertSummary(
                            AlertScope.DISTRICT, district, divisionName, phase);
                    s.setTotalSchools(rs.getInt("total_schools"));
                    s.setRosterTotal(rs.getLong("roster_total"));
                    s.setRosterDone(rs.getLong("roster_done"));
                    for (AlertCriterion c : AlertCriterion.values()) {
                        s.setCount(c, rs.getInt(c.name().toLowerCase()));
                    }
                    byDistrict.put(district, s);
                }
            }
        }
        return byDistrict;
    }

    /**
     * The summary for one scope.
     *
     * A DIVISION summary is assembled by summing its districts rather than by a separate query, for
     * the same reason the overview does: two derivations of one total will eventually disagree.
     */
    private CoordinatorAlertSummary buildSummary(Connection conn, String divisionName,
                                                 AlertScope scope, String name, int phase)
            throws SQLException {
        if (scope == AlertScope.DIVISION) {
            Map<String, CoordinatorAlertSummary> districts = loadDistrictSummaries(conn, name, phase);
            CoordinatorAlertSummary division =
                    new CoordinatorAlertSummary(AlertScope.DIVISION, name, name, phase);
            for (CoordinatorAlertSummary d : districts.values()) {
                division.add(d);
            }
            return division;
        }

        Map<String, CoordinatorAlertSummary> districts = loadDistrictSummaries(conn, divisionName, phase);
        CoordinatorAlertSummary found = districts.get(name);
        if (found != null) {
            return found;
        }
        // A district with no schools at all still needs a summary, so the message and the document
        // can say "0 शाळा" rather than the send failing with a null.
        return new CoordinatorAlertSummary(AlertScope.DISTRICT, name, divisionName, phase);
    }

    /**
     * Schools to list in the document: the bucket's schools for an alert, every school for the
     * status report — which also gets a mark per bucket, computed here so the PDF does not re-derive
     * the conditions in Java and drift from the SQL.
     */
    private List<PhaseSchoolRow> loadRows(Connection conn, String divisionName, AlertScope scope,
                                          String name, CoordinatorAlertType type, int phase)
            throws SQLException {
        boolean division = scope == AlertScope.DIVISION;
        // At division scope the division filter is the selected name; at district scope it stays the
        // logged-in user's division, and the district filter narrows it.
        String divisionFilter = division ? name : divisionName;
        boolean filterDivision = divisionFilter != null;
        boolean filterDistrict = !division;

        StringBuilder sql = new StringBuilder("SELECT udise_no, school_name, district_name, ")
                .append(PhaseBucketSql.COL_TOTAL).append(", ")
                .append(PhaseBucketSql.COL_DONE).append(", ")
                .append(PhaseBucketSql.COL_APPROVAL)
                .append(" FROM (")
                .append(PhaseBucketSql.schoolPhaseSubquery(phase, filterDivision, filterDistrict))
                .append(") sch");
        if (!type.isRollUp()) {
            sql.append(" WHERE ").append(PhaseBucketSql.bucketCondition(type.getCriterion()));
        }
        sql.append(" ORDER BY district_name, school_name LIMIT ").append(MAX_ROWS_PER_DOCUMENT);

        List<PhaseSchoolRow> rows = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            if (filterDivision) ps.setString(idx++, divisionFilter);
            if (filterDistrict) ps.setString(idx, name);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    PhaseSchoolRow r = new PhaseSchoolRow();
                    r.setUdiseNo(rs.getString("udise_no"));
                    r.setSchoolName(rs.getString("school_name"));
                    r.setDistrictName(rs.getString("district_name"));
                    r.setTotal(rs.getInt(PhaseBucketSql.COL_TOTAL));
                    r.setDone(rs.getInt(PhaseBucketSql.COL_DONE));
                    r.setApprovalStatus(rs.getString(PhaseBucketSql.COL_APPROVAL));
                    rows.add(r);
                }
            }
        }
        if (type.isRollUp()) {
            markBuckets(rows);
        }
        return rows;
    }

    /**
     * Flag which buckets each school is in, for the status report's tick columns.
     *
     * Mirrors {@link AlertCriterion#sqlCondition} deliberately and only here — the SQL remains the
     * single source for who is counted; this is presentation of rows the SQL already returned.
     */
    private void markBuckets(List<PhaseSchoolRow> rows) {
        for (PhaseSchoolRow r : rows) {
            int total = r.getTotal();
            int done  = r.getDone();
            int pct   = r.getPercentage();
            String approval = r.getApprovalStatus();

            if (total > 0 && done == 0)                    r.addBucket(AlertCriterion.NOT_STARTED);
            if (total > 0 && done > 0 && pct < 25)         r.addBucket(AlertCriterion.BELOW_25);
            if (total > 0 && done > 0 && pct < 50)         r.addBucket(AlertCriterion.BELOW_50);
            if (total > 0 && done == total
                    && !"APPROVED".equalsIgnoreCase(approval == null ? "" : approval)) {
                r.addBucket(AlertCriterion.PENDING_APPROVAL);
            }
            if ("REJECTED".equalsIgnoreCase(approval == null ? "" : approval)) {
                r.addBucket(AlertCriterion.REJECTED);
            }
        }
    }

    private List<CoordinatorContact> loadRecipients(Connection conn, AlertScope scope, String name)
            throws SQLException {
        return scope == AlertScope.DIVISION
                ? CoordinatorAlertSender.loadDivisionCoordinators(conn, name)
                : CoordinatorAlertSender.loadDistrictCoordinators(conn, name);
    }

    // ------------------------------------------------------------------
    // Send
    // ------------------------------------------------------------------

    private JSONObject sendAlerts(User user, AlertScope scope, CoordinatorAlertType type,
                                  int phase, List<String> names) {
        JSONObject result = baseResult(phase);
        result.put("type", type.name());
        result.put("scope", scope.name());

        JSONArray results = new JSONArray();
        int sent = 0;
        int failed = 0;
        int skipped = 0;
        String divisionName = divisionOf(user);

        try (Connection conn = DatabaseConnection.getConnection()) {
            for (String name : names) {
                JSONObject scopeResult = new JSONObject().put("name", name);

                if (!mayAlert(conn, user, divisionName, scope, name)) {
                    results.put(scopeResult.put("success", false)
                            .put("error", "Not permitted for this " + scope.name().toLowerCase()));
                    skipped++;
                    continue;
                }

                // Re-derived here rather than taken from the request: a console left open while
                // schools finished their work must not send yesterday's counts, and the document must
                // match the numbers in the message it is attached to.
                CoordinatorAlertSummary summary;
                List<PhaseSchoolRow> rows;
                try {
                    summary = buildSummary(conn, divisionName, scope, name, phase);
                    rows = loadRows(conn, divisionName, scope, name, type, phase);
                } catch (SQLException e) {
                    results.put(scopeResult.put("success", false).put("error", e.getMessage()));
                    failed++;
                    continue;
                }

                // Nothing to report is not a message worth sending: "0 शाळांनी काम सुरू केलेले नाही"
                // wastes an officer's attention and a template send. The roll-up is exempt — a
                // district at zero pending is exactly what a status report should be able to say.
                if (rows.isEmpty() && !type.isRollUp()) {
                    results.put(scopeResult.put("success", false)
                            .put("error", "No schools in this list — nothing to send"));
                    skipped++;
                    continue;
                }

                List<CoordinatorContact> recipients;
                try {
                    recipients = loadRecipients(conn, scope, name);
                } catch (SQLException e) {
                    results.put(scopeResult.put("success", false).put("error", e.getMessage()));
                    failed++;
                    continue;
                }
                if (recipients.isEmpty()) {
                    results.put(scopeResult.put("success", false)
                            .put("error", "No active coordinator on record"));
                    skipped++;
                    continue;
                }

                // Built once per scope, not per recipient: two coordinators in one district get the
                // same document rather than two identical uploads.
                String documentUrl = null;
                String fileName = null;
                String documentError = null;
                if (type.carriesDocument()) {
                    try {
                        documentUrl = CoordinatorAlertSender.buildAndUploadDocument(type, summary, rows);
                        fileName = CoordinatorAlertSender.documentBaseName(type, summary) + ".pdf";
                    } catch (IOException | RuntimeException e) {
                        // Send anyway, without the attachment. This used to abandon the scope, which
                        // meant a CDN hiccup silently cost a district its alert entirely - a worse
                        // outcome than an alert carrying a portal link. The wording, the template and
                        // its parameter count all follow documentUrl being null, so the message stays
                        // consistent with what actually arrives.
                        documentError = e.getMessage();
                        documentUrl = null;
                        fileName = null;
                        System.err.println("[CoordinatorAlert] Document unavailable for "
                                + scope + " " + name + ", sending without attachment: " + e);
                    }
                }
                if (documentError != null) {
                    scopeResult.put("documentError", documentError);
                }
                scopeResult.put("documentAttached", documentUrl != null);

                // Built for the document state actually achieved, not the one hoped for.
                String[] params = CoordinatorAlertMessages.build(type, summary, documentUrl != null);
                JSONArray perRecipient = new JSONArray();

                for (CoordinatorContact contact : recipients) {
                    JSONObject r = new JSONObject()
                            .put("userId", contact.getUserId())
                            .put("name", contact.getDisplayName())
                            .put("userType", nullToEmpty(contact.getUserType()));

                    String number = contact.resolveNumber();
                    if (number == null) {
                        // users has no whatsapp_number column, so mobile is all there is.
                        perRecipient.put(r.put("success", false)
                                .put("error", "No mobile number on record"));
                        skipped++;
                        continue;
                    }

                    String destination = SchoolAlertSender.destinationFor(number);
                    WhatsAppResponse waResponse =
                            CoordinatorAlertSender.send(type, params, number, documentUrl, fileName);

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
                    perRecipient.put(r);

                    CoordinatorAlertSender.logSend(conn, type, summary, contact, destination,
                                                   documentUrl, waResponse, user.getUsername());
                }

                scopeResult.put("success", true)
                           .put("schoolCount", rows.size())
                           .put("documentUrl", documentUrl == null ? JSONObject.NULL : documentUrl)
                           .put("recipients", perRecipient);
                results.put(scopeResult);
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

    // ------------------------------------------------------------------
    // Authorization
    // ------------------------------------------------------------------

    /**
     * Whether this user may message the coordinators of this scope.
     *
     * A super-division officer may reach anything. A division user is confined to districts in their
     * own division, and to their own division at DIVISION scope — so a division cannot alert a
     * neighbouring division's officers by posting their name.
     */
    private boolean mayAlert(Connection conn, User user, String divisionName, AlertScope scope,
                             String name) throws SQLException {
        if (user.getUserType() == User.UserType.SUPER_DIVISION_OFFICER) {
            return true;
        }
        if (divisionName == null || name == null) {
            return false;
        }
        if (scope == AlertScope.DIVISION) {
            return divisionName.equalsIgnoreCase(name.trim());
        }
        return SchoolAlertSender.districtInDivision(conn, divisionName, name);
    }

    /** Same guard as the school criteria console: division and super-division logins only. */
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

    // ------------------------------------------------------------------
    // JSON helpers
    // ------------------------------------------------------------------

    private JSONObject summaryJson(CoordinatorAlertSummary summary) {
        JSONObject counts = new JSONObject();
        for (CoordinatorAlertType t : CoordinatorAlertType.values()) {
            if (t.isRollUp()) continue;
            counts.put(t.name(), summary.getCount(t));
        }
        return new JSONObject()
                .put("scope", summary.getScope().name())
                .put("name", summary.getName())
                .put("totalSchools", summary.getTotalSchools())
                .put("rosterTotal", summary.getRosterTotal())
                .put("rosterDone", summary.getRosterDone())
                .put("progress", summary.getProgressPercentage())
                .put("counts", counts);
    }

    private JSONArray recipientsJson(List<CoordinatorContact> contacts) {
        JSONArray array = new JSONArray();
        for (CoordinatorContact c : contacts) {
            String number = c.resolveNumber();
            array.put(new JSONObject()
                    .put("userId", c.getUserId())
                    .put("name", c.getDisplayName())
                    .put("userType", nullToEmpty(c.getUserType()))
                    .put("number", number == null ? "" : number)
                    .put("hasNumber", number != null));
        }
        return array;
    }

    private Object tsJson(Timestamp ts) {
        return ts == null ? JSONObject.NULL : ts.toString();
    }

    /**
     * Envelope every response carries: the UI needs it to render the test-mode banner, and to warn
     * when documents are promised but the renderer or the templates are not ready.
     */
    private JSONObject baseResult(int phase) {
        JSONObject result = new JSONObject();
        result.put("phase", phase);
        result.put("testMode", WhatsAppConfig.ALERT_TEST_MODE);
        result.put("testNumber", WhatsAppConfig.ALERT_TEST_NUMBER);
        // Reported separately because the two families sit on different templates with different
        // approval states: the status report attaches its PDF today, the five alerts still link.
        // EFFECTIVE behaviour, not just the config flags: carriesDocument() also requires a working
        // renderer, so a server without Chromium reports "no attachment" here and the console shows
        // what will actually happen rather than what was configured.
        result.put("alertDocsEnabled", CoordinatorAlertType.NOT_STARTED.carriesDocument());
        result.put("reportDocsEnabled", CoordinatorAlertType.STATUS_REPORT.carriesDocument());
        result.put("alertDocsConfigured", WhatsAppConfig.ALERT_DOC_TEMPLATE_APPROVED);
        result.put("reportDocsConfigured", WhatsAppConfig.STATUS_REPORT_DOC_TEMPLATE_APPROVED);
        boolean browser  = PdfRenderer.isAvailable();
        boolean fallback = Java2DReportRenderer.isAvailable();
        // rendererAvailable answers "will a PDF be attached", which is what the console banner acts
        // on — either renderer produces one, so it must not report only the browser.
        result.put("rendererAvailable", browser || fallback);
        result.put("browserRendererAvailable", browser);
        result.put("fallbackRendererAvailable", fallback);
        result.put("rendererKind", browser ? "chromium" : (fallback ? "java2d" : "none"));
        // Only when something failed: naming every path that was tried turns "no browser available"
        // into something actionable without shell access to the server.
        if (!browser) {
            result.put("rendererDiagnostic", PdfRenderer.describeAvailability());
        }
        if (!fallback) {
            result.put("fallbackDiagnostic", Java2DReportRenderer.describeAvailability());
        }
        return result;
    }

    private PrintWriter beginJson(HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        return response.getWriter();
    }

    private void badRequest(HttpServletResponse response, PrintWriter out, String message) {
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        out.print(new JSONObject().put("error", message).toString());
        out.flush();
    }

    private List<String> parseList(String csv) {
        List<String> values = new ArrayList<>();
        if (csv == null) return values;
        for (String part : csv.split(",")) {
            String value = part.trim();
            if (!value.isEmpty() && !values.contains(value)) {
                values.add(value);
            }
        }
        return values;
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
