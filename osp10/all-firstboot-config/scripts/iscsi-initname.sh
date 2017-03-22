#!#/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-iscsi_initname.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

case ${my_node_role} in
	CTRL)
		echo "iscsi_initname: Setting iscsi initiator name..."
		echo "InitiatorName=iqn.1994-05.com.redhat:$(hostname -s)" > /etc/iscsi/initiatorname.iscsi
		/bin/touch /etc/iscsi/.initiator_reset
	;;
esac
