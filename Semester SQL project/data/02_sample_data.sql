-- =============================================================
-- ITD 132 Semester Project: Integrated IT Infrastructure Database
-- Student: John David Kelly
-- File: 02_sample_data.sql
-- Description: Sample data (min 10 rows per table).
--              Replace with real lab data as available.
-- =============================================================

USE it_infrastructure;

-- -------------------------------------------------------------
-- DEPARTMENTS (10 rows)
-- -------------------------------------------------------------
INSERT INTO DEPARTMENTS (department_name, location) VALUES
    ('IT',              'Building A, Room 101'),
    ('HR',              'Building B, Room 202'),
    ('Sales',           'Building C, Room 305'),
    ('Finance',         'Building B, Room 210'),
    ('Security',        'Building A, Room 110'),
    ('Engineering',     'Building D, Room 401'),
    ('Marketing',       'Building C, Room 310'),
    ('Operations',      'Building A, Room 115'),
    ('Legal',           'Building B, Room 220'),
    ('Executive',       'Building E, Room 500');

-- -------------------------------------------------------------
-- OPERATING_SYSTEMS (10 rows)
-- -------------------------------------------------------------
INSERT INTO OPERATING_SYSTEMS (os_name, os_version, os_type, support_end_date) VALUES
    ('Windows Server',  '2022',         'Windows',  '2031-10-14'),
    ('Windows Server',  '2019',         'Windows',  '2029-01-09'),
    ('Windows',         '11 Pro',       'Windows',  '2031-10-14'),
    ('Windows',         '10 Pro',       'Windows',  '2025-10-14'),
    ('Ubuntu Server',   '22.04 LTS',    'Linux',    '2027-04-01'),
    ('Ubuntu',          '24.04 LTS',    'Linux',    '2029-04-01'),
    ('Kali Linux',      '2024.1',       'Linux',    NULL),
    ('CentOS Stream',   '9',            'Linux',    '2027-05-31'),
    ('Debian',          '12',           'Linux',    '2028-06-01'),
    ('pfSense',         '2.7',          'Other',    NULL);

-- -------------------------------------------------------------
-- NETWORK_SEGMENTS (10 rows) — matches ITN 155 lab topology
-- -------------------------------------------------------------
INSERT INTO NETWORK_SEGMENTS (vlan_id, subnet_address, subnet_mask, gateway, description) VALUES
    (10,  '192.168.10.0/24',  '255.255.255.0',   '192.168.10.1',  'Management VLAN'),
    (20,  '192.168.20.0/24',  '255.255.255.0',   '192.168.20.1',  'Server VLAN'),
    (30,  '192.168.30.0/24',  '255.255.255.0',   '192.168.30.1',  'User Workstations VLAN'),
    (40,  '192.168.40.0/24',  '255.255.255.0',   '192.168.40.1',  'Security Lab VLAN'),
    (50,  '10.0.50.0/24',     '255.255.255.0',   '10.0.50.1',     'DMZ'),
    (60,  '10.0.60.0/24',     '255.255.255.0',   '10.0.60.1',     'Voice VLAN'),
    (70,  '172.16.70.0/24',   '255.255.255.0',   '172.16.70.1',   'Backup Network'),
    (80,  '172.16.80.0/24',   '255.255.255.0',   '172.16.80.1',   'IoT Devices'),
    (90,  '192.168.90.0/24',  '255.255.255.0',   '192.168.90.1',  'Guest WiFi'),
    (100, '10.10.100.0/24',   '255.255.255.0',   '10.10.100.1',   'Monitoring VLAN');

-- -------------------------------------------------------------
-- IP_ALLOCATIONS (12 rows)
-- -------------------------------------------------------------
INSERT INTO IP_ALLOCATIONS (segment_id, ip_address, is_reserved) VALUES
    (1,  '192.168.10.10',  0),
    (1,  '192.168.10.11',  0),
    (2,  '192.168.20.10',  0),
    (2,  '192.168.20.11',  0),
    (2,  '192.168.20.12',  0),
    (3,  '192.168.30.10',  0),
    (3,  '192.168.30.11',  0),
    (3,  '192.168.30.12',  0),
    (4,  '192.168.40.10',  0),
    (4,  '192.168.40.11',  0),
    (5,  '10.0.50.10',     0),
    (7,  '172.16.70.10',   1);

