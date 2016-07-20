#!/bin/bash

set -e

bundles=$(find stable -name bundle.yaml)

for bundle in $bundles; do
    echo "Updating $bundle"
    ./tools/update-bundle-versions -i $bundle
done
