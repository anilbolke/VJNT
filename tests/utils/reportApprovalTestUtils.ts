import { Page } from '@playwright/test';

/**
 * Utility functions for Report Approval Testing
 */

export class ReportApprovalTestUtils {
  /**
   * Login as School Coordinator
   */
  static async loginAsCoordinator(page: Page, email: string, password: string) {
    await page.goto('/login.jsp');
    await page.fill('input[name="email"], input[type="email"]', email);
    await page.fill('input[name="password"], input[type="password"]', password);
    await page.click('button:has-text("Login"), button[type="submit"]');
    await page.waitForURL(/dashboard|home/, { timeout: 5000 });
  }

  /**
   * Login as Head Master
   */
  static async loginAsHeadMaster(page: Page, email: string, password: string) {
    await page.goto('/login.jsp');
    await page.fill('input[name="email"], input[type="email"]', email);
    await page.fill('input[name="password"], input[type="password"]', password);
    await page.click('button:has-text("Login"), button[type="submit"]');
    await page.waitForURL(/dashboard|home/, { timeout: 5000 });
  }

  /**
   * Generate a student report
   */
  static async generateStudentReport(page: Page, studentName: string) {
    await page.click('button:has-text("Generate")');
    await page.waitForSelector('.student-list, table tbody');
    
    // Click on the student
    await page.click(`text=${studentName}`);
    await page.waitForSelector('.modal, [role="dialog"]');
  }

  /**
   * Submit report for approval
   */
  static async submitReportForApproval(page: Page) {
    await page.click('button:has-text("Send to Head Master"), button:has-text("Approval")');
    await page.waitForSelector('.success, .alert-success', { timeout: 5000 });
    
    // Extract request ID
    const requestIdElement = page.locator('[data-test="request-id"], .request-id');
    const requestId = await requestIdElement.textContent();
    return requestId;
  }

  /**
   * Navigate to pending approvals
   */
  static async navigateToPendingApprovals(page: Page) {
    await page.click('text=Approve Reports, [class*="approve"]');
    await page.waitForSelector('.pending-approvals, table, [class*="approval"]', { timeout: 5000 });
  }

  /**
   * Approve a report with optional remarks
   */
  static async approveReport(page: Page, remarks?: string) {
    if (remarks) {
      const remarksField = page.locator('textarea[placeholder*="remarks"], textarea[placeholder*="comments"]').first();
      if (await remarksField.isVisible()) {
        await remarksField.fill(remarks);
      }
    }
    
    await page.click('button:has-text("Approve"), [data-action="approve"]');
    await page.waitForSelector('.success, .alert-success', { timeout: 5000 });
  }

  /**
   * Reject a report with remarks
   */
  static async rejectReport(page: Page, remarks: string) {
    const remarksField = page.locator('textarea[placeholder*="remarks"], textarea[placeholder*="comments"]').first();
    if (await remarksField.isVisible()) {
      await remarksField.fill(remarks);
    }
    
    await page.click('button:has-text("Reject"), [data-action="reject"]');
    
    // Confirm rejection if there's a confirmation dialog
    const confirmBtn = page.locator('button:has-text("Confirm"), button:has-text("Yes")');
    if (await confirmBtn.isVisible()) {
      await confirmBtn.click();
    }
    
    await page.waitForSelector('.error, .alert-danger, [class*="rejected"]', { timeout: 5000 });
  }

  /**
   * Check report status
   */
  static async getReportStatus(page: Page) {
    const statusElement = page.locator('[class*="status-badge"], [class*="status"], .report-status');
    return await statusElement.textContent();
  }

  /**
   * Wait for page to load with specific timeout
   */
  static async waitForPageLoad(page: Page, timeout: number = 5000) {
    await page.waitForLoadState('networkidle', { timeout });
  }

  /**
   * Take screenshot with timestamp
   */
  static async takeScreenshot(page: Page, testName: string) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    await page.screenshot({ 
      path: `./test-results/screenshots/${testName}-${timestamp}.png`,
      fullPage: true 
    });
  }

  /**
   * Get all request IDs from requests table
   */
  static async getAllRequestIds(page: Page) {
    const requestCells = page.locator('[data-field="request-id"], td:first-child');
    const ids: string[] = [];
    
    const count = await requestCells.count();
    for (let i = 0; i < count; i++) {
      const id = await requestCells.nth(i).textContent();
      if (id) ids.push(id.trim());
    }
    
    return ids;
  }

  /**
   * Get report count by status
   */
  static async getReportCountByStatus(page: Page, status: 'PENDING' | 'APPROVED' | 'REJECTED') {
    const statusElements = page.locator(`tr:has-text("${status}"), [class*="status"]:has-text("${status}")`);
    return await statusElements.count();
  }

  /**
   * Export test data to JSON
   */
  static async exportTestData(testName: string, data: any) {
    const fs = require('fs');
    const path = require('path');
    const dir = './test-results/data';
    
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    const filename = path.join(dir, `${testName}-${Date.now()}.json`);
    fs.writeFileSync(filename, JSON.stringify(data, null, 2));
  }
}
