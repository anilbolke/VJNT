package com.vjnt.test;

import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Quick test to verify Bunny CDN credentials
 */
public class BunnyCDNTest {
    
    public static void main(String[] args) {
        String storageZone = "vjnt-student-videos";
        String apiKey = "1806b190-51f1-4f09-8b27bb22aaa8-ec16-4c84";
        
        try {
            //System.out.println("=== Testing Bunny CDN Connection ===");
            //System.out.println("Storage Zone: " + storageZone);
            //System.out.println("API Key: " + apiKey.substring(0, 8) + "..." + apiKey.substring(apiKey.length() - 4));
            
            // Test URL: upload a simple test file - USE SINGAPORE REGION
            String testUrl = "https://sg.storage.bunnycdn.com/" + storageZone + "/test.txt";
            //System.out.println("Test URL: " + testUrl);
            
            URL url = new URL(testUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("PUT");
            conn.setDoOutput(true);
            conn.setRequestProperty("AccessKey", apiKey);
            conn.setRequestProperty("Content-Type", "text/plain");
            
            // Write test content
            String testContent = "Test from Java - " + new java.util.Date();
            conn.setRequestProperty("Content-Length", String.valueOf(testContent.length()));
            
            //System.out.println("\nSending request...");
            
            try (OutputStream os = conn.getOutputStream()) {
                os.write(testContent.getBytes());
                os.flush();
            }
            
            int responseCode = conn.getResponseCode();
            String responseMessage = conn.getResponseMessage();
            
            //System.out.println("\n=== RESPONSE ===");
            //System.out.println("Response Code: " + responseCode);
            //System.out.println("Response Message: " + responseMessage);
            
            if (responseCode == 201 || responseCode == 200) {
                //System.out.println("\n✓✓✓ SUCCESS! ✓✓✓");
                //System.out.println("Credentials are working correctly!");
                //System.out.println("\nYour test file is now available at:");
                //System.out.println("https://vjnt-videos-cdn.b-cdn.net/test.txt");
                //System.out.println("\nThe video upload should work now.");
            } else {
                System.err.println("\n✗✗✗ FAILED! ✗✗✗");
                System.err.println("Response code: " + responseCode);
                System.err.println("\nPossible issues:");
                System.err.println("1. Storage zone name incorrect (check for typos)");
                System.err.println("2. API key is wrong or expired");
                System.err.println("3. Using read-only key instead of write key");
                System.err.println("\nPlease verify in Bunny dashboard:");
                System.err.println("- Storage → " + storageZone);
                System.err.println("- Password field (not read-only password)");
            }
            
            conn.disconnect();
            
        } catch (Exception e) {
            System.err.println("\n✗ ERROR: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
