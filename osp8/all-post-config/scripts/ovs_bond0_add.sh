#!/bin/bash
#### Created Eric Sallie 11/07/2016
# Script required to add bond0 to br-int OVS bridge
#
set -x ; VLOG=/var/log/ospd/post_deploy-ovs_add_bond0.log ; exec &> >(tee -a "${VLOG}")

# initial config
/bin/ovs-vsctl show

# Add bond0 interface to OVS bridge
if [ -d /sys/class/net/bond0 ]; then
	echo "Adding bond0 to br-int.."
	/bin/ovs-vsctl add-port br-int bond0

	# post config
	/bin/ovs-vsctl show
else
	echo "No bond0 present, skipping..."
fi
