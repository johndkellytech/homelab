# Network Architecture

The lab uses a single VLAN-aware Linux bridge (`br-lab`) carrying all internal traffic as 802.1Q trunks. OPNsense sits on the trunk with one sub-interface per VLAN — router-on-a-stick.

For the full buildout (with all the troubleshooting that got us here), see [`Build-Log.md`](./Build-Log.md). For OPNsense specifics, see [`OPNsense.md`](./OPNsense.md).

## Topology

```
                  [ Internet / WAN ]
                         |
                  [ libvirt default NAT ]   <-- OPNsense WAN (vtnet0)
                         |
                   [   OPNsense   ]
                         | (single trunk, 802.1Q)
                   [    br-lab    ]          <-- VLAN-aware Linux bridge
       __________________|__________________
      |          |          |          |
   VLAN 10   VLAN 20    VLAN 30    VLAN 40
    MGMT     ATTACK     VICTIMS     DMZ
```

## VLANs

| VLAN | Name    | Subnet          | Gateway       | Hosts                              |
|------|---------|-----------------|---------------|------------------------------------|
| 10   | MGMT    | 10.10.10.0/24   | 10.10.10.1    | DC01 (10.10.10.10), Windows 11     |
| 20   | ATTACK  | 10.10.20.0/24   | 10.10.20.1    | Kali Linux                         |
| 30   | VICTIMS | 10.10.30.0/24   | 10.10.30.1    | Metasploitable2                    |
| 40   | DMZ     | 10.10.40.0/24   | 10.10.40.1    | (planned)                          |

OPNsense owns `.1` on every VLAN. Each VLAN has its own Kea DHCP pool (`.100`–`.200`). WAN sits on a separate libvirt NAT network (`192.168.122.0/24`).

## Why VLANs / Router-on-a-Stick

- **CCNA-aligned.** 802.1Q trunking and inter-VLAN routing are core CCNA exam topics — this lab is the textbook example.
- **Mirrors production.** Real routers usually have one trunk to a switch carrying many VLANs; multi-NIC-per-network is rare in enterprise networks.
- **Easy to extend.** Adding a VLAN is config-only — no new physical NICs or libvirt networks.

## Persistence

Bridge VLAN config doesn't survive reboots out of the box. Two pieces of automation handle it:

- **NetworkManager dispatcher** (`/etc/NetworkManager/dispatcher.d/99-br-lab-vlans.sh`) — adds VLAN 10 to `br-lab self` so the host can reach MGMT
- **libvirt qemu hook** (`/etc/libvirt/hooks/qemu`) — re-applies VLANs 10/20/30/40 to OPNsense's trunk port (`opn-trunk`) whenever OPNsense boots

OPNsense's trunk port is renamed via `<target dev='opn-trunk'/>` in its libvirt XML so the hook can reliably target it across reboots regardless of vnet boot order.

## Verification

802.1Q tags on the wire:

```bash
sudo tcpdump -e -i br-lab "vlan and icmp"
```

Bridge VLAN map:

```bash
bridge vlan show
```

Inter-VLAN routing decrements TTL (64 → 63), so a TTL drop on a cross-VLAN ping confirms OPNsense is routing rather than the bridge switching.
