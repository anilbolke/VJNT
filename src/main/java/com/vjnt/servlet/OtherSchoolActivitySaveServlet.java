package com.vjnt.servlet;

import com.vjnt.dao.OtherSchoolActivityDAO;
import com.vjnt.dao.SchoolDAO;
import com.vjnt.model.OtherSchoolActivity;
import com.vjnt.model.School;
import com.vjnt.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Date;

@WebServlet("/OtherSchoolActivitySaveServlet")
@MultipartConfig(maxFileSize = 10485760) // 10MB
public class OtherSchoolActivitySaveServlet extends HttpServlet {
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession session = request.getSession(false);
        User user = (User) session.getAttribute("user");
        
        if (user == null || !user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        try {
            String udiseNo = user.getUdiseNo();
            
            // Get school name
            SchoolDAO schoolDAO = new SchoolDAO();
            School school = schoolDAO.getSchoolByUdise(udiseNo);
            String schoolName = school != null ? school.getSchoolName() : "Unknown School";
            
            // Create activity object
            OtherSchoolActivity activity = new OtherSchoolActivity();
            activity.setUdiseNo(udiseNo);
            activity.setSchoolName(schoolName);
            
            // Set form fields
            String dateStr = request.getParameter("activityDate");
            if (dateStr != null && !dateStr.isEmpty()) {
                activity.setActivityDate(Date.valueOf(dateStr));
            }
            
            activity.setActivitySubject(request.getParameter("activitySubject"));
            activity.setGuestsPresent(request.getParameter("guestsPresent"));
            activity.setDescription(request.getParameter("description"));
            activity.setVideoLink(request.getParameter("videoLink"));
            activity.setStatus("DRAFT");
            activity.setCreatedBy(user.getUsername());
            
            // Handle photo1 upload
            Part photo1Part = request.getPart("photo1");
            if (photo1Part != null && photo1Part.getSize() > 0) {
                String fileName1 = getFileName(photo1Part);
                activity.setPhoto1FileName(fileName1);
                
                try (InputStream inputStream = photo1Part.getInputStream()) {
                    byte[] photo1Bytes = inputStream.readAllBytes();
                    activity.setPhoto1Content(photo1Bytes);
                }
            }
            
            // Handle photo2 upload
            Part photo2Part = request.getPart("photo2");
            if (photo2Part != null && photo2Part.getSize() > 0) {
                String fileName2 = getFileName(photo2Part);
                activity.setPhoto2FileName(fileName2);
                
                try (InputStream inputStream = photo2Part.getInputStream()) {
                    byte[] photo2Bytes = inputStream.readAllBytes();
                    activity.setPhoto2Content(photo2Bytes);
                }
            }
            
            // Save to database
            OtherSchoolActivityDAO dao = new OtherSchoolActivityDAO();
            boolean saved = dao.save(activity);
            
            if (saved) {
                response.sendRedirect(request.getContextPath() + 
                    "/other-school-activity.jsp?success=Activity saved successfully");
            } else {
                response.sendRedirect(request.getContextPath() + 
                    "/other-school-activity.jsp?error=Failed to save activity");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + 
                "/other-school-activity.jsp?error=" + e.getMessage());
        }
    }
    
    private String getFileName(Part part) {
        String contentDisposition = part.getHeader("content-disposition");
        for (String token : contentDisposition.split(";")) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf('=') + 1).trim().replace("\"", "");
            }
        }
        return null;
    }
}
