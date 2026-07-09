package com.vjnt.util;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * Configuration class for Bunny CDN settings.
 * Loads settings from bunnycdn.properties on the classpath (src/main/resources),
 * falling back to defaults if the file is missing.
 */
public class BunnyCDNConfig {

    private static final String CONFIG_FILE = "bunnycdn.properties";
    private static Properties properties = new Properties();

    // Fallback defaults if bunnycdn.properties is not found on the classpath.
    private static final String DEFAULT_STORAGE_ZONE_NAME = "vjnt-student1-videos";
    private static final String DEFAULT_STORAGE_PASSWORD = "d7825a10-c6b0-4751-a485f1464d86-6420-4ad9";
    private static final String DEFAULT_PULL_ZONE_URL = "https://vjnt-student1-videos.b-cdn.net";
    private static final String DEFAULT_STORAGE_API_URL = "https://sg.storage.bunnycdn.com";

    static {
        loadConfiguration();
    }

    private static void loadConfiguration() {
        try (InputStream configStream = BunnyCDNConfig.class.getClassLoader().getResourceAsStream(CONFIG_FILE)) {
            if (configStream != null) {
                properties.load(configStream);
            } else {
                System.err.println("Warning: " + CONFIG_FILE + " not found on classpath, using default Bunny CDN configuration");
            }
        } catch (IOException e) {
            System.err.println("Warning: Could not load " + CONFIG_FILE + ": " + e.getMessage());
            System.err.println("Using default Bunny CDN configuration");
        }
    }

    public static String getStorageZoneName() {
        return properties.getProperty("bunnycdn.storage.zone.name", DEFAULT_STORAGE_ZONE_NAME);
    }

    public static String getStoragePassword() {
        return properties.getProperty("bunnycdn.storage.password", DEFAULT_STORAGE_PASSWORD);
    }

    public static String getPullZoneUrl() {
        return properties.getProperty("bunnycdn.pull.zone.url", DEFAULT_PULL_ZONE_URL);
    }

    public static String getStorageApiUrl() {
        return properties.getProperty("bunnycdn.storage.api.url", DEFAULT_STORAGE_API_URL);
    }

    /**
     * Reload configuration from file.
     */
    public static void reload() {
        properties.clear();
        loadConfiguration();
    }
}
