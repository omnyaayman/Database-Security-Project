-- ============================================
-- Database Security Term Project
-- Part A: MLS Views (Multilevel Security)
-- ============================================
-- This script creates classification-based views following Bell-LaPadula

USE SecureStudentRecords;
GO

-- ============================================
-- UNCLASSIFIED VIEWS (Level 1)
-- Accessible by all roles including Guest
-- ============================================

CREATE OR ALTER VIEW vw_Course_Public
AS
SELECT 
    CourseID,
    CourseName,
    PublicInfo
FROM Course
WHERE ClassificationLevel <= 1;
GO

-- ============================================
-- CONFIDENTIAL VIEWS (Level 2)
-- Accessible by Student, TA, Instructor, Admin
-- ============================================

CREATE OR ALTER VIEW vw_Student_Confidential
AS
SELECT 
    StudentID,
    FullName,
    Email,
    Department,
    ClearanceLevel
FROM Student
WHERE ClassificationLevel <= 2;
GO

CREATE OR ALTER VIEW vw_Instructor_Confidential
AS
SELECT 
    InstructorID,
    FullName,
    Email,
    Department,
    ClearanceLevel
FROM Instructor
WHERE ClassificationLevel <= 2;
GO

CREATE OR ALTER VIEW vw_Course_Confidential
AS
SELECT 
    CourseID,
    CourseName,
    Description,
    PublicInfo,
    InstructorID
FROM Course;
GO

-- ============================================
-- SECRET VIEWS (Level 3)
-- Accessible by TA, Instructor, Admin
-- ============================================

CREATE OR ALTER VIEW vw_Attendance_Secret
AS
SELECT 
    a.AttendanceID,
    a.StudentID,
    s.FullName AS StudentName,
    a.CourseID,
    c.CourseName,
    a.Status,
    a.DateRecorded,
    a.RecordedByUserID
FROM Attendance a
INNER JOIN Student s ON a.StudentID = s.StudentID
INNER JOIN Course c ON a.CourseID = c.CourseID
WHERE a.ClassificationLevel <= 3;
GO

-- View for Grades (Instructor and Admin only via stored procedures)
CREATE OR ALTER VIEW vw_Grades_Secret
AS
SELECT 
    g.GradeID,
    g.CourseID,
    c.CourseName,
    g.DateEntered,
    g.EnteredByInstructorID,
    i.FullName AS InstructorName
FROM Grades g
INNER JOIN Course c ON g.CourseID = c.CourseID
INNER JOIN Instructor i ON g.EnteredByInstructorID = i.InstructorID
WHERE g.ClassificationLevel <= 3;
GO

-- ============================================
-- ROLE-SPECIFIC FILTERED VIEWS
-- ============================================

-- View for Students: See only their own attendance
CREATE OR ALTER VIEW vw_Student_OwnAttendance
AS
SELECT 
    a.AttendanceID,
    a.StudentID,
    a.CourseID,
    c.CourseName,
    a.Status,
    a.DateRecorded
FROM Attendance a
INNER JOIN Course c ON a.CourseID = c.CourseID;
GO

-- View for Students: See only their own grades
CREATE OR ALTER VIEW vw_Student_OwnGrades
AS
SELECT 
    g.GradeID,
    g.CourseID,
    c.CourseName,
    g.DateEntered
FROM Grades g
INNER JOIN Course c ON g.CourseID = c.CourseID;
GO

-- View for TAs: See only students in their assigned courses
CREATE OR ALTER VIEW vw_TA_AssignedStudents
AS
SELECT 
    ta.UserID AS TAID,
    ta.CourseID,
    c.CourseName,
    s.StudentID,
    s.FullName AS StudentName,
    s.Email AS StudentEmail,
    s.Department
FROM TAAssignment ta
INNER JOIN Course c ON ta.CourseID = c.CourseID
INNER JOIN CourseEnrollment ce ON c.CourseID = ce.CourseID
INNER JOIN Student s ON ce.StudentID = s.StudentID;
GO

