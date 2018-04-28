#!/bin/bash -ex

oct_tmp="$(mktemp -d)"
git clone --depth 1 https://github.com/openstack-charmers/openstack-charm-testing $oct_tmp

tools="neutron-ext-net neutron-tenant-net neutron-ext-net-ksv3 neutron-tenant-net-ksv3"
for tool in $tools; do
    if ! diff -Naur $oct_tmp/bin/$tool stable/shared/$tool; then
       echo "FAIL: $tool has too much diff against o-c-t"
      exit 1
    fi
    if ! diff -Naur $oct_tmp/bin/$tool development/shared/$tool; then
       echo "FAIL: $tool has too much diff against o-c-t"
      exit 1
    fi
done
rcs="openrc openrcv2 openrcv3_project openrcv3_domain"
for rc in $rcs; do
    if ! diff -Naur $oct_tmp/rcs/$rc stable/shared/$rc; then
       echo "FAIL: $rc has too much diff against o-c-t"
      exit 1
    fi
    if ! diff -Naur $oct_tmp/rcs/$rc development/shared/$rc; then
       echo "FAIL: $rc has too much diff against o-c-t"
      exit 1
    fi
done

rm -rf $oct_tmp
