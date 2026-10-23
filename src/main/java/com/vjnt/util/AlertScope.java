package com.vjnt.util;

/**
 * Who an alert was addressed to, and at what grain its numbers were computed.
 *
 * Stored in whatsapp_alert_log.recipient_scope. It exists because coordinator sends have no
 * udise_no, and the "शेवटचा अलर्ट" lookup is keyed on udise_no — without this column a district
 * coordinator's alert and a school's alert are indistinguishable in the log, and the re-send warning
 * on one console would silently read rows belonging to the other.
 */
public enum AlertScope {

    /** One school, its own figures. The existing Criteria Alerts console. */
    SCHOOL("SCHOOL"),

    /** One district's totals, sent to its District Coordinators. */
    DISTRICT("DISTRICT"),

    /** One division's totals, summed across its districts, sent to its Division officers. */
    DIVISION("DIVISION");

    private final String dbValue;

    AlertScope(String dbValue) {
        this.dbValue = dbValue;
    }

    /** Value written to whatsapp_alert_log.recipient_scope. */
    public String getDbValue() {
        return dbValue;
    }

    /** Parse from the request, or null when missing/unknown. */
    public static AlertScope from(String key) {
        if (key == null) return null;
        try {
            return valueOf(key.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /** True for the two coordinator grains — i.e. aggregate figures rather than one school's. */
    public boolean isCoordinatorScope() {
        return this == DISTRICT || this == DIVISION;
    }
}
