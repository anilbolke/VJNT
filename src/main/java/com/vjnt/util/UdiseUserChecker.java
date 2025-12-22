package com.vjnt.util;

import com.vjnt.dao.UserDAO;
import com.vjnt.model.User;
import java.sql.*;
import java.util.HashSet;
import java.util.Set;

/**
 * Utility to check and debug UDISE user creation issues
 */
public class UdiseUserChecker {
    
    public static void main(String[] args) {
        // Test with the specific UDISE number you mentioned
        String testUdise = "27150615002";
        
        System.out.println("========================================");
        System.out.println("UDISE USER CHECKER");
        System.out.println("========================================");
        System.out.println("Testing UDISE: " + testUdise);
        System.out.println();
        
        checkUdiseUsers(testUdise);
        
        System.out.println("\n========================================");
        System.out.println("Expected usernames for this UDISE:");
        System.out.println("  SR: sr_" + testUdise);
        System.out.println("  HM: hm_" + testUdise);
        System.out.println("========================================");
    }
    
    public static void checkUdiseUsers(String udiseNo) {
        UserDAO userDAO = new UserDAO();
        
        // Check if users exist for this UDISE
        boolean exists = userDAO.udiseUsersExist(udiseNo);
        System.out.println("✓ Users exist for UDISE " + udiseNo + ": " + exists);
        
        // Check using the bulk method
        Set<String> udiseSet = new HashSet<>();
        udiseSet.add(udiseNo);
        Set<String> existingUdises = userDAO.getExistingUdiseNumbers(udiseSet);
        System.out.println("✓ Bulk check result: " + (existingUdises.contains(udiseNo) ? "EXISTS" : "NOT FOUND"));
        
        // Query database directly to see what's there
        System.out.println("\n🔍 Querying database for users with this UDISE...");
        
        String sql = "SELECT user_id, username, user_type, udise_no, full_name FROM users WHERE udise_no = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            boolean found = false;
            while (rs.next()) {
                found = true;
                System.out.println("  Found user:");
                System.out.println("    - User ID: " + rs.getInt("user_id"));
                System.out.println("    - Username: " + rs.getString("username"));
                System.out.println("    - Type: " + rs.getString("user_type"));
                System.out.println("    - UDISE: " + rs.getString("udise_no"));
                System.out.println("    - Full Name: " + rs.getString("full_name"));
                System.out.println();
            }
            
            if (!found) {
                System.out.println("  ❌ NO USERS FOUND for UDISE " + udiseNo);
                System.out.println("  This UDISE needs users created!");
            }
            
        } catch (SQLException e) {
            System.err.println("Error querying database: " + e.getMessage());
            e.printStackTrace();
        }
        
        // Also check by username pattern
        System.out.println("\n🔍 Checking by username pattern...");
        String srUsername = "sr_" + udiseNo;
        String hmUsername = "hm_" + udiseNo;
        
        checkUsername(srUsername);
        checkUsername(hmUsername);
    }
    
    private static void checkUsername(String username) {
        String sql = "SELECT user_id, username, user_type, udise_no FROM users WHERE username = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                System.out.println("  ✓ Username '" + username + "' EXISTS");
                System.out.println("    - User ID: " + rs.getInt("user_id"));
                System.out.println("    - UDISE: " + rs.getString("udise_no"));
            } else {
                System.out.println("  ❌ Username '" + username + "' NOT FOUND");
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking username: " + e.getMessage());
        }
    }
}
