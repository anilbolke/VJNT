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
import java.text.SimpleDateFormat;

@WebServlet("/GetDistrictStudentsServlet")
public class GetDistrictStudentsServlet extends HttpServlet {

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
        String district = request.getParameter("district");

        JsonObject result = new JsonObject();
        JsonArray studentsArray = new JsonArray();

        try (Connection conn = DatabaseConnection.getConnection()) {

            String studentSql;
            PreparedStatement ps;

            if (district == null || district.trim().isEmpty()) {
                if (user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
                    response.getWriter().write("{\"success\": false, \"message\": \"District name required\"}");
                    return;
                }

                studentSql = "SELECT s.student_id, s.student_pen, s.student_name, s.class_category, s.gender, " +
                             "s.marathi_akshara_level, s.marathi_shabda_level, s.marathi_vakya_level, s.marathi_samajpurvak_level, " +
                             "s.math_akshara_level, s.math_shabda_level, s.math_vakya_level, s.math_samajpurvak_level, " +
                             "s.english_akshara_level, " +
                             "s.phase1_marathi, s.phase1_math, s.phase1_english, s.phase1_date, " +
                             "s.phase2_marathi, s.phase2_math, s.phase2_english, s.phase2_date, " +
                             "s.phase3_marathi, s.phase3_math, s.phase3_english, s.phase3_date, " +
                             "s.phase4_marathi, s.phase4_math, s.phase4_english, s.phase4_date, " +
                             "s.district, s.udise_no, sc.school_name " +
                             "FROM students s " +
                             "LEFT JOIN schools sc ON s.udise_no = sc.udise_no COLLATE utf8mb4_unicode_ci " +
                             "ORDER BY s.division, s.district, sc.school_name, s.student_name";

                ps = conn.prepareStatement(studentSql);
            } else {
                studentSql = "SELECT s.student_id, s.student_pen, s.student_name, s.class_category, s.gender, " +
                             "s.marathi_akshara_level, s.marathi_shabda_level, s.marathi_vakya_level, s.marathi_samajpurvak_level, " +
                             "s.math_akshara_level, s.math_shabda_level, s.math_vakya_level, s.math_samajpurvak_level, " +
                             "s.english_akshara_level, " +
                             "s.phase1_marathi, s.phase1_math, s.phase1_english, s.phase1_date, " +
                             "s.phase2_marathi, s.phase2_math, s.phase2_english, s.phase2_date, " +
                             "s.phase3_marathi, s.phase3_math, s.phase3_english, s.phase3_date, " +
                             "s.phase4_marathi, s.phase4_math, s.phase4_english, s.phase4_date, " +
                             "s.district, s.udise_no, sc.school_name " +
                             "FROM students s " +
                             "LEFT JOIN schools sc ON s.udise_no = sc.udise_no COLLATE utf8mb4_unicode_ci " +
                             "WHERE s.district = ? " +
                             "ORDER BY sc.school_name, s.student_name";

                ps = conn.prepareStatement(studentSql);
                ps.setString(1, district);
            }

            ResultSet rs = ps.executeQuery();

            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");

            while (rs.next()) {
                JsonObject student = new JsonObject();
                int studentId = rs.getInt("student_id");
                String penNumber = rs.getString("student_pen");
                student.addProperty("studentId", studentId);
                student.addProperty("penNumber", rs.getString("student_pen"));
                student.addProperty("name", rs.getString("student_name"));
                student.addProperty("studentClass", rs.getString("class_category"));
                student.addProperty("gender", rs.getString("gender"));
                student.addProperty("district", rs.getString("district"));
                student.addProperty("udiseNo", rs.getString("udise_no"));
                student.addProperty("schoolName", rs.getString("school_name"));

                // Current levels - numeric values
                int marathiAksharaLevelNum = rs.getInt("marathi_akshara_level");
                int marathiShabdaLevelNum = rs.getInt("marathi_shabda_level");
                int marathiVakyaLevelNum = rs.getInt("marathi_vakya_level");
                int marathiSamajpurvakLevelNum = rs.getInt("marathi_samajpurvak_level");
                
                int mathAksharaLevelNum = rs.getInt("math_akshara_level");
                int mathShabdaLevelNum = rs.getInt("math_shabda_level");
                int mathVakyaLevelNum = rs.getInt("math_vakya_level");
                int mathSamajpurvakLevelNum = rs.getInt("math_samajpurvak_level");
                
                int englishAksharaLevelNum = rs.getInt("english_akshara_level");
                
                // Add text descriptions
                student.addProperty("marathiAksharaLevelText", getMarathiLevelName(marathiAksharaLevelNum));
                
                student.addProperty("mathAksharaLevelText", getMathLevelName(mathAksharaLevelNum));
                
                student.addProperty("englishAksharaLevelText", getEnglishLevelName(englishAksharaLevelNum));
                
                // Add single current level for each subject (highest level achieved)
                int currentMarathiLevel = Math.max(Math.max(marathiAksharaLevelNum, marathiShabdaLevelNum), 
                                                   Math.max(marathiVakyaLevelNum, marathiSamajpurvakLevelNum));
                int currentMathLevel = Math.max(Math.max(mathAksharaLevelNum, mathShabdaLevelNum), 
                                               Math.max(mathVakyaLevelNum, mathSamajpurvakLevelNum));
                int currentEnglishLevel = englishAksharaLevelNum;
                
                student.addProperty("marathiLevel", String.valueOf(currentMarathiLevel));
                student.addProperty("mathLevel", String.valueOf(currentMathLevel));
                student.addProperty("englishLevel", String.valueOf(currentEnglishLevel));

                // Phase dates
                Date phase1Date = rs.getDate("phase1_date");
                Date phase2Date = rs.getDate("phase2_date");
                Date phase3Date = rs.getDate("phase3_date");
                Date phase4Date = rs.getDate("phase4_date");
                Integer phase1Marathi = (Integer) rs.getObject("phase1_marathi");
                Integer phase1Math = (Integer) rs.getObject("phase1_math");
                Integer phase1English = (Integer) rs.getObject("phase1_english");
                student.addProperty("phase1Date", phase1Date != null ? sdf.format(phase1Date) : null);
                student.addProperty("phase2Date", phase2Date != null ? sdf.format(phase2Date) : null);
                student.addProperty("phase3Date", phase3Date != null ? sdf.format(phase3Date) : null);
                student.addProperty("phase4Date", phase4Date != null ? sdf.format(phase4Date) : null);
                student.addProperty("phase1Marathi", phase1Marathi != null ? phase1Marathi : 0);
                student.addProperty("phase1Math", phase1Math != null ? phase1Math : 0);
                student.addProperty("phase1English", phase1English != null ? phase1English : 0);
                student.addProperty("phase1MarathiText", phase1Marathi != null ? getMarathiLevelName(phase1Marathi) : "स्तर निश्चित केला नाही");
                student.addProperty("phase1MathText", phase1Math != null ? getMathLevelName(phase1Math) : "स्तर निश्चित केला नाही");
                student.addProperty("phase1EnglishText", phase1English != null ? getEnglishLevelName(phase1English) : "स्तर निश्चित केला नाही");
                student.addProperty("phase1Date", phase1Date != null ? sdf.format(phase1Date) : null);
                
                // Phase 2
                Integer phase2Marathi = (Integer) rs.getObject("phase2_marathi");
                Integer phase2Math = (Integer) rs.getObject("phase2_math");
                Integer phase2English = (Integer) rs.getObject("phase2_english");
                
                student.addProperty("phase2Marathi", phase2Marathi != null ? phase2Marathi : 0);
                student.addProperty("phase2Math", phase2Math != null ? phase2Math : 0);
                student.addProperty("phase2English", phase2English != null ? phase2English : 0);
                student.addProperty("phase2MarathiText", phase2Marathi != null ? getMarathiLevelName(phase2Marathi) : "स्तर निश्चित केला नाही");
                student.addProperty("phase2MathText", phase2Math != null ? getMathLevelName(phase2Math) : "स्तर निश्चित केला नाही");
                student.addProperty("phase2EnglishText", phase2English != null ? getEnglishLevelName(phase2English) : "स्तर निश्चित केला नाही");
                student.addProperty("phase2Date", phase2Date != null ? sdf.format(phase2Date) : null);
                
                // Phase 3
                Integer phase3Marathi = (Integer) rs.getObject("phase3_marathi");
                Integer phase3Math = (Integer) rs.getObject("phase3_math");
                Integer phase3English = (Integer) rs.getObject("phase3_english");
                
                student.addProperty("phase3Marathi", phase3Marathi != null ? phase3Marathi : 0);
                student.addProperty("phase3Math", phase3Math != null ? phase3Math : 0);
                student.addProperty("phase3English", phase3English != null ? phase3English : 0);
                student.addProperty("phase3MarathiText", phase3Marathi != null ? getMarathiLevelName(phase3Marathi) : "स्तर निश्चित केला नाही");
                student.addProperty("phase3MathText", phase3Math != null ? getMathLevelName(phase3Math) : "स्तर निश्चित केला नाही");
                student.addProperty("phase3EnglishText", phase3English != null ? getEnglishLevelName(phase3English) : "स्तर निश्चित केला नाही");
                student.addProperty("phase3Date", phase3Date != null ? sdf.format(phase3Date) : null);
                
                // Phase 4
                Integer phase4Marathi = (Integer) rs.getObject("phase4_marathi");
                Integer phase4Math = (Integer) rs.getObject("phase4_math");
                Integer phase4English = (Integer) rs.getObject("phase4_english");
                
                student.addProperty("phase4Marathi", phase4Marathi != null ? phase4Marathi : 0);
                student.addProperty("phase4Math", phase4Math != null ? phase4Math : 0);
                student.addProperty("phase4English", phase4English != null ? phase4English : 0);
                student.addProperty("phase4MarathiText", phase4Marathi != null ? getMarathiLevelName(phase4Marathi) : "स्तर निश्चित केला नाही");
                student.addProperty("phase4MathText", phase4Math != null ? getMathLevelName(phase4Math) : "स्तर निश्चित केला नाही");
                student.addProperty("phase4EnglishText", phase4English != null ? getEnglishLevelName(phase4English) : "स्तर निश्चित केला नाही");
                student.addProperty("phase4Date", phase4Date != null ? sdf.format(phase4Date) : null);

                // Don't load activities and videos initially for performance
                // They will be loaded on-demand via separate requests
                
                studentsArray.add(student);
            }

            result.addProperty("success", true);
            result.add("students", studentsArray);

        } catch (SQLException e) {
            e.printStackTrace();
            result.addProperty("success", false);
            result.addProperty("message", "Database error: " + e.getMessage());
        }

