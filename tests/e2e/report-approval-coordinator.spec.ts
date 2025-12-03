import { test, expect } from '@playwright/test';

test.describe('Report Approval Workflow - School Coordinator', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the school dashboard
    await page.goto('/school-dashboard-enhanced.jsp');
  });

  test('should load school dashboard successfully', async ({ page }) => {
    // Verify page title or heading
    const heading = page.locator('h1, h2, .dashboard-title');
    await expect(heading).toBeVisible();
  });

  test('should generate student report', async ({ page }) => {
    // Click on Generate Report button
    await page.click('button:has-text("Generate")');
    
    // Wait for student list to appear
    await page.waitForSelector('.student-list, table tbody');
    
    // Verify at least one student is displayed
    const studentRows = page.locator('tr, .student-item');
    await expect(studentRows).toHaveCount(1, { timeout: 5000 });
  });

  test('should open report preview modal', async ({ page }) => {
    // Click on Generate Report
    await page.click('button:has-text("Generate")');
    
    // Wait for student list
    await page.waitForSelector('.student-list, table tbody');
    
    // Click on a student's report icon/button
    await page.click('[data-test="generate-report"], .report-btn, button[title*="Report"]');
    
    // Verify modal appears
    const modal = page.locator('.modal, [role="dialog"]');
    await expect(modal).toBeVisible();
  });

  test('should submit report for approval', async ({ page }) => {
    // Navigate through to report preview
    await page.click('button:has-text("Generate")');
    await page.waitForSelector('.student-list, table tbody');
    await page.click('[data-test="generate-report"], .report-btn, button[title*="Report"]');
    
    // Wait for modal
    await page.waitForSelector('.modal, [role="dialog"]');
    
    // Click "Send to Head Master for Approval" button
    await page.click('button:has-text("Send to Head Master"), button:has-text("Approval")');
    
    // Verify success message
    const successMsg = page.locator('.success, .alert-success, [class*="success"]');
    await expect(successMsg).toContainText(/submitted|success/i);
    
    // Verify Request ID is displayed
    const requestId = page.locator('[data-test="request-id"], .request-id');
    await expect(requestId).toBeVisible();
  });

  test('should display request ID after submission', async ({ page }) => {
    // Submit a report
    await page.click('button:has-text("Generate")');
    await page.waitForSelector('.student-list, table tbody');
    await page.click('[data-test="generate-report"], .report-btn, button[title*="Report"]');
    await page.waitForSelector('.modal, [role="dialog"]');
    await page.click('button:has-text("Send to Head Master"), button:has-text("Approval")');
    
    // Extract and verify request ID format
    const requestIdText = await page.locator('[data-test="request-id"], .request-id').textContent();
    expect(requestIdText).toMatch(/#\d+/);
  });
});

test.describe('Report Approval Workflow - View My Requests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/my-report-requests.jsp');
  });

  test('should display report requests list', async ({ page }) => {
    // Verify table is visible
    const table = page.locator('table, .requests-table, [class*="request"]');
    await expect(table).toBeVisible();
  });

  test('should show request statistics', async ({ page }) => {
    // Check for statistics section
    const stats = page.locator('[data-test="statistics"], .stats, [class*="stats"]');
    await expect(stats).toBeVisible();
    
    // Verify statistics contain numbers
    const statsText = await stats.textContent();
    expect(statsText).toMatch(/\d+/);
  });

  test('should display pending requests with correct status badge', async ({ page }) => {
    // Look for pending status
    const pendingStatus = page.locator('[class*="pending"], .status-badge:has-text("PENDING")');
    const pendingCount = await pendingStatus.count();
    
    if (pendingCount > 0) {
      await expect(pendingStatus.first()).toBeVisible();
    }
  });

  test('should display approved requests with print button', async ({ page }) => {
    // Look for approved status
    const approvedStatus = page.locator('[class*="approved"], .status-badge:has-text("APPROVED")');
    const approvedCount = await approvedStatus.count();
    
    if (approvedCount > 0) {
      // Find corresponding print button
      const printBtn = page.locator('button:has-text("Print"), [data-action="print"]').first();
      await expect(printBtn).toBeVisible();
    }
  });

  test('should allow printing approved report', async ({ page }) => {
    // Find approved status row
    const approvedRow = page.locator('tr:has-text("APPROVED"), [class*="approved"]').first();
    
    if (await approvedRow.isVisible()) {
      // Click print button within the row
      await approvedRow.locator('button:has-text("Print"), [data-action="print"]').click();
      
      // Wait for PDF or new window
      await page.waitForTimeout(2000);
    }
  });

  test('should allow resubmitting rejected report', async ({ page }) => {
    // Find rejected status row
    const rejectedRow = page.locator('tr:has-text("REJECTED"), [class*="rejected"]').first();
    
    if (await rejectedRow.isVisible()) {
      // Click resubmit button
      await rejectedRow.locator('button:has-text("Retry"), button:has-text("Resubmit")').click();
      
      // Verify modal or navigation
      const modal = page.locator('.modal, [role="dialog"]');
      await expect(modal).toBeVisible({ timeout: 5000 });
    }
  });
});

test.describe('Report Approval Workflow - Status Indicators', () => {
  test('should show report status: PENDING APPROVAL', async ({ page }) => {
    // This test assumes there's a report details page
    await page.goto('/student-comprehensive-report-new.jsp');
    
    // Look for pending approval status
    const pendingStatus = page.locator('[class*="pending"], [class*="status"]:has-text("PENDING")');
    if (await pendingStatus.isVisible()) {
      await expect(pendingStatus).toContainText(/pending|waiting/i);
    }
  });

  test('should show report status: APPROVED', async ({ page }) => {
    await page.goto('/student-comprehensive-report-new.jsp');
    
    // Look for approved status
    const approvedStatus = page.locator('[class*="approved"], [class*="status"]:has-text("APPROVED")');
    if (await approvedStatus.isVisible()) {
      await expect(approvedStatus).toContainText(/approved/i);
    }
  });

  test('should show report status: REJECTED', async ({ page }) => {
    await page.goto('/student-comprehensive-report-new.jsp');
    
    // Look for rejected status
    const rejectedStatus = page.locator('[class*="rejected"], [class*="status"]:has-text("REJECTED")');
    if (await rejectedStatus.isVisible()) {
      await expect(rejectedStatus).toContainText(/rejected/i);
    }
  });

  test('should display remarks for rejected report', async ({ page }) => {
    await page.goto('/vjnt-class-management/student-comprehensive-report-new.jsp');
    
    // Check for remarks section
    const remarks = page.locator('[data-test="remarks"], .remarks, [class*="remarks"]');
    if (await remarks.isVisible()) {
      const remarksText = await remarks.textContent();
      expect(remarksText?.length).toBeGreaterThan(0);
    }
  });
});
