package com.vjnt.dao;

import com.vjnt.model.User;
import com.vjnt.model.User.UserType;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.util.PasswordUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * User Data Access Object
 * Handles all database operations for User entity
 */
public class UserDAO {
    
    /**
     * Create a new user
     */
    public boolean createUser(User user) {
        String sql = "INSERT INTO users (username, password, user_type, division_name, district_name, " +
                    "udise_no, is_first_login, must_change_password, is_active, created_by, full_name) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            pstmt.setString(1, user.getUsername());
            pstmt.setString(2, user.getPassword());
            pstmt.setString(3, user.getUserType().name());
            pstmt.setString(4, user.getDivisionName());
            pstmt.setString(5, user.getDistrictName());
            pstmt.setString(6, user.getUdiseNo());
            pstmt.setBoolean(7, user.isFirstLogin());
            pstmt.setBoolean(8, user.isMustChangePassword());
            pstmt.setBoolean(9, user.isActive());
            pstmt.setString(10, user.getCreatedBy());
            pstmt.setString(11, user.getFullName());
            
            int rowsAffected = pstmt.executeUpdate();
            
            if (rowsAffected > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    user.setUserId(rs.getInt(1));
                }
                return true;
            }
            return false;
            
        } catch (SQLException e) {
            System.err.println("Error creating user: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * FAST-TRACK: Batch create users (optimized for bulk imports)
     * Process multiple users in a single batch operation for better performance
     * Skips duplicate usernames and continues with the rest
     */
    public int batchCreateUsers(List<User> users) {
        if (users == null || users.isEmpty()) {
            System.out.println("⚠ batchCreateUsers called with empty user list");
            return 0;
        }
        
        System.out.println("📝 batchCreateUsers called with " + users.size() + " users to process");
        
        String sql = "INSERT INTO users (username, password, user_type, division_name, district_name, " +
                    "udise_no, is_first_login, must_change_password, is_active, created_by, full_name) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        int totalInserted = 0;
        int skippedDuplicates = 0;
        int addedToBatch = 0;
        long startTime = System.currentTimeMillis();
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             PreparedStatement checkStmt = conn.prepareStatement("SELECT COUNT(*) FROM users WHERE username = ?")) {
            
            // Disable autocommit for batch operation
            conn.setAutoCommit(false);
            
            for (User user : users) {
                // Check if username already exists
                checkStmt.setString(1, user.getUsername());
                ResultSet rs = checkStmt.executeQuery();
                
                if (rs.next() && rs.getInt(1) > 0) {
                    // Username already exists, skip this user
                    skippedDuplicates++;
                    System.out.println("⚠ Skipping duplicate user: " + user.getUsername() + " (UDISE: " + user.getUdiseNo() + ")");
                    continue;
                }
                
                // Username doesn't exist, add to batch
                System.out.println("✓ Adding to batch: " + user.getUsername() + " (Type: " + user.getUserType() + ", UDISE: " + user.getUdiseNo() + ")");
                pstmt.setString(1, user.getUsername());
                pstmt.setString(2, user.getPassword());
                pstmt.setString(3, user.getUserType().name());
                pstmt.setString(4, user.getDivisionName());
                pstmt.setString(5, user.getDistrictName());
                pstmt.setString(6, user.getUdiseNo());
                pstmt.setBoolean(7, user.isFirstLogin());
                pstmt.setBoolean(8, user.isMustChangePassword());
                pstmt.setBoolean(9, user.isActive());
                pstmt.setString(10, user.getCreatedBy());
                pstmt.setString(11, user.getFullName());
                
                pstmt.addBatch();
                addedToBatch++;
            }
            
            System.out.println("📊 Batch summary: " + addedToBatch + " users to insert, " + skippedDuplicates + " duplicates skipped");
            
            // Execute batch only if there are items to insert
            if (addedToBatch > 0) {
                int[] results = pstmt.executeBatch();
                conn.commit();
                
                for (int result : results) {
                    if (result > 0) {
                        totalInserted++;
                    }
                }
                System.out.println("✓ Batch executed successfully: " + totalInserted + " users inserted");
            } else {
                System.out.println("⚠ No users to insert - all were duplicates");
                conn.commit();
            }
            
            long duration = System.currentTimeMillis() - startTime;
            System.out.println("✓ Batch user insert completed: " + totalInserted + " users inserted, " + 
                             skippedDuplicates + " duplicates skipped in " + duration + "ms");
            return totalInserted;
            
        } catch (SQLException e) {
            System.err.println("Error in batch create users: " + e.getMessage());
            e.printStackTrace();
            return totalInserted;
        }
    }
    
    /**
     * Find user by username
     */
    public User findByUsername(String username) {
        String sql = "SELECT * FROM users WHERE username = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            
            System.out.println(rs);
            if (rs.next()) {
                return extractUserFromResultSet(rs);
            }
            
        } catch (SQLException e) {
            System.err.println("Error finding user: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    /**
     * Authenticate user
     */
    public User authenticateUser(String username, String password) {
        System.out.println("[UserDAO] Authenticating user: " + username);
        
        // List all users in database for debugging
        listAllDatabaseUsers();
        
        User user = findByUsername(username);
        
        if (user == null) {
            System.out.println("[UserDAO] User NOT found in database: " + username);
            
            // Helpful hints for common mistakes
            if ("admin".equalsIgnoreCase(username)) {
                System.out.println("[UserDAO] HINT: Did you mean 'dataadmin'? Try username: dataadmin");
            }
            if (username != null && username.contains(" ")) {
                System.out.println("[UserDAO] HINT: Username contains spaces. Remove spaces and try again.");
            }
            
            return null;
        }
        
        System.out.println("[UserDAO] User found: " + username);
        System.out.println("[UserDAO] - User Type: " + user.getUserType());
        System.out.println("[UserDAO] - Is Active: " + user.isActive());
        System.out.println("[UserDAO] - Is Locked: " + user.isAccountLocked());
        System.out.println("[UserDAO] - DB Password: [" + user.getPassword() + "]");
        System.out.println("[UserDAO] - Input Password: [" + password + "]");
        
        boolean passwordMatch = PasswordUtil.verifyPassword(password, user.getPassword());
        System.out.println("[UserDAO] - Password Match: " + passwordMatch);
        
        if (user != null && passwordMatch) {
            if (user.isAccountLocked()) {
                return null;
            }
            if (!user.isActive()) {
                return null;
            }
            
            updateLastLogin(user.getUserId());
            resetFailedAttempts(user.getUserId());
            return user;
        } else {
            if (user != null) {
                incrementFailedAttempts(user.getUserId());
            }
            return null;
        }
    }
    
    /**
     * List all database users for debugging
     */
    public void listAllDatabaseUsers() {
        System.out.println("\n============================================");
        System.out.println("ALL USERS IN DATABASE:");
        System.out.println("============================================");
        
        String sql = "SELECT user_id, username, user_type, is_active, account_locked, division_name, district_name, udise_no FROM users ORDER BY user_id";
        
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
        } catch (SQLException e) {
            System.err.println("Error listing users: " + e.getMessage());
            e.printStackTrace();
        }
        
        System.out.println("============================================\n");
    }
    
    /**
     * Update password
     */
    public boolean updatePassword(int userId, String newPassword) {
        String sql = "UPDATE users SET password = ?, password_changed_date = ?, " +
                    "is_first_login = FALSE, must_change_password = FALSE " +
                    "WHERE user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, newPassword);
            pstmt.setTimestamp(2, new Timestamp(System.currentTimeMillis()));
            pstmt.setInt(3, userId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating password: " + e.getMessage());
            return false;
        }
    }
    
    /**
     * Update last login time
     */
    private void updateLastLogin(int userId) {
        String sql = "UPDATE users SET last_login_date = ? WHERE user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setTimestamp(1, new Timestamp(System.currentTimeMillis()));
            pstmt.setInt(2, userId);
            pstmt.executeUpdate();
            
        } catch (SQLException e) {
            System.err.println("Error updating last login: " + e.getMessage());
        }
    }
    
    /**
     * Increment failed login attempts
     */
    private void incrementFailedAttempts(int userId) {
        String sql = "UPDATE users SET failed_login_attempts = failed_login_attempts + 1, " +
                    "account_locked = CASE WHEN failed_login_attempts >= 4 THEN TRUE ELSE FALSE END, " +
                    "locked_date = CASE WHEN failed_login_attempts >= 4 THEN ? ELSE locked_date END " +
                    "WHERE user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setTimestamp(1, new Timestamp(System.currentTimeMillis()));
            pstmt.setInt(2, userId);
            pstmt.executeUpdate();
            
        } catch (SQLException e) {
            System.err.println("Error incrementing failed attempts: " + e.getMessage());
        }
    }
    
    /**
     * Reset failed login attempts
     */
    private void resetFailedAttempts(int userId) {
        String sql = "UPDATE users SET failed_login_attempts = 0, account_locked = FALSE, " +
                    "locked_date = NULL WHERE user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            pstmt.executeUpdate();
            
        } catch (SQLException e) {
            System.err.println("Error resetting failed attempts: " + e.getMessage());
        }
    }
    
    /**
     * Check if username exists
     */
    public boolean usernameExists(String username) {
        return findByUsername(username) != null;
    }
    
    /**
     * Check if users exist for a given UDISE number
     * Returns true if any user (HM or SR) exists for this UDISE
     */
    public boolean udiseUsersExist(String udiseNo) {
        if (udiseNo == null || udiseNo.trim().isEmpty()) {
            return false;
        }
        
        String sql = "SELECT COUNT(*) FROM users WHERE udise_no = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo.trim());
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking UDISE users existence: " + e.getMessage());
        }
        
        return false;
    }
    
    /**
     * FAST-TRACK: Check multiple UDISE numbers at once for existing users
     * Returns set of UDISE numbers that already have users in the database
     */
    public Set<String> getExistingUdiseNumbers(Set<String> udiseNumbers) {
        Set<String> existingUdises = new HashSet<>();
        
        if (udiseNumbers == null || udiseNumbers.isEmpty()) {
            System.out.println("⚠ No UDISE numbers to check");
            return existingUdises;
        }
        
        System.out.println("🔍 Checking " + udiseNumbers.size() + " UDISE numbers against database...");
        
        // Process in chunks of 1000 to avoid SQL query size limits
        List<String> udiseList = new ArrayList<>(udiseNumbers);
        int chunkSize = 1000;
        
        for (int i = 0; i < udiseList.size(); i += chunkSize) {
            int end = Math.min(i + chunkSize, udiseList.size());
            List<String> chunk = udiseList.subList(i, end);
            
            StringBuilder placeholders = new StringBuilder();
            for (int j = 0; j < chunk.size(); j++) {
                if (j > 0) placeholders.append(",");
                placeholders.append("?");
            }
            
            String sql = "SELECT DISTINCT udise_no FROM users WHERE udise_no IN (" + placeholders + ") AND udise_no IS NOT NULL";
            
            try (Connection conn = DatabaseConnection.getConnection();
                 PreparedStatement pstmt = conn.prepareStatement(sql)) {
                
                for (int j = 0; j < chunk.size(); j++) {
                    pstmt.setString(j + 1, chunk.get(j).trim());
                }
                
                ResultSet rs = pstmt.executeQuery();
                while (rs.next()) {
                    String udiseNo = rs.getString("udise_no");
                    if (udiseNo != null) {
                        existingUdises.add(udiseNo.trim());
                    }
                }
                
            } catch (SQLException e) {
                System.err.println("Error checking existing UDISE numbers: " + e.getMessage());
                e.printStackTrace();
            }
        }
        
        System.out.println("✓ Found " + existingUdises.size() + " UDISE numbers with existing users in database");
        if (existingUdises.size() > 0 && existingUdises.size() <= 10) {
            System.out.println("  Existing UDISE numbers: " + existingUdises);
        }
        
        return existingUdises;
    }
    
    /**
     * FAST-TRACK: Check multiple usernames at once
     * More efficient than checking individually
     */
    public List<String> getExistingUsernames(List<String> usernames) {
        if (usernames == null || usernames.isEmpty()) {
            return new ArrayList<>();
        }
        
        List<String> existingUsernames = new ArrayList<>();
        
        // Process in chunks of 1000 to avoid SQL query size limits
        int chunkSize = 1000;
        for (int i = 0; i < usernames.size(); i += chunkSize) {
            int end = Math.min(i + chunkSize, usernames.size());
            List<String> chunk = usernames.subList(i, end);
            existingUsernames.addAll(getExistingUsernamesChunk(chunk));
        }
        
        return existingUsernames;
    }
    
    /**
     * Helper method to check existing usernames in a chunk
     */
    private List<String> getExistingUsernamesChunk(List<String> usernames) {
        List<String> existingUsernames = new ArrayList<>();
        
        StringBuilder placeholders = new StringBuilder();
        for (int i = 0; i < usernames.size(); i++) {
            if (i > 0) placeholders.append(",");
            placeholders.append("?");
        }
        
        String sql = "SELECT username FROM users WHERE username IN (" + placeholders + ")";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            for (int i = 0; i < usernames.size(); i++) {
                pstmt.setString(i + 1, usernames.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                existingUsernames.add(rs.getString("username"));
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking existing usernames: " + e.getMessage());
        }
        
        return existingUsernames;
    }
    
    /**
     * Get all users by type
     */
    public List<User> getUsersByType(UserType userType) {
        List<User> users = new ArrayList<>();
        String sql = "SELECT * FROM users WHERE user_type = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, userType.name());
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                users.add(extractUserFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting users by type: " + e.getMessage());
        }
        return users;
    }
    
    /**
     * OPTIMIZED: Get paginated users by type
     */
    public List<User> getUsersByTypePaginated(UserType userType, int offset, int limit, String searchTerm) {
        List<User> users = new ArrayList<>();
        long startTime = System.currentTimeMillis();
        
        StringBuilder sql = new StringBuilder("SELECT * FROM users WHERE user_type = ?");
        List<Object> params = new ArrayList<>();
        params.add(userType.name());
        
        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            sql.append(" AND (username LIKE ? OR full_name LIKE ? OR email LIKE ?)");
            String searchPattern = "%" + searchTerm.trim() + "%";
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
        }
        
        sql.append(" ORDER BY username LIMIT ? OFFSET ?");
        params.add(limit);
        params.add(offset);
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                users.add(extractUserFromResultSet(rs));
            }
            
            long duration = System.currentTimeMillis() - startTime;
            System.out.println("✓ Fetched " + users.size() + " users by type (paginated) in " + duration + "ms");
            
        } catch (SQLException e) {
            System.err.println("Error getting users by type paginated: " + e.getMessage());
        }
        return users;
    }
    
    /**
     * OPTIMIZED: Get count of users by type
     */
    public int getUsersByTypeCount(UserType userType, String searchTerm) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) as total FROM users WHERE user_type = ?");
        List<Object> params = new ArrayList<>();
        params.add(userType.name());
        
        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            sql.append(" AND (username LIKE ? OR full_name LIKE ? OR email LIKE ?)");
            String searchPattern = "%" + searchTerm.trim() + "%";
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
        }
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("total");
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting users by type count: " + e.getMessage());
        }
        return 0;
    }
    
    /**
     * Get all users
     */
    public List<User> getAllUsers() {
        List<User> users = new ArrayList<>();
        String sql = "SELECT * FROM users ORDER BY user_type, username";
        
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                users.add(extractUserFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting all users: " + e.getMessage());
        }
        return users;
    }
    
    /**
     * OPTIMIZED: Get paginated users with filters
     * @param offset Starting position (0-based)
     * @param limit Number of records to fetch
     * @param userType Filter by user type (null for all)
     * @param searchTerm Search in username, full_name, email (null for no search)
     * @param divisionName Filter by division (null for all)
     * @param districtName Filter by district (null for all)
     * @return List of users for the requested page
     */
    public List<User> getUsersPaginated(int offset, int limit, UserType userType, 
                                        String searchTerm, String divisionName, String districtName) {
        List<User> users = new ArrayList<>();
        long startTime = System.currentTimeMillis();
        
        StringBuilder sql = new StringBuilder("SELECT * FROM users WHERE 1=1");
        List<Object> params = new ArrayList<>();
        
        // Apply filters
        if (userType != null) {
            sql.append(" AND user_type = ?");
            params.add(userType.name());
        }
        
        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            sql.append(" AND (username LIKE ? OR full_name LIKE ? OR email LIKE ? OR mobile LIKE ?)");
            String searchPattern = "%" + searchTerm.trim() + "%";
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
        }
        
        if (divisionName != null && !divisionName.trim().isEmpty()) {
            sql.append(" AND division_name = ?");
            params.add(divisionName);
        }
        
        if (districtName != null && !districtName.trim().isEmpty()) {
            sql.append(" AND district_name = ?");
            params.add(districtName);
        }
        
        sql.append(" ORDER BY created_date DESC, user_type, username");
        sql.append(" LIMIT ? OFFSET ?");
        params.add(limit);
        params.add(offset);
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            // Set parameters
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                users.add(extractUserFromResultSet(rs));
            }
            
            long duration = System.currentTimeMillis() - startTime;
            System.out.println("✓ Fetched " + users.size() + " users (paginated) in " + duration + "ms");
            
        } catch (SQLException e) {
            System.err.println("Error getting paginated users: " + e.getMessage());
            e.printStackTrace();
        }
        return users;
    }
    
    /**
     * OPTIMIZED: Get total count of users with filters
     * @param userType Filter by user type (null for all)
     * @param searchTerm Search in username, full_name, email (null for no search)
     * @param divisionName Filter by division (null for all)
     * @param districtName Filter by district (null for all)
     * @return Total count of users matching the filters
     */
    public int getUsersCount(UserType userType, String searchTerm, String divisionName, String districtName) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) as total FROM users WHERE 1=1");
        List<Object> params = new ArrayList<>();
        
        // Apply filters (same as paginated query)
        if (userType != null) {
            sql.append(" AND user_type = ?");
            params.add(userType.name());
        }
        
        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            sql.append(" AND (username LIKE ? OR full_name LIKE ? OR email LIKE ? OR mobile LIKE ?)");
            String searchPattern = "%" + searchTerm.trim() + "%";
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
        }
        
        if (divisionName != null && !divisionName.trim().isEmpty()) {
            sql.append(" AND division_name = ?");
            params.add(divisionName);
        }
        
        if (districtName != null && !districtName.trim().isEmpty()) {
            sql.append(" AND district_name = ?");
            params.add(districtName);
        }
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            // Set parameters
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt("total");
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting users count: " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }
    
    /**
     * Get users by division
     */
    public List<User> getUsersByDivision(String divisionName) {
        List<User> users = new ArrayList<>();
        String sql = "SELECT * FROM users WHERE division_name = ? ORDER BY user_type, username";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, divisionName);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                users.add(extractUserFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting users by division: " + e.getMessage());
        }
        return users;
    }
    
    /**
     * OPTIMIZED: Get paginated users by division
     */
    public List<User> getUsersByDivisionPaginated(String divisionName, int offset, int limit, String searchTerm) {
        List<User> users = new ArrayList<>();
        long startTime = System.currentTimeMillis();
        
        StringBuilder sql = new StringBuilder("SELECT * FROM users WHERE division_name = ?");
        List<Object> params = new ArrayList<>();
        params.add(divisionName);
        
        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            sql.append(" AND (username LIKE ? OR full_name LIKE ? OR email LIKE ?)");
            String searchPattern = "%" + searchTerm.trim() + "%";
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
        }
        
        sql.append(" ORDER BY user_type, username LIMIT ? OFFSET ?");
        params.add(limit);
        params.add(offset);
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                users.add(extractUserFromResultSet(rs));
            }
            
            long duration = System.currentTimeMillis() - startTime;
            System.out.println("✓ Fetched " + users.size() + " users by division (paginated) in " + duration + "ms");
            
        } catch (SQLException e) {
            System.err.println("Error getting users by division paginated: " + e.getMessage());
        }
        return users;
    }
    
    /**
     * OPTIMIZED: Get count of users by division
     */
    public int getUsersByDivisionCount(String divisionName, String searchTerm) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) as total FROM users WHERE division_name = ?");
        List<Object> params = new ArrayList<>();
        params.add(divisionName);
        
        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            sql.append(" AND (username LIKE ? OR full_name LIKE ? OR email LIKE ?)");
            String searchPattern = "%" + searchTerm.trim() + "%";
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
        }
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("total");
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting users by division count: " + e.getMessage());
        }
        return 0;
    }
    
    /**
     * Get users by district
     */
    public List<User> getUsersByDistrict(String districtName) {
        List<User> users = new ArrayList<>();
        String sql = "SELECT * FROM users WHERE district_name = ? ORDER BY user_type, username";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, districtName);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                users.add(extractUserFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting users by district: " + e.getMessage());
        }
        return users;
    }
    
    /**
     * OPTIMIZED: Get paginated users by district
     */
    public List<User> getUsersByDistrictPaginated(String districtName, int offset, int limit, String searchTerm) {
        List<User> users = new ArrayList<>();
        long startTime = System.currentTimeMillis();
        
        StringBuilder sql = new StringBuilder("SELECT * FROM users WHERE district_name = ?");
        List<Object> params = new ArrayList<>();
        params.add(districtName);
        
        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            sql.append(" AND (username LIKE ? OR full_name LIKE ? OR email LIKE ?)");
            String searchPattern = "%" + searchTerm.trim() + "%";
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
        }
        
        sql.append(" ORDER BY user_type, username LIMIT ? OFFSET ?");
        params.add(limit);
        params.add(offset);
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                users.add(extractUserFromResultSet(rs));
            }
            
            long duration = System.currentTimeMillis() - startTime;
            System.out.println("✓ Fetched " + users.size() + " users by district (paginated) in " + duration + "ms");
            
        } catch (SQLException e) {
            System.err.println("Error getting users by district paginated: " + e.getMessage());
        }
        return users;
    }
    
    /**
     * OPTIMIZED: Get count of users by district
     */
    public int getUsersByDistrictCount(String districtName, String searchTerm) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) as total FROM users WHERE district_name = ?");
        List<Object> params = new ArrayList<>();
        params.add(districtName);
        
        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            sql.append(" AND (username LIKE ? OR full_name LIKE ? OR email LIKE ?)");
            String searchPattern = "%" + searchTerm.trim() + "%";
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
        }
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("total");
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting users by district count: " + e.getMessage());
        }
        return 0;
    }
    
    /**
     * Get users by UDISE number
     */
    public List<User> getUsersByUdise(String udiseNo) {
        List<User> users = new ArrayList<>();
        String sql = "SELECT * FROM users WHERE udise_no = ? ORDER BY user_type, username";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                users.add(extractUserFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting users by UDISE: " + e.getMessage());
        }
        return users;
    }
    
    /**
     * Extract User object from ResultSet
     */
    private User extractUserFromResultSet(ResultSet rs) throws SQLException {
        User user = new User();
        user.setUserId(rs.getInt("user_id"));
        user.setUsername(rs.getString("username"));
        user.setPassword(rs.getString("password"));
        
        // Parse user type with error handling
        String userTypeStr = rs.getString("user_type");
        try {
            user.setUserType(UserType.valueOf(userTypeStr));
        } catch (IllegalArgumentException e) {
            System.err.println("Unknown user type: " + userTypeStr + " for user: " + rs.getString("username"));
            // Default to DIVISION if unknown type
            user.setUserType(UserType.DIVISION);
        }
        
        user.setDivisionName(rs.getString("division_name"));
        user.setDistrictName(rs.getString("district_name"));
        user.setUdiseNo(rs.getString("udise_no"));
        user.setFirstLogin(rs.getBoolean("is_first_login"));
        user.setPasswordChangedDate(rs.getTimestamp("password_changed_date"));
        user.setMustChangePassword(rs.getBoolean("must_change_password"));
        user.setActive(rs.getBoolean("is_active"));
        user.setCreatedDate(rs.getTimestamp("created_date"));
        user.setCreatedBy(rs.getString("created_by"));
        user.setLastLoginDate(rs.getTimestamp("last_login_date"));
        user.setFailedLoginAttempts(rs.getInt("failed_login_attempts"));
        user.setAccountLocked(rs.getBoolean("account_locked"));
        user.setLockedDate(rs.getTimestamp("locked_date"));
        user.setEmail(rs.getString("email"));
        user.setMobile(rs.getString("mobile"));
        user.setFullName(rs.getString("full_name"));
        user.setUpdatedDate(rs.getTimestamp("updated_date"));
        user.setUpdatedBy(rs.getString("updated_by"));
        
        // New fields
        try {
            user.setWhatsappNumber(rs.getString("whatsapp_number"));
            user.setRemarks(rs.getString("remarks"));
        } catch (SQLException e) {
            // Fields might not exist in older schema versions
        }
        
        return user;
    }
    
    /**
     * Get school users (School Coordinators and Head Masters) by district
     */
    public List<User> getSchoolUsersByDistrict(String districtName) {
        List<User> users = new ArrayList<>();
        String sql = "SELECT * FROM users WHERE district_name = ? AND user_type IN ('SCHOOL_COORDINATOR', 'HEAD_MASTER') ORDER BY udise_no, user_type";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, districtName);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                users.add(extractUserFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting school users by district: " + e.getMessage());
            e.printStackTrace();
        }
        return users;
    }
    
    /**
     * OPTIMIZED: Get paginated school users by district
     */
    public List<User> getSchoolUsersByDistrictPaginated(String districtName, int offset, int limit, String searchTerm) {
        List<User> users = new ArrayList<>();
        long startTime = System.currentTimeMillis();
        
        StringBuilder sql = new StringBuilder(
            "SELECT * FROM users WHERE district_name = ? " +
            "AND user_type IN ('SCHOOL_COORDINATOR', 'HEAD_MASTER')");
        List<Object> params = new ArrayList<>();
        params.add(districtName);
        
        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            sql.append(" AND (username LIKE ? OR full_name LIKE ? OR udise_no LIKE ?)");
            String searchPattern = "%" + searchTerm.trim() + "%";
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
        }
        
        sql.append(" ORDER BY udise_no, user_type LIMIT ? OFFSET ?");
        params.add(limit);
        params.add(offset);
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                users.add(extractUserFromResultSet(rs));
            }
            
            long duration = System.currentTimeMillis() - startTime;
            System.out.println("✓ Fetched " + users.size() + " school users by district (paginated) in " + duration + "ms");
            
        } catch (SQLException e) {
            System.err.println("Error getting school users by district paginated: " + e.getMessage());
            e.printStackTrace();
        }
        return users;
    }
    
    /**
     * OPTIMIZED: Get count of school users by district
     */
    public int getSchoolUsersByDistrictCount(String districtName, String searchTerm) {
        StringBuilder sql = new StringBuilder(
            "SELECT COUNT(*) as total FROM users WHERE district_name = ? " +
            "AND user_type IN ('SCHOOL_COORDINATOR', 'HEAD_MASTER')");
        List<Object> params = new ArrayList<>();
        params.add(districtName);
        
        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            sql.append(" AND (username LIKE ? OR full_name LIKE ? OR udise_no LIKE ?)");
            String searchPattern = "%" + searchTerm.trim() + "%";
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
        }
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("total");
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting school users by district count: " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }
    
    /**
     * Get user by ID
     */
    public User getUserById(int userId) {
        String sql = "SELECT * FROM users WHERE user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return extractUserFromResultSet(rs);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting user by ID: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    /**
     * Get user by username
     */
    public User getUserByUsername(String username) {
        return findByUsername(username);
    }
    
    /**
     * Update user
     */
    public boolean updateUser(User user) {
        String sql = "UPDATE users SET username = ?, user_type = ?, division_name = ?, district_name = ?, " +
                    "udise_no = ?, full_name = ?, email = ?, mobile = ?, whatsapp_number = ?, remarks = ?, " +
                    "is_active = ?, updated_by = ?, updated_date = NOW() " +
                    "WHERE user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, user.getUsername());
            pstmt.setString(2, user.getUserType().name());
            pstmt.setString(3, user.getDivisionName());
            pstmt.setString(4, user.getDistrictName());
            pstmt.setString(5, user.getUdiseNo());
            pstmt.setString(6, user.getFullName());
            pstmt.setString(7, user.getEmail());
            pstmt.setString(8, user.getMobile());
            pstmt.setString(9, user.getWhatsappNumber());
            pstmt.setString(10, user.getRemarks());
            pstmt.setBoolean(11, user.isActive());
            pstmt.setString(12, user.getUpdatedBy());
            pstmt.setInt(13, user.getUserId());
            
            int rowsAffected = pstmt.executeUpdate();
            
            // Update password if provided
            if (user.getPassword() != null && !user.getPassword().trim().isEmpty()) {
                String passwordSql = "UPDATE users SET password = ? WHERE user_id = ?";
                try (PreparedStatement psPwd = conn.prepareStatement(passwordSql)) {
                    psPwd.setString(1, PasswordUtil.hashPassword(user.getPassword()));
                    psPwd.setInt(2, user.getUserId());
                    psPwd.executeUpdate();
                }
            }
            
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating user: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Delete user
     */
    public boolean deleteUser(int userId) {
        String sql = "DELETE FROM users WHERE user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error deleting user: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
}