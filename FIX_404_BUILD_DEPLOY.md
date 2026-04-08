# Fix 404 Error - Build & Deploy Guide

## Problem
The code changes aren't deployed yet. The ROOT.war file contains old compiled classes that are incompatible with Java 21.

Error message:
```
HTTP Status 404 – Not Found
The requested resource [/VJNT_Class_Managment/public-school-lookup] is not available
```

## Root Cause
- Eclipse hasn't compiled the modified servlet yet
- OLD ROOT.war file in Tomcat contains incompatible Java classes
- Tomcat shows error: "Invalid byte tag in constant pool: 108"

## Solution: Clean Build & Deploy

### Quick Path (Use Script)
```powershell
# Open PowerShell as Administrator
cd "C:\Users\Admin\V2Project\VJNT Class Managment"
.\REBUILD_AND_DEPLOY.ps1
```

The script will guide you through the process automatically.

### Manual Path (Step-by-Step)

#### 1. Clean Eclipse Project
```
In Eclipse:
Menu → Project → Clean...
Select: "Clean all projects"
Click: Clean
Wait: Build complete
```

#### 2. Stop Tomcat
```
Windows Task Manager (Ctrl+Shift+Esc)
Find: java.exe
Right-click → End Task
Wait: 3 seconds
```

#### 3. Delete Old Deployment
```
File Explorer:
D:\apache-tomcat-9.0.100\webapps\
Delete:
  ✓ ROOT.war (if exists)
  ✓ ROOT folder (if exists)
```

#### 4. Build New WAR
```
Command Prompt:
cd "C:\Users\Admin\V2Project\VJNT Class Managment"
BUILD_WAR_ECLIPSE.bat
Wait: "Build Complete!" message
```

#### 5. Deploy to Tomcat
```
Copy ROOT.war from:
  From: C:\Users\Admin\V2Project\VJNT Class Managment\ROOT.war
  To: D:\apache-tomcat-9.0.100\webapps\
```

#### 6. Start Tomcat
```
Option A - Batch file:
  D:\apache-tomcat-9.0.100\bin\catalina.bat start

Option B - Command Prompt:
  cd D:\apache-tomcat-9.0.100\bin
  catalina.bat start

Wait: 10-15 seconds for startup
```

#### 7. Test
```
Open browser:
http://localhost:8080/VJNT_Class_Managment/public-school-lookup?udise=27150201202

Expected Results:
✅ Professional header with navigation
✅ Hero section displays
✅ School details show
✅ Contact cards visible
✅ Beautiful design loads
✅ No 404 error
✅ No Java errors
```

## Verification

### Check if Tomcat is running:
```
Open: http://localhost:8080
Should see: Tomcat default page
```

### Check ROOT.war deployment:
```
File Explorer:
D:\apache-tomcat-9.0.100\webapps\ROOT\
Should see: Multiple folders (js, css, WEB-INF, etc.)
```

### Check Tomcat logs:
```
D:\apache-tomcat-9.0.100\logs\catalina.out

Look for (should find both):
✓ "Deploying web application archive [D:/.../ROOT.war]"
✓ "Deployment of web application archive [ROOT.war] has finished"
✓ No "SEVERE" errors
```

## Expected Error Messages (These are OK)

```
⚠ "At least one JAR was scanned for TLDs yet contained no TLDs"
→ This is harmless, just a warning

⚠ "ContextListener: contextInitialized()"
→ This is normal startup
```

## Expected Error Messages (These mean FAILURE)

```
🔴 "ClassFormatException: Invalid byte tag in constant pool"
→ Need to rebuild (old Java classes)

🔴 "[ROOT.war] has started in ERROR"
→ Build failed, check logs

🔴 "Cannot find resource [/VJNT_Class_Managment/public-school-lookup]"
→ Servlet not compiled, rebuild Eclipse
```

## Timeline

| Step | Time | Action |
|------|------|--------|
| 1 | 1 min | Clean in Eclipse |
| 2 | 1 min | Stop Tomcat |
| 3 | 1 min | Delete old files |
| 4 | 3 min | Build WAR file |
| 5 | 1 min | Copy to webapps |
| 6 | 15 sec | Start Tomcat |
| 7 | 1 min | Test in browser |
| **Total** | **8-10 min** | **Complete!** |

## If Something Goes Wrong

### Symptom: Still getting 404
```
1. Check Tomcat logs (catalina.out)
2. Verify ROOT.war exists in webapps
3. Verify ROOT folder exists in webapps
4. Try stopping Tomcat and deleting ROOT folder
5. Restart and let Tomcat extract WAR again
6. Wait 30 seconds before testing
```

### Symptom: ClassFormatException in logs
```
1. Delete build\classes folder
2. Clean Project in Eclipse (Project → Clean)
3. Wait for recompilation
4. Run BUILD_WAR_ECLIPSE.bat
5. Deploy again
```

### Symptom: BUILD_WAR_ECLIPSE.bat fails
```
1. Ensure Eclipse has finished building
2. Check build\classes folder exists
3. Check build\classes\com\vjnt\servlet\ has .class files
4. If missing, right-click project in Eclipse → Build Project
5. Then retry BUILD_WAR_ECLIPSE.bat
```

## Documents Created
- `REBUILD_AND_DEPLOY.ps1` - Automated script
- `MANUAL_BUILD_STEPS.md` - Detailed manual steps
- `FIX_404_BUILD_DEPLOY.md` - This guide

## Summary

**The Fix:**
1. Clean build in Eclipse
2. Stop Tomcat
3. Delete old ROOT.war
4. Build new WAR file
5. Deploy and restart Tomcat

**Result:** Your professional website design will be live! 🎉

---

**Next Step:** Choose either the automated script or manual steps above and get the page deployed!

**Estimated Time:** 8-10 minutes

**Difficulty:** Easy (just following steps)

Let me know if you hit any issues! 💪
