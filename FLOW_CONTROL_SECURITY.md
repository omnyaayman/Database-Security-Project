# 🔒 SRMS Flow Control & Data Export Prevention

## Security Implementation Summary

This document describes the comprehensive **Flow Control** security features implemented in the Secure Student Records Management System (SRMS) to prevent unauthorized export of classified data.

---

## 🎯 Objective

**Prevent users from downloading, exporting, saving, printing, or copying highly classified data out of the system.**

Specifically:

- ✅ Block export of **Secret (Level 3)** and **Top Secret (Level 4)** data
- ✅ Disable copy/paste for high-classification panels
- ✅ Data remains **VISIBLE** but **CANNOT BE EXTRACTED**

---

## 🛡️ Security Features Implemented

### 1. **SecureText Widget** (Lines 79-141)

Custom text widget that blocks all export operations for classified data:

**Blocked Operations:**

- ❌ `Ctrl+C` - Copy
- ❌ `Ctrl+X` - Cut
- ❌ `Ctrl+V` - Paste
- ❌ `Ctrl+P` - Print
- ❌ `Ctrl+S` - Save
- ❌ `Ctrl+A` - Select All
- ❌ Right-click context menu
- ❌ Export to clipboard (`exportselection=False`)

**Features:**

- Read-only mode for classified data
- Security warning popup on blocked attempts
- Audit logging of violation attempts
- Classification level display

---

### 2. **SecureTreeview Widget** (Lines 143-197)

Custom table/grid widget that blocks data extraction:

**Blocked Operations:**

- ❌ `Ctrl+C` - Copy selected rows
- ❌ `Ctrl+X` - Cut
- ❌ `Ctrl+P` - Print
- ❌ `Ctrl+S` - Save
- ❌ `Ctrl+A` - Select All
- ❌ Right-click context menu
- ❌ Clipboard export

**Features:**

- Visual classification indicators
- Security warnings on blocked operations
- Audit trail logging
- Data remains fully visible and navigable

---

### 3. **Window-Level Protection** (Lines 303-339)

Application-wide security for users with Secret/Top Secret clearance:

**Blocked Operations:**

- ❌ `Print Screen` - Full screen capture
- ❌ `Alt+Print Screen` - Window capture
- ❌ `Win+Shift+S` - Snipping Tool
- ❌ `Ctrl+Shift+S` - Alternative screenshot
- ❌ `F12` - Developer tools

**Features:**

- Security watermark in window title
- Immediate blocking with error message
- Audit logging with username
- "Incident logged" warning to deter violations

---

### 4. **Visual Security Indicators** (Lines 948-1002)

#### Classification Banners

For Secret/Top Secret data views:

- 🔴 **RED BANNER** with classification level
- ⚠️ **WARNING BAR** listing all blocked operations
- 📋 **WATERMARK** overlay ("SECRET NO EXPORT" / "TOP SECRET NO EXPORT")

#### Warning Messages

Clear, prominent warnings displayed:

```
🔒 SECRET LEVEL CLASSIFIED DATA 🔒
⚠️ ALL EXPORT OPERATIONS BLOCKED: Copy • Print • Save • Screenshot • Right-Click
Data is visible for authorized viewing only. Unauthorized export attempts will be logged.
```

---

### 5. **Security Audit Logging** (Lines 18-22, 118-120, 178-180, 324-326)

All blocked operations are logged to `security_audit.log`:

**Log Format:**

```
2025-12-21 01:05:00 - WARNING - BLOCKED: Copy/Export attempt on SECRET data (SecureTreeview widget)
2025-12-21 01:05:15 - WARNING - BLOCKED: Screenshot attempt by user admin1 viewing SECRET data
```

**Logged Events:**

- Copy/paste attempts
- Export attempts
- Screenshot attempts
- User identity (when available)
- Classification level
- Timestamp

---

## 📊 Where Security is Applied

### **Secret Level (3) Data:**

1. **Grades** (`show_grades()` - Line 768)
   - Student grades are classified as SECRET
   - All export operations blocked
   - Visible to: Admin, Instructors (for their courses)

2. **Attendance Records** (`show_attendance()` - Line 849)
   - Attendance data classified as SECRET
   - Export/copy blocked
   - Visible to: Admin, Instructors, TAs (for their courses)

3. **Student Management** (`show_students()` - Line 702)
   - Student personal data (Confidential - Level 2)
   - Partial restrictions applied

### **Top Secret Level (4) Data:**

- Reserved for highly sensitive administrative data
- Same protections as Secret, with enhanced visual warnings
- Darker red banner and stronger language

---

## 🧪 Testing the Security Features

### Test 1: Copy Prevention

