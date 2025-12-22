package com.vjnt.servlet;

import com.google.api.client.auth.oauth2.AuthorizationCodeRequestUrl;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.auth.oauth2.GoogleClientSecrets;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.client.util.store.FileDataStoreFactory;
import com.vjnt.util.YouTubeConfig;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.util.Arrays;
import java.util.List;

/**
 * Manual YouTube OAuth - Generates authorization URL for manual browser entry
 */
@WebServlet("/manual-youtube-auth")
public class ManualYouTubeAuthServlet extends HttpServlet {
    
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
        
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("<title>Manual YouTube Authorization</title>");
        out.println("<style>");
        out.println("body { font-family: Arial, sans-serif; max-width: 1000px; margin: 20px auto; padding: 20px; background: #f5f5f5; }");
        out.println(".container { background: white; padding: 40px; border-radius: 15px; box-shadow: 0 5px 20px rgba(0,0,0,0.2); }");
        out.println("h1 { color: #007bff; text-align: center; font-size: 32px; margin-bottom: 30px; }");
        out.println(".step { background: #e7f3ff; border-left: 5px solid #007bff; padding: 20px; margin: 20px 0; border-radius: 5px; }");
        out.println(".step h2 { color: #007bff; margin-top: 0; font-size: 24px; }");
        out.println(".url-box { background: #f8f9fa; border: 3px solid #28a745; padding: 20px; margin: 20px 0; border-radius: 10px; word-break: break-all; font-family: monospace; font-size: 14px; position: relative; }");
        out.println(".btn { display: inline-block; background: #28a745; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-size: 18px; font-weight: bold; margin: 10px 5px; cursor: pointer; border: none; transition: all 0.3s; }");
        out.println(".btn:hover { background: #218838; transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,0,0,0.2); }");
        out.println(".btn-copy { background: #007bff; }");
        out.println(".btn-copy:hover { background: #0056b3; }");
        out.println(".success { background: #d4edda; border: 2px solid #28a745; color: #155724; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println(".warning { background: #fff3cd; border: 2px solid #ffc107; color: #856404; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println(".error { background: #f8d7da; border: 2px solid #dc3545; color: #721c24; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println("code { background: #f4f4f4; padding: 3px 8px; border-radius: 3px; color: #d63384; }");
        out.println(".center { text-align: center; margin: 30px 0; }");
        out.println("</style>");
        out.println("</head>");
        out.println("<body>");
        out.println("<div class='container'>");
        
        try {
            // Generate OAuth URL
            out.println("<h1>🔐 Manual YouTube Authorization</h1>");
            
            out.println("<div class='warning'>");
            out.println("<h3>⚠️ Browser Not Opening Automatically?</h3>");
            out.println("<p>No problem! We'll give you the authorization URL to copy and paste manually.</p>");
            out.println("</div>");
            
            out.println("<div class='step'>");
            out.println("<h2>STEP 1: Get Authorization URL</h2>");
            out.println("<p>Click the button below to generate your authorization URL:</p>");
            
            // Load client secrets
            InputStream in = getClass().getClassLoader().getResourceAsStream("client_secret.json");
            if (in == null) {
                throw new IOException("client_secret.json not found in classpath");
            }
            
            GoogleClientSecrets clientSecrets = GoogleClientSecrets.load(JSON_FACTORY, new InputStreamReader(in));
            
            // Set up credentials folder
            File credentialsDir = new File(System.getProperty("user.home"), ".vjnt/credentials");
            if (!credentialsDir.exists()) {
                credentialsDir.mkdirs();
            }
            
            // Build flow
            final NetHttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
            GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(
                    httpTransport, JSON_FACTORY, clientSecrets, SCOPES)
                    .setDataStoreFactory(new FileDataStoreFactory(credentialsDir))
                    .setAccessType("offline")
                    .setApprovalPrompt("force")
                    .build();
            
            // Generate authorization URL
            String redirectUri = "http://localhost:8888/Callback";
            AuthorizationCodeRequestUrl authorizationUrl = flow.newAuthorizationUrl().setRedirectUri(redirectUri);
            String url = authorizationUrl.build();
            
            out.println("<div class='url-box' id='authUrl'>");
            out.println(url);
            out.println("</div>");
            
            out.println("<div class='center'>");
            out.println("<button class='btn btn-copy' onclick='copyUrl()'>📋 Copy URL</button>");
            out.println("<a href='" + url + "' target='_blank' class='btn'>🚀 Open in New Tab</a>");
            out.println("</div>");
            out.println("</div>");
            
            out.println("<div class='step'>");
            out.println("<h2>STEP 2: Authorize in Browser</h2>");
            out.println("<ol style='font-size: 16px; line-height: 2;'>");
            out.println("<li>Click the <strong>\"Open in New Tab\"</strong> button above (or copy URL and paste in browser)</li>");
            out.println("<li>You'll be taken to Google's login page</li>");
            out.println("<li>Sign in with your <strong>Google/YouTube account</strong></li>");
            out.println("<li>Click <strong>\"Allow\"</strong> when asked for permissions</li>");
            out.println("<li>You'll see an error page (this is normal!) - <strong>Copy the FULL URL from the browser address bar</strong></li>");
            out.println("</ol>");
            out.println("</div>");
            
            out.println("<div class='step'>");
            out.println("<h2>STEP 3: Complete Authorization</h2>");
            out.println("<p>After you clicked \"Allow\", paste the full URL from your browser here:</p>");
            out.println("<form method='post' action='manual-youtube-auth'>");
            out.println("<textarea name='callbackUrl' style='width: 100%; height: 100px; padding: 10px; font-family: monospace; font-size: 14px; border: 2px solid #007bff; border-radius: 5px;' placeholder='Paste the full URL here (starts with http://localhost:8888/Callback?code=...)'></textarea>");
            out.println("<div class='center'>");
            out.println("<button type='submit' class='btn'>✅ Complete Authorization</button>");
            out.println("</div>");
            out.println("</form>");
            out.println("</div>");
            
            out.println("<div class='success'>");
            out.println("<h3>💡 What's Happening?</h3>");
            out.println("<ul>");
            out.println("<li>Google will redirect you to <code>http://localhost:8888/Callback</code> with an authorization code</li>");
            out.println("<li>This URL won't load (error page is normal)</li>");
            out.println("<li>Just copy the entire URL from browser and paste it above</li>");
            out.println("<li>We'll extract the code and complete the authorization</li>");
            out.println("</ul>");
            out.println("</div>");
            
        } catch (Exception e) {
            out.println("<div class='error'>");
            out.println("<h2>❌ Error Generating Authorization URL</h2>");
            out.println("<p>" + e.getMessage() + "</p>");
            out.println("<pre>");
            e.printStackTrace(out);
            out.println("</pre>");
            out.println("</div>");
        }
        
        out.println("<script>");
        out.println("function copyUrl() {");
        out.println("  var urlText = document.getElementById('authUrl').innerText;");
        out.println("  navigator.clipboard.writeText(urlText).then(function() {");
        out.println("    alert('✅ URL copied to clipboard!\\nNow paste it in a new browser tab.');");
        out.println("  });");
        out.println("}");
        out.println("</script>");
        
        out.println("</div>");
        out.println("</body>");
        out.println("</html>");
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        String callbackUrl = request.getParameter("callbackUrl");
        
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("<title>Authorization Result</title>");
        out.println("<style>");
        out.println("body { font-family: Arial, sans-serif; max-width: 900px; margin: 50px auto; padding: 20px; background: #f5f5f5; }");
        out.println(".container { background: white; padding: 40px; border-radius: 15px; box-shadow: 0 5px 20px rgba(0,0,0,0.2); }");
        out.println("h1 { color: #28a745; text-align: center; }");
        out.println(".success { background: #d4edda; border: 2px solid #28a745; color: #155724; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println(".error { background: #f8d7da; border: 2px solid #dc3545; color: #721c24; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println(".btn { display: inline-block; background: #007bff; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-size: 18px; margin: 10px; }");
        out.println("</style>");
        out.println("</head>");
        out.println("<body>");
        out.println("<div class='container'>");
        
        try {
            if (callbackUrl == null || callbackUrl.trim().isEmpty()) {
                throw new Exception("Please paste the callback URL");
            }
            
            // Extract authorization code
            String code = null;
            if (callbackUrl.contains("code=")) {
                int codeStart = callbackUrl.indexOf("code=") + 5;
                int codeEnd = callbackUrl.indexOf("&", codeStart);
                if (codeEnd == -1) {
                    code = callbackUrl.substring(codeStart);
                } else {
                    code = callbackUrl.substring(codeStart, codeEnd);
                }
            }
            
            if (code == null || code.isEmpty()) {
                throw new Exception("Could not find authorization code in URL. Make sure you pasted the complete URL.");
            }
            
            // Exchange code for tokens
            InputStream in = getClass().getClassLoader().getResourceAsStream("client_secret.json");
            GoogleClientSecrets clientSecrets = GoogleClientSecrets.load(JSON_FACTORY, new InputStreamReader(in));
            
            File credentialsDir = new File(System.getProperty("user.home"), ".vjnt/credentials");
            final NetHttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
            
            GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(
                    httpTransport, JSON_FACTORY, clientSecrets, SCOPES)
                    .setDataStoreFactory(new FileDataStoreFactory(credentialsDir))
                    .setAccessType("offline")
                    .build();
            
            String redirectUri = "http://localhost:8888/Callback";
            com.google.api.client.auth.oauth2.TokenResponse tokenResponse = 
                flow.newTokenRequest(code).setRedirectUri(redirectUri).execute();
            
            flow.createAndStoreCredential(tokenResponse, "user");
            
            out.println("<h1>✅ Authorization Successful!</h1>");
            out.println("<div class='success'>");
            out.println("<h2>🎉 YouTube API Authorized!</h2>");
            out.println("<p style='font-size: 18px;'>Your YouTube account has been successfully authorized.</p>");
            out.println("<ul style='font-size: 16px; line-height: 1.8;'>");
            out.println("<li>✅ Credentials saved to: <code>" + credentialsDir.getAbsolutePath() + "</code></li>");
            out.println("<li>✅ You can now upload videos to YouTube</li>");
            out.println("<li>✅ No browser popup needed anymore</li>");
            out.println("<li>✅ Tokens will auto-refresh automatically</li>");
            out.println("</ul>");
            out.println("</div>");
            
            out.println("<div style='text-align: center; margin-top: 40px;'>");
            out.println("<a href='" + request.getContextPath() + "/school-dashboard-enhanced.jsp' class='btn'>📊 Go to Dashboard</a>");
            out.println("</div>");
            
        } catch (Exception e) {
            out.println("<h1>❌ Authorization Failed</h1>");
            out.println("<div class='error'>");
            out.println("<h2>Error</h2>");
            out.println("<p>" + e.getMessage() + "</p>");
            out.println("<p><strong>Make sure you:</strong></p>");
            out.println("<ul>");
            out.println("<li>Pasted the COMPLETE URL from the browser (including http://localhost:8888/Callback?code=...)</li>");
            out.println("<li>Clicked \"Allow\" on the Google authorization page</li>");
            out.println("<li>Copied the URL immediately after authorization</li>");
            out.println("</ul>");
            out.println("</div>");
            out.println("<div style='text-align: center;'>");
            out.println("<a href='manual-youtube-auth' class='btn'>🔄 Try Again</a>");
            out.println("</div>");
        }
        
        out.println("</div>");
        out.println("</body>");
        out.println("</html>");
    }
}
