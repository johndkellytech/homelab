# Build Log

## 2026-04-08 — OPNsense VM Setup

### Image Types Matter
Downloaded three OPNsense image types before getting it right:
- **nano** — designed for embedded/USB devices (serial console, no installer). Not suitable for VMs.
- **vga** — pre-installed live image. Boots directly into OPNsense but has no separate disk to install *to*. The installer runs but errors with "No disk(s) present to configure" because the image itself is the disk.
- **dvd** — full installer ISO. Creates a proper install onto a qcow2 virtual disk. This is the correct choice for KVM VMs.

**Lesson**: Match the image type to the deployment target. VGA/nano are for bare metal or embedded. DVD ISO is for virtualized installs.

### IP Conflict with Home Router
OPNsense LAN defaults to 192.168.1.1/24. My Spectrum home router is also 192.168.1.1. Trying to access the web GUI at `https://192.168.1.1` hit the Spectrum login page instead.

**Fix**: Changed OPNsense LAN to 192.168.100.0/24 — a completely different subnet with no overlap.

**Lesson**: Always check your existing network before assigning IPs to lab gear. Overlapping subnets = traffic goes to the wrong place.

### Firewall Needs Two NICs
First OPNsense VM only had one NIC. A firewall/router needs a minimum of two interfaces to function — one facing the untrusted network (WAN) and one facing the trusted network (LAN). Without two NICs, there's nothing to route *between*.

**Fix**: Created the `lab-lan` isolated virtual network in libvirt, then added a second NIC to the OPNsense VM.

### DHCP on LAN — Don't Say Yes
During LAN interface config, I set DHCP to `y` on the LAN side. OPNsense then tried to *get* an IP via DHCP instead of *being* the gateway with a static IP. A gateway/router doesn't ask for an address — it *is* the address.

**Fix**: Re-ran option 2, set LAN to static 192.168.100.1/24, said `n` to DHCP.

### Linux CLI Notes
- `find / -iname "*pattern*" 2>/dev/null` — case-insensitive file search, suppress permission errors
- `bunzip2 filename.bz2` — decompress bzip2 files
- Piping find to xargs (`find ... | xargs cmd`) works but can act on unintended files if find returns multiple results. Always run find alone first to verify.

## 2026-04-11 — Pivot: VLAN Rebuild (Router-on-a-Stick)

### Housekeeping
- **Database:** Confirmed the MySQL database is running on **Podman** (not Docker). Container is named `sql-hw`, started via `podman start sql-hw`.
- **Hardware & Capacity Review:** Host specs — i9-10900K, 32GB RAM, 548GB free space. System can handle 8–15 concurrent VMs without bottlenecking.

### Why the Pivot
The multi-NIC OPNsense setup works, but it's not how real networks are built. In production, routers have 2 interfaces (WAN + trunk to a switch) and all internal networks ride the trunk as 802.1Q VLANs. Since I'm studying CCNA, VLANs / trunking / inter-VLAN routing aren't optional — they're core curriculum. Decided to rebuild the lab "the proper way" from the start instead of doing it twice.

**Tradeoff accepted**: steeper learning curve (learning OPNsense + 802.1Q + libvirt bridge VLANs simultaneously) in exchange for a lab that mirrors real-world topology and directly reinforces CCNA material.

### What "Router-on-a-Stick" Means
One trunk cable ("the stick") from router to switch carries every VLAN at once. The router has **sub-interfaces** — one per VLAN — that each act like a separate physical interface. Switch handles all physical connections; router does all the routing between VLANs through that single cable. Called a "stick" because in diagrams the router looks like a lollipop hanging off the switch by one line.

This is literally the CCNA inter-VLAN routing topology.

### Planned VLAN / Subnet Table
| VLAN | Name    | Subnet         | Purpose                          |
|------|---------|----------------|----------------------------------|
| 10   | MGMT    | 10.10.10.0/24  | Management / admin access        |
| 20   | ATTACK  | 10.10.20.0/24  | Kali and offensive tooling       |
| 30   | VICTIMS | 10.10.30.0/24  | Metasploitable, vuln VMs         |
| 40   | DMZ     | 10.10.40.0/24  | Public-facing services, web apps |

Gateway for each VLAN = `.1`, owned by OPNsense.

### Phased Buildout

**Phase 0 — Plan on paper (this entry)**
Decide VLAN IDs and subnets before touching any config. Done.

**Phase 1 — Host: VLAN-aware Linux bridge**
- Create `br-lab` bridge with `vlan_filtering 1` enabled
- Make persistent via NetworkManager (Fedora default)
- Verify with `bridge vlan show`
- Internal-only — no physical NIC attached (same role the old `lab-lan` network played)
- Key: libvirt's default `virbr0` / NAT networks are NOT VLAN-aware, which is why a custom bridge is required

