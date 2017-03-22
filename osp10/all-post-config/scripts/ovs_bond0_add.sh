#!/bin/bash
#### Created Eric Sallie 11/07/2016
# Script required to add bond0 to br-int OVS bridge
#
set -x ; VLOG=/var/log/ospd/post_deploy-ovs_bond0_add.log ; exec &> >(tee -a "${VLOG}")

# initial config
/bin/ovs-vsctl show

# Add bond0 interface to OVS bridge
if [ -d /sys/class/net/bond0 ]; then
	echo "Adding bond0 to br-int.."
	#### This is DISABLED 20170215 as it is only needed when Cisco ACI is on bond0
	#### /bin/ovs-vsctl add-port br-int bond0

	# post config
	/bin/ovs-vsctl show
else
	echo "Bond bond0 not present, skipping..."
fi
