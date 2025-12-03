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
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
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
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().print("{\"success\": false, \"message\": \"Not authenticated\"}");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        
        // Only DATA_ADMIN can upload
        if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.getWriter().print("{\"success\": false, \"message\": \"Access denied. Only Data Admin can upload files.\"}");
            return;
        }
        
        InputStream fileContent = null;
        try {
            // Get uploaded file
            Part filePart = request.getPart("excelFile");
            if (filePart == null) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.getWriter().print("{\"success\": false, \"message\": \"No file uploaded\"}");
                return;
            }
            
            String fileName = getFileName(filePart);
            System.out.println("Uploading file: " + fileName);
            
            // Validate file type
            if (!fileName.endsWith(".xlsx") && !fileName.endsWith(".xls")) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.getWriter().print("{\"success\": false, \"message\": \"Invalid file type. Please upload Excel file (.xlsx or .xls)\"}");
                return;
            }
            
            // Check file size
            long fileSize = filePart.getSize();
            if (fileSize > 52428800) { // 50MB limit
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.getWriter().print("{\"success\": false, \"message\": \"File size exceeds 50MB limit. Current size: " + (fileSize / 1024 / 1024) + "MB\"}");
                return;
            }
            
            System.out.println("File size: " + (fileSize / 1024) + "KB");
            
            // Process Excel file
            fileContent = filePart.getInputStream();
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
                
                response.setStatus(HttpServletResponse.SC_OK);
                response.getWriter().print("{\"success\": true, \"message\": \"" + message + "\"}");
            } else {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                response.getWriter().print("{\"success\": false, \"message\": \"" + result.errorMessage + "\"}");
            }
            
        } catch (IllegalStateException e) {
            System.err.println("File size limit exceeded or multipart parsing error: " + e.getMessage());
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_REQUEST_ENTITY_TOO_LARGE);
            response.getWriter().print("{\"success\": false, \"message\": \"File size exceeds maximum allowed size or multipart parsing error\"}");
        } catch (Exception e) {
            System.err.println("Error processing file: " + e.getMessage());
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().print("{\"success\": false, \"message\": \"Error processing file: " + e.getMessage() + "\"}");
        } finally {
            if (fileContent != null) {
                try {
                    fileContent.close();
                } catch (IOException e) {
                    System.err.println("Error closing file stream: " + e.getMessage());
                }
            }
        }
    }
    
    /**
     * Process Excel file and import data (FAST-TRACK with batch processing)
     */
    private ImportResult processExcelFile(InputStream fileContent, String uploadedBy) {
        ImportResult result = new ImportResult();
        Set<String> processedDivisions = new HashSet<>();
        Set<String> processedDistricts = new HashSet<>();
        Set<String> processedUdiseNumbers = new HashSet<>();
        
        // Collections for batch processing
        List<Student> studentBatch = new ArrayList<>();
        List<User> userBatch = new ArrayList<>();
        final int BATCH_SIZE = 100;  // Process in batches of 100 for optimal performance
        
        try (Workbook workbook = new XSSFWorkbook(fileContent)) {
            org.apache.poi.ss.usermodel.Sheet sheet = workbook.getSheetAt(0);
            
            if (sheet == null) {
                result.success = false;
                result.errorMessage = "Excel file is empty or first sheet is missing";
                return result;
            }
            
            int totalRows = sheet.getLastRowNum();
            System.out.println("Total rows in Excel: " + totalRows);
            
            if (totalRows <= 0) {
                result.success = false;
                result.errorMessage = "Excel file contains no data rows";
                return result;
            }
            
            // FAST-TRACK: Pre-load all existing PENs to avoid repeated DB queries
            List<String> allPensInFile = new ArrayList<>();
            System.out.println("📊 FAST-TRACK: Pre-scanning file for all PENs...");
            for (int i = 1; i <= totalRows; i++) {
                Row row = sheet.getRow(i);
                if (row != null) {
                    String studentPen = getCellValue(row.getCell(8)).trim();
                    if (!isEmpty(studentPen)) {
                        allPensInFile.add(studentPen);
                    }
                }
            }
            
            // Load existing PENs in bulk (single query instead of thousands)
            Set<String> existingPens = new HashSet<>(studentDAO.getExistingPens(allPensInFile));
            System.out.println("✓ Found " + existingPens.size() + " existing students");
            
            // Process data rows (skip header)
            long startTime = System.currentTimeMillis();
            for (int i = 1; i <= totalRows; i++) {
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
                    
                    // FAST-TRACK: Check against pre-loaded PENs (no DB query)
                    if (!isEmpty(studentPen) && existingPens.contains(studentPen)) {
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
                    
                    // FAST-TRACK: Add to batch instead of inserting immediately
                    studentBatch.add(student);
                    
                    // When batch reaches size, flush to database
                    if (studentBatch.size() >= BATCH_SIZE) {
                        int inserted = studentDAO.batchCreateStudents(studentBatch);
                        result.studentsCreated += inserted;
                        studentBatch.clear();
                    }
                    
                    // Track unique divisions, districts, and UDISE for user creation
                    if (!isEmpty(division) && !processedDivisions.contains(division)) {
                        processedDivisions.add(division);
                        User divUser = createDivisionUserObject(division, uploadedBy);
                        userBatch.add(divUser);
                    }
                    
                    if (!isEmpty(district) && !processedDistricts.contains(district)) {
                        processedDistricts.add(district);
                        User dcUser1 = createDistrictUserObject(district, division, "DC1", uploadedBy);
                        User dcUser2 = createDistrictUserObject(district, division, "DC2", uploadedBy);
                        userBatch.add(dcUser1);
                        userBatch.add(dcUser2);
                    }
                    
                    if (!isEmpty(udiseNo) && !processedUdiseNumbers.contains(udiseNo)) {
                        processedUdiseNumbers.add(udiseNo);
                        User scUser = createSchoolUserObject(udiseNo, district, division, "SR", uploadedBy);
                        User hmUser = createSchoolUserObject(udiseNo, district, division, "HM", uploadedBy);
                        userBatch.add(scUser);
                        userBatch.add(hmUser);
                    }
                    
                    // Flush user batch when it reaches size
                    if (userBatch.size() >= BATCH_SIZE) {
                        int inserted = userDAO.batchCreateUsers(userBatch);
                        result.usersCreated += inserted;
                        userBatch.clear();
                    }
                    
                } catch (Exception e) {
                    System.err.println("Error processing row " + i + ": " + e.getMessage());
                    result.studentsSkipped++;
                }
            }
            
            // FAST-TRACK: Flush remaining batches
            if (!studentBatch.isEmpty()) {
                int inserted = studentDAO.batchCreateStudents(studentBatch);
                result.studentsCreated += inserted;
            }
            
            if (!userBatch.isEmpty()) {
                int inserted = userDAO.batchCreateUsers(userBatch);
                result.usersCreated += inserted;
            }
            
            long duration = System.currentTimeMillis() - startTime;
            System.out.println("✓ Excel processing completed in " + duration + "ms");
            System.out.println("  - Students created: " + result.studentsCreated);
            System.out.println("  - Users created: " + result.usersCreated);
            
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
     * FAST-TRACK: Create Division user object (for batch processing)
     */
    private User createDivisionUserObject(String division, String createdBy) {
        String username = PasswordUtil.generateUsername("DIV_HEAD", division);
        User user = new User();
        user.setUsername(username);
        user.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
        user.setUserType(User.UserType.DIVISION);
        user.setDivisionName(division);
        user.setCreatedBy(createdBy);
        user.setFullName(division + " Administrator");
        return user;
    }
    
    /**
     * FAST-TRACK: Create District user object (for batch processing)
     */
    private User createDistrictUserObject(String district, String division, String coordType, String createdBy) {
        String username = PasswordUtil.generateUsername(coordType, district);
        User user = new User();
        user.setUsername(username);
        user.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
        
        if ("DC1".equals(coordType)) {
            user.setUserType(User.UserType.DISTRICT_COORDINATOR);
        } else {
            user.setUserType(User.UserType.DISTRICT_2ND_COORDINATOR);
        }
        
        user.setDistrictName(district);
        user.setDivisionName(division);
        user.setCreatedBy(createdBy);
        user.setFullName(district + " Coordinator (" + coordType + ")");
        return user;
    }
    
    /**
     * FAST-TRACK: Create School user object (for batch processing)
     */
    private User createSchoolUserObject(String udiseNo, String district, String division, String roleType, String createdBy) {
        String username = PasswordUtil.generateUsername(roleType, udiseNo);
        User user = new User();
        user.setUsername(username);
        user.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
        
        if ("SR".equals(roleType)) {
            user.setUserType(User.UserType.SCHOOL_COORDINATOR);
            user.setFullName("School Coordinator - UDISE " + udiseNo);
        } else {
            user.setUserType(User.UserType.HEAD_MASTER);
            user.setFullName("Head Master - UDISE " + udiseNo);
        }
        
        user.setUdiseNo(udiseNo);
        user.setDistrictName(district);
        user.setDivisionName(division);
        user.setCreatedBy(createdBy);
        return user;
    }
    
    /**
     * Create Division user (legacy method, kept for compatibility)
     */
    private void createDivisionUser(String division, String createdBy) {
        User user = createDivisionUserObject(division, createdBy);
        userDAO.createUser(user);
    }
    
    /**
     * Create District users (legacy method, kept for compatibility)
     */
    private int createDistrictUsers(String district, String division, String createdBy) {
        User user1 = createDistrictUserObject(district, division, "DC1", createdBy);
        User user2 = createDistrictUserObject(district, division, "DC2", createdBy);
        int created = 0;
        if (userDAO.createUser(user1)) created++;
        if (userDAO.createUser(user2)) created++;
        return created;
    }
    
    /**
     * Create School users (legacy method, kept for compatibility)
     */
    private int createSchoolUsers(String udiseNo, String district, String division, String createdBy) {
        User user1 = createSchoolUserObject(udiseNo, district, division, "SR", createdBy);
        User user2 = createSchoolUserObject(udiseNo, district, division, "HM", createdBy);
        int created = 0;
        if (userDAO.createUser(user1)) created++;
        if (userDAO.createUser(user2)) created++;
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
