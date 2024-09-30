-- 
-- This will create a apicurio role and login with ownership to the apicurio
-- schema and database, to ensure it's isolated enough to avoid screwing up 
-- anything during development.
--
-- Access to the public schema has been revoked.
--
CREATE ROLE apicurio WITH PASSWORD 'sKWCsUmPoA5EzXhQ';

ALTER ROLE apicurio WITH LOGIN;

CREATE DATABASE apicurio OWNER apicurio;

GRANT CONNECT ON DATABASE apicurio TO apicurio;

REVOKE ALL ON schema public FROM apicurio;
