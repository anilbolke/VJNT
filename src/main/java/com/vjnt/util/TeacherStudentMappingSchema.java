package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Columns + audit table used by the District "Manage Teacher Students" activity
 * on top of teacher_student_mapping:
 *
 *  - mapped_by    'AUTO' (random mapping on the teacher dashboard) or 'DISTRICT'
 *  - removed_by   'DISTRICT' when a district coordinator removed the student
 *                 from that teacher; the auto mapping never re-picks such a
 *                 student for the same teacher + subject
 *  - updated_by / updated_date  last manual change
 *
 * Every district add / remove / replace / restore is logged in
 * teacher_student_mapping_audit.
 *
 * Same change as databse Scripts/DISTRICT_MANAGE_TEACHER_STUDENTS_2026-09-25.sql;
 * applied lazily here so the app works whether or not the script was run.
 * Written for MariaDB 5.5 (prod): no ADD COLUMN IF NOT EXISTS, so each column is
 * checked in information_schema first.
 */
public final class TeacherStudentMappingSchema {

    private static volatile boolean ensured = false;

    private static final String CREATE_AUDIT_TABLE =
            "CREATE TABLE IF NOT EXISTS teacher_student_mapping_audit (" +
            "audit_id INT AUTO_INCREMENT PRIMARY KEY, " +
            "action VARCHAR(20) NOT NULL, " +
            "teacher_id INT NOT NULL, " +
            "udise_code VARCHAR(20) DEFAULT NULL, " +
            "class VARCHAR(10) DEFAULT NULL, " +
            "section VARCHAR(10) DEFAULT NULL, " +
            "subject VARCHAR(50) DEFAULT NULL, " +
            "old_student_id INT DEFAULT NULL, " +
            "new_student_id INT DEFAULT NULL, " +
            "reason VARCHAR(255) DEFAULT NULL, " +
            "done_by VARCHAR(100) DEFAULT NULL, " +
            "done_by_role VARCHAR(40) DEFAULT NULL, " +
            "district VARCHAR(100) DEFAULT NULL, " +
            "created_date DATETIME DEFAULT NULL, " +
            "KEY idx_tsma_teacher (teacher_id), " +
            "KEY idx_tsma_udise (udise_code)" +
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

    private TeacherStudentMappingSchema() {}

    /** Adds the district columns + audit table once per JVM. Safe to call on every request. */
    public static void ensure(Connection conn) throws SQLException {
        if (ensured) return;
        synchronized (TeacherStudentMappingSchema.class) {
            if (ensured) return;
            addColumnIfMissing(conn, "mapped_by", "VARCHAR(20) NOT NULL DEFAULT 'AUTO'");
            addColumnIfMissing(conn, "removed_by", "VARCHAR(20) DEFAULT NULL");
            addColumnIfMissing(conn, "updated_by", "VARCHAR(100) DEFAULT NULL");
            addColumnIfMissing(conn, "updated_date", "DATETIME DEFAULT NULL");
            try (Statement st = conn.createStatement()) {
                st.execute(CREATE_AUDIT_TABLE);
            }
            ensured = true;
        }
    }

    private static void addColumnIfMissing(Connection conn, String column, String definition) throws SQLException {
        String checkSql = "SELECT COUNT(*) FROM information_schema.columns " +
                          "WHERE table_schema = DATABASE() AND table_name = 'teacher_student_mapping' " +
                          "AND column_name = ?";
        try (PreparedStatement ps = conn.prepareStatement(checkSql)) {
            ps.setString(1, column);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) return;
            }
        }
        try (Statement st = conn.createStatement()) {
            st.execute("ALTER TABLE teacher_student_mapping ADD COLUMN " + column + " " + definition);
        }
    }
}
