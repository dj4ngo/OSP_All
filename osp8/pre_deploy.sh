#!/bin/bash
#
#
if [ "x${TOP_DIR}" = "x" ]; then
	echo "(**) TOP_DIR not found in current environment!"
	exit 127
fi

#
for myfile in enable-tls.yaml inject-trust-anchor.yaml local-environment.yaml overcloud.pem undercloud.pem
do
	if [ -f ${TOP_DIR}/${myfile} ]; then
		echo "(II) Using ${TOP_DIR}/${myfile}..."
	else
		echo "(**) ${TOP_DIR}/${myfile} not found!" ; exit 127
	fi
done
#
if [ -h ${TOP_DIR}/templates ]; then
	echo "(II) Good, ${TOP_DIR}/templates is a symlink..."
else
	if [ -d /usr/share/openstack-tripleo-heat-templates ]; then
		/bin/mv -fv ${TOP_DIR}/templates ${TOP_DIR}/templates.$(date +%s)
		/bin/ln -s /usr/share/openstack-tripleo-heat-templates ${TOP_DIR}/templates
	else
		echo "(**) /usr/share/openstack-tripleo-heat-templates missing!" ; exit 127
	fi
fi


# Install overcloud cert
if [ -f /etc/ironic/ironic.conf ]; then
	test -d /etc/pki/instack-certs || sudo mkdir /etc/pki/instack-certs

	test -d /etc/pki/instack-certs || sudo mkdir /etc/pki/instack-certs
	# Install OC certs
	sudo /bin/cp -afv ${TOP_DIR}/overcloud.pem /etc/pki/instack-certs/
	sudo /bin/cp -afv ${TOP_DIR}/cacert-oc.pem /etc/pki/ca-trust/source/anchors

	# Install UC certs
	sudo /bin/cp -afv ${TOP_DIR}/overcloud.pem /etc/pki/instack-certs/
	sudo /bin/cp -afv ${TOP_DIR}/cacert-oc.pem /etc/pki/ca-trust/source/anchors
	sudo pkill -HUP haproxy

	sudo semanage fcontext -a -t etc_t "/etc/pki/instack-certs(/.*)?"
	sudo restorecon -R /etc/pki/instack-certs
	sudo restorecon -Rv /etc/pki
	sudo update-ca-trust extract
fi