**Phase 2 — libvirt: teach it about the bridge**
- Define a libvirt network of type `<forward mode='bridge'/>` pointing at `br-lab`, OR attach VMs directly with `<interface type='bridge'><source bridge='br-lab'/>`
- OPNsense trunk vNIC: no VLAN tag in XML (passes tags through untouched = trunk mode)
- Access-port VMs: `<vlan><tag id='N'/></vlan>` in their NIC XML (libvirt tags frames on the way into the bridge)
- Thinnest-docs step. Expect to read libvirt network XML reference.

**Phase 3 — OPNsense: create VLAN interfaces**
- Shut down OPNsense, remove old `lab-lan` vNIC, add new vNIC on `br-lab` untagged (this becomes the trunk)
- GUI: **Interfaces → Other Types → VLAN** → add VLAN 10/20/30/40 with parent = trunk NIC (e.g. `vtnet1`)
- **Interfaces → Assignments** → assign each as MGMT/ATTACK/VICTIMS/DMZ
- Static IP `.1/24` per interface
- **Services → DHCPv4** → enable per interface with a range
- **Firewall → Rules** → start with allow-all per VLAN, tighten after everything works

**Phase 4 — First test VM**
- Kali first. Edit its NIC to use `br-lab` with VLAN tag 20
- Should DHCP into `10.10.20.0/24`
- `ping 10.10.20.1` (gateway) should succeed

**Phase 5 — Prove isolation**
- On host: `sudo tcpdump -e -i br-lab` — the `-e` flag shows Ethernet headers including VLAN tags (without it, tags are hidden — critical debugging trick)
- Ping from Kali, confirm frames are tagged `vlan 20` in the capture
- Block VLAN 20 → VLAN 30 in OPNsense firewall, verify ping fails
- Re-allow, verify ping works
- This is the payoff step where VLANs finally "click"

### Design Decisions
- **Linux bridge with `vlan_filtering 1`** chosen over **Open vSwitch**. OVS is more powerful but overkill for a first VLAN lab — adds a whole new tool to learn on top of everything else.
- **Multi-NIC fallback rejected**. It would be easier, but it wouldn't teach the trunking/tagging concepts CCNA tests on.

### Open Questions / Gotchas to Watch
- NetworkManager vs manual `ip link` persistence on Fedora — NM should handle bridges, but VLAN filtering flag may need a dispatcher script or nmcli property
- How libvirt handles trunk ports exactly — does omitting the `<vlan>` element really pass all tags through? Verify before assuming.
- Whether existing VMs can be edited in place to switch networks, or if they need to be recreated

### Phase 1 Completion — br-lab bridge

Created the bridge and enabled VLAN filtering:
```bash
nmcli connection add type bridge con-name br-lab ifname br-lab
nmcli connection modify br-lab bridge.vlan-filtering yes
```

**Gotcha**: NetworkManager defaults `ipv4.method` to `auto` (DHCP) on new bridges. A lab bridge is a switch — it doesn't need an IP. OPNsense owns the gateway addresses, not the host. Fix:
```bash
nmcli connection modify br-lab ipv4.method disabled ipv6.method disabled
nmcli connection up br-lab
```

**Answered open question**: NM handles bridge creation and the `vlan-filtering` flag natively via `nmcli` — no dispatcher scripts needed.

### Phase 2 Completion — libvirt NIC swap (2026-04-12)

Used `virsh edit OPNsense` to replace the second NIC (slot 0x04). Changed from the old `lab-lan` libvirt network to a direct bridge attachment on `br-lab`:

```xml
<!-- Old -->
<interface type='network'>
  <source network='lab-lan'/>
</interface>

<!-- New -->
<interface type='bridge'>
  <source bridge='br-lab'/>
</interface>
```

- Kept the same MAC address (`52:54:00:e7:b6:a9`) and PCI slot so OPNsense sees it as the same device
- No `<vlan>` element = trunk mode (all tagged frames pass through untouched)
- WAN NIC (slot 0x03, `default` NAT network) left unchanged

**Answered open question**: Existing VMs *can* be edited in place with `virsh edit` — no need to recreate them.

**Gotcha**: `virsh edit` validates XML on save. A typo (`</domadin>` instead of `</domain>`) caused a save failure. The editor re-opens to let you fix it — read the error message carefully.

### Phase 3 Completion — OPNsense VLAN interfaces (2026-04-13)

