-- ============================================
-- Database Security Term Project
-- Part A & B: Inference Control Stored Procedures
-- ============================================
-- Query Set Size Control and aggregate restrictions

USE SecureStudentRecords;
GO

-- ============================================
-- INFERENCE CONTROL
-- Minimum Group Size = 3
-- ============================================

-- SP: Get Grade Statistics by Department (Inference Control)
CREATE OR ALTER PROCEDURE sp_GetGradeStatsByDepartment
    @Department NVARCHAR(50) = NULL,
    @CourseID INT = NULL,
    @RequestingUserID INT,
    @RequestingUserClearance INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- MLS Check
        IF @RequestingUserClearance < 3
        BEGIN
            RAISERROR('MLS Violation: Cannot access Secret level statistics', 16, 1);
            RETURN;
        END
        
        -- RBAC Check
        DECLARE @RequesterRole NVARCHAR(20);
        SELECT @RequesterRole = Role FROM Users WHERE UserID = @RequestingUserID;
        
        IF @RequesterRole NOT IN ('Admin', 'Instructor')
        BEGIN
            RAISERROR('Access Denied: Insufficient privileges', 16, 1);
            RETURN;
        END
        
        -- Open symmetric key for decryption
        OPEN SYMMETRIC KEY StudentRecordsKey
        DECRYPTION BY CERTIFICATE StudentRecordsCert;
        
        -- Query with Inference Control (minimum 3 students)
        SELECT 
            s.Department,
            c.CourseID,
            c.CourseName,
            COUNT(DISTINCT s.StudentID) AS StudentCount,
            AVG(CAST(CAST(DecryptByKey(g.GradeValueEncrypted) AS VARCHAR(10)) AS DECIMAL(5,2))) AS AverageGrade,
            MIN(CAST(CAST(DecryptByKey(g.GradeValueEncrypted) AS VARCHAR(10)) AS DECIMAL(5,2))) AS MinGrade,
            MAX(CAST(CAST(DecryptByKey(g.GradeValueEncrypted) AS VARCHAR(10)) AS DECIMAL(5,2))) AS MaxGrade
        FROM Grades g
        INNER JOIN Student s ON s.StudentID = CAST(CAST(DecryptByKey(g.StudentIDEncrypted) AS VARCHAR(10)) AS INT)
        INNER JOIN Course c ON g.CourseID = c.CourseID
        WHERE 
            (@Department IS NULL OR s.Department = @Department)
            AND (@CourseID IS NULL OR c.CourseID = @CourseID)
        GROUP BY s.Department, c.CourseID, c.CourseName
        HAVING COUNT(DISTINCT s.StudentID) >= 3; -- Inference Control: Minimum group size
        
        CLOSE SYMMETRIC KEY StudentRecordsKey;
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected)
        VALUES (@RequestingUserID, 'View Grade Statistics', 'Grades');
        
    END TRY
    BEGIN CATCH
        IF (SELECT COUNT(*) FROM sys.openkeys WHERE key_name = 'StudentRecordsKey') > 0
            CLOSE SYMMETRIC KEY StudentRecordsKey;
            
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: Get Attendance Statistics (Inference Control)
CREATE OR ALTER PROCEDURE sp_GetAttendanceStats
    @CourseID INT = NULL,
    @Department NVARCHAR(50) = NULL,
    @RequestingUserID INT,
    @RequestingUserClearance INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- MLS Check
        IF @RequestingUserClearance < 3
        BEGIN
            RAISERROR('MLS Violation: Cannot access Secret level statistics', 16, 1);
            RETURN;
        END
        
        -- RBAC Check
        DECLARE @RequesterRole NVARCHAR(20);
        SELECT @RequesterRole = Role FROM Users WHERE UserID = @RequestingUserID;
        
        IF @RequesterRole NOT IN ('Admin', 'Instructor', 'TA')
        BEGIN
            RAISERROR('Access Denied: Insufficient privileges', 16, 1);
            RETURN;
        END
        
        -- Query with Inference Control
        SELECT 
            c.CourseID,
            c.CourseName,
            s.Department,
            COUNT(DISTINCT a.StudentID) AS TotalStudents,
            SUM(CASE WHEN a.Status = 1 THEN 1 ELSE 0 END) AS TotalPresent,
            SUM(CASE WHEN a.Status = 0 THEN 1 ELSE 0 END) AS TotalAbsent,
            CAST(SUM(CASE WHEN a.Status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS AttendancePercentage
        FROM Attendance a
        INNER JOIN Course c ON a.CourseID = c.CourseID
        INNER JOIN Student s ON a.StudentID = s.StudentID
        WHERE 
            (@CourseID IS NULL OR c.CourseID = @CourseID)
            AND (@Department IS NULL OR s.Department = @Department)
        GROUP BY c.CourseID, c.CourseName, s.Department
        HAVING COUNT(DISTINCT a.StudentID) >= 3; -- Inference Control
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected)
        VALUES (@RequestingUserID, 'View Attendance Statistics', 'Attendance');
        
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: Restricted Student List (Inference Control)
-- Prevents identifying students through small groups
CREATE OR ALTER PROCEDURE sp_GetStudentListByFilters
    @Department NVARCHAR(50) = NULL,
    @CourseID INT = NULL,
    @RequestingUserID INT,
    @RequestingUserClearance INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- MLS Check
        IF @RequestingUserClearance < 2
        BEGIN
            RAISERROR('MLS Violation: Cannot access Confidential level data', 16, 1);
            RETURN;
        END
        
        -- RBAC Check
        DECLARE @RequesterRole NVARCHAR(20);
        SELECT @RequesterRole = Role FROM Users WHERE UserID = @RequestingUserID;
        
        IF @RequesterRole NOT IN ('Admin', 'Instructor', 'TA')
        BEGIN
            RAISERROR('Access Denied: Insufficient privileges', 16, 1);
            RETURN;
        END
        
        -- Create temp table for filtered students
        CREATE TABLE #FilteredStudents (
            StudentID INT,
            FullName NVARCHAR(100),
            Email NVARCHAR(100),
            Department NVARCHAR(50)
        );
        
        -- Apply filters
        INSERT INTO #FilteredStudents
        SELECT DISTINCT
            s.StudentID,
            s.FullName,
            s.Email,
            s.Department
        FROM Student s
        LEFT JOIN CourseEnrollment ce ON s.StudentID = ce.StudentID
        WHERE 
            (@Department IS NULL OR s.Department = @Department)
            AND (@CourseID IS NULL OR ce.CourseID = @CourseID);
        
        -- Inference Control: Check minimum group size
        DECLARE @StudentCount INT;
        SELECT @StudentCount = COUNT(*) FROM #FilteredStudents;
        
        IF @StudentCount < 3 AND @StudentCount > 0
        BEGIN
            -- Too few students - would reveal individual information
            SELECT 'Warning' AS Result, 
                   'Query result set too small (less than 3 students). Result blocked for inference control.' AS Message;
            
            INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage)
            VALUES (@RequestingUserID, 'Student List Query Blocked', 0, 'Inference Control: Result set < 3');
        END
        ELSE IF @StudentCount = 0
        BEGIN
            SELECT 'Info' AS Result, 'No students found matching criteria' AS Message;
        END
        ELSE
        BEGIN
            -- Safe to return results
            SELECT 
                StudentID,
                FullName,
                Email,
                Department
            FROM #FilteredStudents
            ORDER BY FullName;
            
            INSERT INTO AuditLog (UserID, Action, TableAffected)
            VALUES (@RequestingUserID, 'View Student List', 'Student');
        END
        
        DROP TABLE #FilteredStudents;
        
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#FilteredStudents') IS NOT NULL
            DROP TABLE #FilteredStudents;
            
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: Check Query Result Size (Inference Control Helper)
CREATE OR ALTER PROCEDURE sp_CheckQuerySize
    @QueryType NVARCHAR(50),
    @Filters NVARCHAR(MAX),
    @RequestingUserID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- This procedure helps enforce inference control by checking
    -- if a query would return fewer than 3 records before executing
    
    DECLARE @ResultCount INT = 0;
    DECLARE @AllowQuery BIT = 0;
    
    -- Parse filters and count results (simplified example)
    -- In real implementation, this would parse the filters parameter
    
    IF @ResultCount < 3 AND @ResultCount > 0
    BEGIN
        SET @AllowQuery = 0;
        
        INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage)
        VALUES (@RequestingUserID, 'Query Blocked - ' + @QueryType, 0, 
                'Inference Control: Would return ' + CAST(@ResultCount AS VARCHAR) + ' records');
    END
    ELSE
    BEGIN
        SET @AllowQuery = 1;
    END
    
    SELECT @AllowQuery AS AllowQuery, @ResultCount AS ResultCount;
