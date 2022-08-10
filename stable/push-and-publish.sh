#!/bin/bash -ex

bundle="$1"
channel="${2:-latest/edge}"

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

echo "Packing bundle $bundle for charmhub..."
./generate-repo-info.sh . > $home_tmp/$bundle/repo-info
pushd $home_tmp/$bundle
charmcraft pack --verbose
rc=$?
popd

if [ $rc != 0 ]; then
    echo "Failed to pack bundle. Review log files."
    exit 2
fi

archive="$home_tmp/$bundle/$bundle.zip"
echo "Printing contents of artifact to upload: $archive"
zip -sf $archive

echo "Uploading artifact $archive to charmhub in channel $channel..."
charmcraft upload --channel $channel $archive
rc=$?

if [ $rc != 0 ]; then
    echo "Failed to upload and/or release bundle. Review log files."
    exit 3
fi

echo "Cleaning up temp dir..."
rm -rfv $home_tmp

echo "Done"
exit 0
