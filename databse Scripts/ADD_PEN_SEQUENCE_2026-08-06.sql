-- =============================================================================
-- Temporary Student PEN sequence
-- Date: 2026-08-06
--
-- WHY
--   generateCandidatePenNumber() derived the next PEN by scanning for the highest
--   existing 'TEMP%' student_pen and adding 1. TEMP PENs are placeholders: schools
--   replace them with the real government PEN once it arrives (the field is
--   editable on the edit form). The moment the last TEMP row is renamed, the scan
--   finds nothing and the counter resets to TEMP00001 -- which is why every school
--   kept being handed the same number.
--
--   The sort was also lexical, so it broke above TEMP99999 ('TEMP99999' sorts
--   higher than 'TEMP100000'), leaving the generator proposing a number that
--   already existed on every attempt.
--
--   A standalone counter fixes both: it only ever moves forward, and it does not
--   care whether the PENs it issued still exist.
--
-- SAFE TO RE-RUN. Seeding uses GREATEST(), so the counter never moves backwards.
-- =============================================================================

CREATE TABLE IF NOT EXISTS `pen_sequence` (
  `seq_name`   varchar(32) NOT NULL,
  `next_value` bigint      NOT NULL,
  `updated_at` datetime    NOT NULL,
  PRIMARY KEY (`seq_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed above the highest TEMP number ever issued, so no old PEN is handed out twice.
-- graduated_students and student_phase_history are included deliberately: a PEN
-- belonging to a graduated or archived student must never be reissued to a live one.
INSERT INTO `pen_sequence` (`seq_name`, `next_value`, `updated_at`)
SELECT 'TEMP', COALESCE(MAX(n), 0) + 1, NOW()
FROM (
    SELECT CAST(SUBSTRING(student_pen, 5) AS UNSIGNED) AS n
    FROM students                WHERE student_pen REGEXP '^TEMP[0-9]+$'
    UNION ALL
    SELECT CAST(SUBSTRING(student_pen, 5) AS UNSIGNED)
    FROM graduated_students      WHERE student_pen REGEXP '^TEMP[0-9]+$'
    UNION ALL
    SELECT CAST(SUBSTRING(student_pen, 5) AS UNSIGNED)
    FROM student_phase_history   WHERE student_pen REGEXP '^TEMP[0-9]+$'
) AS all_temp_pens
ON DUPLICATE KEY UPDATE
  `next_value` = GREATEST(`next_value`, VALUES(`next_value`)),
  `updated_at` = NOW();

-- Verify
SELECT * FROM `pen_sequence`;


-- -----------------------------------------------------------------------------
-- Duplicate PEN report — run before considering a UNIQUE constraint
--
-- student_pen currently has only a plain KEY (idx_student_pen), so nothing at the
-- database level ever prevented two rows sharing a PEN.
-- -----------------------------------------------------------------------------
SELECT student_pen,
       COUNT(*)                        AS copies,
       COUNT(DISTINCT udise_no)        AS schools,
       GROUP_CONCAT(student_id ORDER BY student_id) AS student_ids
FROM students
WHERE student_pen IS NOT NULL AND student_pen <> ''
GROUP BY student_pen
HAVING copies > 1
ORDER BY copies DESC, student_pen;
