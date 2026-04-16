<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.PhaseApprovalDAO" %>
<%@ page import="com.vjnt.model.Student" %>
<%@ page import="com.vjnt.model.PhaseApproval" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.HEAD_MASTER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    boolean isCoordinator = user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR);
    
    StudentDAO studentDAO = new StudentDAO();
    
    // Pagination parameters
    int currentPage = 1;
    int pageSize = 10;
    String pageParam = request.getParameter("page");
    if (pageParam != null) {
        try {
            currentPage = Integer.parseInt(pageParam);
        } catch (NumberFormatException e) {
            currentPage = 1;
        }
    }
    
    // Get statistics for this school (UDISE)
    String udiseNo = user.getUdiseNo();
    List<com.vjnt.model.Student> allStudents = studentDAO.getStudentsByUdise(udiseNo);
    int totalStudents = studentDAO.getStudentCountByUdise(udiseNo);
    int totalPages = (int) Math.ceil((double) totalStudents / pageSize);
    
    // Get paginated students
    List<com.vjnt.model.Student> students = studentDAO.getStudentsByUdiseWithPagination(udiseNo, currentPage, pageSize);
    
    // Declare phase variables at top level so they're accessible throughout the JSP
    int selectedPhase = 1;
    boolean currentPhaseComplete = false;
    boolean isReadOnly = false;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Students - VJNT</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 15px;
        }
        
        .container {
            max-width: 1600px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            padding: 20px;
        }
        
        .header {
            background: #f0f2f5;
            color: #000;
            padding: 15px 25px;
            border-radius: 10px;
            margin-bottom: 15px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            font-size: 24px;
            margin-bottom: 3px;
            color: #000;
        }
        
        .header p {
            opacity: 1;
            font-size: 13px;
            color: #000;
        }
        
        .breadcrumb {
            background: #f8f9fa;
            padding: 10px 15px;
            border-radius: 8px;
            margin-bottom: 15px;
            font-size: 13px;
            color: #666;
        }
        
        .breadcrumb strong {
            color: #333;
        }
        
        .section {
            background: white;
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 15px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        .section-title {
            font-size: 22px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #43e97b;
        }
        
        .btn {
            padding: 10px 20px;
            border-radius: 5px;
            text-decoration: none;
            font-weight: 500;
            transition: all 0.3s;
            display: inline-block;
            cursor: pointer;
            border: none;
        }
        
        .btn-back {
            background: #6c757d;
            color: white;
        }
        
        .btn-back:hover {
            background: #5a6268;
            transform: translateY(-2px);
        }
        
        .btn-save {
            background: #28a745;
            color: white;
            padding: 6px 12px;
            font-size: 12px;
        }
        
        .btn-save:hover {
            background: #218838;
        }
        
        .table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
            table-layout: fixed;
        }
        
        .table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .table th,
        .table td {
            padding: 6px 8px;
            text-align: left;
            border-bottom: 1px solid #dee2e6;
            font-size: 12px;
        }
        
        .table th {
            font-size: 11px;
            font-weight: 600;
        }
        
        .table th:nth-child(1), .table td:nth-child(1) { width: 8%; } /* PEN */
        .table th:nth-child(2), .table td:nth-child(2) { width: 15%; } /* Name */
        .table th:nth-child(3), .table td:nth-child(3) { width: 6%; } /* Class */
        .table th:nth-child(4), .table td:nth-child(4) { width: 6%; } /* Section */
        .table th:nth-child(5), .table td:nth-child(5) { width: 21%; } /* Marathi */
        .table th:nth-child(6), .table td:nth-child(6) { width: 21%; } /* Math */
        .table th:nth-child(7), .table td:nth-child(7) { width: 16%; } /* English */
        .table th:nth-child(8), .table td:nth-child(8) { width: 12%; text-align: center; } /* Action */
        
        .table tbody tr:hover {
            background: #f8f9fa;
        }
        
        .level-select {
            width: 100%;
            padding: 5px 8px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 12px;
        }
        
        .level-select:focus {
            outline: none;
            border-color: #43e97b;
        }
        
        .pagination {
            display: flex;
            justify-content: center;
            gap: 10px;
            margin-top: 25px;
            flex-wrap: wrap;
        }
        
        .pagination a,
        .pagination span {
            padding: 8px 12px;
            border-radius: 5px;
            text-decoration: none;
            color: #667eea;
            background: #f8f9fa;
        }
        
        .pagination a:hover {
            background: #43e97b;
            color: white;
        }
        
        .pagination .active {
            background: #667eea;
            color: white;
        }
        
        .pagination .disabled {
            color: #ccc;
            cursor: not-allowed;
        }
        
        .phase-selector {
            background: #f8f9fa;
            padding: 12px 15px;
            border-radius: 8px;
            margin-bottom: 12px;
        }
        
        .phase-status {
            display: flex;
            gap: 8px;
            margin-top: 10px;
            flex-wrap: wrap;
        }
        
        .phase-badge {
            padding: 4px 10px;
            border-radius: 15px;
            font-size: 11px;
        }
        
        .phase-complete {
            background: #4caf50;
            color: white;
        }
        
        .phase-progress {
            background: #fff3e0;
            color: #f57c00;
        }
        
        .phase-locked {
            background: #e0e0e0;
            color: #666;
        }
        
        .phase-rejected {
            background: #dc3545;
            color: white;
            font-weight: 600;
        }
        
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        
        .alert-success {
            background: #4caf50;
            color: white;
        }
        
        .alert-info {
            background: #2196f3;
            color: white;
        }
        
        .filter-container {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 15px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
        }
        
        .filter-group {
            display: flex;
            flex-direction: column;
        }
        
        .filter-group label {
            font-weight: 600;
            font-size: 12px;
            color: #333;
            margin-bottom: 5px;
        }
        
        .filter-group input {
            padding: 8px 12px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 13px;
            transition: border-color 0.3s;
        }
        
        .filter-group input:focus {
            outline: none;
            border-color: #43e97b;
        }
        
        .filter-actions {
            display: flex;
            gap: 10px;
            align-items: flex-end;
        }
        
        .filter-actions button {
            padding: 8px 15px;
            border-radius: 5px;
            border: none;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s;
            font-size: 12px;
        }
        
        .btn-filter-clear {
            background: #6c757d;
            color: white;
        }
        
        .btn-filter-clear:hover {
            background: #5a6268;
        }
        
        .filter-results {
            font-size: 12px;
            color: #666;
            padding: 10px 0;
            margin-bottom: 10px;
        }
        
        /* Save Indicator Styles */
        .save-indicator {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 4px 10px;
            background: #0d6efd;
            color: white;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
            animation: fadeIn 0.3s;
            white-space: nowrap;
        }
        
        .save-timestamp {
            font-size: 9px;
            color: #666;
            font-style: italic;
            white-space: nowrap;
        }
        
        .row-saved {
            background: linear-gradient(90deg, #e3f2fd 0%, #f0f8ff 100%) !important;
            border-left: 6px solid #0d6efd !important;
            transition: all 0.3s ease;
            box-shadow: 0 2px 4px rgba(13, 110, 253, 0.15) !important;
        }
        
        .row-saved:hover {
            background: linear-gradient(90deg, #bbdefb 0%, #e3f2fd 100%) !important;
            box-shadow: 0 3px 6px rgba(13, 110, 253, 0.25) !important;
        }
        
        .row-saved td {
            font-weight: 500;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-5px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .save-checkmark {
            display: inline-block;
            width: 16px;
            height: 16px;
            background: #28a745;
            border-radius: 50%;
            color: white;
            text-align: center;
            line-height: 16px;
            font-size: 10px;
            margin-left: 4px;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div>
                <h1>📋 विद्यार्थी यादी आणि भाषा स्तर व्यवस्थापन</h1>
                <p>Student List & Language Level Management</p>
            </div>
            <div>
                <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="btn btn-back">🏠 Back to Dashboard</a>
            </div>
        </div>
        
        <!-- Breadcrumb -->
        <div class="breadcrumb">
            <span>Division:</span> <strong><%= user.getDivisionName() %></strong> 
            <span style="margin: 0 10px;">→</span> 
            <span>District:</span> <strong><%= user.getDistrictName() %></strong>
            <span style="margin: 0 10px;">→</span>
            <span>School UDISE:</span> <strong><%= udiseNo %></strong>
            <span style="margin: 0 10px;">→</span>
            <span>Total Students:</span> <strong><%= totalStudents %></strong>
        </div>
        
        <!-- Main Content Section -->
        <div class="section">
            <% if (!isCoordinator) { %>
            <!-- Access Restricted Message for Head Master -->
            <div class="alert alert-info">
                <strong style="font-size: 18px;">🔒 Access Restricted</strong>
                <p style="margin: 10px 0 0 0; font-size: 15px;">This page is for <strong>School Coordinators</strong> only. As a Head Master, you can view and approve phase submissions from the Phase Approvals page.</p>
                <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="btn btn-back" style="margin-top: 15px; display: inline-block;">🏠 Return to Dashboard</a>
            </div>
            <% } else { %>
            <%
            // Check phase completion status
            StudentDAO phaseDAO = new StudentDAO();
            boolean phase1Complete = phaseDAO.isPhaseComplete(udiseNo, 1);
            boolean phase2Complete = phaseDAO.isPhaseComplete(udiseNo, 2);
            boolean phase3Complete = phaseDAO.isPhaseComplete(udiseNo, 3);
            boolean phase4Complete = phaseDAO.isPhaseComplete(udiseNo, 4);
            
            // Check phase approval status from principal
            PhaseApprovalDAO approvalDAO = new PhaseApprovalDAO();
            PhaseApproval phase1Approval = approvalDAO.getPhaseApproval(udiseNo, 1);
            PhaseApproval phase2Approval = approvalDAO.getPhaseApproval(udiseNo, 2);
            PhaseApproval phase3Approval = approvalDAO.getPhaseApproval(udiseNo, 3);
            PhaseApproval phase4Approval = approvalDAO.getPhaseApproval(udiseNo, 4);
            
            // Check if phases are approved by principal
            boolean phase1Approved = phase1Approval != null && phase1Approval.isApproved();
            boolean phase2Approved = phase2Approval != null && phase2Approval.isApproved();
            boolean phase3Approved = phase3Approval != null && phase3Approval.isApproved();
            boolean phase4Approved = phase4Approval != null && phase4Approval.isApproved();
            
            // Check if phases are rejected by headmaster
            boolean phase1Rejected = phase1Approval != null && phase1Approval.isRejected();
            boolean phase2Rejected = phase2Approval != null && phase2Approval.isRejected();
            boolean phase3Rejected = phase3Approval != null && phase3Approval.isRejected();
            boolean phase4Rejected = phase4Approval != null && phase4Approval.isRejected();
            
            // Get current selected phase from request parameter (default to Phase 1)
            String selectedPhaseStr = request.getParameter("phase");
            if (selectedPhaseStr != null) {
                try {
                    selectedPhase = Integer.parseInt(selectedPhaseStr);
                } catch (NumberFormatException e) {
                    selectedPhase = 1;
                }
            }
            
            // Check if current selected phase is complete
            switch(selectedPhase) {
                case 1: currentPhaseComplete = phase1Complete; break;
                case 2: currentPhaseComplete = phase2Complete; break;
                case 3: currentPhaseComplete = phase3Complete; break;
                case 4: currentPhaseComplete = phase4Complete; break;
            }
            
            // Check if current phase is rejected
            boolean currentPhaseRejected = false;
            switch(selectedPhase) {
                case 1: currentPhaseRejected = phase1Rejected; break;
                case 2: currentPhaseRejected = phase2Rejected; break;
                case 3: currentPhaseRejected = phase3Rejected; break;
                case 4: currentPhaseRejected = phase4Rejected; break;
            }
            
            // Phase is read-only ONLY if complete AND approved (not if rejected)
            // If rejected, coordinator can edit and resubmit
            isReadOnly = currentPhaseComplete && !currentPhaseRejected;
            %>
            
            <!-- Phase Selection -->
            <div class="phase-selector">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <label style="font-weight: 600; font-size: 16px; color: #333; margin-right: 15px;">
                            📊 Select Phase (चरण निवडा):
                        </label>
                        <select id="phaseSelector" onchange="changePhase()" style="padding: 10px 15px; border: 2px solid #43e97b; border-radius: 5px; font-size: 14px; font-weight: 500; min-width: 150px;">
                            <option value="1" <%= selectedPhase == 1 ? "selected" : "" %> <%= (phase1Complete && !phase1Rejected) ? "disabled" : "" %>>Phase 1 <%= phase1Rejected ? "❌ Rejected - Edit & Resubmit" : (phase1Complete ? "✓ Completed" : "") %></option>
                            <option value="2" <%= selectedPhase == 2 ? "selected" : "" %> <%= (!phase1Approved || (phase2Complete && !phase2Rejected)) ? "disabled" : "" %>>Phase 2 <%= phase2Rejected ? "❌ Rejected - Edit & Resubmit" : (phase2Complete ? "✓ Completed" : (!phase1Approved ? "🔒 Awaiting Approval" : "")) %></option>
                            <option value="3" <%= selectedPhase == 3 ? "selected" : "" %> <%= (!phase2Approved || (phase3Complete && !phase3Rejected)) ? "disabled" : "" %>>Phase 3 <%= phase3Rejected ? "❌ Rejected - Edit & Resubmit" : (phase3Complete ? "✓ Completed" : (!phase2Approved ? "🔒 Awaiting Approval" : "")) %></option>
                            <option value="4" <%= selectedPhase == 4 ? "selected" : "" %> <%= (!phase3Approved || (phase4Complete && !phase4Rejected)) ? "disabled" : "" %>>Phase 4 <%= phase4Rejected ? "❌ Rejected - Edit & Resubmit" : (phase4Complete ? "✓ Completed" : (!phase3Approved ? "🔒 Awaiting Approval" : "")) %></option>
                        </select>
                    </div>
                    <div>
                        <span style="font-size: 14px; color: #666;">
                            Current Phase: <strong style="color: #43e97b;">Phase <%= selectedPhase %></strong>
                        </span>
                    </div>
                </div>
                
                <!-- Phase Status Indicators -->
                <div class="phase-status">
                    <span class="phase-badge <%= phase1Rejected ? "phase-rejected" : (phase1Complete ? "phase-complete" : "phase-progress") %>">
                        Phase 1: <%= phase1Rejected ? "❌ Rejected" : (phase1Complete ? "✓ Complete" : "⏳ In Progress") %>
                    </span>
                    <span class="phase-badge <%= phase2Rejected ? "phase-rejected" : (phase2Complete ? "phase-complete" : (phase1Approved ? "phase-progress" : "phase-locked")) %>">
                        Phase 2: <%= phase2Rejected ? "❌ Rejected" : (phase2Complete ? "✓ Complete" : (phase1Approved ? "⏳ Available" : "🔒 Awaiting P1 Approval")) %>
                    </span>
                    <span class="phase-badge <%= phase3Rejected ? "phase-rejected" : (phase3Complete ? "phase-complete" : (phase2Approved ? "phase-progress" : "phase-locked")) %>">
                        Phase 3: <%= phase3Rejected ? "❌ Rejected" : (phase3Complete ? "✓ Complete" : (phase2Approved ? "⏳ Available" : "🔒 Awaiting P2 Approval")) %>
                    </span>
                    <span class="phase-badge <%= phase4Rejected ? "phase-rejected" : (phase4Complete ? "phase-complete" : (phase3Approved ? "phase-progress" : "phase-locked")) %>">
                        Phase 4: <%= phase4Rejected ? "❌ Rejected" : (phase4Complete ? "✓ Complete" : (phase3Approved ? "⏳ Available" : "🔒 Awaiting P3 Approval")) %>
                    </span>
                </div>
            </div>
            
            <% if (currentPhaseRejected) { 
                PhaseApproval currentApproval = approvalDAO.getPhaseApproval(udiseNo, selectedPhase);
            %>
            <!-- Phase Rejected Notification -->
            <div class="alert" style="background: #dc3545; color: white; border-left: 4px solid #a02622;">
                <strong style="font-size: 18px;">❌ Phase <%= selectedPhase %> Rejected by Headmaster</strong>
                <p style="margin: 10px 0 5px 0; font-size: 14px;">
                    <strong>Rejection Remarks:</strong> <%= currentApproval != null && currentApproval.getApprovalRemarks() != null ? currentApproval.getApprovalRemarks() : "No remarks provided" %>
                </p>
                <p style="margin: 5px 0 0 0; font-size: 14px; background: rgba(255,255,255,0.2); padding: 10px; border-radius: 5px;">
                    ⚠️ <strong>Action Required:</strong> You can now edit the student levels below based on the headmaster's feedback. After making corrections, save the changes and re-submit for approval.
                </p>
                <p style="margin: 10px 0 0 0; font-size: 13px; background: rgba(255,255,255,0.15); padding: 8px; border-radius: 5px;">
                    ✏️ <strong>Editing Enabled:</strong> All student level dropdowns are now unlocked. Make your changes, click "Save" for each student, then submit the phase again when ready.
                </p>
            </div>
            <% } else if (currentPhaseComplete) { %>
            <!-- Phase Complete Notification -->
            <div class="alert alert-success">
                <strong style="font-size: 16px;">✓ Phase <%= selectedPhase %> Completed!</strong>
                <p style="margin: 5px 0 0 0;">All students have been assigned language levels for this phase. Data is now read-only.</p>
            </div>
            <% } %>
            
            <% 
            // Show approval pending message if next phase is locked
            boolean showApprovalMessage = false;
            String pendingPhaseMsg = "";
            if (selectedPhase == 1 && phase1Complete && !phase1Approved) {
                showApprovalMessage = true;
                pendingPhaseMsg = "Phase 1 completion is awaiting Principal/Head Master approval before Phase 2 can be started.";
            } else if (selectedPhase == 2 && phase2Complete && !phase2Approved) {
                showApprovalMessage = true;
                pendingPhaseMsg = "Phase 2 completion is awaiting Principal/Head Master approval before Phase 3 can be started.";
            } else if (selectedPhase == 3 && phase3Complete && !phase3Approved) {
                showApprovalMessage = true;
                pendingPhaseMsg = "Phase 3 completion is awaiting Principal/Head Master approval before Phase 4 can be started.";
            }
            
            if (showApprovalMessage) { %>
            <!-- Approval Pending Notification -->
            <div class="alert alert-warning" style="background: #fff3cd; border-left: 4px solid #ffc107; color: #856404;">
                <strong style="font-size: 16px;">⏳ Awaiting Principal Approval</strong>
                <p style="margin: 5px 0 0 0;"><%= pendingPhaseMsg %></p>
            </div>
            <% } %>
            
            <% if (totalStudents == 0) { %>
            <!-- No Students Message -->
            <div class="alert alert-info">
                <strong>ℹ️ No Students Found</strong>
                <p style="margin: 5px 0 0 0;">No students are registered for UDISE <%= udiseNo %>. Please contact Data Admin to upload student data.</p>
            </div>
            <% } else { %>
            
            <!-- Filter Section -->
            <div class="filter-container">
                <div class="filter-group">
                    <label for="filterPEN">🔍 Filter by PEN:</label>
                    <input type="text" id="filterPEN" placeholder="Enter PEN..." onkeyup="applyFilters()">
                </div>
                <div class="filter-group">
                    <label for="filterName">🔍 Filter by Name:</label>
                    <input type="text" id="filterName" placeholder="Enter student name..." onkeyup="applyFilters()">
                </div>
                <div class="filter-group">
                    <label for="filterClass">🔍 Filter by Class:</label>
                    <select id="filterClass" onchange="applyFilters()" style="padding: 8px 12px; border: 2px solid #ddd; border-radius: 5px; font-size: 13px; transition: border-color 0.3s; width: 100%;">
                        <option value="">All Classes</option>
                        <option value="I">I</option>
                        <option value="II">II</option>
                        <option value="III">III</option>
                        <option value="IV">IV</option>
                        <option value="V">V</option>
                        <option value="VI">VI</option>
                        <option value="VII">VII</option>
                        <option value="VIII">VIII</option>
                        <option value="IX">IX</option>
                        <option value="X">X</option>
                        <option value="XI">XI</option>
                        <option value="XII">XII</option>
                    </select>
                </div>
                <div class="filter-group">
                    <label for="filterSection">🔍 Filter by Section:</label>
                    <input type="text" id="filterSection" placeholder="Enter section..." onkeyup="applyFilters()">
                </div>
                <div class="filter-actions">
                    <button class="btn-filter-clear" onclick="clearFilters()">🔄 Clear Filters</button>
                </div>
            </div>
            
            <div class="filter-results">
                <span id="filterResultCount">Showing all <%= totalStudents %> students</span>
                <span id="savedCounter" style="margin-left: 20px; padding: 4px 10px; background: #2196f3; color: white; border-radius: 12px; font-size: 11px; font-weight: 600; display: none;">
                    <span id="savedCount">0</span> student(s) saved in this session
                </span>
            </div>
            
            <p style="margin-bottom: 15px; color: #666; font-size: 14px;">
                Showing <%= (currentPage - 1) * pageSize + 1 %> to <%= Math.min(currentPage * pageSize, totalStudents) %> of <%= totalStudents %> students
                <% if (currentPhaseComplete) { %>
                <span style="color: #4caf50; font-weight: 600; margin-left: 10px;">● Phase <%= selectedPhase %> Complete</span>
                <% } %>
            </p>
            
            <!-- Student Table -->
            <div style="overflow-x: auto;">
                <table class="table">
                    <thead>
                        <tr>
                            <th style="vertical-align: middle;">PEN</th>
                            <th style="vertical-align: middle;">Name</th>
                            <th style="vertical-align: middle;">Class</th>
                            <th style="vertical-align: middle;">Section</th>
                            <th style="text-align: center; background: #5e3f0e;">मराठी भाषा स्तर</th>
                            <th style="text-align: center; background: #005695;">गणित स्तर</th>
                            <th style="text-align: center; background: #a901c1;">इंग्रजी स्तर</th>
                            <th style="vertical-align: middle;">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                        for (com.vjnt.model.Student s : students) {
                        %>
                        <tr id="row-<%= s.getStudentId() %>">
                            <td><%= s.getStudentPen() != null ? s.getStudentPen() : "N/A" %></td>
                            <td><strong><%= s.getStudentName() %></strong></td>
                            <td><%= s.getStudentClass() %></td>
                            <td><%= s.getSection() %></td>
                            <!-- Marathi Levels -->
                            <td>
                                <select name="marathi_akshara" class="level-select" <%= isReadOnly ? "disabled" : "" %>>
                                    <option value="0" <%= s.getMarathiAksharaLevel() == 0 ? "selected" : "" %>>स्थर निश्चित केला नाही</option>
                                    <option value="1" <%= s.getMarathiAksharaLevel() == 1 ? "selected" : "" %>>प्रारंभिक स्तर</option>
                                    <option value="2" <%= s.getMarathiAksharaLevel() == 2 ? "selected" : "" %>>अक्षर स्तर</option>
                                    <option value="3" <%= s.getMarathiAksharaLevel() == 3 ? "selected" : "" %>>शब्द स्तर</option>
                                    <option value="4" <%= s.getMarathiAksharaLevel() == 4 ? "selected" : "" %>>वाक्य स्तर</option>
                                    <option value="5" <%= s.getMarathiAksharaLevel() == 5 ? "selected" : "" %>>समजपूर्वक उतारा वाचन स्तर</option>
                                    <option value="6" <%= s.getMarathiAksharaLevel() == 6 ? "selected" : "" %>>मराठी वाचन व लेखन FLN स्तर 100% पूर्ण</option>
                                </select>
                            </td>
                            <!-- Math Levels -->
                            <td>
                                <select name="math_akshara" class="level-select" <%= isReadOnly ? "disabled" : "" %>>
                                    <option value="0" <%= s.getMathAksharaLevel() == 0 ? "selected" : "" %>>स्तर निश्चित केला नाही</option>
                                    <option value="1" <%= s.getMathAksharaLevel() == 1 ? "selected" : "" %>>प्रारंभिक स्तर</option>
                                    <option value="2" <%= s.getMathAksharaLevel() == 2 ? "selected" : "" %>>अंक ज्ञान स्तर</option>
                                    <option value="3" <%= s.getMathAksharaLevel() == 3 ? "selected" : "" %>>संख्याज्ञान स्तर</option>
                                    <option value="4" <%= s.getMathAksharaLevel() == 4 ? "selected" : "" %>>बेरीज स्तर</option>
                                    <option value="5" <%= s.getMathAksharaLevel() == 5 ? "selected" : "" %>>वजाबाकी स्तर</option>
                                    <option value="6" <%= s.getMathAksharaLevel() == 6 ? "selected" : "" %>>गुणाकार स्तर</option>
                                    <option value="7" <%= s.getMathAksharaLevel() == 7 ? "selected" : "" %>>भागाकार स्तर</option>
                                    <option value="8" <%= s.getMathAksharaLevel() == 8 ? "selected" : "" %>>गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण</option>
                                </select>
                            </td>
                            <!-- English Levels -->
                            <td>
                                <select name="english_akshara" class="level-select" <%= isReadOnly ? "disabled" : "" %>>
                                    <option value="0" <%= s.getEnglishAksharaLevel() == 0 ? "selected" : "" %>>स्तर निश्चित केला नाही</option>
                                    <option value="1" <%= s.getEnglishAksharaLevel() == 1 ? "selected" : "" %>>Beginner level</option>
                                    <option value="2" <%= s.getEnglishAksharaLevel() == 2 ? "selected" : "" %>>Alphabet level</option>
                                    <option value="3" <%= s.getEnglishAksharaLevel() == 3 ? "selected" : "" %>>Word level</option>
                                    <option value="4" <%= s.getEnglishAksharaLevel() == 4 ? "selected" : "" %>>Sentence level</option>
                                    <option value="5" <%= s.getEnglishAksharaLevel() == 5 ? "selected" : "" %>>Paragraph Reading with Understanding</option>
                                    <option value="6" <%= s.getEnglishAksharaLevel() == 6 ? "selected" : "" %>>English reading and writing FLN level 100% complete</option>
                                </select>
                            </td>
                            <td style="text-align: center;">
                                <% if (!isReadOnly) { %>
                                <div style="display: flex; align-items: center; justify-content: center; gap: 8px;">
                                    <button class="btn btn-save" onclick="saveStudent(<%= s.getStudentId() %>)">💾 Save</button>
                                    <div id="msg-<%= s.getStudentId() %>" style="font-size: 11px; font-weight: 600; display: inline-block;"></div>
                                </div>
                                <% } else { %>
                                <span style="color: #28a745;">✓ Complete</span>
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
            
            <!-- Pagination -->
            <% if (totalPages > 1) { %>
            <div class="pagination">
                <% if (currentPage > 1) { %>
                    <a href="?page=1&phase=<%= selectedPhase %>">First</a>
                    <a href="?page=<%= currentPage - 1 %>&phase=<%= selectedPhase %>">Previous</a>
                <% } else { %>
                    <span class="disabled">First</span>
                    <span class="disabled">Previous</span>
                <% } %>
                
                <% 
                int startPage = Math.max(1, currentPage - 2);
                int endPage = Math.min(totalPages, currentPage + 2);
                for (int i = startPage; i <= endPage; i++) {
                    if (i == currentPage) {
                %>
                    <span class="active"><%= i %></span>
                <% } else { %>
                    <a href="?page=<%= i %>&phase=<%= selectedPhase %>"><%= i %></a>
                <% 
                    }
                }
                %>
                
                <% if (currentPage < totalPages) { %>
                    <a href="?page=<%= currentPage + 1 %>&phase=<%= selectedPhase %>">Next</a>
                    <a href="?page=<%= totalPages %>&phase=<%= selectedPhase %>">Last</a>
                <% } else { %>
                    <span class="disabled">Next</span>
                    <span class="disabled">Last</span>
                <% } %>
            </div>
            <% } %>
            <% } %>
            <% } %>
        </div>
    </div>
    
    <script>
        // Restore save indicators on page load
        window.addEventListener('DOMContentLoaded', function() {
            restoreSaveIndicators();
            updateSavedCounter();
        });
        
        function restoreSaveIndicators() {
            // Check DATABASE for saved students (works across all systems/browsers)
            var phase = <%= selectedPhase %>;
            
            fetch('<%= request.getContextPath() %>/check-saved-students?phase=' + phase)
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.savedStudents) {
                        var savedStudentsMap = {};
                        
                        // Convert array to map for quick lookup
                        data.savedStudents.forEach(function(savedInfo) {
                            savedStudentsMap[savedInfo.studentId] = savedInfo;
                        });
                        
                        // Apply saved indicators to all matching rows
                        var rows = document.querySelectorAll('table tbody tr');
                        rows.forEach(function(row) {
                            var studentId = row.id.replace('row-', '');
                            var savedInfo = savedStudentsMap[studentId];
                            
                            if (savedInfo) {
                                // Apply saved row styling IMMEDIATELY
                                row.classList.add('row-saved');
                                
                                // Format saved date/time
                                var timeString = 'Previously saved';
                                if (savedInfo.savedDate) {
                                    var date = new Date(savedInfo.savedDate);
                                    timeString = date.toLocaleString('en-IN');
                                }
                                
                                // Restore the save indicator
                                var msgDiv = document.getElementById('msg-' + studentId);
                                if (msgDiv) {
                                    msgDiv.innerHTML = 
                                        '<div class="save-indicator" title="Last saved: ' + timeString + '">' +
                                            '<span>✓</span>' +
                                            '<span>Saved</span>' +
                                        '</div>';
                                }
                                
                                // Apply visual emphasis to make it clear this row was saved
                                var saveBtn = row.querySelector('.btn-save');
                                if (saveBtn) {
                                    saveBtn.innerHTML = '✓ Saved';
                                    saveBtn.style.background = '#0d6efd';
                                    saveBtn.style.cursor = 'default';
                                }
                            }
                        });
                        
                        // Update the counter
                        updateSavedCounter(data.savedStudents.length);
                    }
                })
                .catch(error => {
                    console.error('Error loading saved indicators:', error);
                });
        }
        
        function updateSavedCounter(savedCount) {
            // Update counter display with database count (works across all systems)
            if (savedCount === undefined) {
                // If called without parameter, fetch from database
                var phase = <%= selectedPhase %>;
                fetch('<%= request.getContextPath() %>/check-saved-students?phase=' + phase)
                    .then(response => response.json())
                    .then(data => {
                        if (data.success && data.savedStudents) {
                            updateSavedCounter(data.savedStudents.length);
                        }
                    });
                return;
            }
            
            // Update counter display
            var counterElement = document.getElementById('savedCounter');
            var countElement = document.getElementById('savedCount');
            
            if (savedCount > 0) {
                countElement.textContent = savedCount;
                counterElement.style.display = 'inline-block';
            } else {
                counterElement.style.display = 'none';
            }
        }
        
        // Load all students data into JavaScript for filtering
        var allStudentsData = [
            <% 
            for (int i = 0; i < allStudents.size(); i++) {
                com.vjnt.model.Student s = allStudents.get(i);
            %>
            {
                id: <%= s.getStudentId() %>,
                pen: '<%= s.getStudentPen() != null ? s.getStudentPen() : "N/A" %>',
                name: '<%= s.getStudentName().replace("'", "\\'") %>',
                studentClass: '<%= s.getStudentClass() %>',
                section: '<%= s.getSection() != null ? s.getSection() : "" %>',
                marathiLevel: <%= s.getMarathiAksharaLevel() %>,
                mathLevel: <%= s.getMathAksharaLevel() %>,
                englishLevel: <%= s.getEnglishAksharaLevel() %>
            }<%= i < allStudents.size() - 1 ? "," : "" %>
            <% } %>
        ];
        
        var isFiltering = false;
        var isReadOnly = <%= isReadOnly %>;
        
        function changePhase() {
            // Simply navigate to the selected phase
            // The dropdown options already have proper disable logic in the JSP
            // so this function will only be called for valid phase switches
            var phase = document.getElementById('phaseSelector').value;
            window.location.href = '?phase=' + phase;
        }
        
        function applyFilters() {
            var filterPEN = document.getElementById('filterPEN').value.toLowerCase();
            var filterName = document.getElementById('filterName').value.toLowerCase();
            var filterClass = document.getElementById('filterClass').value;
            var filterSection = document.getElementById('filterSection').value.toLowerCase();
            
            // Check if any filter is active
            var hasFilter = filterPEN !== '' || filterName !== '' || filterClass !== '' || filterSection !== '';
            
            if (!hasFilter) {
                // No filters - reload page to show pagination
                if (isFiltering) {
                    window.location.href = '?phase=<%= selectedPhase %>';
                }
                return;
            }
            
            isFiltering = true;
            
            // Filter all students data
            var filteredStudents = allStudentsData.filter(function(student) {
                var penMatch = student.pen.toLowerCase().includes(filterPEN) || filterPEN === '';
                var nameMatch = student.name.toLowerCase().includes(filterName) || filterName === '';
                // Exact match for class filter (comparing numbers as strings)
                var classMatch = (filterClass === '' || student.studentClass.toString() === filterClass);
                var sectionMatch = student.section.toLowerCase().includes(filterSection) || filterSection === '';
                
                return penMatch && nameMatch && classMatch && sectionMatch;
            });
            
            // Rebuild table with filtered results
            var tbody = document.querySelector('table tbody');
            tbody.innerHTML = '';
            
            filteredStudents.forEach(function(student) {
                var row = document.createElement('tr');
                row.id = 'row-' + student.id;
                
                row.innerHTML = 
                    '<td>' + student.pen + '</td>' +
                    '<td><strong>' + student.name + '</strong></td>' +
                    '<td>' + student.studentClass + '</td>' +
                    '<td>' + student.section + '</td>' +
                    '<td>' +
                        '<select name="marathi_akshara" class="level-select" ' + (isReadOnly ? 'disabled' : '') + '>' +
                            '<option value="0" ' + (student.marathiLevel == 0 ? 'selected' : '') + '>स्थर निश्चित केला नाही</option>' +
                            '<option value="1" ' + (student.marathiLevel == 1 ? 'selected' : '') + '>प्रारंभिक स्तर</option>' +
                            '<option value="2" ' + (student.marathiLevel == 2 ? 'selected' : '') + '>अक्षर स्तर</option>' +
                            '<option value="3" ' + (student.marathiLevel == 3 ? 'selected' : '') + '>शब्द स्तर</option>' +
                            '<option value="4" ' + (student.marathiLevel == 4 ? 'selected' : '') + '>वाक्य स्तर</option>' +
                            '<option value="5" ' + (student.marathiLevel == 5 ? 'selected' : '') + '>समजपूर्वक उतारा वाचन स्तर</option>' +
                            '<option value="6" ' + (student.marathiLevel == 6 ? 'selected' : '') + '>मराठी वाचन व लेखन FLN स्तर 100% पूर्ण</option>' +
                        '</select>' +
                    '</td>' +
                    '<td>' +
                        '<select name="math_akshara" class="level-select" ' + (isReadOnly ? 'disabled' : '') + '>' +
                            '<option value="0" ' + (student.mathLevel == 0 ? 'selected' : '') + '>स्तर निश्चित केला नाही</option>' +
                            '<option value="1" ' + (student.mathLevel == 1 ? 'selected' : '') + '>प्रारंभिक स्तर</option>' +
                            '<option value="2" ' + (student.mathLevel == 2 ? 'selected' : '') + '>अंक ज्ञान स्तर</option>' +
                            '<option value="3" ' + (student.mathLevel == 3 ? 'selected' : '') + '>संख्याज्ञान स्तर</option>' +
                            '<option value="4" ' + (student.mathLevel == 4 ? 'selected' : '') + '>बेरीज स्तर</option>' +
                            '<option value="5" ' + (student.mathLevel == 5 ? 'selected' : '') + '>वजाबाकी स्तर</option>' +
                            '<option value="6" ' + (student.mathLevel == 6 ? 'selected' : '') + '>गुणाकार स्तर</option>' +
                            '<option value="7" ' + (student.mathLevel == 7 ? 'selected' : '') + '>भागाकार स्तर</option>' +
                            '<option value="8" ' + (student.mathLevel == 8 ? 'selected' : '') + '>गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण</option>' +
                        '</select>' +
                    '</td>' +
                    '<td>' +
                        '<select name="english_akshara" class="level-select" ' + (isReadOnly ? 'disabled' : '') + '>' +
                            '<option value="0" ' + (student.englishLevel == 0 ? 'selected' : '') + '>स्तर निश्चित केला नाही</option>' +
                            '<option value="1" ' + (student.englishLevel == 1 ? 'selected' : '') + '>Beginner level</option>' +
                            '<option value="2" ' + (student.englishLevel == 2 ? 'selected' : '') + '>Alphabet level</option>' +
                            '<option value="3" ' + (student.englishLevel == 3 ? 'selected' : '') + '>Word level</option>' +
                            '<option value="4" ' + (student.englishLevel == 4 ? 'selected' : '') + '>Sentence level</option>' +
                            '<option value="5" ' + (student.englishLevel == 5 ? 'selected' : '') + '>Paragraph Reading with Understanding</option>' +
                        '</select>' +
                    '</td>' +
                    '<td style="text-align: center;">' +
                        (!isReadOnly ? 
                            '<button class="btn btn-save" onclick="saveStudent(' + student.id + ')">💾 Save</button>' +
                            '<div id="msg-' + student.id + '" style="font-size: 11px; margin-top: 4px; font-weight: 600;"></div>' :
                            '<span style="color: #28a745;">✓ Complete</span>'
                        ) +
                    '</td>';
                
                tbody.appendChild(row);
            });
            
            // Restore save indicators after filtering
            restoreSaveIndicators();
            
            // Hide pagination when filtering
            var pagination = document.querySelector('.pagination');
            if (pagination) {
                pagination.style.display = 'none';
            }
            
            // Update filter results count
            document.getElementById('filterResultCount').textContent = 
                'Showing ' + filteredStudents.length + ' student' + (filteredStudents.length !== 1 ? 's' : '') + ' (filtered from <%= totalStudents %> total)';
        }
        
        function getMarathiLevelText(level) {
            var levels = ['स्थर निश्चित केला नाही', 'प्रारंभिक स्तर', 'अक्षर स्तर', 'शब्द स्तर', 'वाक्य स्तर', 'समजपूर्वक उतारा वाचन स्तर', 'मराठी वाचन व लेखन FLN स्तर 100% पूर्ण'];
            return levels[level] || levels[0];
        }
        
        function getMathLevelText(level) {
            var levels = ['स्तर निश्चित केला नाही', 'प्रारंभिक स्तर', 'अंक ज्ञान स्तर', 'संख्याज्ञान स्तर', 'बेरीज स्तर', 'वजाबाकी स्तर', 'गुणाकार स्तर', 'भागाकार स्तर', 'गणितीय संख्या व मूलभूत क्रिया FLN स्तर 100% पूर्ण'];
            return levels[level] || levels[0];
        }
        
        function getEnglishLevelText(level) {
            var levels = ['स्तर निश्चित केला नाही', 'Beginner level', 'Alphabet level', 'Word level', 'Sentence level', 'Paragraph Reading with Understanding'];
            return levels[level] || levels[0];
        }
        
        function clearFilters() {
            document.getElementById('filterPEN').value = '';
            document.getElementById('filterName').value = '';
            document.getElementById('filterClass').value = '';
            document.getElementById('filterSection').value = '';
            
            // Reload page to restore pagination
            window.location.href = '?phase=<%= selectedPhase %>';
        }
        
        function saveStudent(studentId) {
            var row = document.getElementById('row-' + studentId);
            var marathiLevel = row.querySelector('[name="marathi_akshara"]').value;
            var mathLevel = row.querySelector('[name="math_akshara"]').value;
            var englishLevel = row.querySelector('[name="english_akshara"]').value;
            var phase = document.getElementById('phaseSelector').value;
            var saveBtn = event.target;
            var msgDiv = document.getElementById('msg-' + studentId);
            
            // Show saving state
            saveBtn.disabled = true;
            saveBtn.style.background = '#6c757d';
            msgDiv.textContent = 'Saving...';
            msgDiv.style.color = '#6c757d';
            
            fetch('<%= request.getContextPath() %>/update-language-levels', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'studentId=' + studentId + 
                      '&phase=' + phase +
                      '&marathi_akshara=' + marathiLevel + 
                      '&math_akshara=' + mathLevel + 
                      '&english_akshara=' + englishLevel
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // Get current timestamp
                    var now = new Date();
                    var timeString = now.toLocaleTimeString('en-IN', { 
                        hour: '2-digit', 
                        minute: '2-digit',
                        second: '2-digit'
                    });
                    
                    // Show success state with flash animation
                    saveBtn.innerHTML = '✓ Saved';
                    saveBtn.style.background = '#0d6efd';
                    saveBtn.style.cursor = 'default';
                    row.style.background = '#cfe2ff';
                    row.style.transition = 'background 0.3s';
                    
                    // Create persistent save indicator inline with tooltip
                    msgDiv.innerHTML = 
                        '<div class="save-indicator" title="Last saved: ' + timeString + '">' +
                            '<span>✓</span>' +
                            '<span>Saved</span>' +
                        '</div>';
                    
                    // Add persistent row highlighting - ALWAYS visible
                    setTimeout(() => {
                        row.classList.add('row-saved');
                        row.style.background = '';
                    }, 500);
                    
                    // Re-enable button after brief delay
                    setTimeout(() => { 
                        saveBtn.disabled = false;
                    }, 1000);
                    
                    // Update the saved counter from DATABASE (works across all systems)
                    updateSavedCounter();
                    
                } else {
                    // Show error state
                    saveBtn.style.background = '#dc3545';
                    msgDiv.innerHTML = '<div style="color: #dc3545; font-size: 11px; font-weight: 600;">✗ ' + 
                        (data.message || 'Error saving') + '</div>';
                    row.style.background = '#f8d7da';
                    
                    setTimeout(() => { 
                        row.style.background = ''; 
                        msgDiv.innerHTML = '';
                        saveBtn.style.background = '#28a745';
                        saveBtn.disabled = false;
                    }, 3000);
                }
            })
            .catch(error => {
                // Show error state
                saveBtn.style.background = '#dc3545';
                msgDiv.innerHTML = '<div style="color: #dc3545; font-size: 11px; font-weight: 600;">✗ Failed to save</div>';
                row.style.background = '#f8d7da';
                
                setTimeout(() => { 
                    row.style.background = ''; 
                    msgDiv.innerHTML = '';
                    saveBtn.style.background = '#28a745';
                    saveBtn.disabled = false;
                }, 3000);
            });
        }
    </script>
</body>
</html>
