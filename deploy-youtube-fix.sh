#!/bin/bash
# ============================================
# Complete YouTube Upload Fix - Production Deployment
# Run this script on your production server
# ============================================

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  YouTube Upload Fix - Production Deployment                       ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Check if credentials zip exists
if [ ! -f "/tmp/youtube-credentials.zip" ]; then
    echo "✗ ERROR: youtube-credentials.zip not found in /tmp/"
    echo ""
    echo "Please upload the credentials first:"
    echo "  scp youtube-credentials.zip root@YOUR_SERVER:/tmp/"
    echo ""
    exit 1
fi

echo "✓ Found youtube-credentials.zip"
echo ""

# Step 2: Stop Tomcat
echo "[Step 1/6] Stopping Tomcat..."
/opt/apache-tomcat-9/bin/shutdown.sh
sleep 5

# Force kill if still running
if pgrep -f tomcat > /dev/null; then
    echo "  ⚠ Tomcat still running, forcing shutdown..."
    pkill -9 -f tomcat
    sleep 2
fi
echo "✓ Tomcat stopped"
echo ""

# Step 3: Extract credentials to Tomcat directory
echo "[Step 2/6] Extracting credentials..."
cd /opt/apache-tomcat-9
unzip -o /tmp/youtube-credentials.zip

# Check if extracted correctly
if [ -f "/opt/apache-tomcat-9/credentials/StoredCredential" ]; then
    echo "✓ Credentials extracted successfully"
    echo "  Location: /opt/apache-tomcat-9/credentials/StoredCredential"
else
    echo "✗ ERROR: StoredCredential not found after extraction!"
    exit 1
fi
echo ""

# Step 4: Set proper permissions
echo "[Step 3/6] Setting permissions..."
chown -R tomcat:tomcat /opt/apache-tomcat-9/credentials/ 2>/dev/null || chown -R root:root /opt/apache-tomcat-9/credentials/
chmod -R 755 /opt/apache-tomcat-9/credentials/
chmod 644 /opt/apache-tomcat-9/credentials/StoredCredential
echo "✓ Permissions set"
echo ""

# Step 5: Check if ROOT.war exists
echo "[Step 4/6] Checking for ROOT.war..."
if [ ! -f "/tmp/ROOT.war" ]; then
    echo "⚠ WARNING: ROOT.war not found in /tmp/"
    echo ""
    echo "Please upload your WAR file:"
    echo "  1. Run COPY_CLIENT_SECRET.bat on local machine"
    echo "  2. Export ROOT.war from Eclipse"
    echo "  3. scp ROOT.war root@YOUR_SERVER:/tmp/"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✓ Found ROOT.war"
echo ""

# Step 6: Deploy WAR
echo "[Step 5/6] Deploying ROOT.war..."
rm -rf /opt/apache-tomcat-9/webapps/ROOT*
cp /tmp/ROOT.war /opt/apache-tomcat-9/webapps/
chown tomcat:tomcat /opt/apache-tomcat-9/webapps/ROOT.war 2>/dev/null || true
echo "✓ WAR deployed"
echo ""

# Step 7: Start Tomcat
echo "[Step 6/6] Starting Tomcat..."
/opt/apache-tomcat-9/bin/startup.sh
echo "✓ Tomcat started"
echo ""

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  Deployment Complete!                                              ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Waiting 10 seconds for Tomcat to start..."
sleep 10
echo ""

echo "Checking deployment status..."
echo ""

# Check if credentials exist
if [ -f "/opt/apache-tomcat-9/credentials/StoredCredential" ]; then
    echo "✓ Credentials: OK"
else
    echo "✗ Credentials: NOT FOUND"
fi

# Check if WAR is deployed
if [ -d "/opt/apache-tomcat-9/webapps/ROOT" ]; then
    echo "✓ WAR deployment: OK"
else
    echo "⚠ WAR deployment: IN PROGRESS (wait a moment)"
fi

# Check if client_secret.json is in WAR
if [ -f "/opt/apache-tomcat-9/webapps/ROOT/WEB-INF/classes/client_secret.json" ]; then
    echo "✓ client_secret.json: FOUND in WAR"
else
    echo "✗ client_secret.json: NOT FOUND in WAR"
    echo "  You need to run COPY_CLIENT_SECRET.bat before exporting WAR!"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  Next Steps                                                        ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "1. Watch the logs for startup completion:"
echo "   tail -f /opt/apache-tomcat-9/logs/catalina.out"
echo ""
echo "2. Look for these SUCCESS messages:"
echo "   ✓ SUCCESS: Found client_secret.json in classpath"
echo "   ✓ Using existing stored credentials (refresh token found)"
echo ""
echo "3. Test YouTube upload through your application"
echo "   It should work without 502 errors!"
echo ""
echo "4. If you see errors about client_secret.json missing:"
echo "   - Re-run COPY_CLIENT_SECRET.bat on local machine"
echo "   - Export new ROOT.war from Eclipse"
echo "   - Upload and deploy again"
echo ""
