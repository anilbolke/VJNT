package com.vjnt.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.gson.Gson;
import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

/**
 * Servlet to fetch teacher assignments for district coordinators
 * Shows all teacher assignments across all schools in the district
 */
@WebServlet("/get-district-teacher-assignments")
public class GetDistrictTeacherAssignmentsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.getWriter().write("{\"success\":false,\"message\":\"Session expired\"}");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        if (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
            !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR)) {
            response.getWriter().write("{\"success\":false,\"message\":\"Unauthorized access\"}");
            return;
        }
        
        String districtName = user.getDistrictName();
        String udiseFilter = request.getParameter("udise");
        String classFilter = request.getParameter("class");
        String sectionFilter = request.getParameter("section");
        
        // Pagination parameters
        int page = 1;
        int pageSize = 50; // Show 50 records per page
        try {
            String pageParam = request.getParameter("page");
            if (pageParam != null && !pageParam.isEmpty()) {
                page = Integer.parseInt(pageParam);
            }
            String pageSizeParam = request.getParameter("pageSize");
            if (pageSizeParam != null && !pageSizeParam.isEmpty()) {
                pageSize = Integer.parseInt(pageSizeParam);
            }
        } catch (NumberFormatException e) {
            // Use default values
        }
        
        int offset = (page - 1) * pageSize;
        
        List<Map<String, Object>> assignments = new ArrayList<>();
        int totalCount = 0;
        Connection conn = null;
        PreparedStatement pstmt = null;
        PreparedStatement countPstmt = null;
        ResultSet rs = null;
        ResultSet countRs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            // First, get total count for pagination
            StringBuilder countSql = new StringBuilder();
            countSql.append("SELECT COUNT(*) as total ");
            countSql.append("FROM teacher_assignments ta ");
            countSql.append("WHERE ta.district = ? AND ta.is_active = 1 ");
            
            if (udiseFilter != null && !udiseFilter.trim().isEmpty()) {
                countSql.append("AND ta.udise_code = ? ");
            }
            if (classFilter != null && !classFilter.trim().isEmpty()) {
                countSql.append("AND ta.class = ? ");
            }
            if (sectionFilter != null && !sectionFilter.trim().isEmpty()) {
                countSql.append("AND ta.section = ? ");
            }
            
            countPstmt = conn.prepareStatement(countSql.toString());
            int countParamIndex = 1;
            countPstmt.setString(countParamIndex++, districtName);
            
            if (udiseFilter != null && !udiseFilter.trim().isEmpty()) {
                countPstmt.setString(countParamIndex++, udiseFilter);
            }
            if (classFilter != null && !classFilter.trim().isEmpty()) {
                countPstmt.setString(countParamIndex++, classFilter);
            }
            if (sectionFilter != null && !sectionFilter.trim().isEmpty()) {
                countPstmt.setString(countParamIndex++, sectionFilter);
            }
            
            countRs = countPstmt.executeQuery();
            if (countRs.next()) {
                totalCount = countRs.getInt("total");
            }
            
            // Now get paginated data
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT ta.assignment_id, ta.udise_code, ta.district, ta.division, ");
            sql.append("ta.teacher_id, ta.teacher_name, ta.class, ta.section, ");
            sql.append("ta.subjects_assigned, ta.is_class_teacher, ta.created_date, ");
            sql.append("s.school_name ");
            sql.append("FROM teacher_assignments ta ");
            sql.append("LEFT JOIN schools s ON ta.udise_code COLLATE utf8mb4_unicode_ci = s.udise_no COLLATE utf8mb4_unicode_ci ");
            sql.append("WHERE ta.district = ? AND ta.is_active = 1 ");
            
            if (udiseFilter != null && !udiseFilter.trim().isEmpty()) {
                sql.append("AND ta.udise_code = ? ");
            }
            if (classFilter != null && !classFilter.trim().isEmpty()) {
                sql.append("AND ta.class = ? ");
            }
            if (sectionFilter != null && !sectionFilter.trim().isEmpty()) {
                sql.append("AND ta.section = ? ");
            }
            
            sql.append("ORDER BY s.school_name, ta.class, ta.section, ta.teacher_name ");
            sql.append("LIMIT ? OFFSET ?");
            
            pstmt = conn.prepareStatement(sql.toString());
            int paramIndex = 1;
            pstmt.setString(paramIndex++, districtName);
            
            if (udiseFilter != null && !udiseFilter.trim().isEmpty()) {
                pstmt.setString(paramIndex++, udiseFilter);
            }
            if (classFilter != null && !classFilter.trim().isEmpty()) {
                pstmt.setString(paramIndex++, classFilter);
            }
            if (sectionFilter != null && !sectionFilter.trim().isEmpty()) {
                pstmt.setString(paramIndex++, sectionFilter);
            }
            
            pstmt.setInt(paramIndex++, pageSize);
            pstmt.setInt(paramIndex++, offset);
            
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> assignment = new HashMap<>();
                assignment.put("assignmentId", rs.getInt("assignment_id"));
                assignment.put("udiseCode", rs.getString("udise_code"));
                assignment.put("schoolName", rs.getString("school_name"));
                assignment.put("schoolType", "N/A");
                assignment.put("district", rs.getString("district"));
                assignment.put("division", rs.getString("division"));
                assignment.put("teacherId", rs.getInt("teacher_id"));
                assignment.put("teacherName", rs.getString("teacher_name"));
                assignment.put("classValue", rs.getString("class"));
                assignment.put("section", rs.getString("section"));
                assignment.put("subjects", rs.getString("subjects_assigned"));
                assignment.put("isClassTeacher", rs.getInt("is_class_teacher") == 1);
                assignment.put("createdDate", rs.getTimestamp("created_date").toString());
                
                assignments.add(assignment);
            }
            
            // Calculate total pages
            int totalPages = (int) Math.ceil((double) totalCount / pageSize);
            
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("assignments", assignments);
            result.put("count", assignments.size());
            result.put("totalCount", totalCount);
            result.put("currentPage", page);
            result.put("pageSize", pageSize);
            result.put("totalPages", totalPages);
            result.put("hasNext", page < totalPages);
            result.put("hasPrevious", page > 1);
            
            Gson gson = new Gson();
            response.getWriter().write(gson.toJson(result));
            
        } catch (SQLException e) {
            System.err.println("Error fetching teacher assignments: " + e.getMessage());
            e.printStackTrace();
            response.getWriter().write("{\"success\":false,\"message\":\"Database error: " + e.getMessage() + "\"}");
        } finally {
            if (countRs != null) try { countRs.close(); } catch (SQLException e) { }
            if (countPstmt != null) try { countPstmt.close(); } catch (SQLException e) { }
            if (rs != null) try { rs.close(); } catch (SQLException e) { }
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
            if (conn != null) try { conn.close(); } catch (SQLException e) { }
        }
    }
}
