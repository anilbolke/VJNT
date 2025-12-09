# YouTube Upload 502 Error - Complete Solution Guide

## Problem Identified
The 502 Proxy Error occurs because YouTube OAuth authentication tries to open a browser window on your **headless production server**, which causes the servlet to hang and timeout.

## Root Cause
Your production server cannot perform interactive browser-based OAuth authentication because:
- No display/GUI available (headless server)
- Browser cannot open for authorization
- Servlet times out waiting for authorization
- Result: 502 Proxy Error

## ✅ Solution Implemented

I've updated `YouTubeUploader.java` to:
1. ✅ Check for existing credentials FIRST
2. ✅ Detect if running on a headless server
3. ✅ Prevent interactive authentication on production
4. ✅ Provide clear error message with solution

## 🚀 How to Fix (Choose ONE option)

---

### **OPTION 1: Authorize Locally & Copy Credentials (Easiest)**

#### Step 1: Run on Your Local Machine (Windows)

1. Make sure you have the latest code
2. Run `COPY_CLIENT_SECRET.bat`
3. Export WAR from Eclipse as ROOT.war
4. Deploy on your LOCAL Tomcat (not production yet)
5. Try to upload a video through the application
6. A browser window will open - Click **Allow** to authorize
7. Upload should complete successfully

#### Step 2: Copy Credentials to Production

After successful local upload, you'll have a `credentials` folder. Copy it to production:

```bash
# On your local machine, the credentials folder is in Tomcat's working directory
# Usually: C:\Users\Admin\V2Project\VJNT Class Managment\credentials

# Compress it
tar -czf credentials.tar.gz credentials/

# Upload to production server
scp credentials.tar.gz root@YOUR_SERVER:/tmp/

# On production server
ssh root@YOUR_SERVER
cd /opt/apache-tomcat-9
tar -xzf /tmp/credentials.tar.gz
chown -R tomcat:tomcat credentials/
chmod -R 755 credentials/
```

#### Step 3: Deploy to Production

Now deploy your ROOT.war with client_secret.json:

```bash
# Run locally first
COPY_CLIENT_SECRET.bat

# Export WAR from Eclipse

# Upload to production
scp ROOT.war root@YOUR_SERVER:/tmp/

# Deploy
ssh root@YOUR_SERVER
/opt/apache-tomcat-9/bin/shutdown.sh
rm -rf /opt/apache-tomcat-9/webapps/ROOT*
cp /tmp/ROOT.war /opt/apache-tomcat-9/webapps/
/opt/apache-tomcat-9/bin/startup.sh
```

#### Step 4: Verify

Watch the logs:
```bash
tail -f /opt/apache-tomcat-9/logs/catalina.out
```

Look for:
```
✓ SUCCESS: Found client_secret.json in classpath
✓ Using existing stored credentials (refresh token found)
```

YouTube uploads should now work! 🎉

---

### **OPTION 2: Service Account (Recommended for Production)**

This is the proper production solution but requires more setup.

#### Step 1: Create Service Account in Google Cloud

1. Go to https://console.cloud.google.com/
2. Navigate to **IAM & Admin** > **Service Accounts**
3. Click **Create Service Account**
4. Name: `vjnt-youtube-uploader`
5. Grant access to YouTube Data API v3
6. Create and download JSON key

#### Step 2: Modify Code (Future Enhancement)

You would need to modify YouTubeUploader.java to use service account authentication instead of OAuth flow. This requires code changes but is more robust for production.

---

## 🔍 Why This Happens

### Development (Windows with GUI):
```
User clicks upload → OAuth opens browser → User authorizes → Credentials saved → Upload works
```

### Production (Linux headless server):
```
User clicks upload → OAuth tries to open browser → NO DISPLAY → Hangs → Timeout → 502 Error ❌
```

### After Fix:
```
User clicks upload → Check for credentials → Found! → Use stored credentials → Upload works ✅
```

---

## 📋 Quick Checklist

Before deploying to production, ensure:

- [ ] `client_secret.json` exists in `src/main/resources/`
- [ ] Run `COPY_CLIENT_SECRET.bat` before exporting WAR
- [ ] Export ROOT.war from Eclipse
- [ ] Run `VERIFY_ROOT_WAR.bat` to confirm file is in WAR
- [ ] Authorize on local machine first (creates `credentials` folder)
- [ ] Copy `credentials` folder to production server
- [ ] Place in Tomcat's working directory: `/opt/apache-tomcat-9/credentials/`
- [ ] Deploy ROOT.war to production
- [ ] Restart Tomcat
- [ ] Check logs for "Using existing stored credentials"

---

## 🎯 Error Messages You'll See

### Before Fix:
```
502 Proxy Error
Server error: 502
```

### After Fix (if credentials missing):
```
YouTube upload requires initial OAuth authorization.
Please authorize on a local machine first and copy the credentials folder.
```

### After Fix (with credentials):
```
✓ SUCCESS: Found client_secret.json in classpath
✓ Using existing stored credentials
Upload in progress: 45%
Upload Completed!
```

---

## 🔧 Troubleshooting

### Issue: Still getting 502 after deploying

**Solution**: Make sure credentials folder is in the right location:
```bash
# Check if folder exists
ls -la /opt/apache-tomcat-9/credentials/

# Should show StoredCredential file
ls -la /opt/apache-tomcat-9/credentials/StoredCredential
```

### Issue: "No stored credentials found"

**Solution**: You need to authorize on local machine first, then copy the credentials folder.

### Issue: Upload works locally but not on production

**Solution**: 
1. Check credentials folder exists on production
2. Check file permissions (should be readable by Tomcat user)
3. Check Tomcat logs for specific error messages

---

## 📁 File Locations

### Local Machine:
- `client_secret.json`: `src/main/resources/client_secret.json`
- `credentials`: Created in Tomcat working directory after first authorization

### Production Server:
- `client_secret.json`: Inside ROOT.war at `WEB-INF/classes/client_secret.json`
- `credentials`: `/opt/apache-tomcat-9/credentials/` (copy from local)

---

## ✅ Success Indicators

You'll know it's working when:
1. No 502 errors in browser console
2. Tomcat logs show "Using existing stored credentials"
3. Upload progress bar shows percentage
4. Video appears on YouTube channel
5. Video saves to database with YouTube URL

---

**Next Step**: Follow OPTION 1 above - authorize locally, copy credentials, then deploy to production.

---
*Last Updated: December 9, 2025*
