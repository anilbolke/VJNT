package com.vjnt.dao;

import com.vjnt.util.DatabaseConnection;
import org.json.JSONArray;
import org.json.JSONObject;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Read-only lookup for the VidnyanSetu (कृतीतून संकल्पनेकडे विज्ञानसेतू) curriculum
 * reference table: Class -> Week -> Week Topic -> Day -> Day Topic.
 *
 * Data is static/rarely-changing (imported once from the source Excel via
 * "databse Scripts/create_vidnyansetu_curriculum.sql"), so the whole table
 * (~560 rows) is returned as one nested JSON blob and the Class/Week/Day
 * cascade is driven entirely client-side in vidnyansetu-activity.jsp — no
 * per-level AJAX round trip.
 */
public class VidnyanSetuCurriculumDAO {

    private static final String[] CLASS_ORDER = {"III", "IV", "V", "VI", "VII", "VIII", "IX"};

    /**
     * Full curriculum, nested as:
     * { "III": { "weeks": [ { weekNo, weekLabel, weekTopic,
     *                          "days": [ { dayNo, dayLabel, dayTopic }, ... ] }, ... ] }, ... }
     */
    public JSONObject getFullCurriculum() {
        JSONObject byClass = new JSONObject();

        String sql = "SELECT class, week_no, week_label, week_topic, day_no, day_label, day_topic " +
                     "FROM vidnyansetu_curriculum ORDER BY FIELD(class,'III','IV','V','VI','VII','VIII','IX'), week_no, day_no";

        // class -> week_no -> week JSONObject (with its "days" array already attached)
        Map<String, Map<Integer, JSONObject>> weeksByClass = new LinkedHashMap<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                String cls = rs.getString("class");
                int weekNo = rs.getInt("week_no");

                Map<Integer, JSONObject> weeks = weeksByClass.computeIfAbsent(cls, k -> new LinkedHashMap<>());
                JSONObject week = weeks.get(weekNo);
                if (week == null) {
                    week = new JSONObject();
                    week.put("weekNo", weekNo);
                    week.put("weekLabel", rs.getString("week_label"));
                    week.put("weekTopic", rs.getString("week_topic"));
                    week.put("days", new JSONArray());
                    weeks.put(weekNo, week);
                }

                JSONObject day = new JSONObject();
                day.put("dayNo", rs.getInt("day_no"));
                day.put("dayLabel", rs.getString("day_label"));
                day.put("dayTopic", rs.getString("day_topic"));
                week.getJSONArray("days").put(day);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        for (String cls : CLASS_ORDER) {
            Map<Integer, JSONObject> weeks = weeksByClass.get(cls);
            if (weeks == null) continue; // no data imported for this class
            JSONArray weekArr = new JSONArray();
            for (JSONObject week : weeks.values()) weekArr.put(week);
            JSONObject classObj = new JSONObject();
            classObj.put("weeks", weekArr);
            byClass.put(cls, classObj);
        }

        return byClass;
    }
}
