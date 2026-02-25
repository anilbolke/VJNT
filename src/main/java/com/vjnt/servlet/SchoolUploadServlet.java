package com.vjnt.servlet;

import com.vjnt.dao.SchoolDAO;
import com.vjnt.model.School;
import com.vjnt.model.User;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * Servlet to handle School Master Excel Upload
 */
@WebServlet("/upload-schools")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,  // 2MB
    maxFileSize = 1024 * 1024 * 10,       // 10MB
    maxRequestSize = 1024 * 1024 * 50     // 50MB
)
public class SchoolUploadServlet extends HttpServlet {
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("text/html;charset=UTF-8");
        
        // Check authentication
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        
        // Only DATA_ADMIN can upload schools
        if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
            request.setAttribute("errorMessage", "Access Denied. Only Data Admin can upload school data.");
            request.getRequestDispatcher("/data-admin-dashboard.jsp").forward(request, response);
            return;
        }
        
        try {
            
            // Get uploaded file
            Part filePart = request.getPart("schoolFile");
            
            if (filePart == null || filePart.getSize() == 0) {
                request.setAttribute("errorMessage", "Please select a file to upload.");
                request.getRequestDispatcher("/upload-schools.jsp").forward(request, response);
                return;
            }
            
            
            String fileName = getFileName(filePart);
            
            // Validate file type
            if (!fileName.toLowerCase().endsWith(".xlsx") && !fileName.toLowerCase().endsWith(".xls")) {
                request.setAttribute("errorMessage", "Invalid file type. Please upload Excel file (.xlsx or .xls)");
                request.getRequestDispatcher("/upload-schools.jsp").forward(request, response);
                return;
            }
            
            // Parse Excel file
            List<School> schools = parseExcelFile(filePart.getInputStream(), user.getUsername());
            
            if (schools.isEmpty()) {
                request.setAttribute("errorMessage", "No valid school records found in the Excel file.");
                request.getRequestDispatcher("/upload-schools.jsp").forward(request, response);
                return;
            }
            
            // Insert into database
            SchoolDAO schoolDAO = new SchoolDAO();
            int successCount = schoolDAO.batchInsertSchools(schools);
            
            String message = String.format("✓ Successfully uploaded %d school records out of %d total records.", 
                                          successCount, schools.size());
            
            request.setAttribute("successMessage", message);
            request.getRequestDispatcher("/upload-schools.jsp").forward(request, response);
            
        } catch (Exception e) {
            System.err.println("Error uploading schools: " + e.getMessage());
            e.printStackTrace();
            String detailedError = "Error uploading file: " + e.getMessage() + 
                                  ". Check if schools table exists in database.";
            request.setAttribute("errorMessage", detailedError);
            request.getRequestDispatcher("/upload-schools.jsp").forward(request, response);
        }
    }
    
    /**
     * Parse Excel file and extract school data
     */
    private List<School> parseExcelFile(InputStream inputStream, String uploadedBy) throws IOException {
        List<School> schools = new ArrayList<>();
        
        try (Workbook workbook = new XSSFWorkbook(inputStream)) {
            Sheet sheet = workbook.getSheetAt(0);
            
            // Skip header row (row 0)
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                
                if (row == null) {
                    continue;
                }
                
                try {
                    // Excel columns: District Name, School Name, UDISE No
                    String districtName = getCellValueAsString(row.getCell(0));
                    String schoolName = getCellValueAsString(row.getCell(1));
                    String udiseNo = getCellValueAsString(row.getCell(2));
                    
                    
                    // Validate required fields
                    if (udiseNo == null || udiseNo.trim().isEmpty()) {
                        continue;
                    }
                    
                    if (schoolName == null || schoolName.trim().isEmpty()) {
                        continue;
                    }
                    
                    School school = new School(udiseNo.trim(), schoolName.trim(), 
                                               districtName != null ? districtName.trim() : "");
                    school.setCreatedBy(uploadedBy);
                    
                    schools.add(school);
                    
                } catch (Exception e) {
                    System.err.println("Error parsing row " + (i+1) + ": " + e.getMessage());
                    e.printStackTrace();
                }
            }
        }
        
        return schools;
    }
    
    /**
     * Get cell value as String
     */
    private String getCellValueAsString(Cell cell) {
        if (cell == null) return null;
        
        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue();
            case NUMERIC:
                // Handle UDISE numbers stored as numbers
                if (DateUtil.isCellDateFormatted(cell)) {
                    return cell.getDateCellValue().toString();
                } else {
                    return String.valueOf((long) cell.getNumericCellValue());
                }
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            case FORMULA:
                return cell.getCellFormula();
            default:
                return null;
        }
    }
    
    /**
     * Extract filename from Part
     */
    private String getFileName(Part part) {
        String contentDisposition = part.getHeader("content-disposition");
        String[] tokens = contentDisposition.split(";");
        for (String token : tokens) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf("=") + 2, token.length() - 1);
            }
        }
        return "";
    }
}
