<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>School Information - VJNT Class Management</title>
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
            text-align: center;
            color: white;
            margin-bottom: 30px;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        
        .header p {
            font-size: 1.1em;
            opacity: 0.9;
        }
        
        .search-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 30px;
        }
        
        .search-form {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .search-form input {
            flex: 1;
            min-width: 250px;
            padding: 12px 16px;
            border: 2px solid #e0e0e0;
            border-radius: 5px;
            font-size: 1em;
            transition: border-color 0.3s;
        }
        
        .search-form input:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .search-form button {
            padding: 12px 30px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 1em;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.3s;
        }
        
        .search-form button:hover {
            background: #764ba2;
        }
        
        .results-container {
            display: none;
            animation: slideIn 0.3s ease-in;
        }
        
        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .error-message {
            background: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #f5c6cb;
            margin-bottom: 20px;
        }
        
        .success-message {
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #c3e6cb;
            margin-bottom: 20px;
        }
        
        .section {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        
        .section h2 {
            color: #667eea;
            font-size: 1.8em;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        
        .school-details {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }
        
        .detail-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #667eea;
        }
        
        .detail-label {
            font-weight: 700;
            color: #667eea;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 5px;
        }
        
        .detail-value {
            color: #333;
            font-size: 1.1em;
            word-break: break-word;
        }
        
        .contacts-list {
            list-style: none;
        }
        
        .contact-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 10px;
            border-left: 4px solid #764ba2;
        }
        
        .contact-item h4 {
            color: #764ba2;
            margin-bottom: 8px;
        }
        
        .contact-info {
            font-size: 0.95em;
            color: #555;
            line-height: 1.6;
        }
        
        .contact-info a {
            color: #667eea;
            text-decoration: none;
        }
        
        .contact-info a:hover {
            text-decoration: underline;
        }
        
        .activities-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
        }
        
        .activity-card {
            background: #f8f9fa;
            border-radius: 8px;
            overflow: hidden;
            border: 2px solid #e0e0e0;
            transition: transform 0.3s, box-shadow 0.3s;
        }
        
        .activity-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
        }
        
        .activity-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px;
        }
        
        .activity-title {
            font-size: 1.2em;
            font-weight: 700;
            margin-bottom: 5px;
        }
        
        .activity-date {
            font-size: 0.9em;
            opacity: 0.9;
        }
        
        .activity-body {
            padding: 15px;
        }
        
        .activity-info {
            margin-bottom: 12px;
        }
        
        .activity-info label {
            font-weight: 700;
            color: #667eea;
            font-size: 0.85em;
            display: block;
            text-transform: uppercase;
            margin-bottom: 3px;
        }
        
        .activity-info p {
            color: #555;
            line-height: 1.5;
        }
        
        .activity-images {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-top: 15px;
            padding-top: 15px;
            border-top: 1px solid #e0e0e0;
        }
        
        .image-container {
            text-align: center;
        }
        
        .image-container img {
            max-width: 100%;
            height: auto;
            border-radius: 5px;
            background: white;
            cursor: pointer;
            transition: transform 0.3s;
        }
        
        .image-container img:hover {
            transform: scale(1.05);
        }
        
        .video-link {
            display: inline-block;
            margin-top: 10px;
            padding: 8px 16px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-size: 0.9em;
            transition: background 0.3s;
        }
        
        .video-link:hover {
            background: #764ba2;
        }
        
        .empty-state {
            text-align: center;
            padding: 40px;
            color: #999;
        }
        
        .empty-state-icon {
            font-size: 3em;
            margin-bottom: 10px;
        }
        
        .tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            border-bottom: 2px solid #e0e0e0;
            flex-wrap: wrap;
        }
        
        .tab-button {
            padding: 12px 20px;
            background: none;
            border: none;
            border-bottom: 3px solid transparent;
            color: #666;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            font-size: 1em;
        }
        
        .tab-button.active {
            color: #667eea;
            border-bottom-color: #667eea;
        }
        
        .tab-button:hover {
            color: #667eea;
        }
        
        .tab-content {
            display: none;
        }
        
        .tab-content.active {
            display: block;
        }
        
        .loading {
            text-align: center;
            padding: 30px;
            color: #667eea;
        }
        
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #667eea;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 15px;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.8);
        }
        
        .modal.show {
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .modal-content {
            max-width: 90%;
            max-height: 90%;
            position: relative;
        }
        
        .modal-content img {
            max-width: 100%;
            max-height: 100%;
            border-radius: 5px;
        }
        
        .modal-close {
            position: absolute;
            top: -30px;
            right: 0;
            color: white;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
        }
        
        @media (max-width: 768px) {
            .header h1 {
                font-size: 1.8em;
            }
            
            .search-form {
                flex-direction: column;
            }
            
            .search-form input,
            .search-form button {
                width: 100%;
            }
            
            .school-details {
                grid-template-columns: 1fr;
            }
            
            .activities-grid {
                grid-template-columns: 1fr;
            }
            
            .activity-images {
                grid-template-columns: 1fr;
            }
            
            .section {
                padding: 15px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏫 School Information</h1>
            <p>Search by UDISE Number to view school details, meetings, and activities</p>
        </div>
        
        <div class="search-section">
            <form class="search-form" onsubmit="searchSchool(event)">
                <input type="text" id="udiseInput" placeholder="Enter UDISE Number (e.g., 27100100101)" 
                       required autocomplete="off">
                <button type="submit">Search</button>
            </form>
        </div>
        
        <div id="resultsContainer" class="results-container">
            <!-- Results will be loaded here -->
        </div>
    </div>
    
    <!-- Image Modal -->
    <div id="imageModal" class="modal">
        <div class="modal-content">
            <span class="modal-close" onclick="closeImageModal()">&times;</span>
            <img id="modalImage" src="" alt="Image">
        </div>
    </div>
    
    <script>
        const BASE_URL = '<%= request.getContextPath() %>';
        
        function searchSchool(event) {
            event.preventDefault();
            const udiseNo = document.getElementById('udiseInput').value.trim();
            
            if (!udiseNo) {
                showError('Please enter a UDISE number');
                return;
            }
            
            const resultsContainer = document.getElementById('resultsContainer');
            resultsContainer.innerHTML = '<div class="loading"><div class="spinner"></div><p>Loading school details...</p></div>';
            resultsContainer.style.display = 'block';
            
            fetch(`${BASE_URL}/public-school-lookup?udise=${encodeURIComponent(udiseNo)}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        displayResults(data);
                    } else {
                        showError(data.message || 'School not found');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    showError('An error occurred while fetching school details');
                });
        }
        
        function displayResults(data) {
            const school = data.school;
            const melavas = data.palakMelavas || [];
            const activities = data.activities || [];
            
            let html = '';
            
            // School Details Section
            html += `
                <div class="section">
                    <h2>📋 School Details</h2>
                    <div class="school-details">
                        <div class="detail-item">
                            <div class="detail-label">School Name</div>
                            <div class="detail-value">${escapeHtml(school.schoolName)}</div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">UDISE Number</div>
                            <div class="detail-value">${escapeHtml(school.udiseNo)}</div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">District</div>
                            <div class="detail-value">${escapeHtml(school.districtName)}</div>
                        </div>
                    </div>
            `;
            
            // School Contacts
            if (school.contacts && school.contacts.length > 0) {
                html += '<h3 style="margin-top: 25px; margin-bottom: 15px; color: #666;">📞 School Contacts</h3>';
                html += '<ul class="contacts-list">';
                
                school.contacts.forEach(contact => {
                    html += `
                        <li class="contact-item">
                            <h4>${escapeHtml(contact.fullName)} ${contact.contactType ? '(' + escapeHtml(contact.contactType) + ')' : ''}</h4>
                            <div class="contact-info">
                                <div>📱 Mobile: <a href="tel:${escapeHtml(contact.mobile)}">${escapeHtml(contact.mobile)}</a></div>
                                ${contact.whatsappNumber ? `<div>💬 WhatsApp: <a href="https://wa.me/${contact.whatsappNumber.replace(/[^0-9]/g, '')}" target="_blank">${escapeHtml(contact.whatsappNumber)}</a></div>` : ''}
                                ${contact.remarks ? `<div>📝 Remarks: ${escapeHtml(contact.remarks)}</div>` : ''}
                            </div>
                        </li>
                    `;
                });
                
                html += '</ul>';
            }
            
            html += '</div>';
            
            // Tabs Navigation
            html += '<div class="section">';
            html += '<div class="tabs">';
            html += `<button class="tab-button active" onclick="switchTab('palak')">${melavas.length > 0 ? '✓' : '○'} Palak Melava Meetings (${melavas.length})</button>`;
            html += `<button class="tab-button" onclick="switchTab('activities')">${activities.length > 0 ? '✓' : '○'} School Activities (${activities.length})</button>`;
            html += '</div>';
            
            // Palak Melava Section
            html += '<div id="palak" class="tab-content active">';
            if (melavas.length > 0) {
                html += '<div class="activities-grid">';
                melavas.forEach(melava => {
                    html += `
                        <div class="activity-card">
                            <div class="activity-header">
                                <div class="activity-title">👨‍👩‍👧 Parent-Teacher Meeting</div>
                                <div class="activity-date">📅 ${escapeHtml(melava.meetingDate)}</div>
                            </div>
                            <div class="activity-body">
                                <div class="activity-info">
                                    <label>Chief Guest / Attendee</label>
                                    <p>${melava.chiefAttendeeInfo ? escapeHtml(melava.chiefAttendeeInfo) : 'Not specified'}</p>
                                </div>
                                <div class="activity-info">
                                    <label>Parents Attended</label>
                                    <p>${melava.totalParentsAttended ? escapeHtml(melava.totalParentsAttended) : 'Not specified'}</p>
                                </div>
                    `;
                    
                    if (melava.hasPhoto1 || melava.hasPhoto2) {
                        html += '<div class="activity-images">';
                        if (melava.hasPhoto1) {
                            html += `
                                <div class="image-container">
                                    <img src="${BASE_URL}/public-school-image?type=melava&id=${melava.melavaId}&photo=1" 
                                         alt="Photo 1" onclick="openImageModal(this.src)">
                                </div>
                            `;
                        }
                        if (melava.hasPhoto2) {
                            html += `
                                <div class="image-container">
                                    <img src="${BASE_URL}/public-school-image?type=melava&id=${melava.melavaId}&photo=2" 
                                         alt="Photo 2" onclick="openImageModal(this.src)">
                                </div>
                            `;
                        }
                        html += '</div>';
                    }
                    
                    html += `
                                <div style="margin-top: 10px; text-align: center; color: #28a745; font-weight: 600;">
                                    ✓ Approved
                                </div>
                            </div>
                        </div>
                    `;
                });
                html += '</div>';
            } else {
                html += '<div class="empty-state"><div class="empty-state-icon">📭</div><p>No approved Palak Melava meetings recorded yet</p></div>';
            }
            html += '</div>';
            
            // Other School Activities Section
            html += '<div id="activities" class="tab-content">';
            if (activities.length > 0) {
                html += '<div class="activities-grid">';
                activities.forEach(activity => {
                    html += `
                        <div class="activity-card">
                            <div class="activity-header">
                                <div class="activity-title">${escapeHtml(activity.activitySubject || 'School Activity')}</div>
                                <div class="activity-date">📅 ${escapeHtml(activity.activityDate)}</div>
                            </div>
                            <div class="activity-body">
                                <div class="activity-info">
                                    <label>Guests Present</label>
                                    <p>${activity.guestsPresent ? escapeHtml(activity.guestsPresent) : 'Not specified'}</p>
                                </div>
                                <div class="activity-info">
                                    <label>Description</label>
                                    <p>${activity.description ? escapeHtml(activity.description) : 'No description'}</p>
                                </div>
                    `;
                    
                    if (activity.hasPhoto1 || activity.hasPhoto2) {
                        html += '<div class="activity-images">';
                        if (activity.hasPhoto1) {
                            html += `
                                <div class="image-container">
                                    <img src="${BASE_URL}/public-school-image?type=activity&id=${activity.activityId}&photo=1" 
                                         alt="Photo 1" onclick="openImageModal(this.src)">
                                </div>
                            `;
                        }
                        if (activity.hasPhoto2) {
                            html += `
                                <div class="image-container">
                                    <img src="${BASE_URL}/public-school-image?type=activity&id=${activity.activityId}&photo=2" 
                                         alt="Photo 2" onclick="openImageModal(this.src)">
                                </div>
                            `;
                        }
                        html += '</div>';
                    }
                    
                    if (activity.videoLink) {
                        html += `<a href="${escapeHtml(activity.videoLink)}" target="_blank" class="video-link">▶ Watch Video</a>`;
                    }
                    
                    html += `
                                <div style="margin-top: 10px; text-align: center; color: #28a745; font-weight: 600;">
                                    ✓ Approved
                                </div>
                            </div>
                        </div>
                    `;
                });
                html += '</div>';
            } else {
                html += '<div class="empty-state"><div class="empty-state-icon">📭</div><p>No approved school activities recorded yet</p></div>';
            }
            html += '</div>';
            
            html += '</div>';
            
            document.getElementById('resultsContainer').innerHTML = html;
            document.getElementById('resultsContainer').style.display = 'block';
        }
        
        function switchTab(tabName) {
            // Hide all tab contents
            document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.tab-button').forEach(el => el.classList.remove('active'));
            
            // Show selected tab
            document.getElementById(tabName).classList.add('active');
            event.target.classList.add('active');
        }
        
        function showError(message) {
            const resultsContainer = document.getElementById('resultsContainer');
            resultsContainer.innerHTML = `<div class="error-message"><strong>Error:</strong> ${escapeHtml(message)}</div>`;
            resultsContainer.style.display = 'block';
        }
        
        function openImageModal(imageSrc) {
            document.getElementById('imageModal').classList.add('show');
            document.getElementById('modalImage').src = imageSrc;
        }
        
        function closeImageModal() {
            document.getElementById('imageModal').classList.remove('show');
        }
        
        function escapeHtml(text) {
            if (!text) return '';
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        // Close modal when clicking outside image
        document.getElementById('imageModal').onclick = function(event) {
            if (event.target === this) {
                closeImageModal();
            }
        }
        
        // Focus on input on page load
        window.addEventListener('load', function() {
            document.getElementById('udiseInput').focus();
        });
    </script>
</body>
</html>
