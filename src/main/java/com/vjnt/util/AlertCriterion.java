package com.vjnt.util;

/**
 * The five follow-up buckets the division chases schools by, for one phase.
 *
 * Definition lives here once and is used twice: to build the SQL that counts and lists the schools
 * in a bucket, and to re-validate on POST that a school the division ticked really is in the bucket
 * it claims. A stale preview therefore cannot alert the wrong schools.
 *
 * Progress is judged on the ROUNDED percentage, deliberately: the same rounding the division sees in
 * the table and the school sees on its own चरण अहवाल card. Comparing the raw fraction instead would
 * put a school displaying "25%" into the "below 25%" bucket.
 */
public enum AlertCriterion {

    /** No student saved in this phase at all. */
    NOT_STARTED("काम सुरू न केलेली शाळा"),

    /** Started, but under a quarter done. */
    BELOW_25("25% पेक्षा कमी प्रगती"),

    /**
     * Started, but under half done. Deliberately NESTS with BELOW_25 — a school at 10% appears in
     * both, because the two are separate campaigns run at different times and the 50% sweep is
     * meant to be the wider net.
     */
    BELOW_50("50% पेक्षा कमी प्रगती"),

    /** Every student saved, but the Head Master has not approved it. */
    PENDING_APPROVAL("माहिती 100% भरली — Approval प्रलंबित"),

    /** Head Master sent it back and the correction has not been made. */
    REJECTED("माहिती Reject — दुरुस्ती प्रलंबित");

    private final String heading;

    AlertCriterion(String heading) {
        this.heading = heading;
    }

    /** Marathi heading used as {{1}} of the WhatsApp template. */
    public String getHeading() {
        return heading;
    }

    /** Parse a key from the request, or null when it is missing/unknown. */
    public static AlertCriterion from(String key) {
        if (key == null) return null;
        try {
            return valueOf(key.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /**
     * SQL condition selecting the schools in this bucket, in terms of three per-school aggregate
     * column names. Safe to concatenate: the arguments are column names chosen by the caller, never
     * user input.
     *
     * NOT_STARTED is excluded from BELOW_25 / BELOW_50 (via {@code done > 0}) so a school that has
     * not begun is chased under its own heading only, not under three at once.
     *
     * @param doneCol     count of students saved in this phase
     * @param totalCol    phase roster size (see {@link PhaseRosterSql})
     * @param approvalCol phase_approvals.approval_status for this school and phase
     */
    public String sqlCondition(String doneCol, String totalCol, String approvalCol) {
        String pct = "ROUND(" + doneCol + " * 100.0 / " + totalCol + ")";
        switch (this) {
            case NOT_STARTED:
                return totalCol + " > 0 AND " + doneCol + " = 0";
            case BELOW_25:
                return totalCol + " > 0 AND " + doneCol + " > 0 AND " + pct + " < 25";
            case BELOW_50:
                return totalCol + " > 0 AND " + doneCol + " > 0 AND " + pct + " < 50";
            case PENDING_APPROVAL:
                return totalCol + " > 0 AND " + doneCol + " = " + totalCol
                     + " AND (" + approvalCol + " IS NULL OR " + approvalCol + " <> 'APPROVED')";
            case REJECTED:
                return approvalCol + " = 'REJECTED'";
            default:
                throw new IllegalStateException("Unhandled criterion: " + this);
        }
    }
}
