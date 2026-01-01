package com.vjnt.util;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.googleapis.auth.oauth2.GoogleCredential;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.googleapis.media.MediaHttpUploader;
import com.google.api.client.googleapis.media.MediaHttpUploaderProgressListener;
import com.google.api.client.http.InputStreamContent;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.services.youtube.YouTube;
import com.google.api.services.youtube.model.Video;
import com.google.api.services.youtube.model.VideoSnippet;
import com.google.api.services.youtube.model.VideoStatus;

import java.io.*;
import java.security.GeneralSecurityException;
import java.util.Arrays;
import java.util.List;

/**
 * YouTube Video Uploader V2 - Database Credentials Edition
 * Uses OAuth credentials stored in database instead of files
 */
public class YouTubeUploaderV2 {
    
    private static final JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();
    private static final String APPLICATION_NAME = "VJNT Class Management";
    
    /**
     * Upload video to YouTube using database-stored credentials
     * 
     * @param videoFile The video file to upload
     * @param title Video title
     * @param description Video description
     * @param tags Video tags
     * @param categoryId YouTube category ID (27 = Education)
     * @param privacyStatus "public", "private", or "unlisted"
     * @return Video ID of uploaded video
     */
    public static String uploadVideo(File videoFile, String title, String description, 
                                    List<String> tags, String categoryId, String privacyStatus) 
            throws IOException, GeneralSecurityException {
        
        System.out.println("=== YouTube Upload V2 - Database Credentials ===");
        
        // Get credentials from database
        YouTubeCredentialManager.YouTubeCredential dbCred = 
            YouTubeCredentialManager.getCredentials();
        
        if (dbCred == null) {
            throw new IOException("No YouTube credentials found in database. " +
                "Please run /authorize-youtube to set up OAuth.");
        }
        
        System.out.println("✓ Retrieved credentials from database");
        
        // Check if token needs refresh
        boolean needsRefresh = false;
        if (dbCred.getTokenExpiry() != null) {
            long now = System.currentTimeMillis();
            long expiry = dbCred.getTokenExpiry().getTime();
            
            // If expires in less than 5 minutes, refresh now
            if (expiry - now < 300000) {
                needsRefresh = true;
                System.out.println("⚠ Access token expired or expiring soon, will refresh");
            }
        }
        
        // Build credential object
        final NetHttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
        
        GoogleCredential.Builder credentialBuilder = new GoogleCredential.Builder()
            .setTransport(httpTransport)
            .setJsonFactory(JSON_FACTORY)
            .setClientSecrets(dbCred.getClientId(), dbCred.getClientSecret());
        
        GoogleCredential credential = credentialBuilder.build();
        credential.setAccessToken(dbCred.getAccessToken());
        credential.setRefreshToken(dbCred.getRefreshToken());
        
        // Refresh if needed
        if (needsRefresh || credential.getAccessToken() == null) {
            System.out.println("Refreshing access token...");
            boolean refreshed = credential.refreshToken();
            
            if (refreshed) {
                System.out.println("✓ Token refreshed successfully");
                
                // Update database with new token
                long expiresInSeconds = credential.getExpiresInSeconds() != null ? 
                                       credential.getExpiresInSeconds() : 3600;
                
                YouTubeCredentialManager.updateAccessToken(
                    credential.getAccessToken(), 
                    expiresInSeconds
                );
            } else {
                throw new IOException("Failed to refresh access token. Please re-authorize.");
            }
        }
        
        // Build YouTube service
        YouTube youtubeService = new YouTube.Builder(httpTransport, JSON_FACTORY, credential)
                .setApplicationName(APPLICATION_NAME)
                .build();
        
        // Create Video object with metadata
        Video videoObjectDefiningMetadata = new Video();
        
        // Set video snippet (title, description, tags, etc.)
        VideoSnippet snippet = new VideoSnippet();
        
        // Validate and clean title
        String cleanTitle = sanitizeTitle(title);
        if (cleanTitle == null || cleanTitle.trim().isEmpty()) {
            cleanTitle = "Student Progress Video";
        }
        
        snippet.setTitle(cleanTitle);
        snippet.setDescription(description != null ? description : "Educational video from VJNT");
        snippet.setTags(tags);
        snippet.setCategoryId(categoryId != null ? categoryId : "27");
        videoObjectDefiningMetadata.setSnippet(snippet);
        
        // Set video status (privacy)
        VideoStatus status = new VideoStatus();
        status.setPrivacyStatus(privacyStatus != null ? privacyStatus : "unlisted");
        videoObjectDefiningMetadata.setStatus(status);
        
        // Create video file input stream
        InputStreamContent mediaContent = new InputStreamContent(
            "video/*", 
            new BufferedInputStream(new FileInputStream(videoFile))
        );
        mediaContent.setLength(videoFile.length());
        
        System.out.println("Uploading video: " + cleanTitle);
        System.out.println("File size: " + (videoFile.length() / 1024 / 1024) + " MB");
        System.out.println("Privacy: " + privacyStatus);
        
        // Create the video insert request
        YouTube.Videos.Insert videoInsert = youtubeService.videos()
                .insert(Arrays.asList("snippet", "status"), videoObjectDefiningMetadata, mediaContent);
        
        // Set the upload type and add progress listener
        MediaHttpUploader uploader = videoInsert.getMediaHttpUploader();
        uploader.setDirectUploadEnabled(false);
        
        // Add progress listener
        uploader.setProgressListener(new MediaHttpUploaderProgressListener() {
            @Override
            public void progressChanged(MediaHttpUploader uploader) throws IOException {
                switch (uploader.getUploadState()) {
                    case INITIATION_STARTED:
                        System.out.println("Initiation Started");
                        break;
                    case INITIATION_COMPLETE:
                        System.out.println("Initiation Completed");
                        break;
                    case MEDIA_IN_PROGRESS:
                        System.out.printf("Upload progress: %.2f%%\n", uploader.getProgress() * 100);
                        break;
                    case MEDIA_COMPLETE:
                        System.out.println("Upload Completed!");
                        break;
                    case NOT_STARTED:
                        System.out.println("Upload Not Started!");
                        break;
                }
            }
        });
        
        // Execute upload
        Video returnedVideo = videoInsert.execute();
        
        System.out.println("\n=== Upload Successful ===");
        System.out.println("Video ID: " + returnedVideo.getId());
        System.out.println("Title: " + returnedVideo.getSnippet().getTitle());
        System.out.println("Privacy: " + returnedVideo.getStatus().getPrivacyStatus());
        System.out.println("URL: https://www.youtube.com/watch?v=" + returnedVideo.getId());
        System.out.println("========================\n");
        
        return returnedVideo.getId();
    }
    
    /**
     * Sanitize and validate video title for YouTube API
     */
    private static String sanitizeTitle(String title) {
        if (title == null) {
            return "Student Progress Video";
        }
        
        // Trim whitespace
        String trimmed = title.trim();
        
        // Check if empty after trimming
        if (trimmed.isEmpty()) {
            return "Student Progress Video";
        }
        
        // Remove any control characters
        String cleaned = trimmed.replaceAll("[\\p{Cc}]", "");
        
        // Ensure it's not just whitespace
        if (cleaned.trim().isEmpty()) {
            return "Student Progress Video";
        }
        
        // Truncate to YouTube's 100-character limit
        if (cleaned.length() > 100) {
            cleaned = cleaned.substring(0, 100);
        }
        
        return cleaned;
    }
    
    /**
     * Check if credentials are configured
     */
    public static boolean isConfigured() {
        return YouTubeCredentialManager.hasValidCredentials();
    }
}
