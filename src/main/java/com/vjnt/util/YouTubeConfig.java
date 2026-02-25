package com.vjnt.util;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * Configuration class for YouTube API settings
 * Loads settings from youtube.properties file or uses defaults
 */
public class YouTubeConfig {
    
    private static final String CONFIG_FILE = "youtube.properties";
    private static Properties properties = new Properties();
    
    // Default values
    private static final String DEFAULT_APPLICATION_NAME = "VJNT Class Management";
    private static final String DEFAULT_CLIENT_SECRETS_FILE = "client_secret.json";
    private static final String DEFAULT_CREDENTIALS_FOLDER = "credentials";
    private static final String DEFAULT_CATEGORY_ID = "27"; // Education
    private static final String DEFAULT_PRIVACY_STATUS = "unlisted";
    private static final String DEFAULT_DESCRIPTION = "Educational video from VJNT Class Management";
    private static final String DEFAULT_FALLBACK_TITLE = "Untitled Video";
    private static final int DEFAULT_MAX_TITLE_LENGTH = 100;
    private static final String DEFAULT_DEV_PATH = "C:\\Users\\Admin\\V2Project\\VJNT Class Managment\\src\\main\\resources\\";
    private static final String DEFAULT_SERVICE_ACCOUNT_FILE = "service-account.json";
    private static final String DEFAULT_AUTH_TYPE = "oauth"; // "oauth" or "service-account"
    
    static {
        loadConfiguration();
    }
    
    /**
     * Load configuration from properties file
     */
    private static void loadConfiguration() {
        try {
            InputStream configStream = YouTubeConfig.class.getClassLoader().getResourceAsStream(CONFIG_FILE);
            if (configStream != null) {
                properties.load(configStream);
                //System.out.println("✓ Loaded YouTube configuration from " + CONFIG_FILE);
                configStream.close();
            } else {
                //System.out.println("No youtube.properties found, using default values");
            }
        } catch (IOException e) {
            System.err.println("Warning: Could not load youtube.properties: " + e.getMessage());
            System.err.println("Using default configuration values");
        }
    }
    
    /**
     * Get application name for YouTube API
     */
    public static String getApplicationName() {
        return properties.getProperty("youtube.application.name", DEFAULT_APPLICATION_NAME);
    }
    
    /**
     * Get client secrets file name
     */
    public static String getClientSecretsFile() {
        return properties.getProperty("youtube.client.secrets.file", DEFAULT_CLIENT_SECRETS_FILE);
    }
    
    /**
     * Get credentials folder path
     */
    public static String getCredentialsFolder() {
        return properties.getProperty("youtube.credentials.folder", DEFAULT_CREDENTIALS_FOLDER);
    }
    
    /**
     * Get default category ID for videos
     */
    public static String getDefaultCategoryId() {
        return properties.getProperty("youtube.default.category.id", DEFAULT_CATEGORY_ID);
    }
    
    /**
     * Get default privacy status for videos
     */
    public static String getDefaultPrivacyStatus() {
        return properties.getProperty("youtube.default.privacy.status", DEFAULT_PRIVACY_STATUS);
    }
    
    /**
     * Get default video description
     */
    public static String getDefaultDescription() {
        return properties.getProperty("youtube.default.description", DEFAULT_DESCRIPTION);
    }
    
    /**
     * Get fallback title when video title is invalid
     */
    public static String getFallbackTitle() {
        return properties.getProperty("youtube.fallback.title", DEFAULT_FALLBACK_TITLE);
    }
    
    /**
     * Get maximum title length (YouTube limit)
     */
    public static int getMaxTitleLength() {
        String value = properties.getProperty("youtube.max.title.length", String.valueOf(DEFAULT_MAX_TITLE_LENGTH));
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return DEFAULT_MAX_TITLE_LENGTH;
        }
    }
    
    /**
     * Get development path for local development
     */
    public static String getDevPath() {
        return properties.getProperty("youtube.dev.path", DEFAULT_DEV_PATH);
    }
    
    /**
     * Get user home directory subfolder for credentials
     */
    public static String getUserHomeSubfolder() {
        return properties.getProperty("youtube.user.home.subfolder", ".vjnt/");
    }
    
    /**
     * Check if direct upload is enabled
     */
    public static boolean isDirectUploadEnabled() {
        String value = properties.getProperty("youtube.direct.upload.enabled", "false");
        return Boolean.parseBoolean(value);
    }
    
    /**
     * Get OAuth receiver port (-1 for automatic)
     */
    public static int getOAuthReceiverPort() {
        String value = properties.getProperty("youtube.oauth.receiver.port", "-1");
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return -1;
        }
    }
    
    /**
     * Check if debug logging is enabled
     */
    public static boolean isDebugEnabled() {
        String value = properties.getProperty("youtube.debug.enabled", "false");
        return Boolean.parseBoolean(value);
    }
    
    /**
     * Get authentication type (oauth or service-account)
     */
    public static String getAuthType() {
        return properties.getProperty("youtube.auth.type", DEFAULT_AUTH_TYPE);
    }
    
    /**
     * Get service account file name
     */
    public static String getServiceAccountFile() {
        return properties.getProperty("youtube.service.account.file", DEFAULT_SERVICE_ACCOUNT_FILE);
    }
    
    /**
     * Check if using service account authentication
     */
    public static boolean useServiceAccount() {
        return "service-account".equalsIgnoreCase(getAuthType());
    }
    
    /**
     * Get all properties (for debugging)
     */
    public static Properties getAllProperties() {
        return new Properties(properties);
    }
    
    /**
     * Reload configuration from file
     */
    public static void reload() {
        properties.clear();
        loadConfiguration();
    }
}