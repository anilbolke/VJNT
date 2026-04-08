import { Page, expect } from '@playwright/test';

/**
 * Utility functions for public school lookup testing
 */

export interface SchoolData {
  schoolName?: string;
  udiseNo?: string;
  district?: string;
  block?: string;
  village?: string;
}

/**
 * Navigate to public school lookup page with UDISE number
 */
export async function navigateToPublicSchoolLookup(page: Page, udise: string) {
  const url = `/VJNT_Class_Managment/public-school-lookup?udise=${udise}`;
  await page.goto(url);
}

/**
 * Wait for school data to load
 */
export async function waitForSchoolDataToLoad(page: Page) {
  await page.waitForLoadState('networkidle');
  await page.waitForSelector('.school-info, .school-details, h2', { timeout: 5000 });
}

/**
 * Verify school details are displayed
 */
export async function verifySchoolDetailsAreDisplayed(page: Page) {
  const content = page.locator('body');
  await expect(content).toBeVisible();
  
  // Check if school information is displayed
  const schoolInfo = page.locator(
    '.school-info, .school-details, [data-test="school-info"], h2'
  );
  return await schoolInfo.count() > 0;
}

/**
 * Extract school name from page
 */
export async function getSchoolName(page: Page): Promise<string | null> {
  const schoolNameElement = page.locator(
    '.school-name, h2, [data-test="school-name"]'
  ).first();
  
  if (await schoolNameElement.count() > 0) {
    return await schoolNameElement.textContent();
  }
  return null;
}

/**
 * Verify error message for invalid UDISE
 */
export async function verifyErrorMessageDisplayed(page: Page) {
  const errorMessages = [
    'not found',
    'error',
    'invalid',
    'school not found',
    'No school'
  ];
  
  const pageText = await page.textContent('body');
  return errorMessages.some(msg => pageText?.toLowerCase().includes(msg.toLowerCase()));
}

/**
 * Get contact information from page
 */
export async function getContactInformation(page: Page): Promise<string[]> {
  const contacts = await page.locator(
    '.contact-info, .school-contact, [data-test*="contact"], .staff-info'
  ).allTextContents();
  return contacts;
}

/**
 * Get school activities from page
 */
export async function getSchoolActivities(page: Page): Promise<string[]> {
  const activities = await page.locator(
    '.activity, .school-activity, [data-test*="activity"], .activities'
  ).allTextContents();
  return activities;
}

/**
 * Get Palak Melava meetings info
 */
export async function getPalakMelavaMeetings(page: Page): Promise<string[]> {
  const meetings = await page.locator(
    '.melava, .meeting, .parent-meeting, [data-test*="meeting"]'
  ).allTextContents();
  return meetings;
}

/**
 * Verify images are loaded (if any)
 */
export async function verifyImagesLoaded(page: Page): Promise<number> {
  const images = await page.locator('img[src*="servlet"]').all();
  let loadedCount = 0;
  
  for (const img of images) {
    const isVisible = await img.isVisible().catch(() => false);
    if (isVisible) {
      loadedCount++;
    }
  }
  
  return loadedCount;
}

/**
 * Check if page has school data or error
 */
export async function hasSchoolData(page: Page): Promise<boolean> {
  const errorExists = await verifyErrorMessageDisplayed(page);
  const dataExists = await verifySchoolDetailsAreDisplayed(page);
  return !errorExists && dataExists;
}

/**
 * Get all text content for verification
 */
export async function getPageContent(page: Page): Promise<string> {
  return (await page.textContent('body')) || '';
}
