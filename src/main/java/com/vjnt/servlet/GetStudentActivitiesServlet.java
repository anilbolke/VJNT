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

@WebServlet("/GetStudentActivitiesServlet")
public class GetStudentActivitiesServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.getWriter().write("{\"success\": false, \"message\": \"Not authenticated\"}");
            return;
        }

        String studentIdParam = request.getParameter("studentId");
        if (studentIdParam == null || studentIdParam.trim().isEmpty()) {
            response.getWriter().write("{\"success\": false, \"message\": \"Student ID required\"}");
            return;
        }

        JsonObject result = new JsonObject();
        JsonArray activities = new JsonArray();

        try {
            int studentId = Integer.parseInt(studentIdParam);
            
            try (Connection conn = DatabaseConnection.getConnection()) {
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

                result.addProperty("success", true);
                result.add("activities", activities);
            }
        } catch (NumberFormatException e) {
            result.addProperty("success", false);
            result.addProperty("message", "Invalid student ID");
        } catch (SQLException e) {
            e.printStackTrace();
            result.addProperty("success", false);
            result.addProperty("message", "Database error: " + e.getMessage());
        }

        response.getWriter().write(new Gson().toJson(result));
    }
}
