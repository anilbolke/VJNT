package com.vjnt.util;

import com.vjnt.dao.UserDAO;
import com.vjnt.model.User;
import com.vjnt.model.User.UserType;


import java.io.FileInputStream;
import java.io.IOException;
import java.util.*;

import org.apache.poi.sl.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Excel User Loader
 * Reads Excel file and creates user logins based on Division, District, and UDISE NO
 */
public class ExcelUserLoader {
    
    private UserDAO userDAO;
    private Set<String> processedDivisions;
    private Set<String> processedDistricts;
    private Set<String> processedUdiseNumbers;
    private int totalUsersCreated;
    
    public ExcelUserLoader() {
        this.userDAO = new UserDAO();
        this.processedDivisions = new HashSet<>();
        this.processedDistricts = new HashSet<>();
        this.processedUdiseNumbers = new HashSet<>();
        this.totalUsersCreated = 0;
    }
    
    /**
     * Load users from Excel file
     */
    public void loadUsersFromExcel(String excelFilePath) {
        System.out.println("========================================");
        System.out.println("Starting Excel User Loader");
        System.out.println("========================================");
        System.out.println("File: " + excelFilePath);
        
        try (FileInputStream fis = new FileInputStream(excelFilePath);
             Workbook workbook = new XSSFWorkbook(fis)) {
            
            org.apache.poi.ss.usermodel.Sheet sheet = workbook.getSheetAt(0);
            System.out.println("Total rows in Excel: " + sheet.getLastRowNum());
            
            // Skip header row
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) continue;
                
                String division = getCellValue(row.getCell(0));
                String district = getCellValue(row.getCell(1));
                String udiseNo = getCellValue(row.getCell(2));
                
                // Process Division (1 login per division)
                if (division != null && !division.isEmpty()) {
                    processDivision(division);
                }
                
                // Process District (2 logins per district)
                if (district != null && !district.isEmpty()) {
                    processDistrict(district, division);
                }
                
                // Process UDISE NO (2 logins per UDISE)
                if (udiseNo != null && !udiseNo.isEmpty()) {
                    processUdiseNo(udiseNo, district, division);
                }
            }
            
            printSummary();
            
        } catch (IOException e) {
            System.err.println("Error reading Excel file: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Process Division - Create 1 login
     */
    private void processDivision(String division) {
        if (processedDivisions.contains(division)) {
            return; // Already processed
        }
        
        String username = PasswordUtil.generateUsername("DIV_HEAD", division);
        
        // Check if user already exists
        if (userDAO.usernameExists(username)) {
            System.out.println("Division user already exists: " + username);
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
        } else {
            System.out.println("✗ Failed to create Division user: " + username);
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
        String username1 = PasswordUtil.generateUsername("DC1", district);
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
        } else {
            System.out.println("District Coordinator already exists: " + username1);
        }
        
        // Create 2nd District Coordinator
        String username2 = PasswordUtil.generateUsername("DC2", district);
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
        } else {
            System.out.println("District 2nd Coordinator already exists: " + username2);
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
        String username1 = PasswordUtil.generateUsername("SR", udiseNo);
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
        } else {
            System.out.println("School Coordinator already exists: " + username1);
        }
        
        // Create Head Master
        String username2 = PasswordUtil.generateUsername("HM", udiseNo);
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
        } else {
            System.out.println("Head Master already exists: " + username2);
        }
        
        processedUdiseNumbers.add(udiseNo);
    }
    
    /**
     * Get cell value as string
     */
    private String getCellValue(Cell cell) {
        if (cell == null) return null;
        
        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue().trim();
            case NUMERIC:
                return String.valueOf((long) cell.getNumericCellValue());
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            default:
                return null;
        }
    }
    
    /**
     * Print summary
     */
    private void printSummary() {
        System.out.println("\n========================================");
        System.out.println("USER CREATION SUMMARY");
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
        
        ExcelUserLoader loader = new ExcelUserLoader();
        loader.loadUsersFromExcel(excelPath);
    }
}
