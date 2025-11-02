# VJNT Excel Import Guide

## Overview
The **ExcelStudentLoader** now imports both student data AND automatically creates user logins in a single operation.

## What It Does

### 1. Student Data Import
Imports all student records with the following columns:
- Division
- District (Dist)
- UDISE NO
- Class
- Section
- Class Category (Calss Category)
- Student Name
- Gender
- Student PEN
- मराठी भाषा स्तर (Marathi Level)
- गणित स्तर (Math Level)
- इंग्रजी स्तर (English Level)

### 2. Automatic User Login Creation
Creates hierarchical user logins based on the data:

#### Division Level (1 login per division)
- **Username Pattern**: `div_<division_name>`
- **User Type**: DIVISION
- **Example**: `div_latur_division`

#### District Level (2 logins per district)
- **District Coordinator**
  - Username Pattern: `dist_coord_<district_name>`
  - User Type: DISTRICT_COORDINATOR
  - Example: `dist_coord_dharashiv`

- **District 2nd Coordinator**
  - Username Pattern: `dist_coord2_<district_name>`
  - User Type: DISTRICT_2ND_COORDINATOR
  - Example: `dist_coord2_dharashiv`

#### School Level (2 logins per UDISE)
- **School Coordinator**
  - Username Pattern: `school_coord_<udise_no>`
  - User Type: SCHOOL_COORDINATOR
  - Example: `school_coord_10001`

- **Head Master**
  - Username Pattern: `headmaster_<udise_no>`
  - User Type: HEAD_MASTER
  - Example: `headmaster_10001`

## Default Password
**All users are created with the default password: `Pass@123`**

Users must change their password on first login.

## How to Run

### Method 1: Using Batch File
```cmd
run-student-loader.bat
```

### Method 2: Using Command Line
```cmd
cd "C:\Users\Admin\V2Project\VJNT Class Managment"
javac -encoding UTF-8 -source 1.8 -target 1.8 -cp "src/main/webapp/WEB-INF/lib/*" -d build/classes src/main/java/com/vjnt/model/*.java src/main/java/com/vjnt/dao/*.java src/main/java/com/vjnt/util/DatabaseConnection.java src/main/java/com/vjnt/util/PasswordUtil.java src/main/java/com/vjnt/util/ExcelStudentLoader.java
java -cp "src/main/webapp/WEB-INF/lib/*;build/classes" com.vjnt.util.ExcelStudentLoader
```

### Method 3: From Eclipse
1. Open the project in Eclipse
2. Navigate to `src/main/java/com/vjnt/util/ExcelStudentLoader.java`
3. Right-click → Run As → Java Application

## Import Summary Example

```
========================================
STUDENT IMPORT SUMMARY
========================================
Total Rows Processed: 213
Students Created: 213
Students Skipped: 0
========================================

USER LOGIN SUMMARY
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

## Features

✅ **Duplicate Prevention**: Checks for existing users before creating new ones
✅ **Duplicate Student Check**: Checks Student PEN to avoid duplicate records
✅ **Progress Tracking**: Shows progress every 50 students
✅ **Error Handling**: Continues processing even if individual rows fail
✅ **Comprehensive Summary**: Detailed report at the end
✅ **Marathi Support**: Properly handles Marathi column headers
✅ **Hierarchical Login Creation**: Automatically creates all required user levels

## Excel File Location
Default path: `src/main/webapp/Document/V2 Sample Format Data Entry for Anil.xlsx`

To change the file path, edit line 208 in `ExcelStudentLoader.java`:
```java
String excelPath = "YOUR_FILE_PATH_HERE";
```

## Database Tables
The import populates two tables:
1. **students** - All student records
2. **users** - User login accounts with hierarchical access

## Troubleshooting

### Issue: Compilation Errors
**Solution**: Clean the build directory first
```cmd
Remove-Item -Recurse -Force build\classes\*
```

### Issue: Database Connection Error
**Solution**: Check `DatabaseConnection.java` for correct credentials
- Default: localhost:3306
- Database: vjnt_class_management
- Username: root
- Password: root

### Issue: Duplicate Users
**Solution**: The system automatically skips existing users. To start fresh:
```sql
DELETE FROM students;
DELETE FROM users WHERE username != 'admin';
```

## Notes
- The import is idempotent - running multiple times won't create duplicates
- Empty student names are automatically skipped
- All user accounts are created with `is_first_login = TRUE` and `must_change_password = TRUE`
- Users are automatically linked to their respective Division, District, or UDISE
