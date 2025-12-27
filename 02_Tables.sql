-- ============================================
-- Database Security Term Project
-- Part A & B: Table Creation
-- ============================================
-- This script creates all required tables with security classifications

USE SecureStudentRecords;
GO

-- ============================================
-- Classification Levels for MLS:
-- 1 = Unclassified
-- 2 = Confidential
-- 3 = Secret
-- 4 = Top Secret
-- ============================================

-- Table: USERS (Authentication)
-- Security: Encrypted passwords using symmetric key (like examples)
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) UNIQUE NOT NULL,
    PasswordEncrypted VARBINARY(MAX) NOT NULL, -- Encrypted password (like examples)
    Role NVARCHAR(20) NOT NULL CHECK (Role IN ('Admin', 'Instructor', 'TA', 'Student', 'Guest')),
    ClearanceLevel INT NOT NULL CHECK (ClearanceLevel BETWEEN 1 AND 4),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    LastLogin DATETIME NULL,
    CONSTRAINT CK_Role_Clearance CHECK (
        (Role = 'Admin' AND ClearanceLevel = 4) OR
        (Role = 'Instructor' AND ClearanceLevel >= 3) OR
        (Role = 'TA' AND ClearanceLevel >= 2) OR
        (Role = 'Student' AND ClearanceLevel >= 1) OR
        (Role = 'Guest' AND ClearanceLevel = 1)
    )
);
GO

-- Table: STUDENT (Confidential - Level 2)
CREATE TABLE Student (
    StudentID INT IDENTITY(1,1) PRIMARY KEY,
    StudentIDEncrypted VARBINARY(256) NULL, -- Encrypted version of StudentID for external use
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    PhoneEncrypted VARBINARY(256) NULL, -- Encrypted phone
    DOB DATE NOT NULL,
    Department NVARCHAR(50) NOT NULL,
    ClearanceLevel INT DEFAULT 1,
    ClassificationLevel INT DEFAULT 2, -- Confidential
    UserID INT NULL, -- Link to Users table
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Student_User FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
GO

-- Table: INSTRUCTOR (Confidential - Level 2)
CREATE TABLE Instructor (
    InstructorID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Department NVARCHAR(50) NOT NULL,
    ClearanceLevel INT DEFAULT 3,
    ClassificationLevel INT DEFAULT 2, -- Confidential
    UserID INT NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Instructor_User FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
GO

-- Table: COURSE (Unclassified - Level 1)
CREATE TABLE Course (
    CourseID INT IDENTITY(1,1) PRIMARY KEY,
    CourseName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    PublicInfo NVARCHAR(MAX) NULL, -- Visible to all including Guest
    InstructorID INT NULL,
    ClassificationLevel INT DEFAULT 1, -- Unclassified
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Course_Instructor FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID)
);
GO

-- Table: GRADES (Secret - Level 3)
CREATE TABLE Grades (
    GradeID INT IDENTITY(1,1) PRIMARY KEY,
    StudentIDEncrypted VARBINARY(256) NOT NULL, -- Encrypted Student ID
    CourseID INT NOT NULL,
    GradeValueEncrypted VARBINARY(256) NOT NULL, -- Encrypted grade value
    DateEntered DATETIME DEFAULT GETDATE(),
    EnteredByInstructorID INT NOT NULL,
    ClassificationLevel INT DEFAULT 3, -- Secret
    CONSTRAINT FK_Grades_Course FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    CONSTRAINT FK_Grades_Instructor FOREIGN KEY (EnteredByInstructorID) REFERENCES Instructor(InstructorID)
);
GO

-- Table: ATTENDANCE (Secret - Level 3)
CREATE TABLE Attendance (
    AttendanceID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    Status BIT NOT NULL, -- 1 = Present, 0 = Absent
    DateRecorded DATETIME DEFAULT GETDATE(),
    RecordedByUserID INT NULL,
    ClassificationLevel INT DEFAULT 3, -- Secret
    CONSTRAINT FK_Attendance_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    CONSTRAINT FK_Attendance_Course FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    CONSTRAINT FK_Attendance_User FOREIGN KEY (RecordedByUserID) REFERENCES Users(UserID)
);
GO

-- Table: COURSE_ENROLLMENT
-- Links students to courses, also tracks which TAs are assigned to which courses
CREATE TABLE CourseEnrollment (
    EnrollmentID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    EnrollmentDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Enrollment_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    CONSTRAINT FK_Enrollment_Course FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    CONSTRAINT UK_Student_Course UNIQUE (StudentID, CourseID)
);
GO

-- Table: TA_ASSIGNMENT
-- Tracks which TAs are assigned to which courses
CREATE TABLE TAAssignment (
    AssignmentID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL, -- TA User
    CourseID INT NOT NULL,
    AssignedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_TAAssignment_User FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_TAAssignment_Course FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    CONSTRAINT UK_TA_Course UNIQUE (UserID, CourseID)
);
GO

-- ============================================
-- PART B: Role Request Workflow Tables
-- ============================================

-- Table: ROLE_REQUESTS
CREATE TABLE RoleRequests (
    RequestID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    Username NVARCHAR(50) NOT NULL,
    CurrentRole NVARCHAR(20) NOT NULL,
    RequestedRole NVARCHAR(20) NOT NULL CHECK (RequestedRole IN ('Admin', 'Instructor', 'TA', 'Student')),
    Reason NVARCHAR(500) NOT NULL,
    Comments NVARCHAR(MAX) NULL,
    Status NVARCHAR(20) DEFAULT 'Pending' CHECK (Status IN ('Pending', 'Approved', 'Denied')),
    RequestDate DATETIME DEFAULT GETDATE(),
    ProcessedDate DATETIME NULL,
    ProcessedByAdminID INT NULL,
    AdminComments NVARCHAR(MAX) NULL,
    CONSTRAINT FK_RoleRequest_User FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_RoleRequest_Admin FOREIGN KEY (ProcessedByAdminID) REFERENCES Users(UserID)
);
GO

-- Table: AUDIT_LOG
-- Tracks all security-sensitive operations
CREATE TABLE AuditLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NULL,
    Username NVARCHAR(50) NULL,
    Action NVARCHAR(100) NOT NULL,
    TableAffected NVARCHAR(50) NULL,
    RecordID INT NULL,
    OldValue NVARCHAR(MAX) NULL,
    NewValue NVARCHAR(MAX) NULL,
    ActionDate DATETIME DEFAULT GETDATE(),
    IPAddress NVARCHAR(50) NULL,
    Success BIT DEFAULT 1,
    ErrorMessage NVARCHAR(MAX) NULL
);
GO

PRINT 'All tables created successfully.';
GO

