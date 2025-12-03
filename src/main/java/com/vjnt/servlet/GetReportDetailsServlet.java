package com.vjnt.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.google.gson.JsonObject;
import com.vjnt.dao.ReportApprovalDAO;
import com.vjnt.model.ReportApproval;

@WebServlet("/api/getReportDetails")
public class GetReportDetailsServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        String approvalIdStr = request.getParameter("approvalId");
        
        if (approvalIdStr == null || approvalIdStr.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Approval ID required");
            return;
        }
        
        try {
            int approvalId = Integer.parseInt(approvalIdStr);
            ReportApprovalDAO dao = new ReportApprovalDAO();
            ReportApproval report = dao.getReportByApprovalId(approvalId);
            
            if (report == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Report not found");
                return;
            }
            
            JsonObject json = new JsonObject();
            json.addProperty("approvalId", report.getApprovalId());
            json.addProperty("studentName", report.getStudentName());
            json.addProperty("penNumber", report.getPenNumber());
            json.addProperty("studentClass", report.getStudentClass());
            json.addProperty("section", report.getSection());
            json.addProperty("status", report.getApprovalStatus());
            
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write(json.toString());
            
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid approval ID");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Error fetching report details");
        }
    }
}
