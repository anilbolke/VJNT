-- Test query to verify teacher assignments are set up correctly
-- Run this in Oracle SQL Developer or SQL*Plus

-- 1. Check if teacher_assignments table exists and has data
SELECT COUNT(*) as total_assignments 
FROM teacher_assignments 
WHERE is_active = 1;

-- 2. Show all active teacher assignments
SELECT 
    assignment_id,
    udise_code,
    teacher_name,
    class,
    section,
    subjects_assigned,
    is_active,
    created_date
FROM teacher_assignments
WHERE is_active = 1
ORDER BY udise_code, class, section;

-- 3. Check a specific student and their teacher assignments
-- Replace 'YOUR_STUDENT_PEN' with actual student PEN number
SELECT 
    s.student_pen,
    s.student_name,
    s.udise_no,
    s.class,
    s.section,
    ta.teacher_name,
    ta.subjects_assigned
FROM students s
LEFT JOIN teacher_assignments ta 
    ON s.udise_no = ta.udise_code 
    AND s.class = ta.class 
    AND s.section = ta.section
    AND ta.is_active = 1
WHERE s.student_pen = 'YOUR_STUDENT_PEN';

-- 4. Check if subjects_assigned format is correct
-- Should be comma-separated like 'Marathi,Math,English'
SELECT 
    teacher_name,
    subjects_assigned,
    CASE 
        WHEN subjects_assigned LIKE '%,%' THEN 'OK - Multiple subjects'
        WHEN subjects_assigned IS NOT NULL THEN 'OK - Single subject'
        ELSE 'ERROR - NULL subjects'
    END as format_status
FROM teacher_assignments
WHERE is_active = 1;

-- 5. Find students who have teacher assignments
SELECT 
    s.student_pen,
    s.student_name,
    s.class,
    s.section,
    ta.teacher_name,
    ta.subjects_assigned
FROM students s
INNER JOIN teacher_assignments ta 
    ON s.udise_no = ta.udise_code 
    AND s.class = ta.class 
    AND s.section = ta.section
    AND ta.is_active = 1
ORDER BY s.class, s.section, s.student_name;

-- 6. Check for any data mismatches
SELECT 
    'Students without teachers' as check_type,
    COUNT(*) as count
FROM students s
WHERE NOT EXISTS (
    SELECT 1 
    FROM teacher_assignments ta 
    WHERE ta.udise_code = s.udise_no 
    AND ta.class = s.class 
    AND ta.section = s.section
    AND ta.is_active = 1
)
UNION ALL
SELECT 
    'Teachers without students' as check_type,
    COUNT(*) as count
FROM teacher_assignments ta
WHERE ta.is_active = 1
AND NOT EXISTS (
    SELECT 1 
    FROM students s 
    WHERE s.udise_no = ta.udise_code 
    AND s.class = ta.class 
    AND s.section = ta.section
);

-- 7. Sample INSERT if you need to add test data
-- Uncomment and modify as needed
/*
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
    '12345678',           -- Your UDISE code
    1,                    -- Teacher ID
    'Mrs. Jane Smith',    -- Teacher Name
    '1',                  -- Class
    'A',                  -- Section
    'English,Marathi,Math',  -- IMPORTANT: Case-sensitive!
    1,                    -- Active
    SYSDATE
);
COMMIT;
*/