-- -------------------------------------------------------------
-- USERS (12 rows) — imported from AD / ITN 113 lab
-- -------------------------------------------------------------
INSERT INTO USERS (department_id, username, first_name, last_name, email, role) VALUES
    (1,  'jkelly',     'John',     'Kelly',     'jkelly@corp.local',     'Admin'),
    (1,  'bsmith',     'Bob',      'Smith',     'bsmith@corp.local',     'Admin'),
    (5,  'tnguyen',    'Tina',     'Nguyen',    'tnguyen@corp.local',    'Auditor'),
    (2,  'mwilson',    'Mike',     'Wilson',    'mwilson@corp.local',    'User'),
    (3,  'ljohnson',   'Lisa',     'Johnson',   'ljohnson@corp.local',   'User'),
    (4,  'cpark',      'Chris',    'Park',      'cpark@corp.local',      'User'),
    (6,  'alopez',     'Ana',      'Lopez',     'alopez@corp.local',     'User'),
    (1,  'dchen',      'David',    'Chen',      'dchen@corp.local',      'Admin'),
    (5,  'rmorris',    'Rachel',   'Morris',    'rmorris@corp.local',    'Auditor'),
    (7,  'twhite',     'Tom',      'White',     'twhite@corp.local',     'User'),
    (8,  'sbrown',     'Sarah',    'Brown',     'sbrown@corp.local',     'User'),
    (2,  'hlee',       'Henry',    'Lee',       'hlee@corp.local',       'User');

-- -------------------------------------------------------------
-- HOSTS (10 rows)
-- -------------------------------------------------------------
INSERT INTO HOSTS (os_id, ip_id, hostname, host_type, cpu_cores, ram_gb, disk_gb, location, status) VALUES
    (1, 3,  'WIN-SVR-01',   'Server',       8,  32,  500,  'Rack A, U1',  'Online'),
    (1, 4,  'WIN-SVR-02',   'Server',       8,  32,  500,  'Rack A, U2',  'Online'),
    (5, 5,  'LNX-SVR-01',   'Server',       4,  16,  250,  'Rack A, U3',  'Online'),
    (5, 11, 'LNX-DMZ-01',   'Server',       4,  8,   100,  'Rack B, U1',  'Online'),
    (3, 6,  'WS-IT-01',     'Workstation',  4,  16,  256,  'IT Office',   'Online'),
    (3, 7,  'WS-IT-02',     'Workstation',  4,  16,  256,  'IT Office',   'Online'),
    (3, 8,  'WS-HR-01',     'Workstation',  2,  8,   128,  'HR Office',   'Online'),
    (4, 9,  'WS-SEC-01',    'Workstation',  4,  16,  256,  'Sec Lab',     'Online'),
    (10,1,  'FW-CORE-01',   'Network Device',2, 4,   32,   'Rack A, U10', 'Online'),
    (5, 12, 'BACKUP-SRV-01','Server',       4,  32,  2000, 'Backup Room', 'Online');

-- -------------------------------------------------------------
-- VIRTUAL_MACHINES (12 rows)
-- -------------------------------------------------------------
INSERT INTO VIRTUAL_MACHINES (host_id, os_id, owner_user_id, vm_name, cpu_cores, ram_gb, disk_gb, purpose, status) VALUES
    (1, 2,  1,  'VM-AD-01',         2,  8,   80,  'Active Directory Domain Controller',   'Running'),
    (1, 5,  1,  'VM-WEB-01',        2,  4,   50,  'Apache web server',                    'Running'),
    (2, 1,  2,  'VM-SQL-01',        4,  16,  200, 'SQL Server database',                  'Running'),
    (2, 5,  8,  'VM-ANSIBLE-01',    2,  4,   50,  'Ansible automation controller',        'Running'),
    (3, 6,  1,  'VM-UBUNTU-01',     2,  4,   50,  'Ubuntu general purpose',               'Running'),
    (3, 7,  3,  'VM-KALI-01',       4,  8,   100, 'Kali Linux pentesting VM',             'Running'),
    (3, 7,  9,  'VM-KALI-02',       4,  8,   100, 'Kali Linux pentesting VM (auditor)',   'Stopped'),
    (4, 5,  1,  'VM-DMZ-WEB-01',    2,  4,   50,  'DMZ-facing web server',                'Running'),
    (1, 8,  8,  'VM-CENTOS-01',     2,  4,   80,  'CentOS test environment',              'Stopped'),
    (2, 9,  2,  'VM-DEBIAN-01',     2,  4,   50,  'Debian build server',                  'Running'),
    (3, 6,  7,  'VM-UBUNTU-DEV-01', 2,  4,   100, 'Developer sandbox',                   'Running'),
    (4, 7,  3,  'VM-VULN-LAB-01',   2,  4,   50,  'Vulnerable target for ITN 261 labs',  'Running');

