package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Shared class-progression rules for promotion.
 *
 * Before August 2026 the graduating class was the hardcoded constant ('IX','9') in
 * PromoteClassesServlet and TestPromoteServlet. Not every school runs to Class IX — some end
 * at V, VII or VIII — so in those schools the top class was promoted into a class that does not
 * exist there, stayed active, and never reached graduated_students.
 *
 * The terminal class is now resolved per school:
 *
 *   1. schools.max_class, if the Data Admin has set it   (authoritative)
 *   2. otherwise the highest class that school currently has active students in  (derived)
 *
 * The derived fallback means a school with no max_class still behaves correctly. It is only
 * wrong for a school that genuinely runs to IX but happens to have no IX students this year —
 * which is exactly the case max_class exists to pin down.
 *
 * NOTE: students.class holds BOTH Roman ('VII') and Arabic ('7') numerals. Every comparison
 * here normalises both forms to an integer rank. Never compare or MAX() the raw string:
 * MAX('VIII','IX') returns 'VIII' because it is a lexical comparison.
 */
public final class PromotionClassRules {

    private PromotionClassRules() {}

    /** Highest supported class rank (Class IX). */
    public static final int MAX_RANK = 9;

    /** SQL: normalise a class column (Roman or Arabic) to an integer rank; 0 when unrecognised. */
    public static String rank(String col) {
        return "CASE " + col + " " +
               "WHEN 'I'   THEN 1 WHEN '1' THEN 1 WHEN 'II'   THEN 2 WHEN '2' THEN 2 " +
               "WHEN 'III' THEN 3 WHEN '3' THEN 3 WHEN 'IV'   THEN 4 WHEN '4' THEN 4 " +
               "WHEN 'V'   THEN 5 WHEN '5' THEN 5 WHEN 'VI'   THEN 6 WHEN '6' THEN 6 " +
               "WHEN 'VII' THEN 7 WHEN '7' THEN 7 WHEN 'VIII' THEN 8 WHEN '8' THEN 8 " +
               "WHEN 'IX'  THEN 9 WHEN '9' THEN 9 ELSE 0 END";
    }

    /** SQL: map a class column to the next class up. Terminal handling is the caller's job. */
    public static String nextClassCase(String col) {
        return "CASE " + col + " " +
               "WHEN 'I'    THEN 'II'   WHEN 'II'   THEN 'III'  WHEN 'III'  THEN 'IV' " +
               "WHEN 'IV'   THEN 'V'    WHEN 'V'    THEN 'VI'   WHEN 'VI'   THEN 'VII' " +
               "WHEN 'VII'  THEN 'VIII' WHEN 'VIII' THEN 'IX' " +
               "WHEN '1' THEN '2' WHEN '2' THEN '3' WHEN '3' THEN '4' WHEN '4' THEN '5' " +
               "WHEN '5' THEN '6' WHEN '6' THEN '7' WHEN '7' THEN '8' WHEN '8' THEN '9' " +
               "ELSE " + col + " END";
    }

    /** Cached result of the schools.max_class probe; null until first checked. */
    private static volatile Boolean maxClassColumnPresent;

    /**
     * Whether schools.max_class exists yet.
     *
     * The column ships in ADD_SCHOOL_MAX_CLASS_2026-08-06.sql. Deploying the code before running
     * that script is a realistic ordering, so every query degrades to the derived terminal class
     * instead of failing. Result is cached for the life of the JVM — restart after the ALTER.
     */
    public static boolean hasMaxClassColumn(Connection conn) {
        Boolean cached = maxClassColumnPresent;
        if (cached != null) return cached;
        boolean present = false;
        try (ResultSet rs = conn.getMetaData().getColumns(conn.getCatalog(), null, "schools", "max_class")) {
            present = rs.next();
        } catch (SQLException e) {
            System.err.println("PromotionClassRules: could not probe schools.max_class, " +
                               "falling back to derived terminal class: " + e.getMessage());
        }
        if (!present) {
            System.out.println("PromotionClassRules: schools.max_class not present — terminal class " +
                               "will be derived from each school's highest active class. " +
                               "Run ADD_SCHOOL_MAX_CLASS_2026-08-06.sql to pin it down.");
        }
        maxClassColumnPresent = present;
        return present;
    }