1. Login as `admin1` / `Admin@123`
2. Navigate to "📊 View Grades"
3. Try to select and copy data with `Ctrl+C`
4. **Expected:** Warning popup, operation blocked, logged

### Test 2: Right-Click Block

1. View any Secret data (grades/attendance)
2. Right-click on the data table
3. **Expected:** No context menu appears, warning shown

### Test 3: Screenshot Block

1. Login with Secret clearance (Instructor or Admin)
2. View classified data
3. Press `Print Screen` key
4. **Expected:** Error message, screenshot blocked, logged

### Test 4: Print Block

1. View Secret data
2. Press `Ctrl+P`
3. **Expected:** Print dialog does NOT appear, warning shown

### Test 5: Visual Indicators

1. View grades or attendance
2. **Expected:** See:
   - Red classification banner
   - Yellow warning bar
   - Watermark overlay
   - Enhanced record count with classification

### Test 6: Audit Log

1. Perform several blocked operations
2. Check `security_audit.log` file
3. **Expected:** All attempts logged with timestamps

---

## 🔐 Classification Levels

| Level | Name | Color | Data Types | Export Blocked? |
|-------|------|-------|------------|-----------------|
| 1 | Unclassified | Gray | Public course info | ❌ No |
| 2 | Confidential | Orange | Student profiles | ⚠️ Partial |
| 3 | **Secret** | **Red** | **Grades, Attendance** | ✅ **YES** |
| 4 | **Top Secret** | **Dark Red** | **Admin data** | ✅ **YES** |

---

## 💡 Key Design Principles

### 1. **Data Remains Visible**

- Users can VIEW all data they're authorized to see
- No functionality is removed from viewing
- Only EXPORT is blocked

### 2. **Clear Communication**

- Users are immediately informed why operations are blocked
- Classification levels are clearly displayed
- No silent failures

### 3. **Defense in Depth**

- Multiple layers of protection
- Widget-level blocking
- Window-level blocking
- Keyboard shortcut blocking
- Visual deterrents

### 4. **Audit Trail**

- All violation attempts logged
- Timestamps and user info recorded
- Supports compliance and investigation

### 5. **User Experience**

- Warnings are informative, not cryptic
- Visual indicators are clear
- System remains usable for authorized viewing

---

## 📝 Code Locations

| Feature | File | Lines | Description |
|---------|------|-------|-------------|
| SecureText | SRMS_GUI.py | 79-141 | Secure text widget |
| SecureTreeview | SRMS_GUI.py | 143-197 | Secure table widget |
| Window Protection | SRMS_GUI.py | 303-339 | Screenshot blocking |
| Audit Logging | SRMS_GUI.py | 18-22 | Log setup |
| Grades View | SRMS_GUI.py | 768-795 | Secret data view |
| Attendance View | SRMS_GUI.py | 849-873 | Secret data view |
| Table Creation | SRMS_GUI.py | 948-1002 | Visual indicators |

---

## ✅ Compliance Checklist

- ✅ **Copy/Paste Blocked** - Ctrl+C, Ctrl+V, Ctrl+X disabled
- ✅ **Export Blocked** - No clipboard export
- ✅ **Print Blocked** - Ctrl+P disabled
- ✅ **Save Blocked** - Ctrl+S disabled
- ✅ **Screenshot Blocked** - Print Screen disabled
- ✅ **Right-Click Blocked** - Context menu disabled
- ✅ **Data Visible** - All authorized data displays correctly
- ✅ **Visual Warnings** - Clear classification banners
- ✅ **Audit Logging** - All attempts logged
- ✅ **User Feedback** - Clear error messages

---

## 🎓 Bonus Features Implemented

### Bonus +1: Block Export of Secret/Top Secret Data ✅

- Comprehensive blocking of all export methods
- Multi-layer protection
- Audit trail

### Bonus +1: Disable Copy/Paste for High-Classification Panels ✅

- Copy/paste completely disabled
- Data remains visible
- Clear user communication

**Total Bonus Points: +2** 🎉

---

## 🚀 Future Enhancements

Potential additional security measures:

1. **Screen Recording Detection** - Detect and block screen recording software
2. **DRM-style Protection** - Prevent external capture tools
3. **Session Recording** - Record all user actions for audit
4. **Watermark with Username** - Overlay username on classified views
5. **Time-based Access** - Auto-lock after inactivity
6. **Two-Factor for Classified** - Require 2FA for Secret+ data

---

## 📞 Support

For questions about the security implementation:

- Review the code comments in `SRMS_GUI.py`
- Check the audit log: `security_audit.log`
- Test with the provided test credentials

---

**Document Version:** 1.0  
**Last Updated:** 2025-12-21  
**Author:** SRMS Development Team  
**Classification:** UNCLASSIFIED (Documentation)
