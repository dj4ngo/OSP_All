#!/bin/bash
set -euf -o pipefail

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
NET_ID=$(openstack network show internal_network|awk '{if ( $2 == "id" ) print $4}')
#
if [ -f ${HOME}/internalrc ]; then
	. ${HOME}/internalrc
fi
nova boot novavm --flavor m1.micro --image "cirros" --nic net-id=${NET_ID} --min-count 8
