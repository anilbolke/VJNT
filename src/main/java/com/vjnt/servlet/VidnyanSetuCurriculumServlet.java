package com.vjnt.servlet;

import com.vjnt.dao.VidnyanSetuCurriculumDAO;
import com.vjnt.model.User;
import org.json.JSONObject;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;

/**
 * Read-only lookup for the VidnyanSetu curriculum picker
 * (Class -> Week -> Week Topic -> Day -> Day Topic).
 *
 * GET returns the ENTIRE curriculum (~560 rows, all classes) as one nested
 * JSON blob — small enough to load once per page visit so the cascading
 * Class/Week/Day selects in vidnyansetu-activity.jsp run purely client-side
 * with no further round trip.
 */
@WebServlet("/vidnyansetu-curriculum")
public class VidnyanSetuCurriculumServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final VidnyanSetuCurriculumDAO curriculumDAO = new VidnyanSetuCurriculumDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        Object vsUser = (session != null) ? session.getAttribute("vsUser") : null;
        if (user == null && vsUser == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        try {
            JSONObject curriculum = curriculumDAO.getFullCurriculum();
            out.print(curriculum.toString());
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            JSONObject err = new JSONObject();
            err.put("success", false);
            err.put("error", e.getMessage());
            out.print(err.toString());
        }
    }
}
