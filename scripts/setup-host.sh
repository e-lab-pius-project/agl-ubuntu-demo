#!/usr/bin/env bash
# Run from the Ubuntu desktop terminal as the user who will run AGL.
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo "Run without sudo; individual commands request sudo." >&2; exit 1; }
. /etc/os-release
[[ "${ID:-}" == ubuntu && "${VERSION_ID:-}" == 26.04 && "$(uname -m)" == x86_64 ]] ||
  { echo "Ubuntu Desktop 26.04 LTS (amd64) is required." >&2; exit 1; }
[[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] ||
  { echo "Run in a terminal inside your logged-in GNOME desktop." >&2; exit 1; }
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
sudo apt update
sudo apt install -y git curl xz-utils qemu-system-x86 qemu-system-gui qemu-utils \
  openssh-client openssh-server can-utils usbutils acl gnome-remote-desktop
sudo usermod -aG kvm "$(id -un)"
sudo systemctl enable --now ssh.socket
bash "$repo/scripts/configure-desktop.sh"
printf '\nHost setup complete. Log out of Ubuntu and log in again for the kvm group.\n'
printf 'Then configure RDP Desktop Sharing as described in docs/HOST_SETUP.md.\n'
