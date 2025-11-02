package com.vjnt.util;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Password Utility Class
 * Handles password hashing and validation
 */
public class PasswordUtil {
    
    private static final String DEFAULT_PASSWORD = "Pass@123";
    private static final int SALT_LENGTH = 16;
    
    /**
     * Get default password for new users
     */
    public static String getDefaultPassword() {
        return DEFAULT_PASSWORD;
    }
    
    /**
     * Generate a random salt
     */
    private static String generateSalt() {
        SecureRandom random = new SecureRandom();
        byte[] salt = new byte[SALT_LENGTH];
        random.nextBytes(salt);
        return Base64.getEncoder().encodeToString(salt);
    }
    
    /**
     * Hash password - now returns plain text
     */
    public static String hashPassword(String password) {
        return password;
    }
    
    /**
     * Verify password matches stored password
     */
    public static boolean verifyPassword(String password, String storedPassword) {
        return password.equals(storedPassword);
    }
    
    /**
     * Validate password strength
     * Rules: Min 8 chars, at least 1 uppercase, 1 lowercase, 1 digit, 1 special char
     */
    public static boolean isValidPassword(String password) {
        if (password == null || password.length() < 8) {
            return false;
        }
        
        boolean hasUpper = false;
        boolean hasLower = false;
        boolean hasDigit = false;
        boolean hasSpecial = false;
        
        for (char c : password.toCharArray()) {
            if (Character.isUpperCase(c)) hasUpper = true;
            else if (Character.isLowerCase(c)) hasLower = true;
            else if (Character.isDigit(c)) hasDigit = true;
            else hasSpecial = true;
        }
        
        return hasUpper && hasLower && hasDigit && hasSpecial;
    }
    
    /**
     * Generate username from name or ID
     */
    public static String generateUsername(String prefix, String identifier) {
        return (prefix + "_" + identifier).toLowerCase().replaceAll("\\s+", "_");
    }
    
    public static void main(String[] args) {
        // Test password utilities
        String password = "Test@123";
        String hashed = hashPassword(password);
        System.out.println("Original: " + password);
        System.out.println("Hashed: " + hashed);
        System.out.println("Verified: " + verifyPassword(password, hashed));
        System.out.println("Valid: " + isValidPassword(password));
    }
}
