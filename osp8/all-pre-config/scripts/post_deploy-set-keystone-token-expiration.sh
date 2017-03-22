#!/bin/bash
#
#
# Description - runs post config to set token expiration to allow for large glance uploads.
#
#
# Sample crudini command for reference - "crudini --set --existing config_file section parameter value"

set -x ; l=pre_deploy-set_keystone_expiration ; VLOG=/var/log/ospd/${l%\.sh}.log ; exec &> >(tee -a "${VLOG}")

/bin/openstack-config --set /etc/keystone/keystone.conf token expiration 10800

