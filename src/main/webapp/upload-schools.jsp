<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%
    // Check if user is logged in
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    // Only DATA_ADMIN can access
    if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=access_denied");
        return;
    }
    
    SchoolDAO schoolDAO = new SchoolDAO();
    int totalSchools = schoolDAO.getSchoolCount();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Upload Schools - Data Admin</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .upload-container {
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.15);
            width: 100%;
            max-width: 600px;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
            background: #f0f2f5;
            padding: 20px;
            border-radius: 8px;
        }
        
        .header h1 {
            color: #000;
            font-size: 26px;
            margin-bottom: 10px;
        }
        
        .header p {
            color: #000;
            font-size: 14px;
        }
        
        .info-box {
            background: #e3f2fd;
            border-left: 4px solid #2196f3;
            padding: 15px;
            border-radius: 6px;
            margin-bottom: 25px;
        }
        
        .info-box h3 {
            color: #1976d2;
            font-size: 16px;
            margin-bottom: 10px;
        }
        
        .info-box ul {
            margin-left: 20px;
            color: #424242;
            font-size: 14px;
            line-height: 1.8;
        }
        
        .stats-box {
            background: #f7fafc;
            border: 1px solid #e2e8f0;
            padding: 15px;
            border-radius: 6px;
            margin-bottom: 25px;
            text-align: center;
        }
        
        .stats-value {
            font-size: 36px;
            font-weight: 700;
            color: #667eea;
        }
        
        .stats-label {
            font-size: 14px;
            color: #718096;
            margin-top: 5px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #4a5568;
            font-weight: 500;
            font-size: 14px;
        }
        
        .file-input-wrapper {
            position: relative;
            overflow: hidden;
            display: inline-block;
            width: 100%;
        }
        
        .file-input-wrapper input[type=file] {
            position: absolute;
            left: -9999px;
        }
        
        .file-label {
            display: block;
            padding: 15px;
            background: #f7fafc;
            border: 2px dashed #cbd5e0;
            border-radius: 6px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .file-label:hover {
            background: #edf2f7;
            border-color: #667eea;
        }
        
        .file-label .icon {
            font-size: 48px;
            margin-bottom: 10px;
        }
        
        .file-name {
            margin-top: 10px;
            padding: 10px;
            background: #e6fffa;
            border-radius: 6px;
            color: #234e52;
            font-size: 14px;
            word-break: break-all;
        }
        
        .btn-group {
            display: flex;
            gap: 10px;
            margin-top: 20px;
        }
        
        .btn {
            flex: 1;
            padding: 12px;
            border: none;
            border-radius: 6px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            text-decoration: none;
            text-align: center;
        }
        
        .btn-primary {
            background: #667eea;
            color: white;
        }
        
        .btn-primary:hover {
            background: #5568d3;
        }
        
        .btn-primary:disabled {
            background: #cbd5e0;
            cursor: not-allowed;
        }
        
        .btn-secondary {
            background: #e2e8f0;
            color: #4a5568;
        }
        
        .btn-secondary:hover {
            background: #cbd5e0;
        }
        
        .alert {
            padding: 12px 16px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-size: 14px;
            line-height: 1.5;
        }
        
        .alert-success {
            background-color: #c6f6d5;
            color: #276749;
            border-left: 4px solid #48bb78;
        }
        
        .alert-error {
            background-color: #fed7d7;
            color: #c53030;
            border-left: 4px solid #fc8181;
        }
        
        @media (max-width: 600px) {
            .upload-container {
                padding: 25px 20px;
            }
            
            .btn-group {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <div class="upload-container">
        <div class="header">
            <h1>🏫 Upload School Master Data</h1>
            <p>Upload Excel file with UDISE and School Names</p>
        </div>
        
        <% 
        String successMessage = (String) request.getAttribute("successMessage");
        String errorMessage = (String) request.getAttribute("errorMessage");
        
        if (successMessage != null) { 
        %>
            <div class="alert alert-success">
                <%= successMessage %>
            </div>
        <% } %>
        
        <% if (errorMessage != null) { %>
            <div class="alert alert-error">
                <%= errorMessage %>
            </div>
        <% } %>
        
        <div class="stats-box">
            <div class="stats-value"><%= totalSchools %></div>
            <div class="stats-label">Schools Currently in Database</div>
        </div>
        
        <div class="info-box">
            <h3>📋 Excel File Format Requirements:</h3>
            <ul>
                <li><strong>Column A (1):</strong> District Name (Optional)</li>
                <li><strong>Column B (2):</strong> School Name (Required)</li>
                <li><strong>Column C (3):</strong> UDISE No (Required)</li>
                <li>First row should contain headers</li>
                <li>File format: .xlsx or .xls</li>
                <li>Duplicate UDISE numbers will be updated</li>
            </ul>
        </div>
        
        <form action="<%= request.getContextPath() %>/upload-schools" method="post" enctype="multipart/form-data" id="uploadForm">
            <div class="form-group">
                <label>Select Excel File:</label>
                <div class="file-input-wrapper">
                    <input type="file" name="schoolFile" id="schoolFile" accept=".xlsx,.xls" required>
                    <label for="schoolFile" class="file-label">
                        <div class="icon">📄</div>
                        <div>Click to browse or drag file here</div>
                        <div style="font-size: 12px; color: #718096; margin-top: 8px;">
                            Accepted: Excel files (.xlsx, .xls)
                        </div>
                    </label>
                </div>
                <div id="fileName" class="file-name" style="display: none;"></div>
            </div>
            
            <div class="btn-group">
                <button type="submit" class="btn btn-primary" id="uploadBtn">
                    📤 Upload Schools
                </button>
                <a href="<%= request.getContextPath() %>/data-admin-dashboard.jsp" class="btn btn-secondary">
                    ← Back to Dashboard
                </a>
            </div>
        </form>
    </div>
    
    <script>
        // Show selected file name
        document.getElementById('schoolFile').addEventListener('change', function(e) {
            const fileName = e.target.files[0]?.name;
            const fileNameDiv = document.getElementById('fileName');
            
            if (fileName) {
                fileNameDiv.textContent = '📎 Selected: ' + fileName;
                fileNameDiv.style.display = 'block';
            } else {
                fileNameDiv.style.display = 'none';
            }
        });
        
        // Show loading state on submit
        document.getElementById('uploadForm').addEventListener('submit', function() {
            const btn = document.getElementById('uploadBtn');
            btn.disabled = true;
            btn.textContent = '⏳ Uploading...';
        });
    </script>
</body>
</html>
