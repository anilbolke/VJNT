-- =====================================================================
-- VERIFY schema for the 2026-10-11 work (read-only — changes nothing):
--   * Promotion video archive  (ADD_PROMOTION_ARCHIVE_COLUMNS_2026-10-11.sql)
--   * VidnyanSetu video stars  (CREATE_VIDNYANSETU_VIDEO_FAVORITES_2026-10-11.sql)
--   * Mapping audit columns    (DISTRICT_MANAGE_TEACHER_STUDENTS_2026-09-25.sql)
--
-- Run against the target DB (select it first in phpMyAdmin, or USE <db>;).
-- Every row should say OK. MariaDB 5.5 / MySQL 8 safe.
-- =====================================================================

-- 1) Tables
SELECT e.tbl AS table_name,
       CASE WHEN t.TABLE_NAME IS NULL THEN 'MISSING' ELSE 'OK' END AS status
FROM (
          SELECT 'student_videos' AS tbl
UNION ALL SELECT 'vidnyansetu_activities'
UNION ALL SELECT 'class_promotion_log'
UNION ALL SELECT 'teacher_student_mapping'
UNION ALL SELECT 'teacher_student_mapping_audit'
UNION ALL SELECT 'vidnyansetu_video_favorites'
) e
LEFT JOIN information_schema.TABLES t
       ON t.TABLE_SCHEMA = DATABASE() AND t.TABLE_NAME = e.tbl
ORDER BY status DESC, e.tbl;

-- 2) Columns (also shows actual type / nullability / default to compare)
SELECT e.tbl AS table_name, e.col AS column_name, e.expected_type,
       CASE WHEN c.COLUMN_NAME IS NULL THEN 'MISSING' ELSE 'OK' END AS status,
       c.COLUMN_TYPE AS actual_type, c.IS_NULLABLE AS nullable, c.COLUMN_DEFAULT AS default_value
FROM (
          SELECT 'student_videos' AS tbl, 'archived_promotion_id' AS col, 'int, NULL' AS expected_type
UNION ALL SELECT 'vidnyansetu_activities',      'archived_promotion_id',  'int, NULL'
UNION ALL SELECT 'class_promotion_log',         'videos_archived',        'int, NULL'
UNION ALL SELECT 'class_promotion_log',         'vs_activities_archived', 'int, NULL'
UNION ALL SELECT 'teacher_student_mapping',     'mapped_by',              'varchar(20), NOT NULL, AUTO'
UNION ALL SELECT 'teacher_student_mapping',     'removed_by',             'varchar(20), NULL'
UNION ALL SELECT 'teacher_student_mapping',     'updated_by',             'varchar(100), NULL'
UNION ALL SELECT 'teacher_student_mapping',     'updated_date',           'datetime, NULL'
UNION ALL SELECT 'vidnyansetu_video_favorites', 'favorite_id',            'int, PK auto_increment'
UNION ALL SELECT 'vidnyansetu_video_favorites', 'user_id',                'int, NOT NULL'
UNION ALL SELECT 'vidnyansetu_video_favorites', 'activity_id',            'int, NOT NULL'
UNION ALL SELECT 'vidnyansetu_video_favorites', 'created_date',           'timestamp'
) e
LEFT JOIN information_schema.COLUMNS c
       ON c.TABLE_SCHEMA = DATABASE() AND c.TABLE_NAME = e.tbl AND c.COLUMN_NAME = e.col
ORDER BY status DESC, e.tbl, e.col;

-- 3) Indexes (columns listed in index order)
SELECT e.tbl AS table_name, e.idx AS index_name, e.expected_cols,
       CASE WHEN s.INDEX_NAME IS NULL THEN 'MISSING'
            WHEN s.cols <> e.expected_cols THEN 'WRONG COLUMNS'
            WHEN e.must_be_unique = 1 AND s.non_unique <> 0 THEN 'NOT UNIQUE'
            ELSE 'OK' END AS status,
       s.cols AS actual_cols
FROM (
          SELECT 'student_videos' AS tbl, 'idx_sv_archived' AS idx, 'archived_promotion_id' AS expected_cols, 0 AS must_be_unique
UNION ALL SELECT 'vidnyansetu_activities',      'idx_vsa_archived',     'archived_promotion_id', 0
UNION ALL SELECT 'vidnyansetu_video_favorites', 'PRIMARY',              'favorite_id',           1
UNION ALL SELECT 'vidnyansetu_video_favorites', 'uk_vsf_user_activity', 'user_id,activity_id',   1
UNION ALL SELECT 'vidnyansetu_video_favorites', 'idx_vsf_activity',     'activity_id',           0
) e
LEFT JOIN (
    SELECT TABLE_NAME, INDEX_NAME, MAX(NON_UNIQUE) AS non_unique,
           GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX SEPARATOR ',') AS cols
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    GROUP BY TABLE_NAME, INDEX_NAME
) s ON s.TABLE_NAME = e.tbl AND s.INDEX_NAME = e.idx
ORDER BY status DESC, e.tbl, e.idx;

