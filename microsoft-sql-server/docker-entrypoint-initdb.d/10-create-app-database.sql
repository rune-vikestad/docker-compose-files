
/*
 * Database: app
 *
 * Naming conventions:
 *
 *   Roles:   <database>_<permission>
 *   Logins:  svc_<database>_<workload>
 *
 * Roles define what a principal is allowed to do.
 * Logins identify the application or service connecting to the database.
 *
 * Examples:
 *   app_owner           - Database administration
 *   app_migrator        - Schema and data migrations
 *   app_rw              - Read/write access to application data
 *   app_ro              - Read-only access to application data
 *
 *   svc_app_api         - API service
 *   svc_app_worker      - Background worker
 *   svc_app_migrator    - Database migration CLI
 *
 * The naming convention is shared across SQL Server and PostgreSQL,
 * although the underlying permission models differ.
 *
 * Execute as a sufficiently privileged SQL Server administrator.
 * Supply service login passwords securely during provisioning.
 */

-- ============================================================
-- Roles
-- ============================================================

-- Database roles are created after the database exists.

-- ============================================================
-- Logins
-- ============================================================

USE [master];
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.server_principals WHERE name = 'svc_app_api'
)
BEGIN
    CREATE LOGIN [svc_app_api]
        WITH PASSWORD = '1LBzwVnmui6rMY84FxRLDyXT8XPsqz3M',
        CHECK_POLICY = ON;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.server_principals WHERE name = 'svc_app_worker'
)
BEGIN
    CREATE LOGIN [svc_app_worker]
        WITH PASSWORD = 'fT2sB41xCa8PWWwRT0rxzpsWHXuknU2C',
        CHECK_POLICY = ON;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.server_principals WHERE name = 'svc_app_migrator'
)
BEGIN
    CREATE LOGIN [svc_app_migrator]
        WITH PASSWORD = 'NcH6eAaaguydcLMuUCvqiwvMsNo8MD81',
        CHECK_POLICY = ON;
END;
GO

-- ============================================================
-- Database
-- ============================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.databases WHERE name = 'app'
)
BEGIN
    CREATE DATABASE [app];
END;
GO

ALTER DATABASE [app] SET READ_COMMITTED_SNAPSHOT ON;
ALTER DATABASE [app] SET ALLOW_SNAPSHOT_ISOLATION ON;
GO

USE [app];
GO

-- ============================================================
-- Schema
-- ============================================================

-- SQL Server uses dbo as the application schema.
-- No additional schema is required.

-- Create database roles.
IF DATABASE_PRINCIPAL_ID('app_owner') IS NULL
    CREATE ROLE [app_owner];
GO

IF DATABASE_PRINCIPAL_ID('app_migrator') IS NULL
    CREATE ROLE [app_migrator];
GO

IF DATABASE_PRINCIPAL_ID('app_rw') IS NULL
    CREATE ROLE [app_rw];
GO

IF DATABASE_PRINCIPAL_ID('app_ro') IS NULL
    CREATE ROLE [app_ro];
GO

-- Create database users.
IF DATABASE_PRINCIPAL_ID('svc_app_api') IS NULL
    CREATE USER [svc_app_api] FOR LOGIN [svc_app_api];
GO

IF DATABASE_PRINCIPAL_ID('svc_app_worker') IS NULL
    CREATE USER [svc_app_worker] FOR LOGIN [svc_app_worker];
GO

IF DATABASE_PRINCIPAL_ID('svc_app_migrator') IS NULL
    CREATE USER [svc_app_migrator] FOR LOGIN [svc_app_migrator];
GO

-- ============================================================
-- Permissions
-- ============================================================

-- Owner: full database administration.
-- No login is assigned to this role.
IF ISNULL(IS_ROLEMEMBER('db_owner', 'app_owner'), 0) = 0
    ALTER ROLE [db_owner] ADD MEMBER [app_owner];
GO

-- Migrator: schema and data migrations within dbo.
-- ALTER on dbo permits modifying and dropping schema objects,
-- including TRUNCATE on tables within the schema.
GRANT CREATE TABLE TO [app_migrator];
GRANT CREATE VIEW TO [app_migrator];
GRANT CREATE PROCEDURE TO [app_migrator];
GRANT CREATE FUNCTION TO [app_migrator];

GRANT ALTER ON SCHEMA::[dbo] TO [app_migrator];
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[dbo] TO [app_migrator];
GRANT EXECUTE ON SCHEMA::[dbo] TO [app_migrator];
GO

-- Read/write: application runtime access.
GRANT SELECT, INSERT, UPDATE, DELETE
    ON SCHEMA::[dbo] TO [app_rw];
GO

-- Read-only: reporting and future read-only workloads.
GRANT SELECT ON SCHEMA::[dbo] TO [app_ro];
GO

-- ============================================================
-- Memberships
-- ============================================================

IF ISNULL(IS_ROLEMEMBER('app_rw', 'svc_app_api'), 0) = 0
    ALTER ROLE [app_rw] ADD MEMBER [svc_app_api];
GO

IF ISNULL(IS_ROLEMEMBER('app_rw', 'svc_app_worker'), 0) = 0
    ALTER ROLE [app_rw] ADD MEMBER [svc_app_worker];
GO

IF ISNULL(IS_ROLEMEMBER('app_migrator', 'svc_app_migrator'), 0) = 0
    ALTER ROLE [app_migrator] ADD MEMBER [svc_app_migrator];
GO

-- ============================================================
-- Security
-- ============================================================

-- Runtime users receive DML permissions through app_rw only.
-- They are not granted schema modification permissions.

-- The migrator can modify objects within dbo but is not
-- granted db_owner or server-level administrative privileges.

-- app_owner is a non-login database role.
-- The database itself remains owned by its administrative principal.
