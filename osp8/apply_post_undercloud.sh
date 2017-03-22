#!/bin/bash
[ "$BASH" ] && function whence
{
	type -p "$@"
}
#
PATH_SCRIPT="$(cd $(/usr/bin/dirname $(whence -- $0 || echo $0));pwd)"

if [ "x$(id -n -u)" = "xstack" ]; then
	. $HOME/stackrc || exit 127
else
	echo "(**) Not stack, exit!" ; exit 127
fi

if [ -f ${PATH_SCRIPT}/ssh.py.patch ]; then
	if [ -f /usr/lib/python2.7/site-packages/ironic/drivers/modules/ssh.py.orig ]; then
		echo "(II) /usr/lib/python2.7/site-packages/ironic/drivers/modules/ssh.py Already patched.."
	else
		sudo patch -p0 /usr/lib/python2.7/site-packages/ironic/drivers/modules/ssh.py < ${PATH_SCRIPT}/ssh.py.patch 
		sudo python -m compileall /usr/lib/python2.7/site-packages/ironic/drivers/modules/ssh.py
		sleep 0.2
		sudo systemctl restart openstack-ironic-api openstack-ironic-conductor openstack-ironic-inspector
	fi
fi

#if [ -f inspector.ipxe ]; then
#	if [ -f /httpboot/inspector.ipxe.orig ]; then
#		echo "(II) /httpboot/inspector.ipxe Already patched.."
#	else
#		sudo cp -afv /httpboot/inspector.ipxe /httpboot/inspector.ipxe.orig
#		sudo cp -fv inspector.ipxe /httpboot/inspector.ipxe
#	fi
#fi

# Virtio PXE booting is slow:
#if [ "x$(sudo openstack-config --get /etc/ironic/ironic.conf conductor max_time_interval)" != "x300" ]; then
#	sudo openstack-config --set /etc/ironic/ironic.conf conductor max_time_interval 300
#	sudo systemctl restart openstack-ironic-api openstack-ironic-conductor 
#fi
# Lower timeout value
#if [ "x$(sudo openstack-config --get /etc/ironic-inspector/inspector.conf DEFAULT timeout)" != "x600" ]; then
#	sudo openstack-config --set /etc/ironic-inspector/inspector.conf DEFAULT timeout 600
#	sudo systemctl restart openstack-ironic-api openstack-ironic-inspector
#fi

if [ -d ${HOME}/images ]; then
	cd ${HOME}/images
#	tar xvf /usr/share/rhosp-director-images/ironic-python-agent.tar
#	tar xvf /usr/share/rhosp-director-images/overcloud-full.tar
	virt-customize -a overcloud-full.qcow2 --root-password password:r00tme
	openstack overcloud image upload --image-path ${HOME}/images/ --update-existing
	openstack baremetal configure boot
fi

