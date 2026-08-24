package com.vjnt.util;

import java.sql.Connection;
import java.sql.SQLException;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

/**
 * Database Connection Utility
 * Manages database connections using a HikariCP connection pool
 */
public class DatabaseConnection {

    // Database credentials - UPDATE THESE WITH YOUR DATABASE DETAILS
  //  private static final String DB_URL = "jdbc:mysql://localhost:3306/vjnt_class_management_live?useUnicode=true&characterEncoding=UTF-8&connectionCollation=utf8mb4_unicode_ci";

	//GWSonline
    private static final String DB_URL = "jdbc:mysql://localhost:3306/vjnt_class_management?useUnicode=true&characterEncoding=UTF-8&connectionCollation=utf8mb4_unicode_ci&connectTimeout=5000&socketTimeout=20000";
    //gateeonline
	//private static final String DB_URL = "jdbc:mysql://localhost:3306/gateepor_vjnt_class_management?useUnicode=true&characterEncoding=UTF-8&connectionCollation=utf8mb4_unicode_ci";

  private static final String DB_USER = "root";
  //private static final String DB_PASSWORD = "root";
	//gateeonline
     //  private static final String DB_USER = "gateepor_root";
 //  private static final String DB_PASSWORD = "Anill}gN4n3maAy*";
  // private static final String DB_PASSWORD = "Anill}gN4n3maAy*";

//GWSonline
   private static final String DB_PASSWORD = "Ou@rl}gN4n3maAy*";//
   //Anill}gN4n3maAy*  UAT


    private static final String DB_DRIVER = "com.mysql.cj.jdbc.Driver";

    private static final HikariDataSource dataSource;

    static {
        HikariConfig config = new HikariConfig();
        config.setDriverClassName(DB_DRIVER);
        config.setJdbcUrl(DB_URL);
        config.setUsername(DB_USER);
        config.setPassword(DB_PASSWORD);

        // Pool sizing - keep well under MySQL's max_connections and Tomcat's thread pool
        config.setMaximumPoolSize(20);
        config.setMinimumIdle(5);

        // Fail fast instead of hanging the request thread when the pool/DB is unavailable
        config.setConnectionTimeout(5000);   // max wait for a pooled connection
        config.setValidationTimeout(3000);
        config.setIdleTimeout(300000);        // 5 min
        config.setMaxLifetime(1800000);       // 30 min, stay under typical MySQL wait_timeout
        config.setInitializationFailTimeout(-1); // don't block app startup if DB is briefly down

        dataSource = new HikariDataSource(config);
    }

    /**
     * Get a pooled database connection
     */
    public static Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }

    /**
     * Close database connection (returns it to the pool)
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
        //System.out.println("Testing database connection...");
        if (testConnection()) {
            //System.out.println("✓ Database connection successful!");
        } else {
            //System.out.println("✗ Database connection failed!");
        }
    }
}
