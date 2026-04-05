-- =============================================================
-- ITD 132 Semester Project: Integrated IT Infrastructure Database
-- Student: John David Kelly
-- File: 01_create_tables.sql
-- Description: Creates all tables in dependency order with
--              constraints, primary keys, and foreign keys.
-- =============================================================

CREATE DATABASE IF NOT EXISTS it_infrastructure;
USE it_infrastructure;

-- -------------------------------------------------------------
-- 1. DEPARTMENTS
--    Lookup table for organizational groups (IT, HR, Sales...)
-- -------------------------------------------------------------
CREATE TABLE DEPARTMENTS (
    department_id   INT             NOT NULL AUTO_INCREMENT,
    department_name VARCHAR(100)    NOT NULL,
    location        VARCHAR(100),
    PRIMARY KEY (department_id),
    CONSTRAINT uq_dept_name UNIQUE (department_name)
);

-- -------------------------------------------------------------
-- 2. OPERATING_SYSTEMS
--    Lookup/reference table - one OS type installs on many hosts/VMs
-- -------------------------------------------------------------
CREATE TABLE OPERATING_SYSTEMS (
    os_id           INT             NOT NULL AUTO_INCREMENT,
    os_name         VARCHAR(100)    NOT NULL,
    os_version      VARCHAR(50)     NOT NULL,
    os_type         ENUM('Windows', 'Linux', 'macOS', 'Other') NOT NULL,
    support_end_date DATE,                       -- useful for patch-status queries
    PRIMARY KEY (os_id),
    CONSTRAINT uq_os UNIQUE (os_name, os_version)
);

-- -------------------------------------------------------------
-- 3. NETWORK_SEGMENTS
--    VLAN IDs and subnet info (from ITN 155 Cisco labs)
-- -------------------------------------------------------------
CREATE TABLE NETWORK_SEGMENTS (
    segment_id      INT             NOT NULL AUTO_INCREMENT,
    vlan_id         SMALLINT        NOT NULL,
    subnet_address  VARCHAR(18)     NOT NULL,    -- e.g. 192.168.10.0/24
    subnet_mask     VARCHAR(15)     NOT NULL,
    gateway         VARCHAR(15),
    description     VARCHAR(200),
    PRIMARY KEY (segment_id),
    CONSTRAINT uq_vlan UNIQUE (vlan_id),
    CONSTRAINT uq_subnet UNIQUE (subnet_address)
);

