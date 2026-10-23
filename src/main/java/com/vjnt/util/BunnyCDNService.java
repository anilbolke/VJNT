package com.vjnt.util;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Files;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Bunny CDN Service - Upload, download, and delete videos from Bunny CDN Storage
 * 
 * Storage Zone: vjnt-student1-videos
 * Pull Zone: https://vjnt-student1-videos.b-cdn.net/
 */
public class BunnyCDNService {
    
    // Bunny CDN Configuration - loaded from bunnycdn.properties via BunnyCDNConfig
    private static final String STORAGE_ZONE_NAME = BunnyCDNConfig.getStorageZoneName();
    private static final String API_KEY = BunnyCDNConfig.getStoragePassword();
    private static final String PULL_ZONE_URL = BunnyCDNConfig.getPullZoneUrl(); // Public CDN pull zone
    private static final String STORAGE_API_URL = BunnyCDNConfig.getStorageApiUrl();
    
    // Video storage path pattern: /videos/{year}/{month}/{udise}/{filename}
    private static final String VIDEO_PATH_FORMAT = "videos/%s/%s/%s";
    
    /**
     * Upload video file to Bunny CDN Storage
     * 
     * @param videoFile The video file to upload
     * @param originalFileName Original file name
     * @param udiseNo School UDISE number
     * @return CDN URL of uploaded video
     * @throws IOException If upload fails
     */
    public static String uploadVideo(File videoFile, String originalFileName, String udiseNo) throws IOException {

        // Generate unique filename to avoid collisions
        String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
        String fileExtension = getFileExtension(originalFileName);
        String uniqueFileName = "video_" + timestamp + "_" + System.currentTimeMillis() + fileExtension;

        // Build storage path: /videos/2024/12/UDISE123/video_20241229_123456.mp4
        SimpleDateFormat yearFormat = new SimpleDateFormat("yyyy");
        SimpleDateFormat monthFormat = new SimpleDateFormat("MM");
        String year = yearFormat.format(new Date());
        String month = monthFormat.format(new Date());
        String storagePath = String.format(VIDEO_PATH_FORMAT, year, month, udiseNo);
        String fullPath = storagePath + "/" + uniqueFileName;

        // Remove the dot from the extension for the MIME subtype, as before.
        return uploadFile(videoFile, fullPath, "video/" + fileExtension.substring(1));
    }

    /**
     * Upload any file to Bunny CDN Storage and return its public pull-zone URL.
     *
     * Extracted from {@link #uploadVideo}, whose storage path and Content-Type were hardcoded for
     * video. The PUT itself was already generic, and the coordinator alerts need to host a PDF —
     * so the transport lives here once and callers own their own naming.
     *
     * <p><b>The returned URL is public and unauthenticated.</b> Anyone holding it can read the file,
     * and it does not expire. Do not upload anything that should not be world-readable, and delete
     * files that no longer need to exist (see {@link #deleteFile}).
     *
     * @param file        local file to upload
     * @param remotePath  path within the storage zone, no leading slash,
     *                    e.g. {@code "alerts/2026/08/DISTRICT/Latur_NotStarted_Phase1.pdf"}
     * @param contentType MIME type, e.g. {@code "application/pdf"}
     * @return public CDN URL of the uploaded file
     * @throws IOException if the upload is rejected
     */
    public static String uploadFile(File file, String remotePath, String contentType) throws IOException {
        if (file == null || !file.isFile()) {
            throw new IOException("Upload source is missing: " + file);
        }
        String cleanPath = remotePath == null ? "" : remotePath.replaceAll("^/+", "");
        if (cleanPath.isEmpty()) {
            throw new IOException("Upload path is required");
        }

        String uploadUrl = STORAGE_API_URL + "/" + STORAGE_ZONE_NAME + "/" + cleanPath;

        HttpURLConnection connection = null;
        try {
            URL url = new URL(uploadUrl);
            connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("PUT");
            connection.setDoOutput(true);
            connection.setConnectTimeout(15000);
            connection.setReadTimeout(60000);

            // Same three header spellings the video upload has always sent; the storage API accepts
            // AccessKey, and the others are harmless.
            connection.setRequestProperty("AccessKey", API_KEY);
            connection.setRequestProperty("Authorization", API_KEY);
            connection.setRequestProperty("X-Auth-Token", API_KEY);
            connection.setRequestProperty("Content-Type",
                    contentType == null ? "application/octet-stream" : contentType);
            connection.setRequestProperty("Content-Length", String.valueOf(file.length()));

            try (FileInputStream fileInputStream = new FileInputStream(file);
                 OutputStream outputStream = connection.getOutputStream()) {

                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = fileInputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
                }
                outputStream.flush();
            }

            int responseCode = connection.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_CREATED || responseCode == HttpURLConnection.HTTP_OK) {
                return PULL_ZONE_URL + "/" + cleanPath;
            }

