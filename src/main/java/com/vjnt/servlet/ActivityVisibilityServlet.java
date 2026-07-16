package com.vjnt.servlet;

import java.io.BufferedReader;
import java.io.IOException;
import java.util.Iterator;
import java.util.LinkedHashMap;
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

import com.vjnt.dao.ActivityVisibilityDAO;
import com.vjnt.dao.StudentDAO;
import com.vjnt.model.User;
import com.vjnt.model.User.UserType;

/**
 * Division-wise Activity Visibility management API (DATA_ADMIN only).
 *
 * GET  /activity-visibility
 *      -> {activities:[{code,name,marathi,icon}], divisions:[...],
 *          config:{division:{code:true/false}}}   (missing entries = enabled)
 *
 * POST /activity-visibility   body: JSON {"DivisionName": {"CODE": true/false, ...}, ...}
 *      -> {success:true} — upserts checkbox state per division.
 */
@WebServlet("/activity-visibility")
public class ActivityVisibilityServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User admin = requireDataAdmin(request, response);
        if (admin == null) return;

        ActivityVisibilityDAO dao = new ActivityVisibilityDAO();

        JSONArray activities = new JSONArray();
        List<Map<String, String>> acts = dao.getAllActivities();
        for (Map<String, String> a : acts) {
            activities.put(new JSONObject(a));
        }

        List<String> divisions = new StudentDAO().getDistinctDivisions();

        JSONObject config = new JSONObject();
        Map<String, Map<String, Boolean>> matrix = dao.getConfigMatrix();
        for (Map.Entry<String, Map<String, Boolean>> e : matrix.entrySet()) {
            config.put(e.getKey(), new JSONObject(e.getValue()));
        }

        JSONObject json = new JSONObject();
        json.put("activities", activities);
        json.put("divisions", new JSONArray(divisions));
        json.put("config", config);
        writeJson(response, json);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User admin = requireDataAdmin(request, response);
        if (admin == null) return;

        StringBuilder body = new StringBuilder();
        BufferedReader reader = request.getReader();
        String line;
        while ((line = reader.readLine()) != null) {
            body.append(line);
        }

        JSONObject json = new JSONObject();
        try {
            JSONObject payload = new JSONObject(body.toString());
            ActivityVisibilityDAO dao = new ActivityVisibilityDAO();
            boolean allSaved = true;

            Iterator<String> divisions = payload.keys();
            while (divisions.hasNext()) {
                String division = divisions.next();
                JSONObject divConfig = payload.getJSONObject(division);
                Map<String, Boolean> config = new LinkedHashMap<String, Boolean>();
                Iterator<String> codes = divConfig.keys();
                while (codes.hasNext()) {
                    String code = codes.next();
                    config.put(code, divConfig.getBoolean(code));
                }
                if (!config.isEmpty()) {
                    allSaved &= dao.saveDivisionConfig(division, config, admin.getUsername());
                }
            }
            json.put("success", allSaved);
            if (!allSaved) json.put("message", "Some divisions could not be saved. Please retry.");
        } catch (Exception e) {
            json.put("success", false);
            json.put("message", "Invalid request: " + e.getMessage());
        }
        writeJson(response, json);
    }

    private User requireDataAdmin(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        if (user == null || user.getUserType() != UserType.DATA_ADMIN) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write("{\"error\":\"Access denied. Data Admin login required.\"}");
            return null;
        }
        return user;
    }

    private void writeJson(HttpServletResponse response, JSONObject json) throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(json.toString());
    }
}
