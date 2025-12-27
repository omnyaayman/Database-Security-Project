-- ============================================
-- Database Security Term Project
-- Part A & B: Stored Procedures (Part 2)
-- ============================================
-- Attendance, Course, and Role Request operations

USE SecureStudentRecords;
GO

-- ============================================
-- ATTENDANCE OPERATIONS
-- ============================================

-- SP: Record Attendance (Instructor/TA/Admin)
CREATE OR ALTER PROCEDURE sp_RecordAttendance
    @StudentID INT,
    @CourseID INT,
    @Status BIT,
    @RequestingUserID INT,
    @RequestingUserClearance INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- MLS Check: No Write Down (Level 3 - Secret)
        IF @RequestingUserClearance < 3
        BEGIN
            RAISERROR('MLS Violation: Cannot write to Secret level', 16, 1);
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
        
        -- For TAs: verify they are assigned to this course
        IF @RequesterRole = 'TA'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM TAAssignment WHERE UserID = @RequestingUserID AND CourseID = @CourseID)
            BEGIN
                RAISERROR('Access Denied: You are not assigned to this course', 16, 1);
                RETURN;
            END
        END
        
        -- For Instructors: verify they teach this course
        IF @RequesterRole = 'Instructor'
        BEGIN
            DECLARE @InstructorID INT;
            SELECT @InstructorID = InstructorID FROM Instructor WHERE UserID = @RequestingUserID;
            
            IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID AND InstructorID = @InstructorID)
            BEGIN
                RAISERROR('Access Denied: You do not teach this course', 16, 1);
                RETURN;
            END
        END
        
        -- Check if attendance already recorded for this date
        IF EXISTS (
            SELECT 1 FROM Attendance 
            WHERE StudentID = @StudentID 
            AND CourseID = @CourseID 
            AND CAST(DateRecorded AS DATE) = CAST(GETDATE() AS DATE)
        )
        BEGIN
            -- Update existing record
            UPDATE Attendance
            SET Status = @Status, RecordedByUserID = @RequestingUserID
            WHERE StudentID = @StudentID 
            AND CourseID = @CourseID 
            AND CAST(DateRecorded AS DATE) = CAST(GETDATE() AS DATE);
            
            INSERT INTO AuditLog (UserID, Action, TableAffected)
            VALUES (@RequestingUserID, 'Update Attendance', 'Attendance');
            
            SELECT 'Success' AS Result, 'Attendance updated' AS Message;
        END
        ELSE
        BEGIN
            -- Insert new record
            INSERT INTO Attendance (StudentID, CourseID, Status, RecordedByUserID)
            VALUES (@StudentID, @CourseID, @Status, @RequestingUserID);
            
            INSERT INTO AuditLog (UserID, Action, TableAffected, RecordID)
            VALUES (@RequestingUserID, 'Record Attendance', 'Attendance', SCOPE_IDENTITY());
            
            SELECT 'Success' AS Result, SCOPE_IDENTITY() AS AttendanceID;
        END
    END TRY
    BEGIN CATCH
        INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage)
        VALUES (@RequestingUserID, 'Record Attendance Failed', 0, ERROR_MESSAGE());
        
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: View Attendance (with RBAC and MLS)
CREATE OR ALTER PROCEDURE sp_ViewAttendance
    @StudentID INT = NULL,
    @CourseID INT = NULL,
    @RequestingUserID INT,
    @RequestingUserClearance INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- MLS Check: No Read Up (Level 3 - Secret)
        IF @RequestingUserClearance < 3
        BEGIN
            RAISERROR('MLS Violation: Cannot read Secret level data', 16, 1);
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
        
        -- Build filtered query based on role
        IF @RequesterRole = 'TA'
        BEGIN
            -- TAs can only see attendance for their assigned courses
            SELECT 
                a.AttendanceID,
                a.StudentID,
                s.FullName AS StudentName,
                a.CourseID,
                c.CourseName,
                a.Status,
                a.DateRecorded
            FROM Attendance a
            INNER JOIN Student s ON a.StudentID = s.StudentID
            INNER JOIN Course c ON a.CourseID = c.CourseID
            INNER JOIN TAAssignment ta ON a.CourseID = ta.CourseID
            WHERE ta.UserID = @RequestingUserID
            AND (@StudentID IS NULL OR a.StudentID = @StudentID)
            AND (@CourseID IS NULL OR a.CourseID = @CourseID)
            ORDER BY a.DateRecorded DESC;
        END
        ELSE IF @RequesterRole = 'Instructor'
        BEGIN
            -- Instructors can see attendance for their courses
            DECLARE @InstructorID INT;
            SELECT @InstructorID = InstructorID FROM Instructor WHERE UserID = @RequestingUserID;
            
            SELECT 
                a.AttendanceID,
                a.StudentID,
                s.FullName AS StudentName,
                a.CourseID,
                c.CourseName,
                a.Status,
                a.DateRecorded
            FROM Attendance a
            INNER JOIN Student s ON a.StudentID = s.StudentID
            INNER JOIN Course c ON a.CourseID = c.CourseID
            WHERE c.InstructorID = @InstructorID
            AND (@StudentID IS NULL OR a.StudentID = @StudentID)
            AND (@CourseID IS NULL OR a.CourseID = @CourseID)
            ORDER BY a.DateRecorded DESC;
        END
        ELSE -- Admin
        BEGIN
            SELECT 
                a.AttendanceID,
                a.StudentID,
                s.FullName AS StudentName,
                a.CourseID,
                c.CourseName,
                a.Status,
                a.DateRecorded
            FROM Attendance a
            INNER JOIN Student s ON a.StudentID = s.StudentID
            INNER JOIN Course c ON a.CourseID = c.CourseID
            WHERE (@StudentID IS NULL OR a.StudentID = @StudentID)
            AND (@CourseID IS NULL OR a.CourseID = @CourseID)
            ORDER BY a.DateRecorded DESC;
        END
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected)
        VALUES (@RequestingUserID, 'View Attendance', 'Attendance');
        
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: Student View Own Attendance
CREATE OR ALTER PROCEDURE sp_StudentViewOwnAttendance
    @RequestingUserID INT,
    @CourseID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Get student ID
        DECLARE @StudentID INT;
        SELECT @StudentID = StudentID FROM Student WHERE UserID = @RequestingUserID;
        
        IF @StudentID IS NULL
        BEGIN
            RAISERROR('Student record not found', 16, 1);
            RETURN;
        END
        
        SELECT 
            c.CourseName,
            a.Status,
            a.DateRecorded,
            CASE WHEN a.Status = 1 THEN 'Present' ELSE 'Absent' END AS StatusText
        FROM Attendance a
        INNER JOIN Course c ON a.CourseID = c.CourseID
        WHERE a.StudentID = @StudentID
        AND (@CourseID IS NULL OR a.CourseID = @CourseID)
        ORDER BY a.DateRecorded DESC;
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected)
        VALUES (@RequestingUserID, 'View Own Attendance', 'Attendance');
        
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- ============================================
-- COURSE OPERATIONS
-- ============================================

