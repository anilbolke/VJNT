package com.vjnt.dao;

import com.vjnt.model.VidnyanSetuUser;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.util.PasswordUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

/**
 * Auth + lookup for the standalone VidnyanSetu portal's own login table
 * (vidnyansetu_users) — same lockout/failed-attempt shape as UserDAO, kept
 * separate because it is a separate table. See {@link VidnyanSetuUser}.
 */
public class VidnyanSetuUserDAO {

    public VidnyanSetuUser findById(int vsUserId) {
        String sql = "SELECT * FROM vidnyansetu_users WHERE vs_user_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, vsUserId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return extract(rs);
            }
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuUserDAO] findById error: " + e.getMessage());
        }
        return null;
    }

    public VidnyanSetuUser findByUsername(String username) {
        String sql = "SELECT * FROM vidnyansetu_users WHERE username = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return extract(rs);
            }
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuUserDAO] findByUsername error: " + e.getMessage());
        }
        return null;
    }

    public VidnyanSetuUser authenticate(String username, String password) {
        VidnyanSetuUser vsUser = findByUsername(username);
        if (vsUser == null) return null;

        boolean match = PasswordUtil.verifyPassword(password, vsUser.getPassword());
        if (match) {
            if (vsUser.isAccountLocked() || !vsUser.isActive()) return null;
            updateLastLogin(vsUser.getVsUserId());
            resetFailedAttempts(vsUser.getVsUserId());
            return vsUser;
        } else {
            incrementFailedAttempts(vsUser.getVsUserId());
            return null;
        }
    }

    public boolean usernameExists(String username) {
        return findByUsername(username) != null;
    }

    /** Create a new login. password must already be hashed (PasswordUtil.hashPassword). */
    public boolean createUser(String username, String hashedPassword, VidnyanSetuUser.Role role,
                               String udiseNo, String fullName, String mobile, String createdBy) {
        String sql = "INSERT INTO vidnyansetu_users " +
                "(username, password, role, udise_no, full_name, mobile, is_first_login, must_change_password, is_active, created_by) " +
                "VALUES (?, ?, ?, ?, ?, ?, 1, 1, 1, ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, hashedPassword);
            ps.setString(3, role.name());
            ps.setString(4, udiseNo);
            ps.setString(5, fullName);
            ps.setString(6, mobile);
            ps.setString(7, createdBy);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuUserDAO] createUser error: " + e.getMessage());
            return false;
        }
    }

    public boolean updatePassword(int vsUserId, String hashedPassword) {
        String sql = "UPDATE vidnyansetu_users SET password = ?, is_first_login = 0, must_change_password = 0 WHERE vs_user_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, hashedPassword);
            ps.setInt(2, vsUserId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuUserDAO] updatePassword error: " + e.getMessage());
            return false;
        }
    }

    public boolean setActive(int vsUserId, boolean active) {
        String sql = "UPDATE vidnyansetu_users SET is_active = ? WHERE vs_user_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setBoolean(1, active);
            ps.setInt(2, vsUserId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuUserDAO] setActive error: " + e.getMessage());
            return false;
        }
    }

    /** All users of a role for a school (coordinators managing their own teachers, or admin listing coordinators). */
    public List<VidnyanSetuUser> findByUdiseAndRole(String udiseNo, VidnyanSetuUser.Role role) {
        List<VidnyanSetuUser> out = new ArrayList<>();
        String sql = "SELECT * FROM vidnyansetu_users WHERE udise_no = ? AND role = ? ORDER BY full_name";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, udiseNo);
            ps.setString(2, role.name());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(extract(rs));
            }
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuUserDAO] findByUdiseAndRole error: " + e.getMessage());
        }
        return out;
    }

    public List<VidnyanSetuUser> findAllByRole(VidnyanSetuUser.Role role) {
        List<VidnyanSetuUser> out = new ArrayList<>();
        String sql = "SELECT * FROM vidnyansetu_users WHERE role = ? ORDER BY udise_no, full_name";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, role.name());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(extract(rs));
            }
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuUserDAO] findAllByRole error: " + e.getMessage());
        }
        return out;
    }

    private void updateLastLogin(int vsUserId) {
        String sql = "UPDATE vidnyansetu_users SET last_login_date = ? WHERE vs_user_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setTimestamp(1, new Timestamp(System.currentTimeMillis()));
            ps.setInt(2, vsUserId);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuUserDAO] updateLastLogin error: " + e.getMessage());
        }
    }

    private void incrementFailedAttempts(int vsUserId) {
        String sql = "UPDATE vidnyansetu_users SET failed_login_attempts = failed_login_attempts + 1, " +
                "account_locked = CASE WHEN failed_login_attempts >= 4 THEN 1 ELSE 0 END, " +
                "locked_date = CASE WHEN failed_login_attempts >= 4 THEN ? ELSE locked_date END " +
                "WHERE vs_user_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setTimestamp(1, new Timestamp(System.currentTimeMillis()));
            ps.setInt(2, vsUserId);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuUserDAO] incrementFailedAttempts error: " + e.getMessage());
        }
    }

    private void resetFailedAttempts(int vsUserId) {
        String sql = "UPDATE vidnyansetu_users SET failed_login_attempts = 0, account_locked = 0, locked_date = NULL WHERE vs_user_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, vsUserId);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println("[VidnyanSetuUserDAO] resetFailedAttempts error: " + e.getMessage());
        }
    }

    private VidnyanSetuUser extract(ResultSet rs) throws SQLException {
        VidnyanSetuUser u = new VidnyanSetuUser();
        u.setVsUserId(rs.getInt("vs_user_id"));
        u.setUsername(rs.getString("username"));
        u.setPassword(rs.getString("password"));
        u.setRole(VidnyanSetuUser.Role.valueOf(rs.getString("role")));
        u.setUdiseNo(rs.getString("udise_no"));
        u.setFullName(rs.getString("full_name"));
        u.setMobile(rs.getString("mobile"));
        u.setFirstLogin(rs.getBoolean("is_first_login"));
        u.setMustChangePassword(rs.getBoolean("must_change_password"));
        u.setActive(rs.getBoolean("is_active"));
        u.setFailedLoginAttempts(rs.getInt("failed_login_attempts"));
        u.setAccountLocked(rs.getBoolean("account_locked"));
        u.setLockedDate(rs.getTimestamp("locked_date"));
        u.setLastLoginDate(rs.getTimestamp("last_login_date"));
        return u;
    }
}
