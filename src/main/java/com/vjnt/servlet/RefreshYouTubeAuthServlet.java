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
 * Servlet to refresh YouTube OAuth credentials
 * This clears expired tokens and forces re-authorization
 */
@WebServlet("/refresh-youtube-auth")
public class RefreshYouTubeAuthServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("<title>Refresh YouTube Authorization</title>");
        out.println("<style>");
        out.println("body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }");
        out.println(".success { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 15px; border-radius: 5px; margin: 20px 0; }");
        out.println(".error { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 15px; border-radius: 5px; margin: 20px 0; }");
        out.println(".warning { background: #fff3cd; border: 1px solid #ffeeba; color: #856404; padding: 15px; border-radius: 5px; margin: 20px 0; }");
        out.println(".btn { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; text-decoration: none; display: inline-block; margin: 10px 5px; }");
        out.println(".btn:hover { background: #0056b3; }");
        out.println("pre { background: #f5f5f5; padding: 15px; border-radius: 5px; overflow-x: auto; }");
        out.println("h1 { color: #333; }");
        out.println("</style>");
        out.println("</head>");
        out.println("<body>");
        out.println("<h1>🔄 Refresh YouTube Authorization</h1>");
        
        String action = request.getParameter("action");
        
        if ("clear".equals(action)) {
            try {
                // Clear expired credentials
                YouTubeUploader.clearCredentials();
                
                out.println("<div class='success'>");
                out.println("<h2>✅ Credentials Cleared Successfully</h2>");
                out.println("<p>The expired YouTube OAuth tokens have been cleared from the server.</p>");
                out.println("</div>");
                
                out.println("<div class='warning'>");
                out.println("<h3>⚠️ Next Steps - IMPORTANT</h3>");
                out.println("<p><strong>You need to re-authorize YouTube access. Since this is a production server, follow these steps:</strong></p>");
                out.println("<ol>");
                out.println("<li><strong>On your LOCAL development machine:</strong>");
                out.println("<ul>");
                out.println("<li>Run the application locally</li>");
                out.println("<li>Try uploading a video (any video upload feature)</li>");
                out.println("<li>A browser window will open for YouTube authorization</li>");
                out.println("<li>Authorize with your YouTube account</li>");
                out.println("</ul>");
                out.println("</li>");
                out.println("<li><strong>Copy credentials to production:</strong>");
                out.println("<ul>");
                out.println("<li>Find the 'credentials' folder on your local machine (usually in user home/.vjnt/credentials/)</li>");
                out.println("<li>Copy the entire 'credentials' folder to this production server</li>");
                out.println("<li>Place it in: <code>" + System.getProperty("user.home") + "/.vjnt/credentials/</code></li>");
                out.println("</ul>");
                out.println("</li>");
                out.println("<li><strong>Restart Tomcat</strong></li>");
                out.println("<li>Try uploading videos again - it should work!</li>");
                out.println("</ol>");
                out.println("</div>");
                
                out.println("<div class='warning'>");
                out.println("<h3>📝 Alternative: Package Credentials in WAR</h3>");
                out.println("<p>For easier deployment, you can package the credentials in your WAR file:</p>");
                out.println("<ol>");
                out.println("<li>Authorize on local machine (step 1 above)</li>");
                out.println("<li>Copy credentials folder to: <code>src/main/resources/credentials/</code></li>");
                out.println("<li>Rebuild: <code>mvn clean package</code></li>");
                out.println("<li>Deploy new WAR file</li>");
                out.println("</ol>");
                out.println("</div>");
                
            } catch (Exception e) {
                out.println("<div class='error'>");
                out.println("<h2>❌ Error Clearing Credentials</h2>");
                out.println("<p>" + e.getMessage() + "</p>");
                out.println("</div>");
                e.printStackTrace();
            }
        } else {
            // Show information page
            out.println("<div class='error'>");
            out.println("<h2>❌ YouTube OAuth Token Expired</h2>");
            out.println("<p>Your YouTube authorization token has expired or been revoked.</p>");
            out.println("<p><strong>Error:</strong> <code>invalid_grant - Token has been expired or revoked</code></p>");
            out.println("</div>");
            
            out.println("<div class='warning'>");
            out.println("<h3>⚠️ What This Means</h3>");
            out.println("<ul>");
            out.println("<li>You cannot upload videos to YouTube until you re-authorize</li>");
            out.println("<li>The refresh token has been revoked (possibly manually revoked in Google account settings)</li>");
            out.println("<li>You need to complete OAuth authorization again</li>");
            out.println("</ul>");
            out.println("</div>");
            
            out.println("<h3>🔧 Solution</h3>");
            out.println("<p><strong>Step 1:</strong> Clear the expired credentials</p>");
            out.println("<a href='refresh-youtube-auth?action=clear' class='btn'>Clear Expired Credentials</a>");
            
            out.println("<hr style='margin: 40px 0;'>");
            
            out.println("<h3>📋 System Information</h3>");
            out.println("<pre>");
            out.println("User Home: " + System.getProperty("user.home"));
            out.println("Credentials Path: " + System.getProperty("user.home") + "/.vjnt/credentials/");
            out.println("Server Type: " + (System.getenv("DISPLAY") == null ? "Headless (Production)" : "With Display"));
            out.println("OS: " + System.getProperty("os.name"));
            out.println("</pre>");
        }
        
        out.println("<hr style='margin: 40px 0;'>");
        out.println("<p><a href='" + request.getContextPath() + "/school-dashboard-enhanced.jsp'>← Back to Dashboard</a></p>");
        out.println("</body>");
        out.println("</html>");
    }
}
