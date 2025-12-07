package com.vjnt.util;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.extensions.java6.auth.oauth2.AuthorizationCodeInstalledApp;
import com.google.api.client.extensions.jetty.auth.oauth2.LocalServerReceiver;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.auth.oauth2.GoogleClientSecrets;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.googleapis.media.MediaHttpUploader;
import com.google.api.client.googleapis.media.MediaHttpUploaderProgressListener;
import com.google.api.client.http.InputStreamContent;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.client.util.store.FileDataStoreFactory;
import com.google.api.services.youtube.YouTube;
import com.google.api.services.youtube.model.Video;
import com.google.api.services.youtube.model.VideoSnippet;
import com.google.api.services.youtube.model.VideoStatus;

import java.io.*;
import java.security.GeneralSecurityException;
import java.util.Arrays;
import java.util.List;

/**
 * YouTube Video Uploader
 * Uploads videos directly to YouTube channel using YouTube Data API v3
 */
public class YouTubeUploader {
    
    private static final String APPLICATION_NAME = "VJNT Class Managemen";
    private static final JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();
    
    // Scopes required for uploading videos
    private static final List<String> SCOPES = Arrays.asList(
        "https://www.googleapis.com/auth/youtube.upload",
        "https://www.googleapis.com/auth/youtube"
    );
    
    private static final String CLIENT_SECRETS_FILE = "client_secret.json";
    private static final String CREDENTIALS_FOLDER = "credentials";
    
    /**
     * Create an authorized Credential object
     */
    private static Credential getCredentials(final NetHttpTransport httpTransport) throws IOException {
        // Load client secrets - use absolute path with proper normalization
        String secretFilePath = "C:\\Users\\Admin\\V2Project\\VJNT Class Managment\\src\\main\\resources\\" + CLIENT_SECRETS_FILE;
        File secretFile = new File(secretFilePath);
        
        InputStream in = null;
        if (secretFile.exists()) {
            System.out.println("Found client_secret.json at: " + secretFile.getAbsolutePath());
            in = new FileInputStream(secretFile);
        } else {
            System.out.println("File not found at: " + secretFile.getAbsolutePath());
            // Try classpath as fallback
            in = YouTubeUploader.class.getClassLoader().getResourceAsStream(CLIENT_SECRETS_FILE);
            if (in == null) {
                throw new FileNotFoundException("Resource not found: " + CLIENT_SECRETS_FILE + 
                    ". Searched at " + secretFilePath + " and classpath");
            }
        }
        
        GoogleClientSecrets clientSecrets = GoogleClientSecrets.load(JSON_FACTORY, new InputStreamReader(in));
        
        // Create credentials folder if it doesn't exist
        File credentialsFolder = new File(CREDENTIALS_FOLDER);
        if (!credentialsFolder.exists()) {
            credentialsFolder.mkdirs();
            System.out.println("Created credentials folder at: " + credentialsFolder.getAbsolutePath());
        }
        
        // Build flow and trigger user authorization request
        GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(
                httpTransport, JSON_FACTORY, clientSecrets, SCOPES)
                .setDataStoreFactory(new FileDataStoreFactory(credentialsFolder))
                .setAccessType("offline")
                .setApprovalPrompt("force") // Force re-authorization if needed
                .build();
        
        LocalServerReceiver receiver = new LocalServerReceiver.Builder().setPort(8888).build();
        return new AuthorizationCodeInstalledApp(flow, receiver).authorize("user");
    }
    
    /**
     * Clear expired credentials to force re-authorization
     */
    public static void clearCredentials() {
        File credentialsFolder = new File(CREDENTIALS_FOLDER);
        if (credentialsFolder.exists() && credentialsFolder.isDirectory()) {
            File[] files = credentialsFolder.listFiles();
            if (files != null) {
                for (File file : files) {
                    if (file.isFile()) {
                        boolean deleted = file.delete();
                        System.out.println("Deleted credential file: " + file.getName() + " - " + deleted);
                    }
                }
            }
            System.out.println("Cleared all stored credentials");
        }
    }
    
