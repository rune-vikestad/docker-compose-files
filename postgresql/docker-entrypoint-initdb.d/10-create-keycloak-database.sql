-- 
-- This will create a keycloak role and login with ownership to the keycloak
-- schema and database, to ensure it's isolated enough to avoid screwing up 
-- anything during development.
--
-- Access to the public schema has been revoked.
--
CREATE ROLE keycloak WITH PASSWORD 'oMp63L95VtUFkffC';

ALTER ROLE keycloak WITH LOGIN;

CREATE DATABASE keycloak OWNER keycloak;

GRANT CONNECT ON DATABASE keycloak TO keycloak;

REVOKE ALL ON schema public FROM keycloak;
