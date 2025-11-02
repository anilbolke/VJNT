package com.vjnt.servlet;

import com.vjnt.dao.StudentDAO;
import com.vjnt.dao.UserDAO;
import com.vjnt.model.Student;
import com.vjnt.model.User;
import com.vjnt.util.PasswordUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashSet;
import java.util.Set;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Excel Upload Servlet
 * Handles Excel file upload for bulk student data import
 */
@WebServlet("/upload-excel")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,  // 2MB
    maxFileSize = 1024 * 1024 * 10,        // 10MB
    maxRequestSize = 1024 * 1024 * 50      // 50MB
)
public class ExcelUploadServlet extends HttpServlet {
    
    private StudentDAO studentDAO;
    private UserDAO userDAO;
    
    @Override
    public void init() throws ServletException {
        studentDAO = new StudentDAO();
        userDAO = new UserDAO();
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        // Check authentication
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.getWriter().print("{\"success\": false, \"message\": \"Not authenticated\"}");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        
        // Only DATA_ADMIN can upload
        if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
            response.getWriter().print("{\"success\": false, \"message\": \"Access denied. Only Data Admin can upload files.\"}");
            return;
        }
        
        try {
            // Get uploaded file
            Part filePart = request.getPart("excelFile");
            if (filePart == null) {
                response.getWriter().print("{\"success\": false, \"message\": \"No file uploaded\"}");
                return;
            }
            
            String fileName = getFileName(filePart);
            System.out.println("Uploading file: " + fileName);
            
            // Validate file type
            if (!fileName.endsWith(".xlsx") && !fileName.endsWith(".xls")) {
                response.getWriter().print("{\"success\": false, \"message\": \"Invalid file type. Please upload Excel file (.xlsx or .xls)\"}");
                return;
            }
            
            // Process Excel file
            InputStream fileContent = filePart.getInputStream();
            ImportResult result = processExcelFile(fileContent, user.getUsername());
            
            if (result.success) {
                String message = String.format(
                    "Import completed successfully!\\n\\n" +
                    "Rows Processed: %d\\n" +
                    "Students Created: %d\\n" +
                    "Students Skipped: %d\\n" +
                    "Users Created: %d\\n" +
                    "Divisions: %d\\n" +
                    "Districts: %d\\n" +
                    "Schools (UDISE): %d",
                    result.rowsProcessed,
                    result.studentsCreated,
                    result.studentsSkipped,
                    result.usersCreated,
                    result.divisionsProcessed,
                    result.districtsProcessed,
                    result.udiseNumbersProcessed
                );
                
                response.getWriter().print("{\"success\": true, \"message\": \"" + message + "\"}");
            } else {
                response.getWriter().print("{\"success\": false, \"message\": \"" + result.errorMessage + "\"}");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().print("{\"success\": false, \"message\": \"Error processing file: " + e.getMessage() + "\"}");
        }
    }
    
