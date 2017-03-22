#!/usr/bin/env bash
# 
# Disable selinux
set -x ; l=post_deploy-set_selinux_permissive ; VLOG=/var/log/ospd/${l%\.sh}.log ; exec &> >(tee -a "${VLOG}")

echo "Disable SELINUX (config)"
sed -i -e 's/SELINUX=enforcing/SELINUX=permissive/' /etc/sysconfig/selinux

echo "Disable SELINUX (live)"
/usr/sbin/setenforce 0