#### CPU bump
Increased OPNsense from 2 to 4 vCPUs before booting:
```bash
sudo virsh setvcpus OPNsense 4 --config --maximum
sudo virsh setvcpus OPNsense 4 --config
```
Two-step process: raise the ceiling (max), then set the actual count. `--config` writes to saved XML (applies on next boot).

**Gotcha**: `virsh` is a subcommand of `sudo virsh`, not a standalone binary. Also, `virsh` without `sudo` connects to `qemu:///session` (user VMs) — lab VMs live in `qemu:///system` (need `sudo`).

#### Console VLAN setup
Booted OPNsense, used console option 1 (Assign interfaces):
- Said **N** to LAGGs, **Y** to VLANs
- Created 4 VLANs on parent `vtnet1` (trunk NIC on br-lab): tags 10, 20, 30, 40
- Assigned: WAN → vtnet0, LAN → vtnet1_vlan10, OPT1 → vtnet1_vlan20, OPT2 → vtnet1_vlan30, OPT3 → vtnet1_vlan40

Then option 2 (Set interface IP) on LAN (interface 1):
- DHCP client? **N** — gateway doesn't ask for an IP, it *is* the IP
- Static IP: `10.10.10.1/24`, no upstream gateway
- IPv6 WAN tracking? **N**, DHCPv6? **N**, static IPv6? blank (Enter to skip)
- DHCP server on LAN? **Y** — range `10.10.10.100 – 10.10.10.200`
- HTTPS→HTTP? **N**, regenerate cert? **Y**, restore GUI defaults? **Y**

**Key distinction**: "Configure address via DHCP" = client (getting an address). "Enable DHCP server" = server (handing out addresses). Wording is subtle but different.

#### Bridge VLAN filtering — the missing piece
Host couldn't reach `10.10.10.1` after creating `br-lab.10` sub-interface (`10.10.10.2/24`). Ping returned "Destination Host Unreachable".

**Root cause**: `br-lab` has `vlan_filtering=1` enabled, but all ports only had VLAN 1 allowed. The bridge was silently dropping VLAN 10 tagged frames.

**Fix**: Manually allow VLANs on the trunk port (`vnet1`) and the bridge itself:
```bash
sudo bridge vlan add vid 10 dev vnet1
sudo bridge vlan add vid 20 dev vnet1
sudo bridge vlan add vid 30 dev vnet1
sudo bridge vlan add vid 40 dev vnet1
sudo bridge vlan add vid 10 dev br-lab self
```

Used `bridge link show` to identify which vnet was on br-lab (vnet1 = OPNsense trunk, vnet0 = WAN on virbr0).

**Warning**: These `bridge vlan` commands are **not persistent** — lost on reboot. Need to make permanent (TODO).

**Lesson**: VLAN-aware bridges don't just filter — they *whitelist*. Every port must explicitly allow each VLAN ID, or frames get dropped silently. `bridge vlan show` is the diagnostic tool.

#### Web GUI config
Accessed dashboard at `https://10.10.10.1`. Skipped setup wizard (Abort).

**Interfaces → [OPT1/OPT2/OPT3]**: Enabled each, renamed, set static IPs:
| Interface | Description | IP |
|---|---|---|
| OPT1 | ATTACK | 10.10.20.1/24 |
| OPT2 | VICTIMS | 10.10.30.1/24 |
| OPT3 | DMZ | 10.10.40.1/24 |

**Services → Kea DHCP → Kea DHCPv4**:
- Settings tab: Enabled, selected all 4 interfaces (LAN, ATTACK, VICTIMS, DMZ)
- Subnets tab: added 4 subnets with "Auto collect option data" checked:

| Subnet | Description | Pool |
|---|---|---|
| 10.10.10.0/24 | MGMT | 10.10.10.100 – 10.10.10.200 |
| 10.10.20.0/24 | ATTACK | 10.10.20.100 – 10.10.20.200 |
| 10.10.30.0/24 | VICTIMS | 10.10.30.100 – 10.10.30.200 |
| 10.10.40.0/24 | DMZ | 10.10.40.100 – 10.10.40.200 |

**Gotcha**: Kea DHCP subnet form has multi-select fields (Domain search, Time servers) that look required (red borders) but aren't. Checking "Auto collect option data" auto-fills them from the interface config.

**Firewall → Rules**: Added allow-all pass rule (any/any/any) on ATTACK, VICTIMS, and DMZ interfaces. LAN already had a default allow-all. Will tighten in Phase 5.

### Phase 4 Completion — Kali on VLAN 20 (2026-04-13)