    /**
     * Upload video to YouTube
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
        
        final NetHttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
        
        // Build a new authorized API client service
        YouTube youtubeService = new YouTube.Builder(httpTransport, JSON_FACTORY, getCredentials(httpTransport))
                .setApplicationName(APPLICATION_NAME)
                .build();
        
        // Create Video object with metadata
        Video videoObjectDefiningMetadata = new Video();
        
        // Set video snippet (title, description, tags, etc.)
        VideoSnippet snippet = new VideoSnippet();
        
        // Validate and clean title - CRITICAL: YouTube requires non-empty title
        String cleanTitle = sanitizeTitle(title);
        if (cleanTitle == null || cleanTitle.trim().isEmpty()) {
            cleanTitle = "Untitled Video";
        }
        System.out.println("============ YOUTUBE UPLOAD DEBUG ============");
        System.out.println("Original title: [" + title + "]");
        System.out.println("Cleaned title: [" + cleanTitle + "]");
        System.out.println("Title length: " + cleanTitle.length());
        System.out.println("Title bytes: " + java.util.Arrays.toString(cleanTitle.getBytes("UTF-8")));
        System.out.println("Title is null: " + (cleanTitle == null));
        System.out.println("Title is empty: " + (cleanTitle.isEmpty()));
        System.out.println("============================================");
        
        snippet.setTitle(cleanTitle);
        
        // Set description
        String cleanDescription = (description != null && !description.trim().isEmpty()) ? description.trim() : "Educational video from VJNT Class Management";
        snippet.setDescription(cleanDescription);
        
        snippet.setTags(tags);
        snippet.setCategoryId(categoryId != null ? categoryId : "27"); // 27 = Education
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
                        System.out.println("Upload in progress: " + uploader.getProgress());
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
        
        System.out.println("\n================== Returned Video ==================\n");
        System.out.println("  - Id: " + returnedVideo.getId());
        System.out.println("  - Title: " + returnedVideo.getSnippet().getTitle());
        System.out.println("  - Status: " + returnedVideo.getStatus().getPrivacyStatus());
        System.out.println("  - URL: https://www.youtube.com/watch?v=" + returnedVideo.getId());
        
        return returnedVideo.getId();
    }
    
    /**
     * Upload video with progress callback
     */
    public static String uploadVideoWithProgress(File videoFile, String title, String description,
                                                 List<String> tags, UploadProgressCallback callback)
            throws IOException, GeneralSecurityException {
        
        final NetHttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
        
        YouTube youtubeService = new YouTube.Builder(httpTransport, JSON_FACTORY, getCredentials(httpTransport))
                .setApplicationName(APPLICATION_NAME)
                .build();
        
        Video videoObjectDefiningMetadata = new Video();
        
        VideoSnippet snippet = new VideoSnippet();
        
        // Validate and clean title - CRITICAL: YouTube requires non-empty title
        String cleanTitle = sanitizeTitle(title);
        if (cleanTitle == null || cleanTitle.trim().isEmpty()) {
            cleanTitle = "Untitled Video";
        }
        System.out.println("Setting video title: " + cleanTitle);
        snippet.setTitle(cleanTitle);
        
        // Set description
        String cleanDescription = (description != null && !description.trim().isEmpty()) ? description.trim() : "Educational video from VJNT Class Management";
        snippet.setDescription(cleanDescription);
        
        snippet.setTags(tags);
        snippet.setCategoryId("27"); // Education
        videoObjectDefiningMetadata.setSnippet(snippet);
        
        VideoStatus status = new VideoStatus();
        status.setPrivacyStatus("unlisted"); // Default to unlisted
        videoObjectDefiningMetadata.setStatus(status);
        
        InputStreamContent mediaContent = new InputStreamContent(
            "video/*",
            new BufferedInputStream(new FileInputStream(videoFile))
        );
        mediaContent.setLength(videoFile.length());
        
        YouTube.Videos.Insert videoInsert = youtubeService.videos()
                .insert(Arrays.asList("snippet", "status"), videoObjectDefiningMetadata, mediaContent);
        
        MediaHttpUploader uploader = videoInsert.getMediaHttpUploader();
        uploader.setDirectUploadEnabled(false);
        
        uploader.setProgressListener(new MediaHttpUploaderProgressListener() {
            @Override
            public void progressChanged(MediaHttpUploader uploader) throws IOException {
                double progress = uploader.getProgress() * 100;
                if (callback != null) {
                    callback.onProgress(progress, uploader.getUploadState().toString());
                }
            }
        });
        
        Video returnedVideo = videoInsert.execute();
        
        if (callback != null) {
            callback.onComplete(returnedVideo.getId());
        }
        
        return returnedVideo.getId();
    }
    
    /**
     * Sanitize and validate video title for YouTube API
     * YouTube API requires:
     * - Title must not be empty
     * - Title must not exceed 100 characters
     * - Title must not contain only whitespace
     */
    private static String sanitizeTitle(String title) {
        if (title == null) {
            System.err.println("Title is null!");
            return "Untitled Video";
        }
        
        // Trim whitespace
        String trimmed = title.trim();
        
        // Check if empty after trimming
        if (trimmed.isEmpty()) {
            System.err.println("Title is empty after trimming!");
            return "Untitled Video";
        }
        
        // Remove any control characters
        String cleaned = trimmed.replaceAll("[\\p{Cc}]", "");
        
        // Ensure it's not just whitespace
        if (cleaned.trim().isEmpty()) {
            System.err.println("Title contains only whitespace/control characters!");
            return "Untitled Video";
        }
        
        // Truncate to 100 characters max (YouTube limit)
        if (cleaned.length() > 100) {
            cleaned = cleaned.substring(0, 100);
        }
        
        return cleaned;
    }
    
    /**
     * Interface for upload progress callbacks
     */
    public interface UploadProgressCallback {
        void onProgress(double progress, String status);
        void onComplete(String videoId);
        void onError(String error);
    }
}
