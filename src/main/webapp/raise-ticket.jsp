<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.TEACHER)
            && !user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)
            && !user.getUserType().equals(User.UserType.HEAD_MASTER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="mr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Support Tickets - GATEE Portal</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, sans-serif; }
        body { background: #f0f2f5; min-height: 100vh; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px 30px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 15px; }
        .header h1 { font-size: 22px; }
        .header .sub { font-size: 13px; opacity: 0.9; margin-top: 4px; }
        .header-actions a { background: rgba(255,255,255,0.2); color: white; text-decoration: none; padding: 10px 18px; border-radius: 8px; font-size: 14px; font-weight: 600; }
        .container { max-width: 1100px; margin: 25px auto; padding: 0 20px; }
        .section { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 25px; }
        .section h2 { color: #333; margin-bottom: 18px; font-size: 18px; }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; }
        .form-group { display: flex; flex-direction: column; }
        .form-group.full { grid-column: 1 / -1; }
        label { font-size: 14px; font-weight: 600; color: #444; margin-bottom: 6px; }
        label .req { color: #E53935; }
        input, select, textarea { padding: 11px 14px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; font-family: inherit; }
        textarea { min-height: 110px; resize: vertical; }
        .btn { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; padding: 12px 28px; border-radius: 8px; font-size: 15px; font-weight: 600; cursor: pointer; margin-top: 15px; }
        .btn:disabled { background: #999; cursor: not-allowed; }
        .alert { display: none; padding: 12px 15px; border-radius: 8px; margin-top: 15px; font-size: 14px; }
        .alert.ok { background: #E8F5E9; border: 1px solid #A5D6A7; color: #1B5E20; }
        .alert.err { background: #FFEBEE; border: 1px solid #EF9A9A; color: #B71C1C; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #f8f9fa; border-bottom: 2px solid #dee2e6; padding: 12px; text-align: left; font-weight: 600; font-size: 13px; }
        td { padding: 11px 12px; border-bottom: 1px solid #e9ecef; font-size: 13px; vertical-align: top; }
        .badge { display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 11px; font-weight: 600; color: white; white-space: nowrap; }
        .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #667eea; border-radius: 50%; width: 36px; height: 36px; animation: spin 1s linear infinite; margin: 0 auto; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        .remarks { background: #F3E5F5; border-left: 3px solid #8E24AA; padding: 8px 10px; border-radius: 4px; margin-top: 6px; font-size: 12px; color: #4A148C; }
        @media (max-width: 700px) { .form-grid { grid-template-columns: 1fr; } .table-wrap { overflow-x: auto; } }
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>🎫 तक्रार / मदत तिकीट (Support Tickets)</h1>
            <div class="sub"><%= user.getFullName() != null ? user.getFullName() : user.getUsername() %> | <%= user.getUserType().name() %> | UDISE: <%= user.getUdiseNo() != null ? user.getUdiseNo() : "-" %></div>
        </div>
        <div class="header-actions">
            <a href="javascript:history.back()">← Back</a>
        </div>
    </div>

    <div class="container">
        <!-- Raise Ticket Form -->
        <div class="section">
            <h2>➕ नवीन तिकीट (Raise New Ticket)</h2>
            <div class="form-grid">
                <div class="form-group">
                    <label>प्रकार (Category) <span class="req">*</span></label>
                    <select id="tkCategory">
                        <option value="LOGIN_ISSUE">🔑 लॉगिन समस्या (Login Issue)</option>
                        <option value="STUDENT_DATA">👨‍🎓 विद्यार्थी माहिती (Student Data)</option>
                        <option value="PHASE_ISSUE">📊 चरण समस्या (Phase Issue)</option>
                        <option value="PALAK_MELAVA">👪 पालक मेळावा (Palak Melava)</option>
                        <option value="PORTAL_ERROR">⚠️ पोर्टल त्रुटी (Portal Error)</option>
                        <option value="OTHER" selected>📋 इतर (Other)</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>प्राधान्य (Priority)</label>
                    <select id="tkPriority">
                        <option value="LOW">🟢 कमी (Low)</option>
                        <option value="MEDIUM" selected>🟡 मध्यम (Medium)</option>
                        <option value="HIGH">🔴 तातडीचे (High)</option>
                    </select>
                </div>
                <div class="form-group full">
                    <label>विषय (Subject) <span class="req">*</span></label>
                    <input type="text" id="tkSubject" maxlength="255" placeholder="तिकिटाचा विषय थोडक्यात लिहा">
                </div>
                <div class="form-group full">
                    <label>सविस्तर वर्णन (Description) <span class="req">*</span></label>
                    <textarea id="tkDescription" placeholder="समस्येचे सविस्तर वर्णन करा..."></textarea>
                </div>
                <div class="form-group full">
                    <label>संलग्नक (Attachments) — PDF / JPG / PNG, कमाल 3 फाइल्स, प्रत्येकी 5 MB पर्यंत</label>
                    <input type="file" id="tkFiles" multiple accept=".pdf,.jpg,.jpeg,.png,application/pdf,image/jpeg,image/png" onchange="showSelectedFiles()">
                    <div id="tkFileList" style="margin-top:8px; font-size:13px; color:#555;"></div>
                </div>
            </div>
            <button class="btn" id="tkSubmitBtn" onclick="submitTicket()">📨 तिकीट सादर करा (Submit Ticket)</button>
            <div class="alert ok" id="tkOk"></div>
            <div class="alert err" id="tkErr"></div>
        </div>

        <!-- My Tickets -->
        <div class="section">
            <h2>📋 माझी तिकिटे (My Tickets)</h2>
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Ticket No</th>
                            <th>Category</th>
                            <th>Subject</th>
                            <th>Priority</th>
                            <th>Status</th>
                            <th>Raised On</th>
                            <th>Division Response</th>
                        </tr>
                    </thead>
                    <tbody id="myTicketsBody">
                        <tr><td colspan="7" style="text-align:center; padding:30px;"><div class="spinner"></div></td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        const contextPath = '<%= request.getContextPath() %>';

        function escapeHtml(text) {
            if (text === null || text === undefined) return '';
            return String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;')
                .replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#039;');
        }

        function statusBadge(status) {
            const map = {
                'OPEN': '#F44336', 'IN_PROGRESS': '#FF9800',
                'RESOLVED': '#4CAF50', 'REJECTED': '#9E9E9E', 'CLOSED': '#607D8B'
            };
            return '<span class="badge" style="background:' + (map[status] || '#607D8B') + ';">' + escapeHtml(status.replace('_', ' ')) + '</span>';
        }

        function priorityBadge(p) {
            const map = { 'HIGH': '#E53935', 'MEDIUM': '#FB8C00', 'LOW': '#43A047' };
            return '<span class="badge" style="background:' + (map[p] || '#607D8B') + ';">' + escapeHtml(p) + '</span>';
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

        function showSelectedFiles() {
            const files = document.getElementById('tkFiles').files;
            const list = document.getElementById('tkFileList');
            if (!files.length) { list.innerHTML = ''; return; }
            let html = '';
            for (let i = 0; i < files.length; i++) {
                const sizeMb = (files[i].size / (1024 * 1024)).toFixed(2);
                const tooBig = files[i].size > 5 * 1024 * 1024;
                const badType = !/\.(pdf|jpe?g|png)$/i.test(files[i].name);
                html += '<div style="' + ((tooBig || badType) ? 'color:#B71C1C;' : '') + '">📎 ' + escapeHtml(files[i].name) + ' (' + sizeMb + ' MB)'
                     + (tooBig ? ' — 5 MB पेक्षा मोठी, वगळली जाईल' : '')
                     + (badType ? ' — फक्त PDF/JPG/PNG' : '') + '</div>';
            }
            if (files.length > 3) html += '<div style="color:#B71C1C;">कमाल 3 फाइल्स — पहिल्या 3 फाइल्सच जतन होतील</div>';
            list.innerHTML = html;
        }

        function submitTicket() {
            const subject = document.getElementById('tkSubject').value.trim();
            const description = document.getElementById('tkDescription').value.trim();
            const ok = document.getElementById('tkOk');
            const err = document.getElementById('tkErr');
            ok.style.display = 'none';
            err.style.display = 'none';

            if (!subject) { err.textContent = 'कृपया विषय लिहा (Subject is required)'; err.style.display = 'block'; return; }
            if (!description) { err.textContent = 'कृपया वर्णन लिहा (Description is required)'; err.style.display = 'block'; return; }

            const btn = document.getElementById('tkSubmitBtn');
            btn.disabled = true;
            btn.textContent = 'Submitting...';

            const fd = new FormData();
            fd.append('action', 'create');
            fd.append('category', document.getElementById('tkCategory').value);
            fd.append('priority', document.getElementById('tkPriority').value);
            fd.append('subject', subject);
            fd.append('description', description);
            const files = document.getElementById('tkFiles').files;
            for (let i = 0; i < files.length; i++) {
                fd.append('files', files[i]);
            }

            fetch(contextPath + '/tickets', {
                method: 'POST',
                body: fd
            })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                btn.textContent = '📨 तिकीट सादर करा (Submit Ticket)';
                if (data.success) {
                    let msg = '✓ तिकीट यशस्वीरित्या सादर झाले! Ticket No: ' + data.ticketNo;
                    if (data.attachmentsSaved > 0) msg += ' | 📎 ' + data.attachmentsSaved + ' file(s) uploaded';
                    if (data.attachmentsSkipped && data.attachmentsSkipped.length > 0) {
                        msg += ' | Skipped: ' + data.attachmentsSkipped.join(', ');
                    }
                    ok.textContent = msg;
                    ok.style.display = 'block';
                    document.getElementById('tkSubject').value = '';
                    document.getElementById('tkDescription').value = '';
                    document.getElementById('tkFiles').value = '';
                    document.getElementById('tkFileList').innerHTML = '';
                    loadMyTickets();
                } else {
                    err.textContent = 'Failed: ' + (data.error || 'Unknown error');
                    err.style.display = 'block';
                }
            })
            .catch(e => {
                btn.disabled = false;
                btn.textContent = '📨 तिकीट सादर करा (Submit Ticket)';
                err.textContent = 'Failed: ' + e;
                err.style.display = 'block';
            });
        }

        function loadMyTickets() {
            fetch(contextPath + '/tickets?action=my')
                .then(r => r.json())
                .then(data => {
                    const tbody = document.getElementById('myTicketsBody');
                    if (data.error) {
                        tbody.innerHTML = '<tr><td colspan="7" style="color:red; text-align:center; padding:20px;">' + escapeHtml(data.error) + '</td></tr>';
                        return;
                    }
                    const tickets = data.tickets || [];
                    if (tickets.length === 0) {
                        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding:25px; color:#999;">अद्याप एकही तिकीट नाही (No tickets yet)</td></tr>';
                        return;
                    }
                    let html = '';
                    tickets.forEach(t => {
                        html += '<tr>';
                        html += '<td style="font-family:monospace; font-weight:600;">' + escapeHtml(t.ticketNo) + '</td>';
                        html += '<td>' + escapeHtml(t.category) + '</td>';
                        html += '<td><div style="font-weight:600;">' + escapeHtml(t.subject) + '</div><div style="color:#666; font-size:12px; margin-top:3px;">' + escapeHtml(t.description) + '</div>' + attachmentLinks(t) + '</td>';
                        html += '<td>' + priorityBadge(t.priority) + '</td>';
                        html += '<td>' + statusBadge(t.status) + '</td>';
                        html += '<td style="white-space:nowrap;">' + escapeHtml((t.createdDate || '').substring(0, 16)) + '</td>';
                        html += '<td>' + (t.actionRemarks
                                ? '<div class="remarks">💬 ' + escapeHtml(t.actionRemarks) + '<br><span style="opacity:0.7;">- ' + escapeHtml(t.actionBy) + '</span></div>'
                                : '<span style="color:#bbb;">-</span>') + '</td>';
                        html += '</tr>';
                    });
                    tbody.innerHTML = html;
                })
                .catch(e => {
                    document.getElementById('myTicketsBody').innerHTML =
                        '<tr><td colspan="7" style="color:red; text-align:center; padding:20px;">Failed to load tickets</td></tr>';
                });
        }

        window.addEventListener('load', loadMyTickets);
    </script>
</body>
</html>
