package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.json.JSONArray;
import org.json.JSONObject;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

/**
 * District Analytics Servlet
 * Provides analytics data for district dashboard charts
 */
@WebServlet("/district-analytics")
public class DistrictAnalyticsServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        User user = (User) session.getAttribute("user");
        if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                             !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR) &&
                             !user.getUserType().equals(User.UserType.DIVISION))) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        String type = request.getParameter("type");
        String startDate = request.getParameter("startDate");
        String endDate = request.getParameter("endDate");
        String districtName = user.getDistrictName();
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            JSONObject result = new JSONObject();
            
            switch (type) {
                case "palak_melava":
                    result = getPalakMelavaData(districtName, startDate, endDate);
                    break;
                case "student_activities":
                    result = getStudentActivitiesData(districtName, startDate, endDate);
                    break;
                case "student_levels":
                    result = getStudentLevelsData(districtName, startDate, endDate);
                    break;
                case "student_charan":
                    result = getStudentCharanData(districtName, startDate, endDate);
                    break;
                case "phase_completion":
                    String phaseParam = request.getParameter("phase");
                    int phase = phaseParam != null ? Integer.parseInt(phaseParam) : 1;
                    result = getPhaseCompletionData(districtName, phase, startDate, endDate);
                    break;
                case "school_wise_student_count":
                    result = getSchoolWiseStudentCount(districtName, startDate, endDate);
                    break;
                default:
                    result.put("error", "Invalid type parameter");
            }
            
            out.print(result.toString());
            
        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("error", e.getMessage());
            out.print(error.toString());
        }
    }
    
    /**
     * Get Palak Melava (Parent Meeting) statistics
     */
    private JSONObject getPalakMelavaData(String districtName, String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get schools by district
            String schoolSql = "SELECT DISTINCT s.udise_no, s.school_name " +
                              "FROM students st " +
                              "LEFT JOIN schools s ON st.udise_no = s.udise_no " +
                              "WHERE st.district = ?";
            PreparedStatement schoolPs = conn.prepareStatement(schoolSql);
            schoolPs.setString(1, districtName);
            ResultSet schoolRs = schoolPs.executeQuery();
            
            List<String> udiseList = new ArrayList<>();
            Map<String, String> schoolNames = new HashMap<>();
            
            while (schoolRs.next()) {
                String udise = schoolRs.getString("udise_no");
                String schoolName = schoolRs.getString("school_name");
                if (udise != null) {
                    udiseList.add(udise);
                    schoolNames.put(udise, schoolName != null ? schoolName : udise);
                }
            }
            
            // Get Palak Melava data for these schools
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT pm.udise_no, pm.school_name, COUNT(*) as meeting_count, ");
            sql.append("SUM(CAST(pm.total_parents_attended AS UNSIGNED)) as total_parents, ");
            sql.append("MAX(pm.meeting_date) as last_meeting_date ");
            sql.append("FROM palak_melava pm ");
            sql.append("WHERE pm.udise_no IN (");
            
            for (int i = 0; i < udiseList.size(); i++) {
                sql.append("?");
                if (i < udiseList.size() - 1) sql.append(",");
            }
            sql.append(") ");
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                sql.append("AND pm.meeting_date BETWEEN ? AND ? ");
            }
            
            sql.append("GROUP BY pm.udise_no, pm.school_name ");
            sql.append("ORDER BY meeting_count DESC");
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            int paramIndex = 1;
            for (String udise : udiseList) {
                ps.setString(paramIndex++, udise);
            }
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                ps.setString(paramIndex++, startDate);
                ps.setString(paramIndex++, endDate);
            }
            
            ResultSet rs = ps.executeQuery();
            
            JSONArray schoolData = new JSONArray();
            int totalMeetings = 0;
            int totalParents = 0;
            int schoolsWithMeetings = 0;
            
            while (rs.next()) {
                JSONObject school = new JSONObject();
                school.put("udise", rs.getString("udise_no"));
                school.put("schoolName", rs.getString("school_name"));
                school.put("meetingCount", rs.getInt("meeting_count"));
                school.put("totalParents", rs.getInt("total_parents"));
                school.put("lastMeeting", rs.getString("last_meeting_date"));
                schoolData.put(school);
                
                totalMeetings += rs.getInt("meeting_count");
                totalParents += rs.getInt("total_parents");
                schoolsWithMeetings++;
            }
            
            result.put("schools", schoolData);
            result.put("totalSchools", udiseList.size());
            result.put("schoolsWithMeetings", schoolsWithMeetings);
            result.put("totalMeetings", totalMeetings);
            result.put("totalParentsAttended", totalParents);
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Get Student Activities statistics
     */
    private JSONObject getStudentActivitiesData(String districtName, String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get activity summary by school
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT swa.udise_no, swa.language, ");
            sql.append("COUNT(DISTINCT swa.student_id) as student_count, ");
            sql.append("SUM(swa.activity_count) as total_activities, ");
            sql.append("COUNT(*) as unique_activities ");
            sql.append("FROM student_weekly_activities swa ");
            sql.append("INNER JOIN students s ON swa.student_id = s.student_id ");
            sql.append("WHERE s.district = ? ");
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                sql.append("AND swa.assigned_date BETWEEN ? AND ? ");
            }
            
            sql.append("GROUP BY swa.udise_no, swa.language ");
            sql.append("ORDER BY swa.udise_no, swa.language");
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            ps.setString(1, districtName);
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                ps.setString(2, startDate);
                ps.setString(3, endDate);
            }
            
            ResultSet rs = ps.executeQuery();
            
            JSONArray activityData = new JSONArray();
            Map<String, Integer> languageCount = new HashMap<>();
            Map<String, Integer> schoolActivityCount = new HashMap<>();
            int totalActivities = 0;
            int totalStudents = 0;
            
            while (rs.next()) {
                JSONObject activity = new JSONObject();
                String udise = rs.getString("udise_no");
                String language = rs.getString("language");
                int studentCount = rs.getInt("student_count");
                int activityTotal = rs.getInt("total_activities");
                
                activity.put("udise", udise);
                activity.put("language", language);
                activity.put("studentCount", studentCount);
                activity.put("totalActivities", activityTotal);
                activity.put("uniqueActivities", rs.getInt("unique_activities"));
                activityData.put(activity);
                
                languageCount.put(language, languageCount.getOrDefault(language, 0) + activityTotal);
                schoolActivityCount.put(udise, schoolActivityCount.getOrDefault(udise, 0) + activityTotal);
                totalActivities += activityTotal;
                totalStudents += studentCount;
            }
            
            result.put("activities", activityData);
            result.put("languageBreakdown", new JSONObject(languageCount));
            result.put("schoolActivityCount", new JSONObject(schoolActivityCount));
            result.put("totalActivities", totalActivities);
            result.put("totalStudentsWithActivities", totalStudents);
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Get Student Levels distribution
     */
    private JSONObject getStudentLevelsData(String districtName, String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get level distribution by subject
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT ");
            sql.append("SUM(CASE WHEN marathi_level IS NOT NULL THEN 1 ELSE 0 END) as marathi_count, ");
            sql.append("SUM(CASE WHEN math_level IS NOT NULL THEN 1 ELSE 0 END) as math_count, ");
            sql.append("SUM(CASE WHEN english_level IS NOT NULL THEN 1 ELSE 0 END) as english_count, ");
            sql.append("marathi_level, math_level, english_level, udise_no ");
            sql.append("FROM students ");
            sql.append("WHERE district = ? ");
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                sql.append("AND created_date BETWEEN ? AND ? ");
            }
            
            sql.append("GROUP BY marathi_level, math_level, english_level, udise_no");
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            ps.setString(1, districtName);
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                ps.setString(2, startDate);
                ps.setString(3, endDate);
            }
            
            ResultSet rs = ps.executeQuery();
            
            Map<String, Integer> marathiLevels = new HashMap<>();
            Map<String, Integer> mathLevels = new HashMap<>();
            Map<String, Integer> englishLevels = new HashMap<>();
            Map<String, Map<String, Integer>> schoolLevels = new HashMap<>();
            
            while (rs.next()) {
                String marathiLevel = rs.getString("marathi_level");
                String mathLevel = rs.getString("math_level");
                String englishLevel = rs.getString("english_level");
                String udise = rs.getString("udise_no");
                
                if (marathiLevel != null) {
                    marathiLevels.put(marathiLevel, marathiLevels.getOrDefault(marathiLevel, 0) + 1);
                }
                if (mathLevel != null) {
                    mathLevels.put(mathLevel, mathLevels.getOrDefault(mathLevel, 0) + 1);
                }
                if (englishLevel != null) {
                    englishLevels.put(englishLevel, englishLevels.getOrDefault(englishLevel, 0) + 1);
                }
            }
            
            result.put("marathiLevels", new JSONObject(marathiLevels));
            result.put("mathLevels", new JSONObject(mathLevels));
            result.put("englishLevels", new JSONObject(englishLevels));
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Get Student Charan (Detailed Level) statistics
     */
    private JSONObject getStudentCharanData(String districtName, String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get detailed phase-wise data with school names
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT st.udise_no, s.school_name, ");
            sql.append("AVG(COALESCE(st.marathi_akshara_level, 0)) as avg_marathi_akshara, ");
            sql.append("AVG(COALESCE(st.marathi_shabda_level, 0)) as avg_marathi_shabda, ");
            sql.append("AVG(COALESCE(st.marathi_vakya_level, 0)) as avg_marathi_vakya, ");
            sql.append("AVG(COALESCE(st.marathi_samajpurvak_level, 0)) as avg_marathi_samaj, ");
            sql.append("AVG(COALESCE(st.math_akshara_level, 0)) as avg_math_akshara, ");
            sql.append("AVG(COALESCE(st.math_shabda_level, 0)) as avg_math_shabda, ");
            sql.append("AVG(COALESCE(st.math_vakya_level, 0)) as avg_math_vakya, ");
            sql.append("AVG(COALESCE(st.math_samajpurvak_level, 0)) as avg_math_samaj, ");
            sql.append("COUNT(*) as student_count ");
            sql.append("FROM students st ");
            sql.append("LEFT JOIN schools s ON st.udise_no = s.udise_no ");
            sql.append("WHERE st.district = ? ");
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                sql.append("AND st.created_date BETWEEN ? AND ? ");
            }
            
            sql.append("GROUP BY st.udise_no, s.school_name ");
            sql.append("ORDER BY st.udise_no");
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            ps.setString(1, districtName);
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                ps.setString(2, startDate);
                ps.setString(3, endDate);
            }
            
            ResultSet rs = ps.executeQuery();
            
            JSONArray charanData = new JSONArray();
            JSONObject marathiCharan = new JSONObject();
            JSONObject mathCharan = new JSONObject();
            
            double totalMarathiAkshara = 0, totalMarathiShabda = 0, totalMarathiVakya = 0, totalMarathiSamaj = 0;
            double totalMathAkshara = 0, totalMathShabda = 0, totalMathVakya = 0, totalMathSamaj = 0;
            int schoolCount = 0;
            
            while (rs.next()) {
                JSONObject school = new JSONObject();
                school.put("udise", rs.getString("udise_no"));
                school.put("schoolName", rs.getString("school_name"));
                school.put("studentCount", rs.getInt("student_count"));
                
                JSONObject marathi = new JSONObject();
                marathi.put("akshara", rs.getDouble("avg_marathi_akshara"));
                marathi.put("shabda", rs.getDouble("avg_marathi_shabda"));
                marathi.put("vakya", rs.getDouble("avg_marathi_vakya"));
                marathi.put("samajpurvak", rs.getDouble("avg_marathi_samaj"));
                school.put("marathi", marathi);
                
                JSONObject math = new JSONObject();
                math.put("akshara", rs.getDouble("avg_math_akshara"));
                math.put("shabda", rs.getDouble("avg_math_shabda"));
                math.put("vakya", rs.getDouble("avg_math_vakya"));
                math.put("samajpurvak", rs.getDouble("avg_math_samaj"));
                school.put("math", math);
                
                charanData.put(school);
                
                totalMarathiAkshara += rs.getDouble("avg_marathi_akshara");
                totalMarathiShabda += rs.getDouble("avg_marathi_shabda");
                totalMarathiVakya += rs.getDouble("avg_marathi_vakya");
                totalMarathiSamaj += rs.getDouble("avg_marathi_samaj");
                
                totalMathAkshara += rs.getDouble("avg_math_akshara");
                totalMathShabda += rs.getDouble("avg_math_shabda");
                totalMathVakya += rs.getDouble("avg_math_vakya");
                totalMathSamaj += rs.getDouble("avg_math_samaj");
                
                schoolCount++;
            }
            
            // Calculate district averages
            if (schoolCount > 0) {
                marathiCharan.put("akshara", totalMarathiAkshara / schoolCount);
                marathiCharan.put("shabda", totalMarathiShabda / schoolCount);
                marathiCharan.put("vakya", totalMarathiVakya / schoolCount);
                marathiCharan.put("samajpurvak", totalMarathiSamaj / schoolCount);
                
                mathCharan.put("akshara", totalMathAkshara / schoolCount);
                mathCharan.put("shabda", totalMathShabda / schoolCount);
                mathCharan.put("vakya", totalMathVakya / schoolCount);
                mathCharan.put("samajpurvak", totalMathSamaj / schoolCount);
            }
            
            result.put("schoolData", charanData);
            result.put("districtMarathiAverage", marathiCharan);
            result.put("districtMathAverage", mathCharan);
            result.put("totalSchools", schoolCount);
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Get Phase Completion statistics by school
     */
    private JSONObject getPhaseCompletionData(String districtName, int phase, String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get schools in district with their phase completion status
            String sql = "SELECT DISTINCT s.udise_no, s.school_name, " +
                        "COUNT(DISTINCT st.student_id) as total_students, " +
                        "COUNT(DISTINCT CASE WHEN st.phase" + phase + "_date IS NOT NULL THEN st.student_id END) as completed_students " +
                        "FROM students st " +
                        "JOIN schools s ON st.udise_no = s.udise_no " +
                        "WHERE st.district = ? " +
                        "GROUP BY s.udise_no, s.school_name " +
                        "ORDER BY s.school_name";
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, districtName);
            ResultSet rs = stmt.executeQuery();
            
            JSONArray schools = new JSONArray();
            int totalCompleted = 0;
            int totalStudents = 0;
            
            while (rs.next()) {
                JSONObject school = new JSONObject();
                String udiseNo = rs.getString("udise_no");
                String schoolName = rs.getString("school_name");
                int schoolTotalStudents = rs.getInt("total_students");
                int schoolCompletedStudents = rs.getInt("completed_students");
                
                double completionPercentage = schoolTotalStudents > 0 ? 
                    (schoolCompletedStudents * 100.0 / schoolTotalStudents) : 0.0;
                
                school.put("udiseNo", udiseNo);
                school.put("schoolName", schoolName);
                school.put("totalCount", schoolTotalStudents);
                school.put("completedCount", schoolCompletedStudents);
                school.put("completionPercentage", Math.round(completionPercentage * 10.0) / 10.0);
                
                schools.put(school);
                
                totalCompleted += schoolCompletedStudents;
                totalStudents += schoolTotalStudents;
            }
            
            double overallCompletion = totalStudents > 0 ? 
                (totalCompleted * 100.0 / totalStudents) : 0.0;
            
            result.put("schools", schools);
            result.put("totalStudents", totalStudents);
            result.put("totalCompleted", totalCompleted);
            result.put("overallCompletionPercentage", Math.round(overallCompletion * 10.0) / 10.0);
            result.put("phase", phase);
            
            rs.close();
            stmt.close();
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Get School-wise Student Count with date filtering
     */
    private JSONObject getSchoolWiseStudentCount(String districtName, String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get school-wise student count with optional date filtering
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT s.udise_no, s.school_name, ");
            sql.append("COUNT(DISTINCT st.student_id) as student_count, ");
            sql.append("COUNT(DISTINCT CASE WHEN st.gender = 'Male' THEN st.student_id END) as male_count, ");
            sql.append("COUNT(DISTINCT CASE WHEN st.gender = 'Female' THEN st.student_id END) as female_count, ");
            sql.append("COUNT(DISTINCT st.standard) as standard_count, ");
            sql.append("MIN(st.created_date) as first_student_date, ");
            sql.append("MAX(st.created_date) as last_student_date ");
            sql.append("FROM students st ");
            sql.append("LEFT JOIN schools s ON st.udise_no = s.udise_no ");
            sql.append("WHERE st.district = ? ");
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                sql.append("AND st.created_date BETWEEN ? AND ? ");
            }
            
            sql.append("GROUP BY s.udise_no, s.school_name ");
            sql.append("ORDER BY student_count DESC, s.school_name");
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            ps.setString(1, districtName);
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                ps.setString(2, startDate);
                ps.setString(3, endDate);
            }
            
            ResultSet rs = ps.executeQuery();
            
            JSONArray schoolData = new JSONArray();
            int totalStudents = 0;
            int totalMale = 0;
            int totalFemale = 0;
            int totalSchools = 0;
            
            while (rs.next()) {
                JSONObject school = new JSONObject();
                String udise = rs.getString("udise_no");
                String schoolName = rs.getString("school_name");
                int studentCount = rs.getInt("student_count");
                int maleCount = rs.getInt("male_count");
                int femaleCount = rs.getInt("female_count");
                
                school.put("udiseNo", udise != null ? udise : "N/A");
                school.put("schoolName", schoolName != null ? schoolName : "Unknown School");
                school.put("totalStudents", studentCount);
                school.put("maleStudents", maleCount);
                school.put("femaleStudents", femaleCount);
                school.put("standardCount", rs.getInt("standard_count"));
                school.put("firstStudentDate", rs.getString("first_student_date"));
                school.put("lastStudentDate", rs.getString("last_student_date"));
                
                schoolData.put(school);
                
                totalStudents += studentCount;
                totalMale += maleCount;
                totalFemale += femaleCount;
                totalSchools++;
            }
            
            result.put("schools", schoolData);
            result.put("totalSchools", totalSchools);
            result.put("totalStudents", totalStudents);
            result.put("totalMaleStudents", totalMale);
            result.put("totalFemaleStudents", totalFemale);
            result.put("districtName", districtName);
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                result.put("dateFilter", true);
                result.put("startDate", startDate);
                result.put("endDate", endDate);
            } else {
                result.put("dateFilter", false);
            }
            
            rs.close();
            ps.close();
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
}
