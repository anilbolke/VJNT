<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.Student" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>

<%!
    // Helper method to get Marathi level text
    private String getMarathiLevelText(int level) {
        switch(level) {
            case 0: return "स्थर निश्चित केला नाही";
            case 1: return "प्रारंभिक स्तर";
            case 2: return "अक्षर स्तर";
            case 3: return "शब्द स्तर";
            case 4: return "वाक्य स्तर";
            case 5: return "समजपूर्वक उतारा वाचन स्तर";
            case 6: return "मराठी वाचन व लेखन FLN स्तर 100% पूर्ण";
            default: return "Level " + level;
        }
    }
    
    // Helper method to get Math level text
    private String getMathLevelText(int level) {
        switch(level) {
            case 0: return "स्तर निश्चित केला नाही";
            case 1: return "प्रारंभिक स्तर";
            case 2: return "अंक ज्ञान स्तर";
            case 3: return "संख्याज्ञान स्तर";
            case 4: return "बेरीज स्तर";
            case 5: return "वजाबाकी स्तर";
            case 6: return "गुणाकार स्तर";
            case 7: return "भागाकार स्तर";
            case 8: return "गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण";
            default: return "Level " + level;
        }
    }
    
    // Helper method to get English level text
    private String getEnglishLevelText(int level) {
        switch(level) {
            case 0: return "स्तर निश्चित केला नाही";
            case 1: return "Beginner level";
            case 2: return "Alphabet level";
            case 3: return "Word level";
            case 4: return "Sentence level";
            case 5: return "Paragraph Reading with Understanding";
            case 6: return "English reading and writing FLN level 100% complete";
            default: return "Level " + level;
        }
    }
%>

