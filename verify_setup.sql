-- QUICK VERIFICATION SCRIPT
-- Run this to check if everything is set up correctly

-- 1. Does table exist?
SELECT 'teacher_assignments table exists' as status, COUNT(*) as rows
FROM user_tables 
WHERE table_name = 'TEACHER_ASSIGNMENTS';

-- 2. How many active assignments?
SELECT 'Active teacher assignments' as status, COUNT(*) as count
FROM teacher_assignments 
WHERE is_active = 1;

-- 3. Show sample data
SELECT 'Sample teacher assignment' as info,
       teacher_name, 
       class, 
       section, 
       subjects_assigned
FROM teacher_assignments 
WHERE is_active = 1 AND ROWNUM = 1;

-- 4. Check a student
SELECT 'Sample student' as info,
       student_pen,
       student_name,
       udise_no,
       class,
       section
FROM students 
WHERE ROWNUM = 1;

-- 5. Try to match them
SELECT 
    'Match test' as test,
    s.student_pen,
    s.udise_no as student_udise,
    s.class as student_class,
    s.section as student_section,
    ta.udise_code as teacher_udise,
    ta.class as teacher_class,
    ta.section as teacher_section,
    ta.teacher_name,
    CASE 
        WHEN ta.teacher_name IS NOT NULL THEN 'SUCCESS - MATCH FOUND!'
        ELSE 'FAIL - NO MATCH'
    END as result
FROM students s
LEFT JOIN teacher_assignments ta 
    ON s.udise_no = ta.udise_code 
    AND s.class = ta.class 
    AND s.section = ta.section
    AND ta.is_active = 1
WHERE s.ROWNUM = 1;
