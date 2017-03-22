#!/bin/bash
set -uf -o pipefail

(cd OSP/osp10; git diff) > OSP_osp10.diff.$(date +%s)

# Cleanup
if [ "x$(id -n -u)" = "xstack" ]; then
	if [ -f ${HOME}/stackrc ]; then
		. ${HOME}/stackrc
	else
		echo "(**) No ${HOME}/overcloudrc, exit!" ; exit 127
	fi
else
	echo "(**) Not stack, exit!" ; exit 127
fi
openstack stack delete --yes --wait overcloud
./OSP/cleanIronic.sh

# Launch the martians
set -e
./OSP/osp10/bin/deploy17_small.sh
echo "Building ansible hosts file.."
./OSP/instack_payload.sh > ${HOME}/hosts

echo "Waiting 30 secs..." && sleep 30
./OSP/osp10/overcloud_networks_create.sh
echo "Waiting 120 secs..." && sleep 120
. ${HOME}/overcloudrc
./_oc.sh
nova list --all
echo "Waiting 120 secs..." && sleep 120
nova list --all
echo "Waiting 30 secs..." && sleep 30
./_od.sh
echo "Waiting 15 secs..." && sleep 15
./_oc.sh
echo "Waiting 60 secs..." && sleep 60
nova list --all --fields id,name,status,OS-EXT-AZ:availability_zone,OS-EXT-SRV-ATTR:host,OS-EXT-SRV-ATTR:instance_name
#nova list --all --fields id,name,OS-EXT-AZ:availability_zone,OS-EXT-SRV-ATTR:host,OS-EXT-SRV-ATTR:instance_name
