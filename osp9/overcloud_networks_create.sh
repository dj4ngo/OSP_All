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
neutron net-create external_network --provider:network_type flat --provider:physical_network external  --router:external
neutron subnet-create --name external_subnet --enable_dhcp=False \
	--allocation-pool=start=10.0.130.193,end=10.0.130.227 \
	--gateway=10.0.128.254 \
	--dns-nameserver 10.0.128.234 --dns-nameserver 10.0.128.236 \
	external_network 10.0.128.0/22
#
keystone tenant-create --name internal --description "internal tenant" --enabled true
keystone user-create --name internal --tenant internal --pass internal --email vincent@cojot.name --enabled true
nova flavor-create --is-public True m1.micro 99 128 1 1
#
glance image-create --name "cirros" --disk-format qcow2 --container-format bare --is-public True --file ~/cirros-0.3.4-x86_64-disk.img

#
PROJECT_ID=$(openstack project show internal | awk '/id / {print $4}')
#
cat overcloudrc |sed \
	-e 's/OS_USERNAME=.*/OS_USERNAME=internal/' \
	-e 's/OS_TENANT_NAME=.*/OS_TENANT_NAME=internal/' \
	-e 's/OS_PASSWORD=.*/OS_PASSWORD=internal/' > internalrc
. ~/internalrc
#
neutron router-create int_router1 --tenant_id ${PROJECT_ID}
neutron router-gateway-set int_router1 external_network --tenant_id ${PROJECT_ID}
#
#neutron net-create internal_network  --provider:network_type vxlan --tenant_id ${PROJECT_ID} 
neutron net-create internal_network --tenant_id ${PROJECT_ID} 
neutron subnet-create --name internal_subnet --enable_dhcp=True \
	--tenant_id ${PROJECT_ID} \
	internal_network 10.20.30.0/24
#
NET_ID=$(openstack network show internal_network|awk '{if ( $2 == "id" ) print $4}')
#
neutron router-interface-add int_router1 internal_subnet --tenant_id ${PROJECT_ID}
for i in $(seq 1 10); do neutron floatingip-create external_network --tenant_id ${PROJECT_ID}; done 
#
nova boot novavm --flavor m1.micro --image "cirros" --nic net-id=${NET_ID} --num 2
