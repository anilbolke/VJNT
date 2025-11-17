-- =====================================================
-- VJNT Class Management - Phase Approval System
-- Tracks phase completion and approval workflow
-- =====================================================

DROP TABLE IF EXISTS phase_approvals;

CREATE TABLE phase_approvals (
    approval_id INT PRIMARY KEY AUTO_INCREMENT,
    udise_no VARCHAR(50) NOT NULL,
    phase_number INT NOT NULL,
    
    -- Phase Completion by School Coordinator
    completed_by VARCHAR(100),
    completed_date DATETIME,
    completion_remarks TEXT,
    
    -- Phase Approval by Head Master
    approval_status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
    approved_by VARCHAR(100),
    approved_date DATETIME,
    approval_remarks TEXT,
    
    -- Student Count at Time of Completion
    total_students INT DEFAULT 0,
    completed_students INT DEFAULT 0,
    pending_students INT DEFAULT 0,
    ignored_students INT DEFAULT 0,
    
    -- Audit Fields
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE KEY unique_phase_per_school (udise_no, phase_number),
    INDEX idx_udise (udise_no),
    INDEX idx_phase (phase_number),
    INDEX idx_status (approval_status),
    INDEX idx_completed_date (completed_date)
);

-- Sample data structure
-- INSERT INTO phase_approvals 
-- (udise_no, phase_number, completed_by, completed_date, total_students, completed_students, approval_status)
-- VALUES ('12345678901', 1, 'coordinator_user', NOW(), 100, 95, 'PENDING');

SELECT 'Phase approvals table created successfully!' as status;
