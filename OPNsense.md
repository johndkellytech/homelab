# OPNsense (Firewall/Router)

## What It Is
OPNsense 26.1 — FreeBSD 14-based open-source firewall and router. Acts as the **gateway** between the isolated lab network and the internet. Replaces what a physical firewall/router would do in a real enterprise — routing, NAT, DHCP, DNS forwarding, and firewall rules in one box (UTM — Unified Threat Management).

## How It's Built

| Setting | Value |
|---|---|
| **Install Media** | DVD ISO (not VGA or nano — see [[Build-Log]]) |
| **OS Type** | FreeBSD 14.3 (OPNsense is FreeBSD-based) |
| **Filesystem** | ZFS (stripe — single disk, no RAID) |
| **RAM** | 2 GB |
| **CPUs** | 2 |
| **Disk** | 20 GB qcow2 (thin-provisioned) |
| **NIC 1 (WAN)** | vtnet0 → `default` NAT network (192.168.122.0/24, DHCP from libvirt) |
| **NIC 2 (LAN)** | vtnet1 → `lab-lan` isolated network (192.168.100.1/24, static) |

## What It Does
- **Routes** traffic between the lab LAN (192.168.100.0/24) and the internet via NAT
- **Firewalls** traffic between zones (WAN ↔ LAN)
- Will provide **DHCP** for lab VMs (configured via web GUI, not yet enabled)
- Web GUI accessible at `https://192.168.100.1` from any VM on lab-lan
- Default creds: `root` / `opnsense`

## Relationships
- Upstream: WAN side gets IP via DHCP from libvirt's default NAT network
- Downstream: LAN side serves as default gateway for [[DC01]] and all future lab VMs
- See [[Network]] for full topology
