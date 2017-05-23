#!/bin/bash -ex
# Synthetically validate bundle for yaml and Juju syntax
#
# NOTE(beisner): This will fail if a model and controller are not active.
#                https://bugs.launchpad.net/bugs/1679425)

bundles=$(find . -name "bundle*.yaml")
for bundle in $bundles; do
    juju-deployer -c $bundle -d -b
done
