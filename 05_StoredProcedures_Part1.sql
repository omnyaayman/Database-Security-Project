-- ============================================
-- Database Security Term Project
-- Part A & B: Stored Procedures
-- ============================================
-- RBAC, MLS, Flow Control, Inference Control enforcement

USE SecureStudentRecords;
GO

-- ============================================
-- AUTHENTICATION & USER MANAGEMENT
-- ============================================

-- SP: User Registration (Simplified - using encryption like examples)
CREATE OR ALTER PROCEDURE sp_RegisterUser
    @Username NVARCHAR(50),
    @Password NVARCHAR(100),
    @Role NVARCHAR(20),
    @ClearanceLevel INT,
    @CreatedByAdminID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Verify admin permission if not self-registration
        IF @CreatedByAdminID IS NOT NULL
        BEGIN
            DECLARE @AdminRole NVARCHAR(20);
            SELECT @AdminRole = Role FROM Users WHERE UserID = @CreatedByAdminID;
            
            IF @AdminRole != 'Admin'
            BEGIN
                RAISERROR('Only Admin can create users', 16, 1);
                RETURN;
            END
        END
        
        -- Encrypt password using symmetric key (like examples)
        OPEN SYMMETRIC KEY StudentRecordsKey
        DECRYPTION BY CERTIFICATE StudentRecordsCert;
        
        DECLARE @PasswordEncrypted VARBINARY(MAX) = EncryptByKey(Key_GUID('StudentRecordsKey'), @Password);
        
        CLOSE SYMMETRIC KEY StudentRecordsKey;
        
        INSERT INTO Users (Username, PasswordEncrypted, Role, ClearanceLevel)
        VALUES (@Username, @PasswordEncrypted, @Role, @ClearanceLevel);
        
        -- Audit log
        INSERT INTO AuditLog (Username, Action, TableAffected, RecordID, ActionDate)
        VALUES (@Username, 'User Registration', 'Users', SCOPE_IDENTITY(), GETDATE());
        
        SELECT 'Success' AS Result, SCOPE_IDENTITY() AS UserID;
    END TRY
    BEGIN CATCH
        IF (SELECT COUNT(*) FROM sys.openkeys WHERE key_name = 'StudentRecordsKey') > 0
            CLOSE SYMMETRIC KEY StudentRecordsKey;
            
        INSERT INTO AuditLog (Username, Action, Success, ErrorMessage)
        VALUES (@Username, 'User Registration Failed', 0, ERROR_MESSAGE());
        
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: User Login (Simplified - decrypt and compare like examples)
CREATE OR ALTER PROCEDURE sp_Login
    @Username NVARCHAR(50),
    @Password NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UserID INT;
    DECLARE @StoredPasswordEncrypted VARBINARY(MAX);
    DECLARE @Role NVARCHAR(20);
    DECLARE @ClearanceLevel INT;
    DECLARE @IsActive BIT;
    
    -- Get user details
    SELECT 
        @UserID = UserID,
        @StoredPasswordEncrypted = PasswordEncrypted,
        @Role = Role,
        @ClearanceLevel = ClearanceLevel,
        @IsActive = IsActive
    FROM Users
    WHERE Username = @Username;
    
    IF @UserID IS NULL
    BEGIN
        INSERT INTO AuditLog (Username, Action, Success, ErrorMessage)
        VALUES (@Username, 'Login Failed', 0, 'User not found');
        
        SELECT 'Error' AS Result, 'Invalid credentials' AS Message;
        RETURN;
    END
    
    IF @IsActive = 0
    BEGIN
        INSERT INTO AuditLog (UserID, Username, Action, Success, ErrorMessage)
        VALUES (@UserID, @Username, 'Login Failed', 0, 'Account disabled');
        
        SELECT 'Error' AS Result, 'Account is disabled' AS Message;
        RETURN;
    END
    
    -- Decrypt stored password and compare (like examples)
    OPEN SYMMETRIC KEY StudentRecordsKey
    DECRYPTION BY CERTIFICATE StudentRecordsCert;
    
    DECLARE @DecryptedPassword NVARCHAR(100) = CONVERT(NVARCHAR(100), DecryptByKey(@StoredPasswordEncrypted));
    
    CLOSE SYMMETRIC KEY StudentRecordsKey;
    
    IF @Password = @DecryptedPassword
    BEGIN
        -- Update last login
        UPDATE Users SET LastLogin = GETDATE() WHERE UserID = @UserID;
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Username, Action, ActionDate)
        VALUES (@UserID, @Username, 'Login Successful', GETDATE());
        
        SELECT 
            'Success' AS Result,
            @UserID AS UserID,
            @Username AS Username,
            @Role AS Role,
            @ClearanceLevel AS ClearanceLevel;
    END
    ELSE
    BEGIN
        INSERT INTO AuditLog (UserID, Username, Action, Success, ErrorMessage)
        VALUES (@UserID, @Username, 'Login Failed', 0, 'Invalid password');
        
        SELECT 'Error' AS Result, 'Invalid credentials' AS Message;
    END
