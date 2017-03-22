#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-diskinit.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

#
case ${my_node_role} in
	*)
		# Remove previously imported lvm structs
		/usr/sbin/dmsetup ls|awk '{ print $1}'|xargs -n1 /usr/sbin/dmsetup remove
		#
		for i in {b,c,d,e,f,g,h,i,j,k,l,m,n}; do
			if [ -b /dev/sd${i} ]; then
				echo "(II) Wiping disk /dev/sd${i}..."
				sgdisk -Z /dev/sd${i}
				sgdisk -g /dev/sd${i}
			else
				echo "(II) not a block device: /dev/sd${i}"
			fi
		done
	;;
esac
