#!/usr/bin/env bash
# Demo: drop ICMP between two netns with nftables (iptables fallback)
set -euo pipefail

echo "=== BEGIN iptables/nftables ==="
echo "Why: packet filters are the ancestors of kube-proxy / NetworkPolicy datapaths."

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "FAIL: not Linux. On macOS use: make demo-firewall"
  exit 1
fi

cleanup() {
  ip netns del fw-a 2>/dev/null || true
  ip netns del fw-b 2>/dev/null || true
}
trap cleanup EXIT
cleanup

ip netns add fw-a
ip netns add fw-b
ip link add v-a type veth peer name v-b
ip link set v-a netns fw-a
ip link set v-b netns fw-b
ip -n fw-a addr add 10.200.2.1/24 dev v-a
ip -n fw-b addr add 10.200.2.2/24 dev v-b
ip -n fw-a link set lo up
ip -n fw-b link set lo up
ip -n fw-a link set v-a up
ip -n fw-b link set v-b up

echo "-- baseline ping (expect OK) --"
ip netns exec fw-a ping -c 2 -W 2 10.200.2.2

if command -v nft >/dev/null 2>&1; then
  echo "-- installing nft DROP icmp on fw-b input --"
  ip netns exec fw-b nft -f - <<'EOF'
table inet lab {
  chain input {
    type filter hook input priority 0; policy accept;
    ip protocol icmp counter drop
  }
}
EOF
  echo "-- ping after DROP (expect FAIL) --"
  if ip netns exec fw-a ping -c 2 -W 2 10.200.2.2; then
    echo "WARN: ping still succeeded (nft hook may need CAP_NET_ADMIN / kernel nft)"
  else
    echo "OK: ICMP dropped as expected"
  fi
  echo "-- ruleset in fw-b --"
  ip netns exec fw-b nft list ruleset || true
  ip netns exec fw-b nft delete table inet lab || true
else
  echo "-- nft missing; falling back to iptables --"
  ip netns exec fw-b iptables -A INPUT -p icmp -j DROP
  echo "-- ping after iptables DROP (expect FAIL) --"
  if ip netns exec fw-a ping -c 2 -W 2 10.200.2.2; then
    echo "WARN: ping still succeeded"
  else
    echo "OK: ICMP dropped as expected"
  fi
  ip netns exec fw-b iptables -L INPUT -n -v || true
  ip netns exec fw-b iptables -F INPUT || true
fi

echo "Observation: counters / drop behavior show policy enforcement on the datapath."
echo "=== END iptables/nftables ==="
