# Playwright Testing - Using src/main/webapp JSP Files

This document explains how the Playwright testing framework has been configured to work with your `src/main/webapp` JSP files.

## 📂 File Structure

Your project now uses the following structure:

```
src/main/webapp/                    ← Primary JSP source files
├── login.jsp
├── school-dashboard-enhanced.jsp
├── my-report-requests.jsp
├── headmaster-approve-phase.jsp
├── approve-student-reports.jsp
├── student-comprehensive-report-new.jsp
└── ... other JSP files

WebContent/                         ← Deployment folder (mirrors webapp)
├── (same files after build/deploy)
```

## 🔧 Playwright Configuration

### Base URL Setup

The `playwright.config.ts` has been configured with:

```typescript
use: {
  baseURL: 'http://localhost:8080/vjnt-class-management',
  // ...
}
```

This means all relative URLs in tests are resolved to `http://localhost:8080/vjnt-class-management`

### Test Path Examples

**Old paths (❌ Not used):**
```typescript
await page.goto('/vjnt-class-management/login.jsp');      // ❌ Old
await page.goto('/vjnt-class-management/school-dashboard-enhanced.jsp');  // ❌ Old
```

**New paths (✅ Recommended):**
```typescript
await page.goto('/login.jsp');                            // ✅ New
await page.goto('/school-dashboard-enhanced.jsp');        // ✅ New
await page.goto('/my-report-requests.jsp');               // ✅ New
await page.goto('/headmaster-approve-phase.jsp');         // ✅ New
```

## 📋 Available JSP Files for Testing

All JSP files in `src/main/webapp/` are available for testing:

| JSP File | Purpose | Test Coverage |
|----------|---------|----------------|
| `login.jsp` | User authentication | ✅ Auth tests |
| `school-dashboard-enhanced.jsp` | School Coordinator dashboard | ✅ Coordinator workflow |
| `my-report-requests.jsp` | View submitted report requests | ✅ Request tracking |
| `headmaster-approve-phase.jsp` | Head Master approval interface | ✅ Approval workflow |
| `approve-student-reports.jsp` | Report approval management | ✅ Approval actions |
| `student-comprehensive-report-new.jsp` | Student report details | ✅ Report viewing |
| `manage-students.jsp` | Student management | Can be extended |
| `manage-teachers.jsp` | Teacher management | Can be extended |
| `palak-melava.jsp` | Parent-teacher meetings | Can be extended |

## 🚀 Running Tests with webapp JSP Files

### Step 1: Build the Project

Build the Maven project to deploy JSP files to Tomcat:

```bash
mvn clean install
# or
mvn clean package
```

This compiles JSP files and prepares them for deployment.

### Step 2: Deploy to Tomcat

Option A - Manual copy:
```bash
copy target\vjnt-class-management.war "C:\Users\Admin\V2Project\Servers\Tomcat v9.0 Server at localhost-config\webapps\"
```

Option B - Use the setup script menu option 12 (Deploy to Tomcat)

### Step 3: Verify Deployment

Check that your app is running:
```
http://localhost:8080/vjnt-class-management/login.jsp
```

### Step 4: Run Tests

```bash
npm test
```

## 📝 Test Files Using webapp Paths

The following test files have been updated to use webapp JSP paths:

### 1. **report-approval-coordinator.spec.ts**
Tests the complete School Coordinator workflow:

```typescript
// ✅ Uses webapp paths
await page.goto('/school-dashboard-enhanced.jsp');
await page.goto('/my-report-requests.jsp');
await page.goto('/student-comprehensive-report-new.jsp');
```

### 2. **report-approval-headmaster.spec.ts**
Tests the Head Master approval workflow:

```typescript
// ✅ Uses webapp paths
await page.goto('/headmaster-approve-phase.jsp');
```

### 3. **reportApprovalTestUtils.ts**
Reusable test utilities updated with webapp paths:

```typescript
// ✅ Uses webapp paths
await page.goto('/login.jsp');
```

## 🔄 How Tests Access webapp JSP Files

```
Test Script
    ↓
Playwright
    ↓
Browser (Chrome/Firefox/Safari)
    ↓
HTTP Request: http://localhost:8080/vjnt-class-management/login.jsp
    ↓
Tomcat Server
    ↓
src/main/webapp/ (or WebContent/ after deployment)
    ↓
JSP Engine
    ↓
Rendered HTML
    ↓
Browser Display
```

## ✅ Verification Checklist

Before running tests, verify:

- [x] Maven build is successful: `mvn clean install`
- [x] WAR file deployed to Tomcat
- [x] Tomcat is running
- [x] Application accessible: `http://localhost:8080/vjnt-class-management`
- [x] Login page loads: `http://localhost:8080/vjnt-class-management/login.jsp`
- [x] npm dependencies installed: `npm install`
- [x] Playwright browsers installed: `npx playwright install`

## 🎯 Next Steps

1. **Build the project:**
   ```bash
   mvn clean install
   ```

2. **Deploy to Tomcat** (using SETUP.bat menu option 12 or manually)

3. **Verify deployment:**
   - Open `http://localhost:8080/vjnt-class-management/login.jsp` in browser

4. **Run tests:**
   ```bash
   npm test
   ```

5. **View results:**
   ```bash
   npm run test:report
   ```

## 🐛 Troubleshooting

### Tests can't find pages

**Error:** `Target page, context or browser has been closed`

**Solution:**
1. Verify Tomcat is running
2. Check application is deployed: `http://localhost:8080/vjnt-class-management/`
3. Verify baseURL in `playwright.config.ts` is correct

### JSP files not found

**Error:** `net::ERR_CONNECTION_REFUSED`

**Solution:**
1. Rebuild and redeploy: `mvn clean install`
2. Restart Tomcat
3. Check Tomcat logs for errors

### Tests timing out

**Error:** `Timeout 30000ms exceeded`

**Solution:**
1. Check if JSP pages are loading correctly in browser
2. Increase timeout in `playwright.config.ts`
3. Check database connectivity

## 📚 Related Documentation

- **Setup Guide:** `PLAYWRIGHT_SETUP_GUIDE.md`
- **Quick Start:** `PLAYWRIGHT_IMPLEMENTATION.md`
- **Playwright Docs:** https://playwright.dev/

## 📝 Adding New Tests

To add new tests using webapp JSP files:

```typescript
import { test, expect } from '@playwright/test';

test('my new test', async ({ page }) => {
  // Use relative paths (webapp JSP files)
  await page.goto('/my-new-page.jsp');
  
  // ... your test code
});
```

The `baseURL` configuration automatically prepends `http://localhost:8080/vjnt-class-management` to all relative paths.

---

**Configuration Date:** December 3, 2025  
**Test Framework:** Playwright 1.40+  
**JSP Source:** src/main/webapp/  
**Application:** VJNT Class Management System
