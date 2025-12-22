package com.vjnt.util;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.extensions.java6.auth.oauth2.AuthorizationCodeInstalledApp;
import com.google.api.client.extensions.jetty.auth.oauth2.LocalServerReceiver;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.auth.oauth2.GoogleClientSecrets;
import com.google.api.client.googleapis.auth.oauth2.GoogleCredential;
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
    
    private static final JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();
    
    // Scopes required for uploading videos
    private static final List<String> SCOPES = Arrays.asList(
        "https://www.googleapis.com/auth/youtube.upload",
        "https://www.googleapis.com/auth/youtube"
    );
    
    /**
     * Create an authorized Credential object
     * Supports both OAuth and Service Account authentication
     */
    private static Credential getCredentials(final NetHttpTransport httpTransport) throws IOException {
        // Check if using Service Account authentication
        if (YouTubeConfig.useServiceAccount()) {
            System.out.println("Using Service Account authentication for production deployment...");
            return getServiceAccountCredentials(httpTransport);
        }
        
        // Otherwise use OAuth authentication
        System.out.println("Using OAuth authentication...");
        return getOAuthCredentials(httpTransport);
    }
    
    /**
     * Get credentials using Service Account (for production/headless servers)
     */
    private static Credential getServiceAccountCredentials(final NetHttpTransport httpTransport) throws IOException {
        InputStream in = null;
        String foundLocation = null;
        String serviceAccountFile = YouTubeConfig.getServiceAccountFile();
        
        System.out.println("Searching for " + serviceAccountFile + "...");
        
        // PRIORITY 1: Try classpath FIRST (packaged in WAR)
        in = YouTubeUploader.class.getClassLoader().getResourceAsStream(serviceAccountFile);
        if (in != null) {
            foundLocation = "classpath:/" + serviceAccountFile;
            System.out.println("✓ SUCCESS: Found " + serviceAccountFile + " in classpath");
        }
        
        // PRIORITY 2: Try as direct resource from class
        if (in == null) {
            in = YouTubeUploader.class.getResourceAsStream("/" + serviceAccountFile);
            if (in != null) {
                foundLocation = "classpath:/" + serviceAccountFile + " (via class loader)";
                System.out.println("✓ SUCCESS: Found " + serviceAccountFile + " via class resource");
            }
        }
        
        // PRIORITY 3: Try WEB-INF/classes directory
        if (in == null) {
            try {
                String catalinaBase = System.getProperty("catalina.base");
                if (catalinaBase != null) {
                    File classesFile = new File(catalinaBase, "webapps/ROOT/WEB-INF/classes/" + serviceAccountFile);
                    if (classesFile.exists()) {
                        in = new FileInputStream(classesFile);
                        foundLocation = classesFile.getAbsolutePath();
                        System.out.println("✓ SUCCESS: Found " + serviceAccountFile + " in WEB-INF/classes");
                    }
                }
            } catch (Exception e) {
                System.out.println("  WEB-INF/classes search: " + e.getMessage());
            }
        }
        
        // PRIORITY 4: Development path
        if (in == null) {
            String devPath = YouTubeConfig.getDevPath() + serviceAccountFile;
            File devFile = new File(devPath);
            if (devFile.exists()) {
                in = new FileInputStream(devFile);
                foundLocation = devFile.getAbsolutePath();
                System.out.println("✓ SUCCESS: Found " + serviceAccountFile + " at development path");
            }
        }
        
        // PRIORITY 5: User home directory
        if (in == null) {
            File userHomeFile = new File(System.getProperty("user.home"), YouTubeConfig.getUserHomeSubfolder() + serviceAccountFile);
            if (userHomeFile.exists()) {
                in = new FileInputStream(userHomeFile);
                foundLocation = userHomeFile.getAbsolutePath();
                System.out.println("✓ SUCCESS: Found " + serviceAccountFile + " in user home");
            }
        }
        
        // PRIORITY 6: Current working directory
        if (in == null) {
            File cwdFile = new File(serviceAccountFile);
            if (cwdFile.exists()) {
                in = new FileInputStream(cwdFile);
                foundLocation = cwdFile.getAbsolutePath();
                System.out.println("✓ SUCCESS: Found " + serviceAccountFile + " in current directory");
            }
        }
        
        if (in == null) {
            throw new FileNotFoundException(
                "\n╔════════════════════════════════════════════════════════════════════╗\n" +
                "║  ERROR: Service Account Key File Not Found                        ║\n" +
                "╚════════════════════════════════════════════════════════════════════╝\n\n" +
                "File: " + serviceAccountFile + "\n\n" +
                "SOLUTION:\n" +
                "  1. Create a Service Account in Google Cloud Console:\n" +
                "     - Go to: https://console.cloud.google.com/iam-admin/serviceaccounts\n" +
                "     - Create a new Service Account with YouTube Data API access\n" +
                "     - Grant the service account access to your YouTube channel\n" +
                "  2. Download the JSON key file\n" +
                "  3. Place it in: src/main/resources/" + serviceAccountFile + "\n" +
                "  4. Rebuild: mvn clean package\n" +
                "  5. Redeploy the WAR file\n\n" +
                "OR switch back to OAuth authentication:\n" +
                "  Set youtube.auth.type=oauth in youtube.properties\n\n"
            );
        }
        
        System.out.println("Loading Service Account credentials from: " + foundLocation);
        
        System.err.println("\n╔════════════════════════════════════════════════════════════════════╗");
        System.err.println("║  WARNING: Service Accounts Do NOT Work with YouTube API!          ║");
        System.err.println("╚════════════════════════════════════════════════════════════════════╝");
        System.err.println("");
        System.err.println("YouTube Data API does NOT support service account authentication.");
        System.err.println("You will get 401 Unauthorized errors when trying to upload.");
        System.err.println("");
        System.err.println("SOLUTION: Use OAuth with stored credentials");
        System.err.println("  1. Set youtube.auth.type=oauth in youtube.properties");
        System.err.println("  2. Authorize on local machine (browser required - one time)");
        System.err.println("  3. Copy 'credentials' folder to production server");
        System.err.println("  4. Tokens will auto-refresh (no browser needed in production)");
        System.err.println("");
        System.err.println("See YOUTUBE_AUTHENTICATION_SOLUTION.md for detailed instructions");
        System.err.println("");
        
        GoogleCredential credential = GoogleCredential.fromStream(in, httpTransport, JSON_FACTORY)
            .createScoped(SCOPES);
        
        System.out.println("✓ Service Account loaded (but will NOT work for YouTube uploads!)");
        System.out.println("  Service Account: " + credential.getServiceAccountId());
        
        return credential;
    }
    
    /**
     * Get credentials using OAuth (for local development with browser)
     */
    private static Credential getOAuthCredentials(final NetHttpTransport httpTransport) throws IOException {
        InputStream in = null;
        String foundLocation = null;
        String clientSecretsFile = YouTubeConfig.getClientSecretsFile();
        
        System.out.println("Searching for " + clientSecretsFile + "...");
        
        // PRIORITY 1: Try classpath FIRST (works in production WAR without any server setup)
        // Files in src/main/resources/ are automatically included in WAR and available on classpath
        in = YouTubeUploader.class.getClassLoader().getResourceAsStream(clientSecretsFile);
        if (in != null) {
            foundLocation = "classpath:/" + clientSecretsFile;
            System.out.println("✓ SUCCESS: Found " + clientSecretsFile + " in classpath (packaged in WAR)");
            System.out.println("  Location: " + foundLocation);
        }
        
        // PRIORITY 2: Try as direct resource from class (alternative classpath method)
        if (in == null) {
            in = YouTubeUploader.class.getResourceAsStream("/" + clientSecretsFile);
            if (in != null) {
                foundLocation = "classpath:/" + clientSecretsFile + " (via class loader)";
                System.out.println("✓ SUCCESS: Found " + clientSecretsFile + " via class resource");
            }
        }
        
        // PRIORITY 3: Try WEB-INF/classes directory (another classpath location)
        if (in == null) {
            try {
                String catalinaBase = System.getProperty("catalina.base");
                if (catalinaBase != null) {
                    // Try WEB-INF/classes first (where resources go in deployed WAR)
                    File classesFile = new File(catalinaBase, "webapps/ROOT/WEB-INF/classes/" + clientSecretsFile);
                    if (classesFile.exists()) {
                        in = new FileInputStream(classesFile);
                        foundLocation = classesFile.getAbsolutePath();
                        System.out.println("✓ SUCCESS: Found " + clientSecretsFile + " in WEB-INF/classes");
                    }
                }
            } catch (Exception e) {
                System.out.println("  WEB-INF/classes search: " + e.getMessage());
            }
        }
        
        // PRIORITY 4: Development path (for local development only)
        if (in == null) {
            String devPath = YouTubeConfig.getDevPath() + clientSecretsFile;
            File devFile = new File(devPath);
            if (devFile.exists()) {
                in = new FileInputStream(devFile);
                foundLocation = devFile.getAbsolutePath();
                System.out.println("✓ SUCCESS: Found " + clientSecretsFile + " at development path");
            }
        }
        
        // PRIORITY 5: User home directory (fallback for custom server config)
        if (in == null) {
            File userHomeFile = new File(System.getProperty("user.home"), YouTubeConfig.getUserHomeSubfolder() + clientSecretsFile);
            if (userHomeFile.exists()) {
                in = new FileInputStream(userHomeFile);
                foundLocation = userHomeFile.getAbsolutePath();
                System.out.println("✓ SUCCESS: Found " + clientSecretsFile + " in user home");
            }
        }
        
        // PRIORITY 6: Current working directory (last resort)
        if (in == null) {
            File cwdFile = new File(clientSecretsFile);
            if (cwdFile.exists()) {
                in = new FileInputStream(cwdFile);
                foundLocation = cwdFile.getAbsolutePath();
                System.out.println("✓ SUCCESS: Found " + clientSecretsFile + " in current directory");
            }
        }
        
        // If still not found, throw detailed error
        if (in == null) {
            String userHome = System.getProperty("user.home");
            String currentDir = new File(".").getAbsolutePath();
            
            StringBuilder errorMsg = new StringBuilder();
            errorMsg.append("\n╔════════════════════════════════════════════════════════════════════╗\n");
            errorMsg.append("║  ERROR: YouTube API Configuration File Not Found                  ║\n");
            errorMsg.append("╚════════════════════════════════════════════════════════════════════╝\n\n");
            errorMsg.append("File: client_secret.json\n\n");
            errorMsg.append("Searched locations:\n");
            errorMsg.append("  ✗ Classpath (packaged in WAR)\n");
            errorMsg.append("  ✗ WEB-INF/classes/ directory\n");
            errorMsg.append("  ✗ Development path\n");
            errorMsg.append("  ✗ User home: ").append(userHome).append("/.vjnt/\n");
            errorMsg.append("  ✗ Current directory: ").append(currentDir).append("\n\n");
            
            errorMsg.append("╔════════════════════════════════════════════════════════════════════╗\n");
            errorMsg.append("║  SOLUTION: Rebuild and Redeploy WAR (NO SERVER CONFIG NEEDED)     ║\n");
            errorMsg.append("╚════════════════════════════════════════════════════════════════════╝\n\n");
            errorMsg.append("The file should already be in your project at:\n");
            errorMsg.append("  src/main/resources/client_secret.json\n\n");
            errorMsg.append("If the file exists there, rebuild and redeploy:\n\n");
            errorMsg.append("  Step 1: Clean and rebuild WAR\n");
            errorMsg.append("    mvn clean package\n\n");
            errorMsg.append("  Step 2: Redeploy the new WAR file to production\n");
            errorMsg.append("    - Stop Tomcat\n");
            errorMsg.append("    - Replace the old WAR file\n");
            errorMsg.append("    - Start Tomcat\n\n");
            errorMsg.append("  The file will be automatically included in the WAR\n");
            errorMsg.append("  and available on the classpath (no server setup needed).\n\n");
            
            errorMsg.append("╔════════════════════════════════════════════════════════════════════╗\n");
            errorMsg.append("║  If file is missing from src/main/resources/:                     ║\n");
            errorMsg.append("╚════════════════════════════════════════════════════════════════════╝\n");
            errorMsg.append("  1. Obtain client_secret.json from Google Cloud Console\n");
            errorMsg.append("  2. Place it in: src/main/resources/client_secret.json\n");
            errorMsg.append("  3. Rebuild: mvn clean package\n");
            errorMsg.append("  4. Redeploy the WAR file\n\n");
            
            throw new FileNotFoundException(errorMsg.toString());
        }
        
        System.out.println("Loading YouTube credentials from: " + foundLocation);
        GoogleClientSecrets clientSecrets = GoogleClientSecrets.load(JSON_FACTORY, new InputStreamReader(in));
        
        // Try to find credentials folder in multiple locations (production-friendly)
        File credentialsFolder = findCredentialsFolder();
        System.out.println("Using credentials folder: " + credentialsFolder.getAbsolutePath());
        
        // CRITICAL FIX: Extract packaged credentials from WAR BEFORE building flow
        // This must happen FIRST on production servers before any credential checks
        System.out.println("=== PRODUCTION FIX: Extracting packaged credentials from WAR ===");
        boolean extractedFromWAR = false;
        try {
            InputStream credStream = YouTubeUploader.class.getClassLoader()
                .getResourceAsStream("credentials/StoredCredential");
            
            if (credStream != null) {
                System.out.println("✓ Found credentials/StoredCredential in WAR classpath!");
                
                // Ensure credentials folder exists
                if (!credentialsFolder.exists()) {
                    credentialsFolder.mkdirs();
                    System.out.println("✓ Created credentials folder: " + credentialsFolder.getAbsolutePath());
                }
                
                // Extract to credentials folder
                File targetFile = new File(credentialsFolder, "StoredCredential");
                java.nio.file.Files.copy(credStream, targetFile.toPath(), 
                    java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                credStream.close();
                
                extractedFromWAR = true;
                System.out.println("✓ EXTRACTED packaged credentials to: " + targetFile.getAbsolutePath());
                System.out.println("✓ File size: " + targetFile.length() + " bytes");
                System.out.println("✓ PRODUCTION SERVER: Credentials ready for use!");
            } else {
                System.out.println("✗ credentials/StoredCredential not found in WAR classpath");
            }
        } catch (Exception e) {
            System.err.println("✗ Error extracting packaged credentials: " + e.getMessage());
            e.printStackTrace();
        }
        
        // Build flow and trigger user authorization request
        GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(
                httpTransport, JSON_FACTORY, clientSecrets, SCOPES)
                .setDataStoreFactory(new FileDataStoreFactory(credentialsFolder))
                .setAccessType("offline")
                .setApprovalPrompt("force") // Force re-authorization if needed
                .build();
        
        // Check if we already have stored credentials (required for production servers)
        Credential credential = flow.loadCredential("user");
        
        if (credential != null && credential.getRefreshToken() != null) {
            System.out.println("✓ SUCCESS: Using stored credentials");
            System.out.println("  Refresh token found - will auto-refresh without browser");
            System.out.println("  Credentials location: " + credentialsFolder.getAbsolutePath());
            if (extractedFromWAR) {
                System.out.println("  Source: Extracted from packaged WAR file");
            }
            return credential;
        }
        
        // CRITICAL: Try loading from classpath BEFORE checking if headless
        // This allows packaged credentials in WAR to work on production servers
        System.out.println("=== ATTEMPTING TO LOAD PACKAGED CREDENTIALS ===");
        System.out.println("Credentials folder: " + credentialsFolder.getAbsolutePath());
        
        // Method 1: Try loading from classpath resources (packaged in WAR)
        System.out.println("Method 1: Checking classpath for credentials/StoredCredential...");
        try {
            InputStream credStream = YouTubeUploader.class.getClassLoader()
                .getResourceAsStream("credentials/StoredCredential");
            
            if (credStream != null) {
                System.out.println("✓ SUCCESS: Found credentials/StoredCredential in classpath!");
                
                // Ensure credentials folder exists
                if (!credentialsFolder.exists()) {
                    credentialsFolder.mkdirs();
                    System.out.println("✓ Created credentials folder: " + credentialsFolder.getAbsolutePath());
                }
                
                // Copy to credentials folder
                File targetFile = new File(credentialsFolder, "StoredCredential");
                java.nio.file.Files.copy(credStream, targetFile.toPath(), 
                    java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                credStream.close();
                
                System.out.println("✓ Extracted packaged credentials to: " + targetFile.getAbsolutePath());
                System.out.println("✓ File size: " + targetFile.length() + " bytes");
                
                // Reload credentials from extracted file
                credential = flow.loadCredential("user");
                if (credential != null) {
                    System.out.println("✓ Loaded credential object");
                    if (credential.getRefreshToken() != null) {
                        System.out.println("✓ SUCCESS: Refresh token found - credentials are valid!");
                        System.out.println("✓ Production server can now upload to YouTube!");
                        return credential;
                    } else {
                        System.out.println("✗ Warning: Credential loaded but no refresh token");
                    }
                } else {
                    System.out.println("✗ Failed to load credential from extracted file");
                }
            } else {
                System.out.println("✗ credentials/StoredCredential not found in classpath");
                System.out.println("   This means WAR file doesn't contain packaged credentials");
            }
        } catch (Exception e) {
            System.err.println("✗ Error loading packaged credentials: " + e.getMessage());
            e.printStackTrace();
        }
        
        // Method 2: Try loading from packaged credentials helper method
        System.out.println("Method 2: Trying tryLoadPackagedCredentials()...");
        File packagedCredentials = tryLoadPackagedCredentials(credentialsFolder);
        if (packagedCredentials != null) {
            System.out.println("✓ tryLoadPackagedCredentials() succeeded");
            credential = flow.loadCredential("user");
            if (credential != null && credential.getRefreshToken() != null) {
                System.out.println("✓ SUCCESS: Using packaged credentials with refresh token");
                return credential;
            }
        } else {
            System.out.println("✗ tryLoadPackagedCredentials() returned null");
        }
        
        System.out.println("=== ALL PACKAGED CREDENTIAL METHODS FAILED ===");
        
        // Check if we're on a headless server (no display)
        String displayEnv = System.getenv("DISPLAY");
        boolean isHeadless = (displayEnv == null || displayEnv.isEmpty()) || 
                            System.getProperty("java.awt.headless", "false").equals("true");
        
        if (isHeadless) {
            // We're on a production server without a display
            System.err.println("╔════════════════════════════════════════════════════════════════════╗");
            System.err.println("║  ERROR: YouTube OAuth requires initial authorization              ║");
            System.err.println("╚════════════════════════════════════════════════════════════════════╝");
            System.err.println("");
            System.err.println("This is a PRODUCTION SERVER (headless environment).");
            System.err.println("YouTube OAuth requires browser-based authorization on first use.");
            System.err.println("");
            System.err.println("Credentials searched in:");
            System.err.println("  - " + credentialsFolder.getAbsolutePath());
            System.err.println("  - Classpath: credentials/StoredCredential");
            System.err.println("  - WAR file resources");
            System.err.println("");
            System.err.println("SOLUTION:");
            System.err.println("  1. Verify StoredCredential is in src/main/resources/credentials/");
            System.err.println("  2. Rebuild WAR file: Export -> WAR file in Eclipse");
            System.err.println("  3. Redeploy WAR to production server");
            System.err.println("  4. Credentials will be automatically loaded from WAR");
            System.err.println("");
            
            throw new IOException("YouTube upload requires initial OAuth authorization. " +
                "Please authorize on a local machine first and copy the credentials folder, " +
                "or use a Service Account for production deployments.");
        }
        
        // We're on a local machine with display - allow interactive authentication
        System.out.println("No stored credentials found. Starting interactive OAuth flow...");
        
        // Use configured port or -1 to automatically find an available port
        int oauthPort = YouTubeConfig.getOAuthReceiverPort();
        LocalServerReceiver receiver = new LocalServerReceiver.Builder()
                .setPort(oauthPort) // -1 means use any available port
                .build();
        
        System.out.println("OAuth receiver using port: " + receiver.getPort());
        System.out.println("A browser window will open for authorization...");
        
        return new AuthorizationCodeInstalledApp(flow, receiver).authorize("user");
    }
    
    /**
     * Clear expired credentials to force re-authorization
     */
    public static void clearCredentials() {
        File credentialsFolder = new File(YouTubeConfig.getCredentialsFolder());
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
                .setApplicationName(YouTubeConfig.getApplicationName())
                .build();
        
        // Create Video object with metadata
        Video videoObjectDefiningMetadata = new Video();
        
        // Set video snippet (title, description, tags, etc.)
        VideoSnippet snippet = new VideoSnippet();
        
        // Validate and clean title - CRITICAL: YouTube requires non-empty title
        String cleanTitle = sanitizeTitle(title);
        if (cleanTitle == null || cleanTitle.trim().isEmpty()) {
            cleanTitle = YouTubeConfig.getFallbackTitle();
        }
        
        if (YouTubeConfig.isDebugEnabled()) {
            System.out.println("============ YOUTUBE UPLOAD DEBUG ============");
            System.out.println("Original title: [" + title + "]");
            System.out.println("Cleaned title: [" + cleanTitle + "]");
            System.out.println("Title length: " + cleanTitle.length());
            System.out.println("Title bytes: " + java.util.Arrays.toString(cleanTitle.getBytes("UTF-8")));
            System.out.println("Title is null: " + (cleanTitle == null));
            System.out.println("Title is empty: " + (cleanTitle.isEmpty()));
            System.out.println("============================================");
        }
        
        snippet.setTitle(cleanTitle);
        
        // Set description
        String cleanDescription = (description != null && !description.trim().isEmpty()) 
            ? description.trim() 
            : YouTubeConfig.getDefaultDescription();
        snippet.setDescription(cleanDescription);
        
        snippet.setTags(tags);
        snippet.setCategoryId(categoryId != null ? categoryId : YouTubeConfig.getDefaultCategoryId());
        videoObjectDefiningMetadata.setSnippet(snippet);
        
        // Set video status (privacy)
        VideoStatus status = new VideoStatus();
        status.setPrivacyStatus(privacyStatus != null ? privacyStatus : YouTubeConfig.getDefaultPrivacyStatus());
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
        uploader.setDirectUploadEnabled(YouTubeConfig.isDirectUploadEnabled());
        
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
                .setApplicationName(YouTubeConfig.getApplicationName())
                .build();
        
        Video videoObjectDefiningMetadata = new Video();
        
        VideoSnippet snippet = new VideoSnippet();
        
        // Validate and clean title - CRITICAL: YouTube requires non-empty title
        String cleanTitle = sanitizeTitle(title);
        if (cleanTitle == null || cleanTitle.trim().isEmpty()) {
            cleanTitle = YouTubeConfig.getFallbackTitle();
        }
        System.out.println("Setting video title: " + cleanTitle);
        snippet.setTitle(cleanTitle);
        
        // Set description
        String cleanDescription = (description != null && !description.trim().isEmpty()) 
            ? description.trim() 
            : YouTubeConfig.getDefaultDescription();
        snippet.setDescription(cleanDescription);
        
        snippet.setTags(tags);
        snippet.setCategoryId(YouTubeConfig.getDefaultCategoryId());
        videoObjectDefiningMetadata.setSnippet(snippet);
        
        VideoStatus status = new VideoStatus();
        status.setPrivacyStatus(YouTubeConfig.getDefaultPrivacyStatus());
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
     * - Title must not exceed configured max length (default 100 characters)
     * - Title must not contain only whitespace
     */
    private static String sanitizeTitle(String title) {
        if (title == null) {
            System.err.println("Title is null!");
            return YouTubeConfig.getFallbackTitle();
        }
        
        // Trim whitespace
        String trimmed = title.trim();
        
        // Check if empty after trimming
        if (trimmed.isEmpty()) {
            System.err.println("Title is empty after trimming!");
            return YouTubeConfig.getFallbackTitle();
        }
        
        // Remove any control characters
        String cleaned = trimmed.replaceAll("[\\p{Cc}]", "");
        
        // Ensure it's not just whitespace
        if (cleaned.trim().isEmpty()) {
            System.err.println("Title contains only whitespace/control characters!");
            return YouTubeConfig.getFallbackTitle();
        }
        
        // Truncate to configured max length (YouTube limit)
        int maxLength = YouTubeConfig.getMaxTitleLength();
        if (cleaned.length() > maxLength) {
            cleaned = cleaned.substring(0, maxLength);
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
    
    /**
     * Find credentials folder in multiple locations (production-friendly)
     * Priority order:
     * 1. Inside WAR (WEB-INF/classes/credentials) - for packaged credentials
     * 2. Tomcat/webapps folder - for persistent storage
     * 3. User home directory - for per-user credentials
     * 4. Current working directory - fallback
     */
    private static File findCredentialsFolder() {
        File credentialsFolder = null;
        
        // PRIORITY 1: Check inside WAR/classpath (for packaged credentials)
        try {
            String catalinaBase = System.getProperty("catalina.base");
            if (catalinaBase != null) {
                File warCredentials = new File(catalinaBase, "webapps/ROOT/WEB-INF/classes/" + YouTubeConfig.getCredentialsFolder());
                if (warCredentials.exists() && warCredentials.isDirectory()) {
                    System.out.println("✓ Found credentials folder inside WAR: " + warCredentials.getAbsolutePath());
                    return warCredentials;
                }
            }
        } catch (Exception e) {
            // Continue to next option
        }
        
        // PRIORITY 2: Check webapps folder (writable location for token refresh)
        try {
            String catalinaBase = System.getProperty("catalina.base");
            if (catalinaBase != null) {
                File webappsCredentials = new File(catalinaBase, "webapps/" + YouTubeConfig.getCredentialsFolder());
                if (webappsCredentials.exists() || webappsCredentials.mkdirs()) {
                    System.out.println("Using credentials folder in webapps: " + webappsCredentials.getAbsolutePath());
                    return webappsCredentials;
                }
            }
        } catch (Exception e) {
            // Continue to next option
        }
        
        // PRIORITY 3: Check user home directory
        try {
            File userHomeCredentials = new File(System.getProperty("user.home"), YouTubeConfig.getUserHomeSubfolder() + YouTubeConfig.getCredentialsFolder());
            if (userHomeCredentials.exists() || userHomeCredentials.mkdirs()) {
                System.out.println("Using credentials folder in user home: " + userHomeCredentials.getAbsolutePath());
                return userHomeCredentials;
            }
        } catch (Exception e) {
            // Continue to next option
        }
        
        // PRIORITY 4: Fallback to relative path (local development)
        credentialsFolder = new File(YouTubeConfig.getCredentialsFolder());
        if (!credentialsFolder.exists()) {
            credentialsFolder.mkdirs();
        }
        System.out.println("Using credentials folder (relative): " + credentialsFolder.getAbsolutePath());
        return credentialsFolder;
    }
    
    /**
     * Try to load packaged credentials from WAR file
     * This allows pre-authorized credentials to be packaged in the WAR
     */
    private static File tryLoadPackagedCredentials(File targetFolder) {
        try {
            // Try to find StoredCredential in classpath (packaged in WAR)
            InputStream credStream = YouTubeUploader.class.getClassLoader()
                .getResourceAsStream(YouTubeConfig.getCredentialsFolder() + "/StoredCredential");
            
            if (credStream != null) {
                System.out.println("✓ Found packaged credentials in WAR");
                
                // Copy to target folder for the DataStoreFactory to use
                File targetFile = new File(targetFolder, "StoredCredential");
                targetFolder.mkdirs();
                
                try (FileOutputStream out = new FileOutputStream(targetFile)) {
                    byte[] buffer = new byte[8192];
                    int bytesRead;
                    while ((bytesRead = credStream.read(buffer)) != -1) {
                        out.write(buffer, 0, bytesRead);
                    }
                }
                credStream.close();
                
                System.out.println("✓ Copied packaged credentials to: " + targetFile.getAbsolutePath());
                return targetFile;
            }
        } catch (Exception e) {
            System.out.println("No packaged credentials found (this is OK if authorizing for first time)");
        }
        
        return null;
    }
}
