#!/bin/bash
#
set -x ; l=firstboot-tuned_profile ; VLOG=/var/log/ospd/${l%\.sh}.log ; exec &> >(tee -a "${VLOG}")

HYPERVISORS=0

#
if [ -x /usr/sbin/virt-what ]; then
	HYPERVISORS=$(/usr/sbin/virt-what|egrep '(kvm|virtualbox)'|wc -l)
fi

# If running on virtual H/W, proceed
if [ ${HYPERVISORS} -ge 1 ]; then
	echo "Virtualized Environment detected, proceeding..."

	# Setup perf profile
	case "$(hostname)" in
	*-ctrl*-|*-controller*-)
		#/usr/sbin/tuned-adm profile latency-performance
		/usr/sbin/tuned-adm profile virtual-guest
		;;
	*-ceph*-)
		#/usr/sbin/tuned-adm profile throughput-performance
		/usr/sbin/tuned-adm profile virtual-guest
		;;
	*-cmpt*-|*-compute*-)
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
