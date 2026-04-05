# IT Infrastructure DB — Shared Scratchpad

Use this file to leave context for yourself (or for Claude/Gemini) between sessions.

## Status
- [x] Proposal submitted (Feb 16)
- [x] ERD submitted (March 9)
- [ ] Database Implementation — **due April 20**
- [ ] Final Presentation — due May 4

## Checklist for Implementation (April 20)

### Schema
- [ ] Run `schema/01_create_tables.sql` — verify no errors
- [ ] Confirm all 10 tables exist with correct FKs
- [ ] Verify indexes were created (`SHOW INDEX FROM tablename`)

### Data
- [ ] Run `data/02_sample_data.sql`
- [ ] Swap in real lab data from ITN 113 / ITN 155 where possible

### Queries
- [ ] Run `queries/03_views.sql` — verify all 5 views exist
- [ ] Run `queries/04_complex_queries.sql` — confirm output looks right
- [ ] Run `queries/05_procedures_triggers.sql` — test each procedure

### Security
- [ ] Run `security/06_users_permissions.sql` as root
- [ ] Test `security_auditor` login — confirm it can SELECT but not INSERT

### Documentation PDF
- [ ] Table descriptions (what each table is for)
- [ ] Relationship explanations
- [ ] Index justifications
- [ ] Query descriptions + sample output

## File Map
```
Semester SQL project/
├── schema/
│   └── 01_create_tables.sql     10 tables, PKs, FKs, indexes
├── data/
│   └── 02_sample_data.sql       10+ rows per table
├── queries/
│   ├── 03_views.sql             5 views (asset inventory, open vulns, risk summary...)
│   ├── 04_complex_queries.sql   8 queries (joins, aggregation, subqueries, UNION)
│   └── 05_procedures_triggers.sql  3 stored procs + 2 triggers + transaction example
├── security/
│   └── 06_users_permissions.sql dba_user (full) + security_auditor (read-only)
└── notes.md                     this file
```

## Tables
1. DEPARTMENTS
2. OPERATING_SYSTEMS
3. NETWORK_SEGMENTS
4. IP_ALLOCATIONS
5. USERS
6. HOSTS
7. VIRTUAL_MACHINES
8. VULNERABILITIES
9. SCAN_RESULTS (bridge: hosts/VMs <-> vulnerabilities)
10. SOFTWARE_LICENSES

## Notes / Decisions
- SCAN_RESULTS uses a CHECK constraint to enforce exactly one of host_id/vm_id is set
- HOSTS.ip_id has a UNIQUE constraint to enforce 1:1 with IP_ALLOCATIONS
- Stored proc `sp_record_scan_result` is the safe way to log new scan findings
- `security_auditor` gets EXECUTE on `sp_get_risk_report` only — no write access
- Real CVEs used in VULNERABILITIES table (Log4Shell, EternalBlue, ZeroLogon, etc.)

## Context for AI sessions
Tell Claude or Gemini: "I'm working on an IT infrastructure database for ITD 132.
The schema is in schema/01_create_tables.sql. Check notes.md for current status."
