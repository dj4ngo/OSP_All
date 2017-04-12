#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/post_deploy-pcs_cluster_restart.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)
my_node_index=$(cat /var/log/ospd/node_index)
max_ctrl_delay=180

#
case "${my_node_role}${my_node_index}" in
        "CTRL0")
		echo "Doing PCS-specific cluster-wide restarts from Controller0..."
		#pcs cluster stop --all
		#pcs cluster start --all
		pcs resource restart rabbitmq-clone
		# Give time to rabbitmq to settle...
		sleep 90
	;;
esac

# Wait some time as to avoid taking all services down on all controllers at the same time
case ${my_node_role} in
	CTRL)
	;;
esac

# Restart services...
case ${my_node_role} in
	CTRL)
		local_delay=$((${max_ctrl_delay} * ${my_node_index}))
		echo "Waiting for ${local_delay} secs on Controller0..."
		sleep ${local_delay}
		echo "Doing Controller-specific restarts..."
		/usr/bin/systemctl mask openstack-nova-compute
		#systemctl restart neutron-server neutron-openvswitch-agent neutron-metadata-agent neutron-l3-agent neutron-dhcp-agent
		systemctl restart neutron-\*
		systemctl restart openstack-\*
		systemctl restart httpd
	;;
	CMPT)
		echo "Doing Compute-specific restarts..."
		sleep $(($(od -A n -t d -N 3 /dev/urandom) % 60))
		systemctl restart neutron-\*
		sleep $(($(od -A n -t d -N 3 /dev/urandom) % 60))
		systemctl restart openstack-\*
	;;
	CEPH)
		echo "Doing Ceph-specific restarts..."
		sleep $(($(od -A n -t d -N 3 /dev/urandom) % 60))
		systemctl restart openstack-\*
	;;
esac

# First pass of cleanups...
case "${my_node_role}${my_node_index}" in
        "CTRL0")
		echo "Doing PCS-specific cluster-wide cleanups from Controller0..."
		sleep 30
		pcs resource cleanup #--force
	;;
esac

# Last cleanup before stage...
case ${my_node_role} in
	*)
		TO_RESTART=$(systemctl --failed|awk '{ if (( $2 ~ /openstack/ ) || ($2 ~ /neutron/)) { print $2 } } '|xargs)
		if [ "x${TO_RESTART}" != "x" ]; then
			systemctl restart ${TO_RESTART}
		fi
	;;
esac
