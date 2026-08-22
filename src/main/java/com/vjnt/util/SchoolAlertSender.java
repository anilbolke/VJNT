package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import com.vjnt.model.SchoolContact;
import com.vjnt.util.WhatsAppService.WhatsAppResponse;

/**
 * Shared plumbing for "send a WhatsApp template to a school's Head Master and School Coordinator".
 *
 * Two features need it — the per-school Send Alert button (SendHmApprovalAlertServlet) and the
 * criteria alerts console (DivisionCriteriaAlertServlet) — and the rules they must agree on are the
 * fiddly ones: which contact types count, that whatsapp_number wins over mobile, that a contact with
 * neither is skipped rather than failed silently, and that a division may only reach schools in its
 * own districts. Keeping one copy is the point.
 */
public final class SchoolAlertSender {

    /** The two roles a school alert is addressed to. */
    public static final String CONTACT_HM = "Head Master";
    public static final String CONTACT_SC = "School Coordinator";

    private SchoolAlertSender() { }

    /** Head Master + School Coordinator contacts for the given schools. Empty list for no UDISEs. */
    public static List<SchoolContact> loadAlertContacts(Connection conn, Collection<String> udiseNos)
            throws SQLException {
        List<SchoolContact> contacts = new ArrayList<>();
        if (udiseNos == null || udiseNos.isEmpty()) {
            return contacts;
        }

        StringBuilder in = new StringBuilder();
        for (int i = 0; i < udiseNos.size(); i++) {
            in.append(i == 0 ? "?" : ",?");
        }
        String sql = "SELECT contact_id, udise_no, school_name, district_name, contact_type, "
                   + "full_name, mobile, whatsapp_number FROM school_contacts "
                   + "WHERE udise_no IN (" + in + ") AND contact_type IN (?, ?) "
                   + "ORDER BY udise_no, contact_type";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            int idx = 1;
            for (String udise : udiseNos) {
                ps.setString(idx++, udise);
            }
            ps.setString(idx++, CONTACT_HM);
            ps.setString(idx, CONTACT_SC);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    contacts.add(read(rs));
                }
            }
        }
        return contacts;
    }

    /** One contact by id, or null. */
    public static SchoolContact loadContact(Connection conn, int contactId) throws SQLException {
        String sql = "SELECT contact_id, udise_no, school_name, district_name, contact_type, "
                   + "full_name, mobile, whatsapp_number FROM school_contacts WHERE contact_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, contactId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? read(rs) : null;
            }
        }
    }

    private static SchoolContact read(ResultSet rs) throws SQLException {
        SchoolContact c = new SchoolContact();
        c.setContactId(rs.getInt("contact_id"));
        c.setUdiseNo(rs.getString("udise_no"));
        c.setSchoolName(rs.getString("school_name"));
        c.setDistrictName(rs.getString("district_name"));
        c.setContactType(rs.getString("contact_type"));
        c.setFullName(rs.getString("full_name"));
        c.setMobile(rs.getString("mobile"));
        c.setWhatsappNumber(rs.getString("whatsapp_number"));
        return c;
    }

    /**
     * The number to message: whatsapp_number if there is one, otherwise mobile, otherwise null.
     * "null" arrives as a literal string from some imports, so it is treated as absent.
     */
    public static String resolveNumber(SchoolContact contact) {
        String number = clean(contact.getWhatsappNumber());
        if (number == null) {
            number = clean(contact.getMobile());
        }
        return number;
    }

    private static String clean(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        if (trimmed.isEmpty() || "null".equalsIgnoreCase(trimmed) || "-".equals(trimmed)) {
            return null;
        }
        return trimmed;
    }

    /**
     * True when the district belongs to the division, i.e. the division is allowed to alert schools
     * in it. Divisions are defined by which districts have coordinators assigned to them.
     *
     * @param divisionName null for a super-division officer, who may reach every district
     */
    public static boolean districtInDivision(Connection conn, String divisionName, String districtName)
            throws SQLException {
        if (divisionName == null) {
            return true;
        }
        String sql = "SELECT COUNT(*) FROM users WHERE division_name = ? AND district_name = ? "
                   + "AND user_type IN ('DISTRICT_COORDINATOR', 'DISTRICT_2ND_COORDINATOR')";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, divisionName);
            ps.setString(2, districtName == null ? "" : districtName);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    /**
     * Where a message actually goes. While {@link WhatsAppConfig#ALERT_TEST_MODE} is on this is the
     * test number for every recipient — the real contact is still resolved, displayed and logged, so
     * the flow is exercised end to end without messaging hundreds of head masters.
     */
    public static String destinationFor(String realNumber) {
        return WhatsAppConfig.ALERT_TEST_MODE ? WhatsAppConfig.ALERT_TEST_NUMBER : realNumber;
    }

    /** Send one template, honouring the test-mode override. */
    public static WhatsAppResponse sendTemplate(String realNumber, String templateName,
                                                String languageCode, String[] params) {
        return WhatsAppService.getInstance()
                .sendTemplateMessage(destinationFor(realNumber), templateName, languageCode, params);
    }
}
