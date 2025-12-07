<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.ReportApprovalDAO" %>
<%@ page import="com.vjnt.model.ReportApproval" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.HEAD_MASTER)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String udiseNo = user.getUdiseNo();
    ReportApprovalDAO approvalDAO = new ReportApprovalDAO();
    
    // Get pending reports
    List<ReportApproval> pendingReports = approvalDAO.getPendingReportsByUdise(udiseNo);
    
    // Get approved reports
    List<ReportApproval> approvedReports = approvalDAO.getApprovedReportsByUdise(udiseNo);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Approve Student Reports</title>
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
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
        }
        
        .header p {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .back-btn {
            background: white;
            color: #667eea;
            padding: 12px 24px;
            border-radius: 6px;
            text-decoration: none;
            font-weight: 500;
            box-shadow: 0 2px 8px rgba(0,0,0,0.15);
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .back-btn:hover {
            background: #f8f9fa;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }
        
        .content {
            padding: 30px;
        }
        
        .nav-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 30px;
            border-bottom: 2px solid #eee;
        }
        
        .nav-tab {
            padding: 12px 24px;
            background: none;
            border: none;
            cursor: pointer;
            font-size: 16px;
            color: #666;
            border-bottom: 3px solid transparent;
            transition: all 0.3s ease;
        }
        
        .nav-tab.active {
            color: #667eea;
            border-bottom-color: #667eea;
        }
        
        .tab-content {
            display: none;
        }
        
        .tab-content.active {
            display: block;
        }
        
        .reports-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(500px, 1fr));
            gap: 20px;
        }
        
        .report-card {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 20px;
            background: #f9f9f9;
            transition: all 0.3s ease;
        }
        
        .report-card:hover {
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
            transform: translateY(-2px);
        }
        
        .report-status {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            margin-bottom: 15px;
        }
        
        .status-pending {
            background: #fff3cd;
            color: #856404;
        }
        
        .status-approved {
            background: #d4edda;
            color: #155724;
        }
        
        .report-title {
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 15px;
        }
        
        .report-info {
            margin-bottom: 10px;
            color: #666;
            font-size: 14px;
        }
        
        .report-info strong {
            color: #333;
        }
        
        .report-actions {
            display: flex;
            gap: 10px;
            margin-top: 15px;
        }
        
        .btn {
            padding: 10px 16px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s ease;
            flex: 1;
            text-align: center;
        }
        
        .btn-view {
            background: #667eea;
            color: white;
        }
        
        .btn-view:hover {
            background: #5568d3;
        }
        
        .btn-approve {
            background: #28a745;
            color: white;
        }
        
        .btn-approve:hover {
            background: #218838;
        }
        
        .btn-reject {
            background: #dc3545;
            color: white;
        }
        
        .btn-reject:hover {
            background: #c82333;
        }
        
        .empty-state {
            text-align: center;
            padding: 40px;
            color: #999;
        }
        
        .empty-state-icon {
            font-size: 48px;
            margin-bottom: 15px;
        }
        
        .empty-state p {
            font-size: 16px;
        }
        
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            z-index: 1000;
            justify-content: center;
            align-items: center;
        }
        
        .modal.active {
            display: flex;
        }
        
        .modal-content {
            background: white;
            border-radius: 8px;
            padding: 30px;
            max-width: 600px;
            width: 90%;
            max-height: 90vh;
            overflow-y: auto;
        }
        
        .modal-title {
            font-size: 20px;
            font-weight: bold;
            margin-bottom: 20px;
            color: #333;
        }
        
        .form-group {
            margin-bottom: 15px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 5px;
            color: #333;
            font-weight: 500;
        }
        
        .form-group textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-family: Arial, sans-serif;
            min-height: 100px;
            resize: vertical;
        }
        
        .modal-actions {
            display: flex;
            gap: 10px;
            margin-top: 20px;
        }
        
        .modal-actions button {
            flex: 1;
            padding: 10px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
        }
        
        .btn-cancel {
            background: #ccc;
            color: #333;
        }
        
        .count-badge {
            background: #667eea;
            color: white;
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 12px;
            margin-left: 10px;
        }
        
        .header-actions {
            display: flex;
            gap: 15px;
            align-items: center;
        }
        
        @media (max-width: 768px) {
            .header {
                padding: 20px;
            }
            
            .header div {
                flex-direction: column;
                align-items: flex-start !important;
            }
            
            .header h1 {
                font-size: 22px;
            }
            
            .header-actions {
                width: 100%;
                margin-top: 15px;
                flex-wrap: wrap;
            }
            
            .back-btn {
                width: 100%;
                justify-content: center;
            }
        }
        
        .breadcrumb {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 20px;
            padding: 10px;
            background: #f8f9fa;
            border-radius: 5px;
            font-size: 14px;
        }
        
        .breadcrumb a {
            color: #667eea;
            text-decoration: none;
            cursor: pointer;
        }
        
        .breadcrumb a:hover {
            text-decoration: underline;
        }
        
        .breadcrumb-separator {
            color: #999;
        }
        
        /* Report View Modal Styles */
        .report-modal {
            display: none;
            position: fixed;
            z-index: 2000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
            overflow-y: auto;
        }
        
        .report-modal.active {
            display: block;
        }
        
        .report-modal-content {
            background: white;
            margin: 30px auto;
            padding: 0;
            width: 95%;
            max-width: 1000px;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
        }
        
        .report-modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 30px;
            border-radius: 10px 10px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .report-modal-header h2 {
            margin: 0;
            font-size: 22px;
        }
        
        .report-close {
            color: white;
            font-size: 32px;
            font-weight: bold;
            cursor: pointer;
            line-height: 1;
            background: none;
            border: none;
        }
        
        .report-close:hover {
            opacity: 0.8;
        }
        
        .report-modal-body {
            padding: 30px;
            max-height: calc(100vh - 200px);
            overflow-y: auto;
        }
        
        .report-loading {
            text-align: center;
            padding: 40px;
            color: #666;
        }
        
        .report-loading i {
            font-size: 48px;
            animation: spin 2s linear infinite;
            color: #667eea;
        }
        
        @keyframes spin {
            100% { transform: rotate(360deg); }
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
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 15px;
        }
        
        .info-item {
            padding: 10px;
            background: #f8f9fa;
            border-radius: 5px;
        }
        
        .info-item strong {
            color: #495057;
            display: block;
            margin-bottom: 5px;
        }
    </style>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <h1 style="margin: 0;">📋 Approve Student Reports</h1>
                    <p style="margin: 5px 0 0 0;">Review and approve student comprehensive reports</p>
                </div>
                <div class="header-actions">
                    <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="back-btn" title="Go back to dashboard (or press ESC)">
                        <i class="fas fa-arrow-left"></i> Back to Dashboard
                    </a>
                </div>
            </div>
        </div>
        
        <div class="content">
            <!-- Breadcrumb Navigation -->
            <div class="breadcrumb">
                <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp">
                    <i class="fas fa-home"></i> Dashboard
                </a>
                <span class="breadcrumb-separator">/</span>
                <span>Approve Reports</span>
            </div>
            
            <!-- Navigation Tabs -->
            <div class="nav-tabs">
                <button class="nav-tab active" onclick="switchTab('pending')">
                    ⏳ Pending Review <span class="count-badge"><%= pendingReports != null ? pendingReports.size() : 0 %></span>
                </button>
                <button class="nav-tab" onclick="switchTab('approved')">
                    ✅ Approved <span class="count-badge"><%= approvedReports != null ? approvedReports.size() : 0 %></span>
                </button>
            </div>
            
            <!-- Pending Reports Tab -->
            <div id="pending" class="tab-content active">
                <% if (pendingReports != null && !pendingReports.isEmpty()) { %>
                    <div class="reports-grid">
                        <% for (ReportApproval report : pendingReports) { %>
                            <div class="report-card">
                                <span class="report-status status-pending">PENDING</span>
                                <div class="report-title"><%= report.getStudentName() %></div>
                                <div class="report-info">
                                    <strong>PEN:</strong> <%= report.getPenNumber() %>
                                </div>
                                <div class="report-info">
                                    <strong>Class:</strong> <%= report.getStudentClass() %> - <%= report.getSection() %>
                                </div>
                                <div class="report-info">
                                    <strong>Requested By:</strong> <%= report.getRequestedByName() %>
                                </div>
                                <div class="report-info">
                                    <strong>Request Date:</strong> <%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(report.getRequestedDate()) %>
                                </div>
                                <div class="report-actions">
                                    <button class="btn btn-view" onclick="viewReport(<%= report.getApprovalId() %>)">👁️ View Report</button>
                                    <button class="btn btn-approve" onclick="openApproveModal(<%= report.getApprovalId() %>, '<%= report.getStudentName() %>')">✅ Approve</button>
                                    <button class="btn btn-reject" onclick="openRejectModal(<%= report.getApprovalId() %>, '<%= report.getStudentName() %>')">❌ Reject</button>
                                </div>
                            </div>
                        <% } %>
                    </div>
                <% } else { %>
                    <div class="empty-state">
                        <div class="empty-state-icon">✅</div>
                        <p>No pending reports to review!</p>
                    </div>
                <% } %>
            </div>
            
            <!-- Approved Reports Tab -->
            <div id="approved" class="tab-content">
                <% if (approvedReports != null && !approvedReports.isEmpty()) { %>
                    <div class="reports-grid">
                        <% for (ReportApproval report : approvedReports) { %>
                            <div class="report-card">
                                <span class="report-status status-approved">APPROVED</span>
                                <div class="report-title"><%= report.getStudentName() %></div>
                                <div class="report-info">
                                    <strong>PEN:</strong> <%= report.getPenNumber() %>
                                </div>
                                <div class="report-info">
                                    <strong>Class:</strong> <%= report.getStudentClass() %> - <%= report.getSection() %>
                                </div>
                                <div class="report-info">
                                    <strong>Approved Date:</strong> <%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(report.getApprovalDate()) %>
                                </div>
                                <div class="report-actions">
                                    <button class="btn btn-view" onclick="viewReport(<%= report.getApprovalId() %>)">👁️ View Report</button>
                                    <% if (!report.isReportGenerated()) { %>
                                        <button class="btn btn-view" onclick="generateReport(<%= report.getApprovalId() %>)">📥 Generate PDF</button>
                                    <% } %>
                                </div>
                            </div>
                        <% } %>
                    </div>
                <% } else { %>
                    <div class="empty-state">
                        <div class="empty-state-icon">📭</div>
                        <p>No approved reports yet.</p>
                    </div>
                <% } %>
            </div>
        </div>
    </div>
    
    <!-- Approve Modal -->
    <div id="approveModal" class="modal">
        <div class="modal-content">
            <div class="modal-title">Approve Report</div>
            <p>Are you sure you want to approve this report for <strong id="approveStudentName"></strong>?</p>
            <div class="form-group">
                <label>Approval Remarks (Optional)</label>
                <textarea id="approvalRemarks" placeholder="Add any remarks or comments..."></textarea>
            </div>
            <div class="modal-actions">
                <button class="btn btn-cancel" onclick="closeModal('approveModal')">Cancel</button>
                <button class="btn btn-approve" onclick="submitApproval()">✅ Approve</button>
            </div>
        </div>
    </div>
    
    <!-- Reject Modal -->
    <div id="rejectModal" class="modal">
        <div class="modal-content">
            <div class="modal-title">Reject Report</div>
            <p>Are you sure you want to reject this report for <strong id="rejectStudentName"></strong>?</p>
            <div class="form-group">
                <label>Rejection Reason (Required)</label>
                <textarea id="rejectionReason" placeholder="Provide reason for rejection..." required></textarea>
            </div>
            <div class="modal-actions">
                <button class="btn btn-cancel" onclick="closeModal('rejectModal')">Cancel</button>
                <button class="btn btn-reject" onclick="submitRejection()">❌ Reject</button>
            </div>
        </div>
    </div>
    
    <script>
        let currentApprovalId = null;
        
        // Keyboard shortcut: ESC to go back to dashboard
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                // Only navigate if no modal is open
                const modals = document.querySelectorAll('.modal.active, .report-modal.active');
                if (modals.length === 0) {
                    window.location.href = '<%= request.getContextPath() %>/school-dashboard-enhanced.jsp';
                }
            }
        });
        
        function switchTab(tabName) {
            // Hide all tabs
            document.querySelectorAll('.tab-content').forEach(tab => {
                tab.classList.remove('active');
            });
            document.querySelectorAll('.nav-tab').forEach(tab => {
                tab.classList.remove('active');
            });
            
            // Show selected tab
            document.getElementById(tabName).classList.add('active');
            event.target.classList.add('active');
        }
        
        function viewReport(approvalId) {
            window.open('<%= request.getContextPath() %>/GenerateStudentReportPDFServlet?approvalId=' + approvalId, '_blank');
        }
        
        function generateReport(approvalId) {
            window.open('<%= request.getContextPath() %>/GenerateStudentReportPDFServlet?approvalId=' + approvalId, '_blank');
        }
        
        function openApproveModal(approvalId, studentName) {
            currentApprovalId = approvalId;
            document.getElementById('approveStudentName').textContent = studentName;
            document.getElementById('approvalRemarks').value = '';
            document.getElementById('approveModal').classList.add('active');
        }
        
        function openRejectModal(approvalId, studentName) {
            currentApprovalId = approvalId;
            document.getElementById('rejectStudentName').textContent = studentName;
            document.getElementById('rejectionReason').value = '';
            document.getElementById('rejectModal').classList.add('active');
        }
        
        function closeModal(modalId) {
            document.getElementById(modalId).classList.remove('active');
        }
        
        function submitApproval() {
            const remarks = document.getElementById('approvalRemarks').value;
            
            fetch('<%= request.getContextPath() %>/ApproveReportServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: 'approvalId=' + currentApprovalId + 
                      '&action=approve' +
                      '&remarks=' + encodeURIComponent(remarks)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✅ Report approved successfully!');
                    location.reload();
                } else {
                    alert('❌ Error approving report: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('❌ Error approving report');
            });
        }
        
        function submitRejection() {
            const reason = document.getElementById('rejectionReason').value;
            
            if (!reason.trim()) {
                alert('Please provide a reason for rejection');
                return;
            }
            
            fetch('<%= request.getContextPath() %>/ApproveReportServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: 'approvalId=' + currentApprovalId + 
                      '&action=reject' +
                      '&remarks=' + encodeURIComponent(reason)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('❌ Report rejected successfully!');
                    location.reload();
                } else {
                    alert('❌ Error rejecting report: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('❌ Error rejecting report');
            });
        }
        
        // Close modal when clicking outside
        document.querySelectorAll('.modal').forEach(modal => {
            modal.addEventListener('click', function(e) {
                if (e.target === this) {
                    this.classList.remove('active');
                }
            });
        });
    </script>
    
    <!-- Report View Modal -->
    <div id="reportViewModal" class="report-modal">
        <div class="report-modal-content">
            <div class="report-modal-header">
                <h2><i class="fas fa-file-alt"></i> <span id="reportStudentName"></span> - Comprehensive Report</h2>
                <button class="report-close" onclick="closeReportView()">&times;</button>
            </div>
            <div class="report-modal-body">
                <div id="reportViewLoading" class="report-loading">
                    <i class="fas fa-spinner"></i>
                    <div>Loading report data...</div>
                </div>
                <div id="reportViewContent" style="display: none;"></div>
            </div>
        </div>
    </div>
    
    <script>
        // Function to open report view modal
        function viewReport(approvalId) {
            // Get report details first
            fetch('<%= request.getContextPath() %>/api/getReportDetails?approvalId=' + approvalId)
                .then(response => response.json())
                .then(reportData => {
                    document.getElementById('reportStudentName').textContent = reportData.studentName;
                    document.getElementById('reportViewModal').classList.add('active');
                    document.getElementById('reportViewLoading').style.display = 'block';
                    document.getElementById('reportViewContent').style.display = 'none';
                    
                    // Fetch comprehensive data
                    return fetch('<%= request.getContextPath() %>/GetStudentComprehensiveDataServlet?penNumber=' + encodeURIComponent(reportData.penNumber));
                })
                .then(response => response.json())
                .then(data => {
                    document.getElementById('reportViewLoading').style.display = 'none';
                    document.getElementById('reportViewContent').style.display = 'block';
                    displayReportView(data);
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('reportViewLoading').innerHTML = '<i class="fas fa-exclamation-circle" style="color: red;"></i><p>Error loading report</p>';
                });
        }
        
        // Function to display report content
        function displayReportView(data) {
            const container = document.getElementById('reportViewContent');
            let html = '';
            
            // Get subject teachers
            const subjectTeachers = data.subjectTeachers || {};
            
            // Assessment Levels Section
            if (data.assessmentLevels) {
                html += '<div class="report-section">' +
                    '<h3><i class="fas fa-chart-line"></i> Assessment Levels</h3>' +
                    '<div class="info-grid">' +
                    '<div class="info-item"><strong>Marathi Level:</strong> ' + (data.assessmentLevels.marathi || 'Not assessed');
                    if (subjectTeachers.Marathi) {
                        html += '<br><span style="font-size: 12px; color: #495057;"><i class="fas fa-chalkboard-teacher"></i> Subject Teacher: <strong>' + subjectTeachers.Marathi + '</strong></span>';
                    }
                    html += '</div>' +
                    '<div class="info-item"><strong>Math Level:</strong> ' + (data.assessmentLevels.math || 'Not assessed');
                    if (subjectTeachers.Mathematics) {
                        html += '<br><span style="font-size: 12px; color: #495057;"><i class="fas fa-chalkboard-teacher"></i> Subject Teacher: <strong>' + subjectTeachers.Mathematics + '</strong></span>';
                    }
                    html += '</div>' +
                    '<div class="info-item"><strong>English Level:</strong> ' + (data.assessmentLevels.english || 'Not assessed');
                    if (subjectTeachers.English) {
                        html += '<br><span style="font-size: 12px; color: #495057;"><i class="fas fa-chalkboard-teacher"></i> Subject Teacher: <strong>' + subjectTeachers.English + '</strong></span>';
                    }
                    html += '</div>' +
                    '</div></div>';
            }
            
            // Activities Section
            if (data.allActivities && data.allActivities.length > 0) {
                const activities = data.allActivities;
                const totalActivities = activities.length;
                const completedActivities = activities.filter(a => a.completed).length;
                const completionRate = Math.round((completedActivities / totalActivities) * 100);
                
                /* html += '<div class="report-section">' +
                    '<h3><i class="fas fa-tasks"></i> Activities Summary</h3>' +
                    '<div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin-bottom: 20px;">' +
                    '<div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; text-align: center;">' +
                    '<div style="font-size: 32px; font-weight: bold; margin-bottom: 5px;">' + totalActivities + '</div>' +
                    '<div style="font-size: 14px; opacity: 0.9;">Total Activities</div>' +
                    '</div>' +
                    '</div>' +
                    '</div>'; */
                
                // Group by language and week
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
                Object.keys(grouped).sort().forEach(key => {
                    const group = grouped[key];
                    
                    // Get teacher name for this subject
                    const teacherName = subjectTeachers[group.language] || '';
                    const teacherInfo = teacherName ? ' <span style="font-size: 13px; color: #495057; opacity: 0.95;"><i class="fas fa-chalkboard-teacher"></i> Teacher: <strong>' + teacherName + '</strong></span>' : '';
                    
                    html += '<div style="margin-bottom: 20px; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">' +
                        '<div style="background: #f8f9fa; padding: 12px; border-bottom: 2px solid #667eea; cursor: pointer;" ' +
                        'onclick="this.nextElementSibling.style.display = this.nextElementSibling.style.display === \'none\' ? \'block\' : \'none\'">' +
                        '<h4 style="margin: 0; color: #667eea; display: flex; justify-content: space-between; align-items: center;">' +
                        '<span>' + group.language + ' - Week ' + group.week + teacherInfo + '</span>' +
                        '<span style="font-size: 18px;">▼</span>' +
                        '</h4>' +
                        '</div>' +
                        '<div style="display: block;">';
                    
                    // Sort activities by day
                    group.activities.sort((a, b) => a.dayNumber - b.dayNumber);
                    
                    group.activities.forEach(activity => {
                        const statusColor = activity.completed ? '#28a745' : '#ffc107';
                        const statusText = activity.completed ? '✓ Completed' : 'Pending';
                        
                        html += '<div style="padding: 15px; border-bottom: 1px solid #f0f0f0; display: flex; gap: 15px; align-items: start;">' +
                            '<div style="background: #667eea; color: white; padding: 8px 12px; border-radius: 6px; font-weight: bold; min-width: 60px; text-align: center;">' +
                            'Day ' + activity.dayNumber +
                            '</div>' +
                            '<div style="flex: 1;">' +
                            '<div style="font-size: 15px; color: #333; margin-bottom: 5px;">' + (activity.activityText || 'N/A') + '</div>';
                        
                        if (activity.assignedBy || activity.activityCount > 1) {
                            html += '<div style="font-size: 13px; color: #666;">';
                            if (activity.assignedBy) {
                                html += '<span>Assigned by: ' + activity.assignedBy + '</span>';
                            }
                            if (activity.activityCount > 1) {
                                html += '<span style="background: #667eea; color: white; padding: 2px 8px; border-radius: 10px; margin-left: 10px; font-size: 11px;">' +
                                    activity.activityCount + 'x</span>';
                            }
                            html += '</div>';
                        }
                        
                        html += '</div>' +
                            '<div style="background: ' + statusColor + '; color: white; padding: 6px 12px; border-radius: 6px; font-size: 13px; white-space: nowrap;">' +
                            statusText +
                            '</div>' +
                            '</div>';
                    });
                    
                    html += '</div></div>';
                });
                
                html += '</div>';
            } else {
                html += '<div class="report-section">' +
                    '<h3><i class="fas fa-tasks"></i> Activities Summary</h3>' +
                    '<p style="text-align: center; color: #6c757d; padding: 20px;">No activities recorded</p>' +
                    '</div>';
            }
            
            // Palak Melava Section
            if (data.palakMelavaData && data.palakMelavaData.length > 0) {
                html += '<div class="report-section">' +
                    '<h3><i class="fas fa-users"></i> Parent-Teacher Meetings (' + data.palakMelavaData.length + ' meetings)</h3>';
                
                data.palakMelavaData.forEach((melava, index) => {
                    html += '<div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 10px;">' +
                        '<strong>Meeting #' + (index + 1) + '</strong><br>' +
                        'Date: ' + (melava.meetingDate || 'N/A') + '<br>' +
                        'Parents Attended: ' + (melava.totalParentsAttended || 'N/A') + '<br>' +
                        'Chief Guest/Attendee: ' + (melava.chiefAttendeeInfo || 'N/A') +
                        '</div>';
                });
                
                html += '</div>';
            }
            
            container.innerHTML = html;
        }
        
        // Function to close report view modal
        function closeReportView() {
            document.getElementById('reportViewModal').classList.remove('active');
        }
        
        // Close on ESC key (with proper modal hierarchy)
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                const reportModal = document.getElementById('reportViewModal');
                const approveModal = document.getElementById('approveModal');
                const rejectModal = document.getElementById('rejectModal');
                
                // Close report modal first if it's open
                if (reportModal.classList.contains('active')) {
                    closeReportView();
                    return;
                }
                
                // Close approval/rejection modals if open
                if (approveModal.classList.contains('active') || rejectModal.classList.contains('active')) {
                    approveModal.classList.remove('active');
                    rejectModal.classList.remove('active');
                    return;
                }
                
                // If no modals are open, navigate back to dashboard
                window.location.href = '<%= request.getContextPath() %>/school-dashboard-enhanced.jsp';
            }
        });
        
        // Close on outside click
        document.getElementById('reportViewModal').addEventListener('click', function(e) {
            if (e.target === this) {
                closeReportView();
            }
        });
    </script>
</body>
</html>
