<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.PalakMelavaDAO" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR) &&
                         !user.getUserType().equals(User.UserType.DIVISION))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    PalakMelavaDAO palakMelavaDAO = new PalakMelavaDAO();
    
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
    
    // Get Palak Melava status data for all schools in district
    List<Map<String, Object>> allSchools = palakMelavaDAO.getPalakMelavaStatusByDistrict(districtName);
    
    // Calculate Palak Melava statistics (using all schools)
    int schoolsWithMeetings = 0;
    int schoolsPending = 0;
    int schoolsWithoutMeetings = 0;
    int totalMeetingsCount = 0;
    int totalApprovedMeetings = 0;
    
    for (Map<String, Object> school : allSchools) {
        int totalMeetings = (Integer) school.get("totalMeetings");
        int pendingMeetings = (Integer) school.get("pendingMeetings");
        int approvedMeetings = (Integer) school.get("approvedMeetings");
        
        if (totalMeetings > 0) {
            schoolsWithMeetings++;
        } else {
            schoolsWithoutMeetings++;
        }
        
        if (pendingMeetings > 0) {
            schoolsPending++;
        }
        
        totalMeetingsCount += totalMeetings;
        totalApprovedMeetings += approvedMeetings;
    }
    
    // Calculate pagination
    int totalSchools = allSchools.size();
    int totalPages = (int) Math.ceil((double) totalSchools / pageSize);
    if (currentPage > totalPages && totalPages > 0) currentPage = totalPages;
    
    int startIndex = (currentPage - 1) * pageSize;
    int endIndex = Math.min(startIndex + pageSize, totalSchools);
    
    // Get paginated schools for current page
    List<Map<String, Object>> palakMelavaStatus = allSchools.subList(startIndex, endIndex);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Palak Melava Status - <%= districtName %></title>
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
            background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%);
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
            color: #ff9800;
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
            border-bottom: 3px solid #ff9800;
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
            background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%);
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
            background: #fff9f0;
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
                    <span style="font-size: 32px;">👨‍👩‍👧‍👦</span>
                    <span>Palak Melava Status</span>
                </h1>
                <p class="header-subtitle">📍 District: <%= districtName %> | School-wise Parent Meeting Status</p>
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
            <span><strong>Palak Melava Status</strong></span>
        </div>
        
        <!-- Palak Melava Status Section -->
        <div class="section">
            <h2 class="section-title">👨‍👩‍👧‍👦 Palak Melava (Parent Meeting) Status - School-wise</h2>
            
            <!-- Summary Cards -->
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px;">
                <div style="background: linear-gradient(135deg, #4caf50 0%, #45a049 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <div style="font-size: 32px; font-weight: bold;"><%= totalApprovedMeetings %></div>
                    <div style="font-size: 14px; margin-top: 5px;">Approved Meetings</div>
                </div>
                <div style="background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <div style="font-size: 32px; font-weight: bold;"><%= schoolsPending %></div>
                    <div style="font-size: 14px; margin-top: 5px;">Schools Pending Approval</div>
                </div>
                <div style="background: linear-gradient(135deg, #2196f3 0%, #1976d2 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <div style="font-size: 32px; font-weight: bold;"><%= totalMeetingsCount %></div>
                    <div style="font-size: 14px; margin-top: 5px;">Total Meetings Conducted</div>
                </div>
                <div style="background: linear-gradient(135deg, #f44336 0%, #d32f2f 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <div style="font-size: 32px; font-weight: bold;"><%= schoolsWithoutMeetings %></div>
                    <div style="font-size: 14px; margin-top: 5px;">Schools Without Meetings</div>
                </div>
            </div>
            
            <!-- Advanced Filters for Palak Melava Status -->
            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #ff9800;">
                <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 15px;">
                    <span style="font-size: 18px;">🔍</span>
                    <h3 style="margin: 0; color: #333; font-size: 16px;">Advanced Filters</h3>
                </div>
                
                <!-- Status Filter Buttons -->
                <div style="margin-bottom: 15px;">
                    <label style="display: block; margin-bottom: 8px; color: #555; font-weight: 600; font-size: 13px;">
                        📊 Filter by Status
                    </label>
                    <div style="display: flex; gap: 10px; flex-wrap: wrap;">
                        <button onclick="filterPalakMelavaStatus('ALL')" id="pmFilterAll" class="pm-filter-btn active" style="padding: 8px 16px; border: 2px solid #667eea; background: #667eea; color: white; border-radius: 6px; cursor: pointer; font-size: 14px; transition: all 0.3s;">
                            All Schools (<%= palakMelavaStatus.size() %>)
                        </button>
                        <button onclick="filterPalakMelavaStatus('NO_MEETING')" id="pmFilterNoMeeting" class="pm-filter-btn" style="padding: 8px 16px; border: 2px solid #f44336; background: white; color: #f44336; border-radius: 6px; cursor: pointer; font-size: 14px; transition: all 0.3s;">
                            No Meetings (<%= schoolsWithoutMeetings %>)
                        </button>
                        <button onclick="filterPalakMelavaStatus('PENDING_APPROVAL')" id="pmFilterPending" class="pm-filter-btn" style="padding: 8px 16px; border: 2px solid #ff9800; background: white; color: #ff9800; border-radius: 6px; cursor: pointer; font-size: 14px; transition: all 0.3s;">
                            Pending Approval (<%= schoolsPending %>)
                        </button>
                        <button onclick="filterPalakMelavaStatus('COMPLETED')" id="pmFilterCompleted" class="pm-filter-btn" style="padding: 8px 16px; border: 2px solid #4caf50; background: white; color: #4caf50; border-radius: 6px; cursor: pointer; font-size: 14px; transition: all 0.3s;">
                            Completed (<%= schoolsWithMeetings - schoolsPending %>)
                        </button>
                    </div>
                </div>
                
                <!-- Additional Filters -->
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px; margin-top: 15px;">
                    <!-- School Name/UDISE Search -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            🏫 Search School Name/UDISE
                        </label>
                        <input type="text" 
                               id="pmSchoolSearch" 
                               placeholder="Enter school name or UDISE..."
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               oninput="applyPalakMelavaFilters()">
                    </div>
                    
                    <!-- Head Master Name Search -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            👨‍💼 Head Master Name
                        </label>
                        <input type="text" 
                               id="pmHeadMasterSearch" 
                               placeholder="Enter head master name..."
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               oninput="applyPalakMelavaFilters()">
                    </div>
                    
                    <!-- Minimum Meetings -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            📊 Min Meetings
                        </label>
                        <input type="number" 
                               id="pmMinMeetings" 
                               placeholder="e.g., 1"
                               min="0"
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               oninput="applyPalakMelavaFilters()">
                    </div>
                    
                    <!-- Date Range Filter -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            📅 Last Meeting From
                        </label>
                        <input type="date" 
                               id="pmDateFrom" 
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               onchange="applyPalakMelavaFilters()">
                    </div>
                    
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            📅 Last Meeting To
                        </label>
                        <input type="date" 
                               id="pmDateTo" 
                               style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none;"
                               onchange="applyPalakMelavaFilters()">
                    </div>
                    
                    <!-- Sort By -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            🔄 Sort By
                        </label>
                        <select id="pmSortBy" 
                                style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none; cursor: pointer;"
                                onchange="applyPalakMelavaFilters()">
                            <option value="school_asc">School Name (A-Z)</option>
                            <option value="school_desc">School Name (Z-A)</option>
                            <option value="meetings_desc" selected>Most Meetings First</option>
                            <option value="meetings_asc">Least Meetings First</option>
                            <option value="date_desc">Latest Meeting First</option>
                            <option value="date_asc">Oldest Meeting First</option>
                            <option value="parents_desc">Most Parents Attended</option>
                        </select>
                    </div>
                </div>
                
                <!-- Filter Actions -->
                <div style="margin-top: 15px; display: flex; gap: 10px; flex-wrap: wrap; align-items: center;">
                    <button onclick="applyPalakMelavaFilters()" 
                            style="background: #667eea; color: white; padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500;">
                        ✓ Apply Filters
                    </button>
                    <button onclick="clearPalakMelavaFilters()" 
                            style="background: #dc3545; color: white; padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500;">
                        ✕ Clear All
                    </button>
                    <span id="pmFilterResultsInfo" style="color: #666; font-size: 13px; margin-left: 10px;"></span>
                </div>
            </div>
            
            <!-- Schools Table -->
            <div style="overflow-x: auto;">
                <table class="table" id="palakMelavaTable">
                    <thead>
                        <tr>
                            <th>Sr No</th>
                            <th>UDISE No</th>
                            <th>School Name</th>
                            <th>Head Master Details</th>
                            <th>Total Meetings</th>
                            <th>Approved</th>
                            <th>Pending</th>
                            <th>Rejected</th>
                            <th>Draft</th>
                            <th>Last Meeting Date</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% 
                        int srNo = 1;
                        for (Map<String, Object> school : palakMelavaStatus) {
                            String udise = (String) school.get("udiseNo");
                            String schoolName = (String) school.get("schoolName");
                            String hmName = (String) school.get("headmasterName");
                            String hmMobile = (String) school.get("headmasterMobile");
                            String hmWhatsapp = (String) school.get("headmasterWhatsapp");
                            int totalMeetings = (Integer) school.get("totalMeetings");
                            int approvedMeetings = (Integer) school.get("approvedMeetings");
                            int pendingMeetings = (Integer) school.get("pendingMeetings");
                            int rejectedMeetings = (Integer) school.get("rejectedMeetings");
                            int draftMeetings = (Integer) school.get("draftMeetings");
                            java.sql.Date lastMeetingDate = (java.sql.Date) school.get("lastMeetingDate");
                            int totalParents = (Integer) school.get("totalParentsAttended");
                            String status = (String) school.get("status");
                            
                            String statusBadge = "";
                            String statusColor = "";
                            String rowClass = "pm-row-" + status;
                            
                            if ("NO_MEETING".equals(status)) {
                                statusBadge = "No Meeting Yet";
                                statusColor = "background: #f44336; color: white;";
                            } else if ("PENDING_APPROVAL".equals(status)) {
                                statusBadge = "Pending Approval";
                                statusColor = "background: #ff9800; color: white;";
                            } else {
                                statusBadge = "Completed";
                                statusColor = "background: #4caf50; color: white;";
                            }
                        %>
                        <tr class="palak-melava-row <%= rowClass %>" data-status="<%= status %>">
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
                            <td style="text-align: center; font-weight: bold; font-size: 16px;"><%= totalMeetings %></td>
                            <td style="text-align: center;">
                                <% if (approvedMeetings > 0) { %>
                                    <span style="background: #4caf50; color: white; padding: 4px 10px; border-radius: 12px; font-weight: 500;"><%= approvedMeetings %></span>
                                <% } else { %>
                                    <span style="color: #999;">0</span>
                                <% } %>
                            </td>
                            <td style="text-align: center;">
                                <% if (pendingMeetings > 0) { %>
                                    <span style="background: #ff9800; color: white; padding: 4px 10px; border-radius: 12px; font-weight: 500;"><%= pendingMeetings %></span>
                                <% } else { %>
                                    <span style="color: #999;">0</span>
                                <% } %>
                            </td>
                            <td style="text-align: center;">
                                <% if (rejectedMeetings > 0) { %>
                                    <span style="background: #f44336; color: white; padding: 4px 10px; border-radius: 12px; font-weight: 500;"><%= rejectedMeetings %></span>
                                <% } else { %>
                                    <span style="color: #999;">0</span>
                                <% } %>
                            </td>
                            <td style="text-align: center;">
                                <% if (draftMeetings > 0) { %>
                                    <span style="background: #9e9e9e; color: white; padding: 4px 10px; border-radius: 12px; font-weight: 500;"><%= draftMeetings %></span>
                                <% } else { %>
                                    <span style="color: #999;">0</span>
                                <% } %>
                            </td>
                            <td><%= lastMeetingDate != null ? lastMeetingDate : "-" %></td>
                            <td>
                                <span class="badge" style="<%= statusColor %> padding: 6px 12px; border-radius: 4px; font-size: 12px;">
                                    <%= statusBadge %>
                                </span>
                            </td>
                            <td>
                                <% if (totalMeetings > 0) { %>
                                    <button onclick="viewPalakMelavaDetails('<%= udise %>', '<%= schoolName %>')" 
                                            style="background: #2196f3; color: white; padding: 6px 12px; border: none; border-radius: 4px; cursor: pointer; font-size: 12px;">
                                        📋 View Details
                                    </button>
                                <% } else { %>
                                    <span style="color: #999; font-size: 12px;">No data</span>
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
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
                        <a href="?page=<%= currentPage - 1 %>" style="padding: 8px 14px; background: white; color: #2196f3; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">
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
                    
                    // Show first page if not in range
                    if (startPage > 1) { %>
                        <a href="?page=1" style="padding: 8px 14px; background: white; color: #2196f3; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">
                            1
                        </a>
                        <% if (startPage > 2) { %>
                            <span style="padding: 8px 14px; color: #999;">...</span>
                        <% } %>
                    <% } %>
                    
                    <% for (int i = startPage; i <= endPage; i++) { 
                        if (i == currentPage) { %>
                            <span style="padding: 8px 14px; background: #2196f3; color: white; border: 1px solid #2196f3; border-radius: 5px; font-size: 14px; font-weight: bold;">
                                <%= i %>
                            </span>
                        <% } else { %>
                            <a href="?page=<%= i %>" style="padding: 8px 14px; background: white; color: #2196f3; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">
                                <%= i %>
                            </a>
                        <% } %>
                    <% } %>
                    
                    <!-- Show last page if not in range -->
                    <% if (endPage < totalPages) { 
                        if (endPage < totalPages - 1) { %>
                            <span style="padding: 8px 14px; color: #999;">...</span>
                        <% } %>
                        <a href="?page=<%= totalPages %>" style="padding: 8px 14px; background: white; color: #2196f3; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">
                            <%= totalPages %>
                        </a>
                    <% } %>
                    
                    <!-- Next Button -->
                    <% if (currentPage < totalPages) { %>
                        <a href="?page=<%= currentPage + 1 %>" style="padding: 8px 14px; background: white; color: #2196f3; border: 1px solid #e0e0e0; border-radius: 5px; text-decoration: none; font-size: 14px; font-weight: 500; transition: all 0.3s;">
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
        // Palak Melava Status Filter Functions
        let currentPMStatus = 'ALL';
        
        function filterPalakMelavaStatus(status) {
            currentPMStatus = status;
            
            // Apply all filters without changing button colors
            applyPalakMelavaFilters();
        }
        
        // Apply All Palak Melava Filters
        function applyPalakMelavaFilters() {
            const schoolSearch = document.getElementById('pmSchoolSearch').value.toLowerCase();
            const hmSearch = document.getElementById('pmHeadMasterSearch').value.toLowerCase();
            const minMeetings = parseInt(document.getElementById('pmMinMeetings').value) || 0;
            const dateFrom = document.getElementById('pmDateFrom').value;
            const dateTo = document.getElementById('pmDateTo').value;
            const sortBy = document.getElementById('pmSortBy').value;
            
            const table = document.getElementById('palakMelavaTable');
            if (!table) return;
            
            const tbody = table.querySelector('tbody');
            const rows = Array.from(tbody.querySelectorAll('.palak-melava-row'));
            
            let visibleCount = 0;
            
            // Filter rows
            rows.forEach(row => {
                const rowStatus = row.getAttribute('data-status');
                const cells = row.cells;
                
                const udise = cells[1].textContent.toLowerCase();
                const schoolName = cells[2].textContent.toLowerCase();
                const hmName = cells[3].textContent.toLowerCase();
                const totalMeetings = parseInt(cells[4].textContent);
                const lastMeetingDate = cells[9].textContent.trim();
                
                // Apply filters
                let matchesStatus = currentPMStatus === 'ALL' || rowStatus === currentPMStatus;
                let matchesSchoolSearch = schoolSearch === '' || udise.includes(schoolSearch) || schoolName.includes(schoolSearch);
                let matchesHMSearch = hmSearch === '' || hmName.includes(hmSearch);
                let matchesMinMeetings = totalMeetings >= minMeetings;
                let matchesDateRange = true;
                
                if (lastMeetingDate && lastMeetingDate !== '-') {
                    const meetingDate = new Date(lastMeetingDate);
                    if (dateFrom && new Date(dateFrom) > meetingDate) {
                        matchesDateRange = false;
                    }
                    if (dateTo && new Date(dateTo) < meetingDate) {
                        matchesDateRange = false;
                    }
                }
                
                if (matchesStatus && matchesSchoolSearch && matchesHMSearch && matchesMinMeetings && matchesDateRange) {
                    row.style.display = '';
                    visibleCount++;
                } else {
                    row.style.display = 'none';
                }
            });
            
            // Sort visible rows
            const visibleRows = rows.filter(row => row.style.display !== 'none');
            sortPalakMelavaRows(visibleRows, sortBy);
            
            // Re-append sorted rows
            visibleRows.forEach(row => tbody.appendChild(row));
            
            // Update filter info
            const filterInfo = document.getElementById('pmFilterResultsInfo');
            const totalRows = rows.length;
            
            if (visibleCount === totalRows) {
                filterInfo.textContent = 'Showing all ' + totalRows + ' schools';
                filterInfo.style.color = '#28a745';
            } else {
                filterInfo.textContent = 'Filtered: ' + visibleCount + ' of ' + totalRows + ' schools';
                filterInfo.style.color = '#ff9800';
            }
        }
        
        // Sort Palak Melava Rows
        function sortPalakMelavaRows(rows, sortBy) {
            rows.sort((a, b) => {
                switch(sortBy) {
                    case 'school_asc':
                        return a.cells[2].textContent.localeCompare(b.cells[2].textContent);
                    case 'school_desc':
                        return b.cells[2].textContent.localeCompare(a.cells[2].textContent);
                    case 'meetings_desc':
                        return parseInt(b.cells[4].textContent) - parseInt(a.cells[4].textContent);
                    case 'meetings_asc':
                        return parseInt(a.cells[4].textContent) - parseInt(b.cells[4].textContent);
                    case 'date_desc':
                        const dateA = a.cells[9].textContent.trim();
                        const dateB = b.cells[9].textContent.trim();
                        if (dateA === '-') return 1;
                        if (dateB === '-') return -1;
                        return new Date(dateB) - new Date(dateA);
                    case 'date_asc':
                        const dateA2 = a.cells[9].textContent.trim();
                        const dateB2 = b.cells[9].textContent.trim();
                        if (dateA2 === '-') return 1;
                        if (dateB2 === '-') return -1;
                        return new Date(dateA2) - new Date(dateB2);
                    case 'parents_desc':
                        const parentsA = a.cells[10].textContent.trim();
                        const parentsB = b.cells[10].textContent.trim();
                        const numA = parentsA === '-' ? 0 : parseInt(parentsA);
                        const numB = parentsB === '-' ? 0 : parseInt(parentsB);
                        return numB - numA;
                    default:
                        return 0;
                }
            });
        }
        
        // Clear All Palak Melava Filters
        function clearPalakMelavaFilters() {
            document.getElementById('pmSchoolSearch').value = '';
            document.getElementById('pmHeadMasterSearch').value = '';
            document.getElementById('pmMinMeetings').value = '';
            document.getElementById('pmDateFrom').value = '';
            document.getElementById('pmDateTo').value = '';
            document.getElementById('pmSortBy').value = 'meetings_desc';
            
            currentPMStatus = 'ALL';
            filterPalakMelavaStatus('ALL');
            
            document.getElementById('pmFilterResultsInfo').textContent = '';
        }
        
        // View Palak Melava Details for a School
        function viewPalakMelavaDetails(udise, schoolName) {
            const url = '<%= request.getContextPath() %>/palak-melava-details.jsp?udise=' + encodeURIComponent(udise) + '&schoolName=' + encodeURIComponent(schoolName);
            window.open(url, '_blank', 'width=1200,height=800,scrollbars=yes,resizable=yes');
        }
    </script>
</body>
</html>
