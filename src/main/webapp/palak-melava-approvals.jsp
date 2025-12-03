<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.PalakMelavaDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.PalakMelava" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.HEAD_MASTER)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String udiseNo = user.getUdiseNo();
    SchoolDAO schoolDAO = new SchoolDAO();
    School school = schoolDAO.getSchoolByUdise(udiseNo);
    String schoolName = school != null ? school.getSchoolName() : "Unknown School";
    
    PalakMelavaDAO melavaDAO = new PalakMelavaDAO();
    List<PalakMelava> pendingList = melavaDAO.getPendingApprovals(udiseNo);
    List<PalakMelava> allList = melavaDAO.getByUdise(udiseNo);
    
    // Filter approved and rejected
    List<PalakMelava> approvedList = new ArrayList<>();
    List<PalakMelava> rejectedList = new ArrayList<>();
    for (PalakMelava m : allList) {
        if (m.isApproved()) approvedList.add(m);
        if (m.isRejected()) rejectedList.add(m);
    }
    
    SimpleDateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy");
    SimpleDateFormat fullDateFormat = new SimpleDateFormat("dd-MMM-yyyy hh:mm a");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>पालक मेळावा मंजूरी - Palak Melava Approvals</title>
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
            padding: 15px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            padding: 20px;
        }
        
        .header {
            background: #f0f2f5;
            color: #000;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            font-size: 26px;
            margin-bottom: 5px;
            color: #000;
        }
        
        .header-subtitle {
            font-size: 14px;
            opacity: 1;
            color: #000;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            font-size: 14px;
            transition: all 0.3s;
            font-weight: 600;
        }
        
        .btn-success {
            background: #4caf50;
            color: white;
        }
        
        .btn-success:hover {
            background: #45a049;
        }
        
        .btn-danger {
            background: #f44336;
            color: white;
        }
        
        .btn-danger:hover {
            background: #da190b;
        }
        
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        
        .btn-secondary:hover {
            background: #5a6268;
        }
        
        .tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            border-bottom: 2px solid #ddd;
        }
        
        .tab {
            padding: 15px 30px;
            cursor: pointer;
            border: none;
            background: none;
            font-size: 16px;
            font-weight: 600;
            color: #666;
            border-bottom: 3px solid transparent;
            transition: all 0.3s;
        }
        
        .tab:hover {
            color: #333;
            background: #f8f9fa;
        }
        
        .tab.active {
            color: #ff9800;
            border-bottom-color: #ff9800;
        }
        
        .tab-content {
            display: none;
        }
        
        .tab-content.active {
            display: block;
        }
        
        .section {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        
        .section-title {
            font-size: 20px;
            color: #333;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #ff9800;
        }
        
        .cards-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        
        .card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-left: 5px solid #ff9800;
        }
        
        .card.approved {
            border-left-color: #4caf50;
        }
        
        .card.rejected {
            border-left-color: #f44336;
        }
        
        .card-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #f0f0f0;
        }
        
        .card-title {
            font-size: 18px;
            font-weight: 700;
            color: #333;
        }
        
        .card-body {
            font-size: 14px;
            color: #555;
        }
        
        .card-info {
            margin: 8px 0;
            display: flex;
            gap: 10px;
        }
        
        .card-info-label {
            font-weight: 600;
            color: #333;
            min-width: 140px;
        }
        
        .card-info-value {
            color: #666;
            flex: 1;
        }
        
        .status-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .status-pending {
            background: #fff3e0;
            color: #e65100;
        }
        
        .status-approved {
            background: #c8e6c9;
            color: #2e7d32;
        }
        
        .status-rejected {
            background: #ffcdd2;
            color: #c62828;
        }
        
        .card-actions {
            display: flex;
            gap: 10px;
            margin-top: 15px;
            padding-top: 15px;
            border-top: 2px solid #f0f0f0;
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
        
        .badge-count {
            background: #f44336;
            color: white;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 12px;
            margin-left: 8px;
        }
        
        .photo-thumbnail {
            max-width: 200px;
            max-height: 200px;
            width: 100%;
            object-fit: cover;
            border-radius: 8px;
            margin: 10px 5px;
            cursor: pointer;
            border: 3px solid #ddd;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
        }
        
        .photo-thumbnail:hover {
            border-color: #ff9800;
            transform: scale(1.05);
            box-shadow: 0 4px 10px rgba(0,0,0,0.2);
        }
        
        .photos-container {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-top: 10px;
        }
        
        .photo-label {
            font-weight: bold;
            color: #666;
            margin-top: 10px;
            display: block;
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
            overflow-y: auto;
        }
        
        .modal-content {
            background: white;
            margin: 50px auto;
            padding: 0;
            border-radius: 15px;
            max-width: 600px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
        }
        
        .modal-header {
            background: linear-gradient(135deg, #ff9800 0%, #ff5722 100%);
            color: white;
            padding: 20px;
            border-radius: 15px 15px 0 0;
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
            color: #f0f0f0;
        }
        
        .modal-body {
            padding: 30px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
        }
        
        .form-group textarea {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
            min-height: 100px;
            resize: vertical;
        }
        
        .approval-info {
            background: #e8f5e9;
            padding: 15px;
            border-radius: 8px;
            margin-top: 10px;
            border-left: 4px solid #4caf50;
        }
        
        .rejection-info {
            background: #ffebee;
            padding: 15px;
            border-radius: 8px;
            margin-top: 10px;
            border-left: 4px solid #f44336;
        }
        
        .show {
            display: block !important;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div>
                <h1>✅ पालक मेळावा मंजूरी</h1>
                <div class="header-subtitle">Palak Melava Approval Management - Head Master</div>
                <div class="header-subtitle"><%= schoolName %> (UDISE: <%= udiseNo %>)</div>
            </div>
            <div>
                <a href="school-dashboard-enhanced.jsp" class="btn btn-secondary">🏠 Dashboard</a>
            </div>
        </div>
        
        <!-- Tabs -->
        <div class="tabs">
            <button class="tab active" onclick="showTab('pending')">
                ⏳ मंजुरी प्रलंबित (Pending) 
                <% if (pendingList.size() > 0) { %>
                <span class="badge-count"><%= pendingList.size() %></span>
                <% } %>
            </button>
            <button class="tab" onclick="showTab('approved')">
                ✅ मंजूर (Approved) <%= approvedList.size() %>
            </button>
            <button class="tab" onclick="showTab('rejected')">
                ❌ नाकारलेले (Rejected) <%= rejectedList.size() %>
            </button>
        </div>
        
        <!-- Pending Tab -->
        <div id="pending-tab" class="tab-content active">
            <div class="section">
                <h2 class="section-title">⏳ मंजुरीसाठी प्रलंबित (Pending Approvals)</h2>
                
                <% if (pendingList.isEmpty()) { %>
                <div class="empty-state">
                    <div class="empty-state-icon">✅</div>
                    <h3>सर्व मंजूर झाले आहेत!</h3>
                    <p>मंजुरीसाठी कोणतीही नोंद प्रलंबित नाही.</p>
                </div>
                <% } else { %>
                <div class="cards-grid">
                    <% for (PalakMelava melava : pendingList) { %>
                    <div class="card">
                        <div class="card-header">
                            <div class="card-title">📅 <%= sdf.format(melava.getMeetingDate()) %></div>
                            <span class="status-badge status-pending">⏳ प्रलंबित</span>
                        </div>
                        <div class="card-body">
                            <div class="card-info">
                                <span class="card-info-label">उपस्थित पालक:</span>
                                <span class="card-info-value"><%= melava.getTotalParentsAttended() %></span>
                            </div>
                            <div class="card-info">
                                <span class="card-info-label">प्रमुख उपस्थिती:</span>
                                <span class="card-info-value"><%= melava.getChiefAttendeeInfo() %></span>
                            </div>
                            <% if (melava.getSubmittedBy() != null) { %>
                            <div class="card-info">
                                <span class="card-info-label">सबमिट केले:</span>
                                <span class="card-info-value"><%= melava.getSubmittedBy() %> 
                                (<%= fullDateFormat.format(melava.getSubmittedDate()) %>)</span>
                            </div>
                            <% } %>
                            
                            <% if (melava.getPhoto1Path() != null || melava.getPhoto2Path() != null) { %>
                            <div class="card-info">
                                <span class="photo-label">📷 फोटो (Photos):</span>
                                <div class="photos-container">
                                    <% 
                                        String photo1Path = melava.getPhoto1Path();
                                        String photo2Path = melava.getPhoto2Path();
                                        System.out.println("DEBUG: Melava ID=" + melava.getMelavaId() + 
                                                         ", Photo1Path=" + photo1Path + 
                                                         ", Photo2Path=" + photo2Path);
                                    %>
                                    <% if (photo1Path != null && !photo1Path.trim().isEmpty()) { %>
                                    <img src="<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melava.getMelavaId() %>&photo=1" 
                                         class="photo-thumbnail" alt="Photo 1" 
                                         data-melava-id="<%= melava.getMelavaId() %>"
                                         data-photo-num="1"
                                         data-file-path="<%= java.net.URLEncoder.encode(photo1Path, "UTF-8") %>"
                                         onclick="viewPhoto('<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melava.getMelavaId() %>&photo=1')"
                                         title="फोटो १ - Click to view full size"
                                         onerror="loadPhotoFallback(this);"
                                         onload="console.log('Photo 1 loaded successfully from database');">
                                    <% } else { %>
                                    <div style="padding: 20px; background: #f0f0f0; border-radius: 5px; text-align: center; color: #999; min-width: 150px;">
                                        📷 Photo 1 not available
                                    </div>
                                    <% } %>
                                    <% if (photo2Path != null && !photo2Path.trim().isEmpty()) { %>
                                    <img src="<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melava.getMelavaId() %>&photo=2" 
                                         class="photo-thumbnail" alt="Photo 2"
                                         data-melava-id="<%= melava.getMelavaId() %>"
                                         data-photo-num="2"
                                         data-file-path="<%= java.net.URLEncoder.encode(photo2Path, "UTF-8") %>"
                                         onclick="viewPhoto('<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melava.getMelavaId() %>&photo=2')"
                                         title="फोटो २ - Click to view full size"
                                         onerror="loadPhotoFallback(this);"
                                         onload="console.log('Photo 2 loaded successfully from database');">
                                    <% } else { %>
                                    <div style="padding: 20px; background: #f0f0f0; border-radius: 5px; text-align: center; color: #999; min-width: 150px;">
                                        📷 Photo 2 not available
                                    </div>
                                    <% } %>
                                </div>
                            </div>
                            <% } %>
                            
                            <div class="card-actions">
                                <button class="btn btn-success" onclick="approveMelava(<%= melava.getMelavaId() %>)">
                                    ✓ मंजूर करा (Approve)
                                </button>
                                <button class="btn btn-danger" onclick="rejectMelava(<%= melava.getMelavaId() %>)">
                                    ✗ नाकारा (Reject)
                                </button>
                            </div>
                        </div>
                    </div>
                    <% } %>
                </div>
                <% } %>
            </div>
        </div>
        
        <!-- Approved Tab -->
        <div id="approved-tab" class="tab-content">
            <div class="section">
                <h2 class="section-title">✅ मंजूर झालेले (Approved Records)</h2>
                
                <% if (approvedList.isEmpty()) { %>
                <div class="empty-state">
                    <div class="empty-state-icon">📭</div>
                    <h3>कोणतीही मंजूर नोंद नाही</h3>
                </div>
                <% } else { %>
                <div class="cards-grid">
                    <% for (PalakMelava melava : approvedList) { %>
                    <div class="card approved">
                        <div class="card-header">
                            <div class="card-title">📅 <%= sdf.format(melava.getMeetingDate()) %></div>
                            <span class="status-badge status-approved">✓ मंजूर</span>
                        </div>
                        <div class="card-body">
                            <div class="card-info">
                                <span class="card-info-label">उपस्थित पालक:</span>
                                <span class="card-info-value"><%= melava.getTotalParentsAttended() %></span>
                            </div>
                            <div class="card-info">
                                <span class="card-info-label">प्रमुख उपस्थिती:</span>
                                <span class="card-info-value"><%= melava.getChiefAttendeeInfo() %></span>
                            </div>
                            <% if (melava.getApprovedBy() != null) { %>
                            <div class="approval-info">
                                <strong>✓ मंजूर केले:</strong> <%= melava.getApprovedBy() %><br>
                                <strong>तारीख:</strong> <%= fullDateFormat.format(melava.getApprovalDate()) %>
                                <% if (melava.getApprovalRemarks() != null && !melava.getApprovalRemarks().isEmpty()) { %>
                                <br><strong>शेरा:</strong> <%= melava.getApprovalRemarks() %>
                                <% } %>
                            </div>
                            <% } %>
                            
                            <% if (melava.getPhoto1Path() != null || melava.getPhoto2Path() != null) { %>
                            <div class="card-info">
                                <span class="photo-label">📷 फोटो:</span>
                                <div class="photos-container">
                                    <% if (melava.getPhoto1Path() != null) { %>
                                    <img src="<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melava.getMelavaId() %>&photo=1" 
                                         class="photo-thumbnail" alt="Photo 1" 
                                         data-melava-id="<%= melava.getMelavaId() %>"
                                         data-photo-num="1"
                                         data-file-path="<%= java.net.URLEncoder.encode(melava.getPhoto1Path(), "UTF-8") %>"
                                         onclick="viewPhoto('<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melava.getMelavaId() %>&photo=1')"
                                         title="Click to view full size"
                                         onerror="loadPhotoFallback(this);">
                                    <% } %>
                                    <% if (melava.getPhoto2Path() != null) { %>
                                    <img src="<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melava.getMelavaId() %>&photo=2" 
                                         class="photo-thumbnail" alt="Photo 2"
                                         data-melava-id="<%= melava.getMelavaId() %>"
                                         data-photo-num="2"
                                         data-file-path="<%= java.net.URLEncoder.encode(melava.getPhoto2Path(), "UTF-8") %>"
                                         onclick="viewPhoto('<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melava.getMelavaId() %>&photo=2')"
                                         title="Click to view full size"
                                         onerror="loadPhotoFallback(this);">
                                    <% } %>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>
                    <% } %>
                </div>
                <% } %>
            </div>
        </div>
        
        <!-- Rejected Tab -->
        <div id="rejected-tab" class="tab-content">
            <div class="section">
                <h2 class="section-title">❌ नाकारलेले (Rejected Records)</h2>
                
                <% if (rejectedList.isEmpty()) { %>
                <div class="empty-state">
                    <div class="empty-state-icon">📭</div>
                    <h3>कोणतीही नाकारलेली नोंद नाही</h3>
                </div>
                <% } else { %>
                <div class="cards-grid">
                    <% for (PalakMelava melava : rejectedList) { %>
                    <div class="card rejected">
                        <div class="card-header">
                            <div class="card-title">📅 <%= sdf.format(melava.getMeetingDate()) %></div>
                            <span class="status-badge status-rejected">✗ नाकारले</span>
                        </div>
                        <div class="card-body">
                            <div class="card-info">
                                <span class="card-info-label">उपस्थित पालक:</span>
                                <span class="card-info-value"><%= melava.getTotalParentsAttended() %></span>
                            </div>
                            <div class="card-info">
                                <span class="card-info-label">प्रमुख उपस्थिती:</span>
                                <span class="card-info-value"><%= melava.getChiefAttendeeInfo() %></span>
                            </div>
                            <% if (melava.getApprovedBy() != null) { %>
                            <div class="rejection-info">
                                <strong>✗ नाकारले:</strong> <%= melava.getApprovedBy() %><br>
                                <strong>तारीख:</strong> <%= fullDateFormat.format(melava.getApprovalDate()) %>
                                <% if (melava.getRejectionReason() != null && !melava.getRejectionReason().isEmpty()) { %>
                                <br><strong>कारण:</strong> <%= melava.getRejectionReason() %>
                                <% } %>
                            </div>
                            <% } %>
                            
                            <% if (melava.getPhoto1Path() != null || melava.getPhoto2Path() != null) { %>
                            <div class="card-info">
                                <span class="photo-label">📷 फोटो:</span>
                                <div class="photos-container">
                                    <% if (melava.getPhoto1Path() != null) { %>
                                    <img src="<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melava.getMelavaId() %>&photo=1" 
                                         class="photo-thumbnail" alt="Photo 1" 
                                         data-melava-id="<%= melava.getMelavaId() %>"
                                         data-photo-num="1"
                                         data-file-path="<%= java.net.URLEncoder.encode(melava.getPhoto1Path(), "UTF-8") %>"
                                         onclick="viewPhoto('<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melava.getMelavaId() %>&photo=1')"
                                         title="Click to view full size"
                                         onerror="loadPhotoFallback(this);">
                                    <% } %>
                                    <% if (melava.getPhoto2Path() != null) { %>
                                    <img src="<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melava.getMelavaId() %>&photo=2" 
                                         class="photo-thumbnail" alt="Photo 2"
                                         data-melava-id="<%= melava.getMelavaId() %>"
                                         data-photo-num="2"
                                         data-file-path="<%= java.net.URLEncoder.encode(melava.getPhoto2Path(), "UTF-8") %>"
                                         onclick="viewPhoto('<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melava.getMelavaId() %>&photo=2')"
                                         title="Click to view full size"
                                         onerror="loadPhotoFallback(this);">
                                    <% } %>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>
                    <% } %>
                </div>
                <% } %>
            </div>
        </div>
    </div>
    
    <!-- Approval Modal -->
    <div id="approvalModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>✓ मंजूर करा (Approve)</h2>
                <span class="close" onclick="closeModal('approvalModal')">&times;</span>
            </div>
            <div class="modal-body">
                <form id="approvalForm">
                    <input type="hidden" id="approveMelavaId" name="melavaId">
                    <input type="hidden" name="action" value="approve">
                    
                    <div class="form-group">
                        <label for="approvalRemarks">शेरा / Remarks (Optional)</label>
                        <textarea id="approvalRemarks" name="remarks" 
                                  placeholder="उदा. चांगले आयोजन केले आहे..."></textarea>
                    </div>
                    
                    <div style="display: flex; gap: 10px; justify-content: flex-end;">
                        <button type="button" class="btn btn-secondary" onclick="closeModal('approvalModal')">रद्द करा</button>
                        <button type="submit" class="btn btn-success">✓ मंजूर करा</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <!-- Rejection Modal -->
    <div id="rejectionModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>✗ नाकारा (Reject)</h2>
                <span class="close" onclick="closeModal('rejectionModal')">&times;</span>
            </div>
            <div class="modal-body">
                <form id="rejectionForm">
                    <input type="hidden" id="rejectMelavaId" name="melavaId">
                    <input type="hidden" name="action" value="reject">
                    
                    <div class="form-group">
                        <label for="rejectionReason">नाकारण्याचे कारण / Rejection Reason *</label>
                        <textarea id="rejectionReason" name="remarks" required
                                  placeholder="कृपया नाकारण्याचे कारण लिहा..."></textarea>
                    </div>
                    
                    <div style="display: flex; gap: 10px; justify-content: flex-end;">
                        <button type="button" class="btn btn-secondary" onclick="closeModal('rejectionModal')">रद्द करा</button>
                        <button type="submit" class="btn btn-danger">✗ नाकारा</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <!-- Photo Viewer Modal -->
    <div id="photoModal" class="modal" onclick="closePhotoModal()">
        <div class="modal-content" style="max-width: 90%; text-align: center;" onclick="event.stopPropagation()">
            <div class="modal-header">
                <h2>📷 फोटो (Photo)</h2>
                <span class="close" onclick="closePhotoModal()">&times;</span>
            </div>
            <div class="modal-body">
                <img id="modalPhoto" src="" style="max-width: 100%; max-height: 80vh; border-radius: 8px;">
            </div>
        </div>
    </div>
    
    <script>
        function loadPhotoFallback(imgElement) {
            const melavaId = imgElement.dataset.melavaId;
            const photoNum = imgElement.dataset.photoNum;
            const filePath = imgElement.dataset.filePath;
            
            console.log('Database image failed, trying file system fallback for melava:', melavaId, 'photo:', photoNum);
            
            if (filePath) {
                // Try file system as fallback
                const fileUrl = '<%= request.getContextPath() %>/palak-melava-image?path=' + filePath;
                
                imgElement.onerror = function() {
                    console.error('Both database and file system failed for photo:', photoNum);
                    this.style.display = 'none';
                    if (this.parentElement) {
                        this.parentElement.innerHTML = '<div style="padding: 20px; background: #f0f0f0; border-radius: 5px; text-align: center; color: #999;">📷 Photo ' + photoNum + ' N/A</div>';
                    }
                };
                
                imgElement.src = fileUrl;
            } else {
                console.error('No fallback available');
                imgElement.style.display = 'none';
            }
        }
        
        function loadPhotoFromDB(imgElement) {
            const melavaId = imgElement.dataset.melavaId;
            const photoNum = imgElement.dataset.photoNum;
            
            if (!melavaId || !photoNum) {
                console.error('Missing melava ID or photo number');
                imgElement.style.display = 'none';
                return;
            }
            
            console.log('File system failed, attempting database fallback for melava:', melavaId, 'photo:', photoNum);
            
            // Try loading from database
            const dbUrl = '<%= request.getContextPath() %>/palak-melava-image-db?id=' + melavaId + '&photo=' + photoNum;
            
            imgElement.onerror = function() {
                console.error('Database fallback also failed:', dbUrl);
                this.style.display = 'none';
                this.parentElement.innerHTML = '<div style="padding: 20px; background: #f0f0f0; border-radius: 5px; text-align: center; color: #999;">📷 Photo ' + photoNum + ' N/A</div>';
            };
            
            imgElement.onload = function() {
                console.log('Photo ' + photoNum + ' loaded successfully from database');
            };
            
            imgElement.src = dbUrl;
        }
        
        function viewPhoto(photoUrl) {
            console.log('Opening photo modal with URL:', photoUrl);
            const modalImg = document.getElementById('modalPhoto');
            const photoModal = document.getElementById('photoModal');
            
            // Reset image state
            modalImg.style.display = 'block';
            modalImg.dataset.originalUrl = photoUrl;
            modalImg.dataset.fallbackTried = 'false';
            
            // Remove previous error/load handlers
            modalImg.onerror = null;
            modalImg.onload = null;
            
            // Set up new error handler with fallback
            modalImg.onerror = function() {
                const fallbackTried = this.dataset.fallbackTried === 'true';
                console.error('Failed to load photo from:', this.src);
                
                if (!fallbackTried) {
                    console.log('Attempting fallback...');
                    this.dataset.fallbackTried = 'true';
                    
                    // If it was a database URL, try file system
                    if (photoUrl.includes('palak-melava-image-db')) {
                        // Extract the photo number and try to find file path
                        const photoNum = photoUrl.match(/photo=(\d+)/)?.[1];
                        if (photoNum) {
                            // Try to get file path from the clicked image element
                            const clickedImg = document.querySelector('[data-photo-num="' + photoNum + '"]');
                            if (clickedImg && clickedImg.dataset.filePath) {
                                const fallbackUrl = '<%= request.getContextPath() %>/palak-melava-image?path=' + clickedImg.dataset.filePath;
                                console.log('Trying fallback URL:', fallbackUrl);
                                this.src = fallbackUrl;
                                return;
                            }
                        }
                    }
                }
                
                // All fallbacks exhausted
                console.error('Unable to load photo from any source');
                this.style.display = 'none';
                alert('Unable to load the full image. Photo may not be available.');
            };
            
            // Set up load handler
            modalImg.onload = function() {
                console.log('✓ Photo loaded successfully in modal');
                this.style.display = 'block';
            };
            
            // Load the image
            modalImg.src = photoUrl;
            
            // Show the modal
            photoModal.style.display = 'block';
        }
        
        function closePhotoModal() {
            document.getElementById('photoModal').style.display = 'none';
        }
        
        function showTab(tabName) {
            // Hide all tabs
            document.querySelectorAll('.tab-content').forEach(tab => {
                tab.classList.remove('active');
            });
            document.querySelectorAll('.tab').forEach(tab => {
                tab.classList.remove('active');
            });
            
            // Show selected tab
            document.getElementById(tabName + '-tab').classList.add('active');
            event.target.classList.add('active');
        }
        
        function approveMelava(melavaId) {
            document.getElementById('approveMelavaId').value = melavaId;
            document.getElementById('approvalModal').style.display = 'block';
        }
        
        function rejectMelava(melavaId) {
            document.getElementById('rejectMelavaId').value = melavaId;
            document.getElementById('rejectionModal').style.display = 'block';
        }
        
        function closeModal(modalId) {
            document.getElementById(modalId).style.display = 'none';
        }
        
        document.getElementById('approvalForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new URLSearchParams(new FormData(this));
            
            fetch('<%= request.getContextPath() %>/palak-melava-approval', {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ यशस्वीपणे मंजूर केले!');
                    closeModal('approvalModal');
                    location.reload();
                } else {
                    alert('✗ त्रुटी: ' + data.message);
                }
            })
            .catch(error => {
                alert('✗ त्रुटी: ' + error);
            });
        });
        
        document.getElementById('rejectionForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new URLSearchParams(new FormData(this));
            
            fetch('<%= request.getContextPath() %>/palak-melava-approval', {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ यशस्वीपणे नाकारले!');
                    closeModal('rejectionModal');
                    location.reload();
                } else {
                    alert('✗ त्रुटी: ' + data.message);
                }
            })
            .catch(error => {
                alert('✗ त्रुटी: ' + error);
            });
        });
        
        // Close modal on outside click
        window.onclick = function(event) {
            if (event.target.classList.contains('modal')) {
                event.target.style.display = 'none';
            }
        }
    </script>
</body>
</html>