#### Bridge VLAN persistence
The `bridge vlan add` commands from Phase 3 are not persistent. Created a NetworkManager dispatcher script to re-apply them when `br-lab` comes up:

File: `/etc/NetworkManager/dispatcher.d/99-br-lab-vlans.sh`
- Runs on `br-lab` up event
- Adds VLANs 10/20/30/40 to `vnet1` (OPNsense trunk port)
- Adds VLAN 10 to `br-lab self` (host management access)

**Caveat**: Script hardcodes `vnet1` — vnet names are assigned by boot order. If VMs boot in a different order, OPNsense's trunk may get a different vnet name. Good enough for now.

#### Kali VM creation
Kali image was a **pre-built qcow2** (not an ISO) — already installed, no installer needed. Just point a VM at it and boot.

```bash
sudo mv ~/Documents/kali-linux-2026.1-qemu-amd64.qcow2 /var/lib/libvirt/images/
sudo virt-install --name Kali --ram 4096 --vcpus 4 --import \
  --disk /var/lib/libvirt/images/kali-linux-2026.1-qemu-amd64.qcow2 \
  --os-variant debian12 --network bridge=br-lab --noautoconsole
```

- `--import` = use existing disk, don't install from ISO
- Default creds: `kali` / `kali`

#### VLAN 20 access port
`virt-install` doesn't support VLAN tags directly. Workaround: dump XML, edit, redefine.

```bash
sudo virsh dumpxml Kali > ~/kali.xml
# Add <vlan><tag id='20'/></vlan> inside the <interface> block
sudo virsh define ~/kali.xml
```

This makes Kali an access port on VLAN 20 (ATTACK network). Libvirt tags all frames with VLAN 20 on the way into br-lab, and strips the tag on the way out to Kali — the VM sees a normal untagged network.

#### Dnsmasq conflict — DHCP not working
After booting Kali, `dhcpcd` solicited a lease but got no response. Kea DHCP logs showed socket bind failures ("Address already in use").

**Root cause**: During Phase 3 console setup, saying "Y" to "Enable DHCP server on LAN" started **Dnsmasq** (the built-in lightweight DNS/DHCP server). Dnsmasq was holding the DHCP port (67), so Kea couldn't bind.

**Fix**: Disabled Dnsmasq at **Services → Dnsmasq DNS & DHCP → uncheck Enable**. Restarted Kea. Kali immediately got a lease in `10.10.20.0/24`.

**Lesson**: OPNsense has multiple services that can serve DHCP (Dnsmasq, Kea). Only one can hold port 67 at a time. Console "Enable DHCP server" activates Dnsmasq, not Kea.

#### Verification
- Kali booted, got DHCP lease on 10.10.20.0/24 from Kea
- `ping 10.10.20.1` (OPNsense ATTACK gateway) — success
- tcpdump on br-lab confirmed frames tagged `vlan 20`

### DC01 on VLAN 10 — MGMT (2026-04-13)

#### NIC swap to br-lab
DC01 was on the `default` NAT network (`virbr0`), bypassing OPNsense entirely. Moved it to `br-lab` with VLAN tag 10 via virt-manager:
- **GUI**: NIC → Network source → Bridge device → `br-lab`
- **XML tab** (enable XML editing in Edit → Preferences first): added `<vlan><tag id='10'/></vlan>` inside the `<interface>` block

#### vnet numbering shifted
After booting OPNsense + DC01, `bridge link show` revealed:
- `vnet4` → virbr0 (OPNsense WAN)
- `vnet5` → br-lab (OPNsense trunk) — was `vnet1` before
- `vnet7` → br-lab (DC01)

The dispatcher script (`/etc/NetworkManager/dispatcher.d/99-br-lab-vlans.sh`) hardcodes `vnet1` — **this is broken now**. vnet names are assigned dynamically by boot order. Need to fix the script to find the right vnet dynamically. **TODO**.

Had to manually add VLANs to the trunk port:
```bash
sudo bridge vlan add vid 10 dev vnet5
sudo bridge vlan add vid 20 dev vnet5
sudo bridge vlan add vid 30 dev vnet5
sudo bridge vlan add vid 40 dev vnet5
```

#### PVID/untagged — the critical lesson
After assigning DC01's static IP (`10.10.10.10/24`, gateway `10.10.10.1`, DNS `10.10.10.10`), ping to OPNsense failed. Debugging steps:
1. `bridge vlan show` — confirmed VLANs on trunk (vnet5) ✓
2. `tcpdump -e -i vtnet1_vlan10` on OPNsense — saw DC01's multicast (SSDP) but no ARP
3. `arp -an` on OPNsense — no entry for 10.10.10.10, confirming ARP resolution failure
4. Checked `bridge vlan show` for vnet7 — showed `10` but **no PVID or Egress Untagged flags**

