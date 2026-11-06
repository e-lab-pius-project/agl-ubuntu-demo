#!/usr/bin/env bash
# Download the pinned upstream image and keep guest changes in a separate overlay.
set -euo pipefail
umask 077
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
data=${AGL_DIR:-"$HOME/agl-qemu"}
base=${AGL_DOWNLOAD_BASE:-https://github.com/e-lab-pius-project/agl-wsl-demo/releases/download/agl-20261001}
name=agl-ivi-demo-flutter-qemux86-64-20261001034413.ext4
mkdir -p -- "$data"
cd -- "$data"
exec 9>.prepare.lock
flock -n 9 || { echo "Another preparation is running." >&2; exit 1; }
trap 'rm -f -- bzImage.part "$name.xz.part" "$name.part" agl-work.qcow2.part' EXIT
while read -r hash file; do
  [[ -n "$hash" ]] || continue
  if [[ ! -f "$file" ]]; then
    curl --fail --location --retry 3 --output "$file.part" "$base/$file"
    printf '%s  %s\n' "$hash" "$file.part" | sha256sum --check -
    mv -- "$file.part" "$file"
  fi
  printf '%s  %s\n' "$hash" "$file" | sha256sum --check -
done < "$repo/images/SHA256SUMS"
if [[ ! -f "$name" ]]; then
  xz --decompress --stdout "$name.xz" > "$name.part"
  mv -- "$name.part" "$name"
  chmod a-w -- "$name"
fi
if [[ ! -f agl-work.qcow2 ]]; then
  qemu-img create -f qcow2 -F raw -b "$PWD/$name" agl-work.qcow2.part
  mv -- agl-work.qcow2.part agl-work.qcow2
fi
printf 'Ready: %s\nRun: bash %s/scripts/start.sh\n' "$PWD" "$repo"