    /**
     * Derived table: one row per school with its terminal class rank.
     * Alias it as {@code t} and join on {@code t.udise_no}.
     *
     * schools.udise_no is utf8mb4_0900_ai_ci while students.udise_no is utf8mb4_unicode_ci,
     * so the join carries an explicit COLLATE or MySQL raises "Illegal mix of collations".
     */
    public static String terminalSubquery(boolean hasMaxClass) {
        if (!hasMaxClass) {
            return "SELECT s.udise_no AS udise_no, " +
                   "       MAX(" + rank("s.class") + ") AS terminal_rank " +
                   "FROM students s WHERE s.is_active = 1 GROUP BY s.udise_no";
        }
        return "SELECT s.udise_no AS udise_no, " +
               "       COALESCE(NULLIF(MAX(" + rank("sc.max_class") + "),0), " +
               "                MAX(" + rank("s.class") + ")) AS terminal_rank " +
               "FROM students s " +
               "LEFT JOIN schools sc ON sc.udise_no COLLATE utf8mb4_unicode_ci = s.udise_no " +
               "WHERE s.is_active = 1 " +
               "GROUP BY s.udise_no";
    }

    /** Terminal rank for a single school, honouring max_class when the column exists. */
    public static int terminalRankFor(Connection conn, String udise) throws SQLException {
        boolean hasMax = hasMaxClassColumn(conn);
        String sql = hasMax
            ? "SELECT COALESCE(NULLIF(MAX(" + rank("sc.max_class") + "),0), " +
              "                MAX(" + rank("s.class") + ")) AS tr " +
              "FROM students s " +
              "LEFT JOIN schools sc ON sc.udise_no COLLATE utf8mb4_unicode_ci = s.udise_no " +
              "WHERE s.is_active=1 AND s.udise_no=?"
            : "SELECT MAX(" + rank("s.class") + ") AS tr " +
              "FROM students s WHERE s.is_active=1 AND s.udise_no=?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, udise);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("tr");
            }
        }
        return 0;
    }

    /** SQL predicate: this student sits at or above their school's terminal class. */
    public static String isGraduating(String classCol, String terminalRankCol) {
        return "(" + rank(classCol) + ") > 0 AND (" + rank(classCol) + ") >= " + terminalRankCol;
    }

    /** SQL predicate: this student is below their school's terminal class. */
    public static String isPromoting(String classCol, String terminalRankCol) {
        return "(" + rank(classCol) + ") > 0 AND (" + rank(classCol) + ") < " + terminalRankCol;
    }

    /** SQL: the class_after archive label — 'GRADUATED' at the terminal class, else next class. */
    public static String classAfterCase(String classCol, String terminalRankCol) {
        return "CASE WHEN " + isGraduating(classCol, terminalRankCol) +
               " THEN 'GRADUATED' ELSE " + nextClassCase(classCol) + " END";
    }

    /** Integer rank → Roman label. */
    public static String roman(int r) {
        switch (r) {
            case 1: return "I";
            case 2: return "II";
            case 3: return "III";
            case 4: return "IV";
            case 5: return "V";
            case 6: return "VI";
            case 7: return "VII";
            case 8: return "VIII";
            case 9: return "IX";
            default: return "?";
        }
    }

    /** Class label (Roman or Arabic) → integer rank; 0 when unrecognised. Mirrors {@link #rank}. */
    public static int rankOf(String cls) {
        if (cls == null) return 0;
        switch (cls.trim()) {
            case "I":    case "1": return 1;
            case "II":   case "2": return 2;
            case "III":  case "3": return 3;
            case "IV":   case "4": return 4;
            case "V":    case "5": return 5;
            case "VI":   case "6": return 6;
            case "VII":  case "7": return 7;
            case "VIII": case "8": return 8;
            case "IX":   case "9": return 9;
            default: return 0;
        }
    }

    /** Next class label for display; returns the input unchanged when unrecognised. */
    public static String nextClass(String cls) {
        int r = rankOf(cls);
        if (r == 0 || r >= MAX_RANK) return cls;
        boolean arabic = cls != null && cls.trim().matches("\\d+");
        return arabic ? String.valueOf(r + 1) : roman(r + 1);
    }
}
