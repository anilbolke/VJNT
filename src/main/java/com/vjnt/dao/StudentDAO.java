package com.vjnt.dao;

import com.vjnt.model.Student;
import com.vjnt.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Student Data Access Object
 * Handles all database operations for Student entity
 */
public class StudentDAO {

    /** Marathi level that counts as 100% FLN. */
    public static final int FLN_MARATHI_LEVEL = 6;
    /** Math level that counts as 100% FLN. */
    public static final int FLN_MATH_LEVEL    = 8;
    /** English level that counts as 100% FLN. */
    public static final int FLN_ENGLISH_LEVEL = 6;

    /**
     * SQL predicate for "this student's levels actually meet 100% FLN".
     *
     * Kept in one place so the FLN-completed list and the fln_completed flag cannot drift apart.
     * COALESCE is deliberate: a NULL level must read as "not met", and a bare
     * {@code NOT (a=6 AND ...)} would evaluate to NULL and silently pass such rows through.
     */
    public static final String FLN_LEVELS_MET =
        "(COALESCE(marathi_akshara_level,-1) = " + FLN_MARATHI_LEVEL +
        " AND COALESCE(math_akshara_level,-1) = " + FLN_MATH_LEVEL +
        " AND COALESCE(english_akshara_level,-1) = " + FLN_ENGLISH_LEVEL + ")";

    /**
     * Create a new student
     */
    public boolean createStudent(Student student) {
        // Check for duplicate PEN before insertion
        if (student.getStudentPen() != null && !student.getStudentPen().isEmpty()) {
            if (isPenNumberExists(student.getStudentPen())) {
                System.err.println("✗ Cannot create student: PEN number " + student.getStudentPen() + " already exists!");
                return false;
            }
        }
        
        String sql = "INSERT INTO students (division, district, udise_no, class, section, " +
                     "class_category, student_name, gender, student_pen, marathi_level, " +
                     "math_level, english_level, is_active, created_by) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
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
            pstmt.setBoolean(13, student.isActive());
            pstmt.setString(14, student.getCreatedBy());
            
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
            // Check if error is due to duplicate key
            if (e.getMessage().contains("Duplicate entry") && e.getMessage().contains("student_pen")) {
                System.err.println("✗ Duplicate PEN number detected: " + student.getStudentPen());
            } else {
                System.err.println("Error creating student: " + e.getMessage());
                e.printStackTrace();
            }
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
        
        String sql = "SELECT student_pen FROM students WHERE student_pen IN (" + placeholders + ") AND is_active = 1";
        
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
        
        String sql = "SELECT COUNT(*) FROM students WHERE student_pen = ? AND is_active = 1";
        
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
        String sql = "SELECT * FROM students WHERE is_active = 1 ORDER BY division, district, udise_no, class, section, student_name";
        
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
        String sql = "SELECT * FROM students WHERE division = ? AND is_active = 1 ORDER BY district, udise_no, class, section, student_name";
        
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
     * Get the distinct, non-empty division names present in the students table.
     * Used to populate the "All Divisions" dropdown on Super Division Officer pages.
     */
    public List<String> getDistinctDivisions() {
        List<String> divisions = new ArrayList<>();
        String sql = "SELECT DISTINCT division FROM students " +
                     "WHERE division IS NOT NULL AND TRIM(division) <> '' AND is_active = 1 " +
                     "ORDER BY division";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            while (rs.next()) {
                String division = rs.getString("division");
                if (division != null && !division.trim().isEmpty()) {
                    divisions.add(division.trim());
                }
            }

        } catch (SQLException e) {
            System.err.println("Error getting distinct divisions: " + e.getMessage());
        }
        return divisions;
    }

