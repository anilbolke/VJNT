package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.dao.PalakMelavaDAO;
import com.vjnt.model.PalakMelava;

@WebServlet("/GenerateStudentReportPDFServlet")
public class GenerateStudentReportPDFServlet extends HttpServlet {
    
    private static final String CSS_STYLES = 
        "<style>" +
        "* { margin: 0; padding: 0; box-sizing: border-box; }" +
        "body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }" +
        ".container { background: white; max-width: 900px; margin: 20px auto; padding: 0; border-radius: 10px; box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3); }" +
        ".modal-header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px 30px; border-radius: 10px 10px 0 0; }" +
        ".modal-header h2 { margin: 0; font-size: 22px; }" +
        ".modal-body { padding: 30px; }" +
        ".report-section { margin-bottom: 30px; padding: 20px; border: 1px solid #e9ecef; border-radius: 8px; }" +
        ".report-section h3 { color: #667eea; margin-bottom: 15px; font-size: 18px; border-bottom: 2px solid #667eea; padding-bottom: 10px; }" +
        ".approval-banner { padding: 15px; border-radius: 8px; margin-bottom: 20px; display: flex; align-items: center; gap: 15px; }" +
        ".approval-banner.approved { background: #28a745; color: white; }" +
        ".approval-banner i { font-size: 32px; }" +
        ".approval-info .title { font-size: 18px; font-weight: bold; margin-bottom: 5px; }" +
        ".student-info-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; }" +
        ".levels-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin-top: 15px; }" +
        ".level-box { background: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center; border: 2px solid #e9ecef; }" +
        ".level-box.assessed { background: #d4edda; border-color: #28a745; }" +
        ".level-label { font-size: 12px; color: #6c757d; margin-bottom: 5px; font-weight: bold; }" +
        ".level-value { font-size: 14px; font-weight: 600; color: #495057; line-height: 1.4; }" +
        ".overall-progress { margin-top: 15px; padding: 12px; background: #e7f3ff; border-radius: 6px; text-align: center; }" +
        ".summary-stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin-bottom: 20px; }" +
        ".stat-box { padding: 20px; border-radius: 8px; text-align: center; }" +
        ".stat-box.total { background: #e7f3ff; }" +
        ".stat-box.completed { background: #d4edda; }" +
        ".stat-box.completion { background: #fff3cd; }" +
        ".stat-value { font-size: 32px; font-weight: bold; margin-bottom: 5px; }" +
        ".stat-value.blue { color: #667eea; }" +
        ".stat-value.green { color: #28a745; }" +
        ".stat-value.yellow { color: #ffc107; }" +
        ".stat-label { font-size: 12px; color: #6c757d; }" +
        ".activity-group { margin-bottom: 20px; border: 1px solid #dee2e6; border-radius: 8px; overflow: hidden; }" +
        ".activity-group-header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 12px 16px; color: white; }" +
        ".activity-group-title { margin: 0; font-size: 16px; font-weight: 600; }" +
        ".activity-group-content { padding: 15px; }" +
        ".activity-item { padding: 12px; margin-bottom: 10px; border-radius: 6px; background: #f8f9fa; border-left: 4px solid #667eea; }" +
        ".activity-day { font-weight: bold; color: #495057; margin-bottom: 5px; }" +
        ".activity-text { font-size: 13px; color: #6c757d; }" +
        ".activity-meta { display: flex; justify-content: space-between; margin-top: 8px; padding-top: 8px; border-top: 1px solid rgba(0,0,0,0.1); font-size: 11px; color: #6c757d; }" +
        ".activity-count-badge { background: #667eea; color: white; padding: 2px 8px; border-radius: 10px; font-size: 10px; }" +
        ".palak-melava-card { background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 15px; border-left: 4px solid #667eea; }" +
        ".palak-melava-card h4 { color: #667eea; margin: 0 0 15px 0; }" +
        ".palak-melava-card .badge { background: #28a745; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; }" +
        ".palak-details { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-bottom: 15px; }" +
        ".print-button { background: #28a745; color: white; padding: 12px 24px; border: none; border-radius: 6px; cursor: pointer; font-size: 16px; margin: 20px 0; }" +
        "@media print { body { background: white; padding: 0; } .container { box-shadow: none; max-width: 100%; margin: 0; } .print-button { display: none; } }" +
        "</style>";
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        String userType = (String) session.getAttribute("userType");
        String approvalIdParam = request.getParameter("approvalId");
        
        if (approvalIdParam == null || approvalIdParam.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Approval ID is required");
            return;
        }
        
