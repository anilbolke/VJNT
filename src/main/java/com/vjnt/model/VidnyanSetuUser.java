package com.vjnt.model;

import java.sql.Timestamp;

/**
 * Login account for the standalone VidnyanSetu (विज्ञानसेतू) portal.
 * Deliberately separate from {@link User} — see
 * vidnyansetu_users in "databse Scripts/CREATE_VIDNYANSETU_STUDENT_MODULE_2026-09-19.sql"
 * for why (users.username is unique on mobile number, so a person with an
 * existing main-portal login cannot get a second users row for the same
 * mobile, and these are meant to be genuinely separate accounts).
 */
public class VidnyanSetuUser {

    public enum Role {
        COORDINATOR,
        TEACHER
    }

    private int vsUserId;
    private String username;
    private String password;
    private Role role;
    private String udiseNo;
    private String fullName;
    private String mobile;

    private boolean firstLogin;
    private boolean mustChangePassword;
    private boolean active;
    private int failedLoginAttempts;
    private boolean accountLocked;
    private Timestamp lockedDate;
    private Timestamp lastLoginDate;

    public int getVsUserId() { return vsUserId; }
    public void setVsUserId(int vsUserId) { this.vsUserId = vsUserId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }

    public String getUdiseNo() { return udiseNo; }
    public void setUdiseNo(String udiseNo) { this.udiseNo = udiseNo; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getMobile() { return mobile; }
    public void setMobile(String mobile) { this.mobile = mobile; }

    public boolean isFirstLogin() { return firstLogin; }
    public void setFirstLogin(boolean firstLogin) { this.firstLogin = firstLogin; }

    public boolean isMustChangePassword() { return mustChangePassword; }
    public void setMustChangePassword(boolean mustChangePassword) { this.mustChangePassword = mustChangePassword; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public int getFailedLoginAttempts() { return failedLoginAttempts; }
    public void setFailedLoginAttempts(int failedLoginAttempts) { this.failedLoginAttempts = failedLoginAttempts; }

    public boolean isAccountLocked() { return accountLocked; }
    public void setAccountLocked(boolean accountLocked) { this.accountLocked = accountLocked; }

    public Timestamp getLockedDate() { return lockedDate; }
    public void setLockedDate(Timestamp lockedDate) { this.lockedDate = lockedDate; }

    public Timestamp getLastLoginDate() { return lastLoginDate; }
    public void setLastLoginDate(Timestamp lastLoginDate) { this.lastLoginDate = lastLoginDate; }
}
