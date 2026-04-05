-- =============================================================
-- ITD 132 Semester Project: Integrated IT Infrastructure Database
-- Student: John David Kelly
-- File: 04_complex_queries.sql
-- Description: Complex SELECT queries demonstrating joins,
--              aggregations, subqueries, and GROUP BY.
-- =============================================================

USE it_infrastructure;

-- -------------------------------------------------------------
-- QUERY 1: Multi-table JOIN
-- "Show all users in the IT department with their VMs."
-- (matches sample query from proposal)
-- -------------------------------------------------------------
SELECT
    u.username,
    u.first_name,
    u.last_name,
    d.department_name,
    vm.vm_name,
    os.os_name,
    vm.status
FROM USERS u
JOIN DEPARTMENTS d      ON u.department_id  = d.department_id
LEFT JOIN VIRTUAL_MACHINES vm ON vm.owner_user_id = u.user_id
LEFT JOIN OPERATING_SYSTEMS os ON vm.os_id  = os.os_id
WHERE d.department_name = 'IT'
ORDER BY u.last_name, vm.vm_name;

-- -------------------------------------------------------------
-- QUERY 2: Aggregation + GROUP BY
-- "Count how many machines have 'Critical' vulnerabilities per segment."
-- (matches sample query from proposal)
-- -------------------------------------------------------------
SELECT
    ns.description          AS network_segment,
    ns.vlan_id,
    COUNT(DISTINCT sr.scan_id)  AS critical_vuln_count,
    COUNT(DISTINCT h.host_id)   AS affected_hosts
FROM NETWORK_SEGMENTS ns
JOIN IP_ALLOCATIONS ia  ON ns.segment_id    = ia.segment_id
JOIN HOSTS h            ON ia.ip_id         = h.ip_id
JOIN SCAN_RESULTS sr    ON sr.host_id       = h.host_id
JOIN VULNERABILITIES v  ON sr.vuln_id       = v.vuln_id
WHERE v.severity = 'Critical'
  AND sr.remediated = 0
GROUP BY ns.segment_id, ns.description, ns.vlan_id
ORDER BY critical_vuln_count DESC;

-- -------------------------------------------------------------
-- QUERY 3: Subquery
-- "List all VMs running on hosts that have unpatched Critical vulns."
-- -------------------------------------------------------------
SELECT
    vm.vm_name,
    vm.status,
    h.hostname AS physical_host,
    os.os_name
FROM VIRTUAL_MACHINES vm
JOIN HOSTS h ON vm.host_id = h.host_id
JOIN OPERATING_SYSTEMS os ON vm.os_id = os.os_id
WHERE h.host_id IN (
    SELECT DISTINCT sr.host_id
    FROM SCAN_RESULTS sr
    JOIN VULNERABILITIES v ON sr.vuln_id = v.vuln_id
    WHERE v.severity = 'Critical'
      AND sr.remediated = 0
      AND sr.host_id IS NOT NULL
)
ORDER BY h.hostname, vm.vm_name;

-- -------------------------------------------------------------
-- QUERY 4: Aggregation — CVSS risk score per department
-- "Which department's owned VMs have the highest avg CVSS exposure?"
-- -------------------------------------------------------------
SELECT
    d.department_name,
    COUNT(DISTINCT vm.vm_id)        AS vm_count,
    COUNT(sr.scan_id)               AS open_vuln_count,
    ROUND(AVG(v.cvss_score), 2)     AS avg_cvss_score,
    MAX(v.cvss_score)               AS max_cvss_score
FROM DEPARTMENTS d
JOIN USERS u            ON d.department_id  = u.department_id
JOIN VIRTUAL_MACHINES vm ON vm.owner_user_id = u.user_id
JOIN SCAN_RESULTS sr    ON sr.vm_id         = vm.vm_id
JOIN VULNERABILITIES v  ON sr.vuln_id       = v.vuln_id
WHERE sr.remediated = 0
GROUP BY d.department_id, d.department_name
HAVING COUNT(sr.scan_id) > 0
ORDER BY avg_cvss_score DESC;

-- -------------------------------------------------------------
-- QUERY 5: Nested subquery — outdated OS check
-- "List all assets (hosts and VMs) running an OS past end-of-support."
-- -------------------------------------------------------------
SELECT 'Host' AS asset_type, h.hostname AS asset_name, os.os_name, os.os_version, os.support_end_date
FROM HOSTS h
JOIN OPERATING_SYSTEMS os ON h.os_id = os.os_id
WHERE os.support_end_date < CURDATE()
  AND os.support_end_date IS NOT NULL

UNION ALL

SELECT 'VM' AS asset_type, vm.vm_name AS asset_name, os.os_name, os.os_version, os.support_end_date
FROM VIRTUAL_MACHINES vm
JOIN OPERATING_SYSTEMS os ON vm.os_id = os.os_id
WHERE os.support_end_date < CURDATE()
  AND os.support_end_date IS NOT NULL

ORDER BY support_end_date ASC;

-- -------------------------------------------------------------
-- QUERY 6: GROUP BY + HAVING
-- "Show VLANs with more than 2 IP allocations."
-- -------------------------------------------------------------
SELECT
    ns.vlan_id,
    ns.description,
    ns.subnet_address,
    COUNT(ia.ip_id) AS allocated_ips
FROM NETWORK_SEGMENTS ns
JOIN IP_ALLOCATIONS ia ON ns.segment_id = ia.segment_id
GROUP BY ns.segment_id, ns.vlan_id, ns.description, ns.subnet_address
HAVING COUNT(ia.ip_id) > 2
ORDER BY allocated_ips DESC;

-- -------------------------------------------------------------
-- QUERY 7: Correlated subquery
-- "For each host, show whether it has more open vulns than the average."
-- -------------------------------------------------------------
SELECT
    h.hostname,
    h.host_type,
    COUNT(sr.scan_id) AS open_vulns,
    (SELECT ROUND(AVG(sub_count), 1)
     FROM (
         SELECT COUNT(*) AS sub_count
         FROM SCAN_RESULTS
         WHERE remediated = 0 AND host_id IS NOT NULL
         GROUP BY host_id
     ) AS avg_table) AS avg_open_vulns,
    CASE
        WHEN COUNT(sr.scan_id) > (
            SELECT AVG(sub_count) FROM (
                SELECT COUNT(*) AS sub_count
                FROM SCAN_RESULTS
                WHERE remediated = 0 AND host_id IS NOT NULL
                GROUP BY host_id
            ) AS avg_table
        ) THEN 'Above average'
        ELSE 'At or below average'
    END AS risk_relative_to_avg
FROM HOSTS h
LEFT JOIN SCAN_RESULTS sr ON h.host_id = sr.host_id AND sr.remediated = 0
GROUP BY h.host_id, h.hostname, h.host_type;

-- -------------------------------------------------------------
-- QUERY 8: List all VMs on VLAN 10
-- (matches sample query from proposal)
-- -------------------------------------------------------------
SELECT
    vm.vm_name,
    vm.status,
    h.hostname          AS physical_host,
    ia.ip_address       AS host_ip,
    ns.vlan_id,
    ns.description      AS segment
FROM VIRTUAL_MACHINES vm
JOIN HOSTS h            ON vm.host_id   = h.host_id
LEFT JOIN IP_ALLOCATIONS ia ON h.ip_id  = ia.ip_id
LEFT JOIN NETWORK_SEGMENTS ns ON ia.segment_id = ns.segment_id
WHERE ns.vlan_id = 10;
