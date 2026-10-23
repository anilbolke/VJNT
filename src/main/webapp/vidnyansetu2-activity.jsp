<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.vjnt.model.User,com.vjnt.model.VidnyanSetuUser,com.vjnt.model.School,com.vjnt.dao.SchoolDAO,com.vjnt.dao.VidnyanSetu2ActivityDAO,com.vjnt.util.DatabaseConnection,java.sql.*,java.util.*" %>
<%!
    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    // VidnyanSetu 2 — STEM activities, classes VI..IX only. Same access rules as
    // vidnyansetu-activity.jsp: main GATEE login ("user") or VidnyanSetu login
    // ("vsUser"); a VS Teacher is limited to their own assigned class-section(s).
    User user = (User) session.getAttribute("user");
    VidnyanSetuUser vsUser = (VidnyanSetuUser) session.getAttribute("vsUser");
    if (user == null && vsUser == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    String userUdise;
    boolean canWrite;
    boolean isVsTeacher = vsUser != null && vsUser.getRole() == VidnyanSetuUser.Role.TEACHER;
    // {class, section} pairs offered in the Class dropdown, VI..IX only
    List<String[]> classSectionChoices = new ArrayList<>();
    if (user != null) {
        String userType = user.getUserType().toString();
        userUdise = user.getUdiseNo() != null ? user.getUdiseNo().trim() : "";
        canWrite = userType.equals("SCHOOL_COORDINATOR") || userType.equals("HEAD_MASTER")
                || userType.equals("SUPER_DIVISION_OFFICER") || userType.equals("DATA_ADMIN");
    } else {
        userUdise = vsUser.getUdiseNo() != null ? vsUser.getUdiseNo().trim() : "";
        canWrite = true;
    }

    int totalStudents = 0;
    if (!userUdise.isEmpty()) {
        try (Connection conn = DatabaseConnection.getConnection()) {
            if (isVsTeacher) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT DISTINCT class, section FROM vidnyansetu_teacher_assignments " +
                        "WHERE vs_user_id = ? AND is_active = 1 AND class IN ('VI','VII','VIII','IX') " +
                        "ORDER BY FIELD(class,'VI','VII','VIII','IX'), section")) {
                    ps.setInt(1, vsUser.getVsUserId());
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) classSectionChoices.add(new String[]{ rs.getString("class"), rs.getString("section") });
                    }
                }
            } else {
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT DISTINCT class, section FROM students " +
                        "WHERE is_active = 1 AND udise_no = ? AND class IN ('VI','VII','VIII','IX') AND section IS NOT NULL " +
                        "ORDER BY FIELD(class,'VI','VII','VIII','IX'), section")) {
                    ps.setString(1, userUdise);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) classSectionChoices.add(new String[]{ rs.getString("class"), rs.getString("section") });
                    }
                }
            }
            for (String[] cs : classSectionChoices) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM students WHERE is_active = 1 AND udise_no = ? AND class = ? AND section = ?")) {
                    ps.setString(1, userUdise);
                    ps.setString(2, cs[0]);
                    ps.setString(3, cs[1]);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) totalStudents += rs.getInt(1);
                    }
                }
            }
        } catch (Exception ex) { /* page still renders, dropdown just stays empty */ }
    }
    if (classSectionChoices.isEmpty()) canWrite = false;

    List<Map<String,Object>> masterList = new VidnyanSetu2ActivityDAO().getMasterList();

    School school = userUdise.isEmpty() ? null : new SchoolDAO().getSchoolByUdise(userUdise);
    String schoolName = school != null ? school.getSchoolName() : "-";
    List<String> csLabels = new ArrayList<>();
    for (String[] cs : classSectionChoices) csLabels.add(cs[0] + "-" + cs[1]);
    String classesLabel = csLabels.isEmpty() ? "-" : String.join(", ", csLabels);
