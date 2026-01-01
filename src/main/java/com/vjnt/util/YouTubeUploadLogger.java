package com.vjnt.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * YouTube Upload Logger - Comprehensive logging for debugging production issues
 */
public class YouTubeUploadLogger {
    
    private static final String LOG_PREFIX = "[YOUTUBE-UPLOAD]";
    private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    
    /**
     * Log info message
     */
    public static void info(String message) {
        System.out.println(LOG_PREFIX + " [INFO] " + timestamp() + " " + message);
    }
    
    /**
     * Log error message
     */
    public static void error(String message) {
        System.err.println(LOG_PREFIX + " [ERROR] " + timestamp() + " " + message);
    }
    
    /**
     * Log error with exception
     */
    public static void error(String message, Exception e) {
        System.err.println(LOG_PREFIX + " [ERROR] " + timestamp() + " " + message);
        e.printStackTrace();
    }
    
    /**
     * Log warning message
     */
    public static void warn(String message) {
        System.out.println(LOG_PREFIX + " [WARN] " + timestamp() + " " + message);
    }
    
    /**
     * Log success message
     */
    public static void success(String message) {
        System.out.println(LOG_PREFIX + " [SUCCESS] " + timestamp() + " ✓ " + message);
    }
    
    /**
     * Get current timestamp
     */
    private static String timestamp() {
        return "[" + DATE_FORMAT.format(new Date()) + "]";
    }
    
    /**
     * Log complete environment info for debugging
     */
    public static void logEnvironmentInfo() {
        info("=".repeat(80));
        info("YOUTUBE UPLOAD ENVIRONMENT CHECK");
        info("=".repeat(80));
        
        // OS Info
        info("Operating System: " + System.getProperty("os.name"));
        info("OS Version: " + System.getProperty("os.version"));
        info("OS Architecture: " + System.getProperty("os.arch"));
        
        // Java Info
        info("Java Version: " + System.getProperty("java.version"));
        info("Java Home: " + System.getProperty("java.home"));
        
        // Server Info
        info("User Home: " + System.getProperty("user.home"));
        info("Working Directory: " + new File(".").getAbsolutePath());
        info("Headless Mode: " + System.getProperty("java.awt.headless", "false"));
        
        // Display Info
        String display = System.getenv("DISPLAY");
        info("DISPLAY env: " + (display != null ? display : "NOT SET"));
        
        // Check Windows
        boolean isWindows = System.getProperty("os.name", "").toLowerCase().contains("win");
        info("Is Windows: " + isWindows);
        info("Can Display GUI: " + (isWindows || display != null));
        
        info("=".repeat(80));
    }
    
    /**
     * Check and log credential file locations
     */
    public static void checkCredentialLocations() {
        info("=".repeat(80));
        info("CHECKING CREDENTIAL FILE LOCATIONS");
        info("=".repeat(80));
        
        // Check deployment context
        String catalinaBase = System.getProperty("catalina.base");
        String catalinaHome = System.getProperty("catalina.home");
        info("Catalina Base: " + (catalinaBase != null ? catalinaBase : "NOT SET"));
        info("Catalina Home: " + (catalinaHome != null ? catalinaHome : "NOT SET"));
        
        // Check classpath resources
        info("--- Checking Classpath Resources ---");
        
        // Check StoredCredential in classpath
        InputStream credStream = YouTubeUploadLogger.class.getClassLoader()
            .getResourceAsStream("credentials/StoredCredential");
        if (credStream != null) {
            success("✓ StoredCredential FOUND in classpath: credentials/StoredCredential");
            try {
                int size = credStream.available();
                info("  Size: " + size + " bytes");
                credStream.close();
            } catch (IOException e) {
                error("  Error reading stream: " + e.getMessage());
            }
        } else {
            error("✗ StoredCredential NOT FOUND in classpath: credentials/StoredCredential");
        }
        
        // Check client_secret.json in classpath
        InputStream clientStream = YouTubeUploadLogger.class.getClassLoader()
            .getResourceAsStream("client_secret.json");
        if (clientStream != null) {
            success("✓ client_secret.json FOUND in classpath");
            try {
                int size = clientStream.available();
                info("  Size: " + size + " bytes");
                clientStream.close();
            } catch (IOException e) {
                error("  Error reading stream: " + e.getMessage());
            }
        } else {
            error("✗ client_secret.json NOT FOUND in classpath");
        }
        
        // Check service account (optional)
        InputStream serviceStream = YouTubeUploadLogger.class.getClassLoader()
            .getResourceAsStream("service-account.json");
        if (serviceStream != null) {
            success("✓ service-account.json FOUND in classpath");
            try {
                int size = serviceStream.available();
                info("  Size: " + size + " bytes");
                serviceStream.close();
            } catch (IOException e) {
                error("  Error reading stream: " + e.getMessage());
            }
        } else {
            warn("⚠ service-account.json NOT in classpath (OAuth mode only)");
        }
        
        // Check user home directory
        info("--- Checking User Home Directory ---");
        String userHome = System.getProperty("user.home");
        info("User Home: " + userHome);
        
        File vjntDir = new File(userHome, ".vjnt");
        info(".vjnt directory: " + vjntDir.getAbsolutePath());
        info(".vjnt exists: " + vjntDir.exists());
        if (vjntDir.exists()) {
            info(".vjnt is directory: " + vjntDir.isDirectory());
            info(".vjnt is readable: " + vjntDir.canRead());
            info(".vjnt is writable: " + vjntDir.canWrite());
        }
        
        File storedCred = new File(vjntDir, "StoredCredential");
        if (storedCred.exists()) {
            success("✓ StoredCredential found in user home: " + storedCred.getAbsolutePath());
            info("  File size: " + storedCred.length() + " bytes");
            info("  Last modified: " + new Date(storedCred.lastModified()));
            info("  Readable: " + storedCred.canRead());
            info("  Writable: " + storedCred.canWrite());
        } else {
            error("✗ StoredCredential NOT in user home: " + storedCred.getAbsolutePath());
        }
        
        // Check WEB-INF/classes location
        info("--- Checking WEB-INF/classes Directory ---");
        try {
            String classPath = YouTubeUploadLogger.class.getProtectionDomain()
                .getCodeSource().getLocation().getPath();
            info("Current class location: " + classPath);
            
            File classLocation = new File(classPath);
            if (classLocation.isDirectory()) {
                File credInClasses = new File(classLocation, "credentials/StoredCredential");
                info("Checking: " + credInClasses.getAbsolutePath());
                if (credInClasses.exists()) {
                    success("✓ StoredCredential found at: " + credInClasses.getAbsolutePath());
                    info("  Size: " + credInClasses.length() + " bytes");
                } else {
                    error("✗ StoredCredential NOT found at: " + credInClasses.getAbsolutePath());
                }
            }
        } catch (Exception e) {
            warn("Could not determine class location: " + e.getMessage());
        }
        
        info("=".repeat(80));
    }
    
