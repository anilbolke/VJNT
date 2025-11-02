package com.vjnt.util;

import com.vjnt.dao.StudentDAO;
import com.vjnt.dao.UserDAO;
import com.vjnt.model.Student;
import com.vjnt.model.User;
import com.vjnt.model.User.UserType;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.HashSet;
import java.util.Set;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Excel Student Loader
 * Reads Excel file and imports all student data with support for Marathi headers
 * Also creates user logins based on Division, District, and UDISE NO
 */
public class ExcelStudentLoader {
    
    private StudentDAO studentDAO;
    private UserDAO userDAO;
    private Set<String> processedDivisions;
    private Set<String> processedDistricts;
    private Set<String> processedUdiseNumbers;
    private int totalStudentsCreated;
    private int totalStudentsSkipped;
    private int totalRowsProcessed;
    private int totalUsersCreated;
    
    public ExcelStudentLoader() {
        this.studentDAO = new StudentDAO();
        this.userDAO = new UserDAO();
        this.processedDivisions = new HashSet<>();
        this.processedDistricts = new HashSet<>();
        this.processedUdiseNumbers = new HashSet<>();
        this.totalStudentsCreated = 0;
        this.totalStudentsSkipped = 0;
        this.totalRowsProcessed = 0;
        this.totalUsersCreated = 0;
    }
    
    /**
     * Load students from Excel file
     * Supports both English and Marathi headers
     * 
     * Expected columns:
     * 0: Division
     * 1: Dist (District)
     * 2: UDISE NO
     * 3: Class
     * 4: Section
     * 5: Class Category
     * 6: Name
     * 7: Gender
     * 8: Student PEN
     * 9: मराठी भाषा स्तर (Marathi Level)
     * 10: गणित स्तर (Math Level)
     * 11: इंग्रजी स्तर (English Level)
     */
    public void loadStudentsFromExcel(String excelFilePath) {
        System.out.println("========================================");
        System.out.println("Starting Excel Student Loader");
        System.out.println("========================================");
        System.out.println("File: " + excelFilePath);
        
        try (FileInputStream fis = new FileInputStream(excelFilePath);
             Workbook workbook = new XSSFWorkbook(fis)) {
            
            org.apache.poi.ss.usermodel.Sheet sheet = workbook.getSheetAt(0);
            System.out.println("Total rows in Excel: " + sheet.getLastRowNum());
            
            // Read header row for validation
            Row headerRow = sheet.getRow(0);
            if (headerRow != null) {
                System.out.println("\nHeader columns detected:");
                for (int i = 0; i < 12; i++) {
                    Cell cell = headerRow.getCell(i);
                    String header = getCellValue(cell);
                    System.out.println("  Column " + i + ": " + header);
                }
            }
            
            System.out.println("\nProcessing student records...\n");
            
            // Process data rows (skip header row)
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) continue;
                
                totalRowsProcessed++;
                
                try {
                    // Read all columns
                    String division = getCellValue(row.getCell(0));
                    String district = getCellValue(row.getCell(1));
                    String udiseNo = getCellValue(row.getCell(2));
                    String studentClass = getCellValue(row.getCell(3));
                    String section = getCellValue(row.getCell(4));
                    String classCategory = getCellValue(row.getCell(5));
                    String studentName = getCellValue(row.getCell(6));
                    String gender = getCellValue(row.getCell(7));
                    String studentPen = getCellValue(row.getCell(8));
                    String marathiLevel = getCellValue(row.getCell(9));
                    String mathLevel = getCellValue(row.getCell(10));
                    String englishLevel = getCellValue(row.getCell(11));
                    
                    // Process user logins based on Division, District, and UDISE NO
                    if (!isNullOrEmpty(division)) {
                        processDivision(division);
                    }
                    if (!isNullOrEmpty(district)) {
                        processDistrict(district, division);
                    }
                    if (!isNullOrEmpty(udiseNo)) {
                        processUdiseNo(udiseNo, district, division);
                    }
                    
                    // Validate required fields
                    if (isNullOrEmpty(studentName)) {
                        System.out.println("⚠ Row " + (i + 1) + ": Skipping - Student name is empty");
                        totalStudentsSkipped++;
                        continue;
                    }
                    
                    // Check if student already exists (by PEN if available)
                    if (!isNullOrEmpty(studentPen) && studentDAO.studentExists(studentPen)) {
                        System.out.println("⚠ Row " + (i + 1) + ": Skipping - Student PEN " + studentPen + " already exists");
                        totalStudentsSkipped++;
                        continue;
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
                    student.setCreatedBy("EXCEL_IMPORT");
                    
                    // Insert into database
                    if (studentDAO.createStudent(student)) {
                        totalStudentsCreated++;
                        if (totalStudentsCreated % 50 == 0) {
                            System.out.println("✓ Processed " + totalStudentsCreated + " students...");
                        }
                    } else {
                        System.out.println("✗ Row " + (i + 1) + ": Failed to insert student: " + studentName);
                        totalStudentsSkipped++;
                    }
                    
                } catch (Exception e) {
                    System.out.println("✗ Row " + (i + 1) + ": Error processing row - " + e.getMessage());
                    totalStudentsSkipped++;
                }
            }
            
            printSummary();
            
        } catch (IOException e) {
            System.err.println("Error reading Excel file: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Get cell value as string, handling different cell types
     */
    private String getCellValue(Cell cell) {
        if (cell == null) return null;
        
        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue().trim();
            case NUMERIC:
                // Check if it's an integer or decimal
                double numValue = cell.getNumericCellValue();
                if (numValue == (long) numValue) {
                    return String.valueOf((long) numValue);
                } else {
                    return String.valueOf(numValue);
                }
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            case FORMULA:
                try {
                    return cell.getStringCellValue().trim();
                } catch (Exception e) {
                    return String.valueOf(cell.getNumericCellValue());
                }
            case BLANK:
                return null;
            default:
                return null;
        }
    }
    
    /**
     * Check if string is null or empty
     */
    private boolean isNullOrEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }
    
