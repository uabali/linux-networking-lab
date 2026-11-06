# Mac vs Linux — why this lab uses Docker

## Ne

macOS is a BSD-derived kernel (XNU). It has *some* isolation ideas (sandbox, jails-ish, containers via lightweight VMs), but **not** the Linux ABI for:

- mount / UTS / IPC / PID / net / user **namespaces** as Linux defines them
- **cgroups** (v1 or v2)
- **netfilter** (iptables/nftables)
- **eBPF** maps, programs, XDP, kprobes as on Linux

Docker Desktop on Mac runs a **Linux VM**. When you `docker run --platform linux/amd64` (or arm64) an Ubuntu image with `--privileged`, demos talk to **that VM’s Linux kernel**, not Darwin.

## Neden

Distributed Systems interviews and production Kubernetes assume Linux. Practicing `ip netns` on Darwin teaches the wrong mental model (or fails outright).

## Nasıl dene

```bash
# On Mac — this will fail or be meaningless:
unshare --net /bin/bash          # typically: command not found
ls /sys/fs/cgroup                # empty or missing controllers
sudo nft list ruleset            # nft not a Darwin thing

# Correct path on Mac:
make demo-netns                  # Linux container
```

## Ne görürsün

- Host Mac: tools missing or no-ops.
- Inside lab container: full `/proc`, `/sys/fs/cgroup`, `ip netns`, `nft`, and (with privileged) bpf tools.

## Rule of thumb

| Goal | Where to run |
|------|----------------|
| Read notes | Anywhere |
| Run demos | `make demo-*` (Linux container) |
| Prod debugging | Real Linux node / cloud VM |
