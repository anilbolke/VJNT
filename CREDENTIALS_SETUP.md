# Credentials Setup Guide

## Overview
This application requires Google OAuth credentials and service account credentials for YouTube integration. For security reasons, these credentials are NOT included in the repository.

## Required Credentials

### 1. Google OAuth Client Credentials (`client_secret.json`)
**Location:** `src/main/webapp/WEB-INF/classes/client_secret.json`

**Format:**
```json
{
  "web": {
    "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
    "project_id": "your-project-id",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_secret": "YOUR_CLIENT_SECRET",
    "redirect_uris": ["http://localhost:8080/oauth2callback"]
  }
}
```

### 2. Google Service Account Credentials (`service-account.json`)
**Location:** `src/main/webapp/WEB-INF/classes/service-account.json`

**Format:** Download from Google Cloud Console → IAM & Admin → Service Accounts

### 3. OAuth Stored Credentials
**Location:** `src/main/webapp/WEB-INF/classes/credentials/StoredCredential`

**Note:** This file is auto-generated after first OAuth authentication. Do NOT commit this file.

## Setup Instructions

### Option 1: Local Development (File-based)

1. **Obtain credentials from Google Cloud Console:**
   - Go to https://console.cloud.google.com
   - Create or select your project
   - Enable YouTube Data API v3
   - Create OAuth 2.0 Client ID (Web application)
   - Create Service Account and download JSON key

2. **Place credential files:**
   ```bash
   # OAuth client credentials
   cp /path/to/your/client_secret.json src/main/webapp/WEB-INF/classes/client_secret.json
   
   # Service account credentials
   cp /path/to/your/service-account.json src/main/webapp/WEB-INF/classes/service-account.json
   ```

3. **Create credentials directory:**
   ```bash
   mkdir -p src/main/webapp/WEB-INF/classes/credentials
   ```

### Option 2: Production Deployment (Environment Variables)

Set the following environment variables:

```bash
# Google OAuth Client ID
export GOOGLE_CLIENT_ID="YOUR_CLIENT_ID.apps.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="YOUR_CLIENT_SECRET"
export GOOGLE_REDIRECT_URI="https://yourdomain.com/oauth2callback"

# Google Service Account (JSON as string or base64 encoded)
export GOOGLE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'

# Or use base64 encoded
export GOOGLE_SERVICE_ACCOUNT_BASE64="base64_encoded_json_here"
```

### Option 3: Using Docker Secrets or Kubernetes Secrets

For containerized deployments, mount secrets as files:

```yaml
# docker-compose.yml
services:
  app:
    volumes:
      - ./secrets/client_secret.json:/app/WEB-INF/classes/client_secret.json:ro
      - ./secrets/service-account.json:/app/WEB-INF/classes/service-account.json:ro
```

## Security Best Practices

1. **Never commit credential files to version control**
2. **Use environment-specific credentials** (dev, staging, production)
3. **Rotate credentials regularly**
4. **Use least-privilege service accounts**
5. **Enable audit logging for credential access**
6. **Store production credentials in a secure vault** (e.g., HashiCorp Vault, AWS Secrets Manager, Azure Key Vault)

## Verification

After setting up credentials, verify the configuration:

1. Start the application
2. Check logs for credential loading errors
3. Test OAuth flow by accessing YouTube integration features
4. Verify service account can upload videos

## Troubleshooting

### Error: "client_secret.json not found"
- Ensure the file exists at `src/main/webapp/WEB-INF/classes/client_secret.json`
- Check file permissions

### Error: "Invalid OAuth credentials"
- Verify client_id and client_secret are correct
- Check redirect_uri matches Google Cloud Console configuration
- Ensure OAuth consent screen is properly configured

### Error: "Service account authentication failed"
- Verify service account JSON is valid
- Check service account has necessary API permissions
- Ensure YouTube Data API v3 is enabled

## Contact

For credential access or issues, contact the project administrator.
