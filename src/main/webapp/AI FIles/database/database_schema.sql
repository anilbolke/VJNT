-- =====================================================
-- VJNT Class Management - User Login System
-- Database Schema for Multi-Level Access Control
-- =====================================================

-- Drop tables if exist (in reverse order of dependencies)
DROP TABLE IF EXISTS login_audit;
DROP TABLE IF EXISTS users;

-- =====================================================
-- Main Users Table
-- =====================================================
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    user_type ENUM('DIVISION', 'DISTRICT_COORDINATOR', 'DISTRICT_2ND_COORDINATOR', 'SCHOOL_COORDINATOR', 'HEAD_MASTER') NOT NULL,
    
    -- Reference Fields
    division_name VARCHAR(100),
    district_name VARCHAR(100),
    udise_no VARCHAR(50),
    
    -- Password Management
    is_first_login BOOLEAN DEFAULT TRUE,
    password_changed_date DATETIME,
    must_change_password BOOLEAN DEFAULT TRUE,
    
    -- Account Status
    is_active BOOLEAN DEFAULT TRUE,
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    last_login_date DATETIME,
    failed_login_attempts INT DEFAULT 0,
    account_locked BOOLEAN DEFAULT FALSE,
    locked_date DATETIME,
    
    -- Contact Information (optional)
    email VARCHAR(100),
    mobile VARCHAR(15),
    full_name VARCHAR(200),
    
    -- Audit Fields
    updated_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    
    -- Indexes for performance
    INDEX idx_username (username),
    INDEX idx_user_type (user_type),
    INDEX idx_division (division_name),
    INDEX idx_district (district_name),
    INDEX idx_udise (udise_no),
    INDEX idx_active (is_active)
);

-- =====================================================
-- Login Audit Table
-- =====================================================
CREATE TABLE login_audit (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    username VARCHAR(100),
    login_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    logout_time DATETIME,
    ip_address VARCHAR(50),
    session_id VARCHAR(100),
    login_status ENUM('SUCCESS', 'FAILED', 'LOCKED') NOT NULL,
    failure_reason VARCHAR(255),
    user_agent VARCHAR(255),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_login_time (login_time),
    INDEX idx_login_status (login_status)
);

-- =====================================================
-- Default Admin User (Optional)
-- =====================================================
INSERT INTO users (username, password, user_type, is_first_login, must_change_password, is_active, full_name, created_by)
VALUES ('admin', 'admin123', 'DIVISION', FALSE, FALSE, TRUE, 'System Administrator', 'SYSTEM');

-- =====================================================
-- Views for Easy Querying
-- =====================================================

-- View for Division Admins
CREATE OR REPLACE VIEW vw_division_users AS
SELECT user_id, username, division_name, is_active, is_first_login, last_login_date, created_date
FROM users
WHERE user_type = 'DIVISION';

-- View for District Coordinators
CREATE OR REPLACE VIEW vw_district_users AS
SELECT user_id, username, user_type, district_name, division_name, is_active, is_first_login, last_login_date, created_date
FROM users
WHERE user_type IN ('DISTRICT_COORDINATOR', 'DISTRICT_2ND_COORDINATOR')
ORDER BY district_name, user_type;

-- View for School Users
CREATE OR REPLACE VIEW vw_school_users AS
SELECT user_id, username, user_type, udise_no, district_name, division_name, is_active, is_first_login, last_login_date, created_date
FROM users
WHERE user_type IN ('SCHOOL_COORDINATOR', 'HEAD_MASTER')
ORDER BY udise_no, user_type;

-- View for Active Users Summary
CREATE OR REPLACE VIEW vw_active_users_summary AS
SELECT 
    user_type,
    COUNT(*) as total_users,
    SUM(CASE WHEN is_active = TRUE THEN 1 ELSE 0 END) as active_users,
    SUM(CASE WHEN is_first_login = TRUE THEN 1 ELSE 0 END) as pending_first_login,
    SUM(CASE WHEN account_locked = TRUE THEN 1 ELSE 0 END) as locked_accounts
FROM users
GROUP BY user_type;

-- =====================================================
-- Sample Queries for Testing
-- =====================================================

-- Get all users by type
-- SELECT * FROM users WHERE user_type = 'DIVISION';
-- SELECT * FROM users WHERE user_type = 'DISTRICT_COORDINATOR';
-- SELECT * FROM users WHERE user_type = 'SCHOOL_COORDINATOR';

-- Get users pending password change
-- SELECT * FROM users WHERE must_change_password = TRUE;

-- Get login audit trail
-- SELECT * FROM login_audit WHERE login_time >= DATE_SUB(NOW(), INTERVAL 7 DAY);

-- Get failed login attempts
-- SELECT username, COUNT(*) as failed_attempts 
-- FROM login_audit 
-- WHERE login_status = 'FAILED' AND login_time >= DATE_SUB(NOW(), INTERVAL 1 DAY)
-- GROUP BY username;
