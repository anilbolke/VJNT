-- vidnyansetu_activities on vjnt_class_management_live was created before the
-- Head Master approval workflow was added to it (approval_status/is_visible/
-- approved_by/approved_by_name/approval_date/rejection_reason/video_thumbnail_url)
-- — the dev DB (vjnt_class_management) already has these, live didn't, which
-- broke SaveVidnyanSetuActivityServlet/VidnyanSetuActivityDAO with
-- "Unknown column 'video_thumbnail_url' in 'field list'" once the app was
-- pointed at the live DB. Brings live's table definition in line with dev's
-- (see SHOW CREATE TABLE vidnyansetu_activities on vjnt_class_management).
-- Table had 0 rows at the time of this migration, so no backfill needed.

ALTER TABLE vidnyansetu_activities
  ADD COLUMN video_thumbnail_url VARCHAR(500) DEFAULT NULL AFTER video_size,
  ADD COLUMN approval_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' AFTER video_thumbnail_url,
  ADD COLUMN is_visible TINYINT(1) NOT NULL DEFAULT 0 AFTER approval_status,
  ADD COLUMN approved_by INT DEFAULT NULL AFTER is_visible,
  ADD COLUMN approved_by_name VARCHAR(100) DEFAULT NULL AFTER approved_by,
  ADD COLUMN approval_date TIMESTAMP NULL DEFAULT NULL AFTER approved_by_name,
  ADD COLUMN rejection_reason VARCHAR(500) DEFAULT NULL AFTER approval_date,
  ADD KEY idx_approval_status (udise_no, approval_status);
