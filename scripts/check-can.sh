#!/usr/bin/env bash
# Run in Ubuntu after connecting both cannelloni services. Synthetic vcan only.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ip -details link show vcan_agl | grep -qw vcan
# agl-vcar.dbc: ID 1001, unsigned 15-bit BE, scale 1/64, left aligned.
for vector in 0000:0 0A00:20 1500:42 0000:0; do
  speed=${vector#*:}
  cangen vcan_agl -g 100 -n 10 -I 3E9 -L 8 -D "${vector%:*}000000000000"
  result=$(bash "$repo/scripts/ssh.sh" -tt -o BatchMode=yes -o ConnectTimeout=5 \
    'TERM=xterm databroker-cli --server https://localhost:55555 --ca-cert /etc/kuksa-val/CA.pem --token-file /etc/kuksa-can-provider/can-provider.token get Vehicle.Speed')
  printf '%s\n' "$result"
  grep -Fq "Vehicle.Speed: ${speed}.00 km/h" <<< "$result"
done
echo 'PASS: Ubuntu vcan_agl -> TCP -> AGL can0 -> KUKSA (0, 20, 42, 0 km/h)'
