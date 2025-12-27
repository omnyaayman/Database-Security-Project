-- ============================================
-- Database Security Term Project
-- Part A & B: Database Setup
-- ============================================
-- This script creates the database and sets up encryption infrastructure

USE master;
GO

-- Drop database if exists (for fresh start)
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'SecureStudentRecords')
BEGIN
    ALTER DATABASE SecureStudentRecords SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SecureStudentRecords;
END
GO

-- Create the database
CREATE DATABASE SecureStudentRecords;
GO

USE SecureStudentRecords;
GO

-- Create Master Key for encryption
-- IMPORTANT: Change this password in production
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongMasterKey@2025!';
GO

-- Create Certificate for encryption
CREATE CERTIFICATE StudentRecordsCert
    WITH SUBJECT = 'Certificate for Student Records Encryption';
GO

-- Create Symmetric Key for AES encryption
CREATE SYMMETRIC KEY StudentRecordsKey
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE StudentRecordsCert;
GO

PRINT 'Database and encryption infrastructure created successfully.';
GO

