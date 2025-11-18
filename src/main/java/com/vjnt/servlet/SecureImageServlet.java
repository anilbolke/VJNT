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
 * Servlet to serve encrypted images by decrypting them on-the-fly
 */
@WebServlet("/secure-image")
public class SecureImageServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        try {
            // Get the encrypted image path from request parameter
            String imagePath = request.getParameter("path");
            
            if (imagePath == null || imagePath.isEmpty()) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Image path not provided");
                return;
            }
            
            // Prevent directory traversal attacks
            if (imagePath.contains("..")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid path");
                return;
            }
            
            // Construct the full file path
            String realPath = getServletContext().getRealPath("/") + imagePath;
            File encryptedFile = new File(realPath);
            
            // Check if file exists
            if (!encryptedFile.exists()) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Image not found");
                return;
            }
            
            // Decrypt the file
            byte[] decryptedImageBytes = ImageEncryption.decryptFile(realPath);
            
            if (decryptedImageBytes == null || decryptedImageBytes.length == 0) {
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Failed to decrypt image");
                return;
            }
            
            // Get file extension to set proper MIME type
            String originalFileName = request.getParameter("name");
            String extension = "jpg";
            
            if (originalFileName != null && !originalFileName.isEmpty()) {
                extension = ImageEncryption.getFileExtension(originalFileName);
            }
            
            String mimeType = ImageEncryption.getMimeType(extension);
            
            // Set response headers
            response.setContentType(mimeType);
            response.setContentLength(decryptedImageBytes.length);
            response.setHeader("Content-Disposition", "inline; filename=\"image." + extension + "\"");
            response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
            response.setHeader("Pragma", "no-cache");
            response.setHeader("Expires", "0");
            
            // Write decrypted image to response
            OutputStream out = response.getOutputStream();
            out.write(decryptedImageBytes);
            out.flush();
            out.close();
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Error serving image: " + e.getMessage());
        }
    }
}
