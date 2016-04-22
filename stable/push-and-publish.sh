#!/bin/bash

set -ex

bundle="$1"

if [ -z "$bundle" ]; then
    echo "Please provide bundle as the only parameter"
    exit 1
fi

if [ ! -d $bundle ]; then
    echo "Unable to find bundle: $bundle"
    exit 1
fi


echo "Pushing bundle to charm store"
bundle_id=$(charm push $bundle cs:~openstack-charmers/$bundle | grep url | awk '{ print $2 }')

if [ -z "$bundle_id" ]; then
    echo "Publishing failed"
    exit 1
fi

echo "Publishing new bundle version to stable"
charm publish $bundle_id
echo "Ensuring global read permissions"
charm grant cs:~openstack-charmers/$bundle --acl read everyone
charm set cs:~openstack-charmers/$bundle homepage=https://github.com/openstack-charmers/openstack-bundles \
    bugs-url=https://github.com/openstack-charmers/openstack-bundles/issues
