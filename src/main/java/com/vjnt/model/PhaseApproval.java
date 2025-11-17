package com.vjnt.model;

import java.util.Date;

/**
 * PhaseApproval Model
 * Represents phase completion and approval status
 */
public class PhaseApproval {
    
    public enum ApprovalStatus {
        PENDING,
        APPROVED,
        REJECTED
    }
    
    private int approvalId;
    private String udiseNo;
    private int phaseNumber;
    
    // Completion Info
    private String completedBy;
    private Date completedDate;
    private String completionRemarks;
    
    // Approval Info
    private ApprovalStatus approvalStatus;
    private String approvedBy;
    private Date approvedDate;
    private String approvalRemarks;
    
    // Student Statistics
    private int totalStudents;
    private int completedStudents;
    private int pendingStudents;
    private int ignoredStudents;
    
    // Audit
    private Date createdDate;
    private Date updatedDate;
    
    // Constructors
    public PhaseApproval() {
        this.approvalStatus = ApprovalStatus.PENDING;
    }
    
    public PhaseApproval(String udiseNo, int phaseNumber) {
        this.udiseNo = udiseNo;
        this.phaseNumber = phaseNumber;
        this.approvalStatus = ApprovalStatus.PENDING;
    }
    
    // Getters and Setters
    public int getApprovalId() {
        return approvalId;
    }
    
    public void setApprovalId(int approvalId) {
        this.approvalId = approvalId;
    }
    
    public String getUdiseNo() {
        return udiseNo;
    }
    
    public void setUdiseNo(String udiseNo) {
        this.udiseNo = udiseNo;
    }
    
    public int getPhaseNumber() {
        return phaseNumber;
    }
    
    public void setPhaseNumber(int phaseNumber) {
        this.phaseNumber = phaseNumber;
    }
    
    public String getCompletedBy() {
        return completedBy;
    }
    
    public void setCompletedBy(String completedBy) {
        this.completedBy = completedBy;
    }
    
    public Date getCompletedDate() {
        return completedDate;
    }
    
    public void setCompletedDate(Date completedDate) {
        this.completedDate = completedDate;
    }
    
    public String getCompletionRemarks() {
        return completionRemarks;
    }
    
    public void setCompletionRemarks(String completionRemarks) {
        this.completionRemarks = completionRemarks;
    }
    
    public ApprovalStatus getApprovalStatus() {
        return approvalStatus;
    }
    
    public void setApprovalStatus(ApprovalStatus approvalStatus) {
        this.approvalStatus = approvalStatus;
    }
    
    public String getApprovedBy() {
        return approvedBy;
    }
    
    public void setApprovedBy(String approvedBy) {
        this.approvedBy = approvedBy;
    }
    
    public Date getApprovedDate() {
        return approvedDate;
    }
    
    public void setApprovedDate(Date approvedDate) {
        this.approvedDate = approvedDate;
    }
    
    public String getApprovalRemarks() {
        return approvalRemarks;
    }
    
    public void setApprovalRemarks(String approvalRemarks) {
        this.approvalRemarks = approvalRemarks;
    }
    
    public int getTotalStudents() {
        return totalStudents;
    }
    
    public void setTotalStudents(int totalStudents) {
        this.totalStudents = totalStudents;
    }
    
    public int getCompletedStudents() {
        return completedStudents;
    }
    
    public void setCompletedStudents(int completedStudents) {
        this.completedStudents = completedStudents;
    }
    
    public int getPendingStudents() {
        return pendingStudents;
    }
    
    public void setPendingStudents(int pendingStudents) {
        this.pendingStudents = pendingStudents;
    }
    
    public int getIgnoredStudents() {
        return ignoredStudents;
    }
    
    public void setIgnoredStudents(int ignoredStudents) {
        this.ignoredStudents = ignoredStudents;
    }
    
    public Date getCreatedDate() {
        return createdDate;
    }
    
    public void setCreatedDate(Date createdDate) {
        this.createdDate = createdDate;
    }
    
    public Date getUpdatedDate() {
        return updatedDate;
    }
    
    public void setUpdatedDate(Date updatedDate) {
        this.updatedDate = updatedDate;
    }
    
    // Helper Methods
    public boolean isPending() {
        return approvalStatus == ApprovalStatus.PENDING;
    }
    
    public boolean isApproved() {
        return approvalStatus == ApprovalStatus.APPROVED;
    }
    
    public boolean isRejected() {
        return approvalStatus == ApprovalStatus.REJECTED;
    }
    
    public int getCompletionPercentage() {
        if (totalStudents == 0) return 0;
        return (int) ((completedStudents * 100.0) / (totalStudents - ignoredStudents));
    }
    
    @Override
    public String toString() {
        return "PhaseApproval{" +
                "approvalId=" + approvalId +
                ", udiseNo='" + udiseNo + '\'' +
                ", phaseNumber=" + phaseNumber +
                ", approvalStatus=" + approvalStatus +
                ", completedStudents=" + completedStudents +
                ", totalStudents=" + totalStudents +
                '}';
    }
}
