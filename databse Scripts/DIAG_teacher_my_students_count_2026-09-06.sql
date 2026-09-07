-- ============================================================================
-- DIAGNOSTIC: teacher-dashboard.jsp "माझे विद्यार्थी" card total + subject split
-- Date: 2026-09-06   Teacher under test: mobile_number = 9922856200
-- Read-only. Run in the admin SQL console (logged in as DATA_ADMIN).
-- To test another teacher, change the mobile number everywhere below.
-- ============================================================================


-- 0. Resolve the teacher --------------------------------------------------------
SELECT teacher_id, teacher_name, udise_code, subjects_taught
FROM teachers
WHERE mobile_number = '9922856200' AND is_active = 1;


-- 1. CARD TOTAL  (expected: 22) ------------------------------------------------
--    Distinct students across the 3 FLN subjects, with the exact filters
--    TeacherMyStudentsServlet.stuSql applies (mapping+student active, mapping
--    class/section still matching the student's CURRENT class/section).
SELECT COUNT(DISTINCT m.student_id) AS card_total
FROM teacher_student_mapping m
JOIN students s ON m.student_id = s.student_id
WHERE m.teacher_id = (SELECT teacher_id FROM teachers WHERE mobile_number = '9922856200' AND is_active = 1 LIMIT 1)
  AND m.is_active = 1 AND s.is_active = 1
  AND TRIM(m.class)   COLLATE utf8mb4_unicode_ci = TRIM(s.class)   COLLATE utf8mb4_unicode_ci
  AND TRIM(m.section) COLLATE utf8mb4_unicode_ci = TRIM(s.section) COLLATE utf8mb4_unicode_ci
  AND ( m.subject LIKE '%मराठी%'  OR m.subject LIKE '%marathi%'
     OR m.subject LIKE '%इंग्रजी%' OR m.subject LIKE '%इंग्लिश%' OR m.subject LIKE '%english%'
     OR m.subject LIKE '%गणित%'   OR m.subject LIKE '%math%' );


-- 2. PER-SUBJECT SPLIT  (expected: मराठी 15 · इंग्रजी 15 · गणित 15) ----------
--    Distinct students per FLN subject = the caption under the card.
SELECT
  CASE
    WHEN m.subject LIKE '%मराठी%'  OR m.subject LIKE '%marathi%' THEN 'मराठी'
    WHEN m.subject LIKE '%इंग्रजी%' OR m.subject LIKE '%इंग्लिश%' OR m.subject LIKE '%english%' THEN 'इंग्रजी'
    WHEN m.subject LIKE '%गणित%'   OR m.subject LIKE '%math%' THEN 'गणित'
    ELSE m.subject
  END AS subject_group,
  COUNT(DISTINCT m.student_id) AS students
FROM teacher_student_mapping m
JOIN students s ON m.student_id = s.student_id
WHERE m.teacher_id = (SELECT teacher_id FROM teachers WHERE mobile_number = '9922856200' AND is_active = 1 LIMIT 1)
  AND m.is_active = 1 AND s.is_active = 1
  AND TRIM(m.class)   COLLATE utf8mb4_unicode_ci = TRIM(s.class)   COLLATE utf8mb4_unicode_ci
  AND TRIM(m.section) COLLATE utf8mb4_unicode_ci = TRIM(s.section) COLLATE utf8mb4_unicode_ci
GROUP BY subject_group
ORDER BY students DESC;


-- 3. OVERLAP CHECK  —  why 15 + 15 + 15 = 45 but distinct = 22 ----------------
--    Number of the 3 subjects each student is mapped to.
--    Expect:  SUM(subj_count * num_students) = 45  and  SUM(num_students) = 22.
SELECT subj_count, COUNT(*) AS num_students
FROM (
  SELECT m.student_id,
         COUNT(DISTINCT CASE
             WHEN m.subject LIKE '%मराठी%'  OR m.subject LIKE '%marathi%' THEN 'M'
             WHEN m.subject LIKE '%इंग्रजी%' OR m.subject LIKE '%इंग्लिश%' OR m.subject LIKE '%english%' THEN 'E'
             WHEN m.subject LIKE '%गणित%'   OR m.subject LIKE '%math%' THEN 'T'
         END) AS subj_count
  FROM teacher_student_mapping m
  JOIN students s ON m.student_id = s.student_id
  WHERE m.teacher_id = (SELECT teacher_id FROM teachers WHERE mobile_number = '9922856200' AND is_active = 1 LIMIT 1)
    AND m.is_active = 1 AND s.is_active = 1
    AND TRIM(m.class)   COLLATE utf8mb4_unicode_ci = TRIM(s.class)   COLLATE utf8mb4_unicode_ci
    AND TRIM(m.section) COLLATE utf8mb4_unicode_ci = TRIM(s.section) COLLATE utf8mb4_unicode_ci
    AND ( m.subject LIKE '%मराठी%'  OR m.subject LIKE '%marathi%'
       OR m.subject LIKE '%इंग्रजी%' OR m.subject LIKE '%इंग्लिश%' OR m.subject LIKE '%english%'
       OR m.subject LIKE '%गणित%'   OR m.subject LIKE '%math%' )
  GROUP BY m.student_id
) x
GROUP BY subj_count
ORDER BY subj_count;


-- 4. SANITY-CHECK THE "15" ---------------------------------------------------
--    mapRandomStudents target per subject = CEIL(active students of the
--    class-section * map_percent / 100), min 1.  So 15 should equal that.
SELECT s.class, s.section, COUNT(*) AS active_students
FROM students s
WHERE s.udise_no = (SELECT udise_code FROM teachers WHERE mobile_number = '9922856200' AND is_active = 1 LIMIT 1)
  AND s.is_active = 1
GROUP BY s.class, s.section
ORDER BY s.class, s.section;

SELECT setting_value AS map_percent
FROM app_settings
WHERE setting_key = 'teacher_student_map_percent';


-- 5. RAW DUMP  —  every FLN mapping row for this teacher ---------------------
SELECT m.subject,
       m.class   AS map_class,   m.section AS map_section,
       s.class   AS stu_class,   s.section AS stu_section, s.is_active AS stu_active,
       m.student_id, s.student_name, s.student_pen
FROM teacher_student_mapping m
JOIN students s ON m.student_id = s.student_id
WHERE m.teacher_id = (SELECT teacher_id FROM teachers WHERE mobile_number = '9922856200' AND is_active = 1 LIMIT 1)
  AND m.is_active = 1
ORDER BY m.subject, s.student_name;


-- 6. DISTRICT PAGE CROSS-CHECK (district-teacher-videos.jsp) -----------------
--    student_count -> the "N students" shown in the list (expect 22)
--    pair_count    -> phase-slot basis for upload/approval/approved (expect 45)
SELECT COUNT(DISTINCT m.student_id) AS student_count,
       COUNT(*)                    AS pair_count
FROM teacher_student_mapping m
JOIN students st ON st.student_id = m.student_id AND st.is_active = 1
  AND TRIM(m.class)   COLLATE utf8mb4_unicode_ci = TRIM(st.class)   COLLATE utf8mb4_unicode_ci
  AND TRIM(m.section) COLLATE utf8mb4_unicode_ci = TRIM(st.section) COLLATE utf8mb4_unicode_ci
WHERE m.teacher_id = (SELECT teacher_id FROM teachers WHERE mobile_number = '9922856200' AND is_active = 1 LIMIT 1)
  AND m.is_active = 1
  AND ( m.subject LIKE '%मराठी%'  OR m.subject LIKE '%marathi%'
     OR m.subject LIKE '%इंग्रजी%' OR m.subject LIKE '%इंग्लिश%' OR m.subject LIKE '%english%'
     OR m.subject LIKE '%गणित%'   OR m.subject LIKE '%math%' );
