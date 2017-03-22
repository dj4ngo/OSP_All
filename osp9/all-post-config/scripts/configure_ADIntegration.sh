#!/bin/bash
# This Script is called during Director Deployment
# to configure Keystone to authenticate against
# Active Directory for user authentication.  It
# is called during deployment via the
#  ~/templates/ad_bind-environment.yaml file which
# calls the ~/templates/ad_bind-installation.yaml file

set -x ; VLOG=/var/log/ospd/post_deploy-configure_ADIntegration.log ; exec &> >(tee -a "${VLOG}")

#
#  IMPORTANT !!!
#
# THIS SCRIPT MUST BE MODIFIED IN SOME WAY PRIOR TO
# ANY FUTURE DEPLOY OR UPDATE TO THE OVERCLOUD THAT IT
# INTITIALLY CONFIGURED.  THIS IS DUE TO THE FACT THAT
# DIRECTOR SAVES AN MD5SUM ON THIS SCRIPT BEFORE IT'S
# INITIAL RUN.  IF THAT MD5SUM DOESN'T CHANGE, DIRECTOR
# WILL NOT RUN THIS AGAIN UPON FUTURE UPDATES TO THE 
# OVERCLOUD
#
# ALSO, IN ORDER FOR DIRECTOR UPDATES MADE TO THE OVERCLOUD
# AFTER THE INTIAL DEPLOY, YOU MUST HAVE INSTALLED
# THE openstack-puppet-modules 7.1.1 OR HIGHER OR THE 
# UPDATE WILL FAIL
#
#
# VARIABLES
# Overcloud node naming convention
export CONTROLLER=controller
export COMPUTE=compute
export CEPH=ceph

#variables
myhostname=$(hostname -s)

# Active Directory Domain Name
export AD_ENABLE=__AD_ENABLE__
export AD_PRIMARY_DC=__AD_PRIMARY_DC__
export NETBIOS_DOMAIN=__NETBIOS_DOMAIN__

# Closest AD Domain Controller
#AD_PRIMARY_DC=$(dig -t SRV _ldap._tcp.dc._msdcs.${AD_DOMAIN}|grep -A1 ANSWER\ SECTION|tail -1|cut -d " " -f6|sed 's/.$//')

# SCRIPT
case ${AD_ENABLE} in
	"True"|"TRUE"|"true")
		OK=1
		;;
	*)
		exit 0
		;;
esac

# Determine to run only on Controller Nodes

myhostname=$(hostname -s)
case ${myhostname} in
	instack|*-ctrl-*|*-controller-*)
		echo "Doing Controller-Specific configuration..."
	        # SSL & Keystone Settings
	        #openssl s_client -connect $AD_DC:636 -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM > /etc/pki/ca-trust/source/anchors/${AD_DOMAIN}.pem
	        update-ca-trust extract
		/bin/cp -fv /etc/openldap/ldap.conf /etc/openldap/ldap.conf.orig
		sed -i 's/cacerts/certs/g' /etc/openldap/ldap.conf
		setsebool -P authlogin_nsswitch_use_ldap=on
		openstack-config --set /etc/keystone/keystone.conf identity domain_specific_drivers_enabled true
		openstack-config --set /etc/keystone/keystone.conf identity domain_config_dir /etc/keystone/domains
		openstack-config --set /etc/keystone/keystone.conf assignment driver keystone.assignment.backends.sql.Assignment

		# Create Domains Directory and keystone config for domain
		mkdir -p /etc/keystone/domains
		cat >/etc/keystone/domains/keystone.${NETBIOS_DOMAIN}.conf << EOF
[ldap]
url                      = ldaps://${AD_PRIMARY_DC}:636
user                     = CN=svc-ldap,ou=serviceaccounts,dc=corp,dc=ds,dc=fedex,dc=com
password                 = Itsnoteasystack1
suffix                   = dc=corp,dc=ds,dc=fedex,dc=com
user_tree_dn             = dc=corp,dc=ds,dc=fedex,dc=com
user_objectclass         = person
user_filter              = (memberOf=cn=grp-openstack,ou=Openstack,dc=corp,dc=ds,dc=fedex,dc=com)
user_id_attribute        = sAMAccountName
user_name_attribute      = sAMAccountName
user_mail_attribute      = mail
user_pass_attribute      =
user_enabled_attribute   = userAccountControl
user_enabled_mask        = 2
user_enabled_default     = 512
user_attribute_ignore    = password,tenant_id,tenants
user_allow_create        = False
user_allow_update        = False
user_allow_delete        = False
query_scope              = sub

use_tls = False
tls_cacertfile = /etc/ssl/certs/corp.crt

[identity]
driver = keystone.identity.backends.ldap.Identity

EOF

		# Ensure newly created files have proper ownership
		chown -R keystone:keystone /etc/keystone/domains/
		restorecon -Rv /etc/keystone/domains/

		# Configure cinder to use keystone v3
		cinder_auth_uri=$(openstack-config --get /etc/cinder/cinder.conf keystone_authtoken auth_uri)
		new_cinder_auth_uri=$(echo $cinder_auth_uri | sed -e 's/v2.0/v3/')
		openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri $new_cinder_auth_uri
		openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_version v3
		openstack-config --set /etc/nova/nova.conf keystone_authentication auth_version v3
		openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_version v3

		# Restart Services. Not used anymore, Now handled by pcs-cluster-restart-post-config.yaml!!!
		#### systemctl restart openstack-keystone
		#### systemctl restart openstack-cinder-api
		#### systemctl restart httpd
		#### systemctl restart openstack-nova-api
		#### systemctl restart openstack-nova-cert
		#### systemctl restart openstack-nova-conductor
		#### systemctl restart openstack-nova-consoleauth
		#### systemctl restart openstack-nova-novncproxy
		#### systemctl restart openstack-nova-scheduler
	;;
esac


# Determine to run only on Compute Nodes
case ${myhostname} in
	*-cmpt-*|*-compute-*)
		echo "Doing Compute-Specific configuration..."
	        # Compute Node specific settings
		cinder_auth_uri=$(openstack-config --get /etc/cinder/cinder.conf keystone_authtoken auth_uri)
		new_cinder_auth_uri=$(echo $cinder_auth_uri | sed -e 's/v2.0/v3/')
		openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri $new_cinder_auth_uri
		openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_version v3
		openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_version v3
		openstack-config --set /etc/nova/nova.conf keystone_authentication auth_version v3

		# Restart Services. Not used anymore, Now handled by pcs-cluster-restart-post-config.yaml!!!
		#### systemctl restart openstack-nova-compute
	;;
esac