**Root cause**: We manually ran `bridge vlan add vid 10 dev vnet7` which added VLAN 10 without the `pvid untagged` flags. For an access port, the bridge needs:
- **PVID** — tag incoming untagged frames with this VLAN ID
- **Egress Untagged** — strip the VLAN tag on frames going out to the VM

Without these, DC01's untagged frames had no VLAN association, and return traffic still had tags that DC01 didn't understand.

**Fix**:
```bash
sudo bridge vlan del vid 10 dev vnet7
sudo bridge vlan add vid 10 dev vnet7 pvid untagged
```

Ping to `10.10.10.1` immediately succeeded after this.

**Lesson**: Don't manually `bridge vlan add` an access port without `pvid untagged` flags. Libvirt's `<vlan><tag id='N'/>` XML sets this up correctly on its own — if you override it manually, include the flags. For trunk ports (like OPNsense's vnet), no PVID/untagged is correct because the trunk carries tagged traffic.

#### OPNsense interface naming (FreeBSD)
VLAN interfaces inside OPNsense are named `vtnet1_vlan10`, `vtnet1_vlan20`, etc. — NOT `vtnet1.10` or `vlan10`. Use `ifconfig -l` to list all interface names.

#### DC01 state
- **AD domain**: `corp.internal` — fully installed and working
- **Users**: only defaults (Administrator, Guest, krbtgt) — no custom users/OUs yet
- **IP**: `10.10.10.10/24`, DNS pointing to self
- **NIC**: br-lab VLAN 10 (access port)
- Needs: custom OUs, users, and domain-join win11

#### win11 VM
Exists in virt-manager (Shutoff). Still on old network config — needs same NIC swap to br-lab VLAN 10 and domain join. Not started yet.

### Fix: Persistent VLAN Trunk Port (2026-04-13)

The NM dispatcher script (`99-br-lab-vlans.sh`) hardcoded `vnet1` for the OPNsense trunk port, but vnet names are assigned dynamically by boot order — broke when DC01 was added.

**Fix (two parts):**

1. **Persistent interface name**: Added `<target dev='opn-trunk'/>` to OPNsense's br-lab NIC via `virsh edit`. The trunk port is now always called `opn-trunk` regardless of boot order. Name can't start with `vnet` (reserved by libvirt).

2. **Libvirt qemu hook**: Created `/etc/libvirt/hooks/qemu` — fires when OPNsense starts, adds VLANs 10/20/30/40 to `opn-trunk`. This solves the timing problem: NM dispatcher fires when br-lab comes up (before VMs exist), but the hook fires after the VM starts (when the vnet exists).

3. **Slimmed dispatcher**: `99-br-lab-vlans.sh` now only handles `br-lab self` (host management access to VLAN 10). All vnet VLAN config moved to the hook.

**Verified**: `bridge vlan show` shows `opn-trunk` with VLANs 10, 20, 30, 40 after OPNsense boot.

**Sources**: `<target dev>` trick from [anracom blog](https://linux-blog.anracom.com/2016/02/07/kvmqemu-libvirt-virt-manager-persistent-names-for-the-virtual-network-interfaces-of-guest-systems/), hook approach from [enimihil.net](https://enimihil.net/linux-bridging-vlans-and-libvirt) and [kvmvlan](https://github.com/nesanton/kvmvlan).

### win11 — VLAN 10 + Domain Join (2026-04-13)

- Swapped NIC from `default` (virbr0) to `br-lab` VLAN 10 via `virsh define` with edited XML
- Trimmed resources: 8GB → 4GB RAM, 4 → 2 vCPUs (plenty for a domain client)
- Kea DHCP config updated: unchecked "Auto collect option data" on MGMT subnet, set DNS server to `10.10.10.10` (DC01), domain name to `corp.internal`
- DHCP lease: `10.10.10.100/24`, gateway `10.10.10.1`, DNS `10.10.10.10`
- Domain-joined via `Add-Computer -DomainName corp.internal -Credential corp\Administrator -Restart`
- Verified: `(Get-WmiObject Win32_ComputerSystem).Domain` → `corp.internal`

**Note**: `systeminfo | findstr Domain` was slow/unreliable on first domain login — profile build and GP processing causes delays. `Get-WmiObject` is a faster check.

### AD OUs and Users (2026-04-13)

Created 5 OUs and 11 domain users via PowerShell script (`setup-ad.ps1`) executed remotely over WinRM (pywinrm from Linux host → DC01).

**OUs** (under DC=corp,DC=internal): IT Infrastructure, Security Operations, Development, Human Resources, Finance

**Users:**
| Username | Name | OU | Title |
|---|---|---|---|
| jkelly | John Kelly | IT Infrastructure | Systems Administrator |
| mchen | Maria Chen | IT Infrastructure | Network Administrator |
| sadams | Sarah Adams | IT Infrastructure | Infrastructure Lead |
| rjones | Robert Jones | Security Operations | Security Analyst |
| asmith | Aisha Smith | Security Operations | Security Auditor |
| tgarcia | Tony Garcia | Development | Software Developer |
| lnguyen | Lisa Nguyen | Development | Software Developer |
| dwright | Dana Wright | Human Resources | HR Specialist |
| kwilson | Karen Wilson | Human Resources | HR Manager |
| bpatel | Bimal Patel | Finance | Financial Analyst |
| jmorris | James Morris | Finance | Accounting Manager |

All accounts enabled, password `LabPass123!`. Default users (Administrator, Guest, krbtgt) also present.

**WinRM access**: `pywinrm` installed on host (`python3 -m pip install --user pywinrm`). Can run PowerShell on DC01 remotely via NTLM auth — no more manual typing in virt-manager console.

**Sudoers update**: Added `/etc/sudoers.d/lab` with NOPASSWD for `virsh`, `bridge`, `nmcli`, `systemctl restart libvirtd`, and `cp` — Claude can now run lab commands directly.

### Metasploitable2 — VLAN 30 (2026-04-13)

Downloaded Metasploitable2 (~826MB zip from SourceForge), converted `.vmdk` → `.qcow2` with `qemu-img convert`, moved to `/var/lib/libvirt/images/`. Created VM via `virsh define` from hand-written XML (virt-install not in sudoers).

- **VM**: Metasploitable2, 512MB RAM, 1 vCPU, VLAN 30 access port (pvid untagged via libvirt XML)
- **Confirmed**: `vnet10` shows VLAN 30 PVID Egress Untagged in `bridge vlan show`
- **IP**: `10.10.30.100` (Confirmed via nmap scan)

### Phase 4 Completion — Kali Scan & Automation (2026-04-13)

#### SSH Automation
Installed `sshpass` on the host to allow non-interactive command execution against the Kali VM:
```bash
sudo dnf install -y sshpass
```

#### Vulnerability Scan
Executed an `nmap -sV -sC` scan from Kali (`10.10.20.100`) against the VICTIMS subnet (`10.10.30.0/24`). Results redirected to `~/scan_results.txt` on host.

**Findings (Target: 10.10.30.100):**
- **vsftpd 2.3.4** (Port 21) — Likely backdoor (CVE-2011-2523)
- **OpenSSH 4.7p1** (Port 22) — Multiple vulnerabilities (CVE-2008-0166 Debian weak keys, etc.)
- **Samba 3.0.20-Debian** (Port 139/445) — Likely `usermap_script` (CVE-2007-2447)
- **Bindshell** (Port 1524) — Instant root access
- **UnrealIRCd** (Port 6667) — Backdoor potential (CVE-2010-2075)
- **Tomcat 5.5** (Port 8180) — Default/weak credentials

**Lesson**: Metasploitable2 is a "target-rich environment." The presence of a bindshell on 1524 and an anonymous FTP login on 21 confirms the VICTIMS VLAN is properly isolated but highly vulnerable.

**Next Step**: Map these services to formal CVEs and populate the `VULNERABILITIES` and `SCAN_RESULTS` tables in the SQL project.

### Remote Access Setup (2026-04-13)

**WinRM → DC01**: `pywinrm` installed via `python3 -m ensurepip --user && python3 -m pip install --user pywinrm`. Auth: NTLM, `http://10.10.10.10:5985/wsman`, `corp\Administrator`. Can run arbitrary PowerShell on DC01 from host — used to create AD OUs/users without touching virt-manager.

**SSH → Kali**: Enabled via `sudo systemctl enable --now ssh` in Kali terminal. Kali IP: `10.10.20.100` (DHCP from Kea, VLAN 20 pool).

**Host routes to lab VLANs** (added via nmcli, persistent):
```
10.10.20.0/24 via 10.10.10.1 (reaches Kali/ATTACK)
10.10.30.0/24 via 10.10.10.1 (reaches Metasploitable2/VICTIMS)
```
Added to `br-lab.10` connection profile. Host can now reach all lab VLANs through OPNsense.

**Sudoers** (`/etc/sudoers.d/lab`): virsh, bridge, nmcli, systemctl restart libvirtd, cp, tcpdump — all NOPASSWD for Gnimo.

### TODOs
- [x] Fix dispatcher script — make vnet detection dynamic instead of hardcoded `vnet1`
- [x] Move win11 to br-lab VLAN 10, boot, domain-join to `corp.internal`
- [x] Create AD OUs and users on DC01 (feeds DEPARTMENTS and USERS tables in SQL project)
- [x] Stand up Metasploitable2 on VLAN 30 (VICTIMS)
- [ ] Scan Metasploitable2 from Kali (nmap -sV -sC 10.10.30.0/24) — **NEXT STEP**
  - SSH into Kali: `ssh kali@10.10.20.100` (pw: kali)
  - Run: `nmap -sV -sC 10.10.30.0/24 > ~/scan_results.txt`
  - SCP results back: `scp kali@10.10.20.100:~/scan_results.txt ~/`
  - Extract CVEs → populate VULNERABILITIES + SCAN_RESULTS tables
- [ ] Update `02_sample_data.sql` with real lab data (deadline: April 20)
- [ ] Stand up a DMZ box on VLAN 40
- [x] Phase 5 — prove VLAN isolation

### VM Inventory (current)
| VM | RAM | vCPU | VLAN | IP | Status |
|---|---|---|---|---|---|
| OPNsense | 4GB | 4 | trunk (10/20/30/40) | 10.10.10.1 (LAN) | Running |
| DC01 | ? | ? | 10 (MGMT) | 10.10.10.10 | Running |
| win11 | 4GB | 2 | 10 (MGMT) | 10.10.10.100 (DHCP) | Running |
| Kali | 4GB | 4 | 20 (ATTACK) | 10.10.20.100 (DHCP) | Running, SSH enabled |
| Metasploitable2 | 512MB | 1 | 30 (VICTIMS) | 10.10.30.x (DHCP) | Running |

### Phase 5 Completion — VLAN Isolation Proven (2026-04-14)

#### tcpdump — 802.1Q tags on the wire
Ran `tcpdump -e -i br-lab "vlan and icmp"` on the host while Kali pinged Metasploitable2. Output showed the full router-on-a-stick path:

```
Kali → OPNsense (vlan 20) → OPNsense routes → Metasploitable2 (vlan 30)
Metasploitable2 → OPNsense (vlan 30) → OPNsense routes → Kali (vlan 20)
```

- `ethertype 802.1Q (0x8100)` confirmed real 802.1Q tagging
- VLAN tag flips from 20→30 on the request, 30→20 on the reply
- TTL=63 (decremented from 64) = proof traffic is routed through OPNsense, not switched

#### Firewall block test
Created a block rule on the ATTACK interface: Source = ATTACK net, Destination = VICTIMS net, Action = Block, Quick = checked. Rule placed **above** the existing allow-all pass rule (first-match wins).

| Test | Result |
|---|---|
| Cross-VLAN ping before block | 3/3 success, TTL=63 |
| Block rule applied + Apply Changes | 0/3 packets, 100% loss |
| Kali → gateway (10.10.20.1) during block | Still reachable — block is surgical |
| Block rule removed + Apply Changes | 3/3 success restored |

**Lesson**: Rule order matters — block rules must be above allow-all or they never match. OPNsense evaluates per-interface rules top-down, first match wins. The "Quick" flag makes matching immediate but doesn't override position.

**Lesson**: The `-e` flag on tcpdump is essential for VLAN debugging — without it, Ethernet headers (including VLAN tags) are hidden. Use `tcpdump -e -i br-lab "vlan"` to see tagged frames.

### Phase 5 complete — VLAN isolation verified.

### Dispatcher script ownership fix (2026-04-14)

After reboot, host lost access to the lab (`ping 10.10.10.1` failed). Root cause: `br-lab self` port was missing VLAN 10 — the NM dispatcher script `/etc/NetworkManager/dispatcher.d/99-br-lab-vlans.sh` refused to run because it was owned by `Gnimo`, not `root`. `journalctl -u NetworkManager-dispatcher` showed: `Cannot execute ... : not owned by root`.

**Fix**: `sudo chown root:root` on the dispatcher script. Live fix applied with `bridge vlan add vid 10 dev br-lab self`.

**Lesson**: NM dispatcher scripts must be owned by root (security requirement — otherwise any user could escalate by editing scripts that run with NM privileges). Always check ownership after creating dispatcher scripts.

### SQL Sample Data — Real Lab Data (2026-04-14)

Rewrote `Semester SQL project/data/02_sample_data.sql` end-to-end with real lab data.

- **DEPARTMENTS** — 5 real AD OUs + 5 planned placeholders (for 10-row rubric)
- **USERS** — 12 real AD users from `corp.internal` (Administrator + 11 from `setup-ad.ps1`)
- **NETWORK_SEGMENTS** — real VLANs 10/20/30/40 + libvirt default (WAN) + 5 planned
- **IP_ALLOCATIONS** — 11 actual assigned IPs (OPNsense gateways, DC01, win11, Kali, Metasploitable2, host)
- **HOSTS** — `gnimo-host` (Fedora 43, real) + 9 planned
- **VIRTUAL_MACHINES** — 5 real (OPNsense, DC01, win11, Kali, Metasploitable2) + 7 planned (Splunk, Wazuh, Security Onion, Ansible, DMZ-web, dev sandbox, MySQL-lab)
- **VULNERABILITIES** — 5 real CVEs from the Metasploitable2 nmap (vsftpd 2.3.4 backdoor, Samba usermap_script, UnrealIRCd backdoor, OpenSSL Debian weak keys, Tomcat JSP upload) + 5 lab-relevant Windows/AD CVEs (ZeroLogon, Log4Shell, Certifried, PrintNightmare, EternalBlue)
- **SCAN_RESULTS** — 12 rows: 5 unremediated findings on Metasploitable2 (intentionally left for lab use) + 7 simulated patch-history entries demonstrating the remediation workflow on DC01/win11/Kali/host
- **SOFTWARE_LICENSES** — 10 rows mixing OSS (OPNsense, Kali, Ubuntu 8.04, Wazuh, Security Onion, Ansible, MySQL) and subscription (Windows Server 2022, Windows 11 Pro, Splunk trial)

Scan dates set to `2026-04-13` (actual nmap date). Administrator = user_id 1; VMs all host_id 1 (gnimo-host).

**Next**: load against a MySQL instance and run schema → data → views → queries → procedures → perms to verify FKs, CHECK constraint on SCAN_RESULTS, and the triggers all behave.

### Dispatcher script SELinux label fix (2026-04-15)

Follow-up to the 04-14 ownership fix. Script was still failing with `Permission denied`, but this time the cause was SELinux, not unix perms. `ls -l` showed `root:root 0755` (correct), yet execs kept failing.

**Root cause**: The script had SELinux label `unconfined_u:object_r:user_home_t:s0` — the label files inherit when created in `/home`. I'd written it in my home directory and copied it to `/etc/NetworkManager/dispatcher.d/`, which preserves the source label.

NetworkManager's dispatcher runs in the confined domain `NetworkManager_dispatcher_t`. SELinux policy only allows that domain to execute files labeled `NetworkManager_dispatcher_script_t`. A `user_home_t` file → denied, regardless of unix perms.

Diagnostic came from the SELinux alert:
```
avc: denied { execute } for comm="nm-dispatcher" name="99-br-lab-vlans.sh"
scontext=...NetworkManager_dispatcher_t tcontext=...user_home_t
```

**Fix**:
```
sudo restorecon -v /etc/NetworkManager/dispatcher.d/99-br-lab-vlans.sh
```
`restorecon` looks up the path's default label in the SELinux file-context DB (`/etc/selinux/targeted/contexts/files/file_contexts`) and reapplies it. Verified with `ls -Z` → now `NetworkManager_dispatcher_script_t`. Post-fix `ausearch -m AVC -ts recent` returns no matches.

**Lesson**: On Fedora/RHEL with SELinux enforcing, unix perms aren't enough — the file label matters too. Two ways to avoid this when dropping scripts into system dirs from your home folder:
- `sudo install -m 0755 src.sh /etc/.../dst.sh` — sets the correct label from the target dir's default context
- `sudo cp src.sh /etc/.../` then `sudo restorecon -v /etc/.../dst.sh`

This will come up again with udev rules (`/etc/udev/rules.d/`), systemd units (`/etc/systemd/system/`), cron jobs, polkit rules, etc. Any time a system daemon is refusing to exec a file you just dropped in from `/home`, check `ls -Z` before anything else.

**Debug workflow for future SELinux denials**:
```
sudo ausearch -m AVC -ts recent       # see recent denials
ls -Z /path/to/file                   # check current label
sudo restorecon -v /path/to/file      # reset to policy default
```
Only reach for `audit2allow` / custom policy modules when the default label is genuinely wrong for the use case — not for mislabeled files.

### Status
**Phase 5 complete.** SQL sample data rewrite done. Remaining: stand up DMZ box on VLAN 40, load SQL files into MySQL for verification, implementation doc PDF (due April 20).