    /**
     * Process Division - Create 1 login per division
     */
    private void processDivision(String division) {
        if (processedDivisions.contains(division)) {
            return; // Already processed
        }
        
        String username = PasswordUtil.generateUsername("div", division);
        
        if (userDAO.usernameExists(username)) {
            processedDivisions.add(division);
            return;
        }
        
        User user = new User();
        user.setUsername(username);
        user.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
        user.setUserType(UserType.DIVISION);
        user.setDivisionName(division);
        user.setCreatedBy("SYSTEM");
        user.setFullName(division + " Administrator");
        
        if (userDAO.createUser(user)) {
            System.out.println("✓ Created Division user: " + username);
            totalUsersCreated++;
        }
        
        processedDivisions.add(division);
    }
    
    /**
     * Process District - Create 2 logins (Coordinator & 2nd Coordinator)
     */
    private void processDistrict(String district, String division) {
        if (processedDistricts.contains(district)) {
            return; // Already processed
        }
        
        // Create District Coordinator
        String username1 = PasswordUtil.generateUsername("dist_coord", district);
        if (!userDAO.usernameExists(username1)) {
            User user1 = new User();
            user1.setUsername(username1);
            user1.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
            user1.setUserType(UserType.DISTRICT_COORDINATOR);
            user1.setDistrictName(district);
            user1.setDivisionName(division);
            user1.setCreatedBy("SYSTEM");
            user1.setFullName(district + " Coordinator");
            
            if (userDAO.createUser(user1)) {
                System.out.println("✓ Created District Coordinator: " + username1);
                totalUsersCreated++;
            }
        }
        
        // Create 2nd District Coordinator
        String username2 = PasswordUtil.generateUsername("dist_coord2", district);
        if (!userDAO.usernameExists(username2)) {
            User user2 = new User();
            user2.setUsername(username2);
            user2.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
            user2.setUserType(UserType.DISTRICT_2ND_COORDINATOR);
            user2.setDistrictName(district);
            user2.setDivisionName(division);
            user2.setCreatedBy("SYSTEM");
            user2.setFullName(district + " 2nd Coordinator");
            
            if (userDAO.createUser(user2)) {
                System.out.println("✓ Created District 2nd Coordinator: " + username2);
                totalUsersCreated++;
            }
        }
        
        processedDistricts.add(district);
    }
    
