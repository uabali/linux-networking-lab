# Namespaces

## Ne

A **namespace** partitions a kernel resource so processes see a private instance:

| Namespace | Isolates | Classic demo |
|-----------|----------|--------------|
| `mnt` | Mount table | Bind-mount `/tmp` privately |
| `uts` | Hostname / NIS domain | `hostname lab` without changing host |
| `ipc` | SysV / POSIX IPC | Private message queues |
| `pid` | Process IDs | Nested PID 1 |
| `net` | Network stack | Own interfaces, routes, iptables |
| `user` | UIDs/GIDs mapping | Root inside, unprivileged outside |
| `cgroup` | cgroup root view | Hide parent hierarchy |
| `time` | Clock offsets | (newer kernels) |

Containers ≈ “bundle of namespaces + cgroups + rootfs”. Kubernetes pods share the **net** namespace among containers in the pod.

## Neden (DS lens)

- **Multi-tenant safety:** tenant A’s traffic does not bind tenant B’s ports.
- **Blast radius:** a runaway process in a netns cannot see host routes unless you deliberately join them.
- **Debuggability:** `nsenter` into a pod’s netns is how you `tcpdump` “from inside the pod”.
- **Service mesh / CNI:** veth pairs + netns are the plumbing under Calico/Cilium/Flannel.

Mental model:

```
Host netns                    Pod netns
┌──────────────────┐         ┌──────────────────┐
│ eth0 10.0.0.5    │◄─veth─►│ eth0 10.244.1.7 │
│ docker0 / cni0   │         │ lo               │
└──────────────────┘         └──────────────────┘
```

## Nasıl dene

```bash
make demo-netns
# or inside the lab container:
./demos/01-namespaces.sh
```

Script creates two netns (`red`, `blue`), a veth pair, assigns IPs, pings across, then tears down.

Manual sketch (Linux):

```bash
ip netns add red
ip netns add blue
ip link add veth-red type veth peer name veth-blue
ip link set veth-red netns red
ip link set veth-blue netns blue
ip -n red addr add 10.200.1.1/24 dev veth-red
ip -n blue addr add 10.200.1.2/24 dev veth-blue
ip -n red link set veth-red up
ip -n blue link set veth-blue up
ip -n red link set lo up
ip -n blue link set lo up
ip netns exec red ping -c 2 10.200.1.2
```

## Ne görürsün

- `ip netns exec red ip addr` shows only `lo` + `veth-red` — host `eth0` is invisible.
- Ping red→blue succeeds; without routes/NAT, neither reaches the internet unless you add forwarding.
- `ss -lntp` in red does **not** show host listeners.

## Gotchas

- Creating netns needs `CAP_SYS_ADMIN` (hence privileged lab).
- Forgetting `lo up` breaks many local RPC assumptions.
- User namespaces change the security story a lot — root in userns ≠ host root.
