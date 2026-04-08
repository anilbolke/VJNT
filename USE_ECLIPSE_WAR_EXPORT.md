# Quick summary of the issue and solution

The problem is:
- Tomcat has a ROOT folder (manually extracted webapp files) + ROOT.war conflicting
- The @WebServlet annotations in PublicSchoolLookupServlet and SchoolLookupApiServlet are not being processed
- Tomcat is not scanning the deployed directory for annotated servlets

The solution is to properly package everything into a WAR and let Tomcat expand it fresh.

Since the build directory has everything, we can create a WAR properly:

## Option 1: Use Eclipse to export WAR
1. Right-click project in Eclipse → Export → WAR file
2. Save to: D:\apache-tomcat-9.0.100\webapps\ROOT.war
3. Restart Tomcat

## Option 2: Manual WAR creation (if you have jar.exe)
1. Stop Tomcat
2. Delete D:\apache-tomcat-9.0.100\webapps\ROOT* (folder and war)
3. cd C:\Users\Admin\V2Project\VJNT Class Managment\build
4. jar cvf ..\ROOT.war *
5. Copy ROOT.war to D:\apache-tomcat-9.0.100\webapps\
6. Start Tomcat

## Best option right now: Use Eclipse Export WAR

Open Eclipse → Right-click "VJNT Class Management" project → Export → WAR file → 
- File: D:\apache-tomcat-9.0.100\webapps\ROOT.war
- Click Export
- Restart Tomcat

The WAR export will handle:
- Proper packaging of src/main/webapp files
- Correct WEB-INF structure
- All compiled classes in right location  
- Annotation processing by Tomcat

Then test: http://localhost:8080/public-school-lookup?udise=27150408704
