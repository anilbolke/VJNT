-- Fix Phase Approvals Table - Add missing columns
-- Run this script to add the missing created_at and updated_at columns

USE vjnt_class_management;

-- Check if phase_approvals table exists
CREATE TABLE IF NOT EXISTS phase_approvals (
    approval_id INT PRIMARY KEY AUTO_INCREMENT,
    udise_no VARCHAR(50) NOT NULL,
    phase_number INT NOT NULL,
    
    -- Completion info (School Coordinator)
    completed_by VARCHAR(100),
    completed_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    completion_remarks TEXT,
    
    -- Approval info (Head Master)
    approval_status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
    approved_by VARCHAR(100),
    approved_date DATETIME,
    approval_remarks TEXT,
    
    -- Statistics
    total_students INT DEFAULT 0,
    completed_students INT DEFAULT 0,
    pending_students INT DEFAULT 0,
    ignored_students INT DEFAULT 0,
    
    -- Audit timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE KEY unique_phase_approval (udise_no, phase_number),
    INDEX idx_udise (udise_no),
    INDEX idx_status (approval_status),
    INDEX idx_phase (phase_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add created_at column if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'vjnt_class_management' 
  AND TABLE_NAME = 'phase_approvals' 
  AND COLUMN_NAME = 'created_at';

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE phase_approvals ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP AFTER ignored_students',
    'SELECT "Column created_at already exists" as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add updated_at column if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'vjnt_class_management' 
  AND TABLE_NAME = 'phase_approvals' 
  AND COLUMN_NAME = 'updated_at';

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE phase_approvals ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at',
    'SELECT "Column updated_at already exists" as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'Phase Approvals table fixed successfully!' as message;

-- Show table structure
DESCRIBE phase_approvals;
