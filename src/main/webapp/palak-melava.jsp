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
            background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
            color: white;
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
        }
        
        .header-subtitle {
            font-size: 14px;
            opacity: 0.9;
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
                            <button class="btn" style="background: #4caf50; color: white;" disabled>✓ मंजूर</button>
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
                        <label for="photo1">पालक मेळाव्याचा फोटो १ *</label>
                        <input type="file" id="photo1" name="photo1" accept="image/*" onchange="previewPhoto(1)">
                        <img id="photoPreview1" class="photo-preview" style="display: none;">
                    </div>
                    
                    <div class="form-group">
                        <label for="photo2">पालक मेळाव्याचा फोटो २ *</label>
                        <input type="file" id="photo2" name="photo2" accept="image/*" onchange="previewPhoto(2)">
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
            
            const formData = new FormData(this);
            
            fetch('<%= request.getContextPath() %>/palak-melava-save', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ यशस्वीपणे जतन केले!');
                    closeModal();
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
            const modal = document.getElementById('melavaModal');
            if (event.target == modal) {
                closeModal();
            }
        }
    </script>
</body>
</html>
