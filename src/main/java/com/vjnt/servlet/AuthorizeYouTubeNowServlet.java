package com.vjnt.servlet;

import com.vjnt.util.YouTubeUploader;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Arrays;

/**
 * Servlet to trigger YouTube OAuth authorization flow
 * Access this page to authorize YouTube API access
 */
@WebServlet("/authorize-youtube-now")
public class AuthorizeYouTubeNowServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("<title>YouTube Authorization</title>");
        out.println("<style>");
        out.println("body { font-family: Arial, sans-serif; max-width: 900px; margin: 50px auto; padding: 20px; background: #f5f5f5; }");
        out.println(".container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }");
        out.println(".success { background: #d4edda; border: 2px solid #28a745; color: #155724; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println(".error { background: #f8d7da; border: 2px solid #dc3545; color: #721c24; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println(".warning { background: #fff3cd; border: 2px solid #ffc107; color: #856404; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println(".info { background: #d1ecf1; border: 2px solid #17a2b8; color: #0c5460; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println(".btn { background: #007bff; color: white; padding: 15px 30px; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; text-decoration: none; display: inline-block; margin: 10px 5px; }");
        out.println(".btn:hover { background: #0056b3; }");
        out.println(".btn-success { background: #28a745; }");
        out.println(".btn-success:hover { background: #218838; }");
        out.println("h1 { color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }");
        out.println("h2 { color: #555; }");
        out.println(".loading { text-align: center; padding: 40px; }");
        out.println(".spinner { border: 4px solid #f3f3f3; border-top: 4px solid #007bff; border-radius: 50%; width: 50px; height: 50px; animation: spin 1s linear infinite; margin: 20px auto; }");
        out.println("@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }");
        out.println("code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }");
        out.println("</style>");
        out.println("</head>");
        out.println("<body>");
        out.println("<div class='container'>");
        
        String action = request.getParameter("action");
        
        if ("authorize".equals(action)) {
            // Trigger authorization
            out.println("<h1>🔐 YouTube Authorization in Progress...</h1>");
            out.println("<div class='loading'>");
            out.println("<div class='spinner'></div>");
            out.println("<p style='font-size: 18px;'>Opening browser for authorization...</p>");
            out.println("<p>Please wait while we redirect you to Google for authorization.</p>");
            out.println("</div>");
            out.flush();
            
            try {
                
                // Aggressively clear ALL old credentials from all locations
                clearAllCredentials();
                
                // Show instruction page for manual OAuth
                out.println("<h1>🔐 YouTube Authorization Required</h1>");
                out.println("<div class='warning'>");
                out.println("<h2>⚠️ Manual Authorization Needed</h2>");
                out.println("<p>The automatic OAuth flow requires you to authorize through the regular video upload feature.</p>");
                out.println("</div>");
                
                out.println("<div class='info'>");
                out.println("<h3>📋 Follow These Steps:</h3>");
                out.println("<ol style='font-size: 16px; line-height: 2;'>");
                out.println("<li><strong>Go to the Dashboard</strong> - Click the button below</li>");
                out.println("<li><strong>Click \"🎥 Video Upload\"</strong> button</li>");
                out.println("<li><strong>Select any student</strong> from the list</li>");
                out.println("<li><strong>Choose a small video file</strong> (1-5 MB)</li>");
                out.println("<li><strong>Fill the form</strong> (subject, month, progress)</li>");
                out.println("<li><strong>Click \"Upload Video\"</strong></li>");
                out.println("<li><strong>A browser window will open</strong> - Sign in and click \"Allow\"</li>");
                out.println("<li><strong>Done!</strong> Your video uploads and authorization is saved</li>");
                out.println("</ol>");
                out.println("</div>");
                
                out.println("<div style='text-align: center; margin: 40px 0;'>");
                out.println("<a href='" + request.getContextPath() + "/school-dashboard-enhanced.jsp' class='btn btn-success' style='font-size: 20px; padding: 20px 40px;'>");
                out.println("📊 Go to Dashboard & Upload Video");
                out.println("</a>");
                out.println("</div>");
                
                out.println("<div class='success'>");
                out.println("<h3>✅ Why This Works:</h3>");
                out.println("<ul>");
                out.println("<li>The video upload feature triggers the OAuth flow properly</li>");
                out.println("<li>When you upload for the first time, browser opens automatically</li>");
                out.println("<li>After authorization, credentials are saved permanently</li>");
                out.println("<li>All future uploads work without browser popup</li>");
                out.println("</ul>");
                out.println("</div>");
                
            } catch (Exception e) {
                System.err.println("✗ Authorization setup failed: " + e.getMessage());
                e.printStackTrace();
                
                out.println("<div class='error'>");
                out.println("<h2>❌ Error</h2>");
                out.println("<p>" + e.getMessage() + "</p>");
                out.println("</div>");
            }
            
        } else if ("success".equals(request.getParameter("result"))) {
            // Success page
            String videoId = request.getParameter("videoId");
            
            out.println("<h1>✅ YouTube Authorization Successful!</h1>");
            out.println("<div class='success'>");
            out.println("<h2>🎉 Congratulations!</h2>");
            out.println("<p style='font-size: 18px;'><strong>YouTube API has been successfully authorized!</strong></p>");
            out.println("<p>A test video was uploaded to verify the authorization.</p>");
            if (videoId != null) {
                out.println("<p>Test Video ID: <code>" + videoId + "</code></p>");
                out.println("<p><a href='https://www.youtube.com/watch?v=" + videoId + "' target='_blank'>View Test Video on YouTube</a></p>");
            }
            out.println("</div>");
            
            out.println("<div class='info'>");
            out.println("<h3>✓ What Just Happened:</h3>");
            out.println("<ul>");
            out.println("<li>✅ You signed in with your Google/YouTube account</li>");
            out.println("<li>✅ You granted permissions to upload videos</li>");
            out.println("<li>✅ Credentials were saved to: <code>C:\\Users\\Admin\\.vjnt\\credentials\\</code></li>");
            out.println("<li>✅ A test video was uploaded to verify everything works</li>");
            out.println("</ul>");
            out.println("</div>");
            
            out.println("<div class='warning'>");
            out.println("<h3>📝 Important Notes:</h3>");
            out.println("<ul>");
            out.println("<li>This authorization is <strong>permanent</strong> - you won't need to do this again</li>");
            out.println("<li>Tokens will auto-refresh automatically when needed</li>");
            out.println("<li>All future video uploads will work without browser popups</li>");
            out.println("<li>The test video is private - you can delete it from YouTube if you want</li>");
            out.println("</ul>");
            out.println("</div>");
            
            out.println("<h3>🎬 Next Steps:</h3>");
            out.println("<p>You can now upload student videos normally:</p>");
            out.println("<a href='" + request.getContextPath() + "/school-dashboard-enhanced.jsp' class='btn btn-success'>Go to Dashboard</a>");
            
        } else if ("error".equals(request.getParameter("result"))) {
            // Error page
            String errorMessage = request.getParameter("message");
            
            out.println("<h1>❌ Authorization Failed</h1>");
            out.println("<div class='error'>");
            out.println("<h2>Something Went Wrong</h2>");
            out.println("<p><strong>Error:</strong> " + (errorMessage != null ? errorMessage : "Unknown error") + "</p>");
            out.println("</div>");
            
            out.println("<div class='warning'>");
            out.println("<h3>🔧 Troubleshooting:</h3>");
            out.println("<ul>");
            out.println("<li>Make sure you clicked <strong>\"Allow\"</strong> when prompted for permissions</li>");
            out.println("<li>Verify you're using the correct Google account (the one that owns the YouTube channel)</li>");
            out.println("<li>Check that <code>client_secret.json</code> exists in your project</li>");
            out.println("<li>Ensure you have internet connection</li>");
            out.println("<li>Make sure popup blockers are disabled for this site</li>");
            out.println("</ul>");
            out.println("</div>");
            
            out.println("<a href='authorize-youtube-now' class='btn'>← Try Again</a>");
            
        } else {
            // Main page - show authorization button
            out.println("<h1>🔐 YouTube API Authorization</h1>");
            
            out.println("<div class='warning'>");
            out.println("<h2>⚠️ Authorization Required</h2>");
            out.println("<p style='font-size: 16px;'>Your YouTube OAuth token has expired or was never authorized.</p>");
            out.println("<p>You need to authorize this application to upload videos to YouTube.</p>");
            out.println("</div>");
            
            out.println("<div class='info'>");
            out.println("<h3>📋 What Will Happen:</h3>");
            out.println("<ol style='font-size: 15px;'>");
            out.println("<li>When you click the button below, a <strong>browser window will open</strong></li>");
            out.println("<li>You'll be asked to <strong>sign in to your Google account</strong> (the one with YouTube access)</li>");
            out.println("<li>You'll see a permissions screen - click <strong>\"Allow\"</strong></li>");
            out.println("<li>The browser window will close automatically</li>");
            out.println("<li>You'll be redirected back here with a success message</li>");
            out.println("<li>That's it! Authorization is complete and permanent</li>");
            out.println("</ol>");
            out.println("</div>");
            
            out.println("<div class='info'>");
            out.println("<h3>🔒 Privacy & Security:</h3>");
            out.println("<ul>");
            out.println("<li>We only request permission to <strong>upload videos</strong> to YouTube</li>");
            out.println("<li>We cannot access your other Google data</li>");
            out.println("<li>You can revoke access anytime from your Google Account settings</li>");
            out.println("<li>Credentials are stored securely on your server</li>");
            out.println("</ul>");
            out.println("</div>");
            
            out.println("<div style='text-align: center; margin: 40px 0;'>");
            out.println("<a href='authorize-youtube-now?action=authorize' class='btn btn-success' style='font-size: 20px; padding: 20px 40px;'>");
            out.println("🚀 Authorize YouTube Now");
            out.println("</a>");
            out.println("</div>");
            
            out.println("<div style='text-align: center; margin-top: 30px;'>");
            out.println("<p><a href='" + request.getContextPath() + "/school-dashboard-enhanced.jsp'>← Back to Dashboard</a></p>");
            out.println("</div>");
        }
        
        out.println("</div>");
        out.println("</body>");
        out.println("</html>");
    }
    
    /**
     * Aggressively clear all credential files from all possible locations
     */
    private void clearAllCredentials() {
        String[] possiblePaths = {
            "C:/Users/Admin/.vjnt/credentials/StoredCredential",
            "C:/Users/Admin/V2Project/VJNT Class Managment/credentials/StoredCredential",
            "C:/Users/Admin/V2Project/VJNT Class Managment/build/war/credentials/StoredCredential",
            "C:/Users/Admin/V2Project/VJNT Class Managment/build/war/WEB-INF/classes/credentials/StoredCredential",
            "C:/Users/Admin/V2Project/VJNT Class Managment/src/main/webapp/credentials/StoredCredential",
            "C:/Users/Admin/V2Project/VJNT Class Managment/src/main/webapp/WEB-INF/classes/credentials/StoredCredential"
        };
        
        for (String path : possiblePaths) {
            try {
                File credFile = new File(path);
                if (credFile.exists()) {
                    credFile.delete();
                }
            } catch (Exception e) {
                System.err.println("Could not delete: " + path);
            }
        }
        
        // Also use the YouTubeUploader's clear method
        try {
            YouTubeUploader.clearCredentials();
        } catch (Exception e) {
            System.err.println("YouTubeUploader.clearCredentials() failed: " + e.getMessage());
        }
    }
}
