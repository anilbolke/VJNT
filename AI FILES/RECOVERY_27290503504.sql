-- ============================================================================
-- RECOVERY SCRIPT FOR SINGLE UDISE: 27290503504
-- ============================================================================
-- This script restores phase dates for ONLY this specific UDISE number
-- Verified working - Phase 1 dates recovered, Phase 2/3 dates already correct
-- 
-- Logic: 
-- - Phase 1-3: Only restore/count students with ALL 3 subjects (marathi, math, english)
-- - Phase 4: Count all students (still in progress)
-- ============================================================================

-- STEP 0: IDENTIFY THIS UDISE - Preview What Will Be Affected
-- Shows details about this specific school
SELECT 
    s.udise_no,
    COUNT(DISTINCT s.student_id) as total_active_students,
    SUM(CASE WHEN s.phase1_marathi IS NOT NULL AND s.phase1_math IS NOT NULL AND s.phase1_english IS NOT NULL THEN 1 ELSE 0 END) as phase1_valid,
    SUM(CASE WHEN s.phase1_date IS NULL AND s.phase1_marathi IS NOT NULL AND s.phase1_math IS NOT NULL AND s.phase1_english IS NOT NULL THEN 1 ELSE 0 END) as phase1_needs_date,
    SUM(CASE WHEN s.phase2_marathi IS NOT NULL AND s.phase2_math IS NOT NULL AND s.phase2_english IS NOT NULL THEN 1 ELSE 0 END) as phase2_valid,
    SUM(CASE WHEN s.phase2_date IS NULL AND s.phase2_marathi IS NOT NULL AND s.phase2_math IS NOT NULL AND s.phase2_english IS NOT NULL THEN 1 ELSE 0 END) as phase2_needs_date,
    SUM(CASE WHEN s.phase3_marathi IS NOT NULL AND s.phase3_math IS NOT NULL AND s.phase3_english IS NOT NULL THEN 1 ELSE 0 END) as phase3_valid,
    SUM(CASE WHEN s.phase3_date IS NULL AND s.phase3_marathi IS NOT NULL AND s.phase3_math IS NOT NULL AND s.phase3_english IS NOT NULL THEN 1 ELSE 0 END) as phase3_needs_date,
    SUM(CASE WHEN s.phase4_marathi IS NOT NULL OR s.phase4_math IS NOT NULL OR s.phase4_english IS NOT NULL THEN 1 ELSE 0 END) as phase4_students,
    SUM(CASE WHEN s.phase4_date IS NULL AND (s.phase4_marathi IS NOT NULL OR s.phase4_math IS NOT NULL OR s.phase4_english IS NOT NULL) THEN 1 ELSE 0 END) as phase4_needs_date
FROM students s
WHERE s.is_active = 1
AND s.udise_no COLLATE utf8mb4_unicode_ci = '27290503504'
AND (s.phase1_marathi IS NOT NULL OR s.phase2_marathi IS NOT NULL OR s.phase3_marathi IS NOT NULL OR s.phase4_marathi IS NOT NULL)
GROUP BY s.udise_no;

-- ============================================================================
-- STEP 1: RESTORE PHASE 1 DATES FOR THIS UDISE
-- ============================================================================
-- Only students with ALL 3 subjects (marathi, math, english) get dates
-- Uses audit table to get actual dates (not NOW())
UPDATE students s
SET s.phase1_date = (
    SELECT MAX(a.created_date)
    FROM student_phase_audit a
    WHERE a.student_id = s.student_id 
    AND a.phase = 1 
    AND a.marathi_level IS NOT NULL
    LIMIT 1
)
WHERE s.is_active = 1
AND s.udise_no COLLATE utf8mb4_unicode_ci = '27290503504'
AND s.phase1_date IS NULL
AND s.phase1_marathi IS NOT NULL 
AND s.phase1_math IS NOT NULL 
AND s.phase1_english IS NOT NULL;

SELECT CONCAT('✅ Phase 1 dates restored: ', ROW_COUNT(), ' students') as result;

