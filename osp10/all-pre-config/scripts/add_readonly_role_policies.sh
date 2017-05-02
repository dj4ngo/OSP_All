#!/bin/bash
# $Id$
set -x ; VLOG=/var/log/ospd/pre_deploy-add_readonly_role_policies.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

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

# This is needed to skip over the uuencoded payload
exit 0

#################### STOP HERE AND ADD BINARY PAYLOAD ##########################
### done as: python -c "import sys,uu; uu.encode('policydir_ospd.tar.gz', sys.stdout)" >> add-readonly-role-policies.sh #####
################## ADD UUENCODED BINARY PAYLOAD BELOW #############################
begin 664 policydir_ospd.tar.gz
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
JZA5FJ61=M2%$/YW5\>?G_)R?\W-^SL_Y.3_GY_S\8SW_#VR>=S$ : $ 
 
end
