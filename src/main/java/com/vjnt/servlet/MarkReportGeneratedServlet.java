package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.vjnt.util.DatabaseConnection;

@WebServlet("/MarkReportGeneratedServlet")
public class MarkReportGeneratedServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        String approvalIdParam = request.getParameter("approvalId");
        if (approvalIdParam == null || approvalIdParam.trim().isEmpty()) {
            out.print("{\"success\":false,\"message\":\"approvalId is required\"}");
            return;
        }

        try {
            int approvalId = Integer.parseInt(approvalIdParam);
            try (Connection conn = DatabaseConnection.getConnection()) {
                String sql = "UPDATE report_approvals SET report_generated = 1, generated_date = NOW() WHERE approval_id = ?";
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setInt(1, approvalId);
                int rows = stmt.executeUpdate();
                if (rows > 0) {
                    out.print("{\"success\":true}");
                } else {
                    out.print("{\"success\":false,\"message\":\"No record updated\"}");
                }
            }
        } catch (NumberFormatException e) {
            out.print("{\"success\":false,\"message\":\"Invalid approvalId\"}");
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"" + e.getMessage() + "\"}");
        }
    }
}
