#!/usr/bin/env bash
# create-ubuntu-vm.sh — create a fully-unattended (headless) Ubuntu desktop VM
# on libvirt/QEMU using Ubuntu's cloud-init "autoinstall" mechanism.
#
# Usage:
#   VM_PASSWORD='secret' ./create-ubuntu-vm.sh 24.04 [vm-name]
#
# Environment overrides (all optional except VM_PASSWORD or VM_PASSWORD_HASH):
#   VM_USER=ubuntu           first user login name        (default: ubuntu)
#   VM_REALNAME=Ubuntu       user's real name             (default: VM_USER capitalised)
#   VM_HOSTNAME=ubuntu-vm    guest hostname               (default: vm-name)
#   VM_PASSWORD=...          plaintext password (hashed, never logged)
#   VM_PASSWORD_HASH=...     alternative: pre-made sha512-crypt hash
#   VCPUS=4 MEM_MIB=8192 DISK_GB=60
#   POOL_NAME=default        libvirt storage pool for ISO/disk/seed
#   NET=default              libvirt network
#   OS_VARIANT=ubuntu24.04   osinfo id (auto-detected if unset)
#   LOCALE=en_US.UTF-8 KEYBOARD=us
#   WAIT_TIMEOUT=2700        seconds to wait for the unattended install
#
# Requires: virt-install, virsh, curl, openssl, python3,
#           xorriso (or genisoimage/mkisofs), bsdtar (or 7z),
#           passwordless sudo (kernel extraction to /var/lib/libvirt/boot,
#           which libvirt's AppArmor policy whitelists).

set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

VERSION="${1:-24.04}"
VM_NAME="${2:-ubuntu-${VERSION}}"
VM_USER="${VM_USER:-ubuntu}"
VM_REALNAME="${VM_REALNAME:-$(printf '%s' "$VM_USER" | sed 's/^./\U&/')}"
VM_HOSTNAME="${VM_HOSTNAME:-${VM_NAME}}"
VCPUS="${VCPUS:-4}"
MEM_MIB="${MEM_MIB:-8192}"
DISK_GB="${DISK_GB:-60}"
POOL_NAME="${POOL_NAME:-default}"
NET="${NET:-default}"
LOCALE="${LOCALE:-en_US.UTF-8}"
KEYBOARD="${KEYBOARD:-us}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-2700}"

for cmd in virt-install virsh curl openssl python3; do
  command -v "$cmd" >/dev/null || die "missing dependency: $cmd"
done

virsh dominfo "$VM_NAME" >/dev/null 2>&1 && die "VM '$VM_NAME' already exists (virsh undefine it first if you want to replace it)"

# ---- credentials -----------------------------------------------------------
if [ -n "${VM_PASSWORD_HASH:-}" ]; then
  HASH="$VM_PASSWORD_HASH"
elif [ -n "${VM_PASSWORD:-}" ]; then
  HASH="$(openssl passwd -6 "$VM_PASSWORD")"
else
  die "set VM_PASSWORD (plaintext) or VM_PASSWORD_HASH (sha512-crypt) in the environment"
fi
unset VM_PASSWORD VM_PASSWORD_HASH 2>/dev/null || true

# ---- paths -----------------------------------------------------------------
POOL_DIR="$(virsh pool-dumpxml "$POOL_NAME" | sed -n "s:.*<path>\(.*\)</path>.*:\1:p")"
[ -n "$POOL_DIR" ] || die "pool '$POOL_NAME' not found or not a dir pool (run 'virsh pool-list --all' to inspect available pools)"
BOOT_DIR="/var/lib/libvirt/boot/${VM_NAME}"      # AppArmor-whitelisted for -kernel
SEED_SRC="${POOL_DIR}/${VM_NAME}-seed"
SEED_ISO="${POOL_DIR}/${VM_NAME}-autoinstall-seed.iso"
XML="$(mktemp)"

# ---- osinfo id (best-effort; falls back to explicit value or ubuntu24.04) ---
OS_VARIANT="${OS_VARIANT:-$(virt-install --osinfo list 2>/dev/null \
  | awk -F', *' -v id="ubuntu${VERSION}" '$2 == id {print $2}' | tail -1)}"
OS_VARIANT="${OS_VARIANT:-ubuntu24.04}"
echo "==> os-variant: $OS_VARIANT"

