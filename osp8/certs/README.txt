
1)
ls -l KrynnCA.key
openssl req -x509 -new -nodes -key KrynnCA.key -sha256 -days 3650 -out KrynnCA.pem  -subj "/C=US/ST=CA/L=Sunnyvale/O=Krynn/OU=Inn Of The Last Home/CN=raistlin@lasthome.solace.krynn"

2)
openssl req -new -key ${CA}.key -out ${CA}.csr -subj "/C=US/ST=CA/L=Sunnyvale/O=Krynn/OU=Inn Of The Last Home/CN=ocldctl.lasthome.solace.krynn"
openssl x509 -req -days 365 -in ${CA}.csr -signkey ${CA}.key -out ${CA}.crt

openssl req -x509 -nodes -newkey rsa:2048 -days $((365 * 5 + 1)) -keyout  privkey.pem -out cacert.pem -config ./openssl.cnf
cat cacert.pem privkey.pem > undercloud.pem



1a)
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem

2a)
openssl genrsa -out device.key 2048
openssl req -new -key device.key -out device.csr
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 500 -sha256
subjectAltName = @alt_names
[alt_names]
DNS.1 = instack.lasthome.solace.krynn
IP.1 = 10.20.0.2
IP.2 = 10.20.0.3
IP.3 = 10.20.0.4
