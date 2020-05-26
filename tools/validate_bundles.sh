#!/bin/bash -ex
# Synthetically validate bundle for yaml and Juju syntax
#
# NOTE(beisner): This will fail if a model and controller are not active.

bundles=$(find . -name "bundle*.yaml")
for bundle in $bundles; do
    juju deploy --dry-run $bundle
done