-- 4) One-line summary: problems = 0 means everything is in place
SELECT
  (SELECT COUNT(*) FROM (
            SELECT 'student_videos' AS tbl
  UNION ALL SELECT 'vidnyansetu_activities' UNION ALL SELECT 'class_promotion_log'
  UNION ALL SELECT 'teacher_student_mapping' UNION ALL SELECT 'teacher_student_mapping_audit'
  UNION ALL SELECT 'vidnyansetu_video_favorites') e
   WHERE NOT EXISTS (SELECT 1 FROM information_schema.TABLES t
                     WHERE t.TABLE_SCHEMA = DATABASE() AND t.TABLE_NAME = e.tbl)) AS missing_tables,
  (SELECT COUNT(*) FROM (
            SELECT 'student_videos' AS tbl, 'archived_promotion_id' AS col
  UNION ALL SELECT 'vidnyansetu_activities', 'archived_promotion_id'
  UNION ALL SELECT 'class_promotion_log', 'videos_archived'
  UNION ALL SELECT 'class_promotion_log', 'vs_activities_archived'
  UNION ALL SELECT 'teacher_student_mapping', 'mapped_by'
  UNION ALL SELECT 'teacher_student_mapping', 'removed_by'
  UNION ALL SELECT 'teacher_student_mapping', 'updated_by'
  UNION ALL SELECT 'teacher_student_mapping', 'updated_date'
  UNION ALL SELECT 'vidnyansetu_video_favorites', 'user_id'
  UNION ALL SELECT 'vidnyansetu_video_favorites', 'activity_id') e
   WHERE NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS c
                     WHERE c.TABLE_SCHEMA = DATABASE() AND c.TABLE_NAME = e.tbl AND c.COLUMN_NAME = e.col)) AS missing_columns,
  (SELECT COUNT(*) FROM (
            SELECT 'student_videos' AS tbl, 'idx_sv_archived' AS idx
  UNION ALL SELECT 'vidnyansetu_activities', 'idx_vsa_archived'
  UNION ALL SELECT 'vidnyansetu_video_favorites', 'uk_vsf_user_activity'
  UNION ALL SELECT 'vidnyansetu_video_favorites', 'idx_vsf_activity') e
   WHERE NOT EXISTS (SELECT 1 FROM information_schema.STATISTICS s
                     WHERE s.TABLE_SCHEMA = DATABASE() AND s.TABLE_NAME = e.tbl AND s.INDEX_NAME = e.idx)) AS missing_indexes;

-- ---------------------------------------------------------------------
-- FIXES — run ONLY the line for an item reported MISSING above
-- (MariaDB 5.5: no IF NOT EXISTS on columns, so never run these blindly)
-- ---------------------------------------------------------------------
-- ALTER TABLE student_videos ADD COLUMN archived_promotion_id INT NULL DEFAULT NULL;
-- ALTER TABLE student_videos ADD KEY idx_sv_archived (archived_promotion_id);
-- ALTER TABLE vidnyansetu_activities ADD COLUMN archived_promotion_id INT NULL DEFAULT NULL;
-- ALTER TABLE vidnyansetu_activities ADD KEY idx_vsa_archived (archived_promotion_id);
-- ALTER TABLE class_promotion_log ADD COLUMN videos_archived INT NULL DEFAULT NULL;
-- ALTER TABLE class_promotion_log ADD COLUMN vs_activities_archived INT NULL DEFAULT NULL;
-- ALTER TABLE teacher_student_mapping ADD COLUMN mapped_by VARCHAR(20) NOT NULL DEFAULT 'AUTO';
-- ALTER TABLE teacher_student_mapping ADD COLUMN removed_by VARCHAR(20) DEFAULT NULL;
-- ALTER TABLE teacher_student_mapping ADD COLUMN updated_by VARCHAR(100) DEFAULT NULL;
-- ALTER TABLE teacher_student_mapping ADD COLUMN updated_date DATETIME DEFAULT NULL;
-- vidnyansetu_video_favorites (whole table): run CREATE_VIDNYANSETU_VIDEO_FAVORITES_2026-10-11.sql
-- teacher_student_mapping_audit (whole table): run DISTRICT_MANAGE_TEACHER_STUDENTS_2026-09-25.sql
