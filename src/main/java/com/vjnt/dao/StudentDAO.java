package com.vjnt.dao;

import com.vjnt.model.Student;
import com.vjnt.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Student Data Access Object
 * Handles all database operations for Student entity
 */
public class StudentDAO {
    
    /**
     * Create a new student
     */
    public boolean createStudent(Student student) {
        String sql = "INSERT INTO students (division, district, udise_no, class, section, " +
                     "class_category, student_name, gender, student_pen, marathi_level, " +
                     "math_level, english_level, created_by) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            pstmt.setString(1, student.getDivision());
            pstmt.setString(2, student.getDistrict());
            pstmt.setString(3, student.getUdiseNo());
            pstmt.setString(4, student.getStudentClass());
            pstmt.setString(5, student.getSection());
            pstmt.setString(6, student.getClassCategory());
            pstmt.setString(7, student.getStudentName());
            pstmt.setString(8, student.getGender());
            pstmt.setString(9, student.getStudentPen());
            pstmt.setString(10, student.getMarathiLevel());
            pstmt.setString(11, student.getMathLevel());
            pstmt.setString(12, student.getEnglishLevel());
            pstmt.setString(13, student.getCreatedBy());
            
            int rowsAffected = pstmt.executeUpdate();
            
            if (rowsAffected > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    student.setStudentId(rs.getInt(1));
                }
                return true;
            }
            return false;
            
        } catch (SQLException e) {
            System.err.println("Error creating student: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * FAST-TRACK: Batch create students (optimized for bulk imports)
     * Process multiple students in a single batch operation for better performance
     */
    public int batchCreateStudents(List<Student> students) {
        if (students == null || students.isEmpty()) {
            return 0;
        }
        
        String sql = "INSERT INTO students (division, district, udise_no, class, section, " +
                     "class_category, student_name, gender, student_pen, marathi_level, " +
                     "math_level, english_level, created_by) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        int totalInserted = 0;
        long startTime = System.currentTimeMillis();
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            // Disable autocommit for batch operation
            conn.setAutoCommit(false);
            
            for (Student student : students) {
                pstmt.setString(1, student.getDivision());
                pstmt.setString(2, student.getDistrict());
                pstmt.setString(3, student.getUdiseNo());
                pstmt.setString(4, student.getStudentClass());
                pstmt.setString(5, student.getSection());
                pstmt.setString(6, student.getClassCategory());
                pstmt.setString(7, student.getStudentName());
                pstmt.setString(8, student.getGender());
                pstmt.setString(9, student.getStudentPen());
                pstmt.setString(10, student.getMarathiLevel());
                pstmt.setString(11, student.getMathLevel());
                pstmt.setString(12, student.getEnglishLevel());
                pstmt.setString(13, student.getCreatedBy());
                
                pstmt.addBatch();
            }
            
            // Execute batch
            int[] results = pstmt.executeBatch();
            conn.commit();
            
            for (int result : results) {
                if (result > 0) {
                    totalInserted++;
                }
            }
            
            long duration = System.currentTimeMillis() - startTime;
            System.out.println("✓ Batch insert completed: " + totalInserted + " students inserted in " + duration + "ms");
            return totalInserted;
            
        } catch (SQLException e) {
            System.err.println("Error in batch create students: " + e.getMessage());
            e.printStackTrace();
            return totalInserted;
        }
    }
    
    /**
     * FAST-TRACK: Check multiple students by PEN in one query
     * More efficient than checking individually - reduces DB queries significantly
     */
    public List<String> getExistingPens(List<String> pens) {
        if (pens == null || pens.isEmpty()) {
            return new ArrayList<>();
        }
        
        List<String> existingPens = new ArrayList<>();
        
        // Process in chunks of 1000 to avoid SQL query size limits
        int chunkSize = 1000;
        for (int i = 0; i < pens.size(); i += chunkSize) {
            int end = Math.min(i + chunkSize, pens.size());
            List<String> chunk = pens.subList(i, end);
            existingPens.addAll(getExistingPensChunk(chunk));
        }
        
        return existingPens;
    }
    
    /**
     * Helper method to check existing PENs in a chunk
     */
    private List<String> getExistingPensChunk(List<String> pens) {
        List<String> existingPens = new ArrayList<>();
        
        StringBuilder placeholders = new StringBuilder();
        for (int i = 0; i < pens.size(); i++) {
            if (i > 0) placeholders.append(",");
            placeholders.append("?");
        }
        
        String sql = "SELECT student_pen FROM students WHERE student_pen IN (" + placeholders + ")";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            for (int i = 0; i < pens.size(); i++) {
                pstmt.setString(i + 1, pens.get(i).trim());
            }
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                existingPens.add(rs.getString("student_pen"));
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking existing PENs: " + e.getMessage());
        }
        
        return existingPens;
    }
    
    /**
     * Check if student exists by PEN
     */
    public boolean studentExists(String studentPen) {
        if (studentPen == null || studentPen.trim().isEmpty()) {
            return false;
        }
        
        String sql = "SELECT COUNT(*) FROM students WHERE student_pen = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, studentPen.trim());
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking student existence: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Get all students
     */
    public List<Student> getAllStudents() {
        List<Student> students = new ArrayList<>();
        String sql = "SELECT * FROM students ORDER BY division, district, udise_no, class, section, student_name";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            while (rs.next()) {
                students.add(extractStudentFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting all students: " + e.getMessage());
            e.printStackTrace();
        }
        return students;
    }
    
    /**
     * Get a single student by ID
     */
    public Student getStudentById(int studentId) {
        String sql = "SELECT * FROM students WHERE student_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, studentId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return extractStudentFromResultSet(rs);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting student by ID: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    /**
     * Get a single student by PEN (Student Personal Educational Number)
     */
    public Student getStudentByPen(String studentPen) {
        if (studentPen == null || studentPen.trim().isEmpty()) {
            return null;
        }
        
        String sql = "SELECT * FROM students WHERE student_pen = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, studentPen.trim());
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return extractStudentFromResultSet(rs);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting student by PEN: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    /**
     * Get students by division
     */
    public List<Student> getStudentsByDivision(String division) {
        List<Student> students = new ArrayList<>();
        String sql = "SELECT * FROM students WHERE division = ? ORDER BY district, udise_no, class, section, student_name";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, division);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                students.add(extractStudentFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting students by division: " + e.getMessage());
        }
        return students;
    }
    
    /**
     * Get students by district
     */
    public List<Student> getStudentsByDistrict(String district) {
        List<Student> students = new ArrayList<>();
        String sql = "SELECT * FROM students WHERE district = ? ORDER BY udise_no, class, section, student_name";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, district);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                students.add(extractStudentFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting students by district: " + e.getMessage());
        }
        return students;
    }
    
    /**
     * Get students by UDISE number
     */
    public List<Student> getStudentsByUdise(String udiseNo) {
        List<Student> students = new ArrayList<>();
        String sql = "SELECT * FROM students WHERE udise_no = ? ORDER BY class, section, student_name";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                students.add(extractStudentFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting students by UDISE: " + e.getMessage());
        }
        return students;
    }
    
    /**
     * Extract student from ResultSet
     */
    /**
     * Helper method to get Integer or null from ResultSet
     */
    private Integer getIntegerOrNull(ResultSet rs, String columnName) throws SQLException {
        int value = rs.getInt(columnName);
        return rs.wasNull() ? null : value;
    }
    
    private Student extractStudentFromResultSet(ResultSet rs) throws SQLException {
        Student student = new Student();
        student.setStudentId(rs.getInt("student_id"));
        student.setDivision(rs.getString("division"));
        student.setDistrict(rs.getString("district"));
        student.setUdiseNo(rs.getString("udise_no"));
        student.setStudentClass(rs.getString("class"));
        student.setSection(rs.getString("section"));
        student.setClassCategory(rs.getString("class_category"));
        student.setStudentName(rs.getString("student_name"));
        student.setGender(rs.getString("gender"));
        student.setStudentPen(rs.getString("student_pen"));
        student.setMarathiLevel(rs.getString("marathi_level"));
        student.setMathLevel(rs.getString("math_level"));
        student.setEnglishLevel(rs.getString("english_level"));
        
        // Detailed language levels
        student.setMarathiAksharaLevel(rs.getInt("marathi_akshara_level"));
        student.setMarathiShabdaLevel(rs.getInt("marathi_shabda_level"));
        student.setMarathiVakyaLevel(rs.getInt("marathi_vakya_level"));
        student.setMarathiSamajpurvakLevel(rs.getInt("marathi_samajpurvak_level"));
        
        student.setMathAksharaLevel(rs.getInt("math_akshara_level"));
        student.setMathShabdaLevel(rs.getInt("math_shabda_level"));
        student.setMathVakyaLevel(rs.getInt("math_vakya_level"));
        student.setMathSamajpurvakLevel(rs.getInt("math_samajpurvak_level"));
        
        student.setEnglishAksharaLevel(rs.getInt("english_akshara_level"));
        student.setEnglishShabdaLevel(rs.getInt("english_shabda_level"));
        student.setEnglishVakyaLevel(rs.getInt("english_vakya_level"));
        student.setEnglishSamajpurvakLevel(rs.getInt("english_samajpurvak_level"));
        
        // Load phase-specific data
        student.setPhase1Marathi(getIntegerOrNull(rs, "phase1_marathi"));
        student.setPhase1Math(getIntegerOrNull(rs, "phase1_math"));
        student.setPhase1English(getIntegerOrNull(rs, "phase1_english"));
        student.setPhase2Marathi(getIntegerOrNull(rs, "phase2_marathi"));
        student.setPhase2Math(getIntegerOrNull(rs, "phase2_math"));
        student.setPhase2English(getIntegerOrNull(rs, "phase2_english"));
        student.setPhase3Marathi(getIntegerOrNull(rs, "phase3_marathi"));
        student.setPhase3Math(getIntegerOrNull(rs, "phase3_math"));
        student.setPhase3English(getIntegerOrNull(rs, "phase3_english"));
        student.setPhase4Marathi(getIntegerOrNull(rs, "phase4_marathi"));
        student.setPhase4Math(getIntegerOrNull(rs, "phase4_math"));
        student.setPhase4English(getIntegerOrNull(rs, "phase4_english"));
        
        // Load phase dates to track save button clicks
        student.setPhase1Date(rs.getTimestamp("phase1_date"));
        student.setPhase2Date(rs.getTimestamp("phase2_date"));
        student.setPhase3Date(rs.getTimestamp("phase3_date"));
        student.setPhase4Date(rs.getTimestamp("phase4_date"));
        
        student.setCreatedDate(rs.getTimestamp("created_date"));
        student.setCreatedBy(rs.getString("created_by"));
        student.setUpdatedDate(rs.getTimestamp("updated_date"));
        student.setUpdatedBy(rs.getString("updated_by"));
        return student;
    }
    
    /**
     * Get students by UDISE with pagination
     */
    public List<Student> getStudentsByUdiseWithPagination(String udiseNo, int page, int pageSize) {
        List<Student> students = new ArrayList<>();
        int offset = (page - 1) * pageSize;
        String sql = "SELECT * FROM students WHERE udise_no = ? ORDER BY class, section, student_name LIMIT ? OFFSET ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            pstmt.setInt(2, pageSize);
            pstmt.setInt(3, offset);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                students.add(extractStudentFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting students by UDISE with pagination: " + e.getMessage());
        }
        return students;
    }
    
    /**
     * Get total count of students by UDISE
     */
    public int getStudentCountByUdise(String udiseNo) {
        String sql = "SELECT COUNT(*) FROM students WHERE udise_no = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting student count by UDISE: " + e.getMessage());
        }
        return 0;
    }
    
    /**
     * Update student language levels
     */
    public boolean updateLanguageLevels(int studentId, 
                                       int marathiAkshara, int marathiShabda, int marathiVakya, int marathiSamajpurvak,
                                       int mathAkshara, int mathShabda, int mathVakya, int mathSamajpurvak,
                                       int englishAkshara, int englishShabda, int englishVakya, int englishSamajpurvak) {
        String sql = "UPDATE students SET " +
                     "marathi_akshara_level = ?, marathi_shabda_level = ?, marathi_vakya_level = ?, marathi_samajpurvak_level = ?, " +
                     "math_akshara_level = ?, math_shabda_level = ?, math_vakya_level = ?, math_samajpurvak_level = ?, " +
                     "english_akshara_level = ?, english_shabda_level = ?, english_vakya_level = ?, english_samajpurvak_level = ? " +
                     "WHERE student_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, marathiAkshara);
            pstmt.setInt(2, marathiShabda);
            pstmt.setInt(3, marathiVakya);
            pstmt.setInt(4, marathiSamajpurvak);
            pstmt.setInt(5, mathAkshara);
            pstmt.setInt(6, mathShabda);
            pstmt.setInt(7, mathVakya);
            pstmt.setInt(8, mathSamajpurvak);
            pstmt.setInt(9, englishAkshara);
            pstmt.setInt(10, englishShabda);
            pstmt.setInt(11, englishVakya);
            pstmt.setInt(12, englishSamajpurvak);
            pstmt.setInt(13, studentId);
            
            return pstmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating language levels: " + e.getMessage());
            return false;
        }
    }
    
    /**
     * Delete all students (for testing)
     */
    public boolean deleteAllStudents() {
        String sql = "DELETE FROM students";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.executeUpdate();
            return true;

        } catch (SQLException e) {
            System.err.println("Error deleting all students: " + e.getMessage());
            return false;
        }
    }
    
    /**
     * Check if a phase is complete for a school (all students have data for that phase)
     * Only counts students where save button was clicked (phase_date is NOT NULL)
     * Students with all three values as 0 (default) are counted if save was clicked
     */
    public boolean isPhaseComplete(String udiseNo, int phase) {
        String columnPrefix = "phase" + phase + "_";
        String sql = "SELECT COUNT(*) as total, " +
                     "SUM(CASE WHEN " + columnPrefix + "date IS NOT NULL " +
                     "THEN 1 ELSE 0 END) as completed " +
                     "FROM students WHERE udise_no = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int total = rs.getInt("total");
                int completed = rs.getInt("completed");
                System.out.println("Phase " + phase + " check - Total: " + total + ", Completed: " + completed + " (based on save button action - phase_date)");
                return total > 0 && total == completed;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking phase completion: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Update language levels for a specific phase
     */
    public boolean updatePhaseLanguageLevels(int studentId, int phase, 
                                            int marathiLevel, int mathLevel, int englishLevel,
                                            String updatedBy) {
        // Update both phase-specific columns AND the main akshara_level columns
        String columnPrefix = "phase" + phase + "_";
        String sql = "UPDATE students SET " +
                     columnPrefix + "marathi = ?, " +
                     columnPrefix + "math = ?, " +
                     columnPrefix + "english = ?, " +
                     columnPrefix + "date = NOW(), " +
                     "marathi_akshara_level = ?, " +
                     "math_akshara_level = ?, " +
                     "english_akshara_level = ?, " +
                     "updated_date = NOW(), " +
                     "updated_by = ? " +
                     "WHERE student_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, marathiLevel);
            pstmt.setInt(2, mathLevel);
            pstmt.setInt(3, englishLevel);
            pstmt.setInt(4, marathiLevel);  // Also update main columns
            pstmt.setInt(5, mathLevel);
            pstmt.setInt(6, englishLevel);
            pstmt.setString(7, updatedBy);
            pstmt.setInt(8, studentId);
            
            int rows = pstmt.executeUpdate();
            
            // Create audit entry
            if (rows > 0) {
                auditPhaseChange(studentId, phase, marathiLevel, mathLevel, englishLevel, updatedBy);
            }
            
            return rows > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating phase language levels: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Create audit entry for phase changes
     */
    private void auditPhaseChange(int studentId, int phase, int marathiLevel, 
                                 int mathLevel, int englishLevel, String changedBy) {
        String sql = "INSERT INTO student_phase_audit (student_id, phase, marathi_level, " +
                     "math_level, english_level, changed_by, action_type) " +
                     "VALUES (?, ?, ?, ?, ?, ?, 'UPDATE')";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, studentId);
            pstmt.setInt(2, phase);
            pstmt.setInt(3, marathiLevel);
            pstmt.setInt(4, mathLevel);
            pstmt.setInt(5, englishLevel);
            pstmt.setString(6, changedBy);
            pstmt.executeUpdate();
            
        } catch (SQLException e) {
            System.err.println("Error creating audit entry: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Update student basic information
     */
    public boolean updateStudent(Student student) {
        String sql = "UPDATE students SET " +
                     "division = ?, district = ?, udise_no = ?, class = ?, section = ?, " +
                     "class_category = ?, student_name = ?, gender = ?, student_pen = ?, " +
                     "marathi_level = ?, math_level = ?, english_level = ?, " +
                     "updated_date = NOW(), updated_by = ? " +
                     "WHERE student_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, student.getDivision());
            pstmt.setString(2, student.getDistrict());
            pstmt.setString(3, student.getUdiseNo());
            pstmt.setString(4, student.getStudentClass());
            pstmt.setString(5, student.getSection());
            pstmt.setString(6, student.getClassCategory());
            pstmt.setString(7, student.getStudentName());
            pstmt.setString(8, student.getGender());
            pstmt.setString(9, student.getStudentPen());
            pstmt.setString(10, student.getMarathiLevel());
            pstmt.setString(11, student.getMathLevel());
            pstmt.setString(12, student.getEnglishLevel());
            pstmt.setString(13, student.getUpdatedBy());
            pstmt.setInt(14, student.getStudentId());
            
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating student: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Get phase completion percentage for a school
     * Only counts students where save button was clicked (phase_date is NOT NULL)
     * Students with all three values as 0 (default) are counted if save was clicked
     */
    public int getPhaseCompletionPercentage(String udiseNo, int phase) {
        String columnPrefix = "phase" + phase + "_";
        String sql = "SELECT COUNT(*) as total, " +
                     "SUM(CASE WHEN " + columnPrefix + "date IS NOT NULL " +
                     "THEN 1 ELSE 0 END) as completed " +
                     "FROM students WHERE udise_no = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int total = rs.getInt("total");
                int completed = rs.getInt("completed");
                if (total > 0) {
                    return (completed * 100) / total;
                }
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting phase completion percentage: " + e.getMessage());
        }
        return 0;
    }
}
