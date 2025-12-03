package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.vjnt.model.User;
import com.vjnt.dao.ReportApprovalDAO;
import com.vjnt.model.ReportApproval;
import org.json.JSONObject;
import org.json.JSONArray;
import java.text.SimpleDateFormat;
import java.util.List;

@WebServlet("/GetRecentReportsServlet")
public class GetRecentReportsServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json; charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print(new JSONObject().put("success", false).put("message", "Unauthorized").toString());
            return;
        }
        
        User user = (User) session.getAttribute("user");
        String udiseNo = user.getUdiseNo();
        
        try {
            ReportApprovalDAO approvalDAO = new ReportApprovalDAO();
            
            // Get all reports (both pending and approved) for this school
            List<ReportApproval> pendingReports = approvalDAO.getPendingReportsByUdise(udiseNo);
            List<ReportApproval> approvedReports = approvalDAO.getApprovedReportsByUdise(udiseNo);
            
            JSONObject response_obj = new JSONObject();
            JSONArray reports = new JSONArray();
            
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
            
            // Add pending reports
            if (pendingReports != null) {
                for (ReportApproval report : pendingReports) {
                    JSONObject reportObj = new JSONObject();
                    reportObj.put("approvalId", report.getApprovalId());
                    reportObj.put("studentName", report.getStudentName());
                    reportObj.put("penNumber", report.getPenNumber());
                    reportObj.put("reportType", report.getReportType());
                    reportObj.put("status", "PENDING");
                    reportObj.put("requestedDate", sdf.format(report.getRequestedDate()));
                    reports.put(reportObj);
                }
            }
            
            // Add approved reports (limit to last 5)
            if (approvedReports != null) {
                int count = 0;
                for (ReportApproval report : approvedReports) {
                    if (count >= 5) break;
                    
                    JSONObject reportObj = new JSONObject();
                    reportObj.put("approvalId", report.getApprovalId());
                    reportObj.put("studentName", report.getStudentName());
                    reportObj.put("penNumber", report.getPenNumber());
                    reportObj.put("reportType", report.getReportType());
                    reportObj.put("status", "APPROVED");
                    reportObj.put("requestedDate", sdf.format(report.getApprovalDate()));
                    reports.put(reportObj);
                    count++;
                }
            }
            
            response_obj.put("success", true);
            response_obj.put("reports", reports);
            out.print(response_obj.toString());
            
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            JSONObject error_obj = new JSONObject();
            error_obj.put("success", false);
            error_obj.put("message", "Error: " + e.getMessage());
            out.print(error_obj.toString());
        }
    }
}