    /**
     * Get students by district
     */
    public List<Student> getStudentsByDistrict(String district) {
        List<Student> students = new ArrayList<>();
        String sql = "SELECT * FROM students WHERE district = ? AND is_active = 1 ORDER BY udise_no, class, section, student_name";
        
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
     * Get students by UDISE number (includes all students)
     */
    public List<Student> getStudentsByUdise(String udiseNo) {
        List<Student> students = new ArrayList<>();
        String sql = "SELECT * FROM students WHERE udise_no = ? AND is_active = 1 ORDER BY class, section, student_name";
        
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
    
    public List<Student> getStudentsByUdiseALL(String udiseNo) {
        List<Student> students = new ArrayList<>();
        String sql = "SELECT * FROM students WHERE udise_no = ?  ORDER BY class, section, student_name";
        
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
     * Get ALL students by UDISE for viewing (includes all students regardless of FLN status)
     */
    public List<Student> getStudentsByUdiseFOrView(String udiseNo) {
        List<Student> students = new ArrayList<>();
        String sql = "SELECT * FROM students WHERE udise_no = ? AND is_active = 1 ORDER BY class, section, student_name";
        
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
     * Get only FLN completed students by UDISE
     */
    public List<Student> getFlnCompletedStudentsByUdise(String udiseNo) {
        List<Student> students = new ArrayList<>();
        // The stored flag alone is not trusted here: historic rows were flagged by the old
        // write-once code path and can no longer be cleared by re-assessment. Requiring the
        // levels as well means a stale flag cannot show up as an achievement.
        String sql = "SELECT * FROM students WHERE udise_no = ? AND fln_completed = 1 " +
                     "AND is_active = 1 AND " + FLN_LEVELS_MET +
                     " ORDER BY class, section, student_name";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                students.add(extractStudentFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting FLN completed students: " + e.getMessage());
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
        
        // Load active status (default to true if column doesn't exist for backward compatibility)
        try {
            student.setActive(rs.getBoolean("is_active"));
        } catch (SQLException e) {
            student.setActive(true); // Default to active if column not found
        }
        
        // Load FLN completion status
        try {
            student.setFlnCompleted(rs.getBoolean("fln_completed"));
        } catch (SQLException e) {
            student.setFlnCompleted(false); // Default to false if column not found
        }
        
        return student;
    }
    
    /**
     * Get students by UDISE with pagination
     */
    public List<Student> getStudentsByUdiseWithPagination(String udiseNo, int page, int pageSize) {
        List<Student> students = new ArrayList<>();
        int offset = (page - 1) * pageSize;
        String sql = "SELECT * FROM students WHERE udise_no = ? AND is_active = 1 AND (fln_completed IS NULL OR fln_completed = FALSE)  ORDER BY class, section, student_name LIMIT ? OFFSET ?";
        
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
        String sql = "SELECT COUNT(*) FROM students WHERE udise_no = ? AND is_active = 1 AND (fln_completed IS NULL OR fln_completed = FALSE)";
        
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
    
    public int getStudentCountByUdiseFORDASHBOARD(String udiseNo) {
        String sql = "SELECT COUNT(*) FROM students WHERE udise_no = ? AND is_active = 1 ";
        
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
     * Check if a phase is complete for a school
     * Phase is complete when ALL ACTIVE students have their assessments saved (phase_date is set)
     * Note: Only counts students where is_active = 1
     */
    public boolean isPhaseComplete(String udiseNo, int phase) {
        // Phase is complete only when EVERY active (non-FLN) student in the school
        // has the phase{N}_date set, AND (for phases 1-3) all three subject levels.
        // The subject-level + date filter belongs INSIDE the CASE so the denominator
        // (total_students) counts the full school roster, not just the saved rows.
        String phaseColumn = "phase" + phase + "_date";
        String marathiCol = "phase" + phase + "_marathi";
        String mathCol = "phase" + phase + "_math";
        String englishCol = "phase" + phase + "_english";

        String completedCondition = phaseColumn + " IS NOT NULL";
        if (phase >= 1 && phase <= 3) {
            completedCondition += " AND " + marathiCol + " IS NOT NULL" +
                                  " AND " + mathCol + " IS NOT NULL" +
                                  " AND " + englishCol + " IS NOT NULL";
        }

        String sql = "SELECT " +
                     "COUNT(*) as total_students, " +
                     "SUM(CASE WHEN " + completedCondition + " THEN 1 ELSE 0 END) as completed_students " +
                     "FROM students " +
                     "WHERE udise_no COLLATE utf8mb4_unicode_ci = ? " +
                     "AND is_active = 1 " +
                     "AND (fln_completed IS NULL OR fln_completed = FALSE)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int totalStudents = rs.getInt("total_students");
                int completedStudents = rs.getInt("completed_students");
                
                // Phase is complete if there are students and all have completed
                boolean isComplete = totalStudents > 0 && totalStudents == completedStudents;
                
             
                
                return isComplete;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking phase completion: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Check if a phase is approved by Head Master
     */
    public boolean isPhaseApproved(String udiseNo, int phase) {
        String sql = "SELECT approval_status FROM phase_approvals " +
                     "WHERE udise_no COLLATE utf8mb4_unicode_ci = ? AND phase_number = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            pstmt.setInt(2, phase);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                String status = rs.getString("approval_status");
                return "APPROVED".equals(status);
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking phase approval: " + e.getMessage());
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
                
                // Check FLN completion after ANY phase (1, 2, 3, or 4)
                // If student achieves Marathi=6, Math=8, English=6 in ANY phase, mark as FLN completed
                boolean flnComplete = checkFlnCompletion(studentId);

                // Write the flag BOTH ways. This used to be "if (flnComplete) set true" with no
                // else, which made fln_completed a write-once latch: a teacher who picked 6/8/6 by
                // mistake could never undo it, and because the manage-students queries exclude
                // fln_completed=1 the student then vanished from the list and became uneditable.
                // Passing the boolean means lowering a level clears the flag and the student
                // reappears for correction.
                updateFlnCompletionStatus(studentId, flnComplete);
                // NOTE: Removed automatic phase restart on save
                // Phase restart should only happen after admin approval, not on every save!
                // The restart logic causes Phase 4 data to be cleared prematurely.
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
        // Get original student data to check if standard changed
        Student originalStudent = getStudentById(student.getStudentId());
        boolean standardChanged = originalStudent != null && 
                                  !originalStudent.getStudentClass().equals(student.getStudentClass());
        
        String sql = "UPDATE students SET " +
                     "division = ?, district = ?, udise_no = ?, class = ?, section = ?, " +
                     "class_category = ?, student_name = ?, gender = ?, student_pen = ?, " +
                     "marathi_level = ?, math_level = ?, english_level = ?, is_active = ?, " +
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
            pstmt.setBoolean(13, student.isActive());
            pstmt.setString(14, student.getUpdatedBy());
            pstmt.setInt(15, student.getStudentId());
            
            int rowsAffected = pstmt.executeUpdate();
            
            // If standard changed, check FLN completion and handle phase restart
            if (rowsAffected > 0 && standardChanged) {
                handleStandardUpdate(student.getStudentId());
            }
            
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating student: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Get phase completion percentage for a school
     * Phase is complete ONLY if approved by Head Master
     */
    public int getPhaseCompletionPercentage(String udiseNo, int phase) {
        // Percentage is over the full active (non-FLN) roster. The subject-level +
        // date filter belongs INSIDE the CASE so the denominator counts the whole
        // school, not just rows already saved for this phase.
        String phaseColumn = "phase" + phase + "_date";
        String marathiCol = "phase" + phase + "_marathi";
        String mathCol = "phase" + phase + "_math";
        String englishCol = "phase" + phase + "_english";

        String completedCondition = phaseColumn + " IS NOT NULL";
        if (phase >= 1 && phase <= 3) {
            completedCondition += " AND " + marathiCol + " IS NOT NULL" +
                                  " AND " + mathCol + " IS NOT NULL" +
                                  " AND " + englishCol + " IS NOT NULL";
        }

        String sql = "SELECT " +
                     "COUNT(*) as total_students, " +
                     "SUM(CASE WHEN " + completedCondition + " THEN 1 ELSE 0 END) as completed_students " +
                     "FROM students " +
                     "WHERE udise_no COLLATE utf8mb4_unicode_ci = ? " +
                     "AND is_active = 1 " +
                     "AND (fln_completed IS NULL OR fln_completed = FALSE)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int totalStudents = rs.getInt("total_students");
                int completedStudents = rs.getInt("completed_students");
                
                if (totalStudents == 0) {
                    return 0;
                }
                
                // Calculate percentage
                int percentage = (int) Math.round((completedStudents * 100.0) / totalStudents);
                
                
                return percentage;
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting phase completion percentage: " + e.getMessage());
        }
        return 0;
    }
    
    /**
     * Get phase-wise subject statistics for all students by UDISE
     * Returns detailed counts of dropdown values for each phase and subject
     */
    public List<java.util.Map<String, Object>> getPhaseWiseSubjectStatistics(String udiseNo) {
        List<java.util.Map<String, Object>> statistics = new ArrayList<>();
        
        String sql = "SELECT " +
                     "student_id, student_name, student_pen, class, section, " +
                     "phase1_marathi, phase1_math, phase1_english, phase1_date, " +
                     "phase2_marathi, phase2_math, phase2_english, phase2_date, " +
                     "phase3_marathi, phase3_math, phase3_english, phase3_date, " +
                     "phase4_marathi, phase4_math, phase4_english, phase4_date " +
                     "FROM students " +
                     "WHERE udise_no = ? AND is_active = 1 " +
                     "ORDER BY class, section, student_name";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                java.util.Map<String, Object> studentData = new java.util.HashMap<>();
                
                studentData.put("studentId", rs.getInt("student_id"));
                studentData.put("studentName", rs.getString("student_name"));
                studentData.put("studentPen", rs.getString("student_pen"));
                studentData.put("studentClass", rs.getString("class"));
                studentData.put("section", rs.getString("section"));
                
                // Phase 1 data
                studentData.put("phase1Marathi", rs.getObject("phase1_marathi"));
                studentData.put("phase1Math", rs.getObject("phase1_math"));
                studentData.put("phase1English", rs.getObject("phase1_english"));
                studentData.put("phase1Date", rs.getTimestamp("phase1_date"));
                
                // Phase 2 data
                studentData.put("phase2Marathi", rs.getObject("phase2_marathi"));
                studentData.put("phase2Math", rs.getObject("phase2_math"));
                studentData.put("phase2English", rs.getObject("phase2_english"));
                studentData.put("phase2Date", rs.getTimestamp("phase2_date"));
                
                // Phase 3 data
                studentData.put("phase3Marathi", rs.getObject("phase3_marathi"));
                studentData.put("phase3Math", rs.getObject("phase3_math"));
                studentData.put("phase3English", rs.getObject("phase3_english"));
                studentData.put("phase3Date", rs.getTimestamp("phase3_date"));
                
                // Phase 4 data
                studentData.put("phase4Marathi", rs.getObject("phase4_marathi"));
                studentData.put("phase4Math", rs.getObject("phase4_math"));
                studentData.put("phase4English", rs.getObject("phase4_english"));
                studentData.put("phase4Date", rs.getTimestamp("phase4_date"));
                
                statistics.add(studentData);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting phase-wise subject statistics: " + e.getMessage());
            e.printStackTrace();
        }
        
        return statistics;
    }
    
    /**
     * Get aggregate phase-wise subject counts by UDISE
     * Returns summary of how many students have each dropdown value for each phase/subject
     */
    public java.util.Map<String, Object> getPhaseWiseSubjectCounts(String udiseNo) {
        return getPhaseWiseSubjectCounts(udiseNo, null);
    }
    
    /**
     * Get aggregate phase-wise subject counts by UDISE with class filter
     * Returns summary of how many students have each dropdown value for each phase/subject
     * @param udiseNo School UDISE number
     * @param studentClass Optional class filter (e.g., "1", "2", "3", etc.)
     */
    public java.util.Map<String, Object> getPhaseWiseSubjectCounts(String udiseNo, String studentClass) {
        java.util.Map<String, Object> counts = new java.util.HashMap<>();
        

        String sql = "SELECT " +
                     // Phase 1 counts - Marathi (0-6)
                     "SUM(CASE WHEN phase1_marathi = 0 THEN 1 ELSE 0 END) as p1_marathi_0, " +
                     "SUM(CASE WHEN phase1_marathi = 1 THEN 1 ELSE 0 END) as p1_marathi_1, " +
                     "SUM(CASE WHEN phase1_marathi = 2 THEN 1 ELSE 0 END) as p1_marathi_2, " +
                     "SUM(CASE WHEN phase1_marathi = 3 THEN 1 ELSE 0 END) as p1_marathi_3, " +
                     "SUM(CASE WHEN phase1_marathi = 4 THEN 1 ELSE 0 END) as p1_marathi_4, " +
                     "SUM(CASE WHEN phase1_marathi = 5 THEN 1 ELSE 0 END) as p1_marathi_5, " +
                     "SUM(CASE WHEN phase1_marathi = 6 THEN 1 ELSE 0 END) as p1_marathi_6, " +
                     // Phase 1 counts - Math (0-8)
                     "SUM(CASE WHEN phase1_math = 0 THEN 1 ELSE 0 END) as p1_math_0, " +
                     "SUM(CASE WHEN phase1_math = 1 THEN 1 ELSE 0 END) as p1_math_1, " +
                     "SUM(CASE WHEN phase1_math = 2 THEN 1 ELSE 0 END) as p1_math_2, " +
                     "SUM(CASE WHEN phase1_math = 3 THEN 1 ELSE 0 END) as p1_math_3, " +
                     "SUM(CASE WHEN phase1_math = 4 THEN 1 ELSE 0 END) as p1_math_4, " +
                     "SUM(CASE WHEN phase1_math = 5 THEN 1 ELSE 0 END) as p1_math_5, " +
                     "SUM(CASE WHEN phase1_math = 6 THEN 1 ELSE 0 END) as p1_math_6, " +
                     "SUM(CASE WHEN phase1_math = 7 THEN 1 ELSE 0 END) as p1_math_7, " +
                     "SUM(CASE WHEN phase1_math = 8 THEN 1 ELSE 0 END) as p1_math_8, " +
                     // Phase 1 counts - English (0-6)
                     "SUM(CASE WHEN phase1_english = 0 THEN 1 ELSE 0 END) as p1_english_0, " +
                     "SUM(CASE WHEN phase1_english = 1 THEN 1 ELSE 0 END) as p1_english_1, " +
                     "SUM(CASE WHEN phase1_english = 2 THEN 1 ELSE 0 END) as p1_english_2, " +
                     "SUM(CASE WHEN phase1_english = 3 THEN 1 ELSE 0 END) as p1_english_3, " +
                     "SUM(CASE WHEN phase1_english = 4 THEN 1 ELSE 0 END) as p1_english_4, " +
                     "SUM(CASE WHEN phase1_english = 5 THEN 1 ELSE 0 END) as p1_english_5, " +
                     "SUM(CASE WHEN phase1_english = 6 THEN 1 ELSE 0 END) as p1_english_6, " +
                     // Phase 2 counts - Marathi (0-6)
                     "SUM(CASE WHEN phase2_marathi = 0 THEN 1 ELSE 0 END) as p2_marathi_0, " +
                     "SUM(CASE WHEN phase2_marathi = 1 THEN 1 ELSE 0 END) as p2_marathi_1, " +
                     "SUM(CASE WHEN phase2_marathi = 2 THEN 1 ELSE 0 END) as p2_marathi_2, " +
                     "SUM(CASE WHEN phase2_marathi = 3 THEN 1 ELSE 0 END) as p2_marathi_3, " +
                     "SUM(CASE WHEN phase2_marathi = 4 THEN 1 ELSE 0 END) as p2_marathi_4, " +
                     "SUM(CASE WHEN phase2_marathi = 5 THEN 1 ELSE 0 END) as p2_marathi_5, " +
                     "SUM(CASE WHEN phase2_marathi = 6 THEN 1 ELSE 0 END) as p2_marathi_6, " +
                     // Phase 2 counts - Math (0-8)
                     "SUM(CASE WHEN phase2_math = 0 THEN 1 ELSE 0 END) as p2_math_0, " +
                     "SUM(CASE WHEN phase2_math = 1 THEN 1 ELSE 0 END) as p2_math_1, " +
                     "SUM(CASE WHEN phase2_math = 2 THEN 1 ELSE 0 END) as p2_math_2, " +
                     "SUM(CASE WHEN phase2_math = 3 THEN 1 ELSE 0 END) as p2_math_3, " +
                     "SUM(CASE WHEN phase2_math = 4 THEN 1 ELSE 0 END) as p2_math_4, " +
                     "SUM(CASE WHEN phase2_math = 5 THEN 1 ELSE 0 END) as p2_math_5, " +
                     "SUM(CASE WHEN phase2_math = 6 THEN 1 ELSE 0 END) as p2_math_6, " +
                     "SUM(CASE WHEN phase2_math = 7 THEN 1 ELSE 0 END) as p2_math_7, " +
                     "SUM(CASE WHEN phase2_math = 8 THEN 1 ELSE 0 END) as p2_math_8, " +
                     // Phase 2 counts - English (0-6)
                     "SUM(CASE WHEN phase2_english = 0 THEN 1 ELSE 0 END) as p2_english_0, " +
                     "SUM(CASE WHEN phase2_english = 1 THEN 1 ELSE 0 END) as p2_english_1, " +
                     "SUM(CASE WHEN phase2_english = 2 THEN 1 ELSE 0 END) as p2_english_2, " +
                     "SUM(CASE WHEN phase2_english = 3 THEN 1 ELSE 0 END) as p2_english_3, " +
                     "SUM(CASE WHEN phase2_english = 4 THEN 1 ELSE 0 END) as p2_english_4, " +
                     "SUM(CASE WHEN phase2_english = 5 THEN 1 ELSE 0 END) as p2_english_5, " +
                     "SUM(CASE WHEN phase2_english = 6 THEN 1 ELSE 0 END) as p2_english_6, " +
                     // Phase 3 counts - Marathi (0-6)
                     "SUM(CASE WHEN phase3_marathi = 0 THEN 1 ELSE 0 END) as p3_marathi_0, " +
                     "SUM(CASE WHEN phase3_marathi = 1 THEN 1 ELSE 0 END) as p3_marathi_1, " +
                     "SUM(CASE WHEN phase3_marathi = 2 THEN 1 ELSE 0 END) as p3_marathi_2, " +
                     "SUM(CASE WHEN phase3_marathi = 3 THEN 1 ELSE 0 END) as p3_marathi_3, " +
                     "SUM(CASE WHEN phase3_marathi = 4 THEN 1 ELSE 0 END) as p3_marathi_4, " +
                     "SUM(CASE WHEN phase3_marathi = 5 THEN 1 ELSE 0 END) as p3_marathi_5, " +
                     "SUM(CASE WHEN phase3_marathi = 6 THEN 1 ELSE 0 END) as p3_marathi_6, " +
                     // Phase 3 counts - Math (0-8)
                     "SUM(CASE WHEN phase3_math = 0 THEN 1 ELSE 0 END) as p3_math_0, " +
                     "SUM(CASE WHEN phase3_math = 1 THEN 1 ELSE 0 END) as p3_math_1, " +
                     "SUM(CASE WHEN phase3_math = 2 THEN 1 ELSE 0 END) as p3_math_2, " +
                     "SUM(CASE WHEN phase3_math = 3 THEN 1 ELSE 0 END) as p3_math_3, " +
                     "SUM(CASE WHEN phase3_math = 4 THEN 1 ELSE 0 END) as p3_math_4, " +
                     "SUM(CASE WHEN phase3_math = 5 THEN 1 ELSE 0 END) as p3_math_5, " +
                     "SUM(CASE WHEN phase3_math = 6 THEN 1 ELSE 0 END) as p3_math_6, " +
                     "SUM(CASE WHEN phase3_math = 7 THEN 1 ELSE 0 END) as p3_math_7, " +
                     "SUM(CASE WHEN phase3_math = 8 THEN 1 ELSE 0 END) as p3_math_8, " +
                     // Phase 3 counts - English (0-6)
                     "SUM(CASE WHEN phase3_english = 0 THEN 1 ELSE 0 END) as p3_english_0, " +
                     "SUM(CASE WHEN phase3_english = 1 THEN 1 ELSE 0 END) as p3_english_1, " +
                     "SUM(CASE WHEN phase3_english = 2 THEN 1 ELSE 0 END) as p3_english_2, " +
                     "SUM(CASE WHEN phase3_english = 3 THEN 1 ELSE 0 END) as p3_english_3, " +
                     "SUM(CASE WHEN phase3_english = 4 THEN 1 ELSE 0 END) as p3_english_4, " +
                     "SUM(CASE WHEN phase3_english = 5 THEN 1 ELSE 0 END) as p3_english_5, " +
                     "SUM(CASE WHEN phase3_english = 6 THEN 1 ELSE 0 END) as p3_english_6, " +
                     // Phase 4 counts - Marathi (0-6)
                     "SUM(CASE WHEN phase4_marathi = 0 THEN 1 ELSE 0 END) as p4_marathi_0, " +
                     "SUM(CASE WHEN phase4_marathi = 1 THEN 1 ELSE 0 END) as p4_marathi_1, " +
                     "SUM(CASE WHEN phase4_marathi = 2 THEN 1 ELSE 0 END) as p4_marathi_2, " +
                     "SUM(CASE WHEN phase4_marathi = 3 THEN 1 ELSE 0 END) as p4_marathi_3, " +
                     "SUM(CASE WHEN phase4_marathi = 4 THEN 1 ELSE 0 END) as p4_marathi_4, " +
                     "SUM(CASE WHEN phase4_marathi = 5 THEN 1 ELSE 0 END) as p4_marathi_5, " +
                     "SUM(CASE WHEN phase4_marathi = 6 THEN 1 ELSE 0 END) as p4_marathi_6, " +
                     // Phase 4 counts - Math (0-8)
                     "SUM(CASE WHEN phase4_math = 0 THEN 1 ELSE 0 END) as p4_math_0, " +
                     "SUM(CASE WHEN phase4_math = 1 THEN 1 ELSE 0 END) as p4_math_1, " +
                     "SUM(CASE WHEN phase4_math = 2 THEN 1 ELSE 0 END) as p4_math_2, " +
                     "SUM(CASE WHEN phase4_math = 3 THEN 1 ELSE 0 END) as p4_math_3, " +
                     "SUM(CASE WHEN phase4_math = 4 THEN 1 ELSE 0 END) as p4_math_4, " +
                     "SUM(CASE WHEN phase4_math = 5 THEN 1 ELSE 0 END) as p4_math_5, " +
                     "SUM(CASE WHEN phase4_math = 6 THEN 1 ELSE 0 END) as p4_math_6, " +
                     "SUM(CASE WHEN phase4_math = 7 THEN 1 ELSE 0 END) as p4_math_7, " +
                     "SUM(CASE WHEN phase4_math = 8 THEN 1 ELSE 0 END) as p4_math_8, " +
                     // Phase 4 counts - English (0-6)
                     "SUM(CASE WHEN phase4_english = 0 THEN 1 ELSE 0 END) as p4_english_0, " +
                     "SUM(CASE WHEN phase4_english = 1 THEN 1 ELSE 0 END) as p4_english_1, " +
                     "SUM(CASE WHEN phase4_english = 2 THEN 1 ELSE 0 END) as p4_english_2, " +
                     "SUM(CASE WHEN phase4_english = 3 THEN 1 ELSE 0 END) as p4_english_3, " +
                     "SUM(CASE WHEN phase4_english = 4 THEN 1 ELSE 0 END) as p4_english_4, " +
                     "SUM(CASE WHEN phase4_english = 5 THEN 1 ELSE 0 END) as p4_english_5, " +
                     "SUM(CASE WHEN phase4_english = 6 THEN 1 ELSE 0 END) as p4_english_6, " +
                     "COUNT(*) as total_students " +
                     "FROM students " +
                     "WHERE udise_no = ? AND is_active = 1" +
                     (studentClass != null && !studentClass.isEmpty() ? " AND class = ?" : "");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, udiseNo);
            if (studentClass != null && !studentClass.isEmpty()) {
                pstmt.setString(2, studentClass);
            }
            
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int totalStudents = rs.getInt("total_students");
                
                // Store all counts in the map
                for (int phase = 1; phase <= 4; phase++) {
                    // Marathi counts (0-6)
                    java.util.Map<String, Integer> marathiCounts = new java.util.HashMap<>();
                    for (int level = 0; level <= 6; level++) {
                        String columnName = "p" + phase + "_marathi_" + level;
                        int count = rs.getInt(columnName);
                        marathiCounts.put(String.valueOf(level), count);
                    }
                    counts.put("phase" + phase + "_marathi", marathiCounts);
                    
                    // Math counts (0-8)
                    java.util.Map<String, Integer> mathCounts = new java.util.HashMap<>();
                    for (int level = 0; level <= 8; level++) {
                        String columnName = "p" + phase + "_math_" + level;
                        int count = rs.getInt(columnName);
                        mathCounts.put(String.valueOf(level), count);
                    }
                    counts.put("phase" + phase + "_math", mathCounts);
                    
                    // English counts (0-6)
                    java.util.Map<String, Integer> englishCounts = new java.util.HashMap<>();
                    for (int level = 0; level <= 6; level++) {
                        String columnName = "p" + phase + "_english_" + level;
                        int count = rs.getInt(columnName);
                        englishCounts.put(String.valueOf(level), count);
                    }
                    counts.put("phase" + phase + "_english", englishCounts);
                    
                }
                counts.put("totalStudents", totalStudents);
            } else {
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting phase-wise subject counts: " + e.getMessage());
            e.printStackTrace();
        }
        
        return counts;
    }
    
    /**
     * Generate next available PEN number in format TEMPXXXXX
     * @return Next PEN number (e.g., TEMP00001, TEMP00002, etc.)
     */
    public String generateNextPenNumber() {
        int maxRetries = 10;
        
        for (int attempt = 0; attempt < maxRetries; attempt++) {
            String candidatePen = generateCandidatePenNumber();
            
            // Check if this PEN already exists
            if (!isPenNumberExists(candidatePen)) {
                return candidatePen;
            }
            
            
            // Small delay to avoid rapid collision in concurrent scenarios
            try {
                Thread.sleep(50);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
        
        // Fallback: use timestamp-based PEN if we couldn't generate unique one after retries
        String fallbackPen = "TEMP" + String.format("%05d", (int)(System.currentTimeMillis() % 100000));
        System.err.println("⚠ Using fallback PEN after " + maxRetries + " attempts: " + fallbackPen);
        return fallbackPen;
    }
    
    /**
     * Generate a candidate PEN number based on the last used PEN
     * @return Candidate PEN number
     */
    private String generateCandidatePenNumber() {
        String sql = "SELECT student_pen FROM students WHERE student_pen LIKE 'TEMP%' ORDER BY student_pen DESC LIMIT 1";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            if (rs.next()) {
                String lastPen = rs.getString("student_pen");
                // Extract the numeric part (e.g., TEMP00123 -> 123)
                String numericPart = lastPen.substring(4); // Remove "TEMP"
                int nextNumber = Integer.parseInt(numericPart) + 1;
                // Format with leading zeros (5 digits)
                return String.format("TEMP%05d", nextNumber);
            } else {
                // No existing TEMP PEN numbers, start from TEMP00001
                return "TEMP00001";
            }
            
        } catch (SQLException | NumberFormatException e) {
            System.err.println("Error generating candidate PEN number: " + e.getMessage());
            // Fallback: use timestamp-based PEN
            return "TEMP" + String.format("%05d", (int)(System.currentTimeMillis() % 100000));
        }
    }
    
    /**
     * Check if a PEN number already exists in the database
     * @param penNumber The PEN number to check
     * @return true if PEN exists, false otherwise
     */
    public boolean isPenNumberExists(String penNumber) {
        String sql = "SELECT COUNT(*) FROM students WHERE student_pen = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, penNumber);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking PEN number existence: " + e.getMessage());
            e.printStackTrace();
        }
        
        return false; // Assume doesn't exist on error (safe default for generation)
    }
    
    /**
     * Check if student has completed all 4 phases
     */
    public boolean hasCompletedAllPhases(int studentId) {
        String sql = "SELECT phase1_date, phase2_date, phase3_date, phase4_date " +
                     "FROM students WHERE student_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, studentId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getTimestamp("phase1_date") != null &&
                       rs.getTimestamp("phase2_date") != null &&
                       rs.getTimestamp("phase3_date") != null &&
                       rs.getTimestamp("phase4_date") != null;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking phases completion: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Check if student has achieved 100% FLN in all subjects
     * Marathi: Level 6, Math: Level 8, English: Level 6
     */
    public boolean checkFlnCompletion(int studentId) {
        String sql = "SELECT marathi_akshara_level, math_akshara_level, english_akshara_level " +
                     "FROM students WHERE student_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, studentId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int marathiLevel = rs.getInt("marathi_akshara_level");
                int mathLevel = rs.getInt("math_akshara_level");
                int englishLevel = rs.getInt("english_akshara_level");
                
                return marathiLevel == FLN_MARATHI_LEVEL
                    && mathLevel    == FLN_MATH_LEVEL
                    && englishLevel == FLN_ENGLISH_LEVEL;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking FLN completion: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Update FLN completion status for a student
     */
    public boolean updateFlnCompletionStatus(int studentId, boolean flnCompleted) {
        String sql = "UPDATE students SET fln_completed = ?, updated_date = NOW() WHERE student_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setBoolean(1, flnCompleted);
            pstmt.setInt(2, studentId);
            
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating FLN completion status: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Restart phases for a student who completed all phases but didn't achieve 100% FLN
     * Copies Phase 4 data to Phase 1 and clears all phase dates
     */
    public boolean restartPhasesWithPhase4Data(int studentId) {
        String sql = "UPDATE students SET " +
                     "phase1_marathi = phase4_marathi, " +
                     "phase1_math = phase4_math, " +
                     "phase1_english = phase4_english, " +
                     "phase1_date = NULL, " +
                     "phase2_marathi = NULL, " +
                     "phase2_math = NULL, " +
                     "phase2_english = NULL, " +
                     "phase2_date = NULL, " +
                     "phase3_marathi = NULL, " +
                     "phase3_math = NULL, " +
                     "phase3_english = NULL, " +
                     "phase3_date = NULL, " +
                     "phase4_marathi = NULL, " +
                     "phase4_math = NULL, " +
                     "phase4_english = NULL, " +
                     "phase4_date = NULL, " +
                     "updated_date = NOW() " +
                     "WHERE student_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, studentId);
            int rowsAffected = pstmt.executeUpdate();
            
            if (rowsAffected > 0) {
                return true;
            }
            
        } catch (SQLException e) {
            System.err.println("Error restarting phases: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    /**
     * Check and handle student when standard is updated
     * If FLN is not 100% complete, restart phases
     */
    public void handleStandardUpdate(int studentId) {
        try {
            // Check if student has completed all 4 phases
            boolean allPhasesCompleted = hasCompletedAllPhases(studentId);
            
            if (allPhasesCompleted) {
                // Check if FLN is 100% complete
                boolean flnComplete = checkFlnCompletion(studentId);
                
                if (flnComplete) {
                    // Mark student as FLN completed
                    updateFlnCompletionStatus(studentId, true);
                } else {
                    // Restart phases with Phase 4 data
                    restartPhasesWithPhase4Data(studentId);
                }
            }
        } catch (Exception e) {
            System.err.println("Error handling standard update: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Get count of students who have completed a specific phase (based on phase_date NOT NULL)
     * This matches the logic used in school-dashboard-enhanced.jsp
     * @param udiseNo School UDISE number
     * @param phaseNumber Phase number (1-4)
     * @return Count of students who have phase date set
     */
    public int getPhaseCompletedCount(String udiseNo, int phaseNumber) {
        String phaseColumn = "phase" + phaseNumber + "_date";
        String sql = "SELECT COUNT(*) FROM students " +
                     "WHERE udise_no = ? " +
                     "AND is_active = 1 " +
                     "AND (fln_completed IS NULL OR fln_completed = FALSE) " +
                     "AND " + phaseColumn + " IS NOT NULL";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int count = rs.getInt(1);
                return count;
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting phase completed count: " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }
    
    /**
     * Get total count of active students (excluding FLN completed)
     * This matches the logic used in school-dashboard-enhanced.jsp
     * @param udiseNo School UDISE number
     * @return Total count of active students
     */
    public int getTotalActiveStudentCount(String udiseNo) {
        String sql = "SELECT COUNT(*) FROM students " +
                     "WHERE udise_no = ? " +
                     "AND is_active = 1 " +
                     "AND (fln_completed IS NULL OR fln_completed = FALSE)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, udiseNo);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                int count = rs.getInt(1);
                return count;
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting total active student count: " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PROMOTE CLASSES
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns class-wise student counts for the promotion preview screen.
     * List is ordered by class number ascending.
     * Each map has: "class", "count", "action"
     */
    // Roman numeral class mappings (I–IX) with Arabic fallback
    private static final String CLASS_NEXT_CASE =
        "CASE class " +
        "WHEN 'I' THEN 'II' WHEN 'II' THEN 'III' WHEN 'III' THEN 'IV' " +
        "WHEN 'IV' THEN 'V' WHEN 'V' THEN 'VI' WHEN 'VI' THEN 'VII' " +
        "WHEN 'VII' THEN 'VIII' WHEN 'VIII' THEN 'IX' " +
        "WHEN '1' THEN '2' WHEN '2' THEN '3' WHEN '3' THEN '4' WHEN '4' THEN '5' " +
        "WHEN '5' THEN '6' WHEN '6' THEN '7' WHEN '7' THEN '8' WHEN '8' THEN '9' " +
        "ELSE class END";

    private static final String CLASS_AFTER_CASE =
        "CASE class " +
        "WHEN 'I' THEN 'II' WHEN 'II' THEN 'III' WHEN 'III' THEN 'IV' " +
        "WHEN 'IV' THEN 'V' WHEN 'V' THEN 'VI' WHEN 'VI' THEN 'VII' " +
        "WHEN 'VII' THEN 'VIII' WHEN 'VIII' THEN 'IX' WHEN 'IX' THEN 'GRADUATED' " +
        "WHEN '1' THEN '2' WHEN '2' THEN '3' WHEN '3' THEN '4' WHEN '4' THEN '5' " +
        "WHEN '5' THEN '6' WHEN '6' THEN '7' WHEN '7' THEN '8' WHEN '8' THEN '9' " +
        "WHEN '9' THEN 'GRADUATED' ELSE class END";

    private static final String PROMOTE_IN = "('I','II','III','IV','V','VI','VII','VIII','1','2','3','4','5','6','7','8')";
    private static final String GRAD_IN    = "('IX','9')";

    private String nextClassLabel(String cls) {
        if (cls == null) return "?";
        switch (cls.trim()) {
            case "I": return "II"; case "II": return "III"; case "III": return "IV";
            case "IV": return "V"; case "V": return "VI"; case "VI": return "VII";
            case "VII": return "VIII"; case "VIII": return "IX";
            case "1": return "2"; case "2": return "3"; case "3": return "4";
            case "4": return "5"; case "5": return "6"; case "6": return "7";
            case "7": return "8"; case "8": return "9";
            default: return cls;
        }
    }

    public List<Map<String, Object>> getPromotionPreview() {
        List<Map<String, Object>> result = new ArrayList<>();
        String sql = "SELECT class, COUNT(*) AS cnt FROM students WHERE is_active = 1 " +
                     "GROUP BY class ORDER BY " +
                     "FIELD(class,'I','II','III','IV','V','VI','VII','VIII','IX'," +
                           "'1','2','3','4','5','6','7','8','9')";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String cls  = rs.getString("class");
                int cnt     = rs.getInt("cnt");
                boolean grad = "IX".equals(cls) || "9".equals(cls);
                String action = grad ? "→ GRADUATE" : "→ Class " + nextClassLabel(cls);
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("class",  cls);
                row.put("count",  cnt);
                row.put("action", action);
                result.add(row);
            }
        } catch (SQLException e) {
            System.err.println("Error fetching promotion preview: " + e.getMessage());
        }
        return result;
    }

    /**
     * Runs the full class-promotion sequence inside a single transaction.
     * Returns a result map: success(boolean), promotionId(long),
     * studentsPromoted(int), studentsGraduated(int), message(String).
     *
     * Promotion rules:
     *   Classes 1-8 → incremented by 1 (phase1 seeded from phase4, phases 2-4 wiped)
     *   Class 9     → moved to graduated_students, marked is_active=0
     */
    public Map<String, Object> promoteAllClasses(String promotedBy, String academicYear, String remarks) {
        Map<String, Object> result = new HashMap<>();

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            // ── Step 1: Insert promotion log entry ───────────────────────────
            long promotionId;
            String sqlLog = "INSERT INTO class_promotion_log " +
                            "(academic_year, promoted_by, promotion_date, remarks) " +
                            "VALUES (?, ?, NOW(), ?)";
            try (PreparedStatement ps = conn.prepareStatement(sqlLog, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, academicYear);
                ps.setString(2, promotedBy);
                ps.setString(3, remarks);
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                keys.next();
                promotionId = keys.getLong(1);
            }
            System.out.println("Promotion log created: id=" + promotionId);

            // ── Step 2: Archive ALL active student phase data ────────────────
            String sqlArchive =
                "INSERT INTO student_phase_history " +
                "  (promotion_id, student_id, student_name, student_pen, udise_no, " +
                "   division, district, class_before, class_after, " +
                "   phase1_marathi, phase1_math, phase1_english, phase1_date, " +
                "   phase2_marathi, phase2_math, phase2_english, phase2_date, " +
                "   phase3_marathi, phase3_math, phase3_english, phase3_date, " +
                "   phase4_marathi, phase4_math, phase4_english, phase4_date, archived_at) " +
                "SELECT ?, student_id, student_name, student_pen, udise_no, " +
                "       division, district, class, " + CLASS_AFTER_CASE + ", " +
                "       phase1_marathi, phase1_math, phase1_english, phase1_date, " +
                "       phase2_marathi, phase2_math, phase2_english, phase2_date, " +
                "       phase3_marathi, phase3_math, phase3_english, phase3_date, " +
                "       phase4_marathi, phase4_math, phase4_english, phase4_date, NOW() " +
                "FROM students WHERE is_active = 1";
            try (PreparedStatement ps = conn.prepareStatement(sqlArchive)) {
                ps.setLong(1, promotionId);
                int rows = ps.executeUpdate();
                System.out.println("Archived " + rows + " student phase history rows");
            }

            // ── Step 3a: Archive phase approvals ────────────────────────────
            String sqlArchiveApprovals =
                "INSERT INTO phase_approvals_history " +
                "  (promotion_id, udise_no, phase_number, approval_status, " +
                "   approved_by, approval_date, remarks, archived_at) " +
                "SELECT ?, udise_no, phase_number, approval_status, " +
                "       approved_by, approval_date, remarks, NOW() " +
                "FROM phase_approvals";
            try (PreparedStatement ps = conn.prepareStatement(sqlArchiveApprovals)) {
                ps.setLong(1, promotionId);
                int rows = ps.executeUpdate();
                System.out.println("Archived " + rows + " phase approval rows");
            }

            // ── Step 3b: Clear phase_approvals for new year ──────────────────
            try (PreparedStatement ps = conn.prepareStatement("DELETE FROM phase_approvals")) {
                ps.executeUpdate();
            }

            // ── Step 4a: Insert graduating students (Class 9) ────────────────
            String sqlGraduate =
                "INSERT INTO graduated_students " +
                "  (promotion_id, student_id, student_name, student_pen, gender, " +
                "   udise_no, division, district, section, graduated_from_class, academic_year, " +
                "   final_marathi_level, final_math_level, final_english_level, fln_completed, " +
                "   phase1_marathi, phase1_math, phase1_english, " +
                "   phase2_marathi, phase2_math, phase2_english, " +
                "   phase3_marathi, phase3_math, phase3_english, " +
                "   phase4_marathi, phase4_math, phase4_english, graduated_at) " +
                "SELECT ?, student_id, student_name, student_pen, gender, " +
                "       udise_no, division, district, section, '9', ?, " +
                "       phase4_marathi, phase4_math, phase4_english, fln_completed, " +
                "       phase1_marathi, phase1_math, phase1_english, " +
                "       phase2_marathi, phase2_math, phase2_english, " +
                "       phase3_marathi, phase3_math, phase3_english, " +
                "       phase4_marathi, phase4_math, phase4_english, NOW() " +
                "FROM students WHERE class IN " + GRAD_IN + " AND is_active = 1";
            int studentsGraduated;
            try (PreparedStatement ps = conn.prepareStatement(sqlGraduate)) {
                ps.setLong(1, promotionId);
                ps.setString(2, academicYear);
                studentsGraduated = ps.executeUpdate();
                System.out.println("Graduated " + studentsGraduated + " Class-9 students");
            }

            // ── Step 4b: Mark Class IX/9 students inactive ───────────────────
            String sqlDeactivate =
                "UPDATE students SET is_active=0, updated_by=?, updated_date=NOW() " +
                "WHERE class IN " + GRAD_IN + " AND is_active=1";
            try (PreparedStatement ps = conn.prepareStatement(sqlDeactivate)) {
                ps.setString(1, promotedBy);
                ps.executeUpdate();
            }

            // ── Step 5: Promote Classes I–VIII (Roman) / 1–8 (Arabic) ───────
            // COALESCE: use last completed phase as baseline for new Phase 1
            String sqlPromote =
                "UPDATE students SET " +
                "  class          = " + CLASS_NEXT_CASE + ", " +
                "  phase1_marathi = COALESCE(phase4_marathi, phase3_marathi, phase2_marathi, phase1_marathi), " +
                "  phase1_math    = COALESCE(phase4_math,    phase3_math,    phase2_math,    phase1_math), " +
                "  phase1_english = COALESCE(phase4_english, phase3_english, phase2_english, phase1_english), " +
                "  phase1_date    = NULL, " +
                "  phase2_marathi = NULL, phase2_math = NULL, phase2_english = NULL, phase2_date = NULL, " +
                "  phase3_marathi = NULL, phase3_math = NULL, phase3_english = NULL, phase3_date = NULL, " +
                "  phase4_marathi = NULL, phase4_math = NULL, phase4_english = NULL, phase4_date = NULL, " +
                "  updated_by     = ?, updated_date = NOW() " +
                "WHERE is_active = 1 AND class IN " + PROMOTE_IN;
            int studentsPromoted;
            try (PreparedStatement ps = conn.prepareStatement(sqlPromote)) {
                ps.setString(1, promotedBy);
                studentsPromoted = ps.executeUpdate();
                System.out.println("Promoted " + studentsPromoted + " students (classes 1-8)");
            }

            // ── Step 6: Update promotion log counts ──────────────────────────
            String sqlUpdateLog =
                "UPDATE class_promotion_log SET " +
                "  students_promoted  = ?, " +
                "  students_graduated = ? " +
                "WHERE promotion_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sqlUpdateLog)) {
                ps.setInt(1, studentsPromoted);
                ps.setInt(2, studentsGraduated);
                ps.setLong(3, promotionId);
                ps.executeUpdate();
            }

            conn.commit();
            System.out.println("Promotion transaction committed. id=" + promotionId);

            result.put("success",           true);
            result.put("promotionId",        promotionId);
            result.put("studentsPromoted",   studentsPromoted);
            result.put("studentsGraduated",  studentsGraduated);
            result.put("message",            "Class promotion completed successfully");

        } catch (SQLException e) {
            System.err.println("Promotion failed — rolling back: " + e.getMessage());
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { /* ignore */ }
            }
            result.put("success", false);
            result.put("message", "Promotion failed: " + e.getMessage());
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException ex) { /* ignore */ }
            }
        }
        return result;
    }
}
