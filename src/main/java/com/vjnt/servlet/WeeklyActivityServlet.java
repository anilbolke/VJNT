package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.WeeklyActivityDAO;
import com.vjnt.model.User;
import com.vjnt.model.WeeklyActivity;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/weeklyActivity")
public class WeeklyActivityServlet extends HttpServlet {
    private WeeklyActivityDAO activityDAO = new WeeklyActivityDAO();
    private Gson gson = new Gson();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        
        if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
                            !user.getUserType().equals(User.UserType.HEAD_MASTER))) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        String action = request.getParameter("action");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            if ("getClasses".equals(action)) {
                List<String> classes = activityDAO.getAvailableClasses(user.getUdiseNo());
                out.print(gson.toJson(classes));
            } else if ("getSections".equals(action)) {
                String studentClass = request.getParameter("class");
                List<String> sections = activityDAO.getAvailableSections(user.getUdiseNo(), studentClass);
                out.print(gson.toJson(sections));
            } else if ("getLanguages".equals(action)) {
                List<String> languages = activityDAO.getAvailableLanguages();
                out.print(gson.toJson(languages));
            } else if ("getActivities".equals(action)) {
                String studentClass = request.getParameter("class");
                String section = request.getParameter("section");
                String language = request.getParameter("language");
                int weekNumber = Integer.parseInt(request.getParameter("week"));
                
                List<WeeklyActivity> activities;
                if (language != null && !language.isEmpty()) {
                    // Get activities filtered by language
                    activities = activityDAO.getActivitiesByLanguage(
                        user.getUdiseNo(), studentClass, section, language, weekNumber
                    );
                } else {
                    // Get all activities for the week
                    activities = activityDAO.getActivitiesByClassSection(
                        user.getUdiseNo(), studentClass, section, weekNumber
                    );
                }
                
                Map<String, Object> resultData = new HashMap<>();
                resultData.put("activities", activities);
                
                if (language != null && !language.isEmpty()) {
                    resultData.put("completedCount", activityDAO.getCompletedActivitiesCountByLanguage(
                        user.getUdiseNo(), studentClass, section, language, weekNumber
                    ));
                } else {
                    resultData.put("completedCount", activityDAO.getCompletedActivitiesCount(
                        user.getUdiseNo(), studentClass, section, weekNumber
                    ));
                }
                
                out.print(gson.toJson(resultData));
            } else if ("loadFromPDF".equals(action)) {
                String studentClass = request.getParameter("class");
                String section = request.getParameter("section");
                String language = request.getParameter("language");
                
                List<WeeklyActivity> activities = activityDAO.loadActivitiesFromPDF(
                    user.getUdiseNo(), studentClass, section, language
                );
                
                Map<String, Object> resultData = new HashMap<>();
                resultData.put("success", activities.size() > 0);
                resultData.put("activitiesLoaded", activities.size());
                resultData.put("message", activities.size() + " activities loaded from PDF for " + language);
                
                out.print(gson.toJson(resultData));
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        
        if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
                            !user.getUserType().equals(User.UserType.HEAD_MASTER))) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        String action = request.getParameter("action");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            if ("markComplete".equals(action)) {
                int activityId = Integer.parseInt(request.getParameter("activityId"));
                boolean success = activityDAO.markActivityComplete(activityId, user.getFullName());
                result.put("success", success);
            } else if ("markIncomplete".equals(action)) {
                int activityId = Integer.parseInt(request.getParameter("activityId"));
                boolean success = activityDAO.markActivityIncomplete(activityId);
                result.put("success", success);
            } else if ("addActivity".equals(action)) {
                WeeklyActivity activity = new WeeklyActivity(
                    user.getUdiseNo(),
                    request.getParameter("class"),
                    request.getParameter("section"),
                    request.getParameter("subject"),
                    Integer.parseInt(request.getParameter("week")),
                    request.getParameter("day"),
                    request.getParameter("activity")
                );
                boolean success = activityDAO.createActivity(activity);
                result.put("success", success);
                if (success) {
                    result.put("activityId", activity.getId());
                }
            } else if ("updateActivity".equals(action)) {
                int activityId = Integer.parseInt(request.getParameter("activityId"));
                String newActivity = request.getParameter("activity");
                boolean success = activityDAO.updateActivity(activityId, newActivity);
                result.put("success", success);
            } else if ("loadFromPDF".equals(action)) {
                String studentClass = request.getParameter("class");
                String section = request.getParameter("section");
                String language = request.getParameter("language");
                
                List<WeeklyActivity> activities = activityDAO.loadActivitiesFromPDF(
                    user.getUdiseNo(), studentClass, section, language
                );
                
                result.put("success", activities.size() > 0);
                result.put("activitiesLoaded", activities.size());
                result.put("message", activities.size() + " activities loaded from PDF for " + language);
            }
            
            out.print(gson.toJson(result));
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("error", e.getMessage());
            out.print(gson.toJson(result));
        }
    }
}
