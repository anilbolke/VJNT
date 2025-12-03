package com.vjnt.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.google.gson.Gson;
import com.vjnt.model.User;
import com.vjnt.dao.StudentActivityDAO;

@WebServlet("/get-specific-activity-count")
public class GetSpecificActivityCountServlet extends HttpServlet {
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
            String dayStr = request.getParameter("day");
            String activity = request.getParameter("activity");

            if (studentIdStr == null || subject == null || weekStr == null || dayStr == null || activity == null) {
                response.setContentType("application/json");
                response.getWriter().write("{\"success\": false, \"message\": \"Missing parameters\"}");
                return;
            }

            int studentId = Integer.parseInt(studentIdStr);
            int week = Integer.parseInt(weekStr);
            int day = Integer.parseInt(dayStr);

            // Log the request parameters for debugging
            System.out.println("DEBUG: GetSpecificActivityCountServlet called with:");
            System.out.println("  studentId: " + studentId);
            System.out.println("  subject: " + subject);
            System.out.println("  week: " + week);
            System.out.println("  day: " + day);
            System.out.println("  activity: " + activity);

            // Get specific activity count from DAO
            StudentActivityDAO activityDAO = new StudentActivityDAO();
            int count1 = activityDAO.getSpecificActivityCount(studentId, subject, week, day, activity);

            System.out.println("DEBUG: Count returned from DAO: " + count1);

            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            
            java.util.Map<String, Object> responseMap = new java.util.HashMap<>();
            responseMap.put("success", true);
            responseMap.put("count", count1);
            
            Gson gson = new Gson();
            response.getWriter().write(gson.toJson(responseMap));

        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("DEBUG: Exception in GetSpecificActivityCountServlet: " + e.getMessage());
            response.setContentType("application/json");
            response.getWriter().write("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
}
