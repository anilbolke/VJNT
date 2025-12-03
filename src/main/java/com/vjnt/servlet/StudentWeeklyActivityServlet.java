package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.StudentWeeklyActivityDAO;
import com.vjnt.model.Student;
import com.vjnt.model.StudentWeeklyActivity;
import com.vjnt.model.User;

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

@WebServlet("/studentWeeklyActivity")
public class StudentWeeklyActivityServlet extends HttpServlet {
    private StudentWeeklyActivityDAO activityDAO = new StudentWeeklyActivityDAO();
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
            if ("getStudents".equals(action)) {
                String studentClass = request.getParameter("class");
                String section = request.getParameter("section");
                
                List<Student> students = activityDAO.getStudentsByClassSection(
                    user.getUdiseNo(), studentClass, section
                );
                out.print(gson.toJson(students));
                
            } else if ("getStudentActivities".equals(action)) {
                int studentId = Integer.parseInt(request.getParameter("studentId"));
                String language = request.getParameter("language");
                int weekNumber = Integer.parseInt(request.getParameter("week"));
                
                List<StudentWeeklyActivity> activities = activityDAO.getActivitiesForStudentByWeek(
                    studentId, language, weekNumber
                );
                out.print(gson.toJson(activities));
                
            } else if ("getAllStudentActivities".equals(action)) {
                int studentId = Integer.parseInt(request.getParameter("studentId"));
                
                List<StudentWeeklyActivity> activities = activityDAO.getActivitiesForStudent(studentId);
                out.print(gson.toJson(activities));
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("error", e.getMessage());
            out.print(gson.toJson(error));
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
            if ("assignActivity".equals(action)) {
                int studentId = Integer.parseInt(request.getParameter("studentId"));
                String studentPen = request.getParameter("studentPen");
                String studentName = request.getParameter("studentName");
                String studentClass = request.getParameter("class");
                String section = request.getParameter("section");
                String language = request.getParameter("language");
                int weekNumber = Integer.parseInt(request.getParameter("week"));
                int dayNumber = Integer.parseInt(request.getParameter("day"));
                String activityText = request.getParameter("activityText");
                
                StudentWeeklyActivity activity = new StudentWeeklyActivity(
                    studentId, studentPen, user.getUdiseNo(), studentClass, section,
                    studentName, language, weekNumber, dayNumber, activityText
                );
                activity.setAssignedBy(user.getFullName());
                
                boolean success = activityDAO.assignActivityToStudent(activity);
                result.put("success", success);
                if (success) {
                    result.put("message", "Activity assigned successfully");
                }
                
            } else if ("markComplete".equals(action)) {
                int activityId = Integer.parseInt(request.getParameter("activityId"));
                boolean success = activityDAO.markActivityComplete(activityId);
                result.put("success", success);
                
            } else if ("markIncomplete".equals(action)) {
                int activityId = Integer.parseInt(request.getParameter("activityId"));
                boolean success = activityDAO.markActivityIncomplete(activityId);
                result.put("success", success);
                
            } else if ("deleteActivity".equals(action)) {
                int activityId = Integer.parseInt(request.getParameter("activityId"));
                boolean success = activityDAO.deleteActivity(activityId);
                result.put("success", success);
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
