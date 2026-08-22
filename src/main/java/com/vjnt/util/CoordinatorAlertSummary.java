package com.vjnt.util;

import java.util.EnumMap;
import java.util.Map;

/**
 * The figures one coordinator message is built from: how many schools sit in each bucket for one
 * district or one division, out of how many schools, at what overall progress.
 *
 * One object serves both grains. A DIVISION summary is the sum of its districts' rows, not a
 * separately-derived number, so a division officer and their district coordinators can never be
 * quoted totals that disagree.
 *
 * Progress is computed from the roster totals rather than averaging the districts' percentages —
 * averaging would weight a 12-school district the same as a 300-school one.
 */
public class CoordinatorAlertSummary {

    private final AlertScope scope;
    private final String name;
    private final String divisionName;
    private final int phase;

    private int totalSchools;
    private long rosterTotal;
    private long rosterDone;
    private final Map<AlertCriterion, Integer> counts = new EnumMap<>(AlertCriterion.class);

    /**
     * @param scope        DISTRICT or DIVISION
     * @param name         the district name, or the division name
     * @param divisionName owning division; equal to {@code name} at DIVISION scope
     */
    public CoordinatorAlertSummary(AlertScope scope, String name, String divisionName, int phase) {
        this.scope = scope;
        this.name = name;
        this.divisionName = divisionName;
        this.phase = PhaseRosterSql.validatePhase(phase);
        for (AlertCriterion c : AlertCriterion.values()) {
            counts.put(c, 0);
        }
    }

    public AlertScope getScope() { return scope; }
    public String getName() { return name; }
    public String getDivisionName() { return divisionName; }
    public int getPhase() { return phase; }

    /** District name for a DISTRICT summary; null at DIVISION scope, where many districts are in play. */
    public String getDistrictName() {
        return scope == AlertScope.DISTRICT ? name : null;
    }

    public int getTotalSchools() { return totalSchools; }
    public void setTotalSchools(int totalSchools) { this.totalSchools = totalSchools; }

    public long getRosterTotal() { return rosterTotal; }
    public void setRosterTotal(long rosterTotal) { this.rosterTotal = rosterTotal; }

    public long getRosterDone() { return rosterDone; }
    public void setRosterDone(long rosterDone) { this.rosterDone = rosterDone; }

    public int getCount(AlertCriterion criterion) {
        Integer value = counts.get(criterion);
        return value == null ? 0 : value;
    }

    public void setCount(AlertCriterion criterion, int value) {
        counts.put(criterion, value);
    }

    /**
     * Schools in the bucket this alert type reports on.
     *
     * Undefined for a roll-up, which reports every bucket at once — callers building a bucket
     * sentence must not reach here with STATUS_REPORT, so it fails loudly rather than quietly
     * returning zero and sending "0 शाळांनी काम सुरू केलेले नाही".
     */
    public int getCount(CoordinatorAlertType type) {
        if (type.isRollUp()) {
            throw new IllegalArgumentException("STATUS_REPORT has no single bucket count");
        }
        return getCount(type.getCriterion());
    }

    /**
     * Overall progress as a whole percentage, on the same rounding the schools and the division
     * table already display — see {@link AlertCriterion}, which buckets on the rounded value too.
     */
    public int getProgressPercentage() {
        return rosterTotal > 0 ? (int) Math.round(rosterDone * 100.0 / rosterTotal) : 0;
    }

    /** Fold another summary into this one. Used to build a DIVISION total from its districts. */
    public void add(CoordinatorAlertSummary other) {
        totalSchools += other.totalSchools;
        rosterTotal  += other.rosterTotal;
        rosterDone   += other.rosterDone;
        for (AlertCriterion c : AlertCriterion.values()) {
            counts.put(c, getCount(c) + other.getCount(c));
        }
    }

    /**
     * "लातूर जिल्ह्यातील" / "लातूर विभागातील" — the phrase every message opens its figures with.
     * Marathi needs the locative form, so this cannot be assembled from the name and a fixed suffix
     * at the call site without getting it wrong at one of the two grains.
     */
    public String getScopePhrase() {
        return scope == AlertScope.DIVISION
                ? name + " विभागातील"
                : name + " जिल्ह्यातील";
    }

    /** "जिल्ह्यातील एकूण शाळा" / "विभागातील एकूण शाळा" — used without the name, after getScopePhrase(). */
    public String getTotalLabel() {
        return scope == AlertScope.DIVISION ? "विभागातील एकूण शाळा" : "जिल्ह्यातील एकूण शाळा";
    }
}
