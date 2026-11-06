// Minimal XDP sketch for reading — DO NOT attach on a shared NIC in this lab.
// On a dedicated Linux lab NIC you could build with:
//   clang -O2 -g -target bpf -c xdp_drop_sketch.c -o xdp_drop_sketch.o
//   ip link set dev eth0 xdp obj xdp_drop_sketch.o sec xdp
// Then detach: ip link set dev eth0 xdp off

#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

SEC("xdp")
int xdp_pass_all(struct xdp_md *ctx) {
    // XDP_PASS continues the normal stack; XDP_DROP would blackhole.
    // We keep PASS here so the sketch is safe to contemplate.
    return XDP_PASS;
}

char LICENSE[] SEC("license") = "GPL";
