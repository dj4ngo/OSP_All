* 20160502: deploy11.sh with RHEL registration. 10.20.0.2 as GTW for overcloud nodes
even though 10.20.0.1 is the actual network GW (Vbox) in order for the undercloud
VM to MASQ traffic from the other overcloud VMs (those without access to
10.0.0.0/24 - vlan10).

* 20160503:
