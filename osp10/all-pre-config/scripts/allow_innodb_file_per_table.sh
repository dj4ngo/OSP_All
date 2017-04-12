#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/pre_deploy-allow_innodb_file_per_table.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)
patch_file=/var/tmp/innodb_mysql.pp.patch

#
case ${my_node_role} in
	CTRL)
		if [ -f /usr/share/openstack-puppet/modules/tripleo/manifests/profile/pacemaker/database/mysql.pp ]; then
cat > ${patch_file} << EOF
*** /usr/share/openstack-puppet/modules/tripleo/manifests/profile/pacemaker/database/mysql.pp.orig      2017-01-02 19:13:30.000000000 -0500
--- /usr/share/openstack-puppet/modules/tripleo/manifests/profile/pacemaker/database/mysql.pp   2017-04-04 09:48:48.851488981 -0400
***************
*** 65,70 ****
--- 65,71 ----
        'default-storage-engine'        => 'innodb',
        'innodb_autoinc_lock_mode'      => '2',
        'innodb_locks_unsafe_for_binlog'=> '1',
+       'innodb_file_per_table'         => 'ON',
        'query_cache_size'              => '0',
        'query_cache_type'              => '0',
        'bind-address'                  => $bind_address,
EOF
			if [ -f ${patch_file} ]; then
				sudo patch -p0 < \
				${patch_file} \
				/usr/share/openstack-puppet/modules/tripleo/manifests/profile/pacemaker/database/mysql.pp				
			fi
		fi
  ;;
esac
