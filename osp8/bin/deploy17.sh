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
time openstack overcloud deploy \
--templates ${TOP_DIR}/templates \
--control-scale 3 \
--compute-scale 1 \
--ceph-storage-scale 3 \
--swift-storage-scale 0 \
--control-flavor control \
--compute-flavor compute \
--ceph-storage-flavor ceph-storage \
--swift-storage-flavor swift-storage \
--ntp-server '10.20.0.1", "10.20.0.2' \
--validation-errors-fatal \
-e ${TOP_DIR}/templates/overcloud-resource-registry-puppet.yaml \
-e ${TOP_DIR}/templates/environments/network-isolation.yaml \
-e ${TOP_DIR}/templates/environments/storage-environment.yaml \
-e ${TOP_DIR}/net-bond-with-vlans-with-nic4.yaml \
-e ${TOP_DIR}/rhel-registration-environment.yaml \
-e ${TOP_DIR}/storage-environment.yaml \
-e ${TOP_DIR}/krynn-environment.yaml \
-e ${TOP_DIR}/extraconfig-environment.yaml \
-e ${TOP_DIR}/enable-tls.yaml \
-e ${TOP_DIR}/inject-trust-anchor.yaml \
-e ${TOP_DIR}/local-environment.yaml