%>
<!DOCTYPE html>
<html lang="mr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>विज्ञानसेतू 2 उपक्रम — GATEE पोर्टल</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f4f8;color:#1e293b;min-height:100vh;}

.topbar{background:#0f9b6c;color:#fff;display:flex;
        align-items:center;justify-content:space-between;padding:0 24px;height:56px;
        position:sticky;top:0;z-index:100;box-shadow:0 2px 8px rgba(0,0,0,.2);}
.topbar-title{font-size:17px;font-weight:800;}
.topbar-btn{background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.3);color:#fff;
            padding:6px 16px;border-radius:20px;font-size:13px;cursor:pointer;text-decoration:none;}
.topbar-btn:hover{background:rgba(255,255,255,.25);}

.page{max-width:1200px;margin:0 auto;padding:24px 20px 60px;}

.school-header{background:#f0f2f5;color:#000;padding:20px 30px;border-radius:8px;margin-bottom:20px;text-align:center;}
.school-header .school-icon{font-size:24px;}
.school-header h1{font-size:22px;font-weight:700;margin:4px 0;}
.school-header .header-subtitle{font-size:14px;opacity:0.85;}
.breadcrumb{background:#fff;padding:15px 25px;border-radius:12px;margin-bottom:20px;box-shadow:0 4px 15px rgba(0,0,0,0.08);border-left:5px solid #0f9b6c;font-size:13.5px;}
.dashboard-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;margin-bottom:24px;}
.stat-card{background:#fff;padding:15px;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,0.06);border-left:3px solid #0f9b6c;text-align:center;}
.stat-icon{font-size:28px;margin-bottom:6px;display:block;}
.stat-value{font-size:26px;font-weight:700;color:#2d3748;margin-bottom:4px;}
.stat-label{font-size:11px;color:#718096;font-weight:500;}

.alert{border-radius:10px;padding:12px 18px;font-size:14px;margin-bottom:16px;display:flex;align-items:center;gap:10px;}
.alert-ok  {background:#dcfce7;color:#14532d;border:1px solid #86efac;}
.alert-err {background:#fee2e2;color:#991b1b;border:1px solid #fca5a5;}
.alert-info{background:#eff6ff;color:#1e3a8a;border:1px solid #bfdbfe;}

.layout{display:grid;grid-template-columns:1fr 400px;gap:20px;align-items:start;}

.form-card{background:#fff;border-radius:14px;box-shadow:0 2px 12px rgba(0,0,0,.08);padding:22px;position:sticky;top:72px;}
.form-card h3{font-size:16px;font-weight:800;margin-bottom:18px;display:flex;align-items:center;gap:8px;
              padding-bottom:12px;border-bottom:2px solid #f1f5f9;}
.form-group{margin-bottom:14px;}
.form-group label{display:block;font-size:12px;font-weight:700;color:#475569;
                  text-transform:uppercase;letter-spacing:.5px;margin-bottom:5px;}
.form-group input,.form-group select,.form-group textarea{
    width:100%;padding:10px 12px;border:2px solid #e2e8f0;border-radius:8px;
    font-size:13px;font-family:inherit;outline:none;background:#fff;}
.form-group input:focus,.form-group select:focus,.form-group textarea:focus{border-color:#0f9b6c;}
.form-group textarea{resize:vertical;min-height:60px;}
.btn-submit{width:100%;background:#0f9b6c;color:#fff;border:none;
            padding:13px;border-radius:10px;font-size:15px;font-weight:700;cursor:pointer;margin-top:6px;}
.btn-submit:hover{opacity:.9;}
.btn-submit:disabled{opacity:.5;cursor:not-allowed;}
.upload-progress{display:none;margin-top:12px;background:#ecfdf5;border:1px solid #6ee7b7;border-radius:10px;padding:12px 14px;}
.up-head{display:flex;justify-content:space-between;align-items:center;font-size:13px;font-weight:700;color:#064e3b;margin-bottom:8px;}
.up-pct{font-size:16px;color:#0f9b6c;}
.up-track{height:14px;background:#a7f3d0;border-radius:10px;overflow:hidden;}
.up-bar{height:100%;width:0;background:#0f9b6c;border-radius:10px;transition:width .2s ease;}
.up-bar.processing{background:repeating-linear-gradient(45deg,#0f9b6c 0 12px,#34d399 12px 24px);background-size:34px 34px;animation:up-stripes 1s linear infinite;}
@keyframes up-stripes{from{background-position:0 0;}to{background-position:34px 0;}}
.up-meta{display:flex;justify-content:space-between;gap:8px;flex-wrap:wrap;font-size:11.5px;color:#065f46;margin-top:6px;}
.up-cancel{background:none;border:1px solid #dc2626;color:#dc2626;border-radius:6px;padding:3px 10px;font-size:11.5px;font-weight:700;cursor:pointer;}
.up-cancel:hover{background:#fee2e2;}
.photo-zone{border:2px dashed #6ee7b7;border-radius:8px;padding:16px;text-align:center;cursor:pointer;}
.photo-zone:hover{border-color:#0f9b6c;background:#ecfdf5;}
.photo-zone .pz-icon{font-size:28px;margin-bottom:6px;}
.photo-zone p{font-size:12px;color:#64748b;}
.video-link{display:inline-flex;align-items:center;gap:4px;margin-top:8px;font-size:12px;font-weight:700;
            color:#0f9b6c;text-decoration:none;}
.video-link:hover{text-decoration:underline;}
.ac-thumb-wrap{position:relative;display:inline-block;margin-top:8px;}
.ac-thumb{width:120px;height:68px;object-fit:cover;border-radius:8px;background:#1e293b;display:block;}
.ac-thumb-play{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;
               font-size:22px;color:#fff;text-shadow:0 1px 4px rgba(0,0,0,.6);pointer-events:none;}

.list-area h3{font-size:16px;font-weight:800;margin-bottom:0;display:flex;align-items:center;gap:8px;}
.list-head{display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap;margin-bottom:14px;}
.list-head select{padding:6px 10px;border:1.5px solid #e2e8f0;border-radius:8px;font-size:13px;background:#fff;}
.activity-card{background:#fff;border-radius:12px;box-shadow:0 1px 4px rgba(0,0,0,.07);
               margin-bottom:14px;overflow:hidden;border-left:4px solid #0f9b6c;padding:14px 18px;}
.ac-name{font-size:15px;font-weight:700;margin-bottom:6px;}
.ac-sub{font-size:12px;color:#64748b;margin-bottom:6px;}
.ac-desc{font-size:13px;color:#475569;line-height:1.6;}
.chip{display:inline-block;border-radius:10px;padding:2px 10px;font-size:11px;font-weight:700;margin-right:4px;}
.chip-class{background:#dbeafe;color:#1e40af;}
.chip-pending{background:#fef3c7;color:#92400e;}
.chip-approved{background:#dcfce7;color:#14532d;}
.chip-rejected{background:#fee2e2;color:#991b1b;}
.ac-rejection{font-size:12px;color:#991b1b;margin-top:6px;}
.empty{text-align:center;padding:60px 20px;background:#fff;border-radius:12px;box-shadow:0 1px 4px rgba(0,0,0,.07);}
.empty .ei{font-size:56px;margin-bottom:12px;}

@media(max-width:900px){.layout{grid-template-columns:1fr;} .form-card{position:static;}}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-title">🧪 विज्ञानसेतू 2 उपक्रम — STEM Activities</div>
  <a href="javascript:history.back()" class="topbar-btn">← मागे</a>
</div>

<div class="page">
  <div class="school-header">
    <div class="school-icon">🏫</div>
    <h1><%= esc(schoolName) %></h1>
    <div class="header-subtitle">UDISE: <%= esc(userUdise) %></div>
  </div>

  <div class="breadcrumb">
    <span>🏫 School:</span> <strong><%= esc(schoolName) %></strong> (<%= esc(userUdise) %>)
    <span style="margin: 0 10px;">→</span>
    <span>📚 Class:</span> <strong><%= esc(classesLabel) %></strong>
  </div>

  <div class="dashboard-grid">
    <div class="stat-card">
      <div class="stat-icon">👥</div>
      <div class="stat-value"><%= totalStudents %></div>
      <div class="stat-label">Total Students (VI–IX)</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon">📚</div>
      <div class="stat-value"><%= classSectionChoices.size() %></div>
      <div class="stat-label">Class - Sections</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon">🧪</div>
      <div class="stat-value"><%= masterList.size() %></div>
      <div class="stat-label">STEM Activities</div>
    </div>
  </div>

  <div id="alertBox"></div>

  <% if (classSectionChoices.isEmpty()) { %>
  <div class="alert alert-info">ℹ️ विज्ञानसेतू 2 उपक्रम फक्त इयत्ता VI, VII, VIII व IX साठी आहे. तुम्हाला यापैकी कोणतीही इयत्ता नियुक्त केलेली नाही.</div>
  <% } %>

  <div class="layout">
    <div class="list-area">
      <div class="list-head">
        <h3>📋 नोंदवलेले उपक्रम</h3>
        <select id="listSecFilter" onchange="renderActivities()" style="display:none">
          <option value="">सर्व इयत्ता-तुकड्या (All)</option>
        </select>
      </div>
      <div id="activityList"><div class="empty"><div class="ei">⏳</div>लोड होत आहे...</div></div>
    </div>

    <% if (canWrite) { %>
    <div class="form-card">
      <h3>➕ नवीन उपक्रम नोंदवा</h3>
      <form id="activityForm">

        <div class="form-group">
          <label>इयत्ता (Class) *</label>
          <select id="selClass" required>
            <option value="">-- निवडा --</option>
            <% for (String[] cs : classSectionChoices) { %>
            <option value="<%= esc(cs[0]) %>|<%= esc(cs[1]) %>">इयत्ता <%= esc(cs[0]) %> - <%= esc(cs[1]) %></option>
            <% } %>
          </select>
        </div>

        <div class="form-group">
          <label>उपक्रम (STEM Activity) *</label>
          <select id="selActivity" required>
            <option value="">-- निवडा --</option>
            <% for (Map<String,Object> m : masterList) { %>
            <option value="<%= m.get("no") %>"><%= m.get("no") %>. <%= esc((String) m.get("name")) %></option>
            <% } %>
          </select>
        </div>

        <div class="form-group">
          <label>तारीख *</label>
          <input type="date" id="activityDate" required/>
        </div>

        <div class="form-group">
          <label>टिपा / निरीक्षण (पर्यायी)</label>
          <textarea id="description" placeholder="कृती कशी पार पडली याबद्दल थोडक्यात..." maxlength="1000"></textarea>
        </div>

        <div class="form-group">
          <label>उपक्रमाचा व्हिडिओ * (अनिवार्य)</label>
          <div class="photo-zone" onclick="document.getElementById('videoInput').click()">
            <input type="file" id="videoInput" accept="video/*" required
                   onchange="onVideoChosen(this)" style="display:none"/>
            <div class="pz-icon">🎥</div>
            <p>व्हिडिओ निवडा (MP4 / MOV / WEBM, १०० KB – १०० MB)</p>
          </div>
          <div id="videoChosenName" style="margin-top:6px;font-size:12px;color:#0f9b6c;font-weight:600;min-height:18px;"></div>
        </div>

        <button type="submit" class="btn-submit" id="btnSubmit">✅ उपक्रम जतन करा</button>

        <div class="upload-progress" id="uploadProgress">
          <div class="up-head">
            <span id="upStatus">🎥 व्हिडिओ अपलोड होत आहे...</span>
            <span class="up-pct" id="upPct">0%</span>
          </div>
          <div class="up-track"><div class="up-bar" id="upBar"></div></div>
          <div class="up-meta">
            <span id="upBytes">0 MB / 0 MB</span>
            <span id="upSpeed"></span>
            <button type="button" class="up-cancel" id="upCancel" onclick="cancelUpload()">✕ रद्द करा</button>
          </div>
        </div>
      </form>
    </div>
    <% } %>
  </div>
</div>

<script>
const CTX = '<%= request.getContextPath() %>';
const CLASS_ORDER = ['VI','VII','VIII','IX'];
function selCls() { return (document.getElementById('selClass').value || '').split('|')[0]; }
function selSec() { return (document.getElementById('selClass').value || '').split('|')[1] || ''; }

function escHtml(s) {
  return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function showAlert(msg, ok) {
  document.getElementById('alertBox').innerHTML =
    '<div class="alert ' + (ok ? 'alert-ok' : 'alert-err') + '">' + (ok ? '✅ ' : '⚠️ ') + msg + '</div>';
}

// ── Video (mandatory) ──
const MIN_VIDEO_BYTES = 100 * 1024;
const MAX_VIDEO_BYTES = 100 * 1024 * 1024;
function onVideoChosen(input) {
  const label = document.getElementById('videoChosenName');
  const f = input.files && input.files[0];
  if (!f) { label.textContent = ''; return; }
  if (f.size < MIN_VIDEO_BYTES || f.size > MAX_VIDEO_BYTES) {
    label.style.color = '#dc2626';
    label.textContent = '⚠️ आकार 100 KB ते 100 MB दरम्यान असावा (सध्या ' + (f.size/1024/1024).toFixed(2) + ' MB)';
    input.value = '';
    return;
  }
  label.style.color = '#0f9b6c';
  label.textContent = '✓ ' + f.name + ' (' + (f.size/1024/1024).toFixed(2) + ' MB)';
}

// ── Upload progress (XHR — fetch() has no upload progress events) ──
let currentXhr = null;
const SUBMIT_LABEL = '✅ उपक्रम जतन करा';

function fmtMB(bytes) { return (bytes / 1024 / 1024).toFixed(2) + ' MB'; }

function setProgress(loaded, total, startedAt) {
  const pct = total > 0 ? Math.min(100, Math.floor(loaded * 100 / total)) : 0;
  document.getElementById('upBar').style.width = pct + '%';
  document.getElementById('upPct').textContent = pct + '%';
  document.getElementById('upBytes').textContent = fmtMB(loaded) + ' / ' + fmtMB(total);
  const secs = (Date.now() - startedAt) / 1000;
  if (secs > 0.5 && loaded > 0) {
    const speed = loaded / secs;
    const remain = Math.max(0, (total - loaded) / speed);
    document.getElementById('upSpeed').textContent =
      (speed / 1024 / 1024).toFixed(2) + ' MB/s · ' +
      (remain >= 60 ? Math.floor(remain / 60) + ' मि ' + Math.round(remain % 60) + ' से' : Math.round(remain) + ' से') + ' बाकी';
  }
  document.getElementById('btnSubmit').textContent = '🎥 अपलोड होत आहे... ' + pct + '%';
}

function showProgress() {
  const bar = document.getElementById('upBar');
  bar.classList.remove('processing');
  bar.style.width = '0';
  document.getElementById('upStatus').textContent = '🎥 व्हिडिओ अपलोड होत आहे...';
  document.getElementById('upPct').textContent = '0%';
  document.getElementById('upBytes').textContent = '';
  document.getElementById('upSpeed').textContent = '';
  document.getElementById('upCancel').style.display = '';
  document.getElementById('uploadProgress').style.display = 'block';
}

function showProcessing() {
  document.getElementById('upBar').style.width = '100%';
  document.getElementById('upBar').classList.add('processing');
  document.getElementById('upPct').textContent = '100%';
  document.getElementById('upStatus').textContent = '⚙️ अपलोड पूर्ण — सर्व्हरवर प्रक्रिया सुरू आहे...';
  document.getElementById('upSpeed').textContent = '';
  document.getElementById('upCancel').style.display = 'none';
  document.getElementById('btnSubmit').textContent = '⚙️ जतन होत आहे...';
}

function endUpload() {
  currentXhr = null;
  document.getElementById('uploadProgress').style.display = 'none';
  document.getElementById('upBar').classList.remove('processing');
  const btn = document.getElementById('btnSubmit');
  btn.disabled = false; btn.textContent = SUBMIT_LABEL;
}

function cancelUpload() {
  if (currentXhr) currentXhr.abort();
}

window.addEventListener('beforeunload', function(e) {
  if (currentXhr) { e.preventDefault(); e.returnValue = ''; }
});

// ── Save ──
const form = document.getElementById('activityForm');
if (form) {
  form.addEventListener('submit', function(e){
    e.preventDefault();
    const activityNo = document.getElementById('selActivity').value;
    const activityDate = document.getElementById('activityDate').value;
    const videoInput = document.getElementById('videoInput');
    const videoFile = videoInput.files && videoInput.files[0];

    if (!selCls() || !activityNo) { showAlert('कृपया इयत्ता व उपक्रम निवडा', false); return; }
    if (!activityDate) { showAlert('कृपया तारीख निवडा', false); return; }
    if (!videoFile) { showAlert('व्हिडिओ अनिवार्य आहे. कृपया उपक्रमाचा व्हिडिओ जोडा.', false); return; }

    const btn = document.getElementById('btnSubmit');
    btn.disabled = true; btn.textContent = '🎥 अपलोड होत आहे... 0%';
    showProgress();

    const fd = new FormData();
    fd.append('studentClass', selCls());
    if (selSec()) fd.append('studentSection', selSec());
    fd.append('activityNo', activityNo);
    fd.append('activityDate', activityDate);
    fd.append('description', document.getElementById('description').value);
    fd.append('video', videoFile, videoFile.name);

    const xhr = new XMLHttpRequest();
    currentXhr = xhr;
    const startedAt = Date.now();
    setProgress(0, videoFile.size, startedAt);

    xhr.upload.onprogress = function(ev) {
      if (ev.lengthComputable) setProgress(ev.loaded, ev.total, startedAt);
    };
    xhr.upload.onload = showProcessing;
    xhr.onabort = function() { endUpload(); showAlert('अपलोड रद्द केले.', false); };
    xhr.onerror = function() { endUpload(); showAlert('नेटवर्क त्रुटी — व्हिडिओ अपलोड होऊ शकला नाही. कृपया पुन्हा प्रयत्न करा.', false); };
    xhr.ontimeout = function() { endUpload(); showAlert('अपलोडला खूप वेळ लागला. कृपया पुन्हा प्रयत्न करा.', false); };
    xhr.onload = function() {
      endUpload();
      let res;
      try { res = JSON.parse(xhr.responseText); }
      catch (err) {
        showAlert(xhr.status === 413 ? 'व्हिडिओ खूप मोठा आहे (कमाल 100 MB).' : 'सर्व्हर त्रुटी (' + xhr.status + ')', false);
        return;
      }
      if (res.success) {
        showAlert('उपक्रम व व्हिडिओ यशस्वीरित्या जतन झाला! मुख्याध्यापकांच्या मंजुरीनंतर तो दिसेल.', true);
        form.reset();
        document.getElementById('videoChosenName').textContent = '';
        loadActivities();
      } else {
        showAlert(res.message || 'जतन करता आले नाही', false);
      }
    };
    xhr.open('POST', CTX + '/save-vidnyansetu2-activity');
    xhr.send(fd);
  });
}

// ── Logged activities list ──
function clsSecOf(a) { return a.cls + (a.section ? '-' + a.section : ''); }

let allActivities = [];
function loadActivities() {
  const list = document.getElementById('activityList');
  fetch(CTX + '/save-vidnyansetu2-activity')
    .then(r => r.json())
    .then(rows => {
      allActivities = rows;
      const sel = document.getElementById('listSecFilter');
      const keep = sel.value;
      const keys = [...new Set(rows.map(clsSecOf))].sort((a, b) =>
        CLASS_ORDER.indexOf(a.split('-')[0]) - CLASS_ORDER.indexOf(b.split('-')[0]) || a.localeCompare(b));
      sel.innerHTML = '<option value="">सर्व इयत्ता-तुकड्या (All)</option>' +
        keys.map(k => '<option value="' + escHtml(k) + '">इयत्ता ' + escHtml(k.replace('-', ' - ')) + '</option>').join('');
      sel.value = keys.includes(keep) ? keep : '';
      sel.style.display = keys.length > 1 ? '' : 'none';
      renderActivities();
    })
    .catch(() => { list.innerHTML = '<div class="empty"><div class="ei">⚠️</div>उपक्रम लोड होऊ शकले नाहीत.</div>'; });
}

function renderActivities() {
  const list = document.getElementById('activityList');
  const want = document.getElementById('listSecFilter').value;
  const rows = want ? allActivities.filter(a => clsSecOf(a) === want) : allActivities;
  if (!rows.length) {
    list.innerHTML = '<div class="empty"><div class="ei">🧪</div>अजून कोणतेही उपक्रम नोंदवलेले नाहीत.</div>';
    return;
  }
  list.innerHTML = rows.map(function(a){
    const status = a.approvalStatus || 'PENDING';
    const statusChip = status === 'APPROVED'
      ? '<span class="chip chip-approved">✅ मंजूर</span>'
      : status === 'REJECTED'
        ? '<span class="chip chip-rejected">❌ नाकारले</span>'
        : '<span class="chip chip-pending">⏳ मंजुरीच्या प्रतीक्षेत</span>';
    return '<div class="activity-card">' +
      '<div class="ac-name">' + a.activityNo + '. ' + escHtml(a.activityName) + '</div>' +
      '<div class="ac-sub">' +
        '<span class="chip chip-class">इयत्ता ' + escHtml(a.cls) + (a.section ? ' - ' + escHtml(a.section) : '') + '</span>' +
        statusChip +
      '</div>' +
      (a.date ? '<div class="ac-sub">📅 उपक्रम तारीख: <strong>' + escHtml(a.date) + '</strong></div>' : '') +
      (a.desc ? '<div class="ac-desc">📝 ' + escHtml(a.desc) + '</div>' : '') +
      (status === 'REJECTED' && a.rejectionReason ? '<div class="ac-rejection">⚠️ मुख्याध्यापकांचा शेरा: ' + escHtml(a.rejectionReason) + '</div>' : '') +
      (a.videoUrl ? (
        '<a class="ac-thumb-wrap" href="' + escHtml(a.videoUrl) + '" target="_blank" rel="noopener" title="व्हिडिओ पहा">' +
          (a.videoThumbnailUrl ? '<img class="ac-thumb" src="' + escHtml(a.videoThumbnailUrl) + '" alt="व्हिडिओ थंबनेल"/>' : '<div class="ac-thumb"></div>') +
          '<span class="ac-thumb-play">▶</span>' +
        '</a><br/>' +
        '<a class="video-link" href="' + escHtml(a.videoUrl) + '" target="_blank" rel="noopener">🎥 व्हिडिओ पहा' + (a.videoFilename ? ' (' + escHtml(a.videoFilename) + ')' : '') + '</a>'
      ) : '') +
      '</div>';
  }).join('');
}
loadActivities();
</script>
</body>
</html>
