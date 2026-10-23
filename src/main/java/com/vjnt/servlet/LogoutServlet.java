package com.vjnt.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * Logout Servlet
 * Handles user logout
 */
@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        boolean isVidnyanSetuSession = session != null && session.getAttribute("vsUser") != null;
        if (session != null) {
            session.invalidate();
        }

        String target = isVidnyanSetuSession ? "/vidnyansetu-login" : "/login";
        response.sendRedirect(request.getContextPath() + target + "?message=logout");
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}
