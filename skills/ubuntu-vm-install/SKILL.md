---
name: ubuntu-vm-install
description: Create a headless, fully-unattended Ubuntu desktop VM on Linux using libvirt/virt-manager tools (virt-install + cloud-init autoinstall). Trigger when asked to download an Ubuntu ISO and create an Ubuntu VM, install Ubuntu in virt-manager/QEMU/KVM, or run an unattended/headless Ubuntu desktop install. Handles any Ubuntu release, user/password provisioning, and post-install cleanup automatically.
---

# Ubuntu VM install (headless, unattended)

Creates an Ubuntu desktop VM on libvirt (`qemu:///system`) with **zero interactive steps**: downloads the ISO, verifies it, provisions the user, installs to disk, detaches install media, and boots the finished VM.

## Quick start

```bash
VM_PASSWORD='change-me' POOL_NAME=default \
  ./scripts/create-ubuntu-vm.sh 24.04 my-ubuntu-vm
```

The script takes `VERSION [vm-name]` (version examples: `24.04`, `26.04`; point releases like `24.04.4` are resolved automatically). Everything else is controlled by environment variables — see the table in `references/autoinstall-notes.md`, or the script header.

Typical full run: **~25–40 min** (dominated by ISO download at ~5–8 MB/s and a ~14 min unattended install). Run it with `nohup … &` and poll the log rather than blocking a tool call.

## Prerequisites

- `virt-install`, `virsh` (libvirt daemon + KVM access; user in `libvirt`/`kvm` groups)
- `xorriso` (or `genisoimage`/`mkisofs`), `bsdtar` (or `7z`), `curl`, `openssl`, `python3`
- **Passwordless sudo** — needed only to place the extracted kernel/initrd under `/var/lib/libvirt/boot/`, which libvirt's AppArmor policy whitelists for direct kernel boot. (If VMs on the host run with a non-enforcing security driver this matters less, but the path is correct regardless.)
- A libvirt dir-backed storage pool with ≥ ~10 GB free (ISO ~6 GB + thin qcow2)

### Storage pool discovery

Before running, check available pools on the host and verify capacity:

```bash
# List all active storage pools (usually 'default')
virsh pool-list --all

# Check capacity and available space on the target pool
virsh pool-info default

# Confirm the pool is directory-backed (must show type='dir' with a valid <path>)
virsh pool-dumpxml default | grep -E "<pool type|<path"
```

If `default` is missing, inactive, or lacks space, pick an active directory-backed pool with ≥ 10 GB free and pass `POOL_NAME=<pool-name>`.

## How it works (why this method)

`virt-install --unattended` exists, but it depends on libosinfo having an install-script template for the *exact* OS release — `osinfo-db` frequently lags new releases (e.g. knows only up to 25.10 while 26.04 is out). The reliable, release-independent method used here is Ubuntu's native **cloud-init autoinstall**:

1. **ISO**: latest point release scraped from `releases.ubuntu.com/<version>/`, SHA256-verified. Resumes `.part` files if a previous download was interrupted.
2. **Direct kernel boot**: `casper/vmlinuz` + `casper/initrd` are extracted from the ISO into `/var/lib/libvirt/boot/<vm>/` and passed via `virt-install --boot kernel=…,initrd=…,kernel_args="autoinstall boot=casper console=ttyS0 ---"`. This is how the `autoinstall` kernel flag gets set without editing the ISO's GRUB.
3. **CIDATA seed ISO**: `user-data` (autoinstall config: identity/locale/keyboard/storage layout/shutdown) + `meta-data`, built with volume label `CIDATA` — cloud-init in the live session picks it up automatically and provisions the user.
4. **Reboot-loop guard**: the domain is defined with `on_reboot=destroy` during install, and the autoinstall config uses `shutdown: poweroff`, so the installer can never re-run itself.
5. **Post-install**: strip `<kernel>/<initrd>/<cmdline>` and both cdrom devices from the XML, restore `on_reboot=restart`, start the VM from `<boot dev='hd'/>`.
6. **Verify**: a DHCP lease for the guest MAC on the libvirt network proves the installed system booted (the live installer would report a different hostname; the lease hostname comes from the autoinstall identity).

Serial console of the install is logged to `/var/log/libvirt/qemu/<vm>-console.log` (read with sudo) — `reboot: Power down` near the end signals a completed install.

## Verification checklist

- `virsh domstate <vm>` → `running` after the script finishes
- `virsh net-dhcp-leases <net>` → lease with the expected hostname/IP
- Console: `virt-manager` or `virt-viewer --attach <vm>`; log in with the provisioned user

## Gotchas

- **Password is a placeholder by design** — remind the user to change it (`passwd` in guest). Use `VM_PASSWORD_HASH` (sha512-crypt, e.g. `openssl passwd -6`) to keep real secrets out of command lines.
- **Ubuntu desktop ships no sshd** — to reach the VM over ssh, install it in the guest (`sudo apt install openssh-server`).
- **Same-VM reruns fail fast** ("VM already exists") on purpose; undefine + delete the volume to redo.
- **Install hang** (no power-off after ~20 min) almost always means the desktop installer fell back to interactive mode — check the console log, then attach with virt-manager to see the prompt. On releases older than ~23.04 the flutter desktop installer does not support autoinstall at all.
- Ubuntu has no `.06` releases — only `.04` (April) and `.10` (October). If a user asks for e.g. "26.06", confirm they mean the nearest real release (`26.04`).

## See also

- `references/autoinstall-notes.md` — environment variable reference, seed `user-data` template, customisation (disk size, LVM, extra packages), and manual steps if you'd rather not use the script.
- Ubuntu autoinstall reference: https://canonical-autoinstall.readthedocs-hosted.com/
