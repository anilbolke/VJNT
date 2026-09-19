-- Restructure VidnyanSetu student-level tracking into a full Phase 1-4 system
-- that mirrors the FLN workflow exactly: students.phase{N}_marathi + phase{N}_date
-- -> vidnyansetu_student_levels.phase{N}_vidnyan + phase{N}_date, and
-- phase_approvals -> vidnyansetu_phase_approvals (same columns/semantics).
-- Flow: VidnyanSetu Teacher enters levels for the open phase -> VidnyanSetu
-- Coordinator submits that phase for approval (VidnyanSetuSubmitPhaseServlet)
-- -> the school's real Head Master approves/rejects (VidnyanSetuApprovePhaseServlet,
-- main "user" session) -> next phase unlocks. Academic-year reset reuses the
-- same promote/reset tooling as FLN (no separate year column, same as
-- phase_approvals itself has none).
--
-- Replaces the single always-editable vidnyan_level column added in
-- CREATE_VIDNYANSETU_STUDENT_MODULE_2026-09-19.sql (2 test rows only, safe to
-- drop). Collation matched to vidnyansetu_student_levels' existing charset.

ALTER TABLE vidnyansetu_student_levels
  DROP COLUMN vidnyan_level,
  ADD COLUMN phase1_vidnyan TINYINT NULL AFTER student_id,
  ADD COLUMN phase1_date TIMESTAMP NULL AFTER phase1_vidnyan,
  ADD COLUMN phase2_vidnyan TINYINT NULL AFTER phase1_date,
  ADD COLUMN phase2_date TIMESTAMP NULL AFTER phase2_vidnyan,
  ADD COLUMN phase3_vidnyan TINYINT NULL AFTER phase2_date,
  ADD COLUMN phase3_date TIMESTAMP NULL AFTER phase3_vidnyan,
  ADD COLUMN phase4_vidnyan TINYINT NULL AFTER phase3_date,
  ADD COLUMN phase4_date TIMESTAMP NULL AFTER phase4_vidnyan;

CREATE TABLE vidnyansetu_phase_approvals (
  approval_id INT NOT NULL AUTO_INCREMENT,
  udise_no VARCHAR(50) NOT NULL,
  phase_number INT NOT NULL,
  completed_by VARCHAR(100) DEFAULT NULL,
  completed_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  completion_remarks TEXT,
  approval_status ENUM('PENDING','APPROVED','REJECTED') DEFAULT 'PENDING',
  approved_by VARCHAR(100) DEFAULT NULL,
  approved_date DATETIME DEFAULT NULL,
  approval_remarks TEXT,
  total_students INT DEFAULT 0,
  completed_students INT DEFAULT 0,
  pending_students INT DEFAULT 0,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (approval_id),
  UNIQUE KEY uk_vspa_udise_phase (udise_no, phase_number),
  KEY idx_vspa_status (approval_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
