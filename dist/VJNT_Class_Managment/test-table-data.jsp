<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.model.Student" %>
<%@ page import="java.util.List" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    // Try to load students directly
    StudentDAO studentDAO = new StudentDAO();
    String udiseNo = user.getUdiseNo();
    List<Student> students = null;
    String errorMsg = null;
    
    try {
        if (udiseNo != null && !udiseNo.trim().isEmpty()) {
            students = studentDAO.getStudentsByUdise(udiseNo);
        }
    } catch (Exception e) {
        errorMsg = e.getMessage();
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Test Table Data</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { padding: 20px; background: #f5f5f5; }
        .container { max-width: 1400px; background: white; padding: 30px; border-radius: 10px; }
        .info-box { background: #e3f2fd; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
        .error-box { background: #ffebee; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
        .success-box { background: #e8f5e9; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Test Table Data Loading</h1>
        
        <div class="info-box">
            <h5>User Information:</h5>
            <p><strong>Username:</strong> <%= user.getUsername() %></p>
            <p><strong>User Type:</strong> <%= user.getUserType() %></p>
            <p><strong>UDISE Number:</strong> <%= udiseNo != null ? udiseNo : "<span class='text-danger'>NULL</span>" %></p>
        </div>
        
        <% if (errorMsg != null) { %>
        <div class="error-box">
            <h5>❌ Error Loading Students:</h5>
            <p><%= errorMsg %></p>
        </div>
        <% } %>
        
        <% if (udiseNo == null || udiseNo.trim().isEmpty()) { %>
        <div class="error-box">
            <h5>❌ UDISE Number is NULL or Empty</h5>
            <p>Cannot load students without UDISE number.</p>
            <p><strong>Solution:</strong></p>
            <pre>UPDATE users SET udise_no = 'YOUR_UDISE' WHERE username = '<%= user.getUsername() %>';</pre>
        </div>
        <% } else if (students == null) { %>
        <div class="error-box">
            <h5>❌ Students List is NULL</h5>
            <p>Failed to execute query or database connection issue.</p>
        </div>
        <% } else if (students.size() == 0) { %>
        <div class="alert alert-warning">
            <h5>⚠️ No Students Found</h5>
            <p>Query executed successfully but no students found for UDISE: <%= udiseNo %></p>
            <p><strong>Check:</strong></p>
            <pre>SELECT COUNT(*) FROM students WHERE udise_no = '<%= udiseNo %>';</pre>
        </div>
        <% } else { %>
        <div class="success-box">
            <h5>✅ SUCCESS! Students Loaded</h5>
            <p><strong>Total Students:</strong> <%= students.size() %></p>
        </div>
        
        <h3>Student Data:</h3>
        <div class="table-responsive">
            <table class="table table-bordered table-hover">
                <thead class="table-primary">
                    <tr>
                        <th style="text-align: center;">#</th>
                        <th>Student Name</th>
                        <th style="text-align: center;">PEN Number</th>
                        <th style="text-align: center;">Class</th>
                        <th style="text-align: center;">Section</th>
                        <th style="text-align: center;">Gender</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (int i = 0; i < students.size(); i++) { 
                        Student s = students.get(i);
                    %>
                    <tr>
                        <td style="text-align: center;"><strong><%= i + 1 %></strong></td>
                        <td><%= s.getStudentName() %></td>
                        <td style="text-align: center;"><%= s.getStudentPen() != null ? s.getStudentPen() : "N/A" %></td>
                        <td style="text-align: center;"><%= s.getStudentClass() %></td>
                        <td style="text-align: center;"><%= s.getSection() %></td>
                        <td style="text-align: center;"><%= s.getGender() != null ? s.getGender() : "N/A" %></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        
        <h4>Sample JSON Output:</h4>
        <pre style="background: #f8f9fa; padding: 15px; border-radius: 5px; max-height: 300px; overflow: auto;"><%
            Student firstStudent = students.get(0);
            out.print("{\n");
            out.print("  \"studentId\": " + firstStudent.getStudentId() + ",\n");
            out.print("  \"studentName\": \"" + firstStudent.getStudentName() + "\",\n");
            out.print("  \"studentPen\": \"" + firstStudent.getStudentPen() + "\",\n");
            out.print("  \"studentClass\": \"" + firstStudent.getStudentClass() + "\",\n");
            out.print("  \"section\": \"" + firstStudent.getSection() + "\",\n");
            out.print("  \"gender\": \"" + firstStudent.getGender() + "\",\n");
            out.print("  \"udiseNo\": \"" + firstStudent.getUdiseNo() + "\"\n");
            out.print("}");
        %></pre>
        <% } %>
        
        <hr>
        
        <h4>Next Steps:</h4>
        <% if (students != null && students.size() > 0) { %>
        <div class="alert alert-success">
            <p>✅ Data is loading correctly from database</p>
            <p>If table is not showing in main page, the issue is in JavaScript AJAX call</p>
            <p><strong>Check:</strong></p>
            <ul>
                <li>Browser Console (F12) for JavaScript errors</li>
                <li>Network tab to see if AJAX request is being made</li>
                <li>Servlet mapping for /getAllStudents</li>
            </ul>
            <p><strong>Test Servlet:</strong> <a href="test-get-students.jsp" class="btn btn-sm btn-primary">Test Servlet</a></p>
            <p><strong>Main Page:</strong> <a href="student-list-activities.jsp" class="btn btn-sm btn-success">Go to Main Page</a></p>
        </div>
        <% } %>
        
        <a href="student-list-activities.jsp" class="btn btn-secondary">← Back to Main Page</a>
        <button onclick="location.reload()" class="btn btn-primary">🔄 Refresh</button>
    </div>
</body>
</html>
