-- ============================================
-- Database Security Term Project
-- Part A & B: Sample Data Insertion
-- ============================================
-- Test data for all tables with proper encryption

USE SecureStudentRecords;
GO

PRINT 'Starting sample data insertion...';
GO

-- ============================================
-- INSERT USERS (All Roles)
-- ============================================

-- Admin User
EXEC sp_RegisterUser 
    @Username = 'admin1', 
    @Password = 'Admin@123', 
    @Role = 'Admin', 
    @ClearanceLevel = 4;

-- Instructors
EXEC sp_RegisterUser 
    @Username = 'prof.smith', 
    @Password = 'Prof@123', 
    @Role = 'Instructor', 
    @ClearanceLevel = 3;

EXEC sp_RegisterUser 
    @Username = 'prof.jones', 
    @Password = 'Prof@123', 
    @Role = 'Instructor', 
    @ClearanceLevel = 3;

EXEC sp_RegisterUser 
    @Username = 'prof.brown', 
    @Password = 'Prof@123', 
    @Role = 'Instructor', 
    @ClearanceLevel = 3;

-- TAs
EXEC sp_RegisterUser 
    @Username = 'ta.alice', 
    @Password = 'TA@123', 
    @Role = 'TA', 
    @ClearanceLevel = 2;

EXEC sp_RegisterUser 
    @Username = 'ta.bob', 
    @Password = 'TA@123', 
    @Role = 'TA', 
    @ClearanceLevel = 2;

EXEC sp_RegisterUser 
    @Username = 'ta.charlie', 
    @Password = 'TA@123', 
    @Role = 'TA', 
    @ClearanceLevel = 2;

-- Students
EXEC sp_RegisterUser 
    @Username = 'student.john', 
    @Password = 'Student@123', 
    @Role = 'Student', 
    @ClearanceLevel = 1;

EXEC sp_RegisterUser 
    @Username = 'student.mary', 
    @Password = 'Student@123', 
    @Role = 'Student', 
    @ClearanceLevel = 1;

EXEC sp_RegisterUser 
    @Username = 'student.david', 
    @Password = 'Student@123', 
    @Role = 'Student', 
    @ClearanceLevel = 1;

EXEC sp_RegisterUser 
    @Username = 'student.sarah', 
    @Password = 'Student@123', 
    @Role = 'Student', 
    @ClearanceLevel = 1;

EXEC sp_RegisterUser 
    @Username = 'student.mike', 
    @Password = 'Student@123', 
    @Role = 'Student', 
    @ClearanceLevel = 1;

EXEC sp_RegisterUser 
    @Username = 'student.emma', 
    @Password = 'Student@123', 
    @Role = 'Student', 
    @ClearanceLevel = 1;

EXEC sp_RegisterUser 
    @Username = 'student.james', 
    @Password = 'Student@123', 
    @Role = 'Student', 
    @ClearanceLevel = 1;

EXEC sp_RegisterUser 
    @Username = 'student.lisa', 
    @Password = 'Student@123', 
    @Role = 'Student', 
    @ClearanceLevel = 1;

-- Guest
EXEC sp_RegisterUser 
    @Username = 'guest1', 
    @Password = 'Guest@123', 
    @Role = 'Guest', 
    @ClearanceLevel = 1;

PRINT 'Users created successfully.';
GO

-- ============================================
-- INSERT INSTRUCTORS
-- ============================================

INSERT INTO Instructor (FullName, Email, Department, ClearanceLevel, UserID)
VALUES 
    ('Dr. John Smith', 'john.smith@university.edu', 'Computer Science', 3, 
     (SELECT UserID FROM Users WHERE Username = 'prof.smith')),
    ('Dr. Emily Jones', 'emily.jones@university.edu', 'Mathematics', 3, 
     (SELECT UserID FROM Users WHERE Username = 'prof.jones')),
    ('Dr. Michael Brown', 'michael.brown@university.edu', 'Computer Science', 3, 
     (SELECT UserID FROM Users WHERE Username = 'prof.brown'));

PRINT 'Instructors created successfully.';
GO

-- ============================================
-- INSERT STUDENTS (Using Stored Procedure)
-- ============================================

DECLARE @AdminID INT;
DECLARE @StudentJohnID INT;
DECLARE @StudentMaryID INT;
DECLARE @StudentDavidID INT;
DECLARE @StudentSarahID INT;
DECLARE @StudentMikeID INT;
DECLARE @StudentEmmaID INT;
DECLARE @StudentJamesID INT;
DECLARE @StudentLisaID INT;

SELECT @AdminID = UserID FROM Users WHERE Username = 'admin1';
SELECT @StudentJohnID = UserID FROM Users WHERE Username = 'student.john';
SELECT @StudentMaryID = UserID FROM Users WHERE Username = 'student.mary';
SELECT @StudentDavidID = UserID FROM Users WHERE Username = 'student.david';
SELECT @StudentSarahID = UserID FROM Users WHERE Username = 'student.sarah';
SELECT @StudentMikeID = UserID FROM Users WHERE Username = 'student.mike';
SELECT @StudentEmmaID = UserID FROM Users WHERE Username = 'student.emma';
SELECT @StudentJamesID = UserID FROM Users WHERE Username = 'student.james';
SELECT @StudentLisaID = UserID FROM Users WHERE Username = 'student.lisa';

-- Student 1: John Doe
EXEC sp_AddStudent 
    @FullName = 'John Doe',
    @Email = 'john.doe@student.edu',
    @Phone = '555-0101',
    @DOB = '2002-05-15',
    @Department = 'Computer Science',
    @UserID = @StudentJohnID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

-- Student 2: Mary Johnson
EXEC sp_AddStudent 
    @FullName = 'Mary Johnson',
    @Email = 'mary.johnson@student.edu',
    @Phone = '555-0102',
    @DOB = '2001-08-22',
    @Department = 'Computer Science',
    @UserID = @StudentMaryID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

-- Student 3: David Wilson
EXEC sp_AddStudent 
    @FullName = 'David Wilson',
    @Email = 'david.wilson@student.edu',
    @Phone = '555-0103',
    @DOB = '2002-03-10',
    @Department = 'Computer Science',
    @UserID = @StudentDavidID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

-- Student 4: Sarah Martinez
EXEC sp_AddStudent 
    @FullName = 'Sarah Martinez',
    @Email = 'sarah.martinez@student.edu',
    @Phone = '555-0104',
    @DOB = '2002-11-30',
    @Department = 'Mathematics',
    @UserID = @StudentSarahID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

-- Student 5: Mike Anderson
EXEC sp_AddStudent 
    @FullName = 'Mike Anderson',
    @Email = 'mike.anderson@student.edu',
    @Phone = '555-0105',
    @DOB = '2001-07-18',
    @Department = 'Mathematics',
    @UserID = @StudentMikeID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

-- Student 6: Emma Taylor
EXEC sp_AddStudent 
    @FullName = 'Emma Taylor',
    @Email = 'emma.taylor@student.edu',
    @Phone = '555-0106',
    @DOB = '2002-01-25',
    @Department = 'Computer Science',
    @UserID = @StudentEmmaID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

-- Student 7: James Lee
EXEC sp_AddStudent 
    @FullName = 'James Lee',
    @Email = 'james.lee@student.edu',
    @Phone = '555-0107',
    @DOB = '2001-09-12',
    @Department = 'Computer Science',
    @UserID = @StudentJamesID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

-- Student 8: Lisa Chen
EXEC sp_AddStudent 
    @FullName = 'Lisa Chen',
    @Email = 'lisa.chen@student.edu',
    @Phone = '555-0108',
    @DOB = '2002-06-05',
    @Department = 'Mathematics',
    @UserID = @StudentLisaID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

PRINT 'Students created successfully.';
GO

-- ============================================
-- INSERT COURSES
-- ============================================

DECLARE @AdminID INT;
DECLARE @InstructorSmithID INT;
DECLARE @InstructorJonesID INT;
DECLARE @InstructorBrownID INT;

