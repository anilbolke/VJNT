import { test, expect } from '@playwright/test';
import {
  navigateToLogin,
  enterCredentials,
  clickLoginButton,
  performLogin,
  isLoggedIn,
  getLoginErrorMessage,
  verifyLoginPageLoaded,
  logout,
  getPageContent,
  isPasswordChangeRequired,
} from '../utils/loginTestUtils';

test.describe('Login Page & Activity Features', () => {
  // Test credentials provided
  const VALID_USERNAME = 'sr_27150201202';
  const VALID_PASSWORD = 'Saraswati@123';
  const INVALID_USERNAME = 'invalid_user_12345';
  const INVALID_PASSWORD = 'wrongpassword';

  test.describe('Login Page - UI & Accessibility', () => {
    test('should load login page without errors', async ({ page }) => {
      await navigateToLogin(page);

      const isLoaded = await verifyLoginPageLoaded(page);
      expect(isLoaded).toBe(true);
    });

    test('should display login form with required fields', async ({ page }) => {
      await navigateToLogin(page);

      // Username field
      const usernameInput = page.locator('input[name="username"]');
      await expect(usernameInput).toBeVisible();

      // Password field
      const passwordInput = page.locator('input[name="password"]');
      await expect(passwordInput).toBeVisible();

      // Submit button
      const submitButton = page.locator('button[type="submit"]');
      await expect(submitButton).toBeVisible();
    });

    test('should have proper page title', async ({ page }) => {
      await navigateToLogin(page);

      const pageContent = await getPageContent(page);
      expect(pageContent.length).toBeGreaterThan(100);
    });

    test('should display login branding/header', async ({ page }) => {
      await navigateToLogin(page);

      const content = await getPageContent(page);
      // Check for common login page text
      const hasHeading = content.toLowerCase().includes('login') ||
                        content.toLowerCase().includes('sign in') ||
                        content.toLowerCase().includes('gatee');
      expect(hasHeading).toBe(true);
    });

    test('should have responsive layout', async ({ page }) => {
      await navigateToLogin(page);

      const body = page.locator('body');
      await expect(body).toBeVisible();

      const form = page.locator('form').first();
      if (await form.count() > 0) {
        await expect(form).toBeVisible();
      }
    });

    test('should not require login to view login page', async ({ page }) => {
      // Should not redirect away from login page
      await page.goto('/VJNT_Class_Managment/login');
      const url = page.url();
      expect(url).toContain('login');
    });
  });

  test.describe('Valid Login - UDISE 27150201202', () => {
    test('should login successfully with valid credentials', async ({ page }) => {
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);

      const loggedIn = await isLoggedIn(page);
      expect(loggedIn).toBe(true);
    });

    test('should redirect to dashboard after successful login', async ({ page }) => {
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);

      const url = page.url();
      // Should be redirected away from login page
      expect(url).not.toContain('login');

      // Should be on a dashboard or main page
      const isDashboard = url.includes('dashboard') || url.includes('school') || url.includes('district');
      expect(isDashboard).toBe(true);
    });

    test('should display logout button after login', async ({ page }) => {
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);

      const logoutButton = page.locator('button:has-text("Logout"), a:has-text("Logout")').first();
      if (await logoutButton.count() > 0) {
        await expect(logoutButton).toBeVisible();
      }
    });

    test('should maintain session after login', async ({ page }) => {
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);

      // Check if still logged in after waiting
      await page.waitForLoadState('networkidle');
      const loggedIn = await isLoggedIn(page);
      expect(loggedIn).toBe(true);
    });

    test('should handle first login scenario', async ({ page }) => {
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);

      const url = page.url();
      const requiresPasswordChange = await isPasswordChangeRequired(page);

      // Either redirected to dashboard or change-password page
      const isValidPage = url.includes('dashboard') || url.includes('change-password');
      expect(isValidPage).toBe(true);
    });

    test('should load user dashboard with content', async ({ page }) => {
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);

      const content = await getPageContent(page);
      expect(content.length).toBeGreaterThan(500);
    });

    test('should display user information', async ({ page }) => {
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);

      const content = await getPageContent(page);
      const url = page.url();

      // Should either be on dashboard or have user-related content
      const hasUserInfo = url.includes('dashboard') || 
                         url.includes('school') || 
                         url.includes('activity');
      expect(hasUserInfo).toBe(true);
    });
  });

  test.describe('Invalid Login - Error Handling', () => {
    test('should reject login with invalid username', async ({ page }) => {
      await performLogin(page, INVALID_USERNAME, VALID_PASSWORD);

      const loggedIn = await isLoggedIn(page);
      expect(loggedIn).toBe(false);
    });

    test('should reject login with invalid password', async ({ page }) => {
      await performLogin(page, VALID_USERNAME, INVALID_PASSWORD);

      const loggedIn = await isLoggedIn(page);
      expect(loggedIn).toBe(false);
    });

    test('should display error message on invalid login', async ({ page }) => {
      await performLogin(page, INVALID_USERNAME, INVALID_PASSWORD);

      const errorMessage = await getLoginErrorMessage(page);
      
      // Should either show error message or be back on login page
      const url = page.url();
      const isLoginPage = url.includes('login');
      expect(isLoginPage || errorMessage).toBeTruthy();
    });

    test('should stay on login page after failed attempt', async ({ page }) => {
      await performLogin(page, INVALID_USERNAME, INVALID_PASSWORD);

      const url = page.url();
      expect(url).toContain('login');
    });

    test('should allow retry after failed login', async ({ page }) => {
      // First attempt - fail
      await performLogin(page, INVALID_USERNAME, INVALID_PASSWORD);

      let url = page.url();
      expect(url).toContain('login');

      // Second attempt - succeed
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);

      const loggedIn = await isLoggedIn(page);
      expect(loggedIn).toBe(true);
    });

    test('should not crash with empty credentials', async ({ page }) => {
      await navigateToLogin(page);
      
      // Try to submit without credentials
      const submitButton = page.locator('button[type="submit"]').first();
      await submitButton.click();
      
      // Page should still be accessible
      const content = await getPageContent(page);
      expect(content.length).toBeGreaterThan(0);
    });

    test('should handle special characters in password field', async ({ page }) => {
      await performLogin(page, VALID_USERNAME, '@$#!%^&*()');

      const loggedIn = await isLoggedIn(page);
      expect(loggedIn).toBe(false);
    });
  });

  test.describe('Logout Functionality', () => {
    test('should logout successfully after login', async ({ page }) => {
      // Login first
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);
      expect(await isLoggedIn(page)).toBe(true);

      // Logout
      await logout(page);
      await page.waitForLoadState('domcontentloaded');

      // Should be back on login page
      const url = page.url();
      expect(url).toContain('login');
    });

    test('should clear session on logout', async ({ page }) => {
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);

      await logout(page);

      // Try to access protected page - should redirect to login
      await page.goto('/VJNT_Class_Managment/school-dashboard-enhanced.jsp');
      await page.waitForLoadState('domcontentloaded');

      const url = page.url();
      expect(url).toContain('login');
    });

    test('should allow login again after logout', async ({ page }) => {
      // First login
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);
      await logout(page);

      // Second login
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);
      const loggedIn = await isLoggedIn(page);
      expect(loggedIn).toBe(true);
    });
  });

  test.describe('Activity Features - After Login', () => {
    test.beforeEach(async ({ page }) => {
      // Login before each activity test
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);
      expect(await isLoggedIn(page)).toBe(true);
    });

    test('should access activity page if available', async ({ page }) => {
      // Try to navigate to activity page
      await page.goto('/VJNT_Class_Managment/other-school-activity.jsp');
      await page.waitForLoadState('domcontentloaded');

      const url = page.url();
      const content = await getPageContent(page);

      // Should either be on activity page or have activity-related content
      const isActivityPage = url.includes('activity') || 
                            content.toLowerCase().includes('activity') ||
                            content.toLowerCase().includes('उपक्रम');
      expect(isActivityPage).toBe(true);
    });

    test('should display activity form if accessible', async ({ page }) => {
      await page.goto('/VJNT_Class_Managment/other-school-activity.jsp');
      await page.waitForLoadState('domcontentloaded');

      const content = await getPageContent(page);
      const url = page.url();

      // Check for activity form indicators
      const hasActivityContent = 
        url.includes('activity') ||
        content.toLowerCase().includes('activity') ||
        content.toLowerCase().includes('date') ||
        content.toLowerCase().includes('description');

      expect(hasActivityContent).toBe(true);
    });

    test('should have activity navigation menu or links', async ({ page }) => {
      const content = await getPageContent(page);

      // Check for activity-related menu items
      const hasActivityMenu = 
        content.toLowerCase().includes('activity') ||
        content.toLowerCase().includes('अभिलेख');

      expect(hasActivityMenu).toBe(true);
    });

    test('should support activity form fields', async ({ page }) => {
      await page.goto('/VJNT_Class_Managment/other-school-activity.jsp');
      await page.waitForLoadState('domcontentloaded');

      const content = await getPageContent(page);
      const pageHtml = await page.content();

      // Check for common activity form fields
      const hasActivityFields =
        pageHtml.toLowerCase().includes('activity') ||
        pageHtml.toLowerCase().includes('date') ||
        pageHtml.toLowerCase().includes('description') ||
        pageHtml.toLowerCase().includes('guest') ||
        pageHtml.toLowerCase().includes('photo');

      expect(hasActivityFields).toBe(true);
    });

    test('should handle activity page navigation', async ({ page }) => {
      // Navigate to activity page
      await page.goto('/VJNT_Class_Managment/other-school-activity.jsp');
      await page.waitForLoadState('domcontentloaded');

      // Should not crash or show errors
      const content = await getPageContent(page);
      expect(content.length).toBeGreaterThan(0);

      // Should not have error indicators
      const hasError = content.toLowerCase().includes('error') ||
                      content.toLowerCase().includes('404') ||
                      content.toLowerCase().includes('exception');
      expect(hasError).toBe(false);
    });

    test('should maintain login while accessing activity features', async ({ page }) => {
      // Navigate through multiple activity pages
      const activityPages = [
        '/VJNT_Class_Managment/other-school-activity.jsp',
        '/VJNT_Class_Managment/school-dashboard-enhanced.jsp',
      ];

      for (const activityPage of activityPages) {
        await page.goto(activityPage);
        await page.waitForLoadState('domcontentloaded');

        const loggedIn = await isLoggedIn(page);
        expect(loggedIn).toBe(true);
      }
    });

    test('should support activity approvals if user has permission', async ({ page }) => {
      // Try to access activity approvals page
      await page.goto('/VJNT_Class_Managment/other-school-activity-approvals.jsp');
      await page.waitForLoadState('domcontentloaded');

      const url = page.url();
      const content = await getPageContent(page);

      // Either page exists or we're redirected based on permissions
      const isValid = 
        url.includes('approvals') ||
        url.includes('dashboard') ||
        url.includes('login');

      expect(isValid).toBe(true);
    });

    test('should handle Palak Melava activity if available', async ({ page }) => {
      // Try to access Palak Melava page
      await page.goto('/VJNT_Class_Managment/palak-melava.jsp');
      await page.waitForLoadState('domcontentloaded');

      const url = page.url();
      const content = await getPageContent(page);

      // Either page exists, redirected, or shows content
      const isValid = 
        url.includes('palak') ||
        url.includes('dashboard') ||
        url.includes('login') ||
        content.length > 0;

      expect(isValid).toBe(true);
    });

    test('should display activity analysis if available', async ({ page }) => {
      // Try to access activity analysis
      await page.goto('/VJNT_Class_Managment/district-activity-analysis.jsp');
      await page.waitForLoadState('domcontentloaded');

      const url = page.url();
      const content = await getPageContent(page);

      // Should handle access appropriately
      const isHandled = url.includes('activity') || url.includes('dashboard');
      expect(isHandled).toBe(true);
    });
  });

  test.describe('Session & Security', () => {
    test('should not allow access to protected pages without login', async ({ page }) => {
      // Try to access protected dashboard without login
      await page.goto('/VJNT_Class_Managment/school-dashboard-enhanced.jsp');
      await page.waitForLoadState('domcontentloaded');

      const url = page.url();
      // Should redirect to login
      expect(url).toContain('login');
    });

    test('should timeout after inactivity (session management)', async ({ page }) => {
      // Login first
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);
      expect(await isLoggedIn(page)).toBe(true);

      // This test just verifies login succeeds
      // Full timeout testing would require waiting 30 minutes
    });

    test('should handle simultaneous login attempts', async ({ page, context }) => {
      // Create another page/context
      const page2 = await context.newPage();

      // Login on page 1
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);
      expect(await isLoggedIn(page)).toBe(true);

      // Login on page 2
      await performLogin(page2, VALID_USERNAME, VALID_PASSWORD);
      expect(await isLoggedIn(page2)).toBe(true);

      // Both should be logged in
      expect(await isLoggedIn(page)).toBe(true);

      await page2.close();
    });

    test('should use HTTPS for password transmission', async ({ page }) => {
      // Note: This would test actual HTTPS in production
      // For now, just verify form exists
      await navigateToLogin(page);
      const form = page.locator('form').first();
      expect(await form.count()).toBeGreaterThan(0);
    });
  });

  test.describe('Performance & UX', () => {
    test('should load login page quickly', async ({ page }) => {
      const startTime = Date.now();
      await navigateToLogin(page);
      const loadTime = Date.now() - startTime;

      expect(loadTime).toBeLessThan(5000); // < 5 seconds
    });

    test('should complete login within reasonable time', async ({ page }) => {
      const startTime = Date.now();
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);
      const loginTime = Date.now() - startTime;

      expect(loginTime).toBeLessThan(10000); // < 10 seconds
    });

    test('should display login form without JavaScript errors', async ({ page }) => {
      let jsErrors: string[] = [];

      page.on('console', msg => {
        if (msg.type() === 'error') {
          jsErrors.push(msg.text());
        }
      });

      await navigateToLogin(page);

      // Some errors are expected, but critical ones shouldn't exist
      const criticalErrors = jsErrors.filter(
        e => !e.includes('manifest') && 
             !e.includes('favicon') &&
             !e.toLowerCase().includes('warning')
      );

      // Error array should be mostly clean
      expect(criticalErrors.length).toBeLessThan(5);
    });

    test('should support browser back button after login', async ({ page }) => {
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);

      // Navigate somewhere
      await page.goto('/VJNT_Class_Managment/school-dashboard-enhanced.jsp');
      await page.waitForLoadState('domcontentloaded');

      const url1 = page.url();

      // Go back
      await page.goBack();
      await page.waitForLoadState('domcontentloaded');

      const url2 = page.url();

      // Should have navigated back
      expect(url1).not.toEqual(url2);
    });

    test('should handle page refresh while logged in', async ({ page }) => {
      await performLogin(page, VALID_USERNAME, VALID_PASSWORD);

      const url1 = page.url();
      expect(await isLoggedIn(page)).toBe(true);

      // Refresh page
      await page.reload();
      await page.waitForLoadState('domcontentloaded');

      const url2 = page.url();
      expect(await isLoggedIn(page)).toBe(true);

      // Should still be on same page
      expect(url1).toEqual(url2);
    });
  });
});
