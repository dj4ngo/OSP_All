#!/bin/bash
[ "$BASH" ] && function whence
{
	type -p "$@"
}
#
TOP_DIR="$(cd $(/usr/bin/dirname $(whence -- $0 || echo $0));cd ..;pwd)"

if [ -f undercloud.pem ]; then
	echo "(II) undercloud.pem already exists, Ignoring cacert-uc.pem privkey-uc.pem undercloud.pem"
else
	echo "(II) undercloud.pem  is missing, re-generating certs..."
	/bin/rm -fv cacert-uc.pem privkey-uc.pem
	sed -e "s/OSP_CERT_EXTIP/${EXTIP}/" openssl-uc-stub.cnf > openssl-uc.cnf
	openssl req -new -x509 -nodes -newkey rsa:4096 \
		-days $((365 * 5 + 1)) \
		-keyout privkey-uc.pem \
		-out cacert-uc.pem \
		-config ./openssl-uc.cnf \
		-subj "/C=US/ST=CA/L=Sunnyvale/O=Krynn/OU=Inn Of The Last Home/CN=*.lasthome.solace.krynn/CN=10.20.0.2/CN=10.20.0.3/CN=10.20.0.4"
	cat cacert-uc.pem privkey-uc.pem > undercloud.pem
fi
# Print cert
openssl x509 -noout -certopt no_sigdump,no_pubkey -text -in undercloud.pem

# Install Certs
test -d /etc/pki/instack-certs || sudo mkdir /etc/pki/instack-certs
sudo /bin/cp -afv undercloud.pem /etc/pki/instack-certs/
sudo /bin/cp -afv cacert-uc.pem /etc/pki/ca-trust/source/anchors
sudo update-ca-trust extract

# If running on the real instack, do the following
# sudo openstack-config --set undercloud.conf DEFAULT undercloud_service_certificate /etc/pki/instack-certs/undercloud.pem  
sudo pkill -HUP haproxy

/bin/cp -afv undercloud.pem ${TOP_DIR}
/bin/cp -afv cacert-uc.pem ${TOP_DIR}
