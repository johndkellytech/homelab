-- =============================================================
-- ITD 132 Semester Project: Integrated IT Infrastructure Database
-- Student: John David Kelly
-- File: 03_views.sql
-- Description: Views for common reporting operations.
-- =============================================================

USE it_infrastructure;

-- -------------------------------------------------------------
-- VIEW 1: vw_asset_inventory
-- Full joined view of every host with its OS and IP info.
-- Use case: "What do we have and where is it?"
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW vw_asset_inventory AS
SELECT
    h.host_id,
    h.hostname,
    h.host_type,
    h.status,
    os.os_name,
    os.os_version,
    ia.ip_address,
    ns.vlan_id,
    ns.description     AS network_segment,
    h.cpu_cores,
    h.ram_gb,
    h.location
FROM HOSTS h
JOIN OPERATING_SYSTEMS os ON h.os_id       = os.os_id
LEFT JOIN IP_ALLOCATIONS ia ON h.ip_id     = ia.ip_id
LEFT JOIN NETWORK_SEGMENTS ns ON ia.segment_id = ns.segment_id;

-- -------------------------------------------------------------
-- VIEW 2: vw_vm_owner_detail
-- Every VM with its host, owner, and OS info.
-- Use case: "Which user owns which VM, and on what host?"
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW vw_vm_owner_detail AS
SELECT
    vm.vm_id,
    vm.vm_name,
    vm.status,
    vm.purpose,
    h.hostname          AS physical_host,
    os.os_name,
    os.os_version,
    u.username          AS owner,
    u.first_name,
    u.last_name,
    d.department_name
FROM VIRTUAL_MACHINES vm
JOIN HOSTS h            ON vm.host_id       = h.host_id
JOIN OPERATING_SYSTEMS os ON vm.os_id       = os.os_id
JOIN USERS u            ON vm.owner_user_id = u.user_id
JOIN DEPARTMENTS d      ON u.department_id  = d.department_id;

-- -------------------------------------------------------------
-- VIEW 3: vw_open_vulnerabilities
-- All unpatched scan results, showing asset + CVE details.
-- Use case: "What is currently vulnerable?"
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW vw_open_vulnerabilities AS
SELECT
    sr.scan_id,
    sr.scan_date,
    v.cve_id,
    v.vuln_name,
    v.severity,
    v.cvss_score,
    -- Show whether it's a host or VM target
    COALESCE(h.hostname, vm.vm_name)    AS asset_name,
    CASE
        WHEN sr.host_id IS NOT NULL THEN 'Host'
        ELSE 'VM'
    END                                  AS asset_type,
    sr.notes
FROM SCAN_RESULTS sr
JOIN VULNERABILITIES v  ON sr.vuln_id   = v.vuln_id
LEFT JOIN HOSTS h       ON sr.host_id   = h.host_id
LEFT JOIN VIRTUAL_MACHINES vm ON sr.vm_id = vm.vm_id
WHERE sr.remediated = 0;

-- -------------------------------------------------------------
-- VIEW 4: vw_expiring_licenses
-- Software licenses expiring within the next 90 days.
-- Use case: "What licenses need to be renewed soon?"
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW vw_expiring_licenses AS
SELECT
    sl.license_id,
    vm.vm_name,
    sl.software_name,
    sl.license_type,
    sl.expiry_date,
    DATEDIFF(sl.expiry_date, CURDATE()) AS days_remaining
FROM SOFTWARE_LICENSES sl
JOIN VIRTUAL_MACHINES vm ON sl.vm_id = vm.vm_id
WHERE sl.expiry_date IS NOT NULL
  AND sl.expiry_date <= DATE_ADD(CURDATE(), INTERVAL 90 DAY)
ORDER BY sl.expiry_date ASC;

-- -------------------------------------------------------------
-- VIEW 5: vw_risk_summary_by_asset
-- Count of open critical/high vulns per asset.
-- Use case: "Which assets need immediate attention?"
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW vw_risk_summary_by_asset AS
SELECT
    COALESCE(h.hostname, vm.vm_name)    AS asset_name,
    CASE
        WHEN sr.host_id IS NOT NULL THEN 'Host'
        ELSE 'VM'
    END                                  AS asset_type,
    COUNT(sr.scan_id)                   AS total_open_vulns,
    SUM(v.severity = 'Critical')        AS critical_count,
    SUM(v.severity = 'High')            AS high_count,
    MAX(v.cvss_score)                   AS max_cvss
FROM SCAN_RESULTS sr
JOIN VULNERABILITIES v  ON sr.vuln_id   = v.vuln_id
LEFT JOIN HOSTS h       ON sr.host_id   = h.host_id
LEFT JOIN VIRTUAL_MACHINES vm ON sr.vm_id = vm.vm_id
WHERE sr.remediated = 0
GROUP BY asset_name, asset_type
ORDER BY critical_count DESC, max_cvss DESC;
