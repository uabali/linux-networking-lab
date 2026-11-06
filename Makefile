# Linux networking lab — run demos inside a privileged Ubuntu container.
IMAGE ?= linux-networking-lab:local
DOCKER ?= docker

.PHONY: image shell demo-all demo-netns demo-cgroup demo-firewall demo-ebpf help

help:
	@echo "Targets:"
	@echo "  make image          Build Ubuntu lab image"
	@echo "  make demo-all       Run all demos (privileged)"
	@echo "  make demo-netns     Namespaces + veth ping"
	@echo "  make demo-cgroup    cgroup v2 CPU throttle"
	@echo "  make demo-firewall  nftables/iptables ICMP drop"
	@echo "  make demo-ebpf      bpftrace / bpftool light touch"
	@echo "  make shell          Interactive privileged shell"
	@echo ""
	@echo "macOS: demos MUST go through these targets (Linux kernel required)."

image:
	$(DOCKER) build -t $(IMAGE) -f demos/Dockerfile demos

define RUN
	$(DOCKER) run --rm --privileged --name linux-net-lab \
	  -v "$(CURDIR)/notes:/lab/notes:ro" \
	  -v "$(CURDIR)/demos:/lab/demos:ro" \
	  -w /lab $(IMAGE) bash -lc '$(1)'
endef

demo-all: image
	$(call RUN,demos/run-all.sh)

demo-netns: image
	$(call RUN,demos/01-namespaces.sh)

demo-cgroup: image
	$(call RUN,demos/02-cgroups.sh)

demo-firewall: image
	$(call RUN,demos/03-iptables-nftables.sh)

demo-ebpf: image
	$(call RUN,demos/04-ebpf.sh)

shell: image
	$(DOCKER) run --rm -it --privileged \
	  -v "$(CURDIR)/notes:/lab/notes:ro" \
	  -v "$(CURDIR)/demos:/lab/demos:ro" \
	  -w /lab $(IMAGE) bash
