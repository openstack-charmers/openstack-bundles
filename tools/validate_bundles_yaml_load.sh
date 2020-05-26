#!/bin/bash -ex

# Basic yaml syntax check
bundles=$(find . -name "bundle*.yaml")
for bundle in $bundles; do
    /usr/bin/env python -c 'import sys;from ruamel.yaml import YAML;YAML(typ="safe").load(sys.stdin)' < $bundle
done
