# 🚀 VJNT Login System - Step-by-Step Execution Guide

## Complete Setup and Testing Instructions

---

## 📋 PREREQUISITES CHECKLIST

Before you begin, ensure you have:

- [ ] Java Development Kit (JDK) 8 or higher installed
- [ ] Apache Tomcat 9.0+ installed
- [ ] MySQL 8.0+ installed and running
- [ ] Maven 3.6+ installed (optional, for building)
- [ ] Eclipse IDE (your project is already in Eclipse)
- [ ] Excel file accessible at: `C:\Users\Admin\V2Project\VJNT Class Managment\src\main\webapp\Document\V2 Sample Format Data Entry for Anil.xlsx`

---

## STEP 1: VERIFY PROJECT STRUCTURE ✅

Your project now has the following structure:

```
C:\Users\Admin\V2Project\VJNT Class Managment\
├── src/main/
│   ├── java/com/vjnt/
│   │   ├── model/
│   │   │   ├── User.java                    ✅ Created
│   │   │   └── LoginAudit.java              ✅ Created
│   │   ├── dao/
│   │   │   └── UserDAO.java                 ✅ Created
│   │   ├── servlet/
│   │   │   ├── LoginServlet.java            ✅ Created
│   │   │   ├── ChangePasswordServlet.java   ✅ Created
│   │   │   └── LogoutServlet.java           ✅ Created
│   │   └── util/
│   │       ├── DatabaseConnection.java      ✅ Created
│   │       ├── PasswordUtil.java            ✅ Created
│   │       └── ExcelUserLoader.java         ✅ Created
│   └── webapp/
│       ├── login.jsp                        ✅ Created
│       ├── change-password.jsp              ✅ Created
│       ├── dashboard.jsp                    ✅ Created
│       └── WEB-INF/web.xml                  (Existing)
├── database_schema.sql                       ✅ Created
├── pom.xml                                   ✅ Created
└── README.md                                 ✅ Created
```

---

## STEP 2: DATABASE SETUP 🗄️

### 2.1 Open MySQL Command Line or Workbench

**Option A: MySQL Command Line**
```bash
mysql -u root -p
```

**Option B: MySQL Workbench**
- Open MySQL Workbench
- Connect to your local MySQL server

### 2.2 Create Database

Execute the following commands:

```sql
-- Create database
CREATE DATABASE vjnt_class_management;

-- Use the database
USE vjnt_class_management;

-- Verify database is selected
SELECT DATABASE();
```

Expected output: `vjnt_class_management`

### 2.3 Run Schema Script

**Option A: From Command Line**
```sql
SOURCE C:/Users/Admin/V2Project/VJNT Class Managment/database_schema.sql;
```

**Option B: Copy and Paste**
- Open the `database_schema.sql` file
- Copy all contents
- Paste into MySQL console and execute

### 2.4 Verify Tables Created

```sql
-- Show all tables
SHOW TABLES;

-- Should show:
-- +------------------------------------+
-- | Tables_in_vjnt_class_management   |
-- +------------------------------------+
-- | login_audit                        |
-- | users                              |
-- +------------------------------------+

-- Check users table structure
DESCRIBE users;

-- Check if default admin user was created
SELECT user_id, username, user_type FROM users;
```

Expected: 1 row with admin user

---

## STEP 3: CONFIGURE DATABASE CONNECTION 🔧

### 3.1 Update Database Credentials

Open file: `src\main\java\com\vjnt\util\DatabaseConnection.java`

Update these lines (around line 14-16):

```java
private static final String DB_URL = "jdbc:mysql://localhost:3306/vjnt_class_management";
private static final String DB_USER = "root";  // Change if different
private static final String DB_PASSWORD = "your_password";  // YOUR MySQL password
```

**Example**:
```java
private static final String DB_URL = "jdbc:mysql://localhost:3306/vjnt_class_management";
private static final String DB_USER = "root";
private static final String DB_PASSWORD = "admin123";  // Your actual MySQL password
```

