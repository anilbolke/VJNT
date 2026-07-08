-- Teacher-Student random mapping table.
-- NOTE: this table is auto-created by TeacherMyStudentsServlet on first teacher
-- login (CREATE TABLE IF NOT EXISTS) — this script is for reference / manual setup.

CREATE TABLE IF NOT EXISTS teacher_student_mapping (
  mapping_id INT AUTO_INCREMENT PRIMARY KEY,
  teacher_id INT NOT NULL,
  udise_code VARCHAR(20) DEFAULT NULL,
  class VARCHAR(10) DEFAULT NULL,whrer
  section VARCHAR(10) DEFAULT NULL,
  student_id INT NOT NULL,
  created_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  is_active TINYINT(1) DEFAULT 1,
  UNIQUE KEY uq_teacher_student (teacher_id, student_id),
  KEY idx_map_class (udise_code, class, section)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
