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
    if (user == null || !user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String udiseNo = user.getUdiseNo();
    SchoolDAO schoolDAO = new SchoolDAO();
    School school = schoolDAO.getSchoolByUdise(udiseNo);
    String schoolName = school != null ? school.getSchoolName() : "Unknown School";
    
    PalakMelavaDAO melavaDAO = new PalakMelavaDAO();
    List<PalakMelava> melavaList = melavaDAO.getByUdise(udiseNo);
    
    SimpleDateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>पालक मेळावा व्यवस्थापन - Palak Melava Management</title>
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
        }
        
        .btn-primary {
            background: #43e97b;
            color: white;
        }
        
        .btn-primary:hover {
            background: #38d66e;
        }
        
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        
        .btn-secondary:hover {
            background: #5a6268;
        }
        
        .btn-danger {
            background: #dc3545;
            color: white;
        }
        
        .btn-warning {
            background: #ffc107;
            color: #333;
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
            border-bottom: 2px solid #43e97b;
        }
        
        .cards-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        
        .card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            transition: transform 0.3s;
        }
        
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.15);
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
            font-size: 16px;
            font-weight: 600;
            color: #333;
        }
        
        .card-date {
            font-size: 14px;
            color: #666;
        }
        
        .card-body {
            font-size: 14px;
            color: #555;
        }
        
        .card-info {
            margin: 10px 0;
        }
        
        .card-info strong {
            color: #333;
        }
        
        .status-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .status-draft {
            background: #e0e0e0;
            color: #666;
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
        }
        
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            overflow-y: auto;
        }
        
        .modal-content {
            background: white;
            margin: 50px auto;
            padding: 0;
            border-radius: 15px;
            max-width: 800px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
        }
        
        .modal-header {
            background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
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
        
        .form-group input,
        .form-group textarea,
        .form-group select {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
        }
        
        .form-group textarea {
            min-height: 100px;
            resize: vertical;
        }
        
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
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
        
        .photo-preview {
            max-width: 200px;
            max-height: 200px;
            margin-top: 10px;
            border-radius: 5px;
            border: 2px solid #ddd;
        }
        
        .view-details-modal-content {
            background: white;
            margin: 50px auto;
            padding: 0;
            border-radius: 15px;
            max-width: 900px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
        }
        
        .view-details-header {
            background: linear-gradient(135deg, #4caf50 0%, #45a049 100%);
            color: white;
            padding: 25px;
            border-radius: 15px 15px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .view-details-header h2 {
            margin: 0;
            font-size: 24px;
        }
        
        .details-container {
            padding: 30px;
        }
        
        .details-section {
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #f0f0f0;
        }
        
        .details-section:last-child {
            border-bottom: none;
        }
        
        .section-heading {
            font-size: 18px;
            font-weight: 700;
            color: #333;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 3px solid #4caf50;
            display: inline-block;
        }
        
        .details-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 15px;
        }
        
        .detail-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #4caf50;
        }
        
        .detail-label {
            font-size: 12px;
            color: #999;
            font-weight: 700;
            text-transform: uppercase;
            margin-bottom: 5px;
        }
        
        .detail-value {
            font-size: 15px;
            color: #333;
            font-weight: 600;
        }
        
        .photos-section {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-top: 15px;
        }
        
        .photo-container {
            text-align: center;
        }
        
        .photo-label {
            font-size: 14px;
            font-weight: 600;
            color: #333;
            margin-bottom: 10px;
        }
        
        .photo-image {
            max-width: 100%;
            max-height: 300px;
            border-radius: 8px;
            border: 2px solid #ddd;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        .approval-info {
            background: linear-gradient(135deg, #c8e6c9 0%, #a5d6a7 100%);
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #4caf50;
            margin-top: 15px;
        }
        
        .approval-info strong {
            color: #2e7d32;
        }
        
        .close-details {
            color: white;
            font-size: 32px;
            font-weight: bold;
            cursor: pointer;
            line-height: 1;
        }
        
        .close-details:hover {
            color: #f0f0f0;
        }
        
        .details-actions {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
            margin-top: 20px;
            padding-top: 20px;
            border-top: 2px solid #f0f0f0;
        }
        
        .btn-close-details {
            background: #6c757d;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .btn-close-details:hover {
            background: #5a6268;
        }
        
        .btn-download-details {
            background: #4caf50;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .btn-download-details:hover {
            background: #45a049;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div>
                <h1>👥 पालक मेळावा व्यवस्थापन</h1>
                <div class="header-subtitle">Palak Melava (Parent-Teacher Meeting) Management</div>
                <div class="header-subtitle"><%= schoolName %> (UDISE: <%= udiseNo %>)</div>
            </div>
            <div>
                <button class="btn btn-primary" onclick="openAddModal()">➕ नवीन मेळावा जोडा</button>
                <a href="school-dashboard-enhanced.jsp" class="btn btn-secondary">🏠 Dashboard</a>
            </div>
        </div>
        
        <!-- Records Section -->
        <div class="section">
            <h2 class="section-title">📋 पालक मेळावा नोंदी (All Records)</h2>
            
            <% if (melavaList.isEmpty()) { %>
            <div class="empty-state">
                <div class="empty-state-icon">📭</div>
                <h3>कोणतीही नोंद नाही</h3>
                <p>पालक मेळावा जोडण्यासाठी वरील "नवीन मेळावा जोडा" बटण दाबा</p>
            </div>
            <% } else { %>
            <div class="cards-grid">
                <% for (PalakMelava melava : melavaList) { 
                    String statusClass = melava.isDraft() ? "status-draft" : 
                                       melava.isPending() ? "status-pending" :
                                       melava.isApproved() ? "status-approved" : "status-rejected";
                    String statusText = melava.isDraft() ? "मसुदा (Draft)" : 
                                      melava.isPending() ? "मंजुरीसाठी प्रलंबित" :
                                      melava.isApproved() ? "मंजूर (Approved)" : "नाकारले (Rejected)";
                %>
                <div class="card">
                    <div class="card-header">
                        <div class="card-title">📅 <%= sdf.format(melava.getMeetingDate()) %></div>
                        <span class="status-badge <%= statusClass %>"><%= statusText %></span>
                    </div>
                    <div class="card-body">
                        <div class="card-info">
                            <strong>उपस्थित पालक:</strong> <%= melava.getTotalParentsAttended() %>
                        </div>
                        <div class="card-info">
                            <strong>प्रमुख उपस्थिती:</strong> <%= melava.getChiefAttendeeInfo() != null && melava.getChiefAttendeeInfo().length() > 60 ? 
                                                        melava.getChiefAttendeeInfo().substring(0, 60) + "..." : 
                                                        (melava.getChiefAttendeeInfo() != null ? melava.getChiefAttendeeInfo() : "N/A") %>
                        </div>
                        
                        <% if (melava.isRejected() && melava.getRejectionReason() != null) { %>
                        <div class="card-info" style="color: #c62828; margin-top: 10px;">
                            <strong>नाकारण्याचे कारण:</strong> <%= melava.getRejectionReason() %>
                        </div>
                        <% } %>
                        
                        <% if (melava.isApproved() && melava.getApprovalRemarks() != null) { %>
                        <div class="card-info" style="color: #2e7d32; margin-top: 10px;">
                            <strong>शेरा:</strong> <%= melava.getApprovalRemarks() %>
                        </div>
                        <% } %>
                        
                        <div class="card-actions">
                            <% if (melava.isDraft() || melava.isRejected()) { %>
                            <button class="btn btn-primary" onclick="editMelava(<%= melava.getMelavaId() %>)">✏️ संपादित करा</button>
                            <button class="btn btn-warning" onclick="submitForApproval(<%= melava.getMelavaId() %>)">📤 मंजुरीसाठी सबमिट</button>
                            <button class="btn btn-danger" onclick="deleteMelava(<%= melava.getMelavaId() %>)">🗑️ हटवा</button>
                            <% } else if (melava.isPending()) { %>
                            <button class="btn btn-secondary" disabled>⏳ मंजुरी प्रलंबित</button>
                            <% } else if (melava.isApproved()) { %>
                            <button class="btn" style="background: #4caf50; color: white;" onclick="viewApprovedDetails(<%= melava.getMelavaId() %>)">👁️ सर्व तपशील पहा</button>
                            <% } %>
                        </div>
                    </div>
                </div>
                <% } %>
            </div>
            <% } %>
        </div>
    </div>
    
    <!-- Add/Edit Modal -->
    <div id="melavaModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2 id="modalTitle">➕ नवीन पालक मेळावा जोडा</h2>
                <span class="close" onclick="closeModal()">&times;</span>
            </div>
            <div class="modal-body">
                <form id="melavaForm" enctype="multipart/form-data">
                    <input type="hidden" id="melavaId" name="melavaId">
                    <input type="hidden" name="action" id="formAction" value="add">
                    
                    <div class="form-group">
                        <label for="meetingDate">पालक मेळावा घेतल्याची दिनांक *</label>
                        <input type="date" id="meetingDate" name="meetingDate" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="chiefAttendeeInfo">प्रमुख उपस्थिती कोणाची होती त्यांचे नाव व माहिती *</label>
                        <textarea id="chiefAttendeeInfo" name="chiefAttendeeInfo" required
                                  placeholder="उदा. श्री. रमेश पाटील (अध्यक्ष, ग्रामपंचायत)..."></textarea>
                    </div>
                    
                    <div class="form-group">
                        <label for="totalParentsAttended">एकूण उपस्थित पालकांची संख्या *</label>
                        <input type="text" id="totalParentsAttended" name="totalParentsAttended" required
                               placeholder="उदा. 45 पालक">
                    </div>
                    
                    <div class="form-group">
                        <label for="photo1">पालक मेळाव्याचा फोटो १ * (Required)</label>
                        <input type="file" id="photo1" name="photo1" accept="image/*" onchange="previewPhoto(1)" required>
                        <small style="color: #666; display: block; margin-top: 5px;">📸 JPG, PNG (Max 5MB)</small>
                        <img id="photoPreview1" class="photo-preview" style="display: none;">
                    </div>
                    
                    <div class="form-group">
                        <label for="photo2">पालक मेळाव्याचा फोटो २ * (Required)</label>
                        <input type="file" id="photo2" name="photo2" accept="image/*" onchange="previewPhoto(2)" required>
                        <small style="color: #666; display: block; margin-top: 5px;">📸 JPG, PNG (Max 5MB)</small>
                        <img id="photoPreview2" class="photo-preview" style="display: none;">
                    </div>
                    
                    <div style="display: flex; gap: 10px; justify-content: flex-end; margin-top: 20px;">
                        <button type="button" class="btn btn-secondary" onclick="closeModal()">रद्द करा</button>
                        <button type="submit" class="btn btn-primary">💾 जतन करा</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <!-- View Approved Details Modal -->
    <div id="viewDetailsModal" class="modal">
        <div class="view-details-modal-content">
            <div class="view-details-header">
                <h2>👁️ पालक मेळावा सर्व तपशील</h2>
                <span class="close-details" onclick="closeViewDetailsModal()">&times;</span>
            </div>
            <div class="details-container">
                <!-- Meeting Information Section -->
                <div class="details-section">
                    <div class="section-heading">📅 मेळाव्याचे तपशील</div>
                    <div class="details-grid">
                        <div class="detail-item">
                            <div class="detail-label">पालक मेळावा दिनांक</div>
                            <div class="detail-value" id="detailMeetingDate">-</div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">एकूण उपस्थित पालक</div>
                            <div class="detail-value" id="detailTotalParents">-</div>
                        </div>
                        <div class="detail-item" style="grid-column: 1 / -1;">
                            <div class="detail-label">प्रमुख उपस्थिती कोणाची होती</div>
                            <div class="detail-value" id="detailChiefAttendee">-</div>
                        </div>
                    </div>
                </div>
                
                <!-- Photos Section -->
                <div class="details-section">
                    <div class="section-heading">📸 पालक मेळाव्याचे फोटो</div>
                    <div class="photos-section">
                        <div class="photo-container">
                            <div class="photo-label">फोटो १</div>
                            <img id="detailPhoto1" class="photo-image" src="" alt="Photo 1" 
                                 style="cursor: pointer; border: 2px solid #ddd; border-radius: 8px; padding: 5px;"
                                 onclick="viewPhotoFullScreen(this.src)"
                                 title="Click to view full size">
                        </div>
                        <div class="photo-container">
                            <div class="photo-label">फोटो २</div>
                            <img id="detailPhoto2" class="photo-image" src="" alt="Photo 2"
                                 style="cursor: pointer; border: 2px solid #ddd; border-radius: 8px; padding: 5px;"
                                 onclick="viewPhotoFullScreen(this.src)"
                                 title="Click to view full size">
                        </div>
                    </div>
                </div>
                
                <!-- Approval Information Section -->
                <div class="details-section">
                    <div class="section-heading">✓ मंजुरी माहिती</div>
                    <div class="approval-info">
                        <div style="margin-bottom: 10px;">
                            <strong>स्थिती:</strong> मंजूर (Approved)
                        </div>
                        <div style="margin-bottom: 10px;">
                            <strong>मंजुरी तारीख:</strong> <span id="detailApprovalDate">-</span>
                        </div>
                        <div style="margin-bottom: 10px;">
                            <strong>मंजूर करणारा:</strong> <span id="detailApprovedBy">-</span>
                        </div>
                        <div>
                            <strong>शेरा:</strong> <span id="detailApprovalRemarks">-</span>
                        </div>
                    </div>
                </div>
                
                <!-- Action Buttons -->
                <div class="details-actions">
                    <button class="btn-close-details" onclick="closeViewDetailsModal()">बंद करा (Close)</button>
                </div>
            </div>
        </div>
    </div>
    
    </div>
    
    <!-- Photo Viewer Modal for Full Screen Display -->
    <div id="photoViewerModal" style="display: none; position: fixed; z-index: 2000; left: 0; top: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.95); overflow: auto; flex-direction: column; align-items: center; justify-content: center;" onclick="if(event.target.id === 'photoViewerModal') closePhotoViewer()">
        <div style="position: relative; width: 100%; height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center;">
            <span onclick="closePhotoViewer()" style="position: fixed; top: 20px; right: 30px; color: white; font-size: 40px; font-weight: bold; cursor: pointer; z-index: 2001; transition: color 0.3s;">&times;</span>
            <img id="fullScreenPhoto" src="" style="max-width: 95%; max-height: 90vh; border-radius: 8px; box-shadow: 0 0 20px rgba(255,255,255,0.3);" alt="Full Size Photo" onerror=" closePhotoViewer();">
            <div style="color: white; margin-top: 20px; font-size: 14px; text-align: center;">
                <p>ESC दाबा किंवा X क्लिक करा बंद करण्यासाठी</p>
                <p>(Press ESC or click X to close)</p>
            </div>
        </div>
    </div>
    
    <script>
        function openAddModal() {
            console.log('Opening add modal...');
            try {
                document.getElementById('modalTitle').textContent = '➕ नवीन पालक मेळावा जोडा';
                document.getElementById('formAction').value = 'add';
                document.getElementById('melavaForm').reset();
                document.getElementById('melavaId').value = '';
                
                var preview1 = document.getElementById('photoPreview1');
                var preview2 = document.getElementById('photoPreview2');
                
                if (preview1) preview1.style.display = 'none';
                if (preview2) preview2.style.display = 'none';
                
                document.getElementById('melavaModal').style.display = 'block';
                console.log('Modal opened successfully');
            } catch(error) {
                console.error('Error opening modal:', error);
                alert('Error: ' + error.message);
            }
        }
        
        function closeModal() {
            document.getElementById('melavaModal').style.display = 'none';
        }
        
        function previewPhoto(photoNum) {
            const file = document.getElementById('photo' + photoNum).files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    const preview = document.getElementById('photoPreview' + photoNum);
                    preview.src = e.target.result;
                    preview.style.display = 'block';
                }
                reader.readAsDataURL(file);
            }
        }
        
        function editMelava(id) {
            // Load melava data via AJAX and populate form
            fetch('<%= request.getContextPath() %>/palak-melava-data?id=' + id)
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    document.getElementById('modalTitle').textContent = '✏️ पालक मेळावा संपादित करा';
                    document.getElementById('formAction').value = 'edit';
                    document.getElementById('melavaId').value = data.melava.melavaId;
                    document.getElementById('meetingDate').value = data.melava.meetingDate;
                    document.getElementById('chiefAttendeeInfo').value = data.melava.chiefAttendeeInfo;
                    document.getElementById('totalParentsAttended').value = data.melava.totalParentsAttended;
                    
                    document.getElementById('melavaModal').style.display = 'block';
                }
            });
        }
        
        function submitForApproval(id) {
            if (confirm('या पालक मेळाव्याची नोंद मंजुरीसाठी सबमिट करायची आहे का?')) {
                fetch('<%= request.getContextPath() %>/palak-melava-submit', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: 'melavaId=' + id
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('✓ मंजुरीसाठी यशस्वीपणे सबमिट केले!');
                        location.reload();
                    } else {
                        alert('✗ त्रुटी: ' + data.message);
                    }
                });
            }
        }
        
        function deleteMelava(id) {
            if (confirm('ही नोंद हटवायची आहे का?')) {
                fetch('<%= request.getContextPath() %>/palak-melava-delete', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: 'melavaId=' + id
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('✓ यशस्वीपणे हटवले!');
                        location.reload();
                    } else {
                        alert('✗ त्रुटी: ' + data.message);
                    }
                });
            }
        }
        
        document.getElementById('melavaForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Validate photos are selected
            const photo1 = document.getElementById('photo1').files.length;
            const photo2 = document.getElementById('photo2').files.length;
            const formAction = document.getElementById('formAction').value;
            
            // For new records, both photos are required
            if (formAction === 'add') {
                if (photo1 === 0 || photo2 === 0) {
                    alert('⚠️ कृपया दोन्ही फोटो अपलोड करा (Please upload both photos)');
                    return;
                }
            }
            
            const formData = new FormData(this);
            
            fetch('<%= request.getContextPath() %>/palak-melava-save', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ यशस्वीपणे जतन केले! (Successfully saved!)');
                    closeModal();
                    location.reload();
                } else {
                    alert('✗ त्रुटी: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('✗ त्रुटी: ' + error);
            });
        });
        
        function viewApprovedDetails(id) {
            // Load approved melava data via AJAX and display in modal
            fetch('<%= request.getContextPath() %>/palak-melava-data?id=' + id)
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    const melava = data.melava;
                    
                    // Populate details
                    document.getElementById('detailMeetingDate').textContent = melava.meetingDate || '-';
                    document.getElementById('detailTotalParents').textContent = melava.totalParentsAttended || '-';
                    document.getElementById('detailChiefAttendee').textContent = melava.chiefAttendeeInfo || '-';
                    document.getElementById('detailApprovalDate').textContent = melava.approvalDate || '-';
                    document.getElementById('detailApprovedBy').textContent = melava.approvedBy || '-';
                    document.getElementById('detailApprovalRemarks').textContent = melava.approvalRemarks || 'कोणतीही शेरा नाही';
                    
                    // Load photos using the database image servlet as primary source
                    const photo1Img = document.getElementById('detailPhoto1');
                    const photo2Img = document.getElementById('detailPhoto2');
                    
                    if (melava.photo1Path && melava.photo1Path.trim() !== '') {
                        // Use database servlet as primary, fallback to file system
                        photo1Img.src = '<%= request.getContextPath() %>/palak-melava-image-db?id=' + melava.melavaId + '&photo=1';
                        photo1Img.dataset.filePath = encodeURIComponent(melava.photo1Path);
                        photo1Img.dataset.melavaId = melava.melavaId;
                        photo1Img.dataset.photoNum = '1';
                        
                        photo1Img.onerror = function() {
                            console.error('Database photo 1 failed, trying file system fallback');
                            const filePath = this.dataset.filePath;
                            if (filePath && !this.dataset.fallbackTried) {
                                this.dataset.fallbackTried = 'true';
                                this.src = '<%= request.getContextPath() %>/palak-melava-image?path=' + filePath;
                            } else {
                                console.error('All photo 1 load attempts failed');
                                this.style.display = 'none';
                            }
                        };
                        
                        photo1Img.onload = function() {
                            console.log('Photo 1 loaded successfully');
                            this.style.display = 'block';
                        };
                    } else {
                        photo1Img.style.display = 'none';
                    }
                    
                    if (melava.photo2Path && melava.photo2Path.trim() !== '') {
                        // Use database servlet as primary, fallback to file system
                        photo2Img.src = '<%= request.getContextPath() %>/palak-melava-image-db?id=' + melava.melavaId + '&photo=2';
                        photo2Img.dataset.filePath = encodeURIComponent(melava.photo2Path);
                        photo2Img.dataset.melavaId = melava.melavaId;
                        photo2Img.dataset.photoNum = '2';
                        
                        photo2Img.onerror = function() {
                            console.error('Database photo 2 failed, trying file system fallback');
                            const filePath = this.dataset.filePath;
                            if (filePath && !this.dataset.fallbackTried) {
                                this.dataset.fallbackTried = 'true';
                                this.src = '<%= request.getContextPath() %>/palak-melava-image?path=' + filePath;
                            } else {
                                console.error('All photo 2 load attempts failed');
                                this.style.display = 'none';
                            }
                        };
                        
                        photo2Img.onload = function() {
                            console.log('Photo 2 loaded successfully');
                            this.style.display = 'block';
                        };
                    } else {
                        photo2Img.style.display = 'none';
                    }
                    
                    // Show modal
                    document.getElementById('viewDetailsModal').style.display = 'block';
                } else {
                    alert('✗ त्रुटी: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('✗ त्रुटी: ' + error);
            });
        }
        
        function closeViewDetailsModal() {
            document.getElementById('viewDetailsModal').style.display = 'none';
        }
        
        function viewPhotoFullScreen(photoUrl) {
            console.log('Opening full screen photo viewer with URL:', photoUrl);
            const modal = document.getElementById('photoViewerModal');
            const fullScreenImg = document.getElementById('fullScreenPhoto');
            
            if (!photoUrl || photoUrl.trim() === '') {
                alert('Photo URL is not available');
                return;
            }
            
            fullScreenImg.src = photoUrl;
            modal.style.display = 'flex';
        }
        
        function closePhotoViewer() {
            const modal = document.getElementById('photoViewerModal');
            modal.style.display = 'none';
        }
        
        // Close on ESC key press
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closePhotoViewer();
            }
        });
        
        // Close modals on outside click
        window.onclick = function(event) {
            const melavaModal = document.getElementById('melavaModal');
            const viewDetailsModal = document.getElementById('viewDetailsModal');
            const photoViewerModal = document.getElementById('photoViewerModal');
            
            if (event.target == melavaModal) {
                closeModal();
            }
            if (event.target == viewDetailsModal) {
                closeViewDetailsModal();
            }
            if (event.target == photoViewerModal) {
                closePhotoViewer();
            }
        }
    </script>
</body>
</html>
