<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Activity Analysis Test</title>
    <style>
        body { font-family: Arial; padding: 20px; }
        .info { background: #e3f2fd; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .success { background: #c8e6c9; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .error { background: #ffcdd2; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .btn { display: inline-block; padding: 10px 20px; margin: 5px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🔍 Activity Analysis Test Page</h1>
    
    <% if (user == null) { %>
        <div class="error">
            <h3>❌ Not Logged In</h3>
            <p>Please login first</p>
            <a href="login.jsp" class="btn">Go to Login</a>
        </div>
    <% } else { %>
        <div class="success">
            <h3>✅ User Session Found</h3>
        </div>
        
        <div class="info">
            <h4>User Information:</h4>
            <p><strong>Username:</strong> <%= user.getUsername() %></p>
            <p><strong>Full Name:</strong> <%= user.getFullName() %></p>
            <p><strong>User Type:</strong> <%= user.getUserType() %></p>
            <p><strong>Division:</strong> <%= user.getDivisionName() != null ? user.getDivisionName() : "N/A" %></p>
            <p><strong>District:</strong> <%= user.getDistrictName() != null ? user.getDistrictName() : "N/A" %></p>
            <p><strong>UDISE:</strong> <%= user.getUdiseNo() != null ? user.getUdiseNo() : "N/A" %></p>
        </div>
        
        <div class="info">
            <h4>Access Activity Analysis:</h4>
            <% 
                String userType = user.getUserType().toString();
                if (userType.contains("DISTRICT")) { 
            %>
                <p>✓ You can access District Activity Analysis</p>
                <a href="district-activity-analysis.jsp" class="btn">📈 Open District Activity Analysis</a>
            <% } else if (userType.contains("DIVISION")) { %>
                <p>✓ You can access Division Activity Analysis</p>
                <a href="division-activity-analysis.jsp" class="btn">📈 Open Division Activity Analysis</a>
            <% } else { %>
                <p>⚠️ Your user type (<%=userType%>) cannot access Activity Analysis pages</p>
            <% } %>
        </div>
        
        <div class="info">
            <h4>Test Servlets:</h4>
            <% if (userType.contains("DISTRICT")) { %>
                <a href="GetSchoolActivityAnalysisServlet" class="btn" target="_blank">Test District Servlet (JSON)</a>
            <% } %>
            <% if (userType.contains("DIVISION")) { %>
                <a href="GetDistrictActivityAnalysisServlet" class="btn" target="_blank">Test Division Servlet (JSON)</a>
            <% } %>
        </div>
        
        <a href="district-dashboard.jsp" class="btn" style="background: #999;">← Back to Dashboard</a>
    <% } %>
    
</body>
</html>
