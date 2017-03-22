#!/usr/bin/env bash
# 
# Disable selinux
set -x ; VLOG=/var/log/ospd/post_deploy-selinux_set_permissive.log ; exec &> >(tee -a "${VLOG}")

echo "Disable SELINUX (config)"
sed -i -e 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

echo "Disable SELINUX (live)"
/usr/sbin/setenforce 0
