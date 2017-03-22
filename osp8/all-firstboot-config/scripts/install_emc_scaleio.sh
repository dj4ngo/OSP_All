#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-install_emc_scaleio.log ; exec &> >(tee -a "${VLOG}")
#
if [ -f ${RMC_RPM} ]; then
	EMC_RPM=/root/EMC-ScaleIO-sdc.rpm
	MDM_IP=_EMC_MDMIP1_,_EMC_MDMIP2_ rpm -Uvh ${EMC_RPM}
	rpm -q EMC-ScaleIO-sdc && /bin/rm -fv ${EMC_RPM}
	/opt/emc/scaleio/sdc/bin/drv_cfg --add_mdm --ip _EMC_MDMIP1_
fi
