package com.vjnt.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Database Connection Utility
 * Manages database connections using connection pooling
 */
public class DatabaseConnection {
    
    // Database credentials - UPDATE THESE WITH YOUR DATABASE DETAILS
    private static final String DB_URL = "jdbc:mysql://localhost:3306/vjnt_class_management";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "root";
    
   // private static final String DB_USER = "root";
   // private static final String DB_PASSWORD = "Ou@rl}gN4n3maAy*";
    
    
    private static final String DB_DRIVER = "com.mysql.cj.jdbc.Driver";
    
    static {
        try {
            Class.forName(DB_DRIVER);
            System.out.println("Database driver loaded successfully");
        } catch (ClassNotFoundException e) {
            System.err.println("Error loading database driver: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Get database connection with retry logic
     */
    public static Connection getConnection() throws SQLException {
        int maxRetries = 3;
        int retryDelay = 1000; // 1 second
        SQLException lastException = null;
        
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
                if (attempt > 1) {
                    System.out.println("✓ Database connection successful on attempt " + attempt);
                }
                return conn;
            } catch (SQLException e) {
                lastException = e;
                System.err.println("Database connection attempt " + attempt + " failed: " + e.getMessage());
                
                if (attempt < maxRetries) {
                    try {
                        Thread.sleep(retryDelay);
                        retryDelay *= 2; // Exponential backoff
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        throw e;
                    }
                }
            }
        }
        
        System.err.println("Error connecting to database after " + maxRetries + " attempts: " + lastException.getMessage());
        throw lastException;
    }
    
    /**
     * Close database connection
     */
    public static void closeConnection(Connection conn) {
        if (conn != null) {
            try {
                conn.close();
            } catch (SQLException e) {
                System.err.println("Error closing connection: " + e.getMessage());
            }
        }
    }
    
    /**
     * Test database connection
     */
    public static boolean testConnection() {
        try (Connection conn = getConnection()) {
            return conn != null && !conn.isClosed();
        } catch (SQLException e) {
            System.err.println("Database connection test failed: " + e.getMessage());
            return false;
        }
    }
    
    public static void main(String[] args) {
        System.out.println("Testing database connection...");
        if (testConnection()) {
            System.out.println("✓ Database connection successful!");
        } else {
            System.out.println("✗ Database connection failed!");
        }
    }
}
