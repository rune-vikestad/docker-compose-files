/*
 * Database: apicurio
 *
 * Naming conventions:
 *
 *   Roles:   <database>_<permission>
 *   Logins:  svc_<database>_<workload>
 *
 * Roles define what a principal is allowed to do.
 * Logins identify the application or service connecting to the database.
 *
 * Apicurio Registry manages its own database schema, so its service
 * login is granted ownership privileges.
 *
 * Access to the public schema is restricted.
 */

-- ============================================================
-- Roles
-- ============================================================

CREATE ROLE apicurio_owner NOLOGIN;

-- ============================================================
-- Logins
-- ============================================================

CREATE ROLE svc_apicurio_registry
    WITH LOGIN PASSWORD '1wg45TrZCioqXghDDh3PhdiQe5KU4Yq7';

GRANT apicurio_owner TO svc_apicurio_registry;

-- ============================================================
-- Database
-- ============================================================

CREATE DATABASE apicurio OWNER apicurio_owner;

GRANT CONNECT ON DATABASE apicurio TO svc_apicurio_registry;

-- ============================================================
-- Schema
-- ============================================================

\connect apicurio

CREATE SCHEMA apicurio AUTHORIZATION apicurio_owner;

GRANT USAGE, CREATE ON SCHEMA apicurio TO svc_apicurio_registry;

ALTER ROLE svc_apicurio_registry IN DATABASE apicurio
    SET search_path = apicurio;

REVOKE ALL ON SCHEMA public FROM PUBLIC;