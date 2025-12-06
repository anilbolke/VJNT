-- Check what the actual subject name is in the database
SELECT 
    teacher_name,
    subjects_assigned,
    CASE 
        WHEN subjects_assigned LIKE '%Math%' AND subjects_assigned NOT LIKE '%Mathematics%' THEN 'Uses: Math'
        WHEN subjects_assigned LIKE '%Mathematics%' THEN 'Uses: Mathematics'
        ELSE 'Other format'
    END as format_detected
FROM teacher_assignments
WHERE is_active = 1;

-- Check both variations
SELECT 'Checking Math format in subjects_assigned column:' as info FROM dual;

-- Show exact content with quotes
SELECT 
    teacher_name,
    '"' || subjects_assigned || '"' as subjects_with_quotes,
    LENGTH(subjects_assigned) as length
FROM teacher_assignments
WHERE is_active = 1;
