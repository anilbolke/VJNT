-- Adds phase-based video support to student_videos.
-- Run this once against both the local dev DB (vjnt_class_management)
-- and the UAT DB (gateepor_vjnt_class_management) before deploying the
-- teacher phase-video upload feature.
--
-- Existing rows (coordinator/headmaster monthly uploads) are untouched:
-- phase_number stays NULL for them, and MySQL allows multiple NULLs in
-- a UNIQUE key, so they never collide with each other or with phase rows.

ALTER TABLE student_videos
  ADD COLUMN phase_number INT DEFAULT NULL
  COMMENT '1-4 for teacher phase-based uploads; NULL for legacy monthly coordinator uploads'
  AFTER month;

-- These were NOT NULL for the monthly coordinator flow; phase uploads don't use them.
ALTER TABLE student_videos MODIFY subject VARCHAR(50) NULL COMMENT 'Marathi, Math, or English (monthly uploads only)';
ALTER TABLE student_videos MODIFY month VARCHAR(20) NULL COMMENT 'Month of video (monthly uploads only)';
ALTER TABLE student_videos MODIFY has_progress VARCHAR(10) NULL COMMENT 'yes or no (monthly uploads only)';

-- One video per student per phase. NULL phase_number rows (monthly uploads)
-- are exempt since MySQL treats each NULL as distinct in a UNIQUE index.
ALTER TABLE student_videos
  ADD UNIQUE KEY uk_student_phase (student_id, phase_number);

ALTER TABLE student_videos
  ADD INDEX idx_phase_number (phase_number);