-- -------------------------------------------------------------
-- 4. IP_ALLOCATIONS
--    Individual IP addresses within a segment (1:1 with a host)
-- -------------------------------------------------------------
CREATE TABLE IP_ALLOCATIONS (
    ip_id           INT             NOT NULL AUTO_INCREMENT,
    segment_id      INT             NOT NULL,
    ip_address      VARCHAR(15)     NOT NULL,
    is_reserved     TINYINT(1)      NOT NULL DEFAULT 0,
    PRIMARY KEY (ip_id),
    CONSTRAINT uq_ip UNIQUE (ip_address),
    CONSTRAINT fk_ipalloc_segment
        FOREIGN KEY (segment_id) REFERENCES NETWORK_SEGMENTS(segment_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- -------------------------------------------------------------
-- 5. USERS
--    Employee accounts, imported from Active Directory / ITN 113 labs
-- -------------------------------------------------------------
CREATE TABLE USERS (
    user_id         INT             NOT NULL AUTO_INCREMENT,
    department_id   INT             NOT NULL,
    username        VARCHAR(50)     NOT NULL,
    first_name      VARCHAR(50)     NOT NULL,
    last_name       VARCHAR(50)     NOT NULL,
    email           VARCHAR(100)    NOT NULL,
    role            ENUM('Admin', 'User', 'Auditor') NOT NULL DEFAULT 'User',
    account_enabled TINYINT(1)      NOT NULL DEFAULT 1,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    CONSTRAINT uq_username UNIQUE (username),
    CONSTRAINT uq_email    UNIQUE (email),
    CONSTRAINT fk_user_dept
        FOREIGN KEY (department_id) REFERENCES DEPARTMENTS(department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- -------------------------------------------------------------
-- 6. HOSTS
--    Physical hardware: servers and workstations
-- -------------------------------------------------------------
CREATE TABLE HOSTS (
    host_id         INT             NOT NULL AUTO_INCREMENT,
    os_id           INT             NOT NULL,
    ip_id           INT,                         -- 1:1 primary mgmt IP (nullable until assigned)
    hostname        VARCHAR(100)    NOT NULL,
    host_type       ENUM('Server', 'Workstation', 'Network Device') NOT NULL,
    cpu_cores       TINYINT         UNSIGNED,
    ram_gb          SMALLINT        UNSIGNED,
    disk_gb         INT             UNSIGNED,
    location        VARCHAR(100),                -- rack/room/building
    status          ENUM('Online', 'Offline', 'Maintenance') NOT NULL DEFAULT 'Online',
    PRIMARY KEY (host_id),
    CONSTRAINT uq_hostname UNIQUE (hostname),
    CONSTRAINT uq_host_ip  UNIQUE (ip_id),       -- enforces 1:1
    CONSTRAINT fk_host_os
        FOREIGN KEY (os_id)  REFERENCES OPERATING_SYSTEMS(os_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_host_ip
        FOREIGN KEY (ip_id)  REFERENCES IP_ALLOCATIONS(ip_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- -------------------------------------------------------------
-- 7. VIRTUAL_MACHINES
--    Guest VMs running on a physical host, owned by a user
-- -------------------------------------------------------------
CREATE TABLE VIRTUAL_MACHINES (
    vm_id           INT             NOT NULL AUTO_INCREMENT,
    host_id         INT             NOT NULL,
    os_id           INT             NOT NULL,
    owner_user_id   INT             NOT NULL,
    vm_name         VARCHAR(100)    NOT NULL,
    cpu_cores       TINYINT         UNSIGNED,
    ram_gb          SMALLINT        UNSIGNED,
    disk_gb         INT             UNSIGNED,
    purpose         VARCHAR(200),
    status          ENUM('Running', 'Stopped', 'Suspended', 'Deleted') NOT NULL DEFAULT 'Running',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (vm_id),
    CONSTRAINT uq_vm_name UNIQUE (vm_name),
    CONSTRAINT fk_vm_host
        FOREIGN KEY (host_id)       REFERENCES HOSTS(host_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_vm_os
        FOREIGN KEY (os_id)         REFERENCES OPERATING_SYSTEMS(os_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_vm_owner
        FOREIGN KEY (owner_user_id) REFERENCES USERS(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- -------------------------------------------------------------
-- 8. VULNERABILITIES
--    CVE catalog (from ITN 261 Ethical Hacking labs)
-- -------------------------------------------------------------
CREATE TABLE VULNERABILITIES (
    vuln_id         INT             NOT NULL AUTO_INCREMENT,
    cve_id          VARCHAR(20)     NOT NULL,    -- e.g. CVE-2021-44228
    vuln_name       VARCHAR(200)    NOT NULL,
    severity        ENUM('Critical', 'High', 'Medium', 'Low', 'Informational') NOT NULL,
    cvss_score      DECIMAL(3,1)    CHECK (cvss_score BETWEEN 0.0 AND 10.0),
    description     TEXT,
    published_date  DATE,
    PRIMARY KEY (vuln_id),
    CONSTRAINT uq_cve UNIQUE (cve_id)
);

-- -------------------------------------------------------------
-- 9. SCAN_RESULTS
--    Junction table: records when a specific vuln is found on a host or VM.
--    Exactly one of (host_id, vm_id) must be set (enforced via CHECK).
-- -------------------------------------------------------------
CREATE TABLE SCAN_RESULTS (
    scan_id         INT             NOT NULL AUTO_INCREMENT,
    vuln_id         INT             NOT NULL,
    host_id         INT,
    vm_id           INT,
    scan_date       DATE            NOT NULL,
    remediated      TINYINT(1)      NOT NULL DEFAULT 0,
    remediation_date DATE,
    notes           TEXT,
    PRIMARY KEY (scan_id),
    CONSTRAINT fk_scan_vuln
        FOREIGN KEY (vuln_id)  REFERENCES VULNERABILITIES(vuln_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_scan_host
        FOREIGN KEY (host_id)  REFERENCES HOSTS(host_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_scan_vm
        FOREIGN KEY (vm_id)    REFERENCES VIRTUAL_MACHINES(vm_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- Ensure scan targets exactly one asset
    CONSTRAINT chk_scan_target
        CHECK (
            (host_id IS NOT NULL AND vm_id IS NULL) OR
            (host_id IS NULL AND vm_id IS NOT NULL)
        )
);

-- -------------------------------------------------------------
-- 10. SOFTWARE_LICENSES
--     Tracks installed software and license expiration per VM
-- -------------------------------------------------------------
CREATE TABLE SOFTWARE_LICENSES (
    license_id      INT             NOT NULL AUTO_INCREMENT,
    vm_id           INT             NOT NULL,
    software_name   VARCHAR(150)    NOT NULL,
    license_key     VARCHAR(100),
    license_type    ENUM('Perpetual', 'Subscription', 'OEM', 'Open Source') NOT NULL,
    purchase_date   DATE,
    expiry_date     DATE,
    PRIMARY KEY (license_id),
    CONSTRAINT fk_license_vm
        FOREIGN KEY (vm_id) REFERENCES VIRTUAL_MACHINES(vm_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- -------------------------------------------------------------
-- INDEXES for performance (required by rubric)
-- -------------------------------------------------------------
CREATE INDEX idx_users_dept       ON USERS(department_id);
CREATE INDEX idx_vms_host         ON VIRTUAL_MACHINES(host_id);
CREATE INDEX idx_vms_owner        ON VIRTUAL_MACHINES(owner_user_id);
CREATE INDEX idx_scan_vuln        ON SCAN_RESULTS(vuln_id);
CREATE INDEX idx_scan_date        ON SCAN_RESULTS(scan_date);
CREATE INDEX idx_scan_remediated  ON SCAN_RESULTS(remediated);
CREATE INDEX idx_ipalloc_segment  ON IP_ALLOCATIONS(segment_id);
CREATE INDEX idx_license_expiry   ON SOFTWARE_LICENSES(expiry_date);
