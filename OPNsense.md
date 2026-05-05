# OPNsense (Firewall / Router)

OPNsense — FreeBSD-based open-source firewall. Acts as the lab's gateway and inter-VLAN router. Runs as a libvirt VM with two NICs: WAN on libvirt's NAT network and a trunk on `br-lab` carrying all four lab VLANs.

## VM Config

| Setting    | Value                                                |
|------------|------------------------------------------------------|
| Install    | DVD ISO (not VGA / nano — see Build-Log 2026-04-08)  |
| OS Family  | FreeBSD 14.x                                          |
| Filesystem | ZFS stripe (single disk)                              |
| RAM        | 4 GB                                                  |
| vCPUs      | 4                                                     |
| Disk       | 20 GB qcow2                                           |
| NIC 1 WAN  | `vtnet0` → libvirt `default` NAT (192.168.122.0/24)   |
| NIC 2 LAN  | `vtnet1` → bridge `br-lab` (trunk; untagged in XML)   |

The trunk NIC has `<target dev='opn-trunk'/>` in its libvirt XML so the host always sees it as `opn-trunk` regardless of boot order — this is what the qemu hook keys on for VLAN persistence.

## VLAN Sub-Interfaces

Console option 1 (Assign interfaces) created 4 child interfaces on `vtnet1`:

| Interface         | VLAN | Assignment      | IP             |
|-------------------|------|-----------------|----------------|
| `vtnet1_vlan10`   | 10   | LAN (MGMT)      | 10.10.10.1/24  |
| `vtnet1_vlan20`   | 20   | OPT1 (ATTACK)   | 10.10.20.1/24  |
| `vtnet1_vlan30`   | 30   | OPT2 (VICTIMS)  | 10.10.30.1/24  |
| `vtnet1_vlan40`   | 40   | OPT3 (DMZ)      | 10.10.40.1/24  |

Each has a Kea DHCP pool (`.100`–`.200`) and a starting allow-all firewall rule. Inter-VLAN traffic flows through OPNsense (router-on-a-stick) and can be filtered per-interface.

## Verifying Isolation

Phase 5 of the buildout verified VLAN isolation by adding a Block rule above the allow-all on the ATTACK interface:

| Test                           | Result                                                |
|--------------------------------|-------------------------------------------------------|
| Cross-VLAN ping (no block)     | 3/3 success, TTL decremented 64 → 63                  |
| Block rule applied             | 0/3 packets — surgical (gateway still reachable)      |
| Block rule removed             | 3/3 restored                                          |

Full evidence (with tcpdump output) is in `Build-Log.md` (2026-04-14 entry).

## Gotchas

- **"Configure address via DHCP" ≠ "Enable DHCP server"** — easy to confuse during console setup. The first makes OPNsense a DHCP client; the second makes it a server.
- The console "Enable DHCP server on LAN" prompt starts **Dnsmasq**, which conflicts with **Kea** on port 67. Disable Dnsmasq before using Kea: `Services → Dnsmasq DNS & DHCP → uncheck Enable`.
- Default creds (`root` / `opnsense`) are fine on an isolated lab network but must be changed before any production-adjacent use.
