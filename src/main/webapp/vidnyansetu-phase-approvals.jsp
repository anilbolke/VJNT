<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User,com.vjnt.dao.VidnyanSetuPhaseApprovalDAO,java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (user.getUserType() != User.UserType.HEAD_MASTER) {
        response.sendRedirect(request.getContextPath() + "/school-dashboard-enhanced.jsp"); return;
    }

    String udiseNo = user.getUdiseNo();
    VidnyanSetuPhaseApprovalDAO approvalDAO = new VidnyanSetuPhaseApprovalDAO();
    List<Map<String,Object>> pending = approvalDAO.getPendingApprovals(udiseNo);

    String successMessage = (String) session.getAttribute("successMessage");
    String errorMessage = (String) session.getAttribute("errorMessage");
    session.removeAttribute("successMessage");
    session.removeAttribute("errorMessage");
%>
<!DOCTYPE html>
<html lang="mr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>VidnyanSetu Phase Approvals</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f4f8;color:#1e293b;}
.topbar{background:linear-gradient(135deg,#0f9b6c 0%,#0c7b54 100%);color:#fff;padding:16px 24px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;}
.topbar .brand{font-size:19px;font-weight:800;}
.topbar-btn{background:rgba(255,255,255,0.15);color:#fff;text-decoration:none;padding:8px 14px;border-radius:8px;font-size:13px;font-weight:600;border:1px solid rgba(255,255,255,0.3);}
.topbar-btn:hover{background:rgba(255,255,255,0.28);}
.wrap{max-width:900px;margin:30px auto;padding:0 20px;}
.alert{padding:12px 16px;border-radius:8px;font-size:13.5px;margin-bottom:16px;font-weight:500;}
.alert-error{background:#fee2e2;color:#991b1b;}
.alert-success{background:#d1fae5;color:#065f46;}
.card{background:#fff;border-radius:12px;padding:22px;box-shadow:0 4px 18px rgba(0,0,0,0.08);margin-bottom:18px;border:1px solid #e2e8f0;}
.card h3{color:#0c7b54;margin-bottom:8px;}
.meta{font-size:13px;color:#64748b;margin-bottom:14px;line-height:1.7;}
.meta strong{color:#334155;}
.remarks-box{width:100%;padding:9px 10px;border:1px solid #cbd5e1;border-radius:7px;font-size:13px;margin-bottom:10px;min-height:60px;}
.btn-row{display:flex;gap:10px;}
.btn{border:none;padding:9px 18px;border-radius:7px;font-size:13.5px;font-weight:700;cursor:pointer;}
.btn-approve{background:#0f9b6c;color:#fff;}
.btn-approve:hover{background:#0c7b54;}
.btn-reject{background:#dc2626;color:#fff;}
.btn-reject:hover{background:#b91c1c;}
.empty{text-align:center;padding:60px 20px;background:#fff;border-radius:12px;box-shadow:0 1px 4px rgba(0,0,0,.07);color:#64748b;}
</style>
</head>
<body>
<div class="topbar">
    <div class="brand">🔬 विज्ञानसेतू Phase Approvals</div>
    <a class="topbar-btn" href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp">← Dashboard</a>
</div>
<div class="wrap">
    <% if (successMessage != null) { %><div class="alert alert-success"><%= successMessage %></div><% } %>
    <% if (errorMessage != null) { %><div class="alert alert-error"><%= errorMessage %></div><% } %>

    <% if (pending.isEmpty()) { %>
        <div class="empty">✅ No VidnyanSetu phases pending your approval.</div>
    <% } else {
        for (Map<String,Object> a : pending) {
    %>
        <div class="card">
            <h3>Phase <%= a.get("phaseNumber") %></h3>
            <div class="meta">
                <strong>Submitted by:</strong> <%= a.get("completedBy") %> on <%= a.get("completedDate") %><br>
                <strong>Students completed:</strong> <%= a.get("completedStudents") %> / <%= a.get("totalStudents") %>
                (<%= a.get("pendingStudents") %> pending)<br>
                <% if (a.get("completionRemarks") != null && !String.valueOf(a.get("completionRemarks")).isEmpty()) { %>
                    <strong>Coordinator remarks:</strong> <%= a.get("completionRemarks") %>
                <% } %>
            </div>
            <form method="post" action="<%= request.getContextPath() %>/vidnyansetu-approve-phase">
                <input type="hidden" name="approvalId" value="<%= a.get("approvalId") %>">
                <textarea name="remarks" class="remarks-box" placeholder="Remarks (required to reject)"></textarea>
                <div class="btn-row">
                    <button type="submit" name="action" value="approve" class="btn btn-approve">✅ Approve</button>
                    <button type="submit" name="action" value="reject" class="btn btn-reject">❌ Reject</button>
                </div>
            </form>
        </div>
    <% } } %>
</div>
</body>
</html>
