package com.vjnt.util;

import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;
import java.io.File;

/**
 * Standalone utility to authorize YouTube OAuth
 * Run this to fix "Token has been expired or revoked" error
 */
public class YouTubeAuthorizationTool {
    
    public static void main(String[] args) {
        System.out.println("========================================");
        System.out.println("YouTube Authorization Tool");
        System.out.println("========================================");
        System.out.println();
        
        try {
            System.out.println("Checking credentials folder...");
            File credentialsDir = new File(System.getProperty("user.home"), ".vjnt/credentials");
            if (!credentialsDir.exists()) {
                credentialsDir.mkdirs();
                System.out.println("✓ Created credentials folder: " + credentialsDir.getAbsolutePath());
            } else {
                System.out.println("✓ Credentials folder exists: " + credentialsDir.getAbsolutePath());
            }
            
            System.out.println();
            System.out.println("Clearing any expired credentials...");
            YouTubeUploader.clearCredentials();
            System.out.println("✓ Old credentials cleared");
            
            System.out.println();
            System.out.println("Starting YouTube authorization...");
            System.out.println("A browser window will open in a few seconds.");
            System.out.println("Please sign in and grant permissions.");
            System.out.println();
            
            // Create a test file for upload
            File testFile = File.createTempFile("youtube_auth_test_", ".txt");
            testFile.deleteOnExit();
            
            final NetHttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
            
            // This will trigger the OAuth flow and open browser
            System.out.println("Opening browser for authorization...");
            YouTubeUploader.uploadVideo(
                testFile,
                "Test Authorization",
                "This is a test to authorize YouTube API",
                java.util.Arrays.asList("test"),
                "27",
                "private"
            );
            
            System.out.println();
            System.out.println("========================================");
            System.out.println("✅ SUCCESS! YouTube Authorized!");
            System.out.println("========================================");
            System.out.println();
            System.out.println("Credentials saved to: " + credentialsDir.getAbsolutePath());
            System.out.println();
            System.out.println("You can now upload videos from your application!");
            System.out.println("The authorization is saved and will auto-refresh.");
            System.out.println();
            
        } catch (Exception e) {
            System.err.println();
            System.err.println("========================================");
            System.err.println("❌ ERROR: Authorization Failed");
            System.err.println("========================================");
            System.err.println();
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            System.err.println();
            System.err.println("TROUBLESHOOTING:");
            System.err.println("1. Make sure you have internet connection");
            System.err.println("2. Make sure client_secret.json exists in src/main/resources/");
            System.err.println("3. Sign in with the correct Google account that owns the YouTube channel");
            System.err.println("4. Click 'Allow' when prompted for permissions");
            System.err.println();
        }
    }
}
