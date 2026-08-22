package com.vjnt.util;

import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

import com.vjnt.util.WhatsAppService.WhatsAppResponse;

/**
 * Shared plumbing for "send a coordinator alert to the people who supervise these schools".
 *
 * The counterpart of {@link SchoolAlertSender}, one level up: recipients come from {@code users}
 * rather than {@code school_contacts}, the figures are district or division totals rather than one
 * school's, and the message can carry a PDF of the school list.
 *
 * The two cannot share a loader because the tables differ in the way that matters — {@code users}
 * has no whatsapp_number column, so a coordinator is reachable on {@code mobile} alone.
 */
public final class CoordinatorAlertSender {

    /** users.user_type values that are district-level coordinators. */
    public static final String[] DISTRICT_USER_TYPES =
            { "DISTRICT_COORDINATOR", "DISTRICT_2ND_COORDINATOR" };

    /** users.user_type values that are division-level officers. */
    public static final String[] DIVISION_USER_TYPES =
            { "DIVISION", "SUPER_DIVISION_OFFICER" };

    private CoordinatorAlertSender() { }

    // ------------------------------------------------------------------
    // Recipients
    // ------------------------------------------------------------------

    /**
     * Active district coordinators for one district.
     *
     * Reads coordinator_contacts first and only falls back to the users table when that yields
     * nothing — because a coordinator is not necessarily a portal user, users has room for just two
     * district roles where some districts have three people to alert, and users has no
     * whatsapp_number column. The fallback means the console keeps working before the contacts table
     * is seeded, or if it is never created at all.
     *
     * Collation is forced on every comparison because district_name is utf8mb4_0900_ai_ci in
     * {@code users} but varies elsewhere and per deployment — an unqualified compare raises
     * "Illegal mix of collations" on some hosts and silently matches nothing on others.
     */
    public static List<CoordinatorContact> loadDistrictCoordinators(Connection conn, String districtName)
            throws SQLException {
        List<CoordinatorContact> contacts = loadFromContactsTable(conn, AlertScope.DISTRICT, districtName);
        if (!contacts.isEmpty()) {
            return contacts;
        }
        String sql = "SELECT user_id, username, full_name, user_type, district_name, division_name, mobile "
                   + "FROM users WHERE is_active = 1 "
                   + "AND user_type IN ('DISTRICT_COORDINATOR', 'DISTRICT_2ND_COORDINATOR') "
                   + "AND district_name COLLATE utf8mb4_unicode_ci = ? COLLATE utf8mb4_unicode_ci "
                   + "ORDER BY user_type, full_name";
        return query(conn, sql, districtName, AlertScope.DISTRICT);
    }

    /** Active division officers for one division. Same two-source rule as the district loader. */
    public static List<CoordinatorContact> loadDivisionCoordinators(Connection conn, String divisionName)
            throws SQLException {
        List<CoordinatorContact> contacts = loadFromContactsTable(conn, AlertScope.DIVISION, divisionName);
        if (!contacts.isEmpty()) {
            return contacts;
        }
        String sql = "SELECT user_id, username, full_name, user_type, district_name, division_name, mobile "
                   + "FROM users WHERE is_active = 1 "
                   + "AND user_type IN ('DIVISION', 'SUPER_DIVISION_OFFICER') "
                   + "AND division_name COLLATE utf8mb4_unicode_ci = ? COLLATE utf8mb4_unicode_ci "
                   + "ORDER BY user_type, full_name";
        return query(conn, sql, divisionName, AlertScope.DIVISION);
    }

