SET @TID := (SELECT teacher_id FROM teachers WHERE udise_code = '27280104604' AND teacher_name LIKE '%MEKALE%KISHAN%' ORDER BY is_active DESC, teacher_id LIMIT 1);

SELECT @TID AS tid, teacher_id, teacher_name, mobile_number, CONCAT('[', subjects_taught, ']') AS subjects_taught_boxed, is_active
FROM teachers WHERE teacher_id = @TID;

SELECT assignment_id, CONCAT('[', class, ']') AS class_boxed, CONCAT('[', section, ']') AS section_boxed, CONCAT('[', subjects_assigned, ']') AS subjects_boxed, is_class_teacher, is_active
FROM teacher_assignments WHERE teacher_id = @TID;

SELECT CONCAT('[', class, ']') AS class_boxed, CONCAT('[', section, ']') AS section_boxed, COUNT(*) AS total, SUM(is_active) AS active
FROM students WHERE udise_no = '27280104604'
GROUP BY class, section ORDER BY class, section;

SELECT COUNT(*) AS viii_total_active,
       SUM(COALESCE(s.phase4_marathi,s.phase3_marathi,s.phase2_marathi,s.phase1_marathi) BETWEEN 1 AND 4) AS eligible_marathi_1_to_4,
       SUM(COALESCE(s.phase4_marathi,s.phase3_marathi,s.phase2_marathi,s.phase1_marathi) IS NULL) AS marathi_level_null,
       SUM(COALESCE(s.phase4_marathi,s.phase3_marathi,s.phase2_marathi,s.phase1_marathi) IN (5,6)) AS marathi_level_5_or_6
FROM students s WHERE s.udise_no = '27280104604' AND TRIM(s.class) = 'VIII' AND s.is_active = 1;

SELECT CONCAT('[', s.section, ']') AS section_boxed, COUNT(*) AS eligible_students
FROM students s
WHERE s.udise_no = '27280104604' AND TRIM(s.class) = 'VIII' AND s.is_active = 1
  AND COALESCE(s.phase4_marathi,s.phase3_marathi,s.phase2_marathi,s.phase1_marathi) BETWEEN 1 AND 4
GROUP BY s.section;

SELECT m.teacher_id, t.teacher_name, CONCAT('[', m.class, ']') AS class_boxed, CONCAT('[', m.section, ']') AS section_boxed, CONCAT('[', m.subject, ']') AS subject_boxed, m.is_active, COUNT(*) AS n
FROM teacher_student_mapping m
LEFT JOIN teachers t ON t.teacher_id = m.teacher_id
WHERE m.udise_code = '27280104604' AND TRIM(m.class) = 'VIII' AND m.subject LIKE '%मराठी%'
GROUP BY m.teacher_id, t.teacher_name, m.class, m.section, m.subject, m.is_active;

SELECT CONCAT('[', class, ']') AS class_boxed, CONCAT('[', section, ']') AS section_boxed, CONCAT('[', subject, ']') AS subject_boxed, is_active, COUNT(*) AS n
FROM teacher_student_mapping WHERE teacher_id = @TID
GROUP BY class, section, subject, is_active;

SELECT CONCAT('[', s.class, ']') AS class_boxed, CONCAT('[', s.section, ']') AS section_boxed, CONCAT('[', m.subject, ']') AS subject_boxed, COUNT(*) AS n
FROM teacher_student_mapping m
JOIN students s ON m.student_id = s.student_id
WHERE m.teacher_id = @TID AND m.is_active = 1 AND s.is_active = 1
  AND TRIM(m.class) COLLATE utf8mb4_unicode_ci = TRIM(s.class) COLLATE utf8mb4_unicode_ci
GROUP BY s.class, s.section, m.subject;

SELECT setting_key, setting_value FROM app_settings WHERE setting_key LIKE '%percent%' OR setting_key LIKE '%map%';
