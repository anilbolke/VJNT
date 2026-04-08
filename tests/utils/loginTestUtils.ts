import { Page, expect } from '@playwright/test';

/**
 * Utility functions for login page testing
 */

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface UserSession {
  username: string;
  userType: string;
  userId: string;
  isLoggedIn: boolean;
}

/**
 * Navigate to login page
 */
export async function navigateToLogin(page: Page) {
  await page.goto('/VJNT_Class_Managment/login');
  await page.waitForLoadState('domcontentloaded');
}

/**
 * Enter username and password
 */
export async function enterCredentials(
  page: Page,
  username: string,
  password: string
) {
  // Try multiple selectors for username field
  const usernameSelectors = [
    'input[name="username"]',
    'input[id="username"]',
    'input[placeholder*="username" i]',
    'input[type="text"]',
  ];

  let usernameEntered = false;
  for (const selector of usernameSelectors) {
    const element = page.locator(selector).first();
    if (await element.count() > 0) {
      await element.fill(username);
      usernameEntered = true;
      break;
    }
  }

  if (!usernameEntered) {
    throw new Error('Could not find username input field');
  }

  // Try multiple selectors for password field
  const passwordSelectors = [
    'input[name="password"]',
    'input[id="password"]',
    'input[placeholder*="password" i]',
    'input[type="password"]',
  ];

  let passwordEntered = false;
  for (const selector of passwordSelectors) {
    const element = page.locator(selector).first();
    if (await element.count() > 0) {
      await element.fill(password);
      passwordEntered = true;
      break;
    }
  }

  if (!passwordEntered) {
    throw new Error('Could not find password input field');
  }
}

/**
 * Click login button
 */
export async function clickLoginButton(page: Page) {
  const loginButtonSelectors = [
    'button:has-text("Login")',
    'button:has-text("login")',
    'button[type="submit"]',
    'button:has-text("Sign In")',
    'input[type="submit"]',
  ];

  let clicked = false;
  for (const selector of loginButtonSelectors) {
    const button = page.locator(selector).first();
    if (await button.count() > 0) {
      await button.click();
      clicked = true;
      break;
    }
  }

  if (!clicked) {
    throw new Error('Could not find login button');
  }
}

/**
 * Perform complete login
 */
export async function performLogin(
  page: Page,
  username: string,
  password: string
) {
  await navigateToLogin(page);
  await enterCredentials(page, username, password);
  await clickLoginButton(page);
  await page.waitForLoadState('networkidle');
}

/**
 * Check if logged in by verifying session or dashboard presence
 */
export async function isLoggedIn(page: Page): Promise<boolean> {
  const url = page.url();

  // Check if redirected away from login page
  if (url.includes('login')) {
    return false;
  }

  // Check for dashboard indicators
  const dashboardIndicators = [
    'dashboard',
    'school-dashboard',
    'district-dashboard',
    'division-dashboard',
    'data-admin-dashboard',
  ];

  const isDashboard = dashboardIndicators.some(indicator =>
    url.includes(indicator)
  );

  if (isDashboard) {
    return true;
  }

  // Check for logout button (sign of logged-in state)
  const logoutButton = page.locator('button:has-text("Logout"), a:has-text("Logout")');
  return await logoutButton.count() > 0;
}

/**
 * Check for login error message
 */
export async function getLoginErrorMessage(page: Page): Promise<string | null> {
  const errorSelectors = [
    '.error',
    '.alert-danger',
    '.alert-error',
    '[class*="error"]',
    '[class*="invalid"]',
    'div:has-text("Invalid")',
    'div:has-text("incorrect")',
  ];

  for (const selector of errorSelectors) {
    const element = page.locator(selector).first();
    if (await element.count() > 0) {
      const text = await element.textContent();
      if (text) return text.trim();
    }
  }

  return null;
}

/**
 * Verify login page displays correctly
 */
export async function verifyLoginPageLoaded(page: Page): Promise<boolean> {
  const url = page.url();
  if (!url.includes('login')) {
    return false;
  }

  // Check for form elements
  const usernameInput = page.locator('input[name="username"]');
  const passwordInput = page.locator('input[name="password"]');
  const submitButton = page.locator('button[type="submit"]');

  return (
    (await usernameInput.count()) > 0 &&
    (await passwordInput.count()) > 0 &&
    (await submitButton.count()) > 0
  );
}

/**
 * Logout
 */
export async function logout(page: Page) {
  const logoutSelectors = [
    'button:has-text("Logout")',
    'a:has-text("Logout")',
    'button:has-text("logout")',
    'a:has-text("logout")',
  ];

  let found = false;
  for (const selector of logoutSelectors) {
    const button = page.locator(selector).first();
    if (await button.count() > 0) {
      await button.click();
      found = true;
      break;
    }
  }

  if (!found) {
    throw new Error('Logout button not found');
  }

  await page.waitForLoadState('domcontentloaded');
}

/**
 * Get page content for verification
 */
export async function getPageContent(page: Page): Promise<string> {
  return (await page.textContent('body')) || '';
}

/**
 * Check if page requires password change
 */
export async function isPasswordChangeRequired(page: Page): Promise<boolean> {
  const url = page.url();
  return url.includes('change-password');
}

/**
 * Get current user info from session (if accessible in page)
 */
export async function getUserInfo(page: Page): Promise<Partial<UserSession> | null> {
  try {
    const userInfo = await page.evaluate(() => {
      // Try to get from window object if set by page
      return (window as any).userInfo || null;
    });
    return userInfo;
  } catch {
    return null;
  }
}