END
GO

-- SP: Get Course Enrollment Count (Public Statistics)
CREATE OR ALTER PROCEDURE sp_GetCourseEnrollmentStats
    @CourseID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Public statistics - safe aggregates only
    SELECT 
        c.CourseID,
        c.CourseName,
        COUNT(DISTINCT ce.StudentID) AS EnrolledStudents,
        i.FullName AS InstructorName
    FROM Course c
    LEFT JOIN CourseEnrollment ce ON c.CourseID = ce.CourseID
    LEFT JOIN Instructor i ON c.InstructorID = i.InstructorID
    WHERE (@CourseID IS NULL OR c.CourseID = @CourseID)
    GROUP BY c.CourseID, c.CourseName, i.FullName
    HAVING COUNT(DISTINCT ce.StudentID) >= 3 OR COUNT(DISTINCT ce.StudentID) = 0; -- Show courses with 3+ or 0 students
END
GO

-- SP: Aggregate Performance Report (Inference Control)
CREATE OR ALTER PROCEDURE sp_GetAggregatePerformanceReport
    @Department NVARCHAR(50) = NULL,
    @RequestingUserID INT,
    @RequestingUserClearance INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- MLS Check
        IF @RequestingUserClearance < 3
        BEGIN
            RAISERROR('MLS Violation: Cannot access Secret level data', 16, 1);
            RETURN;
        END
        
        -- RBAC Check
        DECLARE @RequesterRole NVARCHAR(20);
        SELECT @RequesterRole = Role FROM Users WHERE UserID = @RequestingUserID;
        
        IF @RequesterRole NOT IN ('Admin', 'Instructor')
        BEGIN
            RAISERROR('Access Denied: Only Admins and Instructors can view performance reports', 16, 1);
            RETURN;
        END
        
        OPEN SYMMETRIC KEY StudentRecordsKey
        DECRYPTION BY CERTIFICATE StudentRecordsCert;
        
        -- Combined performance metrics with inference control
        SELECT 
            s.Department,
            COUNT(DISTINCT s.StudentID) AS TotalStudents,
            COUNT(DISTINCT g.GradeID) AS TotalGradeRecords,
            AVG(CAST(CAST(DecryptByKey(g.GradeValueEncrypted) AS VARCHAR(10)) AS DECIMAL(5,2))) AS OverallAverageGrade,
            CAST(SUM(CASE WHEN a.Status = 1 THEN 1 ELSE 0 END) * 100.0 / 
                 NULLIF(COUNT(a.AttendanceID), 0) AS DECIMAL(5,2)) AS OverallAttendanceRate
        FROM Student s
        LEFT JOIN Grades g ON s.StudentID = CAST(CAST(DecryptByKey(g.StudentIDEncrypted) AS VARCHAR(10)) AS INT)
        LEFT JOIN Attendance a ON s.StudentID = a.StudentID
        WHERE (@Department IS NULL OR s.Department = @Department)
        GROUP BY s.Department
        HAVING COUNT(DISTINCT s.StudentID) >= 3; -- Inference Control
        
        CLOSE SYMMETRIC KEY StudentRecordsKey;
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected)
        VALUES (@RequestingUserID, 'View Performance Report', 'Multiple');
        
    END TRY
    BEGIN CATCH
        IF (SELECT COUNT(*) FROM sys.openkeys WHERE key_name = 'StudentRecordsKey') > 0
            CLOSE SYMMETRIC KEY StudentRecordsKey;
            
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

PRINT 'Inference Control stored procedures created successfully.';
GO

