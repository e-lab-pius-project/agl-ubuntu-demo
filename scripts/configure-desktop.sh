#!/usr/bin/env bash
# Settings apply only to the current GNOME desktop user.
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo "Run without sudo, as the desktop user." >&2; exit 1; }
[[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] ||
  { echo "Run in a terminal inside your logged-in GNOME desktop." >&2; exit 1; }
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
[[ "$(gsettings get org.gnome.desktop.session idle-delay)" == 'uint32 0' ]]
[[ "$(gsettings get org.gnome.desktop.screensaver lock-enabled)" == false ]]
[[ "$(gsettings get org.gnome.settings-daemon.plugins.power idle-dim)" == false ]]
[[ "$(gsettings get org.gnome.settings-daemon.plugins.power ambient-enabled)" == false ]]
[[ "$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type)" == "'nothing'" ]]
[[ "$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type)" == "'nothing'" ]]
echo 'PASS: idle blanking, automatic locking, dimming and idle suspend disabled'
