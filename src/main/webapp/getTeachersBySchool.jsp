<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.vjnt.util.DatabaseConnection" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%
    // Check if user is logged in and is a district coordinator
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR))) {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        out.print("{\"success\": false, \"message\": \"Unauthorized access\"}");
        return;
    }
    
    String udiseCode = request.getParameter("udiseCode");
    
    if (udiseCode == null || udiseCode.trim().isEmpty()) {
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        out.print("{\"success\": false, \"message\": \"UDISE code is required\"}");
        return;
    }
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    SimpleDateFormat dateFormat = new SimpleDateFormat("dd-MMM-yyyy");
    
    try {
        conn = DatabaseConnection.getConnection();
        
        // Verify the school belongs to the user's district
        String verifySql = "SELECT district_name FROM schools WHERE udise_no = ?";
        pstmt = conn.prepareStatement(verifySql);
        pstmt.setString(1, udiseCode);
        rs = pstmt.executeQuery();
        
        if (!rs.next()) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            out.print("{\"success\": false, \"message\": \"School not found\"}");
            return;
        }
        
        String schoolDistrict = rs.getString("district_name");
        if (!schoolDistrict.equals(user.getDistrictName())) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print("{\"success\": false, \"message\": \"Access denied to this school\"}");
            return;
        }
        
        rs.close();
        pstmt.close();
        
        // Fetch teachers for this school
        String sql = "SELECT teacher_id, teacher_name, mobile_number, subjects_taught, " +
                     "description, created_date " +
                     "FROM teachers " +
                     "WHERE udise_code = ? AND is_active = 1 " +
                     "ORDER BY teacher_name";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, udiseCode);
        rs = pstmt.executeQuery();
        
        StringBuilder json = new StringBuilder();
        json.append("{\"success\": true, \"teachers\": [");
        
        boolean first = true;
        while (rs.next()) {
            if (!first) {
                json.append(",");
            }
            first = false;
            
            int teacherId = rs.getInt("teacher_id");
            String teacherName = rs.getString("teacher_name");
            String mobile = rs.getString("mobile_number");
            String subjects = rs.getString("subjects_taught");
            String description = rs.getString("description");
            Timestamp createdDate = rs.getTimestamp("created_date");
            
            // Escape JSON strings
            teacherName = teacherName.replace("\\", "\\\\").replace("\"", "\\\"");
            subjects = subjects.replace("\\", "\\\\").replace("\"", "\\\"");
            if (description != null) {
                description = description.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ").replace("\r", " ");
            }
            
            json.append("{");
            json.append("\"id\": ").append(teacherId).append(",");
            json.append("\"name\": \"").append(teacherName).append("\",");
            json.append("\"mobile\": \"").append(mobile).append("\",");
            json.append("\"subjects\": \"").append(subjects).append("\",");
            json.append("\"description\": ").append(description != null ? "\"" + description + "\"" : "null").append(",");
            json.append("\"createdDate\": \"").append(dateFormat.format(createdDate)).append("\"");
            json.append("}");
        }
        
        json.append("]}");
        
        response.setContentType("application/json");
        out.print(json.toString());
        
    } catch (Exception e) {
        e.printStackTrace();
        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        out.print("{\"success\": false, \"message\": \"Error fetching teacher data: " + e.getMessage() + "\"}");
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
        if (conn != null) try { conn.close(); } catch (SQLException e) { }
    }
%>
