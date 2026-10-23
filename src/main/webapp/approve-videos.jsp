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
    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    // Check if user is logged in and is a headmaster
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    if (user.getUserType() != User.UserType.HEAD_MASTER && user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER) {
        response.sendRedirect("school-dashboard-enhanced.jsp");
        return;
    }

    String udiseNo = user.getUdiseNo();

    // ---- Handle Approve/Reject action (POST/Redirect/GET) ----
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String doAction = request.getParameter("doAction");
        String videoIdStr = request.getParameter("videoId");

        if (doAction != null && videoIdStr != null) {
            try {
                int videoId = Integer.parseInt(videoIdStr);
                Connection actionConn = DatabaseConnection.getConnection();
                try {
                    if ("approve".equals(doAction)) {
                        PreparedStatement ps = actionConn.prepareStatement(
                            "UPDATE student_videos SET approval_status = 'APPROVED', is_visible = TRUE, "
                          + "approved_by = ?, approved_by_name = ?, approval_date = ? "
                          + "WHERE video_id = ? AND udise_no = ? AND approval_status = 'PENDING'");
                        ps.setInt(1, user.getUserId());
                        ps.setString(2, user.getUsername());
                        ps.setTimestamp(3, new Timestamp(System.currentTimeMillis()));
                        ps.setInt(4, videoId);
                        ps.setString(5, udiseNo);
                        ps.executeUpdate();
                        ps.close();
                    } else if ("reject".equals(doAction)) {
                        String rejectionReason = request.getParameter("rejectionReason");
                        if (rejectionReason == null) rejectionReason = "";
                        PreparedStatement ps = actionConn.prepareStatement(
                            "UPDATE student_videos SET approval_status = 'REJECTED', is_visible = FALSE, "
                          + "approved_by = ?, approved_by_name = ?, approval_date = ?, rejection_reason = ? "
                          + "WHERE video_id = ? AND udise_no = ? AND approval_status = 'PENDING'");
                        ps.setInt(1, user.getUserId());
                        ps.setString(2, user.getUsername());
                        ps.setTimestamp(3, new Timestamp(System.currentTimeMillis()));
                        ps.setString(4, rejectionReason.trim());
                        ps.setInt(5, videoId);
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

        // Redirect back to the same filtered/paginated view (Post/Redirect/Get avoids re-submission on refresh)
        String rSubjectPhase = request.getParameter("subjectPhase"); if (rSubjectPhase == null) rSubjectPhase = "";
        String rStudentSearch = request.getParameter("studentSearch"); if (rStudentSearch == null) rStudentSearch = "";
        String rUploadedBy = request.getParameter("uploadedBy"); if (rUploadedBy == null) rUploadedBy = "";
        String rDateFrom = request.getParameter("dateFrom"); if (rDateFrom == null) rDateFrom = "";
        String rDateTo = request.getParameter("dateTo"); if (rDateTo == null) rDateTo = "";
        String rPage = request.getParameter("page"); if (rPage == null) rPage = "1";

        StringBuilder redirectQs = new StringBuilder();
        redirectQs.append("subjectPhase=").append(java.net.URLEncoder.encode(rSubjectPhase, "UTF-8"));
        redirectQs.append("&studentSearch=").append(java.net.URLEncoder.encode(rStudentSearch, "UTF-8"));
        redirectQs.append("&uploadedBy=").append(java.net.URLEncoder.encode(rUploadedBy, "UTF-8"));
        redirectQs.append("&dateFrom=").append(java.net.URLEncoder.encode(rDateFrom, "UTF-8"));
        redirectQs.append("&dateTo=").append(java.net.URLEncoder.encode(rDateTo, "UTF-8"));
        redirectQs.append("&page=").append(java.net.URLEncoder.encode(rPage, "UTF-8"));

        response.sendRedirect("approve-videos.jsp?" + redirectQs.toString());
        return;
    }

    // ---- Read filter params ----
    String subjectPhase = request.getParameter("subjectPhase");
    if (subjectPhase == null) subjectPhase = "";
    String studentSearch = request.getParameter("studentSearch");
    if (studentSearch == null) studentSearch = "";
    String uploadedBy = request.getParameter("uploadedBy");
    if (uploadedBy == null) uploadedBy = "";
    String dateFrom = request.getParameter("dateFrom");
    if (dateFrom == null) dateFrom = "";
    String dateTo = request.getParameter("dateTo");
    if (dateTo == null) dateTo = "";

    int pageNum = 1;
    try { pageNum = Integer.parseInt(request.getParameter("page")); } catch (Exception e) { pageNum = 1; }
    if (pageNum < 1) pageNum = 1;
    final int pageSize = 10;

    // ---- Build dynamic WHERE clause ----
    StringBuilder where = new StringBuilder("sv.udise_no = ? AND sv.approval_status = 'PENDING'");
    List<Object> params = new ArrayList<Object>();
    params.add(udiseNo);

    if (subjectPhase.startsWith("phase:")) {
        where.append(" AND sv.phase_number = ?");
        params.add(Integer.parseInt(subjectPhase.substring(6)));
    } else if (subjectPhase.startsWith("subject:")) {
        where.append(" AND sv.subject = ?");
        params.add(subjectPhase.substring(8));
    }

    if (!studentSearch.trim().isEmpty()) {
        where.append(" AND (s.student_name LIKE ? OR s.student_pen LIKE ?)");
        String like = "%" + studentSearch.trim() + "%";
        params.add(like);
        params.add(like);
    }

    if (!uploadedBy.trim().isEmpty()) {
        where.append(" AND sv.uploaded_by_name = ?");
        params.add(uploadedBy.trim());
    }

    if (!dateFrom.trim().isEmpty()) {
        where.append(" AND sv.upload_date >= ?");
        params.add(dateFrom.trim() + " 00:00:00");
    }

    if (!dateTo.trim().isEmpty()) {
        where.append(" AND sv.upload_date <= ?");
        params.add(dateTo.trim() + " 23:59:59");
    }

    String whereClause = where.toString();

    Connection conn = null;
    int totalCount = 0;
    List<Object[]> rows = new ArrayList<Object[]>();
    List<String> phaseOptions = new ArrayList<String>();
    List<String> subjectOptions = new ArrayList<String>();
    List<String> uploaderOptions = new ArrayList<String>();
    String errorMessage = null;

    try {
        conn = DatabaseConnection.getConnection();

        // Total count for pagination
        PreparedStatement countStmt = conn.prepareStatement(
            "SELECT COUNT(*) FROM student_videos sv INNER JOIN students s ON sv.student_id = s.student_id WHERE " + whereClause);
        for (int i = 0; i < params.size(); i++) countStmt.setObject(i + 1, params.get(i));
        ResultSet countRs = countStmt.executeQuery();
        if (countRs.next()) totalCount = countRs.getInt(1);
        countRs.close();
        countStmt.close();

        // Page of data
        int offset = (pageNum - 1) * pageSize;
        PreparedStatement pstmt = conn.prepareStatement(
            "SELECT sv.video_id, s.student_name, s.student_pen, "
          + "sv.subject, sv.month, sv.phase_number, sv.original_file_name, sv.file_size, "
          + "sv.uploaded_by_name, sv.upload_date, sv.file_path "
          + "FROM student_videos sv INNER JOIN students s ON sv.student_id = s.student_id "
          + "WHERE " + whereClause + " ORDER BY sv.upload_date DESC LIMIT ? OFFSET ?");
        for (int i = 0; i < params.size(); i++) pstmt.setObject(i + 1, params.get(i));
        pstmt.setInt(params.size() + 1, pageSize);
        pstmt.setInt(params.size() + 2, offset);

        ResultSet rs = pstmt.executeQuery();
        while (rs.next()) {
            int phaseNumber = rs.getInt("phase_number");
            boolean hasPhase = !rs.wasNull();
            long fileSize = rs.getLong("file_size");
            String sizeDisplay = fileSize < 1024 ? fileSize + " B"
                : fileSize < 1024 * 1024 ? String.format("%.2f KB", fileSize / 1024.0)
                : String.format("%.2f MB", fileSize / (1024.0 * 1024));
            String subjectPhaseDisplay = hasPhase ? ("Phase " + phaseNumber)
                : (rs.getString("subject") + " / " + rs.getString("month"));
            rows.add(new Object[]{
                rs.getString("student_name"), rs.getString("student_pen"), subjectPhaseDisplay,
                rs.getString("original_file_name"), sizeDisplay, rs.getString("uploaded_by_name"),
                String.valueOf(rs.getTimestamp("upload_date")), rs.getString("file_path"),
                rs.getInt("video_id")
            });
        }
        rs.close();
        pstmt.close();

        // Filter dropdown options (scoped to this school's pending videos)
        PreparedStatement phaseStmt = conn.prepareStatement(
            "SELECT DISTINCT phase_number FROM student_videos WHERE udise_no = ? AND approval_status = 'PENDING' AND phase_number IS NOT NULL ORDER BY phase_number");
        phaseStmt.setString(1, udiseNo);
        ResultSet phaseRs = phaseStmt.executeQuery();
        while (phaseRs.next()) phaseOptions.add(String.valueOf(phaseRs.getInt(1)));
        phaseRs.close();
        phaseStmt.close();

        PreparedStatement subjStmt = conn.prepareStatement(
            "SELECT DISTINCT subject FROM student_videos WHERE udise_no = ? AND approval_status = 'PENDING' AND subject IS NOT NULL ORDER BY subject");
        subjStmt.setString(1, udiseNo);
        ResultSet subjRs = subjStmt.executeQuery();
        while (subjRs.next()) subjectOptions.add(subjRs.getString(1));
        subjRs.close();
        subjStmt.close();

        PreparedStatement upStmt = conn.prepareStatement(
            "SELECT DISTINCT uploaded_by_name FROM student_videos WHERE udise_no = ? AND approval_status = 'PENDING' AND uploaded_by_name IS NOT NULL ORDER BY uploaded_by_name");
        upStmt.setString(1, udiseNo);
        ResultSet upRs = upStmt.executeQuery();
        while (upRs.next()) uploaderOptions.add(upRs.getString(1));
        upRs.close();
        upStmt.close();

    } catch (Exception e) {
        errorMessage = e.getMessage();
        e.printStackTrace();
    } finally {
        try { if (conn != null) conn.close(); } catch (Exception e) {}
    }

    int totalPages = Math.max(1, (int) Math.ceil(totalCount / (double) pageSize));
    if (pageNum > totalPages) pageNum = totalPages;

    // Build a query string preserving current filters, for pagination links
    StringBuilder qs = new StringBuilder();
    qs.append("subjectPhase=").append(java.net.URLEncoder.encode(subjectPhase, "UTF-8"));
    qs.append("&studentSearch=").append(java.net.URLEncoder.encode(studentSearch, "UTF-8"));
    qs.append("&uploadedBy=").append(java.net.URLEncoder.encode(uploadedBy, "UTF-8"));
    qs.append("&dateFrom=").append(java.net.URLEncoder.encode(dateFrom, "UTF-8"));
    qs.append("&dateTo=").append(java.net.URLEncoder.encode(dateTo, "UTF-8"));
    String baseQs = qs.toString();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Approve Student Videos - VJNT Class Management</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 15px;
            text-align: center;
            margin-bottom: 25px;
        }
        .stats-number { font-size: 44px; font-weight: bold; }
        .filter-card label {
            font-size: 12px;
            font-weight: bold;
            color: #667eea;
            text-transform: uppercase;
            margin-bottom: 4px;
        }
        table { margin-top: 5px; font-size: 14px; }
        th, td { padding: 14px 16px !important; }
        th { background: #667eea; color: white; white-space: nowrap; font-weight: 600; }
        td { vertical-align: middle; }
        tbody tr:hover { background-color: #f0f0ff !important; }
        .badge-phase, .badge-subject { font-size: 12px; padding: 6px 10px; }
        .badge-phase { background: #667eea; }
        .badge-subject { background: #495057; }
        .empty-state { text-align: center; padding: 50px 20px; color: #666; }
        .empty-state i { font-size: 64px; color: #ddd; margin-bottom: 15px; }
        .pagination-bar { display: flex; justify-content: space-between; align-items: center; margin-top: 15px; }
        .video-modal-overlay {
            display: none;
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0,0,0,0.85);
            z-index: 1050;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .video-modal-box {
            position: relative;
            width: 100%;
            max-width: 900px;
        }
        .video-modal-close {
            position: absolute;
            top: -40px;
            right: 0;
            background: none;
            border: none;
            color: white;
            font-size: 32px;
            line-height: 1;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header-card">
            <div class="row align-items-center">
                <div class="col-md-8">
                    <h2><i class="fas fa-video"></i> Video Approval Center</h2>
                    <p class="text-muted mb-0">Review pending videos uploaded by school coordinators</p>
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
            <div>Videos Pending Approval</div>
        </div>

        <div class="filter-card">
            <form method="get" action="approve-videos.jsp">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label d-block">Subject / Phase</label>
                        <select class="form-select" name="subjectPhase" onchange="this.form.submit()">
                            <option value="">All</option>
                            <% for (String p : phaseOptions) { %>
                                <option value="phase:<%= p %>" <%= subjectPhase.equals("phase:" + p) ? "selected" : "" %>>Phase <%= p %></option>
                            <% } %>
                            <% for (String subj : subjectOptions) { %>
                                <option value="subject:<%= esc(subj) %>" <%= subjectPhase.equals("subject:" + subj) ? "selected" : "" %>><%= esc(subj) %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label d-block">Student Name / PEN</label>
                        <input type="text" class="form-control" name="studentSearch" value="<%= esc(studentSearch) %>" placeholder="Search name or PEN">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label d-block">Uploaded By</label>
                        <select class="form-select" name="uploadedBy" onchange="this.form.submit()">
                            <option value="">All</option>
                            <% for (String up : uploaderOptions) { %>
                                <option value="<%= esc(up) %>" <%= uploadedBy.equals(up) ? "selected" : "" %>><%= esc(up) %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label d-block">From Date</label>
                        <input type="date" class="form-control" name="dateFrom" value="<%= esc(dateFrom) %>" onchange="this.form.submit()">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label d-block">To Date</label>
                        <input type="date" class="form-control" name="dateTo" value="<%= esc(dateTo) %>" onchange="this.form.submit()">
                    </div>
                </div>
                <div class="row mt-3">
                    <div class="col-12 text-end">
                        <button type="submit" class="btn btn-sm btn-primary me-2">
                            <i class="fas fa-search"></i> Apply
                        </button>
                        <a href="approve-videos.jsp" class="btn btn-sm btn-outline-secondary">
                            <i class="fas fa-times"></i> Clear Filters
                        </a>
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
                <h5>Could Not Load Videos</h5>
                <p><%= esc(errorMessage) %></p>
            </div>
<%
    } else if (rows.isEmpty()) {
%>
            <div class="empty-state">
                <i class="fas fa-check-circle"></i>
                <h5><%= (subjectPhase + studentSearch + uploadedBy + dateFrom + dateTo).isEmpty() ? "All Caught Up!" : "No Matching Videos" %></h5>
                <p><%= (subjectPhase + studentSearch + uploadedBy + dateFrom + dateTo).isEmpty() ? "There are no pending videos to review at this time." : "No pending videos match the selected filters." %></p>
            </div>
<%
    } else {
%>
            <div class="table-responsive">
                <table class="table table-hover table-striped align-middle mb-0">
                    <thead>
                        <tr>
                            <th>Student Name</th>
                            <th>PEN</th>
                            <th>Subject / Phase</th>
                            <th>File Name</th>
                            <th>Size</th>
                            <th>Uploaded By</th>
                            <th>Upload Date</th>
                            <th>Video</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
<%
        for (Object[] row : rows) {
            boolean isPhase = ((String) row[2]).startsWith("Phase ");
            String videoUrl = (String) row[7];
            int videoId = (Integer) row[8];
%>
                        <tr>
                            <td><i class="fas fa-graduation-cap text-muted"></i> <%= esc((String) row[0]) %></td>
                            <td><%= esc((String) row[1]) %></td>
                            <td><span class="badge <%= isPhase ? "badge-phase" : "badge-subject" %>"><%= esc((String) row[2]) %></span></td>
                            <td><%= esc((String) row[3]) %></td>
                            <td class="text-nowrap"><%= row[4] %></td>
                            <td><%= esc((String) row[5]) %></td>
                            <td class="text-nowrap"><%= row[6] %></td>
                            <td>
<%
            if (videoUrl != null && !videoUrl.isEmpty()) {
%>
                                <button type="button" class="btn btn-sm btn-outline-primary" data-video-url="<%= esc(videoUrl) %>" onclick="openVideoModal(this.getAttribute('data-video-url'))">
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
                            <td class="text-nowrap">
                                <form method="post" action="approve-videos.jsp" class="d-inline" onsubmit="return confirm('Approve this video?')">
                                    <input type="hidden" name="doAction" value="approve">
                                    <input type="hidden" name="videoId" value="<%= videoId %>">
                                    <input type="hidden" name="subjectPhase" value="<%= esc(subjectPhase) %>">
                                    <input type="hidden" name="studentSearch" value="<%= esc(studentSearch) %>">
                                    <input type="hidden" name="uploadedBy" value="<%= esc(uploadedBy) %>">
                                    <input type="hidden" name="dateFrom" value="<%= esc(dateFrom) %>">
                                    <input type="hidden" name="dateTo" value="<%= esc(dateTo) %>">
                                    <input type="hidden" name="page" value="<%= pageNum %>">
                                    <button type="submit" class="btn btn-sm btn-success me-1">
                                        <i class="fas fa-check"></i> Approve
                                    </button>
                                </form>
                                <button type="button" class="btn btn-sm btn-danger" onclick="showRejectModal(<%= videoId %>)">
                                    <i class="fas fa-times"></i> Reject
                                </button>
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
                        <a href="approve-videos.jsp?<%= baseQs %>&page=<%= pageNum - 1 %>" class="btn btn-outline-primary btn-sm">
                            <i class="fas fa-chevron-left"></i> Previous
                        </a>
                    <% } else { %>
                        <button class="btn btn-outline-secondary btn-sm" disabled><i class="fas fa-chevron-left"></i> Previous</button>
                    <% } %>
                    <% if (pageNum < totalPages) { %>
                        <a href="approve-videos.jsp?<%= baseQs %>&page=<%= pageNum + 1 %>" class="btn btn-outline-primary btn-sm">
                            Next <i class="fas fa-chevron-right"></i>
                        </a>
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
                <h5>Reject Video</h5>
                <p class="text-muted">Please provide a reason for rejecting this video.</p>
                <form method="post" action="approve-videos.jsp" id="rejectForm" onsubmit="return validateRejectForm()">
                    <input type="hidden" name="doAction" value="reject">
                    <input type="hidden" name="videoId" id="rejectVideoId" value="">
                    <input type="hidden" name="subjectPhase" value="<%= esc(subjectPhase) %>">
                    <input type="hidden" name="studentSearch" value="<%= esc(studentSearch) %>">
                    <input type="hidden" name="uploadedBy" value="<%= esc(uploadedBy) %>">
                    <input type="hidden" name="dateFrom" value="<%= esc(dateFrom) %>">
                    <input type="hidden" name="dateTo" value="<%= esc(dateTo) %>">
                    <input type="hidden" name="page" value="<%= pageNum %>">
                    <textarea class="form-control mb-3" name="rejectionReason" id="rejectionReason" rows="4" placeholder="Enter rejection reason..."></textarea>
                    <div class="text-end">
                        <button type="button" class="btn btn-secondary me-2" onclick="closeRejectModal()">Cancel</button>
                        <button type="submit" class="btn btn-danger"><i class="fas fa-times-circle"></i> Reject Video</button>
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
        function showRejectModal(videoId) {
            document.getElementById('rejectVideoId').value = videoId;
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
