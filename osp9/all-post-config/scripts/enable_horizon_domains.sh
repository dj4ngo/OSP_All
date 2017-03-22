#!/bin/bash
# Modify Horizon configuration to enable domain support
# 
set -x ; VLOG=/var/log/ospd/post_deploy-enable_horizon_domains.log ; exec &> >(tee -a "${VLOG}")

myhostname=$(hostname -s)
case ${myhostname} in
        *-cmpt-*|*-compute-*)
		echo "Not a controller. Exit!"
		exit 0
	;;
        instack|*-ctrl-*|*-controller-*)
		echo "Controller detected, continuing..."
	;;
	*)
		echo "Not a controller. Exit!"
		exit 0
	;;
esac


if [ -f /etc/openstack-dashboard/local_settings ]; then

        grep -q '^OPENSTACK_API_VERSIONS' /etc/openstack-dashboard/local_settings
	if [ $? -ne 0 ]; then
		# Search string wasn't found, edit..
		echo "Editing /etc/openstack-dashboard/local_settings and adding OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT..."
cat >>/etc/openstack-dashboard/local_settings <<EOF
OPENSTACK_API_VERSIONS = {
    "identity": 3
}
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'
EOF

	else
		echo "/etc/openstack-dashboard/local_settings already edited, skipping..."
		exit 0
	fi
fi
