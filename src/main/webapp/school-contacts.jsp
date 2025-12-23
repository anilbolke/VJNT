<%@page import="com.vjnt.model.SchoolContact"%>
<%@page import="com.vjnt.dao.SchoolContactDAO"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.dao.SchoolDAO" %>
<%@ page import="com.vjnt.model.School" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getUserType().equals(User.UserType.DISTRICT_COORDINATOR) && 
                         !user.getUserType().equals(User.UserType.DISTRICT_2ND_COORDINATOR))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String districtName = user.getDistrictName();
    SchoolDAO schoolDAO = new SchoolDAO();
    SchoolContactDAO contactDAO = new SchoolContactDAO();
    
    // Get schools for this district only
    List<School> schools = schoolDAO.getSchoolsByDistrict(districtName);
    System.out.println("DEBUG: District = " + districtName + ", Schools found = " + (schools != null ? schools.size() : "null"));
    
    // Get existing school contacts for this district
    List<SchoolContact> schoolContacts = contactDAO.getContactsByDistrict(districtName);
    System.out.println("DEBUG: Contacts found = " + (schoolContacts != null ? schoolContacts.size() : "null"));
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>School Contacts Directory - VJNT</title>
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
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .header h1 {
            font-size: 26px;
            margin: 0;
        }
        
        .header-subtitle {
            font-size: 14px;
            opacity: 0.9;
            margin-top: 5px;
        }
        
        .btn {
            padding: 10px 20px;
            border-radius: 6px;
            text-decoration: none;
            font-weight: 500;
            transition: all 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            border: none;
            font-size: 14px;
        }
        
        .btn-back {
            background: rgba(255,255,255,0.2);
            color: white;
            border: 1px solid rgba(255,255,255,0.3);
        }
        
        .btn-back:hover {
            background: rgba(255,255,255,0.3);
        }
        
        .btn-primary {
            background: #4caf50;
            color: white;
        }
        
        .btn-primary:hover {
            background: #45a049;
            transform: translateY(-2px);
        }
        
        .btn-edit {
            background: #2196f3;
            color: white;
            padding: 6px 12px;
            font-size: 12px;
        }
        
        .btn-edit:hover {
            background: #1976d2;
        }
        
        .btn-delete {
            background: #f44336;
            color: white;
            padding: 6px 12px;
            font-size: 12px;
        }
        
        .btn-delete:hover {
            background: #d32f2f;
        }
        
        .content {
            padding: 30px;
        }
        
        .section {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 25px;
        }
        
        .section-title {
            font-size: 20px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 3px solid #667eea;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .form-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
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
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            font-size: 14px;
            transition: border-color 0.3s;
            font-family: inherit;
        }
        
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .form-group textarea {
            resize: vertical;
            min-height: 80px;
        }
        
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: none;
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
        
        .table-container {
            overflow-x: auto;
            margin-top: 20px;
        }
        
        .table {
            width: 100%;
            border-collapse: collapse;
            background: white;
        }
        
        .table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .table th,
        .table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e0e0e0;
            font-size: 13px;
        }
        
        .table th {
            font-weight: 600;
        }
        
        .table tbody tr:hover {
            background: #f5f5f5;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
        }
        
        .badge-coordinator {
            background: #e3f2fd;
            color: #1976d2;
        }
        
        .badge-headmaster {
            background: #f3e5f5;
            color: #7b1fa2;
        }
        
        .action-buttons {
            display: flex;
            gap: 8px;
        }
        
        .school-dropdown {
            position: absolute;
            top: 100%;
            left: 0;
            right: 0;
            margin-top: 4px;
            background: white;
            border: 2px solid #667eea;
            border-radius: 6px;
            max-height: 300px;
            overflow-y: auto;
            width: 100%;
            z-index: 1000;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            display: none;
        }
        
        .school-dropdown.show {
            display: block;
        }
        
        .school-option {
            padding: 12px 15px;
            cursor: pointer;
            border-bottom: 1px solid #f0f0f0;
            transition: background 0.2s;
        }
        
        .school-option:hover {
            background: #f5f5ff;
        }
        
        .school-option:last-child {
            border-bottom: none;
        }
        
        .school-option-udise {
            font-weight: 600;
            color: #667eea;
            font-size: 13px;
        }
        
        .school-option-name {
            color: #333;
            font-size: 12px;
            margin-top: 3px;
        }
        
        .selected-school {
            margin-top: 8px;
            padding: 10px;
            background: #e8f5e9;
            border-radius: 6px;
            border-left: 4px solid #4caf50;
            display: none;
        }
        
        .selected-school.show {
            display: block;
        }
        
        .selected-school-info {
            font-size: 13px;
            color: #2e7d32;
        }
        
        .selected-school-udise {
            font-weight: 600;
            margin-bottom: 3px;
        }
        
        .selected-school-clear {
            background: #f44336;
            color: white;
            border: none;
            padding: 4px 10px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 11px;
            margin-top: 8px;
        }
        
        .selected-school-clear:hover {
            background: #d32f2f;
        }
        
        .no-results {
            padding: 15px;
            text-align: center;
            color: #999;
            font-size: 13px;
        }
        
        @media (max-width: 768px) {
            .form-grid {
                grid-template-columns: 1fr;
            }
            
            .header {
                flex-direction: column;
                align-items: stretch;
            }
            
            .action-buttons {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div>
                <h1>👥 School Contacts Directory</h1>
                <div class="header-subtitle">Manage contact information for School Coordinators and Head Masters - <%= districtName %></div>
            </div>
            <a href="<%= request.getContextPath() %>/district-dashboard.jsp" class="btn btn-back">
                <span>🏠</span>
                <span>Back to Dashboard</span>
            </a>
        </div>
        
        <!-- Content -->
        <div class="content">
            <!-- Alert Messages -->
            <div id="alertSuccess" class="alert alert-success"></div>
            <div id="alertError" class="alert alert-error"></div>
            
            <!-- Add/Edit Form -->
            <div class="section">
                <h2 class="section-title">
                    <span>➕</span>
                    <span id="formTitle">Add New Contact</span>
                </h2>
                
                <% if (schools == null || schools.isEmpty()) { %>
                <div style="background: #fff3cd; color: #856404; padding: 15px; border-radius: 8px; margin-bottom: 20px; border: 1px solid #ffc107;">
                    <strong>⚠️ No Schools Found</strong>
                    <p style="margin: 8px 0 0 0;">No schools are registered for district "<%= districtName %>". 
                    Please contact the system administrator to upload school data for your district before adding contacts.</p>
                </div>
                <% } %>
                
                <form id="contactForm">
                    <input type="hidden" id="contactId" name="contactId">
                    <input type="hidden" id="formMode" value="add">
                    
                    <div class="form-grid">
                        <!-- School Selection with Search -->
                        <div class="form-group" style="position: relative;">
                            <label for="schoolSearch">
                                School (UDISE) <span class="required">*</span>
                            </label>
                            <div style="position: relative;">
                                <input type="text" 
                                       id="schoolSearch" 
                                       placeholder="🔍 Type to search school by UDISE or name..." 
                                       autocomplete="off">
                                <input type="hidden" id="udiseNo" name="udiseNo" required>
                                <div id="schoolDropdown" class="school-dropdown"></div>
                            </div>
                            <div id="selectedSchool" class="selected-school"></div>
                        </div>
                        
                        <!-- Contact Type Selection -->
                        <div class="form-group">
                            <label for="contactType">
                                Contact Type <span class="required">*</span>
                            </label>
                            <select id="contactType" name="contactType" required>
                                <option value="">-- Select Type --</option>
                                <option value="School Coordinator">School Coordinator</option>
                                <option value="Head Master">Head Master</option>
                            </select>
                        </div>
                        
                        <!-- Full Name -->
                        <div class="form-group">
                            <label for="fullName">
                                Full Name <span class="required">*</span>
                            </label>
                            <input type="text" id="fullName" name="fullName" placeholder="Enter full name" required>
                        </div>
                        
                        <!-- Mobile Number -->
                        <div class="form-group">
                            <label for="mobile">
                                Mobile Number <span class="required">*</span>
                            </label>
                            <input type="tel" id="mobile" name="mobile" placeholder="Enter 10-digit mobile number" pattern="[0-9]{10}" required>
                        </div>
                        
                        <!-- WhatsApp Number -->
                        <div class="form-group">
                            <label for="whatsapp">
                                WhatsApp Number
                            </label>
                            <input type="tel" id="whatsapp" name="whatsapp" placeholder="Enter 10-digit WhatsApp number" pattern="[0-9]{10}">
                        </div>
                    </div>
                    
                    <!-- Remarks -->
                    <div class="form-group">
                        <label for="remarks">
                            Remarks
                        </label>
                        <textarea id="remarks" name="remarks" placeholder="Enter any additional remarks or notes..."></textarea>
                    </div>
                    
                    <!-- Form Actions -->
                    <div style="display: flex; gap: 15px; margin-top: 25px;">
                        <button type="submit" class="btn btn-primary">
                            <span>💾</span>
                            <span id="submitBtnText">Save Contact</span>
                        </button>
                        <button type="button" class="btn btn-back" onclick="resetForm()" style="background: #9e9e9e;">
                            <span>🔄</span>
                            <span>Reset Form</span>
                        </button>
                    </div>
                </form>
            </div>
            
            <!-- Existing Contacts List -->
            <div class="section">
                <h2 class="section-title">
                    <span>📋</span>
                    <span>School Contacts (<span id="totalContactsCount"><%= schoolContacts.size() %></span>)</span>
                </h2>
                
                <!-- Filter Section -->
                <div style="background: #f0f4ff; padding: 20px; border-radius: 10px; margin-bottom: 20px; border-left: 4px solid #667eea;">
                    <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 15px;">
                        <span style="font-size: 18px;">🔍</span>
                        <h3 style="margin: 0; font-size: 16px; color: #333;">Filter Contacts</h3>
                    </div>
                    
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px; margin-bottom: 15px;">
                        <!-- School Filter -->
                        <div class="form-group" style="margin: 0;">
                            <label for="filterSchool" style="margin-bottom: 8px;">School (UDISE)</label>
                            <select id="filterSchool" style="padding: 10px; border: 2px solid #e0e0e0; border-radius: 6px; font-size: 14px; width: 100%;">
                                <option value="">All Schools</option>
                                <% 
                                // Get unique schools from contacts
                                Set<String> uniqueSchools = new LinkedHashSet<>();
                                for (SchoolContact contact : schoolContacts) {
                                    uniqueSchools.add(contact.getUdiseNo() + "|" + (contact.getSchoolName() != null ? contact.getSchoolName() : ""));
                                }
                                for (String school : uniqueSchools) {
                                    String[] parts = school.split("\\|");
                                    String udise = parts[0];
                                    String name = parts.length > 1 ? parts[1] : "";
                                %>
                                <option value="<%= udise %>"><%= udise %> - <%= name %></option>
                                <% } %>
                            </select>
                        </div>
                        
                        <!-- Contact Type Filter -->
                        <div class="form-group" style="margin: 0;">
                            <label for="filterType" style="margin-bottom: 8px;">Contact Type</label>
                            <select id="filterType" style="padding: 10px; border: 2px solid #e0e0e0; border-radius: 6px; font-size: 14px; width: 100%;">
                                <option value="">All Types</option>
                                <option value="School Coordinator">School Coordinator</option>
                                <option value="Head Master">Head Master</option>
                            </select>
                        </div>
                        
                        <!-- Search Filter -->
                        <div class="form-group" style="margin: 0;">
                            <label for="filterSearch" style="margin-bottom: 8px;">Search (Name/Mobile)</label>
                            <input type="text" 
                                   id="filterSearch" 
                                   placeholder="Type to search..." 
                                   style="padding: 10px; border: 2px solid #e0e0e0; border-radius: 6px; font-size: 14px; width: 100%;">
                        </div>
                    </div>
                    
                    <div style="display: flex; gap: 10px; align-items: center;">
                        <button onclick="applyFilters()" class="btn btn-primary" style="padding: 10px 20px;">
                            <span>🔍</span>
                            <span>Apply Filters</span>
                        </button>
                        <button onclick="resetFilters()" class="btn" style="background: #6c757d; color: white; padding: 10px 20px;">
                            <span>🔄</span>
                            <span>Reset</span>
                        </button>
                        <div id="filterResultText" style="margin-left: 10px; color: #667eea; font-weight: 600; font-size: 14px;"></div>
                    </div>
                </div>
                
                <div class="table-container">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Sr No</th>
                                <th>School (UDISE)</th>
                                <th>School Name</th>
                                <th>Contact Type</th>
                                <th>Full Name</th>
                                <th>Mobile</th>
                                <th>WhatsApp</th>
                                <th>Remarks</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="contactTableBody">
                            <% 
                            int srNo = 1;
                            for (SchoolContact contact : schoolContacts) { 
                            %>
                            <tr>
                                <td><%= srNo++ %></td>
                                <td><strong><%= contact.getUdiseNo() %></strong></td>
                                <td><%= contact.getSchoolName() != null ? contact.getSchoolName() : "-" %></td>
                                <td>
                                    <span class="badge <%= contact.getContactType().equals("School Coordinator") ? "badge-coordinator" : "badge-headmaster" %>">
                                        <%= contact.getContactType() %>
                                    </span>
                                </td>
                                <td><strong><%= contact.getFullName() %></strong></td>
                                <td><a href="tel:<%= contact.getMobile() %>"><%= contact.getMobile() %></a></td>
                                <td>
                                    <% if (contact.getWhatsappNumber() != null && !contact.getWhatsappNumber().isEmpty()) { %>
                                        <a href="https://wa.me/91<%= contact.getWhatsappNumber() %>" target="_blank" style="color: #25D366;">
                                            <%= contact.getWhatsappNumber() %>
                                        </a>
                                    <% } else { %>
                                        -
                                    <% } %>
                                </td>
                                <td><%= contact.getRemarks() != null ? contact.getRemarks() : "-" %></td>
                                <td>
                                    <div class="action-buttons">
                                        <button class="btn btn-edit" onclick="editContact(<%= contact.getContactId() %>)">
                                            ✏️ Edit
                                        </button>
                                        <button class="btn btn-delete" onclick="deleteContact(<%= contact.getContactId() %>, '<%= contact.getFullName() %>')">
                                            🗑️ Delete
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                            <% if (schoolContacts.isEmpty()) { %>
                            <tr>
                                <td colspan="9" style="text-align: center; padding: 30px; color: #999;">
                                    No contacts found. Add your first contact above.
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Schools data for search
        const schoolsData = [
            <% for (int i = 0; i < schools.size(); i++) { 
                School s = schools.get(i);
            %>
            {
                udise: "<%= s.getUdiseNo() %>",
                name: "<%= s.getSchoolName() != null ? s.getSchoolName().replace("\"", "\\\"") : "" %>"
            }<%= i < schools.size() - 1 ? "," : "" %>
            <% } %>
        ];
        
        let selectedSchoolUdise = null;
        
        // School search functionality
        const schoolSearch = document.getElementById('schoolSearch');
        const schoolDropdown = document.getElementById('schoolDropdown');
        const udiseNoInput = document.getElementById('udiseNo');
        const selectedSchoolDiv = document.getElementById('selectedSchool');
        
        schoolSearch.addEventListener('input', function() {
            const searchTerm = this.value.toLowerCase().trim();
            
            if (searchTerm.length === 0) {
                schoolDropdown.classList.remove('show');
                return;
            }
            
            // Filter schools
            const filtered = schoolsData.filter(school => 
                school.udise.toLowerCase().includes(searchTerm) || 
                school.name.toLowerCase().includes(searchTerm)
            );
            
            // Display results
            if (filtered.length > 0) {
                let html = '';
                filtered.slice(0, 10).forEach(school => {
                    html += '<div class="school-option" onclick="selectSchool(\'' + school.udise + '\', \'' + school.name.replace(/'/g, "\\'") + '\')">';
                    html += '<div class="school-option-udise">🏫 ' + school.udise + '</div>';
                    html += '<div class="school-option-name">' + school.name + '</div>';
                    html += '</div>';
                });
                schoolDropdown.innerHTML = html;
                schoolDropdown.classList.add('show');
            } else {
                schoolDropdown.innerHTML = '<div class="no-results">No schools found</div>';
                schoolDropdown.classList.add('show');
            }
        });
        
        // Select school function
        function selectSchool(udise, name) {
            selectedSchoolUdise = udise;
            udiseNoInput.value = udise;
            schoolSearch.value = '';
            schoolDropdown.classList.remove('show');
            
            // Show selected school
            selectedSchoolDiv.innerHTML = 
                '<div class="selected-school-info">' +
                '<div class="selected-school-udise">✅ Selected School: ' + udise + '</div>' +
                '<div>' + name + '</div>' +
                '</div>' +
                '<button type="button" class="selected-school-clear" onclick="clearSchoolSelection()">✕ Clear Selection</button>';
            selectedSchoolDiv.classList.add('show');
        }
        
        // Clear school selection
        function clearSchoolSelection() {
            selectedSchoolUdise = null;
            udiseNoInput.value = '';
            schoolSearch.value = '';
            selectedSchoolDiv.classList.remove('show');
            schoolSearch.focus();
        }
        
        // Close dropdown when clicking outside
        document.addEventListener('click', function(e) {
            if (!schoolSearch.contains(e.target) && !schoolDropdown.contains(e.target)) {
                schoolDropdown.classList.remove('show');
            }
        });
        
        // Form submission
        document.getElementById('contactForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new FormData(this);
            const mode = document.getElementById('formMode').value;
            const districtName = '<%= districtName %>';
            
            formData.append('districtName', districtName);
            formData.append('mode', mode);
            
            // Debug: Log form data
            console.log('=== Form Submission Debug ===');
            console.log('Mode:', mode);
            console.log('District:', districtName);
            for (let pair of formData.entries()) {
                console.log(pair[0] + ': [' + pair[1] + ']');
            }
            console.log('============================');
            
            fetch('<%= request.getContextPath() %>/manage-school-contact', {
                method: 'POST',
                body: formData
            })
            .then(response => {
                console.log('Response status:', response.status);
                return response.json();
            })
            .then(data => {
                console.log('Response data:', data);
                if (data.success) {
                    showAlert('success', data.message || 'Contact saved successfully!');
                    resetForm();
                    setTimeout(() => location.reload(), 2000);
                } else {
                    showAlert('error', data.message || 'Failed to save contact');
                }
            })
            .catch(error => {
                console.error('Fetch error:', error);
                showAlert('error', 'Error submitting form: ' + error.message);
            });
        });
        
        // Edit contact
        function editContact(contactId) {
            fetch('<%= request.getContextPath() %>/get-school-contact?contactId=' + contactId)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const contact = data.contact;
                        
                        document.getElementById('contactId').value = contact.contactId;
                        document.getElementById('formMode').value = 'edit';
                        document.getElementById('udiseNo').value = contact.udiseNo;
                        document.getElementById('contactType').value = contact.contactType;
                        document.getElementById('fullName').value = contact.fullName || '';
                        document.getElementById('mobile').value = contact.mobile || '';
                        document.getElementById('whatsapp').value = contact.whatsappNumber || '';
                        document.getElementById('remarks').value = contact.remarks || '';
                        
                        document.getElementById('formTitle').textContent = 'Edit Contact';
                        document.getElementById('submitBtnText').textContent = 'Update Contact';
                        
                        // Scroll to form
                        document.getElementById('contactForm').scrollIntoView({ behavior: 'smooth' });
                    }
                })
                .catch(error => {
                    showAlert('error', 'Error loading contact data: ' + error.message);
                });
        }
        
        // Delete contact
        function deleteContact(contactId, fullName) {
            if (!confirm('Are you sure you want to delete contact "' + fullName + '"?')) {
                return;
            }
            
            fetch('<%= request.getContextPath() %>/manage-school-contact?action=delete&contactId=' + contactId, {
                method: 'POST'
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showAlert('success', data.message);
                    setTimeout(() => location.reload(), 1500);
                } else {
                    showAlert('error', data.message);
                }
            })
            .catch(error => {
                showAlert('error', 'Error: ' + error.message);
            });
        }
        
        // Reset form
        function resetForm() {
            document.getElementById('contactForm').reset();
            document.getElementById('contactId').value = '';
            document.getElementById('formMode').value = 'add';
            document.getElementById('formTitle').textContent = 'Add New Contact';
            document.getElementById('submitBtnText').textContent = 'Save Contact';
            clearSchoolSelection();
            hideAlerts();
        }
        
        // Show alert
        function showAlert(type, message) {
            hideAlerts();
            const alertId = type === 'success' ? 'alertSuccess' : 'alertError';
            const alertEl = document.getElementById(alertId);
            alertEl.textContent = message;
            alertEl.style.display = 'block';
            
            // Auto hide after 5 seconds
            setTimeout(() => {
                alertEl.style.display = 'none';
            }, 5000);
        }
        
        // Hide all alerts
        function hideAlerts() {
            document.getElementById('alertSuccess').style.display = 'none';
            document.getElementById('alertError').style.display = 'none';
        }
        
        // Auto-fill WhatsApp with mobile number if empty
        document.getElementById('mobile').addEventListener('blur', function() {
            const whatsapp = document.getElementById('whatsapp');
            if (!whatsapp.value && this.value) {
                whatsapp.value = this.value;
            }
        });
        
        // ==================== FILTER FUNCTIONALITY ====================
        
        // Apply filters to contacts table
        function applyFilters() {
            const filterSchool = document.getElementById('filterSchool').value.toLowerCase();
            const filterType = document.getElementById('filterType').value.toLowerCase();
            const filterSearch = document.getElementById('filterSearch').value.toLowerCase();
            
            const tableBody = document.getElementById('contactTableBody');
            const rows = tableBody.getElementsByTagName('tr');
            
            let visibleCount = 0;
            let srNo = 1;
            
            for (let i = 0; i < rows.length; i++) {
                const row = rows[i];
                
                // Skip empty state row
                if (row.cells.length === 1 && row.cells[0].colSpan > 1) {
                    continue;
                }
                
                const udise = row.cells[1].textContent.toLowerCase();
                const schoolName = row.cells[2].textContent.toLowerCase();
                const contactType = row.cells[3].textContent.toLowerCase();
                const fullName = row.cells[4].textContent.toLowerCase();
                const mobile = row.cells[5].textContent.toLowerCase();
                
                // Apply filters
                let showRow = true;
                
                // School filter
                if (filterSchool && !udise.includes(filterSchool)) {
                    showRow = false;
                }
                
                // Contact type filter
                if (filterType && !contactType.includes(filterType)) {
                    showRow = false;
                }
                
                // Search filter (name or mobile)
                if (filterSearch && !fullName.includes(filterSearch) && !mobile.includes(filterSearch)) {
                    showRow = false;
                }
                
                // Show/hide row
                if (showRow) {
                    row.style.display = '';
                    row.cells[0].textContent = srNo++;
                    visibleCount++;
                } else {
                    row.style.display = 'none';
                }
            }
            
            // Update counts
            document.getElementById('totalContactsCount').textContent = visibleCount;
            
            // Show filter result message
            const resultText = document.getElementById('filterResultText');
            if (filterSchool || filterType || filterSearch) {
                resultText.textContent = `Showing ${visibleCount} of <%= schoolContacts.size() %> contacts`;
            } else {
                resultText.textContent = '';
            }
        }
        
        // Reset all filters
        function resetFilters() {
            document.getElementById('filterSchool').value = '';
            document.getElementById('filterType').value = '';
            document.getElementById('filterSearch').value = '';
            
            const tableBody = document.getElementById('contactTableBody');
            const rows = tableBody.getElementsByTagName('tr');
            
            let srNo = 1;
            for (let i = 0; i < rows.length; i++) {
                const row = rows[i];
                if (row.cells.length > 1) {
                    row.style.display = '';
                    row.cells[0].textContent = srNo++;
                }
            }
            
            document.getElementById('totalContactsCount').textContent = '<%= schoolContacts.size() %>';
            document.getElementById('filterResultText').textContent = '';
        }
        
        // Apply filters on Enter key in search box
        document.getElementById('filterSearch').addEventListener('keyup', function(e) {
            if (e.key === 'Enter') {
                applyFilters();
            }
        });
        
        // Real-time search as user types (optional - uncomment if needed)
        // document.getElementById('filterSearch').addEventListener('input', applyFilters);
        
    </script>
</body>
</html>