    /**
     * Contacts recorded specifically for alerting, from coordinator_contacts.
     *
     * Returns empty — rather than throwing — when the table does not exist yet, so a deployment that
     * has not run ADD_COORDINATOR_CONTACTS_2026-08-19.sql degrades to the users table instead of
     * breaking the console. Any other SQL problem is reported for the same reason: losing the ability
     * to send is worse than sending to whoever the users table knows about.
     */
    private static List<CoordinatorContact> loadFromContactsTable(Connection conn, AlertScope scope,
                                                                  String scopeValue) {
        List<CoordinatorContact> list = new ArrayList<>();
        if (scopeValue == null || scopeValue.trim().isEmpty()) {
            return list;
        }
        String column = (scope == AlertScope.DIVISION) ? "division_name" : "district_name";
        String sql = "SELECT contact_id, full_name, designation, district_name, division_name, "
                   + "mobile, whatsapp_number FROM coordinator_contacts "
                   + "WHERE is_active = 1 AND scope = ? "
                   + "AND " + column + " COLLATE utf8mb4_unicode_ci = ? COLLATE utf8mb4_unicode_ci "
                   + "ORDER BY full_name";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, scope.getDbValue());
            ps.setString(2, scopeValue.trim());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    CoordinatorContact c = new CoordinatorContact();
                    // Not a users.user_id — these contacts need no login. Left at 0 so the send log
                    // records NULL rather than pointing at an unrelated user row.
                    c.setUserId(0);
                    c.setFullName(rs.getString("full_name"));
                    c.setUserType(rs.getString("designation"));
                    c.setDistrictName(rs.getString("district_name"));
                    c.setDivisionName(rs.getString("division_name"));
                    c.setMobile(rs.getString("mobile"));
                    c.setWhatsappNumber(rs.getString("whatsapp_number"));
                    c.setScope(scope);
                    list.add(c);
                }
            }
        } catch (SQLException e) {
            System.err.println("[CoordinatorAlert] coordinator_contacts unavailable, falling back to"
                    + " users: " + e.getMessage());
        }
        return list;
    }

    private static List<CoordinatorContact> query(Connection conn, String sql, String scopeValue,
                                                  AlertScope scope) throws SQLException {
        List<CoordinatorContact> list = new ArrayList<>();
        if (scopeValue == null || scopeValue.trim().isEmpty()) {
            return list;
        }
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, scopeValue.trim());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    CoordinatorContact c = new CoordinatorContact();
                    c.setUserId(rs.getInt("user_id"));
                    c.setUsername(rs.getString("username"));
                    c.setFullName(rs.getString("full_name"));
                    c.setUserType(rs.getString("user_type"));
                    c.setDistrictName(rs.getString("district_name"));
                    c.setDivisionName(rs.getString("division_name"));
                    c.setMobile(rs.getString("mobile"));
                    c.setScope(scope);
                    list.add(c);
                }
            }
        }
        return list;
    }

    // ------------------------------------------------------------------
    // Document
    // ------------------------------------------------------------------

    /**
     * Build the school-list PDF and upload it, returning its public URL — or null when this send
     * carries no document (the templates are not approved yet, so the message links to the portal).
     *
     * The local PDF is always deleted, uploaded or not: it is a temp file and there is no reason to
     * leave hundreds of them on the server.
     *
     * @throws IOException if the render or upload fails — the caller must abandon the send rather
     *                     than quietly deliver a message that promises an attachment it lacks
     */
    public static String buildAndUploadDocument(CoordinatorAlertType type,
                                                CoordinatorAlertSummary summary,
                                                List<PhaseSchoolRow> rows) throws IOException {
        if (!type.carriesDocument()) {
            return null;
        }
        String base = documentBaseName(type, summary);
        // Chromium first: it renders the HTML the report was designed in. Without a browser the
        // Java2D renderer paints the same layout from the same model, so the attachment is still
        // sent instead of degrading the whole message to a portal link.
        File pdf = PdfRenderer.isAvailable()
                ? PdfRenderer.renderToPdf(CoordinatorAlertReportHtml.build(type, summary, rows), base)
                : Java2DReportRenderer.renderToPdf(type, summary, rows, base);
        try {
            return BunnyCDNService.uploadFile(pdf, remotePath(summary, base + ".pdf"), "application/pdf");
        } finally {
            if (!pdf.delete()) {
                pdf.deleteOnExit();
            }
        }
    }

    /**
     * Filename the coordinator sees in WhatsApp, so it must say what the document is without being
     * opened. Scope name is transliteration-free by design — it is Devanagari in the database, and a
     * Devanagari filename survives WhatsApp but not every mail client, so the UDISE-style scope key
     * is used instead where the name is not ASCII.
     */
    public static String documentBaseName(CoordinatorAlertType type, CoordinatorAlertSummary summary) {
        String scopeKey = asciiOrFallback(summary.getName(),
                summary.getScope() == AlertScope.DIVISION ? "Division" : "District");
        return scopeKey + "_" + camel(type.name()) + "_Phase" + summary.getPhase()
             + "_" + new SimpleDateFormat("yyyyMMdd").format(new Date());
    }

    /**
     * Storage path for the document.
     *
     * A short random token is included so the URL cannot be guessed from the district and date: the
     * pull zone is public and unauthenticated, and these documents name every school in a district.
     */
    private static String remotePath(CoordinatorAlertSummary summary, String fileName) {
        SimpleDateFormat year  = new SimpleDateFormat("yyyy");
        SimpleDateFormat month = new SimpleDateFormat("MM");
        Date now = new Date();
        String token = UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        return "alerts/" + year.format(now) + "/" + month.format(now) + "/"
             + summary.getScope().getDbValue() + "/" + token + "/" + fileName;
    }

    private static String asciiOrFallback(String value, String fallback) {
        if (value == null) return fallback;
        String ascii = value.trim().replaceAll("[^A-Za-z0-9]", "");
        return ascii.isEmpty() ? fallback : ascii;
    }

    /** NOT_STARTED -> NotStarted, so the filename reads as a name rather than a constant. */
    private static String camel(String enumName) {
        StringBuilder out = new StringBuilder();
        for (String part : enumName.split("_")) {
            if (part.isEmpty()) continue;
            out.append(part.charAt(0))
               .append(part.substring(1).toLowerCase(Locale.ROOT));
        }
        return out.toString();
    }

    // ------------------------------------------------------------------
    // Send
    // ------------------------------------------------------------------

    /**
     * Send one coordinator alert, honouring the {@link WhatsAppConfig#ALERT_TEST_MODE} override the
     * school console already uses — so the recipient is still resolved, displayed and logged while
     * the message goes to the test number.
     *
     * @param documentUrl from {@link #buildAndUploadDocument}, or null for a link-only message
     */
    public static WhatsAppResponse send(CoordinatorAlertType type, String[] params,
                                        String realNumber, String documentUrl, String fileName) {
        String destination = SchoolAlertSender.destinationFor(realNumber);
        WhatsAppService service = WhatsAppService.getInstance();

        // Keyed off the URL actually in hand, not off carriesDocument(): when a document failed to
        // build, this send must go on the no-header template, whose params were built to match.
        if (documentUrl == null || documentUrl.trim().isEmpty()) {
            return service.sendTemplateMessage(destination, type.getTemplateName(false),
                                               type.getLanguageCode(), params);
        }
        return service.sendTemplateMessageWithDocument(destination, type.getTemplateName(true),
                                                       type.getLanguageCode(), params,
                                                       documentUrl, fileName);
    }

    // ------------------------------------------------------------------
    // Log
    // ------------------------------------------------------------------

    /**
     * One row per recipient. A logging failure must never lose an alert that was actually sent, so
     * every problem here is reported and swallowed — same contract as the school console's logSend.
     */
    public static void logSend(Connection conn, CoordinatorAlertType type,
                               CoordinatorAlertSummary summary, CoordinatorContact contact,
                               String destination, String documentUrl,
                               WhatsAppResponse response, String sentBy) {
        String sql = "INSERT INTO whatsapp_alert_log (alert_type, phase_number, division_name, "
                   + "district_name, udise_no, contact_id, contact_type, recipient_name, "
                   + "recipient_number, template_name, success, response_body, sent_by, "
                   + "recipient_scope, user_id, document_url) "
                   + "VALUES (?, ?, ?, ?, NULL, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, type.name());
            ps.setInt(2, summary.getPhase());
            ps.setString(3, summary.getDivisionName());
            // NULL at division scope: the row covers many districts, and naming one would be wrong.
            ps.setString(4, summary.getDistrictName());
            ps.setString(5, contact.getLogContactType());
            ps.setString(6, contact.getDisplayName());
            ps.setString(7, WhatsAppService.normalizeNumber(destination));
            ps.setString(8, type.getTemplateName());
            ps.setBoolean(9, response.isSuccess());
            ps.setString(10, response.getBody());
            ps.setString(11, sentBy);
            ps.setString(12, contact.getScope().getDbValue());
            // Contacts from coordinator_contacts have no users row, so the column stays NULL rather
            // than recording a 0 that looks like a real user id.
            if (contact.getUserId() > 0) {
                ps.setInt(13, contact.getUserId());
            } else {
                ps.setNull(13, java.sql.Types.INTEGER);
            }
            ps.setString(14, documentUrl);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println("[CoordinatorAlert] could not log send to user "
                    + contact.getUserId() + ": " + e.getMessage());
        }
    }

    /**
     * When this scope was last alerted for this type and phase, or null.
     *
     * Scoped on recipient_scope as well as name, so a district's coordinator alerts are never
     * confused with the school-level rows that share the same district_name and alert_type.
     */
    public static Timestamp lastAlertedAt(Connection conn, AlertScope scope, String name,
                                          CoordinatorAlertType type, int phase) {
        boolean division = scope == AlertScope.DIVISION;
        String sql = "SELECT MAX(sent_at) AS last_sent FROM whatsapp_alert_log "
                   + "WHERE recipient_scope = ? AND alert_type = ? AND phase_number = ? "
                   + "AND success = 1 AND "
                   + (division ? "division_name" : "district_name")
                   + " COLLATE utf8mb4_unicode_ci = ? COLLATE utf8mb4_unicode_ci";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, scope.getDbValue());
            ps.setString(2, type.name());
            ps.setInt(3, phase);
            ps.setString(4, name == null ? "" : name);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getTimestamp("last_sent") : null;
            }
        } catch (SQLException e) {
            // The log is a convenience, not a prerequisite: before the migration runs, the console
            // must still work. A missing column costs the "last alerted" stamp and nothing else.
            System.err.println("[CoordinatorAlert] last-alerted lookup skipped: " + e.getMessage());
            return null;
        }
    }
}
