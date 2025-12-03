package com.vjnt.servlet;

import java.io.IOException;
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
import com.vjnt.model.User;
import com.vjnt.dao.StudentActivityDAO;

@WebServlet("/display-activity-counts")
public class DisplayActivityCountsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Check authentication
        User user = (User) request.getSession().getAttribute("user");
        if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
                             !user.getUserType().equals(User.UserType.HEAD_MASTER))) {
            response.setContentType("application/json");
            response.getWriter().write("{\"success\": false, \"message\": \"Unauthorized\"}");
            return;
        }

        try {
            String studentIdStr = request.getParameter("studentId");
            String subject = request.getParameter("subject");
            String weekStr = request.getParameter("week");

            StudentActivityDAO activityDAO = new StudentActivityDAO();
            List<Map<String, Object>> activities = new ArrayList<>();

            if (studentIdStr != null && subject != null && weekStr != null) {
                // Get specific week activities
                int studentId = Integer.parseInt(studentIdStr);
                int week = Integer.parseInt(weekStr);
                activities = activityDAO.getActivityCountByWeek(studentId, subject, week);
            } else {
                // Get all activities
                activities = activityDAO.getAllActivityCounts();
            }

            // Format response
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("tableName", "student_weekly_activities");
            result.put("data", activities);

            response.setContentType("application/json");
            Gson gson = new Gson();
            response.getWriter().write(gson.toJson(result));

        } catch (Exception e) {
            e.printStackTrace();
            response.setContentType("application/json");
            response.getWriter().write("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
}
