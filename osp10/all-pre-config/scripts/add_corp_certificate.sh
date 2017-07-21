#!/bin/bash
# Add SSH trusted keys to the root account

#
set -x ; VLOG=/var/log/ospd/pre_deploy-add_corp_certificate.log ; exec &> >(tee -a "${VLOG}")

#
export CA_DIR=/etc/pki/ca-trust/source/anchors
export CA_FILE=KrynnCA.crt

if [ -d ${CA_DIR} ]; then
	if [ -f ${CA_DIR}/${CA_FILE}.pem ]; then
		echo "Certificate already present. Skipping..."
	else
		echo "Instaling Certificate as ${CA_DIR}/${CA_FILE}.pem ..."
cat >>  ${CA_DIR}/${CA_FILE}.pem << EOF
-----BEGIN CERTIFICATE-----
MIIFDzCCA/egAwIBAgIJAMLnsbDD5KVMMA0GCSqGSIb3DQEBCwUAMIG1MQswCQYD
VQQGEwJDQTELMAkGA1UECBMCUUMxETAPBgNVBAcTCE1vbnRyZWFsMRMwEQYDVQQK
EwpLcnlubiBJbmMuMRAwDgYDVQQLEwdUcmFudG9yMRYwFAYDVQQDEw1LcnlubiBJ
bmMuIENBMRgwFgYDVQQpEw9SYWlzdGxpbiBNYWplcmUxLTArBgkqhkiG9w0BCQEW
HnJhaXN0bGluQGxhc3Rob21lLnNvbGFjZS5rcnlubjAeFw0xNjAzMDMyMjM2NDla
Fw0yNjAzMDEyMjM2NDlaMIG1MQswCQYDVQQGEwJDQTELMAkGA1UECBMCUUMxETAP
BgNVBAcTCE1vbnRyZWFsMRMwEQYDVQQKEwpLcnlubiBJbmMuMRAwDgYDVQQLEwdU
cmFudG9yMRYwFAYDVQQDEw1LcnlubiBJbmMuIENBMRgwFgYDVQQpEw9SYWlzdGxp
biBNYWplcmUxLTArBgkqhkiG9w0BCQEWHnJhaXN0bGluQGxhc3Rob21lLnNvbGFj
ZS5rcnlubjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL+ycHZrGwRR
U2mZvXcinAc1tHqmX6uRX8xTd/KnAlmo9FKkryYT6fH+Vt3YoQZxt1y1/zwP8b5q
YD/fZCXpK+m2tH7KfbHD+dRwOfkfiqEKYlnZjzJDoa1fFXgcD1MOH4WtW0e76gJu
qazHS8PxnPGVbov/Zct4dhu9N5bptyAkSgy8qM58VY+XSfjMo4KlBAMrRIkYD6Km
gxckvl0+h6b+izc67ftcoWqj24mep4mRAF6jRzldWp9gj5oSh/qR7CUBN7AvS+GU
B/hLVkQw3mT3RqZxXDsVrrzrnm+xtRDJMakbwQUyIQ8JrtYGgpo4z+T6tOC9IwJ1
o6mCMreLy7ECAwEAAaOCAR4wggEaMB0GA1UdDgQWBBSuML7sQDcVORQov3TrBvf5
qoq09TCB6gYDVR0jBIHiMIHfgBSuML7sQDcVORQov3TrBvf5qoq09aGBu6SBuDCB
tTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAlFDMREwDwYDVQQHEwhNb250cmVhbDET
MBEGA1UEChMKS3J5bm4gSW5jLjEQMA4GA1UECxMHVHJhbnRvcjEWMBQGA1UEAxMN
S3J5bm4gSW5jLiBDQTEYMBYGA1UEKRMPUmFpc3RsaW4gTWFqZXJlMS0wKwYJKoZI
hvcNAQkBFh5yYWlzdGxpbkBsYXN0aG9tZS5zb2xhY2Uua3J5bm6CCQDC57Gww+Sl
TDAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQCCALlwYznNn8ZOe+/h
sBeDKhiK44CBJBZgfI26V6BB+CGFBsTFanyrmH+kNJyWyL2MNubSZH3qoaL3WTdT
1jnX6Eyv2LjOq+5HgHOq3uOI0+vcWd80PEbIjrf7cC99GbkDn+bUNf0erySiJKR2
AFHgYAE31q/3X4rO/cb5eN9h01uA92m7nmcDfxa3I3C19v9GBRvZ+Kj3z3dbKpNe
hCyC72/+1a93Vxn9JbZsV0XJUZhEB15hemQ57U91Jb6gK18IxvyX2J9tSfeKSvCe
NroC43O7EkOOCr/yBRWxWWojXTiLqlq+3IowBHu524V3TMHpWCnBXqlggw1GfKSF
Own1
-----END CERTIFICATE-----
EOF

	#
	/bin/update-ca-trust
	#
	/bin/rm -fv /etc/pki/tls/certs/${CA_FILE}.crt
	ln -s ${CA_DIR}/${CA_FILE}.pem /etc/pki/tls/certs/${CA_FILE}.crt
	#
	fi
fi
