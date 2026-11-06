# eBPF (light touch)

## Ne

**eBPF** lets you run sandboxed programs **in the kernel** at safe hook points:

- kprobes / tracepoints (observability)
- XDP (earliest RX path — DDoS, load-balance)
- tc / cgroup skb (network policy)
- sockops / sockmap (acceleration)
- LSM hooks (security)

Userland loads bytecode via `bpf()`; verifier guarantees bounded execution. Maps share state with user space (counters, LRU hashes, ring buffers).

High-level tools:

| Tool | Role |
|------|------|
| `bpftrace` | One-liners / scripts (DTrace-like) |
| BCC | Python/C helpers for custom tools |
| `bpftool` | Inspect programs & maps |
| Cilium / pwru | Production networking + debug |

## Neden

- **Observability without sidecars:** see syscalls, TCP RTTs, dropped packets with low overhead.
- **Policy datapath:** Cilium identity-aware rules bypass mega-iptables.
- **Performance:** XDP can drop/redirect before sk_buff allocation.

For DS interviews: “Why did kube-proxy eBPF / Cilium beat iptables at scale?” → constant-time maps vs O(n) rule lists, atomic updates, richer context.

## Nasıl dene

```bash
make demo-ebpf
```

What the demo tries (best-effort inside Docker Desktop):

1. Check kernel BTF / `bpf` syscall availability.
2. Run a **bpftrace one-liner** if present: count `tracepoint:syscalls:sys_enter_openat` for a few seconds.
3. Else run **`bpftool feature`** / show a minimal annotated C sketch under `demos/ebpf/` that would compile with `clang -target bpf` on a full kernel-headers host.
4. Print honest “skipped” reasons if the Docker Desktop kernel lacks BTF or CAP_BPF quirks bite.

This is intentionally a **touch**, not a Cilium course.

## Ne görürsün

Happy path:

```
Attaching 1 probe...
@[...] ... counts of openat ...
```

Or:

```
[skip] bpftrace unavailable — showing static example + bpftool feature probe
```

Both are valid learning outcomes: knowing **when eBPF cannot load** is part of the skill.

## Minimal mental sketch (XDP drop)

```c
SEC("xdp")
int xdp_drop_all(struct xdp_md *ctx) {
    return XDP_DROP; // never do this on a real NIC
}
```

Load with `ip link set dev eth0 xdp obj drop.o sec xdp` on real Linux. In this lab we **do not** attach XDP to a shared Docker NIC (too easy to lock yourself out of the container network).

## Gotchas

- Needs recent kernel + often `CONFIG_DEBUG_INFO_BTF`.
- Docker Desktop kernels vary by version — demos degrade gracefully.
- Privileged ≠ always enough; some setups need `/sys/kernel/btf/vmlinux`.
- Writing production eBPF is a discipline (verifier, CO-RE, maps) — treat this note as the doorway.
