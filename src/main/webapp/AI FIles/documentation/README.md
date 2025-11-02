# VJNT Class Management System - Multi-Level Login System

## 🎯 Quick Start Guide

### Prerequisites
- Java 8 or higher
- Apache Tomcat 9.0+
- MySQL 8.0+
- Maven 3.6+

### Step 1: Database Setup
```sql
CREATE DATABASE vjnt_class_management;
USE vjnt_class_management;
SOURCE database_schema.sql;
```

### Step 2: Configure Database
Edit `src/main/java/com/vjnt/util/DatabaseConnection.java`:
```java
private static final String DB_URL = "jdbc:mysql://localhost:3306/vjnt_class_management";
private static final String DB_USER = "root";
private static final String DB_PASSWORD = "your_password";
```

### Step 3: Build Project
```bash
mvn clean install
```

### Step 4: Load Users from Excel
```bash
# From IDE: Run ExcelUserLoader.java main method
# OR from command line:
java -cp target/classes com.vjnt.util.ExcelUserLoader
```

### Step 5: Deploy
```bash
# Copy WAR to Tomcat
cp target/vjnt-class-management.war $TOMCAT_HOME/webapps/
# Start Tomcat
$TOMCAT_HOME/bin/startup.sh  # Linux/Mac
$TOMCAT_HOME/bin/startup.bat # Windows
```

### Step 6: Access Application
```
URL: http://localhost:8080/vjnt-class-management/login
Default Password: Pass@123
```

## 📊 System Overview

### Excel Analysis Results
- **Total Rows**: 214 (213 data + 1 header)
- **Unique Divisions**: 1 (Latur Division)
- **Unique Districts**: 4 (Dharashiv, Hingoli, Nanded, Latur)
- **Unique UDISE Numbers**: 60

### Login Distribution
```
┌─────────────────────────────────┬──────────────┐
│ Login Type                      │ Total Logins │
├─────────────────────────────────┼──────────────┤
│ Division Administrators         │ 1            │
│ District Coordinators           │ 4            │
│ District 2nd Coordinators       │ 4            │
│ School Coordinators             │ 60           │
│ Head Masters                    │ 60           │
├─────────────────────────────────┼──────────────┤
│ TOTAL                           │ 129          │
└─────────────────────────────────┴──────────────┘
```

## 🔐 Sample Credentials

### Division Level
- Username: `div_latur_division`
- Password: `Pass@123`

### District Level
- Username: `dist_coord_dharashiv`
- Password: `Pass@123`

### School Level
- Username: `school_coord_10001`
- Password: `Pass@123`

**⚠️ All users must change password on first login!**

## 📁 Project Structure
```
VJNT Class Managment/
├── src/main/
│   ├── java/com/vjnt/
│   │   ├── model/          # Entity classes
│   │   ├── dao/            # Data access layer
│   │   ├── servlet/        # Web servlets
│   │   └── util/           # Utilities
│   └── webapp/
│       ├── login.jsp
│       ├── change-password.jsp
│       └── WEB-INF/web.xml
├── database_schema.sql     # Database creation script
├── pom.xml                 # Maven configuration
└── README.md              # This file
```

## 🔧 Key Features

✅ Multi-level access control (5 levels)  
✅ Automatic user creation from Excel  
✅ Secure password hashing (SHA-256)  
✅ Mandatory password change on first login  
✅ Strong password policy enforcement  
✅ Account lockout after 5 failed attempts  
✅ Login audit trail  
✅ Session management (30 min timeout)  
✅ Modern, responsive UI  

## 📖 Documentation

See `VJNT_LOGIN_SYSTEM_COMPLETE_ANALYSIS.md` for detailed documentation.

## 🐛 Troubleshooting

### Database Connection Failed
- Check MySQL is running
- Verify credentials in DatabaseConnection.java
- Check database exists

### Users Not Created
- Run database_schema.sql first
- Check Excel file path in ExcelUserLoader.java
- Verify file has correct columns

### Login Failed
- Default password: Pass@123
- Check user is not locked
- Check account is active

## 📞 Support

For issues or questions, refer to the complete analysis document.

---

**System Version**: 1.0.0  
**Last Updated**: 2025-10-31
