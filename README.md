# Home Lab — Enterprise Network Simulation

A self-built virtual lab simulating a small corporate network on a single Fedora host. Covers VLAN-segmented networking, an Active Directory domain, an attack VLAN with Kali, isolated vulnerability targets, and the workflow for scanning and documenting findings. Built to mirror the topologies and skills tested on CCNA and used in entry-level IT and security roles.

The day-by-day decisions, dead ends, and fixes live in [`Build-Log.md`](./Build-Log.md). This README is the high-level tour.

## Topology

Single Fedora host running KVM/libvirt. One OPNsense VM acts as firewall and router. All internal networks ride a single VLAN-aware Linux bridge as 802.1Q trunks — router-on-a-stick, the same design taught in CCNA inter-VLAN routing.

```
                  [ Internet / WAN ]
                         |
                   [  OPNsense  ]
                         | (single trunk, 802.1Q)
                   [   br-lab   ]
       __________________|__________________
      |          |           |           |
   VLAN 10   VLAN 20    VLAN 30     VLAN 40
    MGMT     ATTACK     VICTIMS      DMZ
   DC01,     Kali     Metasploitable2 (planned)
   Win11
```

| VLAN | Name    | Subnet          | Hosts                                  |
|------|---------|-----------------|----------------------------------------|
| 10   | MGMT    | 10.10.10.0/24   | Windows Server 2022 (DC01), Windows 11 |
| 20   | ATTACK  | 10.10.20.0/24   | Kali Linux                             |
| 30   | VICTIMS | 10.10.30.0/24   | Metasploitable2                        |
| 40   | DMZ     | 10.10.40.0/24   | (planned)                              |

## Stack

- **Host:** Fedora Linux, KVM/QEMU, libvirt, virt-manager
- **Bridging:** VLAN-aware Linux bridge (`vlan_filtering 1`), 802.1Q trunking, persistent across reboots via NetworkManager dispatcher and libvirt qemu hooks
- **Firewall / Router:** OPNsense — 4 VLAN sub-interfaces, Kea DHCP per subnet, per-interface firewall rules
- **Identity:** Windows Server 2022, Active Directory domain `corp.internal`, 5 OUs and 11 users provisioned by PowerShell run remotely from the host over WinRM
- **Endpoints:** Windows 11 (domain-joined over the trunk), Kali Linux, Metasploitable2
- **Tooling:** nmap, tcpdump, Wireshark, PowerShell, Bash

## Repo Contents

- [`Build-Log.md`](./Build-Log.md) — engineering journal, dated entries for every meaningful config change, decision, troubleshooting session, and fix
- [`Network.md`](./Network.md), [`OPNsense.md`](./OPNsense.md), [`DC01.md`](./DC01.md) — focused reference notes on each component
- [`Overview.md`](./Overview.md) — short summary

## Status

- [x] VLAN-aware Linux bridge with persistent VLAN config (NetworkManager + libvirt hooks + SELinux relabeling)
- [x] OPNsense router-on-a-stick with 4 VLAN sub-interfaces and per-VLAN DHCP
- [x] AD domain with OUs and users; Windows 11 domain-joined over the trunk
- [x] Kali on the attack VLAN; Metasploitable2 on the victim VLAN
- [x] First `nmap -sV -sC` sweep done; CVEs mapped (vsftpd 2.3.4 backdoor, Samba `usermap_script`, UnrealIRCd, OpenSSH Debian weak keys, Tomcat default creds)
- [x] VLAN isolation verified with `tcpdump -e` (802.1Q tags on the wire) and per-VLAN firewall rules
- [ ] DMZ host on VLAN 40
- [ ] Centralized logging (Wazuh / Security Onion)
- [ ] Ansible automation for VM provisioning
