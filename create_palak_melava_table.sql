-- Create Palak Melava (Parent-Teacher Meeting) table
CREATE TABLE IF NOT EXISTS palak_melava (
    melava_id INT PRIMARY KEY AUTO_INCREMENT,
    udise_no VARCHAR(20) NOT NULL,
    school_name VARCHAR(255),
    
    -- EXACT REQUIRED FIELDS ONLY
    meeting_date DATE NOT NULL,
    chief_attendee_info TEXT NOT NULL,
    total_parents_attended VARCHAR(100) NOT NULL,
    photo_1_path VARCHAR(500),
    photo_2_path VARCHAR(500),
    
    -- Approval Workflow
    status ENUM('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED') DEFAULT 'DRAFT',
    submitted_by VARCHAR(100),
    submitted_date DATETIME,
    
    approval_status VARCHAR(20),
    approved_by VARCHAR(100),
    approval_date DATETIME,
    approval_remarks TEXT,
    rejection_reason TEXT,
    
    -- Audit fields
    created_by VARCHAR(100),
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    updated_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (udise_no) REFERENCES schools(udise_no) ON DELETE CASCADE
);

-- Create index for faster queries
CREATE INDEX idx_palak_melava_udise ON palak_melava(udise_no);
CREATE INDEX idx_palak_melava_status ON palak_melava(status);
CREATE INDEX idx_palak_melava_date ON palak_melava(meeting_date);
