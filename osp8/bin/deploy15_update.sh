#!/bin/bash
#
#
[ "$BASH" ] && function whence
{
	type -p "$@"
}
#
export PATH_SCRIPT="$(cd $(/usr/bin/dirname $(whence -- $0 || echo $0));pwd)"
export TOP_DIR="$(cd ${PATH_SCRIPT}/..; pwd)"

source ${TOP_DIR}/pre_deploy.sh || exit 127
set -x
yes "" | openstack overcloud update stack \
-i overcloud \
--templates ${TOP_DIR}/templates \
-e ${TOP_DIR}/templates/overcloud-resource-registry-puppet.yaml \
-e ${TOP_DIR}/templates/environments/network-isolation.yaml \
-e ${TOP_DIR}/templates/environments/storage-environment.yaml \
-e ${TOP_DIR}/net-bond-with-vlans-with-nic4.yaml \
-e ${TOP_DIR}/rhel-registration-environment.yaml \
-e ${TOP_DIR}/storage-environment.yaml \
-e ${TOP_DIR}/krynn-environment.yaml \
-e ${TOP_DIR}/extraconfig-environment.yaml \
-e ${TOP_DIR}/local-environment.yaml
