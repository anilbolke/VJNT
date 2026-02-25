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
            padding: 12px;
            font-weight: bold;
            font-size: 16px;
            margin-top: 25px;
            border-radius: 4px;
        }
        
        .assessment-section {
            border: 2px solid #000;
            margin-top: 20px;
        }
        
        .assessment-header {
            background-color: #90EE90;
            padding: 10px;
            font-weight: bold;
            text-align: center;
            border-bottom: 2px solid #000;
            font-size: 15px;
        }
        
        .assessment-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 0;
        }
        
        .assessment-box {
            border-right: 1px solid #000;
            border-bottom: 1px solid #000;
            padding: 20px;
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
            font-size: 12px;
            color: #666;
            margin-bottom: 8px;
            font-weight: 600;
        }
        
        .assessment-value {
            font-size: 14px;
            font-weight: bold;
            color: #333;
            line-height: 1.4;
        }
        
        .assessment-value.level-1 { color: #dc3545; }
        .assessment-value.level-2 { color: #fd7e14; }
        .assessment-value.level-3 { color: #ffc107; }
        .assessment-value.level-4 { color: #28a745; }
        .assessment-value.level-5 { color: #007bff; }
        
        .overall-progress {
            background-color: #e7f3ff;
            padding: 15px;
            text-align: center;
            font-size: 16px;
            font-weight: bold;
            color: #004085;
            border: 2px solid #007bff;
            margin-top: 15px;
        }
        
        .activities-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            border: 2px solid #000;
        }
        
        .activities-table th {
            background-color: #90EE90;
            border: 1px solid #000;
            padding: 10px;
            text-align: center;
            font-weight: bold;
            font-size: 13px;
        }
        
        .activities-table td {
            border: 1px solid #000;
            padding: 8px;
            font-size: 12px;
        }
        
        .activities-table .week-header {
            background-color: #f0f0f0;
            font-weight: bold;
            text-align: center;
        }
        
        .summary-stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-top: 20px;
        }
        
        .stat-card {
            border: 2px solid #000;
            padding: 20px;
            text-align: center;
            border-radius: 8px;
        }
        
        .stat-card.total {
            background-color: #e7f3ff;
            border-color: #007bff;
        }
        
        .stat-card.completed {
            background-color: #d4edda;
            border-color: #28a745;
        }
        
        .stat-card.completion {
            background-color: #fff3cd;
            border-color: #ffc107;
        }
        
        .stat-value {
            font-size: 36px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 13px;
            color: #666;
            font-weight: bold;
        }
        
        .palak-melava-section {
            margin-top: 20px;
            border: 2px solid #000;
        }
        
        .palak-melava-header {
            background-color: #90EE90;
            padding: 10px;
            font-weight: bold;
            text-align: center;
            border-bottom: 2px solid #000;
        }
        
        .palak-melava-content {
            padding: 15px;
        }
        
        .meeting-card {
            background-color: #f8f9fa;
            border: 2px solid #667eea;
            border-left: 6px solid #667eea;
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 4px;
        }
        
        .meeting-card h4 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 15px;
        }
        
        .meeting-details {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 10px;
            margin-top: 10px;
            font-size: 12px;
        }
        
        .meeting-details strong {
            color: #333;
        }
        
        .remarks-section {
            margin-top: 25px;
            border: 2px solid #000;
        }
        
        .remarks-header {
            background-color: #f0f0f0;
            padding: 12px;
            font-weight: bold;
            border-bottom: 2px solid #000;
            text-align: center;
        }
        
        .remarks-content {
            padding: 15px;
            min-height: 80px;
            font-size: 13px;
            line-height: 1.6;
        }
        
        .signatures {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            border: 2px solid #000;
            border-top: none;
        }
        
        .signatures > div {
            padding: 20px;
            border-right: 2px solid #000;
            text-align: center;
            min-height: 100px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }
        
        .signatures > div:last-child {
            border-right: none;
        }
        
        .signature-label {
            font-weight: bold;
            font-size: 13px;
            margin-top: auto;
        }
        
        .date-box {
            text-align: center;
        }
        
        .date-large {
            font-size: 24px;
            font-weight: bold;
            margin: 15px 0;
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
            
            // Approval Banner
            if (approvalData && approvalData.status === 'APPROVED') {
                html += `
                    <div class="approval-banner">
                        <div class="approval-icon">✓</div>
                        <div class="approval-details">
                            <div class="approval-title">मुख्याध्यापकांनी मंजूर केलेला अहवाल</div>
                            <div class="approval-info">मंजुरी तपशील: #\${approvalData.approvalId} | मंजूर तारीख: \${approvalData.approvedDate || 'N/A'} |व्युत्पन्न तारीख: \${currentDate}</div>
                        </div>
                    </div>
                `;
            }
            
            // Assessment Levels
            if (data.assessmentLevels) {
                html += `
                    <div class="section-title">📊 मूल्यांकन स्तर</div>
                    <div class="assessment-section">
                        <div class="assessment-header">विषयनिहाय शिक्षण मूल्यांकन</div>
                        <div class="assessment-grid">
                            <div class="assessment-box">
                                <div class="assessment-label">ENGLISH</div>
                                <div class="assessment-value level-\${data.assessmentLevels.englishLevelNum}">\${data.assessmentLevels.english}</div>
                            </div>
                            <div class="assessment-box">
                                <div class="assessment-label">मराठी</div>
                                <div class="assessment-value level-\${data.assessmentLevels.marathiLevelNum}">\${data.assessmentLevels.marathi}</div>
                            </div>
                            <div class="assessment-box">
                                <div class="assessment-label">गणित</div>
                                <div class="assessment-value level-\${data.assessmentLevels.mathLevelNum}">\${data.assessmentLevels.math}</div>
                            </div>
                        </div>
                    </div>
                    <div class="overall-progress">
                        ⭐ एकूण प्रगती: \${data.assessmentLevels.overall || 'Assessment in progress'}
                    </div>
                `;
            }
            
            // Activities Summary
            if (data.allActivities && data.allActivities.length > 0) {
                const totalActivities = data.allActivities.length;
                const completedActivities = data.allActivities.filter(a => a.completed).length;
                const completionRate = Math.round((completedActivities / totalActivities) * 100);
                
                html += `
                    <div class="section-title">📝 क्रियाकलाप पूर्ण सारांश</div>
                    <div class="summary-stats">
                        <div class="stat-card total">
                            <div class="stat-value" style="color: #007bff;">\${totalActivities}</div>
                            <div class="stat-label">एकूण उपक्रम</div>
                        </div>
                    </div>
                `;
                
                // Activities Table
                html += `
                    <div class="section-title">📚 तपशीलवार क्रियाकलापांचा रेकॉर्ड</div>
                    <table class="activities-table">
                        <thead>
                            <tr>
                                <th style="width: 12%;">विषय</th>
                                <th style="width: 8%;">आठवडा</th>
                                <th style="width: 8%;">दिवस</th>
                                <th style="width: 52%;">क्रियाकलाप वर्णन</th>
                                <th style="width: 20%;">शिक्षकाचे नाव</th>
                            </tr>
                        </thead>
                        <tbody>
                `;
                
                // Group activities by language and week
                const grouped = {};
                data.allActivities.forEach(activity => {
                    const key = activity.language + '-Week' + activity.weekNumber;
                    if (!grouped[key]) {
                        grouped[key] = {
                            language: activity.language,
                            week: activity.weekNumber,
                            activities: []
                        };
                    }
                    grouped[key].activities.push(activity);
                });
                
                // Render grouped activities
                Object.keys(grouped).sort().forEach(key => {
                    const group = grouped[key];
                    html += `
                        <tr class="week-header">
                            <td colspan="5">\${group.language.toUpperCase()} - Week \${group.week}</td>
                        </tr>
                    `;
                    
                    group.activities.sort((a, b) => a.dayNumber - b.dayNumber).forEach(activity => {
                        html += `
                            <tr>
                                <td>\${activity.language}</td>
                                <td>\${activity.weekNumber}</td>
                                <td>\${activity.dayNumber}</td>
                                <td>\${activity.activityText || 'N/A'}</td>
                                <td>\${activity.assignedBy || 'N/A'}</td>
                            </tr>
                        `;
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
                    <div class="section-title">👨‍👩‍👧‍👦 पालक-शिक्षक बैठका (PALAK MELAVA)</div>
                    <div class="palak-melava-section">
                        <div class="palak-melava-header">पालकांच्या सहभागाच्या क्रियाकलापांची नोंद</div>
                        <div class="palak-melava-content">
                            <p style="margin-bottom: 15px; font-weight: bold; color: #666;">एकूण आयोजित बैठका: \${data.palakMelavaData.length}</p>
                `;
                
                data.palakMelavaData.forEach((melava, index) => {
                    html += `
                        <div class="meeting-card">
                            <h4>📅 Meeting #\${index + 1}</h4>
                            <div class="meeting-details">
                                <div><strong>बैठकीची तारीख:</strong> \${melava.meetingDate || 'N/A'}</div>
                                <div><strong>पालक उपस्थित होते:</strong> \${melava.totalParentsAttended || 'N/A'}</div>
                                <div style="grid-column: span 2;">
                                    <strong>प्रमुख पाहुणे/उपस्थित:</strong><br>
                                    \${melava.chiefAttendeeInfo || 'N/A'}
                                </div>
                            </div>
                        </div>
                    `;
                });
                
                html += `
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
            html += `
                <div class="grading-info">
                    <h3>📖 मूल्यांकन पातळी माहिती</h3>
                    <table class="grading-scale">
                        <thead>
                            <tr>
                                <th>Level</th>
                                <th>Level 1</th>
                                <th>Level 2</th>
                                <th>Level 3</th>
                                <th>Level 4</th>
                                <th>Level 5</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>Description</td>
                                <td>Beginning</td>
                                <td>Developing</td>
                                <td>Proficient</td>
                                <td>Advanced</td>
                                <td>Expert</td>
                            </tr>
                        </tbody>
                    </table>
                    
                    <div style="margin-top: 20px; padding: 15px; background: white; border: 2px solid #667eea; border-radius: 6px;">
                        <p style="font-size: 12px; line-height: 1.8; color: #333;">
                            <strong>Important Notes:</strong><br>
                            • This comprehensive report reflects the student's performance throughout the academic year<br>
                            • Activities mentioned are part of the daily learning curriculum as per VJNT Class Management System<br>
                            • Parent-Teacher meetings provide valuable insights for collaborative student development<br>
                            • For any queries regarding this report, please contact the class teacher or Head Master<br>
                            • This is an official document approved by the Head Master and should be preserved carefully
                        </p>
                    </div>
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