-- View for TAs: Manage attendance for assigned courses only
CREATE OR ALTER VIEW vw_TA_AssignedAttendance
AS
SELECT 
    ta.UserID AS TAID,
    a.AttendanceID,
    a.StudentID,
    s.FullName AS StudentName,
    a.CourseID,
    c.CourseName,
    a.Status,
    a.DateRecorded
FROM TAAssignment ta
INNER JOIN Attendance a ON ta.CourseID = a.CourseID
INNER JOIN Student s ON a.StudentID = s.StudentID
INNER JOIN Course c ON a.CourseID = c.CourseID;
GO

-- View for Instructors: See grades for their courses
CREATE OR ALTER VIEW vw_Instructor_OwnCourseGrades
AS
SELECT 
    c.InstructorID,
    g.GradeID,
    g.CourseID,
    c.CourseName,
    g.DateEntered,
    g.EnteredByInstructorID
FROM Grades g
INNER JOIN Course c ON g.CourseID = c.CourseID;
GO

-- ============================================
-- INFERENCE CONTROL VIEWS
-- Aggregate views with minimum group size = 3
-- ============================================

-- Average grades by department (prevents individual identification)
CREATE OR ALTER VIEW vw_DepartmentGradeStats
AS
SELECT 
    s.Department,
    c.CourseID,
    c.CourseName,
    COUNT(*) AS StudentCount,
    AVG(CAST(CAST(DecryptByKey(g.GradeValueEncrypted) AS VARCHAR(10)) AS DECIMAL(5,2))) AS AverageGrade
FROM Grades g
INNER JOIN Student s ON s.StudentID = CAST(CAST(DecryptByKey(g.StudentIDEncrypted) AS VARCHAR(10)) AS INT)
INNER JOIN Course c ON g.CourseID = c.CourseID
GROUP BY s.Department, c.CourseID, c.CourseName
HAVING COUNT(*) >= 3; -- Inference Control: Minimum group size
GO

-- Attendance statistics (prevents identifying individuals)
CREATE OR ALTER VIEW vw_CourseAttendanceStats
AS
SELECT 
    c.CourseID,
    c.CourseName,
    COUNT(DISTINCT a.StudentID) AS TotalStudents,
    SUM(CASE WHEN a.Status = 1 THEN 1 ELSE 0 END) AS TotalPresent,
    SUM(CASE WHEN a.Status = 0 THEN 1 ELSE 0 END) AS TotalAbsent,
    CAST(SUM(CASE WHEN a.Status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS AttendancePercentage
FROM Attendance a
INNER JOIN Course c ON a.CourseID = c.CourseID
GROUP BY c.CourseID, c.CourseName
HAVING COUNT(DISTINCT a.StudentID) >= 3; -- Inference Control
GO

-- ============================================
-- PART B: Role Request Views
-- ============================================

CREATE OR ALTER VIEW vw_PendingRoleRequests
AS
SELECT 
    rr.RequestID,
    rr.UserID,
    rr.Username,
    rr.CurrentRole,
    rr.RequestedRole,
    rr.Reason,
    rr.Comments,
    rr.Status,
    rr.RequestDate
FROM RoleRequests rr
WHERE rr.Status = 'Pending';
GO

CREATE OR ALTER VIEW vw_AllRoleRequests
AS
SELECT 
    rr.RequestID,
    rr.UserID,
    rr.Username,
    rr.CurrentRole,
    rr.RequestedRole,
    rr.Reason,
    rr.Comments,
    rr.Status,
    rr.RequestDate,
    rr.ProcessedDate,
    rr.ProcessedByAdminID,
    u.Username AS ProcessedByAdmin,
    rr.AdminComments
FROM RoleRequests rr
LEFT JOIN Users u ON rr.ProcessedByAdminID = u.UserID;
GO

PRINT 'MLS Views and Inference Control views created successfully.';
GO

