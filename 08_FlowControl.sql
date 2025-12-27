-- ============================================
-- Database Security Term Project
-- Part A: Flow Control Implementation
-- ============================================
-- Prevents data from moving from higher to lower classification

USE SecureStudentRecords;
GO

-- ============================================
-- FLOW CONTROL FUNCTIONS
-- Classification Levels:
-- 1 = Unclassified
-- 2 = Confidential  
-- 3 = Secret
-- 4 = Top Secret
-- ============================================

-- Function: Check Flow Control Violation
CREATE OR ALTER FUNCTION fn_CheckFlowControl
(
    @SourceClassification INT,
    @DestinationClassification INT,
    @UserClearance INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Allowed BIT = 0;
    
    -- Bell-LaPadula No Read Up: User cannot read above clearance
    IF @SourceClassification > @UserClearance
        RETURN 0;
    
    -- Bell-LaPadula No Write Down: User cannot write to lower classification
    IF @DestinationClassification < @UserClearance
        RETURN 0;
    
    -- Flow Control: Data cannot flow from high to low classification
    IF @SourceClassification > @DestinationClassification
        RETURN 0;
    
    -- All checks passed
    RETURN 1;
END
GO

-- ============================================
-- FLOW CONTROL STORED PROCEDURES
-- ============================================

-- SP: Copy/Export Data with Flow Control Check
CREATE OR ALTER PROCEDURE sp_ExportData
    @TableName NVARCHAR(50),
    @RecordID INT,
    @DestinationClassification INT,
    @RequestingUserID INT,
    @RequestingUserClearance INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Get source classification
        DECLARE @SourceClassification INT;
        DECLARE @SQL NVARCHAR(MAX);
        
        IF @TableName = 'Student'
            SELECT @SourceClassification = ClassificationLevel FROM Student WHERE StudentID = @RecordID;
        ELSE IF @TableName = 'Grades'
            SELECT @SourceClassification = ClassificationLevel FROM Grades WHERE GradeID = @RecordID;
        ELSE IF @TableName = 'Attendance'
            SELECT @SourceClassification = ClassificationLevel FROM Attendance WHERE AttendanceID = @RecordID;
        ELSE IF @TableName = 'Instructor'
            SELECT @SourceClassification = ClassificationLevel FROM Instructor WHERE InstructorID = @RecordID;
        ELSE
        BEGIN
            RAISERROR('Invalid table name', 16, 1);
            RETURN;
        END
        
        -- Check Flow Control
        IF dbo.fn_CheckFlowControl(@SourceClassification, @DestinationClassification, @RequestingUserClearance) = 0
        BEGIN
            DECLARE @ErrorMsg NVARCHAR(200) = 'Flow Control Violation: Cannot export ' + 
                CASE @SourceClassification
                    WHEN 4 THEN 'Top Secret'
                    WHEN 3 THEN 'Secret'
                    WHEN 2 THEN 'Confidential'
                    WHEN 1 THEN 'Unclassified'
                END + ' data to ' +
                CASE @DestinationClassification
                    WHEN 4 THEN 'Top Secret'
                    WHEN 3 THEN 'Secret'
                    WHEN 2 THEN 'Confidential'
                    WHEN 1 THEN 'Unclassified'
                END + ' destination';
            
            -- Audit log
            INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage, TableAffected, RecordID)
            VALUES (@RequestingUserID, 'Export Data Blocked', 0, @ErrorMsg, @TableName, @RecordID);
            
            RAISERROR('%s', 16, 1, @ErrorMsg);
            RETURN;
        END
        
        -- Export allowed
        INSERT INTO AuditLog (UserID, Action, TableAffected, RecordID)
        VALUES (@RequestingUserID, 'Export Data Allowed', @TableName, @RecordID);
        
        SELECT 'Success' AS Result, 'Data export allowed' AS Message;
        
    END TRY
    BEGIN CATCH
        INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage)
        VALUES (@RequestingUserID, 'Export Data Failed', 0, ERROR_MESSAGE());
        
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: Transfer Data Between Classifications (Flow Control)
CREATE OR ALTER PROCEDURE sp_TransferDataWithFlowControl
    @SourceTable NVARCHAR(50),
    @SourceRecordID INT,
    @DestinationTable NVARCHAR(50),
    @RequestingUserID INT,
    @RequestingUserClearance INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Get source and destination classifications
        DECLARE @SourceClassification INT;
        DECLARE @DestinationClassification INT;
        
        -- Determine source classification
        IF @SourceTable = 'Student'
            SELECT @SourceClassification = ClassificationLevel FROM Student WHERE StudentID = @SourceRecordID;
        ELSE IF @SourceTable = 'Grades'
            SELECT @SourceClassification = ClassificationLevel FROM Grades WHERE GradeID = @SourceRecordID;
        ELSE IF @SourceTable = 'Attendance'
            SELECT @SourceClassification = ClassificationLevel FROM Attendance WHERE AttendanceID = @SourceRecordID;
        
        -- Determine destination classification (default for table type)
        IF @DestinationTable = 'Student'
            SET @DestinationClassification = 2; -- Confidential
        ELSE IF @DestinationTable = 'Grades' OR @DestinationTable = 'Attendance'
            SET @DestinationClassification = 3; -- Secret
        ELSE IF @DestinationTable = 'Course'
            SET @DestinationClassification = 1; -- Unclassified
        
        -- Flow Control Check
        IF @SourceClassification > @DestinationClassification
        BEGIN
            DECLARE @FlowErrorMsg NVARCHAR(200) = 
                'Flow Control Violation: Cannot transfer data from higher classification (' +
                CAST(@SourceClassification AS VARCHAR) + ') to lower classification (' +
                CAST(@DestinationClassification AS VARCHAR) + ')';
            
            -- Audit log
            INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage)
            VALUES (@RequestingUserID, 'Data Transfer Blocked', 0, @FlowErrorMsg);
            
            RAISERROR('%s', 16, 1, @FlowErrorMsg);
            RETURN;
        END
        
        -- MLS Check: No Write Down
        IF @RequestingUserClearance > @DestinationClassification
        BEGIN
            RAISERROR('MLS Violation: Cannot write down to lower classification', 16, 1);
            RETURN;
        END
        
        -- Transfer allowed
        INSERT INTO AuditLog (UserID, Action, TableAffected)
        VALUES (@RequestingUserID, 'Data Transfer Allowed', @SourceTable + ' -> ' + @DestinationTable);
        
        SELECT 'Success' AS Result, 'Data transfer allowed' AS Message;
        
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: Check if Copy/Export Operation is Allowed
CREATE OR ALTER PROCEDURE sp_CanExportData
    @TableName NVARCHAR(50),
    @RecordID INT,
    @RequestingUserID INT,
    @RequestingUserClearance INT,
    @ExportType NVARCHAR(20) -- 'Print', 'Copy', 'Download', 'Export'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Get data classification
        DECLARE @DataClassification INT;
        
        IF @TableName = 'Student'
            SELECT @DataClassification = ClassificationLevel FROM Student WHERE StudentID = @RecordID;
        ELSE IF @TableName = 'Grades'
            SELECT @DataClassification = ClassificationLevel FROM Grades WHERE GradeID = @RecordID;
        ELSE IF @TableName = 'Attendance'
            SELECT @DataClassification = ClassificationLevel FROM Attendance WHERE AttendanceID = @RecordID;
        ELSE IF @TableName = 'Instructor'
            SELECT @DataClassification = ClassificationLevel FROM Instructor WHERE InstructorID = @RecordID;
        
        -- Flow Control Rule: Secret and Top Secret data cannot be exported/copied/printed
        IF @DataClassification >= 3 -- Secret or Top Secret
        BEGIN
            -- Audit the attempt
            INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage, TableAffected, RecordID)
            VALUES (@RequestingUserID, @ExportType + ' Blocked', 0, 
                    'Flow Control: Cannot export Secret/Top Secret data', @TableName, @RecordID);
            
            SELECT 
                'Denied' AS Result, 
                0 AS CanExport,
                'Flow Control: Export of Secret/Top Secret data is prohibited' AS Reason,
                @DataClassification AS Classification;
            RETURN;
        END
        
        -- MLS Check: User must have sufficient clearance
        IF @RequestingUserClearance < @DataClassification
        BEGIN
            INSERT INTO AuditLog (UserID, Action, Success, ErrorMessage, TableAffected, RecordID)
            VALUES (@RequestingUserID, @ExportType + ' Blocked', 0, 
                    'MLS: Insufficient clearance', @TableName, @RecordID);
            
            SELECT 
                'Denied' AS Result, 
                0 AS CanExport,
                'MLS: Insufficient clearance level' AS Reason;
            RETURN;
        END
        
        -- Export allowed
        SELECT 
            'Allowed' AS Result, 
            1 AS CanExport,
            'Export permitted' AS Reason,
            @DataClassification AS Classification;
        
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Result, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
GO

