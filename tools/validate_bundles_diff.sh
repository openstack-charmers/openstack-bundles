#!/bin/bash -uex
# Assert that bundles will generally look and be the same, except for
# expected differences such as openstack-origin, source, etc.

# Files expected within each bundle directory
expected_files="bundle.yaml neutron-ext-net* neutron-tenant-net* novarc openrc README.md"

# Confirm files exist in dirs
for d in $(find development/ -type d -name openstack-*); do
    for f in $expected_files; do
        stat -t $d/$f
    done
done

# Check openstack-base dev bundle diffs
baseline_bundle="development/openstack-base-xenial-mitaka/bundle.yaml"
too_much_diff=""
for d in $(find development/ -type d -name openstack-base* -and ! -name openstack-base-spaces*); do
    diff -Naur $d/bundle.yaml $baseline_bundle | \
        egrep -v "options:|openstack-origin:|source:" | \
        egrep "^\+ |^\- " &&\
            export too_much_diff="$too_much_diff $d/bundle.yaml" ||\
            echo "Diff OK: $d/bundle.yaml"
done

# Check openstack-telemetry dev bundle diffs
baseline_bundle="development/openstack-telemetry-xenial-mitaka/bundle.yaml"
too_much_diff=""
for d in $(find development/ -type d -name openstack-telemetry*); do
    diff -Naur $d/bundle.yaml $baseline_bundle | \
        egrep -v "options:|openstack-origin:|source:" | \
        egrep "^\+ |^\- " &&\
            export too_much_diff="$too_much_diff $d/bundle.yaml" ||\
            echo "Diff OK: $d/bundle.yaml"
done

# Check current stable openstack-base bundle diff against dev of the same release
baseline_bundle="development/openstack-base-xenial-pike/bundle.yaml"
stable_bundle="stable/openstack-base/bundle.yaml"
diff -Naur $stable_bundle $baseline_bundle | \
    egrep -v " charm:| options:| openstack-origin:| source:" | \
    egrep "^\+ |^\- " &&\
        export too_much_diff="$too_much_diff $stable_bundle" ||\
        echo "Diff OK: $stable_bundle"

# Check current stable openstack-telemetry bundle diff against dev of the same release
baseline_bundle="development/openstack-telemetry-xenial-pike/bundle.yaml"
stable_bundle="stable/openstack-telemetry/bundle.yaml"
diff -Naur $stable_bundle $baseline_bundle | \
    egrep -v " charm:| options:| openstack-origin:| source:" | \
    egrep "^\+ |^\- " &&\
        export too_much_diff="$too_much_diff $stable_bundle" ||\
        echo "Diff OK: $stable_bundle"

if [[ -n "$too_much_diff" ]]; then
    echo "Too much diff in $too_much_diff"
    exit 1
fi
