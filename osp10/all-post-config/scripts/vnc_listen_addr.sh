#!/bin/sh

vncaddr=$(hiera nova::compute::vncserver_proxyclient_address)

if [ "x${vncaddr}" != "x" ]; then

	sed -i.bak \
	-e '/^listen_addr/d' \
	-e '/listen_addr/a listen_addr = "'${vncaddr}'"' \
	/etc/libvirt/libvirtd.conf

	crudini --set /etc/nova/nova.conf vnc vncserver_listen ${vncaddr}

	#sed -i.bak \
	# -e '/^vncserver_listen/d' \
	# -e '/vncserver_listen/a vncserver_listen = '${vncaddr} \
	# /etc/nova/nova.conf

	systemctl restart openstack-nova-compute libvirtd

fi

