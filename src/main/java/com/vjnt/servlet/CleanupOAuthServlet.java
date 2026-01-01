package com.vjnt.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;

/**
 * Servlet to cleanup OAuth resources and prepare for fresh authorization
 * Useful when "Address already in use" errors occur
 */
@WebServlet("/cleanup-oauth")
public class CleanupOAuthServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("<title>OAuth Cleanup</title>");
        out.println("<style>");
        out.println("body { font-family: Arial, sans-serif; max-width: 900px; margin: 50px auto; padding: 20px; background: #f5f5f5; }");
        out.println(".container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }");
        out.println(".success { background: #d4edda; border: 2px solid #28a745; color: #155724; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println(".warning { background: #fff3cd; border: 2px solid #ffc107; color: #856404; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println(".info { background: #d1ecf1; border: 2px solid #17a2b8; color: #0c5460; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println(".btn { background: #007bff; color: white; padding: 15px 30px; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; text-decoration: none; display: inline-block; margin: 10px 5px; }");
        out.println(".btn:hover { background: #0056b3; }");
        out.println("h1 { color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }");
        out.println("code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }");
        out.println("ol { line-height: 2; }");
        out.println("</style>");
        out.println("</head>");
        out.println("<body>");
        out.println("<div class='container'>");
        
        out.println("<h1>🧹 OAuth Cleanup Utility</h1>");
        
        out.println("<div class='warning'>");
        out.println("<h2>⚠️ Fixing 'Address Already in Use' Error</h2>");
        out.println("<p>This error occurs when the OAuth callback server port is occupied.</p>");
        out.println("</div>");
        
        out.println("<div class='info'>");
        out.println("<h2>📋 Manual Cleanup Steps</h2>");
        out.println("<p>Please follow these steps on your <strong>production server</strong>:</p>");
        out.println("<ol>");
        out.println("<li><strong>Check for running Java processes:</strong>");
        out.println("<br><code>netstat -ano | findstr :8888</code> (Windows)");
        out.println("<br><code>lsof -i :8888</code> (Linux)");
        out.println("</li>");
        
        out.println("<li><strong>If any process is using the port, kill it:</strong>");
        out.println("<br><code>taskkill /PID [PID] /F</code> (Windows)");
        out.println("<br><code>kill -9 [PID]</code> (Linux)");
        out.println("</li>");
        
        out.println("<li><strong>Restart Tomcat:</strong>");
        out.println("<br>Stop and start Tomcat completely to release all resources");
        out.println("</li>");
        
        out.println("<li><strong>Alternative: Use different authorization method</strong>");
        out.println("<br>If the issue persists, authorize YouTube on your local machine");
        out.println("<br>Then copy the <code>credentials</code> folder to production server");
        out.println("</li>");
        out.println("</ol>");
        out.println("</div>");
        
        out.println("<div class='success'>");
        out.println("<h2>✅ Recommended Solution for Production</h2>");
        out.println("<p><strong>Best Practice:</strong> Don't run OAuth flow directly on production server!</p>");
        out.println("<ol>");
        out.println("<li>On your <strong>local development machine</strong>:");
        out.println("   <ul>");
        out.println("   <li>Run the authorization at: <code>http://localhost:8080/your-app/authorize-youtube</code></li>");
        out.println("   <li>Complete the OAuth flow</li>");
        out.println("   <li>This will create a <code>credentials</code> folder</li>");
        out.println("   </ul>");
        out.println("</li>");
        out.println("<li>Copy the <code>credentials</code> folder to production:");
        out.println("   <ul>");
        out.println("   <li>Location: <code>WEB-INF/classes/credentials/</code></li>");
        out.println("   <li>Or as configured in <code>youtube.properties</code></li>");
        out.println("   </ul>");
        out.println("</li>");
        out.println("<li>Production server will use the existing credentials (no OAuth needed)</li>");
        out.println("</ol>");
        out.println("</div>");
        
        out.println("<div class='info'>");
        out.println("<h2>🔧 Configuration Check</h2>");
        out.println("<p>Current OAuth port setting in <code>youtube.properties</code>:</p>");
        out.println("<code>youtube.oauth.receiver.port=-1</code>");
        out.println("<p>Value of <code>-1</code> means automatic port selection (recommended)</p>");
        out.println("</div>");
        
        out.println("<div style='margin-top: 30px;'>");
        out.println("<a href='authorize-youtube' class='btn'>🔄 Try Authorization Again</a>");
        out.println("<a href='test-youtube-oauth.jsp' class='btn'>🧪 Test YouTube Setup</a>");
        out.println("</div>");
        
        out.println("</div>");
        out.println("</body>");
        out.println("</html>");
    }
}
