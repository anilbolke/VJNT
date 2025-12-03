package com.vjnt.servlet;

import java.io.IOException;
import java.time.LocalDate;
import java.time.temporal.WeekFields;
import java.util.Locale;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.vjnt.model.User;
import com.vjnt.dao.StudentActivityDAO;

@WebServlet("/save-student-activity")
public class SaveStudentActivityServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Check authentication
        User user = (User) request.getSession().getAttribute("user");
        if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
                             !user.getUserType().equals(User.UserType.HEAD_MASTER))) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized");
            return;
        }

        try {
            // Get parameters
            String studentIdStr = request.getParameter("studentId");
            String subject = request.getParameter("subject");
            String weekStr = request.getParameter("week");
            String activityText = request.getParameter("activity");
            String dayStr = request.getParameter("day");

            if (studentIdStr == null || subject == null || weekStr == null || activityText == null) {
                response.setContentType("application/json");
                response.getWriter().write("{\"success\": false, \"message\": \"Missing required parameters\"}");
                return;
            }

            int studentId = Integer.parseInt(studentIdStr);
            int week = Integer.parseInt(weekStr);
            int day = dayStr != null && !dayStr.isEmpty() ? Integer.parseInt(dayStr) : 0;

            // Call DAO to save activity
            StudentActivityDAO activityDAO = new StudentActivityDAO();
            boolean success = activityDAO.saveOrUpdateStudentActivity(
                studentId, 
                subject, 
                week, 
                day, 
                activityText, 
                user.getUsername()
            );

            response.setContentType("application/json");
            if (success) {
                response.getWriter().write("{\"success\": true, \"message\": \"Activity saved successfully\"}");
            } else {
                response.getWriter().write("{\"success\": false, \"message\": \"Failed to save activity\"}");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.setContentType("application/json");
            response.getWriter().write("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
}