# ---- 1. resolve + download + verify the ISO ---------------------------------
VRE="$(printf '%s' "$VERSION" | sed 's/\./\\./g')"   # dots escaped for grep -E
ISO_NAME="$(curl -fsSL "https://releases.ubuntu.com/${VERSION}/" \
  | grep -oE "ubuntu-${VRE}(\.[0-9]+)?-desktop-amd64\.iso" | sort -uV | tail -1)"
[ -n "$ISO_NAME" ] || die "no desktop amd64 ISO found for ${VERSION}"
ISO="${POOL_DIR}/${ISO_NAME}"
ISO_URL="https://releases.ubuntu.com/${VERSION}/${ISO_NAME}"

if [ ! -f "$ISO" ]; then
  echo "==> downloading ${ISO_NAME}"
  if [ -f "${ISO}.part" ]; then curl -fL -C - -o "${ISO}.part" "$ISO_URL"; else curl -fL -o "${ISO}.part" "$ISO_URL"; fi
  mv "${ISO}.part" "$ISO"
else
  echo "==> using existing ${ISO_NAME}"
fi

EXPECTED="$(curl -fsSL "https://releases.ubuntu.com/${VERSION}/SHA256SUMS" \
  | awk -v f="$ISO_NAME" '$2 ~ f"$" {print $1}')"
ACTUAL="$(sha256sum "$ISO" | awk '{print $1}')"
[ "$ACTUAL" = "$EXPECTED" ] || die "SHA256 mismatch for ${ISO_NAME}"
echo "==> ISO checksum OK"

# ---- 2. extract casper kernel/initrd to the AppArmor-safe boot dir ----------
TMPX="$(mktemp -d)"
if command -v bsdtar >/dev/null; then
  bsdtar -x -f "$ISO" -C "$TMPX" casper/vmlinuz casper/initrd
else
  7z x -o"$TMPX" "$ISO" casper/vmlinuz casper/initrd >/dev/null
fi
sudo install -m 0644 -D "$TMPX/casper/vmlinuz" "${BOOT_DIR}/casper/vmlinuz"
sudo install -m 0644 -D "$TMPX/casper/initrd" "${BOOT_DIR}/casper/initrd"
rm -rf "$TMPX"
echo "==> casper kernel/initrd extracted to ${BOOT_DIR}/casper"

# ---- 3. build the CIDATA autoinstall seed ISO --------------------------------
mkdir -p "$SEED_SRC"; chmod 700 "$SEED_SRC"
umask 077
cat > "${SEED_SRC}/user-data" <<EOF
#cloud-config
autoinstall:
  version: 1
  locale: ${LOCALE}
  keyboard:
    layout: ${KEYBOARD}
  identity:
    realname: ${VM_REALNAME}
    username: ${VM_USER}
    hostname: ${VM_HOSTNAME}
    password: "${HASH}"
  storage:
    layout:
      name: direct
  shutdown: poweroff
EOF
printf 'instance-id: iid-%s-01\nlocal-hostname: %s\n' "$VM_NAME" "$VM_HOSTNAME" > "${SEED_SRC}/meta-data"
umask 022
if command -v xorriso >/dev/null; then
  xorriso -as mkisofs -volid CIDATA -joliet -rock -output "$SEED_ISO" "$SEED_SRC" >/dev/null 2>&1
else
  mkisofs -volid CIDATA -joliet -rock -output "$SEED_ISO" "$SEED_SRC" >/dev/null
fi
echo "==> seed ISO: ${SEED_ISO}"

# ---- 4. disk volume ----------------------------------------------------------
DISK="${POOL_DIR}/${VM_NAME}.qcow2"
virsh vol-path --pool "$POOL_NAME" "${VM_NAME}.qcow2" >/dev/null 2>&1 \
  || virsh vol-create-as --pool "$POOL_NAME" --name "${VM_NAME}.qcow2" --capacity "${DISK_GB}G" --format qcow2 >/dev/null
echo "==> disk: ${DISK} (${DISK_GB}G qcow2)"

