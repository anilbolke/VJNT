package com.vjnt.servlet;

import java.io.IOException;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.google.gson.Gson;
import com.vjnt.util.DatabaseConnection;

@WebServlet("/GetMyReportRequestsServlet")
public class GetMyReportRequestsServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        Integer userId = (Integer) session.getAttribute("userId");
        List<ReportRequest> requests = new ArrayList<>();
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            String sql = "SELECT approval_id, pen_number, student_name, class, section, " +
                        "approval_status, requested_date, approval_remarks " +
                        "FROM report_approvals " +
                        "WHERE requested_by = ? AND is_active = 1 " +
                        "ORDER BY requested_date DESC";
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, userId);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                ReportRequest req = new ReportRequest();
                req.approvalId = rs.getInt("approval_id");
                req.penNumber = rs.getString("pen_number");
                req.studentName = rs.getString("student_name");
                req.studentClass = rs.getString("class");
                req.section = rs.getString("section");
                req.approvalStatus = rs.getString("approval_status");
                req.requestedDate = sdf.format(rs.getTimestamp("requested_date"));
                req.approvalRemarks = rs.getString("approval_remarks");
                requests.add(req);
            }
            
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(new Gson().toJson(requests));
    }
    
    class ReportRequest {
        int approvalId;
        String penNumber;
        String studentName;
        String studentClass;
        String section;
        String approvalStatus;
        String requestedDate;
        String approvalRemarks;
    }
}
