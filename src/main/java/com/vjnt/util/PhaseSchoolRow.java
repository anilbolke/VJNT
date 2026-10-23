package com.vjnt.util;

import java.util.EnumSet;
import java.util.Set;

/**
 * One school's position in one phase: the row behind both the console list and a line of the PDF.
 *
 * Carries the set of buckets the school falls into rather than a single criterion, because the status
 * report lists every school with a mark per bucket, and because BELOW_25 and BELOW_50 deliberately
 * nest — a school at 10% is in both, and a row that could only name one would have to pick.
 */
public class PhaseSchoolRow {

    private String udiseNo;
    private String schoolName;
    private String districtName;
    private int total;
    private int done;
    private String approvalStatus;

    private final Set<AlertCriterion> buckets = EnumSet.noneOf(AlertCriterion.class);

    public String getUdiseNo() { return udiseNo; }
    public void setUdiseNo(String udiseNo) { this.udiseNo = udiseNo; }

    public String getSchoolName() { return schoolName; }
    public void setSchoolName(String schoolName) { this.schoolName = schoolName; }

    public String getDistrictName() { return districtName; }
    public void setDistrictName(String districtName) { this.districtName = districtName; }

    public int getTotal() { return total; }
    public void setTotal(int total) { this.total = total; }

    public int getDone() { return done; }
    public void setDone(int done) { this.done = done; }

    public String getApprovalStatus() { return approvalStatus; }
    public void setApprovalStatus(String approvalStatus) { this.approvalStatus = approvalStatus; }

    public Set<AlertCriterion> getBuckets() { return buckets; }
    public void addBucket(AlertCriterion criterion) { buckets.add(criterion); }
    public boolean isIn(AlertCriterion criterion) { return buckets.contains(criterion); }

    /**
     * Progress on the same rounding the school's own चरण अहवाल card shows — see
     * {@link AlertCriterion}, which buckets on the rounded value for exactly this reason.
     */
    public int getPercentage() {
        return total > 0 ? (int) Math.round(done * 100.0 / total) : 0;
    }

    /** Students still to be assessed in this phase. */
    public int getRemaining() {
        return Math.max(total - done, 0);
    }

    /** School name, falling back to the UDISE — schools.school_name is blank for a few rows. */
    public String getDisplayName() {
        if (schoolName != null && !schoolName.trim().isEmpty()) {
            return schoolName.trim();
        }
        return "UDISE " + (udiseNo == null ? "" : udiseNo);
    }

    /** Approval status in Marathi for the PDF; an em dash when the school has not submitted. */
    public String getApprovalLabel() {
        if (approvalStatus == null || approvalStatus.trim().isEmpty()) {
            return "—";
        }
        switch (approvalStatus.trim().toUpperCase()) {
            case "APPROVED": return "मंजूर";
            case "REJECTED": return "नामंजूर";
            case "PENDING":  return "प्रलंबित";
            default:         return approvalStatus.trim();
        }
    }
}
