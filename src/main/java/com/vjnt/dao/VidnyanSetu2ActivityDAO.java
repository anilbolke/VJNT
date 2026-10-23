package com.vjnt.dao;

import com.vjnt.util.DatabaseConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * VidnyanSetu 2 — STEM activities for classes VI..IX.
 *
 * Kept in its own tables (not vidnyansetu_activities) because VidnyanSetu 1
 * rows are Week -> Day curriculum entries and the division tracker / pending
 * week rules read that table; a STEM activity has no week or day.
 *
 *   vidnyansetu2_activity_master — the 54 activities from
 *       Document/STEM_Activity_List (1).docx, same list for every class.
 *   vidnyansetu2_activities      — one row per logged activity (class level,
 *       video mandatory, Head Master approval). Same approval / archive
 *       columns and semantics as vidnyansetu_activities.
 *
 * Both tables are created, and the master seeded, by {@link #ensureSchema()}
 * on first use — "databse Scripts/CREATE_VIDNYANSETU2_2026-10-23.sql" holds
 * the same DDL for running by hand. Plain CREATE TABLE, MariaDB 5.5 safe.
 */
public class VidnyanSetu2ActivityDAO {

    /** Classes VidnyanSetu 2 applies to (Roman numerals, as stored in students.class). */
    public static final List<String> CLASSES = Collections.unmodifiableList(Arrays.asList("VI", "VII", "VIII", "IX"));

    public static boolean isAllowedClass(String cls) {
        return cls != null && CLASSES.contains(cls.trim().toUpperCase());
    }

    // Seed for vidnyansetu2_activity_master — activity_no = list position.
    private static final String[] SEED = {
        "Expansion and contraction of balloon",
        "Geometry with floating magnets",
        "D. C. motor",
        "Syringe generator",
        "Magnetic field lines",
        "Simple galvanometer",
        "Spoke magnet spinner",
        "Balloon rocket",
        "Levitating pen",
        "Simple levitation (using three magnets)",
        "Vertical levitation – Standing pen",
        "Nut and coin centrifuge (Centrifugal force and sound)",
        "Whistling bird",
        "Paper-cup glider",
        "Balancing toy",
        "Climbing funnels",
        "Balancing pipe",
        "Various shapes using laser and mirror",
        "Tracing path of light",
        "Coloured shadows",
        "Smaller balloon stronger balloon",
        "Pitch of sound",
        "Balloon in syringe (Boyle’s law)",
        "Simple thermometer",
        "Ball in the air: Anti-gravity ball",
        "Chemical balloon inflator",
        "Separating ions",
        "Separating funnel",
        "All in one triangle",
        "All in one quadrilateral",
        "Geometric shapes using two right-angle congruent triangles",
        "Triangles to quadrilaterals",
        "Simple geoboard using push pins",
        "Brain cap",
        "Heating effect of electric current (Small homemade heater)",
        "Longitudinal waves using slinky spring",
        "Transverse waves using straws",
        "Periscope",
        "Platonic solids",
        "Paper flexagon",
        "Newton’s third law and force",
        "Leaf structure cube",
        "Top patterns (CD stroboscope)",
        "Liquid race",
        "Straw siphon",
        "Magical colour separation – Chromatography",
        "Icosahedron & Golden Rectangles!",
        "Visual proof of the Pythagorean Theorem",
        "Visual proof of (a + b)²",
        "Newton’s disc",
        "The “T” puzzle",
        "Triangle to rectangle!",
        "Tangrams",
        "Solar water bottle distillery"
    };

    private static volatile boolean schemaReady = false;

    /** Creates both tables if missing and seeds the master list when empty. Idempotent. */
    public static void ensureSchema() {
        if (schemaReady) return;
        synchronized (VidnyanSetu2ActivityDAO.class) {
            if (schemaReady) return;
            try (Connection conn = DatabaseConnection.getConnection();
                 Statement st = conn.createStatement()) {
                // Division / district screens JOIN schools ON udise_no, and udise_no
                // collation differs per deployment — so build the table in whatever
                // collation schools.udise_no has here instead of hardcoding one.
                String tableOpts = "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
                try (ResultSet rs = st.executeQuery(
                        "SELECT COLLATION_NAME FROM information_schema.COLUMNS " +
                        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'schools' AND COLUMN_NAME = 'udise_no'")) {
                    if (rs.next()) {
                        String coll = rs.getString(1);
                        if (coll != null && coll.matches("utf8mb4_[A-Za-z0-9_]+")) tableOpts += " COLLATE=" + coll;
                    }
                }
                st.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS vidnyansetu2_activity_master (" +
                    "  activity_no INT NOT NULL," +
                    "  activity_name VARCHAR(255) NOT NULL," +
                    "  is_active TINYINT(1) NOT NULL DEFAULT 1," +
                    "  PRIMARY KEY (activity_no)" +
                    ") " + tableOpts);
                st.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS vidnyansetu2_activities (" +
                    "  activity_id INT NOT NULL AUTO_INCREMENT," +
                    "  udise_no VARCHAR(20) NOT NULL," +
                    "  student_class VARCHAR(5) NOT NULL," +
                    "  student_section VARCHAR(10) DEFAULT NULL," +
                    "  activity_no INT NOT NULL," +
                    "  activity_name VARCHAR(255) NOT NULL COMMENT 'snapshot of vidnyansetu2_activity_master.activity_name'," +
                    "  activity_date DATE NOT NULL," +
                    "  description TEXT," +
                    "  created_by VARCHAR(100) DEFAULT NULL," +
                    "  created_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP," +
                    "  video_url VARCHAR(500) DEFAULT NULL," +
                    "  video_filename VARCHAR(255) DEFAULT NULL," +
                    "  video_size BIGINT DEFAULT NULL," +
                    "  video_thumbnail_url VARCHAR(500) DEFAULT NULL," +
                    "  approval_status VARCHAR(20) NOT NULL DEFAULT 'PENDING'," +
                    "  is_visible TINYINT(1) NOT NULL DEFAULT 0," +
                    "  approved_by INT DEFAULT NULL," +
                    "  approved_by_name VARCHAR(100) DEFAULT NULL," +
                    "  approval_date TIMESTAMP NULL DEFAULT NULL," +
                    "  rejection_reason VARCHAR(500) DEFAULT NULL," +
                    "  archived_promotion_id INT DEFAULT NULL COMMENT 'class_promotion_log.promotion_id that archived this activity; NULL = current year'," +
                    "  PRIMARY KEY (activity_id)," +
                    "  KEY idx_vs2_school_class (udise_no, student_class)," +
                    "  KEY idx_vs2_approval_status (udise_no, approval_status)," +
                    "  KEY idx_vs2_archived (archived_promotion_id)" +
                    ") " + tableOpts);

                int existing = 0;
                try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM vidnyansetu2_activity_master")) {
                    if (rs.next()) existing = rs.getInt(1);
                }
                if (existing == 0) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO vidnyansetu2_activity_master (activity_no, activity_name) VALUES (?, ?)")) {
                        for (int i = 0; i < SEED.length; i++) {
                            ps.setInt(1, i + 1);
                            ps.setString(2, SEED[i]);
                            ps.addBatch();
                        }
                        ps.executeBatch();
                    }
                }
                schemaReady = true;
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    public VidnyanSetu2ActivityDAO() {
        ensureSchema();
    }

    /** Active STEM activities as {no, name}, in list order. */
    public List<Map<String, Object>> getMasterList() {
        List<Map<String, Object>> out = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT activity_no, activity_name FROM vidnyansetu2_activity_master WHERE is_active = 1 ORDER BY activity_no");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("no", rs.getInt("activity_no"));
                m.put("name", rs.getString("activity_name"));
                out.add(m);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return out;
    }

    /** Name of an active master activity, or null if the number is unknown/inactive. */
    public String getMasterName(int activityNo) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT activity_name FROM vidnyansetu2_activity_master WHERE activity_no = ? AND is_active = 1")) {
            ps.setInt(1, activityNo);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString(1) : null;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return null;
        }
    }

    public static class NewActivity {
        public String udiseNo, studentClass, studentSection;
        public int activityNo;
        public String activityName;
        public String activityDate; // yyyy-MM-dd
        public String description;
        public String createdBy;
        // Video is mandatory — SaveVidnyanSetu2ActivityServlet rejects the save before this DAO is called.
        public String videoUrl;
        public String videoFilename;
        public long videoSize;
        public String videoThumbnailUrl;
    }

    public boolean saveActivity(NewActivity a) {
        // PENDING + not visible until a Head Master approves — see vidnyansetu2-activity-approval.jsp.
        String sql = "INSERT INTO vidnyansetu2_activities " +
                "(udise_no, student_class, student_section, activity_no, activity_name, activity_date, description, " +
                " created_by, video_url, video_filename, video_size, video_thumbnail_url, approval_status, is_visible) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,'PENDING',0)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int i = 1;
            stmt.setString(i++, a.udiseNo);
            stmt.setString(i++, a.studentClass);
            stmt.setString(i++, a.studentSection);
            stmt.setInt(i++, a.activityNo);
            stmt.setString(i++, a.activityName);
            stmt.setString(i++, a.activityDate);
            stmt.setString(i++, a.description);
            stmt.setString(i++, a.createdBy);
            stmt.setString(i++, a.videoUrl);
            stmt.setString(i++, a.videoFilename);
            stmt.setLong(i++, a.videoSize);
            stmt.setString(i, a.videoThumbnailUrl);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    private static final String LIST_COLUMNS =
            "SELECT activity_id, student_class, student_section, activity_no, activity_name, activity_date, description, " +
            "created_by, created_date, video_url, video_filename, video_thumbnail_url, approval_status, rejection_reason " +
            "FROM vidnyansetu2_activities ";

    /** Current-year activities for a school (newest first). */
    public List<Map<String, Object>> getActivitiesBySchool(String udiseNo, int limit) {
        return getActivitiesBySchoolForClassSections(udiseNo, null, limit);
    }

    /**
     * Same as {@link #getActivitiesBySchool} restricted to the given {class, section}
     * pairs (a VS Teacher's assignments). null = no restriction; an empty list returns
     * no rows (a teacher with no assignment sees nothing).
     */
    public List<Map<String, Object>> getActivitiesBySchoolForClassSections(String udiseNo, List<String[]> classSections, int limit) {
        List<Map<String, Object>> out = new ArrayList<>();
        if (classSections != null && classSections.isEmpty()) return out;

        StringBuilder sql = new StringBuilder(LIST_COLUMNS).append("WHERE udise_no = ? AND archived_promotion_id IS NULL");
        if (classSections != null) {
            sql.append(" AND (");
            for (int i = 0; i < classSections.size(); i++) {
                if (i > 0) sql.append(" OR ");
                sql.append("(student_class = ? AND student_section = ?)");
            }
            sql.append(")");
        }
        sql.append(" ORDER BY created_date DESC LIMIT ?");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            stmt.setString(idx++, udiseNo);
            if (classSections != null) {
                for (String[] cs : classSections) {
                    stmt.setString(idx++, cs[0]);
                    stmt.setString(idx++, cs[1]);
                }
            }
            stmt.setInt(idx, limit);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) out.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return out;
    }

    private static Map<String, Object> mapRow(ResultSet rs) throws SQLException {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", rs.getInt("activity_id"));
        row.put("cls", rs.getString("student_class"));
        row.put("section", rs.getString("student_section"));
        row.put("activityNo", rs.getInt("activity_no"));
        row.put("activityName", rs.getString("activity_name"));
        row.put("date", rs.getDate("activity_date"));
        row.put("desc", rs.getString("description"));
        row.put("createdBy", rs.getString("created_by"));
        row.put("createdDate", rs.getTimestamp("created_date"));
        row.put("videoUrl", rs.getString("video_url"));
        row.put("videoFilename", rs.getString("video_filename"));
        row.put("videoThumbnailUrl", rs.getString("video_thumbnail_url"));
        row.put("approvalStatus", rs.getString("approval_status"));
        row.put("rejectionReason", rs.getString("rejection_reason"));
        return row;
    }
}