SELECT @AdminID = UserID FROM Users WHERE Username = 'admin1';
SELECT @InstructorSmithID = InstructorID FROM Instructor WHERE Email = 'john.smith@university.edu';
SELECT @InstructorJonesID = InstructorID FROM Instructor WHERE Email = 'emily.jones@university.edu';
SELECT @InstructorBrownID = InstructorID FROM Instructor WHERE Email = 'michael.brown@university.edu';

EXEC sp_AddCourse
    @CourseName = 'Database Systems',
    @Description = 'Advanced database design, SQL, and database security',
    @PublicInfo = 'Learn about relational databases and SQL. No prerequisites required.',
    @InstructorID = @InstructorSmithID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

EXEC sp_AddCourse
    @CourseName = 'Data Structures and Algorithms',
    @Description = 'Fundamental data structures and algorithmic techniques',
    @PublicInfo = 'Study arrays, linked lists, trees, graphs, and sorting algorithms.',
    @InstructorID = @InstructorSmithID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

EXEC sp_AddCourse
    @CourseName = 'Calculus I',
    @Description = 'Differential and integral calculus',
    @PublicInfo = 'Introduction to calculus: limits, derivatives, and integrals.',
    @InstructorID = @InstructorJonesID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

EXEC sp_AddCourse
    @CourseName = 'Linear Algebra',
    @Description = 'Matrices, vector spaces, and linear transformations',
    @PublicInfo = 'Mathematical foundations for computer science and engineering.',
    @InstructorID = @InstructorJonesID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

EXEC sp_AddCourse
    @CourseName = 'Network Security',
    @Description = 'Cryptography, secure protocols, and network defense',
    @PublicInfo = 'Learn about securing computer networks and communications.',
    @InstructorID = @InstructorBrownID,
    @RequestingUserID = @AdminID,
    @RequestingUserClearance = 4;

PRINT 'Courses created successfully.';
GO

-- ============================================
-- ENROLL STUDENTS IN COURSES
-- ============================================

DECLARE @AdminID INT;
SELECT @AdminID = UserID FROM Users WHERE Username = 'admin1';

-- Database Systems enrollments
EXEC sp_EnrollStudent @StudentID = 1, @CourseID = 1, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 2, @CourseID = 1, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 3, @CourseID = 1, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 6, @CourseID = 1, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 7, @CourseID = 1, @RequestingUserID = @AdminID;

-- Data Structures enrollments
EXEC sp_EnrollStudent @StudentID = 1, @CourseID = 2, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 2, @CourseID = 2, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 3, @CourseID = 2, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 6, @CourseID = 2, @RequestingUserID = @AdminID;

-- Calculus I enrollments
EXEC sp_EnrollStudent @StudentID = 4, @CourseID = 3, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 5, @CourseID = 3, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 8, @CourseID = 3, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 1, @CourseID = 3, @RequestingUserID = @AdminID;

-- Linear Algebra enrollments
EXEC sp_EnrollStudent @StudentID = 4, @CourseID = 4, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 5, @CourseID = 4, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 8, @CourseID = 4, @RequestingUserID = @AdminID;

-- Network Security enrollments
EXEC sp_EnrollStudent @StudentID = 2, @CourseID = 5, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 3, @CourseID = 5, @RequestingUserID = @AdminID;
EXEC sp_EnrollStudent @StudentID = 7, @CourseID = 5, @RequestingUserID = @AdminID;

PRINT 'Student enrollments completed successfully.';
GO

-- ============================================
-- ASSIGN TAs TO COURSES
-- ============================================

DECLARE @AdminID INT;
DECLARE @TAAliceID INT;
DECLARE @TABobID INT;
DECLARE @TACharlieID INT;

SELECT @AdminID = UserID FROM Users WHERE Username = 'admin1';
SELECT @TAAliceID = UserID FROM Users WHERE Username = 'ta.alice';
SELECT @TABobID = UserID FROM Users WHERE Username = 'ta.bob';
SELECT @TACharlieID = UserID FROM Users WHERE Username = 'ta.charlie';

