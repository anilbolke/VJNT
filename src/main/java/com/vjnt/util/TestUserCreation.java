package com.vjnt.util;

import com.vjnt.dao.UserDAO;
import com.vjnt.model.User;
import java.util.ArrayList;
import java.util.List;

/**
 * Test to simulate user creation for a specific UDISE
 */
public class TestUserCreation {
    
    public static void main(String[] args) {
        System.out.println("========================================");
        System.out.println("TEST USER CREATION FOR UDISE");
        System.out.println("========================================\n");
        
        // Test UDISE number that should have users created
        String testUdise = "27150615002";
        String district = "Test District";
        String division = "Test Division";
        String createdBy = "dataadmin";
        
        System.out.println("Creating users for UDISE: " + testUdise);
        System.out.println("District: " + district);
        System.out.println("Division: " + division);
        System.out.println();
        
        // Create SR user
        User srUser = new User();
        srUser.setUsername(PasswordUtil.generateUsername("SR", testUdise));
        srUser.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
        srUser.setUserType(User.UserType.SCHOOL_COORDINATOR);
        srUser.setFullName("School Coordinator - UDISE " + testUdise);
        srUser.setUdiseNo(testUdise);
        srUser.setDistrictName(district);
        srUser.setDivisionName(division);
        srUser.setCreatedBy(createdBy);
        
        // Create HM user
        User hmUser = new User();
        hmUser.setUsername(PasswordUtil.generateUsername("HM", testUdise));
        hmUser.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
        hmUser.setUserType(User.UserType.HEAD_MASTER);
        hmUser.setFullName("Head Master - UDISE " + testUdise);
        hmUser.setUdiseNo(testUdise);
        hmUser.setDistrictName(district);
        hmUser.setDivisionName(division);
        hmUser.setCreatedBy(createdBy);
        
        System.out.println("User objects created:");
        System.out.println("  SR - Username: " + srUser.getUsername());
        System.out.println("       Type: " + srUser.getUserType());
        System.out.println("       UDISE: " + srUser.getUdiseNo());
        System.out.println("       Active: " + srUser.isActive());
        System.out.println("       First Login: " + srUser.isFirstLogin());
        System.out.println();
        System.out.println("  HM - Username: " + hmUser.getUsername());
        System.out.println("       Type: " + hmUser.getUserType());
        System.out.println("       UDISE: " + hmUser.getUdiseNo());
        System.out.println("       Active: " + hmUser.isActive());
        System.out.println("       First Login: " + hmUser.isFirstLogin());
        System.out.println();
        
        // Add to batch and insert
        List<User> userBatch = new ArrayList<>();
        userBatch.add(srUser);
        userBatch.add(hmUser);
        
        System.out.println("========================================");
        System.out.println("ATTEMPTING BATCH INSERT");
        System.out.println("========================================\n");
        
        UserDAO userDAO = new UserDAO();
        int inserted = userDAO.batchCreateUsers(userBatch);
        
        System.out.println("\n========================================");
        System.out.println("RESULT: " + inserted + " users inserted");
        System.out.println("========================================\n");
        
        // Verify the users were created
        System.out.println("Verifying users were created...\n");
        UdiseUserChecker.checkUdiseUsers(testUdise);
    }
}
