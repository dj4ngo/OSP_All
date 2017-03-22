#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/post_deploy-pcs_cluster_restart.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)
my_node_index=$(cat /var/log/ospd/node_index)
max_ctrl_delay=180

#
case "${my_node_role}${my_node_index}" in
        "CTRL0")
		echo "Doing PCS-specific restarts on Controller0..."
		#pcs cluster stop --all
		#pcs cluster start --all
	;;
esac

# Wait some time as to avoid taking all services down on all controllers at the same time
case "${my_node_role}${my_node_index}" in
        "CTRL0")
		/usr/bin/systemctl mask openstack-nova-compute
		local_delay=$((${max_ctrl_delay} * ${my_node_index}))
		echo "Waiting for ${local_delay} secs on Controller0..."
		sleep ${local_delay}
		sleep $(($(od -A n -t d -N 3 /dev/urandom) % 60))
	;;
        "CTRL1")
		/usr/bin/systemctl mask openstack-nova-compute
		local_delay=$((${max_ctrl_delay} * ${my_node_index}))
		echo "Waiting for ${local_delay} secs on Controller1..."
		sleep ${local_delay}
		sleep $(($(od -A n -t d -N 3 /dev/urandom) % 60))
	;;
        "CTRL2")
		/usr/bin/systemctl mask openstack-nova-compute
		local_delay=$((${max_ctrl_delay} * ${my_node_index}))
		echo "Waiting for ${local_delay} secs on Controller0..."
		sleep ${local_delay}
	;;
esac

# Restart services...
case ${my_node_role} in
	CTRL)
		echo "Doing Controller-specific restarts..."
		systemctl restart neutron-dhcp-agent neutron-l3-agent neutron-metadata-agent neutron-openvswitch-agent
		systemctl restart openstack-\*
		systemctl restart httpd
	;;
        CMPT)
		echo "Doing Compute-specific restarts..."
		sleep $(($(od -A n -t d -N 3 /dev/urandom) % 120))
		systemctl restart neutron-openvswitch-agent.service
		sleep $(($(od -A n -t d -N 3 /dev/urandom) % 120))
		systemctl restart openstack-\*
	;;
        CEPH)
		echo "Doing Ceph-specific restarts..."
		sleep $(($(od -A n -t d -N 3 /dev/urandom) % 120))
		systemctl restart openstack-\*
	;;
esac

# One for the road...
case "${my_node_role}${my_node_index}" in
        "CTRL0")
		echo "Doing PCS-specific restarts on Controller0..."
		sleep 30
		pcs resource cleanup #--force
	;;
esac
