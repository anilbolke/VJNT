package com.vjnt.servlet;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

/**
 * Streams a support-ticket attachment (PDF / image) inline in the browser.
 *
 * GET /ticket-attachment?id=<attachmentId>
 *
 * Access: the user who raised the ticket, DIVISION users of the ticket's
 * division, or the Super Division Officer.
 */
@WebServlet("/ticket-attachment")
public class TicketAttachmentServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("user");
        if (user == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Session expired");
            return;
        }

        String idStr = request.getParameter("id");
        if (idStr == null || !idStr.matches("\\d+")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid attachment id");
            return;
        }

        String sql = "SELECT a.file_name, a.content_type, a.file_size, a.file_data, " +
                     "t.raised_by_user_id, t.division_name " +
                     "FROM ticket_attachments a JOIN support_tickets t ON a.ticket_id = t.ticket_id " +
                     "WHERE a.attachment_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, Integer.parseInt(idStr));
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "Attachment not found");
                    return;
                }

                // Access control
                boolean isRaiser = rs.getInt("raised_by_user_id") == user.getUserId();
                boolean isSdo = user.getUserType() == User.UserType.SUPER_DIVISION_OFFICER;
                boolean isDivision = user.getUserType() == User.UserType.DIVISION
                        && user.getDivisionName() != null
                        && user.getDivisionName().equals(rs.getString("division_name"));
                if (!isRaiser && !isSdo && !isDivision) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied");
                    return;
                }

                String fileName = rs.getString("file_name");
                String contentType = rs.getString("content_type");
                response.setContentType(contentType != null ? contentType : "application/octet-stream");
                response.setHeader("Content-Disposition",
                        "inline; filename=\"" + (fileName == null ? "attachment" : fileName.replace("\"", "")) + "\"");
                int size = rs.getInt("file_size");
                if (size > 0) response.setContentLength(size);

                try (InputStream in = rs.getBinaryStream("file_data");
                     OutputStream out = response.getOutputStream()) {
                    byte[] buffer = new byte[8192];
                    int read;
                    while (in != null && (read = in.read(buffer)) != -1) {
                        out.write(buffer, 0, read);
                    }
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Failed to load attachment");
        }
    }
}