    /**
     * Process Excel file and import data
     */
    private ImportResult processExcelFile(InputStream fileContent, String uploadedBy) {
        ImportResult result = new ImportResult();
        Set<String> processedDivisions = new HashSet<>();
        Set<String> processedDistricts = new HashSet<>();
        Set<String> processedUdiseNumbers = new HashSet<>();
        
        try (Workbook workbook = new XSSFWorkbook(fileContent)) {
            org.apache.poi.ss.usermodel.Sheet sheet = workbook.getSheetAt(0);
            
            System.out.println("Total rows in Excel: " + sheet.getLastRowNum());
            
            // Process data rows (skip header)
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) continue;
                
                result.rowsProcessed++;
                
                try {
                    // Read all columns
                    String division = getCellValue(row.getCell(0)).trim();
                    String district = getCellValue(row.getCell(1)).trim();
                    String udiseNo = getCellValue(row.getCell(2)).trim();
                    String studentClass = getCellValue(row.getCell(3)).trim();
                    String section = getCellValue(row.getCell(4)).trim();
                    String classCategory = getCellValue(row.getCell(5)).trim();
                    String studentName = getCellValue(row.getCell(6)).trim();
                    String gender = getCellValue(row.getCell(7)).trim();
                    String studentPen = getCellValue(row.getCell(8)).trim();
                    String marathiLevel = getCellValue(row.getCell(9)).trim();
                    String mathLevel = getCellValue(row.getCell(10)).trim();
                    String englishLevel = getCellValue(row.getCell(11)).trim();
                    
                    // Validate required fields
                    if (isEmpty(studentName) || isEmpty(studentClass)) {
                        result.studentsSkipped++;
                        continue;
                    }
                    
                    // Check if student already exists by PEN
                    if (!isEmpty(studentPen) && studentDAO.studentExists(studentPen)) {
                        System.out.println("⚠ Student already exists with PEN: " + studentPen + " - Skipping");
                        result.studentsSkipped++;
                        continue;
                    }
                    
                    // Log UDISE number for debugging
                    if (i <= 2) { // Only log first few rows
                        System.out.println("📝 Processing student - UDISE: '" + udiseNo + "', Name: " + studentName);
                    }
                    
                    // Create student object
                    Student student = new Student();
                    student.setDivision(division);
                    student.setDistrict(district);
                    student.setUdiseNo(udiseNo);
                    student.setStudentClass(studentClass);
                    student.setSection(section);
                    student.setClassCategory(classCategory);
                    student.setStudentName(studentName);
                    student.setGender(gender);
                    student.setStudentPen(studentPen);
                    student.setMarathiLevel(marathiLevel);
                    student.setMathLevel(mathLevel);
                    student.setEnglishLevel(englishLevel);
                    student.setCreatedBy(uploadedBy);
                    
                    // Save student
                    if (studentDAO.createStudent(student)) {
                        result.studentsCreated++;
                        
                        // Process Division (create 1 login) - only if not already processed
                        if (!isEmpty(division) && !processedDivisions.contains(division)) {
                            createDivisionUser(division, uploadedBy);
                            processedDivisions.add(division);
                            result.usersCreated++;
                        }
                        
                        // Process District (create 2 logins) - only if not already processed
                        if (!isEmpty(district) && !processedDistricts.contains(district)) {
                            result.usersCreated += createDistrictUsers(district, division, uploadedBy);
                            processedDistricts.add(district);
                        }
                        
                        // Process UDISE NO (create 2 logins) - only if not already processed
                        if (!isEmpty(udiseNo) && !processedUdiseNumbers.contains(udiseNo)) {
                            result.usersCreated += createSchoolUsers(udiseNo, district, division, uploadedBy);
                            processedUdiseNumbers.add(udiseNo);
                        }
                    } else {
                        result.studentsSkipped++;
                    }
                    
                } catch (Exception e) {
                    System.err.println("Error processing row " + i + ": " + e.getMessage());
                    result.studentsSkipped++;
                }
            }
            
