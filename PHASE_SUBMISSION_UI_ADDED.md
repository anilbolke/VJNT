# ✅ Phase Submission UI Added to Dashboard

## Problem Fixed
After completing a phase, School Coordinators couldn't find the option to submit it for approval.

## ✅ Solution Applied

### Changes Made to school-dashboard-enhanced.jsp:

#### 1. **Added Imports**
```jsp
<%@ page import="com.vjnt.dao.PhaseApprovalDAO" %>
<%@ page import="com.vjnt.model.PhaseApproval" %>
```

#### 2. **Added Phase Approval Status Check**
```jsp
PhaseApprovalDAO approvalDAO = new PhaseApprovalDAO();
PhaseApproval phase1Approval = approvalDAO.getPhaseApproval(udiseNo, 1);
PhaseApproval phase2Approval = approvalDAO.getPhaseApproval(udiseNo, 2);
PhaseApproval phase3Approval = approvalDAO.getPhaseApproval(udiseNo, 3);
PhaseApproval phase4Approval = approvalDAO.getPhaseApproval(udiseNo, 4);

int pendingApprovalsCount = approvalDAO.getPendingApprovalCount(udiseNo);
```

#### 3. **Added Submit Buttons to Each Phase Card**
For School Coordinators only, when phase is complete and not yet submitted or was rejected:

```jsp
<% if (user.getUserType().equals(User.UserType.SCHOOL_COORDINATOR) && 
       phase1Complete && 
       (phase1Approval == null || phase1Approval.isRejected())) { %>
    <button class="btn-submit-phase" onclick="submitPhaseForApproval(1)">
        📤 Submit for Approval
    </button>
<% } %>
```

#### 4. **Added Approval Status Display**
Shows current approval status for each phase:

- ⏳ **Pending Approval** - Submitted, waiting for Head Master
- ✓ **Approved by Head Master** - Phase complete and approved
- ✗ **Rejected - Resubmit Required** - Needs revision
- ✓ **Completed** / ⏳ **In Progress** / 🔒 **Not Started** - Default statuses

#### 5. **Added Submit Function**
JavaScript function to handle submission:

```javascript
function submitPhaseForApproval(phaseNumber) {
    const remarks = prompt('Enter remarks (optional):');
    if (remarks === null) return;
    
    fetch('/submit-phase', {
        method: 'POST',
        body: 'phaseNumber=' + phaseNumber + '&remarks=' + remarks
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            alert('✓ ' + data.message);
            location.reload();
        }
    });
}
```

#### 6. **Added Head Master Approvals Link**
In header, shows pending approvals count:

```jsp
<% if (user.getUserType().equals(User.UserType.HEAD_MASTER) && 
       pendingApprovalsCount > 0) { %>
    <a href="/phase-approvals.jsp">
        ⏳ Pending Approvals (<%= pendingApprovalsCount %>)
    </a>
<% } %>
```

#### 7. **Added CSS Styles**
```css
.phase-status.pending-approval {
    background: #ff9800;
    color: white;
}

.phase-status.rejected {
    background: #f44336;
    color: white;
}

.btn-submit-phase {
    width: 100%;
    padding: 12px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    border-radius: 8px;
}
```

---

## 📊 How It Works

### For School Coordinator:

#### When Phase is Complete:
```
Phase 1 Card shows:
┌────────────────────────────────────┐
│ चरण 1 (Phase 1)            ✅      │
│ Progress: 100%                     │
│ ████████████████████████ 100%      │
│                                    │
│ Status: ✓ Completed                │
│                                    │
│ [📤 Submit for Approval]           │ ← NEW BUTTON!
└────────────────────────────────────┘
```

#### After Clicking Submit:
1. Prompt asks for remarks (optional)
2. Confirmation dialog
3. Submits to `/submit-phase` servlet
4. Shows success message
5. Page reloads
6. Button disappears
7. Status changes to "⏳ Pending Approval"

#### If Head Master Rejects:
```
┌────────────────────────────────────┐
│ चरण 1 (Phase 1)            ❌      │
│                                    │
│ Status: ✗ Rejected - Resubmit     │
│        Required                    │
│                                    │
│ [📤 Submit for Approval]           │ ← Button appears again
└────────────────────────────────────┘
```