    /**
     * Attempt to auto-fix missing credentials by copying from various locations
     */
    public static boolean attemptAutoFix() {
        info("=".repeat(80));
        info("ATTEMPTING AUTO-FIX FOR MISSING CREDENTIALS");
        info("=".repeat(80));
        
        try {
            // Target location for credentials
            String userHome = System.getProperty("user.home");
            File vjntDir = new File(userHome, ".vjnt");
            File targetCredential = new File(vjntDir, "StoredCredential");
            
            if (targetCredential.exists()) {
                info("Credentials already exist at: " + targetCredential.getAbsolutePath());
                return true;
            }
            
            // Try to extract from classpath (packaged in WAR)
            InputStream credStream = YouTubeUploadLogger.class.getClassLoader()
                .getResourceAsStream("credentials/StoredCredential");
            
            if (credStream != null) {
                info("Found credentials in classpath - extracting to user home...");
                
                // Create .vjnt directory if it doesn't exist
                if (!vjntDir.exists()) {
                    if (vjntDir.mkdirs()) {
                        success("Created directory: " + vjntDir.getAbsolutePath());
                    } else {
                        error("Failed to create directory: " + vjntDir.getAbsolutePath());
                        return false;
                    }
                }
                
                // Copy credential file
                Files.copy(credStream, targetCredential.toPath(), StandardCopyOption.REPLACE_EXISTING);
                credStream.close();
                
                success("AUTO-FIX SUCCESSFUL! Credentials extracted to: " + targetCredential.getAbsolutePath());
                info("File size: " + targetCredential.length() + " bytes");
                return true;
                
            } else {
                error("AUTO-FIX FAILED: Credentials not found in WAR classpath");
                error("WAR file must be rebuilt with credentials included");
                return false;
            }
            
        } catch (Exception e) {
            error("AUTO-FIX FAILED with exception: " + e.getMessage(), e);
            return false;
        } finally {
            info("=".repeat(80));
        }
    }
    
    /**
     * Create user-friendly error message for frontend
     */
    public static String createUserFriendlyErrorMessage(Exception e, boolean isProduction) {
        StringBuilder msg = new StringBuilder();
        
        msg.append("Video upload failed. ");
        
        if (e.getMessage().contains("credentials") || e.getMessage().contains("authorization")) {
            msg.append("\\n\\nIssue: YouTube credentials not found or expired.");
            
            if (isProduction) {
                msg.append("\\n\\nThis is a production server issue. The administrator needs to:");
                msg.append("\\n1. Rebuild the WAR file with valid credentials");
                msg.append("\\n2. Redeploy the updated WAR to the server");
                msg.append("\\n\\nPlease contact your system administrator.");
            } else {
                msg.append("\\n\\nTo fix this:");
                msg.append("\\n1. Go to Settings → Authorize YouTube");
                msg.append("\\n2. Complete the authorization process");
                msg.append("\\n3. Try uploading again");
            }
        } else {
            msg.append("\\n\\nError: ").append(e.getMessage());
            msg.append("\\n\\nPlease try again or contact support if the issue persists.");
        }
        
        return msg.toString();
    }
}
