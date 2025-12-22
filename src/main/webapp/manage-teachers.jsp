<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.vjnt.util.DatabaseConnection" %>
<%@ page import="java.util.*" %>

<%
    // Check if user is logged in
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    // Only School Coordinators can access this page
    if (!user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR)) {
        response.sendRedirect(request.getContextPath() + "/dashboard.jsp");
        return;
    }
    
    String udiseCode = user.getUdiseNo();
    
    // Get teachers from database
    List<Map<String, Object>> teachers = new ArrayList<>();
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        String sql = "SELECT teacher_id, teacher_name, mobile_number, subjects_taught, description, created_date " +
                     "FROM teachers WHERE udise_code = ? AND is_active = 1 ORDER BY teacher_name";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, udiseCode);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> teacher = new HashMap<>();
            teacher.put("id", rs.getInt("teacher_id"));
            teacher.put("name", rs.getString("teacher_name"));
            teacher.put("mobile", rs.getString("mobile_number"));
            teacher.put("subjects", rs.getString("subjects_taught"));
            teacher.put("description", rs.getString("description"));
            teacher.put("createdDate", rs.getTimestamp("created_date"));
            teachers.add(teacher);
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
    <title>Manage Teachers - VJNT</title>
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
        
        .content {
            padding: 30px;
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 12px;
            text-align: center;
        }
        
        .stat-value {
            font-size: 36px;
            font-weight: 700;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .controls {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .search-box {
            flex: 1;
            min-width: 250px;
        }
        
        .search-box input {
            width: 100%;
            padding: 12px 15px 12px 40px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
        }
        
        .teacher-table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-radius: 10px;
            overflow: hidden;
        }
        
        .teacher-table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .teacher-table th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            font-size: 14px;
        }
        
        .teacher-table td {
            padding: 15px;
            border-bottom: 1px solid #e0e0e0;
            font-size: 14px;
        }
        
        .teacher-table tbody tr:hover {
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
        
        .btn-small {
            padding: 6px 12px;
            font-size: 13px;
            border-radius: 5px;
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
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            font-weight: 600;
            margin-bottom: 8px;
            color: #333;
        }
        
        .form-group input,
        .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
        }
        
        .checkbox-group {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 12px;
            padding: 15px;
            background: #f9f9f9;
            border-radius: 8px;
        }
        
        .checkbox-group label {
            display: flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
        }
        
        .checkbox-group input[type="checkbox"] {
            width: 18px;
            height: 18px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1>👨‍🏫 Manage Teachers</h1>
                <p style="margin-top: 5px; opacity: 0.9;">View, Edit, and Delete Teachers</p>
            </div>
            <a href="<%= request.getContextPath() %>/school-dashboard-enhanced.jsp" class="btn">
                ← Back to Dashboard
            </a>
        </div>
        
        <div class="content">
            <!-- Statistics -->
            <div class="stats">
                <div class="stat-card">
                    <div class="stat-value"><%= teachers.size() %></div>
                    <div class="stat-label">Total Teachers</div>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #4caf50 0%, #45a049 100%);">
                    <div class="stat-value"><%= teachers.stream().filter(t -> ((String)t.get("subjects")).contains("Marathi")).count() %></div>
                    <div class="stat-label">Marathi Teachers</div>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #2196f3 0%, #1976d2 100%);">
                    <div class="stat-value"><%= teachers.stream().filter(t -> ((String)t.get("subjects")).contains("English")).count() %></div>
                    <div class="stat-label">English Teachers</div>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%);">
                    <div class="stat-value"><%= teachers.stream().filter(t -> ((String)t.get("subjects")).contains("Mathematics")).count() %></div>
                    <div class="stat-label">Mathematics Teachers</div>
                </div>
            </div>
            
            <!-- Controls -->
            <div class="controls">
                <div class="search-box">
                    <input type="text" id="searchBox" placeholder="🔍 Search by name, mobile, or subject..." onkeyup="searchTeachers()">
                </div>
                <button class="btn btn-primary" onclick="window.location.href='school-dashboard-enhanced.jsp'">
                    ➕ Add New Teacher
                </button>
            </div>
            
            <!-- Teachers Table -->
            <% if (teachers.isEmpty()) { %>
                <div class="empty-state">
                    <div class="empty-state-icon">👨‍🏫</div>
                    <h2>No Teachers Found</h2>
                    <p>Click "Add New Teacher" to add your first teacher</p>
                </div>
            <% } else { %>
                <table class="teacher-table" id="teacherTable">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Teacher Name</th>
                            <th>Mobile Number</th>
                            <th>Subjects</th>
                            <th>Description</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (int i = 0; i < teachers.size(); i++) {
                            Map<String, Object> teacher = teachers.get(i);
                            String[] subjects = ((String)teacher.get("subjects")).split(",");
                        %>
                        <tr>
                            <td><%= i + 1 %></td>
                            <td><strong><%= teacher.get("name") %></strong></td>
                            <td><%= teacher.get("mobile") %></td>
                            <td>
                                <% for (String subject : subjects) { %>
                                    <span class="subject-badge"><%= subject.trim() %></span>
                                <% } %>
                            </td>
                            <td><%= teacher.get("description") != null ? teacher.get("description") : "-" %></td>
                            <td>
                                <div class="action-buttons">
                                    <button class="btn btn-success btn-small" onclick="editTeacher(<%= teacher.get("id") %>)">
                                        ✏️ Edit
                                    </button>
                                    <button class="btn btn-danger btn-small" onclick="deleteTeacher(<%= teacher.get("id") %>, '<%= teacher.get("name") %>')">
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
    
    <!-- Edit Teacher Modal -->
    <div id="editModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>✏️ Edit Teacher</h2>
                <span class="close" onclick="closeEditModal()">&times;</span>
            </div>
            <div class="modal-body">
                <form id="editTeacherForm" onsubmit="updateTeacher(event)">
                    <input type="hidden" id="editTeacherId" name="teacherId">
                    
                    <div class="form-group">
                        <label>Teacher Name <span style="color: red;">*</span></label>
                        <input type="text" id="editTeacherName" name="teacherName" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Mobile Number <span style="color: red;">*</span></label>
                        <input type="tel" id="editTeacherMobile" name="teacherMobile" pattern="[0-9]{10}" maxlength="10" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Subjects Taught / विषय <span style="color: red;">*</span></label>
                        <div class="checkbox-group" style="max-height: 400px; overflow-y: auto; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));">
                            <label><input type="checkbox" name="subjects" value="मराठी" class="edit-subject-checkbox"> मराठी</label>
                            <label><input type="checkbox" name="subjects" value="इंग्रजी" class="edit-subject-checkbox"> इंग्रजी</label>
                            <label><input type="checkbox" name="subjects" value="हिंदी" class="edit-subject-checkbox"> हिंदी</label>
                            <label><input type="checkbox" name="subjects" value="गणित" class="edit-subject-checkbox"> गणित</label>
                            <label><input type="checkbox" name="subjects" value="परिसर अभ्यास /विज्ञान (भाग १ व २)" class="edit-subject-checkbox"> परिसर अभ्यास /विज्ञान (भाग १ व २)</label>
                            <label><input type="checkbox" name="subjects" value="इतिहास /नागरिकशास्त्र" class="edit-subject-checkbox"> इतिहास /नागरिकशास्त्र</label>
                            <label><input type="checkbox" name="subjects" value="भूगोल" class="edit-subject-checkbox"> भूगोल</label>
                            <label><input type="checkbox" name="subjects" value="जलसुरक्षा" class="edit-subject-checkbox"> जलसुरक्षा</label>
                            <label><input type="checkbox" name="subjects" value="संरक्षण शास्त्र" class="edit-subject-checkbox"> संरक्षण शास्त्र</label>
                            <label><input type="checkbox" name="subjects" value="शारीरिक शिक्षण" class="edit-subject-checkbox"> शारीरिक शिक्षण</label>
                            <label><input type="checkbox" name="subjects" value="कला शिक्षण" class="edit-subject-checkbox"> कला शिक्षण</label>
                            <label><input type="checkbox" name="subjects" value="कार्यअनुभव" class="edit-subject-checkbox"> कार्यअनुभव</label>
                            <label><input type="checkbox" name="subjects" value="भौतिकशास्त्र (Physics)" class="edit-subject-checkbox"> भौतिकशास्त्र (Physics)</label>
                            <label><input type="checkbox" name="subjects" value="रसायनशास्त्र (Chemistry)" class="edit-subject-checkbox"> रसायनशास्त्र (Chemistry)</label>
                            <label><input type="checkbox" name="subjects" value="जीवशास्त्र (Biology)" class="edit-subject-checkbox"> जीवशास्त्र (Biology)</label>
                            <label><input type="checkbox" name="subjects" value="राज्यशास्त्र" class="edit-subject-checkbox"> राज्यशास्त्र</label>
                            <label><input type="checkbox" name="subjects" value="अर्थशास्त्र" class="edit-subject-checkbox"> अर्थशास्त्र</label>
                            <label><input type="checkbox" name="subjects" value="समाजशास्त्र" class="edit-subject-checkbox"> समाजशास्त्र</label>
                            <label><input type="checkbox" name="subjects" value="इतर (Other)" class="edit-subject-checkbox" id="editOtherSubjectCheckbox" onchange="toggleEditOtherSubjectInput()"> इतर (Other)</label>
                        </div>
                        
                        <!-- Other Subject Input Field (Hidden by default) -->
                        <div id="editOtherSubjectInputContainer" style="display: none; margin-top: 15px; padding: 15px; background: #fff3cd; border: 2px solid #ffc107; border-radius: 8px;">
                            <label style="display: block; font-weight: 600; margin-bottom: 8px; color: #856404;">
                                📝 Enter Other Subject Name / इतर विषयाचे नाव लिहा <span style="color: red;">*</span>
                            </label>
                            <input type="text" id="editOtherSubjectName" name="editOtherSubjectName"
                                   style="width: 100%; padding: 12px; border: 2px solid #ffc107; border-radius: 8px; font-size: 14px; background: white;"
                                   placeholder="Enter custom subject name / विषयाचे नाव लिहा">
                            <small style="display: block; margin-top: 5px; color: #856404; font-size: 12px;">
                                💡 This field is required when "Other Subject" is selected
                            </small>
                        </div>
                        
                        <span id="editSubjectError" style="color: red; font-size: 12px; display: none; margin-top: 5px;">कृपया किमान एक विषय निवडा / Please select at least one subject</span>
                    </div>
                    
                    <div class="form-group">
                        <label>Description</label>
                        <textarea id="editTeacherDescription" name="teacherDescription" rows="4"></textarea>
                    </div>
                    
                    <div style="display: flex; gap: 15px; justify-content: flex-end; margin-top: 20px;">
                        <button type="button" class="btn" onclick="closeEditModal()">Cancel</button>
                        <button type="submit" class="btn btn-success">💾 Update Teacher</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <script>
        // Store teacher data for editing
        const teachersData = [
            <% for (int i = 0; i < teachers.size(); i++) {
                Map<String, Object> teacher = teachers.get(i);
                if (i > 0) out.print(",");
                
                // Properly escape strings for JavaScript
                String name = ((String)teacher.get("name")).replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("\r", "\\r");
                String mobile = String.valueOf(teacher.get("mobile"));
                String subjects = ((String)teacher.get("subjects")).replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("\r", "\\r");
                String description = teacher.get("description") != null ? 
                    ((String)teacher.get("description")).replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("\r", "\\r") : "";
            %>
            {
                id: <%= teacher.get("id") %>,
                name: '<%= name %>',
                mobile: '<%= mobile %>',
                subjects: '<%= subjects %>',
                description: '<%= description %>'
            }
            <% } %>
        ];
        
        // Search functionality
        function searchTeachers() {
            const searchTerm = document.getElementById('searchBox').value.toLowerCase();
            const table = document.getElementById('teacherTable');
            const rows = table.getElementsByTagName('tbody')[0].getElementsByTagName('tr');
            
            for (let i = 0; i < rows.length; i++) {
                const row = rows[i];
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(searchTerm) ? '' : 'none';
            }
        }
        
        // Edit teacher
        function editTeacher(teacherId) {
            const teacher = teachersData.find(t => t.id === teacherId);
            if (!teacher) return;
            
            document.getElementById('editTeacherId').value = teacher.id;
            document.getElementById('editTeacherName').value = teacher.name;
            document.getElementById('editTeacherMobile').value = teacher.mobile;
            document.getElementById('editTeacherDescription').value = teacher.description;
            
            // Reset all checkboxes first
            const checkboxes = document.querySelectorAll('#editTeacherForm input[name="subjects"]');
            checkboxes.forEach(cb => cb.checked = false);
            
            // Hide other subject input initially
            document.getElementById('editOtherSubjectInputContainer').style.display = 'none';
            document.getElementById('editOtherSubjectName').value = '';
            
            // Check subject checkboxes
            const subjects = teacher.subjects.split(',').map(s => s.trim());
            
            // Define all predefined subjects
            const predefinedSubjects = [
                'मराठी', 'इंग्रजी', 'हिंदी', 'गणित',
                'परिसर अभ्यास /विज्ञान (भाग १ व २)', 'इतिहास /नागरिकशास्त्र', 'भूगोल',
                'जलसुरक्षा', 'संरक्षण शास्त्र', 'शारीरिक शिक्षण', 'कला शिक्षण', 'कार्यअनुभव',
                'भौतिकशास्त्र (Physics)', 'रसायनशास्त्र (Chemistry)', 'जीवशास्त्र (Biology)',
                'राज्यशास्त्र', 'अर्थशास्त्र', 'समाजशास्त्र'
            ];
            
            let hasOtherSubject = false;
            let otherSubjectValues = [];
            
            subjects.forEach(subject => {
                if (predefinedSubjects.includes(subject)) {
                    // Check the matching predefined subject
                    checkboxes.forEach(cb => {
                        if (cb.value === subject) {
                            cb.checked = true;
                        }
                    });
                } else if (subject) {
                    // This is a custom subject - collect all custom subjects
                    hasOtherSubject = true;
                    otherSubjectValues.push(subject);
                }
            });
            
            // If there's a custom subject, show the "Other Subject" checkbox and input
            if (hasOtherSubject) {
                document.getElementById('editOtherSubjectCheckbox').checked = true;
                document.getElementById('editOtherSubjectInputContainer').style.display = 'block';
                // Join all custom subjects with comma
                document.getElementById('editOtherSubjectName').value = otherSubjectValues.join(', ');
            }
            
            document.getElementById('editModal').classList.add('show');
        }
        
        // Close edit modal
        function closeEditModal() {
            document.getElementById('editModal').classList.remove('show');
            document.getElementById('editTeacherForm').reset();
            document.getElementById('editOtherSubjectInputContainer').style.display = 'none';
            document.getElementById('editOtherSubjectName').value = '';
        }
        
        // Toggle Other Subject Input Field in Edit Modal
        function toggleEditOtherSubjectInput() {
            const checkbox = document.getElementById('editOtherSubjectCheckbox');
            const container = document.getElementById('editOtherSubjectInputContainer');
            const input = document.getElementById('editOtherSubjectName');
            
            if (checkbox.checked) {
                container.style.display = 'block';
                input.focus();
            } else {
                container.style.display = 'none';
                input.value = '';
            }
        }
        
        // Update teacher
        function updateTeacher(event) {
            event.preventDefault();
            
            const teacherId = document.getElementById('editTeacherId').value;
            const name = document.getElementById('editTeacherName').value.trim();
            const mobile = document.getElementById('editTeacherMobile').value.trim();
            const description = document.getElementById('editTeacherDescription').value.trim();
            
            const subjectCheckboxes = document.querySelectorAll('#editTeacherForm input[name="subjects"]:checked');
            let subjects = Array.from(subjectCheckboxes).map(cb => cb.value);
            
            if (subjects.length === 0) {
                document.getElementById('editSubjectError').style.display = 'block';
                alert('कृपया किमान एक विषय निवडा / Please select at least one subject');
                return;
            } else {
                document.getElementById('editSubjectError').style.display = 'none';
            }
            
            // Check if "Other Subject" is selected
            const otherSubjectCheckbox = document.getElementById('editOtherSubjectCheckbox');
            const otherSubjectName = document.getElementById('editOtherSubjectName').value.trim();
            
            if (otherSubjectCheckbox.checked) {
                if (!otherSubjectName) {
                    alert('कृपया इतर विषयाचे नाव लिहा / Please enter the other subject name');
                    document.getElementById('editOtherSubjectName').focus();
                    return;
                }
                // Replace "Other Subject" with the custom name
                subjects = subjects.map(subject => 
                    subject === 'इतर (Other)' ? otherSubjectName : subject
                );
            }
            
            const formData = new URLSearchParams();
            formData.append('teacherId', teacherId);
            formData.append('teacherName', name);
            formData.append('teacherMobile', mobile);
            formData.append('subjects', subjects.join(','));
            formData.append('description', description);
            
            fetch('<%= request.getContextPath() %>/update-teacher', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: formData.toString()
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ Teacher updated successfully!');
                    location.reload();
                } else {
                    alert('Error: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error updating teacher');
            });
        }
        
        // Delete teacher
        function deleteTeacher(teacherId, teacherName) {
            if (!confirm('Are you sure you want to delete teacher "' + teacherName + '"?\n\nThis action cannot be undone.')) {
                return;
            }
            
            const formData = new URLSearchParams();
            formData.append('teacherId', teacherId);
            
            fetch('<%= request.getContextPath() %>/delete-teacher', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: formData.toString()
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✓ Teacher deleted successfully!');
                    location.reload();
                } else {
                    alert('Error: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error deleting teacher');
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
