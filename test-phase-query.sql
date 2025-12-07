-- Test query to check phase data
-- Replace 'YOUR_DISTRICT_NAME' with your actual district name

SELECT 
    s.udise_no, 
    s.school_name,
    COUNT(DISTINCT st.student_id) as total_students,
    -- Phase 1
    COUNT(DISTINCT CASE WHEN st.phase1_date IS NOT NULL THEN st.student_id END) as phase1_completed,
    MAX(CASE WHEN pa.phase_number = 1 THEN pa.approval_status END) as phase1_approval_status,
    -- Phase 2
    COUNT(DISTINCT CASE WHEN st.phase2_date IS NOT NULL THEN st.student_id END) as phase2_completed,
    MAX(CASE WHEN pa.phase_number = 2 THEN pa.approval_status END) as phase2_approval_status,
    -- Phase 3
    COUNT(DISTINCT CASE WHEN st.phase3_date IS NOT NULL THEN st.student_id END) as phase3_completed,
    MAX(CASE WHEN pa.phase_number = 3 THEN pa.approval_status END) as phase3_approval_status,
    -- Phase 4
    COUNT(DISTINCT CASE WHEN st.phase4_date IS NOT NULL THEN st.student_id END) as phase4_completed,
    MAX(CASE WHEN pa.phase_number = 4 THEN pa.approval_status END) as phase4_approval_status
FROM schools s 
LEFT JOIN school_contacts sc_hm ON s.udise_no = sc_hm.udise_no AND sc_hm.contact_type = 'Head Master' 
LEFT JOIN phase_approvals pa ON s.udise_no = pa.udise_no 
LEFT JOIN students st ON s.udise_no = st.udise_no 
WHERE s.district_name = 'YOUR_DISTRICT_NAME'  -- Replace with your district
GROUP BY s.udise_no, s.school_name
ORDER BY s.school_name;

-- This will show you:
-- 1. All schools in your district
-- 2. How many students have completed each phase (phase1_completed, phase2_completed, etc.)
-- 3. The approval status (if submitted)
-- 
-- If you see schools with phase1_completed > 0 but phase1_approval_status is NULL,
-- those are schools that completed the phase but haven't submitted for approval.
