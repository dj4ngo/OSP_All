#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/pre_deploy-allow_innodb_file_per_table.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)
patch_file=/var/tmp/bz1406417_gnocchi.patch
#
case ${my_node_role} in
	*)
		if [ -f /usr/lib/python2.7/site-packages/gnocchi/storage/ceph.py ]; then
cat > ${patch_file} << EOF
*** /usr/lib/python2.7/site-packages/gnocchi/storage/ceph.py.orig       2017-03-10 21:46:05.000000000 +0000
--- /usr/lib/python2.7/site-packages/gnocchi/storage/ceph.py    2017-04-12 13:50:13.295146413 +0000
***************
*** 50,55 ****
--- 50,56 ----   
                 help='Ceph username (ie: admin without "client." prefix).'),
      cfg.StrOpt('ceph_secret', help='Ceph key', secret=True),
      cfg.StrOpt('ceph_keyring', help='Ceph keyring path.'),
+     cfg.IntOpt('ceph_timeout', help='Ceph connection timeout'),
      cfg.StrOpt('ceph_conffile',
                 default='/etc/ceph/ceph.conf',
                 help='Ceph configuration file.'),
***************
*** 68,73 ****
--- 69,78 ----
              options['keyring'] = conf.ceph_keyring
          if conf.ceph_secret:
              options['key'] = conf.ceph_secret
+         if conf.ceph_timeout:
+             options['rados_osd_op_timeout'] = conf.ceph_timeout
+             options['rados_mon_op_timeout'] = conf.ceph_timeout
+             options['client_mount_timeout'] = conf.ceph_timeout

          if not rados:
              raise ImportError("No module named 'rados' nor 'cradox'")
EOF
			if [ -f ${patch_file} ]; then
				sudo patch -p0 < \
				${patch_file} \
				/usr/lib/python2.7/site-packages/gnocchi/storage/ceph.py
			fi
		fi
  ;;
esac
