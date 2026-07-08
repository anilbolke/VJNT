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
  <title>Promote Classes — GATEE Portal</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box;}
    body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f2f5;min-height:100vh;padding:24px;}
    .container{max-width:860px;margin:0 auto;}

    .header{background:#fff;border-radius:12px;padding:24px 28px;margin-bottom:24px;
            box-shadow:0 2px 8px rgba(0,0,0,0.07);display:flex;align-items:center;justify-content:space-between;}
    .header-left{display:flex;align-items:center;gap:14px;}
    .header h1{font-size:22px;font-weight:700;color:#2d3748;}
    .header p{font-size:13px;color:#718096;margin-top:3px;}
    .back-btn{background:#667eea;color:#fff;border:none;border-radius:8px;padding:9px 18px;
              font-size:14px;font-weight:600;cursor:pointer;text-decoration:none;display:inline-block;}
    .back-btn:hover{background:#5a67d8;}

    .card{background:#fff;border-radius:12px;padding:28px;margin-bottom:20px;box-shadow:0 2px 8px rgba(0,0,0,0.07);}
    .card h2{font-size:18px;font-weight:700;margin-bottom:16px;display:flex;align-items:center;gap:8px;}

    /* Preview table */
    table{width:100%;border-collapse:collapse;font-size:14px;}
    th{background:#667eea;color:#fff;padding:11px 16px;text-align:left;font-weight:600;}
    td{padding:11px 16px;border-bottom:1px solid #e2e8f0;}
    tr:last-child td{border-bottom:none;}
    tr.grad-row td{background:#fffbeb;font-weight:600;color:#744210;}
    .action-badge{display:inline-block;border-radius:6px;padding:3px 10px;font-size:12px;font-weight:600;}
    .action-promote{background:#c6f6d5;color:#276749;}
    .action-graduate{background:#fbd38d;color:#7c2d12;}

    /* Form */
    .form-group{margin-bottom:18px;}
    .form-group label{display:block;font-size:14px;font-weight:600;color:#2d3748;margin-bottom:6px;}
    .form-group input,.form-group textarea{width:100%;border:1px solid #e2e8f0;border-radius:8px;
      padding:10px 14px;font-size:14px;font-family:inherit;outline:none;transition:border-color .2s;}
    .form-group input:focus,.form-group textarea:focus{border-color:#667eea;}
    .form-group textarea{resize:vertical;min-height:70px;}
    .form-group .hint{font-size:12px;color:#718096;margin-top:4px;}

    /* Confirm box */
    .confirm-section{background:#fff5f5;border:2px solid #feb2b2;border-radius:10px;padding:20px;margin-bottom:20px;}
    .confirm-section h3{color:#c53030;font-size:16px;margin-bottom:12px;display:flex;align-items:center;gap:8px;}
    .confirm-section p{font-size:14px;color:#742a2a;margin-bottom:14px;}
    .confirm-section input{width:100%;border:2px solid #fc8181;border-radius:8px;padding:10px 14px;
      font-size:15px;font-weight:700;letter-spacing:2px;text-align:center;outline:none;
      background:#fff;transition:border-color .2s;}
    .confirm-section input:focus{border-color:#e53e3e;}

    .btn-promote{width:100%;padding:15px;background:#c53030;color:#fff;border:none;border-radius:10px;
      font-size:17px;font-weight:700;cursor:pointer;transition:background .2s;margin-top:10px;}
    .btn-promote:hover:not(:disabled){background:#9b2c2c;}
    .btn-promote:disabled{background:#e2e8f0;color:#a0aec0;cursor:not-allowed;}

    /* Summary chips */
    .summary-row{display:flex;gap:14px;flex-wrap:wrap;margin-bottom:20px;}
    .chip{background:#ebf8ff;border:1px solid #90cdf4;border-radius:8px;padding:12px 18px;text-align:center;flex:1;min-width:140px;}
    .chip.grad{background:#fffbeb;border-color:#f6e05e;}
    .chip .num{font-size:28px;font-weight:700;color:#3182ce;}
    .chip.grad .num{color:#d69e2e;}
    .chip .lbl{font-size:12px;color:#718096;margin-top:3px;}

    /* Result */
    .result{display:none;border-radius:12px;padding:28px;text-align:center;margin-bottom:20px;}
    .result.success{background:#f0fff4;border:2px solid #9ae6b4;}
    .result.error  {background:#fff5f5;border:2px solid #feb2b2;}
    .result-icon{font-size:52px;margin-bottom:14px;}
    .result h2{font-size:22px;font-weight:700;margin-bottom:10px;}
    .result.success h2{color:#276749;}
    .result.error   h2{color:#c53030;}
    .result p{font-size:14px;color:#718096;margin-bottom:6px;}
    .result .detail{font-size:16px;font-weight:600;color:#2d3748;margin:4px 0;}

    /* Spinner */
    .spinner{display:none;text-align:center;padding:30px;}
    .spinner-ring{width:48px;height:48px;border:5px solid #e2e8f0;border-top-color:#667eea;
      border-radius:50%;animation:spin .9s linear infinite;margin:0 auto 14px;}
    @keyframes spin{to{transform:rotate(360deg);}}
    .spinner p{font-size:14px;color:#718096;}

    .warn-box{background:#fffbeb;border:1px solid #f6e05e;border-radius:8px;padding:14px 18px;
      font-size:13px;color:#744210;display:flex;gap:10px;align-items:flex-start;margin-bottom:20px;}
  </style>
</head>
<body>
<div class="container">

  <!-- Header -->
  <div class="header">
    <div class="header-left">
      <div style="font-size:36px;">🎓</div>
      <div>
        <h1>Promote Classes</h1>
        <p>Advance all students to the next class for a new academic year</p>
      </div>
    </div>
    <a href="<%= request.getContextPath() %>/data-admin-dashboard.jsp" class="back-btn">← Back to Dashboard</a>
  </div>

  <!-- Loading state -->
  <div class="spinner" id="loadingSpinner">
    <div class="spinner-ring"></div>
    <p>Loading student data...</p>
  </div>

  <!-- Main content (hidden until preview loads) -->
  <div id="mainContent" style="display:none;">

    <!-- Summary chips -->
    <div class="summary-row">
      <div class="chip">
        <div class="num" id="chipTotal">—</div>
        <div class="lbl">Total Active Students</div>
      </div>
      <div class="chip">
        <div class="num" id="chipPromote" style="color:#38a169;">—</div>
        <div class="lbl">To Be Promoted (Class 1–8)</div>
      </div>
      <div class="chip grad">
        <div class="num" id="chipGrad">—</div>
        <div class="lbl">To Graduate (Class 9)</div>
      </div>
    </div>

    <!-- Preview table -->
    <div class="card">
      <h2>📋 Class-wise Breakdown</h2>
      <table id="previewTable">
        <thead>
          <tr><th>Current Class</th><th>Students</th><th>Action</th></tr>
        </thead>
        <tbody id="previewBody"></tbody>
      </table>
    </div>

    <!-- Incomplete phases warning — shown only if some schools haven't finished Phase 4 -->
    <div class="warn-box" id="incompleteWarn" style="display:none;background:#fff5f5;border-color:#feb2b2;color:#742a2a;">
      ⚠️
      <div>
        <strong><span id="incompleteCount">0</span> students across <span id="incompleteSchools">0</span> school(s) have not completed all 4 phases.</strong>
        Their Phase 1 baseline for the new year will be seeded from the last phase they did complete. Promotion can still proceed safely.
      </div>
    </div>

    <!-- Test mode link -->
    <div class="warn-box" style="background:#f0fff4;border-color:#9ae6b4;color:#276749;">
      🧪
      <div>
        <strong>Want to test first?</strong>
        Run the promotion for a single school before applying to all.
        <a href="<%= request.getContextPath() %>/test-promote.jsp"
           style="color:#276749;font-weight:700;margin-left:6px;">→ Open Test Promote Tool</a>
      </div>
    </div>

    <!-- Incomplete phases warning — shown only if some schools haven't finished Phase 4 -->
    <div class="warn-box" id="incompleteWarn" style="display:none;background:#fff5f5;border-color:#feb2b2;color:#742a2a;">
      ⚠️
      <div>
        <strong><span id="incompleteCount">0</span> students across <span id="incompleteSchools">0</span> school(s) have not completed all 4 phases.</strong>
        Their Phase 1 baseline for the new year will be seeded from the last phase they did complete. Promotion can still proceed safely.
      </div>
    </div>

    <div class="warn-box">
      ⚠️
      <div>
        <strong>This action covers ALL schools across ALL districts.</strong>
        All phase data will be archived before changes are made. Class 9 students will be moved permanently to the Graduated Students record and marked inactive.
      </div>
    </div>

    <!-- Promotion form -->
    <div class="card">
      <h2>📝 Promotion Details</h2>

      <div class="form-group">
        <label>Academic Year (being closed)</label>
        <input type="text" id="academicYear" placeholder="e.g. 2025-26" maxlength="10"/>
        <div class="hint">Enter the academic year that is ending.</div>
      </div>

      <div class="form-group">
        <label>Remarks (optional)</label>
        <textarea id="remarks" placeholder="e.g. Annual year-end promotion June 2026"></textarea>
      </div>
    </div>

    <!-- Type-to-confirm -->
    <div class="confirm-section">
      <h3>⚠️ Confirm Action</h3>
      <p>This action <strong>cannot be undone</strong>. All phase data is archived but students will be promoted immediately. Type <strong>PROMOTE</strong> below to enable the button.</p>
      <input type="text" id="confirmInput" placeholder='Type PROMOTE to confirm' autocomplete="off"
             oninput="checkConfirm()"/>
      <button class="btn-promote" id="promoteBtn" disabled onclick="runPromotion()">
        🎓 Promote All Classes Now
      </button>
    </div>
  </div>

  <!-- Processing spinner -->
  <div class="spinner" id="processingSpinner">
    <div class="spinner-ring"></div>
    <p>Promotion in progress — please do not close this page...</p>
  </div>

  <!-- Result -->
  <div class="result" id="resultBox">
    <div class="result-icon" id="resultIcon"></div>
    <h2 id="resultTitle"></h2>
    <div id="resultDetails"></div>
    <a href="<%= request.getContextPath() %>/data-admin-dashboard.jsp"
       style="display:inline-block;margin-top:20px;background:#667eea;color:#fff;
              border-radius:8px;padding:10px 24px;text-decoration:none;font-weight:600;">
      ← Back to Dashboard
    </a>
  </div>

</div>

<script>
  // Load preview on page load
  document.getElementById('loadingSpinner').style.display = 'block';

  fetch('<%= request.getContextPath() %>/promote-classes')
    .then(r => r.json())
    .then(data => {
      document.getElementById('loadingSpinner').style.display = 'none';

      if (!data.success) {
        showError('Failed to load preview: ' + data.message);
        return;
      }

      // Fill chips
      document.getElementById('chipTotal').textContent   = (data.totalStudents || 0).toLocaleString();
      document.getElementById('chipPromote').textContent = ((data.totalStudents||0) - (data.totalGraduating||0)).toLocaleString();
      document.getElementById('chipGrad').textContent    = (data.totalGraduating || 0).toLocaleString();

      // Incomplete-phases warning
      if (data.incompleteStudents > 0) {
        const warnEl = document.getElementById('incompleteWarn');
        document.getElementById('incompleteCount').textContent  = data.incompleteStudents.toLocaleString();
        document.getElementById('incompleteSchools').textContent = data.incompleteSchools.toLocaleString();
        warnEl.style.display = 'flex';
      }

      // Fill table
      const tbody = document.getElementById('previewBody');
      (data.preview || []).forEach(row => {
        const isGrad = row.action === '→ GRADUATE';
        const tr = document.createElement('tr');
        if (isGrad) tr.classList.add('grad-row');
        tr.innerHTML =
          '<td>' + (isGrad ? '🎓 ' : '') + 'Class ' + row.class + '</td>' +
          '<td><strong>' + row.count.toLocaleString() + '</strong></td>' +
          '<td><span class="action-badge ' + (isGrad ? 'action-graduate' : 'action-promote') + '">' +
            (isGrad ? '🏁 Graduate → Exit System' : row.action) +
          '</span></td>';
        tbody.appendChild(tr);
      });

      // Auto-fill academic year
      const now = new Date();
      const y1  = now.getFullYear() - 1;
      const y2  = String(now.getFullYear()).slice(-2);
      document.getElementById('academicYear').value = y1 + '-' + y2;

      document.getElementById('mainContent').style.display = 'block';
    })
    .catch(err => {
      document.getElementById('loadingSpinner').style.display = 'none';
      showError('Network error loading preview: ' + err.message);
    });

  function checkConfirm() {
    const val = document.getElementById('confirmInput').value.trim().toUpperCase();
    document.getElementById('promoteBtn').disabled = (val !== 'PROMOTE');
  }

  function runPromotion() {
    const academicYear = document.getElementById('academicYear').value.trim();
    const remarks      = document.getElementById('remarks').value.trim();

    if (!academicYear) {
      alert('Please enter the Academic Year before promoting.');
      return;
    }

    document.getElementById('mainContent').style.display    = 'none';
    document.getElementById('processingSpinner').style.display = 'block';

    const params = new URLSearchParams();
    params.append('academicYear', academicYear);
    params.append('remarks',      remarks);

    fetch('<%= request.getContextPath() %>/promote-classes', {
      method:  'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body:    params.toString()
    })
    .then(r => r.json())
    .then(data => {
      document.getElementById('processingSpinner').style.display = 'none';
      const box = document.getElementById('resultBox');
      box.style.display = 'block';

      if (data.success) {
        box.className = 'result success';
        document.getElementById('resultIcon').textContent  = '✅';
        document.getElementById('resultTitle').textContent = 'Promotion Successful!';
        document.getElementById('resultDetails').innerHTML =
          '<p class="detail">Promotion ID: <strong>#' + data.promotionId + '</strong></p>' +
          '<p class="detail">Students Promoted: <strong>' + (data.studentsPromoted||0).toLocaleString() + '</strong></p>' +
          '<p class="detail">Students Graduated: <strong>' + (data.studentsGraduated||0).toLocaleString() + '</strong></p>' +
          '<p style="margin-top:10px;">All phase data has been archived. Teachers can now begin Phase 1 assessments.</p>';
      } else {
        box.className = 'result error';
        document.getElementById('resultIcon').textContent  = '❌';
        document.getElementById('resultTitle').textContent = 'Promotion Failed';
        document.getElementById('resultDetails').innerHTML =
          '<p>' + (data.message || 'An unexpected error occurred.') + '</p>' +
          '<p style="margin-top:10px;">No changes were made. Please try again or contact support.</p>';
      }
    })
    .catch(err => {
      document.getElementById('processingSpinner').style.display = 'none';
      showError('Network error during promotion: ' + err.message);
    });
  }

  function showError(msg) {
    const box = document.getElementById('resultBox');
    box.className = 'result error';
    box.style.display = 'block';
    document.getElementById('resultIcon').textContent  = '❌';
    document.getElementById('resultTitle').textContent = 'Error';
    document.getElementById('resultDetails').innerHTML = '<p>' + msg + '</p>';
  }
</script>
</body>
</html>
