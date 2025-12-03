<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.Student" %>
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
    String searchFilter = request.getParameter("search");
    
    // Pagination parameters
    int pageSize = 15;
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
        boolean matchSearch = (searchFilter == null || searchFilter.isEmpty() || 
                             student.getStudentName().toLowerCase().contains(searchFilter.toLowerCase()) ||
                             (student.getStudentPen() != null && student.getStudentPen().contains(searchFilter)));
        
        if (matchClass && matchSection && matchSearch) {
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
    for (Student student : students) {
        classes.add(student.getStudentClass());
        if (student.getSection() != null) {
            sections.add(student.getSection());
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Data - <%= schoolName %> (UDISE: <%= udiseNo %>)</title>
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
            background: #f0f2f5;
            color: #000;
            padding: 25px 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .header-content {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            font-size: 26px;
            margin-bottom: 5px;
            color: #000;
        }
        
        .header-info {
            text-align: right;
        }
        
        .user-info {
            font-size: 14px;
            margin-bottom: 3px;
            color: #000;
        }
        
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
            display: inline-block;
            transition: all 0.3s;
        }
        
        .btn-logout {
            background: rgba(255,255,255,0.2);
            color: black;
            margin-left: 10px;
        }
        
        .btn-logout:hover {
            background: rgba(255,255,255,0.3);
        }
        
        .btn-back {
            background: rgba(255,255,255,0.2);
            color: black;
            margin-left: 10px;
        }
        
        .btn-back:hover {
            background: rgba(255,255,255,0.3);
        }
        
        .container {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 30px;
        }
        
        .breadcrumb {
            background: white;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
            font-size: 14px;
        }
        
        .breadcrumb strong {
            color: #333;
        }
        
        .section {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            margin-bottom: 30px;
        }
        
        .section-title {
            font-size: 22px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        
        .filters {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .filter-group {
            display: flex;
            flex-direction: column;
        }
        
        .filter-group label {
            font-size: 13px;
            font-weight: 600;
            color: #4a5568;
            margin-bottom: 6px;
        }
        
        .filter-group input,
        .filter-group select {
            padding: 10px 12px;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            font-size: 13px;
            transition: all 0.2s;
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
        
        .filter-buttons button {
            padding: 10px 16px;
            border: none;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
        }
        
        .btn-filter {
            background: #667eea;
            color: white;
        }
        
        .btn-filter:hover {
            background: #5568d3;
        }
        
        .btn-clear {
            background: #e2e8f0;
            color: #4a5568;
        }
        
        .btn-clear:hover {
            background: #cbd5e0;
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .stat-card {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            border-left: 3px solid #667eea;
        }
        
        .stat-value {
            font-size: 24px;
            font-weight: bold;
            color: #667eea;
        }
        
        .stat-label {
            font-size: 12px;
            color: #718096;
            margin-top: 5px;
        }
        
        .table-responsive {
            overflow-x: auto;
        }
        
        .table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .table th {
            background: #f8f9fa;
            padding: 14px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #e2e8f0;
            font-size: 13px;
        }
        
        .table td {
            padding: 12px 14px;
            border-bottom: 1px solid #e2e8f0;
            font-size: 13px;
        }
        
        .table tr:hover {
            background: #f8f9fa;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .badge-primary {
            background: #e3f2fd;
            color: #1976d2;
        }
        
        .badge-success {
            background: #e8f5e9;
            color: #388e3c;
        }
        
        .badge-warning {
            background: #fff3e0;
            color: #f57c00;
        }
        
        .badge-info {
            background: #e1f5fe;
            color: #0288d1;
        }
        
        .no-data {
            text-align: center;
            padding: 40px 20px;
            color: #718096;
        }
        
        .no-data-icon {
            font-size: 48px;
            margin-bottom: 10px;
        }
        
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 8px;
            margin-top: 20px;
            flex-wrap: wrap;
        }
        
        .pagination a,
        .pagination span {
            display: inline-block;
            padding: 8px 12px;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            text-decoration: none;
            color: #4a5568;
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
            cursor: default;
        }
        
        .pagination .disabled {
            opacity: 0.5;
            cursor: not-allowed;
            background: #f8f9fa;
        }
        
        .pagination .disabled:hover {
            background: #f8f9fa;
            color: #4a5568;
            border-color: #e2e8f0;
        }
        
        .pagination-info {
            text-align: center;
            color: #718096;
            font-size: 13px;
            margin-top: 15px;
        }
        
        .btn-action {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 6px 12px;
            border-radius: 6px;
            text-decoration: none;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
            transition: all 0.3s;
            box-shadow: 0 2px 6px rgba(102, 126, 234, 0.3);
            white-space: nowrap;
        }
        
        .btn-action:hover {
            background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
            box-shadow: 0 4px 10px rgba(102, 126, 234, 0.4);
            transform: translateY(-2px);
        }
        
        .btn-action-secondary {
            background: #28a745;
            color: white;
            padding: 6px 12px;
            border-radius: 6px;
            text-decoration: none;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
            transition: all 0.3s;
            box-shadow: 0 2px 6px rgba(40, 167, 69, 0.3);
            white-space: nowrap;
            margin-left: 5px;
            border: none;
            cursor: pointer;
        }
        
        .btn-action-secondary:hover {
            background: #218838;
            box-shadow: 0 4px 10px rgba(40, 167, 69, 0.4);
            transform: translateY(-2px);
        }
        
        /* Toggle Group Styles */
        .activity-group-header {
            cursor: pointer;
            user-select: none;
            transition: all 0.3s;
        }
        
        .activity-group-header:hover {
            filter: brightness(1.1);
        }
        
        .toggle-icon {
            transition: transform 0.3s;
        }

        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
            animation: fadeIn 0.3s;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        .modal-content {
            background-color: #fff;
            margin: 5% auto;
            padding: 0;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.15);
            width: 90%;
            max-width: 800px;
            animation: slideDown 0.3s;
            max-height: 90vh;
            overflow-y: auto;
        }
        
        @keyframes slideDown {
            from {
                transform: translateY(-50px);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }
        
        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 28px 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-radius: 12px 12px 0 0;
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.25);
        }
        
        .modal-header h2 {
            margin: 0;
            font-size: 24px;
            font-weight: 700;
            letter-spacing: 0.5px;
        }
        
        .close {
            color: white;
            font-size: 32px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s ease;
            padding: 0 8px;
            line-height: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.1);
        }
        
        .close:hover {
            color: #ffffff;
            transform: scale(1.15) rotate(90deg);
            background: rgba(255, 255, 255, 0.2);
        }
        
        .modal-body {
            padding: 30px;
            max-height: 75vh;
            overflow-y: auto;
        }
        
        .modal-body::-webkit-scrollbar {
            width: 8px;
        }
        
        .modal-body::-webkit-scrollbar-track {
            background: #f1f1f1;
            border-radius: 4px;
        }
        
        .modal-body::-webkit-scrollbar-thumb {
            background: #cbd5e0;
            border-radius: 4px;
        }
        
        .modal-body::-webkit-scrollbar-thumb:hover {
            background: #a0aec0;
        }
        
        .modal-student-info {
            background: linear-gradient(135deg, #e8ebff 0%, #f0f4ff 100%);
            padding: 20px 22px;
            border-radius: 10px;
            margin-bottom: 25px;
            border-left: 5px solid #667eea;
            box-shadow: 0 2px 8px rgba(102, 126, 234, 0.12);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-student-info p {
            margin: 6px 0;
            font-size: 14px;
            color: #2d3748;
        }
        
        .modal-student-info strong {
            color: #667eea;
            font-weight: 700;
        }
        
        .modal-student-info span {
            color: #4a5568;
            font-weight: 600;
        }
        
        .modal-filters {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-bottom: 20px;
            background: linear-gradient(135deg, #f8f9ff 0%, #f0f4ff 100%);
            padding: 20px;
            border-radius: 8px;
            border: 1px solid #e8ebf8;
        }
        
        .modal-filter-group {
            display: flex;
            flex-direction: column;
        }
        
        .modal-filter-group[style*="grid-column"] {
            grid-column: 1 / -1;
        }
        
        .modal-filter-group label {
            font-size: 13px;
            font-weight: 700;
            color: #2d3748;
            margin-bottom: 8px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        
        .modal-filter-group select,
        .modal-filter-group input[type="file"],
        .modal-filter-group textarea {
            padding: 12px 14px;
            border: 2px solid #e2e8f0;
            border-radius: 8px;
            font-size: 13px;
            transition: all 0.3s ease;
            background: white;
            min-height: 42px;
            font-family: inherit;
        }
        
        .modal-filter-group select:hover,
        .modal-filter-group input[type="file"]:hover,
        .modal-filter-group textarea:hover {
            border-color: #cbd5e0;
            background: #fbfcfd;
        }
        
        .modal-filter-group select:focus,
        .modal-filter-group input[type="file"]:focus,
        .modal-filter-group textarea:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.12);
            background: #fafbfc;
        }
        
        .modal-filter-group select option {
            padding: 8px;
            font-size: 13px;
        }
        
        .modal-filter-group small {
            font-size: 12px;
            color: #718096;
            margin-top: 6px;
            font-style: italic;
        }
        
        .modal-actions {
            display: flex;
            gap: 12px;
            justify-content: flex-end;
            padding-top: 15px;
            border-top: 2px solid #e2e8f0;
            margin-top: 20px;
        }
        
        .btn-modal-submit,
        .btn-modal-cancel {
            padding: 11px 24px;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            min-width: 120px;
            letter-spacing: 0.5px;
        }
        
        .btn-modal-submit {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.35);
        }
        
        .btn-modal-submit:hover {
            background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
            box-shadow: 0 6px 16px rgba(102, 126, 234, 0.45);
            transform: translateY(-2px);
        }
        
        .btn-modal-submit:active {
            transform: translateY(0);
        }
        
        .btn-modal-cancel {
            background: #f0f4f8;
            color: #2d3748;
            border: 1px solid #cbd5e0;
        }
        
        .btn-modal-cancel:hover {
            background: #e2e8f0;
            border-color: #a0aec0;
        }
        
        /* Activity Count Styles */
        .activity-count-container {
            background: linear-gradient(135deg, #f0f4ff 0%, #e8ecff 100%);
            padding: 20px;
            border-radius: 10px;
            border-left: 5px solid #667eea;
            margin-bottom: 20px;
            box-shadow: 0 2px 8px rgba(102, 126, 234, 0.1);
        }
        
        .activity-count-container h4 {
            margin: 0 0 18px 0;
            color: #2d3748;
            font-size: 16px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .activity-count-display {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 12px;
        }
        
        .count-card {
            background: white;
            padding: 16px 14px;
            border-radius: 10px;
            border: 2px solid #e2e8f0;
            text-align: center;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
            transition: all 0.3s ease;
            cursor: default;
        }
        
        .count-card:hover {
            border-color: #667eea;
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
            transform: translateY(-2px);
        }
        
        .count-card-day {
            font-weight: 700;
            color: #667eea;
            font-size: 12px;
            margin-bottom: 8px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .count-card-number {
            font-size: 32px;
            font-weight: 900;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 6px;
        }
        
        .count-card-label {
            font-size: 11px;
            color: #718096;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }
        
        /* Selected Activity Count Styles */
        .selected-activity-count-container {
            background: linear-gradient(135deg, #f0f9ff 0%, #e8f4ff 100%);
            border-left: 5px solid #667eea;
            padding: 18px 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            box-shadow: 0 2px 8px rgba(102, 126, 234, 0.1);
            border: 2px solid #e2e8f0;
            border-left: 5px solid #667eea;
        }
        
        .selected-activity-info {
            flex: 1;
        }
        
        .selected-activity-info p {
            font-size: 14px;
            color: #2d3748;
            margin: 0;
            line-height: 1.5;
            font-weight: 500;
        }
        
        .activity-count-badge {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 10px 20px;
            border-radius: 25px;
            margin-left: 20px;
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
        }
        
        .count-number {
            font-size: 22px;
            font-weight: 900;
            color: white;
        }
        
        .count-label {
            font-size: 12px;
            color: rgba(255, 255, 255, 0.95);
            font-weight: 600;
        }
        
        /* Video Upload Section Styles */
        .video-upload-section {
            background: linear-gradient(135deg, #fff9e8 0%, #fff4d6 100%);
            padding: 20px;
            border-radius: 10px;
            border: 2px dashed #ffc107;
            margin-bottom: 20px;
        }
        
        .video-upload-section label {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
            font-weight: 700;
            color: #2d3748;
            margin-bottom: 12px;
        }
        
        .form-control {
            width: 100%;
            padding: 12px 14px;
            border: 2px solid #e2e8f0;
            border-radius: 8px;
            font-size: 13px;
            transition: all 0.3s ease;
            font-family: inherit;
            background: white;
        }
        
        .form-control:hover {
            border-color: #cbd5e0;
            background: #fbfcfd;
        }
        
        .form-control:focus {
            outline: none;
            border-color: #ffc107;
            box-shadow: 0 0 0 4px rgba(255, 193, 7, 0.12);
        }
        
        .form-control::placeholder {
            color: #a0aec0;
        }
        
        .video-upload-progress {
            margin-top: 15px;
        }
        
        .video-progress-bar-container {
            background: #e0e0e0;
            border-radius: 10px;
            overflow: hidden;
            height: 28px;
            box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.1);
        }
        
        #videoProgressBar {
            background: linear-gradient(90deg, #ffc107 0%, #ff9800 100%);
            height: 100%;
            width: 0%;
            transition: width 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 12px;
            font-weight: bold;
            box-shadow: 0 2px 8px rgba(255, 193, 7, 0.3);
        }
        
        #videoUploadStatus {
            margin-top: 10px;
            font-size: 13px;
            color: #666;
            font-weight: 500;
        }
        
        #videoUploadResult {
            margin-top: 15px;
            padding: 15px 16px;
            background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%);
            border: 2px solid #c3e6cb;
            border-radius: 8px;
            color: #155724;
            box-shadow: 0 2px 8px rgba(40, 167, 69, 0.15);
        }
        
        #videoUploadResult p {
            margin: 6px 0;
            font-size: 14px;
            font-weight: 500;
        }
        
        #videoUploadResult a {
            color: #0c5460;
            text-decoration: none;
            font-weight: 600;
            word-break: break-all;
        }
        
        #videoUploadResult a:hover {
            text-decoration: underline;
        }
        
        /* Current Level Section Styles */
        #currentLevelSection {
            margin-bottom: 20px;
        }
        
        #currentLevelSection > div {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 18px 20px;
            border-radius: 10px;
            color: white;
            text-align: center;
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
        }
        
        #currentLevelSection h4 {
            margin: 0 0 10px 0;
            font-size: 16px;
            font-weight: 700;
            letter-spacing: 0.5px;
        }
        
        #currentLevelText {
            margin: 0;
            font-size: 15px;
            font-weight: 600;
            white-space: pre-line;
            line-height: 1.6;
        }
        
        /* Section Dividers */
        .modal-section-divider {
            height: 2px;
            background: linear-gradient(90deg, transparent, #e2e8f0, transparent);
            margin: 24px 0;
        }
        
        .modal-section-title {
            font-size: 13px;
            font-weight: 700;
            color: #4a5568;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin: 20px 0 15px 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .modal-section-title::before {
            content: '';
            width: 4px;
            height: 16px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 2px;
        }
        
        /* Responsive Design - Tablet */
        @media (max-width: 1024px) {
            .modal-content {
                max-width: 90%;
                width: 90%;
            }
            
            .modal-filters {
                grid-template-columns: 1fr;
                gap: 12px;
            }
            
            .activity-count-display {
                grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
            }
        }
        
        /* Responsive Design - Mobile */
        @media (max-width: 768px) {
            .modal-content {
                max-width: 95%;
                width: 95%;
                margin: 20% auto !important;
            }
            
            .modal-header {
                padding: 20px 16px;
            }
            
            .modal-header h2 {
                font-size: 20px;
            }
            
            .close {
                font-size: 28px;
                width: 36px;
                height: 36px;
            }
            
            .modal-body {
                padding: 20px;
                max-height: 80vh;
            }
            
            .modal-filters {
                grid-template-columns: 1fr;
                gap: 12px;
                padding: 15px;
            }
            
            .modal-student-info {
                flex-direction: column;
                align-items: flex-start;
            }
            
            .activity-count-badge {
                margin-left: 0;
                margin-top: 12px;
                width: 100%;
                justify-content: center;
            }
            
            .activity-count-display {
                grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
            }
            
            .btn-modal-submit,
            .btn-modal-cancel {
                flex: 1;
                min-width: auto;
                padding: 11px 16px;
            }
            
            .modal-actions {
                flex-direction: column;
                gap: 10px;
            }
            
            .selected-activity-count-container {
                flex-direction: column;
                align-items: flex-start;
            }
        }
        
        /* Responsive Design - Small Mobile */
        @media (max-width: 480px) {
            .modal-content {
                width: 95% !important;
                margin: 30% auto !important;
                max-height: 85vh;
            }
            
            .modal-header {
                padding: 16px 12px;
            }
            
            .modal-header h2 {
                font-size: 18px;
            }
            
            .close {
                font-size: 26px;
                width: 32px;
                height: 32px;
            }
            
            .modal-body {
                padding: 16px;
                max-height: 85vh;
            }
            
            .modal-section-title {
                font-size: 12px;
                margin: 16px 0 12px 0;
            }
            
            .modal-filter-group label {
                font-size: 12px;
            }
            
            .modal-filter-group select,
            .form-control {
                font-size: 12px;
                min-height: 38px;
                padding: 10px 12px;
            }
            
            .btn-modal-submit,
            .btn-modal-cancel {
                padding: 10px 12px;
                font-size: 13px;
                min-width: auto;
            }
            
            .count-card-number {
                font-size: 24px;
            }
            
            .count-card {
                padding: 12px 10px;
            }
            
            .activity-count-badge {
                padding: 8px 12px;
            }
            
            .count-number {
                font-size: 18px;
            }
            
            .video-upload-section {
                padding: 15px;
            }
            
            .selected-activity-info p {
                font-size: 13px;
            }
            
            #currentLevelText {
                font-size: 14px;
            }
            
            .header-content {
                flex-direction: column;
                text-align: center;
            }
            
            .header-info {
                text-align: center;
                margin-top: 10px;
            }
            
            .btn-back,
            .btn-logout {
                margin-left: 5px;
                margin-top: 5px;
            }
            
            .filters {
                grid-template-columns: 1fr;
            }
            
            .table {
                font-size: 12px;
            }
            
            .table th,
            .table td {
                padding: 8px;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div>
                <h1>📊 Student Data Report</h1>
                <p><%= schoolName %> (UDISE: <%= udiseNo %>)</p>
            </div>
            <div class="header-info">
                <div class="user-info">
                    Welcome, <strong><%= user.getFullName() %></strong>
                </div>
               <strong> <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="btn btn-back">← Back to Dashboard</a></strong>
                <strong><a href="<%= request.getContextPath() %>/logout" class="btn btn-logout">Logout</a></strong>
            </div>
        </div>
    </div>
    
    <div class="container">
        <!-- Breadcrumb -->
        <div class="breadcrumb">
            <span>📍</span> <strong><%= schoolName %></strong> → Student Data Report
        </div>
        
        <!-- Filters Section -->
        <div class="section">
            <h2 class="section-title">🔍 Search & Filter Students</h2>
            <form method="get" action="">
                <div class="filters">
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
                        <label for="search">Search (Name/PEN)</label>
                        <input type="text" name="search" id="search" placeholder="Enter name or PEN" 
                               value="<%= (searchFilter != null) ? searchFilter : "" %>">
                    </div>
                    
                    <div class="filter-group" style="justify-content: flex-end;">
                        <label>&nbsp;</label>
                        <div class="filter-buttons">
                            <button type="submit" class="btn-filter">🔍 Filter</button>
                            <a href="?class=&section=&search=" class="btn-clear" style="padding: 10px 16px; border-radius: 6px; text-decoration: none; display: flex; align-items: center; justify-content: center;">Clear</a>
                        </div>
                    </div>
                </div>
            </form>
        </div>
        
        <!-- Statistics -->
        <div class="section">
            <div class="stats">
                <div class="stat-card">
                    <div class="stat-value"><%= filteredStudents.size() %></div>
                    <div class="stat-label">Students Found</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value"><%= classes.size() %></div>
                    <div class="stat-label">Total Classes</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value"><%= sections.size() %></div>
                    <div class="stat-label">Total Sections</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value"><%= students.size() %></div>
                    <div class="stat-label">Total Students</div>
                </div>
            </div>
        </div>
        
        <!-- Student Data Table -->
        <div class="section">
            <h2 class="section-title">📋 Student Data Against UDISE <%= udiseNo %></h2>
            
            <% if (filteredStudents.isEmpty()) { %>
                <div class="no-data">
                    <div class="no-data-icon">📭</div>
                    <p>No students found matching your criteria.</p>
                </div>
            <% } else { %>
                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>PEN</th>
                                <th>Student Name</th>
                                <th>Class</th>
                                <th>Section</th>
                                <th>Gender</th>
                                <th >Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% 
                            int rowNum = startIndex + 1;
                            for (Student student : paginatedStudents) { 
                            %>
                            <tr>
                                <td><%= rowNum++ %></td>
                                <td><strong><%= (student.getStudentPen() != null) ? student.getStudentPen() : "N/A" %></strong></td>
                                <td><%= student.getStudentName() %></td>
                                <td><span class="badge badge-primary">Class <%= student.getStudentClass() %></span></td>
                                <td><span class="badge badge-info">Section <%= student.getSection() %></span></td>
                                <td>
                                    <% 
                                    String gender = student.getGender();
                                    boolean isMale = "Male".equalsIgnoreCase(gender) || "पुरुष".equals(gender);
                                    %>
                                    <span class="badge <%= isMale ? "badge-primary" : "badge-warning" %>">
                                        <%= gender %>
                                    </span>
                                </td>
                                <td>
                                    <button class="btn-action" onclick="openActivityModal('<%= student.getStudentId() %>', '<%= student.getStudentName() %>')" title="Manage Activities">
                                        📚 Activities
                                    </button>
                                    <button class="btn-action-secondary" onclick="viewAllActivities('<%= student.getStudentId() %>', '<%= student.getStudentName() %>')" title="View All Activities">
                                        📋 View All
                                    </button>
                                    <button class="btn-action-secondary" onclick="viewStudentVideos('<%= student.getStudentId() %>', '<%= student.getStudentName() %>', '<%= student.getStudentPen() %>')" title="View Student Videos" style="background: #007bff;">
                                        🎥 Videos
                                    </button>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
                
                <!-- Pagination Controls -->
                <% if (totalPages > 1) { %>
                <div class="pagination">
                    <!-- Previous Button -->
                    <% if (currentPage > 1) { %>
                        <a href="?class=<%= classFilter != null ? classFilter : "" %>&section=<%= sectionFilter != null ? sectionFilter : "" %>&search=<%= searchFilter != null ? searchFilter : "" %>&page=<%= currentPage - 1 %>">← Previous</a>
                    <% } else { %>
                        <span class="disabled">← Previous</span>
                    <% } %>
                    
                    <!-- Page Numbers -->
                    <% 
                    int startPage = Math.max(1, currentPage - 2);
                    int endPage = Math.min(totalPages, currentPage + 2);
                    
                    if (startPage > 1) {
                    %>
                        <a href="?class=<%= classFilter != null ? classFilter : "" %>&section=<%= sectionFilter != null ? sectionFilter : "" %>&search=<%= searchFilter != null ? searchFilter : "" %>&page=1">1</a>
                        <% if (startPage > 2) { %>
                            <span>...</span>
                        <% } %>
                    <% } %>
                    
                    <% for (int i = startPage; i <= endPage; i++) { %>
                        <% if (i == currentPage) { %>
                            <span class="active"><%= i %></span>
                        <% } else { %>
                            <a href="?class=<%= classFilter != null ? classFilter : "" %>&section=<%= sectionFilter != null ? sectionFilter : "" %>&search=<%= searchFilter != null ? searchFilter : "" %>&page=<%= i %>"><%= i %></a>
                        <% } %>
                    <% } %>
                    
                    <% if (endPage < totalPages) { %>
                        <% if (endPage < totalPages - 1) { %>
                            <span>...</span>
                        <% } %>
                        <a href="?class=<%= classFilter != null ? classFilter : "" %>&section=<%= sectionFilter != null ? sectionFilter : "" %>&search=<%= searchFilter != null ? searchFilter : "" %>&page=<%= totalPages %>"><%= totalPages %></a>
                    <% } %>
                    
                    <!-- Next Button -->
                    <% if (currentPage < totalPages) { %>
                        <a href="?class=<%= classFilter != null ? classFilter : "" %>&section=<%= sectionFilter != null ? sectionFilter : "" %>&search=<%= searchFilter != null ? searchFilter : "" %>&page=<%= currentPage + 1 %>">Next →</a>
                    <% } else { %>
                        <span class="disabled">Next →</span>
                    <% } %>
                </div>
                
                <!-- Pagination Info -->
                <div class="pagination-info">
                    Showing <%= startIndex + 1 %> to <%= endIndex %> of <%= totalStudents %> students (Page <%= currentPage %> of <%= totalPages %>)
                </div>
                <% } %>
            <% } %>
        </div>
        
        <!-- Footer Info -->
        <div class="section" style="text-align: center; color: #718096; font-size: 12px;">
            <p>📌 This report shows all student data registered against UDISE number <%= udiseNo %></p>
            <p>Last updated: <%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(new java.util.Date()) %></p>
        </div>
    </div>
    
    <!-- Activity Modal -->
    <div id="activityModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>📚 Manage Student Activities</h2>
                <span class="close" onclick="closeActivityModal()">&times;</span>
            </div>
            <div class="modal-body">
                <div class="modal-student-info">
                    <p><strong>Student Name:</strong> <span id="studentNameDisplay"></span></p>
                    <p><strong>Student ID:</strong> <span id="studentIdDisplay"></span></p>
                </div>
                
                <form id="activityFilterForm">
                    <input type="hidden" id="studentIdInput" name="studentId">
                    
                    <!-- Section 1: Subject & Week Selection -->
                    <div class="modal-section-title">📚 Select Subject & Week</div>
                    <div class="modal-filters">
                        <div class="modal-filter-group">
                            <label for="subjectFilter">📖 Subject</label>
                            <select name="subject" id="subjectFilter" onchange="showLevelInfo(); loadActivities()">
                                <option value="">-- Select Subject --</option>
                                <option value="English">📝 English</option>
                                <option value="Marathi">📕 Marathi</option>
                                <option value="Math">🔢 Math</option>
                            </select>
                        </div>
                        
                        <div class="modal-filter-group">
                            <label for="weekFilter">📅 Week</label>
                            <select name="week" id="weekFilter" onchange="loadActivities(); loadActivityCount();">
                                <option value="">-- Select Week --</option>
                                <option value="1">Week 1</option>
                                <option value="2">Week 2</option>
                                <option value="3">Week 3</option>
                                <option value="4">Week 4</option>
                                <option value="5">Week 5</option>
                                <option value="6">Week 6</option>
                                <option value="7">Week 7</option>
                                <option value="8">Week 8</option>
                                <option value="9">Week 9</option>
                                <option value="10">Week 10</option>
                                <option value="11">Week 11</option>
                                <option value="12">Week 12</option>
                                <option value="13">Week 13</option>
                                <option value="14">Week 14</option>
                            </select>
                        </div>
                    </div>
                    
                    <!-- Current Level Display -->
                    <div id="currentLevelSection" style="display: none;">
                        <div>
                            <h4>📚 Current Level / वर्तमान स्तर</h4>
                            <p id="currentLevelText"></p>
                        </div>
                    </div>
                    
                    <!-- Section 2: Activity Selection -->
                    <div class="modal-section-title">⚡ Select Daily Activity</div>
                    <div class="modal-filter-group" style="grid-column: 1 / -1;">
                        <label for="activityFilter">🎯 Daily Activities</label>
                        <select name="activity" id="activityFilter" onchange="showSelectedActivityCount()">
                            <option value="">-- Select Activity --</option>
                        </select>
                        <small>Choose an activity from the list or enter a custom one</small>
                    </div>
                    
                    <!-- Custom Activity Input (shown when "Other Activities" is selected) -->
                    <div id="customActivitySection" style="display: none;">
                        <div class="modal-section-title">✏️ Custom Activity</div>
                        <div class="modal-filter-group" style="grid-column: 1 / -1;">
                            <label for="customActivityInput">Enter Custom Activity</label>
                            <textarea id="customActivityInput" class="form-control" rows="3" placeholder="Describe your custom activity here..."></textarea>
                            <small>Add details about the activity you want to submit</small>
                        </div>
                    </div>
                    
                    <!-- Section 3: Video Upload -->
                    <div class="modal-section-title">🎬 Upload Video (Optional)</div>
                    <div class="modal-filter-group video-upload-section" style="grid-column: 1 / -1;">
                        <label for="videoUpload">📹 Choose Video File</label>
                        <input type="file" id="videoUpload" name="video" accept="video/*" class="form-control">
                        <small>Supported formats: MP4, AVI, MOV, WMV, FLV, MKV (Max 500MB). Video will be uploaded to YouTube.</small>
                        <div id="videoUploadProgress" class="video-upload-progress" style="display: none;">
                            <div class="video-progress-bar-container">
                                <div id="videoProgressBar"></div>
                            </div>
                            <p id="videoUploadStatus"></p>
                        </div>
                        <div id="videoUploadResult" style="display: none;">
                            <p>✅ Video uploaded successfully!</p>
                            <p style="font-size: 12px; margin-top: 8px;">YouTube URL: <a id="videoYouTubeLink" href="#" target="_blank"></a></p>
                        </div>
                    </div>
                    
                    <!-- Section 4: Activity Summary -->
                    <div id="selectedActivityCountSection" style="display: none;">
                        <div class="modal-section-title">📊 Selected Activity Summary</div>
                        <div class="selected-activity-count-container">
                            <div class="selected-activity-info">
                                <p id="selectedActivityText"></p>
                            </div>
                            <div class="activity-count-badge">
                                <span class="count-number" id="selectedActivityCount">0</span>
                                <span class="count-label">submissions</span>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Activity Count Display Section (Day-wise Summary) -->
                    <div id="activityCountSection" style="display: none;">
                        <div class="activity-count-container">
                            <h4>📊 Day-wise Activity Count</h4>
                            <div id="activityCountDisplay" class="activity-count-display">
                                <!-- Activity count will be populated here -->
                            </div>
                        </div>
                    </div>
                    
                    <!-- Section 5: Action Buttons -->
                    <div class="modal-actions">
                        <button type="button" class="btn-modal-submit" onclick="submitActivity()" title="Submit this activity">
                            ✓ Submit Activity
                        </button>
                        <button type="button" class="btn-modal-cancel" onclick="closeActivityModal()" title="Close without saving">
                            ✕ Cancel
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <!-- View All Activities Modal -->
    <div id="viewAllActivitiesModal" class="modal">
        <div class="modal-content" style="max-width: 900px;">
            <div class="modal-header">
                <h2>📋 All Activities for Student</h2>
                <span class="close" onclick="closeViewAllActivitiesModal()">&times;</span>
            </div>
            <div class="modal-body">
                <div class="modal-student-info">
                    <p><strong>Student Name:</strong> <span id="allActivitiesStudentName"></span></p>
                    <p><strong>Student ID:</strong> <span id="allActivitiesStudentId"></span></p>
                </div>
                
                <div id="allActivitiesLoading" style="text-align: center; padding: 40px; display: none;">
                    <p>⏳ Loading activities...</p>
                </div>
                
                <div id="allActivitiesContent" style="margin-top: 20px;">
                    <!-- Activities will be loaded here -->
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Store parsed activities for later use
        let parsedActivities = [];
        
        // Level mapping for each subject and week
        const levelMapping = {
            'Marathi': {
                1: 'पहिला टप्पा : प्रारंभिक स्तर (Phase 1: Beginner Level)',
                2: 'पहिला टप्पा : प्रारंभिक स्तर (Phase 1: Beginner Level)',
                3: 'दुसरा टप्पा : अक्षर स्तर (Phase 2: Letter Level)',
                4: 'दुसरा टप्पा : अक्षर स्तर (Phase 2: Letter Level)',
                5: 'दुसरा टप्पा : अक्षर स्तर (Phase 2: Letter Level)',
                6: 'तिसरा टप्पा : शब्द स्तर (Phase 3: Word Level)',
                7: 'तिसरा टप्पा : शब्द स्तर (Phase 3: Word Level)',
                8: 'तिसरा टप्पा : शब्द स्तर (Phase 3: Word Level)',
                9: 'चौथा टप्पा : वाक्य स्तर (Phase 4: Sentence Level)',
                10: 'चौथा टप्पा : वाक्य स्तर (Phase 4: Sentence Level)',
                11: 'चौथा टप्पा : वाक्य स्तर (Phase 4: Sentence Level)',
                12: 'चौथा टप्पा : वाक्य स्तर (Phase 4: Sentence Level)',
                13: 'चौथा टप्पा : वाक्य स्तर (Phase 4: Sentence Level)',
                14: 'चौथा टप्पा : वाक्य स्तर (Phase 4: Sentence Level)'
            },
            'Math': {
                1: 'प्रारंभिक - संख्या ओळख (Beginner - Number Recognition)',
                2: 'प्रारंभिक - संख्या ओळख (Beginner - Number Recognition)',
                3: 'मध्यम - गणितीय कौशल्ये (Intermediate - Mathematical Skills)',
                4: 'मध्यम - गणितीय कौशल्ये (Intermediate - Mathematical Skills)',
                5: 'मध्यम - गणितीय कौशल्ये (Intermediate - Mathematical Skills)',
                6: 'मध्यम - गणितीय कौशल्ये (Intermediate - Mathematical Skills)',
                7: 'मध्यम - गणितीय कौशल्ये (Intermediate - Mathematical Skills)',
                8: 'प्रगत - संकल्पना (Advanced - Concepts)',
                9: 'प्रगत - संकल्पना (Advanced - Concepts)',
                10: 'प्रगत - संकल्पना (Advanced - Concepts)',
                11: 'प्रगत - संकल्पना (Advanced - Concepts)',
                12: 'प्रगत - संकल्पना (Advanced - Concepts)',
                13: 'प्रगत - संकल्पना (Advanced - Concepts)',
                14: 'प्रगत - संकल्पना (Advanced - Concepts)'
            },
            'English': {
                1: 'Phase 1: Beginner Level',
                2: 'Phase 1: Beginner Level',
                3: 'Phase 2: Letter Level',
                4: 'Phase 2: Letter Level',
                5: 'Phase 2: Letter Level',
                6: 'Phase 3: Word Level',
                7: 'Phase 3: Word Level',
                8: 'Phase 3: Word Level',
                9: 'Phase 4: Sentence Level',
                10: 'Phase 4: Sentence Level',
                11: 'Phase 4: Sentence Level',
                12: 'Phase 4: Sentence Level',
                13: 'Phase 4: Sentence Level',
                14: 'Phase 4: Sentence Level'
            }
        };
        
        function showLevelInfo() {
            const subject = document.getElementById('subjectFilter').value;
            const studentId = document.getElementById('studentIdInput').value;
            const levelSection = document.getElementById('currentLevelSection');
            const levelText = document.getElementById('currentLevelText');
            
            if (!subject || !studentId) {
                levelSection.style.display = 'none';
                return;
            }
            
            // Fetch student's current phase from database
            const contextPath = '<%= request.getContextPath() %>';
            fetch(contextPath + '/get-student-phase?studentId=' + studentId + '&subject=' + subject)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        levelText.textContent = data.description;
                        levelSection.style.display = 'block';
                    } else {
                        console.error('Error fetching phase:', data.message);
                        levelSection.style.display = 'none';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    levelSection.style.display = 'none';
                });
        }
        
        function openActivityModal(studentId, studentName) {
            document.getElementById('studentIdDisplay').textContent = studentId;
            document.getElementById('studentNameDisplay').textContent = studentName;
            document.getElementById('studentIdInput').value = studentId;
            
            // Reset all sections to hidden state
            document.getElementById('currentLevelSection').style.display = 'none';
            document.getElementById('selectedActivityCountSection').style.display = 'none';
            document.getElementById('customActivitySection').style.display = 'none';
            document.getElementById('activityCountSection').style.display = 'none';
            
            document.getElementById('activityModal').style.display = 'block';
            document.body.style.overflow = 'hidden';
        }
        
        function closeActivityModal() {
            document.getElementById('activityModal').style.display = 'none';
            document.getElementById('subjectFilter').value = '';
            document.getElementById('weekFilter').value = '';
            document.getElementById('activityFilter').value = '';
            document.getElementById('activityFilter').innerHTML = '<option value="">-- Select Activity --</option>';
            document.getElementById('activityCountSection').style.display = 'none';
            document.getElementById('selectedActivityCountSection').style.display = 'none';
            document.getElementById('currentLevelSection').style.display = 'none';
            document.getElementById('customActivitySection').style.display = 'none';
            parsedActivities = [];
            document.body.style.overflow = 'auto';
        }
        
        function loadActivities() {
            const subject = document.getElementById('subjectFilter').value;
            const week = document.getElementById('weekFilter').value;
            const activityFilter = document.getElementById('activityFilter');
            
            // Reset activity dropdown and parsing
            activityFilter.innerHTML = '<option value="">-- Select Activity --</option>';
            parsedActivities = [];
            
            if (!subject || !week) {
                return;
            }
            
            // Construct the path to the HTML file
            const contextPath = '<%= request.getContextPath() %>';
            
            // Try both uppercase and lowercase versions
            const filepaths = [
                contextPath + '/' + subject.toUpperCase() + '/WEEK ' + week + '.html',
                contextPath + '/' + subject.toUpperCase() + '/week ' + week + '.html'
            ];
            
            // Function to try loading from each filepath
            function tryLoadFromPath(filepathIndex) {
                if (filepathIndex >= filepaths.length) {
                    console.error('Error loading activities: File not found');
                    activityFilter.innerHTML = '<option value="">-- No activities found --</option>';
                    return;
                }
                
                const filePath = filepaths[filepathIndex];
                
                fetch(filePath)
                    .then(response => {
                        if (!response.ok) {
                            // Try next filepath
                            tryLoadFromPath(filepathIndex + 1);
                            return;
                        }
                        return response.text();
                    })
                    .then(html => {
                        if (!html) return;
                        
                        // Parse the HTML
                        const parser = new DOMParser();
                        const doc = parser.parseFromString(html, 'text/html');
                        
                        // Get all table rows (skip header)
                        const rows = doc.querySelectorAll('table tbody tr');
                        
                        // Extract data from each row
                        const activities = [];
                        parsedActivities = [];
                        
                        rows.forEach((row, index) => {
                            const cells = row.querySelectorAll('td');
                            // Skip rows that are headers (contain th elements)
                            const headerCells = row.querySelectorAll('th');
                            if (headerCells.length > 0) return;
                            
                            if (cells.length >= 2) {
                                const day = cells[0].textContent.trim();
                                const objective = cells[1].textContent.trim();
                                const activity = cells.length >= 3 ? cells[2].textContent.trim() : '';
                                
                                // Extract day number from text like "दिवस १"
                                const dayNumberMatch = day.match(/[\d१२३४५६789०]/);
                                let dayNumber = 0;
                                if (dayNumberMatch) {
                                    // Convert Devanagari numerals to Arabic if needed
                                    dayNumber = convertDevanagariToArabic(dayNumberMatch[0]);
                                }
                                
                                // Build the full text
                                let fullText = day + ' - ' + objective;
                                if (activity) {
                                    fullText += ' - ' + activity;
                                }
                                
                                if (fullText.trim()) {
                                    activities.push(fullText);
                                    parsedActivities.push({
                                        day: day,
                                        dayNumber: dayNumber,
                                        objective: objective,
                                        activity: activity,
                                        fullText: fullText
                                    });
                                }
                            }
                        });
                        
                        // Populate the activity dropdown
                        if (activities.length > 0) {
                            activities.forEach((activity, index) => {
                                const option = document.createElement('option');
                                option.value = index;
                                option.textContent = activity;
                                activityFilter.appendChild(option);
                            });
                            
                            // Add "Other Activities" option at the end
                            const otherOption = document.createElement('option');
                            otherOption.value = 'other';
                            otherOption.textContent = '-- Other Activities (Enter Custom) --';
                            activityFilter.appendChild(otherOption);
                        } else {
                            activityFilter.innerHTML = '<option value="">-- No activities found --</option>';
                        }
                    })
                    .catch(error => {
                        // Try next filepath
                        tryLoadFromPath(filepathIndex + 1);
                    });
            }
            
            // Start trying to load from first filepath
            tryLoadFromPath(0);
        }
        
        function convertDevanagariToArabic(char) {
            const devanagariNumbers = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
            const arabicNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
            const index = devanagariNumbers.indexOf(char);
            return index !== -1 ? parseInt(arabicNumbers[index]) : 0;
        }
        
        function loadActivityCount() {
            const subject = document.getElementById('subjectFilter').value;
            const week = document.getElementById('weekFilter').value;
            const studentId = document.getElementById('studentIdInput').value;
            
            if (!subject || !week || !studentId) {
                document.getElementById('activityCountSection').style.display = 'none';
                return;
            }
            
            // Fetch activity count from server
            const contextPath = '<%= request.getContextPath() %>';
            fetch(contextPath + '/get-activity-count', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'studentId=' + studentId + '&subject=' + subject + '&week=' + week
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    displayActivityCount(data.counts);
                }
            })
            .catch(error => {
                console.error('Error loading activity count:', error);
            });
        }
        
        function displayActivityCount(counts) {
            const countDisplay = document.getElementById('activityCountDisplay');
            countDisplay.innerHTML = '';
            
            if (Object.keys(counts).length === 0) {
                document.getElementById('activityCountSection').style.display = 'none';
                return;
            }
            
            document.getElementById('activityCountSection').style.display = 'block';
            
            // Sort days numerically
            const sortedDays = Object.keys(counts).sort((a, b) => {
                const numA = parseInt(a.replace('day_', ''));
                const numB = parseInt(b.replace('day_', ''));
                return numA - numB;
            });
            
            sortedDays.forEach(dayKey => {
                const dayNumber = dayKey.replace('day_', '');
                const count = counts[dayKey];
                
                const card = document.createElement('div');
                card.className = 'count-card';
                card.innerHTML = `
                    <div class="count-card-day">दिवस ${dayNumber}</div>
                    <div class="count-card-number">${count}</div>
                    <div class="count-card-label">Times Submitted</div>
                `;
                countDisplay.appendChild(card);
            });
        }
        
        function showSelectedActivityCount() {
            const activityIndex = document.getElementById('activityFilter').value;
            const selectedActivityCountSection = document.getElementById('selectedActivityCountSection');
            const customActivitySection = document.getElementById('customActivitySection');
            
            // Handle "Other Activities" option
            if (activityIndex === 'other') {
                selectedActivityCountSection.style.display = 'none';
                customActivitySection.style.display = 'block';
                document.getElementById('customActivityInput').focus();
                return;
            } else {
                customActivitySection.style.display = 'none';
            }
            
            if (activityIndex === '') {
                selectedActivityCountSection.style.display = 'none';
                return;
            }
            
            // Get the selected activity details
            const selectedActivity = parsedActivities[activityIndex];
            if (!selectedActivity) {
                selectedActivityCountSection.style.display = 'none';
                return;
            }
            
            // Display the selected activity information
            document.getElementById('selectedActivityText').innerHTML = `
                ${selectedActivity.fullText}
            `;
            
            // Fetch the count for this specific activity
            const studentId = document.getElementById('studentIdInput').value;
            const subject = document.getElementById('subjectFilter').value;
            const week = document.getElementById('weekFilter').value;
            
            // Log the data being sent
            console.log('DEBUG: Fetching activity count with:');
            console.log('  studentId:', studentId);
            console.log('  subject:', subject);
            console.log('  week:', week);
            console.log('  day:', selectedActivity.dayNumber);
            console.log('  activity:', selectedActivity.fullText);
            
            const contextPath = '<%= request.getContextPath() %>';
            const formData = new URLSearchParams();
            formData.append('studentId', studentId);
            formData.append('subject', subject);
            formData.append('week', week);
            formData.append('day', selectedActivity.dayNumber);
            formData.append('activity', selectedActivity.fullText);
            
            // First call debug servlet to see what's in database
            fetch(contextPath + '/debug-activity-count', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: formData.toString()
            })
            .then(response => {
                console.log('DEBUG: Debug Response status:', response.status);
                return response.json();
            })
            .then(debugData => {
                console.log('DEBUG: Full debug info from server:', debugData);
                if (debugData && debugData.debug) {
                    console.log('DEBUG: Total records in table:', debugData.debug.totalRecordsInTable);
                    console.log('DEBUG: All records:', debugData.debug.allRecords);
                    console.log('DEBUG: Records by student & language:', debugData.debug.recordsByStudentAndLanguage);
                    console.log('DEBUG: Records by week & day:', debugData.debug.recordsByWeekAndDay);
                } else {
                    console.warn('DEBUG: No debug data received from server');
                }
                
                // Now try to get the specific count
                return fetch(contextPath + '/get-specific-activity-count', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: formData.toString()
                });
            })
            .then(response => {
                console.log('DEBUG: Count Response status:', response.status);
                return response.json();
            })
            .then(data => {
                console.log('DEBUG: Count Response data:', data);
                if (data.success) {
                    document.getElementById('selectedActivityCount').textContent = data.count;
                    selectedActivityCountSection.style.display = 'block';
                } else {
                    console.log('DEBUG: Error from server:', data.message);
                    document.getElementById('selectedActivityCount').textContent = '0';
                    selectedActivityCountSection.style.display = 'block';
                }
            })
            .catch(error => {
                console.error('Error fetching activity count:', error);
                document.getElementById('selectedActivityCount').textContent = '0';
                selectedActivityCountSection.style.display = 'block';
            });
        }
        
        async function submitActivity() {
            const studentId = document.getElementById('studentIdInput').value;
            const subject = document.getElementById('subjectFilter').value;
            const week = document.getElementById('weekFilter').value;
            const activityIndex = document.getElementById('activityFilter').value;
            const videoFile = document.getElementById('videoUpload').files[0];
            
            // Validate selections
            if (!studentId || !subject || !week || activityIndex === '') {
                alert('Please select Subject, Week, and Activity');
                return;
            }
            
            let dayNumber, activityText;
            
            // Handle "Other Activities" option
            if (activityIndex === 'other') {
                const customActivity = document.getElementById('customActivityInput').value.trim();
                if (!customActivity) {
                    alert('Please enter a custom activity');
                    return;
                }
                dayNumber = 0; // Use 0 for custom activities
                activityText = 'Other - ' + customActivity;
            } else {
                // Get the selected activity details
                const selectedActivity = parsedActivities[activityIndex];
                if (!selectedActivity) {
                    alert('Invalid activity selected');
                    return;
                }
                dayNumber = selectedActivity.dayNumber;
                activityText = selectedActivity.fullText;
            }
            
            const contextPath = '<%= request.getContextPath() %>';
            let videoYouTubeUrl = null;
            
            // Upload video first if selected
            if (videoFile) {
                videoYouTubeUrl = await uploadVideoToYouTube(videoFile, studentId, subject, week, activityText);
                if (!videoYouTubeUrl) {
                    alert('Video upload failed. Activity not submitted.');
                    return;
                }
            }
            
            // Submit activity to server
            const formData = new FormData();
            formData.append('studentId', studentId);
            formData.append('subject', subject);
            formData.append('week', week);
            formData.append('day', dayNumber);
            formData.append('activity', activityText);
            if (videoYouTubeUrl) {
                formData.append('videoUrl', videoYouTubeUrl);
            }
            
            fetch(contextPath + '/save-student-activity', {
                method: 'POST',
                body: new URLSearchParams(formData)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ Activity submitted successfully!' + (videoYouTubeUrl ? ' Video uploaded to YouTube.' : ''));
                    // Reload activity count
                    loadActivityCount();
                    // Reset form
                    document.getElementById('activityFilter').value = '';
                    document.getElementById('videoUpload').value = '';
                    document.getElementById('videoUploadResult').style.display = 'none';
                } else {
                    alert('Error: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error submitting activity:', error);
                alert('Failed to submit activity');
            });
        }
        
        async function uploadVideoToYouTube(videoFile, studentId, subject, week, activityText) {
            const contextPath = '<%= request.getContextPath() %>';
            const progressBar = document.getElementById('videoProgressBar');
            const progressSection = document.getElementById('videoUploadProgress');
            const statusText = document.getElementById('videoUploadStatus');
            const resultSection = document.getElementById('videoUploadResult');
            const youtubeLink = document.getElementById('videoYouTubeLink');
            
            // Show progress
            progressSection.style.display = 'block';
            resultSection.style.display = 'none';
            statusText.textContent = 'Preparing upload...';
            progressBar.style.width = '0%';
            progressBar.textContent = '0%';
            
            try {
                const formData = new FormData();
                formData.append('videoFile', videoFile);
                formData.append('title', subject + ' - Week ' + week + ' - ' + activityText.substring(0, 50));
                formData.append('description', 'Activity: ' + activityText + '\nSubject: ' + subject + '\nWeek: ' + week);
                formData.append('category', subject);
                formData.append('subCategory', 'Week ' + week);
                formData.append('studentId', studentId);
                
                const xhr = new XMLHttpRequest();
                
                // Progress listener
                xhr.upload.addEventListener('progress', (e) => {
                    if (e.lengthComputable) {
                        const percentComplete = Math.round((e.loaded / e.total) * 100);
                        progressBar.style.width = percentComplete + '%';
                        progressBar.textContent = percentComplete + '%';
                        statusText.textContent = 'Uploading to YouTube: ' + percentComplete + '%';
                    }
                });
                
                // Return a promise
                return new Promise((resolve, reject) => {
                    xhr.onload = function() {
                        if (xhr.status === 200) {
                            try {
                                const response = JSON.parse(xhr.responseText);
                                if (response.success) {
                                    progressBar.style.width = '100%';
                                    progressBar.textContent = '100%';
                                    statusText.textContent = 'Upload complete!';
                                    
                                    // Show result
                                    resultSection.style.display = 'block';
                                    youtubeLink.href = response.youtubeUrl;
                                    youtubeLink.textContent = response.youtubeUrl;
                                    
                                    setTimeout(() => {
                                        progressSection.style.display = 'none';
                                    }, 2000);
                                    
                                    resolve(response.youtubeUrl);
                                } else {
                                    statusText.textContent = 'Upload failed: ' + response.message;
                                    reject(new Error(response.message));
                                }
                            } catch (e) {
                                statusText.textContent = 'Upload failed: Invalid response';
                                reject(e);
                            }
                        } else {
                            statusText.textContent = 'Upload failed: Server error';
                            reject(new Error('Server error: ' + xhr.status));
                        }
                    };
                    
                    xhr.onerror = function() {
                        statusText.textContent = 'Upload failed: Network error';
                        reject(new Error('Network error'));
                    };
                    
                    xhr.open('POST', contextPath + '/upload-to-youtube', true);
                    xhr.send(formData);
                });
                
            } catch (error) {
                console.error('Video upload error:', error);
                statusText.textContent = 'Upload failed: ' + error.message;
                return null;
            }
        }
        
        // Close modal when clicking outside of it
        window.onclick = function(event) {
            var modal = document.getElementById('activityModal');
            var allActivitiesModal = document.getElementById('viewAllActivitiesModal');
            if (event.target == modal) {
                closeActivityModal();
            }
            if (event.target == allActivitiesModal) {
                closeViewAllActivitiesModal();
            }
        }
        
        // View All Activities Functions
        function viewAllActivities(studentId, studentName) {
            document.getElementById('allActivitiesStudentName').textContent = studentName;
            document.getElementById('allActivitiesStudentId').textContent = studentId;
            document.getElementById('viewAllActivitiesModal').style.display = 'block';
            document.body.style.overflow = 'hidden';
            
            // Show loading
            document.getElementById('allActivitiesLoading').style.display = 'block';
            document.getElementById('allActivitiesContent').innerHTML = '';
            
            // Fetch all activities for this student
            const contextPath = '<%= request.getContextPath() %>';
            fetch(contextPath + '/studentWeeklyActivity?action=getAllStudentActivities&studentId=' + studentId)
                .then(response => response.json())
                .then(activities => {
                    document.getElementById('allActivitiesLoading').style.display = 'none';
                    displayAllActivities(activities);
                })
                .catch(error => {
                    console.error('Error loading activities:', error);
                    document.getElementById('allActivitiesLoading').style.display = 'none';
                    document.getElementById('allActivitiesContent').innerHTML = 
                        '<p style="text-align: center; color: #dc3545;">❌ Error loading activities</p>';
                });
        }
        
        function closeViewAllActivitiesModal() {
            document.getElementById('viewAllActivitiesModal').style.display = 'none';
            document.body.style.overflow = 'auto';
        }
        
        function displayAllActivities(activities) {
            const container = document.getElementById('allActivitiesContent');
            
            if (!activities || activities.length === 0) {
                container.innerHTML = '<p style="text-align: center; color: #6c757d;">No activities found for this student</p>';
                return;
            }
            
            // Group activities by language and week
            const grouped = {};
            activities.forEach(activity => {
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
            
            // Display grouped activities
            let html = '';
            let groupIndex = 0;
            Object.keys(grouped).sort().forEach(key => {
                const group = grouped[key];
                const groupId = 'activityGroup' + groupIndex;
                groupIndex++;
                
                html += '<div style="margin-bottom: 25px; border: 1px solid #dee2e6; border-radius: 8px; overflow: hidden;">';
                html += '<div onclick="toggleActivityGroup(\'' + groupId + '\')" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 12px 16px; color: white; cursor: pointer; display: flex; justify-content: space-between; align-items: center;">';
                html += '<h4 style="margin: 0; font-size: 16px;">' + group.language + ' - Week ' + group.week + '</h4>';
                html += '<span id="' + groupId + 'Icon" style="font-size: 20px; transition: transform 0.3s;">▼</span>';
                html += '</div>';
                html += '<div id="' + groupId + '" style="padding: 15px;">';
                
                // Sort activities by day
                group.activities.sort((a, b) => a.dayNumber - b.dayNumber);
                
                group.activities.forEach(activity => {
                    const completedClass = activity.completed ? 'background: #d4edda; border-left: 4px solid #28a745;' : 'background: #fff3cd; border-left: 4px solid #ffc107;';
                    const completedIcon = activity.completed ? '✅' : '⏳';
                    const statusText = activity.completed ? 'Completed' : 'Pending';
                    
                    let activityHtml = '<div style="' + completedClass + ' padding: 12px; margin-bottom: 10px; border-radius: 6px;">';
                    activityHtml += '<div style="display: flex; justify-content: space-between; align-items: start;">';
                    activityHtml += '<div style="flex: 1;">';
                    activityHtml += '<strong style="color: #495057;">Day ' + activity.dayNumber + '</strong><br>';
                    activityHtml += '<span style="font-size: 13px; color: #6c757d;">' + activity.activityText + '</span>';
                    activityHtml += '</div>';
                    activityHtml += '<div style="text-align: right; min-width: 100px;">';
                    //activityHtml += '<span style="font-size: 20px;">' + completedIcon + '</span><br>';
                    //activityHtml += '<span style="font-size: 11px; color: #6c757d;">' + statusText + '</span>';
                    if (activity.activityCount > 1) {
                        activityHtml += '<br><span style="background: #667eea; color: white; padding: 2px 8px; border-radius: 10px; font-size: 10px;">' + activity.activityCount + 'x</span>';
                    }
                    activityHtml += '</div>';
                    activityHtml += '</div>';
                    if (activity.assignedBy) {
                        activityHtml += '<div style="margin-top: 8px; padding-top: 8px; border-top: 1px solid rgba(0,0,0,0.1); font-size: 11px; color: #6c757d;">Assigned by: ' + activity.assignedBy + '</div>';
                    }
                    activityHtml += '</div>';
                    
                    html += activityHtml;
                });
                
                html += '</div>';
                html += '</div>';
            });
            
            // Add summary at the top
            const totalActivities = activities.length;
            const completedActivities = activities.filter(a => a.completed).length;
            const completionRate = totalActivities > 0 ? Math.round((completedActivities / totalActivities) * 100) : 0;
            
            let summaryHtml = '<div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin-bottom: 20px;">';
            summaryHtml += '<div style="background: #e7f3ff; padding: 15px; border-radius: 8px; text-align: center;">';
            summaryHtml += '<div style="font-size: 24px; font-weight: bold; color: #667eea;">' + totalActivities + '</div>';
            summaryHtml += '<div style="font-size: 12px; color: #6c757d;">Total Activities</div>';
            summaryHtml += '</div>';
            summaryHtml += '<div style="background: #d4edda; padding: 15px; border-radius: 8px; text-align: center;">';
            summaryHtml += '<div style="font-size: 24px; font-weight: bold; color: #28a745;">' + completedActivities + '</div>';
            summaryHtml += '<div style="font-size: 12px; color: #6c757d;">Completed</div>';
            summaryHtml += '</div>';
            summaryHtml += '<div style="background: #fff3cd; padding: 15px; border-radius: 8px; text-align: center;">';
            summaryHtml += '<div style="font-size: 24px; font-weight: bold; color: #ffc107;">' + completionRate + '%</div>';
            summaryHtml += '<div style="font-size: 12px; color: #6c757d;">Completion Rate</div>';
            summaryHtml += '</div>';
            summaryHtml += '</div>';
            
            container.innerHTML = summaryHtml + html;
        }
        
        // Toggle activity group visibility
        function toggleActivityGroup(groupId) {
            const group = document.getElementById(groupId);
            const icon = document.getElementById(groupId + 'Icon');
            
            if (group.style.display === 'none') {
                group.style.display = 'block';
                icon.textContent = '▼';
                icon.style.transform = 'rotate(0deg)';
            } else {
                group.style.display = 'none';
                icon.textContent = '▶';
                icon.style.transform = 'rotate(-90deg)';
            }
        }
        
        // View Student Videos Function
        function viewStudentVideos(studentId, studentName, studentPen) {
            // Create a modal for displaying videos
            const modal = document.createElement('div');
            modal.id = 'videosModal';
            modal.style.cssText = 'display: block; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0, 0, 0, 0.5); animation: fadeIn 0.3s;';
            
            modal.innerHTML = `
                <div class="modal-content" style="width: 90%; max-width: 1000px; max-height: 90vh; overflow-y: auto;">
                    <div class="modal-header">
                        <h2>🎥 Videos - ${studentName} (PEN: ${studentPen})</h2>
                        <span class="close" onclick="closeVideosModal()" style="cursor: pointer; color: white; font-size: 28px; font-weight: bold;">&times;</span>
                    </div>
                    <div class="modal-body">
                        <div id="videosLoading" style="text-align: center; padding: 40px; color: #667eea;">
                            <div style="font-size: 24px; margin-bottom: 10px;">⏳ Loading videos...</div>
                            <div style="font-size: 14px; color: #6c757d;">Please wait while we fetch the videos</div>
                        </div>
                        <div id="videosContent" style="display: none;"></div>
                    </div>
                </div>
            `;
            
            document.body.appendChild(modal);
            document.body.style.overflow = 'hidden';
            
            // Fetch videos for this student
            const contextPath = '<%= request.getContextPath() %>';
            fetch(contextPath + '/getStudentVideos?studentId=' + studentId + '&studentPen=' + studentPen)
                .then(response => response.json())
                .then(data => {
                    document.getElementById('videosLoading').style.display = 'none';
                    document.getElementById('videosContent').style.display = 'block';
                    displayStudentVideos(data);
                })
                .catch(error => {
                    console.error('Error loading videos:', error);
                    document.getElementById('videosLoading').style.display = 'none';
                    document.getElementById('videosContent').style.display = 'block';
                    document.getElementById('videosContent').innerHTML = 
                        '<div style="text-align: center; padding: 40px; color: #dc3545;"><div style="font-size: 24px; margin-bottom: 10px;">❌ Error Loading Videos</div><p>' + error.message + '</p></div>';
                });
        }
        
        function displayStudentVideos(data) {
            const container = document.getElementById('videosContent');
            
            if (!data.videos || data.videos.length === 0) {
                container.innerHTML = `
                    <div style="text-align: center; padding: 40px;">
                        <div style="font-size: 24px; margin-bottom: 10px;">📭 No Videos Found</div>
                        <p style="color: #6c757d;">This student hasn't uploaded any videos yet.</p>
                    </div>
                `;
                return;
            }
            
            // Display summary stats
            let html = '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin-bottom: 20px;">';
            html += '<div style="background: #e7f3ff; padding: 15px; border-radius: 8px; text-align: center;">';
            html += '<div style="font-size: 24px; font-weight: bold; color: #667eea;">' + data.videos.length + '</div>';
            html += '<div style="font-size: 12px; color: #6c757d;">Total Videos</div>';
            html += '</div>';
            
            const totalViews = data.videos.reduce((sum, v) => sum + (v.viewCount || 0), 0);
            html += '<div style="background: #d1ecf1; padding: 15px; border-radius: 8px; text-align: center;">';
            html += '<div style="font-size: 24px; font-weight: bold; color: #17a2b8;">' + totalViews + '</div>';
            html += '<div style="font-size: 12px; color: #6c757d;">Total Views</div>';
            html += '</div>';
            html += '</div>';
            
            // Display videos in a grid
            html += '<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 20px;">';
            
            data.videos.forEach(video => {
                const uploadDate = new Date(video.uploadDate).toLocaleDateString('en-IN', {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric'
                });
                
                html += '<div style="border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); transition: transform 0.2s; cursor: pointer;" onmouseover="this.style.transform=\'translateY(-5px)\'; this.style.boxShadow=\'0 4px 12px rgba(0,0,0,0.15)\';" onmouseout="this.style.transform=\'translateY(0)\'; this.style.boxShadow=\'0 2px 8px rgba(0,0,0,0.1)\';">';
                
                // Thumbnail
                if (video.thumbnailUrl) {
                    html += '<div style="position: relative; width: 100%; height: 150px; background: #f0f0f0; overflow: hidden;">';
                    html += '<img src="' + video.thumbnailUrl + '" style="width: 100%; height: 100%; object-fit: cover;" alt="Video thumbnail">';
                    html += '<div style="position: absolute; inset: 0; background: rgba(0,0,0,0.3); display: flex; align-items: center; justify-content: center; opacity: 0; transition: opacity 0.2s;" onmouseover="this.style.opacity=\'1\'" onmouseout="this.style.opacity=\'0\'">';
                    html += '<a href="' + video.youtubeUrl + '" target="_blank" style="background: #667eea; color: white; padding: 8px 12px; border-radius: 6px; text-decoration: none; font-size: 12px; font-weight: 600;">▶ Watch on YouTube</a>';
                    html += '</div>';
                    html += '</div>';
                } else {
                    html += '<div style="width: 100%; height: 150px; background: #f0f0f0; display: flex; align-items: center; justify-content: center; color: #999;">';
                    html += '🎬 No Thumbnail';
                    html += '</div>';
                }
                
                // Video details
                html += '<div style="padding: 15px;">';
                html += '<h3 style="margin: 0 0 10px 0; font-size: 14px; font-weight: 600; color: #2d3748;">' + video.title + '</h3>';
                
                if (video.description) {
                    const shortDesc = video.description.length > 80 ? video.description.substring(0, 80) + '...' : video.description;
                    html += '<p style="margin: 0 0 10px 0; font-size: 12px; color: #718096;">' + shortDesc + '</p>';
                }
                
                html += '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; font-size: 11px; color: #a0aec0;">';
                html += '<span>📅 ' + uploadDate + '</span>';
                html += '<span>👁️ ' + (video.viewCount || 0) + ' views</span>';
                html += '</div>';
                
                if (video.category) {
                    html += '<div style="display: flex; gap: 5px; flex-wrap: wrap; margin-bottom: 10px;">';
                    html += '<span style="background: #667eea; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px;">' + video.category + '</span>';
                    if (video.subCategory) {
                        html += '<span style="background: #764ba2; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px;">' + video.subCategory + '</span>';
                    }
                    html += '</div>';
                }
                
                html += '<div style="display: flex; gap: 8px;">';
                html += '<a href="' + video.youtubeUrl + '" target="_blank" style="flex: 1; background: #667eea; color: white; padding: 6px; border-radius: 4px; text-decoration: none; text-align: center; font-size: 12px; font-weight: 600; transition: background 0.2s;" onmouseover="this.style.background=\'#764ba2\'" onmouseout="this.style.background=\'#667eea\'">Watch on YouTube</a>';
                html += '</div>';
                
                html += '</div>';
                html += '</div>';
            });
            
            html += '</div>';
            
            container.innerHTML = html;
        }
        
        function closeVideosModal() {
            const modal = document.getElementById('videosModal');
            if (modal) {
                modal.style.animation = 'fadeOut 0.3s';
                setTimeout(() => {
                    modal.remove();
                    document.body.style.overflow = 'auto';
                }, 300);
            }
        }
        
        // Close videos modal when clicking outside
        document.addEventListener('click', function(event) {
            const modal = document.getElementById('videosModal');
            if (modal && event.target === modal) {
                closeVideosModal();
            }
        });
    </script>
</body>
</html>
