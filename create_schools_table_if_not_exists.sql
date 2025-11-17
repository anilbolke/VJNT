-- Create schools table if it doesn't exist
-- Run this script first before uploading Excel file

CREATE TABLE IF NOT EXISTS schools (
    school_id INT PRIMARY KEY AUTO_INCREMENT,
    udise_no VARCHAR(50) UNIQUE NOT NULL,
    school_name VARCHAR(255) NOT NULL,
    district_name VARCHAR(100),
    
    -- Audit Fields
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    
    -- Indexes
    INDEX idx_udise (udise_no),
    INDEX idx_district (district_name),
    INDEX idx_school_name (school_name)
);

-- Verify table was created
SELECT 'Schools table created successfully!' as status;

-- Show table structure
DESC schools;

-- Show current count
SELECT COUNT(*) as school_count FROM schools;
