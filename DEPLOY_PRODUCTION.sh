#!/bin/bash
# ============================================
# Production Deployment Script for Linux
# Run this on your production server
# ============================================

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  Deploying ROOT.war to Production                                 ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if ROOT.war exists in current directory
if [ ! -f "ROOT.war" ]; then
    echo "✗ ERROR: ROOT.war not found in current directory"
    echo ""
    echo "Please upload ROOT.war first:"
    echo "  scp target/ROOT.war root@YOUR_SERVER_IP:/tmp/"
    echo ""
    exit 1
fi

echo "✓ ROOT.war found"
echo ""

# Step 1: Stop Tomcat
echo "[Step 1/5] Stopping Tomcat..."
/opt/apache-tomcat-9/bin/shutdown.sh
sleep 5

# Check if Tomcat stopped
if pgrep -f tomcat > /dev/null; then
    echo "⚠ Tomcat still running, forcing shutdown..."
    pkill -9 -f tomcat
    sleep 2
fi
echo "✓ Tomcat stopped"
echo ""

# Step 2: Backup old deployment
echo "[Step 2/5] Backing up old deployment..."
if [ -f "/opt/apache-tomcat-9/webapps/ROOT.war" ]; then
    BACKUP_NAME="ROOT.war.backup.$(date +%Y%m%d_%H%M%S)"
    mv /opt/apache-tomcat-9/webapps/ROOT.war "/opt/apache-tomcat-9/webapps/$BACKUP_NAME"
    echo "✓ Old WAR backed up as: $BACKUP_NAME"
fi

if [ -d "/opt/apache-tomcat-9/webapps/ROOT" ]; then
    rm -rf /opt/apache-tomcat-9/webapps/ROOT
    echo "✓ Old ROOT directory removed"
fi
echo ""

# Step 3: Deploy new WAR
echo "[Step 3/5] Deploying new WAR..."
cp ROOT.war /opt/apache-tomcat-9/webapps/
chown tomcat:tomcat /opt/apache-tomcat-9/webapps/ROOT.war 2>/dev/null || true
chmod 644 /opt/apache-tomcat-9/webapps/ROOT.war
echo "✓ New WAR deployed"
echo ""

# Step 4: Verify client_secret.json is in WAR
echo "[Step 4/5] Verifying client_secret.json in WAR..."
if jar tf /opt/apache-tomcat-9/webapps/ROOT.war | grep -q "client_secret.json"; then
    echo "✓ client_secret.json found in WAR:"
    jar tf /opt/apache-tomcat-9/webapps/ROOT.war | grep "client_secret.json"
else
    echo "✗ WARNING: client_secret.json NOT found in WAR!"
    echo ""
    echo "The WAR was deployed but client_secret.json is missing."
    echo "YouTube upload will not work."
    echo ""
    echo "Solution: Rebuild WAR on development machine using BUILD_AND_DEPLOY.bat"
    echo ""
fi
echo ""

# Step 5: Start Tomcat
echo "[Step 5/5] Starting Tomcat..."
/opt/apache-tomcat-9/bin/startup.sh
echo "✓ Tomcat started"
echo ""

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  Deployment Complete!                                              ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Checking logs for successful startup..."
echo ""
echo "Run this command to watch logs:"
echo "  tail -f /opt/apache-tomcat-9/logs/catalina.out"
echo ""
echo "Look for these messages:"
echo "  ✓ SUCCESS: Found client_secret.json in classpath"
echo "  ✓ Database connection successful"
echo ""
echo "Wait 30-60 seconds for full deployment, then test the application."
echo ""
