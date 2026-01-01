package com.vjnt.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.gson.Gson;
import com.vjnt.util.DatabaseConnection;

@WebServlet("/GetStudentPhaseDetailsServlet")
public class GetStudentPhaseDetailsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    // Helper method to get Marathi level text
    private String getMarathiLevelText(int level) {
        switch (level) {
            case 1: return "प्रारंभिक स्तर";
            case 2: return "अक्षर स्तर";
            case 3: return "शब्द स्तर";
            case 4: return "वाक्य स्तर";
            case 5: return "समजपूर्वक उतारा वाचन स्तर";
            case 6: return "मराठी वाचन व लेखन FLN स्तर 100% पूर्ण";
            default: return "स्तर निश्चित केला नाही";
        }
    }
    
    // Helper method to get Math level text
    private String getMathLevelText(int level) {
        switch (level) {
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
    
    // Helper method to get English level text
    private String getEnglishLevelText(int level) {
        switch (level) {
            case 1: return "Beginner level";
            case 2: return "Letter level";
            case 3: return "Word level";
            case 4: return "Sentence level";
            case 5: return "Reading comprehension and dictation level";
            case 6: return "English reading and writing FLN level 100% complete";
            default: return "स्तर निश्चित केला नाही";
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String studentPen = request.getParameter("studentPen");
        
        if (studentPen == null || studentPen.trim().isEmpty()) {
            response.getWriter().write("{\"error\": \"Student PEN is required\"}");
            return;
        }
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            // Query to get student data with all phase numeric levels
            String sql = "SELECT " +
                    "s.student_pen, " +
                    "s.student_name, " +
                    "s.marathi_level, " +
                    "s.math_level, " +
                    "s.english_level, " +
                    "s.phase1_marathi, s.phase1_math, s.phase1_english, " +
                    "s.phase2_marathi, s.phase2_math, s.phase2_english, " +
                    "s.phase3_marathi, s.phase3_math, s.phase3_english, " +
                    "s.phase4_marathi, s.phase4_math, s.phase4_english " +
                    "FROM students s " +
                    "WHERE s.student_pen = ?";
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, studentPen);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                Map<String, Object> result = new HashMap<>();
                
                // Student info
                result.put("studentPen", rs.getString("student_pen"));
                result.put("studentName", rs.getString("student_name"));
                
                // Build phases array
                List<Map<String, Object>> phases = new ArrayList<>();
                int currentPhase = 1;
                
                // Phase 1
                int p1m = rs.getInt("phase1_marathi");
                int p1ma = rs.getInt("phase1_math");
                int p1e = rs.getInt("phase1_english");
                if (p1m > 0 || p1ma > 0 || p1e > 0) {
                    Map<String, Object> phase1 = new HashMap<>();
                    phase1.put("phaseNumber", 1);
                    phase1.put("marathiLevel", getMarathiLevelText(p1m));
                    phase1.put("mathLevel", getMathLevelText(p1ma));
                    phase1.put("englishLevel", getEnglishLevelText(p1e));
                    phase1.put("lastUpdated", "Phase 1 Completed");
                    phase1.put("completed", true);
                    phases.add(phase1);
                    currentPhase = 2;
                }
                
                // Phase 2
                int p2m = rs.getInt("phase2_marathi");
                int p2ma = rs.getInt("phase2_math");
                int p2e = rs.getInt("phase2_english");
                if (p2m > 0 || p2ma > 0 || p2e > 0) {
                    Map<String, Object> phase2 = new HashMap<>();
                    phase2.put("phaseNumber", 2);
                    phase2.put("marathiLevel", getMarathiLevelText(p2m));
                    phase2.put("mathLevel", getMathLevelText(p2ma));
                    phase2.put("englishLevel", getEnglishLevelText(p2e));
                    phase2.put("lastUpdated", "Phase 2 Completed");
                    phase2.put("completed", true);
                    phases.add(phase2);
                    currentPhase = 3;
                }
                
                // Phase 3
                int p3m = rs.getInt("phase3_marathi");
                int p3ma = rs.getInt("phase3_math");
                int p3e = rs.getInt("phase3_english");
                if (p3m > 0 || p3ma > 0 || p3e > 0) {
                    Map<String, Object> phase3 = new HashMap<>();
                    phase3.put("phaseNumber", 3);
                    phase3.put("marathiLevel", getMarathiLevelText(p3m));
                    phase3.put("mathLevel", getMathLevelText(p3ma));
                    phase3.put("englishLevel", getEnglishLevelText(p3e));
                    phase3.put("lastUpdated", "Phase 3 Completed");
                    phase3.put("completed", true);
                    phases.add(phase3);
                    currentPhase = 4;
                }
                
                // Phase 4
                int p4m = rs.getInt("phase4_marathi");
                int p4ma = rs.getInt("phase4_math");
                int p4e = rs.getInt("phase4_english");
                if (p4m > 0 || p4ma > 0 || p4e > 0) {
                    Map<String, Object> phase4 = new HashMap<>();
                    phase4.put("phaseNumber", 4);
                    phase4.put("marathiLevel", getMarathiLevelText(p4m));
                    phase4.put("mathLevel", getMathLevelText(p4ma));
                    phase4.put("englishLevel", getEnglishLevelText(p4e));
                    phase4.put("lastUpdated", "Phase 4 Completed");
                    phase4.put("completed", true);
                    phases.add(phase4);
                    currentPhase = 4;
                }
                
                result.put("phases", phases);
                result.put("currentPhase", currentPhase);
                
                // Calculate overall progress based on completed phases
                int completedPhases = phases.size();
                int overallProgress = (completedPhases * 100) / 4;
                result.put("overallProgress", overallProgress);
                
                // Convert to JSON
                Gson gson = new Gson();
                String json = gson.toJson(result);
                response.getWriter().write(json);
                
            } else {
                response.getWriter().write("{\"error\": \"Student not found\"}");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().write("{\"error\": \"Database error: " + e.getMessage() + "\"}");
        } finally {
            try {
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
