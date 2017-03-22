#!/bin/sh
#
# Copyright (C) 2015 Red Hat, Inc.
#
# Author: Pierre Blanc <pblanc@redhat.com>
#         Dimitri Savineau <dsavinea@redhat.com>
#         Gaetan Trellu <gtrellu@redhat.com>
#	  Guillaume Chenuet <gchenuet@redhat.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

if [ ! -f ~/stackrc ]; then
    echo "No stackrc file found"
    exit 1
else
    source ~/stackrc
fi

echo "Checking all ironic nodes..."

#Shutdown node stay on
for node in $(ironic node-list | egrep "power on" | awk '{print $2}'); do
  echo "Switch $node power state to 'off'"
  ironic node-set-power-state $node off
done

#Set provision state to available
for node in $(ironic node-list | grep -P "(active|wait|deploy|cleaning|error)" | awk '{print $2}'); do
  echo "Set $node state to 'available'"
  ironic node-set-provision-state $node deleted
done

#Set provision state to available
for node in $(ironic node-list | grep manageable | awk '{print $2}'); do
  echo "Set $node state to 'available'"
  ironic node-set-provision-state $node provide
done

#Unset instance_uuid param
for node in $(ironic node-list | awk '{print $2" "$6}' | grep -v -P '(None|Inst|^\s*$)'| awk '{print $1}'); do
  echo "Unset instance_uuid on $node" 
  ironic node-update $node remove instance_uuid  > /dev/null
done

#Switch maintenance mode to false
for node in $(ironic node-list | grep "True" | awk '{print $2}'); do
  echo "Switch $node 'maintenance' state to 'false'"
  ironic node-set-maintenance $node false
done

echo "Done."