        response.getWriter().write(new Gson().toJson(result));
    }

    private String getMarathiLevelName(int level) {
        switch (level) {
        case 0: return "स्तर निश्चित केला नाही";
    	case 1: return "प्रारंभिक स्तर";
        case 2: return "अक्षर स्तर";
        case 3: return "शब्द स्तर";
        case 4: return "वाक्य स्तर";
        case 5: return "समजपूर्वक उतारा वाचन स्तर";
        case 6: return "मराठी वाचन व लेखन FLN स्तर 100% पूर्ण";
        default: return "स्तर निश्चित केला नाही";
        }
    }

    private String getMathLevelName(int level) {
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
        default: return "स्तर निश्चित केला नाही";
        }
    }

    private String getEnglishLevelName(int level) {
        switch (level) {
        case 0: return "स्तर निश्चित केला नाही";
        case 1: return "Beginner level";
        case 2: return "Alphabet level";
        case 3: return "Word level";
        case 4: return "Sentence level";
        case 5: return "Paragraph Reading with Understanding";
        case 6: return "English reading and writing FLN level 100% complete";
        default: return "स्तर निश्चित केला नाही";
        }
    }
    
    private JsonArray getStudentActivities(Connection conn, int studentId) {
        JsonArray activities = new JsonArray();

        try {
            String activitySql = "SELECT swa.activity_text, swa.language, swa.week_number, swa.day_number, " +
                                "swa.activity_count, swa.assigned_date, swa.completed " +
                                "FROM student_weekly_activities swa " +
                                "WHERE swa.student_id = ? " +
                                "ORDER BY swa.language, swa.week_number DESC, swa.day_number DESC";

            PreparedStatement ps = conn.prepareStatement(activitySql);
            ps.setInt(1, studentId);
            ResultSet rs = ps.executeQuery();

            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");

            while (rs.next()) {
                JsonObject activity = new JsonObject();
                activity.addProperty("activityName", rs.getString("activity_text"));
                activity.addProperty("language", rs.getString("language"));
                activity.addProperty("weekNumber", rs.getInt("week_number"));
                activity.addProperty("dayNumber", rs.getInt("day_number"));
                activity.addProperty("activityCount", rs.getInt("activity_count"));
                
                Date assignedDate = rs.getDate("assigned_date");
                activity.addProperty("assignedDate", assignedDate != null ? sdf.format(assignedDate) : null);
                
                activity.addProperty("completed", rs.getBoolean("completed"));
                activities.add(activity);
            }
        } catch (SQLException e) {
            System.err.println("Error fetching activities: " + e.getMessage());
        }

        return activities;
    }

    private JsonArray getStudentVideos(Connection conn, String penNumber) {
        JsonArray videos = new JsonArray();

        try {
            // Query videos table - match by uploaded_by (student_id) using PEN to get student_id
            String videoSql = "SELECT v.title, v.youtube_url, v.thumbnail_url, v.upload_date, " +
                             "v.category, v.sub_category, v.youtube_video_id " +
                             "FROM videos v " +
                             "INNER JOIN students s ON v.uploaded_by = s.student_id " +
                             "WHERE s.student_pen = ? AND v.status = 'active' " +
                             "ORDER BY v.upload_date DESC";

            PreparedStatement ps = conn.prepareStatement(videoSql);
            ps.setString(1, penNumber);
            ResultSet rs = ps.executeQuery();

            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");

            while (rs.next()) {
                JsonObject video = new JsonObject();
                video.addProperty("title", rs.getString("title"));
                video.addProperty("url", rs.getString("youtube_url"));
                video.addProperty("thumbnailUrl", rs.getString("thumbnail_url"));
                video.addProperty("category", rs.getString("category"));
                video.addProperty("subCategory", rs.getString("sub_category"));
                video.addProperty("videoId", rs.getString("youtube_video_id"));
                
                Timestamp uploadDate = rs.getTimestamp("upload_date");
                video.addProperty("uploadDate", uploadDate != null ? sdf.format(uploadDate) : null);
                
                videos.add(video);
            }
            
            
        } catch (SQLException e) {
            System.err.println("Error fetching videos for PEN " + penNumber + ": " + e.getMessage());
            e.printStackTrace();
        }

        return videos;
    }
}
