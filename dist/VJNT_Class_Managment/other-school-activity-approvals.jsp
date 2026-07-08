<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.OtherSchoolActivityDAO" %>
<%@ page import="com.vjnt.model.OtherSchoolActivity" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.HEAD_MASTER)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String udiseNo = user.getUdiseNo();
    
    OtherSchoolActivityDAO activityDAO = new OtherSchoolActivityDAO();
    List<OtherSchoolActivity> pendingActivities = activityDAO.getPendingApprovals(udiseNo);
    
    SimpleDateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy");
    
    String successMsg = request.getParameter("success");
    String errorMsg = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Other School Activity Approvals - Headmaster</title>
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
        
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        
        .btn-secondary:hover {
            background: #5a6268;
        }
        
        .btn-success {
            background: #28a745;
            color: white;
        }
        
        .btn-success:hover {
            background: #218838;
        }
        
        .btn-danger {
            background: #dc3545;
            color: white;
        }
        
        .btn-danger:hover {
            background: #c82333;
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
        
        .cards-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        
        .card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
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
        
        .photo-preview {
            max-width: 100%;
            max-height: 200px;
            border-radius: 5px;
            margin-top: 10px;
            cursor: pointer;
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
        
        .approval-form {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 2px solid #f0f2f5;
        }
        
        .form-group {
            margin-bottom: 15px;
        }
        
        .form-label {
            display: block;
            margin-bottom: 5px;
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
            overflow: auto;
            background-color: rgba(0,0,0,0.7);
        }
        
        .modal-content {
            background-color: transparent;
            margin: 5% auto;
            padding: 0;
            width: 90%;
            max-width: 800px;
        }
        
        .modal-content img {
            width: 100%;
            border-radius: 10px;
        }
        
        @media (max-width: 768px) {
            .cards-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1>✅ Approve Other School Activities</h1>
                <div class="header-subtitle">इतर शालेय उपक्रम मंजूरी (Headmaster Approval)</div>
            </div>
            <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="btn btn-secondary">🏠 Back to Dashboard</a>
        </div>
        
        <% if (successMsg != null) { %>
            <div class="alert alert-success">✅ <%= successMsg %></div>
        <% } %>
        
        <% if (errorMsg != null) { %>
            <div class="alert alert-error">❌ <%= errorMsg %></div>
        <% } %>
        
        <div class="section">
            <h2 class="section-title">⏳ Pending Approvals (<%= pendingActivities.size() %>)</h2>
            
            <% if (pendingActivities.isEmpty()) { %>
                <div style="text-align: center; padding: 40px; color: #666;">
                    <div style="font-size: 48px; margin-bottom: 10px;">✅</div>
                    <div style="font-size: 18px;">No pending approvals</div>
                    <div style="font-size: 14px; margin-top: 5px;">All activities have been processed</div>
                </div>
            <% } else { %>
                <div class="cards-grid">
                    <% for (OtherSchoolActivity activity : pendingActivities) { %>
                        <div class="card">
                            <div class="card-header">
                                <div class="card-title"><%= activity.getActivitySubject() %></div>
                                <div class="card-date">📅 <%= sdf.format(activity.getActivityDate()) %></div>
                            </div>
                            
                            <div class="card-field">
                                <div class="card-field-label">उपस्थित पाहुणे (Guests Present):</div>
                                <div class="card-field-value"><%= activity.getGuestsPresent() %></div>
                            </div>
                            
                            <div class="card-field">
                                <div class="card-field-label">विवरण (Description):</div>
                                <div class="card-field-value"><%= activity.getDescription() %></div>
                            </div>
                            
                            <% if (activity.getVideoLink() != null && !activity.getVideoLink().isEmpty()) { %>
                                <div class="card-field">
                                    <div class="card-field-label">व्हिडओ लिंक (Video Link):</div>
                                    <a href="<%= activity.getVideoLink() %>" target="_blank" style="color: #007bff;">🎥 View Video</a>
                                </div>
                            <% } %>
                            
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
                            
                            <div class="card-field">
                                <div class="card-field-label">Submitted By:</div>
                                <div class="card-field-value"><%= activity.getSubmittedBy() %> on <%= sdf.format(activity.getSubmittedDate()) %></div>
                            </div>
                            
                            <div class="approval-form">
                                <form action="<%= request.getContextPath() %>/OtherSchoolActivityApprovalServlet" method="post">
                                    <input type="hidden" name="activityId" value="<%= activity.getActivityId() %>">
                                    
                                    <div class="form-group">
                                        <label class="form-label">Remarks / टिप्पणी:</label>
                                        <textarea name="remarks" class="form-control" rows="3" placeholder="Enter your remarks (optional)"></textarea>
                                    </div>
                                    
                                    <div class="card-actions">
                                        <button type="submit" name="action" value="approve" class="btn btn-success" 
                                                onclick="return confirm('Are you sure you want to approve this activity?')">
                                            ✅ Approve
                                        </button>
                                        <button type="submit" name="action" value="reject" class="btn btn-danger" 
                                                onclick="return confirm('Are you sure you want to reject this activity?')">
                                            ❌ Reject
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    <% } %>
                </div>
            <% } %>
        </div>
    </div>
    
    <!-- Image Modal -->
    <div id="imageModal" class="modal" onclick="closeImageModal()">
        <div class="modal-content">
            <img id="modalImage" alt="Full size image">
        </div>
    </div>
    
    <script>
        function openImageModal(src) {
            document.getElementById('modalImage').src = src;
            document.getElementById('imageModal').style.display = 'block';
        }
        
        function closeImageModal() {
            document.getElementById('imageModal').style.display = 'none';
        }
    </script>
</body>
</html>
