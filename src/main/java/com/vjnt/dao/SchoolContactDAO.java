package com.vjnt.dao;

import com.vjnt.model.SchoolContact;
import com.vjnt.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * SchoolContact Data Access Object
 * Handles database operations for school contact information
 * This is for contact directory data, NOT login users
 */
public class SchoolContactDAO {
    
    /**
     * Create a new school contact
     */
    public boolean createContact(SchoolContact contact) {
        String sql = "INSERT INTO school_contacts (udise_no, school_name, district_name, contact_type, " +
                    "full_name, mobile, whatsapp_number, remarks, created_by) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            pstmt.setString(1, contact.getUdiseNo());
            pstmt.setString(2, contact.getSchoolName());
            pstmt.setString(3, contact.getDistrictName());
            pstmt.setString(4, contact.getContactType());
            pstmt.setString(5, contact.getFullName());
            pstmt.setString(6, contact.getMobile());
            pstmt.setString(7, contact.getWhatsappNumber());
            pstmt.setString(8, contact.getRemarks());
            pstmt.setString(9, contact.getCreatedBy());
            
            int rowsAffected = pstmt.executeUpdate();
            
            if (rowsAffected > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    contact.setContactId(rs.getInt(1));
                }
                return true;
            }
            return false;
            
        } catch (SQLException e) {
            System.err.println("Error creating school contact: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Update school contact
     */
    public boolean updateContact(SchoolContact contact) {
        String sql = "UPDATE school_contacts SET udise_no = ?, school_name = ?, district_name = ?, " +
                    "contact_type = ?, full_name = ?, mobile = ?, whatsapp_number = ?, remarks = ?, " +
                    "updated_by = ?, updated_date = NOW() " +
                    "WHERE contact_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, contact.getUdiseNo());
            pstmt.setString(2, contact.getSchoolName());
            pstmt.setString(3, contact.getDistrictName());
            pstmt.setString(4, contact.getContactType());
            pstmt.setString(5, contact.getFullName());
            pstmt.setString(6, contact.getMobile());
            pstmt.setString(7, contact.getWhatsappNumber());
            pstmt.setString(8, contact.getRemarks());
            pstmt.setString(9, contact.getUpdatedBy());
            pstmt.setInt(10, contact.getContactId());
            
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating school contact: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Delete school contact
     */
    public boolean deleteContact(int contactId) {
        String sql = "DELETE FROM school_contacts WHERE contact_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, contactId);
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error deleting school contact: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Get contact by ID
     */
    public SchoolContact getContactById(int contactId) {
        String sql = "SELECT * FROM school_contacts WHERE contact_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, contactId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return extractContactFromResultSet(rs);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting contact by ID: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    /**
     * Get all contacts by district
     */
    public List<SchoolContact> getContactsByDistrict(String districtName) {
        List<SchoolContact> contacts = new ArrayList<>();
        String sql = "SELECT * FROM school_contacts WHERE district_name = ? ORDER BY udise_no, contact_type";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, districtName);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                contacts.add(extractContactFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting contacts by district: " + e.getMessage());
            e.printStackTrace();
        }
        return contacts;
    }
    
    /**
     * Get all contacts by division
     */
    public List<SchoolContact> getContactsByDivision(String divisionName) {
        List<SchoolContact> contacts = new ArrayList<>();
        String sql = "SELECT * FROM school_contacts WHERE division_name = ? ORDER BY district_name, udise_no, contact_type";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, divisionName);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                contacts.add(extractContactFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting contacts by division: " + e.getMessage());
            e.printStackTrace();
        }
        return contacts;
    }
    
    /**
     * Get contacts by UDISE number
     */
    public List<SchoolContact> getContactsByUdise(String udiseNo) {
        List<SchoolContact> contacts = new ArrayList<>();
        String sql = "SELECT * FROM school_contacts WHERE udise_no = ? ORDER BY contact_type";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                contacts.add(extractContactFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting contacts by UDISE: " + e.getMessage());
            e.printStackTrace();
        }
        return contacts;
    }
    
    /**
     * Extract SchoolContact object from ResultSet
     */
    private SchoolContact extractContactFromResultSet(ResultSet rs) throws SQLException {
        SchoolContact contact = new SchoolContact();
        contact.setContactId(rs.getInt("contact_id"));
        contact.setUdiseNo(rs.getString("udise_no"));
        contact.setSchoolName(rs.getString("school_name"));
        contact.setDistrictName(rs.getString("district_name"));
        contact.setContactType(rs.getString("contact_type"));
        contact.setFullName(rs.getString("full_name"));
        contact.setMobile(rs.getString("mobile"));
        contact.setWhatsappNumber(rs.getString("whatsapp_number"));
        contact.setRemarks(rs.getString("remarks"));
        contact.setCreatedDate(rs.getTimestamp("created_date"));
        contact.setCreatedBy(rs.getString("created_by"));
        contact.setUpdatedDate(rs.getTimestamp("updated_date"));
        contact.setUpdatedBy(rs.getString("updated_by"));
        return contact;
    }
}
