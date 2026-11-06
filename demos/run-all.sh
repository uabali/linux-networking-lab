#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "############################################"
echo "# linux-networking-lab — running all demos #"
echo "############################################"
./01-namespaces.sh
echo
./02-cgroups.sh
echo
./03-iptables-nftables.sh
echo
./04-ebpf.sh
echo
echo "All demo sections finished."
