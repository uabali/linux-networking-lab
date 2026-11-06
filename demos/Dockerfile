# Linux-only lab image for namespace / cgroup / netfilter / light eBPF demos.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    iproute2 iputils-ping net-tools iptables nftables \
    cgroup-tools procps util-linux curl ca-certificates \
    bpftrace bpfcc-tools linux-headers-generic \
    bpftool clang llvm libbpf-dev \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# bpftool package name differs; try common paths later in scripts.
WORKDIR /lab
COPY . /lab/demos/
# notes mounted or copied by compose; keep scripts executable
RUN chmod +x /lab/demos/*.sh || true

CMD ["bash"]