    /**
     * Process UDISE NO - Create 2 logins (School Coordinator & Head Master)
     */
    private void processUdiseNo(String udiseNo, String district, String division) {
        if (processedUdiseNumbers.contains(udiseNo)) {
            return; // Already processed
        }
        
        // Create School Coordinator
        String username1 = PasswordUtil.generateUsername("school_coord", udiseNo);
        if (!userDAO.usernameExists(username1)) {
            User user1 = new User();
            user1.setUsername(username1);
            user1.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
            user1.setUserType(UserType.SCHOOL_COORDINATOR);
            user1.setUdiseNo(udiseNo);
            user1.setDistrictName(district);
            user1.setDivisionName(division);
            user1.setCreatedBy("SYSTEM");
            user1.setFullName("School Coordinator - UDISE " + udiseNo);
            
            if (userDAO.createUser(user1)) {
                System.out.println("✓ Created School Coordinator: " + username1 + " (UDISE: " + udiseNo + ")");
                totalUsersCreated++;
            }
        }
        
        // Create Head Master
        String username2 = PasswordUtil.generateUsername("headmaster", udiseNo);
        if (!userDAO.usernameExists(username2)) {
            User user2 = new User();
            user2.setUsername(username2);
            user2.setPassword(PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()));
            user2.setUserType(UserType.HEAD_MASTER);
            user2.setUdiseNo(udiseNo);
            user2.setDistrictName(district);
            user2.setDivisionName(division);
            user2.setCreatedBy("SYSTEM");
            user2.setFullName("Head Master - UDISE " + udiseNo);
            
            if (userDAO.createUser(user2)) {
                System.out.println("✓ Created Head Master: " + username2 + " (UDISE: " + udiseNo + ")");
                totalUsersCreated++;
            }
        }
        
        processedUdiseNumbers.add(udiseNo);
    }
    
    /**
     * Print summary of import
     */
    private void printSummary() {
        System.out.println("\n========================================");
        System.out.println("STUDENT IMPORT SUMMARY");
        System.out.println("========================================");
        System.out.println("Total Rows Processed: " + totalRowsProcessed);
        System.out.println("Students Created: " + totalStudentsCreated);
        System.out.println("Students Skipped: " + totalStudentsSkipped);
        System.out.println("========================================");
        System.out.println("\nUSER LOGIN SUMMARY");
        System.out.println("========================================");
        System.out.println("Unique Divisions Processed: " + processedDivisions.size());
        System.out.println("Unique Districts Processed: " + processedDistricts.size());
        System.out.println("Unique UDISE Numbers Processed: " + processedUdiseNumbers.size());
        System.out.println("----------------------------------------");
        System.out.println("Expected Users:");
        System.out.println("  - Division logins: " + processedDivisions.size());
        System.out.println("  - District logins: " + (processedDistricts.size() * 2));
        System.out.println("  - UDISE logins: " + (processedUdiseNumbers.size() * 2));
        System.out.println("  - TOTAL EXPECTED: " + (processedDivisions.size() + (processedDistricts.size() * 2) + (processedUdiseNumbers.size() * 2)));
        System.out.println("----------------------------------------");
        System.out.println("Total Users Created: " + totalUsersCreated);
        System.out.println("========================================");
        System.out.println("\nDefault Password for all users: " + PasswordUtil.getDefaultPassword());
        System.out.println("Users must change password on first login.");
        System.out.println("========================================");
    }
    
    /**
     * Main method to run the loader
     */
    public static void main(String[] args) {
        String excelPath = "C:\\Users\\Admin\\V2Project\\VJNT Class Managment\\src\\main\\webapp\\Document\\V2 Sample Format Data Entry for Anil.xlsx";
        
        System.out.println("Starting Student Data Import...\n");
        
        ExcelStudentLoader loader = new ExcelStudentLoader();
        loader.loadStudentsFromExcel(excelPath);
        
        System.out.println("\nImport completed!");
    }
}