END
GO

-- ============================================
-- STUDENT OPERATIONS
-- ============================================

-- SP: Add Student (Admin/Instructor only)
CREATE OR ALTER PROCEDURE sp_AddStudent
    @FullName NVARCHAR(100),
    @Email NVARCHAR(100),
    @Phone NVARCHAR(20),
    @DOB DATE,
    @Department NVARCHAR(50),
    @UserID INT = NULL, -- Link to user account
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
            RAISERROR('Access Denied: Insufficient privileges', 16, 1);
            RETURN;
        END
        
        -- MLS Check: No Write Down (Level 2 - Confidential)
        IF @RequestingUserClearance < 2
        BEGIN
            RAISERROR('MLS Violation: Cannot write to Confidential level', 16, 1);
            RETURN;
        END
        
        -- Open symmetric key for encryption
        OPEN SYMMETRIC KEY StudentRecordsKey
        DECRYPTION BY CERTIFICATE StudentRecordsCert;
        
        DECLARE @PhoneEncrypted VARBINARY(256) = EncryptByKey(Key_GUID('StudentRecordsKey'), @Phone);
        
        CLOSE SYMMETRIC KEY StudentRecordsKey;
        
        -- Insert student
        INSERT INTO Student (FullName, Email, PhoneEncrypted, DOB, Department, UserID)
        VALUES (@FullName, @Email, @PhoneEncrypted, @DOB, @Department, @UserID);
        
        DECLARE @NewStudentID INT = SCOPE_IDENTITY();
        
        -- Update encrypted StudentID
        OPEN SYMMETRIC KEY StudentRecordsKey
        DECRYPTION BY CERTIFICATE StudentRecordsCert;
        
        UPDATE Student 
        SET StudentIDEncrypted = EncryptByKey(Key_GUID('StudentRecordsKey'), CAST(@NewStudentID AS VARCHAR(10)))
        WHERE StudentID = @NewStudentID;
        
        CLOSE SYMMETRIC KEY StudentRecordsKey;
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected, RecordID)
        VALUES (@RequestingUserID, 'Add Student', 'Student', @NewStudentID);
        
        SELECT 'Success' AS Result, @NewStudentID AS StudentID;
    END TRY
    BEGIN CATCH
        IF (SELECT COUNT(*) FROM sys.openkeys WHERE key_name = 'StudentRecordsKey') > 0
            CLOSE SYMMETRIC KEY StudentRecordsKey;
            
        INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage)
        VALUES (@RequestingUserID, 'Add Student Failed', 0, ERROR_MESSAGE());
        
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: View Student Profile (with MLS and RBAC)
CREATE OR ALTER PROCEDURE sp_ViewStudentProfile
    @StudentID INT,
    @RequestingUserID INT,
    @RequestingUserClearance INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- MLS Check: No Read Up
        DECLARE @DataClassification INT;
        SELECT @DataClassification = ClassificationLevel FROM Student WHERE StudentID = @StudentID;
        
        IF @RequestingUserClearance < @DataClassification
        BEGIN
            RAISERROR('MLS Violation: Cannot read higher classification', 16, 1);
            RETURN;
        END
        
        -- RBAC Check
        DECLARE @RequesterRole NVARCHAR(20);
        SELECT @RequesterRole = Role FROM Users WHERE UserID = @RequestingUserID;
        
        -- Students can only view their own profile
        IF @RequesterRole = 'Student'
        BEGIN
            DECLARE @LinkedUserID INT;
            SELECT @LinkedUserID = UserID FROM Student WHERE StudentID = @StudentID;
            
            IF @LinkedUserID != @RequestingUserID
            BEGIN
                RAISERROR('Access Denied: Can only view own profile', 16, 1);
                RETURN;
            END
        END
        
        -- Open symmetric key for decryption
        OPEN SYMMETRIC KEY StudentRecordsKey
        DECRYPTION BY CERTIFICATE StudentRecordsCert;
        
        SELECT 
            StudentID,
            FullName,
            Email,
            CAST(DecryptByKey(PhoneEncrypted) AS NVARCHAR(20)) AS Phone,
            DOB,
            Department,
            ClearanceLevel
        FROM Student
        WHERE StudentID = @StudentID;
        
        CLOSE SYMMETRIC KEY StudentRecordsKey;
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected, RecordID)
        VALUES (@RequestingUserID, 'View Student Profile', 'Student', @StudentID);
        
    END TRY
    BEGIN CATCH
        IF (SELECT COUNT(*) FROM sys.openkeys WHERE key_name = 'StudentRecordsKey') > 0
            CLOSE SYMMETRIC KEY StudentRecordsKey;
            
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- ============================================
-- GRADE OPERATIONS
-- ============================================

