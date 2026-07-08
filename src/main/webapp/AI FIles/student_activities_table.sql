-- ============================================================
-- GATEE Portal — Student Activities Table
-- Run this SQL once in MySQL before using student-activity.jsp
-- ============================================================

CREATE TABLE IF NOT EXISTS student_activities (
  activity_id        INT            AUTO_INCREMENT PRIMARY KEY,
  student_pen        VARCHAR(50)    NOT NULL,
  student_name       VARCHAR(200)   NOT NULL,
  udise_no           VARCHAR(20)    NOT NULL,
  student_class      VARCHAR(10),
  activity_type      VARCHAR(50)    NOT NULL,
  activity_name      VARCHAR(200)   NOT NULL,
  activity_date      DATE,
  description        TEXT,
  achievement        VARCHAR(100),
  competition_level  VARCHAR(50),
  photo_content      LONGBLOB,
  photo_filename     VARCHAR(200),
  photo_content_type VARCHAR(100),
  created_by         VARCHAR(100),
  created_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_udise    (udise_no),
  INDEX idx_pen      (student_pen),
  INDEX idx_type     (activity_type),
  INDEX idx_date     (activity_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Verify table created:
-- DESCRIBE student_activities;
-- SELECT COUNT(*) FROM student_activities;
-- ============================================================
