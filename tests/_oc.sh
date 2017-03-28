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

for i in {1..8}
do
	echo -n "Waiting for novavm-${i} to become ACTIVE...."
	until [[ "$(nova show novavm-${i} | awk '/status/ {print $4}')" == "ACTIVE" ]]; do
		echo -n "."
	done
	echo -ne "OK\n"
	myip=$(openstack server list -c Networks -f value --name novavm-${i}|cut -d= -f2|sed -e 's/,.*//')
	myport=$(neutron port-list --fixed_ips ip_address=${myip} -c id -f value)
	myfloat=$(openstack floating ip list -f value -c ID|sed -e "${i}q;d")
	neutron floatingip-associate $myfloat $myport
done
