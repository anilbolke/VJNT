-- ============================================================================
-- RESTORE PHASE 1, 2 AND 3 DATA FROM AUDIT TABLE
-- FOR ALL UDISE NUMBERS
-- ============================================================================
-- This script restores actual phase data (marathi, math, english levels)
-- from the student_phase_audit table for Phase 1, Phase 2 and Phase 3
-- APPLIES TO ALL SCHOOLS SIMULTANEOUSLY
-- 
-- Purpose:
-- - Recover lost Phase 1 data: phase1_marathi, phase1_math, phase1_english, phase1_date
-- - Recover lost Phase 2 data: phase2_marathi, phase2_math, phase2_english, phase2_date
-- - Recover lost Phase 3 data: phase3_marathi, phase3_math, phase3_english, phase3_date
-- - For ALL affected UDISE numbers at once
-- ============================================================================

-- STEP 0: CHECK CURRENT STATUS BY UDISE - Phase 1
-- ============================================================================
SELECT 
    s.udise_no,
    'PHASE 1' as phase,
    COUNT(*) as total_students,
    SUM(CASE WHEN phase1_marathi IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN phase1_math IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN phase1_english IS NOT NULL THEN 1 ELSE 0 END) as with_english,
    SUM(CASE WHEN phase1_date IS NOT NULL THEN 1 ELSE 0 END) as with_date
