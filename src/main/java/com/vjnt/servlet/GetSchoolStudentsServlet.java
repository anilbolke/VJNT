package com.vjnt.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

@WebServlet("/GetSchoolStudentsServlet")
public class GetSchoolStudentsServlet extends HttpServlet {

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
        String udise = request.getParameter("udise");

        JsonObject result = new JsonObject();
        JsonArray studentsArray = new JsonArray();

        try (Connection conn = DatabaseConnection.getConnection()) {

            String studentSql;
            PreparedStatement ps;

            if (udise == null || udise.trim().isEmpty()) {
                if (user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
                    response.getWriter().write("{\"success\": false, \"message\": \"UDISE number required\"}");
                    return;
                }

                studentSql = "SELECT student_id, student_pen, student_name, class_category, gender, " +
                             "marathi_akshara_level, marathi_shabda_level, marathi_vakya_level, marathi_samajpurvak_level, " +
                             "math_akshara_level, math_shabda_level, math_vakya_level, math_samajpurvak_level, " +
                             "english_akshara_level, " +
                             "phase1_marathi, phase1_math, phase1_english, phase1_date, " +
                             "phase2_marathi, phase2_math, phase2_english, phase2_date, " +
                             "phase3_marathi, phase3_math, phase3_english, phase3_date, " +
                             "phase4_marathi, phase4_math, phase4_english, phase4_date, " +
                             "division, district, udise_no " +
                             "FROM students " +
                             // is_active was missing entirely, so deactivated students -
                             // chiefly last year's graduates - were still being listed.
                             "WHERE is_active = 1 " +
                             "AND TRIM(class) IN " + com.vjnt.dao.StudentDAO.CLASS_I_TO_IX + " " +
                             "ORDER BY division, district, udise_no, student_name";

                ps = conn.prepareStatement(studentSql);
            } else {
                studentSql = "SELECT student_id, student_pen, student_name, class_category, gender, " +
                             "marathi_akshara_level, marathi_shabda_level, marathi_vakya_level, marathi_samajpurvak_level, " +
                             "math_akshara_level, math_shabda_level, math_vakya_level, math_samajpurvak_level, " +
                             "english_akshara_level, " +
                             "phase1_marathi, phase1_math, phase1_english, phase1_date, " +
                             "phase2_marathi, phase2_math, phase2_english, phase2_date, " +
                             "phase3_marathi, phase3_math, phase3_english, phase3_date, " +
                             "phase4_marathi, phase4_math, phase4_english, phase4_date " +
                             "FROM students " +
                             "WHERE udise_no = ? AND is_active = 1 " +
                             "AND TRIM(class) IN " + com.vjnt.dao.StudentDAO.CLASS_I_TO_IX + " " +
                             "ORDER BY student_name";

                ps = conn.prepareStatement(studentSql);
                ps.setString(1, udise);
            }

            ResultSet rs = ps.executeQuery();

            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");

            while (rs.next()) {
                JsonObject student = new JsonObject();
                int studentId = rs.getInt("student_id");
                String penNumber = rs.getString("student_pen");

                student.addProperty("studentId", studentId);
                student.addProperty("penNumber", penNumber);
                student.addProperty("name", rs.getString("student_name"));
                student.addProperty("studentClass", rs.getString("class_category"));
                student.addProperty("gender", rs.getString("gender"));

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
                
                // Add numeric values
                student.addProperty("marathiAksharaLevel", marathiAksharaLevelNum);
                student.addProperty("marathiShabdaLevel", marathiShabdaLevelNum);
                student.addProperty("marathiVakyaLevel", marathiVakyaLevelNum);
                student.addProperty("marathiSamajpurvakLevel", marathiSamajpurvakLevelNum);
                
                student.addProperty("mathAksharaLevel", mathAksharaLevelNum);
                student.addProperty("mathShabdaLevel", mathShabdaLevelNum);
                student.addProperty("mathVakyaLevel", mathVakyaLevelNum);
                student.addProperty("mathSamajpurvakLevel", mathSamajpurvakLevelNum);
                
                student.addProperty("englishAksharaLevel", englishAksharaLevelNum);
                
                // Calculate current overall levels (highest achieved level)
                int currentMarathiLevel = Math.max(Math.max(marathiAksharaLevelNum, marathiShabdaLevelNum), 
                                                   Math.max(marathiVakyaLevelNum, marathiSamajpurvakLevelNum));
                int currentMathLevel = Math.max(Math.max(mathAksharaLevelNum, mathShabdaLevelNum), 
                                               Math.max(mathVakyaLevelNum, mathSamajpurvakLevelNum));
                int currentEnglishLevel = englishAksharaLevelNum;
                
                // Add current overall levels
                student.addProperty("marathiLevel", String.valueOf(currentMarathiLevel));
                student.addProperty("mathLevel", String.valueOf(currentMathLevel));
                student.addProperty("englishLevel", String.valueOf(currentEnglishLevel));
                
                // Add text descriptions
                student.addProperty("marathiAksharaLevelText", getMarathiLevelName(marathiAksharaLevelNum));
                student.addProperty("marathiShabdaLevelText", getMarathiLevelName(marathiShabdaLevelNum));
                student.addProperty("marathiVakyaLevelText", getMarathiLevelName(marathiVakyaLevelNum));
                student.addProperty("marathiSamajpurvakLevelText", getMarathiLevelName(marathiSamajpurvakLevelNum));
                
                student.addProperty("mathAksharaLevelText", getMathLevelName(mathAksharaLevelNum));
                student.addProperty("mathShabdaLevelText", getMathLevelName(mathShabdaLevelNum));
                student.addProperty("mathVakyaLevelText", getMathLevelName(mathVakyaLevelNum));
                student.addProperty("mathSamajpurvakLevelText", getMathLevelName(mathSamajpurvakLevelNum));
                
                student.addProperty("englishAksharaLevelText", getEnglishLevelName(englishAksharaLevelNum));

                // Phase-wise levels and dates
                // Phase 1
                Integer phase1Marathi = (Integer) rs.getObject("phase1_marathi");
                Integer phase1Math = (Integer) rs.getObject("phase1_math");
                Integer phase1English = (Integer) rs.getObject("phase1_english");
                Date phase1Date = rs.getDate("phase1_date");
                
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
                Date phase2Date = rs.getDate("phase2_date");
                
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
                Date phase3Date = rs.getDate("phase3_date");
                
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
                Date phase4Date = rs.getDate("phase4_date");
                
                student.addProperty("phase4Marathi", phase4Marathi != null ? phase4Marathi : 0);
                student.addProperty("phase4Math", phase4Math != null ? phase4Math : 0);
                student.addProperty("phase4English", phase4English != null ? phase4English : 0);
                student.addProperty("phase4MarathiText", phase4Marathi != null ? getMarathiLevelName(phase4Marathi) : "स्तर निश्चित केला नाही");
                student.addProperty("phase4MathText", phase4Math != null ? getMathLevelName(phase4Math) : "स्तर निश्चित केला नाही");
                student.addProperty("phase4EnglishText", phase4English != null ? getEnglishLevelName(phase4English) : "स्तर निश्चित केला नाही");
                student.addProperty("phase4Date", phase4Date != null ? sdf.format(phase4Date) : null);

                // Get activities for this student
                JsonArray activities = getStudentActivities(conn, studentId);
                student.add("activities", activities);

                // Get videos for this student
                JsonArray videos = getStudentVideos(conn, penNumber);
                student.add("videos", videos);

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
        case 6: return "English reading and writing FLN level 100% complete";
        default: return "स्तर निश्चित केला नाही";
        }
    }
}
