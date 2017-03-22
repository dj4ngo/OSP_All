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
export TRIPLEO_DIR="/usr/share/openstack-tripleo-heat-templates"

source ${TOP_DIR}/pre_deploy.sh || exit 127
set -x
time openstack overcloud deploy \
--templates \
--control-scale 3 \
--compute-scale 2 \
--ceph-storage-scale 5 \
--swift-storage-scale 0 \
--control-flavor control \
--compute-flavor compute \
--ceph-storage-flavor ceph-storage \
--swift-storage-flavor swift-storage \
--ntp-server '10.20.0.1", "10.20.0.2' \
--validation-errors-fatal \
-e ${TRIPLEO_DIR}/environments/network-isolation.yaml \
-e ${TRIPLEO_DIR}/environments/storage-environment.yaml \
-e ${TOP_DIR}/net-bond-with-vlans-with-nic4.yaml \
-e ${TOP_DIR}/rhel-registration-environment.yaml \
-e ${TOP_DIR}/storage-environment.yaml \
-e ${TOP_DIR}/krynn-environment.yaml \
-e ${TOP_DIR}/extraconfig-environment.yaml \
-e ${TOP_DIR}/local-environment.yaml
