-- ---------------------------------------------------------------------------
-- teachers.teacher_category — शिक्षक / पर्मनंट शिक्षक
--
-- The District Coordinator marks each teacher as a regular or a permanent
-- teacher, from the new "Teacher Category" page in the district login
-- (district-teacher-category.jsp -> /update-teacher-category).
--
-- Stored as a CODE, not the Marathi text, so WHERE / GROUP BY stay
-- collation-safe and the migration carries no Devanagari:
--     REGULAR   -> शिक्षक              (default for every existing teacher)
--     PERMANENT -> पर्मनंट शिक्षक
-- The Marathi labels live in the JSP / JS only.
--
-- It is a property of the TEACHER (one value per teachers row), so every
-- class-section assignment of that teacher shares it.
-- ---------------------------------------------------------------------------
-- HOW TO RUN (phpMyAdmin or CLI)
--
-- Pick the database the app actually uses first — there are several
-- (vjnt_class_management, vjnt_class_management_live,
-- gateepor_vjnt_class_management). Then run the ALTER below.
--
-- This is a plain ALTER: MySQL has no ADD COLUMN IF NOT EXISTS (that is
-- MariaDB) and the shared host denies the app user access to
-- information_schema, so it cannot be made conditionally re-runnable.
-- Running it a second time is harmless — it just reports:
--     #1060 - Duplicate column name 'teacher_category'
-- ---------------------------------------------------------------------------

ALTER TABLE teachers
  ADD COLUMN teacher_category VARCHAR(20) NOT NULL DEFAULT 'REGULAR'
  COMMENT 'REGULAR = shikshak, PERMANENT = permanent shikshak; set by District Coordinator'
  AFTER subjects_taught;

-- Optional: index it if the district page grows large enough to filter server-side.
-- ALTER TABLE teachers ADD INDEX idx_teacher_category (teacher_category);
