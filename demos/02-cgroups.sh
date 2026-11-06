#!/usr/bin/env bash
# Demo: cgroup v2 CPU quota + throttling counters
set -euo pipefail

echo "=== BEGIN cgroups ==="
echo "Why: same busy-loop feels slower under cpu.max — foundation of K8s limits."

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "FAIL: not Linux. On macOS use: make demo-cgroup"
  exit 1
fi

CGROOT=/sys/fs/cgroup
if [[ ! -f "$CGROOT/cgroup.controllers" ]]; then
  echo "SKIP: cgroup v2 not mounted at $CGROOT"
  exit 0
fi

echo "-- controllers available --"
cat "$CGROOT/cgroup.controllers"

# Find a writable parent: prefer current cgroup
CUR=$(grep -E '^0::' /proc/self/cgroup | cut -d: -f3 || true)
PARENT="$CGROOT${CUR}"
if [[ ! -d "$PARENT" ]]; then
  PARENT="$CGROOT"
fi

LAB="$PARENT/linux-networking-lab-cpu"
echo "Using parent: $PARENT"
mkdir -p "$LAB" || {
  echo "SKIP: cannot create child cgroup under $PARENT (need delegation/privileged)"
  echo "Hint: docker run --privileged and ensure cgroup v2 delegation"
  exit 0
}

cleanup() {
  # kill workers then remove cgroup
  if [[ -f "$LAB/cgroup.procs" ]]; then
    while read -r p; do kill "$p" 2>/dev/null || true; done < "$LAB/cgroup.procs" || true
  fi
  rmdir "$LAB" 2>/dev/null || true
}
trap cleanup EXIT

# Enable cpu controller in parent if possible
if [[ -f "$PARENT/cgroup.subtree_control" ]]; then
  echo "+cpu" > "$PARENT/cgroup.subtree_control" 2>/dev/null || \
    echo "note: could not enable +cpu on parent (may already be enabled)"
fi

# 20% of one CPU: max 20000us per 100000us period
echo "20000 100000" > "$LAB/cpu.max"
echo "cpu.max=$(cat "$LAB/cpu.max")"

burn() {
  # pure userspace burn
  while true; do :; done
}

echo "-- starting constrained burner for 4s --"
burn &
BPID=$!
echo "$BPID" > "$LAB/cgroup.procs"
sleep 4
echo "-- cpu.stat while constrained --"
cat "$LAB/cpu.stat" || true
kill "$BPID" 2>/dev/null || true
wait "$BPID" 2>/dev/null || true

echo "Observation: nr_throttled / throttled_usec should be > 0 under tight cpu.max."
echo "=== END cgroups ==="
