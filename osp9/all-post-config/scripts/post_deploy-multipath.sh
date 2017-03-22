#!/bin/bash
#
# description:
# update overcloud systems to configure multipath
# run commands on all compute nodes using heat post deployment to enable multipath in nova.conf
#
# post_deploy script
#
# Verizon
# Jay Cromer
#
# Borrowed from:
#
# Redhat
# Jason Woods   jwoods@redhat.com
# 2016-05-17

set -x ; l=post_deploy-multipath ; VLOG=/var/log/ospd/${l%\.sh}.log ; exec &> >(tee -a "${VLOG}")

# backup config file before making changes to it
function backup_file() {
  bkup_orig="${1}.$(date +"%F_%T.%N")"
  if [ -n "${1}" ] ; then
    # if arg1 sent to function, use that as file to backup
    bkup_file="${1}"
  else
    # if arg1 is null default to using FILE variable
    bkup_file="${FILE}"
  fi
  if [ -e "${bkup_file}" ] ; then
    cp -fva "${bkup_file}" "${bkup_orig}"
  else
    touch "${bkup_file}" "${bkup_orig}"
  fi
}

function setup_multipath() {
  LOG="/root/extraconfig_setup_multipath.log"
  {
    FILE="/etc/multipath.conf"
    backup_file "${FILE}"
    # enable multipath on all nodes
    #mpathconf --enable --with_multipathd y --user_friendly_names n
    cat << EOF > "${FILE}"
# This is a basic configuration file with some examples, for device mapper
# multipath.
#
# For a complete list of the default configuration values, run either
# multipath -t
# or
# multipathd show config
#
# For a list of configuration options with descriptions, see the multipath.conf
# man page
## By default, devices with vendor = "IBM" and product = "S/390.*" are
## blacklisted. To enable mulitpathing on these devies, uncomment the
## following lines.

#blacklist_exceptions {
#    device {
#        vendor    "IBM"
#        product    "S/390.*"
#    }
#}
## Use user friendly names, instead of using WWIDs as names.

defaults {
    user_friendly_names no
    find_multipaths yes
}

##
## Here is an example of how to configure some standard options.
##
#

#defaults {
#    polling_interval     10
#    path_selector        "round-robin 0"
#    path_grouping_policy    multibus
#    uid_attribute        ID_SERIAL
#    prio            alua
#    path_checker        readsector0
#    rr_min_io        100
#    max_fds            8192
#    rr_weight        priorities
#    failback        immediate
#    no_path_retry        fail
#    user_friendly_names    yes
#}

##
## The wwid line in the following blacklist section is shown as an example
## of how to blacklist devices by wwid.  The 2 devnode lines are the
## compiled in default blacklist. If you want to blacklist entire types
## of devices, such as all scsi devices, you should use a devnode line.
## However, if you want to blacklist specific devices, you should use
## a wwid line.  Since there is no guarantee that a specific device will
## not change names on reboot (from /dev/sda to /dev/sdb for example)
## devnode lines are not recommended for blacklisting specific devices.
##

blacklist {
    devnode "^(ram|raw|loop|fd|md|dm-|sr|scd|st)[0-9]*"
    devnode "^hd[a-z][0-9]*"
    devnode "^cciss!c[0-9]d[0-9]*[p[0-9]*]"
        devnode "^dcssblk[0-9]*"
        device { 
		vendor "IBM"
                product "S/390.*" 
		}
        # don't count normal SATA devices as multipaths
        device { 
		vendor  "ATA" 
		}
        # don't count 3ware devices as multipaths
        device { 
		vendor  "3ware" 
		}
        device { 
		vendor  "AMCC" 
		}
        # nor highpoint devices
        device { 
		vendor  "HP" 
		}
	device { 
		vendor  "HPT" 
		}
        device { 
		vendor iDRAC
                product Virtual_CD 
		}
        device { 
		vendor TEAC
                product DVD-ROM_DV-28SW 
		}
        device { 
		vendor "DELL" 
		}
        device {
                vendor "LSI"
                }
          }
EOF
    systemctl restart multipathd
  } >> "${LOG}"
}
# post_heat_nova_iscsi_conf
function post_heat_nova_iscsi_conf() {
  LOG="/root/post_heat_nova_iscsi_conf.log"
  {

    # run commands on all compute nodes using heat post deployment to enable multipath in nova.conf
    FILE_CHK="/etc/neutron/dnsmasq-neutron.conf"
    if [ -e "${FILE_CHK}" ] ; then
      echo "## Found file: \"${FILE_CHK}\""
      echo "## System appears to be a controller"
    else
    FILE="/etc/nova/nova.conf"
    backup_file "${FILE}"
      crudini --set "${FILE}" libvirt iscsi_use_multipath true
      ## systemctl restart openstack-nova-compute
    fi
  } >> "${LOG}"
}

# functions to execute below
# comment out as needed
setup_multipath
post_heat_nova_iscsi_conf
