#!/bin/bash
# $Id$
set -x ; VLOG=/var/log/ospd/post_deploy-add_readonly_role_policies.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)
my_node_index=$(cat /var/log/ospd/node_index)

#
set -uf -o pipefail
declare -A IP_LIST
src_config=""
dst_config=""
policy_backup=""
svc_name=""
declare -i restart_svc=0

# This tool is used to push policies on the overcloud
[ "$BASH" ] && function whence
{
	type -p "$@"
}
#
TOP_DIR="$(cd $(/usr/bin/dirname $(whence -- $0 || echo $0));pwd)/policydir"


case ${my_node_role} in
        CTRL)
	# Extract our binary payload:
	/usr/bin/python -c "import sys,uu; uu.decode('$0', sys.stdout)" |/usr/bin/tar xvzf -

	# Verify
	for mydir in "${TOP_DIR}/etc" "${TOP_DIR}/etc/nova" "${TOP_DIR}/etc/neutron"
	do
		if [ -d ${mydir} ]; then
			echo "(II) Found directory ${mydir}..."
		else
			echo "(**) Directory ${mydir} not found! Exit!" ; exit 127
		fi
	done

	# Verify syntax, abort if error..
	for mysvc in aodh ceilometer cinder glance gnocchi heat ironic keystone manila mistral neutron nova sahara zaqar
	do
		src_config="${TOP_DIR}/etc/${mysvc}/policy.json"
		json_verify -q < ${src_config}
		if [ $? -eq 0 ]; then
			echo "Validated JSON syntax of ${src_config}, OK"
		else
			echo "Testing JSON syntax of ${src_config} failed!!" ; exit 127
		fi
	done

	# Perform conditional copy
	for mysvc in aodh ceilometer cinder glance gnocchi heat ironic keystone manila mistral neutron nova sahara zaqar
	do
		src_config="${TOP_DIR}/etc/${mysvc}/policy.json"
		dst_config="/etc/${mysvc}/policy.json"
		policy_backup="${dst_config}.pre-readonly"

		# Take a backup, if not present already..
		if [ ! -f ${policy_backup} ]; then
			if [ -f ${dst_config} ]; then
				/bin/cp -afv ${dst_config} ${policy_backup}
			fi
		fi

		# Compare files and copy if necessary...
		cmp -s ${src_config} ${dst_config}
		if [ $? -eq 0 ]; then
			echo "  (II) No update needed on $(hostname -s):${dst_config}"
		else
			# Overwrite service config file....
			echo "  (WW) Updating $(hostname -s):${dst_config} with ${src_config}..."
			/bin/cp -f ${src_config} ${dst_config}

			# Repairs permissions and SELinux context:
			chown root:${mysvc} ${dst_config} && sudo chmod 640 ${dst_config}
			restorecon ${dst_config} 2>/dev/null

			# This is disabled by default as restarting services isn't necessary for policy.json updates.
			if [ "x${restart_svc}" = "x1" ]; then
				# Restart service appropriately... Only 'neutron' does not have an 'openstack' prefix in its service name
				case "${mysvc}" in
					neutron)
						svc_name="${mysvc}"
						;;
					*)
						svc_name="openstack-${mysvc}"
						;;
				esac
				echo -n "  (WW) Restarting (systemctl) ${svc_name}-\* services on ${myctrl} ..."
				systemctl restart "${svc_name}-\*" && echo OK
			fi
		fi
	done

	if [ $? -eq 0 ]; then
		echo "(II) ALL done."
	else
		echo "(**) Failures seen, please check..."
	fi
	;;
esac

# Create readonly role using puppet on ctrl0
case "${my_node_role}${my_node_index}" in
	"CTRL0")
		echo "Creating readonly role on Galera using Controller0..."
		/bin/puppet apply -e 'keystone_role { 'readonly':  ensure => present }'
	;;
esac

# This is needed to skip over the uuencoded payload
exit 0

#################### STOP HERE AND ADD BINARY PAYLOAD ##########################
### done as: python -c "import sys,uu; uu.encode('policydir_only.tar.gz', sys.stdout)" >> add_readonly_role.sh #####
################## ADD UUENCODED BINARY PAYLOAD BELOW #############################
begin 664 policydir_only.tar.gz
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
5<WDNS^6Y/)?G?,__ 6JLH^4 : $ 
 
end
