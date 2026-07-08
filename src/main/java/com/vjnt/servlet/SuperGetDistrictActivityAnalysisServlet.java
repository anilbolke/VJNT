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

/**
 * Super Division Officer version of {@link GetDistrictActivityAnalysisServlet}.
 *
 * The {@code division} parameter is OPTIONAL: missing/empty/"ALL" aggregates every
 * division; a specific division scopes to that division. The per-phase analysis is
 * district-based and unchanged. Existing division servlets are left untouched.
 */
@WebServlet("/super-activity-analysis")
public class SuperGetDistrictActivityAnalysisServlet extends HttpServlet {

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
        if (!user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER)) {
            response.getWriter().write("{\"success\": false, \"message\": \"Access denied\"}");
            return;
        }

        String divisionParam = request.getParameter("division");
        boolean allDivisions = divisionParam == null || divisionParam.trim().isEmpty()
                || "ALL".equalsIgnoreCase(divisionParam.trim());

        JsonObject result = new JsonObject();
        JsonArray districtsArray = new JsonArray();

        try (Connection conn = DatabaseConnection.getConnection()) {

            StringBuilder districtSql = new StringBuilder();
            districtSql.append("SELECT district, COUNT(*) as total_students FROM students WHERE is_active = 1 ");
            if (!allDivisions) {
                districtSql.append("AND division = ? ");
            }
            districtSql.append("GROUP BY district ORDER BY district");

            PreparedStatement ps = conn.prepareStatement(districtSql.toString());
            if (!allDivisions) {
                ps.setString(1, divisionParam);
            }
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                String districtName = rs.getString("district");
                int totalStudents = rs.getInt("total_students");

                JsonObject districtData = new JsonObject();
                districtData.addProperty("districtName", districtName);
                districtData.addProperty("totalStudents", totalStudents);

                JsonArray phasesArray = new JsonArray();
                for (int phase = 1; phase <= 4; phase++) {
                    JsonObject phaseData = getPhaseAnalysisOptimized(conn, districtName, phase);
                    phasesArray.add(phaseData);
                }
                districtData.add("phases", phasesArray);

                districtsArray.add(districtData);
            }

            result.addProperty("success", true);
            result.addProperty("division", allDivisions ? "All Divisions" : divisionParam);
            result.add("districts", districtsArray);

        } catch (SQLException e) {
            e.printStackTrace();
            result.addProperty("success", false);
            result.addProperty("message", "Database error: " + e.getMessage());
        }

        response.getWriter().write(new Gson().toJson(result));
    }

    private JsonObject getPhaseAnalysisOptimized(Connection conn, String districtName, int phase) throws SQLException {
        JsonObject phaseData = new JsonObject();
        phaseData.addProperty("phaseNumber", phase);

        String dateColumn = "phase" + phase + "_date";
        String marathiColumn = "phase" + phase + "_marathi";
        String mathColumn = "phase" + phase + "_math";
        String englishColumn = "phase" + phase + "_english";

        String sql = "SELECT " +
                    marathiColumn + " as marathi_level, " +
                    mathColumn + " as math_level, " +
                    englishColumn + " as english_level " +
                    "FROM students " +
                    "WHERE district = ? AND " + dateColumn + " IS NOT NULL";

        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, districtName);
        ResultSet rs = ps.executeQuery();

        Map<Integer, Integer> marathiMap = new LinkedHashMap<>();
        Map<Integer, Integer> mathMap = new LinkedHashMap<>();
        Map<Integer, Integer> englishMap = new LinkedHashMap<>();

        for (int i = 0; i <= 6; i++) {
            marathiMap.put(i, 0);
            englishMap.put(i, 0);
        }
        for (int i = 0; i <= 8; i++) {
            mathMap.put(i, 0);
        }

        while (rs.next()) {
            Integer marathiLevel = rs.getObject("marathi_level") != null ? rs.getInt("marathi_level") : 0;
            Integer mathLevel = rs.getObject("math_level") != null ? rs.getInt("math_level") : 0;
            Integer englishLevel = rs.getObject("english_level") != null ? rs.getInt("english_level") : 0;

            marathiMap.put(marathiLevel, marathiMap.getOrDefault(marathiLevel, 0) + 1);
            mathMap.put(mathLevel, mathMap.getOrDefault(mathLevel, 0) + 1);
            englishMap.put(englishLevel, englishMap.getOrDefault(englishLevel, 0) + 1);
        }

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
