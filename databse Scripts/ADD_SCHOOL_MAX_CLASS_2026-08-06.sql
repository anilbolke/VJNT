-- =============================================================================
-- Per-School Terminal Class — schools.max_class
-- Date: 2026-08-06
-- Ref : PROMOTION_TERMINAL_CLASS_FIX_PLAN.md  §3 (Option B) and §6
--
-- WHY
--   Promotion used to hardcode the graduating class as ('IX','9'). Schools whose
--   last class is V / VII / VIII had their top class promoted into a class that
--   does not exist there, left active, and never written to graduated_students.
--
--   The code now resolves the terminal class per school:
--     1. schools.max_class, when set                       <- authoritative
--     2. otherwise the highest class that school currently <- derived fallback
--        has active students in
--
--   The fallback alone is not enough: a school that genuinely runs to IX but had
--   no IX students that year would be misdetected. max_class pins it down so the
--   derivation is never repeated and the bug cannot recur.
--
-- RUN ORDER
--   Section 1 is safe to run now.
--   Section 2 (seeding) should be run AFTER the promotion-correction tool, or at
--   least reviewed against Section 3 before you trust it.
--   Section 4 is the review query the district team signs off on.
--
-- NOTE  MySQL 8 has no "ADD COLUMN IF NOT EXISTS". Section 1 is a one-time run;
--       re-running it raises ER_DUP_FIELDNAME (1060), which is harmless.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Schema
-- -----------------------------------------------------------------------------
ALTER TABLE `schools`
  ADD COLUMN `max_class` VARCHAR(10)
      COLLATE utf8mb4_0900_ai_ci NULL
      COMMENT 'Terminal (last) class this school runs to: I..IX. NULL = derive from students.'
      AFTER `district_name`;


-- -----------------------------------------------------------------------------
-- 2. Seed from the pre-promotion snapshot
--
--    IMPORTANT: seed from student_phase_history.class_before, NOT from
--    students.class. Promotion already advanced every live row, so the students
--    table currently shows a terminal-VII school sitting in VIII. class_before is
--    the only truthful pre-promotion record.
-- -----------------------------------------------------------------------------

-- 2a. Pick the run to seed from: the most recent all-schools promotion.
--     Test runs are tagged [TEST-SINGLE-SCHOOL ...] in remarks and are excluded.
SET @pid = (
  SELECT promotion_id
  FROM class_promotion_log
  WHERE remarks IS NULL OR remarks NOT LIKE '%[TEST-SINGLE-SCHOOL%'
  ORDER BY promotion_id DESC
  LIMIT 1
);

SELECT @pid AS seeding_from_promotion_id;   -- sanity check before continuing

-- 2b. Seed. Only fills rows that are still NULL, so any value a Data Admin has
--     already corrected by hand is never overwritten.
UPDATE `schools` sc
JOIN (
  SELECT h.udise_no,
         MAX(CASE h.class_before
               WHEN 'I'   THEN 1 WHEN '1' THEN 1  WHEN 'II'   THEN 2 WHEN '2' THEN 2
               WHEN 'III' THEN 3 WHEN '3' THEN 3  WHEN 'IV'   THEN 4 WHEN '4' THEN 4
               WHEN 'V'   THEN 5 WHEN '5' THEN 5  WHEN 'VI'   THEN 6 WHEN '6' THEN 6
               WHEN 'VII' THEN 7 WHEN '7' THEN 7  WHEN 'VIII' THEN 8 WHEN '8' THEN 8
               WHEN 'IX'  THEN 9 WHEN '9' THEN 9  ELSE 0 END) AS tr
  FROM student_phase_history h
  WHERE h.promotion_id = @pid
  GROUP BY h.udise_no
) d ON sc.udise_no COLLATE utf8mb4_unicode_ci = d.udise_no
SET sc.max_class = CASE d.tr
                     WHEN 1 THEN 'I'   WHEN 2 THEN 'II'   WHEN 3 THEN 'III'
                     WHEN 4 THEN 'IV'  WHEN 5 THEN 'V'    WHEN 6 THEN 'VI'
                     WHEN 7 THEN 'VII' WHEN 8 THEN 'VIII' WHEN 9 THEN 'IX'
                     ELSE NULL END
