<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="java.util.*" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.vjnt.util.DatabaseConnection" %>
<%@ page import="org.json.JSONArray" %>
<%@ page import="org.json.JSONObject" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DIVISION) && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    if (!user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    com.vjnt.dao.StudentDAO __superDao = new com.vjnt.dao.StudentDAO();
    java.util.List<String> __divisions = __superDao.getDistinctDivisions();
    String divisionName = "ALL";
    
    // Fetch existing notifications created by this division head
    List<Map<String, Object>> notifications = new ArrayList<>();
    JSONArray notificationsJSON = new JSONArray();
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        String sql = "SELECT notification_id, title, message, notification_type, target_audience, " +
                     "division, district, udise_code, priority, created_date, expiry_date, is_active " +
                     "FROM notifications " +
                     "WHERE created_by = ? " +
                     "ORDER BY created_date DESC";
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, user.getUserId());
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> notif = new HashMap<>();
            notif.put("id", rs.getInt("notification_id"));
            notif.put("title", rs.getString("title"));
            notif.put("message", rs.getString("message"));
            notif.put("type", rs.getString("notification_type"));
            notif.put("targetAudience", rs.getString("target_audience"));
            notif.put("division", rs.getString("division"));
            notif.put("district", rs.getString("district"));
            notif.put("udiseCode", rs.getString("udise_code"));
            notif.put("priority", rs.getInt("priority"));
            notif.put("createdDate", rs.getTimestamp("created_date"));
            notif.put("expiryDate", rs.getTimestamp("expiry_date"));
            notif.put("isActive", rs.getBoolean("is_active"));
            notifications.add(notif);
            
            // Build JSON object for JavaScript
            JSONObject jsonNotif = new JSONObject();
            jsonNotif.put("id", rs.getInt("notification_id"));
            jsonNotif.put("title", rs.getString("title") != null ? rs.getString("title") : "");
            jsonNotif.put("message", rs.getString("message") != null ? rs.getString("message") : "");
            jsonNotif.put("type", rs.getString("notification_type"));
            jsonNotif.put("priority", rs.getInt("priority"));
            jsonNotif.put("targetAudience", rs.getString("target_audience"));
            jsonNotif.put("district", rs.getString("district") != null ? rs.getString("district") : "");
            jsonNotif.put("udiseCode", rs.getString("udise_code") != null ? rs.getString("udise_code") : "");
            
            // Format expiry date for datetime-local input
            String expiryDateFormatted = "";
            if (rs.getTimestamp("expiry_date") != null) {
                java.text.SimpleDateFormat sdfInput = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm");
                expiryDateFormatted = sdfInput.format(rs.getTimestamp("expiry_date"));
            }
            jsonNotif.put("expiryDate", expiryDateFormatted);
            
            notificationsJSON.put(jsonNotif);
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
        if (conn != null) try { conn.close(); } catch (SQLException e) { }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Announcements - Division Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f7fa;
            min-height: 100vh;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px 30px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            position: sticky;
            top: 0;
            z-index: 1000;
        }
        
        .header-content {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            font-size: 28px;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .header-actions {
            display: flex;
            gap: 15px;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 25px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s;
        }
        
        .btn-back {
            background: rgba(255,255,255,0.2);
            color: white;
            border: 2px solid rgba(255,255,255,0.3);
        }
        
        .btn-back:hover {
            background: rgba(255,255,255,0.3);
        }
        
        .btn-primary {
            background: #4caf50;
            color: white;
        }
        
        .btn-primary:hover {
            background: #45a049;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(76, 175, 80, 0.4);
        }
        
        .btn-edit {
            background: #2196f3;
            color: white;
            padding: 8px 16px;
            font-size: 13px;
        }
        
        .btn-delete {
            background: #f44336;
            color: white;
            padding: 8px 16px;
            font-size: 13px;
        }
        
        .btn-toggle {
            background: #ff9800;
            color: white;
            padding: 8px 16px;
            font-size: 13px;
        }
        
        .container {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        .page-title {
            font-size: 32px;
            margin-bottom: 10px;
            color: #333;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .page-subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 16px;
        }
        
        .card {
            background: white;
            border-radius: 15px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            padding: 30px;
            margin-bottom: 30px;
        }
        
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .form-group {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        
        .form-group.full-width {
            grid-column: 1 / -1;
        }
        
        .form-group label {
            font-weight: 600;
            color: #333;
            font-size: 14px;
        }
        
        .form-group input,
        .form-group select,
        .form-group textarea {
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            font-family: inherit;
            transition: border-color 0.3s;
        }
        
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .form-group textarea {
            min-height: 120px;
            resize: vertical;
        }
        
        .required {
            color: #f44336;
        }
        
        .notification-type-selector {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
        }
        
        .type-option {
            padding: 15px;
            border: 3px solid #e0e0e0;
            border-radius: 12px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .type-option input[type="radio"] {
            display: none;
        }
        
        .type-option.selected {
            transform: scale(1.05);
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }
        
        .type-option.type-INFO {
            border-color: #2196f3;
            background: #e3f2fd;
        }
        
        .type-option.type-INFO.selected {
            background: #2196f3;
            color: white;
        }
        
        .type-option.type-WARNING {
            border-color: #ff9800;
            background: #fff3e0;
        }
        
        .type-option.type-WARNING.selected {
            background: #ff9800;
            color: white;
        }
        
        .type-option.type-URGENT {
            border-color: #f44336;
            background: #ffebee;
        }
        
        .type-option.type-URGENT.selected {
            background: #f44336;
            color: white;
        }
        
        .type-option.type-SUCCESS {
            border-color: #4caf50;
            background: #e8f5e9;
        }
        
        .type-option.type-SUCCESS.selected {
            background: #4caf50;
            color: white;
        }
        
        .type-icon {
            font-size: 32px;
            margin-bottom: 8px;
        }
        
        .type-label {
            font-weight: 600;
            font-size: 14px;
        }
        
        .priority-selector {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
        }
        
        .priority-option {
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .priority-option input[type="radio"] {
            display: none;
        }
        
        .priority-option.selected {
            border-color: #667eea;
            background: #667eea;
            color: white;
            transform: scale(1.05);
        }
        
        .notifications-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        .notifications-table th,
        .notifications-table td {
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .notifications-table th {
            background: #f5f7fa;
            font-weight: 600;
            color: #333;
        }
        
        .notifications-table tr:hover {
            background: #f9f9f9;
        }
        
        .badge {
            padding: 5px 12px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
            display: inline-block;
        }
        
        .badge-INFO {
            background: #e3f2fd;
            color: #2196f3;
        }
        
        .badge-WARNING {
            background: #fff3e0;
            color: #ff9800;
        }
        
        .badge-URGENT {
            background: #ffebee;
            color: #f44336;
        }
        
        .badge-SUCCESS {
            background: #e8f5e9;
            color: #4caf50;
        }
        
        .badge-active {
            background: #4caf50;
            color: white;
        }
        
        .badge-inactive {
            background: #9e9e9e;
            color: white;
        }
        
        .action-buttons {
            display: flex;
            gap: 8px;
        }
        
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 14px;
        }
        
        .alert-success {
            background: #e8f5e9;
            color: #2e7d32;
            border-left: 4px solid #4caf50;
        }
        
        .alert-error {
            background: #ffebee;
            color: #c62828;
            border-left: 4px solid #f44336;
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
            .form-grid {
                grid-template-columns: 1fr;
            }
            
            .notification-type-selector {
                grid-template-columns: repeat(2, 1fr);
            }
            
            .priority-selector {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <div class="header">
        <div class="header-content">
            <h1>
                <span>📢</span>
                <span>Manage Announcements</span>
            </h1>
            <div class="header-actions">
                <a href="super-officer-dashboard.jsp" class="btn btn-back">
                    ← Back to Dashboard
                </a>
            </div>
        </div>
    </div>
    
    <!-- Main Container -->
    <div class="container">
        <div class="page-title">
            🔔 Create New Announcement
        </div>
        <div class="page-subtitle">
            Send important announcements to schools in your division
        </div>
        
        <!-- Create Notification Form -->
        <div class="card">
            <form id="notificationForm" method="post" action="<%= request.getContextPath() %>/super-save-notification">
                <input type="hidden" name="action" value="create">
                <input type="hidden" name="createdBy" value="<%= user.getUserId() %>">
                <input type="hidden" name="createdByName" value="<%= user.getFullName() %>">
                
                <div class="form-grid">
                    <div class="form-group full-width">
                        <label>Notification Title <span class="required">*</span></label>
                        <input type="text" name="title" id="title" placeholder="e.g., Phase 3 Assessment Deadline" required maxlength="255">
                    </div>
                    
                    <div class="form-group full-width">
                        <label>Message <span class="required">*</span></label>
                        <textarea name="message" id="message" placeholder="Enter your announcement message here..." required></textarea>
                    </div>
                    
                    <div class="form-group full-width">
                        <label>Notification Type <span class="required">*</span></label>
                        <div class="notification-type-selector">
                            <label class="type-option type-INFO" data-type="INFO">
                                <input type="radio" name="notificationType" value="INFO" checked>
                                <div class="type-icon">ℹ️</div>
                                <div class="type-label">Information</div>
                            </label>
                            <label class="type-option type-WARNING" data-type="WARNING">
                                <input type="radio" name="notificationType" value="WARNING">
                                <div class="type-icon">⚡</div>
                                <div class="type-label">Warning</div>
                            </label>
                            <label class="type-option type-URGENT" data-type="URGENT">
                                <input type="radio" name="notificationType" value="URGENT">
                                <div class="type-icon">⚠️</div>
                                <div class="type-label">Urgent</div>
                            </label>
                            <label class="type-option type-SUCCESS" data-type="SUCCESS">
                                <input type="radio" name="notificationType" value="SUCCESS">
                                <div class="type-icon">✅</div>
                                <div class="type-label">Success</div>
                            </label>
                        </div>
                    </div>
                    
                    <div class="form-group full-width">
                        <label>Priority Level <span class="required">*</span></label>
                        <div class="priority-selector">
                            <label class="priority-option" data-priority="0">
                                <input type="radio" name="priority" value="0" checked>
                                <div>📋 Normal</div>
                            </label>
                            <label class="priority-option" data-priority="1">
                                <input type="radio" name="priority" value="1">
                                <div>⚡ High</div>
                            </label>
                            <label class="priority-option" data-priority="2">
                                <input type="radio" name="priority" value="2">
                                <div>🚨 Urgent</div>
                            </label>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label>Target Audience <span class="required">*</span></label>
                        <select name="targetAudience" id="targetAudience" required>
                            <option value="ALL">All Users (School Coordinators & Head Masters)</option>
                            <option value="SCHOOL_COORDINATOR">School Coordinators Only</option>
                            <option value="HEAD_MASTER">Head Masters Only</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label>Target Division <span class="required">*</span></label>
                        <select name="division" id="division" required>
                            <option value="ALL">All Divisions (broadcast everywhere)</option>
                            <% for (String __d : __divisions) { %>
                                <option value="<%= __d %>"><%= __d %></option>
                            <% } %>
                        </select>
                        <small style="color: #667eea; font-size: 12px; font-weight: 600;">Choose a specific division, or "All Divisions" to target every division.</small>
                    </div>
                    
                    <div class="form-group">
                        <label>Target District (Optional)</label>
                        <input type="text" name="district" id="district" placeholder="⚠️ Leave BLANK for ALL districts in your division">
                        <small style="color: #ff9800; font-size: 12px; font-weight: 600;">⚠️ Only fill this if targeting ONE specific district</small>
                    </div>
                    
                    <div class="form-group">
                        <label>Target School UDISE (Optional)</label>
                        <input type="text" name="udiseCode" id="udiseCode" placeholder="⚠️ Leave BLANK for ALL schools" maxlength="20">
                        <small style="color: #ff9800; font-size: 12px; font-weight: 600;">⚠️ Only fill this if targeting ONE specific school</small>
                    </div>
                    
                    <div class="form-group">
                        <label>Expiry Date (Optional) 📅</label>
                        <input type="datetime-local" name="expiryDate" id="expiryDate" 
                               style="font-size: 14px; padding: 10px;">
                        <small style="color: #666; font-size: 12px; display: block; margin-top: 5px;">
                            💡 Leave blank for no expiry. Set a date to automatically hide this notification after that time.
                        </small>
                        <small id="expiryDatePreview" style="color: #4CAF50; font-size: 12px; font-weight: bold; display: none; margin-top: 5px;">
                        </small>
                    </div>
                </div>
                
                <div style="display: flex; gap: 15px; justify-content: flex-end; margin-top: 30px;">
                    <button type="reset" class="btn" style="background: #e0e0e0; color: #333;">
                        🔄 Reset Form
                    </button>
                    <button type="submit" class="btn btn-primary">
                        📤 Send Announcement
                    </button>
                </div>
            </form>
        </div>
        
        <!-- Existing Notifications -->
        <div class="card">
            <h2 style="margin-bottom: 20px; color: #333; display: flex; align-items: center; gap: 12px;">
                <span>📋</span>
                <span>Your Announcements (<%= notifications.size() %>)</span>
            </h2>
            
            <% if (notifications.isEmpty()) { %>
            <div class="empty-state">
                <div class="empty-state-icon">📭</div>
                <h3>No Announcements Yet</h3>
                <p>Create your first announcement using the form above</p>
            </div>
            <% } else { %>
            <table class="notifications-table">
                <thead>
                    <tr>
                        <th>Title</th>
                        <th>Type</th>
                        <th>Priority</th>
                        <th>Target</th>
                        <th>Created</th>
                        <th>Expires</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("MMM dd, yyyy");
                    for (Map<String, Object> notif : notifications) {
                        String type = (String) notif.get("type");
                        int priority = (Integer) notif.get("priority");
                        String priorityLabel = priority == 2 ? "🚨 Urgent" : (priority == 1 ? "⚡ High" : "📋 Normal");
                        boolean isActive = (Boolean) notif.get("isActive");
                        String createdDate = sdf.format((java.util.Date) notif.get("createdDate"));
                        String expiryDate = notif.get("expiryDate") != null ? sdf.format((java.util.Date) notif.get("expiryDate")) : "Never";
                    %>
                    <tr>
                        <td><strong><%= notif.get("title") %></strong></td>
                        <td><span class="badge badge-<%= type %>"><%= type %></span></td>
                        <td><%= priorityLabel %></td>
                        <td><%= notif.get("targetAudience") %></td>
                        <td><%= createdDate %></td>
                        <td><%= expiryDate %></td>
                        <td>
                            <span class="badge <%= isActive ? "badge-active" : "badge-inactive" %>">
                                <%= isActive ? "✓ Active" : "✗ Inactive" %>
                            </span>
                        </td>
                        <td>
                            <div class="action-buttons">
                                <button class="btn btn-edit" onclick="editNotification(<%= notif.get("id") %>)">
                                    ✏️ Edit
                                </button>
                                <button class="btn btn-toggle" onclick="toggleNotification(<%= notif.get("id") %>, <%= isActive %>)">
                                    <%= isActive ? "⏸️ Pause" : "▶️ Resume" %>
                                </button>
                                <button class="btn btn-delete" onclick="deleteNotification(<%= notif.get("id") %>)">
                                    🗑️ Delete
                                </button>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
            <% } %>
        </div>
    </div>
    
    <!-- Edit Notification Modal -->
    <div id="editModal" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 9999; overflow-y: auto;">
        <div style="max-width: 800px; margin: 50px auto; background: white; border-radius: 15px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.3);">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px;">
                <h2 style="margin: 0; color: #333;">✏️ Edit Announcement</h2>
                <button onclick="closeEditModal()" style="background: #f44336; color: white; border: none; border-radius: 50%; width: 35px; height: 35px; font-size: 20px; cursor: pointer; display: flex; align-items: center; justify-content: center;">×</button>
            </div>
            
            <form id="editNotificationForm" method="post" action="<%= request.getContextPath() %>/super-save-notification">
                <input type="hidden" name="action" value="update">
                <input type="hidden" name="notificationId" id="edit_notificationId">
                
                <div class="form-grid">
                    <div class="form-group full-width">
                        <label>Notification Title <span class="required">*</span></label>
                        <input type="text" name="title" id="edit_title" required maxlength="255">
                    </div>
                    
                    <div class="form-group full-width">
                        <label>Message <span class="required">*</span></label>
                        <textarea name="message" id="edit_message" required></textarea>
                    </div>
                    
                    <div class="form-group full-width">
                        <label>Notification Type <span class="required">*</span></label>
                        <div class="notification-type-selector" id="edit_typeSelector">
                            <label class="type-option type-INFO" data-type="INFO">
                                <input type="radio" name="notificationType" value="INFO">
                                <div class="type-icon">ℹ️</div>
                                <div class="type-label">Information</div>
                            </label>
                            <label class="type-option type-WARNING" data-type="WARNING">
                                <input type="radio" name="notificationType" value="WARNING">
                                <div class="type-icon">⚡</div>
                                <div class="type-label">Warning</div>
                            </label>
                            <label class="type-option type-URGENT" data-type="URGENT">
                                <input type="radio" name="notificationType" value="URGENT">
                                <div class="type-icon">⚠️</div>
                                <div class="type-label">Urgent</div>
                            </label>
                            <label class="type-option type-SUCCESS" data-type="SUCCESS">
                                <input type="radio" name="notificationType" value="SUCCESS">
                                <div class="type-icon">✅</div>
                                <div class="type-label">Success</div>
                            </label>
                        </div>
                    </div>
                    
                    <div class="form-group full-width">
                        <label>Priority Level <span class="required">*</span></label>
                        <div class="priority-selector" id="edit_prioritySelector">
                            <label class="priority-option" data-priority="0">
                                <input type="radio" name="priority" value="0">
                                <div>📋 Normal</div>
                            </label>
                            <label class="priority-option" data-priority="1">
                                <input type="radio" name="priority" value="1">
                                <div>⚡ High</div>
                            </label>
                            <label class="priority-option" data-priority="2">
                                <input type="radio" name="priority" value="2">
                                <div>🚨 Urgent</div>
                            </label>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label>Target Audience <span class="required">*</span></label>
                        <select name="targetAudience" id="edit_targetAudience" required>
                            <option value="ALL">All Users (School Coordinators & Head Masters)</option>
                            <option value="SCHOOL_COORDINATOR">School Coordinators Only</option>
                            <option value="HEAD_MASTER">Head Masters Only</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label>Target District (Optional)</label>
                        <input type="text" name="district" id="edit_district">
                    </div>
                    
                    <div class="form-group">
                        <label>Target School UDISE (Optional)</label>
                        <input type="text" name="udiseCode" id="edit_udiseCode" maxlength="20">
                    </div>
                    
                    <div class="form-group">
                        <label>Expiry Date (Optional)</label>
                        <input type="datetime-local" name="expiryDate" id="edit_expiryDate">
                    </div>
                </div>
                
                <div style="display: flex; gap: 15px; justify-content: flex-end; margin-top: 30px;">
                    <button type="button" onclick="closeEditModal()" class="btn" style="background: #e0e0e0; color: #333;">
                        ✖ Cancel
                    </button>
                    <button type="submit" class="btn btn-primary">
                        💾 Update Announcement
                    </button>
                </div>
            </form>
        </div>
    </div>
    
    <script>
        // Store notifications data for editing
        const notificationsData = <%= notificationsJSON.toString() %>;
        
        // Edit notification function
        function editNotification(id) {
            console.log('Edit notification called with ID:', id);
            console.log('Available notifications:', notificationsData);
            const notification = notificationsData.find(n => n.id === id);
            if (!notification) {
                alert('Notification not found. Please refresh the page and try again.');
                console.error('Notification not found for ID:', id);
                return;
            }
            console.log('Found notification:', notification);
            
            // Populate form fields
            document.getElementById('edit_notificationId').value = notification.id;
            document.getElementById('edit_title').value = notification.title;
            document.getElementById('edit_message').value = notification.message;
            document.getElementById('edit_targetAudience').value = notification.targetAudience;
            document.getElementById('edit_district').value = notification.district;
            document.getElementById('edit_udiseCode').value = notification.udiseCode;
            document.getElementById('edit_expiryDate').value = notification.expiryDate;
            
            // Reset all selections first
            document.querySelectorAll('#edit_typeSelector .type-option').forEach(opt => {
                opt.classList.remove('selected');
                opt.querySelector('input[type="radio"]').checked = false;
            });
            document.querySelectorAll('#edit_prioritySelector .priority-option').forEach(opt => {
                opt.classList.remove('selected');
                opt.querySelector('input[type="radio"]').checked = false;
            });
            
            // Set notification type - ensure robust selection
            console.log('Looking for type:', notification.type, 'Type:', typeof notification.type);
            const allTypeRadios = document.querySelectorAll('#edit_typeSelector input[name="notificationType"]');
            console.log('All type radios:', allTypeRadios);
            
            let typeSet = false;
            allTypeRadios.forEach(radio => {
                console.log('Checking type radio value:', radio.value, 'against:', notification.type);
                if (radio.value === notification.type) {
                    radio.checked = true;
                    radio.closest('.type-option').classList.add('selected');
                    typeSet = true;
                    console.log('✓ Type selected:', radio.value);
                }
            });
            
            if (!typeSet) {
                console.error('❌ Could not set notification type for value:', notification.type);
                // Force set to INFO as fallback
                const firstType = document.querySelector('#edit_typeSelector input[value="INFO"]');
                if (firstType) {
                    firstType.checked = true;
                    firstType.closest('.type-option').classList.add('selected');
                    console.log('⚠ Set default type: INFO');
                }
            }
            
            // Set priority - ensure we're comparing strings
            console.log('Looking for priority:', notification.priority, 'Type:', typeof notification.priority);
            const priorityValue = String(notification.priority); // Convert to string for comparison
            const allPriorityRadios = document.querySelectorAll('#edit_prioritySelector input[name="priority"]');
            console.log('All priority radios:', allPriorityRadios);
            
            let prioritySet = false;
            allPriorityRadios.forEach(radio => {
                console.log('Checking radio value:', radio.value, 'against:', priorityValue);
                if (radio.value === priorityValue) {
                    radio.checked = true;
                    radio.closest('.priority-option').classList.add('selected');
                    prioritySet = true;
                    console.log('✓ Priority selected:', radio.value);
                }
            });
            
            if (!prioritySet) {
                console.error('❌ Could not set priority for value:', notification.priority);
                // Force set to first option as fallback
                const firstPriority = document.querySelector('#edit_prioritySelector input[name="priority"]');
                if (firstPriority) {
                    firstPriority.checked = true;
                    firstPriority.closest('.priority-option').classList.add('selected');
                    console.log('⚠ Set default priority:', firstPriority.value);
                }
            }
            
            // Show modal
            document.getElementById('editModal').style.display = 'block';
            document.body.style.overflow = 'hidden';
        }
        
        // Close edit modal
        function closeEditModal() {
            document.getElementById('editModal').style.display = 'none';
            document.body.style.overflow = 'auto';
        }
        
        // Setup edit modal type and priority selectors
        document.querySelectorAll('#edit_typeSelector .type-option').forEach(option => {
            option.addEventListener('click', function() {
                document.querySelectorAll('#edit_typeSelector .type-option').forEach(opt => opt.classList.remove('selected'));
                this.classList.add('selected');
                this.querySelector('input[type="radio"]').checked = true;
            });
        });
        
        document.querySelectorAll('#edit_prioritySelector .priority-option').forEach(option => {
            option.addEventListener('click', function() {
                document.querySelectorAll('#edit_prioritySelector .priority-option').forEach(opt => opt.classList.remove('selected'));
                this.classList.add('selected');
                this.querySelector('input[type="radio"]').checked = true;
            });
        });
        
        // Close modal when clicking outside
        document.getElementById('editModal').addEventListener('click', function(e) {
            if (e.target === this) {
                closeEditModal();
            }
        });
        
        // Notification type selector (for main form)
        document.querySelectorAll('.type-option').forEach(option => {
            option.addEventListener('click', function() {
                document.querySelectorAll('.type-option').forEach(opt => opt.classList.remove('selected'));
                this.classList.add('selected');
                this.querySelector('input[type="radio"]').checked = true;
            });
        });
        
        // Priority selector
        document.querySelectorAll('.priority-option').forEach(option => {
            option.addEventListener('click', function() {
                document.querySelectorAll('.priority-option').forEach(opt => opt.classList.remove('selected'));
                this.classList.add('selected');
                this.querySelector('input[type="radio"]').checked = true;
            });
        });
        
        // Set initial selected states
        document.querySelector('.type-option input[type="radio"]:checked').closest('.type-option').classList.add('selected');
        document.querySelector('.priority-option input[type="radio"]:checked').closest('.priority-option').classList.add('selected');
        
        // Toggle notification active/inactive
        function toggleNotification(id, currentStatus) {
            console.log('Toggle notification called - ID:', id, 'Current Status:', currentStatus);
            const action = currentStatus ? 'deactivate' : 'activate';
            if (confirm('Are you sure you want to ' + action + ' this announcement?')) {
                console.log('User confirmed, submitting form...');
                const form = document.createElement('form');
                form.method = 'POST';
                form.action = '<%= request.getContextPath() %>/super-save-notification';
                
                const actionInput = document.createElement('input');
                actionInput.type = 'hidden';
                actionInput.name = 'action';
                actionInput.value = 'toggle';
                form.appendChild(actionInput);
                
                const idInput = document.createElement('input');
                idInput.type = 'hidden';
                idInput.name = 'notificationId';
                idInput.value = id;
                form.appendChild(idInput);
                
                const statusInput = document.createElement('input');
                statusInput.type = 'hidden';
                statusInput.name = 'isActive';
                statusInput.value = currentStatus ? '0' : '1';
                form.appendChild(statusInput);
                
                document.body.appendChild(form);
                console.log('Form created, submitting...');
                form.submit();
            } else {
                console.log('User cancelled');
            }
        }
        
        // Delete notification
        function deleteNotification(id) {
            console.log('Delete notification called with ID:', id);
            if (confirm('⚠️ Are you sure you want to DELETE this announcement?\n\nThis action cannot be undone!')) {
                console.log('User confirmed deletion, submitting form...');
                const form = document.createElement('form');
                form.method = 'POST';
                form.action = '<%= request.getContextPath() %>/super-save-notification';
                
                const actionInput = document.createElement('input');
                actionInput.type = 'hidden';
                actionInput.name = 'action';
                actionInput.value = 'delete';
                form.appendChild(actionInput);
                
                const idInput = document.createElement('input');
                idInput.type = 'hidden';
                idInput.name = 'notificationId';
                idInput.value = id;
                form.appendChild(idInput);
                
                document.body.appendChild(form);
                console.log('Form created, submitting...');
                form.submit();
            } else {
                console.log('User cancelled deletion');
            }
        }
        
        // Expiry date preview
        document.getElementById('expiryDate').addEventListener('change', function() {
            const preview = document.getElementById('expiryDatePreview');
            if (this.value) {
                const date = new Date(this.value);
                preview.textContent = '✓ Will expire on: ' + date.toLocaleString('en-US', {
                    month: 'short',
                    day: 'numeric',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                });
                preview.style.display = 'block';
            } else {
                preview.style.display = 'none';
            }
        });
        
        // Form validation
        document.getElementById('notificationForm').addEventListener('submit', function(e) {
            const title = document.getElementById('title').value.trim();
            const message = document.getElementById('message').value.trim();
            const expiryDate = document.getElementById('expiryDate').value;
            
            // Debug logging
            console.log('=== FORM SUBMISSION DEBUG ===');
            console.log('Title:', title);
            console.log('Expiry Date Value:', expiryDate);
            console.log('Expiry Date Empty?:', expiryDate === '');
            console.log('All Form Data:');
            const formData = new FormData(this);
            for (let [key, value] of formData.entries()) {
                console.log(key + ':', value);
            }
            console.log('============================');
            
            if (title.length < 5) {
                e.preventDefault();
                alert('Title must be at least 5 characters long');
                return false;
            }
            
            if (message.length < 10) {
                e.preventDefault();
                alert('Message must be at least 10 characters long');
                return false;
            }
            
            // Show expiry date info if set
            if (expiryDate) {
                console.log('✓ Expiry date is set to:', expiryDate);
            } else {
                console.log('ℹ No expiry date set - notification will not expire');
            }
        });
        
        // Edit form validation
        document.getElementById('editNotificationForm').addEventListener('submit', function(e) {
            const title = document.getElementById('edit_title').value.trim();
            const message = document.getElementById('edit_message').value.trim();
            const notificationType = document.querySelector('#edit_typeSelector input[name="notificationType"]:checked');
            const priority = document.querySelector('#edit_prioritySelector input[name="priority"]:checked');
            
            console.log('=== EDIT FORM SUBMISSION ===');
            console.log('Title:', title);
            console.log('Message:', message);
            console.log('Notification ID:', document.getElementById('edit_notificationId').value);
            console.log('Type checked element:', notificationType);
            console.log('Type value:', notificationType ? notificationType.value : 'NOT SELECTED');
            console.log('Priority checked element:', priority);
            console.log('Priority value:', priority ? priority.value : 'NOT SELECTED');
            
            if (title.length < 5) {
                e.preventDefault();
                alert('Title must be at least 5 characters long');
                return false;
            }
            
            if (message.length < 10) {
                e.preventDefault();
                alert('Message must be at least 10 characters long');
                return false;
            }
            
            if (!notificationType) {
                e.preventDefault();
                alert('Please select a notification type');
                return false;
            }
            
            if (!priority) {
                e.preventDefault();
                alert('Please select a priority level');
                return false;
            }
            
            console.log('Edit form validation passed, submitting...');
        });
        
        // Make functions globally accessible from onclick handlers
        window.editNotification = editNotification;
        window.toggleNotification = toggleNotification;
        window.deleteNotification = deleteNotification;
        window.closeEditModal = closeEditModal;
        
        console.log('Notification management page loaded. Functions registered:', {
            editNotification: typeof window.editNotification,
            toggleNotification: typeof window.toggleNotification,
            deleteNotification: typeof window.deleteNotification,
            notificationsCount: notificationsData.length
        });
    </script>
</body>
</html>
