-- ============================================
-- Database Security Term Project
-- Part A: SQL Server Roles and Permissions
-- ============================================
-- This script creates SQL roles and assigns permissions (RBAC)

USE SecureStudentRecords;
GO

-- ============================================
-- CREATE SQL SERVER ROLES
-- ============================================

-- Drop roles if they exist
IF DATABASE_PRINCIPAL_ID('AdminRole') IS NOT NULL
    DROP ROLE AdminRole;
IF DATABASE_PRINCIPAL_ID('InstructorRole') IS NOT NULL
    DROP ROLE InstructorRole;
IF DATABASE_PRINCIPAL_ID('TARole') IS NOT NULL
    DROP ROLE TARole;
IF DATABASE_PRINCIPAL_ID('StudentRole') IS NOT NULL
    DROP ROLE StudentRole;
IF DATABASE_PRINCIPAL_ID('GuestRole') IS NOT NULL
    DROP ROLE GuestRole;
GO

-- Create roles
CREATE ROLE AdminRole;
CREATE ROLE InstructorRole;
CREATE ROLE TARole;
CREATE ROLE StudentRole;
CREATE ROLE GuestRole;
GO

-- ============================================
-- ADMIN ROLE PERMISSIONS (Full Access)
-- ============================================
GRANT SELECT, INSERT, UPDATE, DELETE ON Users TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Student TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Instructor TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Course TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Grades TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Attendance TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON CourseEnrollment TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON TAAssignment TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON RoleRequests TO AdminRole;
GRANT SELECT, INSERT ON AuditLog TO AdminRole;
GO

-- ============================================
-- INSTRUCTOR ROLE PERMISSIONS
-- ============================================
GRANT SELECT ON Student TO InstructorRole;
GRANT SELECT ON Instructor TO InstructorRole;
GRANT SELECT ON Course TO InstructorRole;
GRANT SELECT, INSERT, UPDATE ON Grades TO InstructorRole;
GRANT SELECT, INSERT, UPDATE ON Attendance TO InstructorRole;
GRANT SELECT ON CourseEnrollment TO InstructorRole;
GRANT SELECT ON Users TO InstructorRole;
DENY DELETE ON Grades TO InstructorRole;
DENY DELETE ON Attendance TO InstructorRole;
GO

-- ============================================
-- TA ROLE PERMISSIONS
-- ============================================
GRANT SELECT ON Student TO TARole;
GRANT SELECT ON Course TO TARole;
GRANT SELECT, INSERT, UPDATE ON Attendance TO TARole;
GRANT SELECT ON CourseEnrollment TO TARole;
GRANT SELECT ON TAAssignment TO TARole;
DENY SELECT ON Grades TO TARole; -- TAs cannot see grades
DENY SELECT ON Instructor TO TARole;
DENY SELECT ON Users TO TARole;
GO

-- ============================================
-- STUDENT ROLE PERMISSIONS
-- ============================================
GRANT SELECT ON Course TO StudentRole;
-- Students can only view their own data (enforced via stored procedures)
DENY INSERT, UPDATE, DELETE ON Student TO StudentRole;
DENY INSERT, UPDATE, DELETE ON Grades TO StudentRole;
DENY INSERT, UPDATE, DELETE ON Attendance TO StudentRole;
DENY SELECT ON Users TO StudentRole;
DENY SELECT ON Instructor TO StudentRole;
GO

-- ============================================
-- GUEST ROLE PERMISSIONS (Most Restrictive)
-- ============================================
GRANT SELECT ON Course TO GuestRole; -- Only public course information
DENY SELECT ON Student TO GuestRole;
DENY SELECT ON Instructor TO GuestRole;
DENY SELECT ON Grades TO GuestRole;
DENY SELECT ON Attendance TO GuestRole;
DENY SELECT ON Users TO GuestRole;
DENY SELECT ON CourseEnrollment TO GuestRole;
GO

PRINT 'SQL Server roles and permissions created successfully.';
GO

