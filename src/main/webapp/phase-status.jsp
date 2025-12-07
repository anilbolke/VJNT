<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.PhaseApprovalDAO" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR) &&
                         !user.getUserType().equals(User.UserType.DIVISION))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    PhaseApprovalDAO phaseApprovalDAO = new PhaseApprovalDAO();
    
    // Get statistics for this district
    String districtName = user.getDistrictName();
    
    // Pagination parameters
    int pageSize = 10; // Schools per page
    int currentPage = 1;
    String pageParam = request.getParameter("page");
    if (pageParam != null) {
        try {
            currentPage = Integer.parseInt(pageParam);
            if (currentPage < 1) currentPage = 1;
        } catch (NumberFormatException e) {
            currentPage = 1;
        }
    }
    
    // Get Phase status data for all schools in district
    List<Map<String, Object>> allSchools = phaseApprovalDAO.getPhaseStatusByDistrict(districtName);
    
    // Debug: Log the data retrieval
    System.out.println("=== PHASE STATUS DEBUG ===");
    System.out.println("District: " + districtName);
    System.out.println("Total schools retrieved: " + (allSchools != null ? allSchools.size() : 0));
    if (allSchools != null && allSchools.size() > 0) {
        System.out.println("First school sample data: " + allSchools.get(0));
    }
    System.out.println("=========================");
    
    // Handle null or empty result
    if (allSchools == null) {
        allSchools = new ArrayList<>();
        System.err.println("WARNING: getPhaseStatusByDistrict returned null for district: " + districtName);
    }
    
    // Calculate Phase statistics (using all schools)
    int schoolsAllCompleted = 0;
    int schoolsPending = 0;
    int schoolsInProgress = 0;
    int schoolsNotStarted = 0;
    int totalPhase1Completed = 0;
    int totalPhase2Completed = 0;
    int totalPhase3Completed = 0;
    int totalPhase4Completed = 0;
    
    for (Map<String, Object> school : allSchools) {
        String overallStatus = (String) school.get("overallStatus");
        int phasesCompleted = (Integer) school.get("phasesCompleted");
        
        if ("ALL_COMPLETED".equals(overallStatus)) {
            schoolsAllCompleted++;
        } else if ("PENDING_APPROVAL".equals(overallStatus)) {
            schoolsPending++;
        } else if ("IN_PROGRESS".equals(overallStatus)) {
            schoolsInProgress++;
        } else {
            schoolsNotStarted++;
        }
        
        // Count individual phase completions (include APPROVED and COMPLETED_NOT_SUBMITTED)
        String p1Status = (String) school.get("phase1Status");
        String p2Status = (String) school.get("phase2Status");
        String p3Status = (String) school.get("phase3Status");
        String p4Status = (String) school.get("phase4Status");
        
        if ("APPROVED".equals(p1Status) || "COMPLETED_NOT_SUBMITTED".equals(p1Status)) totalPhase1Completed++;
        if ("APPROVED".equals(p2Status) || "COMPLETED_NOT_SUBMITTED".equals(p2Status)) totalPhase2Completed++;
        if ("APPROVED".equals(p3Status) || "COMPLETED_NOT_SUBMITTED".equals(p3Status)) totalPhase3Completed++;
        if ("APPROVED".equals(p4Status) || "COMPLETED_NOT_SUBMITTED".equals(p4Status)) totalPhase4Completed++;
    }
    
    // Calculate pagination
    int totalSchools = allSchools.size();
    int totalPages = (int) Math.ceil((double) totalSchools / pageSize);
    if (currentPage > totalPages && totalPages > 0) currentPage = totalPages;
    
    int startIndex = (currentPage - 1) * pageSize;
    int endIndex = Math.min(startIndex + pageSize, totalSchools);
    
    // Get paginated schools for current page
    List<Map<String, Object>> phaseStatus = allSchools.subList(startIndex, endIndex);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Phase Completion Status - <%= districtName %></title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f7fa;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 0;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            margin-bottom: 30px;
        }
        
        .header-content {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 25px 30px;
            flex-wrap: wrap;
            gap: 20px;
        }
        
        .header-left {
            flex: 1;
            min-width: 300px;
        }
        
        .header h1 {
            font-size: 28px;
            color: white;
            margin: 0 0 8px 0;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .header-subtitle {
            font-size: 15px;
            color: rgba(255,255,255,0.9);
            margin: 0;
            font-weight: 400;
        }
        
        .header-right {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .btn {
            padding: 10px 18px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.3s;
            font-weight: 500;
            box-shadow: 0 2px 5px rgba(0,0,0,0.15);
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0,0,0,0.25);
        }
        
        .btn-back {
            background: white;
            color: #667eea;
        }
        
        .btn-back:hover {
            background: #f5f5f5;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 0 30px 30px 30px;
        }
        
        .breadcrumb {
            background: white;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }
        
        .section {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 25px;
        }
        
        .section-title {
            font-size: 22px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 3px solid #667eea;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }
        
        .table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .table th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            font-size: 14px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .table td {
            padding: 12px 15px;
            border-bottom: 1px solid #e0e0e0;
            font-size: 14px;
        }
        
        .table tbody tr:hover {
            background: #f8f9ff;
        }
        
        .table tbody tr:last-child td {
            border-bottom: none;
        }
        
        .badge {
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
        }
        
        .phase-indicator {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
            margin: 2px;
        }
        
        @media (max-width: 768px) {
            .header-content {
                flex-direction: column;
                align-items: stretch;
            }
            
            .header h1 {
                font-size: 22px;
            }
            
            .header-right {
                justify-content: center;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div class="header-left">
                <h1>
                    <span style="font-size: 32px;">📊</span>
                    <span>Phase Completion Status</span>
                </h1>
                <p class="header-subtitle">📍 District: <%= districtName %> | School-wise Phase Details (1-4)</p>
            </div>
            <div class="header-right">
                <a href="<%= request.getContextPath() %>/district-dashboard.jsp" class="btn btn-back">
                    <span>◀️</span>
                    <span>Go to Dashboard</span>
                </a>
            </div>
        </div>
    </div>
    
    <div class="container">
        <!-- Breadcrumb -->
        <div class="breadcrumb">
            <span>Division:</span> <strong><%= user.getDivisionName() %></strong> 
            <span style="margin: 0 10px;">→</span> 
            <span>District:</span> <strong><%= districtName %></strong>
            <span style="margin: 0 10px;">→</span> 
            <span><strong>Phase Completion Status</strong></span>
        </div>
        
        <!-- Phase Status Section -->
        <div class="section">
            <h2 class="section-title">📊 Phase Completion Status - School-wise</h2>
            
            <!-- Summary Cards -->
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px;">
                <div style="background: linear-gradient(135deg, #4caf50 0%, #45a049 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <div style="font-size: 32px; font-weight: bold;"><%= schoolsAllCompleted %></div>
                    <div style="font-size: 14px; margin-top: 5px;">All Phases Completed</div>
                </div>
                <div style="background: linear-gradient(135deg, #2196f3 0%, #1976d2 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <div style="font-size: 32px; font-weight: bold;"><%= schoolsInProgress %></div>
                    <div style="font-size: 14px; margin-top: 5px;">In Progress</div>
                </div>
                <div style="background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <div style="font-size: 32px; font-weight: bold;"><%= schoolsPending %></div>
                    <div style="font-size: 14px; margin-top: 5px;">Pending Approval</div>
                </div>
                <div style="background: linear-gradient(135deg, #f44336 0%, #d32f2f 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <div style="font-size: 32px; font-weight: bold;"><%= schoolsNotStarted %></div>
                    <div style="font-size: 14px; margin-top: 5px;">Not Started</div>
                </div>
            </div>
            
            <!-- Phase-wise Progress -->
            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
                <h3 style="margin: 0 0 15px 0; color: #333; font-size: 16px;">📈 Individual Phase Progress</h3>
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px;">
                    <div style="text-align: center; padding: 15px; background: white; border-radius: 6px;">
                        <div style="font-size: 24px; font-weight: bold; color: #667eea;"><%= totalPhase1Completed %></div>
                        <div style="font-size: 13px; color: #666; margin-top: 5px;">Phase 1 Completed</div>
                    </div>
                    <div style="text-align: center; padding: 15px; background: white; border-radius: 6px;">
                        <div style="font-size: 24px; font-weight: bold; color: #667eea;"><%= totalPhase2Completed %></div>
                        <div style="font-size: 13px; color: #666; margin-top: 5px;">Phase 2 Completed</div>
                    </div>
                    <div style="text-align: center; padding: 15px; background: white; border-radius: 6px;">
                        <div style="font-size: 24px; font-weight: bold; color: #667eea;"><%= totalPhase3Completed %></div>
                        <div style="font-size: 13px; color: #666; margin-top: 5px;">Phase 3 Completed</div>
                    </div>
                    <div style="text-align: center; padding: 15px; background: white; border-radius: 6px;">
                        <div style="font-size: 24px; font-weight: bold; color: #667eea;"><%= totalPhase4Completed %></div>
                        <div style="font-size: 13px; color: #666; margin-top: 5px;">Phase 4 Completed</div>
                    </div>
                </div>
            </div>
            
            <!-- Advanced Filters -->
            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #667eea;">
                <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 15px;">
                    <span style="font-size: 18px;">🔍</span>
                    <h3 style="margin: 0; color: #333; font-size: 16px;">Advanced Filters</h3>
                </div>
                
                <!-- Status Filter Buttons -->
                <%-- <div style="margin-bottom: 15px;">
                    <label style="display: block; margin-bottom: 8px; color: #555; font-weight: 600; font-size: 13px;">
                        📊 Filter by Overall Status
                    </label>
                    <div style="display: flex; gap: 10px; flex-wrap: wrap;">
                        <button onclick="filterPhaseStatus('ALL')" id="phaseFilterAll" class="phase-filter-btn active" style="padding: 8px 16px; border: 2px solid #667eea; background: #667eea; color: white; border-radius: 6px; cursor: pointer; font-size: 14px; transition: all 0.3s;">
                            All Schools (<%= totalSchools %>)
                        </button>
                        <button onclick="filterPhaseStatus('ALL_COMPLETED')" id="phaseFilterCompleted" class="phase-filter-btn" style="padding: 8px 16px; border: 2px solid #4caf50; background: white; color: #4caf50; border-radius: 6px; cursor: pointer; font-size: 14px; transition: all 0.3s;">
                            All Completed (<%= schoolsAllCompleted %>)
                        </button>
                        <button onclick="filterPhaseStatus('IN_PROGRESS')" id="phaseFilterProgress" class="phase-filter-btn" style="padding: 8px 16px; border: 2px solid #2196f3; background: white; color: #2196f3; border-radius: 6px; cursor: pointer; font-size: 14px; transition: all 0.3s;">
                            In Progress (<%= schoolsInProgress %>)
                        </button>
                        <button onclick="filterPhaseStatus('PENDING_APPROVAL')" id="phaseFilterPending" class="phase-filter-btn" style="padding: 8px 16px; border: 2px solid #ff9800; background: white; color: #ff9800; border-radius: 6px; cursor: pointer; font-size: 14px; transition: all 0.3s;">
                            Pending Approval (<%= schoolsPending %>)
                        </button>
                        <button onclick="filterPhaseStatus('NOT_STARTED')" id="phaseFilterNotStarted" class="phase-filter-btn" style="padding: 8px 16px; border: 2px solid #f44336; background: white; color: #f44336; border-radius: 6px; cursor: pointer; font-size: 14px; transition: all 0.3s;">
                            Not Started (<%= schoolsNotStarted %>)
                        </button>
                    </div>
                </div> --%>
                
                <!-- Additional Filters -->
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px; margin-top: 15px;">
                    <!-- School Name/UDISE Search -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            🏫 Search School Name/UDISE
                        </label>
                        <input type="text" 
                               id="phaseSchoolSearch" 
                               placeholder="Enter school name or UDISE..."
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               oninput="applyPhaseFilters()">
                    </div>
                    
                    <!-- Head Master Name Search -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            👨‍💼 Head Master Name
                        </label>
                        <input type="text" 
                               id="phaseHeadMasterSearch" 
                               placeholder="Enter head master name..."
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               oninput="applyPhaseFilters()">
                    </div>
                    
                    <!-- Overall Status Filter -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            📊 Overall Status
                        </label>
                        <select id="overallStatusFilter" 
                                style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none; cursor: pointer;"
                                onchange="applyPhaseFilters()">
                            <option value="">All Statuses</option>
                            <option value="ALL_COMPLETED">All Completed</option>
                            <option value="PENDING_APPROVAL">Pending Approval</option>
                            <option value="IN_PROGRESS">In Progress</option>
                            <option value="NOT_STARTED">Not Started</option>
                        </select>
                    </div>
                    
                    <!-- Specific Phase Filter -->
                   <!--  <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            🎯 Specific Phase
                        </label>
                        <select id="phaseNumberFilter" 
                                style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none; cursor: pointer;"
                                onchange="applyPhaseFilters()">
                            <option value="">All Phases</option>
                            <option value="1">Phase 1</option>
                            <option value="2">Phase 2</option>
                            <option value="3">Phase 3</option>
                            <option value="4">Phase 4</option>
                        </select>
                    </div> -->
                    
                    <!-- <!-- Phase Status Filter -->
                    <!-- <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            ✅ Phase Status
                        </label>
                        <select id="phaseStatusFilter" 
                                style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none; cursor: pointer;"
                                onchange="applyPhaseFilters()">
                            <option value="">Any Status</option>
                            <option value="APPROVED">Approved</option>
                            <option value="PENDING">Pending</option>
                            <option value="NOT_STARTED">Not Started</option>
                        </select>
                    </div> -->
                    
                    <!-- Sort By -->
                    <!-- <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            🔄 Sort By
                        </label>
                        <select id="phaseSortBy" 
                                style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none; cursor: pointer;"
                                onchange="applyPhaseFilters()">
                            <option value="school_asc">School Name (A-Z)</option>
                            <option value="school_desc">School Name (Z-A)</option>
                            <option value="progress_desc" selected>Most Progress First</option>
                            <option value="progress_asc">Least Progress First</option>
                        </select>
                    </div> -->
                </div>
                
                <!-- Filter Actions -->
                <div style="margin-top: 15px; display: flex; gap: 10px; flex-wrap: wrap; align-items: center;">
                    <button onclick="applyPhaseFilters()" 
                            style="background: #667eea; color: white; padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500;">
                        ✓ Apply Filters
                    </button>
                    <button onclick="clearPhaseFilters()" 
                            style="background: #dc3545; color: white; padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500;">
                        ✕ Clear All
                    </button>
                    <span id="phaseFilterResultsInfo" style="color: #666; font-size: 13px; margin-left: 10px;"></span>
                </div>
            </div>
            
            <!-- Schools Table -->
            <div style="overflow-x: auto;">
                <table class="table" id="phaseStatusTable">
                    <thead>
                        <tr>
                            <th>Sr No</th>
                            <th>UDISE No</th>
                            <th>School Name</th>
                            <th>Head Master Details</th>
                            <th>Total Students</th>
                            <th>Phase 1</th>
                            <th>Phase 2</th>
                            <th>Phase 3</th>
                            <th>Phase 4</th>
                            <th>Overall Status</th>
                            <th>Progress</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% 
                        if (phaseStatus == null || phaseStatus.isEmpty()) {
                        %>
                            <tr>
                                <td colspan="11" style="text-align: center; padding: 40px; color: #666;">
                                    <div style="font-size: 48px; margin-bottom: 15px;">📋</div>
                                    <div style="font-size: 18px; font-weight: bold; margin-bottom: 10px;">No School Data Available</div>
                                    <div style="font-size: 14px;">
                                        No schools found for district: <strong><%= districtName %></strong>
                                        <br><br>
                                        Possible reasons:
                                        <ul style="text-align: left; display: inline-block; margin-top: 10px;">
                                            <li>No schools registered in this district</li>
                                            <li>District name mismatch in database</li>
                                            <li>Database connection issue</li>
                                        </ul>
                                        <br>
                                        <strong>Debug Info:</strong> Total schools retrieved = <%= allSchools.size() %>
                                    </div>
                                </td>
                            </tr>
                        <% 
                        } else {
                            int srNo = 1;
                            for (Map<String, Object> school : allSchools) {
                                String udise = (String) school.get("udiseNo");
                                String schoolName = (String) school.get("schoolName");
                                String hmName = (String) school.get("headmasterName");
                                String hmMobile = (String) school.get("headmasterMobile");
                                String hmWhatsapp = (String) school.get("headmasterWhatsapp");
                                
                                // Safe null handling for Integer values
                                Integer totalStudentsObj = (Integer) school.get("totalStudents");
                                int totalStudents = (totalStudentsObj != null) ? totalStudentsObj : 0;
                                
                                String phase1Status = (String) school.get("phase1Status");
                                String phase2Status = (String) school.get("phase2Status");
                                String phase3Status = (String) school.get("phase3Status");
                                String phase4Status = (String) school.get("phase4Status");
                                
                                Integer phasesCompletedObj = (Integer) school.get("phasesCompleted");
                                int phasesCompleted = (phasesCompletedObj != null) ? phasesCompletedObj : 0;
                                String overallStatus = (String) school.get("overallStatus");
                            
                            String statusBadge = "";
                            String statusColor = "";
                            
                            if ("ALL_COMPLETED".equals(overallStatus)) {
                                statusBadge = "All Completed ✓";
                                statusColor = "background: #4caf50; color: white;";
                            } else if ("PENDING_APPROVAL".equals(overallStatus)) {
                                statusBadge = "Pending Approval";
                                statusColor = "background: #ff9800; color: white;";
                            } else if ("IN_PROGRESS".equals(overallStatus)) {
                                statusBadge = "In Progress";
                                statusColor = "background: #2196f3; color: white;";
                            } else {
                                statusBadge = "Not Started";
                                statusColor = "background: #f44336; color: white;";
                            }
                        %>
                        <tr class="phase-row phase-row-<%= overallStatus %>" 
                            data-status="<%= overallStatus %>"
                            data-phase1="<%= phase1Status != null ? phase1Status : "" %>"
                            data-phase2="<%= phase2Status != null ? phase2Status : "" %>"
                            data-phase3="<%= phase3Status != null ? phase3Status : "" %>"
                            data-phase4="<%= phase4Status != null ? phase4Status : "" %>"
                            data-progress="<%= phasesCompleted %>">
                            <td><strong><%= srNo++ %></strong></td>
                            <td><strong><%= udise %></strong></td>
                            <td><strong style="color: #667eea;"><%= schoolName %></strong></td>
                            <td>
                                <% if (hmName != null && !hmName.isEmpty()) { %>
                                    <div style="font-size: 13px;">
                                        <div style="font-weight: 600; color: #333; margin-bottom: 3px;">
                                            <%= hmName %>
                                        </div>
                                        <% if (hmMobile != null && !hmMobile.isEmpty()) { %>
                                        <div style="color: #666; font-size: 12px;">
                                            📱 <a href="tel:<%= hmMobile %>" style="color: #2196f3; text-decoration: none;">
                                                <%= hmMobile %>
                                            </a>
                                        </div>
                                        <% } %>
                                        <% if (hmWhatsapp != null && !hmWhatsapp.isEmpty()) { %>
                                        <div style="color: #25D366; font-size: 12px;">
                                            💬 <a href="https://wa.me/91<%= hmWhatsapp %>" target="_blank" style="color: #25D366; text-decoration: none;">
                                                <%= hmWhatsapp %>
                                            </a>
                                        </div>
                                        <% } %>
                                    </div>
                                <% } else { %>
                                    <span style="color: #999; font-size: 12px;">Not assigned</span>
                                <% } %>
                            </td>
                            <td style="text-align: center; font-weight: bold;"><%= totalStudents %></td>
                            
                            <!-- Phase 1 -->
                            <td style="text-align: center;">
                                <% 
                                Integer phase1CompletedObj = (Integer) school.get("phase1Completed");
                                Integer phase1PercentageObj = (Integer) school.get("phase1Percentage");
                                int phase1Completed = (phase1CompletedObj != null) ? phase1CompletedObj : 0;
                                int phase1Percentage = (phase1PercentageObj != null) ? phase1PercentageObj : 0;
                                String p1Badge = "";
                                String p1Color = "";
                                String p1Details = "";
                                
                                if ("APPROVED".equals(phase1Status)) {
                                    p1Badge = "✓ Approved";
                                    p1Color = "background: #4caf50; color: white;";
                                    p1Details = phase1Completed + " students (" + phase1Percentage + "%)";
                                } else if ("PENDING".equals(phase1Status)) {
                                    p1Badge = "⏳ Pending";
                                    p1Color = "background: #ff9800; color: white;";
                                    p1Details = phase1Completed + " students (" + phase1Percentage + "%)";
                                } else if ("COMPLETED_NOT_SUBMITTED".equals(phase1Status)) {
                                    p1Badge = "✔️ Done";
                                    p1Color = "background: #2196f3; color: white;";
                                    p1Details = phase1Completed + " students (" + phase1Percentage + "%)";
                                } else {
                                    p1Badge = "—";
                                    p1Color = "background: #e0e0e0; color: #666;";
                                    p1Details = "Not started";
                                }
                                %>
                                <span class="phase-indicator" style="<%= p1Color %>"><%= p1Badge %></span>
                                <div style="font-size: 11px; color: #666; margin-top: 3px;"><%= p1Details %></div>
                            </td>
                            
                            <!-- Phase 2 -->
                            <td style="text-align: center;">
                                <% 
                                Integer phase2CompletedObj = (Integer) school.get("phase2Completed");
                                Integer phase2PercentageObj = (Integer) school.get("phase2Percentage");
                                int phase2Completed = (phase2CompletedObj != null) ? phase2CompletedObj : 0;
                                int phase2Percentage = (phase2PercentageObj != null) ? phase2PercentageObj : 0;
                                String p2Badge = "";
                                String p2Color = "";
                                String p2Details = "";
                                
                                if ("APPROVED".equals(phase2Status)) {
                                    p2Badge = "✓ Approved";
                                    p2Color = "background: #4caf50; color: white;";
                                    p2Details = phase2Completed + " students (" + phase2Percentage + "%)";
                                } else if ("PENDING".equals(phase2Status)) {
                                    p2Badge = "⏳ Pending";
                                    p2Color = "background: #ff9800; color: white;";
                                    p2Details = phase2Completed + " students (" + phase2Percentage + "%)";
                                } else if ("COMPLETED_NOT_SUBMITTED".equals(phase2Status)) {
                                    p2Badge = "✔️ Done";
                                    p2Color = "background: #2196f3; color: white;";
                                    p2Details = phase2Completed + " students (" + phase2Percentage + "%)";
                                } else {
                                    p2Badge = "—";
                                    p2Color = "background: #e0e0e0; color: #666;";
                                    p2Details = "Not started";
                                }
                                %>
                                <span class="phase-indicator" style="<%= p2Color %>"><%= p2Badge %></span>
                                <div style="font-size: 11px; color: #666; margin-top: 3px;"><%= p2Details %></div>
                            </td>
                            
                            <!-- Phase 3 -->
                            <td style="text-align: center;">
                                <% 
                                Integer phase3CompletedObj = (Integer) school.get("phase3Completed");
                                Integer phase3PercentageObj = (Integer) school.get("phase3Percentage");
                                int phase3Completed = (phase3CompletedObj != null) ? phase3CompletedObj : 0;
                                int phase3Percentage = (phase3PercentageObj != null) ? phase3PercentageObj : 0;
                                String p3Badge = "";
                                String p3Color = "";
                                String p3Details = "";
                                
                                if ("APPROVED".equals(phase3Status)) {
                                    p3Badge = "✓ Approved";
                                    p3Color = "background: #4caf50; color: white;";
                                    p3Details = phase3Completed + " students (" + phase3Percentage + "%)";
                                } else if ("PENDING".equals(phase3Status)) {
                                    p3Badge = "⏳ Pending";
                                    p3Color = "background: #ff9800; color: white;";
                                    p3Details = phase3Completed + " students (" + phase3Percentage + "%)";
                                } else if ("COMPLETED_NOT_SUBMITTED".equals(phase3Status)) {
                                    p3Badge = "✔️ Done";
                                    p3Color = "background: #2196f3; color: white;";
                                    p3Details = phase3Completed + " students (" + phase3Percentage + "%)";
                                } else {
                                    p3Badge = "—";
                                    p3Color = "background: #e0e0e0; color: #666;";
                                    p3Details = "Not started";
                                }
                                %>
                                <span class="phase-indicator" style="<%= p3Color %>"><%= p3Badge %></span>
                                <div style="font-size: 11px; color: #666; margin-top: 3px;"><%= p3Details %></div>
                            </td>
                            
                            <!-- Phase 4 -->
                            <td style="text-align: center;">
                                <% 
                                Integer phase4CompletedObj = (Integer) school.get("phase4Completed");
                                Integer phase4PercentageObj = (Integer) school.get("phase4Percentage");
                                int phase4Completed = (phase4CompletedObj != null) ? phase4CompletedObj : 0;
                                int phase4Percentage = (phase4PercentageObj != null) ? phase4PercentageObj : 0;
                                String p4Badge = "";
                                String p4Color = "";
                                String p4Details = "";
                                
                                if ("APPROVED".equals(phase4Status)) {
                                    p4Badge = "✓ Approved";
                                    p4Color = "background: #4caf50; color: white;";
                                    p4Details = phase4Completed + " students (" + phase4Percentage + "%)";
                                } else if ("PENDING".equals(phase4Status)) {
                                    p4Badge = "⏳ Pending";
                                    p4Color = "background: #ff9800; color: white;";
                                    p4Details = phase4Completed + " students (" + phase4Percentage + "%)";
                                } else if ("COMPLETED_NOT_SUBMITTED".equals(phase4Status)) {
                                    p4Badge = "✔️ Done";
                                    p4Color = "background: #2196f3; color: white;";
                                    p4Details = phase4Completed + " students (" + phase4Percentage + "%)";
                                } else {
                                    p4Badge = "—";
                                    p4Color = "background: #e0e0e0; color: #666;";
                                    p4Details = "Not started";
                                }
                                %>
                                <span class="phase-indicator" style="<%= p4Color %>"><%= p4Badge %></span>
                                <div style="font-size: 11px; color: #666; margin-top: 3px;"><%= p4Details %></div>
                            </td>
                            
                            <td>
                                <span class="badge" style="<%= statusColor %> padding: 6px 12px; border-radius: 4px; font-size: 12px;">
                                    <%= statusBadge %>
                                </span>
                            </td>
                            <td style="text-align: center;">
                                <div style="font-size: 18px; font-weight: bold; color: #667eea;"><%= phasesCompleted %>/4</div>
                                <div style="font-size: 11px; color: #666;">Phases Complete</div>
                            </td>
                        </tr>
                        <% 
                            } // End of for loop
                        } // End of else (data available)
                        %>
                    </tbody>
                </table>
            </div>
            
            <!-- Pagination Info and Controls -->
            <div style="margin-top: 20px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 15px;">
                <div style="color: #666; font-size: 14px;">
                    Showing <%= startIndex + 1 %> - <%= endIndex %> of <%= totalSchools %> schools
                </div>
                
                <% if (totalPages > 1) { %>
                <div style="display: flex; gap: 8px; align-items: center; flex-wrap: wrap;">
                    <!-- Previous Button -->
                    <% if (currentPage > 1) { %>
                        <a href="?page=<%= currentPage - 1 %>" style="padding: 8px 14px; background: white; color: #667eea; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">
                            « Previous
                        </a>
                    <% } else { %>
                        <span style="padding: 8px 14px; background: #f5f5f5; color: #ccc; border: 1px solid #e0e0e0; border-radius: 5px; font-size: 14px; font-weight: 500;">
                            « Previous
                        </span>
                    <% } %>
                    
                    <!-- Page Numbers -->
                    <% 
                    int startPage = Math.max(1, currentPage - 2);
                    int endPage = Math.min(totalPages, currentPage + 2);
                    
                    if (startPage > 1) { %>
                        <a href="?page=1" style="padding: 8px 14px; background: white; color: #667eea; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">
                            1
                        </a>
                        <% if (startPage > 2) { %>
                            <span style="padding: 8px 14px; color: #999;">...</span>
                        <% } %>
                    <% } %>
                    
                    <% for (int i = startPage; i <= endPage; i++) { 
                        if (i == currentPage) { %>
                            <span style="padding: 8px 14px; background: #667eea; color: white; border: 1px solid #667eea; border-radius: 5px; font-size: 14px; font-weight: bold;">
                                <%= i %>
                            </span>
                        <% } else { %>
                            <a href="?page=<%= i %>" style="padding: 8px 14px; background: white; color: #667eea; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">
                                <%= i %>
                            </a>
                        <% } %>
                    <% } %>
                    
                    <% if (endPage < totalPages) { 
                        if (endPage < totalPages - 1) { %>
                            <span style="padding: 8px 14px; color: #999;">...</span>
                        <% } %>
                        <a href="?page=<%= totalPages %>" style="padding: 8px 14px; background: white; color: #667eea; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">
                            <%= totalPages %>
                        </a>
                    <% } %>
                    
                    <!-- Next Button -->
                    <% if (currentPage < totalPages) { %>
                        <a href="?page=<%= currentPage + 1 %>" style="padding: 8px 14px; background: white; color: #667eea; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">
                            Next »
                        </a>
                    <% } else { %>
                        <span style="padding: 8px 14px; background: #f5f5f5; color: #ccc; border: 1px solid #e0e0e0; border-radius: 5px; font-size: 14px; font-weight: 500;">
                            Next »
                        </span>
                    <% } %>
                </div>
                <% } %>
            </div>
        </div>
    </div>
    
    <script>
        // Phase Status Filter Functions
        let currentPhaseStatus = 'ALL';
        let currentFilterPage = 1;
        let filteredRows = [];
        const itemsPerPage = 10;
        
        function filterPhaseStatus(status) {
            currentPhaseStatus = status;
            
            // Update button styling
            const buttons = document.querySelectorAll('.phase-filter-btn');
            buttons.forEach(btn => {
                btn.style.background = 'white';
                btn.style.color = btn.style.borderColor;
            });
            
            // Highlight active button
            let activeBtn;
            switch(status) {
                case 'ALL':
                    activeBtn = document.getElementById('phaseFilterAll');
                    break;
                case 'ALL_COMPLETED':
                    activeBtn = document.getElementById('phaseFilterCompleted');
                    break;
                case 'IN_PROGRESS':
                    activeBtn = document.getElementById('phaseFilterProgress');
                    break;
                case 'PENDING_APPROVAL':
                    activeBtn = document.getElementById('phaseFilterPending');
                    break;
                case 'NOT_STARTED':
                    activeBtn = document.getElementById('phaseFilterNotStarted');
                    break;
            }
            
            if (activeBtn) {
                const borderColor = activeBtn.style.borderColor;
                activeBtn.style.background = borderColor;
                activeBtn.style.color = 'white';
            }
            
            applyPhaseFilters();
        }
        
        // Apply All Phase Filters
        function applyPhaseFilters() {
            const schoolSearch = document.getElementById('phaseSchoolSearch').value.toLowerCase();
            const hmSearch = document.getElementById('phaseHeadMasterSearch').value.toLowerCase();
            const overallStatusFilter = document.getElementById('overallStatusFilter').value;
            const phaseNumber = document.getElementById('phaseNumberFilter') ? document.getElementById('phaseNumberFilter').value : '';
            const phaseStatus = document.getElementById('phaseStatusFilter') ? document.getElementById('phaseStatusFilter').value : '';
            const sortBy = document.getElementById('phaseSortBy') ? document.getElementById('phaseSortBy').value : 'school_asc';
            
            const table = document.getElementById('phaseStatusTable');
            if (!table) return;
            
            const tbody = table.querySelector('tbody');
            const rows = Array.from(tbody.querySelectorAll('.phase-row'));
            
            let visibleCount = 0;
            
            // Filter rows
            rows.forEach(row => {
                const rowStatus = row.getAttribute('data-status');
                const cells = row.cells;
                
                const udise = cells[1].textContent.toLowerCase();
                const schoolName = cells[2].textContent.toLowerCase();
                const hmName = cells[3].textContent.toLowerCase();
                
                // Apply filters
                let matchesOverallStatus = currentPhaseStatus === 'ALL' || rowStatus === currentPhaseStatus;
                let matchesSchoolSearch = schoolSearch === '' || udise.includes(schoolSearch) || schoolName.includes(schoolSearch);
                let matchesHMSearch = hmSearch === '' || hmName.includes(hmSearch);
                
                // Apply dropdown Overall Status filter (independent of button filter)
                let matchesDropdownStatus = overallStatusFilter === '' || rowStatus === overallStatusFilter;
                
                // Combine button filter and dropdown filter for overall status
                matchesOverallStatus = matchesOverallStatus && matchesDropdownStatus;
                
                // Phase-specific filter
                let matchesPhaseFilter = true;
                if (phaseNumber && phaseStatus) {
                    const phaseAttr = row.getAttribute('data-phase' + phaseNumber);
                    if (phaseStatus === 'APPROVED') {
                        matchesPhaseFilter = phaseAttr === 'APPROVED';
                    } else if (phaseStatus === 'PENDING') {
                        matchesPhaseFilter = phaseAttr === 'PENDING';
                    } else if (phaseStatus === 'NOT_STARTED') {
                        matchesPhaseFilter = !phaseAttr || phaseAttr === '' || phaseAttr === 'NOT_STARTED';
                    } else {
                        matchesPhaseFilter = phaseAttr === phaseStatus;
                    }
                }
                
                if (matchesOverallStatus && matchesSchoolSearch && matchesHMSearch && matchesPhaseFilter) {
                    row.style.display = '';
                    visibleCount++;
                } else {
                    row.style.display = 'none';
                }
            });
            
            // Sort visible rows
            const visibleRows = rows.filter(row => row.style.display !== 'none');
            sortPhaseRows(visibleRows, sortBy);
            
            // Re-append sorted rows to tbody
            visibleRows.forEach(row => tbody.appendChild(row));
            
            // Store filtered rows globally
            filteredRows = visibleRows;
            
            // Reset to page 1 when filters change
            currentFilterPage = 1;
            
            // Show paginated results
            showFilteredPage(currentFilterPage);
        }
        
        // Show specific page of filtered results
        function showFilteredPage(pageNum) {
            const totalFilteredRows = filteredRows.length;
            const totalFilteredPages = Math.ceil(totalFilteredRows / itemsPerPage);
            
            // Validate page number
            if (pageNum < 1) pageNum = 1;
            if (pageNum > totalFilteredPages && totalFilteredPages > 0) pageNum = totalFilteredPages;
            currentFilterPage = pageNum;
            
            // Hide all filtered rows first
            filteredRows.forEach(row => row.style.display = 'none');
            
            // Show only rows for current page
            const startIdx = (currentFilterPage - 1) * itemsPerPage;
            const endIdx = Math.min(startIdx + itemsPerPage, totalFilteredRows);
            for (let i = startIdx; i < endIdx; i++) {
                filteredRows[i].style.display = '';
                // Update serial number
                filteredRows[i].cells[0].innerHTML = '<strong>' + (i + 1) + '</strong>';
            }
            
            // Update filter info
            const filterInfo = document.getElementById('phaseFilterResultsInfo');
            const table = document.getElementById('phaseStatusTable');
            const tbody = table.querySelector('tbody');
            const allRows = Array.from(tbody.querySelectorAll('.phase-row'));
            const totalRows = allRows.length;
            
            if (totalFilteredRows === totalRows) {
                filterInfo.textContent = 'Showing all ' + totalRows + ' schools (Page ' + currentFilterPage + ' of ' + totalFilteredPages + ')';
                filterInfo.style.color = '#28a745';
            } else {
                filterInfo.textContent = 'Filtered: ' + totalFilteredRows + ' of ' + totalRows + ' schools (Page ' + currentFilterPage + ' of ' + totalFilteredPages + ')';
                filterInfo.style.color = '#ff9800';
            }
            
            // Update pagination controls
            updatePaginationControls(totalFilteredPages, currentFilterPage);
        }
        
        // Update pagination controls
        function updatePaginationControls(totalPages, currentPage) {
            const paginationDiv = document.querySelector('.pagination');
            if (!paginationDiv) return;
            
            let paginationHTML = '';
            
            // Previous button
            if (currentPage > 1) {
                paginationHTML += '<a href="javascript:void(0)" onclick="showFilteredPage(' + (currentPage - 1) + ')" style="padding: 8px 14px; background: white; color: #667eea; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">« Prev</a>';
            } else {
                paginationHTML += '<span style="padding: 8px 14px; background: #f5f5f5; color: #ccc; border: 1px solid #e0e0e0; border-radius: 5px; font-size: 14px; font-weight: 500;">« Prev</span>';
            }
            
            // Page numbers
            const maxVisible = 5;
            let startPage = Math.max(1, currentPage - Math.floor(maxVisible / 2));
            let endPage = Math.min(totalPages, startPage + maxVisible - 1);
            
            if (endPage - startPage < maxVisible - 1) {
                startPage = Math.max(1, endPage - maxVisible + 1);
            }
            
            // First page
            if (startPage > 1) {
                paginationHTML += '<a href="javascript:void(0)" onclick="showFilteredPage(1)" style="padding: 8px 14px; background: white; color: #667eea; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">1</a>';
                if (startPage > 2) {
                    paginationHTML += '<span style="padding: 8px 14px; color: #999;">...</span>';
                }
            }
            
            // Page numbers
            for (let i = startPage; i <= endPage; i++) {
                if (i === currentPage) {
                    paginationHTML += '<span style="padding: 8px 14px; background: #667eea; color: white; border: 1px solid #667eea; border-radius: 5px; font-size: 14px; font-weight: bold;">' + i + '</span>';
                } else {
                    paginationHTML += '<a href="javascript:void(0)" onclick="showFilteredPage(' + i + ')" style="padding: 8px 14px; background: white; color: #667eea; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">' + i + '</a>';
                }
            }
            
            // Last page
            if (endPage < totalPages) {
                if (endPage < totalPages - 1) {
                    paginationHTML += '<span style="padding: 8px 14px; color: #999;">...</span>';
                }
                paginationHTML += '<a href="javascript:void(0)" onclick="showFilteredPage(' + totalPages + ')" style="padding: 8px 14px; background: white; color: #667eea; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">' + totalPages + '</a>';
            }
            
            // Next button
            if (currentPage < totalPages) {
                paginationHTML += '<a href="javascript:void(0)" onclick="showFilteredPage(' + (currentPage + 1) + ')" style="padding: 8px 14px; background: white; color: #667eea; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">Next »</a>';
            } else {
                paginationHTML += '<span style="padding: 8px 14px; background: #f5f5f5; color: #ccc; border: 1px solid #e0e0e0; border-radius: 5px; font-size: 14px; font-weight: 500;">Next »</span>';
            }
            
            paginationDiv.innerHTML = paginationHTML;
        }
        
        // Sort Phase Rows
        function sortPhaseRows(rows, sortBy) {
            rows.sort((a, b) => {
                switch(sortBy) {
                    case 'school_asc':
                        return a.cells[2].textContent.localeCompare(b.cells[2].textContent);
                    case 'school_desc':
                        return b.cells[2].textContent.localeCompare(a.cells[2].textContent);
                    case 'progress_desc':
                        return parseInt(b.getAttribute('data-progress')) - parseInt(a.getAttribute('data-progress'));
                    case 'progress_asc':
                        return parseInt(a.getAttribute('data-progress')) - parseInt(b.getAttribute('data-progress'));
                    default:
                        return 0;
                }
            });
        }
        
        // Clear All Phase Filters
        function clearPhaseFilters() {
            // Clear input fields
            document.getElementById('phaseSchoolSearch').value = '';
            document.getElementById('phaseHeadMasterSearch').value = '';
            document.getElementById('overallStatusFilter').value = '';
            if (document.getElementById('phaseNumberFilter')) document.getElementById('phaseNumberFilter').value = '';
            if (document.getElementById('phaseStatusFilter')) document.getElementById('phaseStatusFilter').value = '';
            if (document.getElementById('phaseSortBy')) document.getElementById('phaseSortBy').value = 'progress_desc';
            
            // Reset to show all
            currentPhaseStatus = 'ALL';
            filterPhaseStatus('ALL');
        }
        
        // Initialize on page load
        document.addEventListener('DOMContentLoaded', function() {
            // Set initial button styling for "All Schools" filter
            const allBtn = document.getElementById('phaseFilterAll');
            if (allBtn) {
                allBtn.style.background = '#667eea';
                allBtn.style.color = 'white';
            }
            
            // Initialize filtered rows with all rows
            const table = document.getElementById('phaseStatusTable');
            if (table) {
                const tbody = table.querySelector('tbody');
                const rows = Array.from(tbody.querySelectorAll('.phase-row'));
                filteredRows = rows;
                
                // Show first page
                showFilteredPage(1);
            }
            
            console.log('Phase status filters initialized with client-side pagination');
        });
    </script>
</body>
</html>
