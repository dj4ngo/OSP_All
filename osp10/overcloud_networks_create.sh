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
neutron net-create external_network --provider:network_type flat --provider:physical_network external  --router:external
if [ -f ${HOME}/make_extnet.sh ]; then
	/bin/bash ${HOME}/make_extnet.sh
fi

#
openstack project create --description 'internal tenant' --enable internal
openstack user create  --project internal --password internal --email vincent@cojot.name --enable internal

openstack flavor create --public --vcpus 1 --rxtx-factor 1 --ram 64 --id 99 --property hw:cpu_policy=shared m1.micro
#
glance image-create --name "cirros" --disk-format qcow2 --container-format bare --is-public True --file ${HOME}/OSP/cirros-0.3.4-x86_64-disk.img

#
PROJECT_ID=$(openstack project show internal | awk '/id / {print $4}')
#
cat ${HOME}/overcloudrc |sed \
	-e 's/OS_USERNAME=.*/OS_USERNAME=internal/' \
	-e 's/OS_TENANT_NAME=.*/OS_TENANT_NAME=internal/' \
	-e 's/OS_PASSWORD=.*/OS_PASSWORD=internal/' > ${HOME}/internalrc
numc=$(neutron agent-list -f value -c binary|grep -c neutron-l3-agent)
. ${HOME}/internalrc

case ${numc} in
	3|1|0)
		neutron router-create int_router1 --tenant_id ${PROJECT_ID}
		;;
esac

neutron router-gateway-set int_router1 external_network --tenant_id ${PROJECT_ID}
#
#neutron net-create internal_network --provider:network_type vxlan --tenant_id ${PROJECT_ID} 
neutron net-create internal_network --tenant_id ${PROJECT_ID} 
neutron subnet-create --name internal_subnet --enable_dhcp=True \
	--tenant_id ${PROJECT_ID} \
	internal_network 10.20.30.0/24
#
NET_ID=$(openstack network show internal_network|awk '{if ( $2 == "id" ) print $4}')
#
neutron router-interface-add int_router1 internal_subnet --tenant_id ${PROJECT_ID}
for i in {1..8}; do neutron floatingip-create external_network --tenant_id ${PROJECT_ID}; done 
#
#nova boot novavm --flavor m1.micro --image "cirros" --nic net-id=${NET_ID} --min-count 4
