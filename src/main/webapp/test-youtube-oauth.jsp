<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>YouTube OAuth Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
        }
        .info-box {
            background: #e7f3ff;
            border-left: 4px solid #2196F3;
            padding: 15px;
            margin: 20px 0;
        }
        .error-box {
            background: #ffebee;
            border-left: 4px solid #f44336;
            padding: 15px;
            margin: 20px 0;
        }
        .success-box {
            background: #e8f5e9;
            border-left: 4px solid #4CAF50;
            padding: 15px;
            margin: 20px 0;
        }
        button {
            background: #2196F3;
            color: white;
            border: none;
            padding: 12px 30px;
            font-size: 16px;
            cursor: pointer;
            border-radius: 4px;
            margin: 10px 5px;
        }
        button:hover {
            background: #1976D2;
        }
        .steps {
            background: #f5f5f5;
            padding: 20px;
            border-radius: 4px;
            margin: 20px 0;
        }
        .step {
            margin: 10px 0;
            padding-left: 25px;
        }
        code {
            background: #f5f5f5;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
        }
    </style>
</head>
<body>
    <h1>🎥 YouTube OAuth Configuration Test</h1>
    
    <div class="info-box">
        <h3>📋 Before You Start</h3>
        <p>This page will help you complete the YouTube OAuth setup. Make sure you have:</p>
        <ol>
            <li>Enabled YouTube Data API v3 in Google Cloud Console</li>
            <li>Configured OAuth consent screen</li>
            <li>Added yourself as a test user (if app is in Testing mode)</li>
        </ol>
    </div>
    
    <div class="steps">
        <h3>🔧 Configuration Steps</h3>
        
        <div class="step">
            <strong>Step 1:</strong> Go to 
            <a href="https://console.cloud.google.com/apis/credentials/consent?project=analog-decoder-479414-i8" target="_blank">
                OAuth Consent Screen
            </a>
        </div>
        
        <div class="step">
            <strong>Step 2:</strong> Add these scopes:
            <ul>
                <li><code>https://www.googleapis.com/auth/youtube.upload</code></li>
                <li><code>https://www.googleapis.com/auth/youtube</code></li>
            </ul>
        </div>
        
        <div class="step">
            <strong>Step 3:</strong> Add your Gmail as a test user in the OAuth consent screen
        </div>
        
        <div class="step">
            <strong>Step 4:</strong> Enable YouTube Data API v3:
            <a href="https://console.cloud.google.com/apis/library/youtube.googleapis.com?project=analog-decoder-479414-i8" target="_blank">
                Enable API
            </a>
        </div>
        
        <div class="step">
            <strong>Step 5:</strong> Click the button below to test OAuth authorization
        </div>
    </div>
    
    <div style="text-align: center; margin: 30px 0;">
        <button onclick="alert('To test OAuth, go to Manage Student Activities and try uploading a video. The OAuth flow will trigger automatically on first upload.');" 
                style="background: #FF9800;">
            ℹ️ OAuth Test Info
        </button>
        
        <form action="manage-students.jsp" method="get" style="display: inline;">
            <button type="submit" style="background: #4CAF50;">
                ✓ Go to Student Management (Test OAuth Here)
            </button>
        </form>
    </div>
    
    <div class="error-box">
        <h3>⚠️ Common Issues</h3>
        <ul>
            <li><strong>403 access_denied:</strong> App not published OR you're not added as test user</li>
            <li><strong>Redirect URI mismatch:</strong> Add <code>http://localhost:8888/Callback</code> to authorized redirects</li>
            <li><strong>Port 8888 in use:</strong> Close any apps using port 8888</li>
        </ul>
    </div>
    
    <div class="info-box">
        <h3>📌 Current Configuration</h3>
        <p><strong>Client ID:</strong> <code>1089840919584-d4beujl24vmilqqa7n9ivl2ae6iccbns.apps.googleusercontent.com</code></p>
        <p><strong>Project ID:</strong> <code>analog-decoder-479414-i8</code></p>
        <p><strong>Redirect URI:</strong> <code>http://localhost:8888/Callback</code></p>
        <p><strong>Callback Port:</strong> <code>8888</code></p>
    </div>
    
    <div class="success-box">
        <h3>✅ After Successful Authorization</h3>
        <p>Once you successfully authorize:</p>
        <ol>
            <li>A <code>credentials</code> folder will be created in your project</li>
            <li>OAuth tokens will be stored there</li>
            <li>Future uploads won't require re-authorization</li>
            <li>You can upload videos from the "Manage Student Activities" page</li>
        </ol>
    </div>
    
    <hr>
    <p style="text-align: center; color: #666;">
        Need help? Check <code>YOUTUBE_OAUTH_FIX_GUIDE.md</code> in project root
    </p>
</body>
</html>
