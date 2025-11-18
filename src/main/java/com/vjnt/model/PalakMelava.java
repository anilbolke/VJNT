package com.vjnt.model;

import java.sql.Date;
import java.sql.Time;
import java.sql.Timestamp;

/**
 * Palak Melava (Parent-Teacher Meeting) Model
 */
public class PalakMelava {
    
    private int melavaId;
    private String udiseNo;
    private String schoolName;
    
    // EXACT REQUIRED FIELDS ONLY
    private Date meetingDate;
    private String chiefAttendeeInfo;
    private String totalParentsAttended;
    private String photo1Path;
    private String photo2Path;
    
    // Approval Workflow
    private String status; // DRAFT, PENDING_APPROVAL, APPROVED, REJECTED
    private String submittedBy;
    private Timestamp submittedDate;
    
    private String approvalStatus;
    private String approvedBy;
    private Timestamp approvalDate;
    private String approvalRemarks;
    private String rejectionReason;
    
    // Audit
    private String createdBy;
    private Timestamp createdDate;
    private String updatedBy;
    private Timestamp updatedDate;
    
    // Constructors
    public PalakMelava() {
    }
    
    // Getters and Setters
    public int getMelavaId() {
        return melavaId;
    }
    
    public void setMelavaId(int melavaId) {
        this.melavaId = melavaId;
    }
    
    public String getUdiseNo() {
        return udiseNo;
    }
    
    public void setUdiseNo(String udiseNo) {
        this.udiseNo = udiseNo;
    }
    
    public String getSchoolName() {
        return schoolName;
    }
    
    public void setSchoolName(String schoolName) {
        this.schoolName = schoolName;
    }
    
    public Date getMeetingDate() {
        return meetingDate;
    }
    
    public void setMeetingDate(Date meetingDate) {
        this.meetingDate = meetingDate;
    }
    
    public String getChiefAttendeeInfo() {
        return chiefAttendeeInfo;
    }
    
    public void setChiefAttendeeInfo(String chiefAttendeeInfo) {
        this.chiefAttendeeInfo = chiefAttendeeInfo;
    }
    
    public String getTotalParentsAttended() {
        return totalParentsAttended;
    }
    
    public void setTotalParentsAttended(String totalParentsAttended) {
        this.totalParentsAttended = totalParentsAttended;
    }
    
    public String getPhoto1Path() {
        return photo1Path;
    }
    
    public void setPhoto1Path(String photo1Path) {
        this.photo1Path = photo1Path;
    }
    
    public String getPhoto2Path() {
        return photo2Path;
    }
    
    public void setPhoto2Path(String photo2Path) {
        this.photo2Path = photo2Path;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public String getSubmittedBy() {
        return submittedBy;
    }
    
    public void setSubmittedBy(String submittedBy) {
        this.submittedBy = submittedBy;
    }
    
    public Timestamp getSubmittedDate() {
        return submittedDate;
    }
    
    public void setSubmittedDate(Timestamp submittedDate) {
        this.submittedDate = submittedDate;
    }
    
    public String getApprovalStatus() {
        return approvalStatus;
    }
    
    public void setApprovalStatus(String approvalStatus) {
        this.approvalStatus = approvalStatus;
    }
    
    public String getApprovedBy() {
        return approvedBy;
    }
    
    public void setApprovedBy(String approvedBy) {
        this.approvedBy = approvedBy;
    }
    
    public Timestamp getApprovalDate() {
        return approvalDate;
    }
    
    public void setApprovalDate(Timestamp approvalDate) {
        this.approvalDate = approvalDate;
    }
    
    public String getApprovalRemarks() {
        return approvalRemarks;
    }
    
    public void setApprovalRemarks(String approvalRemarks) {
        this.approvalRemarks = approvalRemarks;
    }
    
    public String getRejectionReason() {
        return rejectionReason;
    }
    
    public void setRejectionReason(String rejectionReason) {
        this.rejectionReason = rejectionReason;
    }
    
    public String getCreatedBy() {
        return createdBy;
    }
    
    public void setCreatedBy(String createdBy) {
        this.createdBy = createdBy;
    }
    
    public Timestamp getCreatedDate() {
        return createdDate;
    }
    
    public void setCreatedDate(Timestamp createdDate) {
        this.createdDate = createdDate;
    }
    
    public String getUpdatedBy() {
        return updatedBy;
    }
    
    public void setUpdatedBy(String updatedBy) {
        this.updatedBy = updatedBy;
    }
    
    public Timestamp getUpdatedDate() {
        return updatedDate;
    }
    
    public void setUpdatedDate(Timestamp updatedDate) {
        this.updatedDate = updatedDate;
    }
    
    // Helper methods
    public boolean isPending() {
        return "PENDING_APPROVAL".equals(status);
    }
    
    public boolean isApproved() {
        return "APPROVED".equals(status);
    }
    
    public boolean isRejected() {
        return "REJECTED".equals(status);
    }
    
    public boolean isDraft() {
        return "DRAFT".equals(status);
    }
}
