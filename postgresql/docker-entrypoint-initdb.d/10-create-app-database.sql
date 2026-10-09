
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
 * Migration requirements:
 *
 *   The migration CLI must execute the following command before
 *   running any migrations:
 *
 *       SET ROLE app_owner;
 *
 *   This ensures that all database objects created during migrations
 *   are owned by app_owner rather than svc_app_migrator.
 *
 *   PostgreSQL requires object ownership for operations such as
 *   ALTER and DROP, so consistent ownership is essential.
 *
 *   SET ROLE applies only to the current database session and must
 *   be executed again whenever the migration CLI opens a new connection.
 *
 * The naming convention is shared across SQL Server and PostgreSQL,
 * although the underlying permission models differ.
 *
 * Execute using psql as an administrative user, initially connected
 * to the postgres maintenance database.
 */

-- ============================================================
-- Roles
-- ============================================================

SELECT 'CREATE ROLE app_owner NOLOGIN'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'app_owner'
)
\gexec

SELECT 'CREATE ROLE app_migrator NOLOGIN'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'app_migrator'
)
\gexec

SELECT 'CREATE ROLE app_rw NOLOGIN'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'app_rw'
)
\gexec

SELECT 'CREATE ROLE app_ro NOLOGIN'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'app_ro'
)
\gexec

-- ============================================================
-- Logins
-- ============================================================

SELECT 'CREATE ROLE svc_app_api LOGIN'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'svc_app_api'
)
\gexec

SELECT 'CREATE ROLE svc_app_worker LOGIN'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'svc_app_worker'
)
\gexec

SELECT 'CREATE ROLE svc_app_migrator LOGIN NOINHERIT'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'svc_app_migrator'
)
\gexec

-- Passwords are reset on every execution.
-- These are local development credentials only.

ALTER ROLE svc_app_api PASSWORD 'ZKaiVWQgetz4pytTVesDVPtpKbLb0RPw';
ALTER ROLE svc_app_worker PASSWORD 'L5cRrXLqGVswCNikXACa3JNrXkQwn1oH';
ALTER ROLE svc_app_migrator PASSWORD 'qweMWoPYgi97XqTwjLr80he2gpe36i1g';

-- ============================================================
-- Database
-- ============================================================

SELECT 'CREATE DATABASE app OWNER app_owner'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_database WHERE datname = 'app'
)
\gexec

\connect app

-- ============================================================
-- Schema
-- ============================================================

-- Use a dedicated application schema owned by app_owner.
CREATE SCHEMA IF NOT EXISTS app AUTHORIZATION app_owner;

-- Configure the default schema for each workload.
ALTER ROLE svc_app_api IN DATABASE app
    SET search_path = app, public;

ALTER ROLE svc_app_worker IN DATABASE app
    SET search_path = app, public;

ALTER ROLE svc_app_migrator IN DATABASE app
    SET search_path = app, public;

-- ============================================================
-- Permissions
-- ============================================================

-- Database access.
GRANT CONNECT ON DATABASE app TO app_rw;
GRANT CONNECT ON DATABASE app TO app_ro;
GRANT CONNECT ON DATABASE app TO app_migrator;

-- Schema access.
GRANT USAGE ON SCHEMA app TO app_rw;
GRANT USAGE ON SCHEMA app TO app_ro;

-- Read/write access to existing objects.
GRANT SELECT, INSERT, UPDATE, DELETE
    ON ALL TABLES IN SCHEMA app TO app_rw;

GRANT USAGE, SELECT, UPDATE
    ON ALL SEQUENCES IN SCHEMA app TO app_rw;

-- Read-only access to existing objects.
GRANT SELECT
    ON ALL TABLES IN SCHEMA app TO app_ro;

GRANT SELECT
    ON ALL SEQUENCES IN SCHEMA app TO app_ro;

-- Default permissions for future objects created by app_owner.
ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA app
    GRANT SELECT, INSERT, UPDATE, DELETE
    ON TABLES TO app_rw;

ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA app
    GRANT SELECT ON TABLES TO app_ro;

ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA app
    GRANT USAGE, SELECT, UPDATE
    ON SEQUENCES TO app_rw;

ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA app
    GRANT SELECT ON SEQUENCES TO app_ro;

-- ============================================================
-- Memberships
-- ============================================================

GRANT app_rw TO svc_app_api;
GRANT app_rw TO svc_app_worker;

GRANT app_owner TO svc_app_migrator;
GRANT app_migrator TO svc_app_migrator;

-- ============================================================
-- Security
-- ============================================================

-- Restrict access to the public schema.
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Restrict access to the application schema.
REVOKE ALL ON SCHEMA app FROM PUBLIC;

-- Prevent runtime roles from creating database objects.
REVOKE CREATE ON SCHEMA app FROM app_rw;
REVOKE CREATE ON SCHEMA app FROM app_ro;
