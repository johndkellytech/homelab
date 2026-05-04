# Network Architecture

## Overview
The lab uses two virtual networks in libvirt/KVM to simulate a segmented enterprise environment. [[OPNsense]] sits between them as the router/firewall.

## Virtual Networks

### `default` (NAT)
- **Subnet**: 192.168.122.0/24
- **Purpose**: WAN — provides internet access via NAT through the Fedora host
- **DHCP**: Enabled (managed by libvirt)
- **Connected**: OPNsense WAN interface (vtnet0)
- **Note**: This is libvirt's built-in default network. It NATs out through the host's physical NIC.

### `lab-lan` (Isolated)
- **Subnet**: 192.168.100.0/24
- **Purpose**: Internal lab LAN — all lab VMs communicate here
- **DHCP**: Disabled on libvirt side (OPNsense will handle DHCP)
- **Mode**: Isolated — no direct path to the physical network or internet
- **Connected**: OPNsense LAN interface (vtnet1), [[DC01]], and all future lab VMs

## Why Isolated?
The `lab-lan` network has **no forwarding** to the physical network. The only way for a VM on lab-lan to reach the internet is through OPNsense. This mirrors real network segmentation — the firewall controls all traffic in and out. If we used NAT or routed mode, VMs could bypass OPNsense entirely, defeating the purpose.

## Why Disable DHCP on lab-lan?
OPNsense is the authoritative DHCP server for the LAN. Two DHCP servers on the same subnet causes conflicts — devices wouldn't know which one to listen to. Disabling it on the libvirt side gives OPNsense full control over IP assignments, DNS, and gateway info.

## Subnet Scheme

| Network | Subnet | Gateway | Purpose |
|---|---|---|---|
| `default` (NAT) | 192.168.122.0/24 | 192.168.122.1 (libvirt) | WAN / internet access |
| `lab-lan` (Isolated) | 192.168.100.0/24 | 192.168.100.1 (OPNsense) | Internal lab traffic |
| Home network | 192.168.1.0/24 | 192.168.1.1 (Spectrum router) | Physical home network (avoid overlap!) |

## Traffic Flow
```
Lab VM (e.g., DC01) → lab-lan switch → OPNsense LAN (192.168.100.1)
    → OPNsense WAN (192.168.122.x) → default NAT → Fedora host → Internet
```

## TODO
- [ ] Enable DHCP on OPNsense LAN via web GUI
- [ ] Move DC01 NIC from default to lab-lan
- [ ] Configure firewall rules on OPNsense
- [ ] Set up DNS forwarding
