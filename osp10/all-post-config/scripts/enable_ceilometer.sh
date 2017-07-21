#!/bin/bash
# $Id$
set -x ; VLOG=/var/log/ospd/post_deploy-enable_ceilometer.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)
my_node_index=$(cat /var/log/ospd/node_index)

#
set -uf -o pipefail
declare -A IP_LIST
src_config=""
dst_config=""
policy_backup=""
svc_name=""
declare -i restart_svc=0

# This tool is used to push policies on the overcloud
[ "$BASH" ] && function whence
{
	type -p "$@"
}
#
TOP_DIR="$(cd $(/usr/bin/dirname $(whence -- $0 || echo $0));pwd)/policydir"


case ${my_node_role} in
	*)
	# ceilometer.conf changes
	if [ -f /etc/ceilometer/ceilometer.conf ]; then
		crudini --set /etc/ceilometer/ceilometer.conf event drop_unmatched_notifications true
		crudini --set /etc/ceilometer/ceilometer.conf database metering_time_to_live 86400
		crudini --set /etc/ceilometer/ceilometer.conf database event_time_to_live 86400
		crudini --set /etc/ceilometer/ceilometer.conf notification store_events true
		crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_notifications driver noop
		crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_notifications topics notifications,versioned_notifications
	fi

	# swift-proxy
	if [ -f /etc/swift/proxy-server.conf ]; then
		crudini --set /etc/swift/proxy-server.conf filter:ceilometer driver noop
	fi

	# keystone changes
	if [ -f /etc/keystone/keystone.conf ]; then
		crudini --set /etc/keystone/keystone.conf oslo_messaging_notifications driver noop
	fi

	# nova.conf
	if [ -f /etc/nova/nova.conf ]; then
		crudini --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
		crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit true
		crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
		crudini --set /etc/nova/nova.conf DEFAULT notify_on_any_change true
		crudini --set /etc/nova/nova.conf oslo_messaging_notifications driver messaging
		crudini --set /etc/nova/nova.conf oslo_messaging_notifications topics notifications
	fi

	# heat
	if [ -f /etc/heat/heat.conf ]; then
		crudini --set /etc/heat/heat.conf oslo_messaging_notifications driver messaging
		crudini --set /etc/heat/heat.conf oslo_messaging_notifications topics notifications
	fi

	# glance-api.conf
	if [ -f /etc/glance/glance-api.conf ]; then
		crudini --set /etc/glance/glance-api.conf oslo_messaging_notifications driver messaging
		crudini --set /etc/glance/glance-api.conf oslo_messaging_notifications topics notifications
	fi

	# neutron.conf
	if [ -f /etc/neutron/neutron.conf ]; then
		crudini --set /etc/neutron/neutron.conf oslo_messaging_notifications driver messaging
		crudini --set /etc/neutron/neutron.conf oslo_messaging_notifications topics notifications
	fi
	;;
esac
