<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.OtherSchoolActivityDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.OtherSchoolActivity" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String udiseNo = user.getUdiseNo();
    SchoolDAO schoolDAO = new SchoolDAO();
    School school = schoolDAO.getSchoolByUdise(udiseNo);
    String schoolName = school != null ? school.getSchoolName() : "Unknown School";
    
    OtherSchoolActivityDAO activityDAO = new OtherSchoolActivityDAO();
    List<OtherSchoolActivity> activityList = activityDAO.getByUdise(udiseNo);
    
    SimpleDateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy");
    
    String successMsg = request.getParameter("success");
    String errorMsg = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>इतर शालेय उपक्रम - Other School Activity</title>
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
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .header h1 {
            font-size: 26px;
            margin-bottom: 5px;
            color: #000;
        }
        
        .header-subtitle {
            font-size: 14px;
            opacity: 1;
            color: #666;
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
        
        .btn-danger:hover {
            background: #c82333;
        }
        
        .btn-warning {
            background: #ffc107;
            color: #333;
        }
        
        .btn-warning:hover {
            background: #e0a800;
        }
        
        .btn-info {
            background: #17a2b8;
            color: white;
        }
        
        .alert {
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
            font-weight: 500;
        }
        
        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .alert-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
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
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
        }
        
        .form-control {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
        }
        
        .form-control:focus {
            outline: none;
            border-color: #43e97b;
        }
        
        textarea.form-control {
            min-height: 100px;
            resize: vertical;
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
            border-bottom: 2px solid #f0f2f5;
            padding-bottom: 10px;
            margin-bottom: 15px;
        }
        
        .card-title {
            font-size: 18px;
            font-weight: 700;
            color: #333;
            margin-bottom: 5px;
        }
        
        .card-date {
            font-size: 14px;
            color: #666;
        }
        
        .card-body {
            margin-bottom: 15px;
        }
        
        .card-field {
            margin-bottom: 12px;
        }
        
        .card-field-label {
            font-weight: 600;
            color: #555;
            font-size: 13px;
            margin-bottom: 3px;
        }
        
        .card-field-value {
            color: #333;
            font-size: 14px;
        }
        
        .status-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            margin-top: 10px;
        }
        
        .status-draft {
            background: #e7e7e7;
            color: #666;
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
        
        .card-actions {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-top: 15px;
        }
        
        .photo-preview {
            max-width: 100%;
            max-height: 200px;
            border-radius: 5px;
            margin-top: 10px;
        }
        
        .photos-container {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-top: 10px;
        }
        
        .photo-item {
            flex: 1;
            min-width: 150px;
        }
        
        .video-link {
            color: #007bff;
            text-decoration: none;
            word-break: break-all;
        }
        
        .video-link:hover {
            text-decoration: underline;
        }
        
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            overflow: auto;
            background-color: rgba(0,0,0,0.5);
        }
        
        .modal-content {
            background-color: #fefefe;
            margin: 5% auto;
            padding: 0;
            border-radius: 10px;
            width: 90%;
            max-width: 800px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        }
        
        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px 10px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-body {
            padding: 20px;
        }
        
        .close {
            color: white;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
        }
        
        .close:hover {
            color: #ddd;
        }
        
        @media (max-width: 768px) {
            .cards-grid {
                grid-template-columns: 1fr;
            }
            
            .header {
                flex-direction: column;
                align-items: flex-start;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1>🏫 इतर शालेय उपक्रम</h1>
                <div class="header-subtitle">Other School Activity Management</div>
                <div class="header-subtitle" style="margin-top: 5px;">
                    <strong><%= schoolName %></strong> (UDISE: <%= udiseNo %>)
                </div>
            </div>
            <div style="display: flex; gap: 10px; flex-wrap: wrap;">
                <button onclick="openAddModal()" class="btn btn-primary">➕ Add New Activity</button>
                <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="btn btn-secondary">🏠 Back to Dashboard</a>
            </div>
        </div>
        
        <% if (successMsg != null) { %>
            <div class="alert alert-success">✅ <%= successMsg %></div>
        <% } %>
        
        <% if (errorMsg != null) { %>
            <div class="alert alert-error">❌ <%= errorMsg %></div>
        <% } %>
        
        <div class="section">
            <h2 class="section-title">📋 All Activities</h2>
            <p style="color: #666; margin-bottom: 15px;">सर्व शालेय उपक्रम (All school activities recorded)</p>
            
            <% if (activityList.isEmpty()) { %>
                <div style="text-align: center; padding: 40px; color: #666;">
                    <div style="font-size: 48px; margin-bottom: 10px;">📭</div>
                    <div style="font-size: 18px;">No activities recorded yet</div>
                    <div style="font-size: 14px; margin-top: 5px;">Click "Add New Activity" to create your first activity record</div>
                </div>
            <% } else { %>
                <div class="cards-grid">
                    <% for (OtherSchoolActivity activity : activityList) { %>
                        <div class="card">
                            <div class="card-header">
                                <div class="card-title"><%= activity.getActivitySubject() %></div>
                                <div class="card-date">📅 <%= sdf.format(activity.getActivityDate()) %></div>
                            </div>
                            
                            <div class="card-body">
                                <div class="card-field">
                                    <div class="card-field-label">उपस्थित पाहुणे (Guests Present):</div>
                                    <div class="card-field-value"><%= activity.getGuestsPresent() != null ? activity.getGuestsPresent() : "N/A" %></div>
                                </div>
                                
                                <div class="card-field">
                                    <div class="card-field-label">विवरण (Description):</div>
                                    <div class="card-field-value"><%= activity.getDescription() != null ? activity.getDescription() : "N/A" %></div>
                                </div>
                                
                                <% if (activity.getVideoLink() != null && !activity.getVideoLink().isEmpty()) { %>
                                    <div class="card-field">
                                        <div class="card-field-label">व्हिडओ लिंक (Video Link):</div>
                                        <a href="<%= activity.getVideoLink() %>" target="_blank" class="video-link">🎥 View Video</a>
                                    </div>
                                <% } %>
                                
                                <% if (activity.getPhoto1Content() != null || activity.getPhoto2Content() != null) { %>
                                    <div class="card-field">
                                        <div class="card-field-label">फोटो (Photos):</div>
                                        <div class="photos-container">
                                            <% if (activity.getPhoto1Content() != null) { %>
                                                <div class="photo-item">
                                                    <img src="<%= request.getContextPath() %>/OtherSchoolActivityImageServlet?activityId=<%= activity.getActivityId() %>&photoType=photo1" 
                                                         class="photo-preview" alt="Photo 1" onclick="openImageModal(this.src)">
                                                </div>
                                            <% } %>
                                            <% if (activity.getPhoto2Content() != null) { %>
                                                <div class="photo-item">
                                                    <img src="<%= request.getContextPath() %>/OtherSchoolActivityImageServlet?activityId=<%= activity.getActivityId() %>&photoType=photo2" 
                                                         class="photo-preview" alt="Photo 2" onclick="openImageModal(this.src)">
                                                </div>
                                            <% } %>
                                        </div>
                                    </div>
                                <% } %>
                                
                                <div class="card-field">
                                    <% 
                                    String statusClass = "status-draft";
                                    String statusText = "📝 Draft";
                                    
                                    if (activity.getApprovalStatus() != null) {
                                        if (activity.isPending()) {
                                            statusClass = "status-pending";
                                            statusText = "⏳ Pending Approval";
                                        } else if (activity.isApproved()) {
                                            statusClass = "status-approved";
                                            statusText = "✅ Approved";
                                        } else if (activity.isRejected()) {
                                            statusClass = "status-rejected";
                                            statusText = "❌ Rejected";
                                        }
                                    }
                                    %>
                                    <span class="status-badge <%= statusClass %>"><%= statusText %></span>
                                </div>
                                
                                <% if (activity.isRejected() && activity.getRejectionReason() != null) { %>
                                    <div class="card-field" style="margin-top: 10px;">
                                        <div class="card-field-label">Rejection Reason:</div>
                                        <div class="card-field-value" style="color: #dc3545;"><%= activity.getRejectionReason() %></div>
                                    </div>
                                <% } %>
                            </div>
                            
                            <div class="card-actions">
                                <% if (activity.isDraft() || activity.isRejected()) { %>
                                    <button onclick="submitForApproval(<%= activity.getActivityId() %>)" class="btn btn-warning">
                                        📤 Submit for Approval
                                    </button>
                                <% } %>
                                
                                <% if (!activity.isApproved()) { %>
                                    <button onclick="deleteActivity(<%= activity.getActivityId() %>)" class="btn btn-danger">
                                        🗑️ Delete
                                    </button>
                                <% } %>
                            </div>
                        </div>
                    <% } %>
                </div>
            <% } %>
        </div>
    </div>
    
    <!-- Add Activity Modal -->
    <div id="addActivityModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>➕ Add New School Activity</h2>
                <span class="close" onclick="closeAddModal()">&times;</span>
            </div>
            <div class="modal-body">
                <form action="<%= request.getContextPath() %>/OtherSchoolActivitySaveServlet" method="post" enctype="multipart/form-data" onsubmit="return validateForm()">
                    <div class="form-group">
                        <label class="form-label">📅 Date / तारीख <span style="color: red;">*</span></label>
                        <input type="date" name="activityDate" class="form-control" required max="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new Date()) %>">
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">📝 Subject / उपक्रमाचे नाव <span style="color: red;">*</span></label>
                        <input type="text" name="activitySubject" class="form-control" required placeholder="Enter activity subject">
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">👥 उपस्थित पाहुणे (Guests Present) <span style="color: red;">*</span></label>
                        <textarea name="guestsPresent" class="form-control" required placeholder="Enter details of guests who attended"></textarea>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">📄 विवरण (Description) <span style="color: red;">*</span></label>
                        <textarea name="description" class="form-control" required placeholder="Enter activity description"></textarea>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">📷 फोटो 1 (Photo 1) <span style="color: red;">*</span></label>
                        <input type="file" name="photo1" class="form-control" accept="image/*" required onchange="previewImage(this, 'preview1')">
                        <img id="preview1" style="max-width: 200px; margin-top: 10px; display: none;">
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">📷 फोटो 2 (Photo 2) <span style="color: red;">*</span></label>
                        <input type="file" name="photo2" class="form-control" accept="image/*" required onchange="previewImage(this, 'preview2')">
                        <img id="preview2" style="max-width: 200px; margin-top: 10px; display: none;">
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">🎥 व्हिडओ लिंक (Video Link)</label>
                        <input type="url" name="videoLink" class="form-control" placeholder="https://youtube.com/watch?v=...">
                        <small style="color: #666;">Optional: Add YouTube or other video link</small>
                    </div>
                    
                    <div style="display: flex; gap: 10px; justify-content: flex-end; margin-top: 20px;">
                        <button type="button" onclick="closeAddModal()" class="btn btn-secondary">Cancel</button>
                        <button type="submit" class="btn btn-primary">💾 Save Activity</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <!-- Image Modal -->
    <div id="imageModal" class="modal" onclick="closeImageModal()">
        <div class="modal-content" style="max-width: 90%; background: transparent; box-shadow: none;">
            <img id="modalImage" style="width: 100%; border-radius: 10px;">
        </div>
    </div>
    
    <script>
        function openAddModal() {
            document.getElementById('addActivityModal').style.display = 'block';
        }
        
        function closeAddModal() {
            document.getElementById('addActivityModal').style.display = 'none';
        }
        
        function openImageModal(src) {
            document.getElementById('modalImage').src = src;
            document.getElementById('imageModal').style.display = 'block';
        }
        
        function closeImageModal() {
            document.getElementById('imageModal').style.display = 'none';
        }
        
        function previewImage(input, previewId) {
            if (input.files && input.files[0]) {
                var reader = new FileReader();
                reader.onload = function(e) {
                    var preview = document.getElementById(previewId);
                    preview.src = e.target.result;
                    preview.style.display = 'block';
                };
                reader.readAsDataURL(input.files[0]);
            }
        }
        
        function validateForm() {
            // Add any additional validation here
            return true;
        }
        
        function submitForApproval(activityId) {
            if (confirm('Are you sure you want to submit this activity for headmaster approval?')) {
                var form = document.createElement('form');
                form.method = 'POST';
                form.action = '<%= request.getContextPath() %>/OtherSchoolActivitySubmitServlet';
                
                var input = document.createElement('input');
                input.type = 'hidden';
                input.name = 'activityId';
                input.value = activityId;
                
                form.appendChild(input);
                document.body.appendChild(form);
                form.submit();
            }
        }
        
        function deleteActivity(activityId) {
            if (confirm('Are you sure you want to delete this activity? This action cannot be undone.')) {
                var form = document.createElement('form');
                form.method = 'POST';
                form.action = '<%= request.getContextPath() %>/OtherSchoolActivityDeleteServlet';
                
                var input = document.createElement('input');
                input.type = 'hidden';
                input.name = 'activityId';
                input.value = activityId;
                
                form.appendChild(input);
                document.body.appendChild(form);
                form.submit();
            }
        }
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            var modal = document.getElementById('addActivityModal');
            if (event.target == modal) {
                closeAddModal();
            }
        }
    </script>
</body>
</html>
