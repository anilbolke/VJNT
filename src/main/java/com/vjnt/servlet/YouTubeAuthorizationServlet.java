package com.vjnt.servlet;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.extensions.java6.auth.oauth2.AuthorizationCodeInstalledApp;
import com.google.api.client.extensions.jetty.auth.oauth2.LocalServerReceiver;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.auth.oauth2.GoogleClientSecrets;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.client.util.store.MemoryDataStoreFactory;
import com.vjnt.util.YouTubeCredentialManager;

import java.util.Arrays;
import java.util.List;

/**
 * One-time OAuth authorization servlet for YouTube API
 * This servlet handles the initial OAuth flow and stores credentials in database
 */
@WebServlet("/authorize-youtube")
public class YouTubeAuthorizationServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private static final JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();
    private static final List<String> SCOPES = Arrays.asList(
        "https://www.googleapis.com/auth/youtube.upload",
        "https://www.googleapis.com/auth/youtube"
    );
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        // Check if already authorized
        if (YouTubeCredentialManager.hasValidCredentials()) {
            out.println(getSuccessPage("Already Authorized", 
                "YouTube credentials are already configured and active.", 
                "No action needed. You can close this page."));
            return;
        }
        
        try {
            out.println(getLoadingPage());
            out.flush();
            
            // Load client secrets
            InputStream in = getClass().getClassLoader().getResourceAsStream("client_secret.json");
            if (in == null) {
                throw new IOException("client_secret.json not found in classpath. " +
                    "Please ensure it's in src/main/resources/ and rebuild the WAR file.");
            }
            
            GoogleClientSecrets clientSecrets = GoogleClientSecrets.load(JSON_FACTORY, 
                new InputStreamReader(in));
            
            String clientId = clientSecrets.getDetails().getClientId();
            String clientSecret = clientSecrets.getDetails().getClientSecret();
            
            // Build flow with in-memory data store
            final NetHttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
            GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(
                    httpTransport, JSON_FACTORY, clientSecrets, SCOPES)
                    .setDataStoreFactory(MemoryDataStoreFactory.getDefaultInstance())
                    .setAccessType("offline")
                    .setApprovalPrompt("force")
                    .build();
            
            // Start local server to receive OAuth callback
            LocalServerReceiver receiver = new LocalServerReceiver.Builder()
                    .setPort(8888) // Use fixed port for consistency
                    .build();
            
            System.out.println("Starting OAuth authorization flow...");
            System.out.println("Browser will open for Google authorization");
            
            // Perform authorization
            Credential credential = new AuthorizationCodeInstalledApp(flow, receiver).authorize("user");
            
            // Store credentials in database
            long expiresInSeconds = credential.getExpiresInSeconds() != null ? 
                                   credential.getExpiresInSeconds() : 3600;
            
            boolean stored = YouTubeCredentialManager.storeCredentials(
                credential.getAccessToken(),
                credential.getRefreshToken(),
                clientId,
                clientSecret,
                expiresInSeconds
            );
            
            if (stored) {
                out.println(getSuccessPage("Authorization Successful!", 
                    "YouTube credentials have been stored in the database.",
                    "You can now upload videos to YouTube from the application."));
                System.out.println("✓ YouTube authorization completed successfully");
            } else {
                throw new IOException("Failed to store credentials in database");
            }
            
        } catch (Exception e) {
            System.err.println("Error during YouTube authorization: " + e.getMessage());
            e.printStackTrace();
            out.println(getErrorPage("Authorization Failed", e.getMessage()));
        }
    }
    
    /**
     * Loading page HTML
     */
    private String getLoadingPage() {
        return "<!DOCTYPE html>" +
               "<html><head>" +
               "<title>YouTube Authorization</title>" +
               "<style>" +
               "body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; text-align: center; }" +
               ".spinner { border: 5px solid #f3f3f3; border-top: 5px solid #667eea; border-radius: 50%; width: 50px; height: 50px; animation: spin 1s linear infinite; margin: 20px auto; }" +
               "@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }" +
               "</style>" +
               "</head><body>" +
               "<h1>🔐 YouTube Authorization</h1>" +
               "<div class='spinner'></div>" +
               "<p>Starting OAuth authorization flow...</p>" +
               "<p>A browser window will open for you to authorize the application.</p>" +
               "<p><strong>Please wait and follow the instructions in the new window.</strong></p>" +
               "</body></html>";
    }
    
    /**
     * Success page HTML
     */
    private String getSuccessPage(String title, String message, String action) {
        return "<!DOCTYPE html>" +
               "<html><head>" +
               "<title>" + title + "</title>" +
               "<style>" +
               "body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }" +
               ".success { background: #d4edda; border: 1px solid #c3e6cb; padding: 20px; border-radius: 8px; color: #155724; }" +
               ".success h1 { margin: 0 0 15px 0; color: #155724; }" +
               ".btn { display: inline-block; padding: 10px 20px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin-top: 15px; }" +
               ".btn:hover { background: #5568d3; }" +
               "</style>" +
               "</head><body>" +
               "<div class='success'>" +
               "<h1>✅ " + title + "</h1>" +
               "<p><strong>" + message + "</strong></p>" +
               "<p>" + action + "</p>" +
               "<a href='" + getServletContext().getContextPath() + "/school-dashboard-enhanced.jsp' class='btn'>Go to Dashboard</a>" +
               "</div>" +
               "</body></html>";
    }
    
    /**
     * Error page HTML
     */
    private String getErrorPage(String title, String message) {
        return "<!DOCTYPE html>" +
               "<html><head>" +
               "<title>" + title + "</title>" +
               "<style>" +
               "body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }" +
               ".error { background: #f8d7da; border: 1px solid #f5c6cb; padding: 20px; border-radius: 8px; color: #721c24; }" +
               ".error h1 { margin: 0 0 15px 0; color: #721c24; }" +
               ".error pre { background: #fff; padding: 10px; border-radius: 5px; overflow-x: auto; }" +
               ".btn { display: inline-block; padding: 10px 20px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin-top: 15px; }" +
               ".btn:hover { background: #5568d3; }" +
               ".info { background: #d1ecf1; border: 1px solid #bee5eb; padding: 15px; border-radius: 5px; margin-top: 20px; color: #0c5460; }" +
               "</style>" +
               "</head><body>" +
               "<div class='error'>" +
               "<h1>❌ " + title + "</h1>" +
               "<p><strong>Error Details:</strong></p>" +
               "<pre>" + escapeHtml(message) + "</pre>" +
               "<div class='info'>" +
               "<h3>💡 Troubleshooting Steps:</h3>" +
               "<ol style='text-align: left;'>" +
               "<li>Ensure <code>client_secret.json</code> is in <code>src/main/resources/</code></li>" +
               "<li>Rebuild the WAR file: <code>mvn clean package</code> or Export WAR in Eclipse</li>" +
               "<li>Redeploy to Tomcat and restart</li>" +
               "<li>Check that YouTube Data API v3 is enabled in Google Cloud Console</li>" +
               "<li>Verify OAuth consent screen is configured</li>" +
               "<li>Check Tomcat logs for detailed errors</li>" +
               "</ol>" +
               "</div>" +
               "<a href='" + getServletContext().getContextPath() + "/authorize-youtube' class='btn'>Try Again</a>" +
               "</div>" +
               "</body></html>";
    }
    
    /**
     * Escape HTML special characters
     */
    private String escapeHtml(String text) {
        if (text == null) return "";
        return text.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
                   .replace("\"", "&quot;")
                   .replace("'", "&#39;");
    }
}
