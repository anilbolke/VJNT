-- VidnyanSetu (विज्ञानसेतू) standalone login module.
-- New, separate accounts (School Coordinator / Teacher) that only see the
-- VidnyanSetu Activity feature + manage students for subject विज्ञान.
-- Kept fully separate from `users`/`teachers`/`teacher_assignments`/
-- `students.*_level` on purpose: `users.username` is UNIQUE on mobile number,
-- so a person who already has a main-portal login cannot get a second `users`
-- row for the same mobile, and the ask was for genuinely separate accounts.
--
-- Charset/collation matched to students/teacher_assignments/teachers
-- (utf8mb4 / utf8mb4_0900_ai_ci) on this DB — verified via information_schema
-- before writing this script. MariaDB 5.5 prod note: plain CREATE TABLE only,
-- no CTEs/window functions used here so this script is prod-safe as-is.

CREATE TABLE vidnyansetu_users (
  vs_user_id INT NOT NULL AUTO_INCREMENT,
  username VARCHAR(50) NOT NULL,
  password VARCHAR(255) NOT NULL,
  role ENUM('COORDINATOR','TEACHER') NOT NULL,
  udise_no VARCHAR(20) NOT NULL,
  full_name VARCHAR(200) NOT NULL,
  mobile VARCHAR(15) DEFAULT NULL,
  is_first_login TINYINT(1) DEFAULT 1,
  must_change_password TINYINT(1) DEFAULT 1,
  is_active TINYINT(1) DEFAULT 1,
  failed_login_attempts INT DEFAULT 0,
  account_locked TINYINT(1) DEFAULT 0,
  locked_date DATETIME DEFAULT NULL,
  created_by VARCHAR(100) DEFAULT NULL,
  created_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  last_login_date DATETIME DEFAULT NULL,
  PRIMARY KEY (vs_user_id),
  UNIQUE KEY uk_vs_username (username),
  KEY idx_vs_udise (udise_no),
  KEY idx_vs_role (role),
  KEY idx_vs_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE vidnyansetu_teacher_assignments (
  assignment_id INT NOT NULL AUTO_INCREMENT,
  vs_user_id INT NOT NULL,
  udise_code VARCHAR(20) NOT NULL,
  class VARCHAR(10) NOT NULL,
  section VARCHAR(10) NOT NULL,
  is_active TINYINT(1) DEFAULT 1,
  created_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (assignment_id),
  KEY idx_vsa_user (vs_user_id),
  KEY idx_vsa_class_section (udise_code, class, section),
  KEY idx_vsa_active (is_active),
  CONSTRAINT vsa_ibfk_user FOREIGN KEY (vs_user_id) REFERENCES vidnyansetu_users (vs_user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE vidnyansetu_student_levels (
  id INT NOT NULL AUTO_INCREMENT,
  student_id INT NOT NULL,
  vidnyan_level TINYINT NOT NULL DEFAULT 0 COMMENT '0=स्तर निश्चित केला नाही 1=प्रारंभिक 2=विकसनशिल 3=विकसीत 4=प्रगत',
  updated_by INT DEFAULT NULL COMMENT 'vidnyansetu_users.vs_user_id',
  updated_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_vsl_student (student_id),
  CONSTRAINT vsl_ibfk_student FOREIGN KEY (student_id) REFERENCES students (student_id) ON DELETE CASCADE,
  CONSTRAINT vsl_ibfk_user FOREIGN KEY (updated_by) REFERENCES vidnyansetu_users (vs_user_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