-- SP: Log Copy/Paste Attempt (for GUI integration)
CREATE OR ALTER PROCEDURE sp_LogCopyPasteAttempt
    @TableName NVARCHAR(50),
    @RecordID INT,
    @Action NVARCHAR(20), -- 'Copy', 'Paste', 'Cut'
    @Allowed BIT,
    @RequestingUserID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO AuditLog (
        UserID, 
        Action, 
        TableAffected, 
        RecordID, 
        Success,
        ErrorMessage
    )
    VALUES (
        @RequestingUserID,
        @Action + ' Operation',
        @TableName,
        @RecordID,
        @Allowed,
        CASE WHEN @Allowed = 0 THEN 'Flow Control: Operation blocked' ELSE NULL END
    );
END
GO

-- ============================================
-- TRIGGERS FOR FLOW CONTROL
-- ============================================

-- Trigger: Prevent downgrade of classification
CREATE OR ALTER TRIGGER trg_PreventClassificationDowngrade
ON Student
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF UPDATE(ClassificationLevel)
    BEGIN
        -- Check if classification was lowered
        IF EXISTS (
            SELECT 1 
            FROM inserted i
            INNER JOIN deleted d ON i.StudentID = d.StudentID
            WHERE i.ClassificationLevel < d.ClassificationLevel
        )
        BEGIN
            -- Log the violation
            INSERT INTO AuditLog (Action, Success, ErrorMessage, TableAffected)
            VALUES ('Classification Downgrade Attempt', 0, 
                    'Flow Control: Cannot lower classification level', 'Student');
            
            RAISERROR('Flow Control Violation: Cannot downgrade classification level', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END
GO

-- Trigger: Prevent Grade Classification Downgrade
CREATE OR ALTER TRIGGER trg_PreventGradeClassificationDowngrade
ON Grades
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF UPDATE(ClassificationLevel)
    BEGIN
        IF EXISTS (
            SELECT 1 
            FROM inserted i
            INNER JOIN deleted d ON i.GradeID = d.GradeID
            WHERE i.ClassificationLevel < d.ClassificationLevel
        )
        BEGIN
            INSERT INTO AuditLog (Action, Success, ErrorMessage, TableAffected)
            VALUES ('Classification Downgrade Attempt', 0, 
                    'Flow Control: Cannot lower grade classification', 'Grades');
            
            RAISERROR('Flow Control Violation: Cannot downgrade grade classification', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END
GO

-- Trigger: Prevent Attendance Classification Downgrade
CREATE OR ALTER TRIGGER trg_PreventAttendanceClassificationDowngrade
ON Attendance
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF UPDATE(ClassificationLevel)
    BEGIN
        IF EXISTS (
            SELECT 1 
            FROM inserted i
            INNER JOIN deleted d ON i.AttendanceID = d.AttendanceID
            WHERE i.ClassificationLevel < d.ClassificationLevel
        )
        BEGIN
            INSERT INTO AuditLog (Action, Success, ErrorMessage, TableAffected)
            VALUES ('Classification Downgrade Attempt', 0, 
                    'Flow Control: Cannot lower attendance classification', 'Attendance');
            
            RAISERROR('Flow Control Violation: Cannot downgrade attendance classification', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END
GO

-- SP: Validate Data Flow Before Operation
CREATE OR ALTER PROCEDURE sp_ValidateDataFlow
    @SourceClassification INT,
    @DestinationClassification INT,
    @UserClearance INT,
    @Operation NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IsAllowed BIT = 1;
    DECLARE @ViolationReason NVARCHAR(200) = '';
    
    -- Check No Read Up
    IF @SourceClassification > @UserClearance
    BEGIN
        SET @IsAllowed = 0;
        SET @ViolationReason = 'MLS Violation: No Read Up - Cannot read data with higher classification';
    END
    
    -- Check No Write Down
    IF @DestinationClassification < @UserClearance AND @DestinationClassification > 0
    BEGIN
        SET @IsAllowed = 0;
        SET @ViolationReason = 'MLS Violation: No Write Down - Cannot write to lower classification';
    END
    
    -- Check Flow Control
    IF @SourceClassification > @DestinationClassification AND @DestinationClassification > 0
    BEGIN
        SET @IsAllowed = 0;
        SET @ViolationReason = 'Flow Control Violation: Data cannot flow from high to low classification';
    END
    
    SELECT 
        @IsAllowed AS IsAllowed,
        @ViolationReason AS ViolationReason,
        @SourceClassification AS SourceLevel,
        @DestinationClassification AS DestinationLevel,
        @UserClearance AS UserClearance,
        CASE @SourceClassification
            WHEN 4 THEN 'Top Secret'
            WHEN 3 THEN 'Secret'
            WHEN 2 THEN 'Confidential'
            WHEN 1 THEN 'Unclassified'
        END AS SourceLevelName,
        CASE @DestinationClassification
            WHEN 4 THEN 'Top Secret'
            WHEN 3 THEN 'Secret'
            WHEN 2 THEN 'Confidential'
            WHEN 1 THEN 'Unclassified'
            WHEN 0 THEN 'N/A'
        END AS DestinationLevelName;
END
GO

PRINT 'Flow Control procedures and triggers created successfully.';
GO

