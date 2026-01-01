package com.vjnt.servlet;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.extensions.java6.auth.oauth2.AuthorizationCodeInstalledApp;
import com.google.api.client.extensions.jetty.auth.oauth2.LocalServerReceiver;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.auth.oauth2.GoogleClientSecrets;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.client.util.store.FileDataStoreFactory;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.*;
import java.security.GeneralSecurityException;
import java.util.Arrays;
import java.util.List;

/**
 * Direct YouTube OAuth Authorization Servlet
 * Opens browser window for immediate authorization
 */
@WebServlet("/authorize-youtube-direct")
public class DirectYouTubeAuthServlet extends HttpServlet {
    
    private static final String APPLICATION_NAME = "VJNT Class Management";
    private static final JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();
    private static final List<String> SCOPES = Arrays.asList(
        "https://www.googleapis.com/auth/youtube.upload",
        "https://www.googleapis.com/auth/youtube"
    );
    private static final String CREDENTIALS_FOLDER = System.getProperty("user.home") + "/.vjnt";
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        // HTML Header
        out.println("<!DOCTYPE html><html><head>");
        out.println("<title>YouTube Authorization</title>");
        out.println("<style>");
        out.println("body{font-family:Arial;max-width:800px;margin:50px auto;padding:20px;background:#f5f5f5}");
        out.println(".container{background:white;padding:40px;border-radius:10px;box-shadow:0 2px 10px rgba(0,0,0,0.1)}");
        out.println(".success{background:#d4edda;border:2px solid #28a745;color:#155724;padding:20px;border-radius:8px;margin:20px 0}");
        out.println(".error{background:#f8d7da;border:2px solid #dc3545;color:#721c24;padding:20px;border-radius:8px;margin:20px 0}");
        out.println(".info{background:#d1ecf1;border:2px solid #17a2b8;color:#0c5460;padding:20px;border-radius:8px;margin:20px 0}");
        out.println(".loading{text-align:center;padding:40px}");
        out.println(".spinner{border:4px solid #f3f3f3;border-top:4px solid #007bff;border-radius:50%;width:50px;height:50px;animation:spin 1s linear infinite;margin:20px auto}");
        out.println("@keyframes spin{0%{transform:rotate(0deg)}100%{transform:rotate(360deg)}}");
        out.println("h1{color:#333;border-bottom:3px solid #007bff;padding-bottom:10px}");
        out.println(".btn{background:#007bff;color:white;padding:15px 30px;border:none;border-radius:5px;cursor:pointer;font-size:16px;text-decoration:none;display:inline-block;margin:10px 5px}");
        out.println("</style></head><body><div class='container'>");
        
        out.println("<h1>🔐 YouTube Authorization</h1>");
        out.println("<div class='loading'>");
        out.println("<div class='spinner'></div>");
        out.println("<p style='font-size:18px'>Starting authorization...</p>");
        out.println("<p>A browser window should open automatically for Google sign-in.</p>");
        out.println("</div>");
        out.flush();
        
        try {
            // Initialize HTTP transport
            final NetHttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
            
            // Load client secrets
            InputStream in = getClass().getClassLoader().getResourceAsStream("client_secret.json");
            if (in == null) {
                throw new FileNotFoundException("client_secret.json not found in classpath");
            }
            GoogleClientSecrets clientSecrets = GoogleClientSecrets.load(JSON_FACTORY, new InputStreamReader(in));
            
            // Create credentials folder
            File credentialsDir = new File(CREDENTIALS_FOLDER);
            if (!credentialsDir.exists()) {
                credentialsDir.mkdirs();
            }
            
            // Build authorization flow
            GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(
                httpTransport, JSON_FACTORY, clientSecrets, SCOPES)
                .setDataStoreFactory(new FileDataStoreFactory(credentialsDir))
                .setAccessType("offline")
                .build();
            
            // Create local receiver for redirect
            LocalServerReceiver receiver = new LocalServerReceiver.Builder()
                .setPort(8080)
                .build();
            
            // Start authorization flow
            System.out.println("=== Starting Direct YouTube Authorization ===");
            Credential credential = new AuthorizationCodeInstalledApp(flow, receiver).authorize("user");
            System.out.println("✓ Authorization successful!");
            
            // Success message
            out.println("<div class='success'>");
            out.println("<h2>✅ Authorization Successful!</h2>");
            out.println("<p style='font-size:18px'>YouTube credentials have been saved.</p>");
            out.println("<p>You can now close this window and upload videos from the dashboard.</p>");
            out.println("</div>");
            
            out.println("<div class='info'>");
            out.println("<h3>📋 Next Steps:</h3>");
            out.println("<ol style='font-size:16px'>");
            out.println("<li>Go to School Dashboard</li>");
            out.println("<li>Click \"🎥 Video Upload\"</li>");
            out.println("<li>Select student and video file</li>");
            out.println("<li>Upload works automatically (no popup needed!)</li>");
            out.println("</ol>");
            out.println("</div>");
            
            out.println("<div style='text-align:center;margin:30px 0'>");
            out.println("<a href='" + request.getContextPath() + "/school-dashboard-enhanced.jsp' class='btn'>📊 Go to Dashboard</a>");
            out.println("</div>");
            
        } catch (Exception e) {
            System.err.println("✗ Authorization failed: " + e.getMessage());
            e.printStackTrace();
            
            out.println("<div class='error'>");
            out.println("<h2>❌ Authorization Failed</h2>");
            out.println("<p><strong>Error:</strong> " + e.getMessage() + "</p>");
            out.println("</div>");
            
            out.println("<div class='info'>");
            out.println("<h3>🔧 Troubleshooting:</h3>");
            out.println("<ul>");
            out.println("<li>Make sure popup blocker is disabled</li>");
            out.println("<li>Check that port 8080 is not blocked by firewall</li>");
            out.println("<li>Verify redirect URIs in Google Cloud Console</li>");
            out.println("<li>Try uploading a video from dashboard instead</li>");
            out.println("</ul>");
            out.println("</div>");
            
            out.println("<div style='text-align:center;margin:30px 0'>");
            out.println("<a href='" + request.getContextPath() + "/test-youtube-oauth-simple.html' class='btn'>🔄 Try Again</a>");
            out.println("<a href='" + request.getContextPath() + "/school-dashboard-enhanced.jsp' class='btn'>📊 Go to Dashboard</a>");
            out.println("</div>");
        }
        
        out.println("</div></body></html>");
        out.close();
    }
}