### 3.2 Test Database Connection

**From Eclipse:**
1. Right-click on `DatabaseConnection.java`
2. Select `Run As` → `Java Application`
3. Check console output

Expected output:
```
Testing database connection...
Database driver loaded successfully
✓ Database connection successful!
```

If connection fails, verify:
- MySQL is running
- Username and password are correct
- Database `vjnt_class_management` exists

---

## STEP 4: ADD MAVEN DEPENDENCIES (Eclipse) 📦

### 4.1 Refresh Maven Project

1. Right-click on project name in Eclipse
2. Select `Maven` → `Update Project`
3. Check "Force Update of Snapshots/Releases"
4. Click OK

### 4.2 Verify Dependencies Downloaded

Check `Maven Dependencies` in Eclipse Project Explorer:
- javax.servlet-api
- mysql-connector-java
- Apache POI libraries
- slf4j libraries

If any issues:
```bash
# From project directory
mvn clean install
```

---

## STEP 5: LOAD USERS FROM EXCEL 📊

### 5.1 Verify Excel File Path

The ExcelUserLoader is configured to read:
```
C:\Users\Admin\V2Project\VJNT Class Managment\src\main\webapp\Document\V2 Sample Format Data Entry for Anil.xlsx
```

If your file is at a different location, update line 167 in `ExcelUserLoader.java`:
```java
String excelPath = "YOUR_ACTUAL_PATH";
```

### 5.2 Run Excel User Loader

**From Eclipse:**
1. Open `src\main\java\com\vjnt\util\ExcelUserLoader.java`
2. Right-click in editor
3. Select `Run As` → `Java Application`

### 5.3 Expected Output

```
========================================
Starting Excel User Loader
========================================
File: C:\Users\Admin\V2Project\VJNT Class Managment\src\main\webapp\Document\V2 Sample Format Data Entry for Anil.xlsx
Total rows in Excel: 213

✓ Created Division user: div_latur_division

✓ Created District Coordinator: dist_coord_dharashiv
✓ Created District 2nd Coordinator: dist_coord2_dharashiv
✓ Created District Coordinator: dist_coord_hingoli
✓ Created District 2nd Coordinator: dist_coord2_hingoli
✓ Created District Coordinator: dist_coord_nanded
✓ Created District 2nd Coordinator: dist_coord2_nanded
✓ Created District Coordinator: dist_coord_latur
✓ Created District 2nd Coordinator: dist_coord2_latur

✓ Created School Coordinator: school_coord_10001 (UDISE: 10001)
✓ Created Head Master: headmaster_10001 (UDISE: 10001)
... (and so on for all 60 UDISE numbers)

========================================
USER CREATION SUMMARY
========================================
Unique Divisions Processed: 1
Unique Districts Processed: 4
Unique UDISE Numbers Processed: 60
----------------------------------------
Expected Users:
  - Division logins: 1
  - District logins: 8
  - UDISE logins: 120
  - TOTAL EXPECTED: 129
----------------------------------------
Total Users Created: 129
========================================

Default Password for all users: Pass@123
Users must change password on first login.
========================================
```

### 5.4 Verify Users in Database

```sql
-- Check total users created
SELECT COUNT(*) as total_users FROM users;
-- Expected: 130 (129 + 1 admin)

-- Check users by type
SELECT user_type, COUNT(*) as count 
FROM users 
GROUP BY user_type;

-- Expected output:
-- DIVISION: 1
-- DISTRICT_COORDINATOR: 4
-- DISTRICT_2ND_COORDINATOR: 4
-- SCHOOL_COORDINATOR: 60
-- HEAD_MASTER: 60

-- View sample users
SELECT user_id, username, user_type, division_name, district_name, udise_no 
FROM users 
LIMIT 10;
```

---

## STEP 6: DEPLOY TO TOMCAT 🚀

