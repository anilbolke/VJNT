package com.vjnt.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.vjnt.util.DatabaseConnection;

/**
 * Division-wise Activity Visibility management.
 *
 * Data Admin decides, per division, which Quick Action activities are
 * visible on the School Coordinator dashboard.
 *
 * Tables:
 *   activity_master           - one row per School Coordinator quick action
 *   division_activity_config  - checkbox state per division per activity
 *
 * Default behaviour is fail-open: if a division has no config rows (or the
 * lookup fails), every activity stays visible so existing users are unaffected.
 */
public class ActivityVisibilityDAO {

    /** Seed data: code | name | marathi name | icon | display order */
    private static final String[][] SEED_ACTIVITIES = {
        {"MANAGE_STUDENTS",         "Manage Students",                          "विद्यार्थी स्तर निश्चिती",       "📚", "1"},
        {"PALAK_MELAVA",            "Parents Meeting",                          "पालक मेळावा",                    "👥", "2"},
        {"ADD_STUDENT",             "Add Student",                              "विद्यार्थी जोडा",                "➕", "3"},
        {"ADD_TEACHER",             "Add Teacher",                              "शिक्षक जोडा",                    "👨‍🏫", "4"},
        {"EDIT_STUDENT",            "Edit Student",                             "विद्यार्थी संपादित करा",          "✏️", "5"},
        {"MANAGE_TEACHERS",         "Manage Teachers",                          "शिक्षक व्यवस्थापन",              "👨‍🏫", "6"},
        {"ASSIGN_TEACHER",          "Class / Subject Teacher Assignment",       "वर्ग शिक्षक / विषय शिक्षक निश्चिती", "📋", "7"},
        {"OTHER_SCHOOL_ACTIVITY",   "Other School Activity",                    "इतर शालेय उपक्रम",               "🎯", "8"},
        {"VIEW_STUDENT_DATA",       "View All Student Data",                    "सर्व विद्यार्थी डेटा",           "📊", "9"},
        {"STUDENT_PHASE_HISTORY",   "Student Phase History",                    "विद्यार्थी टप्पा इतिहास",         "📋", "10"},
        {"STUDENT_ACTIVITY",        "Student Activities",                       "विद्यार्थी उपक्रम",              "🏅", "11"},
        {"GRADUATED_STUDENTS",      "Graduated Students",                       "उत्तीर्ण विद्यार्थी",            "🎓", "12"},
        {"FLN_COMPLETED",           "FLN Completed Students",                   "FLN 100% पूर्ण विद्यार्थी",      "🏆", "13"},
        {"GENERATE_STUDENT_REPORT", "Generate Student Report",                  "विद्यार्थी अहवाल तयार करा",       "📊", "14"},
        {"UPLOAD_STUDENT_EXCEL",    "Upload Student Excel",                     "विद्यार्थी एक्सेल पाठवा",         "📤", "15"}
    };

    private static volatile boolean tablesEnsured = false;

