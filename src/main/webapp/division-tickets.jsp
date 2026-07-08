<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DIVISION)
            && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="mr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ticket Management - GATEE Portal</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, sans-serif; }
        body { background: #f0f2f5; min-height: 100vh; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px 30px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 15px; }
        .header h1 { font-size: 22px; }
        .header .sub { font-size: 13px; opacity: 0.9; margin-top: 4px; }
        .header-actions a { background: rgba(255,255,255,0.2); color: white; text-decoration: none; padding: 10px 18px; border-radius: 8px; font-size: 14px; font-weight: 600; }
        .container { max-width: 1500px; margin: 25px auto; padding: 0 20px; }
        .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 18px; margin-bottom: 25px; }
        .card { padding: 20px; border-radius: 12px; color: white; text-align: center; cursor: pointer; }
        .card .num { font-size: 30px; font-weight: 700; }
        .card .lbl { font-size: 13px; margin-top: 5px; }
        .section { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .filters { display: flex; gap: 12px; margin-bottom: 18px; flex-wrap: wrap; }
        .filters input, .filters select { padding: 10px 14px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; }
        .filters input { flex: 1; min-width: 220px; }
        .filters button { padding: 10px 18px; background: #667eea; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 600; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #f8f9fa; border-bottom: 2px solid #dee2e6; padding: 12px; text-align: left; font-weight: 600; font-size: 13px; }
        td { padding: 11px 12px; border-bottom: 1px solid #e9ecef; font-size: 13px; vertical-align: top; }
        tr:hover td { background: #f8f9fa; }
        .badge { display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 11px; font-weight: 600; color: white; white-space: nowrap; }
        .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #667eea; border-radius: 50%; width: 36px; height: 36px; animation: spin 1s linear infinite; margin: 0 auto; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        .act-btn { background: #667eea; color: white; border: none; padding: 8px 14px; border-radius: 6px; cursor: pointer; font-size: 12px; font-weight: 600; white-space: nowrap; }
        .remarks { background: #F3E5F5; border-left: 3px solid #8E24AA; padding: 8px 10px; border-radius: 4px; margin-top: 6px; font-size: 12px; color: #4A148C; }
        /* Modal */
        .modal { display: none; position: fixed; z-index: 10000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background: rgba(0,0,0,0.7); }
        .modal-box { position: relative; margin: 6% auto; max-width: 620px; width: 94%; background: white; border-radius: 12px; box-shadow: 0 10px 50px rgba(0,0,0,0.3); }
        .modal-head { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px 25px; border-radius: 12px 12px 0 0; display: flex; justify-content: space-between; align-items: center; }
        .modal-body { padding: 25px; }
        .modal-body label { display: block; font-size: 14px; font-weight: 600; color: #444; margin: 14px 0 6px; }
        .modal-body select, .modal-body textarea { width: 100%; padding: 11px 14px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; font-family: inherit; }
        .modal-body textarea { min-height: 100px; resize: vertical; }
        .close-x { background: rgba(255,255,255,0.2); border: none; color: white; font-size: 26px; cursor: pointer; width: 38px; height: 38px; border-radius: 50%; }
        .ticket-info { background: #f8f9fa; padding: 14px; border-radius: 8px; font-size: 13px; color: #444; line-height: 1.7; }
        @media (max-width: 900px) { .table-wrap { overflow-x: auto; } }
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>🎫 Ticket Management (तिकीट व्यवस्थापन)</h1>
            <div class="sub">Tickets raised by Teachers, School Coordinators &amp; Head Masters<%= user.getDivisionName() != null ? " | Division: " + user.getDivisionName() : "" %></div>
        </div>
        <div class="header-actions">
            <a href="<%= request.getContextPath() %>/division-dashboard.jsp">← Dashboard</a>
        </div>
    </div>

    <div class="container">
        <!-- Summary Cards (click to filter) -->
        <div class="cards">
            <div class="card" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);" onclick="setStatusFilter('')">
                <div class="num" id="cTotal">-</div><div class="lbl">Total Tickets</div>
            </div>
            <div class="card" style="background: linear-gradient(135deg, #f5576c 0%, #f093fb 100%);" onclick="setStatusFilter('OPEN')">
                <div class="num" id="cOpen">-</div><div class="lbl">🔴 Open</div>
            </div>
            <div class="card" style="background: linear-gradient(135deg, #FF9800 0%, #FFC107 100%);" onclick="setStatusFilter('IN_PROGRESS')">
                <div class="num" id="cProgress">-</div><div class="lbl">🟠 In Progress</div>
            </div>
            <div class="card" style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);" onclick="setStatusFilter('RESOLVED')">
                <div class="num" id="cResolved">-</div><div class="lbl">🟢 Resolved</div>
            </div>
        </div>

        <div class="section">
            <div class="filters">
                <input type="text" id="searchBox" placeholder="Search subject, school, UDISE, name..." onkeyup="renderTickets()">
                <select id="statusFilter" onchange="renderTickets()">
                    <option value="">All Statuses</option>
                    <option value="OPEN">Open</option>
                    <option value="IN_PROGRESS">In Progress</option>
                    <option value="RESOLVED">Resolved</option>
                    <option value="REJECTED">Rejected</option>
                    <option value="CLOSED">Closed</option>
                </select>
                <select id="roleFilter" onchange="renderTickets()">
                    <option value="">All Roles</option>
                    <option value="TEACHER">Teacher</option>
                    <option value="SCHOOL_COORDINATOR">School Coordinator</option>
                    <option value="HEAD_MASTER">Head Master</option>
                </select>
                <button onclick="loadTickets()">🔄 Refresh</button>
            </div>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Ticket</th>
                            <th>Raised By</th>
                            <th>School</th>
                            <th>Category</th>
                            <th>Subject / Description</th>
                            <th>Priority</th>
                            <th>Status</th>
                            <th>Raised On</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody id="ticketsBody">
                        <tr><td colspan="9" style="text-align:center; padding:30px;"><div class="spinner"></div></td></tr>
                    </tbody>
                </table>
            </div>
            <div id="countInfo" style="margin-top:12px; color:#666; font-size:14px;"></div>
        </div>
    </div>

    <!-- Action Modal -->
    <div class="modal" id="actionModal">
        <div class="modal-box">
            <div class="modal-head">
                <h3>⚙️ Take Action - <span id="mTicketNo"></span></h3>
                <button class="close-x" onclick="closeModal()">×</button>
            </div>
            <div class="modal-body">
                <div class="ticket-info" id="mTicketInfo"></div>
                <label>Status</label>
                <select id="mStatus">
                    <option value="IN_PROGRESS">🟠 In Progress (कार्यवाही सुरू)</option>
                    <option value="RESOLVED">🟢 Resolved (निराकरण झाले)</option>
                    <option value="REJECTED">⚪ Rejected (नाकारले)</option>
                    <option value="CLOSED">⚫ Closed (बंद)</option>
                </select>
                <label>Remarks / Response (शेरा)</label>
                <textarea id="mRemarks" placeholder="तिकीट सादर करणाऱ्यास दिसणारा प्रतिसाद लिहा..."></textarea>
                <button class="act-btn" id="mSaveBtn" style="margin-top:18px; padding:12px 26px; font-size:14px;" onclick="saveAction()">💾 Save Action</button>
                <span id="mError" style="color:#B71C1C; font-size:13px; margin-left:12px;"></span>
            </div>
        </div>
    </div>

    <script>
        const contextPath = '<%= request.getContextPath() %>';
        let allTickets = [];
        let currentTicketId = null;

        function escapeHtml(text) {
            if (text === null || text === undefined) return '';
            return String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;')
                .replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#039;');
        }

        function statusBadge(status) {
            const map = { 'OPEN': '#F44336', 'IN_PROGRESS': '#FF9800', 'RESOLVED': '#4CAF50', 'REJECTED': '#9E9E9E', 'CLOSED': '#607D8B' };
            return '<span class="badge" style="background:' + (map[status] || '#607D8B') + ';">' + escapeHtml(status.replace('_', ' ')) + '</span>';
        }

        function priorityBadge(p) {
            const map = { 'HIGH': '#E53935', 'MEDIUM': '#FB8C00', 'LOW': '#43A047' };
            return '<span class="badge" style="background:' + (map[p] || '#607D8B') + ';">' + escapeHtml(p) + '</span>';
        }

        function roleLabel(r) {
            const map = { 'TEACHER': '👨‍🏫 Teacher', 'SCHOOL_COORDINATOR': '🎓 School Coordinator', 'HEAD_MASTER': '👨‍💼 Head Master' };
            return map[r] || r;
        }

        function attachmentLinks(t) {
            const atts = t.attachments || [];
            if (!atts.length) return '';
            let html = '<div style="margin-top:6px;">';
            atts.forEach(a => {
                const icon = a.contentType === 'application/pdf' ? '📄' : '🖼️';
                html += '<a href="' + contextPath + '/ticket-attachment?id=' + a.attachmentId + '" target="_blank" '
                     + 'style="display:inline-block; background:#E3F2FD; color:#1565C0; padding:4px 10px; border-radius:12px; '
                     + 'font-size:12px; text-decoration:none; margin:2px 6px 2px 0;">' + icon + ' ' + escapeHtml(a.fileName) + '</a>';
            });
            return html + '</div>';
        }

        function setStatusFilter(status) {
            document.getElementById('statusFilter').value = status;
            renderTickets();
        }

        function loadTickets() {
            document.getElementById('ticketsBody').innerHTML =
                '<tr><td colspan="9" style="text-align:center; padding:30px;"><div class="spinner"></div></td></tr>';
            fetch(contextPath + '/tickets?action=division')
                .then(r => r.json())
                .then(data => {
                    if (data.error) {
                        document.getElementById('ticketsBody').innerHTML =
                            '<tr><td colspan="9" style="color:red; text-align:center; padding:20px;">' + escapeHtml(data.error) + '</td></tr>';
                        return;
                    }
                    allTickets = data.tickets || [];
                    document.getElementById('cTotal').textContent = data.totalCount || 0;
                    document.getElementById('cOpen').textContent = data.openCount || 0;
                    document.getElementById('cProgress').textContent = data.inProgressCount || 0;
                    document.getElementById('cResolved').textContent = data.resolvedCount || 0;
                    renderTickets();
                })
                .catch(e => {
                    document.getElementById('ticketsBody').innerHTML =
                        '<tr><td colspan="9" style="color:red; text-align:center; padding:20px;">Failed to load tickets</td></tr>';
                });
        }

        function renderTickets() {
            const search = document.getElementById('searchBox').value.toLowerCase();
            const statusFilter = document.getElementById('statusFilter').value;
            const roleFilter = document.getElementById('roleFilter').value;
            const tbody = document.getElementById('ticketsBody');

            const filtered = allTickets.filter(t => {
                const matchesSearch = !search ||
                    (t.subject && t.subject.toLowerCase().includes(search)) ||
                    (t.schoolName && t.schoolName.toLowerCase().includes(search)) ||
                    (t.udiseNo && t.udiseNo.toLowerCase().includes(search)) ||
                    (t.raisedByName && t.raisedByName.toLowerCase().includes(search)) ||
                    (t.ticketNo && t.ticketNo.toLowerCase().includes(search));
                const matchesStatus = !statusFilter || t.status === statusFilter;
                const matchesRole = !roleFilter || t.raisedByRole === roleFilter;
                return matchesSearch && matchesStatus && matchesRole;
            });

            if (filtered.length === 0) {
                tbody.innerHTML = '<tr><td colspan="9" style="text-align:center; padding:25px; color:#999;">No tickets found</td></tr>';
                document.getElementById('countInfo').textContent = '';
                return;
            }

            let html = '';
            filtered.forEach(t => {
                html += '<tr>';
                html += '<td style="font-family:monospace; font-weight:600; white-space:nowrap;">' + escapeHtml(t.ticketNo) + '</td>';
                html += '<td><div style="font-weight:600;">' + escapeHtml(t.raisedByName) + '</div><div style="font-size:12px; color:#666;">' + roleLabel(t.raisedByRole) + '</div><div style="font-size:12px; color:#666;">📞 ' + escapeHtml(t.raisedByMobile) + '</div></td>';
                html += '<td><div>' + escapeHtml(t.schoolName || '-') + '</div><div style="font-family:monospace; font-size:12px; color:#666;">' + escapeHtml(t.udiseNo) + '</div><div style="font-size:12px; color:#666;">' + escapeHtml(t.districtName) + '</div></td>';
                html += '<td>' + escapeHtml(t.category) + '</td>';
                html += '<td style="max-width:320px;"><div style="font-weight:600;">' + escapeHtml(t.subject) + '</div><div style="color:#666; font-size:12px; margin-top:3px;">' + escapeHtml(t.description) + '</div>'
                     + attachmentLinks(t)
                     + (t.actionRemarks ? '<div class="remarks">💬 ' + escapeHtml(t.actionRemarks) + '</div>' : '') + '</td>';
                html += '<td>' + priorityBadge(t.priority) + '</td>';
                html += '<td>' + statusBadge(t.status) + '</td>';
                html += '<td style="white-space:nowrap;">' + escapeHtml((t.createdDate || '').substring(0, 16)) + '</td>';
                html += '<td><button class="act-btn" onclick="openAction(' + t.ticketId + ')">⚙️ Action</button></td>';
                html += '</tr>';
            });
            tbody.innerHTML = html;
            document.getElementById('countInfo').textContent = 'Showing ' + filtered.length + ' of ' + allTickets.length + ' tickets';
        }

        function openAction(ticketId) {
            const t = allTickets.find(x => x.ticketId === ticketId);
            if (!t) return;
            currentTicketId = ticketId;
            document.getElementById('mTicketNo').textContent = t.ticketNo;
            document.getElementById('mTicketInfo').innerHTML =
                '<strong>' + escapeHtml(t.subject) + '</strong><br>' + escapeHtml(t.description) +
                '<br><span style="color:#666;">' + escapeHtml(t.raisedByName) + ' (' + roleLabel(t.raisedByRole) + ') | ' +
                escapeHtml(t.schoolName || '') + ' | UDISE ' + escapeHtml(t.udiseNo) + ' | 📞 ' + escapeHtml(t.raisedByMobile) + '</span>' +
                attachmentLinks(t);
            document.getElementById('mStatus').value = t.status === 'OPEN' ? 'IN_PROGRESS' : (t.status === 'RESOLVED' || t.status === 'REJECTED' || t.status === 'CLOSED' ? t.status : 'IN_PROGRESS');
            document.getElementById('mRemarks').value = t.actionRemarks || '';
            document.getElementById('mError').textContent = '';
            document.getElementById('actionModal').style.display = 'block';
            document.body.style.overflow = 'hidden';
        }

        function closeModal() {
            document.getElementById('actionModal').style.display = 'none';
            document.body.style.overflow = 'auto';
        }

        function saveAction() {
            const btn = document.getElementById('mSaveBtn');
            btn.disabled = true;
            btn.textContent = 'Saving...';
            document.getElementById('mError').textContent = '';

            fetch(contextPath + '/tickets', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    action: 'update',
                    ticketId: currentTicketId,
                    status: document.getElementById('mStatus').value,
                    remarks: document.getElementById('mRemarks').value.trim()
                })
            })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                btn.textContent = '💾 Save Action';
                if (data.success) {
                    closeModal();
                    loadTickets();
                } else {
                    document.getElementById('mError').textContent = data.error || 'Failed to update';
                }
            })
            .catch(e => {
                btn.disabled = false;
                btn.textContent = '💾 Save Action';
                document.getElementById('mError').textContent = 'Failed: ' + e;
            });
        }

        window.addEventListener('load', loadTickets);
    </script>
</body>
</html>
