#!/bin/bash
openstack stack output show overcloud --all -f value|grep -B1 --no-group-separator Vip
