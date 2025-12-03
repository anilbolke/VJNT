<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.PhaseApprovalDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.PhaseApproval" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.HEAD_MASTER)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    PhaseApprovalDAO approvalDAO = new PhaseApprovalDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    
    String udiseNo = user.getUdiseNo();
    List<PhaseApproval> allApprovals = approvalDAO.getAllPhaseApprovals(udiseNo);
    List<PhaseApproval> pendingApprovals = approvalDAO.getPendingApprovals(udiseNo);
    
    School school = schoolDAO.getSchoolByUdise(udiseNo);
    String schoolName = school != null ? school.getSchoolName() : "Unknown School";
    
    SimpleDateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy HH:mm");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Phase Approvals - <%= schoolName %></title>
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
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        
        .header {
            background: #f0f2f5;
            color: #000;
            padding: 30px;
            border-radius: 8px;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
            color: #000;
        }
        
        .header p {
            opacity: 1;
            font-size: 14px;
            color: #000;
        }
        
        .content {
            padding: 30px;
        }
        
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .alert-info {
            background: #e3f2fd;
            color: #1976d2;
            border-left: 4px solid #2196f3;
        }
        
        .alert-warning {
            background: #fff3e0;
            color: #e65100;
            border-left: 4px solid #ff9800;
        }
        
        .alert-success {
            background: #e8f5e9;
            color: #2e7d32;
            border-left: 4px solid #4caf50;
        }
        
        .alert-danger {
            background: #ffebee;
            color: #c62828;
            border-left: 4px solid #f44336;
        }
        
        .section {
            margin-bottom: 40px;
        }
        
        .section-title {
            font-size: 22px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e0e0e0;
        }
        
        .phase-card {
            background: white;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            transition: all 0.3s;
        }
        
        .phase-card:hover {
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            transform: translateY(-2px);
        }
        
        .phase-card.pending {
            border-left: 5px solid #ff9800;
            background: #fffbf0;
        }
        
        .phase-card.approved {
            border-left: 5px solid #4caf50;
            background: #f1f8f4;
        }
        
        .phase-card.rejected {
            border-left: 5px solid #f44336;
            background: #fef5f5;
        }
        
        .phase-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }
        
        .phase-title {
            font-size: 18px;
            font-weight: 600;
            color: #333;
        }
        
        .phase-status {
            padding: 6px 16px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 600;
        }
        
        .status-pending {
            background: #fff3e0;
            color: #e65100;
        }
        
        .status-approved {
            background: #e8f5e9;
            color: #2e7d32;
        }
        
        .status-rejected {
            background: #ffebee;
            color: #c62828;
        }
        
        .phase-info {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 15px;
        }
        
        .info-item {
            padding: 12px;
            background: #f8f9fa;
            border-radius: 6px;
        }
        
        .info-label {
            font-size: 12px;
            color: #666;
            margin-bottom: 5px;
        }
        
        .info-value {
            font-size: 16px;
            font-weight: 600;
            color: #333;
        }
        
        .remarks {
            background: #f8f9fa;
            padding: 12px;
            border-radius: 6px;
            margin-top: 10px;
            font-size: 14px;
            color: #555;
        }
        
        .actions {
            display: flex;
            gap: 10px;
            margin-top: 15px;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
        }
        
        .btn-approve {
            background: #4caf50;
            color: white;
        }
        
        .btn-approve:hover {
            background: #45a049;
        }
        
        .btn-reject {
            background: #f44336;
            color: white;
        }
        
        .btn-reject:hover {
            background: #da190b;
        }
        
        .btn-back {
            background: #757575;
            color: white;
        }
        
        .btn-back:hover {
            background: #616161;
        }
        
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }
        
        .empty-state-icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        
        @media (max-width: 768px) {
            .phase-header {
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }
            
            .actions {
                flex-direction: column;
            }
            
            .btn {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 Phase Approval Management</h1>
            <p><%= schoolName %> (UDISE: <%= udiseNo %>)</p>
            <p>Head Master: <%= user.getFullName() %></p>
        </div>
        
        <div class="content">
            <!-- Success/Error Messages -->
            <% 
            String successMsg = (String) session.getAttribute("successMessage");
            String errorMsg = (String) session.getAttribute("errorMessage");
            if (successMsg != null) {
                session.removeAttribute("successMessage");
            %>
                <div class="alert alert-success">
                    <span style="font-size: 24px;">✓</span>
                    <div><strong><%= successMsg %></strong></div>
                </div>
            <% } %>
            <% if (errorMsg != null) {
                session.removeAttribute("errorMessage");
            %>
                <div class="alert alert-danger">
                    <span style="font-size: 24px;">✗</span>
                    <div><strong><%= errorMsg %></strong></div>
                </div>
            <% } %>
            
            <% if (pendingApprovals.size() > 0) { %>
                <div class="alert alert-warning">
                    <span style="font-size: 24px;">⏳</span>
                    <div>
                        <strong><%= pendingApprovals.size() %> phase(s) pending approval</strong>
                        <div style="font-size: 13px; margin-top: 3px;">Please review and approve/reject the submitted phases below</div>
                    </div>
                </div>
            <% } else { %>
                <div class="alert alert-info">
                    <span style="font-size: 24px;">✓</span>
                    <div>
                        <strong>No pending approvals</strong>
                        <div style="font-size: 13px; margin-top: 3px;">All submitted phases have been processed</div>
                    </div>
                </div>
            <% } %>
            
            <!-- Pending Approvals Section -->
            <% if (pendingApprovals.size() > 0) { %>
            <div class="section">
                <h2 class="section-title">⏳ Pending Approvals</h2>
                
                <% for (PhaseApproval approval : pendingApprovals) { %>
                <div class="phase-card pending">
                    <div class="phase-header">
                        <div class="phase-title">चरण <%= approval.getPhaseNumber() %> (Phase <%= approval.getPhaseNumber() %>)</div>
                        <span class="phase-status status-pending">Pending Approval</span>
                    </div>
                    
                    <div class="phase-info">
                        <div class="info-item">
                            <div class="info-label">Submitted By</div>
                            <div class="info-value"><%= approval.getCompletedBy() %></div>
                        </div>
                        <div class="info-item">
                            <div class="info-label">Submitted Date</div>
                            <div class="info-value"><%= approval.getCompletedDate() != null ? sdf.format(approval.getCompletedDate()) : "N/A" %></div>
                        </div>
                        <div class="info-item">
                            <div class="info-label">Total Students</div>
                            <div class="info-value"><%= approval.getTotalStudents() %></div>
                        </div>
                        <div class="info-item">
                            <div class="info-label">Completed</div>
                            <div class="info-value"><%= approval.getCompletedStudents() %> (<%= approval.getCompletionPercentage() %>%)</div>
                        </div>
                        <div class="info-item">
                            <div class="info-label">Pending</div>
                            <div class="info-value"><%= approval.getPendingStudents() %></div>
                        </div>
                        <div class="info-item">
                            <div class="info-label">Ignored</div>
                            <div class="info-value"><%= approval.getIgnoredStudents() %></div>
                        </div>
                    </div>
                    
                    <% if (approval.getCompletionRemarks() != null && !approval.getCompletionRemarks().trim().isEmpty()) { %>
                    <div class="remarks">
                        <strong>Remarks:</strong> <%= approval.getCompletionRemarks() %>
                    </div>
                    <% } %>
                    
                    <div class="actions">
                        <a href="headmaster-approve-phase.jsp?phase=<%= approval.getPhaseNumber() %>" 
                           class="btn btn-primary" 
                           style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; display: inline-block;">
                            📋 View Details & Approve
                        </a>
                    </div>
                </div>
                <% } %>
            </div>
            <% } %>
            
            <!-- All Phases History -->
            <div class="section">
                <h2 class="section-title">📜 Phase Approval History</h2>
                
                <% if (allApprovals.size() == 0) { %>
                <div class="empty-state">
                    <div class="empty-state-icon">📋</div>
                    <p>No phases have been submitted yet</p>
                </div>
                <% } else { %>
                    <% for (PhaseApproval approval : allApprovals) { 
                        String cardClass = approval.isPending() ? "pending" : (approval.isApproved() ? "approved" : "rejected");
                        String statusClass = approval.isPending() ? "status-pending" : (approval.isApproved() ? "status-approved" : "status-rejected");
                        String statusText = approval.isPending() ? "Pending" : (approval.isApproved() ? "Approved" : "Rejected");
                    %>
                    <div class="phase-card <%= cardClass %>">
                        <div class="phase-header">
                            <div class="phase-title">चरण <%= approval.getPhaseNumber() %> (Phase <%= approval.getPhaseNumber() %>)</div>
                            <span class="phase-status <%= statusClass %>"><%= statusText %></span>
                        </div>
                        
                        <div class="phase-info">
                            <div class="info-item">
                                <div class="info-label">Completed Students</div>
                                <div class="info-value"><%= approval.getCompletedStudents() %>/<%= approval.getTotalStudents() - approval.getIgnoredStudents() %></div>
                            </div>
                            <div class="info-item">
                                <div class="info-label">Completion Rate</div>
                                <div class="info-value"><%= approval.getCompletionPercentage() %>%</div>
                            </div>
                            <div class="info-item">
                                <div class="info-label">Submitted Date</div>
                                <div class="info-value"><%= approval.getCompletedDate() != null ? sdf.format(approval.getCompletedDate()) : "N/A" %></div>
                            </div>
                            <% if (approval.isApproved() || approval.isRejected()) { %>
                            <div class="info-item">
                                <div class="info-label"><%= approval.isApproved() ? "Approved" : "Rejected" %> Date</div>
                                <div class="info-value"><%= approval.getApprovedDate() != null ? sdf.format(approval.getApprovedDate()) : "N/A" %></div>
                            </div>
                            <% } %>
                        </div>
                        
                        <% if (approval.getApprovalRemarks() != null && !approval.getApprovalRemarks().trim().isEmpty()) { %>
                        <div class="remarks">
                            <strong>Approval Remarks:</strong> <%= approval.getApprovalRemarks() %>
                        </div>
                        <% } %>
                    </div>
                    <% } %>
                <% } %>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
                <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="btn btn-back">← Back to Dashboard</a>
            </div>
        </div>
    </div>
    
    <script>
        function approvePhase(phaseNumber, action) {
            const remarks = prompt('Enter remarks (optional):');
            if (remarks === null) return; // User cancelled
            
            fetch('<%= request.getContextPath() %>/approve-phase', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'udiseNo=<%= udiseNo %>&phaseNumber=' + phaseNumber + 
                      '&action=' + action + '&remarks=' + encodeURIComponent(remarks)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert(data.message);
                    location.reload();
                } else {
                    alert('Error: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error processing request');
            });
        }
    </script>
</body>
</html>
