package com.vjnt.servlet;

import com.vjnt.dao.SchoolDAO;
import com.vjnt.dao.VidnyanSetuUserDAO;
import com.vjnt.model.School;
import com.vjnt.model.User;
import com.vjnt.model.VidnyanSetuUser;
import com.vjnt.util.PasswordUtil;
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
 * DATA_ADMIN-only: create/enable/disable VidnyanSetu School Coordinator
 * logins (vidnyansetu_users, role COORDINATOR) — one per school, the
 * standalone-portal counterpart of a normal SCHOOL_COORDINATOR account.
 * POST params: action=add (teacherName->coordinatorName, mobile, udiseNo)
 *              action=toggle (vsUserId, active)
 */
@WebServlet("/vidnyansetu-manage-coordinators")
public class VidnyanSetuManageCoordinatorsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final VidnyanSetuUserDAO vsUserDAO = new VidnyanSetuUserDAO();
    private final SchoolDAO schoolDAO = new SchoolDAO();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        JSONObject result = new JSONObject();

        HttpSession session = request.getSession(false);
        User admin = session == null ? null : (User) session.getAttribute("user");
        if (admin == null || admin.getUserType() != User.UserType.DATA_ADMIN) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            result.put("success", false);
            result.put("message", "Unauthorized access");
            out.print(result.toString());
            return;
        }

        String action = request.getParameter("action");
        if ("toggle".equals(action)) {
            doToggle(request, result);
        } else {
            doAdd(request, admin, result);
        }
        out.print(result.toString());
    }

    private void doAdd(HttpServletRequest request, User admin, JSONObject result) {
        String name = request.getParameter("coordinatorName");
        String mobile = request.getParameter("mobile");
        String udiseNo = request.getParameter("udiseNo");

        if (name == null || name.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "Coordinator name is required");
            return;
        }
        if (mobile == null || !mobile.matches("\\d{10}")) {
            result.put("success", false);
            result.put("message", "Valid 10-digit mobile number is required");
            return;
        }
        if (udiseNo == null || udiseNo.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "Please pick a school from the list");
            return;
        }

        // The UDISE must be a real school from the master list (schools table) —
        // the coordinator page's picker only lets the admin choose from there,
        // but the server re-validates in case of a stale/tampered request.
        School school = schoolDAO.getSchoolByUdise(udiseNo.trim());
        if (school == null) {
            result.put("success", false);
            result.put("message", "No school found for UDISE " + udiseNo.trim() + ". Please pick a school from the list.");
            return;
        }

        // Coordinator username is derived from the school's UDISE number, not
        // the mobile number — vs_<udiseNo>, so it also enforces one VidnyanSetu
        // coordinator per school (a second add for the same UDISE collides here).
        String username = "vs_" + udiseNo.trim();
        if (vsUserDAO.usernameExists(username)) {
            result.put("success", false);
            result.put("message", "A VidnyanSetu coordinator already exists for UDISE " + udiseNo.trim()
                    + " (username " + username + ")");
            return;
        }

        boolean created = vsUserDAO.createUser(username,
                PasswordUtil.hashPassword(PasswordUtil.getDefaultPassword()),
                VidnyanSetuUser.Role.COORDINATOR, udiseNo.trim(), name.trim(), mobile, admin.getUsername());

        if (created) {
            VidnyanSetuUser newCoordinator = vsUserDAO.findByUsername(username);
            result.put("success", true);
            result.put("username", username);
            result.put("password", PasswordUtil.getDefaultPassword());
            result.put("vsUserId", newCoordinator != null ? newCoordinator.getVsUserId() : JSONObject.NULL);
            result.put("message", "Coordinator added for " + school.getSchoolName() + " — Username: " + username
                    + ", Password: " + PasswordUtil.getDefaultPassword());
        } else {
            result.put("success", false);
            result.put("message", "Failed to create coordinator login");
        }
    }

    private void doToggle(HttpServletRequest request, JSONObject result) {
        int vsUserId;
        boolean active;
        try {
            vsUserId = Integer.parseInt(request.getParameter("vsUserId"));
            active = Boolean.parseBoolean(request.getParameter("active"));
        } catch (NumberFormatException e) {
            result.put("success", false);
            result.put("message", "Invalid parameters");
            return;
        }
        VidnyanSetuUser target = vsUserDAO.findById(vsUserId);
        if (target == null || target.getRole() != VidnyanSetuUser.Role.COORDINATOR) {
            result.put("success", false);
            result.put("message", "Coordinator not found");
            return;
        }
        boolean ok = vsUserDAO.setActive(vsUserId, active);
        result.put("success", ok);
        if (!ok) result.put("message", "Failed to update status");
    }
}
