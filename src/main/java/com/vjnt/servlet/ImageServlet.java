package com.vjnt.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;

@WebServlet("/uploads/*")
public class ImageServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String requestedFile = request.getPathInfo();
        
        if (requestedFile == null || requestedFile.equals("/")) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        
        // Get the uploads directory path
        String uploadsPath = getServletContext().getRealPath("/") + "uploads";
        File file = new File(uploadsPath + requestedFile);
        
        if (!file.exists() || file.isDirectory()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        
        // Set content type based on file extension
        String filename = file.getName().toLowerCase();
        if (filename.endsWith(".jpg") || filename.endsWith(".jpeg")) {
            response.setContentType("image/jpeg");
        } else if (filename.endsWith(".png")) {
            response.setContentType("image/png");
        } else if (filename.endsWith(".gif")) {
            response.setContentType("image/gif");
        } else {
            response.setContentType("application/octet-stream");
        }
        
        response.setContentLength((int) file.length());
        response.setHeader("Cache-Control", "public, max-age=31536000");
        
        // Stream the file
        try (FileInputStream in = new FileInputStream(file);
             OutputStream out = response.getOutputStream()) {
            
            byte[] buffer = new byte[4096];
            int bytesRead;
            
            while ((bytesRead = in.read(buffer)) != -1) {
                out.write(buffer, 0, bytesRead);
            }
        }
    }
}
