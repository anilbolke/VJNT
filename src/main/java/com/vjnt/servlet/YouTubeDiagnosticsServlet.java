package com.vjnt.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.File;

/**
 * Diagnostic page to check YouTube credentials and configuration
 * Access at: /youtube-diagnostics
 */
@WebServlet("/youtube-diagnostics")
public class YouTubeDiagnosticsServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("<title>YouTube Upload Diagnostics</title>");
        out.println("<style>");
        out.println("body { font-family: 'Courier New', monospace; padding: 20px; background: #1e1e1e; color: #d4d4d4; }");
        out.println(".container { max-width: 1200px; margin: 0 auto; }");
        out.println("h1 { color: #4ec9b0; border-bottom: 2px solid #4ec9b0; padding-bottom: 10px; }");
        out.println("h2 { color: #dcdcaa; margin-top: 30px; }");
        out.println(".status { padding: 15px; margin: 10px 0; border-radius: 5px; }");
        out.println(".success { background: #1e3a1e; border-left: 4px solid #4caf50; color: #4caf50; }");
        out.println(".error { background: #3a1e1e; border-left: 4px solid #f44336; color: #f44336; }");
        out.println(".warning { background: #3a3a1e; border-left: 4px solid #ff9800; color: #ff9800; }");
        out.println(".info { background: #1e2a3a; border-left: 4px solid #2196F3; color: #2196F3; }");
        out.println("pre { background: #2d2d2d; padding: 15px; border-radius: 5px; overflow-x: auto; color: #ce9178; }");
        out.println(".btn { background: #007acc; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; text-decoration: none; display: inline-block; margin: 10px 5px; }");
        out.println(".btn:hover { background: #005a9e; }");
        out.println("table { width: 100%; border-collapse: collapse; margin: 20px 0; }");
        out.println("th, td { padding: 12px; text-align: left; border-bottom: 1px solid #3e3e3e; }");
        out.println("th { background: #2d2d2d; color: #4ec9b0; }");
        out.println("td { color: #d4d4d4; }");
        out.println(".check-mark { color: #4caf50; font-weight: bold; }");
        out.println(".x-mark { color: #f44336; font-weight: bold; }");
        out.println("</style>");
        out.println("</head>");
        out.println("<body>");
        out.println("<div class='container'>");
        
        out.println("<h1>🔍 YouTube Upload Diagnostics</h1>");
        out.println("<p>Production Server: <strong>" + request.getServerName() + "</strong></p>");
        out.println("<p>Time: <strong>" + new java.util.Date() + "</strong></p>");
        
        // System Information
        out.println("<h2>📊 System Information</h2>");
        out.println("<table>");
        out.println("<tr><th>Property</th><th>Value</th></tr>");
        out.println("<tr><td>Java Version</td><td>" + System.getProperty("java.version") + "</td></tr>");
        out.println("<tr><td>OS</td><td>" + System.getProperty("os.name") + " " + System.getProperty("os.version") + "</td></tr>");
        out.println("<tr><td>User Directory</td><td>" + System.getProperty("user.dir") + "</td></tr>");
        out.println("<tr><td>User Home</td><td>" + System.getProperty("user.home") + "</td></tr>");
        out.println("<tr><td>Catalina Base</td><td>" + System.getProperty("catalina.base") + "</td></tr>");
        out.println("<tr><td>Display ENV</td><td>" + System.getenv("DISPLAY") + " " + 
                   (System.getenv("DISPLAY") == null ? "(Headless Server)" : "") + "</td></tr>");
        out.println("</table>");
        
        // Check 1: client_secret.json
        out.println("<h2>🔑 Check 1: client_secret.json</h2>");
        try {
            InputStream clientSecret = getClass().getClassLoader().getResourceAsStream("client_secret.json");
            if (clientSecret != null) {
                int size = clientSecret.available();
                clientSecret.close();
                out.println("<div class='status success'>");
                out.println("<span class='check-mark'>✓</span> <strong>FOUND</strong> in classpath<br>");
                out.println("Size: " + size + " bytes<br>");
                out.println("Location: Packaged in WAR file");
                out.println("</div>");
            } else {
                out.println("<div class='status error'>");
                out.println("<span class='x-mark'>✗</span> <strong>NOT FOUND</strong> in classpath<br>");
                out.println("Expected location: src/main/resources/client_secret.json<br>");
                out.println("Action: Add client_secret.json and rebuild WAR");
                out.println("</div>");
            }
        } catch (Exception e) {
            out.println("<div class='status error'>");
            out.println("<span class='x-mark'>✗</span> <strong>ERROR:</strong> " + e.getMessage());
            out.println("</div>");
        }
        
        // Check 2: StoredCredential
        out.println("<h2>🎫 Check 2: YouTube OAuth Credentials (StoredCredential)</h2>");
        try {
            InputStream credentials = getClass().getClassLoader().getResourceAsStream("credentials/StoredCredential");
            if (credentials != null) {
                int size = credentials.available();
                credentials.close();
                out.println("<div class='status success'>");
                out.println("<span class='check-mark'>✓</span> <strong>FOUND</strong> in classpath<br>");
                out.println("Size: " + size + " bytes<br>");
                out.println("Location: credentials/StoredCredential (packaged in WAR)<br>");
                out.println("Status: <strong>Ready for YouTube uploads!</strong>");
                out.println("</div>");
            } else {
                out.println("<div class='status error'>");
                out.println("<span class='x-mark'>✗</span> <strong>NOT FOUND</strong> in classpath<br>");
                out.println("Expected location: src/main/resources/credentials/StoredCredential<br>");
                out.println("<br><strong>ACTION REQUIRED:</strong><br>");
                out.println("1. Copy StoredCredential to: src/main/resources/credentials/<br>");
                out.println("2. Rebuild WAR in Eclipse<br>");
                out.println("3. Redeploy to production server<br>");
                out.println("4. Refresh this page to verify");
                out.println("</div>");
            }
        } catch (Exception e) {
            out.println("<div class='status error'>");
            out.println("<span class='x-mark'>✗</span> <strong>ERROR:</strong> " + e.getMessage());
            out.println("</div>");
        }
        
        // Check 3: Credentials Folder Locations
        out.println("<h2>📁 Check 3: Credentials Folder Search Paths</h2>");
        String[] searchPaths = {
            System.getProperty("user.home") + "/.vjnt/credentials",
            System.getProperty("catalina.base") + "/webapps/ROOT/WEB-INF/classes/credentials",
            System.getProperty("catalina.base") + "/webapps/credentials",
            "credentials"
        };
        
        out.println("<table>");
        out.println("<tr><th>Location</th><th>Status</th><th>Details</th></tr>");
        
        for (String path : searchPaths) {
            try {
                File dir = new File(path);
                if (dir.exists()) {
                    File credFile = new File(dir, "StoredCredential");
                    if (credFile.exists()) {
                        out.println("<tr>");
                        out.println("<td>" + path + "</td>");
                        out.println("<td><span class='check-mark'>✓ EXISTS</span></td>");
                        out.println("<td>File: " + credFile.length() + " bytes</td>");
                        out.println("</tr>");
                    } else {
                        out.println("<tr>");
                        out.println("<td>" + path + "</td>");
                        out.println("<td><span class='warning'>⚠ Folder exists, no file</span></td>");
                        out.println("<td>-</td>");
                        out.println("</tr>");
                    }
                } else {
                    out.println("<tr>");
                    out.println("<td>" + path + "</td>");
                    out.println("<td><span class='x-mark'>✗ Not found</span></td>");
                    out.println("<td>-</td>");
                    out.println("</tr>");
                }
            } catch (Exception e) {
                out.println("<tr>");
                out.println("<td>" + path + "</td>");
                out.println("<td><span class='x-mark'>✗ Error</span></td>");
                out.println("<td>" + e.getMessage() + "</td>");
                out.println("</tr>");
            }
        }
        out.println("</table>");
        
        // Check 4: YouTubeConfig
        out.println("<h2>⚙️ Check 4: YouTube Configuration</h2>");
        try {
            out.println("<table>");
            out.println("<tr><th>Setting</th><th>Value</th></tr>");
            out.println("<tr><td>Application Name</td><td>" + com.vjnt.util.YouTubeConfig.getApplicationName() + "</td></tr>");
            out.println("<tr><td>Client Secrets File</td><td>" + com.vjnt.util.YouTubeConfig.getClientSecretsFile() + "</td></tr>");
            out.println("<tr><td>Credentials Folder</td><td>" + com.vjnt.util.YouTubeConfig.getCredentialsFolder() + "</td></tr>");
            out.println("<tr><td>Category ID</td><td>" + com.vjnt.util.YouTubeConfig.getDefaultCategoryId() + "</td></tr>");
            out.println("<tr><td>Privacy Status</td><td>" + com.vjnt.util.YouTubeConfig.getDefaultPrivacyStatus() + "</td></tr>");
            out.println("<tr><td>Auth Type</td><td>" + com.vjnt.util.YouTubeConfig.getAuthType() + "</td></tr>");
            out.println("</table>");
        } catch (Exception e) {
            out.println("<div class='status error'>");
            out.println("<span class='x-mark'>✗</span> Error loading configuration: " + e.getMessage());
            out.println("</div>");
        }
        
        // Final Status
        out.println("<h2>🎯 Overall Status</h2>");
        
        boolean hasClientSecret = false;
        boolean hasCredentials = false;
        
        try {
            InputStream cs = getClass().getClassLoader().getResourceAsStream("client_secret.json");
            hasClientSecret = (cs != null);
            if (cs != null) cs.close();
            
            InputStream cred = getClass().getClassLoader().getResourceAsStream("credentials/StoredCredential");
            hasCredentials = (cred != null);
            if (cred != null) cred.close();
        } catch (Exception e) {}
        
        if (hasClientSecret && hasCredentials) {
            out.println("<div class='status success'>");
            out.println("<h3>✅ READY FOR YOUTUBE UPLOADS</h3>");
            out.println("<p>All required files are present in the WAR file.</p>");
            out.println("<p>Video uploads should work on production!</p>");
            out.println("</div>");
        } else {
            out.println("<div class='status error'>");
            out.println("<h3>❌ NOT READY - Missing Files</h3>");
            if (!hasClientSecret) {
                out.println("<p>✗ Missing: client_secret.json</p>");
            }
            if (!hasCredentials) {
                out.println("<p>✗ Missing: credentials/StoredCredential</p>");
            }
            out.println("<br><p><strong>Fix:</strong></p>");
            out.println("<ol>");
            out.println("<li>Add missing files to src/main/resources/</li>");
            out.println("<li>Rebuild WAR in Eclipse</li>");
            out.println("<li>Redeploy WAR to production</li>");
            out.println("<li>Refresh this page</li>");
            out.println("</ol>");
            out.println("</div>");
        }
        
        out.println("<div style='margin-top: 40px; text-align: center;'>");
        out.println("<a href='youtube-diagnostics' class='btn'>🔄 Refresh Diagnostics</a>");
        out.println("<a href='" + request.getContextPath() + "/school-dashboard-enhanced.jsp' class='btn'>📊 Back to Dashboard</a>");
        out.println("</div>");
        
        out.println("<div class='status info' style='margin-top: 40px;'>");
        out.println("<strong>💡 Tip:</strong> Bookmark this page for quick diagnostics without needing server log access!");
        out.println("</div>");
        
        out.println("</div>");
        out.println("</body>");
        out.println("</html>");
    }
}
