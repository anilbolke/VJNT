package com.vjnt.servlet;

import com.vjnt.dao.PalakMelavaDAO;
import com.vjnt.dao.SchoolDAO;
import com.vjnt.model.PalakMelava;
import com.vjnt.model.School;
import com.vjnt.model.User;
import com.vjnt.util.ImageEncryption;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Date;

@WebServlet("/palak-melava-save")
@MultipartConfig
public class PalakMelavaSaveServlet extends HttpServlet {
    
    /**
     * Extract filename from Part header
     */
    private String getFileName(Part part) {
        String contentDisp = part.getHeader("content-disposition");
        String[] tokens = contentDisp.split(";");
        for (String token : tokens) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf("=") + 2, token.length() - 1);
            }
        }
        return "";
    }
    
    /**
     * Read file content into byte array
     */
    private byte[] readFileToBytes(String filePath) throws IOException {
        File file = new File(filePath);
        byte[] fileContent = new byte[(int) file.length()];
        
        try (FileInputStream fis = new FileInputStream(file)) {
            fis.read(fileContent);
        }
        
        return fileContent;
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            out.print("{\"success\": false, \"message\": \"Not authenticated\"}");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        if (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) {
            out.print("{\"success\": false, \"message\": \"Access denied\"}");
            return;
        }
        
        try {
            String action = request.getParameter("action");
            String melavaIdStr = request.getParameter("melavaId");
            
            PalakMelava melava = new PalakMelava();
            
            // Set UDISE and school name
            melava.setUdiseNo(user.getUdiseNo());
            SchoolDAO schoolDAO = new SchoolDAO();
            School school = schoolDAO.getSchoolByUdise(user.getUdiseNo());
            melava.setSchoolName(school != null ? school.getSchoolName() : "");
            
            // Parse form data - EXACT FIELDS ONLY
            String meetingDateStr = request.getParameter("meetingDate");
            melava.setMeetingDate(Date.valueOf(meetingDateStr));
            
            melava.setChiefAttendeeInfo(request.getParameter("chiefAttendeeInfo"));
            melava.setTotalParentsAttended(request.getParameter("totalParentsAttended"));
            melava.setStatus("PENDING_APPROVAL");
            
            // Handle photo 1 upload
            Part photo1Part = request.getPart("photo1");
            if (photo1Part != null && photo1Part.getSize() > 0) {
                try {
                    String originalFileName1 = getFileName(photo1Part);
                    String fileName1 = System.currentTimeMillis() + "_1_" + originalFileName1;
                    String uploadPath = getServletContext().getRealPath("/") + "uploads" + File.separator + "palak-melava" + File.separator;
                    
                    File uploadDir = new File(uploadPath);
                    if (!uploadDir.exists()) {
                        if (!uploadDir.mkdirs()) {
                            System.err.println("Failed to create upload directory: " + uploadPath);
                            throw new IOException("Failed to create upload directory");
                        }
                    }
                    
                    String tempFilePath = uploadPath + fileName1;
                    photo1Part.write(tempFilePath);
                    
                    // Read file content into byte array BEFORE encryption
                    byte[] photoContent1 = readFileToBytes(tempFilePath);
                    
                    // Encrypt the bytes for database storage
                    byte[] encryptedPhotoBytes1 = ImageEncryption.encryptBytesAES(photoContent1);
                    melava.setPhoto1Content(encryptedPhotoBytes1);
                    melava.setPhoto1FileName(originalFileName1);
                    
                    // Encrypt the image
                    String encryptedFileName1 = fileName1 + ".enc";
                    String encryptedFilePath = uploadPath + encryptedFileName1;
                    
                    if (ImageEncryption.encryptFile(tempFilePath, encryptedFilePath)) {
                        melava.setPhoto1Path("uploads/palak-melava/" + encryptedFileName1);
                        System.out.println("Photo 1 uploaded successfully: " + encryptedFilePath);
                    } else {
                        System.err.println("Photo 1 encryption failed");
                        throw new IOException("Photo 1 encryption failed");
                    }
                } catch (Exception e) {
                    System.err.println("Error uploading photo 1: " + e.getMessage());
                    e.printStackTrace();
                    throw new IOException("Error uploading photo 1: " + e.getMessage());
                }
            }
            
            // Handle photo 2 upload
            Part photo2Part = request.getPart("photo2");
            if (photo2Part != null && photo2Part.getSize() > 0) {
                try {
                    String originalFileName2 = getFileName(photo2Part);
                    String fileName2 = System.currentTimeMillis() + "_2_" + originalFileName2;
                    String uploadPath = getServletContext().getRealPath("/") + "uploads" + File.separator + "palak-melava" + File.separator;
                    
                    File uploadDir = new File(uploadPath);
                    if (!uploadDir.exists()) {
                        if (!uploadDir.mkdirs()) {
                            System.err.println("Failed to create upload directory: " + uploadPath);
                            throw new IOException("Failed to create upload directory");
                        }
                    }
                    
                    String tempFilePath = uploadPath + fileName2;
                    photo2Part.write(tempFilePath);
                    
                    // Read file content into byte array BEFORE encryption
                    byte[] photoContent2 = readFileToBytes(tempFilePath);
                    
                    // Encrypt the bytes for database storage
                    byte[] encryptedPhotoBytes2 = ImageEncryption.encryptBytesAES(photoContent2);
                    melava.setPhoto2Content(encryptedPhotoBytes2);
                    melava.setPhoto2FileName(originalFileName2);
                    
                    // Encrypt the image
                    String encryptedFileName2 = fileName2 + ".enc";
                    String encryptedFilePath = uploadPath + encryptedFileName2;
                    
                    if (ImageEncryption.encryptFile(tempFilePath, encryptedFilePath)) {
                        melava.setPhoto2Path("uploads/palak-melava/" + encryptedFileName2);
                        System.out.println("Photo 2 uploaded successfully: " + encryptedFilePath);
                    } else {
                        System.err.println("Photo 2 encryption failed");
                        throw new IOException("Photo 2 encryption failed");
                    }
                } catch (Exception e) {
                    System.err.println("Error uploading photo 2: " + e.getMessage());
                    e.printStackTrace();
                    throw new IOException("Error uploading photo 2: " + e.getMessage());
                }
            }
            
            PalakMelavaDAO dao = new PalakMelavaDAO();
            boolean success;
            
            if ("edit".equals(action) && melavaIdStr != null && !melavaIdStr.isEmpty()) {
                // Update existing
                melava.setMelavaId(Integer.parseInt(melavaIdStr));
                melava.setUpdatedBy(user.getUsername());
                success = dao.update(melava);
            } else {
                // Create new - set submission info when creating with PENDING_APPROVAL status
                melava.setCreatedBy(user.getUsername());
                melava.setSubmittedBy(user.getUsername());
                success = dao.create(melava);
            }
            
            if (success) {
                out.print("{\"success\": true, \"message\": \"Record saved successfully\"}");
            } else {
                out.print("{\"success\": false, \"message\": \"Failed to save record\"}");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
}