FROM students s
WHERE s.is_active = 1
GROUP BY s.udise_no
HAVING SUM(CASE WHEN phase1_marathi IS NOT NULL OR phase1_math IS NOT NULL OR phase1_english IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY s.udise_no;

-- Check Phase 2
SELECT 
    s.udise_no,
    'PHASE 2' as phase,
    COUNT(*) as total_students,
    SUM(CASE WHEN phase2_marathi IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN phase2_math IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN phase2_english IS NOT NULL THEN 1 ELSE 0 END) as with_english,
    SUM(CASE WHEN phase2_date IS NOT NULL THEN 1 ELSE 0 END) as with_date
FROM students s
WHERE s.is_active = 1
GROUP BY s.udise_no
HAVING SUM(CASE WHEN phase2_marathi IS NOT NULL OR phase2_math IS NOT NULL OR phase2_english IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY s.udise_no;

-- Check Phase 3
SELECT 
    s.udise_no,
    'PHASE 3' as phase,
    COUNT(*) as total_students,
    SUM(CASE WHEN phase3_marathi IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN phase3_math IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN phase3_english IS NOT NULL THEN 1 ELSE 0 END) as with_english,
    SUM(CASE WHEN phase3_date IS NOT NULL THEN 1 ELSE 0 END) as with_date
FROM students s
WHERE s.is_active = 1
GROUP BY s.udise_no
HAVING SUM(CASE WHEN phase3_marathi IS NOT NULL OR phase3_math IS NOT NULL OR phase3_english IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY s.udise_no;

-- ============================================================================
-- STEP 1: COUNT WHAT'S IN AUDIT TABLE - Phase 1
-- ============================================================================
SELECT 
    s.udise_no,
    'PHASE 1 IN AUDIT' as info,
    COUNT(DISTINCT a.student_id) as students_in_audit,
    SUM(CASE WHEN a.marathi_level IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN a.math_level IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN a.english_level IS NOT NULL THEN 1 ELSE 0 END) as with_english
FROM student_phase_audit a
JOIN students s ON a.student_id = s.student_id
WHERE a.phase = 1 
AND s.is_active = 1
GROUP BY s.udise_no
ORDER BY s.udise_no;

-- STEP 2: COUNT WHAT'S IN AUDIT TABLE - Phase 2
SELECT 
    s.udise_no,
    'PHASE 2 IN AUDIT' as info,
    COUNT(DISTINCT a.student_id) as students_in_audit,
    SUM(CASE WHEN a.marathi_level IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN a.math_level IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN a.english_level IS NOT NULL THEN 1 ELSE 0 END) as with_english
FROM student_phase_audit a
JOIN students s ON a.student_id = s.student_id
WHERE a.phase = 2 
AND s.is_active = 1
GROUP BY s.udise_no
ORDER BY s.udise_no;

-- STEP 3: COUNT WHAT'S IN AUDIT TABLE - Phase 3
SELECT 
    s.udise_no,
    'PHASE 3 IN AUDIT' as info,
    COUNT(DISTINCT a.student_id) as students_in_audit,
    SUM(CASE WHEN a.marathi_level IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN a.math_level IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN a.english_level IS NOT NULL THEN 1 ELSE 0 END) as with_english
FROM student_phase_audit a
JOIN students s ON a.student_id = s.student_id
WHERE a.phase = 3 
AND s.is_active = 1
GROUP BY s.udise_no
ORDER BY s.udise_no;

-- ============================================================================
-- STEP 4: RESTORE PHASE 1 DATA FROM AUDIT TABLE - ALL UDISE
-- ============================================================================
-- Restores phase1_marathi, phase1_math, phase1_english, phase1_date
-- Uses the latest (MAX) audit record for each student in Phase 1
-- APPLIES TO ALL UDISE NUMBERS

UPDATE students s
SET 
    s.phase1_marathi = (
        SELECT a.marathi_level 
        FROM student_phase_audit a 
        WHERE a.student_id = s.student_id AND a.phase = 1 
        ORDER BY a.created_date DESC 
        LIMIT 1
    ),
    s.phase1_math = (
        SELECT a.math_level 
        FROM student_phase_audit a 
        WHERE a.student_id = s.student_id AND a.phase = 1 
        ORDER BY a.created_date DESC 
        LIMIT 1
    ),
    s.phase1_english = (
        SELECT a.english_level 
        FROM student_phase_audit a 
        WHERE a.student_id = s.student_id AND a.phase = 1 
        ORDER BY a.created_date DESC 
        LIMIT 1
    ),
    s.phase1_date = (
        SELECT MAX(a.created_date) 
        FROM student_phase_audit a 
        WHERE a.student_id = s.student_id AND a.phase = 1
    )
WHERE s.is_active = 1
AND EXISTS (
    SELECT 1 FROM student_phase_audit a 
    WHERE a.student_id = s.student_id 
    AND a.phase = 1
);

SELECT CONCAT('✅ Phase 1 data restored for ALL UDISE: ', ROW_COUNT(), ' students total') as result;

-- ============================================================================
-- STEP 5: RESTORE PHASE 2 DATA FROM AUDIT TABLE - ALL UDISE
-- ============================================================================
-- Restores phase2_marathi, phase2_math, phase2_english, phase2_date
-- Uses the latest (MAX) audit record for each student in Phase 2
-- APPLIES TO ALL UDISE NUMBERS

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
AND EXISTS (
    SELECT 1 FROM student_phase_audit a 
    WHERE a.student_id = s.student_id 
    AND a.phase = 2
);

SELECT CONCAT('✅ Phase 2 data restored for ALL UDISE: ', ROW_COUNT(), ' students total') as result;

-- ============================================================================
-- STEP 6: RESTORE PHASE 3 DATA FROM AUDIT TABLE - ALL UDISE
-- ============================================================================
-- Restores phase3_marathi, phase3_math, phase3_english, phase3_date
-- Uses the latest (MAX) audit record for each student in Phase 3
-- APPLIES TO ALL UDISE NUMBERS

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
AND EXISTS (
    SELECT 1 FROM student_phase_audit a 
    WHERE a.student_id = s.student_id 
    AND a.phase = 3
);

SELECT CONCAT('✅ Phase 3 data restored for ALL UDISE: ', ROW_COUNT(), ' students total') as result;

-- ============================================================================
-- STEP 7: VERIFY PHASE 1 RESTORATION BY UDISE
-- ============================================================================
SELECT 
    s.udise_no,
    'PHASE 1 AFTER' as phase,
    COUNT(*) as total_students,
    SUM(CASE WHEN s.phase1_marathi IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN s.phase1_math IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN s.phase1_english IS NOT NULL THEN 1 ELSE 0 END) as with_english,
    SUM(CASE WHEN s.phase1_date IS NOT NULL THEN 1 ELSE 0 END) as with_date,
    SUM(CASE WHEN s.phase1_marathi IS NOT NULL AND s.phase1_math IS NOT NULL AND s.phase1_english IS NOT NULL AND s.phase1_date IS NOT NULL THEN 1 ELSE 0 END) as fully_restored
FROM students s
WHERE s.is_active = 1
GROUP BY s.udise_no
HAVING SUM(CASE WHEN s.phase1_marathi IS NOT NULL OR s.phase1_math IS NOT NULL OR s.phase1_english IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY s.udise_no;

-- ============================================================================
-- STEP 8: VERIFY PHASE 2 RESTORATION BY UDISE
-- ============================================================================
SELECT 
    s.udise_no,
    'PHASE 2 AFTER' as phase,
    COUNT(*) as total_students,
    SUM(CASE WHEN s.phase2_marathi IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN s.phase2_math IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN s.phase2_english IS NOT NULL THEN 1 ELSE 0 END) as with_english,
    SUM(CASE WHEN s.phase2_date IS NOT NULL THEN 1 ELSE 0 END) as with_date,
    SUM(CASE WHEN s.phase2_marathi IS NOT NULL AND s.phase2_math IS NOT NULL AND s.phase2_english IS NOT NULL AND s.phase2_date IS NOT NULL THEN 1 ELSE 0 END) as fully_restored
FROM students s
WHERE s.is_active = 1
GROUP BY s.udise_no
HAVING SUM(CASE WHEN s.phase2_marathi IS NOT NULL OR s.phase2_math IS NOT NULL OR s.phase2_english IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY s.udise_no;

-- ============================================================================
-- STEP 9: VERIFY PHASE 3 RESTORATION BY UDISE
-- ============================================================================
SELECT 
    s.udise_no,
    'PHASE 3 AFTER' as phase,
    COUNT(*) as total_students,
    SUM(CASE WHEN s.phase3_marathi IS NOT NULL THEN 1 ELSE 0 END) as with_marathi,
    SUM(CASE WHEN s.phase3_math IS NOT NULL THEN 1 ELSE 0 END) as with_math,
    SUM(CASE WHEN s.phase3_english IS NOT NULL THEN 1 ELSE 0 END) as with_english,
    SUM(CASE WHEN s.phase3_date IS NOT NULL THEN 1 ELSE 0 END) as with_date,
    SUM(CASE WHEN s.phase3_marathi IS NOT NULL AND s.phase3_math IS NOT NULL AND s.phase3_english IS NOT NULL AND s.phase3_date IS NOT NULL THEN 1 ELSE 0 END) as fully_restored
FROM students s
WHERE s.is_active = 1
GROUP BY s.udise_no
HAVING SUM(CASE WHEN s.phase3_marathi IS NOT NULL OR s.phase3_math IS NOT NULL OR s.phase3_english IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY s.udise_no;

-- ============================================================================
-- STEP 10: CALCULATE PHASE 1 PERCENTAGES BY UDISE
-- ============================================================================
SELECT 
    s.udise_no,
    'PHASE 1 %' as phase,
    SUM(CASE WHEN s.phase1_marathi IS NOT NULL AND s.phase1_math IS NOT NULL AND s.phase1_english IS NOT NULL THEN 1 ELSE 0 END) as valid_students,
    SUM(CASE WHEN s.phase1_date IS NOT NULL AND s.phase1_marathi IS NOT NULL AND s.phase1_math IS NOT NULL AND s.phase1_english IS NOT NULL THEN 1 ELSE 0 END) as completed,
    ROUND(SUM(CASE WHEN s.phase1_date IS NOT NULL AND s.phase1_marathi IS NOT NULL AND s.phase1_math IS NOT NULL AND s.phase1_english IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / SUM(CASE WHEN s.phase1_marathi IS NOT NULL AND s.phase1_math IS NOT NULL AND s.phase1_english IS NOT NULL THEN 1 ELSE 0 END)) as percentage
FROM students s
WHERE s.is_active = 1
AND (s.fln_completed IS NULL OR s.fln_completed = FALSE)
GROUP BY s.udise_no
HAVING SUM(CASE WHEN s.phase1_marathi IS NOT NULL AND s.phase1_math IS NOT NULL AND s.phase1_english IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY s.udise_no;

-- ============================================================================
-- STEP 11: CALCULATE PHASE 2 PERCENTAGES BY UDISE
-- ============================================================================
SELECT 
    s.udise_no,
    'PHASE 2 %' as phase,
    SUM(CASE WHEN s.phase2_marathi IS NOT NULL AND s.phase2_math IS NOT NULL AND s.phase2_english IS NOT NULL THEN 1 ELSE 0 END) as valid_students,
    SUM(CASE WHEN s.phase2_date IS NOT NULL AND s.phase2_marathi IS NOT NULL AND s.phase2_math IS NOT NULL AND s.phase2_english IS NOT NULL THEN 1 ELSE 0 END) as completed,
    ROUND(SUM(CASE WHEN s.phase2_date IS NOT NULL AND s.phase2_marathi IS NOT NULL AND s.phase2_math IS NOT NULL AND s.phase2_english IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / SUM(CASE WHEN s.phase2_marathi IS NOT NULL AND s.phase2_math IS NOT NULL AND s.phase2_english IS NOT NULL THEN 1 ELSE 0 END)) as percentage
FROM students s
WHERE s.is_active = 1
AND (s.fln_completed IS NULL OR s.fln_completed = FALSE)
GROUP BY s.udise_no
HAVING SUM(CASE WHEN s.phase2_marathi IS NOT NULL AND s.phase2_math IS NOT NULL AND s.phase2_english IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY s.udise_no;

-- ============================================================================
-- STEP 12: CALCULATE PHASE 3 PERCENTAGES BY UDISE
-- ============================================================================
SELECT 
    s.udise_no,
    'PHASE 3 %' as phase,
    SUM(CASE WHEN s.phase3_marathi IS NOT NULL AND s.phase3_math IS NOT NULL AND s.phase3_english IS NOT NULL THEN 1 ELSE 0 END) as valid_students,
    SUM(CASE WHEN s.phase3_date IS NOT NULL AND s.phase3_marathi IS NOT NULL AND s.phase3_math IS NOT NULL AND s.phase3_english IS NOT NULL THEN 1 ELSE 0 END) as completed,
    ROUND(SUM(CASE WHEN s.phase3_date IS NOT NULL AND s.phase3_marathi IS NOT NULL AND s.phase3_math IS NOT NULL AND s.phase3_english IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / SUM(CASE WHEN s.phase3_marathi IS NOT NULL AND s.phase3_math IS NOT NULL AND s.phase3_english IS NOT NULL THEN 1 ELSE 0 END)) as percentage
FROM students s
WHERE s.is_active = 1
AND (s.fln_completed IS NULL OR s.fln_completed = FALSE)
GROUP BY s.udise_no
HAVING SUM(CASE WHEN s.phase3_marathi IS NOT NULL AND s.phase3_math IS NOT NULL AND s.phase3_english IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY s.udise_no;

-- ============================================================================
-- STEP 13: SHOW SAMPLE RESTORED RECORDS - Phase 1, 2, 3
-- ============================================================================
SELECT 
    'PHASE 1-3 SAMPLES' as info,
    student_id,
    student_name,
    udise_no,
    class,
    phase1_marathi, phase1_math, phase1_english, phase1_date,
    phase2_marathi, phase2_math, phase2_english, phase2_date,
    phase3_marathi, phase3_math, phase3_english, phase3_date
FROM students
WHERE is_active = 1
AND (phase1_marathi IS NOT NULL OR phase2_marathi IS NOT NULL OR phase3_marathi IS NOT NULL)
ORDER BY udise_no, student_id
LIMIT 30;

-- ============================================================================
-- STEP 14: FINAL SUMMARY - RESTORATION SUCCESS BY UDISE (ALL PHASES)
-- ============================================================================
-- Complete before/after comparison for all phases

SELECT 
    s.udise_no,
    COUNT(*) as total_students,
    SUM(CASE WHEN s.phase1_marathi IS NOT NULL AND s.phase1_math IS NOT NULL AND s.phase1_english IS NOT NULL THEN 1 ELSE 0 END) as phase1_valid,
    SUM(CASE WHEN s.phase1_date IS NOT NULL THEN 1 ELSE 0 END) as phase1_with_date,
    SUM(CASE WHEN s.phase2_marathi IS NOT NULL AND s.phase2_math IS NOT NULL AND s.phase2_english IS NOT NULL THEN 1 ELSE 0 END) as phase2_valid,
    SUM(CASE WHEN s.phase2_date IS NOT NULL THEN 1 ELSE 0 END) as phase2_with_date,
    SUM(CASE WHEN s.phase3_marathi IS NOT NULL AND s.phase3_math IS NOT NULL AND s.phase3_english IS NOT NULL THEN 1 ELSE 0 END) as phase3_valid,
    SUM(CASE WHEN s.phase3_date IS NOT NULL THEN 1 ELSE 0 END) as phase3_with_date,
    ROUND(SUM(CASE WHEN s.phase1_date IS NOT NULL AND s.phase1_marathi IS NOT NULL AND s.phase1_math IS NOT NULL AND s.phase1_english IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no=s.udise_no AND phase1_marathi IS NOT NULL AND phase1_math IS NOT NULL AND phase1_english IS NOT NULL)) as phase1_percentage,
    ROUND(SUM(CASE WHEN s.phase2_date IS NOT NULL AND s.phase2_marathi IS NOT NULL AND s.phase2_math IS NOT NULL AND s.phase2_english IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no=s.udise_no AND phase2_marathi IS NOT NULL AND phase2_math IS NOT NULL AND phase2_english IS NOT NULL)) as phase2_percentage,
    ROUND(SUM(CASE WHEN s.phase3_date IS NOT NULL AND s.phase3_marathi IS NOT NULL AND s.phase3_math IS NOT NULL AND s.phase3_english IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / (SELECT COUNT(*) FROM students WHERE is_active=1 AND udise_no=s.udise_no AND phase3_marathi IS NOT NULL AND phase3_math IS NOT NULL AND phase3_english IS NOT NULL)) as phase3_percentage
FROM students s
WHERE s.is_active = 1
GROUP BY s.udise_no
HAVING SUM(CASE WHEN s.phase1_marathi IS NOT NULL OR s.phase2_marathi IS NOT NULL OR s.phase3_marathi IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY s.udise_no;

-- ============================================================================
-- END OF PHASE 1, 2 & 3 DATA RESTORATION SCRIPT FOR ALL UDISE
-- ============================================================================
-- Summary of Restoration:
-- ✅ Phase 1 data (marathi, math, english levels) restored from audit table
-- ✅ Phase 1 dates restored from audit table
-- ✅ Phase 2 data (marathi, math, english levels) restored from audit table
-- ✅ Phase 2 dates restored from audit table
-- ✅ Phase 3 data (marathi, math, english levels) restored from audit table
-- ✅ Phase 3 dates restored from audit table
-- ✅ Applied to ALL affected UDISE NUMBERS SIMULTANEOUSLY
-- ✅ Percentages recalculated for each UDISE for all phases
-- 
-- Expected Results:
-- STEP 7-9: Each school should show X students with all 3 subjects and dates
-- STEP 10-12: All phases should show 100% completion (all with dates)
-- STEP 13: Sample records showing restored data
-- STEP 14: Summary showing all schools and phases updated successfully
-- ============================================================================
