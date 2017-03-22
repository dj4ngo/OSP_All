#!/bin/bash
# Configure F5 LBaas Payload

#
set -x ; VLOG=/var/log/ospd/post_deploy-configure_f5_lbaas.log ; exec &> >(tee -a "${VLOG}")
F5_DIR=/usr/lib/python2.7/site-packages/neutron_lbaas/drivers/f5

myhostname=$(hostname -s)
case ${myhostname} in
        instack|*-ctrl-*|*-controller-*)
		echo "Controller detected, continuing..."
		echo -e "Install F5 service driver code on controller nodes \n"
		mkdir ${F5_DIR}
		touch ${F5_DIR}/__init__.py

cat << EOF > "${F5_DIR}/driver_v2.py"
# Copyright 2016 F5 Networks Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import f5lbaasdriver
from f5lbaasdriver.v2.bigip.driver_v2 import F5DriverV2

from oslo_log import log as logging

from neutron_lbaas.drivers import driver_base

VERSION = "0.1.1"
LOG = logging.getLogger(__name__)


class UndefinedEnvironment(Exception):
    pass


class F5LBaaSV2Driver(driver_base.LoadBalancerBaseDriver):

    def __init__(self, plugin, env='Project'):
        super(F5LBaaSV2Driver, self).__init__(plugin)

        self.load_balancer = LoadBalancerManager(self)
        self.listener = ListenerManager(self)
        self.pool = PoolManager(self)
        self.member = MemberManager(self)
        self.health_monitor = HealthMonitorManager(self)

        if not env:
            msg = "F5LBaaSV2Driver cannot be intialized because the environment"\
                " is not defined. To set the environment, edit "\
                "neutron_lbaas.conf and append the environment name to the "\
                "service_provider class name."
            LOG.debug(msg)
            raise UndefinedEnvironment(msg)

        LOG.debug("F5LBaaSV2Driver: initializing, version=%s, impl=%s, env=%s"
                  % (VERSION, f5lbaasdriver.__version__, env))

        self.f5 = F5DriverV2(plugin, env)


class F5LBaaSV2DriverTest(F5LBaaSV2Driver):

    def __init__(self, plugin, env='Test'):
        super(F5LBaaSV2DriverTest, self).__init__(plugin, env)

        LOG.debug(
            "F5LBaaSV2DriverTest: initializing, version=%s, f5=%s, env=%s"
            % (VERSION, f5lbaasdriver.__version__, env))

class F5LBaaSV2DriverProject(F5LBaaSV2Driver):

    def __init__(self, plugin, env='Project'):
        super(F5LBaaSV2DriverProject, self).__init__(plugin, env)

        LOG.debug(
            "F5LBaaSV2DriverProject: initializing, version=%s, f5=%s, env=%s"
            % (VERSION, f5lbaasdriver.__version__, env))


class LoadBalancerManager(driver_base.BaseLoadBalancerManager):

    def create(self, context, lb):
        self.driver.f5.loadbalancer.create(context, lb)

    def update(self, context, old_lb, lb):
        self.driver.f5.loadbalancer.update(context, old_lb, lb)

    def delete(self, context, lb):
        self.driver.f5.loadbalancer.delete(context, lb)

    def refresh(self, context, lb):
        self.driver.f5.loadbalancer.refresh(context, lb)

    def stats(self, context, lb):
        return self.driver.f5.loadbalancer.stats(context, lb)


class ListenerManager(driver_base.BaseListenerManager):

    def create(self, context, listener):
        self.driver.f5.listener.create(context, listener)

    def update(self, context, old_listener, listener):
        self.driver.f5.listener.update(context, old_listener, listener)

    def delete(self, context, listener):
        self.driver.f5.listener.delete(context, listener)


class PoolManager(driver_base.BasePoolManager):

    def create(self, context, pool):
        self.driver.f5.pool.create(context, pool)

    def update(self, context, old_pool, pool):
        self.driver.f5.pool.update(context, old_pool, pool)

    def delete(self, context, pool):
        self.driver.f5.pool.delete(context, pool)


class MemberManager(driver_base.BaseMemberManager):

    def create(self, context, member):
        self.driver.f5.member.create(context, member)

    def update(self, context, old_member, member):
        self.driver.f5.member.update(context, old_member, member)

    def delete(self, context, member):
        self.driver.f5.member.delete(context, member)


class HealthMonitorManager(driver_base.BaseHealthMonitorManager):

    def create(self, context, health_monitor):
        self.driver.f5.healthmonitor.create(context, health_monitor)

    def update(self, context, old_health_monitor, health_monitor):
        self.driver.f5.healthmonitor.update(context, old_health_monitor,
                                   health_monitor)

    def delete(self, context, health_monitor):
        self.driver.f5.healthmonitor.delete(context, health_monitor)
EOF
		chmod 0755 ${F5_DIR}/driver_v2.py
		chmod -R a+Xr ${F5_DIR}

		echo -e "Configure F5 LBaaS V2 agent \n"
		/bin/cp -fv /etc/neutron/services/f5/f5-openstack-agent.ini /etc/neutron/services/f5/f5-openstack-agent.ini.$(date +%m%d%y)
		openstack-config --set /etc/neutron/services/f5/f5-openstack-agent.ini DEFAULT f5_vtep_folder None
		openstack-config --set /etc/neutron/services/f5/f5-openstack-agent.ini DEFAULT f5_vtep_selfip_name None
		openstack-config --set /etc/neutron/services/f5/f5-openstack-agent.ini DEFAULT f5_global_routed_mode False
		openstack-config --set /etc/neutron/services/f5/f5-openstack-agent.ini DEFAULT f5_snat_addresses_per_subnet 0
		openstack-config --set /etc/neutron/services/f5/f5-openstack-agent.ini DEFAULT icontrol_password fedex123
		openstack-config --set /etc/neutron/services/f5/f5-openstack-agent.ini DEFAULT f5_external_physical_mappings default:apic_trunk1:True

		echo -e "Configure Neutron LBaaS service \n"
		/bin/cp -fv /etc/neutron/neutron_lbaas.conf /etc/neutron/neutron_lbaas.conf.$(date +%m%d%y)
		openstack-config --set /etc/neutron/neutron_lbaas.conf service_providers service_provider LOADBALANCERV2:F5Networks:neutron_lbaas.drivers.f5.driver_v2.F5LBaaSV2Driver:default

		echo -e "Configure Neutron File \n"
		/bin/cp -fv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.$(date +%m%d%y)
		openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins cisco_apic_l3,metering,neutron_lbaas.services.loadbalancer.plugin.LoadBalancerPluginv2

		echo "Editing horizon/openstack-dashboard settings and enabling LBaaS.."
		sed -i -e '/enable_lb.:.*False/s@False@True@' /etc/openstack-dashboard/local_settings

		echo "Editing Settings..."
		openstack-config --set /etc/neutron/services/f5/f5-openstack-agent.ini DEFAULT icontrol_hostname __F5_ICONTROL_HOSTNAME__
		openstack-config --set /etc/neutron/services/f5/f5-openstack-agent.ini DEFAULT environment_prefix __F5_ENV_PREFIX__

		echo "Attempting to restart services..."
		systemctl enable f5-openstack-agent
		systemctl start f5-openstack-agent
		# Restart Services. Now handled by pcs-cluster-restart-post-config.yaml!!!
		#### systemctl restart neutron-server
		#### systemctl restart httpd

		# Enable and start F5 agent on all controller nodes:
	;;
	*)
		echo "Not a controller. Exit!"
		exit 0
	;;
esac
