SET NAMES utf8mb4;

SELECT s.student_id, s.student_name, s.section
FROM teacher_student_mapping m
JOIN students s ON s.student_id = m.student_id
WHERE m.udise_code = '27280104604'
  AND m.teacher_id = 1477
  AND m.is_active = 1
  AND TRIM(m.class) = 'VIII'
  AND TRIM(s.class) = 'VIII'
  AND TRIM(s.section) = 'A';

UPDATE teacher_student_mapping m
JOIN students s ON s.student_id = m.student_id
SET m.teacher_id = 1474,
    m.section = 'A'
WHERE m.udise_code = '27280104604'
  AND m.teacher_id = 1477
  AND m.is_active = 1
  AND TRIM(m.class) = 'VIII'
  AND TRIM(s.class) = 'VIII'
  AND TRIM(s.section) = 'A';

SELECT m.teacher_id,
       CASE m.teacher_id WHEN 1474 THEN 'MEKALE (A)' WHEN 1477 THEN 'RATHOD (B)' ELSE '?' END AS teacher,
       TRIM(s.section) AS section,
       COUNT(*) AS students
FROM teacher_student_mapping m
JOIN students s ON s.student_id = m.student_id
WHERE m.udise_code = '27280104604'
  AND m.is_active = 1
  AND m.teacher_id IN (1474, 1477)
  AND TRIM(m.class) = 'VIII'
  AND TRIM(s.class) = 'VIII'
GROUP BY m.teacher_id, TRIM(s.section)
ORDER BY m.teacher_id, section;
