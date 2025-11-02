-- =====================================================
-- VJNT Class Management - Students Table
-- =====================================================

DROP TABLE IF EXISTS students;

CREATE TABLE students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- Location Information
    division VARCHAR(100),
    district VARCHAR(100),
    udise_no VARCHAR(50),
    
    -- Class Information
    class VARCHAR(10),
    section VARCHAR(10),
    class_category VARCHAR(50),
    
    -- Student Information
    student_name VARCHAR(200) NOT NULL,
    gender ENUM('Male', 'Female', 'Other', 'पुरुष', 'स्त्री', 'इतर'),
    student_pen VARCHAR(50),
    
    -- Performance Levels (Marathi: मराठी भाषा स्तर, गणित स्तर, इंग्रजी स्तर)
    marathi_level VARCHAR(50),
    math_level VARCHAR(50),
    english_level VARCHAR(50),
    
    -- Audit Fields
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) DEFAULT 'SYSTEM',
    updated_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    
    -- Indexes
    INDEX idx_division (division),
    INDEX idx_district (district),
    INDEX idx_udise (udise_no),
    INDEX idx_class (class),
    INDEX idx_student_pen (student_pen)
);
