package com.vjnt.servlet;

import com.vjnt.dao.PalakMelavaDAO;
import com.vjnt.dao.OtherSchoolActivityDAO;
import com.vjnt.model.PalakMelava;
import com.vjnt.model.OtherSchoolActivity;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.OutputStream;

/**
 * Public servlet to serve images from Palak Melava and Other School Activities
 * No authentication required - for public website display
 */
@WebServlet("/public-school-image")
public class PublicSchoolImageServlet extends HttpServlet {
    
    private PalakMelavaDAO melavaDAO = new PalakMelavaDAO();
    private OtherSchoolActivityDAO activityDAO = new OtherSchoolActivityDAO();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String type = request.getParameter("type");     // "melava" or "activity"
        String idStr = request.getParameter("id");      // record ID
        String photoNum = request.getParameter("photo"); // "1" or "2"
        
        if (type == null || idStr == null || photoNum == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        
        try {
            int id = Integer.parseInt(idStr);
            int photo = Integer.parseInt(photoNum);
            
            if (photo < 1 || photo > 2) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
            
            byte[] imageData = null;
            
            if ("melava".equals(type) || "palak_melava".equals(type)) {
                // Get Palak Melava photo
                PalakMelava melava = melavaDAO.getById(id);
                if (melava != null && melava.getStatus() != null && melava.getStatus().equals("APPROVED")) {
                    imageData = (photo == 1) ? melava.getPhoto1Content() : melava.getPhoto2Content();
                }
            } else if ("activity".equals(type)) {
                // Get Other School Activity photo
                OtherSchoolActivity activity = activityDAO.getById(id);
                if (activity != null && activity.getApprovalStatus() != null && activity.getApprovalStatus().equals("APPROVED")) {
                    imageData = (photo == 1) ? activity.getPhoto1Content() : activity.getPhoto2Content();
                }
            }
            
            if (imageData != null && imageData.length > 0) {
                response.setContentType("image/jpeg");
                response.setContentLength(imageData.length);
                
                OutputStream out = response.getOutputStream();
                out.write(imageData);
                out.flush();
                out.close();
            } else {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            }
            
        } catch (NumberFormatException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        } catch (IOException e) {
            // Check if this is a client abort (connection closed by browser)
            if (e.getMessage() != null && e.getMessage().contains("aborted")) {
                // Client disconnected - harmless, don't log
                System.out.println("Image request cancelled by client (connection aborted)");
            } else {
                // Actual IO error
                System.err.println("Error retrieving image: " + e.getMessage());
                e.printStackTrace();
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            }
        } catch (Exception e) {
            System.err.println("Error retrieving image: " + e.getMessage());
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }
}
