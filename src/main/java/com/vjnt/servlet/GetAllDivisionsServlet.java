package com.vjnt.servlet;

import com.vjnt.dao.StudentDAO;
import com.google.gson.Gson;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * Returns the distinct list of divisions for the Super Division Officer
 * "All Divisions" dropdown. Restricted to SUPER_DIVISION_OFFICER sessions.
 */
@WebServlet("/get-all-divisions")
public class GetAllDivisionsServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        com.vjnt.model.User user = null;
        if (session != null) {
            user = (com.vjnt.model.User) session.getAttribute("user");
        }

        List<String> divisions = new ArrayList<>();

        if (user != null && user.getUserType() == com.vjnt.model.User.UserType.SUPER_DIVISION_OFFICER) {
            StudentDAO studentDAO = new StudentDAO();
            divisions = studentDAO.getDistinctDivisions();
        }

        response.getWriter().write(new Gson().toJson(divisions));
    }
}
