# Autoinstall notes & reference

## Environment variables (create-ubuntu-vm.sh)

| Variable | Default | Purpose |
|---|---|---|
| `VM_PASSWORD` or `VM_PASSWORD_HASH` | *(required)* | Plaintext (hashed by script, never logged) or pre-made sha512-crypt hash |
| `VM_USER` | `ubuntu` | First-user login name |
| `VM_REALNAME` | capitalised `VM_USER` | GECOS/real name |
| `VM_HOSTNAME` | vm name | Guest hostname |
| `VCPUS` / `MEM_MIB` / `DISK_GB` | `4` / `8192` / `60` | VM sizing |
| `POOL_NAME` | `default` | libvirt dir storage pool (holds ISO, seed, qcow2; run `virsh pool-list --all` to discover) |
| `NET` | `default` | libvirt network (NAT) |
| `OS_VARIANT` | auto-detected | osinfo id; falls back to `ubuntu24.04`. Only affects device defaults, not correctness |
| `LOCALE` / `KEYBOARD` | `en_US.UTF-8` / `us` | Installer locale/keyboard |
| `WAIT_TIMEOUT` | `2700` | Seconds to wait for the unattended install |

## The seed user-data template

Written to `<pool>/<vm>-seed/user-data`, then packed (with `meta-data`) into
`<vm>-autoinstall-seed.iso` with volume label `CIDATA`:

```yaml
#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us
  identity:
    realname: Ubuntu User
    username: ubuntu
    hostname: ubuntu-vm
    password: "<sha512-crypt hash>"
  storage:
    layout:
      name: direct        # plain whole-disk; use `lvm` for an LVM root
  shutdown: poweroff
```

To customise (extra packages, LVM, ssh server), edit `user-data` **before** the
ISO is built, or edit the seed source dir and rebuild with:

```bash
xorriso -as mkisofs -volid CIDATA -joliet -rock -output <vm>-autoinstall-seed.iso <vm>-seed/
```

Common additions (desktop installer supports a subset of the server autoinstall
schema; `packages`, `late-commands`, `snaps`, `ssh` are known to work on
recent releases — always test schema changes, unknown keys can abort autoinstall):

```yaml
  ssh:
    install-server: true
    allow-pw: true
  packages:
    - openssh-server
    - build-essential
```

## Manual procedure (if you can't use the script)

1. Download ISO + `SHA256SUMS` from `https://releases.ubuntu.com/<version>/`; verify.
2. `bsdtar -x -f <iso> casper/vmlinuz casper/initrd` → place under
   `/var/lib/libvirt/boot/<vm>/casper/` (chmod 644, root-owned; AppArmor whitelist).
3. Build the CIDATA seed ISO as above.
4. Generate domain XML headlessly and patch it before defining:

   ```bash
   virt-install --dry-run --print-xml=1 \
     --name <vm> --os-variant ubuntu24.04 \
     --memory 8192 --vcpus 4 --cpu host-passthrough \
     --boot uefi,kernel=/var/lib/libvirt/boot/<vm>/casper/vmlinuz,initrd=/var/lib/libvirt/boot/<vm>/casper/initrd,kernel_args="autoinstall boot=casper console=ttyS0 ---" \
     --disk path=<pool>/<vm>.qcow2,bus=virtio,discard=unmap \
     --disk path=<iso>,device=cdrom,bus=sata \
     --disk path=<seed>.iso,device=cdrom,bus=sata \
     --network network=default,model=virtio \
     --video virtio --graphics spice,listen=none \
     --serial file,path=/var/log/libvirt/qemu/<vm>-console.log > vm.xml
   ```

   Patch `vm.xml`: add `<boot dev='hd'/>` inside `<os>`, and
   `<on_poweroff>destroy</on_poweroff> <on_reboot>destroy</on_reboot> <on_crash>destroy</on_crash>`
   (reboot-loop guard). Then `virsh define vm.xml && virsh start <vm>`.
5. Wait for `virsh domstate <vm>` → `shut off` (installer powers the VM off; ~14 min for desktop).
6. `virsh dumpxml <vm>`, strip `<kernel>/<initrd>/<cmdline>` and all
   `device="cdrom"` disk blocks, set `<on_reboot>restart</on_reboot>`, define, start.
7. Confirm with `virsh net-dhcp-leases default`.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| VM dies instantly, `journalctl` shows AppArmor DENIED on vmlinuz | kernel/initrd not under `/var/lib/libvirt/boot/` — move them there |
| No DHCP lease, install log loops casper messages | seed ISO volume label isn't `CIDATA` — rebuild with `-volid CIDATA` |
| SHA256 mismatch on a resumed `.part` download | two downloaders raced on the same `.part` file (kill + relaunch overlap). The checksum gate is supposed to catch this — delete the ISO/`.part`, confirm no other `curl` is writing (`ps aux | grep curl`), re-run |
| Installer sits interactive at "Try or Install" | `autoinstall` kernel arg missing (check `<cmdline>` in XML), or release predates desktop autoinstall (~23.04) |
| domstate stays `running` past ~20 min with no progress | take a look: `virt-viewer --attach <vm>`; likely a schema typo in `user-data` aborted autoinstall — check the serial console log |
| `VM already exists` | intentional guard: `virsh undefine <vm> --nvram` + `virsh vol-delete <vm>.qcow2 --pool <pool>` |
| Pool not found or not a dir pool | Run `virsh pool-list --all` to inspect active pools; verify directory-backing via `virsh pool-dumpxml <pool>`, then pass `POOL_NAME=<pool>` |
