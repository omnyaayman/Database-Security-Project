# 🧪 Flow Control Security Testing Guide

## Quick Test Checklist

Use this guide to verify all export blocking and copy/paste prevention features.

---

## 🔐 Test Credentials

```
Username: admin1
Password: Admin@123
Role: Admin
Clearance: Level 4 (Top Secret)
```

---

## ✅ Test Suite

### Test 1: Copy Prevention on Grades (SECRET Data)

**Steps:**

1. Login as admin1
2. Click "📊 View Grades"
3. Observe the RED classification banner
4. Try to select text in the table
5. Press `Ctrl+C`

**Expected Results:**

- ✅ Red banner shows "🔒 SECRET LEVEL CLASSIFIED DATA 🔒"
- ✅ Warning bar shows all blocked operations
- ✅ Watermark "SECRET NO EXPORT" visible
- ✅ Popup appears: "Operation Blocked"
- ✅ Message explains classification and restrictions
- ❌ Data is NOT copied to clipboard

**Status:** [ ] PASS [ ] FAIL

---

### Test 2: Right-Click Context Menu Block

**Steps:**

1. While viewing Grades
2. Right-click anywhere on the data table

**Expected Results:**

- ✅ Popup appears: "Operation Blocked"
- ❌ Context menu does NOT appear
- ✅ Entry logged in security_audit.log

**Status:** [ ] PASS [ ] FAIL

---

### Test 3: Print Screen Block

**Steps:**

1. While viewing Grades or Attendance
2. Press `Print Screen` key

**Expected Results:**

- ✅ Error dialog: "🚫 SCREENSHOT BLOCKED"
- ✅ Message: "This incident has been logged"
- ✅ Window title shows "🔒 TOP SECRET - SRMS..."
- ❌ Screenshot is NOT captured

**Status:** [ ] PASS [ ] FAIL

---

### Test 4: Print Dialog Block

**Steps:**

1. View Secret data
2. Press `Ctrl+P`

**Expected Results:**

- ✅ Warning popup appears
- ❌ Print dialog does NOT open
- ✅ Logged in security_audit.log

**Status:** [ ] PASS [ ] FAIL

---

### Test 5: Save Operation Block

**Steps:**

1. View Secret data
2. Press `Ctrl+S`

**Expected Results:**

- ✅ Warning popup appears
- ❌ Save dialog does NOT open

**Status:** [ ] PASS [ ] FAIL

---

### Test 6: Select All Block

**Steps:**

1. View Grades
2. Press `Ctrl+A`

**Expected Results:**

- ✅ Warning popup appears
- ❌ Text is NOT selected

**Status:** [ ] PASS [ ] FAIL

---

### Test 7: Attendance Records (SECRET)

**Steps:**

1. Click "📅 View Attendance"
2. Try `Ctrl+C` on the table

**Expected Results:**

- ✅ Same protections as Grades
- ✅ RED classification banner
- ✅ Copy blocked with warning

**Status:** [ ] PASS [ ] FAIL

---

### Test 8: Visual Security Indicators

**Steps:**

1. Navigate to Grades view
2. Observe all visual elements

**Expected Results:**

- ✅ Red banner at top: "🔒 SECRET LEVEL CLASSIFIED DATA 🔒"
- ✅ Yellow warning bar with blocked operations list
- ✅ Watermark overlay visible in center
- ✅ Record count shows classification level
- ✅ Warning text mentions logging

**Status:** [ ] PASS [ ] FAIL

---

### Test 9: Audit Log Verification

**Steps:**

1. Perform Tests 1-7
2. Open `security_audit.log` in the project folder
3. Check log entries

**Expected Results:**

- ✅ File exists: `security_audit.log`
- ✅ Contains entries for each blocked operation
- ✅ Timestamps are accurate
- ✅ Classification levels mentioned
- ✅ Username included (when applicable)

**Example Log Entry:**

```
2025-12-21 01:05:00 - WARNING - BLOCKED: Copy/Export attempt on SECRET data (SecureTreeview widget)
2025-12-21 01:05:15 - WARNING - BLOCKED: Screenshot attempt by user admin1 viewing TOP SECRET data
```

**Status:** [ ] PASS [ ] FAIL

---

### Test 10: Data Visibility (Critical!)

**Steps:**

1. View Grades
2. View Attendance
3. Verify all data displays correctly

**Expected Results:**