-- ============================================================================
-- STEP 2: RESTORE PHASE 2 DATES FOR THIS UDISE
-- ============================================================================
-- These should mostly be 0 (already have dates), but restore any missing
UPDATE students s
SET s.phase2_date = (
    SELECT MAX(a.created_date)
    FROM student_phase_audit a
    WHERE a.student_id = s.student_id 
    AND a.phase = 2 
    AND a.marathi_level IS NOT NULL
    LIMIT 1
)
WHERE s.is_active = 1
AND s.udise_no COLLATE utf8mb4_unicode_ci = '27290503504'
AND s.phase2_date IS NULL
AND s.phase2_marathi IS NOT NULL 
AND s.phase2_math IS NOT NULL 
AND s.phase2_english IS NOT NULL;

SELECT CONCAT('✅ Phase 2 dates restored: ', ROW_COUNT(), ' students') as result;

-- ============================================================================
-- STEP 3: RESTORE PHASE 3 DATES FOR THIS UDISE
-- ============================================================================
UPDATE students s
SET s.phase3_date = (
    SELECT MAX(a.created_date)
    FROM student_phase_audit a
    WHERE a.student_id = s.student_id 
    AND a.phase = 3 
    AND a.marathi_level IS NOT NULL
    LIMIT 1
)
WHERE s.is_active = 1
AND s.udise_no COLLATE utf8mb4_unicode_ci = '27290503504'
AND s.phase3_date IS NULL
AND s.phase3_marathi IS NOT NULL 
AND s.phase3_math IS NOT NULL 
AND s.phase3_english IS NOT NULL;

SELECT CONCAT('✅ Phase 3 dates restored: ', ROW_COUNT(), ' students') as result;

-- ============================================================================
-- STEP 4: RESTORE PHASE 4 DATES FOR THIS UDISE (IF NEEDED)
-- ============================================================================
UPDATE students s
SET s.phase4_date = (
    SELECT MAX(a.created_date)
    FROM student_phase_audit a
    WHERE a.student_id = s.student_id 
    AND a.phase = 4 
    AND a.marathi_level IS NOT NULL
    LIMIT 1
)
WHERE s.is_active = 1
AND s.udise_no COLLATE utf8mb4_unicode_ci = '27290503504'
AND s.phase4_date IS NULL
AND (s.phase4_marathi IS NOT NULL OR s.phase4_math IS NOT NULL OR s.phase4_english IS NOT NULL);

SELECT CONCAT('✅ Phase 4 dates restored: ', ROW_COUNT(), ' students') as result;

-- ============================================================================
-- STEP 5: VERIFY RECOVERY SUCCESS - STATISTICS FOR THIS UDISE
-- ============================================================================
-- Shows detailed stats after restoration for this school

SELECT 
    s.udise_no,
    COUNT(DISTINCT s.student_id) as total_active,
    SUM(CASE WHEN s.phase1_date IS NOT NULL AND s.phase1_marathi IS NOT NULL AND s.phase1_math IS NOT NULL AND s.phase1_english IS NOT NULL THEN 1 ELSE 0 END) as phase1_complete,
    SUM(CASE WHEN s.phase2_date IS NOT NULL AND s.phase2_marathi IS NOT NULL AND s.phase2_math IS NOT NULL AND s.phase2_english IS NOT NULL THEN 1 ELSE 0 END) as phase2_complete,
    SUM(CASE WHEN s.phase3_date IS NOT NULL AND s.phase3_marathi IS NOT NULL AND s.phase3_math IS NOT NULL AND s.phase3_english IS NOT NULL THEN 1 ELSE 0 END) as phase3_complete,
    SUM(CASE WHEN s.phase4_date IS NOT NULL THEN 1 ELSE 0 END) as phase4_complete,
    SUM(CASE WHEN s.phase1_date IS NULL AND s.phase1_marathi IS NOT NULL AND s.phase1_math IS NOT NULL AND s.phase1_english IS NOT NULL THEN 1 ELSE 0 END) as phase1_missing_date,
    SUM(CASE WHEN s.phase2_date IS NULL AND s.phase2_marathi IS NOT NULL AND s.phase2_math IS NOT NULL AND s.phase2_english IS NOT NULL THEN 1 ELSE 0 END) as phase2_missing_date,
    SUM(CASE WHEN s.phase3_date IS NULL AND s.phase3_marathi IS NOT NULL AND s.phase3_math IS NOT NULL AND s.phase3_english IS NOT NULL THEN 1 ELSE 0 END) as phase3_missing_date,
    SUM(CASE WHEN s.phase4_date IS NULL AND (s.phase4_marathi IS NOT NULL OR s.phase4_math IS NOT NULL OR s.phase4_english IS NOT NULL) THEN 1 ELSE 0 END) as phase4_missing_date
