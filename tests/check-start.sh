#!/usr/bin/env bash
# Exercise launcher arguments and locking without booting or changing a VM.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ -r /dev/kvm && -w /dev/kvm ]] || { echo 'SKIP: /dev/kvm unavailable'; exit 0; }
testdir=$(mktemp -d)
pid=
cleanup() {
  if [[ -n "$pid" ]]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
  rm -rf -- "$testdir"
}
trap cleanup EXIT
mkdir "$testdir/bin" "$testdir/data"
touch "$testdir/data/bzImage" "$testdir/data/agl-work.qcow2"
cat > "$testdir/bin/qemu-system-x86_64" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$TEST_OUTPUT"
touch "$TEST_READY"
[[ "${TEST_EXIT:-0}" != 1 ]] || exit 0
exec sleep 30
MOCK
chmod +x "$testdir/bin/qemu-system-x86_64"
export AGL_DIR="$testdir/data" DISPLAY=:0 TEST_OUTPUT="$testdir/args" TEST_READY="$testdir/ready"
export PATH="$testdir/bin:$PATH"
unset AGL_GL TEST_EXIT
bash "$repo/scripts/start.sh" -monitor stdio > "$testdir/first.log" 2>&1 &
pid=$!
for ((i=0; i<50; i++)); do
  [[ ! -f "$TEST_READY" ]] || break
  sleep 0.1
done
[[ -f "$TEST_READY" ]] || { cat "$testdir/first.log"; exit 1; }
grep -Fxq 'q35,accel=kvm' "$TEST_OUTPUT"
grep -Fxq 'virtio-vga-gl,xres=1920,yres=1080' "$TEST_OUTPUT"
grep -Fxq 'gtk,gl=on,show-cursor=on' "$TEST_OUTPUT"
grep -Fxq 'user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22' "$TEST_OUTPUT"
tail -n 2 "$TEST_OUTPUT" | diff - <(printf '%s\n' -monitor stdio)
if bash "$repo/scripts/start.sh" > "$testdir/second.log" 2>&1; then
  echo 'FAIL: duplicate launch accepted' >&2; exit 1
fi
grep -Fq 'already running' "$testdir/second.log"
kill "$pid"
wait "$pid" 2>/dev/null || true
pid=
AGL_GL=0 TEST_EXIT=1 bash "$repo/scripts/start.sh"
grep -Fxq 'virtio-vga,xres=1920,yres=1080' "$TEST_OUTPUT"
grep -Fxq 'gtk,show-cursor=on' "$TEST_OUTPUT"
if AGL_GL=invalid bash "$repo/scripts/start.sh" > "$testdir/gl.log" 2>&1; then
  echo 'FAIL: invalid AGL_GL accepted' >&2; exit 1
fi
grep -Fq 'AGL_GL must be 0 or 1' "$testdir/gl.log"
if env -u DISPLAY bash "$repo/scripts/start.sh" > "$testdir/display.log" 2>&1; then
  echo 'FAIL: missing DISPLAY accepted' >&2; exit 1
fi
grep -Fq 'DISPLAY is unset' "$testdir/display.log"
echo 'PASS: default GPU acceleration, 2D fallback, invalid graphics mode rejected, loopback SSH, monitor forwarding, locking, DISPLAY required'
