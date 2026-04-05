# Project Notes: ITD 132 Semester SQL Project

## Overview
**Project Name:** Integrated IT Infrastructure Database (ITD 132)
**Student:** John David Kelly
**Goal:** Design and implement a SQL database tracking IT infrastructure — physical hosts, VMs, network segments, users, and security vulnerabilities.
**Deadline:** Implementation due April 20, 2026 | Presentation due May 4, 2026

## Tech Stack
- **Database:** MySQL / MariaDB (`AUTO_INCREMENT`, `ENUM`, stored procedures, triggers)
- **Tools:** Claude CLI, Gemini CLI

## Current Status
- [x] Project proposal submitted (Feb 16)
- [x] ERD submitted (March 9)
- [x] Git repo initialized — first commit done
- [x] Schema defined (`schema/01_create_tables.sql`) — 10 tables, FKs, indexes
- [x] Sample data (`data/02_sample_data.sql`) — 10+ rows per table, real CVEs
- [x] Views (`queries/03_views.sql`) — 5 views
- [x] Complex queries (`queries/04_complex_queries.sql`) — 8 queries
- [x] Stored procedures + triggers (`queries/05_procedures_triggers.sql`)
- [x] User permissions (`security/06_users_permissions.sql`)
- [ ] Run all SQL files against a live MySQL instance and verify
- [ ] Replace sample data with real lab data from ITN 113 / ITN 155
- [ ] Write implementation documentation PDF (due April 20)
- [ ] Final presentation recording (due May 4)

## Directory Structure
- `schema/01_create_tables.sql` — DDL: all 10 tables, PKs, FKs, constraints, indexes
- `data/02_sample_data.sql` — DML: sample inserts (10+ rows per table)
- `queries/03_views.sql` — 5 views for common reporting
- `queries/04_complex_queries.sql` — 8 complex SELECT queries
- `queries/05_procedures_triggers.sql` — 3 stored procs, 2 triggers, 1 transaction example
- `security/06_users_permissions.sql` — dba_user (full) + security_auditor (read-only)
- `notes.md` — checklist and AI handoff scratchpad

## Tables (run in this order)
1. DEPARTMENTS
2. OPERATING_SYSTEMS
3. NETWORK_SEGMENTS
4. IP_ALLOCATIONS
5. USERS (refs DEPARTMENTS)
6. HOSTS (refs OS, IP_ALLOCATIONS)
7. VIRTUAL_MACHINES (refs HOSTS, OS, USERS)
8. VULNERABILITIES
9. SCAN_RESULTS (bridge: hosts/VMs <-> vulnerabilities)
10. SOFTWARE_LICENSES (refs VMs)

## Notes for Claude & Gemini
- SCAN_RESULTS has a CHECK constraint: exactly one of host_id/vm_id must be set
- HOSTS.ip_id is UNIQUE to enforce 1:1 with IP_ALLOCATIONS
- Run files in order: 01 → 02 → 03 → 04 → 05 → 06
- Use `sp_record_scan_result` procedure to safely log new scan findings
- `security_auditor` user is read-only — can only SELECT and call `sp_get_risk_report`