-- TA Alice assigned to Database Systems
EXEC sp_AssignTA 
    @TAUserID = @TAAliceID,
    @CourseID = 1,
    @RequestingUserID = @AdminID;

-- TA Bob assigned to Data Structures
EXEC sp_AssignTA 
    @TAUserID = @TABobID,
    @CourseID = 2,
    @RequestingUserID = @AdminID;

-- TA Charlie assigned to Network Security
EXEC sp_AssignTA 
    @TAUserID = @TACharlieID,
    @CourseID = 5,
    @RequestingUserID = @AdminID;

-- TA Alice also assigned to Calculus I
EXEC sp_AssignTA 
    @TAUserID = @TAAliceID,
    @CourseID = 3,
    @RequestingUserID = @AdminID;

PRINT 'TA assignments completed successfully.';
GO

-- ============================================
-- INSERT GRADES (Using Stored Procedure)
-- ============================================

DECLARE @ProfSmithID INT;
DECLARE @ProfJonesID INT;
SELECT @ProfSmithID = UserID FROM Users WHERE Username = 'prof.smith';
SELECT @ProfJonesID = UserID FROM Users WHERE Username = 'prof.jones';

-- Database Systems grades
EXEC sp_EnterGrade @StudentID = 1, @CourseID = 1, @GradeValue = 85.5, 
     @RequestingUserID = @ProfSmithID, @RequestingUserClearance = 3;
EXEC sp_EnterGrade @StudentID = 2, @CourseID = 1, @GradeValue = 92.0, 
     @RequestingUserID = @ProfSmithID, @RequestingUserClearance = 3;
EXEC sp_EnterGrade @StudentID = 3, @CourseID = 1, @GradeValue = 78.5, 
     @RequestingUserID = @ProfSmithID, @RequestingUserClearance = 3;
EXEC sp_EnterGrade @StudentID = 6, @CourseID = 1, @GradeValue = 88.0, 
     @RequestingUserID = @ProfSmithID, @RequestingUserClearance = 3;
EXEC sp_EnterGrade @StudentID = 7, @CourseID = 1, @GradeValue = 91.5, 
     @RequestingUserID = @ProfSmithID, @RequestingUserClearance = 3;

-- Data Structures grades
EXEC sp_EnterGrade @StudentID = 1, @CourseID = 2, @GradeValue = 90.0, 
     @RequestingUserID = @ProfSmithID, @RequestingUserClearance = 3;
EXEC sp_EnterGrade @StudentID = 2, @CourseID = 2, @GradeValue = 95.5, 
     @RequestingUserID = @ProfSmithID, @RequestingUserClearance = 3;
EXEC sp_EnterGrade @StudentID = 3, @CourseID = 2, @GradeValue = 82.0, 
     @RequestingUserID = @ProfSmithID, @RequestingUserClearance = 3;
EXEC sp_EnterGrade @StudentID = 6, @CourseID = 2, @GradeValue = 87.5, 
     @RequestingUserID = @ProfSmithID, @RequestingUserClearance = 3;

-- Calculus I grades
EXEC sp_EnterGrade @StudentID = 4, @CourseID = 3, @GradeValue = 88.0, 
     @RequestingUserID = @ProfJonesID, @RequestingUserClearance = 3;
EXEC sp_EnterGrade @StudentID = 5, @CourseID = 3, @GradeValue = 76.5, 
     @RequestingUserID = @ProfJonesID, @RequestingUserClearance = 3;
EXEC sp_EnterGrade @StudentID = 8, @CourseID = 3, @GradeValue = 93.0, 
     @RequestingUserID = @ProfJonesID, @RequestingUserClearance = 3;
EXEC sp_EnterGrade @StudentID = 1, @CourseID = 3, @GradeValue = 84.5, 
     @RequestingUserID = @ProfJonesID, @RequestingUserClearance = 3;

PRINT 'Grades entered successfully.';
GO

-- ============================================
-- INSERT ATTENDANCE RECORDS
-- ============================================

