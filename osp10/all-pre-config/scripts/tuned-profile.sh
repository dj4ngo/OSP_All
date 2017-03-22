#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-tuned_profile.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

HYPERVISORS=0

#
if [ -x /usr/sbin/virt-what ]; then
	HYPERVISORS=$(/usr/sbin/virt-what|egrep '(kvm|virtualbox)'|wc -l)
fi

# If running on virtual H/W, proceed
if [ ${HYPERVISORS} -ge 1 ]; then
	echo "Virtualized Environment detected, proceeding..."

	# Setup perf profile
	case ${my_node_role} in
	CTRL)
		#/usr/sbin/tuned-adm profile latency-performance
		/usr/sbin/tuned-adm profile virtual-guest
		;;
	CEPH)
		#/usr/sbin/tuned-adm profile throughput-performance
		/usr/sbin/tuned-adm profile virtual-guest
		;;
	CMPT)
		#/usr/sbin/tuned-adm profile throughput-performance
		/usr/sbin/tuned-adm profile virtual-guest
		;;
	*)
		#/usr/sbin/tuned-adm profile network-latency
		/usr/sbin/tuned-adm profile virtual-guest
		;;
	esac
else
	echo "Baremetal Environment detected, not changing tuned profile..."
fi
