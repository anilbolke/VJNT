package com.vjnt.util;

/**
 * The one definition of "which students count towards a phase", as SQL fragments.
 *
 * Every screen that reports phase progress — the school's चरण अहवाल card, the district phase-status
 * table, the division/super-division phase status, and the criteria alerts — must divide by the same
 * set of students, otherwise one school reads 100% to its coordinator and 99% to the officer chasing
 * it. That set is:
 *
 *   roster = active students who are NOT yet FLN complete, PLUS anyone already saved in this phase
 *   saved  = students whose phase{N}_date is set, i.e. Save was clicked for them
 *
 * The "already saved in this phase" term matters because saving a student at Marathi 6 / Math 8 /
 * English 6 flags them fln_completed immediately; without it they would vanish from the denominator
 * of the very phase they were just completed in. They leave the roster when the next phase starts.
 *
 * Note what "saved" deliberately does NOT require: all three subject levels. Choosing a subject is
 * optional (see StudentDAO.updatePhaseLanguageLevels), so demanding all three excluded students the
 * coordinator had genuinely dealt with and capped schools below 100%.
 *
 * These used to be three hand-maintained copies of the same predicate, which is exactly how they
 * drifted apart. Add call sites here, not new copies.
 */
public final class PhaseRosterSql {

    /**
     * The classes the FLN programme covers. Anything else on a student row (class X, a blank,
     * a NULL, an import artefact) is outside the programme and must not reach any phase figure.
     *
     * Both spellings are listed because the class column genuinely holds both — the promotion
     * logic has always handled Roman and Arabic side by side. Matching only Roman would quietly
     * drop every Arabic-stored student.
     *
     * This is the canonical copy; com.vjnt.dao.StudentDAO.CLASS_I_TO_IX points here rather than
     * keeping a second list, for the same reason the roster predicates live in this class.
     */
    public static final String CLASS_I_TO_IX =
            "('I','II','III','IV','V','VI','VII','VIII','IX'," +
            "'1','2','3','4','5','6','7','8','9')";

    private PhaseRosterSql() { }

    /**
     * "inside the programme", i.e. class I-IX. TRIM because stray whitespace in the class column
     * is exactly the sort of import artefact that would otherwise drop a real student.
     *
     * @param alias table alias to qualify the column with ("st"), or null/empty when the query has
     *              only one table in scope
     */
    public static String inScopeClass(String alias) {
        return "TRIM(" + prefix(alias) + "class) IN " + CLASS_I_TO_IX;
    }

    /** Phase must be 1-4 — it is concatenated into SQL, never bound. */
    public static int validatePhase(int phase) {
        if (phase < 1 || phase > 4) {
            throw new IllegalArgumentException("Invalid phase: " + phase);
        }
        return phase;
    }

    /**
     * "still to be assessed", i.e. not yet flagged FLN complete.
     *
     * @param alias table alias to qualify the column with ("st"), or null/empty when the query has
     *              only one table in scope
     */
    public static String notFlnCompleted(String alias) {
        String p = prefix(alias);
        return "(" + p + "fln_completed IS NULL OR " + p + "fln_completed = FALSE)";
    }

    /** phase{N}_date IS NOT NULL — Save was clicked for this student in this phase. */
    public static String savedPredicate(String alias, int phase) {
        return prefix(alias) + "phase" + validatePhase(phase) + "_date IS NOT NULL";
    }

    /** Membership of the roster the coordinator has to work through for one phase. */
    public static String rosterPredicate(String alias, int phase) {
        return "(" + notFlnCompleted(alias) + " OR " + savedPredicate(alias, phase) + ")";
    }

    /** Roster size as a SELECT-list item. Use in queries where one row = one student. */
    public static String rosterCount(String alias, int phase, String outAlias) {
        return "COUNT(CASE WHEN " + rosterPredicate(alias, phase) + " THEN 1 END) AS " + outAlias;
    }

    /**
     * Roster size for queries whose joins fan a student out over several rows (a LEFT JOIN to
     * phase_approvals, for instance), where a plain COUNT would multiply.
     */
    public static String rosterCountDistinct(String alias, int phase, String idColumn, String outAlias) {
        return "COUNT(DISTINCT CASE WHEN " + rosterPredicate(alias, phase)
                + " THEN " + idColumn + " END) AS " + outAlias;
    }

    /** Saved count as a SELECT-list item. Use in queries where one row = one student. */
    public static String savedCount(String alias, int phase, String outAlias) {
        return "SUM(CASE WHEN " + savedPredicate(alias, phase) + " THEN 1 ELSE 0 END) AS " + outAlias;
    }

    /** Saved count for fan-out queries — see {@link #rosterCountDistinct}. */
    public static String savedCountDistinct(String alias, int phase, String idColumn, String outAlias) {
        return "COUNT(DISTINCT CASE WHEN " + savedPredicate(alias, phase)
                + " THEN " + idColumn + " END) AS " + outAlias;
    }

    private static String prefix(String alias) {
        return (alias == null || alias.trim().isEmpty()) ? "" : alias.trim() + ".";
    }
}
