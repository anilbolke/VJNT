package com.vjnt.dao;

import com.vjnt.model.School;
import com.vjnt.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * School Data Access Object
 * Handles database operations for School master data
 */
public class SchoolDAO {
    
    /**
     * Insert or update school record
     */
    public boolean upsertSchool(School school) {
        String sql = "INSERT INTO schools (udise_no, school_name, district_name, created_by) " +
                     "VALUES (?, ?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE " +
                     "school_name = VALUES(school_name), " +
                     "district_name = VALUES(district_name), " +
                     "updated_by = VALUES(created_by), " +
                     "updated_date = NOW()";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, school.getUdiseNo());
            pstmt.setString(2, school.getSchoolName());
            pstmt.setString(3, school.getDistrictName());
            pstmt.setString(4, school.getCreatedBy());
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error upserting school: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Batch insert schools
     */
    public int batchInsertSchools(List<School> schools) {
        String sql = "INSERT INTO schools (udise_no, school_name, district_name, created_by) " +
                     "VALUES (?, ?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE " +
                     "school_name = VALUES(school_name), " +
                     "district_name = VALUES(district_name), " +
                     "updated_by = VALUES(created_by), " +
                     "updated_date = NOW()";
        
        int successCount = 0;
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            conn.setAutoCommit(false);
            
            for (School school : schools) {
                pstmt.setString(1, school.getUdiseNo());
                pstmt.setString(2, school.getSchoolName());
                pstmt.setString(3, school.getDistrictName());
                pstmt.setString(4, school.getCreatedBy());
                pstmt.addBatch();
            }
            
            int[] results = pstmt.executeBatch();
            conn.commit();
            
            for (int result : results) {
                if (result > 0) successCount++;
            }
            
        } catch (SQLException e) {
            System.err.println("Error batch inserting schools: " + e.getMessage());
            e.printStackTrace();
        }
        
        return successCount;
    }
    
    /**
     * Get school by UDISE number
     */
    public School getSchoolByUdise(String udiseNo) {
        String sql = "SELECT * FROM schools WHERE udise_no = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return extractSchoolFromResultSet(rs);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting school by UDISE: " + e.getMessage());
            e.printStackTrace();
        }
        
        return null;
    }
    
    /**
     * Get all schools
     */
    public List<School> getAllSchools() {
        List<School> schools = new ArrayList<>();
        String sql = "SELECT * FROM schools ORDER BY district_name, school_name";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            while (rs.next()) {
                schools.add(extractSchoolFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting all schools: " + e.getMessage());
            e.printStackTrace();
        }
        
        return schools;
    }
    
    /**
     * Get schools by district
     */
    public List<School> getSchoolsByDistrict(String districtName) {
        List<School> schools = new ArrayList<>();
        String sql = "SELECT * FROM schools WHERE district_name = ? ORDER BY school_name";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, districtName);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                schools.add(extractSchoolFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting schools by district: " + e.getMessage());
            e.printStackTrace();
        }
        
        return schools;
    }
    
    /**
     * Get schools by division
     */
    public List<School> getSchoolsByDivision(String divisionName) {
        List<School> schools = new ArrayList<>();
        String sql = "SELECT * FROM schools WHERE division_name = ? ORDER BY district_name, school_name";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, divisionName);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                schools.add(extractSchoolFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting schools by division: " + e.getMessage());
            e.printStackTrace();
        }
        
        return schools;
    }
    
    /**
     * Get school count
     */
    public int getSchoolCount() {
        String sql = "SELECT COUNT(*) FROM schools";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting school count: " + e.getMessage());
            e.printStackTrace();
        }
        
        return 0;
    }
    
    /**
     * Delete all schools (for re-upload)
     */
    public boolean deleteAllSchools() {
        String sql = "DELETE FROM schools";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.executeUpdate();
            return true;
            
        } catch (SQLException e) {
            System.err.println("Error deleting all schools: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Extract School object from ResultSet
     */
    private School extractSchoolFromResultSet(ResultSet rs) throws SQLException {
        School school = new School();
        school.setSchoolId(rs.getInt("school_id"));
        school.setUdiseNo(rs.getString("udise_no"));
        school.setSchoolName(rs.getString("school_name"));
        school.setDistrictName(rs.getString("district_name"));
        school.setCreatedDate(rs.getTimestamp("created_date"));
        school.setCreatedBy(rs.getString("created_by"));
        school.setUpdatedDate(rs.getTimestamp("updated_date"));
        school.setUpdatedBy(rs.getString("updated_by"));
        return school;
    }
}
