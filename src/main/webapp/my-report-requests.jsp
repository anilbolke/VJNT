<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    String userType = (String) session.getAttribute("userType");
    Integer userId = (Integer) session.getAttribute("userId");
    
    if (user == null || userId == null || !"SCHOOL_COORDINATOR".equals(userType)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Report Requests - VJNT Class Management</title>
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
            min-height: 500px;
        }
        
        .info-banner {
            background: #e7f3ff;
            border-left: 4px solid #2196F3;
            padding: 15px 20px;
            margin-bottom: 25px;
            border-radius: 4px;
        }
        
        .info-banner i {
            color: #2196F3;
            margin-right: 10px;
        }
        
        .stats-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        
        .stat-card.pending {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }
        
        .stat-card.approved {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        }
        
        .stat-card.rejected {
            background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
        }
        
        .stat-number {
            font-size: 36px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .reports-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        .reports-table th {
            background: #667eea;
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
        }
        
        .reports-table td {
            padding: 15px;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .reports-table tr:hover {
            background: #f5f5f5;
        }
        
        .status-badge {
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
        }
        
        .status-pending {
            background: #fff3cd;
            color: #856404;
        }
        
        .status-approved {
            background: #d4edda;
            color: #155724;
        }
        
        .status-rejected {
            background: #f8d7da;
            color: #721c24;
        }
        
        .btn-print {
            background: #28a745;
            color: white;
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .btn-print:hover {
            background: #218838;
            transform: translateY(-2px);
        }
        
        .btn-print:disabled {
            background: #ccc;
            cursor: not-allowed;
            transform: none;
        }
        
        .loading {
            text-align: center;
            padding: 40px;
            color: #666;
        }
        
        .loading i {
            font-size: 48px;
            animation: spin 2s linear infinite;
            color: #667eea;
        }
        
        @keyframes spin {
            100% { transform: rotate(360deg); }
        }
        
        .no-data {
            text-align: center;
            padding: 60px 20px;
            color: #666;
        }
        
        .no-data i {
            font-size: 64px;
            color: #ddd;
            margin-bottom: 20px;
        }
        
        .filter-section {
            margin-bottom: 20px;
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
        }
        
        .filter-btn {
            padding: 10px 20px;
            border: 2px solid #667eea;
            background: white;
            color: #667eea;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .filter-btn.active {
            background: #667eea;
            color: white;
        }
        
        .filter-btn:hover {
            background: #667eea;
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2><i class="fas fa-clipboard-list"></i> My Report Requests</h2>
            <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="back-btn">
                <i class="fas fa-arrow-left"></i> Back to Dashboard
            </a>
        </div>
        
        <div class="content">
            <div class="info-banner">
                <i class="fas fa-info-circle"></i>
                <strong>About Report Requests:</strong> All reports must be approved by the Head Master before you can print them. Track your pending, approved, and rejected requests here.
            </div>
            
            <!-- Statistics Cards -->
            <div class="stats-cards">
                <div class="stat-card">
                    <div class="stat-number" id="totalCount">0</div>
                    <div class="stat-label">Total Requests</div>
                </div>
                <div class="stat-card pending">
                    <div class="stat-number" id="pendingCount">0</div>
                    <div class="stat-label">Pending Approval</div>
                </div>
                <div class="stat-card approved">
                    <div class="stat-number" id="approvedCount">0</div>
                    <div class="stat-label">Approved</div>
                </div>
                <div class="stat-card rejected">
                    <div class="stat-number" id="rejectedCount">0</div>
                    <div class="stat-label">Rejected</div>
                </div>
            </div>
            
            <!-- Filter Buttons -->
            <div class="filter-section">
                <button class="filter-btn active" onclick="filterReports('ALL')">All Reports</button>
                <button class="filter-btn" onclick="filterReports('PENDING')">Pending</button>
                <button class="filter-btn" onclick="filterReports('APPROVED')">Approved</button>
                <button class="filter-btn" onclick="filterReports('REJECTED')">Rejected</button>
            </div>
            
            <!-- Loading State -->
            <div id="loadingState" class="loading">
                <i class="fas fa-spinner"></i>
                <p>Loading your report requests...</p>
            </div>
            
            <!-- No Data State -->
            <div id="noDataState" class="no-data" style="display: none;">
                <i class="fas fa-inbox"></i>
                <h3>No Report Requests Found</h3>
                <p>You haven't submitted any report requests yet.</p>
                <p style="margin-top: 15px;">
                    <a href="<%= request.getContextPath() %>/student-comprehensive-report-new.jsp" style="color: #667eea; text-decoration: none; font-weight: 600;">
                        <i class="fas fa-plus-circle"></i> Generate Your First Report
                    </a>
                </p>
            </div>
            
            <!-- Reports Table -->
            <div id="reportsTableContainer" style="display: none;">
                <table class="reports-table">
                    <thead>
                        <tr>
                            <th>Request ID</th>
                            <th>Student Name</th>
                            <th>PEN Number</th>
                            <th>Class/Section</th>
                            <th>Requested Date</th>
                            <th>Status</th>
                            <th>Remarks</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody id="reportsTableBody">
                        <!-- Data will be loaded here -->
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    
    <!-- Report View Modal -->
    <div id="reportModal" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.7); z-index: 10000; overflow-y: auto;">
        <div style="max-width: 1000px; margin: 50px auto; background: white; border-radius: 10px; box-shadow: 0 10px 40px rgba(0,0,0,0.3);">
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; display: flex; justify-content: space-between; align-items: center;">
                <h2 style="margin: 0; font-size: 24px;"><i class="fas fa-file-alt"></i> Student Comprehensive Report</h2>
                <button onclick="closeReportModal()" style="background: white; color: #667eea; border: none; padding: 8px 16px; border-radius: 5px; cursor: pointer; font-size: 16px;">
                    <i class="fas fa-times"></i> Close
                </button>
            </div>
            <div id="reportContent" style="padding: 30px; min-height: 400px;">
                <div style="text-align: center; padding: 50px;">
                    <i class="fas fa-spinner fa-spin" style="font-size: 48px; color: #667eea;"></i>
                    <p>Loading report...</p>
                </div>
            </div>
            <div style="padding: 20px; background: #f8f9fa; border-radius: 0 0 10px 10px; text-align: center; border-top: 1px solid #dee2e6;">
                <button onclick="printReportModal()" style="background: #28a745; color: white; border: none; padding: 12px 30px; border-radius: 6px; cursor: pointer; font-size: 16px; margin-right: 10px;">
                    <i class="fas fa-print"></i> Print Report
                </button>
                <button onclick="closeReportModal()" style="background: #6c757d; color: white; border: none; padding: 12px 30px; border-radius: 6px; cursor: pointer; font-size: 16px;">
                    <i class="fas fa-times"></i> Close
                </button>
            </div>
        </div>
    </div>
    
    <script>
        const contextPath = '<%= request.getContextPath() %>';
        let allReports = [];
        let currentFilter = 'ALL';
        
        // Load reports on page load
        document.addEventListener('DOMContentLoaded', function() {
            loadReports();
        });
        
        // Load all report requests
        function loadReports() {
            fetch(contextPath + '/GetMyReportRequestsServlet')
                .then(response => response.json())
                .then(data => {
                    allReports = data;
                    updateStatistics(data);
                    displayReports(data);
                    
                    document.getElementById('loadingState').style.display = 'none';
                    
                    if (data.length === 0) {
                        document.getElementById('noDataState').style.display = 'block';
                    } else {
                        document.getElementById('reportsTableContainer').style.display = 'block';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('loadingState').innerHTML = '<i class="fas fa-exclamation-circle" style="color: red;"></i><p>Error loading reports</p>';
                });
        }
        
        // Update statistics
        function updateStatistics(reports) {
            const total = reports.length;
            const pending = reports.filter(r => r.approvalStatus === 'PENDING').length;
            const approved = reports.filter(r => r.approvalStatus === 'APPROVED').length;
            const rejected = reports.filter(r => r.approvalStatus === 'REJECTED').length;
            
            document.getElementById('totalCount').textContent = total;
            document.getElementById('pendingCount').textContent = pending;
            document.getElementById('approvedCount').textContent = approved;
            document.getElementById('rejectedCount').textContent = rejected;
        }
        
        // Display reports in table
        function displayReports(reports) {
            const tbody = document.getElementById('reportsTableBody');
            tbody.innerHTML = '';
            
            if (reports.length === 0) {
                tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; padding: 40px; color: #999;">No reports match the current filter</td></tr>';
                return;
            }
            
            reports.forEach(report => {
                const row = document.createElement('tr');
                
                let statusClass = 'status-pending';
                let statusText = 'Pending';
                if (report.approvalStatus === 'APPROVED') {
                    statusClass = 'status-approved';
                    statusText = 'Approved';
                } else if (report.approvalStatus === 'REJECTED') {
                    statusClass = 'status-rejected';
                    statusText = 'Rejected';
                }
                
                let actionButton = '';
                if (report.approvalStatus === 'APPROVED') {
                    actionButton = '<button class="btn-print" onclick="printReport(' + report.approvalId + ')">' +
                                  '<i class="fas fa-print"></i> Print</button>';
                } else {
                    actionButton = '<button class="btn-print" disabled title="Waiting for approval">' +
                                  '<i class="fas fa-clock"></i> Pending</button>';
                }
                
                row.innerHTML = '<td>#' + report.approvalId + '</td>' +
                    '<td><strong>' + report.studentName + '</strong></td>' +
                    '<td>' + report.penNumber + '</td>' +
                    '<td>' + (report.studentClass || 'N/A') + ' ' + (report.section ? '/ ' + report.section : '') + '</td>' +
                    '<td>' + report.requestedDate + '</td>' +
                    '<td><span class="status-badge ' + statusClass + '">' + statusText + '</span></td>' +
                    '<td>' + (report.approvalRemarks || '-') + '</td>' +
                    '<td>' + actionButton + '</td>';
                
                tbody.appendChild(row);
            });
        }
        
        // Filter reports
        function filterReports(status) {
            currentFilter = status;
            
            // Update active button
            document.querySelectorAll('.filter-btn').forEach(btn => {
                btn.classList.remove('active');
            });
            event.target.classList.add('active');
            
            // Filter data
            let filtered = allReports;
            if (status !== 'ALL') {
                filtered = allReports.filter(r => r.approvalStatus === status);
            }
            
            displayReports(filtered);
        }
        
        // View and print approved report
        let currentApprovalId = null;
        
        function printReport(approvalId) {
            currentApprovalId = approvalId;
            document.getElementById('reportModal').style.display = 'block';
            document.body.style.overflow = 'hidden';
            loadReportData(approvalId);
        }
        
        function closeReportModal() {
            document.getElementById('reportModal').style.display = 'none';
            document.body.style.overflow = 'auto';
            currentApprovalId = null;
        }
        
        function printReportModal() {
            window.print();
        }
        
        // Load comprehensive report data
        function loadReportData(approvalId) {
            document.getElementById('reportContent').innerHTML = `
                <div style="text-align: center; padding: 50px;">
                    <i class="fas fa-spinner fa-spin" style="font-size: 48px; color: #667eea;"></i>
                    <p>Loading report...</p>
                </div>
            `;
            
            fetch(contextPath + '/GetComprehensiveReportServlet?approvalId=' + approvalId)
                .then(response => response.json())
                .then(data => {
                    if (data.error) {
                        document.getElementById('reportContent').innerHTML = `
                            <div style="text-align: center; padding: 50px; color: red;">
                                <i class="fas fa-exclamation-circle" style="font-size: 48px;"></i>
                                <p>${data.error}</p>
                            </div>
                        `;
                        return;
                    }
                    displayComprehensiveReport(data);
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('reportContent').innerHTML = `
                        <div style="text-align: center; padding: 50px; color: red;">
                            <i class="fas fa-exclamation-circle" style="font-size: 48px;"></i>
                            <p>Error loading report data</p>
                        </div>
                    `;
                });
        }
        
        // Display comprehensive report
        function displayComprehensiveReport(data) {
            let html = `
                <!-- Student Info Header -->
                <div style="background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%); padding: 20px; border-radius: 10px; margin-bottom: 20px;">
                    <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px;">
                        <div><strong>Student Name:</strong> ${data.studentName || 'N/A'}</div>
                        <div><strong>PEN Number:</strong> ${data.penNumber || 'N/A'}</div>
                        <div><strong>Class:</strong> ${data.studentClass || 'N/A'}</div>
                        <div><strong>Section:</strong> ${data.section || 'N/A'}</div>
                    </div>
                </div>
            `;
            
            // Assessment Levels
            if (data.assessmentLevels) {
                html += `
                    <div style="margin-bottom: 30px;">
                        <h3 style="color: #667eea; border-bottom: 2px solid #667eea; padding-bottom: 10px; margin-bottom: 15px;">
                            <i class="fas fa-chart-line"></i> Assessment Levels
                        </h3>
                        <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin-bottom: 15px;">
                            <div style="background: #fff3cd; padding: 15px; border-radius: 8px; border: 2px solid #ffc107;">
                                <div style="font-size: 12px; color: #856404; font-weight: bold; margin-bottom: 8px; text-align: center;">MARATHI</div>
                                <div style="font-size: 13px; font-weight: 600; color: #856404; text-align: center; line-height: 1.4;">${data.assessmentLevels.marathi || 'स्तर निश्चित केला नाही'}</div>
                            </div>
                            <div style="background: #d4edda; padding: 15px; border-radius: 8px; border: 2px solid #28a745;">
                                <div style="font-size: 12px; color: #155724; font-weight: bold; margin-bottom: 8px; text-align: center;">ENGLISH</div>
                                <div style="font-size: 13px; font-weight: 600; color: #155724; text-align: center; line-height: 1.4;">${data.assessmentLevels.english || 'स्तर निश्चित केला नाही'}</div>
                            </div>
                            <div style="background: #d1ecf1; padding: 15px; border-radius: 8px; border: 2px solid #17a2b8;">
                                <div style="font-size: 12px; color: #0c5460; font-weight: bold; margin-bottom: 8px; text-align: center;">MATH</div>
                                <div style="font-size: 13px; font-weight: 600; color: #0c5460; text-align: center; line-height: 1.4;">${data.assessmentLevels.math || 'स्तर निश्चित केला नाही'}</div>
                            </div>
                        </div>
                        <div style="background: #e7f3ff; padding: 12px; border-radius: 6px; text-align: center;">
                            <strong>Overall Progress:</strong> ${data.assessmentLevels.overall || 'Not Yet Assessed'}
                        </div>
                    </div>
                `;
            }
            
            // Activities Summary
            if (data.allActivities && data.allActivities.length > 0) {
                const activities = data.allActivities;
                const totalActivities = activities.length;
                const completedActivities = activities.filter(a => a.completed).length;
                const completionRate = Math.round((completedActivities / totalActivities) * 100);
                
                html += `
                    <div style="margin-bottom: 30px;">
                        <h3 style="color: #667eea; border-bottom: 2px solid #667eea; padding-bottom: 10px; margin-bottom: 15px;">
                            <i class="fas fa-tasks"></i> Activities Summary
                        </h3>
                        <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin-bottom: 20px;">
                            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; text-align: center;">
                                <div style="font-size: 32px; font-weight: bold; margin-bottom: 5px;">${totalActivities}</div>
                                <div style="font-size: 14px; opacity: 0.9;">Total Activities</div>
                            </div>
                            <div style="background: linear-gradient(135deg, #28a745 0%, #20c997 100%); color: white; padding: 20px; border-radius: 10px; text-align: center;">
                                <div style="font-size: 32px; font-weight: bold; margin-bottom: 5px;">${completedActivities}</div>
                                <div style="font-size: 14px; opacity: 0.9;">Completed</div>
                            </div>
                            <div style="background: linear-gradient(135deg, #ffc107 0%, #ff9800 100%); color: white; padding: 20px; border-radius: 10px; text-align: center;">
                                <div style="font-size: 32px; font-weight: bold; margin-bottom: 5px;">${completionRate}%</div>
                                <div style="font-size: 14px; opacity: 0.9;">Completion Rate</div>
                            </div>
                        </div>
                `;
                
                // Group activities
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
                
                Object.keys(grouped).sort().forEach(key => {
                    const group = grouped[key];
                    html += `
                        <div style="margin-bottom: 20px; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
                            <div style="background: #f8f9fa; padding: 12px; border-bottom: 2px solid #667eea;">
                                <h4 style="margin: 0; color: #667eea;">${group.language} - Week ${group.week}</h4>
                            </div>
                            <div>
                    `;
                    
                    group.activities.sort((a, b) => a.dayNumber - b.dayNumber);
                    group.activities.forEach(activity => {
                        const statusColor = activity.completed ? '#28a745' : '#ffc107';
                        const statusText = activity.completed ? '✓ Completed' : 'Pending';
                        html += `
                            <div style="padding: 15px; border-bottom: 1px solid #f0f0f0; display: flex; gap: 15px; align-items: start;">
                                <div style="background: #667eea; color: white; padding: 8px 12px; border-radius: 6px; font-weight: bold; min-width: 60px; text-align: center;">
                                    Day ${activity.dayNumber}
                                </div>
                                <div style="flex: 1;">
                                    <div style="font-size: 15px; color: #333; margin-bottom: 5px;">${activity.activityText || 'N/A'}</div>
                                    <div style="font-size: 13px; color: #666; display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
                                        ${activity.assignedBy ? '<span>👤 Assigned by: ' + activity.assignedBy + '</span>' : ''}
                                        ${activity.activityCount > 1 ? '<span style="background: #667eea; color: white; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: bold;">' + activity.activityCount + 'x Activities</span>' : ''}
                                        ${activity.activityIdentifier ? '<span>🏷️ ' + activity.activityIdentifier + '</span>' : ''}
                                    </div>
                                </div>
                                <div style="background: ${statusColor}; color: white; padding: 6px 12px; border-radius: 6px; font-size: 13px; white-space: nowrap;">
                                    ${statusText}
                                </div>
                            </div>
                        `;
                    });
                    
                    html += '</div></div>';
                });
                
                html += '</div>';
            }
            
            // Palak Melava Section
            if (data.palakMelavaData && data.palakMelavaData.length > 0) {
                html += `
                    <div style="margin-bottom: 30px;">
                        <h3 style="color: #667eea; border-bottom: 2px solid #667eea; padding-bottom: 10px; margin-bottom: 15px;">
                            <i class="fas fa-users"></i> Parent-Teacher Meetings
                        </h3>
                `;
                
                data.palakMelavaData.forEach((melava, index) => {
                    html += `
                        <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 10px; border-left: 4px solid #667eea;">
                            <strong>Meeting #${index + 1}</strong><br>
                            <strong>Date:</strong> ${melava.meetingDate || 'N/A'}<br>
                            <strong>Parents Attended:</strong> ${melava.totalParentsAttended || 'N/A'}<br>
                            <strong>Chief Guest/Attendee:</strong> ${melava.chiefAttendeeInfo || 'N/A'}
                        </div>
                    `;
                });
                
                html += '</div>';
            }
            
            document.getElementById('reportContent').innerHTML = html;
        }
    </script>
</body>
</html>