-- -------------------------------------------------------------
-- VULNERABILITIES (10 rows) — real CVEs from ITN 261
-- -------------------------------------------------------------
INSERT INTO VULNERABILITIES (cve_id, vuln_name, severity, cvss_score, description, published_date) VALUES
    ('CVE-2021-44228', 'Log4Shell',                          'Critical', 10.0, 'Remote code execution via JNDI injection in Log4j 2.',                     '2021-12-10'),
    ('CVE-2017-0144',  'EternalBlue (MS17-010)',             'Critical',  9.8, 'SMBv1 buffer overflow used by WannaCry ransomware.',                        '2017-03-14'),
    ('CVE-2021-34527', 'PrintNightmare',                     'Critical',  8.8, 'Windows Print Spooler RCE / LPE vulnerability.',                            '2021-07-01'),
    ('CVE-2023-23397', 'Outlook NTLM Hash Leak',             'Critical',  9.8, 'Zero-click NTLM credential theft via crafted Outlook reminder.',            '2023-03-14'),
    ('CVE-2022-26134', 'Confluence OGNL Injection',          'Critical', 10.0, 'Unauthenticated RCE via OGNL injection in Confluence Server.',              '2022-06-02'),
    ('CVE-2019-19781', 'Citrix ADC Path Traversal',         'Critical',  9.8, 'Arbitrary code execution in Citrix Application Delivery Controller.',       '2019-12-17'),
    ('CVE-2023-44487', 'HTTP/2 Rapid Reset Attack',          'High',      7.5, 'DDoS amplification via HTTP/2 stream cancellation.',                        '2023-10-10'),
    ('CVE-2022-30190', 'Follina (MSDT RCE)',                 'High',      7.8, 'MSDT remote code execution via malicious Office documents.',                '2022-05-30'),
    ('CVE-2021-26855', 'ProxyLogon (Exchange)',              'Critical',  9.8, 'SSRF in Exchange Server leads to authentication bypass.',                   '2021-03-02'),
    ('CVE-2020-1472',  'ZeroLogon',                         'Critical', 10.0, 'Netlogon privilege escalation allowing domain compromise.',                  '2020-08-11');

-- -------------------------------------------------------------
-- SCAN_RESULTS (12 rows)
-- -------------------------------------------------------------
INSERT INTO SCAN_RESULTS (vuln_id, host_id, vm_id, scan_date, remediated, remediation_date, notes) VALUES
    (2, 1,    NULL, '2026-01-15', 1, '2026-01-20', 'SMBv1 disabled after patch applied.'),
    (2, 2,    NULL, '2026-01-15', 0, NULL,         'Pending patch window.'),
    (1, NULL, 3,    '2026-01-20', 1, '2026-01-25', 'Log4j updated to 2.17.1.'),
    (1, NULL, 8,    '2026-01-20', 0, NULL,         'DMZ server — critical, escalated to IT.'),
    (3, 1,    NULL, '2026-02-01', 1, '2026-02-05', 'Print Spooler service disabled.'),
    (3, NULL, 1,    '2026-02-01', 0, NULL,         'DC VM — PrintNightmare unpatched, scheduled.'),
    (10,1,    NULL, '2026-02-10', 1, '2026-02-12', 'ZeroLogon — applied MS20-1472 patch.'),
    (9, NULL, 3,    '2026-02-10', 0, NULL,         'ProxyLogon on SQL VM — investigate further.'),
    (4, NULL, 1,    '2026-03-01', 0, NULL,         'Outlook NTLM hash leak on DC VM.'),
    (7, 4,    NULL, '2026-03-05', 0, NULL,         'HTTP/2 rapid reset on DMZ server.'),
    (8, NULL, 11,   '2026-03-10', 0, NULL,         'Follina found on dev sandbox VM.'),
    (5, NULL, 8,    '2026-03-15', 0, NULL,         'Confluence injection on DMZ web server.');

-- -------------------------------------------------------------
-- SOFTWARE_LICENSES (10 rows)
-- -------------------------------------------------------------
INSERT INTO SOFTWARE_LICENSES (vm_id, software_name, license_key, license_type, purchase_date, expiry_date) VALUES
    (1,  'Windows Server 2019',         'XXXXX-XXXXX-XXXXX-00001', 'OEM',          '2024-01-01', NULL),
    (3,  'Microsoft SQL Server 2022',   'XXXXX-XXXXX-XXXXX-00002', 'Subscription', '2025-01-01', '2026-01-01'),
    (3,  'SQL Server Management Studio','',                         'Open Source',  '2025-01-01', NULL),
    (5,  'Ubuntu 24.04 LTS',            '',                         'Open Source',  '2025-06-01', NULL),
    (6,  'Kali Linux',                  '',                         'Open Source',  '2025-08-01', NULL),
    (11, 'JetBrains IntelliJ IDEA',     'XXXXX-XXXXX-XXXXX-00003', 'Subscription', '2025-09-01', '2026-09-01'),
    (4,  'Ansible Automation Platform', 'XXXXX-XXXXX-XXXXX-00004', 'Subscription', '2025-01-01', '2026-01-01'),
    (2,  'Apache HTTP Server',          '',                         'Open Source',  '2025-03-01', NULL),
    (9,  'CentOS Stream 9',             '',                         'Open Source',  '2025-05-01', NULL),
    (3,  'Veeam Backup Agent',          'XXXXX-XXXXX-XXXXX-00005', 'Subscription', '2025-01-01', '2025-12-31');
