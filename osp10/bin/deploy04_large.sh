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
--templates \
--control-scale 3 \
--compute-scale 2 \
--ceph-storage-scale 5 \
--control-flavor control \
--compute-flavor compute \
--ceph-storage-flavor ceph-storage \
--ntp-server '10.20.0.1", "10.20.0.2' \
--validation-errors-fatal
