<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.Student" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    String userType = (String) session.getAttribute("userType");
    Integer userId = (Integer) session.getAttribute("userId");
    
    if (user == null || userId == null || userType == null || 
        (!userType.equals("SCHOOL_COORDINATOR") && !userType.equals("HEAD_MASTER"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    
    String udiseNo = user.getUdiseNo();
    School school = schoolDAO.getSchoolByUdise(udiseNo);
    String schoolName = school != null ? school.getSchoolName() : "Unknown School";
    
    // Get all students for this UDISE
    List<Student> students = studentDAO.getStudentsByUdise(udiseNo);
    
    // Get unique classes and sections for filters
    Set<String> classes = new TreeSet<>();
    Set<String> sections = new TreeSet<>();
    for (Student student : students) {
        classes.add(student.getStudentClass());
        if (student.getSection() != null) {
            sections.add(student.getSection());
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Comprehensive Report - <%= schoolName %></title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
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
        }
        
        .header {
            background: white;
            padding: 25px;
            border-radius: 10px 10px 0 0;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h2 {
            color: #333;
            font-size: 24px;
        }
        
        .back-btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 10px 20px;
            border-radius: 6px;
            text-decoration: none;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .back-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(102, 126, 234, 0.4);
        }
        
        .content {
            background: white;
            padding: 30px;
            border-radius: 0 0 10px 10px;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
        }
        
        .filters {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 25px;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 8px;
        }
        
        .filter-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: 600;
            color: #495057;
            font-size: 13px;
        }
        
        .filter-group input,
        .filter-group select {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid #ced4da;
            border-radius: 6px;
            font-size: 14px;
        }
        
        .students-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        
        .student-card {
            background: white;
            border: 2px solid #e9ecef;
            border-radius: 10px;
            padding: 20px;
            transition: all 0.3s;
            cursor: pointer;
        }
        
        .student-card:hover {
            border-color: #667eea;
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.2);
            transform: translateY(-2px);
        }
        
        .student-card h3 {
            color: #333;
            margin-bottom: 15px;
            font-size: 18px;
        }
        
        .student-info {
            display: grid;
            gap: 8px;
            margin-bottom: 15px;
        }
        
        .info-row {
            display: flex;
            font-size: 13px;
        }
        
        .info-label {
            font-weight: 600;
            color: #6c757d;
            min-width: 80px;
        }
        
        .info-value {
            color: #495057;
        }
        
        .approval-status-badge {
            margin: 10px 0;
            padding: 8px 12px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            text-align: center;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        
        .approval-status-badge.no-request {
            background: #f8f9fa;
            color: #6c757d;
            border: 1px dashed #dee2e6;
        }
        
        .approval-status-badge.pending {
            background: #fff3cd;
            color: #856404;
            border: 1px solid #ffc107;
        }
        
        .approval-status-badge.approved {
            background: #d4edda;
            color: #155724;
            border: 1px solid #28a745;
        }
        
        .approval-status-badge.approved.printed {
            background: #e7f3ff;
            color: #004085;
            border: 1px solid #007bff;
        }
        
        .approval-status-badge.rejected {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #dc3545;
        }
        
        .generate-btn {
            width: 100%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 10px;
            border: none;
            border-radius: 6px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .generate-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(102, 126, 234, 0.4);
        }
        
        .no-students {
            text-align: center;
            padding: 60px 20px;
            color: #6c757d;
        }
        
        .no-students i {
            font-size: 64px;
            margin-bottom: 20px;
            opacity: 0.3;
        }
        
        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
            overflow-y: auto;
        }
        
        .modal-content {
            background: white;
            margin: 30px auto;
            padding: 0;
            width: 95%;
            max-width: 900px;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
        }
        
        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 30px;
            border-radius: 10px 10px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-header h2 {
            margin: 0;
            font-size: 22px;
        }
        
        .close {
            color: white;
            font-size: 32px;
            font-weight: bold;
            cursor: pointer;
            line-height: 1;
        }
        
        .close:hover {
            opacity: 0.8;
        }
        
        .modal-body {
            padding: 30px;
            max-height: calc(100vh - 200px);
            overflow-y: auto;
        }
        
        .report-section {
            margin-bottom: 30px;
            padding: 20px;
            border: 1px solid #e9ecef;
            border-radius: 8px;
        }
        
        .report-section h3 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 18px;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        
        .levels-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        
        .level-box {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            border: 2px solid #e9ecef;
        }
        
        .level-box.assessed {
            background: #d4edda;
            border-color: #28a745;
        }
        
        .level-label {
            font-size: 12px;
            color: #6c757d;
            margin-bottom: 5px;
        }
        
        .level-value {
            font-size: 20px;
            font-weight: bold;
            color: #495057;
        }
        
        .activity-group {
            margin-bottom: 20px;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            overflow: hidden;
        }
        
        .activity-group-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 12px 16px;
            color: white;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            user-select: none;
        }
        
        .activity-group-header:hover {
            opacity: 0.9;
        }
        
        .activity-group-title {
            margin: 0;
            font-size: 16px;
            font-weight: 600;
        }
        
        .toggle-icon {
            font-size: 20px;
            transition: transform 0.3s;
        }
        
        .activity-group-content {
            padding: 15px;
        }
        
        .activity-item {
            padding: 12px;
            margin-bottom: 10px;
            border-radius: 6px;
            background: #f8f9fa;
            border-left: 4px solid #667eea;
        }
        
        .activity-day {
            font-weight: bold;
            color: #495057;
            margin-bottom: 5px;
        }
        
        .activity-text {
            font-size: 13px;
            color: #6c757d;
        }
        
        .activity-meta {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 8px;
            padding-top: 8px;
            border-top: 1px solid rgba(0, 0, 0, 0.1);
            font-size: 11px;
            color: #6c757d;
        }
        
        .activity-count-badge {
            background: #667eea;
            color: white;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 10px;
        }
        
        .summary-stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .stat-box {
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        
        .stat-box.total {
            background: #e7f3ff;
        }
        
        .stat-box.completed {
            background: #d4edda;
        }
        
        .stat-box.completion {
            background: #fff3cd;
        }
        
        .stat-value {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 12px;
            color: #6c757d;
        }
        
        .loading {
            text-align: center;
            padding: 40px;
            color: #667eea;
        }
        
        .loading i {
            font-size: 48px;
            margin-bottom: 15px;
            animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .print-section {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 2px solid #e9ecef;
            text-align: center;
        }
        
        .print-btn {
            background: #28a745;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 6px;
            font-weight: 600;
            cursor: pointer;
            font-size: 16px;
            transition: all 0.3s;
        }
        
        .print-btn:hover {
            background: #218838;
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(40, 167, 69, 0.4);
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .modal {
                position: relative;
                background: white;
            }
            
            .modal-content {
                box-shadow: none;
                margin: 0;
                max-width: 100%;
            }
            
            .modal-header {
                background: white;
                color: #333;
                border-bottom: 2px solid #667eea;
            }
            
            .close,
            .print-section,
            .back-btn {
                display: none;
            }
            
            .activity-group-content {
                display: block !important;
            }
            
            .toggle-icon {
                display: none;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2><i class="fas fa-file-alt"></i> Student Comprehensive Report</h2>
            <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="back-btn">
                <i class="fas fa-arrow-left"></i> Back to Dashboard
            </a>
        </div>
        
        <div class="content">
            <!-- Filters -->
            <div class="filters">
                <div class="filter-group">
                    <label><i class="fas fa-search"></i> Search Student</label>
                    <input type="text" id="searchInput" placeholder="Search by name or PEN...">
                </div>
                <div class="filter-group">
                    <label><i class="fas fa-school"></i> Class</label>
                    <select id="classFilter">
                        <option value="">All Classes</option>
                        <% for (String cls : classes) { %>
                            <option value="<%= cls %>"><%= cls %></option>
                        <% } %>
                    </select>
                </div>
                <div class="filter-group">
                    <label><i class="fas fa-users"></i> Section</label>
                    <select id="sectionFilter">
                        <option value="">All Sections</option>
                        <% for (String section : sections) { %>
                            <option value="<%= section %>"><%= section %></option>
                        <% } %>
                    </select>
                </div>
            </div>
            
            <!-- Students Grid -->
            <div id="studentsGrid" class="students-grid"></div>
            <div id="noStudents" class="no-students" style="display: none;">
                <i class="fas fa-user-slash"></i>
                <h3>No Students Found</h3>
                <p>Try adjusting your filters</p>
            </div>
        </div>
    </div>
    
    <!-- Report Modal -->
    <div id="reportModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2><i class="fas fa-file-alt"></i> <span id="reportStudentName"></span> - Comprehensive Report</h2>
                <span class="close" onclick="closeReportModal()">&times;</span>
            </div>
            <div class="modal-body">
                <div id="reportLoading" class="loading">
                    <i class="fas fa-spinner"></i>
                    <div>Loading report data...</div>
                </div>
                <div id="reportContent" style="display: none;"></div>
            </div>
        </div>
    </div>
    
    <script>
        const contextPath = '<%= request.getContextPath() %>';
        const allStudents = <%= new com.google.gson.Gson().toJson(students) %>;
        
        // Initialize on page load
        document.addEventListener('DOMContentLoaded', function() {
            displayStudents(allStudents);
            
            // Add event listeners for filters
            document.getElementById('searchInput').addEventListener('input', filterStudents);
            document.getElementById('classFilter').addEventListener('change', filterStudents);
            document.getElementById('sectionFilter').addEventListener('change', filterStudents);
        });
        
        // Display students in grid
        function displayStudents(students) {
            const grid = document.getElementById('studentsGrid');
            const noStudents = document.getElementById('noStudents');
            
            if (!students || students.length === 0) {
                grid.innerHTML = '';
                noStudents.style.display = 'block';
                return;
            }
            
            noStudents.style.display = 'none';
            
            let html = '';
            students.forEach(student => {
                html += `
                    <div class="student-card" id="card-${'$'}{student.studentPen}">
                        <h3>${'$'}{student.studentName}</h3>
                        <div class="student-info">
                            <div class="info-row">
                                <span class="info-label">PEN:</span>
                                <span class="info-value">${'$'}{student.studentPen || 'N/A'}</span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">Class:</span>
                                <span class="info-value">${'$'}{student.studentClass}</span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">Section:</span>
                                <span class="info-value">${'$'}{student.section || 'N/A'}</span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">ID:</span>
                                <span class="info-value">${'$'}{student.studentId}</span>
                            </div>
                        </div>
                        <div class="approval-status-badge" id="status-${'$'}{student.studentPen}">
                            <i class="fas fa-spinner fa-spin"></i> Checking status...
                        </div>
                        <button class="generate-btn" onclick="generateReport('${'$'}{student.studentId}', '${'$'}{student.studentName}', '${'$'}{student.studentPen}')">
                            <i class="fas fa-file-pdf"></i> Generate Report
                        </button>
                    </div>
                `;
            });
            
            grid.innerHTML = html;
            
            // Fetch approval status for each student
            students.forEach(student => {
                if (student.studentPen) {
                    fetchApprovalStatus(student.studentPen);
                }
            });
            
            grid.innerHTML = html;
        }
        
        // Fetch approval status for a student
        function fetchApprovalStatus(penNumber) {
            fetch(contextPath + '/CheckReportApprovalStatusServlet?penNumber=' + encodeURIComponent(penNumber))
                .then(response => response.json())
                .then(data => {
                    const statusBadge = document.getElementById('status-' + penNumber);
                    if (!statusBadge) return;
                    
                    if (!data.hasRequest) {
                        // No approval request yet
                        statusBadge.className = 'approval-status-badge no-request';
                        statusBadge.innerHTML = '<i class="fas fa-info-circle"></i> No Approval Request';
                    } else if (data.status === 'PENDING') {
                        // Pending with Head Master
                        statusBadge.className = 'approval-status-badge pending';
                        statusBadge.innerHTML = '<i class="fas fa-clock"></i> Pending with Head Master';
                    } else if (data.status === 'APPROVED') {
                        // Approved
                        if (data.reportGenerated && data.reportGenerated === 1) {
                            // Already printed
                            statusBadge.className = 'approval-status-badge approved printed';
                            statusBadge.innerHTML = '<i class="fas fa-check-double"></i> Approved & Printed';
                        } else {
                            // Approved but not printed yet
                            statusBadge.className = 'approval-status-badge approved';
                            statusBadge.innerHTML = '<i class="fas fa-check-circle"></i> Approved by Head Master';
                        }
                    } else if (data.status === 'REJECTED') {
                        // Rejected
                        statusBadge.className = 'approval-status-badge rejected';
                        statusBadge.innerHTML = '<i class="fas fa-times-circle"></i> Rejected by Head Master';
                    }
                })
                .catch(error => {
                    console.error('Error fetching approval status:', error);
                    const statusBadge = document.getElementById('status-' + penNumber);
                    if (statusBadge) {
                        statusBadge.className = 'approval-status-badge no-request';
                        statusBadge.innerHTML = '<i class="fas fa-question-circle"></i> Status Unknown';
                    }
                });
        }
        
        // Filter students
        function filterStudents() {
            const searchText = document.getElementById('searchInput').value.toLowerCase();
            const classValue = document.getElementById('classFilter').value;
            const sectionValue = document.getElementById('sectionFilter').value;
            
            const filtered = allStudents.filter(student => {
                const matchSearch = searchText === '' || 
                    student.studentName.toLowerCase().includes(searchText) ||
                    (student.studentPen && student.studentPen.toLowerCase().includes(searchText));
                
                const matchClass = classValue === '' || student.studentClass === classValue;
                const matchSection = sectionValue === '' || student.section === sectionValue;
                
                return matchSearch && matchClass && matchSection;
            });
            
            displayStudents(filtered);
        }
        
        // Generate report
        function generateReport(studentId, studentName, studentPen) {
            if (!studentPen) {
                alert('Student PEN number is required to generate report');
                return;
            }
            
            document.getElementById('reportStudentName').textContent = studentName;
            document.getElementById('reportModal').style.display = 'block';
            document.getElementById('reportLoading').style.display = 'block';
            document.getElementById('reportContent').style.display = 'none';
            document.body.style.overflow = 'hidden';
            
            // Fetch comprehensive data and approval status
            Promise.all([
                fetch(contextPath + '/GetStudentComprehensiveDataServlet?penNumber=' + encodeURIComponent(studentPen)),
                fetch(contextPath + '/CheckReportApprovalStatusServlet?penNumber=' + encodeURIComponent(studentPen))
            ])
                .then(([reportResponse, approvalResponse]) => {
                    if (!reportResponse.ok) {
                        throw new Error('Failed to fetch report data');
                    }
                    return Promise.all([reportResponse.json(), approvalResponse.json()]);
                })
                .then(([reportData, approvalData]) => {
                    document.getElementById('reportLoading').style.display = 'none';
                    document.getElementById('reportContent').style.display = 'block';
                    displayReport(reportData, studentName, studentPen, approvalData);
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('reportLoading').style.display = 'none';
                    document.getElementById('reportContent').innerHTML = `
                        <div style="text-align: center; padding: 40px; color: #dc3545;">
                            <i class="fas fa-exclamation-circle" style="font-size: 48px; margin-bottom: 20px;"></i>
                            <h3>Error Loading Report</h3>
                            <p>${'$'}{error.message}</p>
                        </div>
                    `;
                    document.getElementById('reportContent').style.display = 'block';
                });
        }
        
        // Display report content
        function displayReport(data, studentName, studentPen, approvalData) {
            const container = document.getElementById('reportContent');
            
            let html = '';
            
            // Approval Status Banner
            if (approvalData && approvalData.hasRequest) {
                let statusColor = '#ffc107';
                let statusIcon = 'fa-clock';
                let statusText = 'Pending Approval';
                let statusMessage = 'This report has been sent to Head Master for approval. You cannot print until approved.';
                
                if (approvalData.status === 'APPROVED') {
                    statusColor = '#28a745';
                    statusIcon = 'fa-check-circle';
                    statusText = 'Approved';
                    statusMessage = 'This report has been approved by Head Master. You can now print it.';
                } else if (approvalData.status === 'REJECTED') {
                    statusColor = '#dc3545';
                    statusIcon = 'fa-times-circle';
                    statusText = 'Rejected';
                    statusMessage = 'This report was rejected. Remarks: ' + (approvalData.remarks || 'No remarks provided');
                }
                
                html += `
                    <div style="background: ${statusColor}; color: white; padding: 15px; border-radius: 8px; margin-bottom: 20px; display: flex; align-items: center; gap: 15px;">
                        <i class="fas ${statusIcon}" style="font-size: 32px;"></i>
                        <div style="flex: 1;">
                            <div style="font-size: 18px; font-weight: bold; margin-bottom: 5px;">Report Status: ${statusText}</div>
                            <div style="font-size: 14px; opacity: 0.95;">${statusMessage}</div>
                            <div style="font-size: 12px; margin-top: 5px; opacity: 0.9;">Request ID: #${approvalData.approvalId} | Submitted: ${approvalData.requestedDate}</div>
                        </div>
                    </div>
                `;
            }
            
            // Student Info Section
            html += `
                <div class="report-section">
                    <h3><i class="fas fa-user"></i> Student Information</h3>
                    <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px;">
                        <div><strong>Name:</strong> ${'$'}{studentName}</div>
                        <div><strong>PEN Number:</strong> ${'$'}{studentPen}</div>
                    </div>
                </div>
            `;
            
            // Assessment Levels Section
            if (data.assessmentLevels) {
                html += `
                    <div class="report-section">
                        <h3><i class="fas fa-chart-line"></i> Assessment Levels</h3>
                        <div class="levels-grid">
                            <div class="level-box ${'$'}{data.assessmentLevels.english !== 'Not Assessed' ? 'assessed' : ''}">
                                <div class="level-label">ENGLISH</div>
                                <div class="level-value">${'$'}{data.assessmentLevels.english}</div>
                            </div>
                            <div class="level-box ${'$'}{data.assessmentLevels.marathi !== 'Not Assessed' ? 'assessed' : ''}">
                                <div class="level-label">MARATHI</div>
                                <div class="level-value">${'$'}{data.assessmentLevels.marathi}</div>
                            </div>
                            <div class="level-box ${'$'}{data.assessmentLevels.math !== 'Not Assessed' ? 'assessed' : ''}">
                                <div class="level-label">MATH</div>
                                <div class="level-value">${'$'}{data.assessmentLevels.math}</div>
                            </div>
                        </div>
                        <div style="margin-top: 15px; padding: 12px; background: #e7f3ff; border-radius: 6px; text-align: center;">
                            <strong>Overall Progress:</strong> ${'$'}{data.assessmentLevels.overall}
                        </div>
                    </div>
                `;
            }
            
            // Activities Section
            if (data.allActivities && data.allActivities.length > 0) {
                const activities = data.allActivities;
                const totalActivities = activities.length;
                const completedActivities = activities.filter(a => a.completed).length;
                const completionRate = Math.round((completedActivities / totalActivities) * 100);
                
                html += `
                    <div class="report-section">
                        <h3><i class="fas fa-tasks"></i> Activities Summary</h3>
                        <div class="summary-stats">
                            <div class="stat-box total">
                                <div class="stat-value" style="color: #667eea;">${'$'}{totalActivities}</div>
                                <div class="stat-label">Total Activities</div>
                            </div>
                            <div class="stat-box completed">
                                <div class="stat-value" style="color: #28a745;">${'$'}{completedActivities}</div>
                                <div class="stat-label">Completed</div>
                            </div>
                            <div class="stat-box completion">
                                <div class="stat-value" style="color: #ffc107;">${'$'}{completionRate}%</div>
                                <div class="stat-label">Completion Rate</div>
                            </div>
                        </div>
                `;
                
                // Group activities by language and week
                const grouped = {};
                activities.forEach(activity => {
                    const key = activity.language + '-Week' + activity.weekNumber;
                    if (!grouped[key]) {
                        grouped[key] = {
                            language: activity.language,
                            week: activity.weekNumber,
                            activities: []
                        };
                    }
                    grouped[key].activities.push(activity);
                });
                
                // Display grouped activities
                let groupIndex = 0;
                Object.keys(grouped).sort().forEach(key => {
                    const group = grouped[key];
                    const groupId = 'activityGroup' + groupIndex;
                    groupIndex++;
                    
                    html += `
                        <div class="activity-group">
                            <div class="activity-group-header" onclick="toggleActivityGroup('${'$'}{groupId}')">
                                <h4 class="activity-group-title">${'$'}{group.language} - Week ${'$'}{group.week}</h4>
                                <span id="${'$'}{groupId}Icon" class="toggle-icon">▼</span>
                            </div>
                            <div id="${'$'}{groupId}" class="activity-group-content">
                    `;
                    
                    // Sort activities by day
                    group.activities.sort((a, b) => a.dayNumber - b.dayNumber);
                    
                    group.activities.forEach(activity => {
                        html += `
                            <div class="activity-item">
                                <div class="activity-day">Day ${'$'}{activity.dayNumber}</div>
                                <div class="activity-text">${'$'}{activity.activityText || 'N/A'}</div>
                        `;
                        
                        if (activity.assignedBy || activity.activityCount > 1) {
                            html += '<div class="activity-meta">';
                            if (activity.assignedBy) {
                                html += `<span>Assigned by: ${'$'}{activity.assignedBy}</span>`;
                            }
                            if (activity.activityCount > 1) {
                                html += `<span class="activity-count-badge">${'$'}{activity.activityCount}x</span>`;
                            }
                            html += '</div>';
                        }
                        
                        html += '</div>';
                    });
                    
                    html += '</div></div>';
                });
                
                html += '</div>';
            } else {
                html += `
                    <div class="report-section">
                        <h3><i class="fas fa-tasks"></i> Activities</h3>
                        <p style="text-align: center; color: #6c757d; padding: 20px;">No activities found for this student</p>
                    </div>
                `;
            }
            
            // Palak Melava (Parent Meetings) Section
            if (data.palakMelavaData && data.palakMelavaData.length > 0) {
                html += `
                    <div class="report-section">
                        <h3><i class="fas fa-users"></i> Parent-Teacher Meetings (Palak Melava)</h3>
                        <p style="margin-bottom: 15px; color: #6c757d;">School has conducted ${'$'}{data.palakMelavaData.length} parent-teacher meeting(s)</p>
                `;
                
                data.palakMelavaData.forEach((melava, index) => {
                    html += `
                        <div class="palak-melava-card" style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 15px; border-left: 4px solid #667eea;">
                            <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 15px;">
                                <h4 style="color: #667eea; margin: 0;">Meeting #${'$'}{index + 1}</h4>
                                <span style="background: #28a745; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px;">✓ Approved</span>
                            </div>
                            
                            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-bottom: 15px;">
                                <div>
                                    <strong style="color: #495057;"><i class="fas fa-calendar"></i> Meeting Date:</strong>
                                    <div style="margin-top: 5px;">${'$'}{melava.meetingDate || 'N/A'}</div>
                                </div>
                                <div>
                                    <strong style="color: #495057;"><i class="fas fa-users"></i> Parents Attended:</strong>
                                    <div style="margin-top: 5px;">${'$'}{melava.totalParentsAttended || 'N/A'}</div>
                                </div>
                            </div>
                            
                            <div style="margin-bottom: 15px;">
                                <strong style="color: #495057;"><i class="fas fa-user-tie"></i> Chief Guest/Attendee:</strong>
                                <div style="margin-top: 5px; background: white; padding: 10px; border-radius: 4px;">${'$'}{melava.chiefAttendeeInfo || 'N/A'}</div>
                            </div>
                        </div>
                    `;
                });
                
                html += '</div>';
            }
            
            // Action Buttons Section
            html += '<div class="print-section">';
            
            // Show appropriate buttons based on approval status
            if (!approvalData || !approvalData.hasRequest) {
                // No request yet - show submit button and print button
                html += `
                    <button class="btn-submit-approval" onclick="submitForApproval('${'$'}{studentPen}', '${'$'}{studentName}')" style="background: #667eea; color: white; padding: 12px 24px; border: none; border-radius: 6px; cursor: pointer; margin-right: 10px;">
                        <i class="fas fa-paper-plane"></i> Send to Head Master for Approval
                    </button>
                    <button class="print-btn" onclick="printReport()">
                        <i class="fas fa-print"></i> Print Report
                    </button>
                `;
            } else if (approvalData.status === 'PENDING') {
                // Pending - show waiting message and print button
                html += `
                    <button style="background: #ffc107; color: white; padding: 12px 24px; border: none; border-radius: 6px; cursor: not-allowed; margin-right: 10px;" disabled>
                        <i class="fas fa-clock"></i> Waiting for Approval
                    </button>
                    <button class="print-btn" onclick="printReport()">
                        <i class="fas fa-print"></i> Print Report
                    </button>
                `;
            } else if (approvalData.status === 'APPROVED') {
                // Check if report was already generated/printed
                if (approvalData.reportGenerated && approvalData.reportGenerated === 1) {
                    // Report already printed - show resubmit button only
                    html += `
                        <div style="background: #fff3cd; color: #856404; padding: 15px; border-radius: 6px; margin-bottom: 15px; border-left: 4px solid #ffc107;">
                            <i class="fas fa-info-circle"></i> <strong>Report Already Printed</strong><br>
                            <span style="font-size: 14px;">The approved report has already been viewed/printed. To print again, please resubmit to Head Master for a new approval.</span>
                        </div>
                        <button class="btn-submit-approval" onclick="submitForApproval('${'$'}{studentPen}', '${'$'}{studentName}')" style="background: #667eea; color: white; padding: 12px 24px; border: none; border-radius: 6px; cursor: pointer; margin-right: 10px;">
                            <i class="fas fa-paper-plane"></i> Resubmit to Head Master for New Approval
                        </button>
                        
                    `;
                } else {
                    // Report not yet printed - show normal buttons
                    html += `
                        <button class="btn-submit-approval" onclick="submitForApproval('${'$'}{studentPen}', '${'$'}{studentName}')" style="background: #667eea; color: white; padding: 12px 24px; border: none; border-radius: 6px; cursor: pointer; margin-right: 10px;">
                            <i class="fas fa-paper-plane"></i> Send to Head Master for Approval
                        </button>
                    `;
                    
                    // Only show PDF button if approvalId is available and not yet printed
                    if (approvalData.approvalId) {
                        html += `
                            <button onclick="window.open(contextPath + '/GenerateStudentReportPDFServlet?approvalId=${'$'}{approvalData.approvalId}', '_blank'); markAsGenerated(${'$'}{approvalData.approvalId});" style="background: #28a745; color: white; padding: 12px 24px; border: none; border-radius: 6px; cursor: pointer; margin-right: 10px;">
                                <i class="fas fa-file-pdf"></i> View & Print Approved Report (One Time Only)
                            </button>
                        `;
                    }
                    
                    `;
                }
            } else if (approvalData.status === 'REJECTED') {
                // Rejected - allow resubmission and print button
                html += `
                    <button class="btn-submit-approval" onclick="submitForApproval('${'$'}{studentPen}', '${'$'}{studentName}')" style="background: #dc3545; color: white; padding: 12px 24px; border: none; border-radius: 6px; cursor: pointer; margin-right: 10px;">
                        <i class="fas fa-redo"></i> Resubmit for Approval
                    </button>
                    <button class="print-btn" onclick="printReport()">
                        <i class="fas fa-print"></i> Print Report
                    </button>
                `;
            }
            
            html += '</div>';
            
            container.innerHTML = html;
        }
        
        // Toggle activity group
        function toggleActivityGroup(groupId) {
            const group = document.getElementById(groupId);
            const icon = document.getElementById(groupId + 'Icon');
            
            if (group.style.display === 'none') {
                group.style.display = 'block';
                icon.textContent = '▼';
            } else {
                group.style.display = 'none';
                icon.textContent = '▶';
            }
        }
        
        // Print report - now opens same view as Generate Report in print-friendly format
        function printReport() {
            // Get current student details from modal header
            const studentNameElement = document.getElementById('reportStudentName');
            if (!studentNameElement || !studentNameElement.textContent) {
                alert('Unable to determine student information for printing');
                return;
            }
            
            // Expand all groups before printing
            const groups = document.querySelectorAll('.activity-group-content');
            groups.forEach(group => {
                group.style.display = 'block';
            });
            
            // Trigger browser print
            window.print();
        }
        
        // Close modal
        function closeReportModal() {
            document.getElementById('reportModal').style.display = 'none';
            document.body.style.overflow = 'auto';
        }
        
        // Close modal on outside click
        window.onclick = function(event) {
            const modal = document.getElementById('reportModal');
            if (event.target == modal) {
                closeReportModal();
            }
        }
        
        // Close modal on ESC key
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeReportModal();
            }
        });
        
        // Submit report for approval
        function submitForApproval(penNumber, studentName) {
            if (!confirm('Send this report to Head Master for approval?')) {
                return;
            }
            
            fetch(contextPath + '/SubmitReportForApprovalServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'penNumber=' + encodeURIComponent(penNumber) + '&studentName=' + encodeURIComponent(studentName)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ ' + data.message);
                    closeReportModal();
                } else {
                    alert('✗ ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error submitting report for approval');
            });
        }
        
        // Mark report as generated (called after PDF button click)
        function markAsGenerated(approvalId) {
            // After a short delay (to allow PDF to open), reload the modal to update button state
            setTimeout(function() {
                // Reload the report to show updated status
                if (currentStudentPen) {
                    generateReport(null, currentStudentName, currentStudentPen);
                }
            }, 2000);
        }
    </script>
</body>
</html>

