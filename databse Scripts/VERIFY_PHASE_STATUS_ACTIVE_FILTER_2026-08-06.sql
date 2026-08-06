-- =============================================================================
-- Verify the is_active filter on district phase status
-- Date: 2026-08-06
--
-- READ ONLY. No writes anywhere in this file.
--
-- WHY
--   phase-status.jsp (district login) kept showing phases as already completed
--   after promotion. PhaseApprovalDAO.getPhaseStatusByDistrict() joined students
--   with no is_active filter, so last year's graduates were still counted:
--   promotion sets is_active = 0 on the graduating class but never clears their
--   phase1_date..phase4_date, so those dates stay populated forever.
--
--   phase_approvals IS cleared by promotion, so approval_status was already NULL.
--   It was the completion COUNT that kept the phase looking done.
--
-- HOW TO READ THE RESULTS
--   Section 1 is the headline: any school with stale_* > 0 was being reported
--   wrongly. Section 2 shows the same thing per school with old vs new values
--   side by side. Section 3 confirms the phases really are reset for the students
--   who matter (the active ones).
-- =============================================================================

SET @district = 'REPLACE_WITH_DISTRICT_NAME';   -- <<< set this first


-- -----------------------------------------------------------------------------
-- 1. Headline: how many inactive students were inflating the counts
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*)                                                          AS inactive_students,
    SUM(phase1_date IS NOT NULL)                                      AS stale_phase1,
    SUM(phase2_date IS NOT NULL)                                      AS stale_phase2,
    SUM(phase3_date IS NOT NULL)                                      AS stale_phase3,
    SUM(phase4_date IS NOT NULL)                                      AS stale_phase4
FROM students
WHERE is_active = 0
  AND district COLLATE utf8mb4_unicode_ci = @district COLLATE utf8mb4_unicode_ci;


-- -----------------------------------------------------------------------------
-- 2. Per school: what the page showed BEFORE vs what it shows AFTER
--
--    old_* counts every student row (the bug).
--    new_* counts only active students (the fix).
--    A non-zero difference is exactly what the district was seeing wrongly.
-- -----------------------------------------------------------------------------
SELECT
    s.udise_no,
    s.school_name,
    COUNT(DISTINCT st.student_id)                                             AS old_total,
    COUNT(DISTINCT CASE WHEN st.is_active = 1 THEN st.student_id END)         AS new_total,

    COUNT(DISTINCT CASE WHEN st.phase1_date IS NOT NULL THEN st.student_id END) AS old_phase1,
    COUNT(DISTINCT CASE WHEN st.is_active = 1 AND st.phase1_date IS NOT NULL
                        THEN st.student_id END)                                AS new_phase1,

    COUNT(DISTINCT CASE WHEN st.phase4_date IS NOT NULL THEN st.student_id END) AS old_phase4,
    COUNT(DISTINCT CASE WHEN st.is_active = 1 AND st.phase4_date IS NOT NULL
                        THEN st.student_id END)                                AS new_phase4,

    CASE WHEN COUNT(DISTINCT CASE WHEN st.phase1_date IS NOT NULL THEN st.student_id END) >
              COUNT(DISTINCT CASE WHEN st.is_active = 1 AND st.phase1_date IS NOT NULL
                                  THEN st.student_id END)
         THEN '<-- was over-reported' ELSE '' END                              AS flag
FROM schools s
LEFT JOIN students st
       ON s.udise_no COLLATE utf8mb4_unicode_ci = st.udise_no COLLATE utf8mb4_unicode_ci
WHERE s.district_name COLLATE utf8mb4_unicode_ci = @district COLLATE utf8mb4_unicode_ci
GROUP BY s.udise_no, s.school_name
ORDER BY (old_phase1 - new_phase1) DESC, s.school_name;


-- -----------------------------------------------------------------------------
-- 3. Confirm the new year really is reset for ACTIVE students
--
--    After promotion this should show phase1_saved = 0 (promotion seeds the
--    phase1 levels but sets phase1_date = NULL) and 0 for phases 2-4.
--    Anything non-zero here is genuine new-year data, not stale carry-over.
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*)                      AS active_students,
    SUM(phase1_date IS NOT NULL)  AS phase1_saved,
    SUM(phase2_date IS NOT NULL)  AS phase2_saved,
    SUM(phase3_date IS NOT NULL)  AS phase3_saved,
    SUM(phase4_date IS NOT NULL)  AS phase4_saved
FROM students
WHERE is_active = 1
  AND district COLLATE utf8mb4_unicode_ci = @district COLLATE utf8mb4_unicode_ci;


-- -----------------------------------------------------------------------------
-- 4. phase_approvals should be empty after promotion (Step 3b deletes it).
--    Rows here mean approvals recorded since the promotion run -- normal if
--    schools have started submitting again, suspicious if the run just finished.
-- -----------------------------------------------------------------------------
SELECT pa.udise_no, pa.phase_number, pa.approval_status, pa.approved_date
FROM phase_approvals pa
JOIN schools s ON s.udise_no COLLATE utf8mb4_unicode_ci = pa.udise_no COLLATE utf8mb4_unicode_ci
WHERE s.district_name COLLATE utf8mb4_unicode_ci = @district COLLATE utf8mb4_unicode_ci
ORDER BY pa.udise_no, pa.phase_number;