- ✅ All grades are VISIBLE in the table
- ✅ All attendance records are VISIBLE
- ✅ Data is readable and navigable
- ✅ Scrolling works normally
- ✅ Only EXPORT is blocked, not viewing

**Status:** [ ] PASS [ ] FAIL

---

### Test 11: Lower Classification Data (Control Test)

**Steps:**

1. Click "📚 Manage Courses" (Unclassified - Level 1)
2. Try `Ctrl+C`

**Expected Results:**

- ❌ NO red banner
- ❌ NO warning bar
- ✅ Copy WORKS normally (not blocked)
- ✅ Right-click works
- ✅ No security restrictions

**Status:** [ ] PASS [ ] FAIL

---

### Test 12: Window Title Security

**Steps:**

1. Login as admin1 (Clearance 4)
2. Check window title bar

**Expected Results:**

- ✅ Title shows: "🔒 TOP SECRET - SRMS - Admin Dashboard"
- ✅ Security indicator visible at all times

**Status:** [ ] PASS [ ] FAIL

---

### Test 13: Cut Operation Block

**Steps:**

1. View Secret data
2. Press `Ctrl+X`

**Expected Results:**

- ✅ Warning popup appears
- ❌ Cut operation blocked

**Status:** [ ] PASS [ ] FAIL

---

### Test 14: Paste Prevention

**Steps:**

1. Copy some text from outside the app
2. View Secret data
3. Press `Ctrl+V`

**Expected Results:**

- ✅ Warning popup appears
- ❌ Paste operation blocked

**Status:** [ ] PASS [ ] FAIL

---

### Test 15: Multiple Keyboard Shortcuts

**Steps:**

1. View Grades
2. Try each shortcut:
   - `Ctrl+C` (copy)
   - `Ctrl+X` (cut)
   - `Ctrl+V` (paste)
   - `Ctrl+P` (print)
   - `Ctrl+S` (save)
   - `Ctrl+A` (select all)
   - `Print Screen`
   - `F12`

**Expected Results:**

- ✅ ALL shortcuts blocked
- ✅ Warning appears for each
- ✅ No operations succeed

**Status:** [ ] PASS [ ] FAIL

---

## 📊 Test Results Summary

| Test # | Test Name | Status | Notes |
|--------|-----------|--------|-------|
| 1 | Copy Prevention | ⬜ | |
| 2 | Right-Click Block | ⬜ | |
| 3 | Print Screen Block | ⬜ | |
| 4 | Print Dialog Block | ⬜ | |
| 5 | Save Block | ⬜ | |
| 6 | Select All Block | ⬜ | |
| 7 | Attendance Security | ⬜ | |
| 8 | Visual Indicators | ⬜ | |
| 9 | Audit Logging | ⬜ | |
| 10 | Data Visibility | ⬜ | |
| 11 | Unclassified Control | ⬜ | |
| 12 | Window Title | ⬜ | |
| 13 | Cut Block | ⬜ | |
| 14 | Paste Block | ⬜ | |
| 15 | All Shortcuts | ⬜ | |

**Total Tests:** 15  
**Passed:** ___  
**Failed:**___  
**Pass Rate:** ___%

---

## 🎯 Acceptance Criteria

For the feature to be considered complete:

- ✅ All 15 tests must PASS
- ✅ Data remains visible in all cases
- ✅ Audit log captures all violations
- ✅ Visual warnings are clear and prominent
- ✅ No false positives (unclassified data not blocked)

---

## 🐛 Troubleshooting

### Issue: Copy still works

**Solution:** Check that classification level is >= 3 in the `create_table()` call

### Issue: No audit log file

**Solution:** Check write permissions in the project folder

### Issue: Warnings don't appear

**Solution:** Verify `messagebox` import and SecureTreeview/SecureText usage

### Issue: Data not visible

**Solution:** Check that widgets are properly configured and data is being inserted

---

## 📝 Test Notes

**Tester Name:** _________________  
**Test Date:** _________________  
**Application Version:** SRMS v1.0  
**Test Environment:** Windows / Python 3.x / Tkinter

**Additional Observations:**

```
[Space for notes]
```

---

## ✅ Sign-Off

- [ ] All tests completed
- [ ] All tests passed
- [ ] Audit log verified
- [ ] Documentation reviewed
- [ ] Ready for demonstration

**Tested By:** _________________  
**Date:** _________________  
**Signature:** _________________

---

**End of Testing Guide**
