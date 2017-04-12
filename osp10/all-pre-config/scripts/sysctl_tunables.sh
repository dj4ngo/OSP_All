#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/pre_deploy-sysctl_tunables.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

cat > /etc/sysctl.d/99-local-tuning.conf << EOF
# free the console from unimportant messages
kernel.printk = 3 4 1 3

# FS tuning
fs.file-max = 8388608
fs.aio-max-nr = 1048576
# fix for tail -f: no space left on device: WARNING, over 512k breaks vmware-hostd
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024

# Network tuning:
net.ipv4.tcp_low_latency = 0
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 0
# Pages
net.ipv4.udp_mem = 65536 131072 262144
net.ipv4.tcp_mem = 65536 131072 262144
# Bytes
net.ipv4.tcp_rmem = 16384 873800 33554432
net.ipv4.tcp_wmem = 16384 655360 33554432
net.core.netdev_max_backlog = 262144
net.core.optmem_max = 33554432
net.core.rmem_max = 67108864
net.core.wmem_max = 33554432
net.core.rmem_default = 67108864
net.core.wmem_default = 33554432
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.igmp_max_memberships = 128
net.ipv4.udp_rmem_min = 65536
net.ipv4.udp_wmem_min = 65536
net.core.somaxconn = 32768
net.core.netdev_budget = 1200

# increase the length of the processor input queue
sunrpc.tcp_slot_table_entries = 512
sunrpc.udp_slot_table_entries = 512

# Increase size of RPC datagram queue length
net.unix.max_dgram_qlen = 512

# avoid deleting secondary IPs on deleting the primary IP
net.ipv4.conf.default.promote_secondaries = 1
net.ipv4.conf.all.promote_secondaries = 1

# Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1

# Limit number of orphans, each orphan can eat up to 16M (max wmem) of unswappable memory
net.ipv4.tcp_max_orphans = 16384
net.ipv4.tcp_orphan_retries = 0

# Defaults to 60:
vm.swappiness = 0

EOF

#
case ${my_node_role} in
	*)
		if [ -f /etc/sysctl.d/99-local-tuning.conf  ]; then
			/sbin/sysctl --system
		fi
  ;;
esac
