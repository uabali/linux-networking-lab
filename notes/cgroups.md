# cgroups (control groups)

## Ne

**cgroups** limit and account for resource use of a process tree.

- **v1:** multiple hierarchies, one controller per mount (legacy).
- **v2:** single unified hierarchy under `/sys/fs/cgroup` (what modern K8s wants).

Key v2 controllers for DS work:

| Controller | File(s) | Effect |
|------------|---------|--------|
| `cpu` | `cpu.max` | Quota / period (e.g. `50000 100000` = 50% of one CPU) |
| `memory` | `memory.max` | Hard memory cap; OOM-kill inside the cgroup |
| `io` | `io.max` | Disk bandwidth / IOPS caps |
| `pids` | `pids.max` | Fork-bomb brake |

A **container runtime** (containerd, CRI-O) creates a cgroup per container and puts the process there before `exec`.

## Neden

Without cgroups:

- One noisy neighbor pegs all CPUs → latency spikes for everyone on the node.
- Memory leak → host OOM killer may shoot *innocent* processes.
- Autoscalers and HPA need **signals** (throttling, working set) that come from cgroup accounting.

Interview hook: “How does K8s enforce `resources.limits.cpu`?” → cgroup `cpu.max` (CFS quota).

## Nasıl dene

```bash
make demo-cgroup
```

The demo:

1. Detects cgroup v2.
2. Creates a child cgroup under the container’s own cgroup (delegated).
3. Sets a tight `cpu.max`.
4. Runs a busy loop **inside** that cgroup vs **outside**.
5. Shows `cpu.stat` throttling counters.

## Ne görürsün

- Outside: loop burns ~100% of an available CPU.
- Inside quota: `nr_throttled` and `throttled_usec` climb; wall-clock work slows.
- `memory.current` rises if you allocate; hitting `memory.max` triggers OOM in-cgroup.

## Gotchas

- On Docker Desktop, you are already *inside* a cgroup. You can only create children if the parent delegates controllers (`cgroup.subtree_control`).
- Privileged helps, but **delegation** is the real requirement for nested cgroups.
- v1 vs v2 file layouts differ — always check `stat -fc %T /sys/fs/cgroup` (expect `cgroup2fs`).
