package com.vjnt.model;

import java.sql.Timestamp;

/**
 * Login Audit Entity Class
 * Tracks all login attempts and sessions
 */
public class LoginAudit {
    
    public enum LoginStatus {
        SUCCESS,
        FAILED,
        LOCKED
    }
    
    private int auditId;
    private int userId;
    private String username;
    private Timestamp loginTime;
    private Timestamp logoutTime;
    private String ipAddress;
    private String sessionId;
    private LoginStatus loginStatus;
    private String failureReason;
    private String userAgent;
    
    // Constructors
    public LoginAudit() {
    }
    
    public LoginAudit(String username, LoginStatus loginStatus) {
        this.username = username;
        this.loginStatus = loginStatus;
        this.loginTime = new Timestamp(System.currentTimeMillis());
    }
    
    // Getters and Setters
    public int getAuditId() {
        return auditId;
    }
    
    public void setAuditId(int auditId) {
        this.auditId = auditId;
    }
    
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
    
    public Timestamp getLoginTime() {
        return loginTime;
    }
    
    public void setLoginTime(Timestamp loginTime) {
        this.loginTime = loginTime;
    }
    
    public Timestamp getLogoutTime() {
        return logoutTime;
    }
    
    public void setLogoutTime(Timestamp logoutTime) {
        this.logoutTime = logoutTime;
    }
    
    public String getIpAddress() {
        return ipAddress;
    }
    
    public void setIpAddress(String ipAddress) {
        this.ipAddress = ipAddress;
    }
    
    public String getSessionId() {
        return sessionId;
    }
    
    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }
    
    public LoginStatus getLoginStatus() {
        return loginStatus;
    }
    
    public void setLoginStatus(LoginStatus loginStatus) {
        this.loginStatus = loginStatus;
    }
    
    public String getFailureReason() {
        return failureReason;
    }
    
    public void setFailureReason(String failureReason) {
        this.failureReason = failureReason;
    }
    
    public String getUserAgent() {
        return userAgent;
    }
    
    public void setUserAgent(String userAgent) {
        this.userAgent = userAgent;
    }
    
    @Override
    public String toString() {
        return "LoginAudit{" +
                "auditId=" + auditId +
                ", username='" + username + '\'' +
                ", loginStatus=" + loginStatus +
                ", loginTime=" + loginTime +
                ", ipAddress='" + ipAddress + '\'' +
                '}';
    }
}
