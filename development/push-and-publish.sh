#!/bin/bash -ex

bundle="$1"

if [ -z "$bundle" ]; then
    echo "Please provide bundle directory name as the only parameter"
    exit 1
fi

if [ ! -d $bundle ]; then
    echo "Unable to find bundle: $bundle"
    exit 1
fi

# NOTE(beisner):  The snap-based charm tool can only upload from within
# the user's HOME dir, and it cannot follow symlinks.  So, we copy and
# dereference before upload.
mkdir -p $HOME/temp
home_tmp="$(mktemp -d -p $HOME/temp)"
cp -Lrfv $bundle $home_tmp

echo "Pushing bundle to charm store"
./generate-repo-info.sh . > $home_tmp/$bundle/repo-info
bundle_id=$(charm push $home_tmp/$bundle cs:~openstack-charmers-next/$bundle | grep url | awk '{ print $2 }')

if [ -z "$bundle_id" ]; then
    echo "Publishing failed"
    exit 1
fi

echo "Setting bugs-url and homepage"
charm set $bundle_id \
    bugs-url=https://bugs.launchpad.net/openstack-bundles/+filebug \
    homepage=https://github.com/openstack-charmers/openstack-bundles/

echo "Publishing new bundle version to stable"
charm release $bundle_id
echo "Ensuring global read permissions"
charm grant cs:~openstack-charmers-next/$bundle --acl read everyone
rm -rfv $home_tmp
