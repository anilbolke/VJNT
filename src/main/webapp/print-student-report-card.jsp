<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    String userType = (String) session.getAttribute("userType");
    
    if (user == null || userType == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    // Get parameters from request
    String studentName = request.getParameter("studentName");
    String penNumber = request.getParameter("penNumber");
    String studentClass = request.getParameter("studentClass");
    String section = request.getParameter("section");
    
    SchoolDAO schoolDAO = new SchoolDAO();
    String udiseNo = user.getUdiseNo();
    School school = schoolDAO.getSchoolByUdise(udiseNo);
    
    String schoolName = school != null ? school.getSchoolName() : "School Name";
    String district = school != null ? school.getDistrictName(): "District";
    
    // Current academic year
    Calendar cal = Calendar.getInstance();
    int year = cal.get(Calendar.YEAR);
    int month = cal.get(Calendar.MONTH);
    String academicSession = (month >= 3) ? year + "-" + (year + 1) : (year - 1) + "-" + year;
    
    // Current date
    java.text.SimpleDateFormat dateFormat = new java.text.SimpleDateFormat("dd-MMM-yyyy");
    String currentDate = dateFormat.format(new Date());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Comprehensive Report Card - <%= studentName %></title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: Arial, sans-serif;
            padding: 20px;
            background-color: #f5f5f5;
        }
        
        .report-card {
            max-width: 1000px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            border-bottom: 3px solid #333;
            padding-bottom: 15px;
        }
        
        .logo {
            width: 80px;
            height: 80px;
            background-color: #f0f0f0;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            border: 3px solid #006400;
            font-size: 40px;
        }
        
        .header-center {
            flex-grow: 1;
            text-align: center;
            padding: 0 20px;
        }
        
        .header-center h1 {
            font-size: 28px;
            margin-bottom: 5px;
            font-weight: bold;
            color: #333;
        }
        
        .header-center p {
            font-size: 12px;
            margin: 3px 0;
            color: #555;
        }
        
        .header-center .school-address {
            font-weight: 600;
            color: #000;
        }
        
        .report-title {
            background-color: #000;
            color: white;
            text-align: center;
            padding: 8px;
            font-weight: bold;
            font-size: 18px;
            margin-bottom: 2px;
        }
        
        .class-session {
            display: flex;
            border: 2px solid #000;
            background-color: #f9f9f9;
        }
        
        .class-session > div {
            padding: 10px;
            font-weight: bold;
            font-size: 14px;
        }
        
        .class-info {
            flex: 1;
            border-right: 2px solid #000;
        }
        
        .session-info {
            flex: 1;
            text-align: right;
        }
        
        .student-info {
            display: grid;
            grid-template-columns: 1fr 2fr 1fr 2fr;
            border: 2px solid #000;
            border-top: none;
        }
        
        .student-info > div {
            padding: 10px;
            border-right: 1px solid #000;
            border-bottom: 1px solid #000;
            font-size: 13px;
        }
        
        .student-info > div:nth-child(4n) {
            border-right: none;
        }
        
        .label {
            font-weight: bold;
            background-color: #f0f0f0;
        }
        
        .section-title {
            background-color: #667eea;
            color: white;
            padding: 5px 10px;
            font-weight: bold;
            font-size: 13px;
            margin-top: 8px;
            border-radius: 3px;
        }
        
        .assessment-section {
            border: 1px solid #aaa;
            margin-top: 8px;
        }
        
        .assessment-header {
            background-color: #90EE90;
            padding: 5px 10px;
            font-weight: bold;
            text-align: center;
            border-bottom: 1px solid #aaa;
            font-size: 12px;
        }
        
        .assessment-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 0;
        }
        
        .assessment-box {
            border-right: 1px solid #aaa;
            border-bottom: 1px solid #aaa;
            padding: 6px 8px;
            text-align: center;
        }
        
        .assessment-box:nth-child(3n) {
            border-right: none;
        }
        
        .assessment-box:last-child,
        .assessment-box:nth-last-child(2),
        .assessment-box:nth-last-child(3) {
            border-bottom: none;
        }
        
        .assessment-label {
            font-size: 11px;
            color: #444;
            margin-bottom: 3px;
            font-weight: 700;
            text-transform: uppercase;
        }
        
        .assessment-teacher {
            font-size: 10px;
            color: #888;
            margin-bottom: 3px;
            font-style: italic;
        }
        
        .assessment-value {
            font-size: 12px;
            font-weight: bold;
            color: #333;
            line-height: 1.3;
        }
        
        .assessment-value.level-1 { color: #dc3545; }
        .assessment-value.level-2 { color: #fd7e14; }
        .assessment-value.level-3 { color: #ffc107; }
        .assessment-value.level-4 { color: #28a745; }
        .assessment-value.level-5 { color: #007bff; }
        
        .overall-progress {
            background-color: #e7f3ff;
            padding: 5px 10px;
            text-align: center;
            font-size: 12px;
            font-weight: bold;
            color: #004085;
            border: 1px solid #007bff;
            margin-top: 6px;
        }
        
        /* ── Compact 3-column activity table ── */
        .activities-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 6px;
            font-size: 11px;
        }
        .activities-table th {
            background-color: #90EE90;
            border: 1px solid #666;
            padding: 5px 8px;
            text-align: center;
            font-weight: bold;
            font-size: 11.5px;
        }
        .activities-table td {
            border: 1px solid #bbb;
            padding: 4px 8px;
            vertical-align: middle;
            line-height: 1.4;
            font-size: 11px;
        }
        .activities-table td.subject-cell {
            font-weight: bold;
            font-size: 12px;
            text-align: center;
            background: #f0f4ff;
            border-right: 2px solid #667eea;
        }
        .activities-table td.count-cell {
            text-align: center;
            font-weight: bold;
            color: #007bff;
            font-size: 13px;
        }
        .activities-table tbody tr:nth-child(odd) td:not(.subject-cell) { background: #fff; }
        .activities-table tbody tr:nth-child(even) td:not(.subject-cell) { background: #f9f9f9; }

        /* ── Compact summary bar ── */
        .summary-bar {
            display: flex;
            gap: 20px;
            align-items: center;
            margin-top: 8px;
            padding: 5px 10px;
            background: #e7f3ff;
            border: 1px solid #007bff;
            border-radius: 4px;
            font-size: 12px;
        }
        .summary-bar .sv { font-weight: bold; font-size: 15px; color: #007bff; margin-right: 3px; }

        .stat-label {
            font-size: 13px;
            color: #666;
            font-weight: bold;
        }
        
        .palak-melava-section {
            margin-top: 6px;
            border: 1px solid #aaa;
        }
        
        .palak-melava-header {
            background-color: #90EE90;
            padding: 4px 10px;
            font-weight: bold;
            text-align: center;
            border-bottom: 1px solid #aaa;
            font-size: 11px;
        }
        
        .palak-melava-content {
            padding: 4px 8px;
        }
        
        /* compact one-liner meeting table */
        .meeting-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 11px;
        }
        .meeting-table th {
            background: #f0f4ff;
            border: 1px solid #bbb;
            padding: 3px 6px;
            font-weight: bold;
            text-align: center;
        }
        .meeting-table td {
            border: 1px solid #ddd;
            padding: 3px 6px;
            vertical-align: middle;
        }
        .meeting-table tbody tr:nth-child(even) td { background: #fafafa; }
        
        .remarks-section {
            margin-top: 6px;
            border: 1px solid #aaa;
        }
        
        .remarks-header {
            background-color: #f0f0f0;
            padding: 4px 10px;
            font-weight: bold;
            border-bottom: 1px solid #aaa;
            text-align: center;
            font-size: 11px;
        }
        
        .remarks-content {
            padding: 6px 10px;
            min-height: 30px;
            font-size: 11px;
            line-height: 1.5;
        }
        
        .signatures {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            border: 1px solid #aaa;
            border-top: none;
            margin-top: 6px;
        }
        
        .signatures > div {
            padding: 8px 10px;
            border-right: 1px solid #aaa;
            text-align: center;
            min-height: 55px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }
        
        .signatures > div:last-child {
            border-right: none;
        }
        
        .signature-label {
            font-weight: bold;
            font-size: 11px;
            margin-top: auto;
        }
        
        .date-box {
            text-align: center;
        }
        
        .date-large {
            font-size: 14px;
            font-weight: bold;
            margin: 4px 0;
            color: #333;
        }
        
        .grading-info {
            margin-top: 25px;
            padding: 20px;
            background-color: #f9f9f9;
            border: 2px solid #ddd;
            border-radius: 8px;
        }
        
        .grading-info h3 {
            margin-bottom: 15px;
            color: #333;
            font-size: 16px;
            border-bottom: 2px solid #667eea;
            padding-bottom: 8px;
        }
        
        .grading-scale {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }
        
        .grading-scale th,
        .grading-scale td {
            border: 2px solid #000;
            padding: 10px;
            text-align: center;
            font-weight: bold;
            font-size: 12px;
        }
        
        .grading-scale th {
            background-color: #90EE90;
        }
        
        .approval-banner {
            background-color: #28a745;
            color: white;
            padding: 15px 20px;
            margin-bottom: 20px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            gap: 15px;
            border: 3px solid #1e7e34;
        }
        
        .approval-icon {
            font-size: 32px;
        }
        
        .approval-details {
            flex: 1;
        }
        
        .approval-title {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .approval-info {
            font-size: 13px;
            opacity: 0.95;
        }
        
        .no-print {
            background-color: #17a2b8;
            color: white;
            padding: 15px;
            text-align: center;
            margin-bottom: 20px;
            border-radius: 8px;
            font-weight: bold;
        }
        
        .print-button {
            background-color: #28a745;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            margin-right: 10px;
        }
        
        .close-button {
            background-color: #6c757d;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
        }
        
        @media print {
            body {
                background-color: white;
                padding: 0;
            }
            
            .report-card {
                box-shadow: none;
                padding: 20px;
            }
            
            .no-print {
                display: none;
            }
        }
    </style>
</head>
<body>
    <div class="no-print" style="text-align: center;">
        <button class="print-button" onclick="window.print()">🖨️ Print Report Card</button>
        <button class="close-button" onclick="window.close()">✖ Close</button>
    </div>
    
    <div class="report-card" id="reportContent">
        <!-- Content will be loaded via JavaScript -->
        <div style="text-align: center; padding: 40px; color: #667eea;">
            <i class="fas fa-spinner fa-spin" style="font-size: 48px; margin-bottom: 20px;"></i>
            <div>Loading report data...</div>
        </div>
    </div>
    
    <script>
        const contextPath = '<%= request.getContextPath() %>';
        const penNumber = '<%= penNumber %>';
        const studentName = '<%= studentName %>';
        const studentClass = '<%= studentClass %>';
        const section = '<%= section %>';
        const schoolName = '<%= schoolName %>';
        const district = '<%= district %>';
        const udiseNo = '<%= udiseNo %>';
        const academicSession = '<%= academicSession %>';
        const currentDate = '<%= currentDate %>';
        
        // Load report data on page load
        document.addEventListener('DOMContentLoaded', function() {
            loadReportData();
        });
        
        function loadReportData() {
            Promise.all([
                fetch(contextPath + '/GetStudentComprehensiveDataServlet?penNumber=' + encodeURIComponent(penNumber)),
                fetch(contextPath + '/CheckReportApprovalStatusServlet?penNumber=' + encodeURIComponent(penNumber))
            ])
            .then(([reportResponse, approvalResponse]) => {
                return Promise.all([reportResponse.json(), approvalResponse.json()]);
            })
            .then(([reportData, approvalData]) => {
                renderReport(reportData, approvalData);
            })
            .catch(error => {
                console.error('Error:', error);
                document.getElementById('reportContent').innerHTML = `
                    <div style="text-align: center; padding: 40px; color: #dc3545;">
                        <h3>Error Loading Report</h3>
                        <p>\${error.message}</p>
                    </div>
                `;
            });
        }
        
        function renderReport(data, approvalData) {
            const container = document.getElementById('reportContent');
            
            let html = `
                <!-- Header Section -->
                <div class="header">
                    <div class="logo">🏫</div>
                    <div class="header-center">
                        <h1>\${schoolName}</h1>
                        <p>UDISE No: \${udiseNo} | District: \${district}</p>
                    </div>
                    <div class="logo">🎓</div>
                </div>
                
                <!-- Report Title -->
                <div class="report-title">सर्वसमावेशक विद्यार्थी प्रगती अहवाल</div>
                
                <!-- Class and Session -->
                <div class="class-session">
                    <div class="class-info">वर्ग: \${studentClass}\${section ? ' | Section: ' + section : ''}</div>
                    <div class="session-info">शैक्षणिक सत्र: \${academicSession}</div>
                </div>
                
                <!-- Student Information -->
                <div class="student-info">
                    <div class="label">विद्यार्थ्याचे नाव</div>
                    <div>: \${studentName}</div>
                    <div class="label">पेन नंबर</div>
                    <div>: \${penNumber}</div>
                </div>
            `;
            
            // Assessment Levels
            if (data.assessmentLevels) {
                // Collect teacher per subject from activities
                const teacherByLang = {};
                if (data.allActivities) {
                    data.allActivities.forEach(a => {
                        if (a.assignedBy) teacherByLang[a.language] = a.assignedBy;
                    });
                }
                const engTeacher  = teacherByLang['English']  || teacherByLang['english']  || '';
                const marTeacher  = teacherByLang['Marathi']  || teacherByLang['marathi']  || '';
                const mathTeacher = teacherByLang['Math']     || teacherByLang['math']     || '';

                html += `
                    <div class="section-title">📊 विषयनिहाय शिक्षण मूल्यांकन</div>
                    <div class="assessment-section">
                        <div class="assessment-grid">
                            <div class="assessment-box">
                                <div class="assessment-label">इंग्रजी (English)</div>
                                \${engTeacher ? `<div class="assessment-teacher">🧑‍🏫 \${engTeacher}</div>` : ''}
                                <div class="assessment-value level-\${data.assessmentLevels.englishLevelNum}">\${data.assessmentLevels.english}</div>
                            </div>
                            <div class="assessment-box">
                                <div class="assessment-label">मराठी</div>
                                \${marTeacher ? `<div class="assessment-teacher">🧑‍🏫 \${marTeacher}</div>` : ''}
                                <div class="assessment-value level-\${data.assessmentLevels.marathiLevelNum}">\${data.assessmentLevels.marathi}</div>
                            </div>
                            <div class="assessment-box">
                                <div class="assessment-label">गणित</div>
                                \${mathTeacher ? `<div class="assessment-teacher">🧑‍🏫 \${mathTeacher}</div>` : ''}
                                <div class="assessment-value level-\${data.assessmentLevels.mathLevelNum}">\${data.assessmentLevels.math}</div>
                            </div>
                        </div>
                    </div>
                    <div class="overall-progress">⭐ एकूण प्रगती: \${data.assessmentLevels.overall || 'Assessment in progress'}</div>
                `;
            }
            
            // Activities Summary
            if (data.allActivities && data.allActivities.length > 0) {
                const totalActivities = data.allActivities.length;

                // Count per subject for summary bar
                const subjectCount = {};
                data.allActivities.forEach(a => {
                    subjectCount[a.language] = (subjectCount[a.language] || 0) + 1;
                });
                let subjectSummary = Object.keys(subjectCount).map(s =>
                    `<span><span class="sv">\${subjectCount[s]}</span> \${s}</span>`
                ).join('<span style="color:#999"> | </span>');

                html += `
                    <div class="summary-bar">
                        <span><span class="sv">\${totalActivities}</span> एकूण उपक्रम</span>
                        <span style="color:#999"> | </span>
                        \${subjectSummary}
                    </div>
                `;

                // Group by language → unique activityText → count; also track teacher per subject
                const bySubject = {};
                const teacherPerSubject = {};
                data.allActivities.forEach(a => {
                    if (!bySubject[a.language]) bySubject[a.language] = {};
                    const txt = a.activityText || 'N/A';
                    bySubject[a.language][txt] = (bySubject[a.language][txt] || 0) + 1;
                    if (a.assignedBy) teacherPerSubject[a.language] = a.assignedBy;
                });

                html += `
                    <div class="section-title">📚 तपशीलवार क्रियाकलापांचा रेकॉर्ड</div>
                    <table class="activities-table">
                        <thead>
                            <tr>
                                <th style="width:14%;">विषय</th>
                                <th style="width:72%;">क्रियाकलाप वर्णन</th>
                                <th style="width:14%;">संख्या</th>
                            </tr>
                        </thead>
                        <tbody>
                `;

                Object.keys(bySubject).sort().forEach(lang => {
                    const activities = Object.entries(bySubject[lang]);
                    const teacher = teacherPerSubject[lang] || '';
                    activities.forEach(([ txt, cnt ], idx) => {
                        if (idx === 0) {
                            html += `
                                <tr>
                                    <td class="subject-cell" rowspan="\${activities.length}">
                                        \${lang}
                                        \${teacher ? `<div style="font-size:9px;font-weight:normal;color:#555;margin-top:3px;font-style:italic;">🧑‍🏫 \${teacher}</div>` : ''}
                                    </td>
                                    <td>\${txt}</td>
                                    <td class="count-cell">\${cnt}</td>
                                </tr>
                            `;
                        } else {
                            html += `
                                <tr>
                                    <td>\${txt}</td>
                                    <td class="count-cell">\${cnt}</td>
                                </tr>
                            `;
                        }
                    });
                });

                html += `
                        </tbody>
                    </table>
                `;
            }
            
            // Palak Melava
            if (data.palakMelavaData && data.palakMelavaData.length > 0) {
                html += `
                    <div class="section-title">👨‍👩‍👧‍👦 पालक-शिक्षक बैठका</div>
                    <div class="palak-melava-section">
                        <div class="palak-melava-header">पालकांच्या सहभागाच्या क्रियाकलापांची नोंद &nbsp;|&nbsp; एकूण बैठका: \${data.palakMelavaData.length}</div>
                        <div class="palak-melava-content">
                            <table class="meeting-table">
                                <thead>
                                    <tr>
                                        <th style="width:6%;">#</th>
                                        <th style="width:20%;">बैठकीची तारीख</th>
                                        <th style="width:14%;">उपस्थित पालक</th>
                                        <th>प्रमुख पाहुणे / उपस्थित</th>
                                    </tr>
                                </thead>
                                <tbody>
                `;
                data.palakMelavaData.forEach((melava, index) => {
                    html += `
                        <tr>
                            <td style="text-align:center;">\${index + 1}</td>
                            <td>\${melava.meetingDate || 'N/A'}</td>
                            <td style="text-align:center;">\${melava.totalParentsAttended || 'N/A'}</td>
                            <td>\${melava.chiefAttendeeInfo || 'N/A'}</td>
                        </tr>
                    `;
                });
                html += `
                                </tbody>
                            </table>
                        </div>
                    </div>
                `;
            }
            
            // Teacher's Remarks
            html += `
                <div class="remarks-section">
                    <div class="remarks-header">वर्ग शिक्षकांचे टिप्पण्या आणि निरीक्षणे</div>
                    <div class="remarks-content">
                        \${data.teacherRemarks || 'Remarks will be added by class teacher.'}
                    </div>
                </div>
            `;
            
            // Signatures
            html += `
                <div class="signatures">
                    <div class="date-box">
                        <div style="font-weight: bold; font-size: 14px; color: #666;">अहवाल तारीख</div>
                        <div class="date-large">\${currentDate}</div>
                    </div>
                    <div>
                        <div style="margin-bottom: 40px;"></div>
                        <div class="signature-label">वर्ग शिक्षकाची स्वाक्षरी</div>
                    </div>
                    <div>
                        <div style="margin-bottom: 40px;"></div>
                        <div class="signature-label">मुख्याध्यापकांची सही</div>
                    </div>
                </div>
            `;
            
            // Grading Information
            // Compact grading legend (one line)
            html += `
                <div style="margin-top:6px; padding:4px 10px; background:#f8f9fa; border:1px solid #ddd; font-size:10px; color:#555; text-align:center;">
                    📖 स्तर: <span style="color:#dc3545;">●Level 1 सुरुवात</span> &nbsp;
                    <span style="color:#fd7e14;">●Level 2 विकसित</span> &nbsp;
                    <span style="color:#ffc107;">●Level 3 प्रवीण</span> &nbsp;
                    <span style="color:#28a745;">●Level 4 प्रगत</span> &nbsp;
                    <span style="color:#007bff;">●Level 5 तज्ज्ञ</span>
                </div>
            `;
            
            container.innerHTML = html;
        }
        
        function getLevelClass(level) {
            if (!level || level === 'Not Assessed') return '';
            const levelNum = level.replace('Level ', '');
            return 'level-' + levelNum;
        }
    </script>
</body>
</html>
