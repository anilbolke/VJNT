<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.ReportApprovalDAO" %>
<%@ page import="com.vjnt.model.ReportApproval" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    String userType = (String) session.getAttribute("userType");
    Integer userId = (Integer) session.getAttribute("userId");
    
    if (user == null || userId == null || !"HEAD_MASTER".equals(userType)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    ReportApprovalDAO approvalDAO = new ReportApprovalDAO();
    List<ReportApproval> pendingReports = approvalDAO.getPendingReportsByUdise(user.getUdiseNo());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pending Report Approvals</title>
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
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            padding: 30px;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #e0e0e0;
        }
        
        .header h1 {
            color: #333;
            font-size: 28px;
        }
        
        .back-btn {
            background: #6c757d;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
        }
        
        .back-btn:hover {
            background: #5a6268;
        }
        
        .pending-count {
            background: #ffc107;
            color: #333;
            padding: 8px 16px;
            border-radius: 20px;
            font-weight: bold;
            margin-left: 15px;
        }
        
        .report-card {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            border-left: 4px solid #667eea;
        }
        
        .report-header {
            display: flex;
            justify-content: space-between;
            align-items: start;
            margin-bottom: 15px;
        }
        
        .student-info h3 {
            color: #667eea;
            margin-bottom: 5px;
        }
        
        .student-details {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-bottom: 15px;
        }
        
        .detail-item {
            padding: 10px;
            background: white;
            border-radius: 6px;
        }
        
        .detail-label {
            font-size: 12px;
            color: #6c757d;
            margin-bottom: 5px;
        }
        
        .detail-value {
            font-weight: 600;
            color: #333;
        }
        
        .action-buttons {
            display: flex;
            gap: 10px;
            margin-top: 15px;
        }
        
        .btn-view {
            background: #17a2b8;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            flex: 1;
        }
        
        .btn-view:hover {
            background: #138496;
        }
        
        .btn-approve {
            background: #28a745;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            flex: 1;
        }
        
        .btn-approve:hover {
            background: #218838;
        }
        
        .btn-reject {
            background: #dc3545;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            flex: 1;
        }
        
        .btn-reject:hover {
            background: #c82333;
        }
        
        .no-reports {
            text-align: center;
            padding: 60px 20px;
            color: #6c757d;
        }
        
        .no-reports i {
            font-size: 64px;
            margin-bottom: 20px;
            opacity: 0.5;
        }
        
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.7);
        }
        
        .modal-content {
            background: white;
            margin: 2% auto;
            padding: 0;
            width: 95%;
            max-width: 1200px;
            border-radius: 12px;
            max-height: 90vh;
            overflow-y: auto;
        }
        
        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 12px 12px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .close {
            color: white;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
        }
        
        .close:hover {
            opacity: 0.8;
        }
        
        .remarks-section {
            margin-top: 15px;
            padding: 15px;
            background: white;
            border-radius: 6px;
        }
        
        .remarks-section textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 6px;
            min-height: 80px;
            font-family: inherit;
        }
        
        /* Report Display Styles */
        .report-section {
            background: white;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 8px;
            border: 1px solid #e0e0e0;
        }
        
        .report-section h3 {
            color: #667eea;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e0e0e0;
        }
        
        .levels-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-bottom: 15px;
        }
        
        .level-box {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            border: 2px solid #e0e0e0;
        }
        
        .level-box.assessed {
            background: #d4edda;
            border-color: #28a745;
        }
        
        .level-label {
            font-weight: 600;
            color: #667eea;
            margin-bottom: 10px;
            font-size: 14px;
        }
        
        .level-value {
            font-size: 16px;
            font-weight: 600;
            color: #333;
        }
        
        .activity-group {
            margin-bottom: 15px;
            border: 1px solid #e0e0e0;
            border-radius: 6px;
            overflow: hidden;
        }
        
        .activity-group-header {
            background: #f8f9fa;
            padding: 12px 15px;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .activity-group-header:hover {
            background: #e9ecef;
        }
        
        .activity-group-title {
            color: #667eea;
            font-size: 16px;
            margin: 0;
        }
        
        .activity-group-content {
            padding: 10px;
        }
        
        .activity-item {
            background: white;
            padding: 12px;
            margin-bottom: 8px;
            border-radius: 6px;
            border: 1px solid #e0e0e0;
        }
        
        .activity-day {
            font-weight: 600;
            color: #667eea;
            margin-bottom: 5px;
        }
        
        .activity-text {
            color: #333;
            margin-bottom: 5px;
        }
        
        .activity-meta {
            font-size: 12px;
            color: #6c757d;
            margin-top: 8px;
        }
        
        .summary-stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .stat-box {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        
        .stat-value {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 14px;
            color: #6c757d;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1><i class="fas fa-clipboard-check"></i> Pending Report Approvals
                <% if (pendingReports != null && !pendingReports.isEmpty()) { %>
                    <span class="pending-count"><%= pendingReports.size() %></span>
                <% } %>
                </h1>
            </div>
            <a href="dashboard.jsp" class="back-btn"><i class="fas fa-arrow-left"></i> Back to Dashboard</a>
        </div>
        
        <% if (pendingReports == null || pendingReports.isEmpty()) { %>
            <div class="no-reports">
                <i class="fas fa-inbox"></i>
                <h2>No Pending Approvals</h2>
                <p>All reports have been reviewed!</p>
            </div>
        <% } else {
            for (ReportApproval report : pendingReports) {
        %>
            <div class="report-card">
                <div class="report-header">
                    <div class="student-info">
                        <h3><%= report.getStudentName() %></h3>
                        <p style="color: #6c757d; font-size: 14px;">
                            Requested by: <%= report.getRequestedByName() != null ? report.getRequestedByName() : "Unknown" %> 
                            on <%= report.getRequestedDate() %>
                        </p>
                    </div>
                    <span style="background: #ffc107; color: #333; padding: 6px 16px; border-radius: 16px; font-size: 14px;">
                        <i class="fas fa-clock"></i> PENDING
                    </span>
                </div>
                
                <div class="student-details">
                    <div class="detail-item">
                        <div class="detail-label">PEN Number</div>
                        <div class="detail-value"><%= report.getPenNumber() %></div>
                    </div>
                    <div class="detail-item">
                        <div class="detail-label">Class - Section</div>
                        <div class="detail-value"><%= report.getStudentClass() %> - <%= report.getSection() != null ? report.getSection() : "N/A" %></div>
                    </div>
                    <div class="detail-item">
                        <div class="detail-label">Report Type</div>
                        <div class="detail-value">Comprehensive Report</div>
                    </div>
                </div>
                
                <div class="action-buttons">
                    <button class="btn-view" onclick="window.open('student-comprehensive-report-new.jsp', '_blank')">
                        <i class="fas fa-eye"></i> View Report Page
                    </button>
                    <button class="btn-approve" onclick="showApproveDialog(<%= report.getApprovalId() %>, '<%= report.getStudentName() %>')">
                        <i class="fas fa-check"></i> Approve
                    </button>
                    <button class="btn-reject" onclick="showRejectDialog(<%= report.getApprovalId() %>, '<%= report.getStudentName() %>')">
                        <i class="fas fa-times"></i> Reject
                    </button>
                </div>
            </div>
        <% 
            }
        } 
        %>
    </div>
    
    <!-- Report Modal -->
    <div id="reportModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2><i class="fas fa-file-alt"></i> Student Report - <span id="reportStudentName"></span></h2>
                <span class="close" onclick="closeReportModal()">&times;</span>
            </div>
            <div id="reportContent" style="padding: 20px;"></div>
            <div id="approvalSection" style="padding: 20px; border-top: 2px solid #e0e0e0;">
                <div class="action-buttons">
                    <button class="btn-approve" onclick="approveFromModal()">
                        <i class="fas fa-check"></i> Approve Report
                    </button>
                    <button class="btn-reject" onclick="rejectFromModal()">
                        <i class="fas fa-times"></i> Reject Report
                    </button>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        const contextPath = '<%= request.getContextPath() %>';
        let currentApprovalId = null;
        let currentPenNumber = null;
        
        function viewReport(penNumber, studentName, approvalId) {
            currentApprovalId = approvalId;
            currentPenNumber = penNumber;
            
            document.getElementById('reportStudentName').textContent = studentName;
            document.getElementById('reportModal').style.display = 'block';
            document.body.style.overflow = 'hidden';
            
            // Fetch and display report
            fetch(contextPath + '/GetStudentComprehensiveDataServlet?penNumber=' + encodeURIComponent(penNumber))
                .then(response => response.json())
                .then(data => {
                    displayReport(data, studentName, penNumber);
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('reportContent').innerHTML = '<p style="color: red;">Error loading report</p>';
                });
        }
        
        function displayReport(data, studentName, penNumber) {
            const container = document.getElementById('reportContent');
            
            let html = '';
            
            // Student Info Section
            html += `
                <div class="report-section">
                    <h3><i class="fas fa-user"></i> Student Information</h3>
                    <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px;">
                        <div><strong>Name:</strong> ${studentName}</div>
                        <div><strong>PEN Number:</strong> ${penNumber}</div>
                    </div>
                </div>
            `;
            
            // Assessment Levels Section
            if (data.assessmentLevels) {
                html += `
                    <div class="report-section">
                        <h3><i class="fas fa-chart-line"></i> Assessment Levels</h3>
                        <div class="levels-grid">
                            <div class="level-box ${data.assessmentLevels.english !== 'स्तर निश्चित केला नाही' ? 'assessed' : ''}">
                                <div class="level-label">ENGLISH</div>
                                <div class="level-value">${data.assessmentLevels.english}</div>
                            </div>
                            <div class="level-box ${data.assessmentLevels.marathi !== 'स्तर निश्चित केला नाही' ? 'assessed' : ''}">
                                <div class="level-label">MARATHI</div>
                                <div class="level-value">${data.assessmentLevels.marathi}</div>
                            </div>
                            <div class="level-box ${data.assessmentLevels.math !== 'स्तर निश्चित केला नाही' ? 'assessed' : ''}">
                                <div class="level-label">MATH</div>
                                <div class="level-value">${data.assessmentLevels.math}</div>
                            </div>
                        </div>
                        <div style="margin-top: 15px; padding: 12px; background: #e7f3ff; border-radius: 6px; text-align: center;">
                            <strong>Overall Progress:</strong> ${data.assessmentLevels.overall}
                        </div>
                    </div>
                `;
            }
            
            // Palak Melava Section
            if (data.palakMelavaData && data.palakMelavaData.length > 0) {
                html += `
                    <div class="report-section">
                        <h3><i class="fas fa-users"></i> Parent-Teacher Meetings</h3>
                        <p style="margin-bottom: 15px; color: #6c757d;">School has conducted ${data.palakMelavaData.length} parent-teacher meeting(s)</p>
                `;
                
                data.palakMelavaData.forEach((melava, index) => {
                    html += `
                        <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 10px; border-left: 4px solid #667eea;">
                            <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px;">
                                <div><strong>Meeting Date:</strong> ${melava.meetingDate || 'N/A'}</div>
                                <div><strong>Parents Attended:</strong> ${melava.totalParentsAttended || 'N/A'}</div>
                                <div><strong>Chief Guest:</strong> ${melava.chiefAttendeeInfo || 'N/A'}</div>
                            </div>
                        </div>
                    `;
                });
                
                html += '</div>';
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
                            <div class="stat-box">
                                <div class="stat-value" style="color: #667eea;">${totalActivities}</div>
                                <div class="stat-label">Total Activities</div>
                            </div>
                            <div class="stat-box">
                                <div class="stat-value" style="color: #28a745;">${completedActivities}</div>
                                <div class="stat-label">Completed</div>
                            </div>
                            <div class="stat-box">
                                <div class="stat-value" style="color: #ffc107;">${completionRate}%</div>
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
                
                // Display grouped activities (collapsed by default)
                let groupIndex = 0;
                Object.keys(grouped).sort().forEach(key => {
                    const group = grouped[key];
                    const groupId = 'activityGroupModal' + groupIndex;
                    groupIndex++;
                    
                    html += `
                        <div class="activity-group">
                            <div class="activity-group-header" onclick="toggleActivityGroupModal('${groupId}')">
                                <h4 class="activity-group-title">${group.language} - Week ${group.week}</h4>
                                <span id="${groupId}Icon" class="toggle-icon">▼</span>
                            </div>
                            <div id="${groupId}" class="activity-group-content" style="display: none;">
                    `;
                    
                    group.activities.sort((a, b) => a.dayNumber - b.dayNumber);
                    
                    group.activities.forEach(activity => {
                        html += `
                            <div class="activity-item">
                                <div class="activity-day">Day ${activity.dayNumber}</div>
                                <div class="activity-text">${activity.activityText || 'N/A'}</div>
                        `;
                        
                        if (activity.assignedBy || activity.activityCount > 1) {
                            html += '<div class="activity-meta">';
                            if (activity.assignedBy) {
                                html += `<span>Assigned by: ${activity.assignedBy}</span>`;
                            }
                            if (activity.activityCount > 1) {
                                html += ` <span style="background: #ffc107; color: #333; padding: 2px 8px; border-radius: 10px; margin-left: 10px;">${activity.activityCount}x</span>`;
                            }
                            html += '</div>';
                        }
                        
                        html += '</div>';
                    });
                    
                    html += `
                            </div>
                        </div>
                    `;
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
            
            container.innerHTML = html;
        }
        
        // Toggle activity group in modal
        function toggleActivityGroupModal(groupId) {
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
        
        function closeReportModal() {
            document.getElementById('reportModal').style.display = 'none';
            document.body.style.overflow = 'auto';
        }
        
        function showApproveDialog(approvalId, studentName) {
            const remarks = prompt('Approve report for ' + studentName + '?\n\nOptional remarks:');
            if (remarks !== null) {
                processApproval(approvalId, 'approve', remarks);
            }
        }
        
        function showRejectDialog(approvalId, studentName) {
            const remarks = prompt('Reject report for ' + studentName + '?\n\nReason for rejection (required):');
            if (remarks && remarks.trim()) {
                processApproval(approvalId, 'reject', remarks);
            } else if (remarks !== null) {
                alert('Rejection reason is required');
            }
        }
        
        function approveFromModal() {
            if (currentApprovalId) {
                const remarks = prompt('Optional approval remarks:');
                if (remarks !== null) {
                    processApproval(currentApprovalId, 'approve', remarks);
                }
            }
        }
        
        function rejectFromModal() {
            if (currentApprovalId) {
                const remarks = prompt('Reason for rejection (required):');
                if (remarks && remarks.trim()) {
                    processApproval(currentApprovalId, 'reject', remarks);
                } else if (remarks !== null) {
                    alert('Rejection reason is required');
                }
            }
        }
        
        function processApproval(approvalId, action, remarks) {
            fetch(contextPath + '/ApproveReportServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'approvalId=' + approvalId + '&action=' + action + '&remarks=' + encodeURIComponent(remarks || '')
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ ' + data.message);
                    location.reload();
                } else {
                    alert('✗ ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error processing approval');
            });
        }
    </script>
</body>
</html>
