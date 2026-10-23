-- =====================================================================
-- Promotion archive for teacher-uploaded videos (2026-10-11)
--
-- After a class promotion, last year's teacher phase videos
-- (student_videos with a phase_number) and VidnyanSetu weekly activity
-- videos are stamped with the class_promotion_log.promotion_id that archived
-- them. Current-year screens show only archived_promotion_id IS NULL.
-- See com.vjnt.util.PromotionVideoArchiver.
--
-- OPTIONAL: the app adds these columns itself at startup
-- (PromotionVideoArchiver.ensureSchema via AppLifecycleListener).
--
-- Plain ALTERs — MariaDB 5.5 safe. Re-running gives a harmless
-- "Duplicate column name" error (#1060).
-- =====================================================================

-- 0) Pre-check: videos uploaded BEFORE the latest promotion (should normally be 0)
SELECT COUNT(*) AS phase_videos_before_last_promotion FROM student_videos
WHERE phase_number IS NOT NULL
  AND upload_date < (SELECT MAX(promotion_date) FROM class_promotion_log);
SELECT COUNT(*) AS vs_activities_before_last_promotion FROM vidnyansetu_activities
WHERE created_date < (SELECT MAX(promotion_date) FROM class_promotion_log);

-- 1) Archive columns
ALTER TABLE student_videos
  ADD COLUMN archived_promotion_id INT NULL DEFAULT NULL COMMENT 'class_promotion_log.promotion_id that archived this video; NULL = current year',
  ADD KEY idx_sv_archived (archived_promotion_id);

ALTER TABLE vidnyansetu_activities
  ADD COLUMN archived_promotion_id INT NULL DEFAULT NULL COMMENT 'class_promotion_log.promotion_id that archived this activity; NULL = current year',
  ADD KEY idx_vsa_archived (archived_promotion_id);

-- 2) Per-promotion archive counts (shown on promotion-audit.jsp)
ALTER TABLE class_promotion_log
  ADD COLUMN videos_archived INT NULL DEFAULT NULL,
  ADD COLUMN vs_activities_archived INT NULL DEFAULT NULL;

-- 2b) Mapping audit columns used when promotion retires mappings. Usually ALREADY
--     present (DISTRICT_MANAGE_TEACHER_STUDENTS_2026-09-25.sql), so the ALTERs are
--     commented out — phpMyAdmin stops the whole script at the first #1060.
--     Run this check; uncomment and run ONLY the ALTER for a column it does not list.
SELECT COLUMN_NAME FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teacher_student_mapping'
  AND COLUMN_NAME IN ('mapped_by','removed_by','updated_by','updated_date');
-- ALTER TABLE teacher_student_mapping ADD COLUMN mapped_by VARCHAR(20) NOT NULL DEFAULT 'AUTO';
-- ALTER TABLE teacher_student_mapping ADD COLUMN removed_by VARCHAR(20) DEFAULT NULL;
-- ALTER TABLE teacher_student_mapping ADD COLUMN updated_by VARCHAR(100) DEFAULT NULL;
-- ALTER TABLE teacher_student_mapping ADD COLUMN updated_date DATETIME DEFAULT NULL;
-- (The app also adds any missing ones itself at startup.)

-- 3) NOT RUN BY DEFAULT — back-stamp videos older than the latest promotion,
--    only if the pre-check above found any and you decide they belong to last year.
-- SET @pid = (SELECT promotion_id FROM class_promotion_log ORDER BY promotion_date DESC LIMIT 1);
-- SET @pdate = (SELECT promotion_date FROM class_promotion_log WHERE promotion_id = @pid);
-- UPDATE student_videos SET archived_promotion_id = @pid
--  WHERE archived_promotion_id IS NULL AND phase_number IS NOT NULL AND upload_date < @pdate;
-- UPDATE vidnyansetu_activities SET archived_promotion_id = @pid
--  WHERE archived_promotion_id IS NULL AND created_date < @pdate;

-- UNDO one promotion's archive (replace P and the promotion date):
-- UPDATE student_videos          SET archived_promotion_id = NULL WHERE archived_promotion_id = P;
-- UPDATE vidnyansetu_activities  SET archived_promotion_id = NULL WHERE archived_promotion_id = P;
-- UPDATE teacher_student_mapping SET is_active = 1, removed_by = NULL
--  WHERE removed_by = 'PROMOTION' AND updated_date >= '<promotion_date>';
