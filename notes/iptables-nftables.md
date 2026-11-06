# iptables & nftables

## Ne

**Netfilter** is the Linux packet filtering framework. Two userland frontends:

| Tool | Era | Backend |
|------|-----|---------|
| `iptables` | Classic | xtables (still widely deployed; kube-proxy iptables mode) |
| `nftables` | Modern | `nf_tables` — single VM-ish ruleset, better atomic updates |

Both attach hooks at: prerouting → input / forward → output → postrouting (plus mangle/nat/raw tables historically).

Minimal mental model for a node:

```
packet in → PREROUTING (DNAT) → routing decision
          → INPUT (local process)  or  FORWARD (through the box)
          → OUTPUT (locally generated)
          → POSTROUTING (SNAT/MASQUERADE)
```

## Neden (DS lens)

- **kube-proxy iptables mode** rewrites ClusterIP → PodIP with thousands of rules (scales poorly → IPVS / eBPF alternatives).
- **CNI / NetworkPolicy** implementations historically leaned on iptables; Cilium moved many to eBPF.
- **Egress control & NAT** for containers: masquerade when leaving the host.
- Debugging “service unreachable” often starts with `iptables-save` / `nft list ruleset`.

## Nasıl dene

```bash
make demo-firewall
```

Demo flow:

1. Show empty/baseline nft ruleset (or iptables filter table).
2. Add a chain that **drops** ICMP to a dummy IP *inside a netns* (so we don’t brick the lab container’s SSH-less shell carelessly).
3. Ping before/after; restore.

Prefer **nft** when available; fall back to iptables.

## Ne görürsün

- Before rule: ping succeeds across veth.
- After drop rule on input path: ping fails with 100% loss.
- `nft list ruleset` shows the chain counters incrementing.

## iptables vs nft — when to care

- Greenfield scripts: prefer **nftables**.
- Reading old K8s nodes / docs: still speak **iptables**.
- Mixing both on one host is possible but confusing — pick one for lab demos.

## Gotchas

- Order matters; first matching rule wins in many chains.
- Docker and K8s inject rules dynamically — `DOCKER` / `KUBE-SERVICES` chains.
- Flushing `iptables -F` on a prod node is a classic outage story. Lab only.
