package com.vjnt.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.vjnt.dao.ReportApprovalDAO;
import com.vjnt.dao.StudentDAO;
import com.vjnt.dao.SchoolDAO;
import com.vjnt.model.ReportApproval;
import com.vjnt.model.Student;
import com.vjnt.model.School;
import com.vjnt.model.User;

@WebServlet("/SubmitReportForApprovalServlet")
public class SubmitReportForApprovalServlet extends HttpServlet {
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            sendJsonResponse(response, false, "Session expired. Please login again.", null);
            return;
        }
        
        Integer userId = (Integer) session.getAttribute("userId");
        String userType = (String) session.getAttribute("userType");
        User user = (User) session.getAttribute("user");
        
        // Only SCHOOL_COORDINATOR can submit
        if (!"SCHOOL_COORDINATOR".equals(userType)) {
            sendJsonResponse(response, false, "Only School Coordinator can submit reports for approval.", null);
            return;
        }
        
        String penNumber = request.getParameter("penNumber");
        String studentName = request.getParameter("studentName");
        
        if (penNumber == null || penNumber.trim().isEmpty()) {
            sendJsonResponse(response, false, "Student PEN number is required.", null);
            return;
        }
        
        try {
            ReportApprovalDAO approvalDAO = new ReportApprovalDAO();
            
            // Check if there's already a pending request for this student by this user
            ReportApproval existingRequest = approvalDAO.getLatestReportByPenAndUser(penNumber, userId);
            
            if (existingRequest != null && "PENDING".equals(existingRequest.getApprovalStatus())) {
                sendJsonResponse(response, false, "A report request for this student is already pending approval.", null);
                return;
            }
            
            StudentDAO studentDAO = new StudentDAO();
            Student student = studentDAO.getStudentByPen(penNumber);
            
            if (student == null) {
                sendJsonResponse(response, false, "Student not found.", null);
                return;
            }
            
            SchoolDAO schoolDAO = new SchoolDAO();
            School school = schoolDAO.getSchoolByUdise(user.getUdiseNo());
            
            // Create approval request
            ReportApproval approval = new ReportApproval();
            approval.setReportType("STUDENT_COMPREHENSIVE");
            approval.setPenNumber(penNumber);
            approval.setStudentName(studentName != null ? studentName : student.getStudentName());
            approval.setStudentClass(student.getStudentClass());
            approval.setSection(student.getSection());
            approval.setUdiseCode(user.getUdiseNo());
            approval.setSchoolName(school != null ? school.getSchoolName() : "");
            approval.setDistrict(""); // Set from school if available
            approval.setDivision(""); // Set from school if available
            approval.setRequestedBy(userId);
            
            int approvalId = approvalDAO.createReportApproval(approval);
            
            if (approvalId > 0) {
                sendJsonResponse(response, true, "Report submitted for Head Master approval successfully! Request ID: #" + approvalId, approvalId);
            } else {
                sendJsonResponse(response, false, "Failed to submit report for approval.", null);
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            sendJsonResponse(response, false, "Error: " + e.getMessage(), null);
        }
    }
    
    private void sendJsonResponse(HttpServletResponse response, boolean success, String message, Integer approvalId) 
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        JsonObject json = new JsonObject();
        json.addProperty("success", success);
        json.addProperty("message", message);
        if (approvalId != null) {
            json.addProperty("approvalId", approvalId);
        }
        
        response.getWriter().write(new Gson().toJson(json));
    }
}
