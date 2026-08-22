package com.vjnt.util;

/**
 * Per-school phase figures, and the condition that puts a school in one {@link AlertCriterion}
 * bucket, as SQL fragments.
 *
 * Extracted from DivisionCriteriaAlertServlet, where it was private, because the coordinator alerts
 * console needs the identical numbers at a coarser grain. Two copies of this would be two answers to
 * "how many schools in लातूर have not started चरण 1" — one in the message sent to the school and a
 * different one in the message sent to the officer chasing it. That is the whole reason the roster
 * predicates were centralised in {@link PhaseRosterSql}; the same argument applies one level up.
 *
 * Callers pair the two: build a derived table with {@link #schoolPhaseSubquery} and filter or
 * aggregate it with {@link #bucketCondition}.
 */
public final class PhaseBucketSql {

    /** Column names the subquery exposes, which {@link #bucketCondition} is written against. */
    public static final String COL_TOTAL    = "p_total";
    public static final String COL_DONE     = "p_done";
    public static final String COL_APPROVAL = "approval_status";

    private PhaseBucketSql() { }

    /**
     * Per-school phase figures for every school in scope: udise_no, school_name, district_name,
     * {@value #COL_TOTAL}, {@value #COL_DONE}, {@value #COL_APPROVAL}.
     *
     * The roster and saved counts are computed in a derived table over students alone, so the
     * LEFT JOIN to phase_approvals (one row per phase) cannot multiply them. is_active = 1 and the
     * class I-IX restriction sit inside that derived table rather than in the outer WHERE so schools
     * with no active students still appear — with zero counts — instead of vanishing. School counts
     * therefore come from the schools master and phase state from phase_approvals; students only
     * ever contributes the per-school roster figures.
     *
     * Phase is validated 1-4 and concatenated; the two optional filters are bound by the caller in
     * order: division first, then district.
     *
     * @param filterDivision add "AND district IN (districts of ?)" — bind the division name
     * @param filterDistrict add "AND district_name = ?"            — bind the district name
     */
    public static String schoolPhaseSubquery(int phase, boolean filterDivision, boolean filterDistrict) {
        PhaseRosterSql.validatePhase(phase);
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT s.udise_no, s.school_name, s.district_name, ")
           .append("COALESCE(stu.p_total, 0) AS ").append(COL_TOTAL).append(", ")
           .append("COALESCE(stu.p_done, 0) AS ").append(COL_DONE).append(", ")
           .append("MAX(CASE WHEN pa.phase_number = ").append(phase)
           .append(" THEN pa.approval_status END) AS ").append(COL_APPROVAL).append(" ")
           .append("FROM schools s ")
           .append("LEFT JOIN (SELECT udise_no, ")
           .append(PhaseRosterSql.rosterCount(null, phase, "p_total")).append(", ")
           .append(PhaseRosterSql.savedCount(null, phase, "p_done"))
           .append(" FROM students WHERE is_active = 1 AND ")
           .append(PhaseRosterSql.inScopeClass(null))
           .append(" GROUP BY udise_no) stu ")
           .append("ON s.udise_no COLLATE utf8mb4_unicode_ci = stu.udise_no COLLATE utf8mb4_unicode_ci ")
           .append("LEFT JOIN phase_approvals pa ")
           .append("ON s.udise_no COLLATE utf8mb4_unicode_ci = pa.udise_no COLLATE utf8mb4_unicode_ci ")
           .append("WHERE 1=1 ");

        if (filterDivision) {
            sql.append("AND s.district_name COLLATE utf8mb4_unicode_ci IN ")
               .append("(SELECT DISTINCT district COLLATE utf8mb4_unicode_ci FROM students WHERE division = ?) ");
        }
        if (filterDistrict) {
            sql.append("AND s.district_name COLLATE utf8mb4_unicode_ci = ? COLLATE utf8mb4_unicode_ci ");
        }

        sql.append("GROUP BY s.udise_no, s.school_name, s.district_name, stu.p_total, stu.p_done");
        return sql.toString();
    }

    /**
     * Criterion condition expressed over the column names {@link #schoolPhaseSubquery} exposes,
     * parenthesised so it can be dropped into a WHERE or a SUM(CASE WHEN ...) without precedence
     * surprises.
     */
    public static String bucketCondition(AlertCriterion criterion) {
        return "(" + criterion.sqlCondition(COL_DONE, COL_TOTAL, COL_APPROVAL) + ")";
    }
}
