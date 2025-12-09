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

@WebServlet("/GetDistrictActivityAnalysisServlet")
public class GetDistrictActivityAnalysisServlet extends HttpServlet {

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
        String divisionName = user.getDivisionName();
        
        System.out.println("GetDistrictActivityAnalysisServlet - User: " + user.getUsername());
        System.out.println("GetDistrictActivityAnalysisServlet - Division: " + divisionName);

        JsonObject result = new JsonObject();
        JsonArray districtsArray = new JsonArray();

        try (Connection conn = DatabaseConnection.getConnection()) {

            // Get all districts in this division with their activity analysis
            String districtSql = "SELECT DISTINCT district " +
                                "FROM students " +
                                "WHERE division = ? " +
                                "ORDER BY district";

            PreparedStatement ps = conn.prepareStatement(districtSql);
            ps.setString(1, divisionName);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                String districtName = rs.getString("district");

                JsonObject districtData = new JsonObject();
                districtData.addProperty("districtName", districtName);

                // Get total students in this district
                int totalStudents = getTotalStudents(conn, districtName);
                districtData.addProperty("totalStudents", totalStudents);

                // Get phase-wise analysis
                JsonArray phasesArray = new JsonArray();
                for (int phase = 1; phase <= 4; phase++) {
                    JsonObject phaseData = getPhaseAnalysis(conn, districtName, phase);
                    phasesArray.add(phaseData);
                }
                districtData.add("phases", phasesArray);

                districtsArray.add(districtData);
            }

            result.addProperty("success", true);
            result.addProperty("division", divisionName);
            result.add("districts", districtsArray);

        } catch (SQLException e) {
            e.printStackTrace();
            result.addProperty("success", false);
            result.addProperty("message", "Database error: " + e.getMessage());
        }

        response.getWriter().write(new Gson().toJson(result));
    }

    private int getTotalStudents(Connection conn, String districtName) throws SQLException {
        String sql = "SELECT COUNT(*) as total FROM students WHERE district = ? AND is_active = 1";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, districtName);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            return rs.getInt("total");
        }
        return 0;
    }

    private JsonObject getPhaseAnalysis(Connection conn, String districtName, int phase) throws SQLException {
        JsonObject phaseData = new JsonObject();
        phaseData.addProperty("phaseNumber", phase);

        String dateColumn = "phase" + phase + "_date";
        String marathiColumn = "phase" + phase + "_marathi";
        String mathColumn = "phase" + phase + "_math";
        String englishColumn = "phase" + phase + "_english";

        // Get Marathi level distribution
        JsonArray marathiLevels = getLevelDistribution(conn, districtName, marathiColumn, dateColumn, "marathi");
        phaseData.add("marathiLevels", marathiLevels);

        // Get Math level distribution
        JsonArray mathLevels = getLevelDistribution(conn, districtName, mathColumn, dateColumn, "math");
        phaseData.add("mathLevels", mathLevels);

        // Get English level distribution
        JsonArray englishLevels = getLevelDistribution(conn, districtName, englishColumn, dateColumn, "english");
        phaseData.add("englishLevels", englishLevels);

        return phaseData;
    }

    private JsonArray getLevelDistribution(Connection conn, String districtName, String levelColumn, 
                                          String dateColumn, String subject) throws SQLException {
        JsonArray levelsArray = new JsonArray();

        String sql = "SELECT " + levelColumn + " as level, COUNT(*) as count " +
                    "FROM students " +
                    "WHERE district = ? AND " + dateColumn + " IS NOT NULL " +
                    "GROUP BY " + levelColumn + " " +
                    "ORDER BY " + levelColumn;

        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, districtName);
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
                case 2: return "Letter level";
                case 3: return "Word level";
                case 4: return "Sentence level";
                case 5: return "Reading comprehension and dictation level";
                case 6: return "English reading and writing FLN level 100% complete";
                default: return "Unknown";
            }
        }
        return "Unknown";
    }
}
