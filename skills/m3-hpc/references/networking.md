# M3 Networking and IP Ranges

**As of 2026-08-13.** IP assignments below may change periodically — re-verify before relying on this for firewall rules or anything security-critical.

Not officially documented by eResearch — derived from `whois`, `dig`/reverse DNS, and direct inspection of `/etc` network config on M3 login and compute nodes.

## Public IP range

M3's front-facing public hosts sit in **`118.138.254.128/25`** (118.138.254.128 – 118.138.254.255, gateway `.254`), a subnet of Monash's larger `118.138.0.0/16` allocation (APNIC `MONASHUNI-NET3`, ALLOCATED PORTABLE, abuse contact `net-abuse@monash.edu`).

| IP | Host |
|---|---|
| `118.138.254.221` | m3-login3 |
| `118.138.254.224` | monarch-dtn |
| `118.138.254.231` | m3-insight-p |
| `118.138.254.232` | scout-dtn1 |
| `118.138.254.233` / `.234` | m3-login1 / m3-login2 (targets of the `m3.massive.org.au` DNS alias) |
| `118.138.254.235` / `.236` | m3-dtn1 / m3-dtn2 (targets of the `m3-dtn.massive.org.au` DNS alias) |
| `118.138.254.237`–`.251` | reserved (`reserve-118-138-254-*.erc.monash.edu.au`) |
| `118.138.254.252`–`.254` | Monash MERN datacentre gateways (not M3-specific) |
| `118.138.254.128`–`.220` | generic ERC/Nectar cloud VMs, not M3 |

The lower half of the /24 (`118.138.254.0/25`) does not resolve at all — M3 hosts occupy only the upper /25. Always connect via the DNS aliases (`m3.massive.org.au`, `m3-dtn.massive.org.au`) rather than individual login/DTN node names — the docs note these aliases are kept up to date even if the underlying node addresses change.

`docs.massive.org.au` / `massive.org.au` resolve to `130.194.250.205`, a *different* Monash allocation (`130.194.0.0/16`) — don't assume everything under the `massive.org.au` / MASSIVE brand lives in the `118.138.x.x` space.

## Compute node addressing (private, no public IP)

Compute nodes have no public interface. Confirmed via `ip -4 addr` on sample nodes (`m3v101` in `genomics`, `m3s106` in `short`):

- `172.16.192.0/21`, `172.16.200.0/21` — compute node private VLANs
- `172.23.236.0/22` — additional private VLAN (seen on both login and compute nodes)

## Outbound NAT egress from compute jobs

Traffic originating **from a SLURM job on a compute node** (e.g. `curl`, package downloads, API calls) NATs out through a single address:

- **`118.138.254.235`** (m3-dtn1) — confirmed empirically from two different partitions/nodes via `curl https://api.ipify.org`

Login nodes egress as themselves (`.233`/`.234` depending which login node you're on).

This NAT gateway is not documented and could change (there are two DTN nodes, so a second gateway might be added) — if an external service needs firewall allowlisting for M3 job traffic, confirm current behaviour with `help@massive.org.au` rather than hard-coding this address into critical infrastructure.

## Suggested firewall ranges

- Inbound SSH/services to M3 → `118.138.254.221`, `.233`, `.234`, `.235`, `.236`
- Outbound *from* M3 compute jobs (what a third-party API/service needs to allow) → `118.138.254.235`
- Conservative superset covering all current and future M3 front-end nodes → `118.138.254.128/25`
- Whole-of-Monash superset (rarely needed) → `118.138.0.0/16`

## Monash GlobalProtect staff VPN

Monash staff VPN (GlobalProtect) client range: **`10.44.0.0/17`**. Relevant when a service needs to allow SSH/access from Monash staff connecting off-campus via VPN, as distinct from M3's own node addresses above.
