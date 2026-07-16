<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    if (user.getUserType() != User.UserType.DATA_ADMIN) {
        response.sendRedirect(request.getContextPath() + "/login?message=Access denied. Data Admin login required.");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Activity Visibility - GATEE PORTAL</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 18px 30px;
            display: flex;
            align-items: center;
            gap: 15px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.15);
        }
        .header img {
            width: 52px; height: 52px;
            background: #fff; border-radius: 50%;
            object-fit: contain; padding: 4px;
        }
        .header-title { flex: 1; }
        .header-title h1 { font-size: 20px; }
        .header-title p { font-size: 13px; opacity: 0.9; margin-top: 3px; }
        .back-btn {
            background: rgba(255,255,255,0.2);
            color: #fff;
            border: 1px solid rgba(255,255,255,0.6);
            padding: 8px 18px;
            border-radius: 6px;
            text-decoration: none;
            font-size: 14px;
        }
        .back-btn:hover { background: rgba(255,255,255,0.35); }

        .container { max-width: 1300px; margin: 25px auto; padding: 0 20px; }

        .info-banner {
            background: #ebf4ff;
            border-left: 4px solid #667eea;
            border-radius: 8px;
            padding: 14px 18px;
            font-size: 13.5px;
            color: #2d3748;
            margin-bottom: 20px;
            line-height: 1.6;
        }

        .card {
            background: #fff;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            padding: 20px;
            overflow-x: auto;
        }

        table { border-collapse: collapse; width: 100%; min-width: 750px; }
        th, td {
            border: 1px solid #e2e8f0;
            padding: 10px 12px;
            font-size: 13px;
            text-align: center;
            vertical-align: middle;
        }
        thead th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            font-size: 13px;
            white-space: nowrap;
        }
        th.activity-col, td.activity-col {
            text-align: left;
            min-width: 260px;
            position: sticky;
            left: 0;
            background: #fff;
            z-index: 2;
        }
        thead th.activity-col { background: #5a67d8; z-index: 3; }
        tbody tr:nth-child(even) td.activity-col { background: #f8f9fc; }
        tbody tr:nth-child(even) { background: #f8f9fc; }
        tbody tr:hover { background: #eef2ff; }
        tbody tr:hover td.activity-col { background: #eef2ff; }

        .act-name { font-weight: 600; color: #2d3748; }
        .act-marathi { font-size: 12px; color: #718096; margin-top: 2px; }

        input[type=checkbox] {
            width: 19px; height: 19px;
            cursor: pointer;
            accent-color: #667eea;
        }
        .col-toggle, .row-toggle {
            font-size: 11px;
            display: block;
            margin-top: 5px;
            color: #e9ebff;
            cursor: pointer;
            text-decoration: underline;
        }
        .row-toggle { color: #667eea; margin-top: 4px; display: inline-block; }

        .toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 15px;
            margin-top: 20px;
            flex-wrap: wrap;
        }
        .save-btn {
            background: linear-gradient(135deg, #48bb78 0%, #276749 100%);
            color: #fff;
            border: none;
            padding: 12px 35px;
            border-radius: 8px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            box-shadow: 0 3px 10px rgba(72,187,120,0.4);
        }
        .save-btn:hover { opacity: 0.92; }
        .save-btn:disabled { opacity: 0.6; cursor: not-allowed; }

        #status-msg { font-size: 14px; font-weight: 600; }
        #status-msg.ok { color: #276749; }
        #status-msg.err { color: #c53030; }

        .loading { text-align: center; padding: 50px; color: #718096; font-size: 15px; }

        .legend {
            font-size: 12.5px;
            color: #718096;
            margin-top: 12px;
        }
    </style>
</head>
<body>
    <div class="header">
        <img src="<%= request.getContextPath() %>/Document/GATEE LOGO.png?v=2" alt="GATEE Logo">
        <div class="header-title">
            <h1>🗂️ Activity Visibility Management</h1>
            <p>उपक्रम दृश्यता व्यवस्थापन — Control which Quick Actions each division's School Coordinators can see</p>
        </div>
        <a href="<%= request.getContextPath() %>/data-admin-dashboard.jsp" class="back-btn">← Dashboard</a>
    </div>

    <div class="container">
        <div class="info-banner">
            ✅ <strong>Checked</strong> = activity is visible to School Coordinators of that division &nbsp;|&nbsp;
            ⬜ <strong>Unchecked</strong> = activity is hidden for that division.<br>
            Divisions with no saved settings show <strong>all activities by default</strong>.
            Changes apply the next time the School Coordinator opens their dashboard.
        </div>

        <div class="card">
            <div id="matrix-area" class="loading">⏳ Loading divisions and activities...</div>
        </div>

        <div class="toolbar">
            <span id="status-msg"></span>
            <button class="save-btn" id="save-btn" onclick="saveMatrix()" disabled>💾 Save Changes</button>
        </div>
        <div class="legend">
            Applies to <strong>School Coordinator</strong> logins only. Head Master actions are not affected.
        </div>
    </div>

<script>
var CTX = '<%= request.getContextPath() %>';
var matrixData = null;

function loadMatrix() {
    fetch(CTX + '/activity-visibility')
        .then(function(r) {
            if (r.status === 401) { window.location.href = CTX + '/login'; return null; }
            return r.json();
        })
        .then(function(data) {
            if (!data) return;
            matrixData = data;
            renderMatrix(data);
            document.getElementById('save-btn').disabled = false;
        })
        .catch(function() {
            document.getElementById('matrix-area').innerHTML =
                '<div class="loading">❌ Could not load data. Please refresh the page.</div>';
        });
}

function isEnabled(data, division, code) {
    if (data.config[division] && data.config[division][code] !== undefined) {
        return data.config[division][code];
    }
    return true; /* default: visible */
}

function renderMatrix(data) {
    if (!data.divisions.length) {
        document.getElementById('matrix-area').innerHTML =
            '<div class="loading">No divisions found in student data yet.</div>';
        return;
    }
    var h = '<table><thead><tr>';
    h += '<th class="activity-col">Activity (उपक्रम)</th>';
    data.divisions.forEach(function(div, di) {
        h += '<th>' + esc(div)
           + '<span class="col-toggle" onclick="toggleColumn(' + di + ')">all / none</span></th>';
    });
    h += '</tr></thead><tbody>';

    data.activities.forEach(function(act, ai) {
        h += '<tr>';
        h += '<td class="activity-col"><div class="act-name">' + esc(act.icon || '') + ' ' + esc(act.name) + '</div>'
           + '<div class="act-marathi">' + esc(act.marathi || '') + '</div>'
           + '<span class="row-toggle" onclick="toggleRow(' + ai + ')">all / none</span></td>';
        data.divisions.forEach(function(div, di) {
            var checked = isEnabled(data, div, act.code) ? ' checked' : '';
            h += '<td><input type="checkbox" data-row="' + ai + '" data-col="' + di + '"'
               + ' data-div="' + esc(div) + '" data-code="' + esc(act.code) + '"' + checked + '></td>';
        });
        h += '</tr>';
    });
    h += '</tbody></table>';
    document.getElementById('matrix-area').className = '';
    document.getElementById('matrix-area').innerHTML = h;
}

function toggleColumn(colIdx) {
    var boxes = document.querySelectorAll('input[data-col="' + colIdx + '"]');
    var anyUnchecked = Array.prototype.some.call(boxes, function(b) { return !b.checked; });
    boxes.forEach(function(b) { b.checked = anyUnchecked; });
}

function toggleRow(rowIdx) {
    var boxes = document.querySelectorAll('input[data-row="' + rowIdx + '"]');
    var anyUnchecked = Array.prototype.some.call(boxes, function(b) { return !b.checked; });
    boxes.forEach(function(b) { b.checked = anyUnchecked; });
}

function saveMatrix() {
    var payload = {};
    document.querySelectorAll('#matrix-area input[type=checkbox]').forEach(function(b) {
        var div = b.getAttribute('data-div');
        if (!payload[div]) payload[div] = {};
        payload[div][b.getAttribute('data-code')] = b.checked;
    });

    var btn = document.getElementById('save-btn');
    var msg = document.getElementById('status-msg');
    btn.disabled = true;
    msg.textContent = 'Saving...';
    msg.className = '';

    fetch(CTX + '/activity-visibility', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    })
    .then(function(r) {
        if (r.status === 401) { window.location.href = CTX + '/login'; return null; }
        return r.json();
    })
    .then(function(data) {
        btn.disabled = false;
        if (!data) return;
        if (data.success) {
            msg.textContent = '✅ Saved successfully. Settings are now live.';
            msg.className = 'ok';
        } else {
            msg.textContent = '❌ ' + (data.message || 'Save failed. Please retry.');
            msg.className = 'err';
        }
    })
    .catch(function() {
        btn.disabled = false;
        msg.textContent = '❌ Network error. Please retry.';
        msg.className = 'err';
    });
}

function esc(s) {
    return String(s == null ? '' : s)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

loadMatrix();
</script>
<jsp:include page="chatbot-widget.jsp" />
</body>
</html>
