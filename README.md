# linux-networking-lab

Notes and demos for Linux isolation and networking: namespaces, cgroups, iptables/nftables, and a light eBPF pass.

**Host note:** on macOS, demos run inside a privileged Ubuntu container (real cgroups v2 / netns / nft / eBPF need a Linux kernel).

## Layout

```
notes/          # explainers
demos/          # shell demos + Dockerfile
Makefile        # make demo-* shortcuts
```

## Topics

| Topic | Role |
|-------|------|
| Namespaces | Process / net / mount isolation (container view of the machine) |
| cgroups | CPU / mem / IO limits |
| iptables / nftables | Packet filter and NAT datapath |
| eBPF | Kernel observability / policy without rewriting the kernel |

## Prerequisites

- Docker (Linux containers)
- ~1 GB for the lab image

```bash
make image
make demo-all
# or:
make demo-netns
make demo-cgroup
make demo-firewall
make demo-ebpf
```

### Mac vs Linux

| Capability | macOS host | Linux host / Docker Linux VM |
|------------|------------|------------------------------|
| `unshare`, `ip netns` | No | Yes |
| cgroups v2 | No | Yes (`/sys/fs/cgroup`) |
| iptables / nftables | No | Yes |
| eBPF / bpftrace / bcc | No | Yes |

On Mac use `make demo-*`. Details: `notes/mac-vs-linux.md`.

## Security

Demos use `docker run --privileged` (namespaces, cgroupfs, bpf, netfilter).

- Do not run on a shared prod host.
- Do not expose the container to untrusted traffic.
- Tear down with `docker rm -f` when done.

## Quick start

```bash
git clone https://github.com/uabali/linux-networking-lab.git
cd linux-networking-lab
make image
make demo-all
```

Each demo prints `=== BEGIN/END ===` with commands, observations, and cleanup.

## License

MIT
