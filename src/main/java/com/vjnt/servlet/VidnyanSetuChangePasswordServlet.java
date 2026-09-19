package com.vjnt.servlet;

import com.vjnt.dao.VidnyanSetuUserDAO;
import com.vjnt.model.VidnyanSetuUser;
import com.vjnt.util.PasswordUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

/** Change-password flow for the vidnyansetu_users table. Mirrors ChangePasswordServlet. */
@WebServlet("/vidnyansetu-change-password")
public class VidnyanSetuChangePasswordServlet extends HttpServlet {

    private VidnyanSetuUserDAO vsUserDAO;

    @Override
    public void init() throws ServletException {
        vsUserDAO = new VidnyanSetuUserDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/vidnyansetu-change-password.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        VidnyanSetuUser vsUser = session == null ? null : (VidnyanSetuUser) session.getAttribute("vsUser");
        if (vsUser == null) {
            response.sendRedirect(request.getContextPath() + "/vidnyansetu-login");
            return;
        }

        String currentPassword = request.getParameter("currentPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        if (currentPassword == null || currentPassword.trim().isEmpty() ||
                newPassword == null || newPassword.trim().isEmpty() ||
                confirmPassword == null || confirmPassword.trim().isEmpty()) {
            request.setAttribute("errorMessage", "All fields are required");
            request.getRequestDispatcher("/vidnyansetu-change-password.jsp").forward(request, response);
            return;
        }

        if (!PasswordUtil.verifyPassword(currentPassword, vsUser.getPassword())) {
            request.setAttribute("errorMessage", "Current password is incorrect");
            request.getRequestDispatcher("/vidnyansetu-change-password.jsp").forward(request, response);
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            request.setAttribute("errorMessage", "New password and confirm password do not match");
            request.getRequestDispatcher("/vidnyansetu-change-password.jsp").forward(request, response);
            return;
        }

        if (!PasswordUtil.isValidPassword(newPassword)) {
            request.setAttribute("errorMessage",
                    "Password must be at least 8 characters long and contain uppercase, lowercase, digit, and special character");
            request.getRequestDispatcher("/vidnyansetu-change-password.jsp").forward(request, response);
            return;
        }

        if (currentPassword.equals(newPassword)) {
            request.setAttribute("errorMessage", "New password must be different from current password");
            request.getRequestDispatcher("/vidnyansetu-change-password.jsp").forward(request, response);
            return;
        }

        String hashedNewPassword = PasswordUtil.hashPassword(newPassword);
        if (vsUserDAO.updatePassword(vsUser.getVsUserId(), hashedNewPassword)) {
            session.invalidate();
            response.sendRedirect(request.getContextPath()
                    + "/vidnyansetu-login?message=Password changed successfully! Please login with your new password.");
        } else {
            request.setAttribute("errorMessage", "Failed to update password. Please try again.");
            request.getRequestDispatcher("/vidnyansetu-change-password.jsp").forward(request, response);
        }
    }
}
