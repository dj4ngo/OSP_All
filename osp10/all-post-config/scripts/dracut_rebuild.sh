#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/post_deploy-dracut_rebuild.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

#
if [ -x /usr/sbin/virt-what ]; then
	HYPERVISORS=$(/usr/sbin/virt-what|egrep '(kvm|virtualbox)'|wc -l)
fi

# If running on virtual H/W, proceed
if [ ${HYPERVISORS} -ge 1 ]; then
	echo "Virtualized Environment detected, proceeding..."

	#
	case ${my_node_role} in
		*)
			echo "Removing microcode_ctrl and rebuilding dracut images..."
			rpm -e microcode_ctl
			/sbin/dracut -f --regenerate-all
		;;
	esac
else
	echo "Baremetal Environment detected, not removing microcode_ctl..."
fi

