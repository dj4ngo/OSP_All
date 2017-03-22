#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-setup_nested_kvm.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

#
case ${my_node_role} in
	*)
		if [ -f /etc/modprobe.d/kvm-intel.conf ]; then
			echo "(II) /etc/modprobe.d/kvm-intel.conf already present"
		else
		cat > /etc/modprobe.d/kvm-intel.conf  << EOF
# Setting modprobe kvm_intel/kvm_amd nested = 1
# only enables Nested Virtualization until the next reboot or
# module reload. Uncomment the option applicable
# to your system below to enable the feature permanently.
#
# User changes in this file are preserved across upgrades.
#
# For Intel
options kvm_intel ept=1
options kvm_intel nested=1
options kvm_intel enable_apicv=1
options kvm_intel enable_shadow_vmcs=1
#
# For AMD
# options kvm_amd nested=1
EOF
			chown root:root /etc/modprobe.d/kvm-intel.conf
			chmod 644 /etc/modprobe.d/kvm-intel.conf
		fi
  ;;
esac
