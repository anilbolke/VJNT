# COMPLETE YOUTUBE UPLOAD FIX - DEPLOYMENT CHECKLIST

## Current Status
- ✅ Credentials found: `src/main/webapp/credentials/StoredCredential`
- ✅ Credentials packaged: `youtube-credentials.zip` created
- ⏳ Ready to deploy to production

---

## DEPLOYMENT STEPS (Follow in Order)

### **STEP 1: Prepare on Local Machine**

1. **Ensure client_secret.json is in place:**
   ```cmd
   COPY_CLIENT_SECRET.bat
   ```
   - This copies `client_secret.json` to `WEB-INF/classes/`

2. **Export WAR from Eclipse:**
   - Right-click project → Export → WAR file
   - Save as: `ROOT.war`
   - Location: Project root folder

3. **Verify WAR contains client_secret.json:**
   ```cmd
   VERIFY_ROOT_WAR.bat
   ```
   - Should show: `WEB-INF/classes/client_secret.json`

---

### **STEP 2: Upload Files to Production Server**

Upload both files to your server:

```bash
# Upload credentials
scp youtube-credentials.zip root@YOUR_SERVER_IP:/tmp/

# Upload WAR file
scp ROOT.war root@YOUR_SERVER_IP:/tmp/

# Upload deployment script
scp deploy-youtube-fix.sh root@YOUR_SERVER_IP:/tmp/
```

---

### **STEP 3: Deploy on Production Server**

SSH to your server and run the deployment script:

```bash
ssh root@YOUR_SERVER_IP

# Make script executable
chmod +x /tmp/deploy-youtube-fix.sh

# Run deployment
/tmp/deploy-youtube-fix.sh
```

The script will automatically:
- ✅ Stop Tomcat
- ✅ Extract credentials to `/opt/apache-tomcat-9/credentials/`
- ✅ Set correct permissions
- ✅ Deploy ROOT.war
- ✅ Start Tomcat
- ✅ Verify deployment

---

### **STEP 4: Verify Success**

Watch the Tomcat logs:

```bash
tail -f /opt/apache-tomcat-9/logs/catalina.out
```

**Look for these SUCCESS messages:**
```
✓ SUCCESS: Found client_secret.json in classpath
✓ Using existing stored credentials (refresh token found)
```

**If you see these, YouTube uploads will work!**

---

## WHAT EACH FILE DOES

### 1. **client_secret.json** (in WAR)
- Contains Google API credentials
- Needed for YouTube API authentication
- Must be in `WEB-INF/classes/` inside WAR

### 2. **credentials/StoredCredential** (on server)
- Contains OAuth access and refresh tokens
- Allows server to upload without browser
- Must be in `/opt/apache-tomcat-9/credentials/`

### 3. **Both files are required!**
- `client_secret.json` → Identifies your app to Google
- `StoredCredential` → Authorizes your app to upload

---

## TROUBLESHOOTING

### Issue: "client_secret.json not found"
**Cause:** File not included in WAR

**Solution:**
1. Run `COPY_CLIENT_SECRET.bat` on local machine
2. Export new ROOT.war from Eclipse
3. Upload and deploy again

### Issue: "YouTube upload requires initial OAuth authorization"
**Cause:** StoredCredential not found on server

**Solution:**
```bash
# Verify credentials exist on server
ls -la /opt/apache-tomcat-9/credentials/StoredCredential

# If missing, re-extract:
cd /opt/apache-tomcat-9
unzip -o /tmp/youtube-credentials.zip
chown -R tomcat:tomcat credentials/
```

### Issue: Still getting 502 errors
**Cause:** Servlet crashing before reaching credentials check

**Solution:**
1. Check Tomcat logs: `tail -100 /opt/apache-tomcat-9/logs/catalina.out`
2. Look for specific error messages
3. Verify both files are present:
   - `/opt/apache-tomcat-9/credentials/StoredCredential`
   - `/opt/apache-tomcat-9/webapps/ROOT/WEB-INF/classes/client_secret.json`

---

## QUICK VERIFICATION COMMANDS

Run these on production server to verify everything is in place:

```bash
# 1. Check credentials
ls -la /opt/apache-tomcat-9/credentials/StoredCredential
# Should show file with ~400-500 bytes

# 2. Check client_secret.json
ls -la /opt/apache-tomcat-9/webapps/ROOT/WEB-INF/classes/client_secret.json
# Should show file with ~300-400 bytes

# 3. Check Tomcat is running
ps aux | grep tomcat

# 4. Check logs for errors
tail -50 /opt/apache-tomcat-9/logs/catalina.out | grep -i error

# 5. Check logs for success
tail -50 /opt/apache-tomcat-9/logs/catalina.out | grep -i "stored credentials"
```

---

## FILES YOU SHOULD HAVE

On Local Machine:
- ✅ `youtube-credentials.zip` (created)
- ✅ `ROOT.war` (export from Eclipse)
- ✅ `deploy-youtube-fix.sh` (created)

On Production Server (after deployment):
- ✅ `/opt/apache-tomcat-9/credentials/StoredCredential`
- ✅ `/opt/apache-tomcat-9/webapps/ROOT.war`
- ✅ `/opt/apache-tomcat-9/webapps/ROOT/WEB-INF/classes/client_secret.json`

---

## EXPECTED RESULTS

### Before Fix:
```
User uploads video → 502 Proxy Error ❌
```

### After Fix:
```
User uploads video → Progress bar → Upload to YouTube → Success! ✅
```

---

## READY TO DEPLOY?

Follow the steps in order:

1. ✅ Run `COPY_CLIENT_SECRET.bat`
2. ✅ Export ROOT.war from Eclipse
3. ✅ Upload 3 files to server (credentials.zip, ROOT.war, deploy script)
4. ✅ Run deployment script
5. ✅ Verify in logs
6. ✅ Test upload!

---

**You have all the files ready. Start with STEP 1 above!**
