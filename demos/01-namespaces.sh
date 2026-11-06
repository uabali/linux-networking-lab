#!/usr/bin/env bash
# Demo: two network namespaces + veth + ping
set -euo pipefail

echo "=== BEGIN namespaces ==="
echo "Kernel: $(uname -srm)"
echo "Why: show that netns gives a private network stack (pod-like isolation)."

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "FAIL: not Linux. On macOS use: make demo-netns"
  exit 1
fi

cleanup() {
  ip netns del red 2>/dev/null || true
  ip netns del blue 2>/dev/null || true
}
trap cleanup EXIT

cleanup
ip netns add red
ip netns add blue
ip link add veth-red type veth peer name veth-blue
ip link set veth-red netns red
ip link set veth-blue netns blue

ip -n red addr add 10.200.1.1/24 dev veth-red
ip -n blue addr add 10.200.1.2/24 dev veth-blue
ip -n red link set lo up
ip -n blue link set lo up
ip -n red link set veth-red up
ip -n blue link set veth-blue up

echo "-- interfaces in red --"
ip netns exec red ip -br addr
echo "-- interfaces in blue --"
ip netns exec blue ip -br addr

echo "-- ping red -> blue --"
ip netns exec red ping -c 3 -W 2 10.200.1.2

echo "Observation: host eth0 is invisible inside red/blue; only lo + veth."
echo "=== END namespaces ==="