            result.divisionsProcessed = processedDivisions.size();
            result.districtsProcessed = processedDistricts.size();
            result.udiseNumbersProcessed = processedUdiseNumbers.size();
            result.success = true;
            
        } catch (Exception e) {
            e.printStackTrace();
            result.success = false;
            result.errorMessage = "Error reading Excel file: " + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * Create Division user
     */
    private void createDivisionUser(String division, String createdBy) {
        String username = PasswordUtil.generateUsername("div", division);
        if (!userDAO.usernameExists(username)) {
            User user = new User();
            user.setUsername(username);
            user.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
            user.setUserType(User.UserType.DIVISION);
            user.setDivisionName(division);
            user.setCreatedBy(createdBy);
            user.setFullName(division + " Division");
            userDAO.createUser(user);
            System.out.println("✓ Created Division user: " + username);
        }
    }
    
    /**
     * Create District users (2 coordinators)
     */
    private int createDistrictUsers(String district, String division, String createdBy) {
        int created = 0;
        
        // District Coordinator
        String username1 = PasswordUtil.generateUsername("dist_coord", district);
        if (!userDAO.usernameExists(username1)) {
            User user1 = new User();
            user1.setUsername(username1);
            user1.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
            user1.setUserType(User.UserType.DISTRICT_COORDINATOR);
            user1.setDistrictName(district);
            user1.setDivisionName(division);
            user1.setCreatedBy(createdBy);
            user1.setFullName(district + " District Coordinator");
            if (userDAO.createUser(user1)) {
                created++;
                System.out.println("✓ Created District Coordinator: " + username1);
            }
        }
        
        // District 2nd Coordinator
        String username2 = PasswordUtil.generateUsername("dist_coord2", district);
        if (!userDAO.usernameExists(username2)) {
            User user2 = new User();
            user2.setUsername(username2);
            user2.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
            user2.setUserType(User.UserType.DISTRICT_2ND_COORDINATOR);
            user2.setDistrictName(district);
            user2.setDivisionName(division);
            user2.setCreatedBy(createdBy);
            user2.setFullName(district + " 2nd Coordinator");
            if (userDAO.createUser(user2)) {
                created++;
                System.out.println("✓ Created District 2nd Coordinator: " + username2);
            }
        }
        
        return created;
    }
    
    /**
     * Create School users (School Coordinator & Head Master)
     */
    private int createSchoolUsers(String udiseNo, String district, String division, String createdBy) {
        int created = 0;
        
        // School Coordinator
        String username1 = PasswordUtil.generateUsername("school_coord", udiseNo);
        if (!userDAO.usernameExists(username1)) {
            User user1 = new User();
            user1.setUsername(username1);
            user1.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
            user1.setUserType(User.UserType.SCHOOL_COORDINATOR);
            user1.setUdiseNo(udiseNo);
            user1.setDistrictName(district);
            user1.setDivisionName(division);
            user1.setCreatedBy(createdBy);
            user1.setFullName("School Coordinator - UDISE " + udiseNo);
            if (userDAO.createUser(user1)) {
                created++;
                System.out.println("✓ Created School Coordinator: " + username1 + " with UDISE: '" + udiseNo + "'");
            }
        } else {
            System.out.println("⚠ School Coordinator already exists: " + username1 + " (UDISE: '" + udiseNo + "')");
        }
        
        // Head Master
        String username2 = PasswordUtil.generateUsername("headmaster", udiseNo);
        if (!userDAO.usernameExists(username2)) {
            User user2 = new User();
            user2.setUsername(username2);
            user2.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
            user2.setUserType(User.UserType.HEAD_MASTER);
            user2.setUdiseNo(udiseNo);
            user2.setDistrictName(district);
            user2.setDivisionName(division);
            user2.setCreatedBy(createdBy);
            user2.setFullName("Head Master - UDISE " + udiseNo);
            if (userDAO.createUser(user2)) {
                created++;
                System.out.println("✓ Created Head Master: " + username2 + " with UDISE: '" + udiseNo + "'");
            }
        } else {
            System.out.println("⚠ Head Master already exists: " + username2 + " (UDISE: '" + udiseNo + "')");
        }
        
        return created;
    }
    
    /**
     * Get cell value as string
     */
    private String getCellValue(Cell cell) {
        if (cell == null) return "";
        
        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue().trim();
            case NUMERIC:
                return String.valueOf((long) cell.getNumericCellValue());
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            case FORMULA:
                return cell.getCellFormula();
            default:
                return "";
        }
    }
    
    /**
     * Check if string is empty
     */
    private boolean isEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }
    
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
     * Import Result class
     */
    private static class ImportResult {
        boolean success = false;
        String errorMessage = "";
        int rowsProcessed = 0;
        int studentsCreated = 0;
        int studentsSkipped = 0;
        int usersCreated = 0;
        int divisionsProcessed = 0;
        int districtsProcessed = 0;
        int udiseNumbersProcessed = 0;
    }
}
