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
if [ -f ${HOME}/internalrc ]; then
	. ${HOME}/internalrc
fi
#
#
# Cleanup VMs
VM_LIST=$(nova list|grep novavm|awk '{ print $2}'|xargs)
if [ "x${VM_LIST}" != "x" ]; then
	echo ${VM_LIST}|xargs nova delete
fi

neutron router-interface-delete int_router1 internal_subnet
neutron router-interface-delete int_router1 external_subnet
neutron router-delete int_router1
for mynet in external_subnet internal_subnet
do
	SUBNET_ID=$(openstack subnet show ${mynet} -c id -f value)
	if [ "x${SUBNET_ID}" != "x" ]; then
		PORT_LIST=$(openstack port list -f value|grep ${NET_ID}|awk '{print $1}')
		if [ "x${PORT_LIST}" != "x" ]; then
			for myport in ${PORT_LIST}
			do
				openstack port delete $myport
			done
		fi
	fi
done
neutron subnet-delete internal_subnet
neutron net-delete internal_network
FLOAT_LIST=$(neutron floatingip-list --format value|awk '{ print $1}')
if [ "x${FLOAT_LIST}" != "x" ]; then
	echo ${FLOAT_LIST}|xargs -n1 neutron floatingip-delete
fi
. ${HOME}/overcloudrc
neutron subnet-delete external_subnet
neutron net-delete external_network
nova flavor-delete m1.micro
glance image-delete cirros
openstack project delete internal
openstack user delete internal
rm -fv ${HOME}/internalrc
