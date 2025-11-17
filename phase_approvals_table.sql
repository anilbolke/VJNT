-- Phase Approvals Table
-- Tracks phase submissions and approvals by School Coordinator and Head Master

USE vjnt_class_management;

DROP TABLE IF EXISTS phase_approvals;

CREATE TABLE phase_approvals (
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

-- Sample data for testing (optional - remove if not needed)
-- INSERT INTO phase_approvals (udise_no, phase_number, completed_by, total_students, completed_students, pending_students, ignored_students)
-- VALUES ('12345678', 1, 'coordinator_user', 100, 95, 0, 5);

SELECT 'Phase Approvals table created successfully!' as message;
