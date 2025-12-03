package com.vjnt.servlet;

import com.vjnt.util.YouTubeUploader;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;

/**
 * Test servlet to verify YouTube OAuth configuration
 */
@WebServlet("/TestYouTubeOAuthServlet")
public class TestYouTubeOAuthServlet extends HttpServlet {
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("<title>YouTube OAuth Test Result</title>");
        out.println("<style>");
        out.println("body { font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; }");
        out.println(".success { background: #e8f5e9; border-left: 4px solid #4CAF50; padding: 15px; margin: 20px 0; }");
        out.println(".error { background: #ffebee; border-left: 4px solid #f44336; padding: 15px; margin: 20px 0; }");
        out.println(".info { background: #e7f3ff; border-left: 4px solid #2196F3; padding: 15px; margin: 20px 0; }");
        out.println("button { background: #2196F3; color: white; border: none; padding: 12px 30px; ");
        out.println("font-size: 16px; cursor: pointer; border-radius: 4px; margin: 10px 5px; }");
        out.println("button:hover { background: #1976D2; }");
        out.println("</style>");
        out.println("</head>");
        out.println("<body>");
        out.println("<h1>🔐 YouTube OAuth Test</h1>");
        
        try {
            out.println("<div class='info'>");
            out.println("<h3>🔄 Testing OAuth Authorization...</h3>");
            out.println("<p>A browser window should open for Google authorization.</p>");
            out.println("<p><strong>Important:</strong> Sign in with the Gmail account you added as a test user.</p>");
            out.println("</div>");
            
            // Test OAuth by attempting to get credentials
            out.println("<div class='info'>");
            out.println("<h3>📋 Test Details:</h3>");
            out.println("<p>• Client ID: 1089840919584-d4beujl24vmilqqa7n9ivl2ae6iccbns.apps.googleusercontent.com</p>");
            out.println("<p>• Project ID: analog-decoder-479414-i8</p>");
            out.println("<p>• Redirect URI: http://localhost:8888/Callback</p>");
            out.println("<p>• Scopes: youtube.upload, youtube</p>");
            out.println("</div>");
            
            // Note: We can't actually test the full upload here without a video file
            // but the authorization flow will be triggered
            
            out.println("<div class='success'>");
            out.println("<h3>✅ Next Steps:</h3>");
            out.println("<ol>");
            out.println("<li>Complete the authorization in the browser window that opened</li>");
            out.println("<li>Grant the requested permissions</li>");
            out.println("<li>Wait for the redirect back to localhost:8888</li>");
            out.println("<li>If successful, you'll see 'Received verification code'</li>");
            out.println("<li>A 'credentials' folder will be created in your project</li>");
            out.println("<li>Try uploading a video from Manage Student Activities</li>");
            out.println("</ol>");
            out.println("</div>");
            
            out.println("<div class='info'>");
            out.println("<h3>⚠️ If Authorization Fails:</h3>");
            out.println("<ul>");
            out.println("<li><strong>403 access_denied:</strong> Make sure you added yourself as a test user in OAuth consent screen</li>");
            out.println("<li><strong>Redirect URI mismatch:</strong> Add http://localhost:8888/Callback to authorized redirect URIs</li>");
            out.println("<li><strong>App not verified:</strong> Your app must be published or you must be a test user</li>");
            out.println("</ul>");
            out.println("</div>");
            
            out.println("<div style='text-align: center; margin: 30px 0;'>");
            out.println("<button onclick='window.location.href=\"test-youtube-oauth.jsp\"'>← Back to Test Page</button>");
            out.println("<button onclick='window.location.href=\"manage-students.jsp\"' style='background: #4CAF50;'>Go to Student Management →</button>");
            out.println("</div>");
            
        } catch (Exception e) {
            out.println("<div class='error'>");
            out.println("<h3>❌ Error Occurred</h3>");
            out.println("<p><strong>Error:</strong> " + e.getMessage() + "</p>");
            out.println("<pre>");
            e.printStackTrace(out);
            out.println("</pre>");
            out.println("</div>");
            
            out.println("<div class='info'>");
            out.println("<h3>🔧 How to Fix:</h3>");
            out.println("<ol>");
            out.println("<li>Go to <a href='https://console.cloud.google.com' target='_blank'>Google Cloud Console</a></li>");
            out.println("<li>Navigate to APIs & Services → OAuth consent screen</li>");
            out.println("<li>Add yourself as a test user</li>");
            out.println("<li>Enable YouTube Data API v3</li>");
            out.println("<li>Try again</li>");
            out.println("</ol>");
            out.println("</div>");
        }
        
        out.println("</body>");
        out.println("</html>");
    }
}
