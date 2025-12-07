package com.vjnt.model;

import java.sql.Timestamp;

/**
 * SchoolContact Model
 * Represents contact information for School Coordinators and Head Masters
 * This is NOT a login user - just contact/directory information
 */
public class SchoolContact {
    
    private int contactId;
    private String udiseNo;
    private String schoolName;
    private String districtName;
    private String contactType; // "School Coordinator" or "Head Master"
    private String fullName;
    private String mobile;
    private String whatsappNumber;
    private String remarks;
    private Timestamp createdDate;
    private String createdBy;
    private Timestamp updatedDate;
    private String updatedBy;
    
    // Constructors
    public SchoolContact() {
    }
    
    public SchoolContact(String udiseNo, String contactType, String fullName, String mobile) {
        this.udiseNo = udiseNo;
        this.contactType = contactType;
        this.fullName = fullName;
        this.mobile = mobile;
    }
    
    // Getters and Setters
    public int getContactId() {
        return contactId;
    }
    
    public void setContactId(int contactId) {
        this.contactId = contactId;
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
    
    public String getDistrictName() {
        return districtName;
    }
    
    public void setDistrictName(String districtName) {
        this.districtName = districtName;
    }
    
    public String getContactType() {
        return contactType;
    }
    
    public void setContactType(String contactType) {
        this.contactType = contactType;
    }
    
    public String getFullName() {
        return fullName;
    }
    
    public void setFullName(String fullName) {
        this.fullName = fullName;
    }
    
    public String getMobile() {
        return mobile;
    }
    
    public void setMobile(String mobile) {
        this.mobile = mobile;
    }
    
    public String getWhatsappNumber() {
        return whatsappNumber;
    }
    
    public void setWhatsappNumber(String whatsappNumber) {
        this.whatsappNumber = whatsappNumber;
    }
    
    public String getRemarks() {
        return remarks;
    }
    
    public void setRemarks(String remarks) {
        this.remarks = remarks;
    }
    
    public Timestamp getCreatedDate() {
        return createdDate;
    }
    
    public void setCreatedDate(Timestamp createdDate) {
        this.createdDate = createdDate;
    }
    
    public String getCreatedBy() {
        return createdBy;
    }
    
    public void setCreatedBy(String createdBy) {
        this.createdBy = createdBy;
    }
    
    public Timestamp getUpdatedDate() {
        return updatedDate;
    }
    
    public void setUpdatedDate(Timestamp updatedDate) {
        this.updatedDate = updatedDate;
    }
    
    public String getUpdatedBy() {
        return updatedBy;
    }
    
    public void setUpdatedBy(String updatedBy) {
        this.updatedBy = updatedBy;
    }
    
    @Override
    public String toString() {
        return "SchoolContact{" +
                "contactId=" + contactId +
                ", udiseNo='" + udiseNo + '\'' +
                ", contactType='" + contactType + '\'' +
                ", fullName='" + fullName + '\'' +
                ", mobile='" + mobile + '\'' +
                '}';
    }
}
