#!/bin/bash
set -x
# Warning! Dangerous step! Removes lots of packages
yum remove -y nrpe "nagios*" puppet "*openstack*" \
mysql mysql-server "*memcache*" scsi-target-utils \
iscsi-initiator-utils perl-DBI perl-DBD-MySQL openvswitch puppet python-novaclient python-neutron \
python-cinderclient python-swiftclient python-glance-store python-glance python-heatclient \
yum-plugin-protectbase pykde4;

# Warning! Dangerous step! Deletes local application data
rm -rf /etc/nagios /etc/yum.repos.d/packstack_* /root/.my.cnf \
/var/lib/mysql/ /var/lib/glance /var/lib/nova /etc/nova /etc/swift \
/srv/node/device*/* /var/lib/cinder/ /etc/rsync.d/frag* \
/var/cache/swift /var/log/keystone /var/log/cinder/ /var/log/nova/ \
/var/log/httpd /var/log/glance/ /var/log/nagios/ /var/log/quantum/ \
/var/lib/openvswitch /etc/openvswitch /etc/puppet /var/lib/puppet \
/var/lib/iscsi /etc/iscsi /etc/ceilometer /etc/neutron /etc/keystone \
/etc/neutron /var/lib/neutron /var/tmp/packstack;

for svc in dnsmasq tgtd httpd
do
	pkill ${svc}
done

