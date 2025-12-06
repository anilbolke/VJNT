-- COMPLETE DIAGNOSTIC FOR MATH TEACHER ISSUE
-- Run ALL queries below and share the results

-- ============================================================================
-- QUERY 1: Check if teacher_assignments table has any data
-- ============================================================================
SELECT 'Query 1: Total active teachers' as query_name, COUNT(*) as count
FROM teacher_assignments 
WHERE is_active = 1;

-- ============================================================================
-- QUERY 2: Show ALL teacher assignments with exact format
-- ============================================================================
SELECT 
    'Query 2: Teacher assignments' as query_name,
    assignment_id,
    udise_code,
    teacher_name,
    class,
    section,
    subjects_assigned,
    LENGTH(subjects_assigned) as length,
    is_active
FROM teacher_assignments
WHERE is_active = 1
ORDER BY assignment_id;

-- ============================================================================
-- QUERY 3: Check exact format of subjects_assigned (with quotes to see spaces)
-- ============================================================================
SELECT 
    'Query 3: Format check' as query_name,
    teacher_name,
    '"' || subjects_assigned || '"' as subjects_with_quotes,
    CASE 
        WHEN subjects_assigned = 'English,Marathi,Math' THEN 'PERFECT!'
        WHEN subjects_assigned LIKE '%Math%' THEN 'Has Math but wrong format'
        WHEN subjects_assigned LIKE '%Mathematics%' THEN 'ERROR: Uses Mathematics'
        ELSE 'ERROR: No Math at all'
    END as format_status
FROM teacher_assignments
WHERE is_active = 1;

-- ============================================================================
-- QUERY 4: Pick ONE student and show their class/section
-- ============================================================================
SELECT 
    'Query 4: Sample student' as query_name,
    student_pen,
    student_name,
    udise_no,
    class,
    section
FROM students 
WHERE ROWNUM = 1;

-- ============================================================================
-- QUERY 5: Try to JOIN student with teacher (THIS IS THE KEY TEST!)
-- ============================================================================
SELECT 
    'Query 5: MATCH TEST' as query_name,
    s.student_pen,
    s.student_name,
    s.udise_no as student_udise,
    s.class as student_class,
    s.section as student_section,
    ta.udise_code as teacher_udise,
    ta.class as teacher_class,
    ta.section as teacher_section,
    ta.teacher_name,
    ta.subjects_assigned,
    CASE 
        WHEN ta.teacher_name IS NOT NULL THEN 'SUCCESS - MATCH FOUND!'
        ELSE 'FAIL - NO MATCH (Check UDISE/class/section)'
    END as match_status
FROM students s
LEFT JOIN teacher_assignments ta 
    ON s.udise_no = ta.udise_code 
    AND s.class = ta.class 
    AND s.section = ta.section
    AND ta.is_active = 1
WHERE s.ROWNUM = 1;

-- ============================================================================
-- QUERY 6: Check for exact match issues (spaces, case)
-- ============================================================================
SELECT 
    'Query 6: Data quality' as query_name,
    teacher_name,
    'UDISE: [' || udise_code || ']' as udise_check,
    'Class: [' || class || ']' as class_check,
    'Section: [' || section || ']' as section_check,
    LENGTH(TRIM(udise_code)) as udise_length,
    LENGTH(TRIM(class)) as class_length,
    LENGTH(TRIM(section)) as section_length
FROM teacher_assignments
WHERE is_active = 1;

-- ============================================================================
-- QUERY 7: Check what subjects will be parsed out
-- ============================================================================
SELECT 
    'Query 7: Subject parsing' as query_name,
    teacher_name,
    subjects_assigned,
    REGEXP_SUBSTR(subjects_assigned, '[^,]+', 1, 1) as subject_1,
    REGEXP_SUBSTR(subjects_assigned, '[^,]+', 1, 2) as subject_2,
    REGEXP_SUBSTR(subjects_assigned, '[^,]+', 1, 3) as subject_3
FROM teacher_assignments
WHERE is_active = 1;

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- Query 1: Should show count > 0
-- Query 2: Should show your teacher records
-- Query 3: Should show "PERFECT!" status
-- Query 4: Should show a student
-- Query 5: Should show "SUCCESS - MATCH FOUND!"
-- Query 6: Lengths should match (no extra spaces)
-- Query 7: Should show "English", "Marathi", "Math" separately

-- ============================================================================
-- IF QUERY 5 SHOWS "FAIL - NO MATCH":
-- ============================================================================
-- The problem is UDISE/class/section don't match!
-- Compare student_udise vs teacher_udise
-- Compare student_class vs teacher_class  
-- Compare student_section vs teacher_section
-- They must be EXACTLY the same (case-sensitive, no spaces)

-- ============================================================================
-- QUICK FIX IF FORMAT IS WRONG:
-- ============================================================================
/*
UPDATE teacher_assignments
SET subjects_assigned = 'English,Marathi,Math'
WHERE is_active = 1;
COMMIT;
*/

-- ============================================================================
-- QUICK FIX IF NO TEACHER EXISTS:
-- ============================================================================
/*
-- First get a student's details from Query 4 above, then:
INSERT INTO teacher_assignments (
    assignment_id,
    udise_code,
    teacher_id,
    teacher_name,
    class,
    section,
    subjects_assigned,
    is_active,
    created_date
) VALUES (
    (SELECT NVL(MAX(assignment_id), 0) + 1 FROM teacher_assignments),
    'PASTE_UDISE_FROM_QUERY_4',
    1,
    'Mrs. Test Teacher',
    'PASTE_CLASS_FROM_QUERY_4',
    'PASTE_SECTION_FROM_QUERY_4',
    'English,Marathi,Math',
    1,
    SYSDATE
);
COMMIT;
*/