-- SP: Enter Grade (Instructor/Admin only)
CREATE OR ALTER PROCEDURE sp_EnterGrade
    @StudentID INT,
    @CourseID INT,
    @GradeValue DECIMAL(5,2),
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
            RAISERROR('Access Denied: Only Instructors and Admins can enter grades', 16, 1);
            RETURN;
        END
        
        -- MLS Check: No Write Down (Level 3 - Secret)
        IF @RequestingUserClearance < 3
        BEGIN
            RAISERROR('MLS Violation: Cannot write to Secret level', 16, 1);
            RETURN;
        END
        
        -- Get Instructor ID
        DECLARE @InstructorID INT;
        SELECT @InstructorID = InstructorID FROM Instructor WHERE UserID = @RequestingUserID;
        
        IF @InstructorID IS NULL AND @RequesterRole != 'Admin'
        BEGIN
            RAISERROR('Instructor record not found', 16, 1);
            RETURN;
        END
        
        -- For Instructors: verify they teach this course
        IF @RequesterRole = 'Instructor'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID AND InstructorID = @InstructorID)
            BEGIN
                RAISERROR('Access Denied: You do not teach this course', 16, 1);
                RETURN;
            END
        END
        
        -- Open symmetric key for encryption
        OPEN SYMMETRIC KEY StudentRecordsKey
        DECRYPTION BY CERTIFICATE StudentRecordsCert;
        
        DECLARE @StudentIDEncrypted VARBINARY(256) = EncryptByKey(Key_GUID('StudentRecordsKey'), CAST(@StudentID AS VARCHAR(10)));
        DECLARE @GradeValueEncrypted VARBINARY(256) = EncryptByKey(Key_GUID('StudentRecordsKey'), CAST(@GradeValue AS VARCHAR(10)));
        
        CLOSE SYMMETRIC KEY StudentRecordsKey;
        
        -- Insert grade
        INSERT INTO Grades (StudentIDEncrypted, CourseID, GradeValueEncrypted, EnteredByInstructorID)
        VALUES (@StudentIDEncrypted, @CourseID, @GradeValueEncrypted, ISNULL(@InstructorID, 1));
        
        DECLARE @GradeID INT = SCOPE_IDENTITY();
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected, RecordID)
        VALUES (@RequestingUserID, 'Enter Grade', 'Grades', @GradeID);
        
        SELECT 'Success' AS Result, @GradeID AS GradeID;
    END TRY
    BEGIN CATCH
        IF (SELECT COUNT(*) FROM sys.openkeys WHERE key_name = 'StudentRecordsKey') > 0
            CLOSE SYMMETRIC KEY StudentRecordsKey;
            
        INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage)
        VALUES (@RequestingUserID, 'Enter Grade Failed', 0, ERROR_MESSAGE());
        
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: View Grades (with RBAC and MLS)
CREATE OR ALTER PROCEDURE sp_ViewGrades
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
        
        IF @RequesterRole NOT IN ('Admin', 'Instructor')
        BEGIN
            RAISERROR('Access Denied: Only Instructors and Admins can view all grades', 16, 1);
            RETURN;
        END
        
        -- For Instructors: filter by their courses
        DECLARE @InstructorID INT;
        IF @RequesterRole = 'Instructor'
        BEGIN
            SELECT @InstructorID = InstructorID FROM Instructor WHERE UserID = @RequestingUserID;
        END
        
        -- Open symmetric key for decryption
        OPEN SYMMETRIC KEY StudentRecordsKey
        DECRYPTION BY CERTIFICATE StudentRecordsCert;
        
        SELECT 
            g.GradeID,
            CAST(CAST(DecryptByKey(g.StudentIDEncrypted) AS VARCHAR(10)) AS INT) AS StudentID,
            s.FullName AS StudentName,
            g.CourseID,
            c.CourseName,
            CAST(CAST(DecryptByKey(g.GradeValueEncrypted) AS VARCHAR(10)) AS DECIMAL(5,2)) AS GradeValue,
            g.DateEntered,
            i.FullName AS EnteredBy
        FROM Grades g
        INNER JOIN Course c ON g.CourseID = c.CourseID
        INNER JOIN Instructor i ON g.EnteredByInstructorID = i.InstructorID
        LEFT JOIN Student s ON s.StudentID = CAST(CAST(DecryptByKey(g.StudentIDEncrypted) AS VARCHAR(10)) AS INT)
        WHERE 
            (@StudentID IS NULL OR CAST(CAST(DecryptByKey(g.StudentIDEncrypted) AS VARCHAR(10)) AS INT) = @StudentID)
            AND (@CourseID IS NULL OR g.CourseID = @CourseID)
            AND (@RequesterRole = 'Admin' OR c.InstructorID = @InstructorID);
        
        CLOSE SYMMETRIC KEY StudentRecordsKey;
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected)
        VALUES (@RequestingUserID, 'View Grades', 'Grades');
        
    END TRY
    BEGIN CATCH
        IF (SELECT COUNT(*) FROM sys.openkeys WHERE key_name = 'StudentRecordsKey') > 0
            CLOSE SYMMETRIC KEY StudentRecordsKey;
            
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: Student View Own Grades
CREATE OR ALTER PROCEDURE sp_StudentViewOwnGrades
    @RequestingUserID INT
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
        
        -- Open symmetric key for decryption
        OPEN SYMMETRIC KEY StudentRecordsKey
        DECRYPTION BY CERTIFICATE StudentRecordsCert;
        
        SELECT 
            c.CourseName,
            CAST(CAST(DecryptByKey(g.GradeValueEncrypted) AS VARCHAR(10)) AS DECIMAL(5,2)) AS GradeValue,
            g.DateEntered
        FROM Grades g
        INNER JOIN Course c ON g.CourseID = c.CourseID
        WHERE CAST(CAST(DecryptByKey(g.StudentIDEncrypted) AS VARCHAR(10)) AS INT) = @StudentID;
        
        CLOSE SYMMETRIC KEY StudentRecordsKey;
        
        -- Audit log
        INSERT INTO AuditLog (UserID, Action, TableAffected)
        VALUES (@RequestingUserID, 'View Own Grades', 'Grades');
        
    END TRY
    BEGIN CATCH
        IF (SELECT COUNT(*) FROM sys.openkeys WHERE key_name = 'StudentRecordsKey') > 0
            CLOSE SYMMETRIC KEY StudentRecordsKey;
            
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

PRINT 'Part 1 of stored procedures created successfully.';
GO

