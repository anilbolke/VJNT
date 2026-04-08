# MANUAL REBUILD STEPS FOR PUBLIC SCHOOL LOOKUP

## What was done:
- Created PublicSchoolLookupServlet.java (displays HTML page)
- Created SchoolLookupApiServlet.java (serves JSON API)
- Reverted previous defensive fixes

## What you need to do NOW:

### STEP 1: Tell Eclipse to rebuild
```
1. Open Eclipse
2. Right-click on "VJNT Class Management" project
3. Select: Project → Clean...
4. Click "Clean all projects"
5. Wait for bottom-right to say: "Build complete"
   (you'll see a small checkmark or "Build complete" message)
```

### STEP 2: Verify new files are compiled
```
1. In Eclipse, expand: VJNT Class Management → build → classes → com → vjnt → servlet
2. You should see these new .class files:
   - PublicSchoolLookupServlet.class
   - SchoolLookupApiServlet.class
   (They should have today's timestamp if just compiled)
```

### STEP 3: Stop Tomcat
```
Option A - Task Manager:
  Press: Ctrl+Shift+Esc
  Find: java.exe
  Right-click: End Task
  Wait: 5 seconds

Option B - Command Prompt:
  D:\apache-tomcat-9.0.100\bin\catalina.bat stop
  Wait: 5 seconds
```

### STEP 4: Delete old deployment files
```
File Explorer:
  Go to: D:\apache-tomcat-9.0.100\webapps\
  
  Delete:
    ❌ ROOT.war (if exists)
    ❌ ROOT folder (entire folder)
    
  Wait: 5 seconds
```

### STEP 5: Copy new code to Tomcat
```
From Explorer:
  Source: C:\Users\Admin\V2Project\VJNT Class Managment\src\main\webapp
  Destination: D:\apache-tomcat-9.0.100\webapps\ROOT
  
  Action: Copy everything (paste into webapps\ROOT folder)
  
Copy compiled classes:
  Source: C:\Users\Admin\V2Project\VJNT Class Managment\build\classes
  Destination: D:\apache-tomcat-9.0.100\webapps\ROOT\WEB-INF\classes
  
  Action: Copy everything
```

### STEP 6: Copy credential file
```
If exists: C:\Users\Admin\V2Project\VJNT Class Managment\src\main\resources\client_secret.json
Copy to: D:\apache-tomcat-9.0.100\webapps\ROOT\WEB-INF\classes\client_secret.json
```

### STEP 7: Start Tomcat
```
Command Prompt:
  D:\apache-tomcat-9.0.100\bin\catalina.bat start
  Wait: 15 seconds for startup messages
```

### STEP 8: TEST
```
Open Browser:
  http://localhost:8080/VJNT_Class_Managment/public-school-lookup?udise=27150408704

You should see:
  ✓ Header with navigation
  ✓ Hero section with title
  ✓ School information loading
  ✓ Contact details
  ✓ Palak Melava section
  ✓ Activities section
  ✓ Professional design
  ✓ NO 404 errors
  ✓ NO JavaScript errors (F12 to check)
```

## TROUBLESHOOTING

If you get 404 still:
- Ensure Eclipse finished building (check .class file timestamps)
- Ensure new files copied to webapps\ROOT\WEB-INF\classes
- Check Tomcat is running (tasklist | find java)
- Check Tomcat logs: D:\apache-tomcat-9.0.100\logs\catalina.out

If you get errors in Tomcat log:
- Check client_secret.json is in WEB-INF/classes
- Check web.xml has proper servlet mappings
- Restart Tomcat after fixing

## FILES CREATED

New Java files to compile:
- src/main/java/com/vjnt/servlet/PublicSchoolLookupServlet.java
- src/main/java/com/vjnt/servlet/SchoolLookupApiServlet.java

These should auto-compile when you "Clean" the project in Eclipse.
