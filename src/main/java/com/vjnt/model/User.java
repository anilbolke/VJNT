package com.vjnt.model;

import java.sql.Timestamp;

/**
 * User Entity Class
 * Represents a user in the VJNT Class Management System
 */
public class User {
    
    // Enum for User Types
    public enum UserType {
        DIVISION,
        DISTRICT_COORDINATOR,
        DISTRICT_2ND_COORDINATOR,
        SCHOOL_COORDINATOR,
        HEAD_MASTER,
        DATA_ADMIN
    }
    
    // Primary Fields
    private int userId;
    private String username;
    private String password;
    private UserType userType;
    
    // Reference Fields
    private String divisionName;
    private String districtName;
    private String udiseNo;
    
    // Password Management
    private boolean isFirstLogin;
    private Timestamp passwordChangedDate;
    private boolean mustChangePassword;
    
    // Account Status
    private boolean isActive;
    private Timestamp createdDate;
    private String createdBy;
    private Timestamp lastLoginDate;
    private int failedLoginAttempts;
    private boolean accountLocked;
    private Timestamp lockedDate;
    
    // Contact Information
    private String email;
    private String mobile;
    private String whatsappNumber;
    private String fullName;
    
    // Additional Information
    private String remarks;
    
    // Audit Fields
    private Timestamp updatedDate;
    private String updatedBy;
    
    // Constructors
    public User() {
        this.isFirstLogin = true;
        this.mustChangePassword = true;
        this.isActive = true;
        this.failedLoginAttempts = 0;
        this.accountLocked = false;
    }
    
    public User(String username, String password, UserType userType) {
        this();
        this.username = username;
        this.password = password;
        this.userType = userType;
    }
    
    // Getters and Setters
    public int getUserId() {
        return userId;
    }
    
    public void setUserId(int userId) {
        this.userId = userId;
    }
    
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getPassword() {
        return password;
    }
    
    public void setPassword(String password) {
        this.password = password;
    }
    
    public UserType getUserType() {
        return userType;
    }
    
    public void setUserType(UserType userType) {
        this.userType = userType;
    }
    
    public String getDivisionName() {
        return divisionName;
    }
    
    public void setDivisionName(String divisionName) {
        this.divisionName = divisionName;
    }
    
    public String getDistrictName() {
        return districtName;
    }
    
    public void setDistrictName(String districtName) {
        this.districtName = districtName;
    }
    
    public String getUdiseNo() {
        return udiseNo;
    }
    
    public void setUdiseNo(String udiseNo) {
        this.udiseNo = udiseNo;
    }
    
    public boolean isFirstLogin() {
        return isFirstLogin;
    }
    
    public void setFirstLogin(boolean isFirstLogin) {
        this.isFirstLogin = isFirstLogin;
    }
    
    public Timestamp getPasswordChangedDate() {
        return passwordChangedDate;
    }
    
    public void setPasswordChangedDate(Timestamp passwordChangedDate) {
        this.passwordChangedDate = passwordChangedDate;
    }
    
    public boolean isMustChangePassword() {
        return mustChangePassword;
    }
    
    public void setMustChangePassword(boolean mustChangePassword) {
        this.mustChangePassword = mustChangePassword;
    }
    
    public boolean isActive() {
        return isActive;
    }
    
    public void setActive(boolean isActive) {
        this.isActive = isActive;
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
    
    public Timestamp getLastLoginDate() {
        return lastLoginDate;
    }
    
    public void setLastLoginDate(Timestamp lastLoginDate) {
        this.lastLoginDate = lastLoginDate;
    }
    
    public int getFailedLoginAttempts() {
        return failedLoginAttempts;
    }
    
    public void setFailedLoginAttempts(int failedLoginAttempts) {
        this.failedLoginAttempts = failedLoginAttempts;
    }
    
    public boolean isAccountLocked() {
        return accountLocked;
    }
    
    public void setAccountLocked(boolean accountLocked) {
        this.accountLocked = accountLocked;
    }
    
    public Timestamp getLockedDate() {
        return lockedDate;
    }
    
    public void setLockedDate(Timestamp lockedDate) {
        this.lockedDate = lockedDate;
    }
    
    public String getEmail() {
        return email;
    }
    
    public void setEmail(String email) {
        this.email = email;
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
    
    public String getFullName() {
        return fullName;
    }
    
    public void setFullName(String fullName) {
        this.fullName = fullName;
    }
    
    public String getRemarks() {
        return remarks;
    }
    
    public void setRemarks(String remarks) {
        this.remarks = remarks;
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
        return "User{" +
                "userId=" + userId +
                ", username='" + username + '\'' +
                ", userType=" + userType +
                ", divisionName='" + divisionName + '\'' +
                ", districtName='" + districtName + '\'' +
                ", udiseNo='" + udiseNo + '\'' +
                ", isActive=" + isActive +
                ", isFirstLogin=" + isFirstLogin +
                '}';
    }
}