            String errorMessage = readErrorResponse(connection);
            System.err.println("[BunnyCDN] Upload failed with code: " + responseCode);
            System.err.println("[BunnyCDN] Error: " + errorMessage);
            throw new IOException("Upload failed: " + responseCode + " - " + errorMessage);

        } finally {
            if (connection != null) {
                connection.disconnect();
            }
        }
    }

    /**
     * Delete any file previously uploaded by {@link #uploadFile}, by its public CDN URL.
     *
     * Same DELETE as {@link #deleteVideo}; named for the general case so a retention sweep does not
     * read as if it were removing videos.
     */
    public static boolean deleteFile(String cdnUrl) throws IOException {
        return deleteVideo(cdnUrl);
    }
    
    /**
     * Delete video from Bunny CDN Storage
     * 
     * @param cdnUrl The CDN URL of the video to delete
     * @return true if deleted successfully
     * @throws IOException If deletion fails
     */
    public static boolean deleteVideo(String cdnUrl) throws IOException {
        
        // Extract path from CDN URL
        String path = cdnUrl.replace(PULL_ZONE_URL + "/", "");
        String deleteUrl = STORAGE_API_URL + "/" + STORAGE_ZONE_NAME + "/" + path;
        
        
        HttpURLConnection connection = null;
        
        try {
            URL url = new URL(deleteUrl);
            connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("DELETE");
            connection.setRequestProperty("AccessKey", API_KEY);
            
            int responseCode = connection.getResponseCode();
            
            if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_NO_CONTENT) {
                return true;
            } else {
                String errorMessage = readErrorResponse(connection);
                System.err.println("Delete failed: " + responseCode + " - " + errorMessage);
                return false;
            }
            
        } finally {
            if (connection != null) {
                connection.disconnect();
            }
        }
    }
    
    /**
     * Check if video exists on Bunny CDN
     * 
     * @param cdnUrl The CDN URL to check
     * @return true if video exists
     */
    public static boolean videoExists(String cdnUrl) {
        try {
            URL url = new URL(cdnUrl);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("HEAD");
            connection.setConnectTimeout(5000);
            connection.setReadTimeout(5000);
            
            int responseCode = connection.getResponseCode();
            connection.disconnect();
            
            return responseCode == HttpURLConnection.HTTP_OK;
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Get thumbnail URL for video
     * Bunny CDN automatically generates thumbnails for videos
     * 
     * @param cdnUrl The CDN URL of the video
     * @return Thumbnail URL
     */
    public static String getThumbnailUrl(String cdnUrl) {
        // Bunny CDN auto-generates thumbnails
        // Format: video-url + ?thumbnail=true
        return cdnUrl + "?thumbnail=true";
    }
    
    /**
     * Get file extension from filename
     */
    private static String getFileExtension(String fileName) {
        if (fileName == null || fileName.isEmpty()) {
            return ".mp4"; // Default
        }
        int lastDot = fileName.lastIndexOf('.');
        return lastDot > 0 ? fileName.substring(lastDot) : ".mp4";
    }
    
    /**
     * Read error response from connection
     */
    private static String readErrorResponse(HttpURLConnection connection) {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(
                    connection.getErrorStream() != null ? 
                    connection.getErrorStream() : connection.getInputStream()))) {
            
            StringBuilder response = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                response.append(line);
            }
            return response.toString();
        } catch (Exception e) {
            return "Unknown error";
        }
    }
    
    /**
     * Format file size for display
     */
    public static String formatFileSize(long bytes) {
        if (bytes < 1024) {
            return bytes + " B";
        } else if (bytes < 1024 * 1024) {
            return String.format("%.2f KB", bytes / 1024.0);
        } else {
            return String.format("%.2f MB", bytes / (1024.0 * 1024.0));
        }
    }
    
    /**
     * Test connection to Bunny CDN
     */
    public static boolean testConnection() {
        try {
            
            // Try to list files (will return 404 if empty, but proves connection works)
            String testUrl = STORAGE_API_URL + "/" + STORAGE_ZONE_NAME + "/";
            URL url = new URL(testUrl);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setRequestProperty("AccessKey", API_KEY);
            connection.setConnectTimeout(5000);
            
            int responseCode = connection.getResponseCode();
            connection.disconnect();
            
            
            return responseCode < 500; // Any code under 500 means connection is working
        } catch (Exception e) {
            System.err.println("Connection test failed: " + e.getMessage());
            return false;
        }
    }
}
