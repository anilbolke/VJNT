# Manual Build & Deployment Steps

## Problem
The old compiled classes in ROOT.war are incompatible with Java 21. We need to clean and rebuild.

## Solution: Step-by-Step Guide

### Step 1: In Eclipse - Clean the Project
```
1. Click on "VJNT Class Management" project in Project Explorer
2. Go to Menu: Project → Clean...
3. Select "Clean all projects"
4. Click "Clean" button
5. Wait for build to complete (check bottom right)
   Should say: "Build complete" ✓
```

### Step 2: Verify Compilation
After cleaning, Eclipse will automatically rebuild. Check:
```
In Eclipse, bottom right corner:
"0 errors, 0 warnings" ✓ (or just warnings, that's OK)
```

### Step 3: Check Compiled Classes
Open File Explorer and verify:
```
C:\Users\Admin\V2Project\VJNT Class Managment\build\classes\
  └─ com\vjnt\servlet\
     └─ PublicSchoolLookupServlet.class ✓ (should exist and be recent)
```

### Step 4: Stop Tomcat
```
In Windows:
1. Open Task Manager (Ctrl+Shift+Esc)
2. Find "java.exe" or "Apache Tomcat"
3. Right-click → End Task
4. Wait for it to close
```

### Step 5: Clean Tomcat Deployment
```
In File Explorer, navigate to:
D:\apache-tomcat-9.0.100\webapps\

Delete:
  - ROOT.war (if exists)
  - ROOT folder (if exists)
```

### Step 6: Build WAR File
```
1. Open Command Prompt (Win+R → cmd → Enter)
2. Navigate to project:
   cd "C:\Users\Admin\V2Project\VJNT Class Managment"

3. Run build script:
   BUILD_WAR_ECLIPSE.bat

4. Wait for completion message:
   "Build Complete!" ✓

5. Verify ROOT.war exists:
   dir ROOT.war
```

### Step 7: Deploy to Tomcat
```
1. Copy ROOT.war:
   - From: C:\Users\Admin\V2Project\VJNT Class Managment\ROOT.war
   - To: D:\apache-tomcat-9.0.100\webapps\

2. Start Tomcat:
   - Run: D:\apache-tomcat-9.0.100\bin\catalina.bat start
   - Or double-click the batch file

3. Wait 10-15 seconds for startup
```

### Step 8: Test the Page
```
Open web browser and navigate to:
http://localhost:8080/VJNT_Class_Managment/public-school-lookup?udise=27150201202

Expected:
✓ Professional header with navigation
✓ School information displays
✓ No 404 errors
✓ No Java errors
✓ Beautiful design loads
```

## Quick Deployment Script (Alternative)

Instead of manual steps, you can use the automated script:

```powershell
# Open PowerShell as Administrator
# Navigate to project directory
cd "C:\Users\Admin\V2Project\VJNT Class Managment"

# Run the deployment script
.\REBUILD_AND_DEPLOY.ps1
```

The script will:
1. Stop Tomcat
2. Clean old build files
3. Prompt you to clean in Eclipse
4. Build new WAR file
5. Deploy to Tomcat
6. Start Tomcat

## Troubleshooting

### Issue: "Build/classes directory not found"
```
Solution:
1. In Eclipse, right-click project → Build Project
2. Wait for completion
3. Check if build/classes folder is created
4. If not, check Eclipse console for errors
```

### Issue: "Invalid byte tag in constant pool"
```
Solution: This means old Java class files are still there
1. Close Eclipse
2. Delete C:\Users\Admin\V2Project\VJNT Class Managment\build folder
3. Reopen Eclipse
4. Eclipse will auto-rebuild
5. Check build\classes folder for .class files
```

### Issue: ROOT.war is too large (>200MB)
```
Solution: WAR has old unused files
1. Delete build\war folder
2. Run BUILD_WAR_ECLIPSE.bat again
3. It should be 10-50MB
```

### Issue: Page still shows 404
```
Check Tomcat logs:
D:\apache-tomcat-9.0.100\logs\catalina.out

Look for:
"Deploying web application archive [ROOT.war]" ✓
"Deployment finished"

If not found, ROOT.war wasn't deployed properly
Try:
1. Stop Tomcat (Task Manager)
2. Check D:\apache-tomcat-9.0.100\webapps\ROOT folder exists
3. Restart Tomcat
4. Wait 30 seconds before testing
```

### Issue: Page loads but shows "School not found"
```
This is OK! The UDISE query parameter is empty
Test with a valid UDISE:
http://localhost:8080/VJNT_Class_Managment/public-school-lookup?udise=27150201202

If it still doesn't work, check:
1. Database connection (check server logs)
2. School exists in database with that UDISE
```

## Verification Checklist

After deployment, verify:
- [ ] Tomcat started without errors
- [ ] Page loads (no 404 error)
- [ ] Header and navigation visible
- [ ] School details display
- [ ] Contact cards show
- [ ] Images load
- [ ] Responsive on mobile (resize browser)
- [ ] Click image for full screen works
- [ ] No errors in browser console (F12)

## Summary

The process:
1. Clean in Eclipse (Project → Clean)
2. Stop Tomcat
3. Delete old ROOT.war and ROOT folder
4. Run BUILD_WAR_ECLIPSE.bat
5. Copy ROOT.war to webapps
6. Start Tomcat
7. Test in browser

**Estimated time: 2-3 minutes**

Good luck! 🚀
