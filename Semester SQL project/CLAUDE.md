# Project Notes: ITD 132 Semester SQL Project

## Overview
**Project Name:** Integrated IT Infrastructure Database (ITD 132)
**Goal:** Design and implement a SQL database to track IT infrastructure, including physical hosts, VMs, network segments, users, and security vulnerabilities.

## Tech Stack
- **Database:** MySQL / MariaDB (implied by `AUTO_INCREMENT` and `ENUM` types)
- **Tools:** Gemini CLI, Claude CLI

## Current Status
- [x] Initial Schema Defined (`schema/01_create_tables.sql`)
- [ ] Sample Data Insertion (`data/`)
- [ ] Query Development (`queries/`)
- [ ] Security & User Roles (`security/`)

## Active Task
Setting up shared context for Gemini and Claude CLIs.

## Directory Structure
- `schema/`: DDL scripts for tables, constraints, and indexes.
- `data/`: DML scripts for sample data.
- `queries/`: SQL queries for reports and analysis.
- `security/`: Scripts for users, roles, and permissions.

## Notes for Claude & Gemini
- Use this file to log significant changes or next steps so the other agent can pick up where you left off.
- The schema is designed with foreign key constraints and `CHECK` constraints for data integrity.
- Focus on maintaining the dependency order when inserting data (e.g., Departments before Users).