        int approvalId;
        try {
            approvalId = Integer.parseInt(approvalIdParam);
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid Approval ID");
            return;
        }
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            // Get approval details
            String sql = "SELECT ra.*, u.username as approved_by_name " +
                        "FROM report_approvals ra " +
                        "LEFT JOIN users u ON ra.approved_by = u.user_id " +
                        "WHERE ra.approval_id = ?";
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, approvalId);
            ResultSet rs = stmt.executeQuery();
            
            if (!rs.next()) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Report not found");
                return;
            }
            
            String penNumber = rs.getString("pen_number");
            String studentName = rs.getString("student_name");
            String udiseCode = rs.getString("udise_code");
            String approvalStatus = rs.getString("approval_status");
            String approvedBy = rs.getString("approved_by_name");
            Timestamp approvalDate = rs.getTimestamp("approval_date");
            
            // Check permission
            if (!"HEAD_MASTER".equals(userType) && !"APPROVED".equals(approvalStatus)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Report not approved yet");
                return;
            }
            
            // Get student's class and section for teacher lookup
            String studentClass = null;
            String studentSection = null;
            sql = "SELECT class, section FROM students WHERE student_pen = ?";
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, penNumber);
            rs = stmt.executeQuery();
            if (rs.next()) {
                studentClass = rs.getString("class");
                studentSection = rs.getString("section");
            }
            
            // Get comprehensive data
            Map<String, Object> data = new HashMap<>();
            data.put("assessmentLevels", getAssessmentLevels(conn, penNumber));
            data.put("allActivities", getAllActivities(conn, penNumber));
            data.put("palakMelavaData", getPalakMelava(udiseCode));
            data.put("subjectTeachers", getSubjectTeachers(conn, udiseCode, studentClass, studentSection));
            
            // Generate HTML
            response.setContentType("text/html; charset=UTF-8");
            PrintWriter out = response.getWriter();
            
            out.println("<!DOCTYPE html><html><head>");
            out.println("<meta charset='UTF-8'>");
            out.println("<title>Student Report - " + studentName + "</title>");
            out.println(CSS_STYLES);
            out.println("<link href='https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css' rel='stylesheet'>");
            out.println("<script>function printReport() { window.print(); }</script>");
            out.println("</head><body>");
            out.println("<div class='container'>");
            
            // Header
            out.println("<div class='modal-header'>");
            out.println("<h2><i class='fas fa-file-alt'></i> " + esc(studentName) + " - Comprehensive Report</h2>");
            out.println("</div>");
            
            out.println("<div class='modal-body'>");
            
            // Print button
            out.println("<button class='print-button' onclick='printReport()'><i class='fas fa-print'></i> Print / Save as PDF</button>");
            
            // Approval banner
            writeApprovalBanner(out, approvalStatus, approvalId, approvedBy, approvalDate);
            
            // Student info
            writeStudentInfo(out, studentName, penNumber);
            
            // Assessment levels
            writeAssessmentLevels(out, data);
            
            // Activities
            writeActivities(out, data);
            
            // Palak Melava
            writePalakMelava(out, data);
            
            out.println("</div></div></body></html>");
            out.close();
            
            // Update status
            String updateSql = "UPDATE report_approvals SET report_generated = 1, generated_date = NOW() WHERE approval_id = ?";
            PreparedStatement updateStmt = conn.prepareStatement(updateSql);
            updateStmt.setInt(1, approvalId);
            updateStmt.executeUpdate();
            
        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException("Error generating report", e);
        }
    }
    
    private Map<String, String> getAssessmentLevels(Connection conn, String penNumber) throws SQLException {
        Map<String, String> levels = new HashMap<>();
        String sql = "SELECT marathi_akshara_level, math_akshara_level, english_akshara_level " +
                    "FROM students WHERE student_pen = ?";
        PreparedStatement stmt = conn.prepareStatement(sql);
        stmt.setString(1, penNumber);
        ResultSet rs = stmt.executeQuery();
        
        if (rs.next()) {
            int marathiLevel = rs.getInt("marathi_akshara_level");
            int mathLevel = rs.getInt("math_akshara_level");
            int englishLevel = rs.getInt("english_akshara_level");
            
            // Get level text based on number
            levels.put("marathi", getMarathiLevelText(marathiLevel));
            levels.put("math", getMathLevelText(mathLevel));
            levels.put("english", getEnglishLevelText(englishLevel));
            
            // Calculate overall
            int count = 0;
            if (marathiLevel > 0) count++;
            if (mathLevel > 0) count++;
            if (englishLevel > 0) count++;
            
            String overall = "Not Started";
            if (count == 3) overall = "All Subjects Assessed";
            else if (count == 2) overall = "2 of 3 Assessed";
            else if (count == 1) overall = "1 of 3 Assessed";
            levels.put("overall", overall);
        }
        return levels;
    }
    
    // Get Marathi level text based on level number
    private String getMarathiLevelText(int level) {
        switch (level) {
            case 1: return "अक्षर स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)";
            case 2: return "शब्द स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)";
            case 3: return "वाक्य स्तरावरील विद्यार्थी संख्या";
            case 4: return "समजपुर्वक उतार वाचन स्तरावरील विद्यार्थी संख्या";
            case 5: return "वाचन–लेखन FLN स्तर 100%पूर्ण.";
            default: return "स्तर निश्चित केला नाही";
        }
    }
    
    // Get Math level text based on level number
    private String getMathLevelText(int level) {
        switch (level) {
            case 1: return "प्रारंभीक स्तरावरील विद्यार्थी संख्या";
            case 2: return "अंक स्तरावरील विद्यार्थी संख्या";
            case 3: return "संख्या वाचन स्तरावरील विद्यार्थी संख्या";
            case 4: return "बेरीज स्तरावरील विद्यार्थी संख्या";
            case 5: return "वजाबाकी स्तरावरील विद्यार्थी संख्या";
            case 6: return "गुणाकार स्तरावरील विद्यार्थी संख्या";
            case 7: return "भागाकर स्तरावरील विद्यार्थी संख्या";
            case 8: return "संख्या व मूलभूत क्रिया FLN स्तर 100%पूर्ण.";
            default: return "स्तर निश्चित केला नाही";
        }
    }
    
    // Get English level text based on level number
    private String getEnglishLevelText(int level) {
        switch (level) {
            case 1: return "BEGINER LEVEL";
            case 2: return "ALPHABET LEVEL Reading and Writing";
            case 3: return "WORD LEVEL Reading and Writing";
            case 4: return "SENTENCE LEVEL";
            case 5: return "Paragraph Reading with Understanding";
            case 6: return "Reading and Writing FLN Level 100% Complete.";
            default: return "स्तर निश्चित केला नाही";
        }
    }
    
    private List<Map<String, Object>> getAllActivities(Connection conn, String penNumber) throws SQLException {
        List<Map<String, Object>> activities = new ArrayList<>();
        String sql = "SELECT language, week_number, day_number, activity_text, activity_count, completed, assigned_by " +
                    "FROM student_weekly_activities WHERE student_pen = ? ORDER BY language, week_number, day_number";
        PreparedStatement stmt = conn.prepareStatement(sql);
        stmt.setString(1, penNumber);
        ResultSet rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> activity = new HashMap<>();
            activity.put("language", rs.getString("language"));
            activity.put("weekNumber", rs.getInt("week_number"));
            activity.put("dayNumber", rs.getInt("day_number"));
            activity.put("activityText", rs.getString("activity_text"));
            activity.put("activityCount", rs.getInt("activity_count"));
            activity.put("completed", rs.getBoolean("completed"));
            activity.put("assignedBy", rs.getString("assigned_by"));
            activities.add(activity);
        }
        return activities;
    }
    
    private List<PalakMelava> getPalakMelava(String udiseCode) {
        try {
            List<PalakMelava> all = new PalakMelavaDAO().getByUdise(udiseCode);
            // Filter only approved meetings
            List<PalakMelava> approved = new ArrayList<>();
            for (PalakMelava m : all) {
                if ("APPROVED".equals(m.getStatus())) {
                    approved.add(m);
                }
            }
            return approved;
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }
    
    private void writeApprovalBanner(PrintWriter out, String status, int id, String by, Timestamp date) {
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        out.println("<div class='approval-banner approved'>");
        out.println("<i class='fas fa-check-circle'></i>");
        out.println("<div class='approval-info'>");
        out.println("<div class='title'>Report Status: Approved</div>");
        out.println("<div>This report has been approved by Head Master.</div>");
        out.println("<div style='font-size:12px; margin-top:5px;'>Request ID: #" + id);
        if (date != null) out.println(" | Approved: " + sdf.format(date));
        if (by != null) out.println(" | By: " + esc(by));
        out.println("</div></div></div>");
    }
    
    private void writeStudentInfo(PrintWriter out, String name, String pen) {
        out.println("<div class='report-section'>");
        out.println("<h3><i class='fas fa-user'></i> Student Information</h3>");
        out.println("<div class='student-info-grid'>");
        out.println("<div><strong>Name:</strong> " + esc(name) + "</div>");
        out.println("<div><strong>PEN Number:</strong> " + esc(pen) + "</div>");
        out.println("</div></div>");
    }
    
    private void writeAssessmentLevels(PrintWriter out, Map<String, Object> data) {
        out.println("<div class='report-section'>");
        out.println("<h3><i class='fas fa-chart-line'></i> Assessment Levels</h3>");
        
        Map<String, String> levels = (Map<String, String>) data.get("assessmentLevels");
        Map<String, String> teachers = (Map<String, String>) data.get("subjectTeachers");
        if (teachers == null) teachers = new HashMap<>();
        
        if (levels != null) {
            String eng = levels.get("english");
            String mar = levels.get("marathi");
            String mat = levels.get("math");
            
            out.println("<div class='levels-grid'>");
            out.println("<div class='level-box" + (eng != null && !eng.equals("Not Assessed") ? " assessed" : "") + "'>");
            out.println("<div class='level-label'>ENGLISH</div>");
            out.println("<div class='level-value'>" + esc(eng) + "</div>");
            if (teachers.containsKey("English")) {
                out.println("<div style='font-size: 11px; margin-top: 8px; color: #495057;'><i class='fas fa-chalkboard-teacher'></i> Subject Teacher: <strong>" + esc(teachers.get("English")) + "</strong></div>");
            }
            out.println("</div>");
            
            out.println("<div class='level-box" + (mar != null && !mar.equals("Not Assessed") ? " assessed" : "") + "'>");
            out.println("<div class='level-label'>MARATHI</div>");
            out.println("<div class='level-value'>" + esc(mar) + "</div>");
            if (teachers.containsKey("Marathi")) {
                out.println("<div style='font-size: 11px; margin-top: 8px; color: #495057;'><i class='fas fa-chalkboard-teacher'></i> Subject Teacher: <strong>" + esc(teachers.get("Marathi")) + "</strong></div>");
            }
            out.println("</div>");
            
            out.println("<div class='level-box" + (mat != null && !mat.equals("Not Assessed") ? " assessed" : "") + "'>");
            out.println("<div class='level-label'>Mathematics</div>");
            out.println("<div class='level-value'>" + esc(mat) + "</div>");
            if (teachers.containsKey("Mathematics")) {
                out.println("<div style='font-size: 11px; margin-top: 8px; color: #495057;'><i class='fas fa-chalkboard-teacher'></i> Subject Teacher: <strong>" + esc(teachers.get("Mathematics")) + "</strong></div>");
            }
            out.println("</div>");
            out.println("</div>");
            
            out.println("<div class='overall-progress'><strong>Overall Progress:</strong> " + esc(levels.get("overall")) + "</div>");
        }
        out.println("</div>");
    }
    
    @SuppressWarnings("unchecked")
    private void writeActivities(PrintWriter out, Map<String, Object> data) {
        out.println("<div class='report-section'>");
        out.println("<h3><i class='fas fa-tasks'></i> Activities Summary</h3>");
        
        List<Map<String, Object>> activities = (List<Map<String, Object>>) data.get("allActivities");
        
        if (activities != null && !activities.isEmpty()) {
            int total = activities.size();
            int completed = 0;
            Map<String, List<String>> grouped = new LinkedHashMap<>();
            
            for (Map<String, Object> act : activities) {
                if (Boolean.TRUE.equals(act.get("completed"))) completed++;
                
                String lang = (String) act.get("language");
                Integer week = (Integer) act.get("weekNumber");
                Integer day = (Integer) act.get("dayNumber");
                String text = (String) act.get("activityText");
                Integer count = (Integer) act.get("activityCount");
                String by = (String) act.get("assignedBy");
                
                String key = lang + "-Week" + week;
                grouped.putIfAbsent(key, new ArrayList<>());
                
                String html = "<div class='activity-item'><div class='activity-day'>Day " + day + "</div>";
                html += "<div class='activity-text'>" + esc(text) + "</div>";
                if (by != null || (count != null && count > 1)) {
                    html += "<div class='activity-meta'>";
                    if (by != null) html += "<span>Assigned by: " + esc(by) + "</span>";
                    if (count != null && count > 1) html += "<span class='activity-count-badge'>" + count + "x</span>";
                    html += "</div>";
                }
                html += "</div>";
                grouped.get(key).add(html);
            }
            
            int rate = (int) Math.round((completed * 100.0) / total);
            
            out.println("<div class='summary-stats'>");
            out.println("<div class='stat-box total'><div class='stat-value blue'>" + total + "</div><div class='stat-label'>Total Activities</div></div>");
            out.println("</div>");
            
            Map<String, String> teachers = (Map<String, String>) data.get("subjectTeachers");
            if (teachers == null) teachers = new HashMap<>();
            
            for (Map.Entry<String, List<String>> entry : grouped.entrySet()) {
                String[] parts = entry.getKey().split("-");
                String subject = parts[0];
                String teacherInfo = "";
                if (teachers.containsKey(subject)) {
                    teacherInfo = " <span style='font-size: 13px; opacity: 0.95;'><i class='fas fa-chalkboard-teacher'></i> Teacher: <strong>" + esc(teachers.get(subject)) + "</strong></span>";
                }
                out.println("<div class='activity-group'>");
                out.println("<div class='activity-group-header'><h4 class='activity-group-title'>" + esc(parts[0]) + " - " + parts[1] + teacherInfo + "</h4></div>");
                out.println("<div class='activity-group-content'>");
                for (String html : entry.getValue()) out.println(html);
                out.println("</div></div>");
            }
        } else {
            out.println("<p style='text-align:center;color:#6c757d;padding:20px;'>No activities found</p>");
        }
        out.println("</div>");
    }
    
    @SuppressWarnings("unchecked")
    private void writePalakMelava(PrintWriter out, Map<String, Object> data) {
        out.println("<div class='report-section'>");
        out.println("<h3><i class='fas fa-users'></i> Parent-Teacher Meetings (Palak Melava)</h3>");
        
        List<PalakMelava> meetings = (List<PalakMelava>) data.get("palakMelavaData");
        
        if (meetings != null && !meetings.isEmpty()) {
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
            int count = 0;
            for (PalakMelava m : meetings) {
                count++;
                out.println("<div class='palak-melava-card'>");
                out.println("<div style='display:flex;justify-content:space-between;margin-bottom:15px;'>");
                out.println("<h4>Meeting #" + count + "</h4>");
                out.println("<span class='badge'>✓ Approved</span></div>");
                out.println("<div class='palak-details'>");
                out.println("<div><strong><i class='fas fa-calendar'></i> Meeting Date:</strong><div>" + 
                    (m.getMeetingDate() != null ? sdf.format(m.getMeetingDate()) : "N/A") + "</div></div>");
                out.println("<div><strong><i class='fas fa-users'></i> Parents Attended:</strong><div>" + 
                    (m.getTotalParentsAttended() != null ? m.getTotalParentsAttended() : "N/A") + "</div></div>");
                out.println("</div>");
                out.println("<div><strong><i class='fas fa-user-tie'></i> Chief Guest:</strong>");
                out.println("<div style='margin-top:5px;background:white;padding:10px;border-radius:4px;'>" + 
                    esc(m.getChiefAttendeeInfo()) + "</div></div>");
                out.println("</div>");
            }
            out.println("<p style='color:#6c757d;'>School conducted " + count + " meeting(s)</p>");
        } else {
            out.println("<p style='color:#6c757d;'>No meetings recorded yet.</p>");
        }
        out.println("</div>");
    }
    
    private String esc(String text) {
        if (text == null) return "";
        return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                   .replace("\"", "&quot;").replace("'", "&#39;");
    }
    
    // Get subject teachers for a specific class and section
    private Map<String, String> getSubjectTeachers(Connection conn, String udiseCode, String studentClass, String section) {
        Map<String, String> subjectTeachers = new HashMap<>();
        
        if (udiseCode == null || studentClass == null || section == null) {
            return subjectTeachers;
        }
        
        String sql = "SELECT teacher_name, subjects_assigned FROM teacher_assignments " +
                     "WHERE udise_code = ? AND class = ? AND section = ? AND is_active = 1";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, udiseCode);
            stmt.setString(2, studentClass);
            stmt.setString(3, section);
            
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                String teacherName = rs.getString("teacher_name");
                String subjects = rs.getString("subjects_assigned");
                
                if (teacherName != null && subjects != null) {
                    // subjects_assigned is a comma-separated list like "Marathi,Math,English"
                    String[] subjectArray = subjects.split(",");
                    for (String subject : subjectArray) {
                        subject = subject.trim();
                        if (!subject.isEmpty()) {
                            // Store the teacher name for each subject
                            subjectTeachers.put(subject, teacherName);
                        }
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return subjectTeachers;
    }
}
