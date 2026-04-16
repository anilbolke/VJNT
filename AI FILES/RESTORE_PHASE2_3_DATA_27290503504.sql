-- ============================================================================
-- RESTORE PHASE 2 AND PHASE 3 DATA FROM AUDIT TABLE
-- UDISE: 27290503504
-- ============================================================================
-- This script restores actual phase data (marathi, math, english levels)
-- from the student_phase_audit table for Phase 2 and Phase 3
-- 
-- Purpose:
-- - Recover lost Phase 2 data: phase2_marathi, phase2_math, phase2_english, phase2_date
-- - Recover lost Phase 3 data: phase3_marathi, phase3_math, phase3_english, phase3_date
-- ============================================================================

-- STEP 0: CHECK CURRENT STATUS - What's missing
-- ============================================================================
SELECT 
    'CURRENT PHASE 2 STATUS' as status,
    COUNT(*) as total_students,
    SUM(CASE WHEN phase2_marathi IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN phase2_math IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN phase2_english IS NOT NULL THEN 1 ELSE 0 END) as with_english,
    SUM(CASE WHEN phase2_date IS NOT NULL THEN 1 ELSE 0 END) as with_date
FROM students
WHERE is_active = 1 AND udise_no = '27290503504';

-- Check Phase 3
SELECT 
    'CURRENT PHASE 3 STATUS' as status,
    COUNT(*) as total_students,
    SUM(CASE WHEN phase3_marathi IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN phase3_math IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN phase3_english IS NOT NULL THEN 1 ELSE 0 END) as with_english,
    SUM(CASE WHEN phase3_date IS NOT NULL THEN 1 ELSE 0 END) as with_date
FROM students
WHERE is_active = 1 AND udise_no = '27290503504';

-- ============================================================================
-- STEP 1: PREVIEW WHAT'S IN AUDIT TABLE FOR PHASE 2
-- ============================================================================
-- Shows what Phase 2 data exists in audit table
SELECT 
    'PHASE 2 IN AUDIT TABLE' as info,
    a.student_id,
    s.student_name,
    a.marathi_level,
    a.math_level,
    a.english_level,
    a.created_date
FROM student_phase_audit a
JOIN students s ON a.student_id = s.student_id
WHERE a.phase = 2 
AND s.udise_no = '27290503504'
ORDER BY a.student_id, a.created_date DESC;

-- ============================================================================
-- STEP 2: PREVIEW WHAT'S IN AUDIT TABLE FOR PHASE 3
-- ============================================================================
SELECT 
    'PHASE 3 IN AUDIT TABLE' as info,
    a.student_id,
    s.student_name,
    a.marathi_level,
    a.math_level,
    a.english_level,
    a.created_date
FROM student_phase_audit a
JOIN students s ON a.student_id = s.student_id
WHERE a.phase = 3 
AND s.udise_no = '27290503504'
ORDER BY a.student_id, a.created_date DESC;

-- ============================================================================
-- STEP 3: RESTORE PHASE 2 DATA FROM AUDIT TABLE
-- ============================================================================
-- Restores phase2_marathi, phase2_math, phase2_english, phase2_date
-- Uses the latest (MAX) audit record for each student in Phase 2

UPDATE students s
SET 
    s.phase2_marathi = (
        SELECT a.marathi_level 
        FROM student_phase_audit a 
        WHERE a.student_id = s.student_id AND a.phase = 2 
        ORDER BY a.created_date DESC 
        LIMIT 1
    ),
    s.phase2_math = (
        SELECT a.math_level 
        FROM student_phase_audit a 
        WHERE a.student_id = s.student_id AND a.phase = 2 
        ORDER BY a.created_date DESC 
        LIMIT 1
    ),
    s.phase2_english = (
        SELECT a.english_level 
        FROM student_phase_audit a 
        WHERE a.student_id = s.student_id AND a.phase = 2 
        ORDER BY a.created_date DESC 
        LIMIT 1
    ),
    s.phase2_date = (
        SELECT MAX(a.created_date) 
        FROM student_phase_audit a 
        WHERE a.student_id = s.student_id AND a.phase = 2
    )
WHERE s.is_active = 1
AND s.udise_no = '27290503504'
AND EXISTS (
    SELECT 1 FROM student_phase_audit a 
    WHERE a.student_id = s.student_id 
    AND a.phase = 2
);

SELECT CONCAT('✅ Phase 2 data restored: ', ROW_COUNT(), ' students') as result;

-- ============================================================================
-- STEP 4: RESTORE PHASE 3 DATA FROM AUDIT TABLE
-- ============================================================================
-- Restores phase3_marathi, phase3_math, phase3_english, phase3_date
-- Uses the latest (MAX) audit record for each student in Phase 3

