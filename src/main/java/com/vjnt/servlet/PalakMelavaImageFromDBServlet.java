package com.vjnt.servlet;

import com.vjnt.dao.PalakMelavaDAO;
import com.vjnt.model.PalakMelava;
import com.vjnt.util.ImageEncryption;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.OutputStream;

/**
 * Servlet to serve encrypted Palak Melava images directly from database
 * Decrypts and streams the image data on-the-fly
 */
@WebServlet("/palak-melava-image-db")
public class PalakMelavaImageFromDBServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        try {
            // Get parameters
            String melavaIdStr = request.getParameter("id");
            String photoNumber = request.getParameter("photo"); // "1" or "2"
            
            if (melavaIdStr == null || melavaIdStr.isEmpty() || 
                photoNumber == null || photoNumber.isEmpty()) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, 
                    "Missing parameters: id and photo required");
                return;
            }
            
            // Validate photo number
            if (!photoNumber.equals("1") && !photoNumber.equals("2")) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, 
                    "Invalid photo number. Must be 1 or 2");
                return;
            }
            
            int melavaId = Integer.parseInt(melavaIdStr);
            
            // Fetch record from database
            PalakMelavaDAO dao = new PalakMelavaDAO();
            PalakMelava melava = dao.getById(melavaId);
            
            if (melava == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Record not found");
                return;
            }
            
            // Get appropriate photo content and filename
            byte[] encryptedPhotoContent = null;
            String photoFileName = null;
            
            if ("1".equals(photoNumber)) {
                encryptedPhotoContent = melava.getPhoto1Content();
                photoFileName = melava.getPhoto1FileName();
            } else {
                encryptedPhotoContent = melava.getPhoto2Content();
                photoFileName = melava.getPhoto2FileName();
            }
            
            // Check if photo exists
            if (encryptedPhotoContent == null || encryptedPhotoContent.length == 0) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, 
                    "Photo " + photoNumber + " not found");
                return;
            }
            
            // Decrypt the image content
            byte[] decryptedImageBytes = ImageEncryption.decryptBytesAES(encryptedPhotoContent);
            
            if (decryptedImageBytes == null || decryptedImageBytes.length == 0) {
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, 
                    "Failed to decrypt image");
                return;
            }
            
            // Determine MIME type based on filename
            String mimeType = "image/jpeg"; // default
            if (photoFileName != null) {
                // Remove .enc extension if present to get actual filename
                String originalFileName = photoFileName;
                if (originalFileName.endsWith(".enc")) {
                    originalFileName = originalFileName.substring(0, originalFileName.length() - 4);
                }
                String extension = ImageEncryption.getFileExtension(originalFileName);
                mimeType = ImageEncryption.getMimeType(extension);
            }
            
            // Set response headers
            response.setContentType(mimeType);
            response.setContentLength(decryptedImageBytes.length);
            response.setHeader("Content-Disposition", 
                "inline; filename=\"palak-melava-photo-" + photoNumber + ".jpg\"");
            response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
            response.setHeader("Pragma", "no-cache");
            response.setHeader("Expires", "0");
            
            // Stream the decrypted image
            try (OutputStream out = response.getOutputStream()) {
                out.write(decryptedImageBytes);
                out.flush();
            }
            
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid ID format");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, 
                "Error serving image: " + e.getMessage());
        }
    }
}
