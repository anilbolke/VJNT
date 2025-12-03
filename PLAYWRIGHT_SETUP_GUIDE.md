# Playwright Testing Setup for VJNT Class Management System

This guide will help you set up and run Playwright E2E (End-to-End) tests for the Report Approval Workflow.

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Running Tests](#running-tests)
5. [Test Structure](#test-structure)
6. [Available Tests](#available-tests)
7. [Troubleshooting](#troubleshooting)
8. [CI/CD Integration](#cicd-integration)

---

## Prerequisites

- **Node.js** (v16 or higher) - [Download](https://nodejs.org/)
- **npm** (comes with Node.js)
- **Java 11+** - For Maven builds
- **Maven** - For building the Java project
- **Tomcat v9.0** - Already configured in your workspace
- **Database** - MySQL (ensure your database is running)

### Verify Installation

```bash
# Check Node.js version
node --version

# Check npm version
npm --version

# Check Java version
java -version

# Check Maven version
mvn --version
```

---

## Installation

### Step 1: Install Project Dependencies

Navigate to your project root and install npm packages:

```bash
cd "C:\Users\Admin\V2Project\VJNT Class Managment"
npm install
```

This will install:
- `@playwright/test` - Main Playwright test framework

### Step 2: Install Playwright Browsers

```bash
npx playwright install
```

This installs Chromium, Firefox, and WebKit browsers used for testing.

### Step 3: Build Java Project (Maven)

```bash
mvn clean install
```

Or if you only need to compile without running tests:

```bash
mvn clean compile
```

### Step 4: Deploy to Tomcat

1. Build the WAR file:
```bash
mvn package
```

2. Copy the WAR file to Tomcat's webapps directory:
```bash
copy target\vjnt-class-management.war "C:\Users\Admin\V2Project\Servers\Tomcat v9.0 Server at localhost-config\webapps\"
```

3. Start Tomcat (if not already running)

---

## Configuration

### Update Base URL

Edit `playwright.config.ts` to set your Tomcat URL:

```typescript
use: {
  baseURL: 'http://localhost:8080/vjnt-class-management',
  // ... other settings
}
```

### Environment Variables

Create a `.env` file in the project root (optional):

```env
# Test URLs
BASE_URL=http://localhost:8080/vjnt-class-management

# Test Credentials (if needed)
COORDINATOR_EMAIL=coordinator@school.com
COORDINATOR_PASSWORD=password123
HEADMASTER_EMAIL=headmaster@school.com
HEADMASTER_PASSWORD=password123

# Test Configuration
HEADLESS=true
SLOW_MO=0
TIMEOUT=30000
```

### Update playwright.config.ts for Your Environment

If using environment variables:

```typescript
import dotenv from 'dotenv';
dotenv.config();

export default defineConfig({
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:8080/vjnt-class-management',
    // ... rest of config
  }
});
```

---

## Running Tests

### Run All Tests

```bash
npm test
```

### Run Tests in Headed Mode (See Browser)

```bash
npm run test:headed
```

### Run Tests in Debug Mode

```bash
npm run test:debug
```

### Run Tests with UI Mode (Interactive)

```bash
npm run test:ui
```

### Run Specific Test File

```bash
npx playwright test tests/e2e/report-approval-coordinator.spec.ts
```

### Run Specific Test

```bash
npx playwright test -g "should submit report for approval"
```

### Run Tests in Specific Browser

```bash
# Chromium only
npx playwright test --project=chromium

# Firefox only
npx playwright test --project=firefox

# WebKit only
npx playwright test --project=webkit
```

### Run Tests on Mobile Devices

```bash
# Mobile Chrome (Android)
npx playwright test --project="Mobile Chrome"

# Mobile Safari (iPhone)
npx playwright test --project="Mobile Safari"
```

### View Test Report

```bash
npm run test:report
```

---

## Test Structure

### Directory Layout

```
VJNT Class Managment/
├── tests/
│   ├── e2e/                                    # End-to-end tests
│   │   ├── report-approval-coordinator.spec.ts # Coordinator workflow
│   │   └── report-approval-headmaster.spec.ts  # Head Master workflow
│   └── utils/
│       └── reportApprovalTestUtils.ts          # Test utilities
├── test-results/                               # Test results (auto-generated)
│   ├── screenshots/                            # Failed test screenshots
│   ├── videos/                                 # Test recordings
│   └── results.json                            # Test results JSON
├── playwright.config.ts                        # Playwright configuration
├── package.json                                # npm dependencies
└── pom.xml                                     # Maven configuration
```

### Test File Naming Convention

- Coordinator tests: `*-coordinator.spec.ts`
- Head Master tests: `*-headmaster.spec.ts`
- Authentication tests: `*-auth.spec.ts`
- Performance tests: `*-performance.spec.ts`

---

## Available Tests

### Coordinator Workflow Tests (`report-approval-coordinator.spec.ts`)

1. **Dashboard Loading**
   - Verify school dashboard loads
   - Check for Generate Report button

2. **Report Generation**
   - Generate student report
   - Open report preview modal
   - Verify student information displays

3. **Report Submission**
   - Submit report for Head Master approval
   - Verify success message
   - Extract and validate Request ID

4. **Request Tracking**
   - View My Report Requests page
   - Check request statistics
   - Filter by status (Pending/Approved/Rejected)

5. **Report Actions**
   - Print approved reports
   - Resubmit rejected reports
   - View approval remarks

### Head Master Workflow Tests (`report-approval-headmaster.spec.ts`)

1. **Dashboard Loading**
   - Verify Head Master dashboard loads
   - Check pending approval badge count

2. **Approval Management**
   - View pending approval requests
   - Open full report preview
   - Add remarks/comments

3. **Report Approval**
   - Approve report with remarks
   - Verify success confirmation
   - Check request status update

4. **Report Rejection**
   - Reject report with reason
   - Add detailed remarks
   - Verify rejection notification

5. **History & Analytics**
   - View approval history
   - Check approval dates and times
   - Track approval statistics

---

## Test Utilities

Use the `ReportApprovalTestUtils` class for common operations:

```typescript
import { ReportApprovalTestUtils } from '../../utils/reportApprovalTestUtils';

test('example', async ({ page }) => {
  // Login
  await ReportApprovalTestUtils.loginAsCoordinator(page, 'email@test.com', 'password');
  
  // Generate and submit report
  await ReportApprovalTestUtils.generateStudentReport(page, 'John Doe');
  const requestId = await ReportApprovalTestUtils.submitReportForApproval(page);
  
  // Navigate and approve
  await ReportApprovalTestUtils.navigateToPendingApprovals(page);
  await ReportApprovalTestUtils.approveReport(page, 'Approved with excellent progress');
  
  // Take screenshot
  await ReportApprovalTestUtils.takeScreenshot(page, 'approval-success');
});
```

---

## Troubleshooting

### Tests Can't Connect to Application

**Error**: `Connection refused` or `ERR_CONNECTION_REFUSED`

**Solution**:
1. Verify Tomcat is running
2. Check Tomcat logs: `C:\Users\Admin\V2Project\Servers\Tomcat v9.0 Server at localhost-config\logs\`
3. Verify application is deployed: Check `webapps/vjnt-class-management/` exists
4. Update `baseURL` in `playwright.config.ts`

### Timeouts During Tests

**Error**: `Timeout 30000ms exceeded`

**Solution**:
1. Increase timeout in `playwright.config.ts`:
   ```typescript
   timeout: 60000, // 60 seconds
   ```

2. Check application performance
3. Verify database is responding
4. Add explicit waits for slow elements

### Element Not Found

**Error**: `Error: locator.click: Target page, context or browser has been closed`

**Solution**:
1. Update selectors in test files to match your HTML
2. Use data-test attributes for better stability:
   ```html
   <!-- In JSP file -->
   <button data-test="submit-btn">Submit</button>
   
   <!-- In test -->
   await page.click('[data-test="submit-btn"]');
   ```

3. Add explicit waits:
   ```typescript
   await page.waitForSelector('[data-test="modal"]');
   ```

### Browser Crashes

**Error**: `Browser has been closed` or `Protocol error`

**Solution**:
1. Run single test: `npx playwright test --debug`
2. Reduce workers: `npx playwright test --workers=1`
3. Update Playwright: `npm install @playwright/test@latest`

### No Reports Generated

**Error**: Test runs but generates no report

**Solution**:
1. Check `test-results/` directory exists
2. Enable HTML report in config:
   ```typescript
   reporter: [['html']]
   ```
3. Run: `npm run test:report`

---

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Playwright Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    timeout-minutes: 60
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Install Playwright browsers
      run: npx playwright install --with-deps
    
    - name: Run Playwright tests
      run: npm test
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: playwright-report
        path: playwright-report/
```

### Jenkins Pipeline

Create `Jenkinsfile`:

```groovy
pipeline {
    agent any
    
    stages {
        stage('Install') {
            steps {
                sh 'npm ci'
                sh 'npx playwright install --with-deps'
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
        
        stage('Report') {
            steps {
                publishHTML([
                    reportDir: 'playwright-report',
                    reportFiles: 'index.html',
                    reportName: 'Playwright Report'
                ])
            }
        }
    }
    
    post {
        always {
            junit 'test-results/junit.xml'
        }
    }
}
```

---

## Best Practices

### 1. Use Data Test Attributes

```html
<!-- JSP/HTML -->
<button data-test="submit-report">Submit</button>

<!-- Test -->
await page.click('[data-test="submit-report"]');
```

### 2. Explicit Waits

```typescript
// Instead of arbitrary delays
await page.waitForSelector('.modal');
await page.waitForURL(/approval/);
await page.waitForFunction(() => document.readyState === 'complete');
```

### 3. Error Screenshots

```typescript
test.afterEach(async ({ page }, testInfo) => {
  if (testInfo.status !== 'passed') {
    await page.screenshot({ 
      path: `screenshot-${Date.now()}.png` 
    });
  }
});
```

### 4. Isolate Test Data

```typescript
test.beforeEach(async ({ page }) => {
  // Setup test data before each test
  await createTestReport();
});

test.afterEach(async ({ page }) => {
  // Cleanup after each test
  await deleteTestReport();
});
```

### 5. Parallel Execution

```typescript
// Run tests in parallel (default)
export default defineConfig({
  fullyParallel: true,
  workers: 4, // Adjust based on your system
});
```

---

## Advanced Features

### Visual Regression Testing

```typescript
test('report layout should match', async ({ page }) => {
  await page.goto('/report');
  await expect(page).toHaveScreenshot();
});
```

### Performance Testing

```typescript
test('report should load within 3 seconds', async ({ page }) => {
  const startTime = Date.now();
  await page.goto('/report');
  const loadTime = Date.now() - startTime;
  
  expect(loadTime).toBeLessThan(3000);
});
```

### API Testing Integration

```typescript
test('approval API should work', async ({ request }) => {
  const response = await request.post('/api/approve-report', {
    data: {
      requestId: '#123',
      remarks: 'Approved'
    }
  });
  
  expect(response.status()).toBe(200);
});
```

---

## Quick Commands Reference

| Command | Description |
|---------|-------------|
| `npm install` | Install dependencies |
| `npx playwright install` | Install browsers |
| `npm test` | Run all tests |
| `npm run test:headed` | Run tests with visible browser |
| `npm run test:debug` | Run tests in debug mode |
| `npm run test:ui` | Run tests with UI mode |
| `npm run test:report` | View HTML test report |
| `npx playwright test --project=chromium` | Run on Chromium only |
| `npx playwright test -g "pattern"` | Run tests matching pattern |
| `npx playwright codegen` | Generate tests by recording |

---

## Support & Resources

- **Playwright Docs**: https://playwright.dev/
- **Playwright Community**: https://github.com/microsoft/playwright/discussions
- **Test Report**: Open `playwright-report/index.html` after running tests

---

## Next Steps

1. ✅ Install npm dependencies
2. ✅ Install Playwright browsers
3. ✅ Update test credentials in `.env`
4. ✅ Run tests: `npm test`
5. ✅ View report: `npm run test:report`
6. ✅ Customize tests for your specific selectors
7. ✅ Integrate into CI/CD pipeline

---

**Last Updated**: December 3, 2025
**Playwright Version**: 1.40+
**Node.js Version**: 16+
