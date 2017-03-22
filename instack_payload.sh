#!/bin/bash
# $Id: instack_payload.sh,v 1.3 2016/02/29 17:11:08 vcojot Exp vcojot $

# Support commands
IRONIC_CMD=/usr/bin/ironic
NOVA_CMD=/usr/bin/nova
GLANCE_CMD=/usr/bin/glance
declare -a tuids names ips profiles

# Image defaults
IRONIC_PROFILE_LIST=( compute control ceph-storage swift-storage )
ANSIBLE_PROFILE_LIST=( cmpt ctrl ceph strg )


usage() {
	echo -e "Usage: $0 <uuid> ..."
	exit 122
}

#

_TMPDIR=$(/usr/bin/mktemp -d)
if [ ! -d ${_TMPDIR} ]; then
	echo "(EE) ${_TMPDIR} not useable!"
	exit 123
else
	touch ${_TMPDIR}/{tmp,node}list.txt
fi

#
for mycmd in ${IRONIC_CMD} ${NOVA_CMD} ${GLANCE_CMD}
do
	if [ ! -x ${mycmd} ]; then
		echo "(EE) ${mycmd} not found!"
		exit 124
	fi
done

if [ "x${OS_AUTH_URL}" = "x" ]; then
	echo "\$OS_AUTH_URL undefined! Source the proper Stack rc file..!"
	exit 125
fi

# Give the user some ouput as to avoid pressing the panic button
>&2 echo -n "# Collecting information from Nova.."

# Process nodes and skip missing/invalid ones..
${NOVA_CMD} list|awk '{ if ( $6 == "ACTIVE" ) { print $2,$4,$12 } }'|while read novaid name temp
do
	myip=$(echo $temp|cut -d= -f2)
	echo "${novaid} ${name} ${myip}" >> ${_TMPDIR}/tmplist.txt
done


#####
for nodeid in $(cat ${_TMPDIR}/tmplist.txt|awk '{ print $1}' )
do
	nodename=$(grep ${nodeid} ${_TMPDIR}/tmplist.txt|awk '{ print $2}')
	nodeip=$(grep ${nodeid} ${_TMPDIR}/tmplist.txt|awk '{ print $3}')

	>&2 echo -n "."
	uuid=$(ironic node-show --instance ${nodeid}|awk '{ if ($2 == "uuid" ) { print $4} }')
	>&2 echo -n "."
	myprofile=$(ironic node-show ${uuid}|awk '/properties/,/instance_uuid/'|cut -d'|' -f3|perl -pe'chomp, s/$// unless eof' |sed -e 's/ *//g'|grep profile|sed -e 's/.*profile://' -e 's/,.*$//' -e "s/'}.*//")
	>&2 echo -n "."
	ipmi=$(ironic node-show ${uuid} |awk '/driver_info/,/driver_internal_info/'|cut -d'|' -f3|perl -pe'chomp, s/$// unless eof' |sed -e 's/ *//g'|grep ipmi_address|sed -e 's/.*ipmi_address//' -e 's/,.*$//' -e "s@'@@g" -e 's@:u@@')

	# Outputs
	if [ "x${ipmi}" != "x" ]; then
		echo "${myprofile} ${nodeid} ${nodename} ${nodeip} ipmi_lan_addr=${ipmi}" >> ${_TMPDIR}/nodelist.txt
	else
		echo "${myprofile} ${nodeid} ${nodename} ${nodeip}" >> ${_TMPDIR}/nodelist.txt
	fi
done

>&2 echo "Done!"

####
i=0
for myprofile in ${IRONIC_PROFILE_LIST[@]:0}
do
	echo "[${ANSIBLE_PROFILE_LIST[$i]}]"
	grep "^${myprofile} " ${_TMPDIR}/nodelist.txt|awk '{ print $3,"ansible_ssh_host=" $4,$5 }'

	echo "[${ANSIBLE_PROFILE_LIST[$i]}:vars]"
	echo "ansible_user=heat-admin"
	i=$((i + 1))
done
