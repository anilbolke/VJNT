<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.model.Student" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.HEAD_MASTER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    
    // Pagination parameters
    int currentPage = 1;
    int pageSize = 10;
    String pageParam = request.getParameter("page");
    if (pageParam != null) {
        try {
            currentPage = Integer.parseInt(pageParam);
        } catch (NumberFormatException e) {
            currentPage = 1;
        }
    }
    
    // Get statistics for this school (UDISE)
    String udiseNo = user.getUdiseNo();
    List<com.vjnt.model.Student> allStudents = studentDAO.getStudentsByUdise(udiseNo);
    int totalStudents = studentDAO.getStudentCountByUdise(udiseNo);
    int totalPages = (int) Math.ceil((double) totalStudents / pageSize);
    
    // Get paginated students
    List<com.vjnt.model.Student> students = studentDAO.getStudentsByUdiseWithPagination(udiseNo, currentPage, pageSize);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Students - VJNT</title>
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
            padding: 30px;
        }
        
        .header {
            background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
            color: white;
            padding: 20px 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 5px;
        }
        
        .header p {
            opacity: 0.9;
        }
        
        .breadcrumb {
            background: #f8f9fa;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 25px;
            font-size: 14px;
            color: #666;
        }
        
        .breadcrumb strong {
            color: #333;
        }
        
        .section {
            background: white;
            border-radius: 10px;
            padding: 25px;
            margin-bottom: 25px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        .section-title {
            font-size: 22px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #43e97b;
        }
        
        .btn {
            padding: 10px 20px;
            border-radius: 5px;
            text-decoration: none;
            font-weight: 500;
            transition: all 0.3s;
            display: inline-block;
            cursor: pointer;
            border: none;
        }
        
        .btn-back {
            background: #6c757d;
            color: white;
        }
        
        .btn-back:hover {
            background: #5a6268;
            transform: translateY(-2px);
        }
        
        .btn-save {
            background: #28a745;
            color: white;
        }
        
        .btn-save:hover {
            background: #218838;
        }
        
        .table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        .table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .table th,
        .table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #dee2e6;
        }
        
        .table tbody tr:hover {
            background: #f8f9fa;
        }
        
        .level-select {
            width: 100%;
            padding: 8px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 13px;
        }
        
        .level-select:focus {
            outline: none;
            border-color: #43e97b;
        }
        
        .pagination {
            display: flex;
            justify-content: center;
            gap: 10px;
            margin-top: 25px;
            flex-wrap: wrap;
        }
        
        .pagination a,
        .pagination span {
            padding: 8px 12px;
            border-radius: 5px;
            text-decoration: none;
            color: #667eea;
            background: #f8f9fa;
        }
        
        .pagination a:hover {
            background: #43e97b;
            color: white;
        }
        
        .pagination .active {
            background: #667eea;
            color: white;
        }
        
        .pagination .disabled {
            color: #ccc;
            cursor: not-allowed;
        }
        
        .phase-selector {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        
        .phase-status {
            display: flex;
            gap: 10px;
            margin-top: 15px;
            flex-wrap: wrap;
        }
        
        .phase-badge {
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 12px;
        }
        
        .phase-complete {
            background: #4caf50;
            color: white;
        }
        
        .phase-progress {
            background: #fff3e0;
            color: #f57c00;
        }
        
        .phase-locked {
            background: #e0e0e0;
            color: #666;
        }
        
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        
        .alert-success {
            background: #4caf50;
            color: white;
        }
        
        .alert-info {
            background: #2196f3;
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div>
                <h1>📋 विद्यार्थी यादी आणि भाषा स्तर व्यवस्थापन</h1>
                <p>Student List & Language Level Management</p>
            </div>
            <div>
                <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="btn btn-back">🏠 Back to Dashboard</a>
            </div>
        </div>
        
        <!-- Breadcrumb -->
        <div class="breadcrumb">
            <span>Division:</span> <strong><%= user.getDivisionName() %></strong> 
            <span style="margin: 0 10px;">→</span> 
            <span>District:</span> <strong><%= user.getDistrictName() %></strong>
            <span style="margin: 0 10px;">→</span>
            <span>School UDISE:</span> <strong><%= udiseNo %></strong>
            <span style="margin: 0 10px;">→</span>
            <span>Total Students:</span> <strong><%= totalStudents %></strong>
        </div>
        
        <!-- Main Content Section -->
        <div class="section">
            <%
            // Check phase completion status
            StudentDAO phaseDAO = new StudentDAO();
            boolean phase1Complete = phaseDAO.isPhaseComplete(udiseNo, 1);
            boolean phase2Complete = phaseDAO.isPhaseComplete(udiseNo, 2);
            boolean phase3Complete = phaseDAO.isPhaseComplete(udiseNo, 3);
            boolean phase4Complete = phaseDAO.isPhaseComplete(udiseNo, 4);
            
            // Get current selected phase from request parameter (default to Phase 1)
            String selectedPhaseStr = request.getParameter("phase");
            int selectedPhase = 1;
            if (selectedPhaseStr != null) {
                try {
                    selectedPhase = Integer.parseInt(selectedPhaseStr);
                } catch (NumberFormatException e) {
                    selectedPhase = 1;
                }
            }
            
            // Check if current selected phase is complete
            boolean currentPhaseComplete = false;
            switch(selectedPhase) {
                case 1: currentPhaseComplete = phase1Complete; break;
                case 2: currentPhaseComplete = phase2Complete; break;
                case 3: currentPhaseComplete = phase3Complete; break;
                case 4: currentPhaseComplete = phase4Complete; break;
            }
            %>
            
            <!-- Phase Selection -->
            <div class="phase-selector">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <label style="font-weight: 600; font-size: 16px; color: #333; margin-right: 15px;">
                            📊 Select Phase (चरण निवडा):
                        </label>
                        <select id="phaseSelector" onchange="changePhase()" style="padding: 10px 15px; border: 2px solid #43e97b; border-radius: 5px; font-size: 14px; font-weight: 500; min-width: 150px;">
                            <option value="1" <%= selectedPhase == 1 ? "selected" : "" %> <%= phase1Complete ? "disabled" : "" %>>Phase 1 <%= phase1Complete ? "✓ Completed" : "" %></option>
                            <option value="2" <%= selectedPhase == 2 ? "selected" : "" %> <%= !phase1Complete || phase2Complete ? "disabled" : "" %>>Phase 2 <%= phase2Complete ? "✓ Completed" : "" %></option>
                            <option value="3" <%= selectedPhase == 3 ? "selected" : "" %> <%= !phase2Complete || phase3Complete ? "disabled" : "" %>>Phase 3 <%= phase3Complete ? "✓ Completed" : "" %></option>
                            <option value="4" <%= selectedPhase == 4 ? "selected" : "" %> <%= !phase3Complete || phase4Complete ? "disabled" : "" %>>Phase 4 <%= phase4Complete ? "✓ Completed" : "" %></option>
                        </select>
                    </div>
                    <div>
                        <span style="font-size: 14px; color: #666;">
                            Current Phase: <strong style="color: #43e97b;">Phase <%= selectedPhase %></strong>
                        </span>
                    </div>
                </div>
                
                <!-- Phase Status Indicators -->
                <div class="phase-status">
                    <span class="phase-badge <%= phase1Complete ? "phase-complete" : "phase-progress" %>">
                        Phase 1: <%= phase1Complete ? "✓ Complete" : "⏳ In Progress" %>
                    </span>
                    <span class="phase-badge <%= phase2Complete ? "phase-complete" : (phase1Complete ? "phase-progress" : "phase-locked") %>">
                        Phase 2: <%= phase2Complete ? "✓ Complete" : (phase1Complete ? "⏳ Available" : "🔒 Locked") %>
                    </span>
                    <span class="phase-badge <%= phase3Complete ? "phase-complete" : (phase2Complete ? "phase-progress" : "phase-locked") %>">
                        Phase 3: <%= phase3Complete ? "✓ Complete" : (phase2Complete ? "⏳ Available" : "🔒 Locked") %>
                    </span>
                    <span class="phase-badge <%= phase4Complete ? "phase-complete" : (phase3Complete ? "phase-progress" : "phase-locked") %>">
                        Phase 4: <%= phase4Complete ? "✓ Complete" : (phase3Complete ? "⏳ Available" : "🔒 Locked") %>
                    </span>
                </div>
            </div>
            
            <% if (currentPhaseComplete) { %>
            <!-- Phase Complete Notification -->
            <div class="alert alert-success">
                <strong style="font-size: 16px;">✓ Phase <%= selectedPhase %> Completed!</strong>
                <p style="margin: 5px 0 0 0;">All students have been assigned language levels for this phase. Data is now read-only.</p>
            </div>
            <% } %>
            
            <% if (totalStudents == 0) { %>
            <!-- No Students Message -->
            <div class="alert alert-info">
                <strong>ℹ️ No Students Found</strong>
                <p style="margin: 5px 0 0 0;">No students are registered for UDISE <%= udiseNo %>. Please contact Data Admin to upload student data.</p>
            </div>
            <% } else { %>
            
            <p style="margin-bottom: 15px; color: #666; font-size: 14px;">
                Showing <%= (currentPage - 1) * pageSize + 1 %> to <%= Math.min(currentPage * pageSize, totalStudents) %> of <%= totalStudents %> students
                <% if (currentPhaseComplete) { %>
                <span style="color: #4caf50; font-weight: 600; margin-left: 10px;">● Phase <%= selectedPhase %> Complete</span>
                <% } %>
            </p>
            
            <!-- Student Table -->
            <div style="overflow-x: auto;">
                <table class="table">
                    <thead>
                        <tr>
                            <th style="vertical-align: middle;">PEN</th>
                            <th style="vertical-align: middle;">Name</th>
                            <th style="vertical-align: middle;">Class</th>
                            <th style="vertical-align: middle;">Section</th>
                            <th style="text-align: center; background: #5e3f0e;">मराठी भाषा स्तर</th>
                            <th style="text-align: center; background: #005695;">गणित स्तर</th>
                            <th style="text-align: center; background: #a901c1;">इंग्रजी स्तर</th>
                            <th style="vertical-align: middle;">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                        for (com.vjnt.model.Student s : students) {
                        %>
                        <tr id="row-<%= s.getStudentId() %>">
                            <td><%= s.getStudentPen() != null ? s.getStudentPen() : "N/A" %></td>
                            <td><strong><%= s.getStudentName() %></strong></td>
                            <td><%= s.getStudentClass() %></td>
                            <td><%= s.getSection() %></td>
                            <!-- Marathi Levels -->
                            <td>
                                <select name="marathi_akshara" class="level-select" <%= currentPhaseComplete ? "disabled" : "" %>>
                                    <option value="0" <%= s.getMarathiAksharaLevel() == 0 ? "selected" : "" %>>निरांक</option>
                                    <option value="1" <%= s.getMarathiAksharaLevel() == 1 ? "selected" : "" %>>अक्षर स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)</option>
                                    <option value="2" <%= s.getMarathiAksharaLevel() == 2 ? "selected" : "" %>>शब्द स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)</option>
                                    <option value="3" <%= s.getMarathiAksharaLevel() == 3 ? "selected" : "" %>>वाक्य स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="4" <%= s.getMarathiAksharaLevel() == 4 ? "selected" : "" %>>समजपुर्वक उतार वाचन स्तरावरील विद्यार्थी संख्या</option>
                                </select>
                            </td>
                            <!-- Math Levels -->
                            <td>
                                <select name="math_akshara" class="level-select" <%= currentPhaseComplete ? "disabled" : "" %>>
                                    <option value="0" <%= s.getMathAksharaLevel() == 0 ? "selected" : "" %>>निरांक</option>
                                    <option value="1" <%= s.getMathAksharaLevel() == 1 ? "selected" : "" %>>प्रारंभीक स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="2" <%= s.getMathAksharaLevel() == 2 ? "selected" : "" %>>अंक स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="3" <%= s.getMathAksharaLevel() == 3 ? "selected" : "" %>>संख्या वाचन स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="4" <%= s.getMathAksharaLevel() == 4 ? "selected" : "" %>>बेरीज स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="5" <%= s.getMathAksharaLevel() == 5 ? "selected" : "" %>>वजाबाकी स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="6" <%= s.getMathAksharaLevel() == 6 ? "selected" : "" %>>गुणाकार स्तरावरील विद्यार्थी संख्या</option>
                                    <option value="7" <%= s.getMathAksharaLevel() == 7 ? "selected" : "" %>>भागाकर स्तरावरील विद्यार्थी संख्या</option>
                                </select>
                            </td>
                            <!-- English Levels -->
                            <td>
                                <select name="english_akshara" class="level-select" <%= currentPhaseComplete ? "disabled" : "" %>>
                                    <option value="0" <%= s.getEnglishAksharaLevel() == 0 ? "selected" : "" %>>NA</option>
                                    <option value="1" <%= s.getEnglishAksharaLevel() == 1 ? "selected" : "" %>>BEGINER LEVEL</option>
                                    <option value="2" <%= s.getEnglishAksharaLevel() == 2 ? "selected" : "" %>>ALPHABET LEVEL Reading and Writing</option>
                                    <option value="3" <%= s.getEnglishAksharaLevel() == 3 ? "selected" : "" %>>WORD LEVEL Reading and Writing</option>
                                    <option value="4" <%= s.getEnglishAksharaLevel() == 4 ? "selected" : "" %>>SENTENCE LEVEL</option>
                                    <option value="5" <%= s.getEnglishAksharaLevel() == 5 ? "selected" : "" %>>Paragraph Reading with Understanding</option>
                                </select>
                            </td>
                            <td>
                                <% if (!currentPhaseComplete) { %>
                                <button class="btn btn-save" onclick="saveStudent(<%= s.getStudentId() %>)">💾 Save</button>
                                <% } else { %>
                                <span style="color: #28a745;">✓ Complete</span>
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
            
            <!-- Pagination -->
            <% if (totalPages > 1) { %>
            <div class="pagination">
                <% if (currentPage > 1) { %>
                    <a href="?page=1&phase=<%= selectedPhase %>">First</a>
                    <a href="?page=<%= currentPage - 1 %>&phase=<%= selectedPhase %>">Previous</a>
                <% } else { %>
                    <span class="disabled">First</span>
                    <span class="disabled">Previous</span>
                <% } %>
                
                <% 
                int startPage = Math.max(1, currentPage - 2);
                int endPage = Math.min(totalPages, currentPage + 2);
                for (int i = startPage; i <= endPage; i++) {
                    if (i == currentPage) {
                %>
                    <span class="active"><%= i %></span>
                <% } else { %>
                    <a href="?page=<%= i %>&phase=<%= selectedPhase %>"><%= i %></a>
                <% 
                    }
                }
                %>
                
                <% if (currentPage < totalPages) { %>
                    <a href="?page=<%= currentPage + 1 %>&phase=<%= selectedPhase %>">Next</a>
                    <a href="?page=<%= totalPages %>&phase=<%= selectedPhase %>">Last</a>
                <% } else { %>
                    <span class="disabled">Next</span>
                    <span class="disabled">Last</span>
                <% } %>
            </div>
            <% } %>
            <% } %>
        </div>
    </div>
    
    <script>
        function changePhase() {
            var phase = document.getElementById('phaseSelector').value;
            window.location.href = '?phase=' + phase;
        }
        
        function saveStudent(studentId) {
            var row = document.getElementById('row-' + studentId);
            var marathiLevel = row.querySelector('[name="marathi_akshara"]').value;
            var mathLevel = row.querySelector('[name="math_akshara"]').value;
            var englishLevel = row.querySelector('[name="english_akshara"]').value;
            var phase = document.getElementById('phaseSelector').value;
            
            fetch('<%= request.getContextPath() %>/update-language-levels', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'studentId=' + studentId + 
                      '&phase=' + phase +
                      '&marathi_akshara=' + marathiLevel + 
                      '&math_akshara=' + mathLevel + 
                      '&english_akshara=' + englishLevel
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ Student data saved successfully!');
                    row.style.background = '#d4edda';
                    setTimeout(() => { row.style.background = ''; }, 2000);
                } else {
                    alert('✗ Error: ' + data.message);
                }
            })
            .catch(error => {
                alert('✗ Error saving data: ' + error);
            });
        }
    </script>
</body>
</html>