-- SP: Add Course (Admin/Instructor)
CREATE OR ALTER PROCEDURE sp_AddCourse
    @CourseName NVARCHAR(100),
    @Description NVARCHAR(MAX),
    @PublicInfo NVARCHAR(MAX),
    @InstructorID INT = NULL,
    @RequestingUserID INT,
    @RequestingUserClearance INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- RBAC Check
        DECLARE @RequesterRole NVARCHAR(20);
        SELECT @RequesterRole = Role FROM Users WHERE UserID = @RequestingUserID;
        
        IF @RequesterRole NOT IN ('Admin', 'Instructor')
        BEGIN
            RAISERROR('Access Denied: Only Admins and Instructors can add courses', 16, 1);
            RETURN;
        END
        
        INSERT INTO Course (CourseName, Description, PublicInfo, InstructorID)
        VALUES (@CourseName, @Description, @PublicInfo, @InstructorID);
        
        DECLARE @CourseID INT = SCOPE_IDENTITY();
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected, RecordID)
        VALUES (@RequestingUserID, 'Add Course', 'Course', @CourseID);
        
        SELECT 'Success' AS Result, @CourseID AS CourseID;
    END TRY
    BEGIN CATCH
        INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage)
        VALUES (@RequestingUserID, 'Add Course Failed', 0, ERROR_MESSAGE());
        
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: View Courses (Public - accessible to all)
CREATE OR ALTER PROCEDURE sp_ViewCourses
    @RequestingUserID INT = NULL,
    @RequestingUserRole NVARCHAR(20) = 'Guest'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF @RequestingUserRole = 'Guest'
        BEGIN
            -- Guest can only see public info
            SELECT 
                CourseID,
                CourseName,
                PublicInfo
            FROM Course;
        END
        ELSE
        BEGIN
            -- Other roles can see full details
            SELECT 
                c.CourseID,
                c.CourseName,
                c.Description,
                c.PublicInfo,
                c.InstructorID,
                i.FullName AS InstructorName
            FROM Course c
            LEFT JOIN Instructor i ON c.InstructorID = i.InstructorID;
        END
        
        -- Audit log
        IF @RequestingUserID IS NOT NULL
        BEGIN
            INSERT INTO AuditLog (UserID, Action, TableAffected)
            VALUES (@RequestingUserID, 'View Courses', 'Course');
        END
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: Enroll Student in Course
CREATE OR ALTER PROCEDURE sp_EnrollStudent
    @StudentID INT,
    @CourseID INT,
    @RequestingUserID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- RBAC Check
        DECLARE @RequesterRole NVARCHAR(20);
        SELECT @RequesterRole = Role FROM Users WHERE UserID = @RequestingUserID;
        
        IF @RequesterRole NOT IN ('Admin', 'Instructor')
        BEGIN
            RAISERROR('Access Denied: Only Admins and Instructors can enroll students', 16, 1);
            RETURN;
        END
        
        -- Check if already enrolled
        IF EXISTS (SELECT 1 FROM CourseEnrollment WHERE StudentID = @StudentID AND CourseID = @CourseID)
        BEGIN
            SELECT 'Info' AS Result, 'Student already enrolled' AS Message;
            RETURN;
        END
        
        INSERT INTO CourseEnrollment (StudentID, CourseID)
        VALUES (@StudentID, @CourseID);
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected, RecordID)
        VALUES (@RequestingUserID, 'Enroll Student', 'CourseEnrollment', SCOPE_IDENTITY());
        
        SELECT 'Success' AS Result, SCOPE_IDENTITY() AS EnrollmentID;
    END TRY
    BEGIN CATCH
        INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage)
        VALUES (@RequestingUserID, 'Enroll Student Failed', 0, ERROR_MESSAGE());
        
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: Assign TA to Course
CREATE OR ALTER PROCEDURE sp_AssignTA
    @TAUserID INT,
    @CourseID INT,
    @RequestingUserID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- RBAC Check
        DECLARE @RequesterRole NVARCHAR(20);
        SELECT @RequesterRole = Role FROM Users WHERE UserID = @RequestingUserID;
        
        IF @RequesterRole NOT IN ('Admin', 'Instructor')
        BEGIN
            RAISERROR('Access Denied: Only Admins and Instructors can assign TAs', 16, 1);
            RETURN;
        END
        
        -- Verify user is a TA
        DECLARE @TARole NVARCHAR(20);
        SELECT @TARole = Role FROM Users WHERE UserID = @TAUserID;
        
        IF @TARole != 'TA'
        BEGIN
            RAISERROR('User is not a TA', 16, 1);
            RETURN;
        END
        
        -- Check if already assigned
        IF EXISTS (SELECT 1 FROM TAAssignment WHERE UserID = @TAUserID AND CourseID = @CourseID)
        BEGIN
            SELECT 'Info' AS Result, 'TA already assigned to this course' AS Message;
            RETURN;
        END
        
        INSERT INTO TAAssignment (UserID, CourseID)
        VALUES (@TAUserID, @CourseID);
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected, RecordID)
        VALUES (@RequestingUserID, 'Assign TA', 'TAAssignment', SCOPE_IDENTITY());
        
        SELECT 'Success' AS Result, SCOPE_IDENTITY() AS AssignmentID;
    END TRY
    BEGIN CATCH
        INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage)
        VALUES (@RequestingUserID, 'Assign TA Failed', 0, ERROR_MESSAGE());
        
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- ============================================
-- PART B: ROLE REQUEST WORKFLOW
-- ============================================

