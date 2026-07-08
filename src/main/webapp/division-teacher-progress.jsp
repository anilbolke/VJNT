<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null ||
        (user.getUserType() != User.UserType.DIVISION &&
         user.getUserType() != User.UserType.SUPER_DIVISION_OFFICER)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String divisionName = user.getDivisionName();
    boolean isSdo = user.getUserType() == User.UserType.SUPER_DIVISION_OFFICER;
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Teacher Progress - <%= divisionName %></title>
<style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', Arial, sans-serif; background: #f0f2f5; color: #333; }

    /* Header */
    .page-header {
        background: linear-gradient(135deg, #1a237e 0%, #283593 60%, #3949ab 100%);
        color: #fff; padding: 18px 24px;
        display: flex; align-items: center; justify-content: space-between;
    }
    .page-header h1 { font-size: 1.3rem; font-weight: 600; }
    .page-header .sub { font-size: 0.85rem; opacity: .8; margin-top: 3px; }
    .btn-back {
        background: rgba(255,255,255,.15); color: #fff; border: none;
        padding: 8px 16px; border-radius: 6px; cursor: pointer; font-size: .85rem;
        text-decoration: none; display: inline-flex; align-items: center; gap: 6px;
    }
    .btn-back:hover { background: rgba(255,255,255,.25); }

    /* Summary cards */
    .summary-section { padding: 20px 24px 0; }
    .summary-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 14px; }
    .summary-card {
        background: #fff; border-radius: 10px; padding: 16px;
        box-shadow: 0 1px 6px rgba(0,0,0,.08); text-align: center;
        border-top: 3px solid #667eea;
    }
    .summary-card.green { border-top-color: #2e7d32; }
    .summary-card.blue  { border-top-color: #1565c0; }
    .summary-card.yellow{ border-top-color: #f57f17; }
    .summary-card.red   { border-top-color: #c62828; }
    .summary-card h2 { font-size: 1.8rem; font-weight: 700; color: #1a237e; }
    .summary-card p { font-size: .78rem; color: #666; margin-top: 4px; }

    /* Filters */
    .filter-bar {
        background: #fff; margin: 16px 24px; border-radius: 10px;
        padding: 14px 18px; box-shadow: 0 1px 6px rgba(0,0,0,.06);
        display: flex; flex-wrap: wrap; gap: 12px; align-items: center;
    }
    .filter-bar select, .filter-bar input {
        border: 1px solid #ddd; border-radius: 6px; padding: 8px 12px;
        font-size: .88rem; outline: none; min-width: 150px;
    }
    .filter-bar select:focus, .filter-bar input:focus { border-color: #667eea; }
    .btn-reset {
        background: #667eea; color: #fff; border: none; border-radius: 6px;
        padding: 8px 18px; cursor: pointer; font-size: .88rem;
    }
    .btn-reset:hover { background: #5a67d8; }

    /* Content */
    .content { padding: 0 24px 40px; }

    /* District block */
    .district-block { background: #fff; border-radius: 10px; margin-bottom: 16px; box-shadow: 0 1px 6px rgba(0,0,0,.07); overflow: hidden; }
    .district-header {
        background: linear-gradient(90deg, #e8eaf6, #f5f5f5);
        padding: 14px 18px; cursor: pointer;
        display: flex; justify-content: space-between; align-items: center;
        user-select: none; border-bottom: 1px solid #e0e0e0;
    }
    .district-header:hover { background: linear-gradient(90deg, #dde0f5, #efefef); }
    .district-header h3 { font-size: 1rem; color: #1a237e; }
    .district-header .meta { font-size: .8rem; color: #666; display: flex; gap: 16px; }
    .district-header .arrow { transition: transform .25s; font-size: .9rem; }
    .district-header.open .arrow { transform: rotate(180deg); }

    /* School block */
    .school-block { border-bottom: 1px solid #f0f0f0; }
    .school-header {
        padding: 10px 18px 10px 32px; cursor: pointer; background: #fafafa;
        display: flex; justify-content: space-between; align-items: center;
        user-select: none;
    }
    .school-header:hover { background: #f0f4ff; }
    .school-header h4 { font-size: .9rem; color: #283593; }
    .school-header .smeta { font-size: .78rem; color: #888; }
    .school-header .arrow { transition: transform .25s; font-size: .8rem; }
    .school-header.open .arrow { transform: rotate(180deg); }
    /* Generic section body (used by both district and school) */
    .section-body { display: none; }

    /* Teacher cards */
    .teachers-grid { padding: 12px 18px 12px 36px; display: flex; flex-direction: column; gap: 10px; }
    .teacher-card {
        border: 1px solid #e8e8e8; border-radius: 8px; padding: 14px 16px;
        background: #fff; transition: box-shadow .2s;
    }
    .teacher-card:hover { box-shadow: 0 2px 10px rgba(0,0,0,.1); }
    .teacher-top { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; flex-wrap: wrap; }
    .teacher-info h5 { font-size: .95rem; color: #1a237e; margin-bottom: 3px; }
    .teacher-info .tmeta { font-size: .78rem; color: #888; display: flex; gap: 12px; flex-wrap: wrap; }
    .teacher-info .class-tag {
        background: #e8eaf6; color: #3949ab; padding: 2px 8px;
        border-radius: 12px; font-size: .75rem; font-weight: 600;
    }
    .class-teacher-tag {
        background: #e8f5e9; color: #2e7d32; padding: 2px 8px;
        border-radius: 12px; font-size: .72rem;
    }
    .progress-section { min-width: 220px; }
    .progress-bar-wrap { height: 10px; background: #eee; border-radius: 5px; overflow: hidden; margin-bottom: 5px; }
    .progress-bar-fill { height: 100%; border-radius: 5px; transition: width .5s; }
    .bar-excellent      { background: linear-gradient(90deg, #2e7d32, #43a047); }
    .bar-good           { background: linear-gradient(90deg, #1565c0, #1976d2); }
    .bar-average        { background: linear-gradient(90deg, #f57f17, #ffa000); }
    .bar-needs-improvement { background: linear-gradient(90deg, #c62828, #e53935); }
    .bar-no-data        { background: #bbb; }
    .progress-labels { display: flex; justify-content: space-between; font-size: .75rem; color: #666; }

    /* Badge */
    .badge {
        display: inline-block; padding: 4px 10px; border-radius: 12px;
        font-size: .72rem; font-weight: 700; text-transform: uppercase; letter-spacing: .5px;
    }
    .badge-excellent        { background: #e8f5e9; color: #2e7d32; }
    .badge-good             { background: #e3f2fd; color: #1565c0; }
    .badge-average          { background: #fff8e1; color: #f57f17; }
    .badge-needs-improvement{ background: #ffebee; color: #c62828; }
    .badge-no-data          { background: #f5f5f5; color: #9e9e9e; }

    /* Student counts */
    .student-counts { display: flex; gap: 12px; margin-top: 8px; flex-wrap: wrap; }
    .count-chip {
        display: flex; align-items: center; gap: 6px; font-size: .8rem;
        padding: 4px 10px; border-radius: 20px; cursor: pointer; border: none;
        font-family: inherit; transition: opacity .15s;
    }
    .count-chip:hover { opacity: .8; }
    .chip-progress    { background: #e8f5e9; color: #2e7d32; }
    .chip-nonprogress { background: #ffebee; color: #c62828; }
    .chip-total       { background: #e8eaf6; color: #3949ab; }

    /* Student table */
    .student-table-wrap { margin-top: 10px; display: none; }
    .student-table-wrap.visible { display: block; }
    .student-table {
        width: 100%; border-collapse: collapse; font-size: .8rem;
    }
    .student-table th {
        background: #f5f5f5; padding: 7px 10px; text-align: left;
        font-weight: 600; color: #444; border-bottom: 1px solid #ddd;
    }
    .student-table td { padding: 6px 10px; border-bottom: 1px solid #f0f0f0; }
    .student-table tr:hover td { background: #fafafa; }
    .level-pill {
        display: inline-block; padding: 2px 8px; border-radius: 10px;
        font-weight: 600; font-size: .75rem;
    }
    .level-ok  { background: #c8e6c9; color: #1b5e20; }
    .level-bad { background: #ffcdd2; color: #b71c1c; }

    /* Loading spinner */
    .spin { display: inline-block; width: 16px; height: 16px;
        border: 2px solid #ccc; border-top-color: #667eea;
        border-radius: 50%; animation: spin .7s linear infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }

    /* Empty state */
    .empty-state { text-align: center; padding: 48px 20px; color: #999; }
    .empty-state .icon { font-size: 3rem; margin-bottom: 12px; }

    /* Loading overlay */
    #loadingOverlay {
        position: fixed; inset: 0; background: rgba(255,255,255,.85);
        display: flex; align-items: center; justify-content: center;
        z-index: 1000; flex-direction: column; gap: 12px;
    }
    #loadingOverlay .big-spin { width: 48px; height: 48px; border-width: 4px; }
    #loadingOverlay p { color: #444; font-size: 1rem; }

    /* Info button */
    .btn-info {
        background: rgba(255,255,255,.18); color: #fff; border: 1.5px solid rgba(255,255,255,.4);
        padding: 7px 14px; border-radius: 6px; cursor: pointer; font-size: .85rem;
        display: inline-flex; align-items: center; gap: 6px; font-weight: 600;
        transition: background .2s;
    }
    .btn-info:hover { background: rgba(255,255,255,.3); }

    /* Info modal */
    .info-overlay {
        display: none; position: fixed; inset: 0;
        background: rgba(0,0,0,.55); z-index: 2000;
        align-items: center; justify-content: center; padding: 20px;
    }
    .info-overlay.open { display: flex; }
    .info-modal {
        background: #fff; border-radius: 14px; max-width: 660px; width: 100%;
        max-height: 90vh; overflow-y: auto;
        box-shadow: 0 8px 40px rgba(0,0,0,.25);
    }
    .info-modal-head {
        background: linear-gradient(135deg, #1a237e, #3949ab);
        color: #fff; padding: 18px 22px;
        border-radius: 14px 14px 0 0;
        display: flex; justify-content: space-between; align-items: center;
    }
    .info-modal-head h2 { font-size: 1.1rem; font-weight: 700; }
    .info-modal-head .close-btn {
        background: rgba(255,255,255,.2); border: none; color: #fff;
        width: 30px; height: 30px; border-radius: 50%; font-size: 1.1rem;
        cursor: pointer; display: flex; align-items: center; justify-content: center;
    }
    .info-modal-head .close-btn:hover { background: rgba(255,255,255,.35); }
    .info-modal-body { padding: 22px; font-size: .9rem; line-height: 1.8; color: #333; }
    .info-section { margin-bottom: 20px; }
    .info-section h3 {
        font-size: .92rem; font-weight: 700; color: #1a237e;
        border-left: 4px solid #3949ab; padding-left: 10px;
        margin-bottom: 10px;
    }
    .info-table { width: 100%; border-collapse: collapse; font-size: .83rem; margin-top: 8px; }
    .info-table th {
        background: #e8eaf6; color: #1a237e; padding: 8px 10px;
        text-align: left; font-weight: 700; border: 1px solid #c5cae9;
    }
    .info-table td { padding: 7px 10px; border: 1px solid #e0e0e0; vertical-align: top; }
    .info-table tr:nth-child(even) td { background: #f9f9ff; }
    .badge-row { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 6px; }
    .ibadge {
        display: inline-block; padding: 4px 12px; border-radius: 12px;
        font-size: .78rem; font-weight: 700;
    }
    .ib-exc  { background: #e8f5e9; color: #2e7d32; }
    .ib-good { background: #e3f2fd; color: #1565c0; }
    .ib-avg  { background: #fff8e1; color: #f57f17; }
    .ib-ni   { background: #ffebee; color: #c62828; }
    .ib-nd   { background: #f5f5f5; color: #9e9e9e; }
    .info-note {
        background: #fff8e1; border: 1px solid #ffe082; border-radius: 8px;
        padding: 12px 14px; font-size: .83rem; color: #5d4037; margin-top: 8px;
    }
</style>
</head>
<body>

<!-- Header -->
<div class="page-header">
    <div>
        <h1>Teacher FLN Progress Report</h1>
        <div class="sub"><%= divisionName %></div>
    </div>
    <div style="display:flex;gap:10px;align-items:center;">
        <button class="btn-info" onclick="document.getElementById('infoOverlay').classList.add('open')">
            &#9432; गणना कशी होते?
        </button>
        <a href="<%= request.getContextPath() %>/division-dashboard.jsp" class="btn-back">&#8592; Dashboard</a>
    </div>
</div>

<!-- Info Modal -->
<div class="info-overlay" id="infoOverlay" onclick="if(event.target===this)this.classList.remove('open')">
    <div class="info-modal">
        <div class="info-modal-head">
            <h2>&#9432; शिक्षक FLN प्रगती अहवाल — गणना पद्धती</h2>
            <button class="close-btn" onclick="document.getElementById('infoOverlay').classList.remove('open')">&#10005;</button>
        </div>
        <div class="info-modal-body">

            <div class="info-section">
                <h3>१. प्रगती म्हणजे काय? (What is Progress?)</h3>
                <p>एखादा विद्यार्थी <strong>प्रगतीशील (Progress)</strong> मानला जातो जेव्हा त्याने <strong>तिन्ही विषयांत</strong> (मराठी, गणित, इंग्रजी) आपल्या इयत्तेनुसार किमान स्तर गाठलेला असतो. एखाद्या एका विषयात कमी स्तर असला तरी विद्यार्थी <em>Non-Progress</em> ठरतो.</p>
            </div>

            <div class="info-section">
                <h3>२. इयत्तानिहाय किमान स्तर (Class-wise Minimum Levels)</h3>
                <table class="info-table">
                    <thead>
                        <tr>
                            <th>इयत्ता</th>
                            <th>मराठी किमान स्तर</th>
                            <th>इंग्रजी किमान स्तर</th>
                            <th>गणित किमान स्तर</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr><td>इयत्ता १</td><td>स्तर २</td><td>स्तर २</td><td>स्तर २</td></tr>
                        <tr><td>इयत्ता २</td><td>स्तर २</td><td>स्तर २</td><td>स्तर ३</td></tr>
                        <tr><td>इयत्ता ३</td><td>स्तर ३</td><td>स्तर ३</td><td>स्तर ३</td></tr>
                        <tr><td>इयत्ता ४</td><td>स्तर ३</td><td>स्तर ३</td><td>स्तर ४</td></tr>
                        <tr><td>इयत्ता ५</td><td>स्तर ४</td><td>स्तर ४</td><td>स्तर ५</td></tr>
                        <tr><td>इयत्ता ६</td><td>स्तर ४</td><td>स्तर ४</td><td>स्तर ५</td></tr>
                        <tr><td>इयत्ता ७</td><td>स्तर ५</td><td>स्तर ५</td><td>स्तर ६</td></tr>
                        <tr><td>इयत्ता ८</td><td>स्तर ५</td><td>स्तर ५</td><td>स्तर ७</td></tr>
                        <tr><td>इयत्ता ९</td><td>स्तर ६</td><td>स्तर ६</td><td>स्तर ८</td></tr>
                    </tbody>
                </table>
                <div class="info-note">
                    📌 मराठी व इंग्रजीसाठी स्तर १–६ वापरला जातो. गणितासाठी स्तर १–८ वापरला जातो.
                </div>
            </div>

            <div class="info-section">
                <h3>३. टप्पा स्तर कसा निवडला जातो? (Which Phase Level is Used?)</h3>
                <p>एखाद्या विद्यार्थ्याचे चारही टप्प्यांमधील (टप्पा १, २, ३, ४) स्तर पाहिले जातात आणि <strong>सर्वाधिक (Maximum) स्तर</strong> विचारात घेतला जातो.</p>
                <div class="info-note">
                    उदाहरण: एखाद्या विद्यार्थ्याचे मराठी स्तर — टप्पा १: २, टप्पा २: ३, टप्पा ३: ३, टप्पा ४: ४ → <strong>वापरला जाणारा स्तर: ४</strong>
                </div>
            </div>

            <div class="info-section">
                <h3>४. शिक्षकाचा प्रगती % कसा काढला जातो?</h3>
                <p>शिक्षकाला नियुक्त केलेल्या इयत्ता व विभागातील एकूण विद्यार्थ्यांपैकी किती विद्यार्थी प्रगतीशील आहेत, यावरून टक्केवारी काढली जाते:</p>
                <div style="background:#e8eaf6;border-radius:8px;padding:12px 16px;margin-top:8px;font-family:monospace;font-size:.9rem;color:#1a237e;text-align:center;">
                    प्रगती % = (प्रगतीशील विद्यार्थी ÷ एकूण विद्यार्थी) × १००
                </div>
            </div>

            <div class="info-section">
                <h3>५. Badge श्रेणी (Performance Badges)</h3>
                <div class="badge-row">
                    <span class="ibadge ib-exc">&#9733; Excellent — ८०% व त्यावर</span>
                    <span class="ibadge ib-good">&#10003; Good — ६०% ते ७९%</span>
                    <span class="ibadge ib-avg">&#9888; Average — ४०% ते ५९%</span>
                    <span class="ibadge ib-ni">&#9888; Needs Improvement — ४०% पेक्षा कमी</span>
                    <span class="ibadge ib-nd">No Data — विद्यार्थी नाहीत</span>
                </div>
            </div>

            <div class="info-section">
                <h3>६. महत्त्वाच्या नोंदी</h3>
                <ul style="padding-left:18px;line-height:2;">
                    <li>फक्त <strong>सक्रिय (is_active = 1)</strong> विद्यार्थी व शिक्षक विचारात घेतले जातात.</li>
                    <li>शिक्षकाची एकच इयत्ता-विभाग नियुक्ती एक नोंद मानली जाते. एखाद्या शिक्षकाला एकाधिक इयत्ता असल्यास त्या स्वतंत्रपणे दाखवल्या जातात.</li>
                    <li>प्रगती % वर क्लिक केल्यावर त्या शिक्षकाच्या विद्यार्थ्यांची संपूर्ण यादी पाहता येते.</li>
                </ul>
            </div>

        </div>
    </div>
</div>

<!-- Summary cards -->
<div class="summary-section">
    <div class="summary-cards">
        <div class="summary-card">
            <h2 id="totalTeachers">-</h2>
            <p>Total Teachers</p>
        </div>
        <div class="summary-card green">
            <h2 id="excellentTeachers">-</h2>
            <p>Excellent (&ge;80%)</p>
        </div>
        <div class="summary-card blue">
            <h2 id="goodTeachers">-</h2>
            <p>Good (60-79%)</p>
        </div>
        <div class="summary-card yellow">
            <h2 id="avgTeachers">-</h2>
            <p>Average (40-59%)</p>
        </div>
        <div class="summary-card red">
            <h2 id="needsImprovementTeachers">-</h2>
            <p>Needs Improvement (&lt;40%)</p>
        </div>
        <div class="summary-card">
            <h2 id="avgProgressPct">-</h2>
            <p>Avg Progress %</p>
        </div>
    </div>
</div>

<!-- Filters -->
<div class="filter-bar">
    <% if (isSdo) { %>
    <input type="text" id="divisionInput" placeholder="Division name..."
           value="<%= divisionName != null ? divisionName : "" %>">
    <% } %>
    <select id="districtFilter">
        <option value="">All Districts</option>
    </select>
    <select id="classFilter">
        <option value="">All Classes</option>
        <% for (int c = 1; c <= 9; c++) { %>
        <option value="<%= c %>">Class <%= c %></option>
        <% } %>
    </select>
    <select id="badgeFilter">
        <option value="">All Progress Levels</option>
        <option value="excellent">Excellent (&ge;80%)</option>
        <option value="good">Good (60-79%)</option>
        <option value="average">Average (40-59%)</option>
        <option value="needs-improvement">Needs Improvement (&lt;40%)</option>
        <option value="no-data">No Students</option>
    </select>
    <input type="text" id="searchInput" placeholder="Search teacher / school...">
    <button class="btn-reset" onclick="applyFilters()">Apply Filters</button>
    <button class="btn-reset" style="background:#888" onclick="resetFilters()">Reset</button>
</div>

<!-- Main content -->
<div class="content" id="mainContent">
    <div style="text-align:center;padding:60px 20px;color:#555">
        <div class="spin" style="width:40px;height:40px;border-width:4px;margin:0 auto 14px"></div>
        <p>Loading teacher progress data...</p>
    </div>
</div>

<script>
    var contextPath  = '<%= request.getContextPath() %>';
    var divisionName = '<%= divisionName != null ? divisionName.replace("\\", "\\\\").replace("'", "\\'") : "" %>';
    var isSdo        = <%= isSdo %>;

    var allDistricts = [];

    // ── Helpers ─────────────────────────────────────────────────────────────────
    var mainContent = document.getElementById('mainContent');

    function setContent(html) {
        mainContent.innerHTML = html;
    }

    function showSpinner() {
        setContent('<div style="text-align:center;padding:60px 20px;color:#555">' +
            '<div class="spin" style="width:40px;height:40px;border-width:4px;' +
            'margin:0 auto 14px"></div><p>Loading...</p></div>');
    }

    function setText(id, val) {
        var el = document.getElementById(id);
        if (el) el.textContent = val;
    }

    function getDivision() {
        if (isSdo) {
            var inp = document.getElementById('divisionInput');
            return (inp && inp.value.trim()) ? inp.value.trim() : divisionName;
        }
        return divisionName;
    }

    // ── Load data from server ───────────────────────────────────────────────────
    function loadData() {
        showSpinner();

        var division = getDivision();
        var district = document.getElementById('districtFilter').value;
        var cls      = document.getElementById('classFilter').value;

        var url = contextPath + '/teacher-progress?division=' + encodeURIComponent(division);
        if (district) url += '&district=' + encodeURIComponent(district);
        if (cls)      url += '&class='    + encodeURIComponent(cls);

        var controller   = new AbortController();
        var timeoutId    = setTimeout(function() { controller.abort(); }, 60000);

        fetch(url, { signal: controller.signal })
            .then(function(r) {
                clearTimeout(timeoutId);
                if (!r.ok) throw new Error('HTTP ' + r.status);
                return r.json();
            })
            .then(function(data) {
                if (data.error) throw new Error(data.error);

                // Support both array (old format) and object (new format)
                allDistricts = Array.isArray(data) ? [] : (data.districts || []);

                // Always compute summary client-side from actual loaded data
                updateSummary(computeSummary(allDistricts));
                populateDistrictDropdown(allDistricts);
                renderDistricts(allDistricts);
            })
            .catch(function(err) {
                clearTimeout(timeoutId);
                console.error('Teacher progress load error:', err);
                var msg = err.name === 'AbortError'
                    ? 'Request timed out (30s). The query may be slow — try again or apply a district/class filter to narrow results.'
                    : 'Error loading data: ' + err.message;
                setContent('<div class="empty-state"><div class="icon">❌</div>' +
                    '<p>' + msg + '</p>' +
                    '<p style="font-size:.8rem;margin-top:8px;color:#999">Check browser console or Tomcat logs for details</p></div>');
            });
    }

    // ── Summary: computed client-side from loaded district tree ─────────────────
    function computeSummary(districtList) {
        var total = 0, excellent = 0, good = 0, avg = 0, ni = 0, totalPct = 0;

        (districtList || []).forEach(function(dist) {
            (dist.schools || []).forEach(function(school) {
                (school.teachers || []).forEach(function(t) {
                    total++;
                    totalPct += (parseFloat(t.progressPct) || 0);
                    if      (t.badge === 'excellent')          excellent++;
                    else if (t.badge === 'good')               good++;
                    else if (t.badge === 'average')            avg++;
                    else if (t.badge === 'needs-improvement')  ni++;
                });
            });
        });

        return {
            totalTeachers:            total,
            excellentTeachers:        excellent,
            goodTeachers:             good,
            averageTeachers:          avg,
            needsImprovementTeachers: ni,
            avgProgressPct: total > 0 ? Math.round((totalPct / total) * 10) / 10 : 0
        };
    }

    function updateSummary(s) {
        setText('totalTeachers',            s.totalTeachers            || 0);
        setText('excellentTeachers',        s.excellentTeachers        || 0);
        setText('goodTeachers',             s.goodTeachers             || 0);
        setText('avgTeachers',              s.averageTeachers          || 0);
        setText('needsImprovementTeachers', s.needsImprovementTeachers || 0);
        setText('avgProgressPct',          (s.avgProgressPct           || 0) + '%');
    }

    // ── District dropdown ───────────────────────────────────────────────────────
    function populateDistrictDropdown(list) {
        var sel     = document.getElementById('districtFilter');
        var current = sel.value;
        while (sel.options.length > 1) sel.remove(1);
        list.forEach(function(d) {
            var opt = document.createElement('option');
            opt.value       = d.districtName;
            opt.textContent = d.districtName + ' (' + (d.totalTeachers || 0) + ' teachers)';
            sel.appendChild(opt);
        });
        sel.value = current;
    }

    // ── Render districts ────────────────────────────────────────────────────────
    function renderDistricts(districtList) {
        var badge  = document.getElementById('badgeFilter').value;
        var search = document.getElementById('searchInput').value.toLowerCase().trim();

        if (!districtList || districtList.length === 0) {
            setContent('<div class="empty-state"><div class="icon">📭</div>' +
                '<p>No teacher assignment data found for this division.</p></div>');
            return;
        }

        var html        = '';
        var totalShown  = 0;

        districtList.forEach(function(dist) {
            var distHtml         = '';
            var distTeacherCount = 0;

            (dist.schools || []).forEach(function(school) {
                var schoolHtml         = '';
                var schoolTeacherCount = 0;

                (school.teachers || []).forEach(function(t) {
                    if (badge  && t.badge !== badge) return;
                    if (search && !matchSearch(t, school, dist, search)) return;
                    schoolTeacherCount++;
                    schoolHtml += teacherCardHtml(t, school.udiseNo);
                });

                if (schoolTeacherCount === 0) return;
                distTeacherCount += schoolTeacherCount;

                distHtml +=
                    '<div class="school-block">' +
                    '<div class="school-header" onclick="toggleSection(this)">' +
                    '<h4>🏫 ' + esc(school.schoolName) + '</h4>' +
                    '<div style="display:flex;align-items:center;gap:12px">' +
                    '<span class="smeta">' + schoolTeacherCount + ' teacher(s)</span>' +
                    '<span class="arrow">▼</span></div></div>' +
                    '<div class="section-body" style="display:none">' +
                    '<div class="teachers-grid">' + schoolHtml + '</div></div></div>';
            });

            if (distTeacherCount === 0) return;
            totalShown += distTeacherCount;

            html +=
                '<div class="district-block">' +
                '<div class="district-header" onclick="toggleSection(this)">' +
                '<h3>📍 ' + esc(dist.districtName) + '</h3>' +
                '<div style="display:flex;align-items:center;gap:20px">' +
                '<div class="meta"><span>' + distTeacherCount + ' teacher(s)</span>' +
                '<span>' + (dist.schools || []).length + ' school(s)</span></div>' +
                '<span class="arrow">▼</span></div></div>' +
                '<div class="section-body" style="display:none">' + distHtml + '</div></div>';
        });

        setContent(html || '<div class="empty-state"><div class="icon">🔍</div><p>No results match your filters.</p></div>');
    }

    function matchSearch(teacher, school, dist, search) {
        return (teacher.teacherName || '').toLowerCase().includes(search) ||
               (school.schoolName  || '').toLowerCase().includes(search)  ||
               (dist.districtName  || '').toLowerCase().includes(search);
    }

    function esc(str) {
        if (!str) return '';
        return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
    }

    function teacherCardHtml(t, udise) {
        var pct        = t.progressPct || 0;
        var safeUdise  = (udise  || '').replace(/'/g, '');
        var safeCls    = (t.classAssigned   || '').replace(/'/g, '');
        var safeSec    = (t.sectionAssigned || '').replace(/'/g, '');
        var wrapId     = 'stw-' + safeUdise + '-' + safeCls + '-' + safeSec;

        var badgeLabels = {
            'excellent': 'Excellent', 'good': 'Good',
            'average': 'Average', 'needs-improvement': 'Needs Improvement', 'no-data': 'No Data'
        };
        var badgeLabel = badgeLabels[t.badge] || t.badge;

        return '<div class="teacher-card" data-badge="' + t.badge + '">' +
            '<div class="teacher-top">' +
            '<div class="teacher-info"><h5>' + esc(t.teacherName) + '</h5>' +
            '<div class="tmeta">' +
            '<span class="class-tag">Class ' + esc(safeCls) + '-' + esc(safeSec) + '</span>' +
            (t.isClassTeacher ? '<span class="class-teacher-tag">Class Teacher</span>' : '') +
            (t.mobile ? '<span>📞 ' + esc(t.mobile) + '</span>' : '') +
            '</div></div>' +
            '<div class="progress-section">' +
            '<div style="text-align:right;margin-bottom:4px">' +
            '<span class="badge badge-' + t.badge + '">' + badgeLabel + '</span>' +
            '<strong style="margin-left:8px;color:#1a237e">' + pct + '%</strong></div>' +
            '<div class="progress-bar-wrap"><div class="progress-bar-fill bar-' + t.badge +
            '" style="width:' + pct + '%"></div></div>' +
            '<div class="progress-labels"><span>0%</span><span>50%</span><span>100%</span></div>' +
            '</div></div>' +
            '<div class="student-counts">' +
            '<span class="count-chip chip-total">👥 ' + (t.totalStudents || 0) + ' Total</span>' +
            '<button class="count-chip chip-progress" onclick="loadStudents(\'' +
            safeUdise + '\',\'' + safeCls + '\',\'' + safeSec + '\',\'progress\')">✅ ' +
            (t.progressCount || 0) + ' Progress</button>' +
            '<button class="count-chip chip-nonprogress" onclick="loadStudents(\'' +
            safeUdise + '\',\'' + safeCls + '\',\'' + safeSec + '\',\'non-progress\')">❌ ' +
            (t.nonProgressCount || 0) + ' Non-Progress</button>' +
            '</div>' +
            '<div class="student-table-wrap" id="' + wrapId + '"></div>' +
            '</div>';
    }

    // ── Collapse toggles ────────────────────────────────────────────────────────
    function toggleSection(header) {
        header.classList.toggle('open');
        var body = header.nextElementSibling;
        body.style.display = (body.style.display === 'none') ? 'block' : 'none';
    }

    // ── Student drill-down ──────────────────────────────────────────────────────
    function loadStudents(udise, cls, section, type) {
        var wrapId = 'stw-' + udise + '-' + cls + '-' + section;
        var wrap   = document.getElementById(wrapId);
        if (!wrap) return;

        // Toggle off if same type already shown
        if (wrap.classList.contains('visible') && wrap.dataset.currentType === type) {
            wrap.classList.remove('visible');
            wrap.innerHTML = '';
            wrap.dataset.currentType = '';
            return;
        }

        wrap.innerHTML = '<div style="padding:10px;text-align:center">' +
            '<div class="spin" style="width:20px;height:20px;margin:0 auto"></div></div>';
        wrap.classList.add('visible');
        wrap.dataset.currentType = type;

        var url = contextPath + '/teacher-progress-students' +
            '?udise='   + encodeURIComponent(udise) +
            '&class='   + encodeURIComponent(cls) +
            '&section=' + encodeURIComponent(section) +
            '&type='    + encodeURIComponent(type);

        fetch(url)
            .then(function(r) { return r.json(); })
            .then(function(students) {
                if (!Array.isArray(students) || students.length === 0) {
                    wrap.innerHTML = '<p style="padding:10px;color:#888;font-size:.8rem">No students found.</p>';
                    return;
                }
                wrap.innerHTML = buildStudentTable(students);
            })
            .catch(function(err) {
                wrap.innerHTML = '<p style="color:red;padding:8px;font-size:.8rem">Error: ' + err.message + '</p>';
            });
    }

    function buildStudentTable(students) {
        var html = '<table class="student-table"><thead><tr>' +
            '<th>#</th><th>Student Name</th><th>PEN</th>' +
            '<th>Marathi</th><th>Math</th><th>English</th><th>Status</th>' +
            '</tr></thead><tbody>';

        students.forEach(function(s, i) {
            var minME   = s.minME   || 2;
            var minMath = s.minMath || 2;
            html += '<tr><td>' + (i + 1) + '</td>' +
                '<td><strong>' + esc(s.studentName) + '</strong></td>' +
                '<td>' + (s.studentPen || '-') + '</td>' +
                '<td><span class="level-pill ' + (s.marathiLevel  >= minME   ? 'level-ok' : 'level-bad') + '">' + s.marathiLevel  + '</span></td>' +
                '<td><span class="level-pill ' + (s.mathLevel    >= minMath  ? 'level-ok' : 'level-bad') + '">' + s.mathLevel    + '</span></td>' +
                '<td><span class="level-pill ' + (s.englishLevel >= minME   ? 'level-ok' : 'level-bad') + '">' + s.englishLevel + '</span></td>' +
                '<td>' + (s.isProgress
                    ? '<span class="badge badge-excellent">Good</span>'
                    : '<span class="badge badge-needs-improvement">Needs Help</span>') + '</td></tr>';
        });

        return html + '</tbody></table>';
    }

    // ── Filters ─────────────────────────────────────────────────────────────────
    function applyFilters() {
        var district = document.getElementById('districtFilter').value;
        var cls      = document.getElementById('classFilter').value;
        var badge    = document.getElementById('badgeFilter').value;
        var search   = document.getElementById('searchInput').value.toLowerCase().trim();

        if (district || cls) {
            loadData();
            return;
        }

        if (!badge && !search) {
            renderDistricts(allDistricts);
            return;
        }

        var filtered = allDistricts.map(function(dist) {
            var schools = (dist.schools || []).map(function(school) {
                var teachers = (school.teachers || []).filter(function(t) {
                    if (badge && t.badge !== badge) return false;
                    if (search && !matchSearch(t, school, dist, search)) return false;
                    return true;
                });
                return { schoolName: school.schoolName, udiseNo: school.udiseNo, teachers: teachers };
            }).filter(function(s) { return s.teachers.length > 0; });
            return { districtName: dist.districtName, schools: schools,
                     totalTeachers: schools.reduce(function(a, s) { return a + s.teachers.length; }, 0) };
        }).filter(function(d) { return d.schools.length > 0; });

        renderDistricts(filtered);
    }

    function resetFilters() {
        document.getElementById('districtFilter').value = '';
        document.getElementById('classFilter').value    = '';
        document.getElementById('badgeFilter').value    = '';
        document.getElementById('searchInput').value    = '';
        if (isSdo) {
            var inp = document.getElementById('divisionInput');
            if (inp) inp.value = divisionName;
        }
        loadData();
    }

    // ── Start ───────────────────────────────────────────────────────────────────
    loadData();

    if (isSdo) {
        var divInp = document.getElementById('divisionInput');
        if (divInp) {
            divInp.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') loadData();
            });
        }
    }
</script>
</body>
</html>
