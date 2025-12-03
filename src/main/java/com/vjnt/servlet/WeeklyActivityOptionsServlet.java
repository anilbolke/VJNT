package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.model.User;
import com.vjnt.util.WeeklyActivityHTMLParser;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.Map;

@WebServlet("/weeklyActivityOptions")
public class WeeklyActivityOptionsServlet extends HttpServlet {
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
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            String language = request.getParameter("language");
            int weekNumber = Integer.parseInt(request.getParameter("week"));
            
            // Get the WebContent path
            String webContentPath = getServletContext().getRealPath("/");
            
            // Parse HTML and get activities
            Map<Integer, String> activities = WeeklyActivityHTMLParser.getActivitiesForWeek(
                language, weekNumber, webContentPath
            );
            
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("activities", activities);
            
            out.print(gson.toJson(result));
            
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("error", e.getMessage());
            out.print(gson.toJson(error));
        }
    }
}