-- SP: Submit Role Request (Student/TA)
CREATE OR ALTER PROCEDURE sp_SubmitRoleRequest
    @RequestingUserID INT,
    @RequestedRole NVARCHAR(20),
    @Reason NVARCHAR(500),
    @Comments NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Get current user info
        DECLARE @Username NVARCHAR(50);
        DECLARE @CurrentRole NVARCHAR(20);
        
        SELECT @Username = Username, @CurrentRole = Role
        FROM Users
        WHERE UserID = @RequestingUserID;
        
        IF @Username IS NULL
        BEGIN
            RAISERROR('User not found', 16, 1);
            RETURN;
        END
        
        -- Validate role upgrade path
        IF @CurrentRole = 'Admin'
        BEGIN
            RAISERROR('Admins cannot request role changes', 16, 1);
            RETURN;
        END
        
        IF @CurrentRole = 'Guest' AND @RequestedRole NOT IN ('Student', 'TA')
        BEGIN
            RAISERROR('Invalid role upgrade path', 16, 1);
            RETURN;
        END
        
        IF @CurrentRole = 'Student' AND @RequestedRole NOT IN ('TA', 'Instructor')
        BEGIN
            RAISERROR('Invalid role upgrade path', 16, 1);
            RETURN;
        END
        
        IF @CurrentRole = 'TA' AND @RequestedRole NOT IN ('Instructor')
        BEGIN
            RAISERROR('Invalid role upgrade path', 16, 1);
            RETURN;
        END
        
        IF @CurrentRole = @RequestedRole
        BEGIN
            RAISERROR('Cannot request same role', 16, 1);
            RETURN;
        END
        
        -- Check for pending requests
        IF EXISTS (
            SELECT 1 FROM RoleRequests 
            WHERE UserID = @RequestingUserID 
            AND Status = 'Pending'
        )
        BEGIN
            RAISERROR('You already have a pending role request', 16, 1);
            RETURN;
        END
        
        -- Insert role request
        INSERT INTO RoleRequests (UserID, Username, CurrentRole, RequestedRole, Reason, Comments)
        VALUES (@RequestingUserID, @Username, @CurrentRole, @RequestedRole, @Reason, @Comments);
        
        DECLARE @RequestID INT = SCOPE_IDENTITY();
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected, RecordID)
        VALUES (@RequestingUserID, 'Submit Role Request', 'RoleRequests', @RequestID);
        
        SELECT 'Success' AS Result, @RequestID AS RequestID, 'Your request has been submitted and is pending admin approval' AS Message;
    END TRY
    BEGIN CATCH
        INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage)
        VALUES (@RequestingUserID, 'Submit Role Request Failed', 0, ERROR_MESSAGE());
        
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: View Pending Role Requests (Admin only)
CREATE OR ALTER PROCEDURE sp_ViewPendingRoleRequests
    @RequestingUserID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- RBAC Check
        DECLARE @RequesterRole NVARCHAR(20);
        SELECT @RequesterRole = Role FROM Users WHERE UserID = @RequestingUserID;
        
        IF @RequesterRole != 'Admin'
        BEGIN
            RAISERROR('Access Denied: Only Admins can view role requests', 16, 1);
            RETURN;
        END
        
        SELECT 
            RequestID,
            UserID,
            Username,
            CurrentRole,
            RequestedRole,
            Reason,
            Comments,
            Status,
            RequestDate
        FROM RoleRequests
        WHERE Status = 'Pending'
        ORDER BY RequestDate ASC;
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected)
        VALUES (@RequestingUserID, 'View Pending Role Requests', 'RoleRequests');
        
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: Process Role Request (Admin only - Approve/Deny)
CREATE OR ALTER PROCEDURE sp_ProcessRoleRequest
    @RequestID INT,
    @AdminUserID INT,
    @Action NVARCHAR(10), -- 'Approve' or 'Deny'
    @AdminComments NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- RBAC Check
        DECLARE @AdminRole NVARCHAR(20);
        SELECT @AdminRole = Role FROM Users WHERE UserID = @AdminUserID;
        
        IF @AdminRole != 'Admin'
        BEGIN
            RAISERROR('Access Denied: Only Admins can process role requests', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Get request details
        DECLARE @UserID INT;
        DECLARE @RequestedRole NVARCHAR(20);
        DECLARE @CurrentStatus NVARCHAR(20);
        DECLARE @Username NVARCHAR(50);
        
        SELECT 
            @UserID = UserID,
            @RequestedRole = RequestedRole,
            @CurrentStatus = Status,
            @Username = Username
        FROM RoleRequests
        WHERE RequestID = @RequestID;
        
        IF @UserID IS NULL
        BEGIN
            RAISERROR('Request not found', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        IF @CurrentStatus != 'Pending'
        BEGIN
            RAISERROR('Request has already been processed', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        IF @Action = 'Approve'
        BEGIN
            -- Calculate new clearance level based on role
            DECLARE @NewClearance INT;
            
            IF @RequestedRole = 'Student'
                SET @NewClearance = 1;
            ELSE IF @RequestedRole = 'TA'
                SET @NewClearance = 2;
            ELSE IF @RequestedRole = 'Instructor'
                SET @NewClearance = 3;
            ELSE IF @RequestedRole = 'Admin'
                SET @NewClearance = 4;
            
            -- Update user role and clearance
            UPDATE Users
            SET Role = @RequestedRole, ClearanceLevel = @NewClearance
            WHERE UserID = @UserID;
            
            -- Update request status
            UPDATE RoleRequests
            SET Status = 'Approved',
                ProcessedDate = GETDATE(),
                ProcessedByAdminID = @AdminUserID,
                AdminComments = @AdminComments
            WHERE RequestID = @RequestID;
            
            -- Audit log
            INSERT INTO AuditLog (UserID, Action, TableAffected, RecordID, NewValue)
            VALUES (@AdminUserID, 'Approve Role Request', 'RoleRequests', @RequestID, 
                    'User: ' + @Username + ' upgraded to ' + @RequestedRole);
            
            SELECT 'Success' AS Result, 'Role request approved. User upgraded to ' + @RequestedRole AS Message;
        END
        ELSE IF @Action = 'Deny'
        BEGIN
            -- Update request status
            UPDATE RoleRequests
            SET Status = 'Denied',
                ProcessedDate = GETDATE(),
                ProcessedByAdminID = @AdminUserID,
                AdminComments = @AdminComments
            WHERE RequestID = @RequestID;
            
            -- Audit log
            INSERT INTO AuditLog (UserID, Action, TableAffected, RecordID)
            VALUES (@AdminUserID, 'Deny Role Request', 'RoleRequests', @RequestID);
            
            SELECT 'Success' AS Result, 'Role request denied' AS Message;
        END
        ELSE
        BEGIN
            RAISERROR('Invalid action. Must be Approve or Deny', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage)
        VALUES (@AdminUserID, 'Process Role Request Failed', 0, ERROR_MESSAGE());
        
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: View User's Own Role Requests
CREATE OR ALTER PROCEDURE sp_ViewOwnRoleRequests
    @RequestingUserID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        SELECT 
            RequestID,
            CurrentRole,
            RequestedRole,
            Reason,
            Comments,
            Status,
            RequestDate,
            ProcessedDate,
            AdminComments
        FROM RoleRequests
        WHERE UserID = @RequestingUserID
        ORDER BY RequestDate DESC;
        
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: View All Role Requests (Admin only)
CREATE OR ALTER PROCEDURE sp_ViewAllRoleRequests
    @RequestingUserID INT,
    @Status NVARCHAR(20) = NULL -- Filter by status: 'Pending', 'Approved', 'Denied', or NULL for all
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- RBAC Check
        DECLARE @RequesterRole NVARCHAR(20);
        SELECT @RequesterRole = Role FROM Users WHERE UserID = @RequestingUserID;
        
        IF @RequesterRole != 'Admin'
        BEGIN
            RAISERROR('Access Denied: Only Admins can view all role requests', 16, 1);
            RETURN;
        END
        
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
            u.Username AS ProcessedByAdmin,
            rr.AdminComments
        FROM RoleRequests rr
        LEFT JOIN Users u ON rr.ProcessedByAdminID = u.UserID
        WHERE (@Status IS NULL OR rr.Status = @Status)
        ORDER BY 
            CASE rr.Status 
                WHEN 'Pending' THEN 1 
                WHEN 'Approved' THEN 2 
                WHEN 'Denied' THEN 3 
            END,
            rr.RequestDate DESC;
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected)
        VALUES (@RequestingUserID, 'View All Role Requests', 'RoleRequests');
        
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

PRINT 'Part 2 of stored procedures created successfully.';
GO

