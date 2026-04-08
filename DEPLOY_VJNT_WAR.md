# DEPLOYMENT STEPS - PUBLIC SCHOOL LOOKUP

## Problem Identified:
- VJNT_Class_Managment app is NOT deployed in Tomcat
- URL tries to access `/VJNT_Class_Managment/public-school-lookup` but the context doesn't exist
- There's a correct ROOT.war (52 MB) in the project, but Tomcat has an old ROOT.war (3.5 MB)

## Solution:
Deploy the correct ROOT.war from the project to Tomcat

## Steps:

### STEP 1: Stop Tomcat
```powershell
# Get Java process ID
Get-Process java -ErrorAction SilentlyContinue | Select-Object Id

# Stop it (use the ID from above)
Stop-Process -Id 30076 -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5
```

### STEP 2: Delete old Tomcat deployment
```
File Explorer:
  Go to: D:\apache-tomcat-9.0.100\webapps\
  Delete:
    ❌ ROOT.war
    ❌ ROOT folder (entire directory)
  Wait: 5 seconds
```

### STEP 3: Copy new WAR to Tomcat
```
Copy from: C:\Users\Admin\V2Project\VJNT Class Managment\ROOT.war
Paste to: D:\apache-tomcat-9.0.100\webapps\ROOT.war
```

### STEP 4: Start Tomcat
```cmd
D:\apache-tomcat-9.0.100\bin\catalina.bat start
```
Wait 15-20 seconds for startup.

### STEP 5: TEST
```
Browser:
  http://localhost:8080/VJNT_Class_Managment/public-school-lookup?udise=27150408704
```

You should see:
✅ Page loads (no 404)
✅ Header and navigation
✅ School information loading
✅ Professional design

## Important Notes:
- This ROOT.war is 52 MB (large because it's the complete VJNT project)
- It contains the newly compiled PublicSchoolLookupServlet and SchoolLookupApiServlet
- The URL path `/VJNT_Class_Managment/` matches the context in this WAR
- Make sure Tomcat fully starts before testing (wait 15-20 seconds)

## If you get 404 again:
1. Check Tomcat logs: `D:\apache-tomcat-9.0.100\logs\catalina.out`
2. Make sure ROOT folder exists in webapps
3. Make sure Java process is running
4. Try hard refresh: `Ctrl+Shift+R` in browser
5. Wait longer for Tomcat to fully initialize
