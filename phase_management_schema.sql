-- Phase Management Schema
-- This script creates tables to track phase-based language level management

-- Table to store language level data for each phase
CREATE TABLE IF NOT EXISTS student_language_phase (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    phase INT NOT NULL,
    marathi_level INT DEFAULT 0,
    math_level INT DEFAULT 0,
    english_level INT DEFAULT 0,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    UNIQUE KEY unique_student_phase (student_id, phase)
);

-- Table to track phase completion status for each school
CREATE TABLE IF NOT EXISTS phase_completion_status (
    id INT PRIMARY KEY AUTO_INCREMENT,
    udise_no VARCHAR(50) NOT NULL,
    phase INT NOT NULL,
    is_complete BOOLEAN DEFAULT FALSE,
    completion_date TIMESTAMP NULL,
    completed_by VARCHAR(100),
    total_students INT DEFAULT 0,
    completed_students INT DEFAULT 0,
    UNIQUE KEY unique_school_phase (udise_no, phase)
);

-- Audit table to track all changes
CREATE TABLE IF NOT EXISTS language_level_audit (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    phase INT NOT NULL,
    action_type VARCHAR(50), -- INSERT, UPDATE
    marathi_level_old INT,
    marathi_level_new INT,
    math_level_old INT,
    math_level_new INT,
    english_level_old INT,
    english_level_new INT,
    changed_by VARCHAR(100),
    changed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- Indexes for better performance
CREATE INDEX idx_student_phase ON student_language_phase(student_id, phase);
CREATE INDEX idx_udise_phase ON phase_completion_status(udise_no, phase);
CREATE INDEX idx_audit_student ON language_level_audit(student_id, phase);
CREATE INDEX idx_audit_date ON language_level_audit(changed_date);

-- Insert initial phase completion status for existing schools
INSERT IGNORE INTO phase_completion_status (udise_no, phase, is_complete, total_students)
SELECT DISTINCT udise_no, 1, FALSE, 0 FROM students;

INSERT IGNORE INTO phase_completion_status (udise_no, phase, is_complete, total_students)
SELECT DISTINCT udise_no, 2, FALSE, 0 FROM students;

INSERT IGNORE INTO phase_completion_status (udise_no, phase, is_complete, total_students)
SELECT DISTINCT udise_no, 3, FALSE, 0 FROM students;

INSERT IGNORE INTO phase_completion_status (udise_no, phase, is_complete, total_students)
SELECT DISTINCT udise_no, 4, FALSE, 0 FROM students;
