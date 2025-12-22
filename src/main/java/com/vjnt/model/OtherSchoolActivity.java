package com.vjnt.model;

import java.sql.Date;
import java.sql.Timestamp;

/**
 * Other School Activity Model
 * For various school activities that require headmaster approval
 */
public class OtherSchoolActivity {
    
    private int activityId;
    private String udiseNo;
    private String schoolName;
    
    // Activity Fields
    private Date activityDate;
    private String activitySubject; // Subject / उपक्रमाचे नाव
    private String guestsPresent; // उपस्थित पाहुणे
    private String description; // विवरण
    private String photo1Path;
    private String photo2Path;
    private String videoLink; // व्हिडओ लिंक
    
    // Image content stored in database (BLOB)
    private byte[] photo1Content;
    private byte[] photo2Content;
    private String photo1FileName;
    private String photo2FileName;
    
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
    public OtherSchoolActivity() {
    }
    
    // Getters and Setters
    public int getActivityId() {
        return activityId;
    }
    
    public void setActivityId(int activityId) {
        this.activityId = activityId;
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
    
    public Date getActivityDate() {
        return activityDate;
    }
    
    public void setActivityDate(Date activityDate) {
        this.activityDate = activityDate;
    }
    
    public String getActivitySubject() {
        return activitySubject;
    }
    
    public void setActivitySubject(String activitySubject) {
        this.activitySubject = activitySubject;
    }
    
    public String getGuestsPresent() {
        return guestsPresent;
    }
    
    public void setGuestsPresent(String guestsPresent) {
        this.guestsPresent = guestsPresent;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
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
    
    public String getVideoLink() {
        return videoLink;
    }
    
    public void setVideoLink(String videoLink) {
        this.videoLink = videoLink;
    }
    
    public byte[] getPhoto1Content() {
        return photo1Content;
    }
    
    public void setPhoto1Content(byte[] photo1Content) {
        this.photo1Content = photo1Content;
    }
    
    public byte[] getPhoto2Content() {
        return photo2Content;
    }
    
    public void setPhoto2Content(byte[] photo2Content) {
        this.photo2Content = photo2Content;
    }
    
    public String getPhoto1FileName() {
        return photo1FileName;
    }
    
    public void setPhoto1FileName(String photo1FileName) {
        this.photo1FileName = photo1FileName;
    }
    
    public String getPhoto2FileName() {
        return photo2FileName;
    }
    
    public void setPhoto2FileName(String photo2FileName) {
        this.photo2FileName = photo2FileName;
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
        return "PENDING_APPROVAL".equals(approvalStatus);
    }
    
    public boolean isApproved() {
        return "APPROVED".equals(approvalStatus);
    }
    
    public boolean isRejected() {
        return "REJECTED".equals(approvalStatus);
    }
    
    public boolean isDraft() {
        return "DRAFT".equals(status);
    }
}
