-- =============================================================
-- ITD 132 Semester Project: Integrated IT Infrastructure Database
-- Student: John David Kelly
-- File: 06_users_permissions.sql
-- Description: User roles and permissions as defined in project
--              proposal: DBA (full access) and Security Auditor (read-only).
-- NOTE: Run as root/admin MySQL user.
-- =============================================================

USE it_infrastructure;

-- -------------------------------------------------------------
-- ROLE 1: dba_user — System Administrator
-- Full access to create, modify, import data.
-- From proposal: "Full access to create tables, modify schema,
--                and import bulk data from lab exports."
-- -------------------------------------------------------------
CREATE USER IF NOT EXISTS 'dba_user'@'localhost' IDENTIFIED BY 'StrongP@ss1!';

GRANT ALL PRIVILEGES ON it_infrastructure.* TO 'dba_user'@'localhost';

-- -------------------------------------------------------------
-- ROLE 2: security_auditor — Read-Only
-- Can run SELECT queries for risk reports only.
-- From proposal: "Restricted access to execute SELECT queries for
--                generating risk reports, but cannot modify or
--                delete asset records."
-- -------------------------------------------------------------
CREATE USER IF NOT EXISTS 'security_auditor'@'localhost' IDENTIFIED BY 'AuditR3ad0nly!';

-- Grant SELECT on all tables
GRANT SELECT ON it_infrastructure.DEPARTMENTS         TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.OPERATING_SYSTEMS   TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.NETWORK_SEGMENTS    TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.IP_ALLOCATIONS      TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.USERS               TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.HOSTS               TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.VIRTUAL_MACHINES    TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.VULNERABILITIES     TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.SCAN_RESULTS        TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.SOFTWARE_LICENSES   TO 'security_auditor'@'localhost';

-- Grant SELECT on views (read risk reports via views)
GRANT SELECT ON it_infrastructure.vw_open_vulnerabilities TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.vw_risk_summary_by_asset TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.vw_asset_inventory TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.vw_vm_owner_detail TO 'security_auditor'@'localhost';
GRANT SELECT ON it_infrastructure.vw_expiring_licenses TO 'security_auditor'@'localhost';

-- Grant EXECUTE on the risk report procedure only
GRANT EXECUTE ON PROCEDURE it_infrastructure.sp_get_risk_report TO 'security_auditor'@'localhost';

-- Explicitly deny modification (these are NOT granted — principle of least privilege)
-- security_auditor has NO INSERT, UPDATE, DELETE, CREATE, or DROP

-- Apply changes
FLUSH PRIVILEGES;

-- -------------------------------------------------------------
-- Verify: show grants for each user
-- -------------------------------------------------------------
-- SHOW GRANTS FOR 'dba_user'@'localhost';
-- SHOW GRANTS FOR 'security_auditor'@'localhost';
