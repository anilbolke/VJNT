package com.vjnt.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.*;
import java.util.*;

@WebServlet("/GetSchoolActivityAnalysisServlet")
public class GetSchoolActivityAnalysisServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.getWriter().write("{\"success\": false, \"message\": \"Not authenticated\"}");
            return;
        }

        User user = (User) session.getAttribute("user");
        String districtName = user.getDistrictName();
        

        JsonObject result = new JsonObject();
        JsonArray schoolsArray = new JsonArray();

        try (Connection conn = DatabaseConnection.getConnection()) {
            long startTime = System.currentTimeMillis();

            // Get all schools in this district with their activity analysis
            // Optimized query to get student counts in single query
            String schoolSql = "SELECT s.udise_no, " +
                              "COALESCE(sc.school_name, s.udise_no) as school_name, " +
                              "COUNT(*) as total_students " +
                              "FROM students s " +
                              "LEFT JOIN schools sc ON s.udise_no = sc.udise_no " +
                              "WHERE s.district = ? AND s.is_active = 1 " +
                              "GROUP BY s.udise_no, sc.school_name " +
                              "ORDER BY sc.school_name";

            PreparedStatement ps = conn.prepareStatement(schoolSql);
            ps.setString(1, districtName);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                String udiseNo = rs.getString("udise_no");
                String schoolName = rs.getString("school_name");
                int totalStudents = rs.getInt("total_students");

                JsonObject schoolData = new JsonObject();
                schoolData.addProperty("udiseNo", udiseNo);
                schoolData.addProperty("schoolName", schoolName);
                schoolData.addProperty("totalStudents", totalStudents);

                // Get phase-wise analysis
                JsonArray phasesArray = new JsonArray();
                for (int phase = 1; phase <= 4; phase++) {
                    JsonObject phaseData = getPhaseAnalysisOptimized(conn, udiseNo, phase);
                    phasesArray.add(phaseData);
                }
                schoolData.add("phases", phasesArray);

                schoolsArray.add(schoolData);
            }
            
            long endTime = System.currentTimeMillis();

            result.addProperty("success", true);
            result.addProperty("district", districtName);
            result.add("schools", schoolsArray);

        } catch (SQLException e) {
            e.printStackTrace();
            result.addProperty("success", false);
            result.addProperty("message", "Database error: " + e.getMessage());
        }

        response.getWriter().write(new Gson().toJson(result));
    }

    private JsonObject getPhaseAnalysisOptimized(Connection conn, String udiseNo, int phase) throws SQLException {
        JsonObject phaseData = new JsonObject();
        phaseData.addProperty("phaseNumber", phase);

        String dateColumn = "phase" + phase + "_date";
        String marathiColumn = "phase" + phase + "_marathi";
        String mathColumn = "phase" + phase + "_math";
        String englishColumn = "phase" + phase + "_english";

        // Single optimized query to get all subject distributions at once
        String sql = "SELECT " +
                    marathiColumn + " as marathi_level, " +
                    mathColumn + " as math_level, " +
                    englishColumn + " as english_level " +
                    "FROM students " +
                    "WHERE udise_no = ? AND " + dateColumn + " IS NOT NULL";

        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, udiseNo);
        ResultSet rs = ps.executeQuery();

        // Count distributions in memory (faster than multiple DB queries)
        Map<Integer, Integer> marathiMap = new LinkedHashMap<>();
        Map<Integer, Integer> mathMap = new LinkedHashMap<>();
        Map<Integer, Integer> englishMap = new LinkedHashMap<>();

        // Initialize all levels to 0
        for (int i = 0; i <= 6; i++) {
            marathiMap.put(i, 0);
            englishMap.put(i, 0);
        }
        for (int i = 0; i <= 8; i++) {
            mathMap.put(i, 0);
        }

        // Count occurrences
        while (rs.next()) {
            Integer marathiLevel = rs.getObject("marathi_level") != null ? rs.getInt("marathi_level") : 0;
            Integer mathLevel = rs.getObject("math_level") != null ? rs.getInt("math_level") : 0;
            Integer englishLevel = rs.getObject("english_level") != null ? rs.getInt("english_level") : 0;

            marathiMap.put(marathiLevel, marathiMap.get(marathiLevel) + 1);
            mathMap.put(mathLevel, mathMap.get(mathLevel) + 1);
            englishMap.put(englishLevel, englishMap.get(englishLevel) + 1);
        }

        // Convert to JSON arrays
        phaseData.add("marathiLevels", buildLevelArray(marathiMap, "marathi"));
        phaseData.add("mathLevels", buildLevelArray(mathMap, "math"));
        phaseData.add("englishLevels", buildLevelArray(englishMap, "english"));

        return phaseData;
    }

    private JsonArray buildLevelArray(Map<Integer, Integer> levelMap, String subject) {
        JsonArray levelsArray = new JsonArray();
        for (Map.Entry<Integer, Integer> entry : levelMap.entrySet()) {
            JsonObject levelData = new JsonObject();
            levelData.addProperty("level", entry.getKey());
            levelData.addProperty("levelName", getLevelName(entry.getKey(), subject));
            levelData.addProperty("studentCount", entry.getValue());
            levelsArray.add(levelData);
        }
        return levelsArray;
    }

    private JsonObject getPhaseAnalysis(Connection conn, String udiseNo, int phase) throws SQLException {
        JsonObject phaseData = new JsonObject();
        phaseData.addProperty("phaseNumber", phase);

        String dateColumn = "phase" + phase + "_date";
        String marathiColumn = "phase" + phase + "_marathi";
        String mathColumn = "phase" + phase + "_math";
        String englishColumn = "phase" + phase + "_english";

        // Get Marathi level distribution
        JsonArray marathiLevels = getLevelDistribution(conn, udiseNo, marathiColumn, dateColumn, "marathi");
        phaseData.add("marathiLevels", marathiLevels);

        // Get Math level distribution
        JsonArray mathLevels = getLevelDistribution(conn, udiseNo, mathColumn, dateColumn, "math");
        phaseData.add("mathLevels", mathLevels);

        // Get English level distribution
        JsonArray englishLevels = getLevelDistribution(conn, udiseNo, englishColumn, dateColumn, "english");
        phaseData.add("englishLevels", englishLevels);

        return phaseData;
    }

    private JsonArray getLevelDistribution(Connection conn, String udiseNo, String levelColumn, 
                                          String dateColumn, String subject) throws SQLException {
        JsonArray levelsArray = new JsonArray();

        String sql = "SELECT " + levelColumn + " as level, COUNT(*) as count " +
                    "FROM students " +
                    "WHERE udise_no = ? AND " + dateColumn + " IS NOT NULL " +
                    "GROUP BY " + levelColumn + " " +
                    "ORDER BY " + levelColumn;

        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, udiseNo);
        ResultSet rs = ps.executeQuery();

        // Create a map to hold all levels with counts
        Map<Integer, Integer> levelMap = new LinkedHashMap<>();
        
        // Initialize all levels to 0
        int maxLevel = subject.equals("math") ? 8 : 6;
        for (int i = 0; i <= maxLevel; i++) {
            levelMap.put(i, 0);
        }

        // Fill in actual counts
        while (rs.next()) {
            Integer level = rs.getObject("level") != null ? rs.getInt("level") : 0;
            int count = rs.getInt("count");
            levelMap.put(level, count);
        }

        // Build JSON array
        for (Map.Entry<Integer, Integer> entry : levelMap.entrySet()) {
            JsonObject levelData = new JsonObject();
            levelData.addProperty("level", entry.getKey());
            levelData.addProperty("levelName", getLevelName(entry.getKey(), subject));
            levelData.addProperty("studentCount", entry.getValue());
            levelsArray.add(levelData);
        }

        return levelsArray;
    }

    private String getLevelName(int level, String subject) {
        if (subject.equals("marathi")) {
            switch (level) {
                case 0: return "स्तर निश्चित केला नाही";
                case 1: return "प्रारंभिक स्तर";
                case 2: return "अक्षर स्तर";
                case 3: return "शब्द स्तर";
                case 4: return "वाक्य स्तर";
                case 5: return "समजपूर्वक उतारा वाचन स्तर";
                case 6: return "मराठी वाचन व लेखन FLN स्तर 100% पूर्ण";
                default: return "Unknown";
            }
        } else if (subject.equals("math")) {
            switch (level) {
                case 0: return "स्तर निश्चित केला नाही";
                case 1: return "प्रारंभिक स्तर";
                case 2: return "अंक ज्ञान स्तर";
                case 3: return "संख्याज्ञान स्तर";
                case 4: return "बेरीज स्तर";
                case 5: return "वजाबाकी स्तर";
                case 6: return "गुणाकार स्तर";
                case 7: return "भागाकार स्तर";
                case 8: return "गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण";
                default: return "Unknown";
            }
        } else if (subject.equals("english")) {
            switch (level) {
                case 0: return "Level Not Set";
                case 1: return "Beginner level";
                case 2: return "Alphabet level";
                case 3: return "Word level";
                case 4: return "Sentence level";
                case 5: return "Paragraph Reading with Understanding";
                case 6: return "English reading and writing FLN level 100% complete";
                default: return "Unknown";
            }
        }
        return "Unknown";
    }
}
