package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import org.json.JSONArray;
import org.json.JSONObject;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;

/**
 * Support Ticket System
 *
 * Raise tickets  : TEACHER, SCHOOL_COORDINATOR, HEAD_MASTER
 * Take action    : DIVISION (own division), SUPER_DIVISION_OFFICER (all)
 *
 * Endpoints (single servlet, action parameter):
 *   GET  /tickets?action=my                       - my raised tickets
 *   GET  /tickets?action=division[&status=OPEN]   - tickets for division login
 *   POST /tickets  action=create                  - raise a ticket
 *   POST /tickets  action=update                  - division takes action
 *
 * Statuses: OPEN → IN_PROGRESS → RESOLVED / REJECTED → CLOSED
 *
 * Attachments: up to 3 PDF/JPG/PNG files (max 5 MB each) can be uploaded with
 * a ticket (multipart field name "files"); stored in ticket_attachments and
 * served by TicketAttachmentServlet.
 */
@WebServlet("/tickets")
@MultipartConfig(fileSizeThreshold = 512 * 1024, maxFileSize = 5 * 1024 * 1024, maxRequestSize = 20 * 1024 * 1024)
public class TicketServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final int MAX_ATTACHMENTS = 3;
    private static final long MAX_ATTACHMENT_SIZE = 5 * 1024 * 1024; // 5 MB

    private static final String CREATE_ATTACHMENTS_TABLE =
            "CREATE TABLE IF NOT EXISTS ticket_attachments (" +
            "attachment_id INT AUTO_INCREMENT PRIMARY KEY, " +
            "ticket_id INT NOT NULL, " +
            "file_name VARCHAR(255) DEFAULT NULL, " +
            "content_type VARCHAR(100) DEFAULT NULL, " +
            "file_size INT DEFAULT 0, " +
            "file_data MEDIUMBLOB, " +
            "created_date DATETIME DEFAULT CURRENT_TIMESTAMP, " +
            "KEY idx_att_ticket (ticket_id)" +
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

    private static final String CREATE_TABLE =
            "CREATE TABLE IF NOT EXISTS support_tickets (" +
            "ticket_id INT AUTO_INCREMENT PRIMARY KEY, " +
            "raised_by_user_id INT NOT NULL, " +
            "raised_by_name VARCHAR(200) DEFAULT NULL, " +
            "raised_by_role VARCHAR(50) DEFAULT NULL, " +
            "raised_by_mobile VARCHAR(15) DEFAULT NULL, " +
            "udise_no VARCHAR(50) DEFAULT NULL, " +
            "school_name VARCHAR(255) DEFAULT NULL, " +
            "district_name VARCHAR(100) DEFAULT NULL, " +
            "division_name VARCHAR(100) DEFAULT NULL, " +
            "category VARCHAR(50) DEFAULT 'OTHER', " +
            "priority VARCHAR(20) DEFAULT 'MEDIUM', " +
            "subject VARCHAR(255) NOT NULL, " +
            "description TEXT, " +
            "status VARCHAR(20) DEFAULT 'OPEN', " +
            "action_remarks TEXT, " +
            "action_by VARCHAR(100) DEFAULT NULL, " +
            "action_date DATETIME DEFAULT NULL, " +
            "created_date DATETIME DEFAULT CURRENT_TIMESTAMP, " +
            "updated_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, " +
            "KEY idx_ticket_status (status), " +
            "KEY idx_ticket_division (division_name), " +
            "KEY idx_ticket_user (raised_by_user_id)" +
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

    private static boolean canRaise(User user) {
        return user.getUserType() == User.UserType.TEACHER
                || user.getUserType() == User.UserType.SCHOOL_COORDINATOR
                || user.getUserType() == User.UserType.HEAD_MASTER;
    }

    private static boolean canAct(User user) {
        return user.getUserType() == User.UserType.DIVISION
                || user.getUserType() == User.UserType.SUPER_DIVISION_OFFICER;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        User user = sessionUser(request);
        if (user == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"error\": \"Session expired\"}");
            return;
        }

        String action = request.getParameter("action");
        JSONObject result;

        if ("my".equals(action) && (canRaise(user) || canAct(user))) {
            result = listMyTickets(user);
        } else if ("division".equals(action) && canAct(user)) {
            String divisionName = user.getUserType() == User.UserType.SUPER_DIVISION_OFFICER
                    ? null : user.getDivisionName();
            result = listDivisionTickets(divisionName, request.getParameter("status"));
        } else {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            result = new JSONObject().put("error", "Unauthorized access");
        }

        out.print(result.toString());
        out.flush();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        User user = sessionUser(request);
        if (user == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"error\": \"Session expired\"}");
            return;
        }

        String action = request.getParameter("action");
        JSONObject result;

        if ("create".equals(action) && canRaise(user)) {
            result = createTicket(user, request);
        } else if ("update".equals(action) && canAct(user)) {
            result = updateTicket(user, request);
        } else {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            result = new JSONObject().put("error", "Unauthorized access");
        }

        out.print(result.toString());
        out.flush();
    }

    private User sessionUser(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session == null ? null : (User) session.getAttribute("user");
    }

    // ─────────────────────────── create ───────────────────────────

    private JSONObject createTicket(User user, HttpServletRequest request) {
        JSONObject result = new JSONObject();

        String category = trimOrDefault(request.getParameter("category"), "OTHER");
        String priority = trimOrDefault(request.getParameter("priority"), "MEDIUM");
        String subject = request.getParameter("subject");
        String description = request.getParameter("description");

        if (subject == null || subject.trim().isEmpty()) {
            return result.put("success", false).put("error", "Subject is required");
        }
        if (description == null || description.trim().isEmpty()) {
            return result.put("success", false).put("error", "Description is required");
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureTable(conn);

            // Best-effort school/district/division context
            String udise = user.getUdiseNo();
            String district = user.getDistrictName();
            String division = user.getDivisionName();
            String schoolName = null;

            if (udise != null && !udise.isEmpty()) {
                String sSql = "SELECT school_name, district_name FROM schools WHERE udise_no = ? LIMIT 1";
                try (PreparedStatement ps = conn.prepareStatement(sSql)) {
                    ps.setString(1, udise);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            schoolName = rs.getString("school_name");
                            if (district == null || district.isEmpty()) {
                                district = rs.getString("district_name");
                            }
                        }
                    }
                }
                if (division == null || division.isEmpty()) {
                    String dSql = "SELECT division FROM students WHERE udise_no = ? AND division IS NOT NULL LIMIT 1";
                    try (PreparedStatement ps = conn.prepareStatement(dSql)) {
                        ps.setString(1, udise);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) division = rs.getString("division");
                        }
                    }
                }
            }

            String sql = "INSERT INTO support_tickets (raised_by_user_id, raised_by_name, raised_by_role, " +
                         "raised_by_mobile, udise_no, school_name, district_name, division_name, " +
                         "category, priority, subject, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, user.getUserId());
                ps.setString(2, user.getFullName() != null ? user.getFullName() : user.getUsername());
                ps.setString(3, user.getUserType().name());
                ps.setString(4, user.getMobile() != null ? user.getMobile() : user.getUsername());
                ps.setString(5, udise);
                ps.setString(6, schoolName);
                ps.setString(7, district);
                ps.setString(8, division);
                ps.setString(9, category);
                ps.setString(10, priority);
                ps.setString(11, subject.trim());
                ps.setString(12, description.trim());
                ps.executeUpdate();

                int ticketId = 0;
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) ticketId = keys.getInt(1);
                }

                // Save uploaded attachments (PDF / images), if any
                int saved = 0;
                JSONArray skipped = new JSONArray();
                String contentType = request.getContentType();
                if (ticketId > 0 && contentType != null && contentType.toLowerCase().startsWith("multipart/")) {
                    saved = saveAttachments(conn, ticketId, request, skipped);
                }

                result.put("success", true);
                result.put("ticketId", ticketId);
                result.put("ticketNo", "TKT-" + String.format("%05d", ticketId));
                result.put("attachmentsSaved", saved);
                result.put("attachmentsSkipped", skipped);
                result.put("message", "Ticket raised successfully");
            }

        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false).put("error", e.getMessage());
        }
        return result;
    }

    /** Stores valid attachment parts; invalid ones are listed in skipped with a reason. */
    private int saveAttachments(Connection conn, int ticketId, HttpServletRequest request, JSONArray skipped)
            throws IOException, ServletException, SQLException {
        int saved = 0;
        String sql = "INSERT INTO ticket_attachments (ticket_id, file_name, content_type, file_size, file_data) " +
                     "VALUES (?, ?, ?, ?, ?)";
        for (Part part : request.getParts()) {
            if (!"files".equals(part.getName()) || part.getSize() == 0) continue;

            String fileName = part.getSubmittedFileName();
            if (fileName == null || fileName.trim().isEmpty()) continue;
            fileName = fileName.replaceAll(".*[/\\\\]", ""); // strip any path

            if (saved >= MAX_ATTACHMENTS) {
                skipped.put(fileName + " (maximum " + MAX_ATTACHMENTS + " files allowed)");
                continue;
            }
            if (part.getSize() > MAX_ATTACHMENT_SIZE) {
                skipped.put(fileName + " (larger than 5 MB)");
                continue;
            }
            String type = detectContentType(fileName, part.getContentType());
            if (type == null) {
                skipped.put(fileName + " (only PDF, JPG and PNG allowed)");
                continue;
            }

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, ticketId);
                ps.setString(2, fileName);
                ps.setString(3, type);
                ps.setLong(4, part.getSize());
                ps.setBinaryStream(5, part.getInputStream());
                ps.executeUpdate();
                saved++;
            }
        }
        return saved;
    }

    /** Returns the safe content type for allowed extensions, or null if not allowed. */
    static String detectContentType(String fileName, String declaredType) {
        String lower = fileName.toLowerCase();
        if (lower.endsWith(".pdf")) return "application/pdf";
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
        if (lower.endsWith(".png")) return "image/png";
        return null;
    }

    // ─────────────────────────── lists ───────────────────────────

    private JSONObject listMyTickets(User user) {
        JSONObject result = new JSONObject();
        String sql = "SELECT * FROM support_tickets WHERE raised_by_user_id = ? ORDER BY ticket_id DESC";

        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureTable(conn);
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, user.getUserId());
                try (ResultSet rs = ps.executeQuery()) {
                    JSONArray tickets = ticketsToJson(rs);
                    attachAttachments(conn, tickets);
                    result.put("tickets", tickets);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        return result;
    }

    private JSONObject listDivisionTickets(String divisionName, String statusFilter) {
        JSONObject result = new JSONObject();

        StringBuilder sql = new StringBuilder("SELECT * FROM support_tickets WHERE 1=1 ");
        if (divisionName != null) {
            sql.append("AND division_name = ? ");
        }
        if (statusFilter != null && !statusFilter.trim().isEmpty()) {
            sql.append("AND status = ? ");
        }
        sql.append("ORDER BY CASE status WHEN 'OPEN' THEN 0 WHEN 'IN_PROGRESS' THEN 1 ELSE 2 END, ticket_id DESC");

        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureTable(conn);
            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                int i = 1;
                if (divisionName != null) ps.setString(i++, divisionName);
                if (statusFilter != null && !statusFilter.trim().isEmpty()) ps.setString(i++, statusFilter.trim());
                try (ResultSet rs = ps.executeQuery()) {
                    JSONArray tickets = ticketsToJson(rs);
                    attachAttachments(conn, tickets);
                    result.put("tickets", tickets);

                    int open = 0, inProgress = 0, resolved = 0, other = 0;
                    for (int t = 0; t < tickets.length(); t++) {
                        String st = tickets.getJSONObject(t).optString("status", "");
                        if ("OPEN".equals(st)) open++;
                        else if ("IN_PROGRESS".equals(st)) inProgress++;
                        else if ("RESOLVED".equals(st)) resolved++;
                        else other++;
                    }
                    result.put("openCount", open);
                    result.put("inProgressCount", inProgress);
                    result.put("resolvedCount", resolved);
                    result.put("otherCount", other);
                    result.put("totalCount", tickets.length());
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
        }
        return result;
    }

    // ─────────────────────────── update ───────────────────────────

    private JSONObject updateTicket(User user, HttpServletRequest request) {
        JSONObject result = new JSONObject();

        String ticketIdStr = request.getParameter("ticketId");
        String status = request.getParameter("status");
        String remarks = request.getParameter("remarks");

        if (ticketIdStr == null || !ticketIdStr.matches("\\d+")) {
            return result.put("success", false).put("error", "Invalid ticketId");
        }
        if (status == null || !status.matches("OPEN|IN_PROGRESS|RESOLVED|REJECTED|CLOSED")) {
            return result.put("success", false).put("error", "Invalid status");
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureTable(conn);

            StringBuilder sql = new StringBuilder(
                    "UPDATE support_tickets SET status = ?, action_remarks = ?, action_by = ?, action_date = NOW() " +
                    "WHERE ticket_id = ? ");
            // Division users may only act on their own division's tickets
            if (user.getUserType() == User.UserType.DIVISION) {
                sql.append("AND division_name = ? ");
            }

            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                ps.setString(1, status);
                ps.setString(2, remarks == null ? null : remarks.trim());
                ps.setString(3, user.getUsername());
                ps.setInt(4, Integer.parseInt(ticketIdStr));
                if (user.getUserType() == User.UserType.DIVISION) {
                    ps.setString(5, user.getDivisionName());
                }

                int rows = ps.executeUpdate();
                if (rows > 0) {
                    result.put("success", true).put("message", "Ticket updated");
                } else {
                    result.put("success", false).put("error", "Ticket not found or not in your division");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
            result.put("success", false).put("error", e.getMessage());
        }
        return result;
    }

    // ─────────────────────────── helpers ───────────────────────────

    private void ensureTable(Connection conn) throws SQLException {
        try (Statement st = conn.createStatement()) {
            st.execute(CREATE_TABLE);
            st.execute(CREATE_ATTACHMENTS_TABLE);
        }
    }

    private JSONArray ticketsToJson(ResultSet rs) throws SQLException {
        JSONArray arr = new JSONArray();
        while (rs.next()) {
            JSONObject t = new JSONObject();
            int id = rs.getInt("ticket_id");
            t.put("ticketId", id);
            t.put("ticketNo", "TKT-" + String.format("%05d", id));
            t.put("raisedByName", nvl(rs.getString("raised_by_name")));
            t.put("raisedByRole", nvl(rs.getString("raised_by_role")));
            t.put("raisedByMobile", nvl(rs.getString("raised_by_mobile")));
            t.put("udiseNo", nvl(rs.getString("udise_no")));
            t.put("schoolName", nvl(rs.getString("school_name")));
            t.put("districtName", nvl(rs.getString("district_name")));
            t.put("divisionName", nvl(rs.getString("division_name")));
            t.put("category", nvl(rs.getString("category")));
            t.put("priority", nvl(rs.getString("priority")));
            t.put("subject", nvl(rs.getString("subject")));
            t.put("description", nvl(rs.getString("description")));
            t.put("status", nvl(rs.getString("status")));
            t.put("actionRemarks", nvl(rs.getString("action_remarks")));
            t.put("actionBy", nvl(rs.getString("action_by")));
            t.put("actionDate", rs.getTimestamp("action_date") == null ? "" : rs.getTimestamp("action_date").toString());
            t.put("createdDate", rs.getTimestamp("created_date") == null ? "" : rs.getTimestamp("created_date").toString());
            arr.put(t);
        }
        return arr;
    }

    /** Adds an "attachments" array (id, name, type, size) to every ticket JSON object. */
    private void attachAttachments(Connection conn, JSONArray tickets) throws SQLException {
        if (tickets.length() == 0) return;

        java.util.Map<Integer, JSONArray> byTicket = new java.util.HashMap<>();
        StringBuilder in = new StringBuilder();
        for (int i = 0; i < tickets.length(); i++) {
            if (i > 0) in.append(",");
            in.append(tickets.getJSONObject(i).getInt("ticketId"));
            byTicket.put(tickets.getJSONObject(i).getInt("ticketId"), new JSONArray());
        }

        String sql = "SELECT attachment_id, ticket_id, file_name, content_type, file_size " +
                     "FROM ticket_attachments WHERE ticket_id IN (" + in + ") ORDER BY attachment_id";
        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                JSONArray arr = byTicket.get(rs.getInt("ticket_id"));
                if (arr == null) continue;
                JSONObject a = new JSONObject();
                a.put("attachmentId", rs.getInt("attachment_id"));
                a.put("fileName", nvl(rs.getString("file_name")));
                a.put("contentType", nvl(rs.getString("content_type")));
                a.put("fileSize", rs.getInt("file_size"));
                arr.put(a);
            }
        }

        for (int i = 0; i < tickets.length(); i++) {
            JSONObject t = tickets.getJSONObject(i);
            t.put("attachments", byTicket.get(t.getInt("ticketId")));
        }
    }

    private static String nvl(String s) {
        return s == null ? "" : s;
    }

    private static String trimOrDefault(String s, String def) {
        return (s == null || s.trim().isEmpty()) ? def : s.trim();
    }
}
