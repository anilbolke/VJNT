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
  <title>School Terminal Class — GATEE Portal</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box;}
    body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f2f5;min-height:100vh;padding:24px;}
    .container{max-width:1150px;margin:0 auto;}

    .header{background:#fff;border-radius:12px;padding:24px 28px;margin-bottom:20px;
            box-shadow:0 2px 8px rgba(0,0,0,0.07);display:flex;align-items:center;
            justify-content:space-between;gap:16px;flex-wrap:wrap;}
    .header-left{display:flex;align-items:center;gap:14px;}
    .header h1{font-size:22px;font-weight:700;color:#2d3748;}
    .header p{font-size:13px;color:#718096;margin-top:3px;}
    .back-btn{background:#667eea;color:#fff;border-radius:8px;padding:9px 18px;
              font-size:14px;font-weight:600;text-decoration:none;}
    .back-btn:hover{background:#5a67d8;}

    .info-banner{background:#ebf8ff;border:2px solid #90cdf4;border-radius:12px;padding:14px 20px;
                 margin-bottom:20px;display:flex;gap:12px;font-size:14px;color:#2c5282;align-items:flex-start;}
    .err-banner{background:#fff5f5;border:2px solid #feb2b2;color:#742a2a;}

    .card{background:#fff;border-radius:12px;padding:22px 26px;margin-bottom:20px;box-shadow:0 2px 8px rgba(0,0,0,0.07);}
    .card h2{font-size:17px;font-weight:700;margin-bottom:14px;color:#2d3748;}

    .toolbar{display:flex;gap:10px;flex-wrap:wrap;align-items:center;}
    input[type=text]{border:1px solid #e2e8f0;border-radius:8px;padding:9px 14px;font-size:14px;
                     font-family:inherit;flex:1;min-width:220px;}
    button{background:#667eea;color:#fff;border:none;border-radius:8px;padding:9px 18px;
           font-size:14px;font-weight:600;cursor:pointer;font-family:inherit;}
    button:hover:not(:disabled){background:#5a67d8;}
    button:disabled{background:#cbd5e0;cursor:not-allowed;}
    .btn-seed{background:#dd6b20;} .btn-seed:hover:not(:disabled){background:#c05621;}
    .btn-small{padding:5px 12px;font-size:13px;}
    .btn-ghost{background:#e2e8f0;color:#4a5568;} .btn-ghost:hover:not(:disabled){background:#cbd5e0;}
    label.check{display:flex;align-items:center;gap:6px;font-size:14px;color:#4a5568;cursor:pointer;}

    .summary-row{display:flex;gap:16px;margin-bottom:20px;flex-wrap:wrap;}
    .chip{flex:1;min-width:150px;background:#fff;border-radius:12px;padding:16px;text-align:center;
          box-shadow:0 2px 8px rgba(0,0,0,0.07);}
    .chip .num{font-size:26px;font-weight:700;color:#2d3748;}
    .chip .lbl{font-size:12px;color:#718096;margin-top:4px;text-transform:uppercase;letter-spacing:.4px;}
    .chip.warn .num{color:#c53030;}

    table{width:100%;border-collapse:collapse;font-size:14px;}
    th{background:#f7fafc;text-align:left;padding:10px 12px;font-weight:700;color:#4a5568;
       border-bottom:2px solid #e2e8f0;font-size:13px;}
    td{padding:8px 12px;border-bottom:1px solid #edf2f7;color:#2d3748;}
    tr:hover td{background:#f7fafc;}
    tr.unset td{background:#fffaf0;}
    tr.differs td{background:#fff5f5;}
    .scroll{max-height:560px;overflow:auto;border:1px solid #edf2f7;border-radius:8px;}
    .table-wrap{overflow-x:auto;}
    select.cls{border:1px solid #e2e8f0;border-radius:6px;padding:5px 8px;font-size:13px;font-family:inherit;}
    .badge{display:inline-block;padding:3px 9px;border-radius:11px;font-size:12px;font-weight:600;}
    .b-unset{background:#fbd38d;color:#7c2d12;}
    .b-diff{background:#fed7d7;color:#822727;}
    .b-ok{background:#c6f6d5;color:#22543d;}
    .muted{font-size:13px;color:#718096;}
    .spinner{display:none;text-align:center;padding:30px;}
    .spinner-ring{width:40px;height:40px;border:4px solid #e2e8f0;border-top-color:#667eea;
                  border-radius:50%;animation:spin .9s linear infinite;margin:0 auto 10px;}
    @keyframes spin{to{transform:rotate(360deg);}}
    #toast{position:fixed;bottom:24px;right:24px;background:#2d3748;color:#fff;padding:12px 20px;
           border-radius:8px;font-size:14px;display:none;box-shadow:0 4px 20px rgba(0,0,0,.25);z-index:99;}
  </style>
</head>
<body>
<div class="container">

  <div class="header">
    <div class="header-left">
      <div style="font-size:34px;">🏫</div>
      <div>
        <h1>School Terminal Class</h1>
        <p>The last class each school runs to — decides who graduates at promotion</p>
      </div>
    </div>
    <a href="<%= request.getContextPath() %>/data-admin-dashboard.jsp" class="back-btn">← Back to Dashboard</a>
  </div>

  <div class="info-banner" id="infoBanner">
    <div style="font-size:22px;">ℹ️</div>
    <div>
      <strong>Why this matters.</strong>
      Promotion graduates each school's last class. Where <strong>Set</strong> is blank the system
      falls back to <strong>Derived</strong> — the highest class that school currently has students in.
      That is right most of the time, but wrong for a school that runs to Class IX and simply had no
      Class IX students this year: its Class VIII would graduate by mistake.
      Setting the value explicitly removes the guess.
    </div>
  </div>

  <div class="summary-row">
    <div class="chip"><div class="num" id="chipTotal">—</div><div class="lbl">Schools Listed</div></div>
    <div class="chip warn"><div class="num" id="chipUnset">—</div><div class="lbl">Not Set (derived)</div></div>
    <div class="chip warn"><div class="num" id="chipDiff">—</div><div class="lbl">Set ≠ Derived</div></div>
  </div>

  <div class="card">
    <h2>🔎 Find schools</h2>
    <div class="toolbar">
      <input type="text" id="searchInput" placeholder="UDISE, school name or district…"
             onkeydown="if(event.key==='Enter') load()"/>
      <label class="check"><input type="checkbox" id="onlyUnset" onchange="load()"/> Only unset</label>
      <button onclick="load()">Search</button>
      <button class="btn-seed" onclick="seedAll()" id="seedBtn">⚡ Fill all blanks from Derived</button>
    </div>
    <div class="muted" style="margin-top:10px;">
      Filling blanks never overwrites a value you have already set. Review anything ending below
      Class VIII with the district team before trusting it.
    </div>
  </div>

  <div class="spinner" id="spinner"><div class="spinner-ring"></div><p class="muted">Loading…</p></div>

  <div class="card" id="listCard" style="display:none;">
    <h2>📋 Schools</h2>
    <div class="table-wrap">
      <div class="scroll">
        <table>
          <thead><tr>
            <th>UDISE</th><th>School</th><th>District</th>
            <th>Students</th><th>Derived</th><th>Set</th><th></th>
          </tr></thead>
          <tbody id="body"></tbody>
        </table>
      </div>
    </div>
    <div class="muted" id="truncNote" style="display:none;margin-top:10px;">
      Showing the first 500 matches — narrow the search to see more.
    </div>
  </div>

</div>
<div id="toast"></div>
<script>
  var CTX = '<%= request.getContextPath() %>';
  var CLASSES = ['I','II','III','IV','V','VI','VII','VIII','IX'];

  document.addEventListener('DOMContentLoaded', load);

  function load() {
    var search = document.getElementById('searchInput').value.trim();
    var onlyUnset = document.getElementById('onlyUnset').checked ? '1' : '';
    document.getElementById('listCard').style.display = 'none';
    document.getElementById('spinner').style.display = 'block';

    fetch(CTX + '/school-max-class?search=' + encodeURIComponent(search) +
                '&onlyUnset=' + onlyUnset)
      .then(function(r){ return r.json(); })
      .then(function(data){
        document.getElementById('spinner').style.display = 'none';
        if (!data.success) { toast('Error: ' + data.message); return; }

        if (data.columnPresent === false) {
          var b = document.getElementById('infoBanner');
          b.className = 'info-banner err-banner';
          b.innerHTML = '<div style="font-size:22px;">⚠️</div><div><strong>Column not created yet.</strong><br/>' +
                        esc(data.message) + '</div>';
          document.getElementById('seedBtn').disabled = true;
          return;
        }

        var rows = data.schools || [];
        document.getElementById('chipTotal').textContent = rows.length.toLocaleString();
        document.getElementById('chipUnset').textContent = (data.unset||0).toLocaleString();
        document.getElementById('chipDiff').textContent  = (data.mismatched||0).toLocaleString();

        var tb = document.getElementById('body');
        tb.innerHTML = '';
        rows.forEach(function(s){
          var tr = document.createElement('tr');
          if (!s.maxClass) tr.classList.add('unset');
          else if (s.differs) tr.classList.add('differs');

          var opts = '<option value="">— not set —</option>';
          CLASSES.forEach(function(c){
            opts += '<option value="' + c + '"' + (s.maxClass === c ? ' selected' : '') + '>Class ' + c + '</option>';
          });

          var state = !s.maxClass
            ? '<span class="badge b-unset">derived</span>'
            : (s.differs ? '<span class="badge b-diff">differs</span>' : '<span class="badge b-ok">set</span>');

          tr.innerHTML =
            '<td><strong>' + esc(s.udise) + '</strong></td>' +
            '<td>' + esc(s.schoolName) + '</td>' +
            '<td>' + esc(s.district) + '</td>' +
            '<td>' + (s.activeStudents||0).toLocaleString() + '</td>' +
            '<td>' + (s.derivedClass ? 'Class ' + s.derivedClass : '<em>—</em>') + '</td>' +
            '<td><select class="cls" onchange="setClass(this,\'' + s.udise + '\')">' + opts + '</select> ' + state + '</td>' +
            '<td>' + (s.maxClass
                ? '<button class="btn-small btn-ghost" onclick="clearClass(\'' + s.udise + '\')">Clear</button>'
                : '') + '</td>';
          tb.appendChild(tr);
        });

        document.getElementById('truncNote').style.display = data.truncated ? 'block' : 'none';
        document.getElementById('listCard').style.display = 'block';
      })
      .catch(function(e){
        document.getElementById('spinner').style.display = 'none';
        toast('Network error: ' + e.message);
      });
  }

  function setClass(sel, udise) {
    var val = sel.value;
    if (!val) { clearClass(udise); return; }
    post({ action:'set', udise:udise, maxClass:val }, 'Class ' + val + ' set for ' + udise);
  }

  function clearClass(udise) {
    post({ action:'clear', udise:udise }, 'Cleared ' + udise + ' — will be derived');
  }

  function seedAll() {
    if (!confirm('Fill max_class for every school that has none, using the derived value?\n\n' +
                 'Values you have already set are left untouched.')) return;
    post({ action:'seedAll' }, null);
  }

  function post(fields, okMsg) {
    var params = new URLSearchParams();
    Object.keys(fields).forEach(function(k){ params.append(k, fields[k]); });

    fetch(CTX + '/school-max-class', {
      method:'POST',
      headers:{ 'Content-Type':'application/x-www-form-urlencoded' },
      body: params.toString()
    })
    .then(function(r){ return r.json(); })
    .then(function(data){
      if (!data.success) { toast('Error: ' + data.message); load(); return; }
      toast(okMsg || ('Updated ' + (data.updated||0) + ' school(s)'));
      load();
    })
    .catch(function(e){ toast('Network error: ' + e.message); });
  }

  function toast(msg) {
    var t = document.getElementById('toast');
    t.textContent = msg;
    t.style.display = 'block';
    clearTimeout(t._h);
    t._h = setTimeout(function(){ t.style.display = 'none'; }, 3200);
  }

  function esc(s) {
    if (s === null || s === undefined) return '';
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;')
                    .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  }
</script>
</body>
</html>
