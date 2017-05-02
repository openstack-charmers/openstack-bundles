#!/bin/bash -ex

# Basic yaml syntax check
bundles=$(find . -name "bundle*.yaml")
for bundle in $bundles; do
    /usr/bin/env python -c 'import yaml,sys;yaml.safe_load(sys.stdin)' < $bundle
done
