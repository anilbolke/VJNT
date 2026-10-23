<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Promotion Correction — Terminal Class — GATEE Portal</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box;}
    body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f2f5;min-height:100vh;padding:24px;}
    .container{max-width:1100px;margin:0 auto;}

    .header{background:#fff;border-radius:12px;padding:24px 28px;margin-bottom:24px;
            box-shadow:0 2px 8px rgba(0,0,0,0.07);display:flex;align-items:center;justify-content:space-between;gap:16px;flex-wrap:wrap;}
    .header-left{display:flex;align-items:center;gap:14px;}
    .header h1{font-size:22px;font-weight:700;color:#2d3748;}
    .header p{font-size:13px;color:#718096;margin-top:3px;}
    .back-btn{background:#667eea;color:#fff;border:none;border-radius:8px;padding:9px 18px;
              font-size:14px;font-weight:600;cursor:pointer;text-decoration:none;display:inline-block;}
    .back-btn:hover{background:#5a67d8;}

    .info-banner{background:#ebf8ff;border:2px solid #90cdf4;border-radius:12px;
                 padding:14px 20px;margin-bottom:20px;display:flex;align-items:flex-start;gap:12px;font-size:14px;color:#2c5282;}
    .info-banner strong{font-size:15px;}

    .card{background:#fff;border-radius:12px;padding:24px 28px;margin-bottom:20px;box-shadow:0 2px 8px rgba(0,0,0,0.07);}
    .card h2{font-size:17px;font-weight:700;margin-bottom:16px;display:flex;align-items:center;gap:8px;color:#2d3748;}
    .step-num{background:#667eea;color:#fff;width:26px;height:26px;border-radius:50%;
              display:inline-flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0;}

    select,input[type=text]{border:1px solid #e2e8f0;border-radius:8px;padding:10px 14px;font-size:14px;font-family:inherit;}
    select{width:100%;background:#fff;}
    .row{display:flex;gap:10px;flex-wrap:wrap;}
    .row input[type=text]{flex:1;min-width:220px;}
    button{background:#667eea;color:#fff;border:none;border-radius:8px;padding:10px 20px;
           font-size:14px;font-weight:600;cursor:pointer;font-family:inherit;}
    button:hover:not(:disabled){background:#5a67d8;}
    button:disabled{background:#cbd5e0;cursor:not-allowed;}
    .btn-danger{background:#e53e3e;} .btn-danger:hover:not(:disabled){background:#c53030;}
    .btn-warn{background:#dd6b20;}   .btn-warn:hover:not(:disabled){background:#c05621;}

    table{width:100%;border-collapse:collapse;font-size:14px;}
    th{background:#f7fafc;text-align:left;padding:10px 12px;font-weight:700;color:#4a5568;
       border-bottom:2px solid #e2e8f0;font-size:13px;position:sticky;top:0;}
    td{padding:9px 12px;border-bottom:1px solid #edf2f7;color:#2d3748;}
    tr:hover td{background:#f7fafc;}
    .scroll{max-height:420px;overflow:auto;border:1px solid #edf2f7;border-radius:8px;}
    .table-wrap{overflow-x:auto;}

    .badge{display:inline-block;padding:3px 10px;border-radius:12px;font-size:12px;font-weight:600;}
    .b-short{background:#fed7d7;color:#822727;}
    .b-ok{background:#c6f6d5;color:#22543d;}
    .b-done{background:#e2e8f0;color:#4a5568;}
    .row-affected td{background:#fffaf0;}
    .row-affected:hover td{background:#fef5e7;}

    .summary-row{display:flex;gap:16px;margin-bottom:20px;flex-wrap:wrap;}
    .chip{flex:1;min-width:150px;background:#fff;border-radius:12px;padding:18px;text-align:center;
          box-shadow:0 2px 8px rgba(0,0,0,0.07);}
    .chip .num{font-size:28px;font-weight:700;color:#2d3748;}
    .chip .lbl{font-size:12px;color:#718096;margin-top:4px;text-transform:uppercase;letter-spacing:.4px;}
    .chip.bad .num{color:#c53030;}
    .chip.good .num{color:#2f855a;}

    .school-info{display:none;margin-top:16px;padding:14px 18px;background:#f7fafc;border-radius:8px;border-left:4px solid #667eea;}
    .school-info .name{font-size:16px;font-weight:700;color:#2d3748;}
    .school-info .meta{font-size:13px;color:#718096;margin-top:4px;}

    .warn-box{border-radius:10px;padding:14px 18px;margin-bottom:18px;display:flex;gap:12px;
              align-items:flex-start;font-size:14px;background:#fffbeb;border:2px solid #f6ad55;color:#744210;}

    .confirm-section{background:#fff5f5;border:2px solid #feb2b2;border-radius:12px;padding:22px;margin-bottom:20px;}
    .confirm-section h3{font-size:16px;font-weight:700;color:#c53030;margin-bottom:8px;}
    .confirm-section p{font-size:14px;color:#742a2a;margin-bottom:14px;}
    .confirm-section input{width:100%;margin-bottom:14px;}

    .spinner{display:none;text-align:center;padding:36px;}
    .spinner-ring{width:44px;height:44px;border:4px solid #e2e8f0;border-top-color:#667eea;
                  border-radius:50%;animation:spin .9s linear infinite;margin:0 auto 12px;}
    @keyframes spin{to{transform:rotate(360deg);}}
    .spinner p{font-size:14px;color:#718096;}

    .result{display:none;border-radius:12px;padding:26px;text-align:center;margin-bottom:20px;}
    .result.success{background:#f0fff4;border:2px solid #9ae6b4;}
    .result.error{background:#fff5f5;border:2px solid #feb2b2;}
    .result-icon{font-size:44px;margin-bottom:10px;}
    .result h2{font-size:20px;font-weight:700;margin-bottom:8px;}
    .result.success h2{color:#276749;} .result.error h2{color:#c53030;}
    .result .detail{font-size:15px;font-weight:600;color:#2d3748;margin:3px 0;}
    .muted{font-size:13px;color:#718096;margin-top:6px;}
    .hint{font-size:12px;color:#a0aec0;margin-top:6px;}
  </style>
</head>
<body>
<div class="container">

  <div class="header">
    <div class="header-left">
      <div style="font-size:34px;">🩺</div>
      <div>
        <h1>Promotion Correction — Terminal Class</h1>
        <p>Graduate students who sat in their school's real last class but were promoted instead</p>
      </div>
    </div>
    <a href="<%= request.getContextPath() %>/data-admin-dashboard.jsp" class="back-btn">← Back to Dashboard</a>
  </div>

  <div class="info-banner">
    <div style="font-size:22px;">ℹ️</div>
    <div>
      <strong>What this fixes</strong><br/>
      Promotion assumed every school ends at Class IX. In a school whose last class is V, VII or VIII,
      the top class was promoted into a class that does not exist there and never reached the graduated list.
      This tool reads each school's real terminal class from the pre-promotion snapshot
      (<code>student_phase_history</code>) and graduates those students with the correct class.
      <br/><br/>
      Marks are restored <strong>from the snapshot, not from the students table</strong> — promotion already
      overwrote the live rows, so the snapshot is the only place the real marks still exist.
    </div>
  </div>

  <!-- Step 1 — pick the run -->
  <div class="card">
    <h2><span class="step-num">1</span> Choose the promotion run</h2>
    <select id="runSelect" onchange="onRunChange()">
      <option value="">Loading promotion runs…</option>
    </select>
    <div class="hint">Single-school test runs are marked [TEST]. Pick the all-schools run you want to correct.</div>
    <div style="margin-top:14px;">
      <button id="scanBtn" onclick="scanAll()" disabled>🔍 Scan All Schools (read-only)</button>
    </div>
  </div>

  <div class="spinner" id="scanSpinner">
    <div class="spinner-ring"></div>
    <p>Scanning schools…</p>
  </div>

  <!-- Scan results -->
  <div id="scanSection" style="display:none;">
    <div class="summary-row">
      <div class="chip"><div class="num" id="chipSchools">—</div><div class="lbl">Schools in Run</div></div>
      <div class="chip bad"><div class="num" id="chipShort">—</div><div class="lbl">End Below Class IX</div></div>
      <div class="chip bad"><div class="num" id="chipAffected">—</div><div class="lbl">Students To Correct</div></div>
      <div class="chip"><div class="num" id="chipSchoolsAff">—</div><div class="lbl">Schools To Correct</div></div>
    </div>

    <div class="warn-box">
      ⚠️
      <div>
        <strong>Review this list with the district team before applying.</strong>
        The terminal class is derived from the highest class that actually had students that year.
        A school that genuinely runs to IX but had no IX students would show up here incorrectly —
        check any school ending below VIII especially carefully.
      </div>
    </div>

    <div class="card">
      <h2>🏫 Detected Terminal Class Per School</h2>
      <div class="table-wrap">
        <div class="scroll">
          <table>
            <thead><tr>
              <th>UDISE</th><th>School</th><th>District</th>
              <th>Last Class</th><th>Students</th><th>To Correct</th><th>Action</th>
            </tr></thead>
            <tbody id="scanBody"></tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <!-- Step 2 — one school -->
  <div class="card">
    <h2><span class="step-num">2</span> Dry run for one school</h2>
    <div class="row">
      <input type="text" id="udiseInput" placeholder="e.g. 27150300114" maxlength="20"
             onkeydown="if(event.key==='Enter') loadSchool()"/>
      <button onclick="loadSchool()">Load Dry Run</button>
    </div>
    <div class="hint">Zero writes. Shows exactly which students would be graduated and with which class.</div>
    <div class="school-info" id="schoolInfo">
      <div class="name" id="schoolName"></div>
      <div class="meta" id="schoolMeta"></div>
    </div>
  </div>

  <div class="spinner" id="loadSpinner">
    <div class="spinner-ring"></div>
    <p>Loading school…</p>
  </div>

  <div id="schoolSection" style="display:none;">
    <div class="summary-row">
      <div class="chip"><div class="num" id="chipTerminal">—</div><div class="lbl">Detected Last Class</div></div>
      <div class="chip bad"><div class="num" id="chipWillGrad">—</div><div class="lbl">Will Be Graduated</div></div>
      <div class="chip good"><div class="num" id="chipDone">—</div><div class="lbl">Already Corrected</div></div>
    </div>

    <div class="card">
      <h2>📋 Class Shape Before Promotion</h2>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Class</th><th>Students</th><th>Role</th></tr></thead>
          <tbody id="breakdownBody"></tbody>
        </table>
      </div>
    </div>

    <div class="card">
      <h2>🎓 Students That Will Be Graduated</h2>
      <div class="table-wrap">
        <div class="scroll">
          <table>
            <thead><tr>
              <th>Student</th><th>PEN</th><th>Real Class</th>
              <th>Wrongly Set To</th><th>Now In</th><th>Ph4 M/G/E</th>
            </tr></thead>
            <tbody id="studentBody"></tbody>
          </table>
        </div>
      </div>
      <div class="muted" id="noStudentsNote" style="display:none;">
        Nothing to correct for this school — every terminal-class student is already graduated.
      </div>
    </div>

    <div class="confirm-section" id="confirmOne">
      <h3>⚠️ Apply Correction — This School Only</h3>
      <p>
        These students will be inserted into <strong>graduated_students</strong>, marked inactive, and have
        their real class and marks restored from the snapshot. Type <strong>CORRECT</strong> to enable.
      </p>
      <input type="text" id="confirmInput" placeholder="Type CORRECT to confirm"
             autocomplete="off" oninput="checkConfirm()"/>
      <button class="btn-warn" id="applyOneBtn" disabled onclick="applyOne()">
        🩺 Apply Correction for This School
      </button>
    </div>
  </div>

  <!-- Step 3 — all schools -->
  <div class="card">
    <h2><span class="step-num">3</span> Apply to all schools</h2>
    <p style="font-size:14px;color:#718096;margin-bottom:14px;">
      Only after you have verified one school and confirmed those students now appear on
      <a href="<%= request.getContextPath() %>/graduated-students.jsp" target="_blank">graduated-students.jsp</a>.
      Each school is committed separately, so one bad school cannot corrupt the rest, and re-running
      never double-graduates anyone.
    </p>
    <div class="confirm-section">
      <h3>⚠️ Apply Correction — Every Affected School</h3>
      <p>Type <strong>CORRECT ALL</strong> to enable.</p>
      <input type="text" id="confirmAllInput" placeholder="Type CORRECT ALL to confirm"
             autocomplete="off" oninput="checkConfirmAll()"/>
      <button class="btn-danger" id="applyAllBtn" disabled onclick="applyAll()">
        🚨 Apply Correction for ALL Schools
      </button>
    </div>
  </div>

  <div class="spinner" id="applySpinner">
    <div class="spinner-ring"></div>
    <p>Applying correction — please wait…</p>
  </div>

  <div class="result" id="resultBox">
    <div class="result-icon" id="resultIcon"></div>
    <h2 id="resultTitle"></h2>
    <div id="resultDetails"></div>
    <div style="display:flex;gap:12px;justify-content:center;margin-top:18px;flex-wrap:wrap;">
      <a href="<%= request.getContextPath() %>/graduated-students.jsp" target="_blank"
         style="background:#48bb78;color:#fff;border-radius:8px;padding:10px 22px;text-decoration:none;font-weight:600;">
        🎓 View Graduated Students
      </a>
      <a href="<%= request.getContextPath() %>/promotion-correction.jsp"
         style="background:#667eea;color:#fff;border-radius:8px;padding:10px 22px;text-decoration:none;font-weight:600;">
        🔁 Start Over
      </a>
    </div>
  </div>

</div>
<script>
  var CTX = '<%= request.getContextPath() %>';
  var currentPid = '';
  var currentUdise = '';

  document.addEventListener('DOMContentLoaded', loadRuns);

  function loadRuns() {
    fetch(CTX + '/promotion-correction')
      .then(function(r){ return r.json(); })
      .then(function(data){
        var sel = document.getElementById('runSelect');
        if (!data.success || !data.runs || !data.runs.length) {
          sel.innerHTML = '<option value="">No promotion runs found</option>';
          return;
        }
        sel.innerHTML = '<option value="">— Select a promotion run —</option>';
        data.runs.forEach(function(r){
          var o = document.createElement('option');
          o.value = r.promotionId;
          o.textContent = '#' + r.promotionId + '  ' + r.academicYear +
            '  •  ' + (r.promotionDate || '').substring(0,16) +
            '  •  ' + r.schools + ' schools, ' + r.archived + ' students' +
            (r.isTest ? '   [TEST]' : '');
          sel.appendChild(o);
        });
      })
      .catch(function(e){
        document.getElementById('runSelect').innerHTML =
          '<option value="">Error loading runs: ' + e.message + '</option>';
      });
  }

  function onRunChange() {
    currentPid = document.getElementById('runSelect').value;
    document.getElementById('scanBtn').disabled = !currentPid;
    document.getElementById('scanSection').style.display = 'none';
    document.getElementById('schoolSection').style.display = 'none';
    document.getElementById('schoolInfo').style.display = 'none';
    document.getElementById('resultBox').style.display = 'none';
  }

  function scanAll() {
    if (!currentPid) { alert('Select a promotion run first.'); return; }
    document.getElementById('scanSection').style.display = 'none';
    document.getElementById('scanSpinner').style.display = 'block';

    fetch(CTX + '/promotion-correction?action=scan&promotionId=' + encodeURIComponent(currentPid))
      .then(function(r){ return r.json(); })
      .then(function(data){
        document.getElementById('scanSpinner').style.display = 'none';
        if (!data.success) { alert('Error: ' + data.message); return; }

        document.getElementById('chipSchools').textContent    = (data.totalSchools||0).toLocaleString();
        document.getElementById('chipShort').textContent      = (data.shortSchools||0).toLocaleString();
        document.getElementById('chipAffected').textContent   = (data.totalAffected||0).toLocaleString();
        document.getElementById('chipSchoolsAff').textContent = (data.schoolsAffected||0).toLocaleString();

        var tb = document.getElementById('scanBody');
        tb.innerHTML = '';
        (data.schools||[]).forEach(function(s){
          var tr = document.createElement('tr');
          if (s.affected > 0) tr.classList.add('row-affected');
          var cls = s.terminalRank < 9
            ? '<span class="badge b-short">Class ' + s.terminalClass + '</span>'
            : '<span class="badge b-ok">Class ' + s.terminalClass + '</span>';
          var act = s.affected > 0
            ? '<button onclick="pick(\'' + s.udise + '\')">Dry run →</button>'
            : '<span class="badge b-done">✓ nothing to do</span>';
          tr.innerHTML =
            '<td><strong>' + s.udise + '</strong></td>' +
            '<td>' + esc(s.schoolName) + '</td>' +
            '<td>' + esc(s.district) + '</td>' +
            '<td>' + cls + '</td>' +
            '<td>' + s.totalStudents + '</td>' +
            '<td><strong>' + (s.affected > 0 ? s.affected : '—') + '</strong></td>' +
            '<td>' + act + '</td>';
          tb.appendChild(tr);
        });
        document.getElementById('scanSection').style.display = 'block';
      })
      .catch(function(e){
        document.getElementById('scanSpinner').style.display = 'none';
        alert('Network error: ' + e.message);
      });
  }

  function pick(udise) {
    document.getElementById('udiseInput').value = udise;
    loadSchool();
    document.getElementById('udiseInput').scrollIntoView({behavior:'smooth', block:'center'});
  }

  function loadSchool() {
    if (!currentPid) { alert('Select a promotion run first.'); return; }
    var udise = document.getElementById('udiseInput').value.trim();
    if (!udise) { alert('Enter a UDISE number.'); return; }

    document.getElementById('schoolSection').style.display = 'none';
    document.getElementById('schoolInfo').style.display = 'none';
    document.getElementById('resultBox').style.display = 'none';
    document.getElementById('confirmInput').value = '';
    document.getElementById('applyOneBtn').disabled = true;
    document.getElementById('loadSpinner').style.display = 'block';

    fetch(CTX + '/promotion-correction?promotionId=' + encodeURIComponent(currentPid) +
                '&udise=' + encodeURIComponent(udise))
      .then(function(r){ return r.json(); })
      .then(function(data){
        document.getElementById('loadSpinner').style.display = 'none';
        if (!data.success) { alert('Error: ' + data.message); return; }

        currentUdise = data.udise;
        document.getElementById('schoolName').textContent = data.schoolName;
        document.getElementById('schoolMeta').textContent =
          'UDISE: ' + data.udise + '  |  Division: ' + (data.division||'—') +
          '  |  District: ' + (data.district||'—');
        document.getElementById('schoolInfo').style.display = 'block';

        document.getElementById('chipTerminal').textContent = data.terminalClass;
        document.getElementById('chipWillGrad').textContent = data.affected;
        document.getElementById('chipDone').textContent     = data.alreadyCorrected;

        var bb = document.getElementById('breakdownBody');
        bb.innerHTML = '';
        (data.breakdown||[]).forEach(function(b){
          var tr = document.createElement('tr');
          if (b.isTerminal) tr.classList.add('row-affected');
          tr.innerHTML =
            '<td>' + (b.isTerminal ? '🎓 ' : '') + 'Class ' + esc(b.classBefore) + '</td>' +
            '<td><strong>' + b.count + '</strong></td>' +
            '<td>' + (b.isTerminal
                ? '<span class="badge b-short">School terminal class</span>'
                : '<span class="badge b-ok">Promoted correctly</span>') + '</td>';
          bb.appendChild(tr);
        });

        var sb = document.getElementById('studentBody');
        sb.innerHTML = '';
        (data.students||[]).forEach(function(s){
          var lv = [s.marathi, s.math, s.english]
                   .map(function(v){ return (v===null||v===undefined) ? '—' : v; }).join(' / ');
          var tr = document.createElement('tr');
          tr.innerHTML =
            '<td>' + esc(s.studentName) + '</td>' +
            '<td>' + esc(s.studentPen) + '</td>' +
            '<td><strong>' + esc(s.classBefore) + '</strong></td>' +
            '<td><span class="badge b-short">' + esc(s.classAfter) + '</span></td>' +
            '<td>' + (s.stillPresent ? esc(s.currentClass) : '<em>not found</em>') + '</td>' +
            '<td>' + lv + '</td>';
          sb.appendChild(tr);
        });

        var none = data.affected === 0;
        document.getElementById('noStudentsNote').style.display = none ? 'block' : 'none';
        document.getElementById('confirmOne').style.display     = none ? 'none' : 'block';
        document.getElementById('schoolSection').style.display  = 'block';
      })
      .catch(function(e){
        document.getElementById('loadSpinner').style.display = 'none';
        alert('Network error: ' + e.message);
      });
  }

  function checkConfirm() {
    document.getElementById('applyOneBtn').disabled =
      document.getElementById('confirmInput').value.trim().toUpperCase() !== 'CORRECT';
  }
  function checkConfirmAll() {
    document.getElementById('applyAllBtn').disabled =
      document.getElementById('confirmAllInput').value.trim().toUpperCase() !== 'CORRECT ALL';
  }

  function applyOne() {
    if (!currentUdise) { alert('Load a school first.'); return; }
    post({ promotionId: currentPid, udise: currentUdise }, 'this school');
  }

  function applyAll() {
    if (!currentPid) { alert('Select a promotion run first.'); return; }
    post({ promotionId: currentPid, scope: 'all' }, 'all schools');
  }

  function post(fields, label) {
    document.getElementById('schoolSection').style.display = 'none';
    document.getElementById('scanSection').style.display   = 'none';
    document.getElementById('applySpinner').style.display  = 'block';
    document.getElementById('resultBox').style.display     = 'none';

    var params = new URLSearchParams();
    Object.keys(fields).forEach(function(k){ params.append(k, fields[k]); });

    fetch(CTX + '/promotion-correction', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: params.toString()
    })
    .then(function(r){ return r.json(); })
    .then(function(data){
      document.getElementById('applySpinner').style.display = 'none';
      var box = document.getElementById('resultBox');
      box.style.display = 'block';

      if (data.success || data.totalGraduated > 0) {
        box.className = 'result ' + (data.success ? 'success' : 'error');
        document.getElementById('resultIcon').textContent  = data.success ? '✅' : '⚠️';
        document.getElementById('resultTitle').textContent =
          data.success ? 'Correction Applied' : 'Applied With Errors';

        var html =
          '<p class="detail">Scope: <strong>' + label + '</strong></p>' +
          '<p class="detail">Schools processed: <strong>' + (data.schoolsAttempted||0) + '</strong></p>' +
          '<p class="detail">Students graduated: <strong>' + (data.totalGraduated||0) + '</strong></p>';
        if (data.schoolsFailed) {
          html += '<p class="detail" style="color:#c53030;">Schools failed: <strong>' +
                  data.schoolsFailed + '</strong></p>';
        }
        if (data.message) html += '<p class="muted">' + esc(data.message) + '</p>';

        var fails = (data.perSchool||[]).filter(function(p){ return !p.success; });
        if (fails.length) {
          html += '<div style="text-align:left;margin-top:14px;font-size:13px;color:#742a2a;">';
          fails.slice(0,20).forEach(function(f){
            html += '<div>• ' + f.udise + ' — ' + esc(f.message||'') + '</div>';
          });
          html += '</div>';
        }
        html += '<p class="muted">Verify on the graduated students page before doing anything else.</p>';
        document.getElementById('resultDetails').innerHTML = html;
      } else {
        box.className = 'result error';
        document.getElementById('resultIcon').textContent  = '❌';
        document.getElementById('resultTitle').textContent = 'Correction Failed';
        document.getElementById('resultDetails').innerHTML =
          '<p>' + esc(data.message||'An unexpected error occurred.') + '</p>' +
          '<p class="muted">No changes were committed.</p>';
      }
    })
    .catch(function(e){
      document.getElementById('applySpinner').style.display = 'none';
      var box = document.getElementById('resultBox');
      box.className = 'result error';
      box.style.display = 'block';
      document.getElementById('resultIcon').textContent  = '❌';
      document.getElementById('resultTitle').textContent = 'Network Error';
      document.getElementById('resultDetails').innerHTML = '<p>' + esc(e.message) + '</p>';
    });
  }

  function esc(s) {
    if (s === null || s === undefined) return '';
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;')
                    .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  }
</script>
</body>
</html>
