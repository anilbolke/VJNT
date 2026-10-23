-- =============================================================================
-- Student status change audit
-- Date: 2026-08-06
--
-- WHY
--   Bulk deactivation is a two-click operation with no bulk undo. is_active = 0 is
--   not cosmetic: it removes a student from phase-completion percentages, the
--   promotion run, the FLN list and analytics. A school could mark its remaining
--   students inactive and have a phase read as complete.
--
--   This table records who deactivated whom and when, so a division officer can
--   see it happened. One row per student per action.
--
-- SAFE TO RE-RUN.
-- =============================================================================

CREATE TABLE IF NOT EXISTS `student_status_audit` (
  `audit_id`    bigint      NOT NULL AUTO_INCREMENT,
  `student_id`  int         NOT NULL,
  `udise_no`    varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `action`      varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'DEACTIVATE / ACTIVATE',
  `source`      varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. BULK_SELECT_STUDENT',
  `reason`      varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `changed_by`  varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `changed_at`  datetime    NOT NULL,
  PRIMARY KEY (`audit_id`),
  KEY `idx_ssa_student` (`student_id`),
  KEY `idx_ssa_udise` (`udise_no`),
  KEY `idx_ssa_changed_at` (`changed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -----------------------------------------------------------------------------
-- Review queries
-- -----------------------------------------------------------------------------

-- Recent bulk deactivations, largest batches first
SELECT udise_no, changed_by, DATE(changed_at) AS day, COUNT(*) AS students
FROM student_status_audit
WHERE action = 'DEACTIVATE'
GROUP BY udise_no, changed_by, DATE(changed_at)
ORDER BY students DESC, day DESC
LIMIT 100;

-- Full trail for one school
-- SELECT a.*, s.student_name, s.class
-- FROM student_status_audit a
-- LEFT JOIN students s ON s.student_id = a.student_id
-- WHERE a.udise_no = '27150300114'
-- ORDER BY a.changed_at DESC;