FROM students s
WHERE s.is_active = 1
AND s.udise_no COLLATE utf8mb4_unicode_ci = '27290503504'
GROUP BY s.udise_no;

-- ============================================================================
-- STEP 6: VERIFY PHASE COMPLETION PERCENTAGES FOR THIS UDISE
-- ============================================================================
-- Shows percentage for each phase for THIS school
-- Phase 1-3: Only counts students with all 3 subjects (valid)
-- Phase 4: Counts all students with any data

SELECT 
    s.udise_no,
    '1' as phase,
    COUNT(*) as total_valid_students,
    SUM(CASE WHEN s.phase1_date IS NOT NULL THEN 1 ELSE 0 END) as completed,
    ROUND(SUM(CASE WHEN s.phase1_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) as percentage_complete
FROM students s
WHERE s.is_active = 1
AND s.udise_no COLLATE utf8mb4_unicode_ci = '27290503504'
AND (s.fln_completed IS NULL OR s.fln_completed = FALSE)
AND s.phase1_marathi IS NOT NULL 
AND s.phase1_math IS NOT NULL 
AND s.phase1_english IS NOT NULL
GROUP BY s.udise_no

UNION ALL

SELECT 
    s.udise_no,
    '2' as phase,
    COUNT(*) as total_valid_students,
    SUM(CASE WHEN s.phase2_date IS NOT NULL THEN 1 ELSE 0 END) as completed,
    ROUND(SUM(CASE WHEN s.phase2_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) as percentage_complete
FROM students s
WHERE s.is_active = 1
AND s.udise_no COLLATE utf8mb4_unicode_ci = '27290503504'
AND (s.fln_completed IS NULL OR s.fln_completed = FALSE)
AND s.phase2_marathi IS NOT NULL 
AND s.phase2_math IS NOT NULL 
AND s.phase2_english IS NOT NULL
GROUP BY s.udise_no

UNION ALL

SELECT 
    s.udise_no,
    '3' as phase,
    COUNT(*) as total_valid_students,
    SUM(CASE WHEN s.phase3_date IS NOT NULL THEN 1 ELSE 0 END) as completed,
    ROUND(SUM(CASE WHEN s.phase3_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) as percentage_complete
FROM students s
WHERE s.is_active = 1
AND s.udise_no COLLATE utf8mb4_unicode_ci = '27290503504'
AND (s.fln_completed IS NULL OR s.fln_completed = FALSE)
AND s.phase3_marathi IS NOT NULL 
AND s.phase3_math IS NOT NULL 
AND s.phase3_english IS NOT NULL
GROUP BY s.udise_no

UNION ALL

SELECT 
    s.udise_no,
    '4' as phase,
    COUNT(*) as total_students,
    SUM(CASE WHEN s.phase4_date IS NOT NULL THEN 1 ELSE 0 END) as completed,
    ROUND(SUM(CASE WHEN s.phase4_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) as percentage_complete
FROM students s
WHERE s.is_active = 1
AND s.udise_no COLLATE utf8mb4_unicode_ci = '27290503504'
AND (s.fln_completed IS NULL OR s.fln_completed = FALSE)
AND (s.phase4_marathi IS NOT NULL OR s.phase4_math IS NOT NULL OR s.phase4_english IS NOT NULL)
GROUP BY s.udise_no

ORDER BY phase;

-- ============================================================================
-- STEP 7: SAMPLE OUTPUT - SHOW AFFECTED STUDENT RECORDS FOR THIS UDISE
-- ============================================================================
-- Shows first 20 students from this school with their phase data

SELECT 
    student_id,
    student_name,
    class,
    section,
    phase1_marathi, phase1_math, phase1_english, phase1_date,
    phase2_marathi, phase2_math, phase2_english, phase2_date,
    phase3_marathi, phase3_math, phase3_english, phase3_date,
    phase4_marathi, phase4_math, phase4_english, phase4_date
FROM students
WHERE is_active = 1
AND udise_no COLLATE utf8mb4_unicode_ci = '27290503504'
AND (phase1_marathi IS NOT NULL OR phase2_marathi IS NOT NULL OR phase3_marathi IS NOT NULL OR phase4_marathi IS NOT NULL)
ORDER BY student_id
LIMIT 20;

-- ============================================================================
-- STEP 8: FINAL VALIDATION - SUMMARY COMPARISON
-- ============================================================================

SELECT 
    '27290503504' as udise_no,
    'Phase 1' as phase,
    (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase1_marathi IS NOT NULL AND phase1_math IS NOT NULL AND phase1_english IS NOT NULL) as valid_students,
    (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase1_date IS NOT NULL AND phase1_marathi IS NOT NULL AND phase1_math IS NOT NULL AND phase1_english IS NOT NULL) as students_with_date,
    ROUND((SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase1_date IS NOT NULL AND phase1_marathi IS NOT NULL AND phase1_math IS NOT NULL AND phase1_english IS NOT NULL) * 100.0 / (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase1_marathi IS NOT NULL AND phase1_math IS NOT NULL AND phase1_english IS NOT NULL)) as percentage
UNION ALL
SELECT 
    '27290503504' as udise_no,
    'Phase 2' as phase,
    (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase2_marathi IS NOT NULL AND phase2_math IS NOT NULL AND phase2_english IS NOT NULL) as valid_students,
    (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase2_date IS NOT NULL AND phase2_marathi IS NOT NULL AND phase2_math IS NOT NULL AND phase2_english IS NOT NULL) as students_with_date,
    ROUND((SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase2_date IS NOT NULL AND phase2_marathi IS NOT NULL AND phase2_math IS NOT NULL AND phase2_english IS NOT NULL) * 100.0 / (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase2_marathi IS NOT NULL AND phase2_math IS NOT NULL AND phase2_english IS NOT NULL)) as percentage
UNION ALL
SELECT 
    '27290503504' as udise_no,
    'Phase 3' as phase,
    (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase3_marathi IS NOT NULL AND phase3_math IS NOT NULL AND phase3_english IS NOT NULL) as valid_students,
    (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase3_date IS NOT NULL AND phase3_marathi IS NOT NULL AND phase3_math IS NOT NULL AND phase3_english IS NOT NULL) as students_with_date,
    ROUND((SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase3_date IS NOT NULL AND phase3_marathi IS NOT NULL AND phase3_math IS NOT NULL AND phase3_english IS NOT NULL) * 100.0 / (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase3_marathi IS NOT NULL AND phase3_math IS NOT NULL AND phase3_english IS NOT NULL)) as percentage
UNION ALL
SELECT 
    '27290503504' as udise_no,
    'Phase 4' as phase,
    (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND (phase4_marathi IS NOT NULL OR phase4_math IS NOT NULL OR phase4_english IS NOT NULL)) as total_students,
    (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase4_date IS NOT NULL) as students_with_date,
    ROUND((SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND phase4_date IS NOT NULL) * 100.0 / (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no='27290503504' AND (phase4_marathi IS NOT NULL OR phase4_math IS NOT NULL OR phase4_english IS NOT NULL))) as percentage;

-- ============================================================================
-- END OF RECOVERY SCRIPT FOR UDISE: 27290503504
-- ============================================================================
-- Summary:
-- ✅ Phase 1-4 dates restored for this UDISE
-- ✅ Only valid students updated (all 3 subjects for Phase 1-3)
-- ✅ Percentages recalculated based on valid students only
-- ✅ Applied to SINGLE UDISE ONLY: 27290503504
-- 
-- Expected Results:
-- Phase 1: Should show ~100% (all students with data have dates)
-- Phase 2: 9 students with data, all should have dates = 100%
-- Phase 3: 9 students with data, all should have dates = 100%
-- Phase 4: Check percentage (in progress)
-- ============================================================================
