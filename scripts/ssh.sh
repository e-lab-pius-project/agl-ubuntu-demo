#!/usr/bin/env bash
set -euo pipefail
data=${AGL_DIR:-"$HOME/agl-qemu"}
mkdir -p -- "$data"
exec ssh -o StrictHostKeyChecking=accept-new \
  -o UserKnownHostsFile="$data/known_hosts" -p 2222 root@127.0.0.1 "$@"
