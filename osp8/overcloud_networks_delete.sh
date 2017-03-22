#!/bin/bash
if [ "x$(id -n -u)" = "xstack" ]; then
	if [ -f $HOME/overcloudrc ]; then
		. $HOME/overcloudrc
	else
		echo "(**) No $HOME/overcloudrc, exit!" ; exit 127
	fi
else
	echo "(**) Not stack, exit!" ; exit 127
fi

#
PROJECT_ID=$(openstack project show internal | awk '/id / {print $4}')
NET_ID=$(openstack network show internal_network|awk '{if ( $2 == "id" ) print $4}')
#
. ~/internalrc
#
nova list|grep novavm|awk '{ print $2}'|xargs nova delete
sleep 60
#
neutron router-interface-delete int_router1 ${NET_ID}
neutron router-delete int_router1
neutron subnet-delete internal_subnet
neutron net-delete internal_network
neutron floatingip-list --format value|awk '{ print $1}' |xargs -n1 neutron floatingip-delete
. ~/overcloudrc
neutron subnet-delete external_subnet
neutron net-delete external_network
nova flavor-delete m1.micro
glance image-delete cirros
keystone tenant-delete internal
keystone user-delete internal
