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
     * Get multiple schools by UDISE numbers (batch fetch for performance)
     */
    public List<School> getSchoolsByUdises(List<String> udiseNumbers) {
        List<School> schools = new ArrayList<>();
        if (udiseNumbers == null || udiseNumbers.isEmpty()) {
            return schools;
        }
        
        StringBuilder sql = new StringBuilder("SELECT * FROM schools WHERE udise_no IN (");
        for (int i = 0; i < udiseNumbers.size(); i++) {
            if (i > 0) sql.append(",");
            sql.append("?");
        }
        sql.append(")");
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < udiseNumbers.size(); i++) {
                pstmt.setString(i + 1, udiseNumbers.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                schools.add(extractSchoolFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting schools by UDISE numbers: " + e.getMessage());
            e.printStackTrace();
        }
        
        return schools;
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
     * Get schools by division (based on students' division)
     */
    public List<School> getSchoolsByDivision(String divisionName) {
        return getSchoolsWithStudents(divisionName);
    }

    /**
     * Real school counts per district for a division, read from the schools master
     * table itself rather than derived from distinct UDISE numbers on the students
     * table (which only ever counts schools that currently have an active student on
     * file, undercounting/overcounting whenever a school has none or a UDISE typo).
     * The schools table has no division column of its own, so students is touched
     * only to resolve which districts belong to the division.
     */
    public java.util.Map<String, Integer> getSchoolCountsByDistrictForDivision(String divisionName) {
        java.util.Map<String, Integer> counts = new java.util.LinkedHashMap<>();
        String sql = "SELECT s.district_name AS district, COUNT(DISTINCT s.udise_no) AS cnt " +
                     "FROM schools s " +
                     "WHERE s.district_name COLLATE utf8mb4_unicode_ci IN " +
                     "      (SELECT DISTINCT st.district COLLATE utf8mb4_unicode_ci " +
                     "       FROM students st WHERE st.division = ?) " +
                     "GROUP BY s.district_name";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, divisionName);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                counts.put(rs.getString("district"), rs.getInt("cnt"));
            }

        } catch (SQLException e) {
            System.err.println("Error getting school counts by district for division: " + e.getMessage());
            e.printStackTrace();
        }

        return counts;
    }

    /**
     * Every school that actually has active class I-IX students, across all divisions.
     * Unlike {@link #getAllSchools()} this is driven from the students table, so it neither
     * lists schools with nobody in them nor loses students whose UDISE is missing from the
     * schools master.
     */
    public List<School> getSchoolsWithStudents() {
        return getSchoolsWithStudents(null);
    }

    /**
     * Schools that have active class I-IX students, optionally scoped to one division.
     *
     * Driven from students, not schools: a UDISE that never made it into the schools
     * master would be dropped by an INNER JOIN, taking its students out of every
     * division total with it. LEFT JOIN keeps them and falls back to the district
     * recorded on the student rows. GROUP BY collapses duplicate schools rows for the
     * same UDISE, which would otherwise be counted twice by the callers that aggregate.
     *
     * @param divisionName division to scope to, or null/empty for every division
     */
    public List<School> getSchoolsWithStudents(String divisionName) {
        List<School> schools = new ArrayList<>();
        boolean scoped = divisionName != null && !divisionName.trim().isEmpty();

        String sql = "SELECT st.udise_no, " +
                     "MAX(s.school_id) AS school_id, " +
                     "COALESCE(MAX(s.school_name), CONCAT('UDISE ', st.udise_no, ' (not in schools master)')) AS school_name, " +
                     "COALESCE(MAX(s.district_name), MAX(st.district), 'Unknown District') AS district_name " +
                     "FROM students st " +
                     "LEFT JOIN schools s ON s.udise_no COLLATE utf8mb4_unicode_ci = st.udise_no " +
                     "WHERE st.is_active = 1 " +
                     // Same I-IX restriction the level counts use, from the same constant so
                     // the two cannot drift. Without it a school whose only students sit
                     // outside the programme would list with a zero total.
                     "AND TRIM(st.class) IN " + com.vjnt.dao.StudentDAO.CLASS_I_TO_IX + " " +
                     (scoped ? "AND st.division = ? " : "") +
                     "GROUP BY st.udise_no " +
                     "ORDER BY district_name, school_name";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            if (scoped) {
                pstmt.setString(1, divisionName);
            }
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                School school = new School();
                school.setSchoolId(rs.getInt("school_id"));
                school.setUdiseNo(rs.getString("udise_no"));
                school.setSchoolName(rs.getString("school_name"));
                school.setDistrictName(rs.getString("district_name"));
                schools.add(school);
            }

        } catch (SQLException e) {
            System.err.println("Error getting schools with students: " + e.getMessage());
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
