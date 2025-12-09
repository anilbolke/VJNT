# YouTube Service Account Setup Guide

## Overview
Service Account authentication allows your application to upload videos to YouTube without requiring manual browser-based OAuth authorization. This is **essential for production servers** where there's no display/browser available.

## When to Use Service Account vs OAuth

### OAuth (Default)
- ✅ Best for: Local development, testing
- ✅ Requires: Browser access for initial authorization
- ✅ Setup: Simple, just need client_secret.json
- ❌ Problem: Doesn't work on headless servers

### Service Account (Production)
- ✅ Best for: Production servers, automated deployments, headless environments
- ✅ Requires: No browser needed
- ✅ Setup: More steps (see below)
- ✅ Benefit: Fully automated, no manual intervention

---

## Step 1: Create a Service Account

### 1.1 Go to Google Cloud Console
Navigate to: https://console.cloud.google.com/iam-admin/serviceaccounts

### 1.2 Select Your Project
Choose the same project where your YouTube Data API is enabled

### 1.3 Create Service Account
1. Click **"+ CREATE SERVICE ACCOUNT"**
2. **Service account name**: `youtube-uploader`
3. **Service account ID**: `youtube-uploader` (auto-generated)
4. **Description**: `Service account for automated YouTube video uploads`
5. Click **"CREATE AND CONTINUE"**

### 1.4 Grant Roles (Optional)
You can skip role assignment for now and click **"CONTINUE"**

### 1.5 Create and Download Key
1. Click **"DONE"** to create the service account
2. Find your new service account in the list
3. Click on the service account email
4. Go to **"KEYS"** tab
5. Click **"ADD KEY"** → **"Create new key"**
6. Choose **JSON** format
7. Click **"CREATE"**
8. The key file will download automatically (e.g., `your-project-abc123.json`)

---

## Step 2: Grant Service Account Access to YouTube Channel

**CRITICAL STEP**: The service account needs permission to manage your YouTube channel.

### Option A: Using YouTube Studio (Recommended)

1. Go to YouTube Studio: https://studio.youtube.com
2. Click **Settings** (gear icon)
3. Click **Permissions**
4. Click **INVITE**
5. Enter the service account email (looks like: `youtube-uploader@your-project.iam.gserviceaccount.com`)
6. Select role: **Manager** or **Editor**
7. Click **DONE**
8. The service account should receive an invitation
9. **Important**: The invitation is automatically accepted for service accounts

### Option B: Using YouTube Brand Account

If using a Brand Account:
1. Go to: https://www.youtube.com/account_advanced
2. Under "Account Information", click **Add or remove manager(s)**
3. Add the service account email
4. Grant **Manager** permissions

---

## Step 3: Configure Your Application

### 3.1 Rename and Place the Key File

1. Rename the downloaded JSON file to: `service-account.json`
2. Place it in: `src/main/resources/service-account.json`

**File structure should look like:**
```
VJNT Class Managment/
├── src/
│   └── main/
│       └── resources/
│           ├── client_secret.json      (for OAuth)
│           ├── service-account.json    (for Service Account) ← NEW
│           └── youtube.properties
```

### 3.2 Update youtube.properties

Edit `src/main/resources/youtube.properties`:

```properties
# Change authentication type to service-account
youtube.auth.type=service-account

# Optionally customize the service account file name
youtube.service.account.file=service-account.json
```

### 3.3 Rebuild and Deploy

```bash
# Clean and rebuild the WAR
mvn clean package

# Or use your build script
BUILD_WAR_ECLIPSE.bat

# Deploy to production (the service-account.json will be packaged in the WAR)
```

---

## Step 4: Verify Setup

### Test Upload
1. Deploy your updated WAR file
2. Try uploading a video through your application
3. Check the logs for:
   ```
   Using Service Account authentication for production deployment...
   ✓ Service Account authentication successful
   Service Account: youtube-uploader@your-project.iam.gserviceaccount.com
   ```

### Common Success Indicators
- ✅ No browser authorization required
- ✅ Uploads work on headless servers
- ✅ Service account email shown in logs
- ✅ Videos appear in your YouTube channel

---

## Troubleshooting

### Error: "Service Account Key File Not Found"
**Solution**: Make sure `service-account.json` is in `src/main/resources/` and rebuild the WAR

### Error: "The caller does not have permission"
**Cause**: Service account not granted access to YouTube channel
**Solution**: Follow Step 2 again - add the service account as a channel manager

### Error: "Access Not Configured. YouTube Data API has not been used..."
**Solution**: Enable YouTube Data API v3 in Google Cloud Console
1. Go to: https://console.cloud.google.com/apis/library
2. Search for "YouTube Data API v3"
3. Click **ENABLE**

### Videos Not Appearing in Channel
**Check**:
1. Service account has Manager/Editor role on the channel
2. Videos are set to correct privacy status (public/unlisted/private)
3. Check YouTube Studio for any copyright/policy issues

### Authentication Still Using OAuth
**Check**:
1. `youtube.properties` has `youtube.auth.type=service-account`
2. WAR was rebuilt after adding the property
3. Properties file is in the deployed WAR (check WEB-INF/classes/)

---

## Security Best Practices

### 🔒 Protect Your Service Account Key
- ❌ **NEVER** commit `service-account.json` to Git
- ❌ **NEVER** share the key file publicly
- ✅ Add to `.gitignore`: `**/service-account.json`
- ✅ Use environment-specific keys (dev/staging/prod)
- ✅ Rotate keys periodically (every 90 days recommended)

### 🔐 Add to .gitignore
```gitignore
# Google Cloud credentials
client_secret.json
service-account.json
credentials/
*.json
```

### 🔄 Key Rotation Process
1. Create a new key for the service account
2. Update `service-account.json` in your project
3. Deploy the new version
4. Test to ensure it works
5. Delete the old key from Google Cloud Console

---

## Comparison: OAuth vs Service Account

| Feature | OAuth | Service Account |
|---------|-------|-----------------|
| **Browser Required** | Yes (first time) | No |
| **Headless Server** | ❌ Requires manual setup | ✅ Works automatically |
| **Setup Complexity** | Simple | Medium |
| **Production Ready** | No | ✅ Yes |
| **Token Refresh** | Automatic | Automatic |
| **Channel Access** | Direct | Requires permission grant |
| **Best For** | Development | Production |

---

## Quick Reference Commands

```bash
# Switch to Service Account
echo "youtube.auth.type=service-account" >> src/main/resources/youtube.properties

# Switch back to OAuth
echo "youtube.auth.type=oauth" >> src/main/resources/youtube.properties

# Rebuild WAR
mvn clean package

# Check if service-account.json is in WAR
jar tf target/ROOT.war | grep service-account.json

# View service account in logs
grep "Service Account" logs/catalina.out
```

---

## Additional Resources

- [Google Cloud Service Accounts Documentation](https://cloud.google.com/iam/docs/service-accounts)
- [YouTube Data API Overview](https://developers.google.com/youtube/v3/getting-started)
- [Managing YouTube Channel Permissions](https://support.google.com/youtube/answer/4628007)

---

## Support

If you encounter issues:
1. Check the application logs for detailed error messages
2. Verify service account permissions in YouTube Studio
3. Ensure the service-account.json file is properly packaged in the WAR
4. Enable debug mode: `youtube.debug.enabled=true` in youtube.properties
