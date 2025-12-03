package com.vjnt.servlet;

import com.vjnt.util.ImageEncryption;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;

/**
 * Servlet to serve encrypted Palak Melava images
 * Decrypts and streams the image data on-the-fly
 */
@WebServlet("/palak-melava-image")
public class PalakMelavaImageServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String imagePath = request.getParameter("path");
        
        if (imagePath == null || imagePath.isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Image path not provided");
            return;
        }
        
        // Validate path to prevent directory traversal attacks
        if (imagePath.contains("..") || imagePath.startsWith("/")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid image path");
            return;
        }
        
        // Construct full file path
        String uploadsPath = getServletContext().getRealPath("/") + "uploads" + File.separator;
        String fullPath = uploadsPath + imagePath.replace("/", File.separator);
        
        File file = new File(fullPath);
        
        // Verify file exists and is within uploads directory
        if (!file.exists() || !file.getCanonicalPath().startsWith(uploadsPath)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Image not found");
            return;
        }
        
        try {
            // Decrypt the file
            byte[] decryptedData = ImageEncryption.decryptFile(fullPath);
            
            if (decryptedData == null || decryptedData.length == 0) {
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Failed to decrypt image");
                return;
            }
            
            // Determine content type based on original filename (before .enc)
            // Example: 1732806543210_1_meeting.jpg.enc -> get jpg
            String filename = file.getName().toLowerCase();
            String extension = "jpg"; // default
            
            // Remove .enc extension if present
            if (filename.endsWith(".enc")) {
                filename = filename.substring(0, filename.length() - 4);
            }
            
            // Now get the actual image extension
            extension = ImageEncryption.getFileExtension(filename);
            
            String contentType = ImageEncryption.getMimeType(extension);
            
            response.setContentType(contentType);
            response.setContentLength(decryptedData.length);
            response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
            response.setHeader("Pragma", "no-cache");
            response.setHeader("Expires", "0");
            
            // Stream the decrypted image
            try (OutputStream out = response.getOutputStream()) {
                out.write(decryptedData);
                out.flush();
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Error serving image");
        }
    }
}
