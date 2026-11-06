#!/usr/bin/env bash
set -euo pipefail
umask 077
cd -- "${AGL_DIR:-"$HOME/agl-qemu"}"
[[ -r /dev/kvm && -w /dev/kvm ]] || {
  echo "/dev/kvm is unavailable. See README troubleshooting (UEFI virtualization / kvm group)." >&2
  exit 1
}
[[ -n "${DISPLAY:-}" ]] || { echo "DISPLAY is unset. Start from a terminal in the Ubuntu GNOME desktop." >&2; exit 1; }
[[ -f bzImage && -f agl-work.qcow2 ]] || { echo "Run scripts/prepare.sh first." >&2; exit 1; }
exec 9>.run.lock
flock -n 9 || { echo "AGL is already running with this data directory." >&2; exit 1; }
exec qemu-system-x86_64 \
  -name 'AGL on Ubuntu' \
  -machine q35,accel=kvm -cpu host -smp 2 -m 2048 \
  -kernel bzImage \
  -drive file=agl-work.qcow2,format=qcow2,if=virtio \
  -append 'root=/dev/vda rw console=ttyS0,115200 ip=dhcp' \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -device virtio-vga,xres=1920,yres=1080 \
  -display gtk,show-cursor=on \
  -device qemu-xhci -device usb-tablet \
  -device virtio-rng-pci \
  -serial file:serial.log \
  "$@"
