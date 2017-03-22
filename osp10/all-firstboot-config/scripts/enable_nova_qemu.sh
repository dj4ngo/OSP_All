#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/firstboot-enable_nova_qemu.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

#
case ${my_node_role} in
	*)
		#
		if [ -x /usr/bin/patch ]; then
			if [ -f /usr/lib/python2.7/site-packages/nova/virt/libvirt/driver.py ]; then
				# Inject Patch
				cat > /var/log/ospd/enable_nova_qemu.patch << EOF
--- driver.py.orig	2016-11-21 15:19:53.000000000 -0500
+++ driver.py	2017-01-24 18:58:35.000000000 -0500
@@ -3818,6 +3818,9 @@
             # instance as an optimisation
             return GuestNumaConfig(allowed_cpus, None, None, None)
         else:
+            if CONF.libvirt.virt_type == "qemu":
+                LOG.info('Disabling NUMA in qemu/TCG mode')
+                return GuestNumaConfig(None, None, None, None)
             if topology:
                 # Now get the CpuTune configuration from the numa_topology
                 guest_cpu_tune = vconfig.LibvirtConfigGuestCPUTune()
EOF
				# Apply patch
				/usr/bin/patch -p0 < /var/log/ospd/enable_nova_qemu.patch /usr/lib/python2.7/site-packages/nova/virt/libvirt/driver.py
				python -m compileall /usr/lib/python2.7/site-packages/nova/virt/libvirt/driver.py
			fi
		else
			echo "(II) /usr/bin/patch not found!"
		fi
	;;
esac
