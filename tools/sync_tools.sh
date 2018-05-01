#!/bin/bash -ex
# Sync neutron config tools from openstack-charm-testing

oct_tmp="$(mktemp -d)"
git clone --depth 1 https://github.com/openstack-charmers/openstack-charm-testing $oct_tmp

tools="neutron-ext-net neutron-tenant-net neutron-ext-net-ksv3 neutron-tenant-net-ksv3"
for tool in $tools; do
    cp -fvp $oct_tmp/bin/$tool stable/shared/$tool
    cp -fvp $oct_tmp/bin/$tool development/shared/$tool
done
rcs="openrc openrcv2 openrcv3_project openrcv3_domain"
for rc in $rcs; do
    cp -fvp $oct_tmp/rcs/$rc stable/shared/$rc
    cp -fvp $oct_tmp/rcs/$rc development/shared/$rc
done
rm -rf $oct_tmp
