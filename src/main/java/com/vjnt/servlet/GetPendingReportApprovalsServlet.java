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

@WebServlet("/GetPendingReportApprovalsServlet")
public class GetPendingReportApprovalsServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        String udiseCode = (String) session.getAttribute("udiseCode");
        List<ApprovalRequest> approvals = new ArrayList<>();
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            String sql = "SELECT ra.approval_id, ra.pen_number, ra.student_name, ra.class, ra.section, " +
                        "ra.requested_date, u.username as requested_by_name " +
                        "FROM report_approvals ra " +
                        "JOIN users u ON ra.requested_by = u.user_id " +
                        "WHERE ra.udise_code = ? AND ra.approval_status = 'PENDING' AND ra.is_active = 1 " +
                        "ORDER BY ra.requested_date ASC";
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, udiseCode);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                ApprovalRequest approval = new ApprovalRequest();
                approval.approvalId = rs.getInt("approval_id");
                approval.penNumber = rs.getString("pen_number");
                approval.studentName = rs.getString("student_name");
                approval.studentClass = rs.getString("class");
                approval.section = rs.getString("section");
                approval.requestedDate = sdf.format(rs.getTimestamp("requested_date"));
                approval.requestedByName = rs.getString("requested_by_name");
                approvals.add(approval);
            }
            
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(new Gson().toJson(approvals));
    }
    
    class ApprovalRequest {
        int approvalId;
        String penNumber;
        String studentName;
        @com.google.gson.annotations.SerializedName("class")
        String studentClass;
        String section;
        String requestedDate;
        String requestedByName;
    }
}
