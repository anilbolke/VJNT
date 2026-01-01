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
    
    int totalSchools = allSchools.size();
    
    // Use all schools - no server-side pagination
    List<Map<String, Object>> palakMelavaStatus = allSchools;
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
                    
                    <!-- Status Filter Dropdown -->
                    <div>
                        <label style="display: block; margin-bottom: 5px; color: #555; font-weight: 500; font-size: 13px;">
                            📊 Status Filter
                        </label>
                        <select id="pmStatusFilter" 
                                style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; outline: none; cursor: pointer;"
                                onchange="applyPalakMelavaFilters()">
                            <option value="ALL">All Schools</option>
                            <option value="NO_MEETING">No Meetings</option>
                            <option value="PENDING_APPROVAL">Pending Approval</option>
                            <option value="COMPLETED">Completed</option>
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
                            <td class="sr-no-cell"><strong>-</strong></td>
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
            
            <!-- Total Schools Info -->
            <div id="pmTotalInfo" style="margin-top: 20px; padding: 15px; background: #f8f9fa; border-radius: 8px; text-align: center;">
                <div style="color: #666; font-size: 14px;">
                    Total: <strong style="color: #2196f3; font-size: 16px;"><%= totalSchools %></strong> schools loaded
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Palak Melava Status Filter Functions
        let currentPMStatus = 'ALL';
        
        function filterPalakMelavaStatus(status) {
            currentPMStatus = status;
            
            // Update dropdown to match button click
            const statusFilter = document.getElementById('pmStatusFilter');
            if (statusFilter) {
                statusFilter.value = status;
            }
            
            // Apply all filters
            applyPalakMelavaFilters();
        }
        
        // Apply All Palak Melava Filters
        function applyPalakMelavaFilters() {
            const schoolSearch = document.getElementById('pmSchoolSearch').value.toLowerCase();
            const hmSearch = document.getElementById('pmHeadMasterSearch').value.toLowerCase();
            const minMeetings = parseInt(document.getElementById('pmMinMeetings').value) || 0;
            const dateFrom = document.getElementById('pmDateFrom').value;
            const dateTo = document.getElementById('pmDateTo').value;
            const statusFilter = document.getElementById('pmStatusFilter').value;
            
            // Update currentPMStatus based on dropdown
            currentPMStatus = statusFilter;
            
            // Update button states
            updateStatusButtonStates();
            
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
            
            // Update serial numbers for visible rows
            updateSerialNumbers();
            
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
        
        // Update serial numbers for visible rows
        function updateSerialNumbers() {
            const table = document.getElementById('palakMelavaTable');
            if (!table) return;
            
            const tbody = table.querySelector('tbody');
            const rows = tbody.querySelectorAll('.palak-melava-row');
            let srNo = 1;
            
            rows.forEach(row => {
                const srNoCell = row.querySelector('.sr-no-cell strong');
                if (row.style.display !== 'none') {
                    if (srNoCell) {
                        srNoCell.textContent = srNo++;
                    }
                }
            });
        }
        
        // Update status button states to match dropdown
        function updateStatusButtonStates() {
            const buttons = {
                'ALL': document.getElementById('pmFilterAll'),
                'NO_MEETING': document.getElementById('pmFilterNoMeeting'),
                'PENDING_APPROVAL': document.getElementById('pmFilterPending'),
                'COMPLETED': document.getElementById('pmFilterCompleted')
            };
            
            // Remove active class from all buttons
            Object.values(buttons).forEach(btn => {
                if (btn) {
                    btn.classList.remove('active');
                    const status = Object.keys(buttons).find(key => buttons[key] === btn);
                    if (status === 'ALL') {
                        btn.style.background = 'white';
                        btn.style.color = '#667eea';
                    } else if (status === 'NO_MEETING') {
                        btn.style.background = 'white';
                        btn.style.color = '#f44336';
                    } else if (status === 'PENDING_APPROVAL') {
                        btn.style.background = 'white';
                        btn.style.color = '#ff9800';
                    } else if (status === 'COMPLETED') {
                        btn.style.background = 'white';
                        btn.style.color = '#4caf50';
                    }
                }
            });
            
            // Add active class to current button
            const activeBtn = buttons[currentPMStatus];
            if (activeBtn) {
                activeBtn.classList.add('active');
                if (currentPMStatus === 'ALL') {
                    activeBtn.style.background = '#667eea';
                    activeBtn.style.color = 'white';
                } else if (currentPMStatus === 'NO_MEETING') {
                    activeBtn.style.background = '#f44336';
                    activeBtn.style.color = 'white';
                } else if (currentPMStatus === 'PENDING_APPROVAL') {
                    activeBtn.style.background = '#ff9800';
                    activeBtn.style.color = 'white';
                } else if (currentPMStatus === 'COMPLETED') {
                    activeBtn.style.background = '#4caf50';
                    activeBtn.style.color = 'white';
                }
            }
        }
        
        // Clear All Palak Melava Filters
        function clearPalakMelavaFilters() {
            document.getElementById('pmSchoolSearch').value = '';
            document.getElementById('pmHeadMasterSearch').value = '';
            document.getElementById('pmMinMeetings').value = '';
            document.getElementById('pmDateFrom').value = '';
            document.getElementById('pmDateTo').value = '';
            document.getElementById('pmStatusFilter').value = 'ALL';
            
            currentPMStatus = 'ALL';
            filterPalakMelavaStatus('ALL');
            
            document.getElementById('pmFilterResultsInfo').textContent = '';
        }
        
        // View Palak Melava Details for a School
        function viewPalakMelavaDetails(udise, schoolName) {
            const url = '<%= request.getContextPath() %>/palak-melava-details.jsp?udise=' + encodeURIComponent(udise) + '&schoolName=' + encodeURIComponent(schoolName);
            window.open(url, '_blank', 'width=1200,height=800,scrollbars=yes,resizable=yes');
        }
        
        // Initialize serial numbers on page load
        window.addEventListener('DOMContentLoaded', function() {
            updateSerialNumbers();
        });
    </script>
</body>
</html>
