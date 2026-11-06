# linux-networking-lab

Hands-on notes and demos for **Linux isolation & networking primitives** that distributed systems actually sit on: namespaces, cgroups, iptables/nftables, and a light touch of eBPF.

> **Target audience:** engineers aiming at Distributed Systems / infra roles (fal-style).  
> **Host caveat:** Umut’s laptop is **macOS**. Real cgroups v2, network namespaces, nftables, and eBPF need a **Linux kernel**. On Mac we run demos inside a privileged Ubuntu container via Docker Desktop.

## What you learn

| Topic | Why it matters in DS |
|-------|----------------------|
| Namespaces | Pod/container isolation; “same PID 1, different view of the machine” |
| cgroups | CPU/mem/IO limits → noisy-neighbor control, autoscaling signals |
| iptables/nftables | Service mesh datapath ancestors; kube-proxy, CNI, egress policy |
| eBPF | Modern observability + policy without rewriting the kernel |

## Repo layout

```
notes/          # engineer-facing explainers (ne / neden / nasıl / ne görürsün)
demos/          # shell demos + Dockerfile (Linux-only)
Makefile        # make demo-* shortcuts
```

## Prerequisites

- Docker Desktop (or any Docker engine that can run Linux containers)
- ~1 GB disk for the lab image
- Willingness to use `--privileged` **only for local learning** (see Security)

```bash
# from this repo
make image          # build lab image
make demo-all       # run all demos in one privileged container
# or individually:
make demo-netns
make demo-cgroup
make demo-firewall
make demo-ebpf
```

### Mac vs Linux

| Capability | macOS host | Linux host / Docker Linux VM |
|------------|------------|------------------------------|
| `unshare`, `ip netns` | No (or incomplete) | Yes |
| cgroups v2 controllers | No | Yes (`/sys/fs/cgroup`) |
| iptables / nftables | No kernel tables | Yes |
| eBPF / bpftrace / bcc | No | Yes (needs kernel headers + CAP_BPF/privileged) |

On Mac, **always** go through `make demo-*`. See `notes/mac-vs-linux.md`.

## Security warning

Demos use `docker run --privileged` so they can create namespaces, mount cgroupfs, load bpf, and poke netfilter. That gives the container near-host kernel power **inside Docker Desktop’s Linux VM**.

- Do **not** run these scripts on a shared prod host.
- Do **not** expose the container’s network to untrusted traffic.
- Tear down with `docker rm -f` when done; do not leave privileged shells open.

## Quick start (one shot)

```bash
git clone https://github.com/uabali/linux-networking-lab.git
cd linux-networking-lab
make image
make demo-all
```

Expected: each demo prints a clear `=== BEGIN/END ===` section with commands, observations, and cleanup.

## License

MIT — learning material. Use at your own risk.
