package com.vjnt.servlet;

import com.vjnt.dao.OtherSchoolActivityDAO;
import com.vjnt.model.OtherSchoolActivity;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.OutputStream;

@WebServlet("/OtherSchoolActivityImageServlet")
public class OtherSchoolActivityImageServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            int activityId = Integer.parseInt(request.getParameter("activityId"));
            String photoType = request.getParameter("photoType"); // "photo1" or "photo2"
            
            OtherSchoolActivityDAO dao = new OtherSchoolActivityDAO();
            OtherSchoolActivity activity = dao.getById(activityId);
            
            if (activity != null) {
                byte[] imageData = null;
                
                if ("photo1".equals(photoType)) {
                    imageData = activity.getPhoto1Content();
                } else if ("photo2".equals(photoType)) {
                    imageData = activity.getPhoto2Content();
                }
                
                if (imageData != null && imageData.length > 0) {
                    response.setContentType("image/jpeg");
                    response.setContentLength(imageData.length);
                    
                    try (OutputStream out = response.getOutputStream()) {
                        out.write(imageData);
                        out.flush();
                    }
                } else {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND);
                }
            } else {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }
}
