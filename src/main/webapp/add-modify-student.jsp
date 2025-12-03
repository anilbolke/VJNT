<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.StudentDAO" %>
<%@ page import="com.vjnt.model.Student" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
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
    
    // Check if editing existing student
    String studentIdParam = request.getParameter("studentId");
    Student editStudent = null;
    boolean isEdit = false;
    
    if (studentIdParam != null && !studentIdParam.isEmpty()) {
        try {
            int studentId = Integer.parseInt(studentIdParam);
            editStudent = studentDAO.getStudentById(studentId);
            if (editStudent != null && editStudent.getUdiseNo().equals(udiseNo)) {
                isEdit = true;
            }
        } catch (NumberFormatException e) {
            // Invalid student ID
        }
    }
    
    // Handle form submission
    String action = request.getParameter("action");
    String successMessage = "";
    String errorMessage = "";
    
    if ("save".equals(action)) {
        try {
            Student student = new Student();
            
            if (isEdit && editStudent != null) {
                student.setStudentId(editStudent.getStudentId());
            }
            
            // Auto-populated fields
            student.setDivision(user.getDivisionName());
            student.setDistrict(user.getDistrictName());
            student.setUdiseNo(udiseNo);
            
            // User input fields
            student.setStudentClass(request.getParameter("studentClass"));
            student.setSection(request.getParameter("section"));
            student.setClassCategory(request.getParameter("classCategory"));
            student.setStudentName(request.getParameter("studentName"));
            student.setGender(request.getParameter("gender"));
            student.setStudentPen(request.getParameter("studentPen"));
            
            // Active/Inactive status (default to active if not specified)
            String isActiveParam = request.getParameter("isActive");
            boolean isActive = isActiveParam == null || "true".equals(isActiveParam);
            // Note: Add isActive field to Student model if not already present
            
            if (isEdit && editStudent != null) {
                student.setCreatedDate(editStudent.getCreatedDate());
                student.setCreatedBy(editStudent.getCreatedBy());
                student.setUpdatedDate(new Date());
                student.setUpdatedBy(user.getUsername());
                // Update existing student
                if (studentDAO.updateStudent(student)) {
                    successMessage = "✓ Student record updated successfully!";
                    // Refresh the student data
                    editStudent = studentDAO.getStudentById(student.getStudentId());
                } else {
                    errorMessage = "✗ Error updating student. Please check the details and try again.";
                }
            } else {
                student.setCreatedDate(new Date());
                student.setCreatedBy(user.getUsername());
                student.setUpdatedDate(new Date());
                student.setUpdatedBy(user.getUsername());
                // Add new student
                if (studentDAO.createStudent(student)) {
                    successMessage = "✓ Student record added successfully!";
                    // Reset form for next entry
                    editStudent = null;
                } else {
                    errorMessage = "✗ Error adding student. Please check the details and try again.";
                }
            }
        } catch (Exception e) {
            errorMessage = "✗ Error saving student: " + e.getMessage();
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isEdit ? "Modify Student" : "Add Student" %> - <%= schoolName %></title>
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
            max-width: 900px;
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
        
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .alert-success {
            background: #c8e6c9;
            color: #2e7d32;
            border-left: 4px solid #4caf50;
        }
        
        .alert-error {
            background: #ffcdd2;
            color: #c62828;
            border-left: 4px solid #f44336;
        }
        
        .form-section {
            margin-bottom: 25px;
        }
        
        .section-title {
            font-size: 16px;
            font-weight: 700;
            color: #333;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        
        .form-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .form-group {
            display: flex;
            flex-direction: column;
        }
        
        .form-group label {
            font-weight: 600;
            color: #333;
            margin-bottom: 8px;
            font-size: 14px;
        }
        
        .form-group label .required {
            color: #f44336;
            margin-left: 3px;
        }
        
        .form-group input,
        .form-group select,
        .form-group textarea {
            padding: 12px 14px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            font-size: 14px;
            font-family: inherit;
            transition: all 0.3s;
        }
        
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .form-group input[type="text"],
        .form-group input[type="email"],
        .form-group input[type="date"],
        .form-group select {
            height: 45px;
        }
        
        .form-group select {
            cursor: pointer;
        }
        
        .form-actions {
            display: flex;
            gap: 15px;
            justify-content: flex-start;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 2px solid #e0e0e0;
        }
        
        .btn {
            padding: 12px 30px;
            border: none;
            border-radius: 6px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            text-decoration: none;
            display: inline-block;
        }
        
        .btn-submit {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .btn-submit:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        
        .btn-reset {
            background: #95a5a6;
            color: white;
        }
        
        .btn-reset:hover {
            background: #7f8c8d;
        }
        
        .info-box {
            background: #f0f2f5;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            border-left: 4px solid #667eea;
        }
        
        .info-box p {
            color: #555;
            font-size: 13px;
            line-height: 1.6;
            margin: 5px 0;
        }
        
        .info-box strong {
            color: #333;
        }
        
        @media (max-width: 768px) {
            .header {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }
            
            .form-grid {
                grid-template-columns: 1fr;
            }
            
            .form-actions {
                flex-direction: column;
            }
            
            .btn {
                width: 100%;
                text-align: center;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1><%= isEdit ? "📝 Modify Student" : "➕ Add New Student" %></h1>
                <div class="header-subtitle">School: <%= schoolName %> (UDISE: <%= udiseNo %>)</div>
            </div>
            <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="btn-back">🏠 Back to Dashboard</a>
        </div>
        
        <div class="content">
            <% if (!successMessage.isEmpty()) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div><%= successMessage %></div>
            </div>
            <% } %>
            
            <% if (!errorMessage.isEmpty()) { %>
            <div class="alert alert-error">
                <span>✗</span>
                <div><%= errorMessage %></div>
            </div>
            <% } %>
            
            <div class="info-box">
                <p><strong>📋 Instructions:</strong> System auto-populates <strong>Division, District, and UDISE Number</strong>. Fill in all other required fields marked with <span style="color: #f44336;">*</span>.</p>
            </div>
            
            <form method="POST" action="<%= request.getContextPath() %>/add-modify-student.jsp<% if (isEdit && editStudent != null) { %>?studentId=<%= editStudent.getStudentId() %><% } %>">
                <input type="hidden" name="action" value="save">
                
                <!-- Auto-Populated System Information Section -->
                <div class="form-section">
                    <div class="section-title">🔒 System Information (Auto-Populated)</div>
                    
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Division</label>
                            <input type="text" value="<%= user.getDivisionName() %>" disabled 
                                   placeholder="Auto-populated">
                        </div>
                        
                        <div class="form-group">
                            <label>District</label>
                            <input type="text" value="<%= user.getDistrictName() %>" disabled 
                                   placeholder="Auto-populated">
                        </div>
                        
                        <div class="form-group">
                            <label>UDISE Number</label>
                            <input type="text" value="<%= udiseNo %>" disabled 
                                   placeholder="Auto-populated">
                        </div>
                    </div>
                </div>
                
                <!-- Personal Information Section -->
                <div class="form-section">
                    <div class="section-title">👤 Personal Information</div>
                    
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Student Name <span class="required">*</span></label>
                            <input type="text" name="studentName" required 
                                   value="<%= editStudent != null ? editStudent.getStudentName() : "" %>" 
                                   placeholder="Enter student name">
                        </div>
                        
                        <div class="form-group">
                            <label>Gender <span class="required">*</span></label>
                            <select name="gender" required>
                                <option value="">-- Select Gender --</option>
                                <option value="Male" <%= editStudent != null && "Male".equals(editStudent.getGender()) ? "selected" : "" %>>Male (पुरुष)</option>
                                <option value="Female" <%= editStudent != null && "Female".equals(editStudent.getGender()) ? "selected" : "" %>>Female (स्त्री)</option>
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label>Student PEN <span class="required">*</span></label>
                            <input type="text" name="studentPen" required 
                                   value="<%= editStudent != null && editStudent.getStudentPen() != null ? editStudent.getStudentPen() : "" %>" 
                                   placeholder="Enter PEN">
                        </div>
                    </div>
                </div>
                
                <!-- Academic Information Section -->
                <div class="form-section">
                    <div class="section-title">🎓 Academic Information</div>
                    
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Class <span class="required">*</span></label>
                            <select name="studentClass" required>
                                <option value="">-- Select Class --</option>
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
                        
                        <div class="form-group">
                            <label>Section <span class="required">*</span></label>
                            <select name="section" required>
                                <option value="">-- Select Section --</option>
                                <option value="A" <%= editStudent != null && "A".equals(editStudent.getSection()) ? "selected" : "" %>>Section A</option>
                                <option value="B" <%= editStudent != null && "B".equals(editStudent.getSection()) ? "selected" : "" %>>Section B</option>
                                <option value="C" <%= editStudent != null && "C".equals(editStudent.getSection()) ? "selected" : "" %>>Section C</option>
                                <option value="D" <%= editStudent != null && "D".equals(editStudent.getSection()) ? "selected" : "" %>>Section D</option>
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label>Class Category <span class="required">*</span></label>
                            <select name="classCategory" required>
                                <option value="">-- Select Category --</option>
                                <option value="Primary" <%= editStudent != null && "Primary".equals(editStudent.getClassCategory()) ? "selected" : "" %>>Primary</option>
                                <option value="Higher Primary" <%= editStudent != null && "Higher Primary".equals(editStudent.getClassCategory()) ? "selected" : "" %>>Higher Primary</option>
                                <option value="Secondary" <%= editStudent != null && "Secondary".equals(editStudent.getClassCategory()) ? "selected" : "" %>>Secondary</option>
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label>Status <span class="required">*</span></label>
                            <select name="isActive" required>
                                <option value="true">Active (सक्रिय)</option>
                                <option value="false">Inactive (निष्क्रिय)</option>
                            </select>
                        </div>
                    </div>
                </div>
                
                <!-- Form Actions -->
                <div class="form-actions">
                    <button type="submit" class="btn btn-submit">
                        <%= isEdit ? "💾 Update Student" : "➕ Add Student" %>
                    </button>
                    <button type="reset" class="btn btn-reset">
                        🔄 Clear Form
                    </button>
                </div>
            </form>
        </div>
    </div>
</body>
</html>
