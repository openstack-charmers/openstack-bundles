#!/bin/bash

set -e

bundles=$(find . -name "bundle.yaml")

for bundle in $bundles; do
    echo "Validating $bundle"
    juju-deployer -c $bundle -d -b
done
