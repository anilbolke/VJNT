-- =====================================================
-- VJNT Class Management - Schools Master Table
-- Stores UDISE numbers with School Names
-- =====================================================

DROP TABLE IF EXISTS schools;

CREATE TABLE schools (
    school_id INT PRIMARY KEY AUTO_INCREMENT,
    udise_no VARCHAR(50) UNIQUE NOT NULL,
    school_name VARCHAR(255) NOT NULL,
    district_name VARCHAR(100),
    
    -- Audit Fieldscontinue
    
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    
    -- Indexes
    INDEX idx_udise (udise_no),
    INDEX idx_district (district_name),
    INDEX idx_school_name (school_name)
);

-- Sample data (can be removed after Excel upload)
-- INSERT INTO schools (udise_no, school_name, district_name, created_by)
-- VALUES ('12345678901', 'Government Primary School', 'Pune', 'SYSTEM');
