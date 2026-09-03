<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.vjnt.model.User,com.vjnt.util.DatabaseConnection,java.sql.*,java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    String userType  = user.getUserType().toString();
    String userUdise = user.getUdiseNo() != null ? user.getUdiseNo().trim() : "";
    boolean canWrite = userType.equals("SCHOOL_COORDINATOR") || userType.equals("HEAD_MASTER")
                        || userType.equals("SUPER_DIVISION_OFFICER") || userType.equals("DATA_ADMIN");

    // ── Load students for the search box (own school) ──
    List<Map<String,Object>> students = new ArrayList<>();
    if (!userUdise.isEmpty()) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT student_id, student_pen, student_name, class " +
                 "FROM students WHERE is_active=1 AND udise_no=? ORDER BY class, student_name")) {
            ps.setString(1, userUdise);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String,Object> s = new LinkedHashMap<>();
                s.put("pen",   rs.getString("student_pen"));
                s.put("name",  rs.getString("student_name"));
                s.put("class", rs.getString("class"));
                students.add(s);
            }
        } catch (Exception ex) { /* table/column not ready yet — page still renders */ }
    }
%>
<!DOCTYPE html>
<html lang="mr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>विज्ञानसेतू उपक्रम — GATEE पोर्टल</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f4f8;color:#1e293b;min-height:100vh;}

.topbar{background:linear-gradient(90deg,#f97316,#ea580c);color:#fff;display:flex;
        align-items:center;justify-content:space-between;padding:0 24px;height:56px;
        position:sticky;top:0;z-index:100;box-shadow:0 2px 8px rgba(0,0,0,.2);}
.topbar-title{font-size:17px;font-weight:800;}
.topbar-btn{background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.3);color:#fff;
            padding:6px 16px;border-radius:20px;font-size:13px;cursor:pointer;text-decoration:none;}
.topbar-btn:hover{background:rgba(255,255,255,.25);}

.page{max-width:1200px;margin:0 auto;padding:24px 20px 60px;}