# ---- 5. define the VM: direct kernel boot with the autoinstall flag ----------
virt-install --dry-run --print-xml=1 --quiet \
  --name "$VM_NAME" \
  --description "Ubuntu ${VERSION} desktop (autoinstall)" \
  --os-variant "$OS_VARIANT" \
  --memory "$MEM_MIB" --vcpus "$VCPUS" --cpu host-passthrough \
  --boot uefi,kernel="${BOOT_DIR}/casper/vmlinuz",initrd="${BOOT_DIR}/casper/initrd",kernel_args="autoinstall boot=casper console=ttyS0 ---" \
  --disk path="$DISK",bus=virtio,discard=unmap \
  --disk path="$ISO",device=cdrom,bus=sata \
  --disk path="$SEED_ISO",device=cdrom,bus=sata \
  --network "network=${NET}",model=virtio \
  --video virtio --graphics spice,listen=none \
  --serial "file,path=/var/log/libvirt/qemu/${VM_NAME}-console.log" \
  > "$XML"

python3 - "$XML" <<'PYEOF'
import sys
p = sys.argv[1]
xml = open(p).read()
# guard rails: any guest reboot/panic ends the VM instead of re-looping the installer
xml = xml.replace("<pm>", "<on_poweroff>destroy</on_poweroff>\n  <on_reboot>destroy</on_reboot>\n  <on_crash>destroy</on_crash>\n  <pm>", 1)
# once kernel-boot is stripped post-install, boot from disk
if "boot dev=" not in xml:
    xml = xml.replace("</os>", "    <boot dev='hd'/>\n  </os>", 1)
open(p, "w").write(xml)
PYEOF
virsh define "$XML" >/dev/null
virsh start "$VM_NAME"
echo "==> VM started; unattended install in progress (watch: sudo tail -f /var/log/libvirt/qemu/${VM_NAME}-console.log)"

# ---- 6. wait for the installer to power the VM off ---------------------------
ST="running"
DEADLINE=$(( SECONDS + WAIT_TIMEOUT ))
while [ $SECONDS -lt $DEADLINE ]; do
  ST="$(virsh domstate "$VM_NAME" 2>/dev/null || echo 'shut off')"
  [ "$ST" = "shut off" ] && break
  sleep 30
done
[ "$ST" = "shut off" ] || die "timeout waiting for install; inspect console log + virt-manager"

# ---- 7. post-install: normal boot from disk, detach ISOs ---------------------
virsh dumpxml "$VM_NAME" > "$XML"
python3 - "$XML" <<'PYEOF'
import re, sys
p = sys.argv[1]
xml = open(p).read()
xml = re.sub(r"\s*<(kernel|initrd|cmdline)>.*?</\1>", "", xml)                       # drop direct kernel boot
xml = re.sub(r"\s*<disk type=['\"]file['\"] device=['\"]cdrom['\"]>.*?</disk>", "", xml, flags=re.S)  # drop cdroms
xml = xml.replace("<on_reboot>destroy</on_reboot>", "<on_reboot>restart</on_reboot>") # normal reboots again
open(p, "w").write(xml)
PYEOF
virsh define "$XML" >/dev/null
virsh start "$VM_NAME"
echo "==> install complete; VM rebooted into the installed system"

# ---- 8. wait for a DHCP lease and report --------------------------------------
MAC="$(virsh dumpxml "$VM_NAME" | sed -n "s:.*<mac address='\([^']*\)'.*:\1:p")"
IP=""
DEADLINE=$(( SECONDS + 180 ))
while [ $SECONDS -lt $DEADLINE ] && [ -z "$IP" ]; do
  IP="$(virsh net-dhcp-leases "$NET" 2>/dev/null | awk -v mac="$MAC" '$0 ~ mac {sub(/\/.*/, "", $5); print $5; exit}')"
  [ -n "$IP" ] || sleep 10
done

rm -f "$XML"
echo
echo "=== VM '$VM_NAME' ready ==="
echo "    state    : $(virsh domstate "$VM_NAME")"
echo "    console  : virt-manager  (or: virt-viewer --attach $VM_NAME)"
[ -n "$IP" ] && echo "    ip       : $IP  (dhcp lease on '$NET')"
echo "    user     : $VM_USER  (password as supplied — change it in the guest!)"
[ -n "$IP" ] && echo "    note     : no sshd on Ubuntu desktop by default; 'sudo apt install openssh-server' in the guest to ssh ${VM_USER}@${IP}"