UPDATE students s
SET 
    s.phase3_marathi = (
        SELECT a.marathi_level 
        FROM student_phase_audit a 
        WHERE a.student_id = s.student_id AND a.phase = 3 
        ORDER BY a.created_date DESC 
        LIMIT 1
    ),
    s.phase3_math = (
        SELECT a.math_level 
        FROM student_phase_audit a 
        WHERE a.student_id = s.student_id AND a.phase = 3 
        ORDER BY a.created_date DESC 
        LIMIT 1
    ),
    s.phase3_english = (
        SELECT a.english_level 
        FROM student_phase_audit a 
        WHERE a.student_id = s.student_id AND a.phase = 3 
        ORDER BY a.created_date DESC 
        LIMIT 1
    ),
    s.phase3_date = (
        SELECT MAX(a.created_date) 
        FROM student_phase_audit a 
        WHERE a.student_id = s.student_id AND a.phase = 3
    )
WHERE s.is_active = 1
AND s.udise_no = '27290503504'
AND EXISTS (
    SELECT 1 FROM student_phase_audit a 
    WHERE a.student_id = s.student_id 
    AND a.phase = 3
);

SELECT CONCAT('✅ Phase 3 data restored: ', ROW_COUNT(), ' students') as result;

-- ============================================================================
-- STEP 5: VERIFY PHASE 2 RESTORATION
-- ============================================================================
SELECT 
    'PHASE 2 AFTER RESTORE' as status,
    COUNT(*) as total_students,
    SUM(CASE WHEN phase2_marathi IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN phase2_math IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN phase2_english IS NOT NULL THEN 1 ELSE 0 END) as with_english,
    SUM(CASE WHEN phase2_date IS NOT NULL THEN 1 ELSE 0 END) as with_date,
    SUM(CASE WHEN phase2_marathi IS NOT NULL AND phase2_math IS NOT NULL AND phase2_english IS NOT NULL AND phase2_date IS NOT NULL THEN 1 ELSE 0 END) as fully_restored
FROM students
WHERE is_active = 1 AND udise_no = '27290503504';

-- ============================================================================
-- STEP 6: VERIFY PHASE 3 RESTORATION
-- ============================================================================
SELECT 
    'PHASE 3 AFTER RESTORE' as status,
    COUNT(*) as total_students,
    SUM(CASE WHEN phase3_marathi IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN phase3_math IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN phase3_english IS NOT NULL THEN 1 ELSE 0 END) as with_english,
    SUM(CASE WHEN phase3_date IS NOT NULL THEN 1 ELSE 0 END) as with_date,
    SUM(CASE WHEN phase3_marathi IS NOT NULL AND phase3_math IS NOT NULL AND phase3_english IS NOT NULL AND phase3_date IS NOT NULL THEN 1 ELSE 0 END) as fully_restored
FROM students
WHERE is_active = 1 AND udise_no = '27290503504';

-- ============================================================================
-- STEP 7: SHOW SAMPLE RESTORED RECORDS - PHASE 2
-- ============================================================================
SELECT 
    'PHASE 2 SAMPLES' as info,
    student_id,
    student_name,
    class,
    phase2_marathi,
    phase2_math,
    phase2_english,
    phase2_date
FROM students
WHERE is_active = 1
AND udise_no = '27290503504'
AND phase2_marathi IS NOT NULL
LIMIT 10;

-- ============================================================================
-- STEP 8: SHOW SAMPLE RESTORED RECORDS - PHASE 3
-- ============================================================================
SELECT 
    'PHASE 3 SAMPLES' as info,
    student_id,
    student_name,
    class,
    phase3_marathi,
    phase3_math,
    phase3_english,
    phase3_date
FROM students
WHERE is_active = 1
AND udise_no = '27290503504'
AND phase3_marathi IS NOT NULL
LIMIT 10;

-- ============================================================================
-- STEP 9: CALCULATE PERCENTAGES AFTER RESTORATION
-- ============================================================================

SELECT 
    s.udise_no,
    '2' as phase,
    COUNT(*) as total_valid_students,
    SUM(CASE WHEN s.phase2_date IS NOT NULL THEN 1 ELSE 0 END) as completed,
    ROUND(SUM(CASE WHEN s.phase2_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) as percentage_complete
FROM students s
WHERE s.is_active = 1
AND s.udise_no = '27290503504'
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
AND s.udise_no = '27290503504'
AND (s.fln_completed IS NULL OR s.fln_completed = FALSE)
AND s.phase3_marathi IS NOT NULL 
AND s.phase3_math IS NOT NULL 
AND s.phase3_english IS NOT NULL
GROUP BY s.udise_no

ORDER BY phase;

-- ============================================================================
-- END OF PHASE 2 & 3 DATA RESTORATION SCRIPT
-- ============================================================================
-- Summary of Restoration:
-- ✅ Phase 2 data (marathi, math, english levels) restored from audit table
-- ✅ Phase 2 dates restored from audit table
-- ✅ Phase 3 data (marathi, math, english levels) restored from audit table
-- ✅ Phase 3 dates restored from audit table
-- ✅ Percentages recalculated
-- 
-- Expected Results:
-- STEP 5: Phase 2 should show X students with all 3 subjects and dates
-- STEP 6: Phase 3 should show X students with all 3 subjects and dates
-- STEP 9: Both phases should show 100% completion (all with dates)
-- ============================================================================
