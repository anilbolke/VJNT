# YouTube API Authentication Solution

## The Problem

You're getting a **401 Unauthorized** error with service account authentication because:

**YouTube API does NOT support service accounts for uploading videos.**

YouTube channels are owned by personal Google accounts, and the YouTube Data API requires OAuth 2.0 with user consent. Service accounts work for other Google APIs (like Drive, Sheets), but NOT for YouTube.

---

## The Solution: Pre-Authorized OAuth Tokens

The correct approach is to:
1. Authorize YouTube access on your LOCAL machine (one-time)
2. Copy the generated credentials to PRODUCTION server
3. The application uses these stored credentials (with auto-refresh)

This is the **official recommended approach** for YouTube API in production.

---

## Step-by-Step Implementation

### Phase 1: Generate OAuth Tokens Locally

#### 1.1 Switch Back to OAuth Mode

Edit `src/main/resources/youtube.properties`:
```properties
# Use OAuth (NOT service-account for YouTube)
youtube.auth.type=oauth
```

#### 1.2 Run Authorization Locally

On your development machine:

1. Make sure you have a display/browser available
2. Set `youtube.credentials.folder=production-credentials` in youtube.properties
3. Run the application or use a test servlet
4. A browser will open asking you to authorize YouTube access
5. Grant permission to your YouTube channel
6. Tokens will be saved in the `production-credentials` folder

#### 1.3 Verify Token Files Created

Check that these files exist:
```
production-credentials/
└── StoredCredential
```

This file contains:
- Access token (short-lived)
- Refresh token (long-lived) ← This is what matters!

---

### Phase 2: Deploy Tokens to Production

#### 2.1 Copy Credentials to Production Server

**Option A: Package in WAR (Recommended)**
```bash
# Copy credentials to webapp folder
mkdir "src\main\webapp\WEB-INF\classes\credentials"
copy "production-credentials\StoredCredential" "src\main\webapp\WEB-INF\classes\credentials\StoredCredential"

# Rebuild WAR
BUILD_WAR_ECLIPSE.bat
```

**Option B: Manual Copy to Server**
```bash
# On production server
mkdir /path/to/tomcat/webapps/ROOT/WEB-INF/classes/credentials
# Upload StoredCredential to this directory
```

#### 2.2 Ensure Configuration

Make sure `youtube.properties` uses OAuth:
```properties
youtube.auth.type=oauth
youtube.credentials.folder=credentials
```

#### 2.3 Deploy and Test

The application will:
- ✅ Find existing credentials
- ✅ Use refresh token to get new access tokens automatically
- ✅ No browser needed (tokens auto-refresh)

---

### Phase 3: Token Maintenance

#### Refresh Tokens Last 6 Months (with use)

- **Auto-refresh**: Tokens refresh automatically when used
- **Expiration**: If not used for 6 months, re-authorize
- **Best practice**: Test uploads monthly to keep tokens active

#### Re-Authorization (if tokens expire)

If you get 401 errors after months:
1. Delete old credentials: `rm production-credentials/StoredCredential`
2. Run local authorization again
3. Copy new credentials to production

---

## Why Service Accounts Don't Work for YouTube

| API | Service Account Support |
|-----|------------------------|
| Google Drive | ✅ Yes |
| Google Sheets | ✅ Yes |
| Google Calendar | ✅ Yes |
| **YouTube Data API** | ❌ **NO** |
| Gmail API | ❌ No |

**YouTube requires OAuth because:**
- Channels are personal accounts
- Content ownership tied to user identity
- Terms of Service enforcement
- Copyright/DMCA compliance

---

## Implementation: Enhanced Error Handling

I'll update the code to:
1. Detect YouTube 401 errors
2. Provide clear guidance
3. Create a helper tool for token generation

---

## Quick Start Commands

### Generate Tokens Locally
```bash
# 1. Set OAuth mode
echo youtube.auth.type=oauth > src\main\resources\youtube.properties

# 2. Run test upload (triggers browser authorization)
# Access: http://localhost:8080/your-app/test-youtube-oauth.jsp

# 3. Find credentials
dir production-credentials\StoredCredential
```

### Package for Production
```bash
# Copy credentials to WAR
mkdir src\main\webapp\WEB-INF\classes\credentials
copy production-credentials\StoredCredential src\main\webapp\WEB-INF\classes\credentials\

# Rebuild
BUILD_WAR_ECLIPSE.bat

# Deploy ROOT.war
```

### Verify in Production
```bash
# Check credentials exist in deployed WAR
jar tf ROOT.war | findstr StoredCredential

# Should show:
# WEB-INF/classes/credentials/StoredCredential
```

---

## Alternative: Domain-Wide Delegation (Complex)

If you have Google Workspace, you CAN use service accounts with domain-wide delegation, but:

❌ **Requires**: Google Workspace (not free Gmail)  
❌ **Complex**: Admin must delegate domain-wide authority  
❌ **Overkill**: For single-channel uploads, OAuth is simpler  

**Recommendation**: Use OAuth with stored credentials (simpler and works for everyone)

---

## Security Notes

### Protecting Stored Credentials

- ✅ Credentials are encrypted by Google libraries
- ✅ Access tokens expire every hour (auto-refresh)
- ✅ Refresh tokens work as long as they're used
- ⚠️ Keep `credentials/StoredCredential` file secure
- ⚠️ Don't commit to Git (add to .gitignore)

### If Credentials Are Compromised

1. Go to: https://myaccount.google.com/permissions
2. Revoke access for your application
3. Generate new credentials (re-authorize locally)
4. Deploy new credentials to production

---

## Troubleshooting

### Error: "401 Unauthorized"

**Cause**: No valid credentials or expired tokens

**Solution**:
1. Generate tokens locally (see Phase 1)
2. Copy to production (see Phase 2)

### Error: "credentials folder not found"

**Cause**: Credentials not packaged in WAR or wrong path

**Solution**:
```bash
# Verify in WAR
jar tf ROOT.war | findstr credentials

# Should show: WEB-INF/classes/credentials/StoredCredential
```

### Error: "invalid_grant"

**Cause**: Refresh token expired (>6 months unused)

**Solution**: Re-authorize (delete old credentials, authorize again)

---

## Summary

✅ **DO**: Use OAuth with stored credentials  
❌ **DON'T**: Use service accounts for YouTube  
✅ **DO**: Package credentials in WAR for production  
❌ **DON'T**: Commit credentials to Git  
✅ **DO**: Test uploads monthly to keep tokens active  

---

**Next Steps**:
1. Set `youtube.auth.type=oauth` in youtube.properties
2. Run authorization on local machine
3. Copy `credentials/StoredCredential` to WAR
4. Rebuild and deploy

This is the standard, supported way to use YouTube API in production! 🎯
