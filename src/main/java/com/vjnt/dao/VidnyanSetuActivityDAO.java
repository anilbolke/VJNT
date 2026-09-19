package com.vjnt.dao;

import com.vjnt.util.DatabaseConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Save/list activity records created against the VidnyanSetu curriculum
 * picker (Class -> Week -> Day). week_topic/day_topic are stored as a
 * snapshot at creation time — see vidnyansetu_activities in
 * "databse Scripts/create_vidnyansetu_curriculum.sql" for why.
 */
public class VidnyanSetuActivityDAO {

    public static class NewActivity {
        public String udiseNo, studentPen, studentName, studentClass;
        public int weekNo, dayNo;
        public String weekLabel, weekTopic, dayLabel, dayTopic;
        public String activityDate; // yyyy-MM-dd
        public String description;
        public String createdBy;
        // Video is mandatory — see SaveVidnyanSetuActivityServlet, which rejects the
        // save before this DAO is ever called if videoUrl is missing.
        public String videoUrl;
        public String videoFilename;
        public long videoSize;
        public String videoThumbnailUrl;
    }

    public boolean saveActivity(NewActivity a) {
        // approval_status='PENDING', is_visible=0 — same as insertPhaseVideo() in
        // UploadTeacherPhaseVideoServlet; a Head Master must approve before the
        // video is visible outside the coordinator's own list. See
        // vidnyansetu-activity-approval.jsp.
        String sql = "INSERT INTO vidnyansetu_activities " +
                "(udise_no, student_pen, student_name, student_class, week_no, week_label, week_topic, " +
                " day_no, day_label, day_topic, activity_date, description, created_by, " +
                " video_url, video_filename, video_size, video_thumbnail_url, approval_status, is_visible) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'PENDING',0)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setString(1, a.udiseNo);
            stmt.setString(2, a.studentPen);
            stmt.setString(3, a.studentName);
            stmt.setString(4, a.studentClass);
            stmt.setInt(5, a.weekNo);
            stmt.setString(6, a.weekLabel);
            stmt.setString(7, a.weekTopic);
            stmt.setInt(8, a.dayNo);
            stmt.setString(9, a.dayLabel);
            stmt.setString(10, a.dayTopic);
            stmt.setString(11, a.activityDate);
            stmt.setString(12, a.description);
            stmt.setString(13, a.createdBy);
            stmt.setString(14, a.videoUrl);
            stmt.setString(15, a.videoFilename);
            stmt.setLong(16, a.videoSize);
            stmt.setString(17, a.videoThumbnailUrl);

            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Recent activities for a school (newest first), for the listing panel. */
    public List<Map<String, Object>> getActivitiesBySchool(String udiseNo, int limit) {
        List<Map<String, Object>> out = new ArrayList<>();
        String sql = "SELECT activity_id, student_pen, student_name, student_class, week_no, week_label, " +
                "week_topic, day_no, day_label, day_topic, activity_date, description, created_by, created_date, " +
                "video_url, video_filename, video_thumbnail_url, approval_status, rejection_reason " +
                "FROM vidnyansetu_activities WHERE udise_no=? ORDER BY created_date DESC LIMIT ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, udiseNo);
            stmt.setInt(2, limit);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("id", rs.getInt("activity_id"));
                    row.put("pen", rs.getString("student_pen"));
                    row.put("name", rs.getString("student_name"));
                    row.put("cls", rs.getString("student_class"));
                    row.put("weekNo", rs.getInt("week_no"));
                    row.put("weekLabel", rs.getString("week_label"));
                    row.put("weekTopic", rs.getString("week_topic"));
                    row.put("dayNo", rs.getInt("day_no"));
                    row.put("dayLabel", rs.getString("day_label"));
                    row.put("dayTopic", rs.getString("day_topic"));
                    row.put("date", rs.getDate("activity_date"));
                    row.put("desc", rs.getString("description"));
                    row.put("createdBy", rs.getString("created_by"));
                    row.put("createdDate", rs.getTimestamp("created_date"));
                    row.put("videoUrl", rs.getString("video_url"));
                    row.put("videoFilename", rs.getString("video_filename"));
                    row.put("videoThumbnailUrl", rs.getString("video_thumbnail_url"));
                    row.put("approvalStatus", rs.getString("approval_status"));
                    row.put("rejectionReason", rs.getString("rejection_reason"));
                    out.add(row);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return out;
    }

    /**
     * Same as {@link #getActivitiesBySchool} but restricted to the given
     * classes — used for a VidnyanSetu Teacher, who should only see
     * activities logged for their own assigned class(es), not the whole
     * school's. Empty/null classes returns no rows rather than falling back
     * to "all classes" (a teacher with no assignment should see nothing).
     */
    public List<Map<String, Object>> getActivitiesBySchoolForClasses(String udiseNo, List<String> classes, int limit) {
        List<Map<String, Object>> out = new ArrayList<>();
        if (classes == null || classes.isEmpty()) return out;

        StringBuilder placeholders = new StringBuilder();
        for (int i = 0; i < classes.size(); i++) {
            if (i > 0) placeholders.append(",");
            placeholders.append("?");
        }
        String sql = "SELECT activity_id, student_pen, student_name, student_class, week_no, week_label, " +
                "week_topic, day_no, day_label, day_topic, activity_date, description, created_by, created_date, " +
                "video_url, video_filename, video_thumbnail_url, approval_status, rejection_reason " +
                "FROM vidnyansetu_activities WHERE udise_no=? AND student_class IN (" + placeholders + ") " +
                "ORDER BY created_date DESC LIMIT ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            int idx = 1;
            stmt.setString(idx++, udiseNo);
            for (String c : classes) stmt.setString(idx++, c);
            stmt.setInt(idx, limit);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("id", rs.getInt("activity_id"));
                    row.put("pen", rs.getString("student_pen"));
                    row.put("name", rs.getString("student_name"));
                    row.put("cls", rs.getString("student_class"));
                    row.put("weekNo", rs.getInt("week_no"));
                    row.put("weekLabel", rs.getString("week_label"));
                    row.put("weekTopic", rs.getString("week_topic"));
                    row.put("dayNo", rs.getInt("day_no"));
                    row.put("dayLabel", rs.getString("day_label"));
                    row.put("dayTopic", rs.getString("day_topic"));
                    row.put("date", rs.getDate("activity_date"));
                    row.put("desc", rs.getString("description"));
                    row.put("createdBy", rs.getString("created_by"));
                    row.put("createdDate", rs.getTimestamp("created_date"));
                    row.put("videoUrl", rs.getString("video_url"));
                    row.put("videoFilename", rs.getString("video_filename"));
                    row.put("videoThumbnailUrl", rs.getString("video_thumbnail_url"));
                    row.put("approvalStatus", rs.getString("approval_status"));
                    row.put("rejectionReason", rs.getString("rejection_reason"));
                    out.add(row);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return out;
    }
}
