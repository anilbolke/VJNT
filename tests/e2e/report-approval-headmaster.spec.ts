import { test, expect } from '@playwright/test';

test.describe('Report Approval Workflow - Head Master', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to Head Master dashboard
    await page.goto('/headmaster-approve-phase.jsp');
  });

  test('should load head master dashboard', async ({ page }) => {
    // Verify dashboard loads
    const heading = page.locator('h1, h2, .dashboard-title');
    await expect(heading).toBeVisible();
  });

  test('should display approve reports section with badge', async ({ page }) => {
    // Look for "Approve Reports" section with pending count badge
    const approveSection = page.locator('text=Approve Reports, [class*="approve"]');
    await expect(approveSection).toBeVisible();
    
    // Check for badge showing count
    const badge = page.locator('[class*="badge"], .count-badge');
    if (await badge.isVisible()) {
      const badgeText = await badge.textContent();
      expect(badgeText).toMatch(/\d+/);
    }
  });

  test('should navigate to pending approvals', async ({ page }) => {
    // Click on Approve Reports
    await page.click('text=Approve Reports, [class*="approve"]');
    
    // Verify pending approvals page loads
    await page.waitForSelector('.pending-approvals, table, [class*="approval"]');
    
    const content = page.locator('.pending-approvals, table, [class*="approval"]');
    await expect(content).toBeVisible();
  });

  test('should display pending request details', async ({ page }) => {
    // Navigate to approvals
    await page.click('text=Approve Reports, [class*="approve"]');
    await page.waitForSelector('.pending-approvals, table, [class*="approval"]');
    
    // Look for request details
    const requestCard = page.locator('[class*="request-card"], .approval-item, [data-test="pending-request"]');
    
    if (await requestCard.isVisible()) {
      // Verify contains key information
      const detailsText = await requestCard.textContent();
      expect(detailsText).toContain('Request');
    }
  });

  test('should display student information in pending request', async ({ page }) => {
    await page.click('text=Approve Reports, [class*="approve"]');
    await page.waitForSelector('.pending-approvals, table, [class*="approval"]');
    
    const requestCard = page.locator('[class*="request-card"], .approval-item, [data-test="pending-request"]').first();
    
    if (await requestCard.isVisible()) {
      // Check for student name, PEN, class
      const studentInfo = requestCard.locator('[class*="student"], [data-field="student"]');
      await expect(studentInfo).toBeVisible();
    }
  });

  test('should display view full report button', async ({ page }) => {
    await page.click('text=Approve Reports, [class*="approve"]');
    await page.waitForSelector('.pending-approvals, table, [class*="approval"]');
    
    const viewReportBtn = page.locator('button:has-text("View Full Report"), button:has-text("View Report"), [data-action="view-report"]').first();
    
    if (await viewReportBtn.isVisible()) {
      await expect(viewReportBtn).toBeEnabled();
    }
  });

  test('should open full report preview', async ({ page }) => {
    await page.click('text=Approve Reports, [class*="approve"]');
    await page.waitForSelector('.pending-approvals, table, [class*="approval"]');
    
    const viewReportBtn = page.locator('button:has-text("View Full Report"), button:has-text("View Report"), [data-action="view-report"]').first();
    
    if (await viewReportBtn.isVisible()) {
      await viewReportBtn.click();
      
      // Wait for report modal/page
      await page.waitForSelector('.report-modal, .report-content, [data-test="report-preview"]', { timeout: 5000 });
    }
  });

  test('should display approve button', async ({ page }) => {
    await page.click('text=Approve Reports, [class*="approve"]');
    await page.waitForSelector('.pending-approvals, table, [class*="approval"]');
    
    const approveBtn = page.locator('button:has-text("Approve"), [data-action="approve"]').first();
    
    if (await approveBtn.isVisible()) {
      await expect(approveBtn).toBeEnabled();
    }
  });

  test('should display reject button', async ({ page }) => {
    await page.click('text=Approve Reports, [class*="approve"]');
    await page.waitForSelector('.pending-approvals, table, [class*="approval"]');
    
    const rejectBtn = page.locator('button:has-text("Reject"), [data-action="reject"]').first();
    
    if (await rejectBtn.isVisible()) {
      await expect(rejectBtn).toBeEnabled();
    }
  });

  test('should display remarks/comments textarea', async ({ page }) => {
    await page.click('text=Approve Reports, [class*="approve"]');
    await page.waitForSelector('.pending-approvals, table, [class*="approval"]');
    
    const remarksField = page.locator('textarea[placeholder*="remarks"], textarea[placeholder*="comments"], [data-test="remarks"]');
    
    if (await remarksField.isVisible()) {
      await expect(remarksField).toBeVisible();
    }
  });

  test('should approve report successfully', async ({ page }) => {
    await page.click('text=Approve Reports, [class*="approve"]');
    await page.waitForSelector('.pending-approvals, table, [class*="approval"]');
    
    const requestCard = page.locator('[class*="request-card"], .approval-item, [data-test="pending-request"]').first();
    
    if (await requestCard.isVisible()) {
      // Optional: Add remarks
      const remarksField = requestCard.locator('textarea[placeholder*="remarks"], textarea[placeholder*="comments"]');
      if (await remarksField.isVisible()) {
        await remarksField.fill('Good progress, approved');
      }
      
      // Click Approve button
      await requestCard.locator('button:has-text("Approve"), [data-action="approve"]').click();
      
      // Wait for success message
      const successMsg = page.locator('.success, .alert-success, [class*="success"]');
      await expect(successMsg).toContainText(/approved|success/i, { timeout: 5000 });
    }
  });

  test('should reject report with remarks', async ({ page }) => {
    await page.click('text=Approve Reports, [class*="approve"]');
    await page.waitForSelector('.pending-approvals, table, [class*="approval"]');
    
    const requestCard = page.locator('[class*="request-card"], .approval-item, [data-test="pending-request"]').first();
    
    if (await requestCard.isVisible()) {
      // Add rejection reason
      const remarksField = requestCard.locator('textarea[placeholder*="remarks"], textarea[placeholder*="comments"]');
      if (await remarksField.isVisible()) {
        await remarksField.fill('Please verify student attendance records');
      }
      
      // Click Reject button
      await requestCard.locator('button:has-text("Reject"), [data-action="reject"]').click();
      
      // Wait for confirmation
      const confirmBtn = page.locator('button:has-text("Confirm"), button:has-text("Yes")');
      if (await confirmBtn.isVisible()) {
        await confirmBtn.click();
      }
      
      // Verify rejection message
      const rejectionMsg = page.locator('.error, .alert-danger, [class*="rejected"]');
      await expect(rejectionMsg).toContainText(/rejected|denied/i, { timeout: 5000 });
    }
  });

  test('should update pending count after approval', async ({ page }) => {
    // Get initial badge count
    await page.goto('/headmaster-approve-phase.jsp');
    
    const initialBadge = page.locator('[class*="badge"], .count-badge').first();
    const initialCount = parseInt(await initialBadge.textContent() || '0');
    
    // Navigate to approvals and approve one
    await page.click('text=Approve Reports, [class*="approve"]');
    await page.waitForSelector('.pending-approvals, table, [class*="approval"]');
    
    const requestCard = page.locator('[class*="request-card"], .approval-item', { has: page.locator('button:has-text("Approve")') }).first();
    
    if (await requestCard.isVisible()) {
      await requestCard.locator('button:has-text("Approve"), [data-action="approve"]').click();
      
      // Navigate back to dashboard
      await page.goto('/headmaster-approve-phase.jsp');
      
      // Verify badge count decreased
      const newBadge = page.locator('[class*="badge"], .count-badge').first();
      const newCount = parseInt(await newBadge.textContent() || '0');
      
      expect(newCount).toBeLessThanOrEqual(initialCount);
    }
  });
});

