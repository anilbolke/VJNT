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

@WebServlet("/GetDivisionStudentsServlet")
public class GetDivisionStudentsServlet extends HttpServlet {

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
        String division = request.getParameter("division");

        if (division == null || division.trim().isEmpty()) {
            response.getWriter().write("{\"success\": false, \"message\": \"Division name required\"}");
            return;
        }

        JsonObject result = new JsonObject();
        JsonArray studentsArray = new JsonArray();

        try (Connection conn = DatabaseConnection.getConnection()) {

            // Get students with their details from all districts in this division
            String studentSql = "SELECT s.student_id, s.student_pen, s.student_name, s.class_category, s.gender, " +
                               "s.marathi_akshara_level, s.marathi_shabda_level, s.marathi_vakya_level, s.marathi_samajpurvak_level, " +
                               "s.math_akshara_level, s.math_shabda_level, s.math_vakya_level, s.math_samajpurvak_level, " +
                               "s.english_akshara_level, " +
                               "s.phase1_marathi, s.phase1_math, s.phase1_english, s.phase1_date, " +
                               "s.phase2_marathi, s.phase2_math, s.phase2_english, s.phase2_date, " +
                               "s.phase3_marathi, s.phase3_math, s.phase3_english, s.phase3_date, " +
                               "s.phase4_marathi, s.phase4_math, s.phase4_english, s.phase4_date, " +
                               "s.district, s.udise_no, sc.school_name " +
                               "FROM students s " +
                               "LEFT JOIN schools sc ON s.udise_no = sc.udise_no " +
                               "WHERE s.division = ? " +
                               "ORDER BY s.district, sc.school_name, s.student_name";

            PreparedStatement ps = conn.prepareStatement(studentSql);
            ps.setString(1, division);
            ResultSet rs = ps.executeQuery();

            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");

            while (rs.next()) {
                JsonObject student = new JsonObject();
                int studentId = rs.getInt("student_id");

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
                student.addProperty("marathiAksharaLevel", getMarathiLevelName(marathiAksharaLevelNum));
                student.addProperty("marathiShabdaLevel", getMarathiLevelName(marathiShabdaLevelNum));
                student.addProperty("marathiVakyaLevel", getMarathiLevelName(marathiVakyaLevelNum));
                student.addProperty("marathiSamajpurvakLevel", getMarathiLevelName(marathiSamajpurvakLevelNum));
                
                student.addProperty("mathAksharaLevel", getMathLevelName(mathAksharaLevelNum));
                student.addProperty("mathShabdaLevel", getMathLevelName(mathShabdaLevelNum));
                student.addProperty("mathVakyaLevel", getMathLevelName(mathVakyaLevelNum));
                student.addProperty("mathSamajpurvakLevel", getMathLevelName(mathSamajpurvakLevelNum));
                
                student.addProperty("englishAksharaLevel", getEnglishLevelName(englishAksharaLevelNum));
                
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
                
                student.addProperty("phase1Date", phase1Date != null ? sdf.format(phase1Date) : null);
                student.addProperty("phase2Date", phase2Date != null ? sdf.format(phase2Date) : null);
                student.addProperty("phase3Date", phase3Date != null ? sdf.format(phase3Date) : null);
                student.addProperty("phase4Date", phase4Date != null ? sdf.format(phase4Date) : null);

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
        case 0: return "स्थर निश्चित केला नाही";
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
        case 0: return "स्थर निश्चित केला नाही";
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
        case 0: return "स्थर निश्चित केला नाही";
        case 1: return "Beginner level";
        case 2: return "Letter level";
        case 3: return "Word level";
        case 4: return "Sentence level";
        case 5: return "Reading comprehension and dictation level";
        case 6: return "English reading and writing FLN level 100% complete";
        default: return "स्तर निश्चित केला नाही";
        }
    }
}
