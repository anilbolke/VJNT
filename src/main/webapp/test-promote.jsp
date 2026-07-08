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
  <title>Test Promote (Single School) — GATEE Portal</title>
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

    /* Test mode banner */
    .test-banner{background:#fffbeb;border:2px solid #f6ad55;border-radius:12px;
                 padding:14px 20px;margin-bottom:20px;display:flex;align-items:center;gap:12px;font-size:14px;color:#744210;}
    .test-banner strong{font-size:15px;}

    .card{background:#fff;border-radius:12px;padding:28px;margin-bottom:20px;box-shadow:0 2px 8px rgba(0,0,0,0.07);}
    .card h2{font-size:17px;font-weight:700;margin-bottom:16px;display:flex;align-items:center;gap:8px;}

    /* UDISE lookup */
    .udise-row{display:flex;gap:10px;}
    .udise-row input{flex:1;border:1px solid #e2e8f0;border-radius:8px;padding:10px 14px;
                     font-size:15px;outline:none;transition:border-color .2s;}
    .udise-row input:focus{border-color:#ed8936;}
    .udise-row button{background:#ed8936;color:#fff;border:none;border-radius:8px;padding:10px 22px;
                      font-size:14px;font-weight:600;cursor:pointer;white-space:nowrap;}
    .udise-row button:hover{background:#dd6b20;}

    /* School info badge */
    .school-info{display:none;background:#fefce8;border:1px solid #fde68a;border-radius:8px;
                 padding:14px 18px;margin-top:14px;}
    .school-info .name{font-size:15px;font-weight:700;color:#92400e;}
    .school-info .meta{font-size:13px;color:#a16207;margin-top:4px;}

    /* Preview table */
    table{width:100%;border-collapse:collapse;font-size:14px;}
    th{background:#ed8936;color:#fff;padding:11px 16px;text-align:left;font-weight:600;}
    td{padding:11px 16px;border-bottom:1px solid #e2e8f0;}
    tr:last-child td{border-bottom:none;}
    tr.grad-row td{background:#fffbeb;font-weight:600;color:#744210;}
    .action-badge{display:inline-block;border-radius:6px;padding:3px 10px;font-size:12px;font-weight:600;}
    .action-promote{background:#c6f6d5;color:#276749;}
    .action-graduate{background:#fbd38d;color:#7c2d12;}

    /* Summary chips */
    .summary-row{display:flex;gap:14px;flex-wrap:wrap;margin-bottom:20px;}
    .chip{background:#fff7ed;border:1px solid #fdba74;border-radius:8px;padding:12px 18px;
          text-align:center;flex:1;min-width:130px;}
    .chip.grad{background:#fffbeb;border-color:#f6e05e;}
    .chip .num{font-size:26px;font-weight:700;color:#c2410c;}
    .chip.grad .num{color:#d69e2e;}
    .chip .lbl{font-size:12px;color:#718096;margin-top:3px;}

    /* Form */
    .form-group{margin-bottom:18px;}
    .form-group label{display:block;font-size:14px;font-weight:600;color:#2d3748;margin-bottom:6px;}
    .form-group input,.form-group textarea{width:100%;border:1px solid #e2e8f0;border-radius:8px;
      padding:10px 14px;font-size:14px;font-family:inherit;outline:none;transition:border-color .2s;}
    .form-group input:focus,.form-group textarea:focus{border-color:#ed8936;}
    .form-group textarea{resize:vertical;min-height:60px;}
    .form-group .hint{font-size:12px;color:#718096;margin-top:4px;}

    /* Confirm */
    .confirm-section{background:#fff5f5;border:2px solid #feb2b2;border-radius:10px;padding:20px;margin-bottom:20px;}
    .confirm-section h3{color:#c53030;font-size:15px;margin-bottom:10px;display:flex;align-items:center;gap:8px;}
    .confirm-section p{font-size:13px;color:#742a2a;margin-bottom:12px;}
    .confirm-section input{width:100%;border:2px solid #fc8181;border-radius:8px;padding:10px 14px;
      font-size:15px;font-weight:700;letter-spacing:2px;text-align:center;outline:none;background:#fff;}

    .btn-promote{width:100%;padding:14px;background:#c53030;color:#fff;border:none;border-radius:10px;
      font-size:16px;font-weight:700;cursor:pointer;transition:background .2s;margin-top:10px;}
    .btn-promote:hover:not(:disabled){background:#9b2c2c;}
    .btn-promote:disabled{background:#e2e8f0;color:#a0aec0;cursor:not-allowed;}

    /* Warn */
    .warn-box{background:#fffbeb;border:1px solid #f6e05e;border-radius:8px;padding:13px 16px;
      font-size:13px;color:#744210;display:flex;gap:10px;align-items:flex-start;margin-bottom:18px;}

    /* Spinner */
    .spinner{display:none;text-align:center;padding:28px;}
    .spinner-ring{width:44px;height:44px;border:5px solid #e2e8f0;border-top-color:#ed8936;
      border-radius:50%;animation:spin .9s linear infinite;margin:0 auto 12px;}
    @keyframes spin{to{transform:rotate(360deg);}}
    .spinner p{font-size:14px;color:#718096;}

    /* Result */
    .result{display:none;border-radius:12px;padding:28px;text-align:center;margin-bottom:20px;}
    .result.success{background:#f0fff4;border:2px solid #9ae6b4;}
    .result.error  {background:#fff5f5;border:2px solid #feb2b2;}
    .result-icon{font-size:48px;margin-bottom:12px;}
    .result h2{font-size:20px;font-weight:700;margin-bottom:8px;}
    .result.success h2{color:#276749;}
    .result.error   h2{color:#c53030;}
    .result p{font-size:14px;color:#718096;margin-bottom:5px;}
    .result .detail{font-size:15px;font-weight:600;color:#2d3748;margin:3px 0;}
  </style>
</head>
<body>
<div class="container">

  <!-- Header -->
  <div class="header">
    <div class="header-left">
      <div style="font-size:34px;">🧪</div>
      <div>
        <h1>Test Promote — Single School</h1>
        <p>Run the full promotion flow for one school before promoting all</p>
      </div>
    </div>
    <a href="<%= request.getContextPath() %>/promote-classes.jsp" class="back-btn">← Back to Promote</a>
  </div>

  <!-- Test mode banner -->
  <div class="test-banner">
    🔬
    <div>
      <strong>Test Mode — Real Data Will Be Modified</strong><br/>
      This performs the actual promotion for ONE school. Phase data is archived, Class IX students graduate, and classes advance. Use this to verify the process works correctly before running it for all schools.
    </div>
  </div>

  <!-- UDISE Lookup -->
  <div class="card">
    <h2>🏫 Enter School UDISE Number</h2>
    <div class="udise-row">
      <input type="text" id="udiseInput" placeholder="e.g. 27150100101" maxlength="20"
             onkeydown="if(event.key==='Enter') loadPreview()"/>
      <button onclick="loadPreview()">Load Preview</button>
    </div>
    <div class="school-info" id="schoolInfo">
      <div class="name" id="schoolName"></div>
      <div class="meta" id="schoolMeta"></div>
    </div>
  </div>

  <!-- Spinner -->
  <div class="spinner" id="loadingSpinner">
    <div class="spinner-ring"></div>
    <p>Loading school data...</p>
  </div>

  <!-- Preview section (hidden until loaded) -->
  <div id="previewSection" style="display:none;">

    <!-- Summary chips -->
    <div class="summary-row">
      <div class="chip">
        <div class="num" id="chipTotal">—</div>
        <div class="lbl">Total Students</div>
      </div>
      <div class="chip">
        <div class="num" id="chipPromote" style="color:#2f855a;">—</div>
        <div class="lbl">To Be Promoted</div>
      </div>
      <div class="chip grad">
        <div class="num" id="chipGrad">—</div>
        <div class="lbl">To Graduate (Class 9)</div>
      </div>
    </div>

    <!-- Class breakdown -->
    <div class="card">
      <h2>📋 Class-wise Breakdown</h2>
      <table>
        <thead><tr><th>Current Class</th><th>Students</th><th>Action</th></tr></thead>
        <tbody id="previewBody"></tbody>
      </table>
    </div>

    <!-- Incomplete warning -->
    <div class="warn-box" id="incompleteWarn" style="display:none;background:#fff5f5;border-color:#feb2b2;color:#742a2a;">
      ⚠️
      <div>
        <strong><span id="incompleteCount">0</span> students have not completed all 4 phases.</strong>
        Their Phase 1 baseline will be seeded from the last phase they completed. Promotion is still safe.
      </div>
    </div>

    <!-- Promotion details form -->
    <div class="card">
      <h2>📝 Promotion Details</h2>
      <div class="form-group">
        <label>Academic Year (being closed)</label>
        <input type="text" id="academicYear" placeholder="e.g. 2025-26" maxlength="10"/>
        <div class="hint">Enter the academic year that is ending.</div>
      </div>
      <div class="form-group">
        <label>Remarks (optional)</label>
        <textarea id="remarks" placeholder="e.g. Test run before full promotion"></textarea>
      </div>
    </div>

    <!-- Type-to-confirm -->
    <div class="confirm-section">
      <h3>⚠️ Confirm Test Promotion</h3>
      <p>This will promote all students in this one school. All phase data will be archived. Type <strong>PROMOTE</strong> to enable the button.</p>
      <input type="text" id="confirmInput" placeholder="Type PROMOTE to confirm"
             autocomplete="off" oninput="checkConfirm()"/>
      <button class="btn-promote" id="promoteBtn" disabled onclick="runPromotion()">
        🧪 Run Test Promotion for This School
      </button>
    </div>
  </div>

  <!-- Processing spinner -->
  <div class="spinner" id="processingSpinner">
    <div class="spinner-ring"></div>
    <p>Promotion in progress — please wait...</p>
  </div>

  <!-- Result -->
  <div class="result" id="resultBox">
    <div class="result-icon" id="resultIcon"></div>
    <h2 id="resultTitle"></h2>
    <div id="resultDetails"></div>
    <div style="display:flex;gap:12px;justify-content:center;margin-top:20px;flex-wrap:wrap;">
      <a href="<%= request.getContextPath() %>/test-promote.jsp"
         style="background:#ed8936;color:#fff;border-radius:8px;padding:10px 22px;text-decoration:none;font-weight:600;">
        🔁 Test Another School
      </a>
      <a href="<%= request.getContextPath() %>/promote-classes.jsp"
         style="background:#667eea;color:#fff;border-radius:8px;padding:10px 22px;text-decoration:none;font-weight:600;">
        🎓 Go to Full Promotion
      </a>
      <a href="<%= request.getContextPath() %>/promotion-audit.jsp"
         style="background:#48bb78;color:#fff;border-radius:8px;padding:10px 22px;text-decoration:none;font-weight:600;">
        📋 View Audit Log
      </a>
    </div>
  </div>

</div>
<script>
  let currentUdise = '';

  function loadPreview() {
    const udise = document.getElementById('udiseInput').value.trim();
    if (!udise) { alert('Please enter a UDISE number.'); return; }

    // Reset
    document.getElementById('previewSection').style.display = 'none';
    document.getElementById('schoolInfo').style.display     = 'none';
    document.getElementById('resultBox').style.display      = 'none';
    document.getElementById('previewBody').innerHTML        = '';
    document.getElementById('confirmInput').value           = '';
    document.getElementById('promoteBtn').disabled          = true;

    document.getElementById('loadingSpinner').style.display = 'block';

    fetch('<%= request.getContextPath() %>/test-promote?udise=' + encodeURIComponent(udise))
      .then(r => r.json())
      .then(data => {
        document.getElementById('loadingSpinner').style.display = 'none';

        if (!data.success) {
          alert('Error: ' + data.message);
          return;
        }

        currentUdise = data.udise;

        // School info
        document.getElementById('schoolName').textContent = data.schoolName;
        document.getElementById('schoolMeta').textContent =
          'UDISE: ' + data.udise + '  |  Division: ' + (data.division||'—') + '  |  District: ' + (data.district||'—');
        document.getElementById('schoolInfo').style.display = 'block';

        // Chips
        document.getElementById('chipTotal').textContent   = (data.totalStudents||0).toLocaleString();
        document.getElementById('chipPromote').textContent = ((data.totalStudents||0)-(data.totalGraduating||0)).toLocaleString();
        document.getElementById('chipGrad').textContent    = (data.totalGraduating||0).toLocaleString();

        // Incomplete warning
        if (data.incompleteStudents > 0) {
          document.getElementById('incompleteCount').textContent = data.incompleteStudents.toLocaleString();
          document.getElementById('incompleteWarn').style.display = 'flex';
        } else {
          document.getElementById('incompleteWarn').style.display = 'none';
        }

        // Table
        const tbody = document.getElementById('previewBody');
        (data.preview||[]).forEach(row => {
          const isGrad = row.action === '→ GRADUATE';
          const tr = document.createElement('tr');
          if (isGrad) tr.classList.add('grad-row');
          tr.innerHTML =
            '<td>' + (isGrad ? '🎓 ' : '') + 'Class ' + row.class + '</td>' +
            '<td><strong>' + row.count.toLocaleString() + '</strong></td>' +
            '<td><span class="action-badge ' + (isGrad ? 'action-graduate' : 'action-promote') + '">' +
              (isGrad ? '🏁 Graduate' : row.action) +
            '</span></td>';
          tbody.appendChild(tr);
        });

        // Auto-fill year
        const now = new Date();
        document.getElementById('academicYear').value =
          (now.getFullYear()-1) + '-' + String(now.getFullYear()).slice(-2);

        document.getElementById('previewSection').style.display = 'block';
      })
      .catch(err => {
        document.getElementById('loadingSpinner').style.display = 'none';
        alert('Network error: ' + err.message);
      });
  }

  function checkConfirm() {
    const val = document.getElementById('confirmInput').value.trim().toUpperCase();
    document.getElementById('promoteBtn').disabled = (val !== 'PROMOTE');
  }

  function runPromotion() {
    const academicYear = document.getElementById('academicYear').value.trim();
    const remarks      = document.getElementById('remarks').value.trim();

    if (!academicYear) { alert('Please enter the Academic Year.'); return; }
    if (!currentUdise)  { alert('Please load a school first.'); return; }

    document.getElementById('previewSection').style.display    = 'none';
    document.getElementById('processingSpinner').style.display = 'block';

    const params = new URLSearchParams();
    params.append('udise',        currentUdise);
    params.append('academicYear', academicYear);
    params.append('remarks',      remarks);

    fetch('<%= request.getContextPath() %>/test-promote', {
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
        document.getElementById('resultTitle').textContent = 'Test Promotion Successful!';
        document.getElementById('resultDetails').innerHTML =
          '<p class="detail">School: <strong>' + currentUdise + '</strong></p>' +
          '<p class="detail">Promotion Log ID: <strong>#' + data.promotionId + '</strong></p>' +
          '<p class="detail">Students Promoted: <strong>' + (data.studentsPromoted||0) + '</strong></p>' +
          '<p class="detail">Students Graduated: <strong>' + (data.studentsGraduated||0) + '</strong></p>' +
          '<p style="margin-top:10px;color:#276749;">The promotion logic is working correctly.<br/>You can now run the full promotion for all schools.</p>';
      } else {
        box.className = 'result error';
        document.getElementById('resultIcon').textContent  = '❌';
        document.getElementById('resultTitle').textContent = 'Test Promotion Failed';
        document.getElementById('resultDetails').innerHTML =
          '<p>' + (data.message||'An unexpected error occurred.') + '</p>' +
          '<p style="margin-top:8px;">No changes were made. Check the error and try again.</p>';
      }
    })
    .catch(err => {
      document.getElementById('processingSpinner').style.display = 'none';
      const box = document.getElementById('resultBox');
      box.className = 'result error';
      box.style.display = 'block';
      document.getElementById('resultIcon').textContent  = '❌';
      document.getElementById('resultTitle').textContent = 'Network Error';
      document.getElementById('resultDetails').innerHTML = '<p>' + err.message + '</p>';
    });
  }
</script>
</body>
</html>
