#!/bin/bash
#### Created Eric Sallie 06/9/2016
# Script required to create filesystem for openstack VMs
#
set -x ; VLOG=/var/log/ospd/firstboot-create_fs_nova.log ; exec &> >(tee -a "${VLOG}")
my_node_role=$(cat /var/log/ospd/node_role)

TSTAMP=$(date +%s)
lvm_vg=novadg
lvm_lv=lv_instances
mypv=/dev/sdb
myfs=/var/lib/nova/instances

case ${my_node_role} in
	CMPT)

	echo -e "Creating volume group ${lvm_vg} with ${mypv} disk\n"
	fdisk ${mypv} -l
	if [ $? -eq 1 ]; then
		echo "Disk ${mypv} does not exist"
		exit 1;
	fi

	# Sanity check
	df ${myfs} > /dev/null 2>&1
	if [ $? -eq 1 ]; then
		echo "Filesystem ${myfs} already exists"
		exit 0;
	fi

	# Overwrite
	/usr/sbin/sgdisk -Z ${mypv}
	blockdev --rereadpt  ${mypv}
	parted --script "${mypv}" mklabel gpt mkpart primary xfs 1 100% \
		--script set 1 lvm on
	blockdev --rereadpt  ${mypv}
	pvcreate -f -y "${mypv}1"
	vgcreate -f -y ${lvm_vg} "${mypv}1"
	lvremove -f /dev/${lvm_vg}/${lvm_lv}
	lvcreate -L 1.5T -n ${lvm_lv} ${lvm_vg}

	echo -e "Creating /var/lib/nova instances filesystem \n"
	mkfs.xfs -f /dev/${lvm_vg}/${lvm_lv}
	mkdir /tmp_mnt
	mount /dev/${lvm_vg}/${lvm_lv} /tmp_mnt

	#echo -e "Stopping nova-compute service \n"
	#systemctl stop openstack-nova-compute

	echo -e "Syncing ${myfs} data into new filesystem \n"
	/bin/cp -fax ${myfs}/ /tmp_mnt

	echo -e "Backing up existing instances directory and creating new mount point \n"
	umount /tmp_mnt
	rmdir /tmp_mnt
	/bin/mv ${myfs} ${myfs}.${TSTAMP}
	mkdir ${myfs}
	chmod ${myfs} --reference=${myfs}.${TSTAMP}
	chown ${myfs} --reference=${myfs}.${TSTAMP}

	echo -e "Updating /etc/fstab and mounting new filesystem \n"
	/bin/cp /etc/fstab /etc/fstab.${TSTAMP}
	echo "/dev/mapper/${lvm_vg}-${lvm_lv} ${myfs} xfs defaults 0 2" >> /etc/fstab
	cat /etc/fstab
	mount -a
	# Fix perms again..
	chmod ${myfs} --reference=${myfs}.${TSTAMP}
	chown ${myfs} --reference=${myfs}.${TSTAMP}
	restorecon -rv ${myfs}
	/sbin/vgcfgbackup ${lvm_vg}

	for mysvc in libvirtd virtlockd virtlogd
	do
		if [ -f /usr/lib/systemd/system/${mysvc}.service ]; then
			systemctl restart ${mysvc}
		fi
	done

	echo -e "Display filesystem table with new filesystem \n"
	df -h

	;;
	*)
		echo "Not a compute, exit!"
	;;
esac
