package com.vjnt.servlet;

import com.vjnt.dao.VidnyanSetuUserDAO;
import com.vjnt.model.VidnyanSetuUser;
import org.json.JSONObject;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;

/** VidnyanSetu Coordinator enables/disables one of their VidnyanSetu Teacher logins. */
@WebServlet("/vidnyansetu-toggle-teacher")
public class VidnyanSetuToggleTeacherServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final VidnyanSetuUserDAO vsUserDAO = new VidnyanSetuUserDAO();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        JSONObject result = new JSONObject();

        HttpSession session = request.getSession(false);
        VidnyanSetuUser coordinator = session == null ? null : (VidnyanSetuUser) session.getAttribute("vsUser");
        if (coordinator == null || coordinator.getRole() != VidnyanSetuUser.Role.COORDINATOR) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            result.put("success", false);
            result.put("message", "Unauthorized access");
            out.print(result.toString());
            return;
        }

        int vsUserId;
        boolean active;
        try {
            vsUserId = Integer.parseInt(request.getParameter("vsUserId"));
            active = Boolean.parseBoolean(request.getParameter("active"));
        } catch (NumberFormatException e) {
            result.put("success", false);
            result.put("message", "Invalid parameters");
            out.print(result.toString());
            return;
        }

        VidnyanSetuUser target = vsUserDAO.findById(vsUserId);

        if (target == null || target.getRole() != VidnyanSetuUser.Role.TEACHER
                || !coordinator.getUdiseNo().equals(target.getUdiseNo())) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            result.put("success", false);
            result.put("message", "This teacher does not belong to your school");
            out.print(result.toString());
            return;
        }

        boolean ok = vsUserDAO.setActive(vsUserId, active);
        result.put("success", ok);
        if (!ok) result.put("message", "Failed to update login status");
        out.print(result.toString());
    }
}