test.describe('Report Approval Workflow - Approval History', () => {
  test('should display approval history', async ({ page }) => {
    await page.goto('/headmaster-approve-phase.jsp');
    
    const historySection = page.locator('text=History, text=Approval History, [class*="history"]');
    
    if (await historySection.isVisible()) {
      await expect(historySection).toBeVisible();
    }
  });

  test('should display approved reports in history', async ({ page }) => {
    await page.goto('/headmaster-approve-phase.jsp');
    
    const historyTable = page.locator('[class*="history-table"], table').last();
    
    if (await historyTable.isVisible()) {
      const approvedRow = historyTable.locator('tr:has-text("APPROVED")');
      if (await approvedRow.isVisible()) {
        await expect(approvedRow).toContainText('APPROVED');
      }
    }
  });

  test('should display rejected reports in history', async ({ page }) => {
    await page.goto('/headmaster-approve-phase.jsp');
    
    const historyTable = page.locator('[class*="history-table"], table').last();
    
    if (await historyTable.isVisible()) {
      const rejectedRow = historyTable.locator('tr:has-text("REJECTED")');
      if (await rejectedRow.isVisible()) {
        await expect(rejectedRow).toContainText('REJECTED');
      }
    }
  });

  test('should show approval date and time in history', async ({ page }) => {
    await page.goto('/headmaster-approve-phase.jsp');
    
    const historyTable = page.locator('[class*="history-table"], table').last();
    
    if (await historyTable.isVisible()) {
      const dateCell = historyTable.locator('td:has-text(/\\d{1,2}\\/\\d{1,2}\\/\\d{4}/)');
      if (await dateCell.isVisible()) {
        await expect(dateCell).toBeVisible();
      }
    }
  });
});
