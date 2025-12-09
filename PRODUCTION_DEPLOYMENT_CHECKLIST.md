# Production Deployment Checklist - Service Account Setup

## Pre-Deployment (One-Time Setup)

### ☐ 1. Create Service Account in Google Cloud Console
- [ ] Navigate to https://console.cloud.google.com/iam-admin/serviceaccounts
- [ ] Create new service account: `youtube-uploader`
- [ ] Download JSON key file
- [ ] Save as: `service-account.json`

### ☐ 2. Grant Service Account Access to YouTube Channel
- [ ] Go to YouTube Studio → Settings → Permissions
- [ ] Click "INVITE"
- [ ] Add service account email (e.g., `youtube-uploader@project.iam.gserviceaccount.com`)
- [ ] Grant "Manager" or "Editor" role
- [ ] Verify permission granted

### ☐ 3. Configure Application
- [ ] Place `service-account.json` in `src/main/resources/`
- [ ] Edit `src/main/resources/youtube.properties`
- [ ] Set: `youtube.auth.type=service-account`
- [ ] Verify: `youtube.service.account.file=service-account.json`

---

## Build & Deploy Steps

### ☐ 4. Build WAR File
```bash
# Run one of these:
mvn clean package
# OR
BUILD_WAR_ECLIPSE.bat
```

### ☐ 5. Verify Service Account File is in WAR
```bash
# Check that service-account.json is packaged
jar tf build/war/ROOT.war | findstr service-account.json
```
Expected output: `WEB-INF/classes/service-account.json`

### ☐ 6. Deploy to Production Server
- [ ] Stop Tomcat server
- [ ] Backup current WAR (optional)
- [ ] Copy new ROOT.war to webapps folder
- [ ] Start Tomcat server
- [ ] Wait for WAR to extract

---

## Post-Deployment Verification

### ☐ 7. Check Logs for Service Account Authentication
```bash
# Look for these messages in catalina.out:
grep "Service Account" logs/catalina.out
```

Expected output:
```
Using Service Account authentication for production deployment...
✓ Service Account authentication successful
Service Account: youtube-uploader@your-project.iam.gserviceaccount.com
```

### ☐ 8. Test Video Upload
- [ ] Upload a test video through the application
- [ ] Check for success message (no OAuth browser prompt)
- [ ] Verify video appears in YouTube Studio
- [ ] Confirm video metadata is correct

### ☐ 9. Monitor for Errors
Common issues to watch for:
- [ ] "Service Account Key File Not Found" → Rebuild WAR
- [ ] "The caller does not have permission" → Check YouTube channel permissions
- [ ] "Access Not Configured" → Enable YouTube Data API v3

---

## Security Checklist

### ☐ 10. Protect Credentials
- [ ] Verify `service-account.json` is NOT in Git repository
- [ ] Add to `.gitignore`: `**/service-account.json`
- [ ] Remove any accidentally committed credential files
- [ ] Document credential location for team (secure wiki/vault)

### ☐ 11. Set Up Key Rotation Schedule
- [ ] Schedule key rotation (recommended: every 90 days)
- [ ] Document rotation procedure
- [ ] Test with new key before deleting old key

---

## Rollback Plan (If Issues Occur)

### ☐ 12. Quick Rollback to OAuth (Emergency)
If service account doesn't work, switch back to OAuth temporarily:

1. Edit `youtube.properties` on server:
   ```properties
   youtube.auth.type=oauth
   ```

2. Copy pre-authorized `credentials` folder to server

3. Restart application

4. Investigate service account issue

---

## Success Criteria

✅ **Deployment is successful when:**
- [ ] No browser authorization required
- [ ] Videos upload successfully from production server
- [ ] Service account email appears in logs
- [ ] No permission errors in logs
- [ ] Videos appear in correct YouTube channel
- [ ] Application works on headless server

---

## Quick Reference

### File Locations
```
Production Server:
  └── tomcat/webapps/ROOT/
      └── WEB-INF/classes/
          ├── service-account.json  ← Must exist
          └── youtube.properties     ← Must have auth.type=service-account

Development:
  └── src/main/resources/
      ├── service-account.json
      └── youtube.properties
```

### Key Commands
```bash
# Check current auth type
grep "auth.type" src/main/resources/youtube.properties

# Verify file in WAR
jar tf ROOT.war | findstr service-account

# View service account logs
tail -f logs/catalina.out | findstr "Service Account"

# Test configuration
curl http://localhost:8080/your-app/test-youtube-auth
```

---

## Troubleshooting Quick Guide

| Error | Solution |
|-------|----------|
| File not found | Rebuild WAR with service-account.json in resources |
| Permission denied | Add service account to YouTube channel permissions |
| API not enabled | Enable YouTube Data API v3 in Cloud Console |
| Invalid credentials | Re-download service account key |
| Still using OAuth | Check youtube.properties in deployed WAR |

---

## Need Help?

1. Enable debug mode: `youtube.debug.enabled=true`
2. Check full error in logs
3. Review SERVICE_ACCOUNT_SETUP.md for detailed instructions
4. Verify all checklist items above

---

**Last Updated**: December 9, 2025  
**Document Version**: 1.0