DECLARE @ProfSmithID INT, @TAAliceID INT, @TABobID INT;
SELECT @ProfSmithID = UserID FROM Users WHERE Username = 'prof.smith';
SELECT @TAAliceID = UserID FROM Users WHERE Username = 'ta.alice';
SELECT @TABobID = UserID FROM Users WHERE Username = 'ta.bob';

-- Database Systems attendance (Course 1)
EXEC sp_RecordAttendance @StudentID = 1, @CourseID = 1, @Status = 1, 
     @RequestingUserID = @TAAliceID, @RequestingUserClearance = 3;
EXEC sp_RecordAttendance @StudentID = 2, @CourseID = 1, @Status = 1, 
     @RequestingUserID = @TAAliceID, @RequestingUserClearance = 3;
EXEC sp_RecordAttendance @StudentID = 3, @CourseID = 1, @Status = 0, 
     @RequestingUserID = @TAAliceID, @RequestingUserClearance = 3;
EXEC sp_RecordAttendance @StudentID = 6, @CourseID = 1, @Status = 1, 
     @RequestingUserID = @TAAliceID, @RequestingUserClearance = 3;
EXEC sp_RecordAttendance @StudentID = 7, @CourseID = 1, @Status = 1, 
     @RequestingUserID = @TAAliceID, @RequestingUserClearance = 3;

-- Data Structures attendance (Course 2)
EXEC sp_RecordAttendance @StudentID = 1, @CourseID = 2, @Status = 1, 
     @RequestingUserID = @TABobID, @RequestingUserClearance = 3;
EXEC sp_RecordAttendance @StudentID = 2, @CourseID = 2, @Status = 1, 
     @RequestingUserID = @TABobID, @RequestingUserClearance = 3;
EXEC sp_RecordAttendance @StudentID = 3, @CourseID = 2, @Status = 1, 
     @RequestingUserID = @TABobID, @RequestingUserClearance = 3;
EXEC sp_RecordAttendance @StudentID = 6, @CourseID = 2, @Status = 0, 
     @RequestingUserID = @TABobID, @RequestingUserClearance = 3;

PRINT 'Attendance records created successfully.';
GO

-- ============================================
-- INSERT SAMPLE ROLE REQUESTS (Part B)
-- ============================================

DECLARE @StudentJohnID INT;
DECLARE @StudentMaryID INT;
DECLARE @TAAliceID INT;

SELECT @StudentJohnID = UserID FROM Users WHERE Username = 'student.john';
SELECT @StudentMaryID = UserID FROM Users WHERE Username = 'student.mary';
SELECT @TAAliceID = UserID FROM Users WHERE Username = 'ta.alice';

-- Student requesting TA role
EXEC sp_SubmitRoleRequest
    @RequestingUserID = @StudentJohnID,
    @RequestedRole = 'TA',
    @Reason = 'I have completed Database Systems with an A grade and want to help other students',
    @Comments = 'I am available 10 hours per week';

-- Student requesting Instructor role (will be denied - invalid path)
EXEC sp_SubmitRoleRequest
    @RequestingUserID = @StudentMaryID,
    @RequestedRole = 'TA',
    @Reason = 'Strong academic performance and teaching experience',
    @Comments = 'Tutored students for 2 years';

-- TA requesting Instructor role
EXEC sp_SubmitRoleRequest
    @RequestingUserID = @TAAliceID,
    @RequestedRole = 'Instructor',
    @Reason = 'Completed PhD in Computer Science and have 3 years of TA experience',
    @Comments = 'Specialization in database systems';

PRINT 'Sample role requests created successfully.';
GO

PRINT '';
PRINT '==============================================';
PRINT 'Sample data insertion completed successfully!';
PRINT '==============================================';
PRINT '';
PRINT 'Login Credentials:';
PRINT '  Admin: admin1 / Admin@123';
PRINT '  Instructor: prof.smith / Prof@123';
PRINT '  TA: ta.alice / TA@123';
PRINT '  Student: student.john / Student@123';
PRINT '  Guest: guest1 / Guest@123';
PRINT '';
GO

