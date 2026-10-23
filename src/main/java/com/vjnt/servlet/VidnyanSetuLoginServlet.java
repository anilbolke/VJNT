package com.vjnt.servlet;

import com.vjnt.dao.VidnyanSetuUserDAO;
import com.vjnt.model.VidnyanSetuUser;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * Login for the standalone VidnyanSetu (विज्ञानसेतू) portal — separate from
 * /login: authenticates against vidnyansetu_users (not users) and stores the
 * result under session attribute "vsUser" (not "user"), so the two portals
 * never collide. See VidnyanSetuUser for why these are separate accounts.
 */
@WebServlet("/vidnyansetu-login")
public class VidnyanSetuLoginServlet extends HttpServlet {

    private VidnyanSetuUserDAO vsUserDAO;

    @Override
    public void init() throws ServletException {
        vsUserDAO = new VidnyanSetuUserDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/vidnyansetu-login.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        if (username == null || username.trim().isEmpty() ||
                password == null || password.trim().isEmpty()) {
            request.setAttribute("errorMessage", "Username and password are required");
            request.getRequestDispatcher("/vidnyansetu-login.jsp").forward(request, response);
            return;
        }

        VidnyanSetuUser vsUser = vsUserDAO.authenticate(username.trim(), password);

        if (vsUser != null) {
            HttpSession session = request.getSession();
            session.setAttribute("vsUser", vsUser);
            session.setAttribute("vsUserId", vsUser.getVsUserId());
            session.setAttribute("vsUsername", vsUser.getUsername());
            session.setAttribute("vsRole", vsUser.getRole().name());
            session.setAttribute("vsUdise", vsUser.getUdiseNo());
            session.setMaxInactiveInterval(30 * 60);

            if (vsUser.isFirstLogin() || vsUser.isMustChangePassword()) {
                response.sendRedirect(request.getContextPath() + "/vidnyansetu-change-password.jsp");
            } else {
                response.sendRedirect(request.getContextPath() + getDashboardUrl(vsUser.getRole()));
            }
        } else {
            VidnyanSetuUser check = vsUserDAO.findByUsername(username.trim());
            String errorMessage = "Invalid username or password";
            if (check != null && check.isAccountLocked()) {
                errorMessage = "Your account has been locked due to multiple failed login attempts. Please contact your VidnyanSetu coordinator/administrator.";
            } else if (check != null && !check.isActive()) {
                errorMessage = "Your account is inactive. Please contact your administrator.";
            }
            request.setAttribute("errorMessage", errorMessage);
            request.getRequestDispatcher("/vidnyansetu-login.jsp").forward(request, response);
        }
    }

    private String getDashboardUrl(VidnyanSetuUser.Role role) {
        switch (role) {
            case COORDINATOR:
                return "/vidnyansetu-coordinator-dashboard.jsp";
            case TEACHER:
                return "/vidnyansetu-teacher-dashboard.jsp";
            default:
                return "/vidnyansetu-login.jsp";
        }
    }
}
