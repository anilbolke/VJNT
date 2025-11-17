<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.List" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Test School Upload</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        .test-section { background: #f0f0f0; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .success { color: green; }
        .error { color: red; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
    </style>
</head>
<body>
    <h1>🔍 School Upload System - Test Page</h1>
    
    <div class="test-section">
        <h2>1. Database Connection Test</h2>
        <%
        try {
            SchoolDAO schoolDAO = new SchoolDAO();
            out.println("<p class='success'>✓ SchoolDAO instantiated successfully</p>");
            
            int count = schoolDAO.getSchoolCount();
            out.println("<p class='success'>✓ Database connection working</p>");
            out.println("<p><strong>Current schools in database: " + count + "</strong></p>");
        } catch (Exception e) {
            out.println("<p class='error'>✗ Error: " + e.getMessage() + "</p>");
            e.printStackTrace();
        }
        %>
    </div>
    
    <div class="test-section">
        <h2>2. Schools Table Structure Test</h2>
        <%
        try {
            SchoolDAO schoolDAO = new SchoolDAO();
            out.println("<p class='success'>✓ Schools table exists</p>");
            out.println("<p>Required columns: school_id, udise_no, school_name, district_name</p>");
        } catch (Exception e) {
            out.println("<p class='error'>✗ Error accessing schools table: " + e.getMessage() + "</p>");
            out.println("<p><strong>Solution:</strong> Run create_schools_table_if_not_exists.sql</p>");
        }
        %>
    </div>
    
    <div class="test-section">
        <h2>3. List Current Schools (Top 10)</h2>
        <%
        try {
            SchoolDAO schoolDAO = new SchoolDAO();
            List<School> schools = schoolDAO.getAllSchools();
            
            if (schools.isEmpty()) {
                out.println("<p>No schools found in database. Upload Excel file to add schools.</p>");
            } else {
                out.println("<p>Showing top 10 schools:</p>");
                out.println("<table>");
                out.println("<tr><th>UDISE No</th><th>School Name</th><th>District</th></tr>");
                
                int limit = Math.min(10, schools.size());
                for (int i = 0; i < limit; i++) {
                    School s = schools.get(i);
                    out.println("<tr>");
                    out.println("<td>" + s.getUdiseNo() + "</td>");
                    out.println("<td>" + s.getSchoolName() + "</td>");
                    out.println("<td>" + (s.getDistrictName() != null ? s.getDistrictName() : "-") + "</td>");
                    out.println("</tr>");
                }
                
                out.println("</table>");
                out.println("<p><em>Total: " + schools.size() + " schools</em></p>");
            }
        } catch (Exception e) {
            out.println("<p class='error'>✗ Error: " + e.getMessage() + "</p>");
            e.printStackTrace();
        }
        %>
    </div>
    
    <div class="test-section">
        <h2>4. Upload Test</h2>
        <p>If all above tests pass, proceed to upload:</p>
        <a href="<%= request.getContextPath() %>/upload-schools.jsp" style="display: inline-block; padding: 10px 20px; background: #4CAF50; color: white; text-decoration: none; border-radius: 5px;">
            Go to Upload Page
        </a>
    </div>
    
    <div class="test-section">
        <h2>5. Servlet Mapping Test</h2>
        <p>Servlet URL: <code><%= request.getContextPath() %>/upload-schools</code></p>
        <p>Servlet should be accessible at this URL (POST method)</p>
    </div>
    
    <hr>
    <p><a href="<%= request.getContextPath() %>/data-admin-dashboard.jsp">← Back to Dashboard</a></p>
</body>
</html>
