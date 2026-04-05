# HomeLab

Integrated IT Infrastructure Database — a relational database tracking hosts, VMs, users, network segments, and vulnerabilities for a simulated company environment.

## Purpose

Consolidate data from multiple courses (Active Directory, Networking, Ethical Hacking) into a single MySQL database. Tracks "who has access to what" and "which assets are vulnerable" using real lab configurations instead of fake data.

## Entities

- Hosts, VirtualMachines, OperatingSystems
- NetworkSegments, IPAllocations
- Users, Departments
- Vulnerabilities, ScanResults
- SoftwareLicenses

## Tech Stack

- MySQL (Docker)
- Fedora Linux / KDE Plasma
- QEMU/KVM for Windows Server lab

## Status

- [x] Project proposal approved
- [x] ERD designed
- [ ] Git repo initialized (needs first commit)
- [ ] Database schema (CREATE TABLEs)
- [ ] Data import from AD/Packet Tracer labs
- [ ] Risk reporting queries
