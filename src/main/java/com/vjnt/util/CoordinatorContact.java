package com.vjnt.util;

/**
 * One coordinator who can be sent an alert, read from the {@code users} table.
 *
 * Deliberately not {@link com.vjnt.model.SchoolContact}: the two come from different tables with
 * different columns and different rules. Most importantly, {@code users} has no whatsapp_number
 * column — {@link com.vjnt.model.User} declares the field but the table does not have it — so
 * {@link #resolveNumber()} has only {@code mobile} to work with, where a school contact prefers
 * whatsapp_number and falls back to mobile.
 */
public class CoordinatorContact {

    private int userId;
    private String username;
    private String fullName;
    private String userType;
    private String districtName;
    private String divisionName;
    private String mobile;

    /**
     * Only ever populated from coordinator_contacts — the users table has no such column. Null for a
     * contact that came from a portal login.
     */
    private String whatsappNumber;

    /** DISTRICT for a district coordinator, DIVISION for a division/super-division officer. */
    private AlertScope scope;

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getUserType() { return userType; }
    public void setUserType(String userType) { this.userType = userType; }

    public String getDistrictName() { return districtName; }
    public void setDistrictName(String districtName) { this.districtName = districtName; }

    public String getDivisionName() { return divisionName; }
    public void setDivisionName(String divisionName) { this.divisionName = divisionName; }

    public String getMobile() { return mobile; }
    public void setMobile(String mobile) { this.mobile = mobile; }

    public String getWhatsappNumber() { return whatsappNumber; }
    public void setWhatsappNumber(String whatsappNumber) { this.whatsappNumber = whatsappNumber; }

    public AlertScope getScope() { return scope; }
    public void setScope(AlertScope scope) { this.scope = scope; }

    /**
     * The number to message: whatsapp_number if there is one, otherwise mobile, otherwise null.
     *
     * Same precedence as {@code SchoolAlertSender.resolveNumber}, so a coordinator and a head master
     * are reached by the same rule. A contact loaded from the users table can only ever have mobile,
     * because that table has no whatsapp_number column.
     *
     * "null" arrives as a literal string from some imports and "-" from others, so both are treated
     * as absent rather than dialled.
     */
    public String resolveNumber() {
        String number = clean(whatsappNumber);
        return number != null ? number : clean(mobile);
    }

    private static String clean(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        if (trimmed.isEmpty() || "null".equalsIgnoreCase(trimmed) || "-".equals(trimmed)) {
            return null;
        }
        return trimmed;
    }

    /** Whether this coordinator can actually be reached. */
    public boolean hasNumber() {
        return resolveNumber() != null;
    }

    /**
     * Value written to whatsapp_alert_log.contact_type, mirroring how school sends record
     * "Head Master" / "School Coordinator" there.
     */
    public String getLogContactType() {
        return scope == AlertScope.DIVISION ? "Division Coordinator" : "District Coordinator";
    }

    /** Name for the console and the log; falls back to the username, which is never blank. */
    public String getDisplayName() {
        if (fullName != null && !fullName.trim().isEmpty()) {
            return fullName.trim();
        }
        return username == null ? "" : username;
    }
}