WHERE sc.max_class IS NULL
  AND d.tr > 0;


-- -----------------------------------------------------------------------------
-- 3. Cross-check: derived-from-history vs derived-from-current-students
--
--    Rows where these disagree are worth a look. Before the correction tool runs
--    they will disagree by exactly one class for every affected school — that is
--    the bug itself, not a data problem.
-- -----------------------------------------------------------------------------
SELECT sc.udise_no,
       sc.school_name,
       sc.max_class                                   AS seeded_max_class,
       hist.tr                                        AS rank_from_history,
       cur.tr                                         AS rank_from_current_students,
       CASE WHEN hist.tr <> cur.tr THEN '<-- differs' ELSE '' END AS flag
FROM `schools` sc
LEFT JOIN (
  SELECT h.udise_no,
         MAX(CASE h.class_before
               WHEN 'I'   THEN 1 WHEN '1' THEN 1  WHEN 'II'   THEN 2 WHEN '2' THEN 2
               WHEN 'III' THEN 3 WHEN '3' THEN 3  WHEN 'IV'   THEN 4 WHEN '4' THEN 4
               WHEN 'V'   THEN 5 WHEN '5' THEN 5  WHEN 'VI'   THEN 6 WHEN '6' THEN 6
               WHEN 'VII' THEN 7 WHEN '7' THEN 7  WHEN 'VIII' THEN 8 WHEN '8' THEN 8
               WHEN 'IX'  THEN 9 WHEN '9' THEN 9  ELSE 0 END) AS tr
  FROM student_phase_history h WHERE h.promotion_id = @pid GROUP BY h.udise_no
) hist ON sc.udise_no COLLATE utf8mb4_unicode_ci = hist.udise_no
LEFT JOIN (
  SELECT s.udise_no,
         MAX(CASE s.class
               WHEN 'I'   THEN 1 WHEN '1' THEN 1  WHEN 'II'   THEN 2 WHEN '2' THEN 2
               WHEN 'III' THEN 3 WHEN '3' THEN 3  WHEN 'IV'   THEN 4 WHEN '4' THEN 4
               WHEN 'V'   THEN 5 WHEN '5' THEN 5  WHEN 'VI'   THEN 6 WHEN '6' THEN 6
               WHEN 'VII' THEN 7 WHEN '7' THEN 7  WHEN 'VIII' THEN 8 WHEN '8' THEN 8
               WHEN 'IX'  THEN 9 WHEN '9' THEN 9  ELSE 0 END) AS tr
  FROM students s WHERE s.is_active = 1 GROUP BY s.udise_no
) cur ON sc.udise_no COLLATE utf8mb4_unicode_ci = cur.udise_no
WHERE hist.tr IS NOT NULL OR cur.tr IS NOT NULL
ORDER BY (hist.tr <> cur.tr) DESC, sc.udise_no;


-- -----------------------------------------------------------------------------
-- 4. Review list for the district team
--    Anything terminating below VIII deserves an explicit confirmation.
-- -----------------------------------------------------------------------------
SELECT max_class,
       COUNT(*) AS schools
FROM `schools`
GROUP BY max_class
ORDER BY FIELD(max_class,'I','II','III','IV','V','VI','VII','VIII','IX');

SELECT udise_no, school_name, district_name, max_class
FROM `schools`
WHERE max_class IS NULL
   OR FIELD(max_class,'I','II','III','IV','V','VI','VII','VIII','IX') < 8
ORDER BY FIELD(max_class,'I','II','III','IV','V','VI','VII','VIII','IX'), udise_no;


-- -----------------------------------------------------------------------------
-- 5. Rollback, if ever needed
-- -----------------------------------------------------------------------------
-- ALTER TABLE `schools` DROP COLUMN `max_class`;
--   Safe: the code falls back to deriving the terminal class from current students.
