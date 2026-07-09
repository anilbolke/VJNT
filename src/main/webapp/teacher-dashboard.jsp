<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.TEACHER)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="mr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Teacher Dashboard - GATEE Portal</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, sans-serif; }
        body { background: #f0f2f5; min-height: 100vh; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px 30px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 15px; }
        .header h1 { font-size: 22px; }
        .header .sub { font-size: 13px; opacity: 0.9; margin-top: 4px; }
        .header-actions { display: flex; gap: 10px; }
        .header-actions a { background: rgba(255,255,255,0.2); color: white; text-decoration: none; padding: 10px 18px; border-radius: 8px; font-size: 14px; font-weight: 600; }
        .header-actions a:hover { background: rgba(255,255,255,0.3); }
        .container { max-width: 1300px; margin: 25px auto; padding: 0 20px; }
        .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 25px; }
        .card { padding: 20px; border-radius: 12px; color: white; text-align: center; }
        .card .num { font-size: 32px; font-weight: 700; }
        .card .lbl { font-size: 14px; margin-top: 5px; }
        .section { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 25px; }
        .section h2 { color: #333; margin-bottom: 15px; font-size: 18px; }
        .filters { display: flex; gap: 15px; margin-bottom: 18px; flex-wrap: wrap; }
        .filters input, .filters select { padding: 10px 15px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; }
        .filters input { flex: 1; min-width: 220px; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #f8f9fa; border-bottom: 2px solid #dee2e6; padding: 12px; text-align: left; font-weight: 600; font-size: 14px; }
        td { padding: 11px 12px; border-bottom: 1px solid #e9ecef; font-size: 14px; }
        tr:hover td { background: #f8f9fa; }
        .badge { display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600; color: white; }
        .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #667eea; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        .assignment-chip { display: inline-block; background: #EDE7F6; color: #4527A0; padding: 6px 14px; border-radius: 16px; font-size: 13px; font-weight: 600; margin: 0 8px 8px 0; }
        .error-box { background: #FFEBEE; border: 1px solid #EF9A9A; color: #B71C1C; padding: 15px; border-radius: 8px; }
        @media (max-width: 700px) { .table-wrap { overflow-x: auto; } }

        .video-btn { background: #667eea; color: white; border: none; padding: 7px 14px; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; white-space: nowrap; }
        .video-btn:hover { background: #5568d3; }
        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.55); z-index: 1000; align-items: center; justify-content: center; padding: 20px; }
        .modal-overlay.open { display: flex; }
        .modal-box { background: white; border-radius: 12px; max-width: 480px; width: 100%; max-height: 90vh; overflow-y: auto; padding: 25px; }
        .modal-box h3 { margin-bottom: 4px; color: #333; }
        .modal-box .modal-sub { color: #777; font-size: 13px; margin-bottom: 16px; }
        .modal-close { float: right; background: none; border: none; font-size: 20px; cursor: pointer; color: #999; }
        .phase-row { display: flex; justify-content: space-between; align-items: center; padding: 9px 0; border-bottom: 1px solid #eee; font-size: 13px; }
        .phase-row:last-child { border-bottom: none; }
        .phase-badge { padding: 3px 10px; border-radius: 10px; font-size: 11px; font-weight: 700; color: white; }
        .phase-badge.locked { background: #9e9e9e; }
        .phase-badge.available { background: #43a047; }
        .phase-badge.pending { background: #fb8c00; }
        .phase-badge.approved { background: #1e88e5; }
        .phase-badge.rejected { background: #e53935; }
        .modal-box form { margin-top: 16px; }
        .modal-box label { display: block; font-size: 13px; font-weight: 600; color: #444; margin-bottom: 6px; }
        .modal-box select, .modal-box input[type="file"] { width: 100%; padding: 9px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; margin-bottom: 14px; }
        .modal-box button[type="submit"] { background: #43a047; color: white; border: none; padding: 11px 20px; border-radius: 6px; font-weight: 600; cursor: pointer; width: 100%; }
        .modal-box button[type="submit"]:disabled { background: #bbb; cursor: not-allowed; }
        .upload-msg { margin-top: 10px; font-size: 13px; padding: 8px 10px; border-radius: 6px; }
        .upload-msg.ok { background: #E8F5E9; color: #1B5E20; }
        .upload-msg.err { background: #FFEBEE; color: #B71C1C; }
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>👨‍🏫 <span id="hdrTeacherName"><%= user.getFullName() != null ? user.getFullName() : user.getUsername() %></span></h1>
            <div class="sub">Subject Teacher | UDISE: <%= user.getUdiseNo() != null ? user.getUdiseNo() : "-" %> | <span id="hdrSubjects"></span></div>
        </div>
        <div class="header-actions">
            <a href="<%= request.getContextPath() %>/raise-ticket.jsp">🎫 Support Tickets</a>
            <a href="<%= request.getContextPath() %>/change-password">🔑 Change Password</a>
            <a href="<%= request.getContextPath() %>/logout">🚪 Logout</a>
        </div>
    </div>

    <div class="container">
        <!-- Summary Cards -->
        <div class="cards">
            <div class="card" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
                <div class="num" id="cardStudents">-</div>
                <div class="lbl">माझे विद्यार्थी (My Students)</div>
            </div>
            <div class="card" style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);">
                <div class="num" id="cardClasses">-</div>
                <div class="lbl">नियुक्त वर्ग (Assigned Classes)</div>
            </div>
            <div class="card" style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);">
                <div class="num" id="cardSubjects">-</div>
                <div class="lbl">विषय (Subjects)</div>
            </div>
        </div>

        <!-- Assignments -->
        <div class="section">
            <h2>📚 माझे वर्ग (My Class Assignments)</h2>
            <div id="assignmentChips"><div class="spinner"></div></div>
        </div>

        <!-- My Students -->
        <div class="section">
            <h2>👨‍🎓 माझे विद्यार्थी (My Students)</h2>
            <p style="color:#666; font-size:13px; margin-bottom:15px;">फक्त आपल्याला नियुक्त केलेले विद्यार्थी येथे दिसतात (Only students mapped to you are shown).</p>
            <div class="filters">
                <input type="text" id="searchBox" placeholder="Search student name / PEN..." onkeyup="renderStudents()">
                <select id="classFilter" onchange="renderStudents()">
                    <option value="">All Classes</option>
                </select>
            </div>
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>विद्यार्थ्याचे नाव (Student Name)</th>
                            <th>वर्ग (Class)</th>
                            <th>तुकडी (Section)</th>
                            <th>Gender</th>
                            <th>PEN</th>
                            <th>मराठी</th>
                            <th>गणित</th>
                            <th>English</th>
                            <th>Phase Video</th>
                        </tr>
                    </thead>
                    <tbody id="studentsBody">
                        <tr><td colspan="10" style="text-align:center; padding:40px;"><div class="spinner"></div></td></tr>
                    </tbody>
                </table>
            </div>
            <div id="countInfo" style="margin-top:12px; color:#666; font-size:14px;"></div>
        </div>
    </div>

    <!-- Phase Video Upload Modal -->
    <div class="modal-overlay" id="videoModal">
        <div class="modal-box">
            <button class="modal-close" onclick="closeVideoModal()">&times;</button>
            <h3 id="modalStudentName">-</h3>
            <div class="modal-sub">प्रत्येक टप्प्यासाठी एकच व्हिडिओ अपलोड करता येईल, फक्त मुख्याध्यापकांनी तो टप्पा मंजूर केल्यावरच (One video per phase, only after the Head Master approves that phase).</div>

            <div id="phaseStatusList"></div>

            <form id="phaseVideoForm">
                <label for="phaseSelect">टप्पा निवडा (Select Phase)</label>
                <select id="phaseSelect" required></select>

                <label for="videoFileInput">व्हिडिओ फाईल (Video File)</label>
                <input type="file" id="videoFileInput" accept="video/*" required>

                <button type="submit" id="uploadSubmitBtn">📹 Upload Video</button>
            </form>
            <div id="uploadMsg"></div>
        </div>
    </div>

    <!-- Video Player Popup -->
    <div class="modal-overlay" id="playerModal">
        <div class="modal-box" style="max-width: 680px;">
            <button class="modal-close" onclick="closePlayerModal()">&times;</button>
            <h3 id="playerTitle">Video Player</h3>
            <video id="playerVideoEl" controls controlsList="nodownload noremoteplayback" disablePictureInPicture oncontextmenu="return false;" style="width:100%; max-height:70vh; border-radius:8px; margin-top:12px; background:#000;"></video>
        </div>
    </div>

    <script>
        const contextPath = '<%= request.getContextPath() %>';
        let allStudents = [];
        let phaseApprovals = {};   // { "1": "APPROVED"/"PENDING"/"REJECTED"/undefined, ... }
        let videosByStudent = {};  // { studentId: { "1": {approvalStatus, rejectionReason, ...}, ... } }
        let activeModalStudentId = null;

        function escapeHtml(text) {
            if (text === null || text === undefined) return '';
            return String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;')
                .replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#039;');
        }

        function loadVideoStatus() {
            return fetch(contextPath + '/teacher-phase-video-status')
                .then(r => r.json())
                .then(data => {
                    phaseApprovals = data.phaseApprovals || {};
                    videosByStudent = data.videos || {};
                })
                .catch(() => { phaseApprovals = {}; videosByStudent = {}; });
        }

        window.addEventListener('load', function() {
            Promise.all([
                fetch(contextPath + '/teacher-my-students').then(r => r.json()),
                loadVideoStatus()
            ]).then(([data]) => {
                    if (data.error) {
                        document.getElementById('assignmentChips').innerHTML = '';
                        document.getElementById('studentsBody').innerHTML =
                            '<tr><td colspan="10"><div class="error-box">' + escapeHtml(data.error) + '</div></td></tr>';
                        return;
                    }

                    document.getElementById('hdrSubjects').textContent = data.subjectsTaught || '';

                    // Assignments
                    const assignments = data.assignments || [];
                    let chips = '';
                    assignments.forEach(a => {
                        chips += '<span class="assignment-chip">वर्ग ' + escapeHtml(a['class']) + ' - ' + escapeHtml(a.section)
                              + ' | ' + escapeHtml(a.subjects)
                              + (a.isClassTeacher ? ' ⭐ (Class Teacher)' : '') + '</span>';
                    });
                    document.getElementById('assignmentChips').innerHTML =
                        chips || '<div class="error-box">अद्याप वर्ग नियुक्त केलेले नाहीत. कृपया शाळा समन्वयकांशी संपर्क करा.<br>(No classes assigned yet. Please contact your School Coordinator.)</div>';

                    // Cards
                    allStudents = data.students || [];
                    document.getElementById('cardStudents').textContent = allStudents.length;
                    document.getElementById('cardClasses').textContent = assignments.length;
                    const subjects = (data.subjectsTaught || '').split(',').map(s => s.trim()).filter(s => s);
                    document.getElementById('cardSubjects').textContent = subjects.length || '-';

                    // Class filter options
                    const classes = [...new Set(allStudents.map(s => s['class'] + ' - ' + s.section))].sort();
                    const sel = document.getElementById('classFilter');
                    classes.forEach(c => {
                        const opt = document.createElement('option');
                        opt.value = c;
                        opt.textContent = 'वर्ग ' + c;
                        sel.appendChild(opt);
                    });

                    renderStudents();
                })
                .catch(err => {
                    document.getElementById('studentsBody').innerHTML =
                        '<tr><td colspan="10"><div class="error-box">Failed to load students: ' + escapeHtml(err) + '</div></td></tr>';
                });
        });

        function levelBadge(level) {
            if (!level || level === '-') return '<span style="color:#bbb;">-</span>';
            return '<span class="badge" style="background:#667eea;">' + escapeHtml(level) + '</span>';
        }

        function renderStudents() {
            const search = document.getElementById('searchBox').value.toLowerCase();
            const classFilter = document.getElementById('classFilter').value;
            const tbody = document.getElementById('studentsBody');

            const filtered = allStudents.filter(s => {
                const matchesSearch = !search ||
                    s.studentName.toLowerCase().includes(search) ||
                    (s.studentPen && s.studentPen.toLowerCase().includes(search));
                const matchesClass = !classFilter || (s['class'] + ' - ' + s.section) === classFilter;
                return matchesSearch && matchesClass;
            });

            if (filtered.length === 0) {
                tbody.innerHTML = '<tr><td colspan="10" style="text-align:center; padding:25px; color:#999;">No students found</td></tr>';
                document.getElementById('countInfo').textContent = '';
                return;
            }

            let html = '';
            filtered.forEach((s, i) => {
                html += '<tr>';
                html += '<td>' + (i + 1) + '</td>';
                html += '<td style="font-weight:500;">' + escapeHtml(s.studentName) + '</td>';
                html += '<td>' + escapeHtml(s['class']) + '</td>';
                html += '<td>' + escapeHtml(s.section) + '</td>';
                html += '<td>' + escapeHtml(s.gender) + '</td>';
                html += '<td style="font-family:monospace; color:#666;">' + escapeHtml(s.studentPen) + '</td>';
                html += '<td>' + levelBadge(s.marathiLevel) + '</td>';
                html += '<td>' + levelBadge(s.mathLevel) + '</td>';
                html += '<td>' + levelBadge(s.englishLevel) + '</td>';
                html += '<td>' + videoCellHtml(s.studentId) + '</td>';
                html += '</tr>';
            });
            tbody.innerHTML = html;
            document.getElementById('countInfo').textContent = 'Showing ' + filtered.length + ' of ' + allStudents.length + ' students';
        }

        // ---------- Phase Video Upload ----------

        // TEMPORARY: lets teachers upload without the phase being approved by
        // the Head Master first, so the upload button can be tested end-to-end.
        // Set back to false to require phase approval before unlocking upload.
        const TESTING_BYPASS_PHASE_LOCK = true;

        function phaseStateFor(studentId, phase) {
            const approvalStatus = phaseApprovals[String(phase)];
            const video = (videosByStudent[String(studentId)] || {})[String(phase)];

            if (approvalStatus !== 'APPROVED' && !TESTING_BYPASS_PHASE_LOCK) {
                return { state: 'locked', label: 'Locked', video: video || null };
            }
            if (!video) {
                return { state: 'available', label: 'Available', video: null };
            }
            if (video.approvalStatus === 'PENDING') {
                return { state: 'pending', label: 'Pending HM Review', video: video };
            }
            if (video.approvalStatus === 'APPROVED') {
                return { state: 'approved', label: 'Approved', video: video };
            }
            return { state: 'rejected', label: 'Rejected - Re-upload', video: video };
        }

        function videoCellHtml(studentId) {
            let done = 0;
            for (let p = 1; p <= 4; p++) {
                if (phaseStateFor(studentId, p).state === 'approved') done++;
            }
            return '<button class="video-btn" onclick="openVideoModal(' + studentId + ')">📹 ' + done + '/4</button>';
        }

        let modalPhaseVideoUrls = {}; // { phase: cdnUrl } for the currently open modal

        function watchPhaseVideo(phase) {
            const url = modalPhaseVideoUrls[phase];
            if (!url) return;
            document.getElementById('playerTitle').textContent = 'Phase ' + phase + ' Video';
            const videoEl = document.getElementById('playerVideoEl');
            videoEl.src = url;
            document.getElementById('playerModal').classList.add('open');
            videoEl.play().catch(() => {}); // autoplay may be blocked; controls remain usable either way
        }

        function closePlayerModal() {
            const videoEl = document.getElementById('playerVideoEl');
            videoEl.pause();
            videoEl.removeAttribute('src');
            videoEl.load();
            document.getElementById('playerModal').classList.remove('open');
        }

        function openVideoModal(studentId) {
            const student = allStudents.find(s => s.studentId === studentId);
            if (!student) return;
            activeModalStudentId = studentId;

            document.getElementById('modalStudentName').textContent = student.studentName +
                ' (वर्ग ' + student['class'] + ' - ' + student.section + ')';

            modalPhaseVideoUrls = {};
            let listHtml = '';
            let defaultPhase = null;
            for (let p = 1; p <= 4; p++) {
                const info = phaseStateFor(studentId, p);
                let watchBtn = '';
                if (info.video && info.video.filePath) {
                    modalPhaseVideoUrls[p] = info.video.filePath;
                    watchBtn = '<button type="button" class="video-btn" style="padding:3px 10px; font-size:11px; margin-left:8px;" onclick="watchPhaseVideo(' + p + ')">▶ Watch</button>';
                }
                listHtml += '<div class="phase-row"><span>Phase ' + p + '</span>' +
                    '<span><span class="phase-badge ' + info.state + '">' + escapeHtml(info.label) + '</span>' + watchBtn + '</span></div>';
                if (info.state === 'available' || info.state === 'rejected') {
                    defaultPhase = p; // keep overwriting so the LAST (highest-numbered) uploadable phase wins
                }
            }
            document.getElementById('phaseStatusList').innerHTML = listHtml;

            const select = document.getElementById('phaseSelect');
            select.innerHTML = '';
            let anyUploadable = false;
            for (let p = 1; p <= 4; p++) {
                const info = phaseStateFor(studentId, p);
                const uploadable = info.state === 'available' || info.state === 'rejected';
                if (uploadable) anyUploadable = true;
                const opt = document.createElement('option');
                opt.value = p;
                opt.textContent = 'Phase ' + p + ' (' + info.label + ')';
                opt.disabled = !uploadable;
                if (p === defaultPhase) opt.selected = true;
                select.appendChild(opt);
            }

            document.getElementById('uploadSubmitBtn').disabled = !anyUploadable;
            document.getElementById('uploadMsg').innerHTML = '';
            document.getElementById('videoFileInput').value = '';
            document.getElementById('videoModal').classList.add('open');
        }

        function closeVideoModal() {
            document.getElementById('videoModal').classList.remove('open');
            activeModalStudentId = null;
        }

        document.getElementById('phaseVideoForm').addEventListener('submit', function(e) {
            e.preventDefault();
            if (!activeModalStudentId) return;

            const phase = document.getElementById('phaseSelect').value;
            const fileInput = document.getElementById('videoFileInput');
            const msgEl = document.getElementById('uploadMsg');
            const submitBtn = document.getElementById('uploadSubmitBtn');

            if (!fileInput.files || fileInput.files.length === 0) {
                msgEl.innerHTML = '<div class="upload-msg err">Please select a video file.</div>';
                return;
            }

            const formData = new FormData();
            formData.append('studentId', activeModalStudentId);
            formData.append('phaseNumber', phase);
            formData.append('videoFile', fileInput.files[0]);

            submitBtn.disabled = true;
            submitBtn.textContent = '⏳ Uploading...';
            msgEl.innerHTML = '';

            fetch(contextPath + '/upload-phase-video', { method: 'POST', body: formData })
                .then(r => r.json())
                .then(data => {
                    submitBtn.textContent = '📹 Upload Video';
                    if (data.success) {
                        msgEl.innerHTML = '<div class="upload-msg ok">' + escapeHtml(data.message) + '</div>';
                        loadVideoStatus().then(() => {
                            renderStudents();
                            openVideoModal(activeModalStudentId);
                        });
                    } else {
                        submitBtn.disabled = false;
                        msgEl.innerHTML = '<div class="upload-msg err">' + escapeHtml(data.message) + '</div>';
                    }
                })
                .catch(err => {
                    submitBtn.disabled = false;
                    submitBtn.textContent = '📹 Upload Video';
                    msgEl.innerHTML = '<div class="upload-msg err">Upload failed: ' + escapeHtml(err) + '</div>';
                });
        });
    </script>
</body>
</html>
