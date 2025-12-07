<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.PalakMelavaDAO" %>
<%@ page import="com.vjnt.model.PalakMelava" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR) &&
                         !user.getUserType().equals(User.UserType.DIVISION))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    // Get parameters
    String udiseNo = request.getParameter("udise");
    String schoolName = request.getParameter("schoolName");
    
    if (udiseNo == null || udiseNo.isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/palak-melava-status.jsp");
        return;
    }
    
    PalakMelavaDAO palakMelavaDAO = new PalakMelavaDAO();
    List<PalakMelava> meetings = palakMelavaDAO.getByUdise(udiseNo);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Palak Melava Details - <%= schoolName %></title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f7fa;
        }
        
        .header {
            background: linear-gradient(135deg, #2196f3 0%, #1976d2 100%);
            color: white;
            padding: 25px 30px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            margin-bottom: 30px;
        }
        
        .header-content {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 20px;
        }
        
        .header h1 {
            font-size: 26px;
            color: white;
            margin: 0 0 8px 0;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .header-subtitle {
            font-size: 14px;
            color: rgba(255,255,255,0.9);
            margin: 0;
        }
        
        .btn {
            padding: 10px 18px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.3s;
            font-weight: 500;
            box-shadow: 0 2px 5px rgba(0,0,0,0.15);
            background: white;
            color: #2196f3;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0,0,0,0.25);
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 0 30px 30px 30px;
        }
        
        .breadcrumb {
            background: white;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
            font-size: 14px;
        }
        
        .meeting-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            border-left: 5px solid #2196f3;
        }
        
        .meeting-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #e0e0e0;
        }
        
        .meeting-title {
            font-size: 20px;
            font-weight: 700;
            color: #333;
        }
        
        .status-badge {
            padding: 8px 16px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
        }
        
        .status-draft {
            background: #9e9e9e;
            color: white;
        }
        
        .status-pending {
            background: #ff9800;
            color: white;
        }
        
        .status-approved {
            background: #4caf50;
            color: white;
        }
        
        .status-rejected {
            background: #f44336;
            color: white;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .info-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 6px;
        }
        
        .info-label {
            font-size: 12px;
            color: #666;
            margin-bottom: 5px;
            text-transform: uppercase;
            font-weight: 600;
        }
        
        .info-value {
            font-size: 16px;
            color: #333;
            font-weight: 500;
        }
        
        .photos-section {
            margin-top: 20px;
        }
        
        .photos-title {
            font-size: 16px;
            font-weight: 600;
            color: #333;
            margin-bottom: 15px;
        }
        
        .photos-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 15px;
        }
        
        .photo-item {
            text-align: center;
        }
        
        .photo-item img {
            max-width: 100%;
            height: auto;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.15);
            cursor: pointer;
            transition: transform 0.3s;
        }
        
        .photo-item img:hover {
            transform: scale(1.05);
        }
        
        .photo-label {
            margin-top: 10px;
            font-size: 13px;
            color: #666;
            font-weight: 500;
        }
        
        .no-data {
            text-align: center;
            padding: 60px 20px;
            color: #999;
            font-size: 18px;
        }
        
        .no-data-icon {
            font-size: 64px;
            margin-bottom: 15px;
        }
        
        .summary-box {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        
        .summary-title {
            font-size: 18px;
            font-weight: 700;
            margin-bottom: 15px;
        }
        
        .summary-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
        }
        
        .summary-stat {
            text-align: center;
        }
        
        .summary-stat-value {
            font-size: 32px;
            font-weight: 700;
        }
        
        .summary-stat-label {
            font-size: 13px;
            opacity: 0.9;
            margin-top: 5px;
        }
        
        @media (max-width: 768px) {
            .header-content {
                flex-direction: column;
                align-items: stretch;
            }
            
            .meeting-header {
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div>
                <h1>
                    <span style="font-size: 32px;">📋</span>
                    <span>Palak Melava Details</span>
                </h1>
                <p class="header-subtitle">
                    🏫 <%= schoolName %> | UDISE: <%= udiseNo %>
                </p>
            </div>
            <button onclick="window.close()" class="btn">
                <span>✕</span>
                <span>Close</span>
            </button>
        </div>
    </div>
    
    <div class="container">
        <!-- Breadcrumb -->
        <div class="breadcrumb">
            <span>District:</span> <strong><%= user.getDistrictName() %></strong>
            <span style="margin: 0 10px;">→</span>
            <span>School:</span> <strong><%= schoolName %></strong>
            <span style="margin: 0 10px;">→</span>
            <span><strong>Palak Melava Meetings</strong></span>
        </div>
        
        <% if (meetings != null && !meetings.isEmpty()) { %>
            <!-- Summary Box -->
            <div class="summary-box">
                <div class="summary-title">📊 Meeting Summary</div>
                <div class="summary-stats">
                    <div class="summary-stat">
                        <div class="summary-stat-value"><%= meetings.size() %></div>
                        <div class="summary-stat-label">Total Meetings</div>
                    </div>
                    <div class="summary-stat">
                        <div class="summary-stat-value">
                            <%= meetings.stream().filter(m -> "APPROVED".equals(m.getStatus())).count() %>
                        </div>
                        <div class="summary-stat-label">Approved</div>
                    </div>
                    <div class="summary-stat">
                        <div class="summary-stat-value">
                            <%= meetings.stream().filter(m -> "PENDING_APPROVAL".equals(m.getStatus())).count() %>
                        </div>
                        <div class="summary-stat-label">Pending</div>
                    </div>
                    <div class="summary-stat">
                        <div class="summary-stat-value">
                            <%= meetings.stream().mapToInt(m -> {
                                try {
                                    return Integer.parseInt(m.getTotalParentsAttended());
                                } catch (Exception e) {
                                    return 0;
                                }
                            }).sum() %>
                        </div>
                        <div class="summary-stat-label">Total Parents</div>
                    </div>
                </div>
            </div>
            
            <!-- Meeting Details -->
            <% 
            int meetingNo = 1;
            for (PalakMelava meeting : meetings) { 
                String status = meeting.getStatus();
                String statusClass = "";
                String statusLabel = "";
                
                if ("DRAFT".equals(status)) {
                    statusClass = "status-draft";
                    statusLabel = "Draft";
                } else if ("PENDING_APPROVAL".equals(status)) {
                    statusClass = "status-pending";
                    statusLabel = "Pending Approval";
                } else if ("APPROVED".equals(status)) {
                    statusClass = "status-approved";
                    statusLabel = "Approved";
                } else if ("REJECTED".equals(status)) {
                    statusClass = "status-rejected";
                    statusLabel = "Rejected";
                } else {
                    statusClass = "status-draft";
                    statusLabel = status != null ? status : "Unknown";
                }
            %>
            <div class="meeting-card">
                <div class="meeting-header">
                    <div class="meeting-title">
                        📅 Meeting #<%= meetingNo++ %>
                        <% if (meeting.getMeetingDate() != null) { %>
                            - <%= meeting.getMeetingDate() %>
                        <% } %>
                    </div>
                    <span class="status-badge <%= statusClass %>"><%= statusLabel %></span>
                </div>
                
                <div class="info-grid">
                    <div class="info-item">
                        <div class="info-label">📅 Meeting Date</div>
                        <div class="info-value">
                            <%= meeting.getMeetingDate() != null ? meeting.getMeetingDate() : "Not specified" %>
                        </div>
                    </div>
                    
                    <div class="info-item">
                        <div class="info-label">👥 Parents Attended</div>
                        <div class="info-value">
                            <%= meeting.getTotalParentsAttended() != null ? meeting.getTotalParentsAttended() : "0" %>
                        </div>
                    </div>
                    
                    <div class="info-item">
                        <div class="info-label">👨‍💼 Chief Attendee</div>
                        <div class="info-value">
                            <%= meeting.getChiefAttendeeInfo() != null ? meeting.getChiefAttendeeInfo() : "Not specified" %>
                        </div>
                    </div>
                    
                    <div class="info-item">
                        <div class="info-label">📝 Created By</div>
                        <div class="info-value">
                            <%= meeting.getCreatedBy() != null ? meeting.getCreatedBy() : "Unknown" %>
                        </div>
                    </div>
                </div>
                
                <% if ("APPROVED".equals(status) && meeting.getApprovedBy() != null) { %>
                    <div class="info-grid">
                        <div class="info-item">
                            <div class="info-label">✅ Approved By</div>
                            <div class="info-value"><%= meeting.getApprovedBy() %></div>
                        </div>
                        <div class="info-item">
                            <div class="info-label">📅 Approval Date</div>
                            <div class="info-value">
                                <%= meeting.getApprovalDate() != null ? meeting.getApprovalDate() : "-" %>
                            </div>
                        </div>
                        <% if (meeting.getApprovalRemarks() != null && !meeting.getApprovalRemarks().isEmpty()) { %>
                        <div class="info-item" style="grid-column: 1 / -1;">
                            <div class="info-label">💬 Approval Remarks</div>
                            <div class="info-value"><%= meeting.getApprovalRemarks() %></div>
                        </div>
                        <% } %>
                    </div>
                <% } %>
                
                <% if ("REJECTED".equals(status) && meeting.getRejectionReason() != null) { %>
                    <div class="info-grid">
                        <div class="info-item">
                            <div class="info-label">❌ Rejected By</div>
                            <div class="info-value"><%= meeting.getApprovedBy() != null ? meeting.getApprovedBy() : "Unknown" %></div>
                        </div>
                        <div class="info-item" style="grid-column: 1 / -1;">
                            <div class="info-label">📝 Rejection Reason</div>
                            <div class="info-value"><%= meeting.getRejectionReason() %></div>
                        </div>
                    </div>
                <% } %>
                
                <!-- Photos Section -->
                <div class="photos-section">
                    <div class="photos-title">📷 Meeting Photos</div>
                    <div class="photos-grid">
                        <% 
                        boolean hasPhoto1 = meeting.getPhoto1Content() != null && meeting.getPhoto1Content().length > 0;
                        boolean hasPhoto2 = meeting.getPhoto2Content() != null && meeting.getPhoto2Content().length > 0;
                        
                        if (hasPhoto1 || hasPhoto2) {
                            if (hasPhoto1) { %>
                                <div class="photo-item">
                                    <img src="<%= request.getContextPath() %>/palak-melava-image-db?id=<%= meeting.getMelavaId() %>&photo=1" 
                                         alt="Photo 1"
                                         onclick="window.open(this.src, '_blank')"
                                         onerror="this.onerror=null; this.src='data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22300%22 height=%22200%22%3E%3Crect width=%22300%22 height=%22200%22 fill=%22%23f0f0f0%22/%3E%3Ctext x=%2250%25%22 y=%2250%25%22 dominant-baseline=%22middle%22 text-anchor=%22middle%22 font-family=%22Arial%22 font-size=%2216%22 fill=%22%23999%22%3EPhoto not available%3C/text%3E%3C/svg%3E';">
                                    <div class="photo-label">Photo 1</div>
                                </div>
                            <% }
                            if (hasPhoto2) { %>
                                <div class="photo-item">
                                    <img src="<%= request.getContextPath() %>/palak-melava-image-db?id=<%= meeting.getMelavaId() %>&photo=2" 
                                         alt="Photo 2"
                                         onclick="window.open(this.src, '_blank')"
                                         onerror="this.onerror=null; this.src='data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22300%22 height=%22200%22%3E%3Crect width=%22300%22 height=%22200%22 fill=%22%23f0f0f0%22/%3E%3Ctext x=%2250%25%22 y=%2250%25%22 dominant-baseline=%22middle%22 text-anchor=%22middle%22 font-family=%22Arial%22 font-size=%2216%22 fill=%22%23999%22%3EPhoto not available%3C/text%3E%3C/svg%3E';">
                                    <div class="photo-label">Photo 2</div>
                                </div>
                            <% }
                        } else { %>
                            <div style="grid-column: 1 / -1; text-align: center; padding: 20px; color: #999;">
                                📷 No photos uploaded for this meeting
                            </div>
                        <% } %>
                    </div>
                </div>
            </div>
            <% } %>
            
        <% } else { %>
            <div class="meeting-card">
                <div class="no-data">
                    <div class="no-data-icon">📭</div>
                    <div>No Palak Melava meetings found for this school</div>
                </div>
            </div>
        <% } %>
    </div>
</body>
</html>
