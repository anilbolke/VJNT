package com.vjnt.servlet;

import java.io.IOException;
import java.sql.*;
import java.text.SimpleDateFormat;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.google.gson.JsonObject;
import com.vjnt.util.DatabaseConnection;

@WebServlet("/CheckReportApprovalStatusServlet")
public class CheckReportApprovalStatusServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        Integer userId = (Integer) session.getAttribute("userId");
        String penNumber = request.getParameter("penNumber");
        
        if (penNumber == null || penNumber.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "PEN number required");
            return;
        }
        
        JsonObject result = new JsonObject();
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            // Get the most recent approval request for this student by this user
            // Only show APPROVED status if report hasn't been generated yet (report_generated = 0)
            // Once report is generated/printed, we should show "No Approval Request" for new submissions
            String sql = "SELECT approval_id, approval_status, requested_date, approval_remarks, report_generated " +
                        "FROM report_approvals " +
                        "WHERE pen_number = ? AND requested_by = ? AND is_active = 1 " +
                        "ORDER BY requested_date DESC " +
                        "LIMIT 1";

            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, penNumber);
            stmt.setInt(2, userId);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                String approvalStatus = rs.getString("approval_status");
                int reportGenerated = rs.getInt("report_generated");
                
                // If status is APPROVED and report has been generated (printed), 
                // treat it as if there's no active approval request
                // This allows coordinator to make new changes and submit again
                if ("APPROVED".equals(approvalStatus) && reportGenerated == 1) {
                    result.addProperty("hasRequest", false);
                    result.addProperty("previouslyApproved", true);
                    result.addProperty("message", "Previous report was approved and printed. You can submit new changes for approval.");
                } else {
                    result.addProperty("hasRequest", true);
                    result.addProperty("approvalId", rs.getInt("approval_id"));
                    result.addProperty("status", approvalStatus);
                    result.addProperty("remarks", rs.getString("approval_remarks"));
                    result.addProperty("reportGenerated", reportGenerated);

                    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
                    result.addProperty("requestedDate", sdf.format(rs.getTimestamp("requested_date")));
                }
            } else {
                result.addProperty("hasRequest", false);
            }

        } catch (Exception e) {
            e.printStackTrace();
            result.addProperty("hasRequest", false);
            result.addProperty("error", e.getMessage());
        }
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(result.toString());
    }
}
