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
 * Division Analytics Servlet
 * Provides analytics data for division dashboard charts showing district-wise data
 */
@WebServlet("/division-analytics")
public class DivisionAnalyticsServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        User user = (User) session.getAttribute("user");
        if (user == null || (!user.getUserType().equals(User.UserType.DIVISION) && 
                             !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        String type = request.getParameter("type");
        String startDate = request.getParameter("startDate");
        String endDate = request.getParameter("endDate");
        
        // Trim date parameters
        if (startDate != null) {
            startDate = startDate.trim();
            if (startDate.isEmpty()) startDate = null;
        }
        if (endDate != null) {
            endDate = endDate.trim();
            if (endDate.isEmpty()) endDate = null;
        }
        
        String divisionName = user.getDivisionName();
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            JSONObject result = new JSONObject();
            
            // Check if type parameter is provided
            if (type == null || type.trim().isEmpty()) {
                result.put("error", "Type parameter is required");
                result.put("validTypes", new String[]{"palak_melava", "student_activities", "student_levels", "student_charan", "phase_completion"});
                out.print(result.toString());
                return;
            }
            
            switch (type) {
                case "palak_melava":
                    result = getPalakMelavaData(divisionName, startDate, endDate);
                    break;
                case "student_activities":
                    result = getStudentActivitiesData(divisionName, startDate, endDate);
                    break;
                case "student_levels":
                    result = getStudentLevelsData(divisionName, startDate, endDate);
                    break;
                case "student_charan":
                    result = getStudentCharanData(divisionName, startDate, endDate);
                    break;
                case "phase_completion":
                    String phaseParam = request.getParameter("phase");
                    int phase = phaseParam != null ? Integer.parseInt(phaseParam) : 1;
                    result = getPhaseCompletionData(divisionName, phase, startDate, endDate);
                    break;
                default:
                    result.put("error", "Invalid type parameter: " + type);
                    result.put("validTypes", new String[]{"palak_melava", "student_activities", "student_levels", "student_charan", "phase_completion"});
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
     * Get Palak Melava (Parent Meeting) statistics district-wise
     */
    private JSONObject getPalakMelavaData(String divisionName, String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get district-wise Palak Melava data
            // Query from palak_melava, join schools for district_name, filter by division from students
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT sch.district_name as district, ");
            sql.append("COUNT(DISTINCT pm.melava_id) as meeting_count, ");
            sql.append("SUM(CAST(pm.total_parents_attended AS UNSIGNED)) as total_parents, ");
            sql.append("MAX(pm.meeting_date) as last_meeting_date, ");
            sql.append("COUNT(DISTINCT pm.udise_no) as schools_with_meetings ");
            sql.append("FROM palak_melava pm ");
            sql.append("INNER JOIN schools sch ON pm.udise_no = sch.udise_no COLLATE utf8mb4_unicode_ci ");
            sql.append("WHERE pm.udise_no IN (SELECT DISTINCT udise_no FROM students WHERE division = ? AND is_active = 1) ");
            
            boolean hasDateFilter = (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty());
            if (hasDateFilter) {
                sql.append("AND DATE(pm.meeting_date) BETWEEN ? AND ? ");
            }
            
            sql.append("GROUP BY sch.district_name ");
            sql.append("ORDER BY meeting_count DESC");
            
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            int paramIndex = 1;
            ps.setString(paramIndex++, divisionName);
            
            if (hasDateFilter) {
                ps.setString(paramIndex++, startDate);
                ps.setString(paramIndex++, endDate);
            } else {
            }
            
	            ResultSet rs = ps.executeQuery();
            
            
            JSONArray districtData = new JSONArray();
            int totalMeetings = 0;
            int totalParents = 0;
            int totalSchoolsWithMeetings = 0;
            
            while (rs.next()) {
                JSONObject district = new JSONObject();
                district.put("districtName", rs.getString("district"));
                district.put("meetingCount", rs.getInt("meeting_count"));
                district.put("totalParents", rs.getInt("total_parents"));
                district.put("schoolsWithMeetings", rs.getInt("schools_with_meetings"));
                district.put("lastMeeting", rs.getString("last_meeting_date"));
                districtData.put(district);
                
                totalMeetings += rs.getInt("meeting_count");
                totalParents += rs.getInt("total_parents");
                totalSchoolsWithMeetings += rs.getInt("schools_with_meetings");
            }
            
         
            if (hasDateFilter) {
            }
            
            result.put("districts", districtData);
            result.put("totalMeetings", totalMeetings);
            result.put("totalParentsAttended", totalParents);
            result.put("totalSchoolsWithMeetings", totalSchoolsWithMeetings);
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Get Student Activities statistics district-wise
     */
    private JSONObject getStudentActivitiesData(String divisionName, String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get activity summary by district
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT s.district, swa.language, ");
            sql.append("COUNT(DISTINCT swa.student_id) as student_count, ");
            sql.append("SUM(swa.activity_count) as total_activities, ");
            sql.append("COUNT(*) as unique_activities ");
            sql.append("FROM student_weekly_activities swa ");
            sql.append("INNER JOIN students s ON swa.student_id = s.student_id ");
            // Current cohort only: without this, activity records belonging to last year's
            // graduates keep counting toward this year's participation figures.
            sql.append("WHERE s.division = ? AND s.is_active = 1 ");
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                sql.append("AND swa.assigned_date BETWEEN ? AND ? ");
            }
            
            sql.append("GROUP BY s.district, swa.language ");
            sql.append("ORDER BY s.district, swa.language");
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            ps.setString(1, divisionName);
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                ps.setString(2, startDate);
                ps.setString(3, endDate);
            }
            
            ResultSet rs = ps.executeQuery();
            
            JSONArray activityData = new JSONArray();
            Map<String, Integer> districtActivityCount = new HashMap<>();
            Map<String, Integer> languageCount = new HashMap<>();
            int totalActivities = 0;
            int totalStudents = 0;
            
            while (rs.next()) {
                JSONObject activity = new JSONObject();
                String district = rs.getString("district");
                String language = rs.getString("language");
                int studentCount = rs.getInt("student_count");
                int activityTotal = rs.getInt("total_activities");
                
                activity.put("district", district);
                activity.put("language", language);
                activity.put("studentCount", studentCount);
                activity.put("totalActivities", activityTotal);
                activity.put("uniqueActivities", rs.getInt("unique_activities"));
                activityData.put(activity);
                
                districtActivityCount.put(district, districtActivityCount.getOrDefault(district, 0) + activityTotal);
                languageCount.put(language, languageCount.getOrDefault(language, 0) + activityTotal);
                totalActivities += activityTotal;
                totalStudents += studentCount;
            }
            
            result.put("activities", activityData);
            result.put("districtActivityCount", new JSONObject(districtActivityCount));
            result.put("languageBreakdown", new JSONObject(languageCount));
            result.put("totalActivities", totalActivities);
            result.put("totalStudentsWithActivities", totalStudents);
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Get Student Levels distribution district-wise
     */
    private JSONObject getStudentLevelsData(String divisionName, String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get level distribution by district and subject
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT district, ");
            sql.append("SUM(CASE WHEN marathi_level IS NOT NULL THEN 1 ELSE 0 END) as marathi_count, ");
            sql.append("SUM(CASE WHEN math_level IS NOT NULL THEN 1 ELSE 0 END) as math_count, ");
            sql.append("SUM(CASE WHEN english_level IS NOT NULL THEN 1 ELSE 0 END) as english_count, ");
            sql.append("marathi_level, math_level, english_level ");
            sql.append("FROM students ");
            // Current cohort only: graduates left active here would inflate the level counts.
            sql.append("WHERE division = ? AND is_active = 1 ");
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                sql.append("AND created_date BETWEEN ? AND ? ");
            }
            
            sql.append("GROUP BY district, marathi_level, math_level, english_level");
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            ps.setString(1, divisionName);
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                ps.setString(2, startDate);
                ps.setString(3, endDate);
            }
            
            ResultSet rs = ps.executeQuery();
            
            JSONObject districtLevels = new JSONObject();
            Map<String, Integer> marathiLevels = new HashMap<>();
            Map<String, Integer> mathLevels = new HashMap<>();
            Map<String, Integer> englishLevels = new HashMap<>();
            
            while (rs.next()) {
                String district = rs.getString("district");
                String marathiLevel = rs.getString("marathi_level");
                String mathLevel = rs.getString("math_level");
                String englishLevel = rs.getString("english_level");
                
                if (!districtLevels.has(district)) {
                    districtLevels.put(district, new JSONObject());
                }
                
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
            
            result.put("districtLevels", districtLevels);
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
     * Get Student Charan (Detailed Level) statistics district-wise
     */
    private JSONObject getStudentCharanData(String divisionName, String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get detailed phase-wise data by district
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT st.district, ");
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
            // Current cohort only: graduates finished at high levels and would drag the
            // averages upward, masking a genuine drop in the new intake.
            sql.append("WHERE st.division = ? AND st.is_active = 1 ");
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                sql.append("AND st.created_date BETWEEN ? AND ? ");
            }
            
            sql.append("GROUP BY st.district ");
            sql.append("ORDER BY st.district");
            
            PreparedStatement ps = conn.prepareStatement(sql.toString());
            ps.setString(1, divisionName);
            
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                ps.setString(2, startDate);
                ps.setString(3, endDate);
            }
            
            ResultSet rs = ps.executeQuery();
            
            JSONArray districtData = new JSONArray();
            JSONObject divisionMarathiCharan = new JSONObject();
            JSONObject divisionMathCharan = new JSONObject();
            
            double totalMarathiAkshara = 0, totalMarathiShabda = 0, totalMarathiVakya = 0, totalMarathiSamaj = 0;
            double totalMathAkshara = 0, totalMathShabda = 0, totalMathVakya = 0, totalMathSamaj = 0;
            int districtCount = 0;
            
            while (rs.next()) {
                JSONObject district = new JSONObject();
                district.put("districtName", rs.getString("district"));
                district.put("studentCount", rs.getInt("student_count"));
                
                JSONObject marathi = new JSONObject();
                marathi.put("akshara", rs.getDouble("avg_marathi_akshara"));
                marathi.put("shabda", rs.getDouble("avg_marathi_shabda"));
                marathi.put("vakya", rs.getDouble("avg_marathi_vakya"));
                marathi.put("samajpurvak", rs.getDouble("avg_marathi_samaj"));
                district.put("marathi", marathi);
                
                JSONObject math = new JSONObject();
                math.put("akshara", rs.getDouble("avg_math_akshara"));
                math.put("shabda", rs.getDouble("avg_math_shabda"));
                math.put("vakya", rs.getDouble("avg_math_vakya"));
                math.put("samajpurvak", rs.getDouble("avg_math_samaj"));
                district.put("math", math);
                
                districtData.put(district);
                
                totalMarathiAkshara += rs.getDouble("avg_marathi_akshara");
                totalMarathiShabda += rs.getDouble("avg_marathi_shabda");
                totalMarathiVakya += rs.getDouble("avg_marathi_vakya");
                totalMarathiSamaj += rs.getDouble("avg_marathi_samaj");
                
                totalMathAkshara += rs.getDouble("avg_math_akshara");
                totalMathShabda += rs.getDouble("avg_math_shabda");
                totalMathVakya += rs.getDouble("avg_math_vakya");
                totalMathSamaj += rs.getDouble("avg_math_samaj");
                
                districtCount++;
            }
            
            // Calculate division averages
            if (districtCount > 0) {
                divisionMarathiCharan.put("akshara", totalMarathiAkshara / districtCount);
                divisionMarathiCharan.put("shabda", totalMarathiShabda / districtCount);
                divisionMarathiCharan.put("vakya", totalMarathiVakya / districtCount);
                divisionMarathiCharan.put("samajpurvak", totalMarathiSamaj / districtCount);
                
                divisionMathCharan.put("akshara", totalMathAkshara / districtCount);
                divisionMathCharan.put("shabda", totalMathShabda / districtCount);
                divisionMathCharan.put("vakya", totalMathVakya / districtCount);
                divisionMathCharan.put("samajpurvak", totalMathSamaj / districtCount);
            }
            
            result.put("districtData", districtData);
            result.put("divisionMarathiAverage", divisionMarathiCharan);
            result.put("divisionMathAverage", divisionMathCharan);
            result.put("totalDistricts", districtCount);
            
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Get Phase Completion statistics by district
     * Phase is considered complete ONLY if approved by Head Master
     * Returns count of approved SCHOOLS (not districts)
     */
    private JSONObject getPhaseCompletionData(String divisionName, int phase, String startDate, String endDate) {
        JSONObject result = new JSONObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // School counts come from the schools master, NOT from students. Counting
            // DISTINCT udise_no in students only ever sees schools that happen to have
            // students on file, so the dashboard total never matched the real school count.
            // Phase state comes entirely from phase_approvals: APPROVED / PENDING /
            // REJECTED, and "not started" is simply the absence of a row for that phase.
            // students is touched only to resolve which districts belong to the division -
            // the schools table has no division column of its own.
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT s.district_name AS district, ");
            sql.append("COUNT(DISTINCT s.udise_no) AS total_schools, ");
            sql.append("COUNT(DISTINCT CASE WHEN pa.approval_status = 'APPROVED' THEN s.udise_no END) AS approved_schools, ");
            sql.append("COUNT(DISTINCT CASE WHEN pa.approval_status = 'PENDING'  THEN s.udise_no END) AS pending_schools, ");
            sql.append("COUNT(DISTINCT CASE WHEN pa.approval_status = 'REJECTED' THEN s.udise_no END) AS rejected_schools, ");
            sql.append("COUNT(DISTINCT CASE WHEN pa.approval_status IS NULL      THEN s.udise_no END) AS not_started_schools, ");
            // Student figures are the ones the school itself submitted with the phase.
            sql.append("COALESCE(SUM(pa.total_students), 0) AS total_students, ");
            sql.append("COALESCE(SUM(CASE WHEN pa.approval_status = 'APPROVED' THEN pa.completed_students END), 0) AS completed_students ");
            sql.append("FROM schools s ");
            sql.append("LEFT JOIN phase_approvals pa ");
            sql.append("       ON s.udise_no COLLATE utf8mb4_unicode_ci = pa.udise_no COLLATE utf8mb4_unicode_ci ");
            sql.append("      AND pa.phase_number = ? ");
            
            // In the JOIN, not the WHERE: in the WHERE this would turn the LEFT JOIN into an
            // INNER JOIN and drop every school without an approval in the date range -
            // exactly the not-started schools the chart needs to show.
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                sql.append("      AND pa.approved_date BETWEEN ? AND ? ");
            }
            
            sql.append("WHERE s.district_name COLLATE utf8mb4_unicode_ci IN ");
            sql.append("      (SELECT DISTINCT st.district COLLATE utf8mb4_unicode_ci ");
            sql.append("       FROM students st WHERE st.division = ?) ");
            sql.append("GROUP BY s.district_name ");
            sql.append("ORDER BY s.district_name");
            
            PreparedStatement stmt = conn.prepareStatement(sql.toString());
            int paramIndex = 1;
            stmt.setInt(paramIndex++, phase);
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                stmt.setString(paramIndex++, startDate);
                stmt.setString(paramIndex++, endDate);
            }
            stmt.setString(paramIndex++, divisionName);
            
            ResultSet rs = stmt.executeQuery();
            
            JSONArray districts = new JSONArray();
            int totalApprovedSchools = 0;
            int totalPendingSchools = 0;
            int totalRejectedSchools = 0;
            int totalNotStartedSchools = 0;
            int totalSchools = 0;
            int totalStudents = 0;
            int totalCompletedStudents = 0;
            int districtsWithAllSchoolsComplete = 0;
            
            while (rs.next()) {
                JSONObject district = new JSONObject();
                String districtName        = rs.getString("district");
                int districtTotalSchools   = rs.getInt("total_schools");
                int districtApproved       = rs.getInt("approved_schools");
                int districtPending        = rs.getInt("pending_schools");
                int districtRejected       = rs.getInt("rejected_schools");
                int districtNotStarted     = rs.getInt("not_started_schools");
                int districtTotalStudents  = rs.getInt("total_students");
                int districtCompletedStuds = rs.getInt("completed_students");
                
                double completionPercentage = districtTotalSchools > 0 ?
                    (districtApproved * 100.0 / districtTotalSchools) : 0.0;
                
                if (completionPercentage >= 100.0) {
                    districtsWithAllSchoolsComplete++;
                }
                
                district.put("districtName", districtName);
                district.put("totalSchools", districtTotalSchools);
                district.put("schoolCount", districtTotalSchools);
                district.put("completedSchools", districtApproved);
                district.put("approvedSchools", districtApproved);
                district.put("pendingSchools", districtPending);
                district.put("rejectedSchools", districtRejected);
                district.put("notStartedSchools", districtNotStarted);
                // Retained for callers still reading the old key: everything submitted but
                // not yet approved, i.e. pending plus rejected.
                district.put("incompleteSchools", districtPending + districtRejected);
                district.put("totalStudents", districtTotalStudents);
                district.put("completedStudents", districtCompletedStuds);
                district.put("completionPercentage", Math.round(completionPercentage * 10.0) / 10.0);
                
                districts.put(district);
                
                totalApprovedSchools   += districtApproved;
                totalPendingSchools    += districtPending;
                totalRejectedSchools   += districtRejected;
                totalNotStartedSchools += districtNotStarted;
                totalSchools           += districtTotalSchools;
                totalStudents          += districtTotalStudents;
                totalCompletedStudents += districtCompletedStuds;
            }
            
            double overallCompletion = totalSchools > 0 ?
                (totalApprovedSchools * 100.0 / totalSchools) : 0.0;
            
            result.put("districts", districts);
            result.put("totalSchools", totalSchools);
            result.put("completedSchools", totalApprovedSchools);  // APPROVED in phase_approvals
            result.put("approvedSchools", totalApprovedSchools);
            result.put("pendingSchools", totalPendingSchools);     // PENDING - awaiting HM approval
            result.put("rejectedSchools", totalRejectedSchools);   // REJECTED - sent back
            result.put("notStartedSchools", totalNotStartedSchools); // no phase_approvals row at all
            result.put("incompleteSchools", totalPendingSchools + totalRejectedSchools);
            result.put("totalStudents", totalStudents); // Total students across all districts
            result.put("completedStudents", totalCompletedStudents); // Total students in completed schools
            result.put("districtsComplete", districtsWithAllSchoolsComplete); // Districts at 100%
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
}
