<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.PhaseApprovalDAO" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.PhaseApproval" %>
<%@ page import="com.vjnt.model.Student" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    // Security check
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.HEAD_MASTER)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    // Get phase number from request
    String phaseParam = request.getParameter("phase");
    if (phaseParam == null || phaseParam.isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/phase-approvals.jsp");
        return;
    }
    
    int phaseNumber = Integer.parseInt(phaseParam);
    String udiseNo = user.getUdiseNo();
    
    // Get DAOs
    PhaseApprovalDAO approvalDAO = new PhaseApprovalDAO();
    StudentDAO studentDAO = new StudentDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    
    // Get phase approval details
    PhaseApproval approval = approvalDAO.getPhaseApproval(udiseNo, phaseNumber);
    if (approval == null) {
        response.sendRedirect(request.getContextPath() + "/phase-approvals.jsp");
        return;
    }
    
    // Get school info
    School school = schoolDAO.getSchoolByUdise(udiseNo);
    String schoolName = school != null ? school.getSchoolName() : "Unknown School";
    
    // Get all students for this school
    List<Student> allStudents = studentDAO.getStudentsByUdise(udiseNo);
    
    // Helper method to get level description
    java.util.function.Function<Integer, String> getMarathiDescription = (level) -> {
        if (level == null) return "निरांक";
        switch (level) {
            case 1: return "अक्षर स्तरावरील (वाचन व लेखन)";
            case 2: return "शब्द स्तरावरील (वाचन व लेखन)";
            case 3: return "वाक्य स्तरावरील";
            case 4: return "समजपुर्वक उतार वाचन स्तरावरील";
            default: return "निरांक";
        }
    };
    
    java.util.function.Function<Integer, String> getMathDescription = (level) -> {
        if (level == null) return "निरांक";
        switch (level) {
            case 1: return "प्रारंभीक स्तरावरील";
            case 2: return "अंक स्तरावरील";
            case 3: return "संख्या वाचन स्तरावरील";
            case 4: return "बेरीज स्तरावरील";
            case 5: return "वजाबाकी स्तरावरील";
            case 6: return "गुणाकार स्तरावरील";
            case 7: return "भागाकर स्तरावरील";
            default: return "निरांक";
        }
    };
    
    java.util.function.Function<Integer, String> getEnglishDescription = (level) -> {
        if (level == null) return "NA";
        switch (level) {
            case 1: return "BEGINER LEVEL";
            case 2: return "ALPHABET LEVEL";
            case 3: return "WORD LEVEL";
            case 4: return "SENTENCE LEVEL";
            case 5: return "PARAGRAPH LEVEL";
            default: return "NA";
        }
    };
    
    // Filter students based on phase completion
    List<Student> completedStudents = new ArrayList<>();
    List<Student> ignoredStudents = new ArrayList<>();
    
    for (Student student : allStudents) {
        // Check if student has phase data saved
        Date phaseDate = null;
        Integer marathi = null, math = null, english = null;
        
        switch (phaseNumber) {
            case 1:
                phaseDate = student.getPhase1Date();
                marathi = student.getPhase1Marathi();
                math = student.getPhase1Math();
                english = student.getPhase1English();
                break;
            case 2:
                phaseDate = student.getPhase2Date();
                marathi = student.getPhase2Marathi();
                math = student.getPhase2Math();
                english = student.getPhase2English();
                break;
            case 3:
                phaseDate = student.getPhase3Date();
                marathi = student.getPhase3Marathi();
                math = student.getPhase3Math();
                english = student.getPhase3English();
                break;
            case 4:
                phaseDate = student.getPhase4Date();
                marathi = student.getPhase4Marathi();
                math = student.getPhase4Math();
                english = student.getPhase4English();
                break;
        }
        
        // Check if data was saved (phase_date is not null)
        if (phaseDate != null) {
            // Check if all three are null (not set)
            boolean isDefault = marathi == null && 
                               math == null && 
                               english == null;
            
            if (isDefault) {
                ignoredStudents.add(student);
            } else {
                completedStudents.add(student);
            }
        }
    }
    
    SimpleDateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy HH:mm");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Approve Phase <%= phaseNumber %> - <%= schoolName %></title>
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
            padding: 30px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 3px solid #667eea;
        }
        
        .header-left h1 {
            color: #333;
            font-size: 28px;
            margin-bottom: 5px;
        }
        
        .header-left .subtitle {
            color: #666;
            font-size: 14px;
        }
        
        .back-btn {
            padding: 10px 20px;
            background: #6c757d;
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .back-btn:hover {
            background: #5a6268;
            transform: translateY(-2px);
        }
        
        .summary-section {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 25px;
            border-radius: 10px;
            color: white;
            margin-bottom: 30px;
        }
        
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 15px;
        }
        
        .summary-item {
            text-align: center;
        }
        
        .summary-value {
            font-size: 36px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .summary-label {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .info-section {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }
        
        .info-item {
            display: flex;
            flex-direction: column;
        }
        
        .info-label {
            font-size: 12px;
            color: #666;
            margin-bottom: 5px;
            font-weight: 600;
        }
        
        .info-value {
            font-size: 15px;
            color: #333;
        }
        
        .section-title {
            font-size: 20px;
            color: #333;
            margin-bottom: 20px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .section-title::before {
            content: '';
            width: 4px;
            height: 24px;
            background: #667eea;
            border-radius: 2px;
        }
        
        .students-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .students-table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .students-table th {
            padding: 15px 10px;
            text-align: left;
            font-weight: 600;
            font-size: 13px;
        }
        
        .students-table td {
            padding: 12px 10px;
            border-bottom: 1px solid #e0e0e0;
            font-size: 14px;
        }
        
        .students-table tbody tr:hover {
            background: #f8f9fa;
        }
        
        .level-badge {
            display: inline-block;
            padding: 8px 12px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 600;
            line-height: 1.4;
            max-width: 200px;
            word-wrap: break-word;
            white-space: normal;
        }
        
        .level-L1 { background: #ffebee; color: #c62828; }
        .level-L2 { background: #fff3e0; color: #e65100; }
        .level-L3 { background: #fff9c4; color: #f57f17; }
        .level-L4 { background: #e8f5e9; color: #2e7d32; }
        .level-L5 { background: #e1f5fe; color: #01579b; }
        
        .ignored-badge {
            background: #fafafa;
            color: #9e9e9e;
            padding: 4px 12px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .action-section {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 10px;
            margin-top: 30px;
        }
        
        .remarks-textarea {
            width: 100%;
            padding: 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            font-family: inherit;
            resize: vertical;
            min-height: 100px;
            margin-bottom: 20px;
        }
        
        .remarks-textarea:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .action-buttons {
            display: flex;
            gap: 15px;
            justify-content: center;
        }
        
        .btn {
            padding: 15px 40px;
            font-size: 16px;
            font-weight: 600;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .btn-approve {
            background: linear-gradient(135deg, #4caf50 0%, #2e7d32 100%);
            color: white;
        }
        
        .btn-approve:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(76, 175, 80, 0.4);
        }
        
        .btn-reject {
            background: linear-gradient(135deg, #f44336 0%, #c62828 100%);
            color: white;
        }
        
        .btn-reject:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(244, 67, 54, 0.4);
        }
        
        .empty-state {
            text-align: center;
            padding: 40px;
            color: #999;
        }
        
        .status-badge {
            display: inline-block;
            padding: 6px 16px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 600;
        }
        
        .status-pending {
            background: #fff3e0;
            color: #e65100;
        }
        
        @media print {
            .action-section, .back-btn {
                display: none;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div class="header-left">
                <h1>📋 Phase <%= phaseNumber %> Approval</h1>
                <div class="subtitle">
                    <%= schoolName %> (UDISE: <%= udiseNo %>)
                </div>
            </div>
            <a href="phase-approvals.jsp" class="back-btn">← Back to Approvals</a>
        </div>
        
        <!-- Summary Section -->
        <div class="summary-section">
            <h3 style="margin-bottom: 15px;">📊 Phase Summary</h3>
            <div class="summary-grid">
                <div class="summary-item">
                    <div class="summary-value"><%= allStudents.size() %></div>
                    <div class="summary-label">Total Students</div>
                </div>
                <div class="summary-item">
                    <div class="summary-value"><%= completedStudents.size() %></div>
                    <div class="summary-label">Data Filled</div>
                </div>
                <div class="summary-item">
                    <div class="summary-value"><%= ignoredStudents.size() %></div>
                    <div class="summary-label">Ignored (Default)</div>
                </div>
                <div class="summary-item">
                    <div class="summary-value"><%= 
                        allStudents.size() > 0 ? 
                        Math.round((completedStudents.size() * 100.0) / allStudents.size()) : 0 
                    %>%</div>
                    <div class="summary-label">Completion Rate</div>
                </div>
            </div>
        </div>
        
        <!-- Submission Info -->
        <div class="info-section">
            <h3 class="section-title">📝 Submission Details</h3>
            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Submitted By</div>
                    <div class="info-value"><%= approval.getCompletedBy() %></div>
                </div>
                <div class="info-item">
                    <div class="info-label">Submission Date</div>
                    <div class="info-value"><%= sdf.format(approval.getCompletedDate()) %></div>
                </div>
                <div class="info-item">
                    <div class="info-label">Status</div>
                    <div class="info-value">
                        <span class="status-badge status-pending">⏳ Pending Approval</span>
                    </div>
                </div>
                <% if (approval.getCompletionRemarks() != null && !approval.getCompletionRemarks().isEmpty()) { %>
                <div class="info-item" style="grid-column: 1 / -1;">
                    <div class="info-label">Coordinator's Remarks</div>
                    <div class="info-value"><%= approval.getCompletionRemarks() %></div>
                </div>
                <% } %>
            </div>
        </div>
        
        <!-- Completed Students Table -->
        <% if (!completedStudents.isEmpty()) { %>
        <div style="margin-bottom: 40px;">
            <h3 class="section-title">✅ Students with Data Filled (<%= completedStudents.size() %>)</h3>
            <table class="students-table">
                <thead>
                    <tr>
                        <th style="width: 50px;">#</th>
                        <th>Student Name</th>
                        <th>Class</th>
                        <th>Gender</th>
                        <th>Marathi</th>
                        <th>Math</th>
                        <th>English</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                    int index = 1;
                    for (Student student : completedStudents) { 
                        Integer marathi = null, math = null, english = null;
                        switch (phaseNumber) {
                            case 1:
                                marathi = student.getPhase1Marathi();
                                math = student.getPhase1Math();
                                english = student.getPhase1English();
                                break;
                            case 2:
                                marathi = student.getPhase2Marathi();
                                math = student.getPhase2Math();
                                english = student.getPhase2English();
                                break;
                            case 3:
                                marathi = student.getPhase3Marathi();
                                math = student.getPhase3Math();
                                english = student.getPhase3English();
                                break;
                            case 4:
                                marathi = student.getPhase4Marathi();
                                math = student.getPhase4Math();
                                english = student.getPhase4English();
                                break;
                        }
                    %>
                    <tr>
                        <td><%= index++ %></td>
                        <td><strong><%= student.getStudentName() %></strong></td>
                        <td><%= student.getStudentClass() %> - <%= student.getSection() %></td>
                        <td><%= student.getGender() %></td>
                        <td><span class="level-badge level-L<%= marathi %>"><%= getMarathiDescription.apply(marathi) %></span></td>
                        <td><span class="level-badge level-L<%= math %>"><%= getMathDescription.apply(math) %></span></td>
                        <td><span class="level-badge level-L<%= english %>"><%= getEnglishDescription.apply(english) %></span></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <% } %>
        
        <!-- Ignored Students Table -->
        <% if (!ignoredStudents.isEmpty()) { %>
        <div style="margin-bottom: 40px;">
            <h3 class="section-title">⊘ Ignored Students (Default Values) (<%= ignoredStudents.size() %>)</h3>
            <table class="students-table">
                <thead>
                    <tr>
                        <th style="width: 50px;">#</th>
                        <th>Student Name</th>
                        <th>Class</th>
                        <th>Gender</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                    int ignoreIndex = 1;
                    for (Student student : ignoredStudents) { 
                    %>
                    <tr>
                        <td><%= ignoreIndex++ %></td>
                        <td><%= student.getStudentName() %></td>
                        <td><%= student.getStudentClass() %> - <%= student.getSection() %></td>
                        <td><%= student.getGender() %></td>
                        <td><span class="ignored-badge">Not Evaluated</span></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <% } %>
        
        <!-- Action Section -->
        <% if (approval.isPending()) { %>
        <div class="action-section">
            <h3 class="section-title">✍️ Your Decision</h3>
            <form id="approvalForm" method="post" action="<%= request.getContextPath() %>/approve-phase">
                <input type="hidden" name="approvalId" value="<%= approval.getApprovalId() %>">
                <input type="hidden" name="action" id="actionInput" value="">
                
                <label for="remarks" style="display: block; margin-bottom: 10px; font-weight: 600; color: #333;">
                    Remarks (Optional):
                </label>
                <textarea name="remarks" id="remarks" class="remarks-textarea" 
                          placeholder="Enter your remarks or feedback for the coordinator..."></textarea>
                
                <div class="action-buttons">
                    <button type="button" class="btn btn-approve" onclick="submitForm('approve')">
                        ✓ Approve Phase
                    </button>
                    <button type="button" class="btn btn-reject" onclick="submitForm('reject')">
                        ✗ Reject Phase
                    </button>
                </div>
            </form>
        </div>
        <% } %>
    </div>
    
    <script>
        function submitForm(action) {
            const remarks = document.getElementById('remarks').value.trim();
            
            if (action === 'reject' && remarks === '') {
                alert('⚠️ Please provide remarks when rejecting a phase.');
                document.getElementById('remarks').focus();
                return;
            }
            
            const confirmMsg = action === 'approve' 
                ? '✅ Are you sure you want to APPROVE this phase?\n\nThis will mark Phase <%= phaseNumber %> as completed.'
                : '❌ Are you sure you want to REJECT this phase?\n\nThe coordinator will need to resubmit after making corrections.';
            
            if (confirm(confirmMsg)) {
                document.getElementById('actionInput').value = action;
                document.getElementById('approvalForm').submit();
            }
        }
        
        // Print functionality
        function printPage() {
            window.print();
        }
    </script>
</body>
</html>
