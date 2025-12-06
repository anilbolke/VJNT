-- Quick Debug Query - Run this to check the issue

-- 1. Check if teacher_assignments table has data
SELECT 'Total Active Teachers' as check_name, COUNT(*) as count
FROM teacher_assignments 
WHERE is_active = 1;

-- 2. Show what's in teacher_assignments
SELECT * FROM teacher_assignments WHERE is_active = 1 AND ROWNUM <= 5;

-- 3. Pick a student and check if teacher exists
SELECT 
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
        WHEN ta.teacher_name IS NULL THEN 'NO MATCH'
        ELSE 'MATCH FOUND'
    END as match_status
FROM students s
LEFT JOIN teacher_assignments ta 
    ON s.udise_no = ta.udise_code 
    AND s.class = ta.class 
    AND s.section = ta.section
    AND ta.is_active = 1
WHERE ROWNUM = 1;

-- 4. Check for case/space issues in subjects_assigned
SELECT 
    teacher_name,
    subjects_assigned,
    LENGTH(subjects_assigned) as length,
    CASE 
        WHEN subjects_assigned LIKE 'English,Marathi,Math' THEN 'CORRECT'
        WHEN subjects_assigned LIKE '%English%' THEN 'HAS ENGLISH but wrong format'
        ELSE 'WRONG FORMAT'
    END as format_check
FROM teacher_assignments
WHERE is_active = 1;

-- 5. Check if UDISE/class/section have extra spaces
SELECT 
    udise_code,
    '"' || udise_code || '"' as udise_with_quotes,
    class,
    '"' || class || '"' as class_with_quotes,
    section,
    '"' || section || '"' as section_with_quotes
FROM teacher_assignments
WHERE is_active = 1 AND ROWNUM = 1;