### 6.1 Build WAR File

**Option A: Eclipse**
1. Right-click on project
2. Select `Export` → `WAR file`
3. Choose destination: `C:\Users\Admin\vjnt-class-management.war`
4. Click Finish

**Option B: Maven**
```bash
cd "C:\Users\Admin\V2Project\VJNT Class Managment"
mvn clean package
# WAR file will be in target/vjnt-class-management.war
```

### 6.2 Deploy to Tomcat

1. Locate your Tomcat installation (e.g., `C:\Program Files\Apache Software Foundation\Tomcat 9.0\`)
2. Copy WAR file to `webapps` folder:
   ```
   Copy: C:\Users\Admin\V2Project\VJNT Class Managment\target\vjnt-class-management.war
   To: C:\Program Files\Apache Software Foundation\Tomcat 9.0\webapps\
   ```

### 6.3 Start Tomcat

**Windows:**
```bash
# Navigate to Tomcat bin folder
cd "C:\Program Files\Apache Software Foundation\Tomcat 9.0\bin"

# Start Tomcat
startup.bat
```

**Or use Eclipse:**
1. Window → Show View → Servers
2. Right-click on Tomcat server
3. Select "Start"

### 6.4 Verify Deployment

Watch console output for:
```
INFO: Deployment of web application directory [...\vjnt-class-management] has finished in [X] ms
```

---

## STEP 7: ACCESS THE APPLICATION 🌐

### 7.1 Open Browser

Navigate to:
```
http://localhost:8080/vjnt-class-management/login
```

### 7.2 You Should See

A beautiful login page with:
- VJNT Class Management System header
- Username field
- Password field
- Login button
- Default password information (Pass@123)

---

## STEP 8: TEST LOGINS 🧪

### 8.1 Test Division Login

**Credentials:**
- Username: `div_latur_division`
- Password: `Pass@123`

**Steps:**
1. Enter username and password
2. Click "Login"
3. You should be redirected to "Change Password" page
4. Enter current password: `Pass@123`
5. Enter new password (must meet requirements): `NewPass@123`
6. Confirm new password: `NewPass@123`
7. Click "Change Password"
8. You should see the dashboard

### 8.2 Test District Login

**Credentials:**
- Username: `dist_coord_dharashiv`
- Password: `Pass@123`

Follow same steps as above.

### 8.3 Test School Login

**Credentials:**
- Username: `school_coord_10001`
- Password: `Pass@123`

**Or:**
- Username: `headmaster_10001`
- Password: `Pass@123`

### 8.4 Test Invalid Credentials

Try logging in with:
- Wrong username
- Wrong password
- Locked account (after 5 failed attempts)

Verify appropriate error messages appear.

---

## STEP 9: VERIFY PASSWORD CHANGE FUNCTIONALITY 🔐

### 9.1 After First Login
- Verify user is forced to change password
- Cannot access dashboard without changing password

### 9.2 Password Validation Tests

Try setting passwords that:
- Are too short (< 8 characters) - Should fail
- Missing uppercase - Should fail
- Missing lowercase - Should fail
- Missing digit - Should fail
- Missing special character - Should fail
- Same as current password - Should fail
- Valid password - Should succeed

### 9.3 Verify in Database

After changing password:
```sql
SELECT username, is_first_login, must_change_password, password_changed_date
FROM users
WHERE username = 'div_latur_division';
```

Should show:
- `is_first_login`: 0 (FALSE)
- `must_change_password`: 0 (FALSE)
- `password_changed_date`: Current timestamp

---

## STEP 10: VERIFY SECURITY FEATURES 🔒

### 10.1 Test Account Lockout

1. Login with username: `dist_coord_hingoli`
2. Enter wrong password 5 times
3. Account should be locked
4. Verify error message: "Account locked due to multiple failed attempts"

**Check in database:**
```sql
SELECT username, failed_login_attempts, account_locked, locked_date
FROM users
WHERE username = 'dist_coord_hingoli';
```

### 10.2 Check Login Audit

```sql
SELECT * FROM login_audit
ORDER BY login_time DESC
LIMIT 10;
```

Should show all login attempts with status (SUCCESS/FAILED/LOCKED)

### 10.3 Test Session Timeout

1. Login successfully
2. Wait 30+ minutes (or change timeout in LoginServlet for testing)
3. Try to access a page
4. Should be redirected to login

---

## STEP 11: SAMPLE QUERIES FOR VERIFICATION 📊

### Get All Division Users
```sql
SELECT * FROM users WHERE user_type = 'DIVISION';
```

### Get All District Coordinators
```sql
SELECT username, district_name, user_type 
FROM users 
WHERE user_type IN ('DISTRICT_COORDINATOR', 'DISTRICT_2ND_COORDINATOR')
ORDER BY district_name, user_type;
```

### Get All School Users for Specific UDISE
```sql
SELECT username, user_type, udise_no, district_name
FROM users
WHERE udise_no = '10001';
```

### Get Users Who Haven't Changed Password
```sql
SELECT username, user_type, created_date
FROM users
WHERE is_first_login = TRUE OR must_change_password = TRUE;
```

### Get Recent Login Activity
```sql
SELECT u.username, u.user_type, la.login_time, la.login_status, la.ip_address
FROM login_audit la
JOIN users u ON la.user_id = u.user_id
ORDER BY la.login_time DESC
LIMIT 20;
```

### Get Locked Accounts
```sql
SELECT username, user_type, failed_login_attempts, locked_date
FROM users
WHERE account_locked = TRUE;
```

---

## STEP 12: TROUBLESHOOTING GUIDE 🔧

### Problem 1: Database Connection Failed

**Symptoms:** "Error connecting to database"

**Solutions:**
1. Check MySQL is running:
   ```bash
   # Windows
   net start MySQL80
   ```
2. Verify credentials in `DatabaseConnection.java`
3. Test connection:
   ```bash
   mysql -u root -p -h localhost
   ```
4. Check firewall settings

### Problem 2: Excel File Not Found

**Symptoms:** "FileNotFoundException" when running ExcelUserLoader

**Solutions:**
1. Verify file path in `ExcelUserLoader.java` line 167
2. Check file exists at specified location
3. Use absolute path with double backslashes: `C:\\Users\\Admin\\...`

### Problem 3: Users Not Created

**Symptoms:** ExcelUserLoader runs but 0 users created

**Solutions:**
1. Check database schema is created
2. Verify database connection works
3. Check Excel file has correct column structure (Division, Dist, UDISE NO in columns 1, 2, 3)
4. Check console for error messages

### Problem 4: Cannot Access Login Page

**Symptoms:** 404 Error when accessing http://localhost:8080/vjnt-class-management/login

**Solutions:**
1. Verify Tomcat is running
2. Check WAR file deployed correctly in webapps folder
3. Check Tomcat logs: `logs/catalina.out` or `logs/localhost.log`
4. Verify context path matches
5. Try: `http://localhost:8080/vjnt-class-management/` (with trailing slash)

### Problem 5: Login Failed with Correct Password

**Symptoms:** "Invalid username or password" with correct credentials

**Solutions:**
1. Verify user exists:
   ```sql
   SELECT * FROM users WHERE username = 'your_username';
   ```
2. Check account is not locked:
   ```sql
   SELECT account_locked FROM users WHERE username = 'your_username';
   ```
3. Verify account is active:
   ```sql
   SELECT is_active FROM users WHERE username = 'your_username';
   ```
4. Reset password if needed:
   ```sql
   UPDATE users 
   SET password = SHA2('Pass@123', 256),
       account_locked = FALSE,
       failed_login_attempts = 0
   WHERE username = 'your_username';
   ```

### Problem 6: Maven Dependencies Not Downloaded

**Symptoms:** Import errors in Java files

**Solutions:**
1. Right-click project → Maven → Update Project (Force Update)
2. Run from command line:
   ```bash
   mvn clean install -U
   ```
3. Check `pom.xml` for errors
4. Verify Maven settings.xml has correct repository URLs

### Problem 7: Tomcat Port Already in Use

**Symptoms:** "Port 8080 is already in use"

**Solutions:**
1. Change Tomcat port in `server.xml`
2. Or kill process using port 8080:
   ```bash
   # Windows
   netstat -ano | findstr :8080
   taskkill /PID <process_id> /F
   ```

---

## STEP 13: UNLOCK ACCOUNT (If Needed) 🔓

If you lock an account during testing:

```sql
-- Unlock specific user
UPDATE users 
SET account_locked = FALSE,
    failed_login_attempts = 0,
    locked_date = NULL
WHERE username = 'your_username';

-- Unlock all accounts (for testing)
UPDATE users 
SET account_locked = FALSE,
    failed_login_attempts = 0,
    locked_date = NULL;
```

---

## STEP 14: RESET PASSWORD (If Needed) 🔄

```sql
-- Reset to default password (Pass@123)
UPDATE users 
SET password = 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
    must_change_password = TRUE,
    is_first_login = TRUE
WHERE username = 'your_username';
```

Note: The hash is SHA-256 of "Pass@123"

---

## STEP 15: FINAL VERIFICATION CHECKLIST ✅

- [ ] Database created with all tables and views
- [ ] 129 users loaded from Excel (130 including admin)
- [ ] Can access login page at http://localhost:8080/vjnt-class-management/login
- [ ] Division user can login
- [ ] District coordinator can login
- [ ] School coordinator can login
- [ ] Head master can login
- [ ] First login forces password change
- [ ] Password strength validation works
- [ ] Account locks after 5 failed attempts
- [ ] Session timeout works (30 minutes)
- [ ] Logout works correctly
- [ ] Login audit records created
- [ ] Dashboard displays user information correctly

---

## 📊 COMPLETE STATISTICS

### Excel Data:
- Total Rows: 214
- Data Rows: 213
- Columns: 12

### Users Created:
- Divisions: 1
- Districts: 4
- UDISE Numbers: 60
- **Total Logins: 129**

### User Distribution:
```
Division Administrators:        1
District Coordinators:          4
District 2nd Coordinators:      4
School Coordinators:           60
Head Masters:                  60
─────────────────────────────────
TOTAL:                        129
```

---

## 🎓 CONCLUSION

If all steps completed successfully:

✅ **System is FULLY OPERATIONAL!**

You now have:
1. ✅ Complete database with 129+ users
2. ✅ Secure login system
3. ✅ Password management
4. ✅ Multi-level access control
5. ✅ Audit trail
6. ✅ Modern web interface

**Next Steps:**
- Add additional features (student management, reports, etc.)
- Customize dashboards for each user type
- Add more security features (email verification, 2FA, etc.)
- Deploy to production server

---

## 📞 QUICK REFERENCE

### Default Credentials:
```
All users: Password = Pass@123
Must change on first login
```

### Sample Usernames:
```
Division:        div_latur_division
District:        dist_coord_dharashiv
School:          school_coord_10001
Head Master:     headmaster_10001
```

### Important URLs:
```
Login:           http://localhost:8080/vjnt-class-management/login
Change Password: http://localhost:8080/vjnt-class-management/change-password
Dashboard:       http://localhost:8080/vjnt-class-management/dashboard.jsp
Logout:          http://localhost:8080/vjnt-class-management/logout
```

### Database:
```
Name:     vjnt_class_management
Tables:   users, login_audit
Host:     localhost
Port:     3306
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-10-31  
**System Status:** ✅ PRODUCTION READY

---

**END OF GUIDE**
