package com.vjnt.model;

import java.sql.Timestamp;

public class ReportApproval {
    private int approvalId;
    private String reportType;
    private String penNumber;
    private String studentName;
    private String studentClass;
    private String section;
    private String udiseCode;
    private String schoolName;
    private String district;
    private String division;
    private int requestedBy;
    private String requestedByName;
    private Timestamp requestedDate;
    private String approvalStatus; // PENDING, APPROVED, REJECTED
    private int approvedBy;
    private String approvedByName;
    private Timestamp approvalDate;
    private String approvalRemarks;
    private boolean reportGenerated;
    private Timestamp generatedDate;
    private boolean isActive;
    
    // Constructors
    public ReportApproval() {
    }
    
    public ReportApproval(String reportType, String penNumber, String studentName,
                         String studentClass, String section, String udiseCode,
                         String schoolName, String district, String division, int requestedBy) {
        this.reportType = reportType;
        this.penNumber = penNumber;
        this.studentName = studentName;
        this.studentClass = studentClass;
        this.section = section;
        this.udiseCode = udiseCode;
        this.schoolName = schoolName;
        this.district = district;
        this.division = division;
        this.requestedBy = requestedBy;
        this.approvalStatus = "PENDING";
        this.reportGenerated = false;
        this.isActive = true;
    }
    
    // Getters and Setters
    public int getApprovalId() {
        return approvalId;
    }
    
    public void setApprovalId(int approvalId) {
        this.approvalId = approvalId;
    }
    
    public String getReportType() {
        return reportType;
    }
    
    public void setReportType(String reportType) {
        this.reportType = reportType;
    }
    
    public String getPenNumber() {
        return penNumber;
    }
    
    public void setPenNumber(String penNumber) {
        this.penNumber = penNumber;
    }
    
    public String getStudentName() {
        return studentName;
    }
    
    public void setStudentName(String studentName) {
        this.studentName = studentName;
    }
    
    public String getStudentClass() {
        return studentClass;
    }
    
    public void setStudentClass(String studentClass) {
        this.studentClass = studentClass;
    }
    
    public String getSection() {
        return section;
    }
    
    public void setSection(String section) {
        this.section = section;
    }
    
    public String getUdiseCode() {
        return udiseCode;
    }
    
    public void setUdiseCode(String udiseCode) {
        this.udiseCode = udiseCode;
    }
    
    public String getSchoolName() {
        return schoolName;
    }
    
    public void setSchoolName(String schoolName) {
        this.schoolName = schoolName;
    }
    
    public String getDistrict() {
        return district;
    }
    
    public void setDistrict(String district) {
        this.district = district;
    }
    
    public String getDivision() {
        return division;
    }
    
    public void setDivision(String division) {
        this.division = division;
    }
    
    public int getRequestedBy() {
        return requestedBy;
    }
    
    public void setRequestedBy(int requestedBy) {
        this.requestedBy = requestedBy;
    }
    
    public String getRequestedByName() {
        return requestedByName;
    }
    
    public void setRequestedByName(String requestedByName) {
        this.requestedByName = requestedByName;
    }
    
    public Timestamp getRequestedDate() {
        return requestedDate;
    }
    
    public void setRequestedDate(Timestamp requestedDate) {
        this.requestedDate = requestedDate;
    }
    
    public String getApprovalStatus() {
        return approvalStatus;
    }
    
    public void setApprovalStatus(String approvalStatus) {
        this.approvalStatus = approvalStatus;
    }
    
    public boolean isPending() {
        return "PENDING".equals(approvalStatus);
    }
    
    public boolean isApproved() {
        return "APPROVED".equals(approvalStatus);
    }
    
    public boolean isRejected() {
        return "REJECTED".equals(approvalStatus);
    }
    
    public int getApprovedBy() {
        return approvedBy;
    }
    
    public void setApprovedBy(int approvedBy) {
        this.approvedBy = approvedBy;
    }
    
    public String getApprovedByName() {
        return approvedByName;
    }
    
    public void setApprovedByName(String approvedByName) {
        this.approvedByName = approvedByName;
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
    
    public boolean isReportGenerated() {
        return reportGenerated;
    }
    
    public void setReportGenerated(boolean reportGenerated) {
        this.reportGenerated = reportGenerated;
    }
    
    public Timestamp getGeneratedDate() {
        return generatedDate;
    }
    
    public void setGeneratedDate(Timestamp generatedDate) {
        this.generatedDate = generatedDate;
    }
    
    public boolean isActive() {
        return isActive;
    }
    
    public void setActive(boolean active) {
        isActive = active;
    }
    
    @Override
    public String toString() {
        return "ReportApproval{" +
                "approvalId=" + approvalId +
                ", reportType='" + reportType + '\'' +
                ", penNumber='" + penNumber + '\'' +
                ", studentName='" + studentName + '\'' +
                ", approvalStatus='" + approvalStatus + '\'' +
                '}';
    }
}
