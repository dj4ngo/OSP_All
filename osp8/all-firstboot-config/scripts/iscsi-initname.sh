#!#/bin/bash
#
set -x ; l=firstboot-iscsi_initname ; VLOG=/var/log/ospd/${l%\.sh}.log ; exec &> >(tee -a "${VLOG}")

case "$HOSTNAME" in
	*ctrl*)
		echo "iscsi_initname: Setting iscsi initiator name..."
		echo "InitiatorName=iqn.1994-05.com.redhat:$(hostname -s)" > /etc/iscsi/initiatorname.iscsi
		/bin/touch /etc/iscsi/.initiator_reset
	;;
esac
