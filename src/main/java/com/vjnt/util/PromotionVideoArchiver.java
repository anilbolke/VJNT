package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Year-end promotion support for teacher-uploaded videos.
 *
 * Teacher phase videos (student_videos with a phase_number) and VidnyanSetu
 * weekly activity videos (vidnyansetu_activities, and VidnyanSetu 2 STEM
 * activities in vidnyansetu2_activities) carry no academic year, so
 * after a class promotion last year's videos would still show as "uploaded"
 * for the new year and block re-uploads. Instead of deleting them, promotion
 * stamps them with its class_promotion_log.promotion_id in
 * archived_promotion_id. Every current-year screen reads only rows where
 * archived_promotion_id IS NULL; "previous year" views read the stamped rows.
 *
 * Also retires (is_active = 0, removed_by = 'PROMOTION') teacher_student_mapping
 * rows of the promoted students — the class-match join already hides them;
 * teachers' quotas refill from the new cohort on their next login.
 *
 * VidnyanSetu levels, teacher assignments and logins are deliberately NOT
 * touched (levels carry over to the new class).
 *
 * Undo for one promotion id P:
 *   UPDATE student_videos          SET archived_promotion_id = NULL WHERE archived_promotion_id = P;
 *   UPDATE vidnyansetu_activities  SET archived_promotion_id = NULL WHERE archived_promotion_id = P;
 *   UPDATE vidnyansetu2_activities SET archived_promotion_id = NULL WHERE archived_promotion_id = P;
 *   UPDATE teacher_student_mapping SET is_active = 1, removed_by = NULL
 *    WHERE removed_by = 'PROMOTION' AND updated_date >= <promotion_date>;
 *
 * DDL: databse Scripts/ADD_PROMOTION_ARCHIVE_COLUMNS_2026-10-11.sql (also
 * applied automatically by {@link #ensureSchema()} at startup).
 */
public final class PromotionVideoArchiver {

    /** SQL condition for "current year" rows; use as {@code AND <alias>.} + this, or bare. */
    public static final String CURRENT = "archived_promotion_id IS NULL";

    private static volatile boolean schemaReady = false;

    private PromotionVideoArchiver() {}

    /** Counts of what {@link #archive} stamped. */
    public static final class Result {
        public int phaseVideos;
        public int vsActivities;   // VidnyanSetu 1 + VidnyanSetu 2 activities
        public int mappingsRetired;
    }

    /**
     * Adds the archive columns if they are missing. Uses its OWN connection
     * because ALTER TABLE implicitly commits — never call it with a connection
     * that is inside a transaction. Plain ALTERs after an information_schema
     * check, so MariaDB 5.5 safe.
     */
    public static void ensureSchema() {
        if (schemaReady) return;
        try (Connection conn = DatabaseConnection.getConnection()) {
            addColumnIfMissing(conn, "student_videos", "archived_promotion_id",
                "ALTER TABLE student_videos ADD COLUMN archived_promotion_id INT NULL DEFAULT NULL " +
                "COMMENT 'class_promotion_log.promotion_id that archived this video; NULL = current year', " +
                "ADD KEY idx_sv_archived (archived_promotion_id)");
            addColumnIfMissing(conn, "vidnyansetu_activities", "archived_promotion_id",
                "ALTER TABLE vidnyansetu_activities ADD COLUMN archived_promotion_id INT NULL DEFAULT NULL " +
                "COMMENT 'class_promotion_log.promotion_id that archived this activity; NULL = current year', " +
                "ADD KEY idx_vsa_archived (archived_promotion_id)");
            addColumnIfMissing(conn, "class_promotion_log", "videos_archived",
                "ALTER TABLE class_promotion_log ADD COLUMN videos_archived INT NULL DEFAULT NULL, " +
                "ADD COLUMN vs_activities_archived INT NULL DEFAULT NULL");
            // Step 3e writes removed_by / updated_by / updated_date on teacher_student_mapping;
            // those columns are otherwise only added when the district mapping page is first used.
            TeacherStudentMappingSchema.ensure(conn);
            // VidnyanSetu 2 tables (own connection — CREATE TABLE implicitly commits)
            com.vjnt.dao.VidnyanSetu2ActivityDAO.ensureSchema();
            schemaReady = true;
        } catch (SQLException e) {
            System.err.println("PromotionVideoArchiver.ensureSchema failed: " + e.getMessage());
        }
    }

    private static void addColumnIfMissing(Connection conn, String table, String column, String ddl) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM information_schema.COLUMNS " +
                "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?")) {
            ps.setString(1, table);
            ps.setString(2, column);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return;
            }
        }
        // Table itself may not exist yet in a fresh environment — skip quietly then.
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?")) {
            ps.setString(1, table);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return;
            }
        }
        try (Statement st = conn.createStatement()) {
            st.executeUpdate(ddl);
            System.out.println("PromotionVideoArchiver: added " + table + "." + column);
        }
    }

    /**
     * What {@link #archive} WOULD stamp right now, for the promotion confirm screens.
     * Read-only; same WHERE clauses as archive(). Call {@link #ensureSchema()} first.
     *
     * @param udiseOrNull one school (Test Promote) or null for every school
     */
    public static Result preview(Connection conn, String udiseOrNull) throws SQLException {
        Result r = new Result();
        boolean one = udiseOrNull != null;
        r.phaseVideos = count(conn,
            "SELECT COUNT(*) FROM student_videos WHERE archived_promotion_id IS NULL AND phase_number IS NOT NULL" +
            (one ? " AND udise_no = ?" : ""), udiseOrNull);
        r.vsActivities = count(conn,
            "SELECT COUNT(*) FROM vidnyansetu_activities WHERE archived_promotion_id IS NULL" +
            (one ? " AND udise_no = ?" : ""), udiseOrNull)
          + count(conn,
            "SELECT COUNT(*) FROM vidnyansetu2_activities WHERE archived_promotion_id IS NULL" +
            (one ? " AND udise_no = ?" : ""), udiseOrNull);
        r.mappingsRetired = count(conn,
            "SELECT COUNT(*) FROM teacher_student_mapping WHERE is_active = 1" +
            (one ? " AND udise_code = ?" : ""), udiseOrNull);
        return r;
    }

    private static int count(Connection conn, String sql, String udiseOrNull) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            if (udiseOrNull != null) ps.setString(1, udiseOrNull);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    /**
     * Stamps the current-year videos of the promoted scope and retires stale
     * mappings. Runs on the caller's connection, inside its promotion
     * transaction; call it BEFORE students are graduated / promoted.
     *
     * @param udiseOrNull one school (Test Promote) or null for every school
     */
    public static Result archive(Connection conn, long promotionId, String udiseOrNull, String promotedBy) throws SQLException {
        Result r = new Result();
        boolean one = udiseOrNull != null;

        // 3c. GATEE teacher phase videos (month-based progress videos without a phase are left alone)
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE student_videos SET archived_promotion_id = ? " +
                "WHERE archived_promotion_id IS NULL AND phase_number IS NOT NULL" +
                (one ? " AND udise_no = ?" : ""))) {
            ps.setLong(1, promotionId);
            if (one) ps.setString(2, udiseOrNull);
            r.phaseVideos = ps.executeUpdate();
        }

        // 3d. VidnyanSetu weekly activity videos
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE vidnyansetu_activities SET archived_promotion_id = ? " +
                "WHERE archived_promotion_id IS NULL" + (one ? " AND udise_no = ?" : ""))) {
            ps.setLong(1, promotionId);
            if (one) ps.setString(2, udiseOrNull);
            r.vsActivities = ps.executeUpdate();
        }

        // 3d-2. VidnyanSetu 2 STEM activity videos (counted into vsActivities)
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE vidnyansetu2_activities SET archived_promotion_id = ? " +
                "WHERE archived_promotion_id IS NULL" + (one ? " AND udise_no = ?" : ""))) {
            ps.setLong(1, promotionId);
            if (one) ps.setString(2, udiseOrNull);
            r.vsActivities += ps.executeUpdate();
        }

        // 3e. Retire the promoted students' teacher-student mappings
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE teacher_student_mapping SET is_active = 0, removed_by = 'PROMOTION', " +
                "       updated_by = ?, updated_date = NOW() " +
                "WHERE is_active = 1" + (one ? " AND udise_code = ?" : ""))) {
            ps.setString(1, promotedBy);
            if (one) ps.setString(2, udiseOrNull);
            r.mappingsRetired = ps.executeUpdate();
        }

        // Log counts (columns added by ensureSchema; skip silently if they are missing)
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE class_promotion_log SET videos_archived = ?, vs_activities_archived = ? WHERE promotion_id = ?")) {
            ps.setInt(1, r.phaseVideos);
            ps.setInt(2, r.vsActivities);
            ps.setLong(3, promotionId);
            ps.executeUpdate();
        } catch (SQLException e) {
            // A failed statement does not abort a MySQL transaction; the stamps above stay.
            System.err.println("PromotionVideoArchiver: could not log counts: " + e.getMessage());
        }

        System.out.println("PromotionVideoArchiver: promotion " + promotionId +
                (one ? " udise=" + udiseOrNull : " (all schools)") +
                " phaseVideos=" + r.phaseVideos + " vsActivities=" + r.vsActivities +
                " mappingsRetired=" + r.mappingsRetired);
        return r;
    }
}