.alert{border-radius:10px;padding:12px 18px;font-size:14px;margin-bottom:16px;display:flex;align-items:center;gap:10px;}
.alert-ok  {background:#dcfce7;color:#14532d;border:1px solid #86efac;}
.alert-err {background:#fee2e2;color:#991b1b;border:1px solid #fca5a5;}

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
.form-group select:disabled{background:#f1f5f9;color:#94a3b8;}
.form-group input:focus,.form-group select:focus,.form-group textarea:focus{border-color:#f97316;}
.form-group textarea{resize:vertical;min-height:60px;}
.topic-box{background:#fff7ed;border:1px dashed #fdba74;border-radius:8px;padding:10px 12px;
           font-size:13px;color:#7c2d12;line-height:1.6;min-height:20px;}
.stu-select-wrap{position:relative;}
.stu-dropdown{display:none;position:absolute;top:100%;left:0;right:0;background:#fff;
              border:2px solid #f97316;border-top:none;border-radius:0 0 8px 8px;
              max-height:200px;overflow-y:auto;z-index:50;box-shadow:0 8px 20px rgba(0,0,0,.1);}
.stu-opt{padding:9px 12px;font-size:13px;cursor:pointer;display:flex;justify-content:space-between;}
.stu-opt:hover{background:#f1f5f9;}
.stu-opt .so-name{font-weight:600;}
.stu-opt .so-meta{font-size:11px;color:#94a3b8;}
.btn-submit{width:100%;background:linear-gradient(135deg,#f97316,#ea580c);color:#fff;border:none;
            padding:13px;border-radius:10px;font-size:15px;font-weight:700;cursor:pointer;margin-top:6px;}
.btn-submit:hover{opacity:.9;}
.btn-submit:disabled{opacity:.5;cursor:not-allowed;}
.photo-zone{border:2px dashed #fdba74;border-radius:8px;padding:16px;text-align:center;cursor:pointer;}
.photo-zone:hover{border-color:#ea580c;background:#fff7ed;}
.photo-zone .pz-icon{font-size:28px;margin-bottom:6px;}
.photo-zone p{font-size:12px;color:#64748b;}
.video-link{display:inline-flex;align-items:center;gap:4px;margin-top:8px;font-size:12px;font-weight:700;
            color:#ea580c;text-decoration:none;}
.video-link:hover{text-decoration:underline;}
.ac-thumb-wrap{position:relative;display:inline-block;margin-top:8px;}
.ac-thumb{width:120px;height:68px;object-fit:cover;border-radius:8px;background:#1e293b;display:block;}
.ac-thumb-play{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;
               font-size:22px;color:#fff;text-shadow:0 1px 4px rgba(0,0,0,.6);pointer-events:none;}

.list-area h3{font-size:16px;font-weight:800;margin-bottom:14px;display:flex;align-items:center;gap:8px;}
.activity-card{background:#fff;border-radius:12px;box-shadow:0 1px 4px rgba(0,0,0,.07);
               margin-bottom:14px;overflow:hidden;border-left:4px solid #f97316;padding:14px 18px;}
.ac-name{font-size:15px;font-weight:700;margin-bottom:4px;}
.ac-sub{font-size:12px;color:#64748b;margin-bottom:6px;}
.ac-desc{font-size:13px;color:#475569;line-height:1.6;}
.chip{display:inline-block;border-radius:10px;padding:2px 10px;font-size:11px;font-weight:700;margin-right:4px;}
.chip-class{background:#dbeafe;color:#1e40af;}
.chip-week{background:#fef3c7;color:#92400e;}
.chip-day{background:#fce7f3;color:#9d174d;}
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
  <div class="topbar-title">🔬 विज्ञानसेतू उपक्रम — कृतीतून संकल्पनेकडे</div>
  <a href="javascript:history.back()" class="topbar-btn">← मागे</a>
</div>

<div class="page">
  <div id="alertBox"></div>

  <div class="layout">
    <div class="list-area">
      <h3>📋 नोंदवलेले उपक्रम</h3>
      <div id="activityList"><div class="empty"><div class="ei">⏳</div>लोड होत आहे...</div></div>
    </div>

    <% if (canWrite) { %>
    <div class="form-card">
      <h3>➕ नवीन उपक्रम नोंदवा</h3>
      <form id="activityForm">

        <%-- Student selection hidden — VidnyanSetu activity is recorded at CLASS level.
             The elements stay in the DOM (hidden) so the filter/select JS keeps working. --%>
        <div class="form-group" style="display:none">
          <label>विद्यार्थी निवडा (ऐच्छिक — हा उपक्रम वर्ग स्तरावर आहे)</label>
          <div class="stu-select-wrap">
            <input type="text" id="stuSearch" placeholder="नाव किंवा PEN टाइप करा... (आवश्यक नाही)" autocomplete="off"
                   oninput="filterStudents(this.value)" onfocus="showDropdown()"/>
            <div class="stu-dropdown" id="stuDropdown">
              <% for (Map<String,Object> s : students) { %>
              <div class="stu-opt"
                   onclick="selectStudent('<%= s.get("pen") %>','<%= String.valueOf(s.get("name")).replace("'","\\'") %>','<%= s.get("class") %>')">
                <span class="so-name"><%= s.get("name") %></span>
                <span class="so-meta">इयत्ता <%= s.get("class") %> | PEN: <%= s.get("pen") %></span>
              </div>
              <% } %>
              <% if (students.isEmpty()) { %>
              <div style="padding:12px;font-size:13px;color:#94a3b8;">या शाळेत विद्यार्थी नाहीत</div>
              <% } %>
            </div>
          </div>
          <div id="selectedStu" style="margin-top:6px;font-size:12px;color:#ea580c;font-weight:600;min-height:18px;"></div>
        </div>

        <div class="form-group">
          <label>इयत्ता (Class) *</label>
          <select id="selClass" onchange="onClassChange()" required>
            <option value="">-- लोड होत आहे --</option>
          </select>
        </div>

        <div class="form-group">
          <label>आठवडा (Week) *</label>
          <select id="selWeek" onchange="onWeekChange()" disabled required>
            <option value="">-- आधी इयत्ता निवडा --</option>
          </select>
        </div>
        <div class="form-group">
          <label>आठवड्याचा विषय (Week Topic)</label>
          <div class="topic-box" id="weekTopicBox">—</div>
        </div>

        <div class="form-group">
          <label>दिवस (Day) *</label>
          <select id="selDay" onchange="onDayChange()" disabled required>
            <option value="">-- आधी आठवडा निवडा --</option>
          </select>
        </div>
        <div class="form-group">
          <label>दिवसाचा विषय (Day Topic)</label>
          <div class="topic-box" id="dayTopicBox">—</div>
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
            <p>व्हिडिओ निवडा (MP4 / MOV / WEBM, ५० KB – १०० MB)</p>
          </div>
          <div id="videoChosenName" style="margin-top:6px;font-size:12px;color:#ea580c;font-weight:600;min-height:18px;"></div>
        </div>

        <button type="submit" class="btn-submit" id="btnSubmit">✅ उपक्रम जतन करा</button>
      </form>
    </div>
    <% } %>
  </div>
</div>

<script>
const CTX = '<%= request.getContextPath() %>';
let curriculum = null;   // full nested {class: {weeks:[...]}} payload
let selectedPen = '', selectedName = '', selectedClass = '';
const CLASS_ORDER = ['III','IV','V','VI','VII','VIII','IX'];

function showAlert(msg, ok) {
  document.getElementById('alertBox').innerHTML =
    '<div class="alert ' + (ok ? 'alert-ok' : 'alert-err') + '">' + (ok ? '✅ ' : '⚠️ ') + msg + '</div>';
}

// ── Student search (identical pattern to student-activity.jsp) ──
function filterStudents(q) {
  q = q.toLowerCase();
  document.querySelectorAll('.stu-opt').forEach(function(el){
    el.style.display = el.textContent.toLowerCase().indexOf(q) > -1 ? 'flex' : 'none';
  });
  showDropdown();
}
function showDropdown() { document.getElementById('stuDropdown').style.display = 'block'; }
function selectStudent(pen, name, cls) {
  selectedPen = pen; selectedName = name; selectedClass = cls;
  document.getElementById('stuSearch').value = name;
  document.getElementById('stuDropdown').style.display = 'none';
  document.getElementById('selectedStu').textContent = '✓ ' + name + ' (इयत्ता ' + cls + ', PEN: ' + pen + ')';
  // Pre-select the curriculum Class dropdown to match the student's own class, if present
  const selClass = document.getElementById('selClass');
  if (selClass && [...selClass.options].some(o => o.value === cls)) {
    selClass.value = cls;
    onClassChange();
  }
}
document.addEventListener('click', function(e){
  if (!e.target.closest('.stu-select-wrap')) document.getElementById('stuDropdown').style.display = 'none';
});

// ── Cascading Class -> Week -> Day, driven client-side from one preloaded payload ──
function onClassChange() {
  const cls = document.getElementById('selClass').value;
  const selWeek = document.getElementById('selWeek');
  const selDay = document.getElementById('selDay');
  selWeek.innerHTML = '<option value="">-- निवडा --</option>';
  selDay.innerHTML = '<option value="">-- आधी आठवडा निवडा --</option>';
  selDay.disabled = true;
  document.getElementById('weekTopicBox').textContent = '—';
  document.getElementById('dayTopicBox').textContent = '—';

  if (!cls || !curriculum[cls]) { selWeek.disabled = true; return; }
  curriculum[cls].weeks.forEach(function(w){
    const opt = document.createElement('option');
    opt.value = w.weekNo;
    opt.textContent = w.weekLabel.trim() + ' — ' + w.weekTopic;
    selWeek.appendChild(opt);
  });
  selWeek.disabled = false;
}

function currentWeekObj() {
  const cls = document.getElementById('selClass').value;
  const weekNo = document.getElementById('selWeek').value;
  if (!cls || !weekNo || !curriculum[cls]) return null;
  return curriculum[cls].weeks.find(w => String(w.weekNo) === String(weekNo)) || null;
}

function onWeekChange() {
  const week = currentWeekObj();
  const selDay = document.getElementById('selDay');
  selDay.innerHTML = '<option value="">-- निवडा --</option>';
  document.getElementById('dayTopicBox').textContent = '—';

  if (!week) {
    document.getElementById('weekTopicBox').textContent = '—';
    selDay.disabled = true;
    return;
  }
  document.getElementById('weekTopicBox').textContent = week.weekTopic;
  week.days.forEach(function(d){
    const opt = document.createElement('option');
    opt.value = d.dayNo;
    opt.textContent = d.dayLabel;
    selDay.appendChild(opt);
  });
  selDay.disabled = false;
}

function onDayChange() {
  const week = currentWeekObj();
  const dayNo = document.getElementById('selDay').value;
  const box = document.getElementById('dayTopicBox');
  if (!week || !dayNo) { box.textContent = '—'; return; }
  const day = week.days.find(d => String(d.dayNo) === String(dayNo));
  box.textContent = day ? day.dayTopic : '—';
}

// ── Video (mandatory) ──
const MIN_VIDEO_BYTES = 50 * 1024;
const MAX_VIDEO_BYTES = 100 * 1024 * 1024;
function onVideoChosen(input) {
  const label = document.getElementById('videoChosenName');
  const f = input.files && input.files[0];
  if (!f) { label.textContent = ''; return; }
  if (f.size < MIN_VIDEO_BYTES || f.size > MAX_VIDEO_BYTES) {
    label.style.color = '#dc2626';
    label.textContent = '⚠️ आकार 50 KB ते 100 MB दरम्यान असावा (सध्या ' + (f.size/1024/1024).toFixed(2) + ' MB)';
    input.value = '';
    return;
  }
  label.style.color = '#ea580c';
  label.textContent = '✓ ' + f.name + ' (' + (f.size/1024/1024).toFixed(2) + ' MB)';
}

// ── Load curriculum once, then populate the Class dropdown ──
fetch(CTX + '/vidnyansetu-curriculum')
  .then(r => r.json())
  .then(data => {
    curriculum = data;
    const selClass = document.getElementById('selClass');
    if (!selClass) return; // read-only viewer, no form
    selClass.innerHTML = '<option value="">-- निवडा --</option>';
    CLASS_ORDER.filter(c => curriculum[c]).forEach(function(c){
      const opt = document.createElement('option');
      opt.value = c; opt.textContent = 'इयत्ता ' + c;
      selClass.appendChild(opt);
    });
  })
  .catch(err => showAlert('अभ्यासक्रम डेटा लोड होऊ शकला नाही: ' + err, false));

// ── Save ──
const form = document.getElementById('activityForm');
if (form) {
  form.addEventListener('submit', function(e){
    e.preventDefault();
    const week = currentWeekObj();
    const dayNo = document.getElementById('selDay').value;
    const day = week ? week.days.find(d => String(d.dayNo) === String(dayNo)) : null;

    const videoInput = document.getElementById('videoInput');
    const videoFile = videoInput.files && videoInput.files[0];

    // विद्यार्थी ऐच्छिक — हा उपक्रम वर्ग स्तरावर नोंदवला जातो
    if (!week || !day) { showAlert('कृपया इयत्ता, आठवडा व दिवस निवडा', false); return; }
    if (!videoFile) { showAlert('व्हिडिओ अनिवार्य आहे. कृपया उपक्रमाचा व्हिडिओ जोडा.', false); return; }

    const btn = document.getElementById('btnSubmit');
    btn.disabled = true; btn.textContent = '🎥 व्हिडिओ अपलोड होत आहे...';

    const fd = new FormData();
    if (selectedPen)  fd.append('studentPen', selectedPen);     // ऐच्छिक
    if (selectedName) fd.append('studentName', selectedName);   // ऐच्छिक
    fd.append('studentClass', document.getElementById('selClass').value);
    fd.append('weekNo', week.weekNo);
    fd.append('weekLabel', week.weekLabel);
    fd.append('weekTopic', week.weekTopic);
    fd.append('dayNo', day.dayNo);
    fd.append('dayLabel', day.dayLabel);
    fd.append('dayTopic', day.dayTopic);
    fd.append('activityDate', document.getElementById('activityDate').value);
    fd.append('description', document.getElementById('description').value);
    fd.append('video', videoFile, videoFile.name);

    fetch(CTX + '/save-vidnyansetu-activity', { method: 'POST', body: fd })
      .then(r => r.json())
      .then(res => {
        btn.disabled = false; btn.textContent = '✅ उपक्रम जतन करा';
        if (res.success) {
          showAlert('उपक्रम व व्हिडिओ यशस्वीरित्या जतन झाला! मुख्याध्यापकांच्या मंजुरीनंतर तो दिसेल.', true);
          form.reset();
          document.getElementById('selectedStu').textContent = '';
          document.getElementById('videoChosenName').textContent = '';
          document.getElementById('weekTopicBox').textContent = '—';
          document.getElementById('dayTopicBox').textContent = '—';
          document.getElementById('selWeek').disabled = true;
          document.getElementById('selDay').disabled = true;
          selectedPen = '';
          loadActivities();
        } else {
          showAlert(res.message || 'जतन करता आले नाही', false);
        }
      })
      .catch(err => { btn.disabled = false; btn.textContent = '✅ उपक्रम जतन करा'; showAlert('त्रुटी: ' + err, false); });
  });
}

// ── Recent activities list ──
function loadActivities() {
  const list = document.getElementById('activityList');
  fetch(CTX + '/save-vidnyansetu-activity')
    .then(r => r.json())
    .then(rows => {
      if (!rows.length) {
        list.innerHTML = '<div class="empty"><div class="ei">🔬</div>अजून कोणतेही उपक्रम नोंदवलेले नाहीत.</div>';
        return;
      }
      list.innerHTML = rows.map(function(a){
        const status = a.approvalStatus || 'PENDING';
        const statusChip = status === 'APPROVED'
          ? '<span class="chip chip-approved">✅ मंजूर</span>'
          : status === 'REJECTED'
            ? '<span class="chip chip-rejected">❌ नाकारले</span>'
            : '<span class="chip chip-pending">⏳ मंजुरीच्या प्रतीक्षेत</span>';
        const who = a.name
          ? (a.name + ' <span style="font-weight:400;color:#94a3b8;font-size:12px;">PEN: ' + (a.pen || '—') + '</span>')
          : '<span style="color:#64748b;">वर्ग स्तर उपक्रम</span>';
        return '<div class="activity-card">' +
          '<div class="ac-name">' + who + '</div>' +
          '<div class="ac-sub">' +
            '<span class="chip chip-class">इयत्ता ' + a.cls + '</span>' +
            '<span class="chip chip-week">' + (a.weekLabel || '').trim() + '</span>' +
            '<span class="chip chip-day">' + (a.dayLabel || '').trim() + '</span>' +
            statusChip +
          '</div>' +
          (a.date ? '<div class="ac-sub">📅 उपक्रम तारीख: <strong>' + a.date + '</strong></div>' : '') +
          '<div class="ac-desc"><strong>' + (a.weekTopic || '') + '</strong> → ' + (a.dayTopic || '') + '</div>' +
          (a.desc ? '<div class="ac-desc" style="margin-top:6px;">📝 ' + a.desc + '</div>' : '') +
          (status === 'REJECTED' && a.rejectionReason ? '<div class="ac-rejection">⚠️ मुख्याध्यापकांचा शेरा: ' + a.rejectionReason + '</div>' : '') +
          (a.videoUrl ? (
            '<a class="ac-thumb-wrap" href="' + a.videoUrl + '" target="_blank" rel="noopener" title="व्हिडिओ पहा">' +
              (a.videoThumbnailUrl ? '<img class="ac-thumb" src="' + a.videoThumbnailUrl + '" alt="व्हिडिओ थंबनेल"/>' : '<div class="ac-thumb"></div>') +
              '<span class="ac-thumb-play">▶</span>' +
            '</a><br/>' +
            '<a class="video-link" href="' + a.videoUrl + '" target="_blank" rel="noopener">🎥 व्हिडिओ पहा' + (a.videoFilename ? ' (' + a.videoFilename + ')' : '') + '</a>'
          ) : '') +
          '</div>';
      }).join('');
    })
    .catch(() => { list.innerHTML = '<div class="empty"><div class="ei">⚠️</div>उपक्रम लोड होऊ शकले नाहीत.</div>'; });
}
loadActivities();
</script>
</body>
</html>