### For Head Master:

#### In Header:
```
┌──────────────────────────────────────────┐
│ 🏫 School Name                          │
│                                          │
│ [⏳ Pending Approvals (2)]              │ ← NEW LINK!
│ [🔐 Change Password] [🚪 Logout]        │
└──────────────────────────────────────────┘
```

#### Clicking Link:
Goes to `phase-approvals.jsp` to review and approve/reject phases

---

## 🎯 Workflow

### Complete Workflow:

```
1. School Coordinator fills phase data
   ↓
2. Phase shows 100% completion
   ↓
3. [📤 Submit for Approval] button appears
   ↓
4. Click button → Enter remarks → Confirm
   ↓
5. Phase submitted (status: Pending Approval)
   ↓
6. Head Master sees notification
   ↓
7. Head Master clicks "Pending Approvals"
   ↓
8. Reviews phase details
   ↓
9. Approves OR Rejects
   ↓
10. If APPROVED: Phase complete ✓
    If REJECTED: Button reappears for resubmission
```

---

## 🔍 Button Visibility Logic

Button appears when **ALL** conditions are met:

1. ✅ User is SCHOOL_COORDINATOR
2. ✅ Phase is 100% complete (all students saved)
3. ✅ Phase NOT yet submitted (approval == null)
   **OR**
   Phase was rejected (approval.isRejected())

Button hidden when:
- ❌ Phase not complete
- ❌ Phase pending approval
- ❌ Phase already approved
- ❌ User is HEAD_MASTER

---

## 📱 UI Changes Summary

| Location | Change | For User |
|----------|--------|----------|
| Phase Cards | Submit button | School Coordinator |
| Phase Cards | Approval status | Both |
| Header | Approvals link | Head Master |
| Phase Status | New colors (pending, rejected) | Both |

---

## 🎨 Visual Example

### Before (No Submit Option):
```
┌────────────────────┐
│ Phase 1       ✅   │
│ Progress: 100%     │
│ ✓ Completed        │
└────────────────────┘
```

### After (With Submit Button):
```
┌────────────────────┐
│ Phase 1       ✅   │
│ Progress: 100%     │
│ ✓ Completed        │
│                    │
│ [Submit Approval]  │ ← NEW!
└────────────────────┘
```

### After Submission:
```
┌────────────────────┐
│ Phase 1       ⏳   │
│ Progress: 100%     │
│ ⏳ Pending Approval│
└────────────────────┘
```

### After Approval:
```
┌────────────────────┐
│ Phase 1       ✅   │
│ Progress: 100%     │
│ ✓ Approved by HM   │
└────────────────────┘
```

---

## ✅ Testing Checklist

- [ ] Create phase_approvals table
- [ ] Restart Tomcat
- [ ] Login as School Coordinator
- [ ] Complete Phase 1 (fill all students)
- [ ] Check "Submit for Approval" button appears
- [ ] Click button
- [ ] Enter remarks
- [ ] Confirm submission
- [ ] Verify status changes to "Pending Approval"
- [ ] Login as Head Master (same UDISE)
- [ ] See "Pending Approvals (1)" in header
- [ ] Click to view approvals
- [ ] Approve phase
- [ ] Login back as School Coordinator
- [ ] Verify phase shows "Approved by Head Master"

---

## 🚀 Files Modified

1. **school-dashboard-enhanced.jsp**
   - Added PhaseApprovalDAO imports
   - Added approval status checking
   - Added submit buttons (conditional)
   - Added approval status display
   - Added Head Master approvals link
   - Added CSS for new statuses
   - Added JavaScript submit function

---

## 📝 Additional Features

### For School Coordinator:
- ✅ See which phases are pending approval
- ✅ See which phases are approved
- ✅ Resubmit rejected phases
- ✅ Add remarks during submission

### For Head Master:
- ✅ Notification badge with count
- ✅ Quick link to approvals page
- ✅ See all submitted phases
- ✅ Track approval history

---

**Status:** ✅ Complete  
**Date:** November 17, 2024  
**Issue:** Submit button missing after phase completion  
**Resolution:** Added conditional submit buttons with approval workflow

Now School Coordinators can easily submit completed phases for approval! 🎉
