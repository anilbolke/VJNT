package com.vjnt.servlet;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

@WebServlet("/save-notification")
public class SaveNotificationServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        if (!user.getUserType().equals(User.UserType.DIVISION)) {
            response.sendRedirect(request.getContextPath() + "/division-dashboard.jsp");
            return;
        }
        
        String action = request.getParameter("action");
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            if ("create".equals(action)) {
                // Create new notification
                String title = request.getParameter("title");
                String message = request.getParameter("message");
                String notificationType = request.getParameter("notificationType");
                String targetAudience = request.getParameter("targetAudience");
                String district = request.getParameter("district");
                String udiseCode = request.getParameter("udiseCode");
                String expiryDateStr = request.getParameter("expiryDate");
                int priority = Integer.parseInt(request.getParameter("priority"));
                int createdBy = user.getUserId();
                String createdByName = user.getFullName();
                
                // Division is ALWAYS set to Division Head's division
                // They can only send notifications to schools in their division
                String division = user.getDivisionName();
                
                // Convert empty strings to null
                if (district != null && district.trim().isEmpty()) district = null;
                if (udiseCode != null && udiseCode.trim().isEmpty()) udiseCode = null;
                
                // Add debug logging
                
                Timestamp expiryDate = null;
                if (expiryDateStr != null && !expiryDateStr.trim().isEmpty()) {
                    try {
                        // Parse datetime-local format: yyyy-MM-dd'T'HH:mm
                        String originalDateStr = expiryDateStr;
                        expiryDateStr = expiryDateStr.replace("T", " ") + ":00";
                        expiryDate = Timestamp.valueOf(expiryDateStr);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                
                String sql = "INSERT INTO notifications (title, message, notification_type, target_audience, " +
                           "division, district, udise_code, priority, created_by, created_by_name, expiry_date) " +
                           "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, title);
                pstmt.setString(2, message);
                pstmt.setString(3, notificationType);
                pstmt.setString(4, targetAudience);
                pstmt.setString(5, division);
                pstmt.setString(6, district);
                pstmt.setString(7, udiseCode);
                pstmt.setInt(8, priority);
                pstmt.setInt(9, createdBy);
                pstmt.setString(10, createdByName);
                pstmt.setTimestamp(11, expiryDate);
                
                pstmt.executeUpdate();
                
                session.setAttribute("successMessage", "✓ Announcement sent successfully!");
                
            } else if ("update".equals(action)) {
                // Update existing notification
                String notificationIdStr = request.getParameter("notificationId");
                String priorityStr = request.getParameter("priority");
                
                if (notificationIdStr == null || notificationIdStr.trim().isEmpty()) {
                    session.setAttribute("errorMessage", "✗ Error: Notification ID is required");
                    response.sendRedirect(request.getContextPath() + "/manage-notifications.jsp");
                    return;
                }
                
                int notificationId = Integer.parseInt(notificationIdStr);
                String title = request.getParameter("title");
                String message = request.getParameter("message");
                String notificationType = request.getParameter("notificationType");
                String targetAudience = request.getParameter("targetAudience");
                String district = request.getParameter("district");
                String udiseCode = request.getParameter("udiseCode");
                String expiryDateStr = request.getParameter("expiryDate");
                int priority = (priorityStr != null && !priorityStr.trim().isEmpty()) ? Integer.parseInt(priorityStr) : 0;
                
                // Convert empty strings to null
                if (district != null && district.trim().isEmpty()) district = null;
                if (udiseCode != null && udiseCode.trim().isEmpty()) udiseCode = null;
                
                
                Timestamp expiryDate = null;
                if (expiryDateStr != null && !expiryDateStr.trim().isEmpty()) {
                    try {
                        String originalDateStr = expiryDateStr;
                        expiryDateStr = expiryDateStr.replace("T", " ") + ":00";
                        expiryDate = Timestamp.valueOf(expiryDateStr);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                
                String sql = "UPDATE notifications SET title = ?, message = ?, notification_type = ?, " +
                           "target_audience = ?, district = ?, udise_code = ?, priority = ?, expiry_date = ? " +
                           "WHERE notification_id = ? AND created_by = ?";
                
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, title);
                pstmt.setString(2, message);
                pstmt.setString(3, notificationType);
                pstmt.setString(4, targetAudience);
                pstmt.setString(5, district);
                pstmt.setString(6, udiseCode);
                pstmt.setInt(7, priority);
                pstmt.setTimestamp(8, expiryDate);
                pstmt.setInt(9, notificationId);
                pstmt.setInt(10, user.getUserId());
                
                int rowsUpdated = pstmt.executeUpdate();
                
                if (rowsUpdated > 0) {
                    session.setAttribute("successMessage", "✓ Announcement updated successfully!");
                } else {
                    session.setAttribute("errorMessage", "✗ Unable to update announcement. You may not have permission.");
                }
                
            } else if ("toggle".equals(action)) {
                // Toggle notification active/inactive
                String notificationIdStr = request.getParameter("notificationId");
                String isActiveStr = request.getParameter("isActive");
                
                if (notificationIdStr == null || isActiveStr == null) {
                    session.setAttribute("errorMessage", "✗ Error: Missing required parameters");
                    response.sendRedirect(request.getContextPath() + "/manage-notifications.jsp");
                    return;
                }
                
                int notificationId = Integer.parseInt(notificationIdStr);
                int isActive = Integer.parseInt(isActiveStr);
                
                String sql = "UPDATE notifications SET is_active = ? WHERE notification_id = ? AND created_by = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, isActive);
                pstmt.setInt(2, notificationId);
                pstmt.setInt(3, user.getUserId());
                
                pstmt.executeUpdate();
                
                session.setAttribute("successMessage", isActive == 1 ? "✓ Announcement activated!" : "✓ Announcement deactivated!");
                
            } else if ("delete".equals(action)) {
                // Delete notification
                String notificationIdStr = request.getParameter("notificationId");
                
                if (notificationIdStr == null || notificationIdStr.trim().isEmpty()) {
                    session.setAttribute("errorMessage", "✗ Error: Notification ID is required");
                    response.sendRedirect(request.getContextPath() + "/manage-notifications.jsp");
                    return;
                }
                
                int notificationId = Integer.parseInt(notificationIdStr);
                
                String sql = "DELETE FROM notifications WHERE notification_id = ? AND created_by = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, notificationId);
                pstmt.setInt(2, user.getUserId());
                
                pstmt.executeUpdate();
                
                session.setAttribute("successMessage", "✓ Announcement deleted successfully!");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("errorMessage", "✗ Error: " + e.getMessage());
        } finally {
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
            if (conn != null) try { conn.close(); } catch (SQLException e) { }
        }
        
        response.sendRedirect(request.getContextPath() + "/manage-notifications.jsp");
    }
}
