#!/bin/bash
set -uf -o pipefail

if [ "x$(id -n -u)" = "xstack" ]; then
	if [ -f ${HOME}/overcloudrc ]; then
		. ${HOME}/overcloudrc
	else
		echo "(**) No ${HOME}/overcloudrc, exit!" ; exit 127
	fi
else
	echo "(**) Not stack, exit!" ; exit 127
fi

#
PROJECT_ID=$(openstack project show internal | awk '/id / {print $4}')
NET_ID=$(openstack network show internal_network|awk '{if ( $2 == "id" ) print $4}')
#
#
#
# Cleanup VMs
VM_LIST=$(nova list --all|grep novavm|awk '{ print $2}'|xargs)
if [ "x${VM_LIST}" != "x" ]; then
	echo ${VM_LIST}|xargs nova delete
fi
