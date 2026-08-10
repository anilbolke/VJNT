<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.model.Student" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%!
    /** Offered in the "Show" dropdown. */
    private static final int[] PAGE_SIZES = { 10, 20, 30, 50, 100 };

    /**
     * Whitelist the page size instead of trusting the parameter: this page holds the whole
     * filtered roster in memory and renders every row, so an arbitrary ?pageSize=999999 would
     * happily build a page with every student in the school on it.
     */
    private static int resolvePageSize(String raw) {
        if (raw != null && !raw.trim().isEmpty()) {
            try {
                int n = Integer.parseInt(raw.trim());
                for (int allowed : PAGE_SIZES) {
                    if (allowed == n) return n;
                }
            } catch (NumberFormatException ignored) {
                // fall through to the default
            }
        }
        return PAGE_SIZES[0];
    }

    /** URL-encode a filter value for the pagination links. */
    private static String enc(String v) {
        try {
            return java.net.URLEncoder.encode(v != null ? v : "", "UTF-8");
        } catch (java.io.UnsupportedEncodingException e) {
            return "";   // UTF-8 is always present
        }
    }
%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    
    String udiseNo = user.getUdiseNo();
    School school = schoolDAO.getSchoolByUdise(udiseNo);
    String schoolName = school != null ? school.getSchoolName() : "Unknown School";
    
    // Get all students for this UDISE
    List<Student> students = studentDAO.getStudentsByUdiseALL(udiseNo);
    
    // Filter parameters
    String classFilter = request.getParameter("class");
    String sectionFilter = request.getParameter("section");
    String classCategoryFilter = request.getParameter("classCategory");
    String searchFilter = request.getParameter("search");
    
    // Pagination
    int pageSize = resolvePageSize(request.getParameter("pageSize"));
    int currentPage = 1;
    String pageParam = request.getParameter("page");
    if (pageParam != null && !pageParam.isEmpty()) {
        try {
            currentPage = Integer.parseInt(pageParam);
            if (currentPage < 1) currentPage = 1;
        } catch (NumberFormatException e) {
            currentPage = 1;
        }
    }
    
    // Bulk deactivation is School Coordinator only. This page is also reachable by
    // SUPER_DIVISION_OFFICER, so the capability is gated on the role, not on page access.
    boolean canBulkDeactivate = user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR);

    // status = active | inactive | all  (default: active, since that is what schools work with)
    String statusFilter = request.getParameter("status");
    if (statusFilter == null || statusFilter.isEmpty()) statusFilter = "active";

    // Every pagination link carries the full filter set. Built once, because the links used to be
    // assembled inline and had drifted: classCategory was missing from all of them (paging away
    // silently dropped that filter) and search was interpolated raw, so a name with a space or
    // an "&" produced a broken link.
    String linkQuery = "class="         + enc(classFilter)
                     + "&section="      + enc(sectionFilter)
                     + "&classCategory=" + enc(classCategoryFilter)
                     + "&search="       + enc(searchFilter)
                     + "&status="       + enc(statusFilter)
                     + "&pageSize="     + pageSize;

    List<Student> filteredStudents = new ArrayList<>();

    int activeCount = 0, inactiveCount = 0;
    for (Student student : students) {
        if (student.isActive()) activeCount++; else inactiveCount++;
    }

    for (Student student : students) {
        boolean matchClass = (classFilter == null || classFilter.isEmpty() || student.getStudentClass().equals(classFilter));
        boolean matchSection = (sectionFilter == null || sectionFilter.isEmpty() || student.getSection().equals(sectionFilter));
        boolean matchClassCategory = (classCategoryFilter == null || classCategoryFilter.isEmpty() || student.getClassCategory().equals(classCategoryFilter));
        boolean matchSearch = (searchFilter == null || searchFilter.isEmpty() ||
                             student.getStudentName().toLowerCase().contains(searchFilter.toLowerCase()) ||
                             (student.getStudentPen() != null && student.getStudentPen().contains(searchFilter)));
        boolean matchStatus = "all".equals(statusFilter)
                              || ("inactive".equals(statusFilter) && !student.isActive())
                              || ("active".equals(statusFilter) && student.isActive());

        if (matchClass && matchSection && matchClassCategory && matchSearch && matchStatus) {
            filteredStudents.add(student);
        }
    }
    
    // Calculate pagination
    int totalStudents = filteredStudents.size();
    int totalPages = (int) Math.ceil((double) totalStudents / pageSize);
    if (currentPage > totalPages && totalPages > 0) {
        currentPage = totalPages;
    }
    
    int startIndex = (currentPage - 1) * pageSize;
    int endIndex = Math.min(startIndex + pageSize, totalStudents);
    
    List<Student> paginatedStudents = new ArrayList<>();
    if (startIndex < totalStudents) {
        paginatedStudents = filteredStudents.subList(startIndex, endIndex);
    }

    // "Select all" only reaches the rows actually rendered, so the label states the count up
    // front rather than leaving the user to infer it from the page size.
    int activeOnPage = 0;
    for (Student s2 : paginatedStudents) {
        if (s2.isActive()) activeOnPage++;
    }
    
    // Get unique classes and sections for filters
    Set<String> classes = new TreeSet<>();
    Set<String> sections = new TreeSet<>();
    Set<String> classCategories = new TreeSet<>();
    for (Student student : students) {
        classes.add(student.getStudentClass());
        if (student.getSection() != null) {
            sections.add(student.getSection());
        }
        if (student.getClassCategory() != null) {
            classCategories.add(student.getClassCategory());
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Select Student to Edit - <%= schoolName %></title>
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
            padding: 20px;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        .header {
            background: #f0f2f5;
            color: #000;
            padding: 25px 30px;
            border-bottom: 3px solid #667eea;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            font-size: 26px;
            color: #000;
        }
        
        .header-subtitle {
            font-size: 14px;
            color: #666;
            margin-top: 5px;
        }
        
        .btn-back {
            background: #6c757d;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            font-weight: 600;
            transition: background 0.3s;
        }
        
        .btn-back:hover {
            background: #5a6268;
        }
        
        .content {
            padding: 30px;
        }
        
        .filters-section {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 25px;
        }
        
        .filters-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 15px;
        }
        
        .filter-group {
            display: flex;
            flex-direction: column;
        }
        
        .filter-group label {
            font-weight: 600;
            color: #333;
            margin-bottom: 6px;
            font-size: 13px;
        }
        
        .filter-group input,
        .filter-group select {
            padding: 10px 12px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            font-size: 13px;
            font-family: inherit;
            transition: all 0.3s;
        }
        
        .filter-group input:focus,
        .filter-group select:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .filter-buttons {
            display: flex;
            gap: 10px;
        }
        
        .btn-filter {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s;
            flex: 1;
        }
        
        .btn-filter:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        
        .btn-clear {
            background: #95a5a6;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s;
            flex: 1;
        }
        
        .btn-clear:hover {
            background: #7f8c8d;
        }
        
        .stats {
            background: white;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            border-left: 4px solid #667eea;
        }
        
        .stat-text {
            color: #555;
            font-size: 14px;
            font-weight: 600;
        }
        
        .stat-number {
            color: #667eea;
            font-weight: 700;
            font-size: 16px;
        }
        
        .students-section {
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
        }
        
        .section-title {
            font-size: 18px;
            font-weight: 700;
            color: #333;
            padding: 20px;
            background: #f8f9fa;
            border-bottom: 2px solid #e0e0e0;
        }
        
        .no-data {
            text-align: center;
            padding: 50px 20px;
            color: #999;
        }
        
        .no-data-icon {
            font-size: 48px;
            margin-bottom: 15px;
        }
        
        .students-list {
            list-style: none;
        }
        
        .student-item {
            padding: 18px 20px;
            border-bottom: 1px solid #e0e0e0;
            display: flex;
            justify-content: space-between;
            align-items: center;
            transition: all 0.3s;
            cursor: pointer;
        }
        
        .student-item:hover {
            background: #f8f9fa;
            transform: translateX(5px);
        }
        
        .student-item:last-child {
            border-bottom: none;
        }
        
        .student-info {
            flex: 1;
        }
        
        .student-name {
            font-size: 15px;
            font-weight: 600;
            color: #333;
            margin-bottom: 5px;
        }
        
        .student-details {
            font-size: 12px;
            color: #999;
            display: flex;
            gap: 15px;
        }
        
        .student-detail-item {
            display: flex;
            align-items: center;
            gap: 5px;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
            background: #e3f2fd;
            color: #1976d2;
        }
        
        .badge-section {
            background: #f3e5f5;
            color: #7b1fa2;
        }
        
        .btn-edit {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 8px 16px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
            text-decoration: none;
            display: inline-block;
            transition: all 0.3s;
            white-space: nowrap;
            margin-left: 10px;
        }
        
        .btn-edit:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }
        
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 8px;
            padding: 20px;
            background: #f8f9fa;
            border-top: 1px solid #e0e0e0;
            flex-wrap: wrap;
        }
        
        .pagination a,
        .pagination span {
            display: inline-block;
            padding: 8px 12px;
            border: 1px solid #e0e0e0;
            border-radius: 6px;
            text-decoration: none;
            color: #333;
            font-size: 13px;
            font-weight: 500;
            transition: all 0.2s;
        }
        
        .pagination a:hover {
            background: #667eea;
            color: white;
            border-color: #667eea;
        }
        
        .pagination .active {
            background: #667eea;
            color: white;
            border-color: #667eea;
        }
        
        .pagination .disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
        
        @media (max-width: 768px) {
            .header {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }
            
            .filters-grid {
                grid-template-columns: 1fr;
            }
            
            .student-item {
                flex-direction: column;
                align-items: flex-start;
            }
            
            .btn-edit {
                margin-left: 0;
                margin-top: 10px;
                width: 100%;
                text-align: center;
            }
            
            .student-details {
                flex-direction: column;
                gap: 5px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1>✏️ Edit Student</h1>
                <div class="header-subtitle">School: <%= schoolName %> (UDISE: <%= udiseNo %>)</div>
            </div>
            <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="btn-back">🏠 Back to Dashboard</a>
        </div>
        
        <div class="content">
            <!-- Filters Section -->
            <div class="filters-section">
                <h3 style="margin-bottom: 15px; font-size: 16px; color: #333;">🔍 Search & Filter Students</h3>
                <form method="get" action="">
                    <div class="filters-grid">
                        <div class="filter-group">
                            <label for="class">Class</label>
                            <select name="class" id="class">
                                <option value="">All Classes</option>
                                <% for (String cls : classes) { %>
                                <option value="<%= cls %>" <%= (classFilter != null && classFilter.equals(cls)) ? "selected" : "" %>>
                                    Class <%= cls %>
                                </option>
                                <% } %>
                            </select>
                        </div>
                        
                        <div class="filter-group">
                            <label for="section">Section</label>
                            <select name="section" id="section">
                                <option value="">All Sections</option>
                                <% for (String sec : sections) { %>
                                <option value="<%= sec %>" <%= (sectionFilter != null && sectionFilter.equals(sec)) ? "selected" : "" %>>
                                    Section <%= sec %>
                                </option>
                                <% } %>
                            </select>
                        </div>
                        
                        <div class="filter-group">
                            <label for="classCategory">Class Category</label>
                            <select name="classCategory" id="classCategory">
                                <option value="">All Categories</option>
                                <option value="Primary" <%= (classCategoryFilter != null && classCategoryFilter.equals("Primary")) ? "selected" : "" %>>Primary</option>
                                <option value="Higher Primary" <%= (classCategoryFilter != null && classCategoryFilter.equals("Higher Primary")) ? "selected" : "" %>>Higher Primary</option>
                                <option value="Secondary" <%= (classCategoryFilter != null && classCategoryFilter.equals("Secondary")) ? "selected" : "" %>>Secondary</option>
                            </select>
                        </div>
                        
                        <div class="filter-group">
                            <label for="search">Search (Name/PEN)</label>
                            <input type="text" name="search" id="search" placeholder="Enter name or PEN"
                                   value="<%= (searchFilter != null) ? searchFilter : "" %>">
                        </div>

                        <div class="filter-group">
                            <label for="status">Status</label>
                            <select name="status" id="status">
                                <option value="active"   <%= "active".equals(statusFilter)   ? "selected" : "" %>>Active only</option>
                                <option value="inactive" <%= "inactive".equals(statusFilter) ? "selected" : "" %>>Inactive only</option>
                                <option value="all"      <%= "all".equals(statusFilter)      ? "selected" : "" %>>All</option>
                            </select>
                        </div>

                        <div class="filter-group">
                            <label for="pageSize">Students per page</label>
                            <%-- Selecting more per page is what makes bulk deactivation practical:
                                 "Select all" only ever reaches the rows actually rendered. Submits
                                 on change and drops back to page 1, since the old page number is
                                 meaningless once the page size moves. --%>
                            <select name="pageSize" id="pageSize"
                                    onchange="this.form.page.value = 1; this.form.submit();">
                                <% for (int size : PAGE_SIZES) { %>
                                <option value="<%= size %>" <%= pageSize == size ? "selected" : "" %>>
                                    Show <%= size %>
                                </option>
                                <% } %>
                            </select>
                        </div>
                    </div>

                    <%-- Filtering always restarts at page 1; the pagination links set this. --%>
                    <input type="hidden" name="page" value="1">
                    
                    <div class="filter-buttons">
                        <button type="submit" class="btn-filter">🔍 Filter</button>
                        <%-- Clearing the filters keeps the chosen page size; it is a view
                             preference, not a filter. --%>
                        <a href="?pageSize=<%= pageSize %>" class="btn-clear">Clear Filters</a>
                    </div>
                </form>
            </div>
            
            <!-- Statistics -->
            <div class="stats">
                <span class="stat-text">📊 Found: <span class="stat-number"><%= filteredStudents.size() %></span> students</span>
                <span style="margin-left: 30px;">📚 Total: <span class="stat-number"><%= students.size() %></span> students</span>
                <span style="margin-left: 30px;">✅ Active: <span class="stat-number"><%= activeCount %></span></span>
                <span style="margin-left: 30px;">🚫 Inactive: <span class="stat-number"><%= inactiveCount %></span></span>
                <% if (totalStudents > 0) { %>
                <span style="margin-left: 30px;">👁️ Showing
                    <span class="stat-number"><%= startIndex + 1 %>–<%= endIndex %></span>
                    of <span class="stat-number"><%= totalStudents %></span>
                </span>
                <% } %>
            </div>

            <% if (canBulkDeactivate) { %>
            <!-- Bulk deactivate action bar -->
            <div id="bulkBar" style="display:none; background:#fff5f5; border:2px solid #feb2b2;
                        border-radius:10px; padding:14px 18px; margin-bottom:18px;
                        align-items:center; gap:14px; flex-wrap:wrap;">
                <strong style="color:#c53030; font-size:15px;">
                    <span id="selCount">0</span> student(s) selected
                </strong>
                <input type="text" id="bulkReason" placeholder="Reason (optional) — e.g. transferred out"
                       maxlength="255"
                       style="flex:1; min-width:220px; border:1px solid #e2e8f0; border-radius:8px;
                              padding:8px 12px; font-size:14px; font-family:inherit;">
                <button type="button" id="bulkBtn" onclick="bulkDeactivate()"
                        style="background:#e53e3e; color:#fff; border:none; border-radius:8px;
                               padding:10px 20px; font-size:14px; font-weight:600; cursor:pointer;">
                    🚫 Mark Selected Inactive
                </button>
                <button type="button" onclick="clearSelection()"
                        style="background:#e2e8f0; color:#4a5568; border:none; border-radius:8px;
                               padding:10px 16px; font-size:14px; font-weight:600; cursor:pointer;">
                    Clear
                </button>
                <div style="flex-basis:100%; font-size:12px; color:#742a2a;">
                    Inactive students are excluded from phase completion, promotion and reports.
                    There is no bulk undo — reversing this is one student at a time via Edit.
                </div>
            </div>
            <% } %>
            
            <!-- Students List -->
            <div class="students-section">
                <div class="section-title">📋 Select Student to Edit</div>
                
                <% if (filteredStudents.isEmpty()) { %>
                    <div class="no-data">
                        <div class="no-data-icon">📭</div>
                        <p>No students found matching your criteria.</p>
                    </div>
                <% } else { %>
                    <% if (canBulkDeactivate) { %>
                    <div style="padding:10px 4px 14px; border-bottom:1px solid #e2e8f0; margin-bottom:10px;">
                        <label style="display:inline-flex; align-items:center; gap:8px; font-size:14px;
                                      color:#4a5568; cursor:pointer; font-weight:600;">
                            <input type="checkbox" id="selectAll" onclick="toggleAll(this)"
                                   style="width:17px; height:17px; cursor:pointer;">
                            Select all <%= activeOnPage %> active student(s) on this page
                        </label>
                    </div>
                    <% } %>
                    <ul class="students-list">
                        <%
                        int rowNum = startIndex + 1;
                        for (Student student : paginatedStudents) {
                            boolean active = student.isActive();
                        %>
                        <li class="student-item" style="<%= !active ? "opacity:0.72;" : "" %>">
                            <% if (canBulkDeactivate) { %>
                            <input type="checkbox" class="stu-check" value="<%= student.getStudentId() %>"
                                   onclick="updateSelection()" <%= !active ? "disabled" : "" %>
                                   title="<%= !active ? "Already inactive" : "Select for bulk deactivation" %>"
                                   style="width:17px; height:17px; margin-right:14px; cursor:<%= active ? "pointer" : "not-allowed" %>;">
                            <% } %>
                            <div class="student-info">
                                <div class="student-name"><%= rowNum %>. <%= student.getStudentName() %></div>
                                <div class="student-details">
                                    <span class="student-detail-item">
                                        📌 PEN: <strong><%= (student.getStudentPen() != null) ? student.getStudentPen() : "N/A" %></strong>
                                    </span>
                                    <span class="badge">Class <%= student.getStudentClass() %></span>
                                    <span class="badge badge-section">Section <%= student.getSection() %></span>
                                    <span class="student-detail-item">👥 <%= student.getGender() %></span>
                                    <% if (active) { %>
                                        <span class="badge" style="background:#c6f6d5; color:#22543d;">✅ Active</span>
                                    <% } else { %>
                                        <span class="badge" style="background:#fed7d7; color:#822727;">🚫 Inactive</span>
                                    <% } %>
                                </div>
                            </div>
                            <a href="<%= request.getContextPath() %>/add-modify-student.jsp?studentId=<%= student.getStudentId() %>" class="btn-edit">
                                ✏️ Edit
                            </a>
                        </li>
                        <% rowNum++; } %>
                    </ul>
                    
                    <!-- Pagination -->
                    <% if (totalPages > 1) { %>
                    <div class="pagination">
                        <% if (currentPage > 1) { %>
                            <a href="?<%= linkQuery %>&page=1">First</a>
                            <a href="?<%= linkQuery %>&page=<%= currentPage - 1 %>">← Previous</a>
                        <% } %>

                        <% for (int i = Math.max(1, currentPage - 2); i <= Math.min(totalPages, currentPage + 2); i++) { %>
                            <% if (i == currentPage) { %>
                                <span class="active"><%= i %></span>
                            <% } else { %>
                                <a href="?<%= linkQuery %>&page=<%= i %>"><%= i %></a>
                            <% } %>
                        <% } %>

                        <% if (currentPage < totalPages) { %>
                            <a href="?<%= linkQuery %>&page=<%= currentPage + 1 %>">Next →</a>
                            <a href="?<%= linkQuery %>&page=<%= totalPages %>">Last</a>
                        <% } %>
                    </div>
                    <% } %>
                <% } %>
            </div>
        </div>
    </div>

<% if (canBulkDeactivate) { %>
<script>
    var CTX = '<%= request.getContextPath() %>';

    function checkboxes() {
        return Array.prototype.slice.call(document.querySelectorAll('.stu-check'));
    }

    function selectedIds() {
        return checkboxes().filter(function (c) { return c.checked && !c.disabled; })
                           .map(function (c) { return c.value; });
    }

    function toggleAll(master) {
        checkboxes().forEach(function (c) {
            // Inactive rows are disabled; leave them alone.
            if (!c.disabled) c.checked = master.checked;
        });
        updateSelection();
    }

    function updateSelection() {
        var n = selectedIds().length;
        document.getElementById('selCount').textContent = n;
        document.getElementById('bulkBar').style.display = n > 0 ? 'flex' : 'none';

        var master = document.getElementById('selectAll');
        if (master) {
            var selectable = checkboxes().filter(function (c) { return !c.disabled; });
            master.checked = selectable.length > 0 && n === selectable.length;
        }
    }

    function clearSelection() {
        checkboxes().forEach(function (c) { c.checked = false; });
        var master = document.getElementById('selectAll');
        if (master) master.checked = false;
        updateSelection();
    }

    function bulkDeactivate() {
        var ids = selectedIds();
        if (ids.length === 0) { alert('No students selected.'); return; }

        // No bulk undo exists, so the count is spelled out and the names of the first few are
        // shown — a mis-click on "select all" is otherwise invisible until it is too late.
        var names = checkboxes()
            .filter(function (c) { return c.checked && !c.disabled; })
            .slice(0, 5)
            .map(function (c) {
                var item = c.closest('.student-item');
                var el = item ? item.querySelector('.student-name') : null;
                return el ? '  • ' + el.textContent.trim() : '';
            })
            .filter(function (s) { return s; })
            .join('\n');

        var msg = 'Mark ' + ids.length + ' student(s) INACTIVE?\n\n' + names +
                  (ids.length > 5 ? '\n  … and ' + (ids.length - 5) + ' more' : '') +
                  '\n\nInactive students are excluded from phase completion, promotion and reports.' +
                  '\nThere is no bulk undo — each one must be reactivated individually via Edit.';
        if (!confirm(msg)) return;

        var btn = document.getElementById('bulkBtn');
        btn.disabled = true;
        btn.textContent = 'Working…';

        var params = new URLSearchParams();
        params.append('studentIds', ids.join(','));
        params.append('reason', document.getElementById('bulkReason').value.trim());

        fetch(CTX + '/bulk-deactivate-students', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: params.toString()
        })
        .then(function (r) { return r.json(); })
        .then(function (data) {
            if (!data.success) {
                alert('Error: ' + (data.message || 'Could not deactivate.'));
                btn.disabled = false;
                btn.textContent = '🚫 Mark Selected Inactive';
                return;
            }
            var msg = data.deactivated + ' student(s) marked inactive.';
            if (data.skipped > 0) {
                msg += '\n' + data.skipped + ' skipped (already inactive, or not in this school).';
            }
            if (data.message) msg += '\n' + data.message;
            alert(msg);
            window.location.reload();
        })
        .catch(function (e) {
            alert('Network error: ' + e.message);
            btn.disabled = false;
            btn.textContent = '🚫 Mark Selected Inactive';
        });
    }

    document.addEventListener('DOMContentLoaded', updateSelection);
</script>
<% } %>
</body>
</html>
