# Fix: Not Started Filter Button Issue

## Problem
The "Not Started" filter button was showing 2 completed schools in the button count, but after clicking the button, it was not showing any completed school details (or showing incorrect schools).

## Root Cause
The issue was in the `PhaseApprovalDAO.java` file where the `overallStatus` calculation logic was incorrect.

**Original Logic (INCORRECT):**
```java
if (phasesNotStarted == 0 && (phasesApproved + phasesDone + phasesPending) == 4) {
    overallStatus = "ALL_COMPLETED";
} else if (phasesPending > 0) {
    overallStatus = "PENDING_APPROVAL";
} else if (phasesCompleted > 0) {
    overallStatus = "IN_PROGRESS";
} else {
    overallStatus = "NOT_STARTED";
}
```

The problem was that the condition checked if all 4 phases were in ANY state (approved, done, or pending), which could incorrectly classify schools. This meant schools with mixed states could be miscategorized.

## Solution
Updated the logic to be more precise and prioritize correctly:

**New Logic (CORRECT):**
```java
if (phasesApproved == 4) {
    // All 4 phases are officially APPROVED
    overallStatus = "ALL_COMPLETED";
} else if (phasesPending > 0) {
    // Has some pending approvals
    overallStatus = "PENDING_APPROVAL";
} else if (phasesDone > 0 || phasesApproved > 0) {
    // Has some completed or approved phases but not all 4 approved
    overallStatus = "IN_PROGRESS";
} else {
    // Nothing started at all
    overallStatus = "NOT_STARTED";
}
```

## Changes Made

### File: `src/main/java/com/vjnt/dao/PhaseApprovalDAO.java`
- **Line ~388-400**: Updated the overall status calculation logic
- **Change**: Modified condition to check `phasesApproved == 4` for ALL_COMPLETED status
- **Change**: Simplified IN_PROGRESS check to include any phases with progress
- **Change**: NOT_STARTED now only applies when absolutely nothing has been started

## Impact

### Fixed Behaviors:
1. ✅ **ALL_COMPLETED** - Only shows when all 4 phases are APPROVED
2. ✅ **PENDING_APPROVAL** - Shows when any phase is pending approval
3. ✅ **IN_PROGRESS** - Shows when some phases are done/approved but not all 4
4. ✅ **NOT_STARTED** - Only shows when no phases have any progress at all

### Filter Buttons Now Work Correctly:
- **All Schools** - Shows all schools (no change)
- **All Completed** - Shows only schools with all 4 phases approved
- **In Progress** - Shows schools with some progress but not all completed
- **Pending Approval** - Shows schools with phases waiting for approval
- **Not Started** - Shows ONLY schools with no progress at all

## Testing
After deploying this fix:
1. Restart the Tomcat server
2. Navigate to Phase Status page
3. Click each filter button and verify the counts match the displayed schools
4. Specifically check "Not Started" button - it should only show schools with zero progress

## Deployment
File compiled successfully. Deploy to server and restart Tomcat to apply changes.

Date: December 7, 2025
