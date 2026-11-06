#!/usr/bin/env bash
# Demo: light eBPF touch — bpftrace one-liner or graceful skip + static example
set -euo pipefail

echo "=== BEGIN eBPF ==="
echo "Why: modern observability/policy (Cilium, pwru) sits on eBPF maps + verified programs."

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "FAIL: not Linux. On macOS use: make demo-ebpf"
  exit 1
fi

echo "-- kernel / BTF --"
uname -r
if [[ -e /sys/kernel/btf/vmlinux ]]; then
  echo "BTF: /sys/kernel/btf/vmlinux present"
else
  echo "BTF: missing (CO-RE / many bpftrace scripts may fail)"
fi

if command -v bpftool >/dev/null 2>&1; then
  echo "-- bpftool feature probe (short) --"
  bpftool feature probe 2>/dev/null | head -n 40 || echo "bpftool probe failed"
else
  echo "bpftool: not installed"
fi

EXAMPLE="/lab/demos/ebpf/xdp_drop_sketch.c"
if [[ -f "$EXAMPLE" ]]; then
  echo "-- static XDP sketch (NOT loaded onto a NIC in this lab) --"
  sed -n '1,40p' "$EXAMPLE"
fi

ran=0
if command -v bpftrace >/dev/null 2>&1; then
  echo "-- bpftrace: count openat for 5s (best effort) --"
  if timeout 8s bpftrace -e 'tracepoint:syscalls:sys_enter_openat { @[comm] = count(); }' -c "/bin/sleep 5" 2>/tmp/bpftrace.err; then
    ran=1
  else
    echo "[skip] bpftrace failed to attach:"
    sed -n '1,20p' /tmp/bpftrace.err || true
  fi
fi

if [[ "$ran" -eq 0 ]]; then
  echo "[skip] live eBPF attach unavailable in this environment."
  echo "On a real Linux host with BTF you would see per-comm openat counts."
  echo "Still useful: know the failure mode (verifier, CAP_BPF, missing BTF)."
fi

echo "Observation: eBPF is powerful but environment-sensitive — especially under Docker Desktop kernels."
echo "=== END eBPF ==="
