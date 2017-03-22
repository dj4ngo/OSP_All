#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-install_f5_rpms.log ; exec &> >(tee -a "${VLOG}")
#
F5_RPM1="/root/f5-icontrol-rest.rpm"
F5_RPM2="/root/f5-sdk.rpm"
F5_RPM3="/root/f5-openstack-agent.rpm"
F5_RPM4="/root/f5-openstack-lbaasv2-driver.rpm"
for myrpm in ${F5_RPM1}  ${F5_RPM2} ${F5_RPM3} ${F5_RPM4}
do
	rpm -Uvh ${myrpm} && /bin/rm -fv ${myrpm}
done