    /**
     * Creates the tables if they don't exist and seeds activity_master.
     * Safe to call repeatedly; runs the DDL only once per JVM.
     */
    public void ensureTables() {
        if (tablesEnsured) return;
        synchronized (ActivityVisibilityDAO.class) {
            if (tablesEnsured) return;
            try (Connection conn = DatabaseConnection.getConnection();
                 Statement stmt = conn.createStatement()) {

                stmt.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS activity_master (" +
                    "  activity_code VARCHAR(50) PRIMARY KEY," +
                    "  activity_name VARCHAR(100) NOT NULL," +
                    "  activity_name_marathi VARCHAR(150)," +
                    "  icon VARCHAR(10)," +
                    "  display_order INT DEFAULT 0," +
                    "  is_active TINYINT(1) DEFAULT 1" +
                    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

                stmt.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS division_activity_config (" +
                    "  config_id INT AUTO_INCREMENT PRIMARY KEY," +
                    "  division_name VARCHAR(100) NOT NULL," +
                    "  activity_code VARCHAR(50) NOT NULL," +
                    "  is_enabled TINYINT(1) NOT NULL DEFAULT 1," +
                    "  updated_by VARCHAR(100)," +
                    "  updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
                    "  UNIQUE KEY uk_division_activity (division_name, activity_code)" +
                    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT IGNORE INTO activity_master " +
                        "(activity_code, activity_name, activity_name_marathi, icon, display_order) " +
                        "VALUES (?, ?, ?, ?, ?)")) {
                    for (String[] a : SEED_ACTIVITIES) {
                        ps.setString(1, a[0]);
                        ps.setString(2, a[1]);
                        ps.setString(3, a[2]);
                        ps.setString(4, a[3]);
                        ps.setInt(5, Integer.parseInt(a[4]));
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }
                tablesEnsured = true;
            } catch (SQLException e) {
                System.err.println("ActivityVisibilityDAO.ensureTables failed: " + e.getMessage());
                e.printStackTrace();
            }
        }
    }

    /**
     * All active activities in display order.
     * Each row: {code, name, marathi, icon}
     */
    public List<Map<String, String>> getAllActivities() {
        ensureTables();
        List<Map<String, String>> list = new ArrayList<Map<String, String>>();
        String sql = "SELECT activity_code, activity_name, activity_name_marathi, icon " +
                     "FROM activity_master WHERE is_active = 1 ORDER BY display_order";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, String> m = new LinkedHashMap<String, String>();
                m.put("code", rs.getString("activity_code"));
                m.put("name", rs.getString("activity_name"));
                m.put("marathi", rs.getString("activity_name_marathi"));
                m.put("icon", rs.getString("icon"));
                list.add(m);
            }
        } catch (SQLException e) {
            System.err.println("ActivityVisibilityDAO.getAllActivities failed: " + e.getMessage());
        }
        return list;
    }

    /**
     * Full config matrix: division -> (activity_code -> is_enabled).
     * Only divisions that have saved rows appear; missing entries mean enabled.
     */
    public Map<String, Map<String, Boolean>> getConfigMatrix() {
        ensureTables();
        Map<String, Map<String, Boolean>> matrix = new LinkedHashMap<String, Map<String, Boolean>>();
        String sql = "SELECT division_name, activity_code, is_enabled " +
                     "FROM division_activity_config ORDER BY division_name";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String div = rs.getString("division_name");
                Map<String, Boolean> row = matrix.get(div);
                if (row == null) {
                    row = new LinkedHashMap<String, Boolean>();
                    matrix.put(div, row);
                }
                row.put(rs.getString("activity_code"), rs.getBoolean("is_enabled"));
            }
        } catch (SQLException e) {
            System.err.println("ActivityVisibilityDAO.getConfigMatrix failed: " + e.getMessage());
        }
        return matrix;
    }

    /**
     * Saves the checkbox state for one division (upsert per activity).
     */
    public boolean saveDivisionConfig(String divisionName, Map<String, Boolean> config, String updatedBy) {
        ensureTables();
        String sql = "INSERT INTO division_activity_config " +
                     "(division_name, activity_code, is_enabled, updated_by) VALUES (?, ?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE is_enabled = VALUES(is_enabled), updated_by = VALUES(updated_by)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (Map.Entry<String, Boolean> e : config.entrySet()) {
                ps.setString(1, divisionName);
                ps.setString(2, e.getKey());
                ps.setBoolean(3, e.getValue());
                ps.setString(4, updatedBy);
                ps.addBatch();
            }
            ps.executeBatch();
            return true;
        } catch (SQLException e) {
            System.err.println("ActivityVisibilityDAO.saveDivisionConfig failed: " + e.getMessage());
            return false;
        }
    }

    /**
     * Activity codes HIDDEN for the school with the given UDISE.
     * Returns an empty set when everything should stay visible
     * (no config for the division, division not resolvable, or any error)
     * so callers can safely treat "not in set" as visible.
     */
    public Set<String> getHiddenCodesForUdise(String udiseNo) {
        Set<String> hidden = new HashSet<String>();
        if (udiseNo == null || udiseNo.trim().isEmpty()) return hidden;
        ensureTables();

        String division = getDivisionForUdise(udiseNo);
        if (division == null) return hidden;

        String sql = "SELECT activity_code FROM division_activity_config " +
                     "WHERE division_name = ? AND is_enabled = 0";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, division);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    hidden.add(rs.getString("activity_code"));
                }
            }
        } catch (SQLException e) {
            System.err.println("ActivityVisibilityDAO.getHiddenCodesForUdise failed: " + e.getMessage());
            hidden.clear();
        }
        return hidden;
    }

    /**
     * Resolves a school's division from the students table (the schools
     * table has no division column). Returns null when not resolvable.
     */
    public String getDivisionForUdise(String udiseNo) {
        String sql = "SELECT division FROM students " +
                     "WHERE udise_no = ? AND division IS NOT NULL AND TRIM(division) <> '' " +
                     "AND is_active = 1 LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, udiseNo);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String div = rs.getString("division");
                    return (div != null && !div.trim().isEmpty()) ? div.trim() : null;
                }
            }
        } catch (SQLException e) {
            System.err.println("ActivityVisibilityDAO.getDivisionForUdise failed: " + e.getMessage());
        }
        return null;
    }
}
