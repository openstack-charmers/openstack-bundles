#!/bin/bash -e
# Generate indentifying information about the checked out git repo.
# Takes 1 optional parameter:  path of directory to inspect.

PARAM1=$1
DIR="$(pwd)"
if [[ -n "$PARAM1" ]]; then
    cd $PARAM1
fi

echo "commit-sha-1: $(git rev-parse HEAD)
commit-short: $(git rev-parse --short HEAD)
branch: $(git rev-parse --abbrev-ref HEAD)
remote: $(git config --get remote.origin.url)
info-generated: $(date -u)
note: This file should exist only in a built or released bundle artifact (not in the bundle source code tree)."

if [[ -n "$PARAM1" ]]; then
    cd $DIR
fi

