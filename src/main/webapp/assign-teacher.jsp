<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.vjnt.util.DatabaseConnection" %>
<%@ page import="java.util.*" %>

<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    if (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) {
        response.sendRedirect(request.getContextPath() + "/dashboard.jsp");
        return;
    }
    
    String udiseCode = user.getUdiseNo();
    String district = user.getDistrictName() != null && !user.getDistrictName().isEmpty() ? user.getDistrictName() : "";
    String division = user.getDivisionName() != null && !user.getDivisionName().isEmpty() ? user.getDivisionName() : "";
    
    // If district/division not in user object, get from students table (any student from this school)
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    if (district.isEmpty() || division.isEmpty()) {
        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT district, division FROM students WHERE udise_code = ? LIMIT 1";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, udiseCode);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                if (district.isEmpty()) district = rs.getString("district") != null ? rs.getString("district") : "";
                if (division.isEmpty()) division = rs.getString("division") != null ? rs.getString("division") : "";
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { }
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
            if (conn != null) try { conn.close(); } catch (SQLException e) { }
        }
    }
    
    // Get all teachers
    List<Map<String, Object>> teachers = new ArrayList<>();
    try {
        conn = DatabaseConnection.getConnection();
        String sql = "SELECT teacher_id, teacher_name, subjects_taught FROM teachers WHERE udise_code = ? AND is_active = 1 ORDER BY teacher_name";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, udiseCode);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> teacher = new HashMap<>();
            teacher.put("id", rs.getInt("teacher_id"));
            teacher.put("name", rs.getString("teacher_name"));
            teacher.put("subjects", rs.getString("subjects_taught"));
            teachers.add(teacher);
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
        if (conn != null) try { conn.close(); } catch (SQLException e) { }
    }
    
    // Get all assignments
    List<Map<String, Object>> assignments = new ArrayList<>();
    try {
        conn = DatabaseConnection.getConnection();
        String sql = "SELECT assignment_id, teacher_name, class, section, subjects_assigned, created_date " +
                     "FROM teacher_assignments WHERE udise_code = ? AND is_active = 1 ORDER BY class, section, teacher_name";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, udiseCode);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> assignment = new HashMap<>();
            assignment.put("id", rs.getInt("assignment_id"));
            assignment.put("teacherName", rs.getString("teacher_name"));
            assignment.put("class", rs.getString("class"));
            assignment.put("section", rs.getString("section"));
            assignment.put("subjects", rs.getString("subjects_assigned"));
            assignment.put("createdDate", rs.getTimestamp("created_date"));
            assignments.add(assignment);
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { }
        if (conn != null) try { conn.close(); } catch (SQLException e) { }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Assign Teacher - VJNT</title>
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
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            font-size: 28px;
            font-weight: 700;
        }
        
        .btn {
            padding: 10px 20px;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: all 0.3s;
            border: none;
            cursor: pointer;
            display: inline-block;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.3);
        }
        
        .btn-primary {
            background: #667eea;
            color: white;
        }
        
        .btn-success {
            background: #4caf50;
            color: white;
        }
        
        .btn-danger {
            background: #f44336;
            color: white;
        }
        
        .btn-small {
            padding: 6px 12px;
            font-size: 13px;
        }
        
        .content {
            padding: 30px;
        }
        
        .form-section {
            background: #f9f9f9;
            padding: 30px;
            border-radius: 12px;
            margin-bottom: 30px;
        }
        
        .form-section h2 {
            color: #333;
            margin-bottom: 20px;
            font-size: 22px;
        }
        
        .form-row {
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
            margin-bottom: 8px;
            color: #333;
        }
        
        .form-group input,
        .form-group select {
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
        }
        
        .form-group input:focus,
        .form-group select:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .form-group input:disabled {
            background: #f5f5f5;
            cursor: not-allowed;
        }
        
        /* Readonly fields styling - auto-filled fields */
        .form-group input[readonly] {
            background: #e8f5e9;
            border: 2px solid #4caf50;
            color: #2e7d32;
            font-weight: 600;
            cursor: not-allowed;
        }
        
        /* Add icon to readonly field labels */
        .auto-fill-label {
            display: flex;
            align-items: center;
            gap: 5px;
        }
        
        .auto-fill-label::before {
            content: "🔒";
            font-size: 14px;
        }
        
        .checkbox-group {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
            gap: 12px;
            padding: 15px;
            background: white;
            border-radius: 8px;
            border: 2px solid #e0e0e0;
        }
        
        .checkbox-group label {
            display: flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            font-weight: normal;
        }
        
        .checkbox-group input[type="checkbox"] {
            width: 18px;
            height: 18px;
            cursor: pointer;
        }
        
        .assignments-table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-radius: 10px;
            overflow: hidden;
        }
        
        .assignments-table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .assignments-table th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            font-size: 14px;
        }
        
        .assignments-table td {
            padding: 15px;
            border-bottom: 1px solid #e0e0e0;
            font-size: 14px;
        }
        
        .assignments-table tbody tr:hover {
            background: #f5f7fa;
        }
        
        .subject-badge {
            display: inline-block;
            padding: 4px 8px;
            background: #e3f2fd;
            color: #1976d2;
            border-radius: 4px;
            font-size: 12px;
            margin-right: 5px;
            margin-bottom: 5px;
        }
        
        .action-buttons {
            display: flex;
            gap: 8px;
        }
        
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-weight: 500;
        }
        
        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .alert-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }
        
        .empty-state-icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        
        #subjectCheckboxes {
            display: none;
        }
        
        .required {
            color: red;
        }
        
        /* Modal styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
        }
        
        .modal.show {
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .modal-content {
            background: white;
            border-radius: 15px;
            max-width: 700px;
            width: 90%;
            max-height: 90vh;
            overflow-y: auto;
        }
        
        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-radius: 15px 15px 0 0;
        }
        
        .modal-header h2 {
            font-size: 24px;
        }
        
        .close {
            font-size: 32px;
            cursor: pointer;
            line-height: 1;
        }
        
        .modal-body {
            padding: 30px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1>👨‍🏫 Assign Teacher to Class</h1>
                <p style="margin-top: 5px; opacity: 0.9;">शिक्षक वर्ग नियुक्ती / Assign teachers to classes and subjects</p>
            </div>
            <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="btn">
                ← Back to Dashboard
            </a>
        </div>
        
        <div class="content">
            <!-- Assignment Form -->
            <div class="form-section">
                <h2>📝 Create New Assignment</h2>
                
                <form id="assignmentForm" onsubmit="submitAssignment(event)">
                    <div class="form-row">
                        <div class="form-group">
                            <label class="auto-fill-label">UDISE Code <span style="color: #666; font-size: 12px; font-weight: normal;">(Auto-filled)</span></label>
                            <input type="text" id="udiseCode" name="udiseCode" value="<%= udiseCode %>" readonly title="This field is automatically filled and cannot be edited">
                        </div>
                        
                        <div class="form-group">
                            <label class="auto-fill-label">District <span style="color: #666; font-size: 12px; font-weight: normal;">(Auto-filled)</span></label>
                            <input type="text" id="district" name="district" value="<%= district %>" readonly title="This field is automatically filled and cannot be edited">
                        </div>
                        
                        <div class="form-group">
                            <label class="auto-fill-label">Division <span style="color: #666; font-size: 12px; font-weight: normal;">(Auto-filled)</span></label>
                            <input type="text" id="division" name="division" value="<%= division %>" readonly title="This field is automatically filled and cannot be edited">
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label>Class <span class="required">*</span></label>
                            <select id="classSelect" name="class" required onchange="loadSections()">
                                <option value="">Select Class</option>
                                <option value="I">I (First)</option>
                                <option value="II">II (Second)</option>
                                <option value="III">III (Third)</option>
                                <option value="IV">IV (Fourth)</option>
                                <option value="V">V (Fifth)</option>
                                <option value="VI">VI (Sixth)</option>
                                <option value="VII">VII (Seventh)</option>
                                <option value="VIII">VIII (Eighth)</option>
                                <option value="IX">IX (Ninth)</option>
                                <option value="X">X (Tenth)</option>
                                <option value="XI">XI (Eleventh)</option>
                                <option value="XII">XII (Twelfth)</option>
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label>Section <span class="required">*</span></label>
                            <select id="sectionSelect" name="section" required>
                                <option value="">Select Section</option>
                                <option value="A">A</option>
                                <option value="B">B</option>
                                <option value="C">C</option>
                                <option value="D">D</option>
                                <option value="E">E</option>
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label>Teacher <span class="required">*</span></label>
                            <select id="teacherSelect" name="teacherId" required onchange="loadTeacherSubjects()">
                                <option value="">Select Teacher</option>
                                <% for (Map<String, Object> teacher : teachers) { %>
                                    <option value="<%= teacher.get("id") %>" 
                                            data-name="<%= teacher.get("name") %>"
                                            data-subjects="<%= teacher.get("subjects") %>">
                                        <%= teacher.get("name") %>
                                    </option>
                                <% } %>
                            </select>
                        </div>
                    </div>
                    
                    <div class="form-group" id="subjectCheckboxes">
                        <label>Subjects to Assign <span class="required">*</span></label>
                        <div class="checkbox-group" id="subjectsContainer">
                            <!-- Subjects will be loaded here dynamically -->
                        </div>
                        <span id="subjectError" style="color: red; font-size: 12px; display: none;">Please select at least one subject</span>
                    </div>
                    
                    <div style="margin-top: 30px; display: flex; gap: 15px;">
                        <button type="submit" class="btn btn-success">💾 Save Assignment</button>
                        <button type="button" class="btn" onclick="resetForm()">🔄 Reset</button>
                    </div>
                </form>
            </div>
            
            <!-- Assignments Table -->
            <div>
                <h2 style="margin-bottom: 20px;">📋 Current Assignments</h2>
                
                <% if (assignments.isEmpty()) { %>
                    <div class="empty-state">
                        <div class="empty-state-icon">👨‍🏫</div>
                        <h2>No Assignments Yet</h2>
                        <p>Create your first teacher assignment using the form above</p>
                    </div>
                <% } else { %>
                    <table class="assignments-table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Teacher Name</th>
                                <th>Class</th>
                                <th>Section</th>
                                <th>Subjects Assigned</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (int i = 0; i < assignments.size(); i++) {
                                Map<String, Object> assignment = assignments.get(i);
                                String[] subjects = ((String)assignment.get("subjects")).split(",");
                            %>
                            <tr>
                                <td><%= i + 1 %></td>
                                <td><strong><%= assignment.get("teacherName") %></strong></td>
                                <td><%= assignment.get("class") %></td>
                                <td><%= assignment.get("section") %></td>
                                <td>
                                    <% for (String subject : subjects) { %>
                                        <span class="subject-badge"><%= subject.trim() %></span>
                                    <% } %>
                                </td>
                                <td>
                                    <div class="action-buttons">
                                        <button class="btn btn-success btn-small" onclick="editAssignment(<%= assignment.get("id") %>)">
                                            ✏️ Edit
                                        </button>
                                        <button class="btn btn-danger btn-small" onclick="deleteAssignment(<%= assignment.get("id") %>, '<%= assignment.get("teacherName") %>', '<%= assignment.get("class") %>', '<%= assignment.get("section") %>')">
                                            🗑️ Delete
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                <% } %>
            </div>
        </div>
    </div>
    
    <!-- Edit Modal -->
    <div id="editModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>✏️ Edit Assignment</h2>
                <span class="close" onclick="closeEditModal()">&times;</span>
            </div>
            <div class="modal-body">
                <form id="editAssignmentForm" onsubmit="updateAssignment(event)">
                    <input type="hidden" id="editAssignmentId" name="assignmentId">
                    
                    <div class="form-group" style="margin-bottom: 20px;">
                        <label>Class <span class="required">*</span></label>
                        <select id="editClass" name="class" required>
                            <option value="">Select Class</option>
                            <option value="I">I (First)</option>
                            <option value="II">II (Second)</option>
                            <option value="III">III (Third)</option>
                            <option value="IV">IV (Fourth)</option>
                            <option value="V">V (Fifth)</option>
                            <option value="VI">VI (Sixth)</option>
                            <option value="VII">VII (Seventh)</option>
                            <option value="VIII">VIII (Eighth)</option>
                            <option value="IX">IX (Ninth)</option>
                            <option value="X">X (Tenth)</option>
                            <option value="XI">XI (Eleventh)</option>
                            <option value="XII">XII (Twelfth)</option>
                        </select>
                    </div>
                    
                    <div class="form-group" style="margin-bottom: 20px;">
                        <label>Section <span class="required">*</span></label>
                        <select id="editSection" name="section" required>
                            <option value="">Select Section</option>
                            <option value="A">A</option>
                            <option value="B">B</option>
                            <option value="C">C</option>
                            <option value="D">D</option>
                            <option value="E">E</option>
                        </select>
                    </div>
                    
                    <div class="form-group" style="margin-bottom: 20px;">
                        <label>Subjects Assigned <span class="required">*</span></label>
                        <div class="checkbox-group" id="editSubjectsContainer">
                            <!-- Subjects will be loaded here -->
                        </div>
                        <span id="editSubjectError" style="color: red; font-size: 12px; display: none;">Please select at least one subject</span>
                    </div>
                    
                    <div style="display: flex; gap: 15px; justify-content: flex-end; margin-top: 20px;">
                        <button type="button" class="btn" onclick="closeEditModal()">Cancel</button>
                        <button type="submit" class="btn btn-success">💾 Update Assignment</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <script>
        console.log('=== ASSIGN TEACHER PAGE LOADED ===');
        console.log('UDISE Code: <%= udiseCode %>');
        console.log('District: <%= district %>');
        console.log('Division: <%= division %>');
        
        // Store assignments data for editing
        const assignmentsData = [
            <% for (int i = 0; i < assignments.size(); i++) {
                Map<String, Object> assignment = assignments.get(i);
                if (i > 0) out.print(",");
            %>
            {
                id: <%= assignment.get("id") %>,
                teacherName: '<%= ((String)assignment.get("teacherName")).replace("'", "\\'") %>',
                class: '<%= assignment.get("class") %>',
                section: '<%= assignment.get("section") %>',
                subjects: '<%= assignment.get("subjects") %>'
            }
            <% } %>
        ];
        
        // Store teachers data
        const teachersData = [
            <% for (int i = 0; i < teachers.size(); i++) {
                Map<String, Object> teacher = teachers.get(i);
                if (i > 0) out.print(",");
            %>
            {
                id: <%= teacher.get("id") %>,
                name: '<%= ((String)teacher.get("name")).replace("'", "\\'") %>',
                subjects: '<%= teacher.get("subjects") %>'
            }
            <% } %>
        ];
        
        function loadSections() {
            // Sections are already available, no need to load
        }
        
        function loadTeacherSubjects() {
            const teacherSelect = document.getElementById('teacherSelect');
            const selectedOption = teacherSelect.options[teacherSelect.selectedIndex];
            
            if (selectedOption.value === '') {
                document.getElementById('subjectCheckboxes').style.display = 'none';
                return;
            }
            
            const subjects = selectedOption.getAttribute('data-subjects').split(',');
            const container = document.getElementById('subjectsContainer');
            container.innerHTML = '';
            
            subjects.forEach(subject => {
                const label = document.createElement('label');
                const checkbox = document.createElement('input');
                checkbox.type = 'checkbox';
                checkbox.name = 'subjects';
                checkbox.value = subject.trim();
                
                label.appendChild(checkbox);
                label.appendChild(document.createTextNode(' ' + subject.trim()));
                container.appendChild(label);
            });
            
            document.getElementById('subjectCheckboxes').style.display = 'block';
        }
        
        function submitAssignment(event) {
            event.preventDefault();
            
            const form = document.getElementById('assignmentForm');
            const formData = new FormData(form);
            
            // Get selected subjects
            const subjectCheckboxes = document.querySelectorAll('#subjectsContainer input[name="subjects"]:checked');
            const subjects = Array.from(subjectCheckboxes).map(cb => cb.value);
            
            if (subjects.length === 0) {
                document.getElementById('subjectError').style.display = 'block';
                return;
            }
            
            document.getElementById('subjectError').style.display = 'none';
            
            // Get teacher name
            const teacherSelect = document.getElementById('teacherSelect');
            const teacherName = teacherSelect.options[teacherSelect.selectedIndex].getAttribute('data-name');
            
            const data = new URLSearchParams();
            data.append('udiseCode', formData.get('udiseCode'));
            data.append('district', formData.get('district'));
            data.append('division', formData.get('division'));
            data.append('class', formData.get('class'));
            data.append('section', formData.get('section'));
            data.append('teacherId', formData.get('teacherId'));
            data.append('teacherName', teacherName);
            data.append('subjects', subjects.join(','));
            
            console.log('Submitting assignment:', Object.fromEntries(data));
            
            fetch('<%= request.getContextPath() %>/save-teacher-assignment', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: data.toString()
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ Teacher assigned successfully!');
                    location.reload();
                } else {
                    alert('Error: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error assigning teacher');
            });
        }
        
        function resetForm() {
            document.getElementById('assignmentForm').reset();
            document.getElementById('subjectCheckboxes').style.display = 'none';
            document.getElementById('subjectError').style.display = 'none';
        }
        
        function editAssignment(assignmentId) {
            const assignment = assignmentsData.find(a => a.id === assignmentId);
            if (!assignment) return;
            
            // Find teacher data
            const teacher = teachersData.find(t => t.name === assignment.teacherName);
            if (!teacher) return;
            
            document.getElementById('editAssignmentId').value = assignment.id;
            document.getElementById('editClass').value = assignment.class;
            document.getElementById('editSection').value = assignment.section;
            
            // Load teacher's subjects
            const subjects = teacher.subjects.split(',');
            const container = document.getElementById('editSubjectsContainer');
            container.innerHTML = '';
            
            const assignedSubjects = assignment.subjects.split(',').map(s => s.trim());
            
            subjects.forEach(subject => {
                const label = document.createElement('label');
                const checkbox = document.createElement('input');
                checkbox.type = 'checkbox';
                checkbox.name = 'editSubjects';
                checkbox.value = subject.trim();
                checkbox.checked = assignedSubjects.includes(subject.trim());
                
                label.appendChild(checkbox);
                label.appendChild(document.createTextNode(' ' + subject.trim()));
                container.appendChild(label);
            });
            
            document.getElementById('editModal').classList.add('show');
        }
        
        function closeEditModal() {
            document.getElementById('editModal').classList.remove('show');
        }
        
        function updateAssignment(event) {
            event.preventDefault();
            
            const assignmentId = document.getElementById('editAssignmentId').value;
            const classValue = document.getElementById('editClass').value;
            const section = document.getElementById('editSection').value;
            
            const subjectCheckboxes = document.querySelectorAll('#editSubjectsContainer input[name="editSubjects"]:checked');
            const subjects = Array.from(subjectCheckboxes).map(cb => cb.value);
            
            if (subjects.length === 0) {
                document.getElementById('editSubjectError').style.display = 'block';
                return;
            }
            
            const data = new URLSearchParams();
            data.append('assignmentId', assignmentId);
            data.append('class', classValue);
            data.append('section', section);
            data.append('subjects', subjects.join(','));
            
            fetch('<%= request.getContextPath() %>/update-teacher-assignment', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: data.toString()
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ Assignment updated successfully!');
                    location.reload();
                } else {
                    alert('Error: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error updating assignment');
            });
        }
        
        function deleteAssignment(assignmentId, teacherName, classVal, section) {
            if (!confirm(`Are you sure you want to delete this assignment?\n\nTeacher: ${teacherName}\nClass: ${classVal}\nSection: ${section}\n\nThis action cannot be undone.`)) {
                return;
            }
            
            const data = new URLSearchParams();
            data.append('assignmentId', assignmentId);
            
            fetch('<%= request.getContextPath() %>/delete-teacher-assignment', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: data.toString()
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ Assignment deleted successfully!');
                    location.reload();
                } else {
                    alert('Error: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error deleting assignment');
            });
        }
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('editModal');
            if (event.target === modal) {
                closeEditModal();
            }
        }
    </script>
</body>
</html>
