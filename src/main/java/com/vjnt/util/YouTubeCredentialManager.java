package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/**
 * Manages YouTube OAuth credentials stored in database
 * This eliminates the need for file-based credential storage
 */
public class YouTubeCredentialManager {
    
    /**
     * Store YouTube OAuth credentials in database
     */
    public static boolean storeCredentials(String accessToken, String refreshToken, 
                                          String clientId, String clientSecret, 
                                          long expiresInSeconds) {
        String sql = "INSERT INTO youtube_credentials (credential_name, access_token, refresh_token, " +
                    "client_id, client_secret, token_expiry, is_active, last_refresh_date) " +
                    "VALUES ('default', ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND), TRUE, NOW()) " +
                    "ON DUPLICATE KEY UPDATE " +
                    "access_token = VALUES(access_token), " +
                    "refresh_token = VALUES(refresh_token), " +
                    "client_id = VALUES(client_id), " +
                    "client_secret = VALUES(client_secret), " +
                    "token_expiry = VALUES(token_expiry), " +
                    "is_active = TRUE, " +
                    "last_refresh_date = NOW()";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, accessToken);
            pstmt.setString(2, refreshToken);
            pstmt.setString(3, clientId);
            pstmt.setString(4, clientSecret);
            pstmt.setLong(5, expiresInSeconds);
            
            int result = pstmt.executeUpdate();
            //System.out.println("✓ YouTube credentials stored in database");
            return result > 0;
            
        } catch (SQLException e) {
            System.err.println("Error storing YouTube credentials: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Get YouTube OAuth credentials from database
     */
    public static YouTubeCredential getCredentials() {
        String sql = "SELECT access_token, refresh_token, client_id, client_secret, token_expiry " +
                    "FROM youtube_credentials " +
                    "WHERE credential_name = 'default' AND is_active = TRUE";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            if (rs.next()) {
                YouTubeCredential credential = new YouTubeCredential();
                credential.setAccessToken(rs.getString("access_token"));
                credential.setRefreshToken(rs.getString("refresh_token"));
                credential.setClientId(rs.getString("client_id"));
                credential.setClientSecret(rs.getString("client_secret"));
                credential.setTokenExpiry(rs.getTimestamp("token_expiry"));
                
                return credential;
            }
            
        } catch (SQLException e) {
            System.err.println("Error retrieving YouTube credentials: " + e.getMessage());
            e.printStackTrace();
        }
        
        return null;
    }
    
    /**
     * Check if valid credentials exist in database
     */
    public static boolean hasValidCredentials() {
        YouTubeCredential cred = getCredentials();
        if (cred == null) {
            return false;
        }
        
        // Check if token is still valid (not expired)
        if (cred.getTokenExpiry() != null) {
            long now = System.currentTimeMillis();
            long expiry = cred.getTokenExpiry().getTime();
            
            // Token expires in less than 5 minutes - consider it expired
            if (expiry - now < 300000) {
                return false;
            }
        }
        
        return cred.getAccessToken() != null && 
               !cred.getAccessToken().equals("PLACEHOLDER") &&
               cred.getRefreshToken() != null &&
               !cred.getRefreshToken().equals("PLACEHOLDER");
    }
    
    /**
     * Update access token after refresh
     */
    public static boolean updateAccessToken(String newAccessToken, long expiresInSeconds) {
        String sql = "UPDATE youtube_credentials SET " +
                    "access_token = ?, " +
                    "token_expiry = DATE_ADD(NOW(), INTERVAL ? SECOND), " +
                    "last_refresh_date = NOW() " +
                    "WHERE credential_name = 'default'";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, newAccessToken);
            pstmt.setLong(2, expiresInSeconds);
            
            int result = pstmt.executeUpdate();
            if (result > 0) {
                //System.out.println("✓ Access token refreshed");
            }
            return result > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating access token: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Clear credentials from database (for re-authorization)
     */
    public static boolean clearCredentials() {
        String sql = "UPDATE youtube_credentials SET " +
                    "is_active = FALSE " +
                    "WHERE credential_name = 'default'";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            int result = pstmt.executeUpdate();
            //System.out.println("✓ YouTube credentials cleared");
            return result > 0;
            
        } catch (SQLException e) {
            System.err.println("Error clearing credentials: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Inner class to hold credential data
     */
    public static class YouTubeCredential {
        private String accessToken;
        private String refreshToken;
        private String clientId;
        private String clientSecret;
        private Timestamp tokenExpiry;
        
        public String getAccessToken() {
            return accessToken;
        }
        
        public void setAccessToken(String accessToken) {
            this.accessToken = accessToken;
        }
        
        public String getRefreshToken() {
            return refreshToken;
        }
        
        public void setRefreshToken(String refreshToken) {
            this.refreshToken = refreshToken;
        }
        
        public String getClientId() {
            return clientId;
        }
        
        public void setClientId(String clientId) {
            this.clientId = clientId;
        }
        
        public String getClientSecret() {
            return clientSecret;
        }
        
        public void setClientSecret(String clientSecret) {
            this.clientSecret = clientSecret;
        }
        
        public Timestamp getTokenExpiry() {
            return tokenExpiry;
        }
        
        public void setTokenExpiry(Timestamp tokenExpiry) {
            this.tokenExpiry = tokenExpiry;
        }
    }
}
