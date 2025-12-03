package com.vjnt.servlet;

import java.io.IOException;
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

@WebServlet("/get-activity-count")
public class GetActivityCountServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
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

            if (studentIdStr == null || subject == null || weekStr == null) {
                response.setContentType("application/json");
                response.getWriter().write("{\"success\": false, \"message\": \"Missing parameters\"}");
                return;
            }

            int studentId = Integer.parseInt(studentIdStr);
            int week = Integer.parseInt(weekStr);

            // Get activity count from DAO
            StudentActivityDAO activityDAO = new StudentActivityDAO();
            Map<String, Integer> activityCount = activityDAO.getActivitySummary(studentId, subject, week);

            response.setContentType("application/json");
            Gson gson = new Gson();
            response.getWriter().write(gson.toJson(new Object() {
                public boolean success = true;
                public Map<String, Integer> counts = activityCount;
            }));

        } catch (Exception e) {
            e.printStackTrace();
            response.setContentType("application/json");
            response.getWriter().write("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
}
