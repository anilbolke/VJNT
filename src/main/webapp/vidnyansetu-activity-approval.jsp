<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.util.DatabaseConnection" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.Timestamp" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%!
    // Head Master approval queue for VidnyanSetu activities — same
    // Post/Redirect/Get pattern, same approval_status/is_visible/approved_by/
    // rejection_reason columns and semantics as approve-videos.jsp
    // (student_videos), just applied to vidnyansetu_activities.
    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) { response.sendRedirect("login.jsp"); return; }

    if (user.getUserType() != User.UserType.HEAD_MASTER && user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
        response.sendRedirect("school-dashboard-enhanced.jsp");
        return;
    }

    String udiseNo = user.getUdiseNo();

    // ---- Handle Approve/Reject action (POST/Redirect/GET) ----
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String doAction = request.getParameter("doAction");
        String activityIdStr = request.getParameter("activityId");

        if (doAction != null && activityIdStr != null) {
            try {
                int activityId = Integer.parseInt(activityIdStr);
                Connection actionConn = DatabaseConnection.getConnection();
                try {
                    if ("approve".equals(doAction)) {
                        PreparedStatement ps = actionConn.prepareStatement(
                            "UPDATE vidnyansetu_activities SET approval_status = 'APPROVED', is_visible = TRUE, "
                          + "approved_by = ?, approved_by_name = ?, approval_date = ? "
                          + "WHERE activity_id = ? AND udise_no = ? AND approval_status = 'PENDING'");
                        ps.setInt(1, user.getUserId());
                        ps.setString(2, user.getUsername());
                        ps.setTimestamp(3, new Timestamp(System.currentTimeMillis()));
                        ps.setInt(4, activityId);
                        ps.setString(5, udiseNo);
                        ps.executeUpdate();
                        ps.close();
                    } else if ("reject".equals(doAction)) {
                        String rejectionReason = request.getParameter("rejectionReason");
                        if (rejectionReason == null) rejectionReason = "";
                        PreparedStatement ps = actionConn.prepareStatement(
                            "UPDATE vidnyansetu_activities SET approval_status = 'REJECTED', is_visible = FALSE, "
                          + "approved_by = ?, approved_by_name = ?, approval_date = ?, rejection_reason = ? "
                          + "WHERE activity_id = ? AND udise_no = ? AND approval_status = 'PENDING'");
                        ps.setInt(1, user.getUserId());
                        ps.setString(2, user.getUsername());
                        ps.setTimestamp(3, new Timestamp(System.currentTimeMillis()));
                        ps.setString(4, rejectionReason.trim());
                        ps.setInt(5, activityId);
                        ps.setString(6, udiseNo);
                        ps.executeUpdate();
                        ps.close();
                    }
                } finally {
                    actionConn.close();
                }
            } catch (Exception actionEx) {
                actionEx.printStackTrace();
            }
        }

        String rClass = request.getParameter("classFilter"); if (rClass == null) rClass = "";
        String rStudentSearch = request.getParameter("studentSearch"); if (rStudentSearch == null) rStudentSearch = "";
        String rStatus = request.getParameter("statusFilter"); if (rStatus == null) rStatus = "";
        String rPage = request.getParameter("page"); if (rPage == null) rPage = "1";

        StringBuilder redirectQs = new StringBuilder();
        redirectQs.append("classFilter=").append(java.net.URLEncoder.encode(rClass, "UTF-8"));
        redirectQs.append("&studentSearch=").append(java.net.URLEncoder.encode(rStudentSearch, "UTF-8"));
        redirectQs.append("&statusFilter=").append(java.net.URLEncoder.encode(rStatus, "UTF-8"));
        redirectQs.append("&page=").append(java.net.URLEncoder.encode(rPage, "UTF-8"));

        response.sendRedirect("vidnyansetu-activity-approval.jsp?" + redirectQs.toString());
        return;
    }

    // ---- Read filter params ----
    String classFilter = request.getParameter("classFilter");
    if (classFilter == null) classFilter = "";
    String studentSearch = request.getParameter("studentSearch");
    if (studentSearch == null) studentSearch = "";

    // Which activities to show: PENDING queue (default), or the APPROVED / REJECTED
    // history, or ALL. Only PENDING rows carry the Approve/Reject buttons.
    String statusFilter = request.getParameter("statusFilter");
    if (statusFilter == null || statusFilter.trim().isEmpty()) statusFilter = "PENDING";
    statusFilter = statusFilter.trim().toUpperCase();
    if (!statusFilter.equals("PENDING") && !statusFilter.equals("APPROVED")
            && !statusFilter.equals("REJECTED") && !statusFilter.equals("ALL")) {
        statusFilter = "PENDING";
    }

    int pageNum = 1;
    try { pageNum = Integer.parseInt(request.getParameter("page")); } catch (Exception e) { pageNum = 1; }
    if (pageNum < 1) pageNum = 1;
    final int pageSize = 10;

    StringBuilder where = new StringBuilder("udise_no = ?");
    List<Object> params = new ArrayList<Object>();
    params.add(udiseNo);

    if (!statusFilter.equals("ALL")) {
        where.append(" AND approval_status = ?");
        params.add(statusFilter);
    }

    if (!classFilter.trim().isEmpty()) {
        where.append(" AND student_class = ?");
        params.add(classFilter.trim());
    }
    if (!studentSearch.trim().isEmpty()) {
        where.append(" AND (student_name LIKE ? OR student_pen LIKE ?)");
        String like = "%" + studentSearch.trim() + "%";
        params.add(like);
        params.add(like);
    }
    String whereClause = where.toString();

    Connection conn = null;
    int totalCount = 0;
    List<Object[]> rows = new ArrayList<Object[]>();
    List<String> classOptions = new ArrayList<String>();
    String errorMessage = null;

    try {
        conn = DatabaseConnection.getConnection();

        PreparedStatement countStmt = conn.prepareStatement(
            "SELECT COUNT(*) FROM vidnyansetu_activities WHERE " + whereClause);
        for (int i = 0; i < params.size(); i++) countStmt.setObject(i + 1, params.get(i));
        ResultSet countRs = countStmt.executeQuery();
        if (countRs.next()) totalCount = countRs.getInt(1);
        countRs.close();
        countStmt.close();

        int offset = (pageNum - 1) * pageSize;
        PreparedStatement pstmt = conn.prepareStatement(
            "SELECT activity_id, student_name, student_pen, student_class, week_label, week_topic, "
          + "day_label, day_topic, activity_date, description, video_url, video_thumbnail_url, "
          + "video_filename, video_size, created_by, created_date, "
          + "approval_status, approved_by_name, approval_date, rejection_reason "
          + "FROM vidnyansetu_activities WHERE " + whereClause + " ORDER BY created_date DESC LIMIT ? OFFSET ?");
        for (int i = 0; i < params.size(); i++) pstmt.setObject(i + 1, params.get(i));
        pstmt.setInt(params.size() + 1, pageSize);
        pstmt.setInt(params.size() + 2, offset);

        ResultSet rs = pstmt.executeQuery();
        while (rs.next()) {
            long fileSize = rs.getLong("video_size");
            String sizeDisplay = fileSize < 1024 ? fileSize + " B"
                : fileSize < 1024 * 1024 ? String.format("%.2f KB", fileSize / 1024.0)
                : String.format("%.2f MB", fileSize / (1024.0 * 1024));
            java.sql.Timestamp apprTs = rs.getTimestamp("approval_date");
            rows.add(new Object[]{
                rs.getInt("activity_id"), rs.getString("student_name"), rs.getString("student_pen"),
                rs.getString("student_class"), rs.getString("week_label"), rs.getString("week_topic"),
                rs.getString("day_label"), rs.getString("day_topic"), rs.getDate("activity_date"),
                rs.getString("description"), rs.getString("video_url"), rs.getString("video_thumbnail_url"),
                rs.getString("video_filename"), sizeDisplay, rs.getString("created_by"),
                String.valueOf(rs.getTimestamp("created_date")),
                rs.getString("approval_status"), rs.getString("approved_by_name"),
                apprTs == null ? null : apprTs.toString(), rs.getString("rejection_reason")
            });
        }
        rs.close();
        pstmt.close();

        PreparedStatement clsStmt = conn.prepareStatement(
            "SELECT DISTINCT student_class FROM vidnyansetu_activities WHERE udise_no = ? "
          + "ORDER BY FIELD(student_class,'III','IV','V','VI','VII','VIII','IX')");
        clsStmt.setString(1, udiseNo);
        ResultSet clsRs = clsStmt.executeQuery();
        while (clsRs.next()) classOptions.add(clsRs.getString(1));
        clsRs.close();
        clsStmt.close();

    } catch (Exception e) {
        errorMessage = e.getMessage();
        e.printStackTrace();
    } finally {
        try { if (conn != null) conn.close(); } catch (Exception e) {}
    }

    int totalPages = Math.max(1, (int) Math.ceil(totalCount / (double) pageSize));
    if (pageNum > totalPages) pageNum = totalPages;

    StringBuilder qs = new StringBuilder();
    qs.append("classFilter=").append(java.net.URLEncoder.encode(classFilter, "UTF-8"));
    qs.append("&studentSearch=").append(java.net.URLEncoder.encode(studentSearch, "UTF-8"));
    qs.append("&statusFilter=").append(java.net.URLEncoder.encode(statusFilter, "UTF-8"));
    String baseQs = qs.toString();

    String statusLabel = statusFilter.equals("PENDING")  ? "Pending Approval"
                       : statusFilter.equals("APPROVED") ? "Approved"
                       : statusFilter.equals("REJECTED") ? "Rejected" : "All";
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Approve VidnyanSetu Activities - VJNT Class Management</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        body {
            background: linear-gradient(135deg, #f97316 0%, #ea580c 100%);
            min-height: 100vh;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .container { margin-top: 30px; margin-bottom: 30px; }
        .header-card, .filter-card, .table-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.15);
            margin-bottom: 25px;
        }
        .stats-card {
            background: linear-gradient(135deg, #f97316 0%, #ea580c 100%);
            color: white;
            padding: 20px;
            border-radius: 15px;
            text-align: center;
            margin-bottom: 25px;
        }
        .stats-number { font-size: 44px; font-weight: bold; }
        .filter-card label { font-size: 12px; font-weight: bold; color: #ea580c; text-transform: uppercase; margin-bottom: 4px; }
        table { margin-top: 5px; font-size: 12.5px; }
        th, td { padding: 8px 10px !important; }
        thead th { background: #ea580c !important; color: #ffffff !important; white-space: nowrap; font-weight: 600; position: sticky; top: 0; z-index: 2; border-bottom: 2px solid #c2410c; }
        td { vertical-align: middle; }
        tbody tr:hover { background-color: #fff7ed !important; }
        .badge-week { background: #f97316; font-size: 12px; padding: 6px 10px; }
        .topic-cell { max-width: 220px; }
        .topic-line { font-size: 12px; color: #475569; }
        .topic-line strong { color: #1e293b; }
        .thumb { width: 90px; height: 51px; object-fit: cover; border-radius: 6px; background: #000; cursor: pointer; }
        .empty-state { text-align: center; padding: 50px 20px; color: #666; }
        .empty-state i { font-size: 64px; color: #ddd; margin-bottom: 15px; }
        .pagination-bar { display: flex; justify-content: space-between; align-items: center; margin-top: 15px; }
        .video-modal-overlay { display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.85); z-index: 1050; align-items: center; justify-content: center; padding: 20px; }
        .video-modal-box { position: relative; width: 100%; max-width: 900px; }
        .video-modal-close { position: absolute; top: -40px; right: 0; background: none; border: none; color: white; font-size: 32px; line-height: 1; cursor: pointer; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header-card">
            <div class="row align-items-center">
                <div class="col-md-8">
                    <h2><i class="fas fa-flask"></i> VidnyanSetu Activity Approval</h2>
                    <p class="text-muted mb-0">Review activities (with video) submitted by school coordinators</p>
                    <p class="mb-0"><strong>School:</strong> <%= user.getUdiseNo() %> | <strong>Headmaster:</strong> <%= user.getUsername() %></p>
                </div>
                <div class="col-md-4 text-end">
                    <button class="btn btn-primary" onclick="window.location.href='school-dashboard-enhanced.jsp'">
                        <i class="fas fa-home"></i> Back to Dashboard
                    </button>
                </div>
            </div>
        </div>

        <div class="stats-card">
            <div class="stats-number"><%= totalCount %></div>
            <div>VidnyanSetu Activities &mdash; <%= statusLabel %></div>
        </div>

        <div class="filter-card">
            <form method="get" action="vidnyansetu-activity-approval.jsp">
                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="form-label d-block">Status</label>
                        <select class="form-select" name="statusFilter" onchange="this.form.submit()">
                            <option value="PENDING"  <%= statusFilter.equals("PENDING")  ? "selected" : "" %>>Pending Approval</option>
                            <option value="APPROVED" <%= statusFilter.equals("APPROVED") ? "selected" : "" %>>Approved</option>
                            <option value="REJECTED" <%= statusFilter.equals("REJECTED") ? "selected" : "" %>>Rejected</option>
                            <option value="ALL"      <%= statusFilter.equals("ALL")      ? "selected" : "" %>>All</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label d-block">Class</label>
                        <select class="form-select" name="classFilter" onchange="this.form.submit()">
                            <option value="">All</option>
                            <% for (String c : classOptions) { %>
                                <option value="<%= c %>" <%= classFilter.equals(c) ? "selected" : "" %>>इयत्ता <%= c %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col-md-4 d-flex align-items-end">
                        <button type="submit" class="btn btn-sm btn-primary me-2"><i class="fas fa-search"></i> Apply</button>
                        <a href="vidnyansetu-activity-approval.jsp" class="btn btn-sm btn-outline-secondary"><i class="fas fa-times"></i> Clear</a>
                    </div>
                </div>
            </form>
        </div>

        <div class="table-card">
<%
    if (errorMessage != null) {
%>
            <div class="empty-state">
                <i class="fas fa-exclamation-triangle"></i>
                <h5>Could Not Load Activities</h5>
                <p><%= esc(errorMessage) %></p>
            </div>
<%
    } else if (rows.isEmpty()) {
%>
            <div class="empty-state">
                <i class="fas fa-check-circle"></i>
                <h5><%= (statusFilter.equals("PENDING") && classFilter.isEmpty()) ? "All Caught Up!" : "No Activities Found" %></h5>
                <p>No <%= esc(statusLabel.toLowerCase()) %> VidnyanSetu activities<%= classFilter.isEmpty() ? "" : " for इयत्ता " + esc(classFilter) %>.</p>
            </div>
<%
    } else {
%>
            <div class="table-responsive">
                <table class="table table-hover table-striped align-middle mb-0">
                    <thead>
                        <tr>
                            <th>Class</th>
                            <th>Week / Day</th>
                            <th>Activity Date</th>
                            <th>Topic</th>
                            <th>Notes</th>
                            <th>Video</th>
                            <th>Submitted By</th>
                            <th>Submitted On</th>
                            <th>Status</th>
                            <th>Review</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
<%
        for (Object[] row : rows) {
            int activityId = (Integer) row[0];
            String weekLabel = (String) row[4], weekTopic = (String) row[5];
            String dayLabel = (String) row[6], dayTopic = (String) row[7];
            String desc = (String) row[9];
            Object activityDate = row[8];
            String videoUrl = (String) row[10], videoFilename = (String) row[12];
            String videoSizeDisplay = (String) row[13];
            String apprStatus = row[16] != null ? (String) row[16] : "PENDING";
            String apprByName = (String) row[17];
            String apprDate = (String) row[18];
            String rejReason = (String) row[19];
            String statusBadge = "APPROVED".equals(apprStatus)
                    ? "<span class='badge bg-success'>Approved</span>"
                    : "REJECTED".equals(apprStatus)
                        ? "<span class='badge bg-danger'>Rejected</span>"
                        : "<span class='badge bg-warning text-dark'>Pending</span>";
%>
                        <tr>
                            <td><span class="badge badge-week">इयत्ता <%= esc((String) row[3]) %></span></td>
                            <td><%= esc(weekLabel != null ? weekLabel.trim() : "") %> / <%= esc(dayLabel) %></td>
                            <td class="text-nowrap"><%= activityDate != null ? esc(activityDate.toString()) : "<span class='text-muted'>&mdash;</span>" %></td>
                            <td class="topic-cell">
                                <div class="topic-line"><strong>आठवडा:</strong> <%= esc(weekTopic) %></div>
                                <div class="topic-line"><strong>दिवस:</strong> <%= esc(dayTopic) %></div>
                            </td>
                            <td><%= desc != null && !desc.isEmpty() ? esc(desc) : "<span class='text-muted'>&mdash;</span>" %></td>
                            <td>
<%
            if (videoUrl != null && !videoUrl.isEmpty()) {
%>
                                <button type="button" class="btn btn-sm btn-outline-primary"
                                        data-video-url="<%= esc(videoUrl) %>" onclick="openVideoModal(this.getAttribute('data-video-url'))"
                                        title="<%= esc(videoFilename) %> (<%= videoSizeDisplay %>)">
                                    <i class="fas fa-play"></i> View Video
                                </button>
<%
            } else {
%>
                                <span class="text-muted">&mdash;</span>
<%
            }
%>
                            </td>
                            <td><%= esc((String) row[14]) %></td>
                            <td class="text-nowrap"><%= row[15] %></td>
                            <td><%= statusBadge %></td>
                            <td class="topic-cell">
<%
            if ("PENDING".equals(apprStatus)) {
%>
                                <span class="text-muted">&mdash;</span>
<%
            } else {
%>
                                <div class="topic-line"><strong><%= "APPROVED".equals(apprStatus) ? "Approved by:" : "Rejected by:" %></strong> <%= esc(apprByName != null ? apprByName : "-") %></div>
                                <div class="topic-line"><strong>On:</strong> <%= esc(apprDate != null ? apprDate : "-") %></div>
<%
                if ("REJECTED".equals(apprStatus) && rejReason != null && !rejReason.trim().isEmpty()) {
%>
                                <div class="topic-line" style="color:#991b1b;"><strong>Reason:</strong> <%= esc(rejReason) %></div>
<%
                }
            }
%>
                            </td>
                            <td class="text-nowrap">
<%
            if ("PENDING".equals(apprStatus)) {
%>
                                <form method="post" action="vidnyansetu-activity-approval.jsp" class="d-inline" onsubmit="return confirm('Approve this activity?')">
                                    <input type="hidden" name="doAction" value="approve">
                                    <input type="hidden" name="activityId" value="<%= activityId %>">
                                    <input type="hidden" name="classFilter" value="<%= esc(classFilter) %>">
                                    <input type="hidden" name="studentSearch" value="<%= esc(studentSearch) %>">
                                    <input type="hidden" name="statusFilter" value="<%= esc(statusFilter) %>">
                                    <input type="hidden" name="page" value="<%= pageNum %>">
                                    <button type="submit" class="btn btn-sm btn-success me-1"><i class="fas fa-check"></i> Approve</button>
                                </form>
                                <button type="button" class="btn btn-sm btn-danger" onclick="showRejectModal(<%= activityId %>)">
                                    <i class="fas fa-times"></i> Reject
                                </button>
<%
            } else {
%>
                                <span class="text-muted">&mdash;</span>
<%
            }
%>
                            </td>
                        </tr>
<%
        }
%>
                    </tbody>
                </table>
            </div>

            <div class="pagination-bar">
                <span class="text-muted">Showing page <%= pageNum %> of <%= totalPages %> (<%= totalCount %> total)</span>
                <div>
                    <% if (pageNum > 1) { %>
                        <a href="vidnyansetu-activity-approval.jsp?<%= baseQs %>&page=<%= pageNum - 1 %>" class="btn btn-outline-primary btn-sm"><i class="fas fa-chevron-left"></i> Previous</a>
                    <% } else { %>
                        <button class="btn btn-outline-secondary btn-sm" disabled><i class="fas fa-chevron-left"></i> Previous</button>
                    <% } %>
                    <% if (pageNum < totalPages) { %>
                        <a href="vidnyansetu-activity-approval.jsp?<%= baseQs %>&page=<%= pageNum + 1 %>" class="btn btn-outline-primary btn-sm">Next <i class="fas fa-chevron-right"></i></a>
                    <% } else { %>
                        <button class="btn btn-outline-secondary btn-sm" disabled>Next <i class="fas fa-chevron-right"></i></button>
                    <% } %>
                </div>
            </div>
<%
    }
%>
        </div>
    </div>

    <div id="videoModalOverlay" class="video-modal-overlay" onclick="if (event.target === this) closeVideoModal()">
        <div class="video-modal-box">
            <button type="button" class="video-modal-close" onclick="closeVideoModal()" aria-label="Close">&times;</button>
            <video id="videoModalPlayer" controls autoplay style="width:100%; max-height:80vh; border-radius:8px; background:#000;"></video>
        </div>
    </div>

    <div id="rejectModalOverlay" class="video-modal-overlay" onclick="if (event.target === this) closeRejectModal()">
        <div class="video-modal-box" style="max-width: 480px;">
            <button type="button" class="video-modal-close" onclick="closeRejectModal()" aria-label="Close">&times;</button>
            <div class="bg-white rounded p-4">
                <h5>Reject Activity</h5>
                <p class="text-muted">Please provide a reason for rejecting this activity.</p>
                <form method="post" action="vidnyansetu-activity-approval.jsp" id="rejectForm" onsubmit="return validateRejectForm()">
                    <input type="hidden" name="doAction" value="reject">
                    <input type="hidden" name="activityId" id="rejectActivityId" value="">
                    <input type="hidden" name="classFilter" value="<%= esc(classFilter) %>">
                    <input type="hidden" name="studentSearch" value="<%= esc(studentSearch) %>">
                    <input type="hidden" name="statusFilter" value="<%= esc(statusFilter) %>">
                    <input type="hidden" name="page" value="<%= pageNum %>">
                    <textarea class="form-control mb-3" name="rejectionReason" id="rejectionReason" rows="4" placeholder="Enter rejection reason..."></textarea>
                    <div class="text-end">
                        <button type="button" class="btn btn-secondary me-2" onclick="closeRejectModal()">Cancel</button>
                        <button type="submit" class="btn btn-danger"><i class="fas fa-times-circle"></i> Reject Activity</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        function openVideoModal(url) {
            var player = document.getElementById('videoModalPlayer');
            player.src = url;
            document.getElementById('videoModalOverlay').style.display = 'flex';
        }
        function closeVideoModal() {
            var player = document.getElementById('videoModalPlayer');
            player.pause();
            player.src = '';
            document.getElementById('videoModalOverlay').style.display = 'none';
        }
        function showRejectModal(activityId) {
            document.getElementById('rejectActivityId').value = activityId;
            document.getElementById('rejectionReason').value = '';
            document.getElementById('rejectModalOverlay').style.display = 'flex';
        }
        function closeRejectModal() {
            document.getElementById('rejectModalOverlay').style.display = 'none';
        }
        function validateRejectForm() {
            if (!document.getElementById('rejectionReason').value.trim()) {
                alert('Please provide a rejection reason');
                return false;
            }
            return true;
        }
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') { closeVideoModal(); closeRejectModal(); }
        });
    </script>
</body>
</html>
