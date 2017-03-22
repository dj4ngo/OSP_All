#!/bin/bash
#
set -x ; l=post_deploy-pcs_cluster_restart ; VLOG=/var/log/ospd/${l%\.sh}.log ; exec &> >(tee -a "${VLOG}")

#
myhostname=$(hostname -s)
case ${myhostname} in
        *-ctrl-0|*-controller-0)
                echo "Doing Controller0-Specific configuration..."
		pcs resource restart openstack-keystone-clone
		# Give it some time to settle
		sleep 60
		pcs resource restart httpd-clone
		# Wait up to 240 secs (5m)
		sleep 240
		pcs resource cleanup --force
	;;
	*)
		echo "Not Controller0, skipping..."
	;;
esac
