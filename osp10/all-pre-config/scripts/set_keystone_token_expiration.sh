#!/bin/bash
#
# Description - runs post config to set token expiration to allow for large glance uploads.
# Sample crudini command for reference - "crudini --set --existing config_file section parameter value"
#
set -x ; VLOG=/var/log/ospd/pre_deploy-set_keystone_expiration.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

case ${my_node_role} in
	CTRL)
		crudini --set /etc/keystone/keystone.conf token expiration 10800
		;;
	*)
		crudini --set /etc/keystone/keystone.conf token expiration 10800
		;;
esac

