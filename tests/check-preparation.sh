#!/usr/bin/env bash
# Uses a prepared image; does not download or boot a VM.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
data=$(realpath -- "${AGL_DIR:-"$HOME/agl-qemu"}")
name=agl-ivi-demo-flutter-qemux86-64-20261001034413.ext4
testdir=$(mktemp -d)
trap 'rm -rf -- "$testdir"' EXIT
for file in "$name.xz" "$name"; do ln -s -- "$data/$file" "$testdir/$file"; done
cp -- "$data/bzImage" "$testdir/bzImage"
AGL_DIR="$testdir" bash "$repo/scripts/prepare.sh"
qemu-img check "$testdir/agl-work.qcow2"
qemu-io -f qcow2 -c 'write -P 0xab 0 512' "$testdir/agl-work.qcow2"
before=$(sha256sum "$testdir/agl-work.qcow2")
AGL_DIR="$testdir" bash "$repo/scripts/prepare.sh"
[[ "$before" == "$(sha256sum "$testdir/agl-work.qcow2")" ]]
printf 'corrupt' >> "$testdir/bzImage"
if AGL_DIR="$testdir" bash "$repo/scripts/prepare.sh"; then
  echo "FAIL: corrupt kernel accepted" >&2
  exit 1
fi
[[ "$before" == "$(sha256sum "$testdir/agl-work.qcow2")" ]]
echo 'PASS: overlay creation, existing changes preserved, corrupt kernel rejected'
