#!/bin/bash
#
# description:
# update overcloud systems to comply with openscap
# not that pretty, but functional
#
# post_deploy script
#
# created using requirements given by Rob Fisher @Verizon
#
# Red Hat
# Jason Woods	jwoods@redhat.com
# 2016-05-17

set -x ; l=post_deploy-openscap ; VLOG=/var/log/ospd/${l%\.sh}.log ; exec &> >(tee -a "${VLOG}")

# unalias command aliases that could cause trouble
unalias mv cp rm

# directories that will be moved to their own filesystems
MOUNT_DIRS="home tmp var"

# setup_fileperms
function setup_fileperms() {
  LOG="/root/firstboot_setup_fileperms.log"
  {
    # modify permissions on specific files
    chown -v root:root /var/log/*log
    chmod -v 600 /var/log/*log
    chown -v root:root /etc/cron.*ly
    chmod -v og-rwx /etc/cron.*ly
    chown -v root:root /etc/crontab
    chmod -v og-rwx /etc/crontab
    # Fix at/cron daemon permissions:
    rm -vf /etc/at.deny
    touch /etc/at.allow
    chown -v root:root /etc/at.allow
    chmod -v og-rww /etc/at.allow
    rm -vf /etc/cron.deny
    touch /etc/cron.allow
    chmod -v og-rwx /etc/cron.allow
    chown -v root:root /etc/cron.allow
  } >> "${LOG}"
}

# setup_sshd
function setup_sshd() {
  LOG="/root/firstboot_setup_sshd.log"
  {
    FILE="/etc/ssh/sshd_config"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i '
/^Protocol\ /d;
/^Ciphers\ /d;
/^LogLevel\ /d;
/^PermitRootLogin\ /d;
/^MaxAuthTries\ /d;
/^HostbaseAuthentication\ /d;
/^IgnoreRhosts\ /d;
/^PermitEmptyPasswords\ /d;
/^PermitUserEnvironment\ /d;
/^Banner\ /d;
' "${FILE}"
    cat << EOF >> /etc/ssh/sshd_config
Protocol 2
Ciphers aes128-ctr,aes192-ctr,aes256-ctr
LogLevel INFO
PermitRootLogin no
MaxAuthTries 4
HostbasedAuthentication no
IgnoreRhosts yes
PermitEmptyPasswords no
PermitUserEnvironment no
Banner /etc/custombanner
EOF
    systemctl restart sshd
  } >> "${LOG}"
}

# create_banner
function create_banner() {
  LOG="/root/firstboot_create_banner.log"
  {
    FILE="/etc/custombanner"
    cat << EOF > "${FILE}"
 ************ WARNING: UNAUTHORIZED PERSONS, DO NOT PROCEED ************

This system is intended to be used solely by authorized users in the course of
legitimate corporate business.  Users are monitored to the extent necessary to
properly administer the system, to identify unauthorized users or users operating
beyond their proper authority, and to investigate improper access or use. By
accessing the system, you are consenting to this monitoring.  Additionally, users
accessing this system agree that they understand and will comply with all Company
Information Security and Privacy policies, including policy statements, instructions,
standards and guidelines.

 ************ WARNING: UNAUTHORIZED PERSONS, DO NOT PROCEED ************
EOF
    restorecon -v "${FILE}"
    FILE="/etc/issue"
    cat << EOF > "${FILE}"
 ************ WARNING: UNAUTHORIZED PERSONS, DO NOT PROCEED ************

This system is intended to be used solely by authorized users in the course of
legitimate corporate business.  Users are monitored to the extent necessary to
properly administer the system, to identify unauthorized users or users operating
beyond their proper authority, and to investigate improper access or use. By
accessing the system, you are consenting to this monitoring.  Additionally, users
accessing this system agree that they understand and will comply with all Company
Information Security and Privacy policies, including policy statements, instructions,
standards and guidelines.

 ************ WARNING: UNAUTHORIZED PERSONS, DO NOT PROCEED ************
EOF
    restorecon -v "${FILE}"
  } >> "${LOG}"
}

# setup_passpolicy
function setup_passpolicy() {
  LOG="/root/firstboot_setup_passpolicy.log"
  {
    FILE="/etc/pam.d/system-auth"
    cp -fva "${FILE}" "${FILE}.orig"
    cat << EOF >> "${FILE}"
password    sufficient    pam_unix.so remember=5
EOF
    # modify pwqualityconf
    FILE="/etc/security/pwquality.conf"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i '
      /^minlen\ /d;
      /^dcredit\ /d;
      /^ucredit\ /d;
      /^lcredit\ /d;
      /^ocredit\ /d;
' "${FILE}"
    cat << EOF >> "${FILE}"
# openscap settings
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
EOF
  } >> "${LOG}"
}

# setup_su
function setup_su() {
  LOG="/root/firstboot_setup_su.log"
  {
    FILE="/etc/group"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i 's/^wheel:.*/wheel:x:10:corona,stack/;' "${FILE}"
    FILE="/etc/pam.d/su"
    cp -fva "${FILE}" "${FILE}.orig"
    # uncomment the following line in /etc/pam.d/su
    sed -i '/#\(auth.*required.*pam_wheel.so\ use_uid\)/s/\#//;' /etc/pam.d/su
  } >> "${LOG}"
}

# setup_login
function setup_login() {
  LOG="/root/firstboot_setup_login.log"
  {
    FILE="/etc/login.defs"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i '
      s/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/;
      s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/;
' "${FILE}"
  } >> "${LOG}"
}

# functions below for post_deploy
setup_fileperms
setup_sshd
create_banner
setup_passpolicy
setup_su
setup_login


