#!/bin/bash
[ "$BASH" ] && function whence
{
	type -p "$@"
}
#
TOP_DIR="$(cd $(/usr/bin/dirname $(whence -- $0 || echo $0));cd ..;pwd)"

if [ -f ${TOP_DIR}/local-environment.yaml ]; then
	EXTIP=$(awk '{ if ( $1 ~ /ExternalAllocationPools/) print $3}' < ${TOP_DIR}/local-environment.yaml|sed -e "s@,@@g" -e "s@'@@g")
else
	echo "(**) ${TOP_DIR}/local-environment.yaml Not found!"
	exit 127
fi

if [ "x${EXTIP}" = "x" ]; then
	echo "(**) Something went wrong in EXTIP!"
	exit 127
else
	echo "(II) Using EXTIP = ${EXTIP}...."
fi

if [ -f overcloud.pem ]; then
        echo "(II) overcloud.pem already exists, Ignoring cacert-oc.pem privkey-oc.pem overcloud.pem"
else
        echo "(II) overcloud.pem  is missing, re-generating certs..."
	/bin/rm -fv cacert-oc.pem privkey-oc.pem overcloud.pem ${TOP_DIR}/enable-tls.yaml ${TOP_DIR}/inject-trust-anchor.yaml
	#openssl req -x509 -nodes -newkey rsa:4096 -days $((365 * 5 + 1)) -keyout privkey-oc.pem -out cacert-oc.pem -config ./openssl-oc.cnf
	#-reqexts SAN \
	#-config <(cat ./openssl-oc.cnf \
	#<(printf "[SAN]\nsubjectAltName=DNS.1:ocldctl.lasthome.solace.krynn,IP.1:${EXTIP}")) \
	sed -e "s/OSP_CERT_EXTIP/${EXTIP}/" openssl-oc-stub.cnf > openssl-oc.cnf
	openssl req -new -x509 -nodes -newkey rsa:4096 \
		-days $((365 * 5 + 1)) \
		-keyout privkey-oc.pem \
		-out cacert-oc.pem \
		-config ./openssl-oc.cnf \
                -subj "/C=US/ST=CA/L=Sunnyvale/O=Krynn/OU=Inn Of The Last Home/CN=*.lasthome.solace.krynn/CN=${EXTIP}"
	cat cacert-oc.pem privkey-oc.pem > overcloud.pem 
fi
openssl x509 -noout -certopt no_sigdump,no_pubkey -text -in overcloud.pem

# Build enable-tls.yaml...
if [ -f ${TOP_DIR}/enable-tls.yaml ]; then
	echo "(II) ${TOP_DIR}/enable-tls.yaml already exists, Ignoring.."
else
	echo "(II) Building ${TOP_DIR}/enable-tls.yaml..."
	cat > ${TOP_DIR}/enable-tls.yaml << EOF
parameter_defaults:
  SSLCertificate: |
EOF
	cat  cacert-oc.pem|sed -e 's/^/    /' >> ${TOP_DIR}/enable-tls.yaml

	cat >> ${TOP_DIR}/enable-tls.yaml << EOF
  SSLIntermediateCertificate: ''
  SSLKey: |
EOF
	cat  privkey-oc.pem|sed -e 's/^/    /' >> ${TOP_DIR}/enable-tls.yaml

	sed -n '/EndpointMap:/,$p' ${TOP_DIR}/templates/environments/enable-tls.yaml|sed -e 's@ \.\.\/puppet@ templates/puppet@' >> ${TOP_DIR}/enable-tls.yaml
	sed -i -e 's/CLOUDNAME/IP_ADDRESS/' ${TOP_DIR}/enable-tls.yaml
fi

# Build inject-trust-anchor.yaml
if [ -f ${TOP_DIR}/inject-trust-anchor.yaml ]; then
	echo "(II) ${TOP_DIR}/inject-trust-anchor.yaml already exists, Ignoring.."
else
	echo "(II) Building ${TOP_DIR}/inject-trust-anchor.yaml..."

	cat > ${TOP_DIR}/inject-trust-anchor.yaml << EOF
parameter_defaults:
  SSLRootCertificate: |
EOF
	cat  cacert-oc.pem|sed -e 's/^/    /' >> ${TOP_DIR}/inject-trust-anchor.yaml

	cat >> ${TOP_DIR}/inject-trust-anchor.yaml << EOF

resource_registry:
  OS::TripleO::NodeTLSCAData: templates/puppet/extraconfig/tls/ca-inject.yaml
EOF
fi

# Install certs
test -d /etc/pki/instack-certs || sudo mkdir /etc/pki/instack-certs
sudo /bin/cp -afv overcloud.pem /etc/pki/instack-certs/
sudo /bin/cp -afv cacert-oc.pem /etc/pki/ca-trust/source/anchors
sudo update-ca-trust extract

/bin/cp -afv overcloud.pem ${TOP_DIR}
/bin/cp -afv cacert-oc.pem ${TOP_DIR}

