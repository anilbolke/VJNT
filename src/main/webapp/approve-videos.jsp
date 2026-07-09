<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    // Check if user is logged in and is a headmaster
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    if (user.getUserType() != User.UserType.HEAD_MASTER) {
        response.sendRedirect("school-dashboard-enhanced.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Approve Student Videos - VJNT Class Management</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        
        .container {
            margin-top: 30px;
            margin-bottom: 30px;
        }
        
        .header-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 30px;
        }
        
        .video-card {
            background: white;
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }
        
        .video-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.15);
        }
        
        .video-preview {
            position: relative;
            width: 100%;
            padding-bottom: 56.25%; /* 16:9 aspect ratio */
            background: #000;
            border-radius: 10px;
            overflow: hidden;
        }
        
        .video-preview video {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
        }
        
        .video-info {
            margin-top: 15px;
        }
        
        .student-badge {
            background: #667eea;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 14px;
            display: inline-block;
            margin-right: 10px;
        }
        
        .status-badge {
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
        }
        
        .status-pending {
            background: #ffc107;
            color: #000;
        }
        
        .btn-approve {
            background: #28a745;
            color: white;
            border: none;
            padding: 10px 25px;
            border-radius: 25px;
            font-weight: bold;
            transition: all 0.3s ease;
        }
        
        .btn-approve:hover {
            background: #218838;
            transform: scale(1.05);
        }
        
        .btn-reject {
            background: #dc3545;
            color: white;
            border: none;
            padding: 10px 25px;
            border-radius: 25px;
            font-weight: bold;
            transition: all 0.3s ease;
        }
        
        .btn-reject:hover {
            background: #c82333;
            transform: scale(1.05);
        }
        
        .stats-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 15px;
            text-align: center;
            margin-bottom: 20px;
        }
        
        .stats-number {
            font-size: 48px;
            font-weight: bold;
        }
        
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #666;
        }
        
        .empty-state i {
            font-size: 80px;
            color: #ddd;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header-card">
            <div class="row align-items-center">
                <div class="col-md-8">
                    <h2><i class="fas fa-video"></i> Video Approval Center</h2>
                    <p class="text-muted mb-0">Review and approve videos uploaded by school coordinators</p>
                    <p class="mb-0"><strong>School:</strong> <%= user.getUdiseNo() %> | <strong>Headmaster:</strong> <%= user.getUsername() %></p>
                </div>
                <div class="col-md-4 text-end">
                    <button class="btn btn-primary" onclick="window.location.href='school-dashboard-enhanced.jsp'">
                        <i class="fas fa-home"></i> Back to Dashboard
                    </button>
                </div>
            </div>
        </div>
        
        <!-- Stats -->
        <div class="row" id="statsContainer">
            <div class="col-md-12">
                <div class="stats-card">
                    <div class="stats-number" id="pendingCount">0</div>
                    <div>Videos Pending Approval</div>
                </div>
            </div>
        </div>
        
        <!-- Videos List -->
        <div id="videosContainer">
            <div class="text-center">
                <div class="spinner-border text-light" role="status">
                    <span class="visually-hidden">Loading...</span>
                </div>
                <p class="text-white mt-3">Loading pending videos...</p>
            </div>
        </div>
    </div>
    
    <!-- Rejection Modal -->
    <div class="modal fade" id="rejectModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Reject Video</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <p>Please provide a reason for rejecting this video:</p>
                    <textarea class="form-control" id="rejectionReason" rows="4" 
                              placeholder="Enter rejection reason..."></textarea>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-danger" onclick="confirmReject()">
                        <i class="fas fa-times-circle"></i> Reject Video
                    </button>
                </div>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        let currentVideoId = null;
        let rejectModalInstance = null;
        
        // Load pending videos on page load
        document.addEventListener('DOMContentLoaded', function() {
            rejectModalInstance = new bootstrap.Modal(document.getElementById('rejectModal'));
            loadPendingVideos();
        });
        
        // Open video in new tab and manage focus
        function openVideoInNewTab(videoUrl) {
            // Open video in new tab
            const videoTab = window.open(videoUrl, '_blank');
            
            // If popup was blocked, alert user
            if (!videoTab || videoTab.closed || typeof videoTab.closed == 'undefined') {
                alert('⚠️ Popup blocked! Please allow popups for this site and try again.');
                return;
            }
            
            // Focus on the new tab
            videoTab.focus();
            
            // Periodically check if the video tab is closed, then refocus this window
            const checkInterval = setInterval(function() {
                if (videoTab.closed) {
                    clearInterval(checkInterval);
                    window.focus(); // Return focus to this approval window
                    console.log('Video tab closed, focus returned to approval page');
                }
            }, 500); // Check every 500ms
            
            // Stop checking after 30 minutes (cleanup)
            setTimeout(function() {
                clearInterval(checkInterval);
            }, 1800000); // 30 minutes
        }
        
        // Open video from card - retrieves URL from data attribute
        function openVideoFromCard(videoId) {
            const card = document.getElementById('video-' + videoId);
            if (!card) {
                alert('Error: Could not find video card');
                return;
            }
            
            const videoUrl = card.getAttribute('data-video-url');
            if (!videoUrl) {
                alert('Error: Video URL not found');
                console.error('No video URL in card:', card);
                return;
            }
            
            console.log('Opening video URL:', videoUrl);
            openVideoInNewTab(videoUrl);
        }
        
        // Load pending videos
        function loadPendingVideos() {
            fetch('get-pending-videos')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        displayVideos(data.videos);
                        document.getElementById('pendingCount').textContent = data.count;
                    } else {
                        showError(data.message);
                    }
                })
                .catch(error => {
                    console.error('Error loading videos:', error);
                    showError('Failed to load videos: ' + error.message);
                });
        }
        
        // Display videos
        function displayVideos(videos) {
            const container = document.getElementById('videosContainer');
            
            if (videos.length === 0) {
                container.innerHTML = `
                    <div class="empty-state">
                        <i class="fas fa-check-circle"></i>
                        <h3>All Caught Up!</h3>
                        <p>There are no pending videos to review at this time.</p>
                    </div>
                `;
                return;
            }
            
            let html = '';
            videos.forEach(video => {
                // Extract videoId safely
                const videoId = video.videoId;
                
                // Escape single quotes in URL for onclick attribute
                const safeUrl = (video.filePath || '').replace(/'/g, "\\'");
                
                html += `
                    <div class="video-card" id="video-` + videoId + `">
                        <div class="row">
                            <div class="col-md-6">
                                <div class="video-preview" style="display: flex; flex-direction: column; align-items: center; justify-content: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px; border-radius: 10px;">
                                    <i class="fas fa-play-circle" style="font-size: 80px; color: white; margin-bottom: 20px;"></i>
                                    <h4 style="color: white; margin-bottom: 10px; text-align: center;">Video Preview</h4>
                                    <p style="color: rgba(255,255,255,0.9); margin-bottom: 20px; text-align: center; font-size: 14px;">Click below to watch the video</p>
                                    <button onclick="openVideoInNewTab('` + safeUrl + `')" class="btn" style="background: white; color: #667eea; padding: 12px 30px; border: none; border-radius: 25px; font-weight: bold; font-size: 16px; cursor: pointer; transition: all 0.3s ease; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                                        <i class="fas fa-external-link-alt"></i> Open Video
                                    </button>
                                    <p style="color: rgba(255,255,255,0.8); margin-top: 15px; font-size: 12px; text-align: center;">
                                        <i class="fas fa-info-circle"></i> Video will open in a new tab
                                    </p>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="video-info">
                                    <h5><i class="fas fa-graduation-cap"></i> ${video.studentName}</h5>
                                    <p class="text-muted">PEN: ${video.studentPen}</p>
                                    
                                    <div class="mb-3">
                                        ${video.phaseNumber ?
                                            '<span class="student-badge"><i class="fas fa-flag-checkered"></i> Phase ' + video.phaseNumber + '</span>' :
                                            '<span class="student-badge"><i class="fas fa-book"></i> ' + video.subject + '</span>' +
                                            '<span class="student-badge"><i class="fas fa-calendar"></i> ' + video.month + '</span>'
                                        }
                                        <span class="status-badge status-pending">
                                            <i class="fas fa-clock"></i> PENDING
                                        </span>
                                    </div>
                                    
                                    <p><strong>File:</strong> ${video.originalFileName}</p>
                                    <p><strong>Size:</strong> ` + formatFileSize(video.fileSize) + `</p>
                                    <p><strong>Uploaded By:</strong> ${video.uploadedByName}</p>
                                    <p><strong>Upload Date:</strong> ` + formatDate(video.uploadDate) + `</p>
                                    
                                    <div class="mt-4">
                                        <button class="btn-approve me-2" onclick="approveVideo(` + videoId + `)">
                                            <i class="fas fa-check-circle"></i> Approve
                                        </button>
                                        <button class="btn-reject" onclick="showRejectModal(` + videoId + `)">
                                            <i class="fas fa-times-circle"></i> Reject
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                `;
            });
            
            container.innerHTML = html;
        }
        
        // Approve video
        function approveVideo(videoId) {
            if (!confirm('Are you sure you want to approve this video?')) {
                return;
            }
            
            // Use URL-encoded format instead of FormData
            const params = new URLSearchParams();
            params.append('videoId', videoId);
            params.append('action', 'approve');
            
            fetch('approve-video', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: params.toString()
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showSuccess(data.message);
                    removeVideoCard(videoId);
                    updateCount(-1);
                } else {
                    showError(data.message);
                }
            })
            .catch(error => {
                console.error('Error approving video:', error);
                showError('Failed to approve video: ' + error.message);
            });
        }
        
        // Show reject modal
        function showRejectModal(videoId) {
            currentVideoId = videoId;
            document.getElementById('rejectionReason').value = '';
            rejectModalInstance.show();
        }
        
        // Confirm reject
        function confirmReject() {
            const reason = document.getElementById('rejectionReason').value.trim();
            
            if (!reason) {
                alert('Please provide a rejection reason');
                return;
            }
            
            // Use URL-encoded format instead of FormData
            const params = new URLSearchParams();
            params.append('videoId', currentVideoId);
            params.append('action', 'reject');
            params.append('rejectionReason', reason);
            
            fetch('approve-video', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: params.toString()
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showSuccess(data.message);
                    removeVideoCard(currentVideoId);
                    updateCount(-1);
                    rejectModalInstance.hide();
                } else {
                    showError(data.message);
                }
            })
            .catch(error => {
                console.error('Error rejecting video:', error);
                showError('Failed to reject video: ' + error.message);
            });
        }
        
        // Remove video card
        function removeVideoCard(videoId) {
            const card = document.getElementById('video-' + videoId);
            if (card) {
                card.style.transition = 'opacity 0.3s ease';
                card.style.opacity = '0';
                setTimeout(() => card.remove(), 300);
            }
            
            // Check if any videos left
            setTimeout(() => {
                const container = document.getElementById('videosContainer');
                if (container.children.length === 0) {
                    displayVideos([]);
                }
            }, 400);
        }
        
        // Update count
        function updateCount(change) {
            const countEl = document.getElementById('pendingCount');
            const currentCount = parseInt(countEl.textContent);
            countEl.textContent = Math.max(0, currentCount + change);
        }
        
        // Handle video playback errors
        function handleVideoError(videoElement, videoUrl, videoId) {
            console.error('Video playback error for:', videoUrl);
            console.error('Error details:', videoElement.error);
            
            // Hide video player and show error message
            videoElement.style.display = 'none';
            
            // Show error div
            const errorDiv = document.getElementById('video-error-' + videoId);
            if (errorDiv) {
                errorDiv.style.display = 'block';
            }
            
            // Log specific error type
            if (videoElement.error) {
                const errorMessages = {
                    1: 'MEDIA_ERR_ABORTED - Video download was aborted',
                    2: 'MEDIA_ERR_NETWORK - Network error while downloading video',
                    3: 'MEDIA_ERR_DECODE - Video file is corrupted or browser cannot decode',
                    4: 'MEDIA_ERR_SRC_NOT_SUPPORTED - Video format not supported or CDN blocked'
                };
                console.error('Error Code:', videoElement.error.code, '-', errorMessages[videoElement.error.code]);
                
                // For CORS issues, the error might not be specific
                console.warn('If video opens in new tab but not here, this may be a CDN configuration issue.');
            }
        }
        
        // Format file size
        function formatFileSize(bytes) {
            if (bytes < 1024) return bytes + ' B';
            if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
            return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
        }
        
        // Format date
        function formatDate(dateStr) {
            const date = new Date(dateStr);
            return date.toLocaleString('en-IN', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        }
        
        // Show success message
        function showSuccess(message) {
            alert('✓ ' + message);
        }
        
        // Show error message
        function showError(message) {
            alert('✗ ' + message);
        }
    </script>
</body>
</html>