<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    
    String udiseNo = user.getUdiseNo();
    School school = schoolDAO.getSchoolByUdise(udiseNo);
    String schoolName = school != null ? school.getSchoolName() : "Unknown School";
    
    // Get FLN completed students
    List<Student> flnCompletedStudents = studentDAO.getFlnCompletedStudentsByUdise(udiseNo);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FLN Completed Students - <%= schoolName %></title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%);
            color: white;
            padding: 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            font-size: 28px;
            font-weight: 600;
        }
        
        .header-info {
            text-align: right;
            font-size: 14px;
        }
        
        .back-button {
            display: inline-block;
            background: white;
            color: #2ecc71;
            padding: 10px 20px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            transition: all 0.3s;
            margin-top: 10px;
        }
        
        .back-button:hover {
            background: #f0f0f0;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        
        .content {
            padding: 30px;
        }
        
        .summary-card {
            background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%);
            color: white;
            padding: 25px;
            border-radius: 12px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        
        .summary-card h2 {
            font-size: 24px;
            margin-bottom: 10px;
        }
        
        .summary-card p {
            font-size: 16px;
            opacity: 0.95;
            line-height: 1.6;
        }
        
        .stats {
            display: flex;
            gap: 20px;
            margin-top: 15px;
        }
        
        .stat-item {
            background: rgba(255,255,255,0.2);
            padding: 15px 20px;
            border-radius: 8px;
            flex: 1;
        }
        
        .stat-value {
            font-size: 32px;
            font-weight: 700;
            display: block;
        }
        
        .stat-label {
            font-size: 14px;
            opacity: 0.9;
            margin-top: 5px;
        }
        
        .table-container {
            overflow-x: auto;
            margin-top: 20px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
        }
        
        thead {
            background: #f8f9fa;
        }
        
        th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            color: #495057;
            border-bottom: 2px solid #dee2e6;
            white-space: nowrap;
        }
        
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #dee2e6;
        }
        
        tbody tr:hover {
            background: #f8f9fa;
        }
        
        .badge {
            display: inline-block;
            padding: 8px 14px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            text-align: left;
            line-height: 1.5;
            max-width: 100%;
            word-wrap: break-word;
        }
        
        .badge-success {
            background: #d4edda;
            color: #155724;
        }
        
        .badge-marathi {
            background: #e3f2fd;
            color: #0d47a1;
            display: block;
        }
        
        .badge-math {
            background: #fff3e0;
            color: #e65100;
            display: block;
        }
        
        .badge-english {
            background: #f3e5f5;
            color: #4a148c;
            display: block;
        }
        
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #6c757d;
        }
        
        .empty-state-icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        
        .empty-state h3 {
            font-size: 24px;
            margin-bottom: 10px;
        }
        
        .empty-state p {
            font-size: 16px;
            line-height: 1.6;
        }
        
        .trophy-icon {
            display: inline-block;
            margin-right: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1><span class="trophy-icon">🏆</span> FLN 100% Completed Students</h1>
                <div style="margin-top: 10px; font-size: 16px; opacity: 0.95;">
                    <%= schoolName %> | UDISE: <%= udiseNo %>
                </div>
                <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="back-button">← Back to Dashboard</a>
            </div>
            <div class="header-info">
                <div><strong><%= user.getUsername() %></strong></div>
                <div style="opacity: 0.9; margin-top: 5px;">School Coordinator</div>
            </div>
        </div>
        
        <div class="content">
            <div class="summary-card">
                <h2>🎓 FLN Achievement Summary</h2>
                <p>
                    These students have successfully achieved 100% Foundational Literacy and Numeracy (FLN) in all three subjects 
                    after completing all 4 phases. They no longer require phase assessments.
                </p>
                <div class="stats">
                    <div class="stat-item">
                        <span class="stat-value"><%= flnCompletedStudents.size() %></span>
                        <div class="stat-label">Total FLN Completed Students</div>
                    </div>
                    <div class="stat-item">
                        <span class="stat-value">100%</span>
                        <div class="stat-label">FLN Achievement Level</div>
                    </div>
                    <div class="stat-item">
                        <span class="stat-value">3/3</span>
                        <div class="stat-label">Subjects Mastered</div>
                    </div>
                </div>
            </div>
            
            <% if (flnCompletedStudents.isEmpty()) { %>
                <div class="empty-state">
                    <div class="empty-state-icon">📚</div>
                    <h3>No FLN Completed Students Yet</h3>
                    <p>
                        Students who achieve 100% FLN in all subjects (Marathi Level 6, Math Level 8, English Level 6) 
                        will appear here.<br>
                        Keep working with your students through the 4 phases to help them reach this milestone!
                    </p>
                </div>
            <% } else { %>
                <div class="table-container">
                    <table>
                        <thead>
                            <tr>
                                <th>Sr. No.</th>
                                <th>Student PEN</th>
                                <th>Student Name</th>
                                <th>Class</th>
                                <th>Section</th>
                                <th>Gender</th>
                                <th>Marathi Level</th>
                                <th>Math Level</th>
                                <th>English Level</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% 
                            int srNo = 1;
                            for (Student student : flnCompletedStudents) { 
                            %>
                                <tr>
                                    <td><%= srNo++ %></td>
                                    <td><strong><%= student.getStudentPen() %></strong></td>
                                    <td><%= student.getStudentName() %></td>
                                    <td><%= student.getStudentClass() %></td>
                                    <td><%= student.getSection() %></td>
                                    <td><%= student.getGender() %></td>
                                    <td>
                                        <span class="badge badge-marathi" title="Level <%= student.getMarathiAksharaLevel() %>">
                                            <%= getMarathiLevelText(student.getMarathiAksharaLevel()) %>
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge badge-math" title="Level <%= student.getMathAksharaLevel() %>">
                                            <%= getMathLevelText(student.getMathAksharaLevel()) %>
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge badge-english" title="Level <%= student.getEnglishAksharaLevel() %>">
                                            <%= getEnglishLevelText(student.getEnglishAksharaLevel()) %>
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge badge-success">
                                            ✓ FLN Completed
                                        </span>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            <% } %>
        </div>
    </div>
</body>
</html>
