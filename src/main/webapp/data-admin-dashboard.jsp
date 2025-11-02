<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    // Check if user is logged in
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    // Only DATA_ADMIN can access
    if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Data Admin Dashboard - VJNT Class Management</title>
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
        }
        
        .header {
            background: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            color: #333;
            font-size: 24px;
        }
        
        .logout-btn {
            padding: 10px 20px;
            background: #f44336;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
        }
        
        .logout-btn:hover {
            background: #d32f2f;
        }
        
        .upload-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        
        .upload-section h2 {
            color: #333;
            margin-bottom: 20px;
        }
        
        .info-box {
            background: #e3f2fd;
            border-left: 4px solid #2196f3;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        
        .info-box h3 {
            color: #1976d2;
            font-size: 16px;
            margin-bottom: 10px;
        }
        
        .info-box ul {
            margin-left: 20px;
            color: #555;
        }
        
        .info-box li {
            margin: 5px 0;
        }
        
        .upload-area {
            border: 3px dashed #ccc;
            border-radius: 10px;
            padding: 40px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
            margin-bottom: 20px;
        }
        
        .upload-area:hover {
            border-color: #667eea;
            background: #f8f9fa;
        }
        
        .upload-area.dragover {
            border-color: #667eea;
            background: #e3f2fd;
        }
        
        .upload-icon {
            font-size: 48px;
            margin-bottom: 15px;
        }
        
        .file-input {
            display: none;
        }
        
        .btn-upload {
            padding: 12px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            cursor: pointer;
            transition: transform 0.2s;
        }
        
        .btn-upload:hover {
            transform: translateY(-2px);
        }
        
        .btn-upload:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        
        .file-info {
            margin: 20px 0;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 5px;
            display: none;
        }
        
        .file-info.show {
            display: block;
        }
        
        .progress-bar {
            width: 100%;
            height: 30px;
            background: #e0e0e0;
            border-radius: 15px;
            overflow: hidden;
            margin: 20px 0;
            display: none;
        }
        
        .progress-bar.show {
            display: block;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            width: 0%;
            transition: width 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
        }
        
        .result-box {
            padding: 20px;
            border-radius: 8px;
            margin-top: 20px;
            display: none;
        }
        
        .result-box.show {
            display: block;
        }
        
        .result-box.success {
            background: #e8f5e9;
            border: 1px solid #4caf50;
            color: #2e7d32;
        }
        
        .result-box.error {
            background: #ffebee;
            border: 1px solid #f44336;
            color: #c62828;
        }
        
        .result-box pre {
            white-space: pre-wrap;
            margin-top: 10px;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div>
                <h1>📊 Data Admin Dashboard</h1>
                <p style="color: #666; margin-top: 5px;">Welcome, <%= user.getFullName() %></p>
            </div>
            <a href="<%= request.getContextPath() %>/logout" class="logout-btn">Logout</a>
        </div>
        
        <!-- Upload Section -->
        <div class="upload-section">
            <h2>📤 Upload Student Data (Excel)</h2>
            
            <!-- Information Box -->
            <div class="info-box">
                <h3>ℹ️ Excel File Format Requirements:</h3>
                <ul>
                    <li><strong>Column 0:</strong> Division</li>
                    <li><strong>Column 1:</strong> District (Dist)</li>
                    <li><strong>Column 2:</strong> UDISE NO</li>
                    <li><strong>Column 3:</strong> Class</li>
                    <li><strong>Column 4:</strong> Section</li>
                    <li><strong>Column 5:</strong> Class Category</li>
                    <li><strong>Column 6:</strong> Student Name</li>
                    <li><strong>Column 7:</strong> Gender</li>
                    <li><strong>Column 8:</strong> Student PEN</li>
                    <li><strong>Column 9:</strong> मराठी भाषा स्तर (Marathi Level)</li>
                    <li><strong>Column 10:</strong> गणित स्तर (Math Level)</li>
                    <li><strong>Column 11:</strong> इंग्रजी स्तर (English Level)</li>
                </ul>
                <p style="margin-top: 10px; font-weight: bold;">Note: First row must be header. Data starts from row 2.</p>
            </div>
            
            <!-- Upload Area -->
            <div class="upload-area" id="uploadArea">
                <div class="upload-icon">📁</div>
                <h3>Click to select Excel file or drag & drop here</h3>
                <p style="color: #666; margin-top: 10px;">Supported formats: .xlsx, .xls</p>
                <input type="file" id="fileInput" class="file-input" accept=".xlsx,.xls">
            </div>
            
            <!-- File Info -->
            <div class="file-info" id="fileInfo">
                <strong>Selected File:</strong> <span id="fileName"></span>
                <br>
                <strong>Size:</strong> <span id="fileSize"></span>
            </div>
            
            <!-- Upload Button -->
            <button class="btn-upload" id="uploadBtn" onclick="uploadFile()" disabled>
                📤 Upload and Process
            </button>
            
            <!-- Progress Bar -->
            <div class="progress-bar" id="progressBar">
                <div class="progress-fill" id="progressFill">0%</div>
            </div>
            
            <!-- Result Box -->
            <div class="result-box" id="resultBox">
                <strong id="resultTitle"></strong>
                <pre id="resultMessage"></pre>
            </div>
        </div>
    </div>
    
    <script>
        let selectedFile = null;
        
        // Get elements
        const uploadArea = document.getElementById('uploadArea');
        const fileInput = document.getElementById('fileInput');
        const fileInfo = document.getElementById('fileInfo');
        const fileName = document.getElementById('fileName');
        const fileSize = document.getElementById('fileSize');
        const uploadBtn = document.getElementById('uploadBtn');
        const progressBar = document.getElementById('progressBar');
        const progressFill = document.getElementById('progressFill');
        const resultBox = document.getElementById('resultBox');
        const resultTitle = document.getElementById('resultTitle');
        const resultMessage = document.getElementById('resultMessage');
        
        // Click to select file
        uploadArea.addEventListener('click', () => {
            fileInput.click();
        });
        
        // File selected
        fileInput.addEventListener('change', (e) => {
            if (e.target.files.length > 0) {
                selectedFile = e.target.files[0];
                displayFileInfo(selectedFile);
            }
        });
        
        // Drag and drop
        uploadArea.addEventListener('dragover', (e) => {
            e.preventDefault();
            uploadArea.classList.add('dragover');
        });
        
        uploadArea.addEventListener('dragleave', () => {
            uploadArea.classList.remove('dragover');
        });
        
        uploadArea.addEventListener('drop', (e) => {
            e.preventDefault();
            uploadArea.classList.remove('dragover');
            
            if (e.dataTransfer.files.length > 0) {
                selectedFile = e.dataTransfer.files[0];
                displayFileInfo(selectedFile);
            }
        });
        
        // Display file info
        function displayFileInfo(file) {
            fileName.textContent = file.name;
            fileSize.textContent = formatFileSize(file.size);
            fileInfo.classList.add('show');
            uploadBtn.disabled = false;
            resultBox.classList.remove('show');
        }
        
        // Format file size
        function formatFileSize(bytes) {
            if (bytes < 1024) return bytes + ' B';
            if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
            return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
        }
        
        // Upload file
        function uploadFile() {
            if (!selectedFile) {
                alert('Please select a file first');
                return;
            }
            
            // Validate file type
            if (!selectedFile.name.endsWith('.xlsx') && !selectedFile.name.endsWith('.xls')) {
                showResult(false, 'Invalid file type. Please upload Excel file (.xlsx or .xls)');
                return;
            }
            
            // Show progress
            uploadBtn.disabled = true;
            uploadBtn.textContent = '⏳ Uploading...';
            progressBar.classList.add('show');
            resultBox.classList.remove('show');
            
            // Create form data
            const formData = new FormData();
            formData.append('excelFile', selectedFile);
            
            // Upload file
            fetch('<%= request.getContextPath() %>/upload-excel', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                progressFill.style.width = '100%';
                progressFill.textContent = '100%';
                
                setTimeout(() => {
                    showResult(data.success, data.message);
                    uploadBtn.disabled = false;
                    uploadBtn.textContent = '📤 Upload and Process';
                    progressBar.classList.remove('show');
                    progressFill.style.width = '0%';
                    
                    if (data.success) {
                        // Reset form
                        selectedFile = null;
                        fileInput.value = '';
                        fileInfo.classList.remove('show');
                        uploadBtn.disabled = true;
                    }
                }, 500);
            })
            .catch(error => {
                showResult(false, 'Error uploading file: ' + error.message);
                uploadBtn.disabled = false;
                uploadBtn.textContent = '📤 Upload and Process';
                progressBar.classList.remove('show');
            });
        }
        
        // Show result
        function showResult(success, message) {
            resultBox.classList.remove('success', 'error');
            resultBox.classList.add(success ? 'success' : 'error');
            resultTitle.textContent = success ? '✅ Success!' : '❌ Error!';
            resultMessage.textContent = message;
            resultBox.classList.add('show');
        }
    </script>
</body>
</html>
