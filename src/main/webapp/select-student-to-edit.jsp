<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.model.Student" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    StudentDAO studentDAO = new StudentDAO();
    SchoolDAO schoolDAO = new SchoolDAO();
    
    String udiseNo = user.getUdiseNo();
    School school = schoolDAO.getSchoolByUdise(udiseNo);
    String schoolName = school != null ? school.getSchoolName() : "Unknown School";
    
    // Get all students for this UDISE
    List<Student> students = studentDAO.getStudentsByUdise(udiseNo);
    
    // Filter parameters
    String classFilter = request.getParameter("class");
    String sectionFilter = request.getParameter("section");
    String classCategoryFilter = request.getParameter("classCategory");
    String searchFilter = request.getParameter("search");
    
    // Pagination
    int pageSize = 10;
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
    
    List<Student> filteredStudents = new ArrayList<>();
    
    for (Student student : students) {
        boolean matchClass = (classFilter == null || classFilter.isEmpty() || student.getStudentClass().equals(classFilter));
        boolean matchSection = (sectionFilter == null || sectionFilter.isEmpty() || student.getSection().equals(sectionFilter));
        boolean matchClassCategory = (classCategoryFilter == null || classCategoryFilter.isEmpty() || student.getClassCategory().equals(classCategoryFilter));
        boolean matchSearch = (searchFilter == null || searchFilter.isEmpty() || 
                             student.getStudentName().toLowerCase().contains(searchFilter.toLowerCase()) ||
                             (student.getStudentPen() != null && student.getStudentPen().contains(searchFilter)));
        
        if (matchClass && matchSection && matchClassCategory && matchSearch) {
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
                    </div>
                    
                    <div class="filter-buttons">
                        <button type="submit" class="btn-filter">🔍 Filter</button>
                        <a href="?" class="btn-clear">Clear Filters</a>
                    </div>
                </form>
            </div>
            
            <!-- Statistics -->
            <div class="stats">
                <span class="stat-text">📊 Found: <span class="stat-number"><%= filteredStudents.size() %></span> students</span>
                <span style="margin-left: 30px;">📚 Total: <span class="stat-number"><%= students.size() %></span> students</span>
            </div>
            
            <!-- Students List -->
            <div class="students-section">
                <div class="section-title">📋 Select Student to Edit</div>
                
                <% if (filteredStudents.isEmpty()) { %>
                    <div class="no-data">
                        <div class="no-data-icon">📭</div>
                        <p>No students found matching your criteria.</p>
                    </div>
                <% } else { %>
                    <ul class="students-list">
                        <% 
                        int rowNum = startIndex + 1;
                        for (Student student : paginatedStudents) { 
                        %>
                        <li class="student-item">
                            <div class="student-info">
                                <div class="student-name"><%= rowNum %>. <%= student.getStudentName() %></div>
                                <div class="student-details">
                                    <span class="student-detail-item">
                                        📌 PEN: <strong><%= (student.getStudentPen() != null) ? student.getStudentPen() : "N/A" %></strong>
                                    </span>
                                    <span class="badge">Class <%= student.getStudentClass() %></span>
                                    <span class="badge badge-section">Section <%= student.getSection() %></span>
                                    <span class="student-detail-item">👥 <%= student.getGender() %></span>
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
                            <a href="?class=<%= classFilter != null ? classFilter : "" %>&section=<%= sectionFilter != null ? sectionFilter : "" %>&search=<%= searchFilter != null ? searchFilter : "" %>&page=1">First</a>
                            <a href="?class=<%= classFilter != null ? classFilter : "" %>&section=<%= sectionFilter != null ? sectionFilter : "" %>&search=<%= searchFilter != null ? searchFilter : "" %>&page=<%= currentPage - 1 %>">← Previous</a>
                        <% } %>
                        
                        <% for (int i = Math.max(1, currentPage - 2); i <= Math.min(totalPages, currentPage + 2); i++) { %>
                            <% if (i == currentPage) { %>
                                <span class="active"><%= i %></span>
                            <% } else { %>
                                <a href="?class=<%= classFilter != null ? classFilter : "" %>&section=<%= sectionFilter != null ? sectionFilter : "" %>&search=<%= searchFilter != null ? searchFilter : "" %>&page=<%= i %>"><%= i %></a>
                            <% } %>
                        <% } %>
                        
                        <% if (currentPage < totalPages) { %>
                            <a href="?class=<%= classFilter != null ? classFilter : "" %>&section=<%= sectionFilter != null ? sectionFilter : "" %>&search=<%= searchFilter != null ? searchFilter : "" %>&page=<%= currentPage + 1 %>">Next →</a>
                            <a href="?class=<%= classFilter != null ? classFilter : "" %>&section=<%= sectionFilter != null ? sectionFilter : "" %>&search=<%= searchFilter != null ? searchFilter : "" %>&page=<%= totalPages %>">Last</a>
                        <% } %>
                    </div>
                    <% } %>
                <% } %>
            </div>
        </div>
    </div>
</body>
</html>
