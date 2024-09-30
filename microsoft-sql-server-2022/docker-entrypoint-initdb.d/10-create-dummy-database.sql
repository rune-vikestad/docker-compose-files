-- Creates the `Contoso` login and user
CREATE LOGIN Contoso
    WITH PASSWORD = 'dcVcScuxbyePy9Ug';  
GO  

CREATE USER Contoso FOR LOGIN Contoso;  
GO  

-- Create [Contoso].[App] database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'App')
BEGIN
   CREATE DATABASE [Contoso]
   ALTER DATABASE App SET READ_COMMITTED_SNAPSHOT ON;
   ALTER DATABASE App SET ALLOW_SNAPSHOT_ISOLATION ON;
END;
GO 

USE [App]
GO

-- Create [App].[dbo].[Products] table
CREATE TABLE [App].[dbo].[Products] (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID()
);
GO