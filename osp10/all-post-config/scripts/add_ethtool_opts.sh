#!/bin/bash
# set some ethtool flags on specific interfaces..

#
set -x ; VLOG=/var/log/ospd/post_deploy-add_ethtool_opts.log ; exec &> >(tee -a "${VLOG}")

bufsz=4096
/sbin/ip route
RSS_NICS="ens1f0 ens2f0 ens1f1 ens2f1"

# First loop through the specific NICs...
for mynic in ${RSS_NICS}
do
	if [ -d /sys/class/net/${mynic} ]; then
		echo "Found Interface ${mynic}, continuing..."
		mybusid=$(/sbin/ethtool -i ${mynic}|grep '^bus.info'|cut -d: -f3-)
		mydevtype=$(/sbin/lspci -mmv -s ${mybusid}|grep SDevice|cut -d: -f2-|sed -e 's/^[ \t]*//' )
		case "${mydevtype}" in
			"Ethernet Server Adapter X520-2")
				#
				/sbin/ethtool -N ${mynic} rx-flow-hash udp4 sdfn
				/sbin/ethtool -G ${mynic} rx ${bufsz} tx ${bufsz}
				#
				IFCFG="/etc/sysconfig/network-scripts/ifcfg-${mynic}"
				if [ -f ${IFCFG} ]; then
					grep -q ETHTOOL_OPTS ${IFCFG}
					if [ $? -eq 1 ]; then
						echo "ETHTOOL_OPTS=\" -G \${DEVICE} rx ${bufsz} tx ${bufsz} ; -N \${DEVICE} rx-flow-hash udp4 sdfn\""  >> ${IFCFG}
					fi
				fi
				# Give it time to settle.
				/bin/sleep 5
				;;
			"*")
				echo "Interface ${mynic} not an X520-2, Skipping.."
				;;
		esac
	else
		echo "Interface ${mynic} not found, ignoring.."
	fi
done

# Next, handle the -other- NICs, excluding those from the list above..
for mynic in $(/sbin/ip -o l |awk '{if ( $2 != "lo:") { print substr($2,0,length($2)-1)}}')
do
	if [ -d /sys/class/net/${mynic} ]; then
		matches=$(echo ${RSS_NICS}|grep -w ${mynic}|wc -l)
		if [ $matches -eq 0 ]; then
			/sbin/ethtool -G ${mynic} rx ${bufsz} tx ${bufsz}
			#
			IFCFG="/etc/sysconfig/network-scripts/ifcfg-${mynic}"
			if [ -f ${IFCFG} ]; then
				grep -q ETHTOOL_OPTS ${IFCFG}
				if [ $? -eq 1 ]; then
					echo "ETHTOOL_OPTS=\" -G \${DEVICE} rx ${bufsz} tx ${bufsz}\""  >> ${IFCFG}
				fi
			fi
			# Give it time to settle.
			/bin/sleep 5
		fi
	fi
done


i=0
while [ $i -le 30 ];
do
sleep 5
# Be careful (looking for root cause of issue)
ROUTES=$(/sbin/ip route|wc -l)
if [ $ROUTES -eq 0 ]; then
	/sbin/ip route
	systemctl restart network
	/sbin/ip route
fi
i=$(($i+1))
done
