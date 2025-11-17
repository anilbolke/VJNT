package com.vjnt.model;

import java.util.Date;

/**
 * School Model
 * Represents school master data (UDISE number and School Name mapping)
 */
public class School {
    
    private int schoolId;
    private String udiseNo;
    private String schoolName;
    private String districtName;
    private Date createdDate;
    private String createdBy;
    private Date updatedDate;
    private String updatedBy;
    
    // Constructors
    public School() {
    }
    
    public School(String udiseNo, String schoolName, String districtName) {
        this.udiseNo = udiseNo;
        this.schoolName = schoolName;
        this.districtName = districtName;
    }
    
    // Getters and Setters
    public int getSchoolId() {
        return schoolId;
    }
    
    public void setSchoolId(int schoolId) {
        this.schoolId = schoolId;
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
    
    public Date getCreatedDate() {
        return createdDate;
    }
    
    public void setCreatedDate(Date createdDate) {
        this.createdDate = createdDate;
    }
    
    public String getCreatedBy() {
        return createdBy;
    }
    
    public void setCreatedBy(String createdBy) {
        this.createdBy = createdBy;
    }
    
    public Date getUpdatedDate() {
        return updatedDate;
    }
    
    public void setUpdatedDate(Date updatedDate) {
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
        return "School{" +
                "schoolId=" + schoolId +
                ", udiseNo='" + udiseNo + '\'' +
                ", schoolName='" + schoolName + '\'' +
                ", districtName='" + districtName + '\'' +
                '}';
    }
}
